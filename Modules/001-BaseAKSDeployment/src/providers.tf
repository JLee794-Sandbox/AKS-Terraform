terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }

  ## [Section 2.3] Example for Optional Backend Remote State Configuration
  # backend "azurerm" {
  #   resource_group_name  = "validation-rg"
  #   storage_account_name = "bootstrapsadev"
  #   container_name       = "tfstate"
  #   key                  = "lab01.tfstate"
  # }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}