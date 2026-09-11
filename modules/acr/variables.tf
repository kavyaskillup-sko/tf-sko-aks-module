variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "zone_redundancy_enabled" {
  type    = bool
  default = true
}

variable "untagged_retention_days" {
  type    = number
  default = 30
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "aks_kubelet_identity_principal_id" {
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
