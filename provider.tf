terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">4.0"
    }
    fortiflexvm = {
      source  = "fortinetdev/fortiflexvm"
      version = ">2.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "fortiflexvm" {
  # FortiFLEX VM provider configuration username and password are pulled from environment variables
  # export FORTIFLEX_ACCESS_USERNAME=""
  # export FORTIFLEX_ACCESS_PASSWORD=""
}