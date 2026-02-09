output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.crewai_platform.cluster_configuration.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for GKE cluster API"
  value       = module.crewai_platform.cluster_configuration.cluster_endpoint
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = module.crewai_platform.cluster_configuration.cluster_location
}

output "database_ip" {
  description = "Private IP address of CloudSQL instance"
  value       = module.crewai_platform.database_configuration.private_ip_address
}

output "database_connection_name" {
  description = "Connection name for CloudSQL instance"
  value       = module.crewai_platform.database_configuration.connection_name
}

output "database_name" {
  description = "Name of the database"
  value       = module.crewai_platform.database_configuration.database_name
}

output "registry_uri" {
  description = "URI for Artifact Registry"
  value       = module.crewai_platform.repository_configuration.registry_uri
}

output "gcs_data_bucket" {
  description = "Name of the GCS data bucket"
  value       = module.crewai_platform.storage_configuration.data_bucket_name
}

output "gcs_logs_bucket" {
  description = "Name of the GCS logs bucket"
  value       = module.crewai_platform.storage_configuration.logs_bucket_name
}

output "workload_namespace" {
  description = "Kubernetes namespace for platform workloads"
  value       = var.platform_namespace
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.crewai_platform.cluster_configuration.cluster_name} --region ${module.crewai_platform.cluster_configuration.cluster_location} --project ${var.project_id}"
}
