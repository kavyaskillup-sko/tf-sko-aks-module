variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "replication_type" {
  type    = string
  default = "ZRS"
}

variable "soft_delete_retention_days" {
  type    = number
  default = 30
}

variable "containers" {
  type    = list(string)
  default = ["course-assets", "user-uploads", "grades-export"]
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "workload_identity_principal_id" {
  type = string
}

variable "enable_cmk" {
  type    = bool
  default = false
}

variable "key_vault_id" {
  description = "Key Vault resource ID holding the CMK. Required when enable_cmk is true."
  type        = string
  default     = null
}

variable "cmk_key_name" {
  description = "Name of the Key Vault key to use for CMK. Required when enable_cmk is true."
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
