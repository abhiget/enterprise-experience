locals {
  vnet_name              = "vnet-${var.name_prefix}-${var.name_suffix}"
  app_subnet_name        = "snet-appsvc-integration"
  postgres_subnet_name   = "snet-postgres"
  postgres_server_name   = "pg-${var.name_prefix}-${var.name_suffix}"
  postgres_database_name = "aiops"
  key_vault_name         = "kv-${var.name_prefix}-${var.name_suffix}"
  openai_name            = "aoai-${var.name_prefix}-${var.name_suffix}"
  grafana_name           = "amg-${var.name_prefix}-${var.name_suffix}"
  app_service_plan_name  = "asp-${var.name_prefix}-${var.name_suffix}"
  api_app_name           = "app-${var.name_prefix}-api-${var.name_suffix}"
  worker_app_name        = "app-${var.name_prefix}-worker-${var.name_suffix}"
}
