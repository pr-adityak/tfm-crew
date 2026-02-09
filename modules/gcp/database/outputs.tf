output "connection_name" {
  description = "Connection name for Cloud SQL instance (used for Cloud SQL Proxy)"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the created database"
  value       = google_sql_database.database.name
}

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "replica_connection_names" {
  description = "Connection names for read replicas"
  value       = google_sql_database_instance.read_replica[*].connection_name
}

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}
