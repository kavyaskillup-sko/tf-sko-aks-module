variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "disks" {
  description = "Map of standalone managed disks to create. Empty by default - opt in per environment."
  type = map(object({
    size_gb              = number
    storage_account_type = optional(string, "Premium_ZRS")
    zone                 = optional(string)
  }))
  default = {}
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID for CMK-encrypted disks, or null for platform-managed encryption."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
