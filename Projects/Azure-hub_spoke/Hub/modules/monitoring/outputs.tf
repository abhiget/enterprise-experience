# Monitoring Module - Outputs

output "workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.name
}

output "workspace_resource_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.workspace_id
}

output "network_watcher_id" {
  description = "ID of the Network Watcher"
  value       = var.create_network_watcher ? azurerm_network_watcher.watcher[0].id : null
}

output "network_monitoring_solution_id" {
  description = "ID of the Network Monitoring solution"
  value       = var.enable_network_monitoring ? azurerm_log_analytics_solution.network_monitoring[0].id : null
}
