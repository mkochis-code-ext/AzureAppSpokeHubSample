variable "name" {
  description = "Name of the App Service"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the service plan"
  type        = string
}

variable "app_settings" {
  description = "App settings for the web app"
  type        = map(string)
  default     = {}
}

variable "virtual_network_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
}

variable "user_assigned_identity_id" {
  description = "ID of the User Assigned Identity"
  type        = string
  default     = null
}

variable "connection_strings" {
  description = "Connection strings for the web app"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
