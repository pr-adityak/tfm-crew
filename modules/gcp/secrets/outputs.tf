output "secret_id" {
  description = "ID of the database credentials secret"
  value       = google_secret_manager_secret.database_credentials.secret_id
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = google_secret_manager_secret.database_credentials.secret_id
}
