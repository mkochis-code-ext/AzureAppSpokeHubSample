locals {
  resource_group_name  = "rg-${var.workload}-${var.environment_prefix}-${var.suffix}"
  actual_data_location = var.data_location != "" ? var.data_location : var.location
}

# Resource Group
module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# ============================================================
# Hub-and-Spoke Virtual Network Architecture
# ============================================================

# DMZ Virtual Network (for Front Door Private Link)
module "vnet_dmz" {
  source = "../modules/azurerm/virtual_network"

  name                = "vnet-dmz-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.dmz_vnet_address_space]
  tags                = var.tags
}

# Hub Virtual Network (Central connectivity hub)
module "vnet_hub" {
  source = "../modules/azurerm/virtual_network"

  name                = "vnet-hub-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.hub_vnet_address_space]
  tags                = var.tags
}

# Spoke Virtual Network (for App Service)
module "vnet_spoke_app" {
  source = "../modules/azurerm/virtual_network"

  name                = "vnet-spoke-app-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.spoke_app_vnet_address_space]
  tags                = var.tags
}

# Spoke Virtual Network (for Data - SQL Database)
module "vnet_spoke_data" {
  source = "../modules/azurerm/virtual_network"

  name                = "vnet-spoke-data-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.spoke_data_vnet_address_space]
  tags                = var.tags
}

# ============================================================
# VNet Peerings (Hub-and-Spoke)
# ============================================================

# Peering: DMZ -> Hub
module "peering_dmz_to_hub" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-dmz-to-hub"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_dmz.name
  remote_virtual_network_id = module.vnet_hub.id
  allow_forwarded_traffic   = true
}

# Peering: Hub -> DMZ
module "peering_hub_to_dmz" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-hub-to-dmz"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_dmz.id
  allow_forwarded_traffic   = true
}

# Peering: Spoke (App) -> Hub
module "peering_spoke_app_to_hub" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-spoke-app-to-hub"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_spoke_app.name
  remote_virtual_network_id = module.vnet_hub.id
  allow_forwarded_traffic   = true
}

# Peering: Hub -> Spoke (App)
module "peering_hub_to_spoke_app" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-hub-to-spoke-app"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_spoke_app.id
  allow_forwarded_traffic   = true
}

# Peering: Spoke (Data) -> Hub
module "peering_spoke_data_to_hub" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-spoke-data-to-hub"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_spoke_data.name
  remote_virtual_network_id = module.vnet_hub.id
  allow_forwarded_traffic   = true
}

# Peering: Hub -> Spoke (Data)
module "peering_hub_to_spoke_data" {
  source = "../modules/azurerm/vnet_peering"

  name                      = "peer-hub-to-spoke-data"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_spoke_data.id
  allow_forwarded_traffic   = true
}

# ============================================================
# Azure Firewall for Hub-and-Spoke routing
# ============================================================

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Public IP for Azure Firewall Management
resource "azurerm_public_ip" "firewall_mgmt" {
  name                = "pip-firewall-mgmt-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Firewall subnet (must be named AzureFirewallSubnet)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_hub.name
  address_prefixes     = [var.hub_firewall_subnet_address_prefix]
}

# Firewall management subnet (must be named AzureFirewallManagementSubnet)
resource "azurerm_subnet" "firewall_mgmt" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_hub.name
  address_prefixes     = [var.hub_firewall_mgmt_subnet_address_prefix]
}

# Azure Firewall (Basic SKU for cost efficiency)
resource "azurerm_firewall" "hub" {
  name                = "fw-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  management_ip_configuration {
    name                 = "management"
    subnet_id            = azurerm_subnet.firewall_mgmt.id
    public_ip_address_id = azurerm_public_ip.firewall_mgmt.id
  }
}

# Firewall Network Rule Collection for SQL traffic
resource "azurerm_firewall_network_rule_collection" "sql" {
  name                = "allow-sql"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = module.resource_group.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-spoke-app-to-spoke-data"
    source_addresses = [
      var.spoke_app_vnet_address_space
    ]
    destination_addresses = [
      var.spoke_data_vnet_address_space
    ]
    destination_ports = ["1433"]
    protocols         = ["TCP"]
  }
}

# Route Table for Spoke App to route to Spoke Data via Firewall
resource "azurerm_route_table" "spoke_app" {
  name                = "rt-spoke-app-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags

  route {
    name                   = "to-spoke-data"
    address_prefix         = var.spoke_data_vnet_address_space
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

# Route Table for Spoke Data to route to Spoke App via Firewall
resource "azurerm_route_table" "spoke_data" {
  name                = "rt-spoke-data-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags

  route {
    name                   = "to-spoke-app"
    address_prefix         = var.spoke_app_vnet_address_space
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

# Associate route table with App Integration subnet
resource "azurerm_subnet_route_table_association" "app_integration" {
  subnet_id      = module.subnet_app_integration.id
  route_table_id = azurerm_route_table.spoke_app.id
}

# Associate route table with Data Private Endpoint subnet
resource "azurerm_subnet_route_table_association" "data_pe" {
  subnet_id      = module.subnet_data_private_endpoints.id
  route_table_id = azurerm_route_table.spoke_data.id
}

# ============================================================
# Subnets
# ============================================================

# DMZ Subnets
module "subnet_dmz_frontdoor" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-frontdoor"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_dmz.name
  address_prefixes     = [var.dmz_frontdoor_subnet_address_prefix]
}

# Spoke App Subnets
module "subnet_app_integration" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-app-integration"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_spoke_app.name
  address_prefixes     = [var.app_subnet_address_prefix]
  
  delegation = {
    name = "delegation"
    service_delegation = {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

module "subnet_private_endpoints" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-private-endpoints"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_spoke_app.name
  address_prefixes     = [var.pe_subnet_address_prefix]
}

# Spoke Data Subnets
module "subnet_data_private_endpoints" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-data-pe"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet_spoke_data.name
  address_prefixes     = [var.data_pe_subnet_address_prefix]
}

# ============================================================
# Private DNS Zones
# ============================================================

# Private DNS Zone for App Service
module "private_dns_app" {
  source = "../modules/azurerm/private_dns"

  name                = "privatelink.azurewebsites.net"
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.vnet_hub.id
  tags                = var.tags
}

# Link Private DNS to DMZ VNet
resource "azurerm_private_dns_zone_virtual_network_link" "app_dmz" {
  name                  = "link-app-dmz"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.private_dns_app.name
  virtual_network_id    = module.vnet_dmz.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link Private DNS to Spoke App VNet
resource "azurerm_private_dns_zone_virtual_network_link" "app_spoke" {
  name                  = "link-app-spoke"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.private_dns_app.name
  virtual_network_id    = module.vnet_spoke_app.id
  registration_enabled  = false
  tags                  = var.tags
}

# Private DNS Zone for SQL Database
module "private_dns_sql" {
  source = "../modules/azurerm/private_dns"

  name                = "privatelink.database.windows.net"
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.vnet_hub.id
  tags                = var.tags
}

# Link Private DNS to DMZ VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dmz" {
  name                  = "link-sql-dmz"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.private_dns_sql.name
  virtual_network_id    = module.vnet_dmz.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link Private DNS to Spoke App VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke_app" {
  name                  = "link-sql-spoke-app"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.private_dns_sql.name
  virtual_network_id    = module.vnet_spoke_app.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link Private DNS to Spoke Data VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke_data" {
  name                  = "link-sql-spoke-data"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.private_dns_sql.name
  virtual_network_id    = module.vnet_spoke_data.id
  registration_enabled  = false
  tags                  = var.tags
}

# ============================================================
# Azure SQL Database
# ============================================================

# User Assigned Identity for App Service
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "id-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# SQL Server with Azure AD-only authentication
module "sql_server" {
  source = "../modules/azurerm/azure_sql_server"

  name                          = "sql-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  azuread_authentication_only   = true
  azuread_admin_login_username  = azurerm_user_assigned_identity.app_identity.name
  azuread_admin_object_id       = azurerm_user_assigned_identity.app_identity.principal_id
  public_network_access_enabled = false
  tags                          = var.tags
}

# SQL Database
module "sql_database" {
  source = "../modules/azurerm/azure_sql_database"

  name        = "sqldb-${var.workload}-${var.environment_prefix}"
  server_id   = module.sql_server.id
  max_size_gb = var.sql_database_max_size_gb
  sku_name    = var.sql_database_sku
  tags        = var.tags
}

# Private Endpoint for SQL Server
module "private_endpoint_sql" {
  source = "../modules/azurerm/private_endpoint"

  name                           = "pe-sql-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.subnet_data_private_endpoints.id
  private_connection_resource_id = module.sql_server.id
  subresource_names              = ["sqlServer"]
  private_dns_zone_ids           = [module.private_dns_sql.id]
  tags                           = var.tags
}

# ============================================================
# App Service
# ============================================================

# Private Endpoint for App Service
module "private_endpoint_app" {
  source = "../modules/azurerm/private_endpoint"

  name                           = "pe-app-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.subnet_private_endpoints.id
  private_connection_resource_id = module.app_service.id
  subresource_names              = ["sites"]
  private_dns_zone_ids           = [module.private_dns_app.id]
  tags                           = var.tags
}

# App Service
module "app_service" {
  source = "../modules/azurerm/app_service"

  name                       = "app-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  sku_name                   = var.app_service_sku
  virtual_network_subnet_id  = module.subnet_app_integration.id
  user_assigned_identity_id  = azurerm_user_assigned_identity.app_identity.id
  
  connection_strings = [
    {
      name  = "SqlDatabase"
      type  = "SQLAzure"
      value = "Server=tcp:${module.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${module.sql_database.name};Authentication=Active Directory Default;User Id=${azurerm_user_assigned_identity.app_identity.client_id};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    }
  ]

  app_settings = {
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.app_identity.client_id
  }

  tags                       = var.tags
}

# ============================================================
# Azure Front Door with WAF
# ============================================================

# WAF Policy for Front Door
module "waf_policy" {
  source = "../modules/azurerm/waf_policy"

  name                = "wafpolicy${var.workload}${var.environment_prefix}${var.suffix}"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  mode                = var.waf_mode
  tags                = var.tags
}

# Azure Front Door
module "front_door" {
  source = "../modules/azurerm/front_door"

  name                 = "fd-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name  = module.resource_group.name
  sku_name             = var.frontdoor_sku_name
  backend_hostname     = module.app_service.default_hostname
  backend_location     = module.resource_group.location
  backend_resource_id  = module.app_service.id
  health_probe_path    = var.frontdoor_health_probe_path
  waf_policy_id        = module.waf_policy.id
  tags                 = var.tags

  depends_on = [
    module.private_endpoint_app,
    module.peering_dmz_to_hub,
    module.peering_hub_to_dmz,
    module.peering_spoke_app_to_hub,
    module.peering_hub_to_spoke_app
  ]
}

# ============================================================
# Network Security Groups
# ============================================================

# Network Security Group for App Service Integration Subnet
module "nsg_app" {
  source = "../modules/azurerm/network_security_group"

  name                = "nsg-app-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.subnet_app_integration.id
  
  security_rules = [
    {
      name                       = "AllowFrontDoorInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureFrontDoor.Backend"
      destination_address_prefix = var.app_subnet_address_prefix
    },
    {
      name                       = "AllowVNetInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  ]
  
  tags = var.tags
}

# Network Security Group for Private Endpoints Subnet
module "nsg_private_endpoints" {
  source = "../modules/azurerm/network_security_group"

  name                = "nsg-pe-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.subnet_private_endpoints.id
  
  security_rules = [
    {
      name                       = "AllowVNetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  ]
  
  tags = var.tags
}
