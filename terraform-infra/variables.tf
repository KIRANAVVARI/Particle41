variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "acr_login_server" {
  description = "ACR login server"
  type        = string
}

variable "image_name" {
  description = "Container image name with tag"
  type        = string
}

variable "container_port" {
  description = "Port exposed by container"
  type        = number
  default     = 8080
}

variable "rg_name_infra" {
  type        = string
  description = "Resource group for infrastructure" 
}

variable "vnet_name" {
  type        = string
  description = "Virtual Network name for infrastructure" 
}

variable "private1_subnet_name" {
  type        = string
  description = "subnet name for infrastructure (private1)" 
}

variable "private2_subnet_name" {
  type        = string
  description = "subnet name for infrastructure (private2)" 
}

variable "public1_subnet_name" {
  type        = string
  description = "subnet name for infrastructure (public1)" 
}

variable "public2_subnet_name" {
  type        = string
  description = "subnet name for infrastructure (public2)" 
}

variable "vnet_address_space"{
  type       = list(string)
  description = "address space for VNET"
}

variable "private1_subnet_address_space"{
  type       = list(string)
  description = "address space for subnet private1"
}

variable "private2_subnet_address_space"{
  type       = list(string)
  description = "address space for subnet private2"
}

variable "public1_subnet_address_space"{
  type       = list(string)
  description = "address space for subnet public1"
}

variable "public2_subnet_address_space"{
  type       = list(string)
  description = "address space for subnet public2"
}

variable "container_app_environment_name" {
  type     = string
  description = "name of the container app enviornment"
}

variable "container_app_name" {
  type     = string
  description = "name of the container app"
}

variable "log_analytics_name" {
  type     = string
  description = "name of the log analytics workspace"
}

variable "app_gateway_name" {
  type     = string
  description = "name of the application gateway"
}