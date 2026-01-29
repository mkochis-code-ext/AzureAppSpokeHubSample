output "id" {
  description = "ID of the WAF policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.id
}

output "name" {
  description = "Name of the WAF policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.name
}
