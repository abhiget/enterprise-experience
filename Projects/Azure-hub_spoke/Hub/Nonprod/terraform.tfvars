# Terraform Variables File - AU/Nonprod Environment
# This file contains example values - update with your actual values

subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

hub_address_space = ["10.0.0.0/16"]

spoke_address_spaces = [
  ["10.1.0.0/16"],
  ["10.2.0.0/16"]
]

hub_subnets = {
  "AzureFirewallSubnet" = {
    name             = "AzureFirewallSubnet"
    address_prefixes = ["10.0.1.0/24"]
  }
  "AzureBastionSubnet" = {
    name             = "AzureBastionSubnet"
    address_prefixes = ["10.0.2.0/24"]
  }
  "Management" = {
    name             = "Management"
    address_prefixes = ["10.0.3.0/24"]
  }
}

firewall_sku = "Standard"

enable_monitoring = true

log_retention_days = 30
