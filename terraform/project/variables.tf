variable "environment_prefix" {
  description = "Environment prefix"
  type        = string
}

variable "suffix" {
  description = "Random suffix for uniqueness"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "workload" {
  description = "Workload name"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "data_location" {
  description = "Azure region for data resources"
  type        = string
}

# ============================================================
# Network Configuration - Hub and Spoke
# ============================================================

variable "dmz_vnet_address_space" {
  description = "Address space for the DMZ virtual network"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for the Hub virtual network"
  type        = string
}

variable "spoke_app_vnet_address_space" {
  description = "Address space for the Spoke App virtual network"
  type        = string
}

variable "spoke_data_vnet_address_space" {
  description = "Address space for the Spoke Data virtual network"
  type        = string
}

variable "dmz_frontdoor_subnet_address_prefix" {
  description = "Address prefix for Front Door subnet in DMZ"
  type        = string
}

variable "hub_firewall_subnet_address_prefix" {
  description = "Address prefix for Firewall subnet in Hub"
  type        = string
}

variable "hub_firewall_mgmt_subnet_address_prefix" {
  description = "Address prefix for Firewall Management subnet in Hub"
  type        = string
}

variable "app_subnet_address_prefix" {
  description = "Address prefix for App Service integration subnet"
  type        = string
}

variable "pe_subnet_address_prefix" {
  description = "Address prefix for Private Endpoints subnet"
  type        = string
}

variable "data_pe_subnet_address_prefix" {
  description = "Address prefix for Data Private Endpoints subnet"
  type        = string
}

# ============================================================
# App Service Configuration
# ============================================================

variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
}

# ============================================================
# Azure Front Door Configuration
# ============================================================

variable "frontdoor_sku_name" {
  description = "SKU name for Front Door (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "frontdoor_health_probe_path" {
  description = "Health probe path for Front Door"
  type        = string
  default     = "/"
}

variable "waf_mode" {
  description = "Mode for the WAF policy (Prevention or Detection)"
  type        = string
  default     = "Prevention"
}

# ============================================================
# Azure SQL Database Configuration
# ============================================================

variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_database_sku" {
  description = "SKU for the SQL Database"
  type        = string
}

variable "sql_database_max_size_gb" {
  description = "Maximum size of the SQL Database in GB"
  type        = number
}
