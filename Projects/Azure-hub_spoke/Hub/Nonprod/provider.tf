# Azure Provider Configuration - AU/Nonprod Environment

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion            = true
      graceful_shutdown                     = false
      skip_shutdown_and_force_delete        = false
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
}
