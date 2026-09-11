variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "consistency_level" {
  type    = string
  default = "Session"
}

variable "zone_redundant" {
  type    = bool
  default = true
}

variable "failover_locations" {
  type    = list(string)
  default = []
}

variable "disable_local_auth" {
  description = "Disable key-based auth in favor of Azure AD/managed identity (recommended for prod, but confirm driver/app support)."
  type        = bool
  default     = false
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
  type    = bool
  default = false
}

variable "cmk_key_vault_key_id" {
  description = "Versioned Key Vault key URI for CMK encryption. Required when enable_cmk is true; the Azure Cosmos DB service principal must already have wrap/unwrap access on the key."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
