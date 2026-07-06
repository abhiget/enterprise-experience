# Firewall Module - Variables

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
}

variable "firewall_pip_name" {
  description = "Name of the Firewall public IP"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the firewall"
  type        = string
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  description = "SKU tier for the firewall"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
