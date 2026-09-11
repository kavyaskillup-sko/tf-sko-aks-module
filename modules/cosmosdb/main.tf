# Cosmos DB (used for Open edX forum/analytics workloads) — public network
# access disabled, private endpoint only, zone-redundant, encryption at rest
# (platform-managed or optional CMK), Azure AD local auth optional.

resource "azurerm_cosmosdb_account" "this" {
  name                          = "cosmos-${var.name_prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  public_network_access_enabled = false
  is_virtual_network_filter_enabled = true
  local_authentication_disabled = var.disable_local_auth
  key_vault_key_id               = var.enable_cmk ? var.cmk_key_vault_key_id : null

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = var.zone_redundant
  }

  dynamic "geo_location" {
    for_each = var.failover_locations
    content {
      location          = geo_location.value
      failover_priority = geo_location.key + 1
      zone_redundant    = var.zone_redundant
    }
  }

  backup {
    type                = "Continuous"
    tier                = "Continuous30Days"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-cosmos-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cosmos-${var.name_prefix}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_cosmosdb_account.this.name}"
  target_resource_id         = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_log {
    category = "ControlPlaneRequests"
  }
  metric {
    category = "AllMetrics"
  }
}
