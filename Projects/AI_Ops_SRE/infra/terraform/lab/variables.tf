variable "subscription_id" {
  description = "Azure subscription that contains the existing AIOps resource group."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "Provide a valid Azure subscription GUID."
  }
}

variable "resource_group_name" {
  description = "Existing resource group for disposable AIOps lab resources. Terraform does not create or delete this group."
  type        = string
  default     = "RG-SRE-AIOPS"
}

variable "name_prefix" {
  description = "Short lowercase alphanumeric prefix used for Azure resource names."
  type        = string
  default     = "sreaiops"

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.name_prefix))
    error_message = "name_prefix must contain 3-8 lowercase letters or numbers."
  }
}

variable "name_suffix" {
  description = "Stable 4-8 character lowercase alphanumeric suffix; keep it unchanged across lab destroy/recreate cycles."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{4,8}$", var.name_suffix))
    error_message = "name_suffix must contain 4-8 lowercase letters or numbers."
  }
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention period in days."
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily Log Analytics ingestion cap in GB. This is a data-ingestion limit, not a spending cap."
  type        = number
  default     = 1

  validation {
    condition     = var.log_analytics_daily_quota_gb >= 0.5
    error_message = "The Log Analytics daily quota must be at least 0.5 GB."
  }
}

variable "eventhub_capacity" {
  description = "Event Hubs Standard throughput units. Review region pricing before increasing."
  type        = number
  default     = 1

  validation {
    condition     = var.eventhub_capacity >= 1 && var.eventhub_capacity <= 20
    error_message = "Event Hubs capacity must be between 1 and 20 throughput units."
  }
}

variable "activity_log_categories" {
  description = "Subscription Activity Log categories exported to Log Analytics and Event Hubs."
  type        = set(string)
  default     = ["Administrative", "Alert", "Policy", "ResourceHealth", "ServiceHealth", "Security"]
}

variable "enable_subscription_activity_log_export" {
  description = "Create a subscription-scoped Activity Log diagnostic setting. Review the plan because its scope is the whole subscription."
  type        = bool
  default     = true
}

variable "enable_extended_stack" {
  description = "Create the optional database, Key Vault, Azure OpenAI, Managed Grafana, and App Service resources. Review costs and regional availability before apply."
  type        = bool
  default     = false
}

variable "postgres_admin_principal_name" {
  description = "Entra ID user principal name assigned as the PostgreSQL Microsoft Entra administrator."
  type        = string
  default     = ""
}

variable "postgres_sku_name" {
  description = "Azure Database for PostgreSQL Flexible Server compute SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "openai_model_name" {
  description = "Azure OpenAI model to deploy for incident summaries."
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_model_version" {
  description = "Azure OpenAI model version. Confirm availability and quota in the selected region before apply."
  type        = string
  default     = "2024-07-18"
}

variable "openai_deployment_sku" {
  description = "Azure OpenAI deployment SKU."
  type        = string
  default     = "GlobalStandard"
}

variable "openai_deployment_capacity" {
  description = "Capacity units for the Azure OpenAI deployment."
  type        = number
  default     = 1
}

variable "additional_tags" {
  description = "Optional tags applied to lab resources."
  type        = map(string)
  default     = {}
}
