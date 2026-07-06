# Monitoring Module - Main Configuration

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = var.tags
}

resource "azurerm_network_watcher" "watcher" {
  count               = var.create_network_watcher ? 1 : 0
  name                = var.network_watcher_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "network_monitoring" {
  count               = var.enable_network_monitoring ? 1 : 0
  solution_name       = "NetworkMonitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_name      = azurerm_log_analytics_workspace.workspace.name
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/NetworkMonitoring"
  }
}
