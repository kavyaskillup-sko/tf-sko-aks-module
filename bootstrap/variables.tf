variable "resource_group_name" {
  type    = string
  default = "tfstate-rg"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (lowercase, 3-24 chars). Must match the value used in envs/*/backend.hcl."
  type        = string
}

variable "container_name" {
  type    = string
  default = "tfstate"
}

variable "allowed_ip_ranges" {
  description = "Public IP ranges (e.g. CI runners, office egress IP) allowed to reach the state storage account."
  type        = list(string)
  default     = []
}

variable "tags" {
  type = map(string)
  default = {
    Purpose   = "terraform-remote-state"
    ManagedBy = "Terraform"
  }
}
