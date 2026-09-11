variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "storage_gb" {
  type    = number
  default = 128
}

variable "storage_iops" {
  type    = number
  default = 500
}

variable "backup_retention_days" {
  type    = number
  default = 35
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = true
}

variable "ha_enabled" {
  type    = bool
  default = true
}

variable "zone" {
  type    = string
  default = "1"
}

variable "standby_zone" {
  type    = string
  default = "2"
}

variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "databases" {
  type    = list(string)
  default = ["openedx", "openedx_notes", "openedx_ecommerce"]
}

variable "enable_cmk" {
  type    = bool
  default = false
}

variable "cmk_identity_id" {
  description = "User-assigned managed identity ID granted Key Vault Crypto Service Encryption User, used to unwrap the CMK. Required when enable_cmk is true."
  type        = string
  default     = null
}

variable "cmk_key_vault_key_id" {
  description = "Versioned or versionless Key Vault key ID for CMK encryption. Required when enable_cmk is true."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
