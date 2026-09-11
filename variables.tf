variable "environment" {
  description = "Deployment environment name (dev, uat, prod). Drives naming and sizing defaults."
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, uat, prod."
  }
}

variable "project" {
  description = "Short project/workload name used in resource naming (e.g. openedx)."
  type        = string
  default     = "openedx"
}

variable "location" {
  description = "Primary Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "secondary_location" {
  description = "Secondary Azure region used for geo-redundant/paired-region resources (backups, failover)."
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create for this environment."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to every resource in addition to the mandatory tagging strategy tags."
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner/team responsible for the environment, used for tagging and alerting."
  type        = string
  default     = "platform-engineering"
}

variable "cost_center" {
  description = "Cost center code used for tagging/chargeback."
  type        = string
  default     = "unassigned"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "vnet_address_space" {
  description = "Address space for the environment VNet."
  type        = list(string)
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. Key is the logical subnet name.
    prefixes: list of CIDR ranges
    delegation: optional service delegation (e.g. Microsoft.DBforMySQL/flexibleServers)
    service_endpoints: optional list of service endpoints
  EOT
  type = map(object({
    prefixes          = list(string)
    delegation        = optional(string)
    service_endpoints = optional(list(string), [])
  }))
}

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Network Protection plan on the VNet. Strongly recommended for production."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# AKS
# ---------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.29"
}

variable "aks_system_node_pool" {
  description = "Configuration for the AKS system node pool."
  type = object({
    vm_size             = string
    min_count           = number
    max_count           = number
    availability_zones  = list(string)
    os_disk_size_gb     = number
  })
  default = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 3
    max_count           = 5
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 128
  }
}

variable "aks_user_node_pools" {
  description = "Additional user node pools for Open edX workloads (e.g. lms, cms, workers)."
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

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin via Azure AD RBAC integration."
  type        = list(string)
  default     = []
}

variable "authorized_ip_ranges" {
  description = "Public CIDR ranges authorized to reach the AKS API server (used only if private_cluster is disabled)."
  type        = list(string)
  default     = []
}

variable "aks_private_cluster_enabled" {
  description = "Deploy AKS as a private cluster (no public API server endpoint). Must be true for production."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Data services
# ---------------------------------------------------------------------------
variable "mysql_sku_name" {
  description = "SKU for Azure Database for MySQL Flexible Server."
  type        = string
  default     = "GP_Standard_D2ds_v4"
}

variable "mysql_storage_gb" {
  description = "Storage size in GB for MySQL Flexible Server."
  type        = number
  default     = 128
}

variable "mysql_ha_enabled" {
  description = "Enable zone-redundant high availability for MySQL Flexible Server."
  type        = bool
  default     = true
}

variable "mysql_admin_username" {
  description = "Administrator login name for MySQL. Password is auto-generated and stored in Key Vault."
  type        = string
  default     = "openedxadmin"
}

variable "redis_sku_name" {
  description = "SKU name for Azure Cache for Redis (Basic, Standard, Premium)."
  type        = string
  default     = "Premium"
}

variable "redis_capacity" {
  description = "Capacity/size for the Redis SKU."
  type        = number
  default     = 1
}

variable "redis_zones" {
  description = "Availability zones for Redis Premium (zone redundancy)."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "cosmosdb_consistency_level" {
  description = "Default consistency level for the Cosmos DB account."
  type        = string
  default     = "Session"
}

variable "cosmosdb_failover_locations" {
  description = "List of Azure regions (in priority order) for Cosmos DB automatic failover, in addition to the primary location."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Storage / Key Vault
# ---------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Retention in days for Log Analytics workspace and diagnostic logs."
  type        = number
  default     = 90
}

variable "key_vault_sku_name" {
  description = "SKU for Azure Key Vault (standard or premium/HSM-backed)."
  type        = string
  default     = "premium"
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days for Key Vault and storage."
  type        = number
  default     = 90
}

variable "managed_disks" {
  description = "Standalone managed disks to provision (e.g. shared data volumes). Empty by default; opt in per environment."
  type = map(object({
    size_gb              = number
    storage_account_type = optional(string, "Premium_ZRS")
    zone                 = optional(string)
  }))
  default = {}
}

variable "enable_customer_managed_keys" {
  description = "Encrypt Storage, MySQL and Cosmos DB at rest with a Key Vault-backed customer-managed key instead of platform-managed keys."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Security posture
# ---------------------------------------------------------------------------
variable "enable_defender_for_cloud" {
  description = "Enable Microsoft Defender for Cloud pricing plans. This is a subscription-wide setting - enable it in exactly one environment stack per subscription to avoid conflicting applies."
  type        = bool
  default     = false
}

variable "security_alert_email_addresses" {
  description = "Email addresses notified by the security/critical action group."
  type        = list(string)
  default     = []
}

variable "enable_nsg_flow_logs" {
  description = "Enable NSG flow logs + Traffic Analytics for the workload NSGs."
  type        = bool
  default     = true
}

variable "network_watcher_name" {
  description = "Name of the (subscription auto-created) Network Watcher in this region. Defaults to the standard 'NetworkWatcher_<region>' name."
  type        = string
  default     = null
}

variable "network_watcher_resource_group_name" {
  description = "Resource group of the Network Watcher. Defaults to the standard 'NetworkWatcherRG'."
  type        = string
  default     = null
}
