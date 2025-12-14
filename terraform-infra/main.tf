############################
# Resource Group
############################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name_infra
  location = var.location
}

############################
# Virtual Network
############################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

############################
# Container Apps Subnet
# MUST be /23 and delegated
############################
resource "azurerm_subnet" "containerapps" {
  name                 = var.private1_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private1_subnet_address_space

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet" "appgw" {
  name                 = var.public1_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public1_subnet_address_space
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet" "private2" {
  name                 = var.private2_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private2_subnet_address_space

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet" "public2" {
  name                 = var.public2_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public2_subnet_address_space
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

############################
# Log Analytics Workspace
############################
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################
# Container App Environment
############################
resource "azurerm_container_app_environment" "cae" {
  name                       = var.container_app_environment_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id   = azurerm_subnet.containerapps.id
  depends_on = [
    azurerm_subnet.containerapps
  ]
}


############################
# Container App
############################
resource "azurerm_container_app" "app" {
  name                         = var.container_app_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = var.container_app_name
      image  = "${var.acr_login_server}/${var.image_name}"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
############################
# Application Gateway
############################
resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }
  probe {
    name                                      = "aca-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 120
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
}
  backend_address_pool {
    name  = "aca-backend"
    fqdns = [
      azurerm_container_app.app.latest_revision_fqdn
    ]
  }

  backend_http_settings {
    name                  = "http-setting"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 120
    pick_host_name_from_backend_address = true
    cookie_based_affinity               = "Enabled"
    probe_name                          = "aca-probe"
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                 = "Basic"
    http_listener_name        = "listener"
    backend_address_pool_name = "aca-backend"
    backend_http_settings_name = "http-setting"
    priority                   = 10
  }
}
