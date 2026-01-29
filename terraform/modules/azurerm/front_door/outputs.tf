output "id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "endpoint_hostname" {
  description = "Hostname of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "endpoint_id" {
  description = "ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.id
}

output "profile_id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}
