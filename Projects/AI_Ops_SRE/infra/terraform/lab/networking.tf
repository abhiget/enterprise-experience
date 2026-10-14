resource "azurerm_virtual_network" "app" {
  count = var.enable_extended_stack ? 1 : 0

  name                = local.vnet_name
  resource_group_name = data.azurerm_resource_group.project.name
  location            = data.azurerm_resource_group.project.location
  address_space       = ["10.42.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "appservice_integration" {
  count = var.enable_extended_stack ? 1 : 0

  name                 = local.app_subnet_name
  resource_group_name  = data.azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.app[0].name
  address_prefixes     = ["10.42.1.0/24"]

  delegation {
    name = "app-service"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  count = var.enable_extended_stack ? 1 : 0

  name                 = local.postgres_subnet_name
  resource_group_name  = data.azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.app[0].name
  address_prefixes     = ["10.42.2.0/28"]

  delegation {
    name = "postgres-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  count = var.enable_extended_stack ? 1 : 0

  name                = "private.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.project.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count = var.enable_extended_stack ? 1 : 0

  name                  = "pdnslink-${var.name_prefix}-${var.name_suffix}"
  resource_group_name   = data.azurerm_resource_group.project.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = azurerm_virtual_network.app[0].id
  registration_enabled  = false

  tags = local.common_tags
}
