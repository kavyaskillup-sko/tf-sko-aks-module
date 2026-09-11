resource_group_name = null # defaults to rg-openedx-dev-eus2

environment = "dev"
project     = "openedx"
location    = "eastus2"
owner       = "platform-engineering"
cost_center = "eng-dev"

vnet_address_space = ["10.10.0.0/16"]

subnets = {
  aks = {
    prefixes = ["10.10.0.0/22"]
  }
  data = {
    prefixes = ["10.10.4.0/24"]
  }
  mysql = {
    prefixes   = ["10.10.5.0/24"]
    delegation = "Microsoft.DBforMySQL/flexibleServers"
  }
  firewall = {
    prefixes = ["10.10.6.0/26"]
  }
}

enable_ddos_protection        = false

kubernetes_version          = "1.29"
aks_private_cluster_enabled = true

aks_system_node_pool = {
  vm_size            = "Standard_D2s_v5"
  min_count          = 1
  max_count          = 3
  availability_zones = ["1", "2", "3"]
  os_disk_size_gb    = 100
}

aks_user_node_pools = {
  workloads = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 1
    max_count          = 3
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 100
  }
}

aks_admin_group_object_ids = []

mysql_sku_name   = "B_Standard_B1ms"
mysql_storage_gb = 32
mysql_ha_enabled = false

redis_sku_name = "Standard"
redis_capacity = 1

cosmosdb_consistency_level = "Session"

log_retention_days         = 30
key_vault_sku_name         = "standard"
soft_delete_retention_days = 7

enable_customer_managed_keys = false
enable_nsg_flow_logs         = false
enable_defender_for_cloud    = false
