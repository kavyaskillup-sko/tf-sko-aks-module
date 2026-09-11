# NSG flow logs + Traffic Analytics for the workload NSGs, sent to the
# platform storage account and Log Analytics workspace for network forensics.
# Azure auto-provisions a Network Watcher per region on first VNet creation;
# this looks it up rather than creating a duplicate.

data "azurerm_network_watcher" "this" {
  count               = var.enable_nsg_flow_logs ? 1 : 0
  name                = coalesce(var.network_watcher_name, "NetworkWatcher_${var.location}")
  resource_group_name = coalesce(var.network_watcher_resource_group_name, "NetworkWatcherRG")
}

locals {
  flow_log_nsgs = var.enable_nsg_flow_logs ? {
    aks   = module.nsg_aks.nsg_id
    data  = module.nsg_data.nsg_id
    mysql = module.nsg_mysql.nsg_id
  } : {}
}

resource "azurerm_network_watcher_flow_log" "this" {
  for_each = local.flow_log_nsgs

  name                 = "flowlog-${each.key}-${local.name_prefix}"
  network_watcher_name = data.azurerm_network_watcher.this[0].name
  resource_group_name  = data.azurerm_network_watcher.this[0].resource_group_name
  network_security_group_id = each.value
  storage_account_id    = module.storage.storage_account_id
  enabled               = true
  version               = 2

  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id           = module.monitoring.log_analytics_workspace_guid
    workspace_region       = var.location
    workspace_resource_id  = module.monitoring.log_analytics_workspace_id
    interval_in_minutes    = 10
  }

  tags = local.tags
}
