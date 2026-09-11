output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_guid" {
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.critical.id
}
