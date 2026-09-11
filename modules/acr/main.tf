# Azure Container Registry: Premium SKU (required for private endpoints),
# public network access disabled, admin user disabled (pull is via AKS
# kubelet managed identity + AcrPull role), content trust + retention policy.

resource "azurerm_container_registry" "this" {
  name                          = replace("acr${var.name_prefix}", "-", "")
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  data_endpoint_enabled         = true
  quarantine_policy_enabled     = true

  network_rule_set {
    default_action = "Deny"
  }

  retention_policy {
    days    = var.untagged_retention_days
    enabled = true
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr-${var.name_prefix}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Grant the AKS kubelet identity permission to pull images (no static credentials).
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_principal_id
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_container_registry.this.name}"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }
  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }
  metric {
    category = "AllMetrics"
  }
}
