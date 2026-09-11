# Reusable Network Security Group with explicit least-privilege rules.
# Callers pass in only the rules they need; a default deny-all inbound rule
# is always appended with the lowest priority to enforce least privilege.

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}-${var.subnet_key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "custom" {
  for_each = { for r in var.security_rules : r.name => r }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Explicit deny-all inbound as a safety net (defense in depth beyond Azure defaults).
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                         = "DenyAllInbound"
  priority                     = 4096
  direction                    = "Inbound"
  access                       = "Deny"
  protocol                     = "*"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefix         = "*"
  destination_address_prefix    = "*"
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_network_security_group.this.name}"
  target_resource_id         = azurerm_network_security_group.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
