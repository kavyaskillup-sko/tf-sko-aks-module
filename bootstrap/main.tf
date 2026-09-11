# Bootstrap: creates the remote state backend (storage account + container)
# used by the root module's `azurerm` backend. Run this once per Azure
# subscription/environment tier BEFORE `terraform init` in the root module.
#
# This configuration intentionally uses local state - it creates the remote
# state store itself, so it cannot depend on it. After it's applied, treat
# this state file as an important artifact (store securely, e.g. in a
# restricted-access location) since it manages the state-storage account.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = var.location
  account_tier                     = "Standard"
  account_replication_type         = "GRS"
  min_tls_version                  = "TLS1_2"
  public_network_access_enabled    = true # restrict via network_rules below; disable entirely once CI runs from a private agent/VPN
  shared_access_key_enabled        = false
  https_traffic_only_enabled       = true
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

# Grant the current caller (and, in CI, the pipeline's managed identity/SP)
# access via RBAC rather than shared keys.
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "state_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
