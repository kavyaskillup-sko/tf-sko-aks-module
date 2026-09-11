# Subscription Activity Log -> Log Analytics, for full control-plane audit
# trail (who created/modified/deleted resources) alongside per-resource
# diagnostic logs. Named per environment stack so multiple envs in the same
# subscription can each ship activity logs without colliding (max 5 settings).

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name               = "diag-activitylog-${local.name_prefix}"
  target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "ServiceHealth" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Recommendation" }
  enabled_log { category = "Policy" }
  enabled_log { category = "Autoscale" }
  enabled_log { category = "ResourceHealth" }
}
