terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random suffix for uniqueness
resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
}

locals {
  suffix = random_string.suffix.result
  tags = merge(
    var.tags,
    {
      Environment = var.environment_prefix
      ManagedBy   = "Terraform"
    }
  )
}

# Call project module
module "project" {
  source = "../../project"

  environment_prefix = var.environment_prefix
  suffix             = local.suffix
  tags               = local.tags
  workload           = var.workload
  location           = var.location
  data_location      = var.data_location

  # Hub-and-Spoke Network configuration
  dmz_vnet_address_space                = var.dmz_vnet_address_space
  hub_vnet_address_space                = var.hub_vnet_address_space
  spoke_app_vnet_address_space          = var.spoke_app_vnet_address_space
  spoke_data_vnet_address_space         = var.spoke_data_vnet_address_space
  dmz_frontdoor_subnet_address_prefix   = var.dmz_frontdoor_subnet_address_prefix
  hub_firewall_subnet_address_prefix    = var.hub_firewall_subnet_address_prefix
  hub_firewall_mgmt_subnet_address_prefix = var.hub_firewall_mgmt_subnet_address_prefix
  app_subnet_address_prefix             = var.app_subnet_address_prefix
  pe_subnet_address_prefix              = var.pe_subnet_address_prefix
  data_pe_subnet_address_prefix         = var.data_pe_subnet_address_prefix

  # App Service configuration
  app_service_sku = var.app_service_sku

  # Azure SQL Database configuration
  sql_admin_username         = var.sql_admin_username
  sql_admin_password         = var.sql_admin_password
  sql_database_sku           = var.sql_database_sku
  sql_database_max_size_gb   = var.sql_database_max_size_gb

  # Front Door configuration
  frontdoor_sku_name          = var.frontdoor_sku_name
  frontdoor_health_probe_path = var.frontdoor_health_probe_path
  waf_mode                    = var.waf_mode
}
