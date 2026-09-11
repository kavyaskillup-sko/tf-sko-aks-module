# User-assigned managed identities used across the platform instead of
# service principal credentials or storage of static secrets.

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "id-kubelet-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "data_cmk" {
  name                = "id-data-cmk-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Allows the AKS control-plane identity to manage the kubelet identity.
resource "azurerm_role_assignment" "aks_manage_kubelet_identity" {
  scope                = azurerm_user_assigned_identity.aks_kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Allows the AKS control-plane identity to manage the VNet (route tables, LB rules, private link)
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
