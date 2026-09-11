# Azure Database for MySQL Flexible Server — private access only (VNet
# injected), zone-redundant HA, encrypted at rest, TLS-enforced, AAD auth
# supported, automated backups with geo-redundancy for production.

resource "azurerm_mysql_flexible_server" "this" {
  name                = "mysql-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sku_name = var.sku_name
  version  = "8.0.21"

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  storage {
    size_gb           = var.storage_gb
    auto_grow_enabled = true
    iops              = var.storage_iops
  }

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  zone = var.zone

  dynamic "identity" {
    for_each = var.enable_cmk ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.cmk_identity_id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_cmk ? [1] : []
    content {
      key_vault_key_id                      = var.cmk_key_vault_key_id
      primary_user_assigned_identity_id     = var.cmk_identity_id
      geo_backup_key_vault_key_id           = var.geo_redundant_backup_enabled ? var.cmk_key_vault_key_id : null
      geo_backup_user_assigned_identity_id  = var.geo_redundant_backup_enabled ? var.cmk_identity_id : null
    }
  }

  dynamic "high_availability" {
    for_each = var.ha_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.standby_zone
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [zone] # Azure may rebalance zone placement.
  }
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "tls_version" {
  name                = "tls_version"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "TLSv1.2"
}

resource "azurerm_mysql_flexible_database" "openedx" {
  for_each            = toset(var.databases)
  name                = each.value
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_monitor_diagnostic_setting" "mysql" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_mysql_flexible_server.this.name}"
  target_resource_id         = azurerm_mysql_flexible_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "MySqlAuditLogs"
  }
  enabled_log {
    category = "MySqlSlowLogs"
  }
  metric {
    category = "AllMetrics"
  }
}
