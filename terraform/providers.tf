provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  # The Azure provider configuration below is commented out to use environment variables instead.
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, and ARM_TENANT_ID

  # tenant_id       = var.tenant_id
  # subscription_id = var.subscription_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
}

provider "fortiflexvm" {
  # FortiFLEX VM provider configuration username and password are pulled from environment variables
  # FORTIFLEX_ACCESS_USERNAME=""
  # FORTIFLEX_ACCESS_PASSWORD=""
}
