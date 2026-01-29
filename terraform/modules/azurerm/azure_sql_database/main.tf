resource "azurerm_mssql_database" "main" {
  name           = var.name
  server_id      = var.server_id
  collation      = var.collation
  max_size_gb    = var.max_size_gb
  sku_name       = var.sku_name
  zone_redundant = var.zone_redundant

  tags = var.tags
}
