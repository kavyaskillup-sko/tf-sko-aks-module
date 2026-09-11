# Azure Firewall (Standard/Premium) providing centralized, least-privilege
# egress control for the hub. All spoke subnets route 0.0.0.0/0 here.

resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  name                = "fwpolicy-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_tier
  threat_intelligence_mode = var.threat_intelligence_mode
  tags                = var.tags

  dns {
    proxy_enabled = true
  }

  dynamic "intrusion_detection" {
    for_each = var.sku_tier == "Premium" ? [1] : []
    content {
      mode = var.idps_mode
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "network-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  network_rule_collection {
    name     = "allow-egress-required"
    priority = 100
    action   = "Allow"

    dynamic "rule" {
      for_each = var.network_rules
      content {
        name                  = rule.value.name
        protocols             = rule.value.protocols
        source_addresses      = rule.value.source_addresses
        destination_addresses = try(rule.value.destination_addresses, null)
        destination_fqdns     = try(rule.value.destination_fqdns, null)
        destination_ports     = rule.value.destination_ports
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "application-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 300

  application_rule_collection {
    name     = "allow-fqdn-required"
    priority = 100
    action   = "Allow"

    dynamic "rule" {
      for_each = var.application_rules
      content {
        name              = rule.value.name
        source_addresses  = rule.value.source_addresses
        destination_fqdns = rule.value.destination_fqdns

        protocols {
          type = "Https"
          port = 443
        }
      }
    }
  }
}

resource "azurerm_firewall" "this" {
  name                = "afw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = var.zones
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_firewall.this.name}"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  enabled_log {
    category = "AzureFirewallDnsProxy"
  }
  metric {
    category = "AllMetrics"
  }
}
