output "server_name" {
  description = "The name of the Postgresql server name."
  value       = azurerm_postgresql_server.main.name
}

output "server_fqdn" {
  description = "The name of the Postgresql server name."
  value       = azurerm_postgresql_server.main.fqdn
}

output "database_name" {
  description = "The name of the Postgresql database name."
  value       = azurerm_postgresql_database.main.name
}

output "server_login_name" {
  description = "The name of the Postgresql database name."
  value       = azurerm_postgresql_server.main.administrator_login
}