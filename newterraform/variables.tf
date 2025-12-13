variable "location" {
  description = "Azure region"
  default     = "West US"
}

variable "acr_login_server" {
  description = "ACR login server"
  default     = "particle41.azurecr.io"
}

variable "image_name" {
  description = "Container image"
  default     = "particle41:latest"
}
