# Local Variables - AU/Nonprod Environment

locals {
  common_tags = {
    Environment = local.environment
    Region      = local.region
    ManagedBy   = "Terraform"
    CreatedDate = "2025-11-28"
  }

  rg_name           = "rg-${local.region}-${local.environment}-hub-spoke"
  hub_vnet_name     = "vnet-${local.region}-${local.environment}-hub"
  spoke_vnet_names  = ["vnet-${local.region}-${local.environment}-spoke1", "vnet-${local.region}-${local.environment}-spoke2"]
  firewall_name     = "fw-${local.region}-${local.environment}"
  bastion_name      = "bastion-${local.region}-${local.environment}"
  workspace_name    = "law-${local.region}-${local.environment}"
}
