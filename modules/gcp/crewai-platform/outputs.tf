# Cluster Configuration Outputs
output "cluster_configuration" {
  description = "GKE cluster configuration details"
  value = {
    cluster_name     = module.cluster.cluster_name
    cluster_endpoint = module.cluster.cluster_endpoint
    cluster_location = module.cluster.cluster_location
  }
}

# Database Configuration Outputs
output "database_configuration" {
  description = "Cloud SQL database configuration details"
  value = {
    connection_name    = module.database.connection_name
    private_ip_address = module.database.private_ip_address
    database_name      = module.database.database_name
  }
}

# Storage Configuration Outputs
output "storage_configuration" {
  description = "GCS storage configuration details"
  value = {
    data_bucket_name = module.storage.data_bucket_name
    data_bucket_url  = module.storage.data_bucket_url
    logs_bucket_name = module.storage.logs_bucket_name
    logs_bucket_url  = module.storage.logs_bucket_url
  }
}

# Network Configuration Outputs
output "network_configuration" {
  description = "VPC network configuration details"
  value = {
    network_name = module.networking.network_name
    network_id   = module.networking.network_id
    subnet_names = module.networking.subnet_names
    region       = module.networking.region
  }
}

# Secrets Outputs
output "secrets_configuration" {
  description = "Secret Manager configuration details"
  value = {
    secret_name = module.secrets.secret_name
    db_password = module.database.db_password
  }
  sensitive = true
}

# Repository Configuration Outputs
output "repository_configuration" {
  description = "Artifact Registry configuration details"
  value = {
    registry_uri = module.repository.registry_uri
  }
}

# Consolidated Output for Easy Reference
output "platform_summary" {
  description = "Summary of key platform resources for quick reference"
  value = {
    region = var.region

    # Key endpoints
    database_connection = module.database.connection_name
    database_ip         = module.database.private_ip_address
    cluster_endpoint    = module.cluster.cluster_endpoint

    # Cluster information
    cluster_name     = module.cluster.cluster_name
    cluster_location = module.cluster.cluster_location

    # Node Service Account
    node_service_account_email = module.cluster.node_service_account_email

    # Network basics
    network_name = module.networking.network_name
    network_id   = module.networking.network_id

    # GCS buckets
    data_bucket = module.storage.data_bucket_name
    logs_bucket = module.storage.logs_bucket_name

    # Secrets
    secret_name = module.secrets.secret_name

    # Artifact Repository
    registry_uri = module.repository.registry_uri
  }
}
