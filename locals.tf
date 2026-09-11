locals {
  # Naming convention: <project>-<environment>-<region-short>-<resource-type>
  region_short = lookup(local.region_shortnames, var.location, substr(var.location, 0, 6))

  region_shortnames = {
    eastus2     = "eus2"
    eastus      = "eus"
    centralus   = "cus"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
  }

  name_prefix = "${var.project}-${var.environment}-${local.region_short}"

  resource_group_name = coalesce(var.resource_group_name, "rg-${local.name_prefix}")

  mandatory_tags = {
    Environment  = var.environment
    Project      = var.project
    Owner        = var.owner
    CostCenter   = var.cost_center
    ManagedBy    = "Terraform"
    DataSensitivity = "Confidential"
  }

  tags = merge(local.mandatory_tags, var.tags)

  is_prod = var.environment == "prod"
}
