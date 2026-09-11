# Standalone Azure Managed Disks — e.g. shared/backup data volumes that are
# not tied to a specific VM. Encrypted with the platform CMK/Disk Encryption
# Set when provided, zone-pinned for predictable attach latency.

resource "azurerm_managed_disk" "this" {
  for_each = var.disks

  name                 = "disk-${var.name_prefix}-${each.key}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb          = each.value.size_gb
  zone                  = each.value.zone
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags
}
