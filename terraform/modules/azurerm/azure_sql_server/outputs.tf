output "id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "fully_qualified_domain_name" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}
