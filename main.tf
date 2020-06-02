# Configure the Microsoft Azure Provider
provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
  subscription_id = "1234567yourdatahere89"
  client_id       = "1234567yourdatahere89" 
  client_secret   = "1234567yourdatahere89"
  tenant_id       = "1234567yourdatahere89"

}

# Set up Azure keyvault
data "azurerm_key_vault" "azkv" {
  name                = "yourkeyvaultname"
  resource_group_name = "keyvaultrg"
}

#Grab the key for the local admin password for compute
data "azurerm_key_vault_secret" "localadmin" {
name = "yourkeyname"
key_vault_id = data.azurerm_key_vault.azkv.id
}

# Grab current region info to use for auto choosing a region
data "http" "geoipdata" {
  url = "http://www.geoplugin.net/json.gp"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}


# Set up terraform resource group
resource "azurerm_resource_group" "tfrg" {
        name = "tfrg"
        location = local.localregion
}
