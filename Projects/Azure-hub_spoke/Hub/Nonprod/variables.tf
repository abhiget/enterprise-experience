# Variables - AU/Nonprod Environment

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "hub_address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_address_spaces" {
  description = "Address spaces for spoke VNets"
  type        = list(list(string))
  default     = [["10.1.0.0/16"], ["10.2.0.0/16"]]
}

variable "hub_subnets" {
  description = "Subnets for the hub VNet"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegation       = optional(list(object({
      name    = string
      service = string
      actions = list(string)
    })), [])
  }))
  default = {
    "AzureFirewallSubnet" = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.1.0/24"]
    }
    "AzureBastionSubnet" = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

variable "firewall_sku" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "enable_monitoring" {
  description = "Enable monitoring and log analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}
