provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  storage_use_azuread = true
}

provider "azuread" {}
