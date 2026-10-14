resource "azurerm_postgresql_flexible_server" "aiops" {
  count = var.enable_extended_stack ? 1 : 0

  name                          = local.postgres_server_name
  resource_group_name           = data.azurerm_resource_group.project.name
  location                      = data.azurerm_resource_group.project.location
  version                       = "16"
  sku_name                      = var.postgres_sku_name
  storage_mb                    = 32768
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.postgres[0].id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres[0].id

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres,
  ]

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "current_user" {
  count = var.enable_extended_stack ? 1 : 0

  server_name         = azurerm_postgresql_flexible_server.aiops[0].name
  resource_group_name = data.azurerm_resource_group.project.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = var.postgres_admin_principal_name
  principal_type      = "User"

  lifecycle {
    precondition {
      condition     = length(trimspace(var.postgres_admin_principal_name)) > 0
      error_message = "Set postgres_admin_principal_name to the signed-in Entra user's UPN when the extended stack is enabled."
    }
  }
}

resource "azurerm_postgresql_flexible_server_database" "aiops" {
  count = var.enable_extended_stack ? 1 : 0

  name      = local.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.aiops[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
