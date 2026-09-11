variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "retention_days" {
  type    = number
  default = 90
}

variable "alert_email_addresses" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
