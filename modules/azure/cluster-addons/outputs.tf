output "platform_namespace" {
  description = "Name of the platform namespace"
  value       = kubernetes_namespace.platform.metadata[0].name
}

output "database_secret_name" {
  description = "Name of the database secret"
  value       = kubernetes_secret.database.metadata[0].name
}

output "agic_identity_client_id" {
  description = "Client ID of the AGIC identity"
  value       = azurerm_user_assigned_identity.agic.client_id
}

output "agic_helm_release_status" {
  description = "Status of the AGIC Helm release"
  value       = helm_release.agic.status
}
