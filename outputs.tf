output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "mysql_fqdn" {
  value = module.mysql.fqdn
}

output "redis_hostname" {
  value = module.redis.redis_hostname
}

output "cosmosdb_account_name" {
  value = module.cosmosdb.account_name
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "workload_identity_client_id" {
  description = "Client ID to reference from Kubernetes ServiceAccount annotations for Azure Workload Identity federation."
  value       = module.identity.workload_identity_client_id
}

output "cmk_key_vault_key_id" {
  description = "Versionless Key Vault key ID used for customer-managed key encryption, when enabled."
  value       = module.keyvault.cmk_key_versionless_id
}

output "disk_encryption_set_id" {
  value = module.keyvault.disk_encryption_set_id
}
