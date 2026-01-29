resource "azurerm_mssql_server" "main" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.azuread_authentication_only ? null : var.administrator_login
  administrator_login_password  = var.azuread_authentication_only ? null : var.administrator_login_password
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  azuread_administrator {
    login_username              = var.azuread_admin_login_username != null ? var.azuread_admin_login_username : "SQL Admin"
    object_id                   = var.azuread_admin_object_id != null ? var.azuread_admin_object_id : data.azurerm_client_config.current.object_id
    azuread_authentication_only = var.azuread_authentication_only
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}
