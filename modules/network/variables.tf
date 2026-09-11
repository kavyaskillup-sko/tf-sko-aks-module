variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    prefixes          = list(string)
    delegation        = optional(string)
    service_endpoints = optional(list(string), [])
  }))
}

variable "enable_ddos_protection" {
  type    = bool
  default = false
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
