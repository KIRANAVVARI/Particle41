output "public_ip_address" {
  description = "The public IP address of the Application Gateway (Load Balancer)."
  value       = azurerm_public_ip.appgw_public_ip.ip_address
}

output "service_url" {
  description = "The public URL to access the SimpleTimeService."
  value       = "http://${azurerm_public_ip.appgw_public_ip.ip_address}"
}

output "resource_group_name" {
  description = "The name of the resource group created."
  value       = azurerm_resource_group.rg.name
}