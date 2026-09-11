module "identity" {
  source = "./modules/identity"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_id             = module.network.vnet_id
  tags                = local.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix                 = local.name_prefix
  location                    = var.location
  resource_group_name         = azurerm_resource_group.this.name
  sku_name                    = var.key_vault_sku_name
  purge_protection_enabled    = local.is_prod
  soft_delete_retention_days  = var.soft_delete_retention_days
  private_endpoint_subnet_id  = module.network.subnet_ids["data"]
  private_dns_zone_id         = azurerm_private_dns_zone.this["key_vault"].id
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  enable_cmk                  = var.enable_customer_managed_keys
  tags                        = local.tags
}

# Azure Cosmos DB uses a fixed, well-known first-party service principal (same
# application ID in every Azure AD tenant) to wrap/unwrap its CMK.
data "azuread_service_principal" "cosmosdb" {
  count     = var.enable_customer_managed_keys ? 1 : 0
  client_id = "a232010e-820c-4083-83bb-3ace5fc29d0b"
}

resource "azurerm_role_assignment" "cosmos_cmk_access" {
  count                = var.enable_customer_managed_keys ? 1 : 0
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = data.azuread_service_principal.cosmosdb[0].object_id
}

resource "azurerm_role_assignment" "mysql_cmk_access" {
  count                = var.enable_customer_managed_keys ? 1 : 0
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = module.identity.data_cmk_identity_principal_id
}

module "defender" {
  count  = var.enable_defender_for_cloud ? 1 : 0
  source = "./modules/defender"
}
