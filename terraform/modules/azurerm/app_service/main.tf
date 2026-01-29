resource "azurerm_service_plan" "main" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "main" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.main.id
  https_only                    = true
  virtual_network_subnet_id     = var.virtual_network_subnet_id
  public_network_access_enabled = false
  tags                          = var.tags

  site_config {
    always_on              = true
    ftps_state             = "Disabled"
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    vnet_route_all_enabled = true
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = merge({
    "WEBSITE_DNS_SERVER" = "168.63.129.16"
  }, var.app_settings)

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  identity {
    type         = var.user_assigned_identity_id != null ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : []
  }
}
