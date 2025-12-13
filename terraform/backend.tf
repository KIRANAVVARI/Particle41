terraform {
  backend "azurerm" {
    # Replace these placeholders with the details of your existing storage account
    resource_group_name  = "tfstate-backend-rg"        # The RG where your storage account lives
    storage_account_name = "tfstatebackendsa1" # The name of your existing storage account
    container_name       = "tfstate"              # The container you created in step 1
    key                  = "timeservice.tfstate"  # The name of the state file blob
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}