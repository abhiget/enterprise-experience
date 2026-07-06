# NSG Module - Outputs

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.nsg.name
}

output "nsg_rules" {
  description = "Security rules in the NSG"
  value = {
    for k, v in azurerm_network_security_rule.rules : k => {
      priority    = v.priority
      direction   = v.direction
      access      = v.access
      protocol    = v.protocol
    }
  }
}
