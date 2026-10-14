data "azurerm_resource_group" "project" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

locals {
  common_tags = merge(var.additional_tags, {
    project     = "aiops-sre"
    environment = "dev-lab"
    managed_by  = "terraform"
  })

  compact_prefix = var.name_prefix
  workspace_name = "law-${var.name_prefix}-${var.name_suffix}"
  namespace_name = "ehns-${var.name_prefix}-${var.name_suffix}"
  storage_name   = "st${local.compact_prefix}${var.name_suffix}"
}

resource "azurerm_log_analytics_workspace" "aiops" {
  name                         = local.workspace_name
  resource_group_name          = data.azurerm_resource_group.project.name
  location                     = data.azurerm_resource_group.project.location
  sku                          = "PerGB2018"
  retention_in_days            = var.log_analytics_retention_days
  daily_quota_gb               = var.log_analytics_daily_quota_gb
  internet_ingestion_enabled   = true
  internet_query_enabled       = true
  local_authentication_enabled = false

  tags = local.common_tags
}

resource "azurerm_eventhub_namespace" "aiops" {
  name                = local.namespace_name
  resource_group_name = data.azurerm_resource_group.project.name
  location            = data.azurerm_resource_group.project.location
  sku                 = "Standard"
  capacity            = var.eventhub_capacity

  minimum_tls_version           = "1.2"
  local_authentication_enabled  = true
  public_network_access_enabled = true
  auto_inflate_enabled          = false

  tags = local.common_tags
}

resource "azurerm_eventhub" "telemetry" {
  name              = "aiops-telemetry"
  namespace_id      = azurerm_eventhub_namespace.aiops.id
  partition_count   = 2
  message_retention = 1
}

resource "azurerm_eventhub_consumer_group" "worker" {
  name                = "aiops-worker"
  namespace_name      = azurerm_eventhub_namespace.aiops.name
  eventhub_name       = azurerm_eventhub.telemetry.name
  resource_group_name = data.azurerm_resource_group.project.name
  user_metadata       = "AIOps telemetry worker consumer group"
}

resource "azurerm_storage_account" "checkpoint" {
  name                            = local.storage_name
  resource_group_name             = data.azurerm_resource_group.project.name
  location                        = data.azurerm_resource_group.project.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = true

  tags = local.common_tags
}

resource "azurerm_storage_container" "checkpoint" {
  name                  = "eventhub-checkpoints"
  storage_account_id    = azurerm_storage_account.checkpoint.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "worker" {
  name                = "id-${var.name_prefix}-worker-${var.name_suffix}"
  resource_group_name = data.azurerm_resource_group.project.name
  location            = data.azurerm_resource_group.project.location

  tags = local.common_tags
}

resource "azurerm_role_assignment" "worker_eventhub_receive" {
  scope                = azurerm_eventhub.telemetry.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_user_assigned_identity.worker.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "worker_checkpoint_access" {
  scope                = azurerm_storage_account.checkpoint.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.worker.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_eventhub_namespace_authorization_rule" "monitor_send" {
  name                = "monitor-diagnostic-send"
  namespace_name      = azurerm_eventhub_namespace.aiops.name
  resource_group_name = data.azurerm_resource_group.project.name
  manage              = true
  send                = true
  listen              = true
}

resource "azurerm_monitor_diagnostic_setting" "subscription_activity" {
  count = var.enable_subscription_activity_log_export ? 1 : 0

  name                           = "diag-aiops-activity-${var.name_suffix}"
  target_resource_id             = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.aiops.id
  eventhub_name                  = azurerm_eventhub.telemetry.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.monitor_send.id

  dynamic "enabled_log" {
    for_each = var.activity_log_categories

    content {
      category = enabled_log.value
    }
  }
}
