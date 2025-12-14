output "container_app_url" {
  description = "Public URL of the Container App"
  value       = azurerm_container_app.app.ingress[0].fqdn
}