variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "sku_tier" {
  description = "Free, Standard (SLA-backed) or Premium (long-term support)."
  type        = string
  default     = "Standard"
}

variable "private_cluster_enabled" {
  type    = bool
  default = true
}

variable "private_dns_zone_id" {
  description = "Custom private DNS zone ID for the API server, or 'System' to let AKS manage it automatically."
  type        = string
  default     = "System"
}

variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}

variable "subnet_id" {
  type = string
}

variable "aks_identity_id" {
  type = string
}

variable "kubelet_identity_id" {
  type = string
}

variable "kubelet_identity_principal_id" {
  type = string
}

variable "kubelet_identity_client_id" {
  type = string
}

variable "workload_identity_principal_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "admin_group_object_ids" {
  type    = list(string)
  default = []
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "system_node_pool" {
  type = object({
    vm_size            = string
    min_count          = number
    max_count          = number
    availability_zones = list(string)
    os_disk_size_gb    = number
  })
}

variable "user_node_pools" {
  type = map(object({
    vm_size            = string
    min_count          = number
    max_count          = number
    availability_zones = list(string)
    os_disk_size_gb    = number
    node_labels        = optional(map(string), {})
    node_taints        = optional(list(string), [])
    mode               = optional(string, "User")
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
