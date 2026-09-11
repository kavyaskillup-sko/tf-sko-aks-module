resource_group_name = null # defaults to rg-openedx-prod-eus2

environment = "prod"
project     = "openedx"
location    = "eastus2"
owner       = "platform-engineering"
cost_center = "eng-prod"

vnet_address_space = ["10.30.0.0/16"]

subnets = {
  aks = {
    prefixes = ["10.30.0.0/21"]
  }
  data = {
    prefixes = ["10.30.8.0/24"]
  }
  mysql = {
    prefixes   = ["10.30.9.0/24"]
    delegation = "Microsoft.DBforMySQL/flexibleServers"
  }
  firewall = {
    prefixes = ["10.30.10.0/26"]
  }
}

enable_ddos_protection        = true

kubernetes_version          = "1.29"
aks_private_cluster_enabled = true

aks_system_node_pool = {
  vm_size            = "Standard_D4s_v5"
  min_count          = 3
  max_count          = 5
  availability_zones = ["1", "2", "3"]
  os_disk_size_gb    = 128
}

aks_user_node_pools = {
  lms = {
    vm_size            = "Standard_D8s_v5"
    min_count          = 3
    max_count          = 10
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 256
    node_labels        = { workload = "lms" }
  }
  cms = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 2
    max_count          = 6
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 256
    node_labels        = { workload = "cms" }
  }
  workers = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 2
    max_count          = 8
    availability_zones = ["1", "2", "3"]
    os_disk_size_gb    = 256
    node_labels        = { workload = "celery" }
  }
}

aks_admin_group_object_ids = []

mysql_sku_name   = "GP_Standard_D4ds_v4"
mysql_storage_gb = 256
mysql_ha_enabled = true

redis_sku_name = "Premium"
redis_capacity = 2
redis_zones     = ["1", "2", "3"]

cosmosdb_consistency_level = "Session"
cosmosdb_failover_locations = ["centralus"]

log_retention_days         = 180
key_vault_sku_name         = "premium"
soft_delete_retention_days = 90

enable_customer_managed_keys = true
enable_nsg_flow_logs         = true
enable_defender_for_cloud    = true
