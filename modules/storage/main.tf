# Storage account for Open edX media/course assets — public access disabled,
# private endpoint (blob) only, encryption at rest with Microsoft-managed or
# customer-managed keys, versioning + soft delete, TLS 1.2 minimum.

resource "azurerm_storage_account" "this" {
  name                     = substr(replace("st${var.name_prefix}", "-", ""), 0, 24)
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  cross_tenant_replication_enabled = false
  https_traffic_only_enabled       = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.name_prefix}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "workload_blob_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.workload_identity_principal_id
}

# CMK must be enabled only after the storage account's own identity can
# unwrap/wrap with the key, hence the separate resource + explicit depends_on.
resource "azurerm_role_assignment" "storage_cmk_access" {
  count                = var.enable_cmk ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.this.identity[0].principal_id
}

resource "azurerm_storage_account_customer_managed_key" "this" {
  count              = var.enable_cmk ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id
  key_vault_id        = var.key_vault_id
  key_name            = var.cmk_key_name

  depends_on = [azurerm_role_assignment.storage_cmk_access]
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_storage_account.this.name}"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  metric {
    category = "Transaction"
  }
}
