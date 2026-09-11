# Production-grade private AKS cluster for Open edX workloads.
# - Private API server (no public endpoint) with Azure AD + Kubernetes RBAC
# - User-assigned control-plane and kubelet identities (no service principal secrets)
# - Azure CNI with network policy, zone-redundant system + user node pools
# - Key Vault secrets provider (CSI driver) and OIDC/workload identity enabled
# - Azure Policy add-on and Defender for Containers-ready diagnostics

resource "azurerm_kubernetes_cluster" "this" {
  name                              = "aks-${var.name_prefix}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = replace("aks-${var.name_prefix}", "-", "")
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sku_tier
  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = var.private_cluster_enabled ? var.private_dns_zone_id : null
  automatic_channel_upgrade         = "patch"
  http_application_routing_enabled = false
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  tags                              = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.aks_identity_id]
  }

  kubelet_identity {
    client_id                 = var.kubelet_identity_client_id
    object_id                 = var.kubelet_identity_principal_id
    user_assigned_identity_id = var.kubelet_identity_id
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    enable_auto_scaling          = true
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    os_disk_type                 = "Ephemeral"
    zones                        = var.system_node_pool.availability_zones
    vnet_subnet_id                = var.subnet_id
    only_critical_addons_enabled = true
    max_pods                     = 60
    upgrade_settings {
      max_surge = "33%"
    }
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
    outbound_type        = "userDefinedRouting"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  azure_policy_enabled = true

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
  }

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = substr(each.key, 0, 12)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  enable_auto_scaling    = true
  min_count              = each.value.min_count
  max_count              = each.value.max_count
  os_disk_size_gb        = each.value.os_disk_size_gb
  os_disk_type           = "Ephemeral"
  zones                  = each.value.availability_zones
  vnet_subnet_id          = var.subnet_id
  mode                   = try(each.value.mode, "User")
  node_labels             = try(each.value.node_labels, {})
  node_taints             = try(each.value.node_taints, [])
  max_pods                = 60
  tags                    = var.tags
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_role_assignment" "workload_identity_keyvault" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_kubernetes_cluster.this.name}"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }
  enabled_log {
    category = "kube-audit"
  }
  enabled_log {
    category = "kube-controller-manager"
  }
  enabled_log {
    category = "guard"
  }
  metric {
    category = "AllMetrics"
  }
}
