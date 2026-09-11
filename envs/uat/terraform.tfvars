resource_group_name = null # defaults to rg-openedx-uat-eus2

environment = "uat"
project     = "openedx"
location    = "eastus2"
owner       = "platform-engineering"
cost_center = "eng-uat"

vnet_address_space = ["10.20.0.0/16"]

subnets = {
  aks = {
    prefixes = ["10.20.0.0/22"]
  }
  data = {
    prefixes = ["10.20.4.0/24"]
  }
  mysql = {
    prefixes   = ["10.20.5.0/24"]
    delegation = "Microsoft.DBforMySQL/flexibleServers"
  }
  firewall = {
    prefixes = ["10.20.6.0/26"]
  }
}

enable_ddos_protection        = false

kubernetes_version          = "1.29"
aks_private_cluster_enabled = true

aks_system_node_pool = {
  vm_size            = "Standard_D4s_v5"
  min_count          = 2
  max_count          = 4
  availability_zones = ["1", "2", "3"]
  os_disk_size_gb    = 128
}

aks_user_node_pools = {
  workloads = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 2
    max_count          = 6
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 128
  }
}

aks_admin_group_object_ids = []

mysql_sku_name   = "GP_Standard_D2ds_v4"
mysql_storage_gb = 64
mysql_ha_enabled = true

redis_sku_name = "Premium"
redis_capacity = 1

cosmosdb_consistency_level = "Session"

log_retention_days         = 60
key_vault_sku_name         = "premium"
soft_delete_retention_days = 30

enable_customer_managed_keys = true
enable_nsg_flow_logs         = true
enable_defender_for_cloud    = false
