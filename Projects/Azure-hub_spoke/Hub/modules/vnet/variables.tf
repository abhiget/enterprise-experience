# VNet Module - Variables

variable "vnet_name" {
  description = "Name of the virtual network"
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

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets for the VNet"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegation       = optional(list(object({
      name    = string
      service = string
      actions = list(string)
    })), [])
  }))
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
