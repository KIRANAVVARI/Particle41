############################
# Resource Group
############################
resource "azurerm_resource_group" "rg" {
  name     = "rg-particle41"
  location = var.location
}

############################
# Virtual Network
############################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-particle41"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

############################
# Container Apps Subnet
# MUST be /23 and delegated
############################
resource "azurerm_subnet" "containerapps" {
  name                 = "snet-containerapps"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "containerapps-delegation"

    service_delegation {
      name = "Microsoft.App/environments"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

############################
# Log Analytics
############################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-particle41"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################
# Container App Environment (PRIVATE)
############################
resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-particle41"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id   = azurerm_subnet.containerapps.id
}

############################
# Container App
############################
resource "azurerm_container_app" "app" {
  name                         = "simple-time-service"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = "simple-time-service"
      image  = "${var.acr_login_server}/${var.image_name}"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
