output "database_secret_name" {
  description = "Name of the database Kubernetes secret"
  value       = kubernetes_secret.database.metadata[0].name
}

output "database_secret_namespace" {
  description = "Namespace of the database Kubernetes secret"
  value       = kubernetes_secret.database.metadata[0].namespace
}
