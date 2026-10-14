resource "azurerm_service_plan" "apps" {
  count = var.enable_extended_stack ? 1 : 0

  name                = local.app_service_plan_name
  resource_group_name = data.azurerm_resource_group.project.name
  location            = data.azurerm_resource_group.project.location
  os_type             = "Linux"
  sku_name            = "B1"
  worker_count        = 1

  tags = local.common_tags
}

resource "azurerm_linux_web_app" "api" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.api_app_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  service_plan_id               = azurerm_service_plan.apps[0].id
  https_only                    = true
  public_network_access_enabled = true
  virtual_network_subnet_id     = azurerm_subnet.appservice_integration[0].id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api[0].id]
  }

  site_config {
    always_on                         = true
    minimum_tls_version               = "1.2"
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 2
    app_command_line                  = "uvicorn app.main:app --host 0.0.0.0 --port 8000"

    application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.aiops[0].connection_string
    AZURE_CLIENT_ID                       = azurerm_user_assigned_identity.api[0].client_id
    AZURE_OPENAI_ENDPOINT                 = azurerm_cognitive_account.openai[0].endpoint
    AZURE_OPENAI_DEPLOYMENT               = azurerm_cognitive_deployment.incident_triage[0].name
    KEY_VAULT_URI                         = azurerm_key_vault.aiops[0].vault_uri
    LOG_ANALYTICS_WORKSPACE_ID            = azurerm_log_analytics_workspace.aiops.workspace_id
    POSTGRES_DATABASE                     = azurerm_postgresql_flexible_server_database.aiops[0].name
    POSTGRES_HOST                         = azurerm_postgresql_flexible_server.aiops[0].fqdn
    POSTGRES_AUTH_MODE                    = "managed_identity"
    WEBSITES_PORT                         = "8000"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }

  tags = local.common_tags
}

resource "azurerm_linux_web_app" "worker" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.worker_app_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  service_plan_id               = azurerm_service_plan.apps[0].id
  https_only                    = true
  public_network_access_enabled = true
  virtual_network_subnet_id     = azurerm_subnet.appservice_integration[0].id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.worker.id]
  }

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
    app_command_line    = "python -m app.worker"

    application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.aiops[0].connection_string
    AZURE_CLIENT_ID                       = azurerm_user_assigned_identity.worker.client_id
    EVENTHUB_CONSUMER_GROUP               = azurerm_eventhub_consumer_group.worker.name
    EVENTHUB_NAME                         = azurerm_eventhub.telemetry.name
    EVENTHUB_NAMESPACE                    = azurerm_eventhub_namespace.aiops.name
    EVENTHUB_CHECKPOINT_ACCOUNT           = azurerm_storage_account.checkpoint.name
    EVENTHUB_CHECKPOINT_CONTAINER         = azurerm_storage_container.checkpoint.name
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }

  tags = local.common_tags
}
