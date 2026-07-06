# UDR Module - Outputs

output "route_table_id" {
  description = "ID of the route table"
  value       = azurerm_route_table.udr.id
}

output "route_table_name" {
  description = "Name of the route table"
  value       = azurerm_route_table.udr.name
}

output "routes" {
  description = "Routes in the route table"
  value = {
    for k, v in azurerm_route.routes : k => {
      address_prefix    = v.address_prefix
      next_hop_type     = v.next_hop_type
      next_hop_ip       = v.next_hop_in_ip_address
    }
  }
}
