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
