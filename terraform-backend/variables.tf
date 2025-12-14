variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "rg_name" {
  type        = string
  description = "Resource Group name for backend"
  default     = "backend-tfstate-rg"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for Terraform state"
  default     = "backendtfstatesa41"
}

variable "container_name" {
  type        = string
  description = "Storage container name for Terraform state"
  default     = "tfstate"
}
