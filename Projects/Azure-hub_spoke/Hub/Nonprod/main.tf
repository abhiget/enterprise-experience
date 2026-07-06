# Main Configuration - AU/Nonprod Environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment to use remote state
  # backend "azurerm" {
  #   resource_group_name  = ""
  #   storage_account_name = ""
  #   container_name       = ""
  #   key                  = "nonprod.tfstate"
  # }
}

# Local variables for the environment
locals {
  environment = "nonprod"
  region      = "AU"
  location    = "australiaeast"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = local.location

  tags = local.common_tags
}

# Module References (Example - uncomment and configure as needed)
# module "hub_vnet" {
#   source = "../../modules/vnet"
#
#   vnet_name           = local.hub_vnet_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   address_space       = var.hub_address_space
#   subnets             = var.hub_subnets
#   tags                = local.common_tags
# }
