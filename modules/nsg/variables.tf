variable "name_prefix" {
  type = string
}

variable "subnet_key" {
  description = "Logical name of the subnet this NSG protects (used for naming)."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_rules" {
  description = "List of explicit least-privilege security rules. No rule should use '*'/0.0.0.0/0 for production ingress."
  type = list(object({
    name                          = string
    priority                      = number
    direction                     = string
    access                        = string
    protocol                      = string
    destination_port_ranges       = list(string)
    source_address_prefixes       = list(string)
    destination_address_prefixes  = list(string)
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
