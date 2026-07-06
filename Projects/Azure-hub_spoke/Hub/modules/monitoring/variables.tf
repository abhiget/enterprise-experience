# Monitoring Module - Variables

variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
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

variable "sku" {
  description = "SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "create_network_watcher" {
  description = "Create Network Watcher"
  type        = bool
  default     = true
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher"
  type        = string
  default     = "NetworkWatcher"
}

variable "enable_network_monitoring" {
  description = "Enable network monitoring solution"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
