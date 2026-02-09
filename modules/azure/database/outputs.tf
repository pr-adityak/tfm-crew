output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "administrator_login" {
  description = "Administrator login name"
  value       = var.administrator_login
}

output "replica_fqdns" {
  description = "FQDNs of read replica servers"
  value       = [for replica in azurerm_postgresql_flexible_server.replica : replica.fqdn]
}
