# terraform.tfvars
# Replace these values with your actual configuration
location            = "West US 2"
resource_group_name = "particle41-devops-challenge"

# ACR Details from Task 1
acr_name       = "particle41"      # Your Azure Container Registry name
acr_image_name = "particle41" # The image name in your registry
acr_image_tag  = "latest"
aca_subnet_cidr   = "10.0.0.0/23" 
appgw_subnet_cidr = "10.0.2.0/24"