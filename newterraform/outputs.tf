output "container_app_internal_fqdn" {
  value       = azurerm_container_app.app.latest_revision_fqdn
  description = "Internal Container App FQDN"
}
