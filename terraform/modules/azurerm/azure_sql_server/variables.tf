variable "name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "administrator_login" {
  description = "Administrator login for SQL Server"
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  default     = null
}

variable "azuread_authentication_only" {
  description = "Enable Azure AD-only authentication"
  type        = bool
  default     = true
}

variable "azuread_admin_login_username" {
  description = "Azure AD admin login username"
  type        = string
  default     = null
}

variable "azuread_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
  default     = null
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
