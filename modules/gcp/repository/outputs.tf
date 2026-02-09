output "repository_name" {
  description = "Name of the Google Artifact Repository"
  value       = google_artifact_registry_repository.repository.name
}

output "repository_id" {
  description = "ID of the Google Artifact Repository"
  value       = google_artifact_registry_repository.repository.id
}

output "registry_uri" {
  description = "Registry URI of the Google Artifact Repository"
  value       = google_artifact_registry_repository.repository.registry_uri
}
