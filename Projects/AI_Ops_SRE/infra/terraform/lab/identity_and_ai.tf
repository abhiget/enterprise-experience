resource "azurerm_user_assigned_identity" "api" {
  count = var.enable_extended_stack ? 1 : 0

  name                = "id-${var.name_prefix}-api-${var.name_suffix}"
  resource_group_name = data.azurerm_resource_group.project.name
  location            = data.azurerm_resource_group.project.location

  tags = local.common_tags
}

resource "azurerm_role_assignment" "api_log_reader" {
  count = var.enable_extended_stack ? 1 : 0

  scope                = azurerm_log_analytics_workspace.aiops.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.api[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_key_vault" "aiops" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.key_vault_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  rbac_authorization_enabled    = true
  public_network_access_enabled = true

  tags = local.common_tags
}

resource "azurerm_role_assignment" "api_key_vault_secrets_user" {
  count = var.enable_extended_stack ? 1 : 0

  scope                = azurerm_key_vault.aiops[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_cognitive_account" "openai" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.openai_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = local.openai_name
  local_auth_enabled            = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "api_openai_user" {
  count = var.enable_extended_stack ? 1 : 0

  scope                = azurerm_cognitive_account.openai[0].id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.api[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_cognitive_deployment" "incident_triage" {
  count = var.enable_extended_stack ? 1 : 0

  name                 = "incident-triage"
  cognitive_account_id = azurerm_cognitive_account.openai[0].id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  sku {
    name     = var.openai_deployment_sku
    capacity = var.openai_deployment_capacity
  }
}
