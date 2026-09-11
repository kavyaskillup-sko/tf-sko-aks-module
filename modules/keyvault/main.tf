# Azure Key Vault: RBAC-authorized, no public network access, private
# endpoint only, soft-delete + purge protection enabled for production.

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "kv-${substr(replace(var.name_prefix, "-", ""), 0, 17)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  enable_rbac_authorization      = true
  purge_protection_enabled       = var.purge_protection_enabled
  soft_delete_retention_days     = var.soft_delete_retention_days
  public_network_access_enabled  = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-${var.name_prefix}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_key_vault.this.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

# Auto-generated MySQL admin password, stored securely — never in state as a
# plain variable and never printed in outputs.
resource "random_password" "mysql_admin" {
  length      = 32
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin.result
  key_vault_id = azurerm_key_vault.this.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

# Customer-managed key for at-rest encryption of Storage/MySQL/Cosmos DB and
# a Disk Encryption Set for any standalone managed disks.
resource "azurerm_key_vault_key" "cmk" {
  count        = var.enable_cmk ? 1 : 0
  name         = "cmk-${var.name_prefix}"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  rotation_policy {
    expire_after         = "P1Y"
    notify_before_expiry = "P30D"

    automatic {
      time_before_expiry = "P30D"
    }
  }

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_disk_encryption_set" "cmk" {
  count               = var.enable_cmk ? 1 : 0
  name                = "des-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_key_id    = azurerm_key_vault_key.cmk[0].versionless_id
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Grant the Disk Encryption Set's identity permission to wrap/unwrap with the CMK.
resource "azurerm_role_assignment" "des_key_access" {
  count                = var.enable_cmk ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.cmk[0].identity[0].principal_id
}

