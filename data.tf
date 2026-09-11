module "mysql" {
  source = "./modules/mysql"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  administrator_login    = var.mysql_admin_username
  administrator_password = module.keyvault.mysql_admin_password

  sku_name              = var.mysql_sku_name
  storage_gb            = var.mysql_storage_gb
  ha_enabled            = var.mysql_ha_enabled && local.is_prod
  geo_redundant_backup_enabled = local.is_prod

  delegated_subnet_id = module.network.subnet_ids["mysql"]
  private_dns_zone_id = azurerm_private_dns_zone.this["mysql"].id

  enable_cmk           = var.enable_customer_managed_keys
  cmk_identity_id       = var.enable_customer_managed_keys ? module.identity.data_cmk_identity_id : null
  cmk_key_vault_key_id  = var.enable_customer_managed_keys ? module.keyvault.cmk_key_versionless_id : null

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this, azurerm_role_assignment.mysql_cmk_access]
}

module "cosmosdb" {
  source = "./modules/cosmosdb"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  consistency_level  = var.cosmosdb_consistency_level
  zone_redundant     = local.is_prod
  failover_locations = var.cosmosdb_failover_locations

  private_endpoint_subnet_id = module.network.subnet_ids["data"]
  private_dns_zone_id        = azurerm_private_dns_zone.this["cosmos"].id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags

  enable_cmk           = var.enable_customer_managed_keys
  cmk_key_vault_key_id = var.enable_customer_managed_keys ? module.keyvault.cmk_key_versionless_id : null

  depends_on = [azurerm_role_assignment.cosmos_cmk_access]
}

module "redis" {
  source = "./modules/redis"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  sku_name = var.redis_sku_name
  capacity = var.redis_capacity
  zones    = local.is_prod ? var.redis_zones : []

  private_endpoint_subnet_id = module.network.subnet_ids["data"]
  private_dns_zone_id        = azurerm_private_dns_zone.this["redis"].id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

module "storage" {
  source = "./modules/storage"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  replication_type           = local.is_prod ? "GZRS" : "LRS"
  private_endpoint_subnet_id = module.network.subnet_ids["data"]
  private_dns_zone_id        = azurerm_private_dns_zone.this["blob"].id

  workload_identity_principal_id = module.identity.workload_identity_principal_id
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  tags                            = local.tags

  enable_cmk   = var.enable_customer_managed_keys
  key_vault_id = var.enable_customer_managed_keys ? module.keyvault.key_vault_id : null
  cmk_key_name = var.enable_customer_managed_keys ? module.keyvault.cmk_key_name : null
}

module "managed_disk" {
  source = "./modules/managed-disk"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  disks                   = var.managed_disks
  disk_encryption_set_id  = var.enable_customer_managed_keys ? module.keyvault.disk_encryption_set_id : null
  tags                    = local.tags
}
