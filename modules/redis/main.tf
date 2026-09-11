# Azure Cache for Redis (Premium) — private endpoint only, TLS 1.2 minimum,
# no public network access, zone redundant, RDB persistence for durability.

resource "azurerm_redis_cache" "this" {
  name                          = "redis-${var.name_prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = "P"
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  zones                         = var.zones
  tags                          = var.tags

  redis_configuration {
    rdb_backup_enabled            = var.backup_storage_connection_string != null
    rdb_backup_frequency          = var.backup_storage_connection_string != null ? 60 : null
    rdb_backup_max_snapshot_count = var.backup_storage_connection_string != null ? 1 : null
    rdb_storage_connection_string = var.backup_storage_connection_string
    aof_backup_enabled            = false
  }
}

resource "azurerm_private_endpoint" "redis" {
  name                = "pe-redis-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-redis-${var.name_prefix}"
    private_connection_resource_id = azurerm_redis_cache.this.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "redis" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_redis_cache.this.name}"
  target_resource_id         = azurerm_redis_cache.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ConnectedClientList"
  }
  metric {
    category = "AllMetrics"
  }
}
