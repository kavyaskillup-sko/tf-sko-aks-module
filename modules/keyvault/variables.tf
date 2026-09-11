variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "premium"
}

variable "purge_protection_enabled" {
  type    = bool
  default = true
}

variable "soft_delete_retention_days" {
  type    = number
  default = 90
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "enable_cmk" {
  description = "Create a customer-managed key + Disk Encryption Set for wiring CMK encryption into Storage/MySQL/Cosmos DB/managed disks."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
