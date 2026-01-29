output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.project.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.project.resource_group_id
}

# ============================================================
# App Service Outputs
# ============================================================

output "app_service_name" {
  description = "Name of the App Service"
  value       = module.project.app_service_name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service (internal use only)"
  value       = module.project.app_service_default_hostname
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = module.project.app_service_identity_principal_id
}

# ============================================================
# Front Door Outputs
# ============================================================

output "front_door_endpoint_hostname" {
  description = "Hostname of the Front Door endpoint"
  value       = module.project.front_door_endpoint_hostname
}

output "front_door_url" {
  description = "URL to access the application via Front Door (use this URL)"
  value       = module.project.front_door_url
}

output "front_door_id" {
  description = "ID of the Front Door profile"
  value       = module.project.front_door_id
}

# ============================================================
# Virtual Network Outputs
# ============================================================

output "vnet_dmz_id" {
  description = "ID of the DMZ virtual network"
  value       = module.project.vnet_dmz_id
}

output "vnet_dmz_name" {
  description = "Name of the DMZ virtual network"
  value       = module.project.vnet_dmz_name
}

output "vnet_hub_id" {
  description = "ID of the Hub virtual network"
  value       = module.project.vnet_hub_id
}

output "vnet_hub_name" {
  description = "Name of the Hub virtual network"
  value       = module.project.vnet_hub_name
}

output "vnet_spoke_app_id" {
  description = "ID of the Spoke App virtual network"
  value       = module.project.vnet_spoke_app_id
}

output "vnet_spoke_app_name" {
  description = "Name of the Spoke App virtual network"
  value       = module.project.vnet_spoke_app_name
}
