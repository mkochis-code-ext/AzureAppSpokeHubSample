variable "name" {
  description = "Name of the WAF policy"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU name for WAF policy (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "mode" {
  description = "Mode for the WAF policy (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
