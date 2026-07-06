# Outputs - AU/Nonprod Environment

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.rg.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

# Uncomment to output module values once modules are instantiated
# output "hub_vnet_id" {
#   description = "ID of the hub VNet"
#   value       = module.hub_vnet.vnet_id
# }
#
# output "hub_subnets" {
#   description = "Hub subnet details"
#   value       = module.hub_vnet.subnet_details
# }
#
# output "firewall_private_ip" {
#   description = "Private IP of the firewall"
#   value       = module.firewall.firewall_private_ip
# }
