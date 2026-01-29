output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# ============================================================
# App Service Outputs
# ============================================================

output "app_service_name" {
  description = "Name of the App Service"
  value       = module.app_service.name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = module.app_service.default_hostname
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = module.app_service.identity_principal_id
}

# ============================================================
# Front Door Outputs
# ============================================================

output "front_door_endpoint_hostname" {
  description = "Hostname of the Front Door endpoint"
  value       = module.front_door.endpoint_hostname
}

output "front_door_url" {
  description = "URL to access the application via Front Door"
  value       = "https://${module.front_door.endpoint_hostname}"
}

output "front_door_id" {
  description = "ID of the Front Door profile"
  value       = module.front_door.id
}

# ============================================================
# Virtual Network Outputs
# ============================================================

output "vnet_dmz_id" {
  description = "ID of the DMZ virtual network"
  value       = module.vnet_dmz.id
}

output "vnet_dmz_name" {
  description = "Name of the DMZ virtual network"
  value       = module.vnet_dmz.name
}

output "vnet_hub_id" {
  description = "ID of the Hub virtual network"
  value       = module.vnet_hub.id
}

output "vnet_hub_name" {
  description = "Name of the Hub virtual network"
  value       = module.vnet_hub.name
}

output "vnet_spoke_app_id" {
  description = "ID of the Spoke App virtual network"
  value       = module.vnet_spoke_app.id
}

output "vnet_spoke_app_name" {
  description = "Name of the Spoke App virtual network"
  value       = module.vnet_spoke_app.name
}
