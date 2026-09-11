resource_group_name  = "rg-tfstate-prod"
location             = "eastus2"
storage_account_name = "tfstateopenedxprod01"
container_name       = "tfstate"

# Restrict to your office/CI egress IP(s); never leave this empty in shared subscriptions.
allowed_ip_ranges = []

tags = {
  Purpose     = "terraform-remote-state"
  ManagedBy   = "Terraform"
  Environment = "prod"
}
