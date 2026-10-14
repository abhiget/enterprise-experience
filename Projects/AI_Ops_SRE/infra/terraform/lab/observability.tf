resource "azurerm_dashboard_grafana" "aiops" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.grafana_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  grafana_major_version         = "11"
  sku                           = "Standard"
  api_key_enabled               = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count = var.enable_extended_stack ? 1 : 0

  scope                = azurerm_log_analytics_workspace.aiops.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.aiops[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "current_user_grafana_admin" {
  count = var.enable_extended_stack ? 1 : 0

  scope                = azurerm_dashboard_grafana.aiops[0].id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_application_insights" "aiops" {
  count = var.enable_extended_stack ? 1 : 0

  name                 = "appi-${var.name_prefix}-${var.name_suffix}"
  resource_group_name  = data.azurerm_resource_group.project.name
  location             = data.azurerm_resource_group.project.location
  application_type     = "web"
  workspace_id         = azurerm_log_analytics_workspace.aiops.id
  retention_in_days    = var.log_analytics_retention_days
  daily_data_cap_in_gb = var.log_analytics_daily_quota_gb

  tags = local.common_tags
}
