# Private DNS zones for all private-endpoint-backed services, linked to the
# platform VNet so name resolution stays entirely inside the network.

locals {
  private_dns_zone_names = {
    key_vault = "privatelink.vaultcore.azure.net"
    acr       = "privatelink.azurecr.io"
    cosmos    = "privatelink.mongo.cosmos.azure.com"
    redis     = "privatelink.redis.cache.windows.net"
    blob      = "privatelink.blob.core.windows.net"
    mysql     = "privatelink.mysql.database.azure.com"
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zone_names
  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.private_dns_zone_names
  name                  = "link-${each.key}-${local.name_prefix}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = module.network.vnet_id
  registration_enabled  = false
  tags                  = local.tags
}
