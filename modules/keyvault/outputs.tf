output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "mysql_admin_password_secret_name" {
  value = azurerm_key_vault_secret.mysql_admin_password.name
}

output "mysql_admin_password" {
  value     = random_password.mysql_admin.result
  sensitive = true
}

output "cmk_key_id" {
  value = var.enable_cmk ? azurerm_key_vault_key.cmk[0].id : null
}

output "cmk_key_versionless_id" {
  value = var.enable_cmk ? azurerm_key_vault_key.cmk[0].versionless_id : null
}

output "cmk_key_name" {
  value = var.enable_cmk ? azurerm_key_vault_key.cmk[0].name : null
}

output "disk_encryption_set_id" {
  value = var.enable_cmk ? azurerm_disk_encryption_set.cmk[0].id : null
}
