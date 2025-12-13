variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "West US 2" # Example default
}

variable "resource_group_name" {
  description = "The name of the Resource Group."
  type        = string
}

# Networking Variables
variable "vnet_cidr" {
  description = "The CIDR block for the Virtual Network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aca_subnet_cidr" {
  description = "The CIDR block for the private ACA Subnet (/23 or larger is required for ACA)."
  type        = string
  default     = "10.0.0.0/23" 
}

variable "appgw_subnet_cidr" {
  description = "The CIDR block for the public Application Gateway Subnet."
  type        = string
  default     = "10.0.2.0/24" 
}

# Container Registry Variables (from Task 1)
variable "acr_name" {
  description = "The name of your Azure Container Registry (e.g., particle41)."
  type        = string
}

variable "acr_image_name" {
  description = "The name of your container image in the ACR (e.g., simpletimeservice)."
  type        = string
}

variable "acr_image_tag" {
  description = "The tag of your container image."
  type        = string
  default     = "latest"
}