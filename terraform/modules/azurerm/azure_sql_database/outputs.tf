output "id" {
  description = "ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
}

output "name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}
