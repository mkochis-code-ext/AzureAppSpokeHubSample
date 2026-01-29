variable "name" {
  description = "Name of the Front Door profile"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Front Door (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}

variable "backend_hostname" {
  description = "Hostname of the backend origin"
  type        = string
}

variable "backend_location" {
  description = "Location of the backend resource for Private Link"
  type        = string
}

variable "backend_resource_id" {
  description = "Resource ID of the backend for Private Link"
  type        = string
}

variable "health_probe_path" {
  description = "Path for health probe"
  type        = string
  default     = "/"
}

variable "waf_policy_id" {
  description = "Resource ID of the WAF policy"
  type        = string
}
