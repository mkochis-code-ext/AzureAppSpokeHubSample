output "id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "identity_principal_id" {
  description = "Principal ID of the App Service system-assigned managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "Tenant ID of the App Service system-assigned managed identity"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}
