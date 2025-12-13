# --- 1. Core Networking (VNet and Subnets) ---

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
}

# Subnet for the Azure Container Apps Environment (Private Subnet)
# NOTE: ACA requires a /23 or larger subnet
resource "azurerm_subnet" "aca_private_subnet" {
  name                 = "aca-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aca_subnet_cidr]
}

# Subnet for the Application Gateway (Public Subnet)
resource "azurerm_subnet" "appgw_public_subnet" {
  name                 = "appgw-public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

# --- 2. Container Hosting (Azure Container Apps) ---

# Log Analytics Workspace for Container Apps Environment
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "${var.resource_group_name}-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

# Container App Environment (The 'Cluster' equivalent)
resource "azurerm_container_app_environment" "aca_env" {
  name                        = "${var.resource_group_name}-env"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.log_workspace.id
  infrastructure_subnet_id    = azurerm_subnet.aca_private_subnet.id
  # Makes the app accessible only from within the VNet (private ingress)
  internal_load_balancer_enabled = true 
}

# SimpleTimeService Container App
resource "azurerm_container_app" "simple_time_service" {
  name                         = "simple-time-service"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # The service is exposed internally, accessible via the VNet or Application Gateway
  ingress {
    external_enabled = false # Critical: Keep the service private to the VNet
    target_port      = 8080   # Port exposed by your container
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "simple-time-service-container"
      image  = "${var.acr_name}.azurecr.io/${var.acr_image_name}:${var.acr_image_tag}"
      cpu    = 0.5
      memory = "1.0Gi"
    }
  }
}

# --- 3. Public Load Balancer (Application Gateway) ---

# Public IP for the Application Gateway (External Load Balancer)
resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "appgw-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Web Application Firewall Policy (MANDATORY for WAF_v2 SKU)
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "${var.resource_group_name}-waf-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  managed_rules {
   managed_rule_set {
      type    = "OWASP"
      version = "3.2" 
    } 
  }

  # Set the policy mode (Prevention or Detection)
  policy_settings {
    enabled = true
    mode    = "Detection"
  }
}
# NSG for Application Gateway Subnet
# Corrected NSG for Application Gateway Subnet
resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "appgw-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # RULE 1: Allow required INBOUND traffic for Application Gateway V2 control plane
  security_rule {
    name                       = "AllowAppGwControlInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    # Source is the Azure GatewayManager service tag
    source_address_prefix      = "GatewayManager" 
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "65200-65535"
  }
  
  # RULE 2: Allow required OUTBOUND traffic for Application Gateway V2 control plane
  security_rule {
    name                       = "AllowAppGwControlOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    # Destination is the Internet/Azure Management Plane
    destination_address_prefix = "Internet" 
    destination_port_range     = "65200-65535"
  }
  
  # RULE 3: Allow inbound traffic from Internet to Application Gateway on port 80 (HTTP)
  security_rule {
    name                       = "AllowPublicHttpInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }
}

# The association resource remains correct:
resource "azurerm_subnet_network_security_group_association" "appgw_nsg_association" {
  subnet_id                 = azurerm_subnet.appgw_public_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}
# Application Gateway (the 'Load Balancer' equivalent)
resource "azurerm_application_gateway" "appgw" {
  name                = "${var.resource_group_name}-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  probe {
    name                = "simple-time-service-probe" # IMPORTANT: This name is referenced below
    protocol            = "Http"
    # Target the root path that your simple app exposes
    path                = "/" 
    # FQDN must match the Container App's internal FQDN
    host                = azurerm_container_app.simple_time_service.latest_revision_fqdn 
    
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    # Port is derived from the backend_http_settings when used inline
    port                = 8080
  }
  
  # FIX: Reference the WAF Policy ID (REQUIRED)
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf_policy.id

  sku {
    name = "WAF_v2" 
    tier = "WAF_v2"
  }
  ssl_policy {
    # Set the minimum supported TLS version to the modern standard
    min_protocol_version = "TLSv1_2" 
    
    # Use a pre-defined cipher suite setting that is modern and compliant.
    # The recommended policy is "AppGwSslPolicy20170401S" (Standard) or "AppGwSslPolicy20170401P" (Predefined)
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S" 
  }
  
  # FIX: Autoscale configuration (REQUIRED for WAF_v2)
  autoscale_configuration {
    min_capacity = 1 
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_public_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  # Backend Pool: Points to the internal, private FQDN of the Container App
  backend_address_pool {
    name  = "simple-time-service-pool"
    # FQDN is dynamic, sourced from the internal Container App Environment
    fqdns = [azurerm_container_app.simple_time_service.latest_revision_fqdn]
  }

  # HTTP Listener: Binds to the public IP on port 80
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # Backend HTTP Settings: Defines connection to the private backend
  backend_http_settings {
    name                                = "http-settings"
    port                                = 8080 
    protocol                            = "Http"
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 60
    # Crucial for routing to private FQDN of Container Apps
    pick_host_name_from_backend_address = true 
    probe_name                          = "simple-time-service-probe"
  }

  # Routing Rule: Public HTTP traffic (listener) -> Private Container App (pool)
  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "simple-time-service-pool"
    backend_http_settings_name = "http-settings"
    # FIX: Priority (REQUIRED)
    priority                   = 100 
  }
}