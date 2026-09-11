output "aks_identity_id" {
  value = azurerm_user_assigned_identity.aks.id
}

output "aks_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks.principal_id
}

output "kubelet_identity_id" {
  value = azurerm_user_assigned_identity.aks_kubelet.id
}

output "kubelet_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_kubelet.principal_id
}

output "kubelet_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_kubelet.client_id
}

output "workload_identity_id" {
  value = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "data_cmk_identity_id" {
  value = azurerm_user_assigned_identity.data_cmk.id
}

output "data_cmk_identity_principal_id" {
  value = azurerm_user_assigned_identity.data_cmk.principal_id
}

