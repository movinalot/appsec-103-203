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
