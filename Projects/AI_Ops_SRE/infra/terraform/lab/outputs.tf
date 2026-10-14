output "resource_group_name" {
  description = "Existing resource group used by the lab."
  value       = data.azurerm_resource_group.project.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.aiops.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  value       = azurerm_log_analytics_workspace.aiops.name
}

output "eventhub_namespace_name" {
  description = "Event Hubs namespace name."
  value       = azurerm_eventhub_namespace.aiops.name
}

output "eventhub_name" {
  description = "Telemetry Event Hub name."
  value       = azurerm_eventhub.telemetry.name
}

output "eventhub_consumer_group" {
  description = "Dedicated consumer group for the Python worker."
  value       = azurerm_eventhub_consumer_group.worker.name
}

output "worker_identity_client_id" {
  description = "Client ID of the user-assigned identity for the Event Hubs worker."
  value       = azurerm_user_assigned_identity.worker.client_id
}

output "worker_identity_principal_id" {
  description = "Principal ID of the user-assigned identity for the Event Hubs worker."
  value       = azurerm_user_assigned_identity.worker.principal_id
}

output "checkpoint_storage_account_name" {
  description = "Storage account holding Event Hubs consumer checkpoints."
  value       = azurerm_storage_account.checkpoint.name
}

output "checkpoint_container_name" {
  description = "Private Blob container used for consumer checkpoints."
  value       = azurerm_storage_container.checkpoint.name
}

output "activity_log_export_enabled" {
  description = "Whether subscription Activity Logs are routed to Log Analytics and Event Hubs."
  value       = var.enable_subscription_activity_log_export
}

output "postgres_server_fqdn" {
  description = "Private FQDN of the AIOps PostgreSQL server when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_postgresql_flexible_server.aiops[0].fqdn : null
}

output "postgres_database_name" {
  description = "AIOps PostgreSQL database name when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_postgresql_flexible_server_database.aiops[0].name : null
}

output "api_managed_identity_client_id" {
  description = "User-assigned managed identity client ID for the API."
  value       = var.enable_extended_stack ? azurerm_user_assigned_identity.api[0].client_id : null
}

output "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_cognitive_account.openai[0].endpoint : null
}

output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_dashboard_grafana.aiops[0].endpoint : null
}

output "api_default_hostname" {
  description = "Default API App Service hostname when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_linux_web_app.api[0].default_hostname : null
}

output "worker_default_hostname" {
  description = "Default worker App Service hostname when the extended stack is enabled."
  value       = var.enable_extended_stack ? azurerm_linux_web_app.worker[0].default_hostname : null
}
