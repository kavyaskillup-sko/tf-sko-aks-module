module "acr" {
  source = "./modules/acr"

  name_prefix                       = local.name_prefix
  location                          = var.location
  resource_group_name               = azurerm_resource_group.this.name
  zone_redundancy_enabled           = local.is_prod
  private_endpoint_subnet_id        = module.network.subnet_ids["data"]
  private_dns_zone_id               = azurerm_private_dns_zone.this["acr"].id
  aks_kubelet_identity_principal_id = module.identity.kubelet_identity_principal_id
  log_analytics_workspace_id        = module.monitoring.log_analytics_workspace_id
  tags                              = local.tags
}

module "aks" {
  source = "./modules/aks"

  name_prefix          = local.name_prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  tenant_id            = data.azurerm_client_config.current.tenant_id
  kubernetes_version   = var.kubernetes_version
  sku_tier             = local.is_prod ? "Standard" : "Free"
  private_cluster_enabled = var.aks_private_cluster_enabled
  authorized_ip_ranges = var.authorized_ip_ranges
  subnet_id            = module.network.subnet_ids["aks"]

  aks_identity_id                = module.identity.aks_identity_id
  kubelet_identity_id            = module.identity.kubelet_identity_id
  kubelet_identity_principal_id  = module.identity.kubelet_identity_principal_id
  kubelet_identity_client_id     = module.identity.kubelet_identity_client_id
  workload_identity_principal_id = module.identity.workload_identity_principal_id

  key_vault_id               = module.keyvault.key_vault_id
  admin_group_object_ids     = var.aks_admin_group_object_ids
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  system_node_pool = var.aks_system_node_pool
  user_node_pools  = var.aks_user_node_pools

  tags = local.tags

  depends_on = [module.route_table]
}
