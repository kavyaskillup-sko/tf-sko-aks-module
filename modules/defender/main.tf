# Microsoft Defender for Cloud plan enrollment. These are subscription-wide
# resources - only enable this module in one environment stack per
# subscription (see enable_defender_for_cloud) to avoid duplicate/conflicting
# pricing resources across dev/uat/prod applies.

resource "azurerm_security_center_subscription_pricing" "plans" {
  for_each      = toset(var.plans)
  tier          = "Standard"
  resource_type = each.value
}
