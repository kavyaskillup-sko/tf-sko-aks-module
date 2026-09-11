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
  default = "Premium"
}

variable "capacity" {
  type    = number
  default = 1
}

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "backup_storage_connection_string" {
  description = "Optional storage account connection string for RDB backups."
  type        = string
  default     = null
  sensitive   = true
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

variable "tags" {
  type    = map(string)
  default = {}
}
