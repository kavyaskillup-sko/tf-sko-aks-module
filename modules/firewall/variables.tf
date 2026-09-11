variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet', /26 or larger)."
  type        = string
}

variable "sku_tier" {
  type    = string
  default = "Standard"
}

variable "threat_intelligence_mode" {
  description = "Off, Alert, or Deny. Use Deny in production once false positives have been tuned out."
  type        = string
  default     = "Alert"
}

variable "idps_mode" {
  description = "Intrusion Detection and Prevention System mode (Off, Alert, Deny) - only applies when sku_tier is Premium."
  type        = string
  default     = "Alert"
}

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "network_rules" {
  description = "Network rules for required egress (e.g. NTP, DNS, package mirrors)."
  type = list(object({
    name                  = string
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = optional(list(string))
    destination_fqdns     = optional(list(string))
    destination_ports     = list(string)
  }))
  default = []
}

variable "application_rules" {
  description = "FQDN-based application rules for required egress (e.g. Microsoft/Ubuntu/pip/npm mirrors)."
  type = list(object({
    name              = string
    source_addresses  = list(string)
    destination_fqdns = list(string)
  }))
  default = []
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
