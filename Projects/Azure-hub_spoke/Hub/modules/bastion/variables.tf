# Bastion Module - Variables

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
}

variable "bastion_pip_name" {
  description = "Name of the Bastion public IP"
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

variable "bastion_subnet_id" {
  description = "ID of the AzureBastionSubnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
