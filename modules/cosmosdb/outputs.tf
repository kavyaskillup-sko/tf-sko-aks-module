output "account_id" {
  value = azurerm_cosmosdb_account.this.id
}

output "account_name" {
  value = azurerm_cosmosdb_account.this.name
}

output "connection_strings" {
  value = [
    azurerm_cosmosdb_account.this.primary_mongodb_connection_string,
    azurerm_cosmosdb_account.this.secondary_mongodb_connection_string,
  ]
  sensitive = true
}
