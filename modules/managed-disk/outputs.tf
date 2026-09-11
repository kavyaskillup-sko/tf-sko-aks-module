output "disk_ids" {
  value = { for k, v in azurerm_managed_disk.this : k => v.id }
}
