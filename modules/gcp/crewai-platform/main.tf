# CrewAI Platform Module
# This module encapsulates the complete CrewAI platform infrastructure for GCP

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Storage Module - GCS Buckets
module "storage" {
  source = "../storage"

  data_bucket_name = var.gcs_data_bucket_name
  logs_bucket_name = var.gcs_logs_bucket_name
  region           = var.region
}

# Networking Module - Creates complete VPC infrastructure
module "networking" {
  source = "../networking"

  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  vpc_cidr     = var.vpc_cidr
  zone_count   = var.zone_count
}

# Database Module - Cloud SQL PostgreSQL
module "database" {
  depends_on = [module.networking]

  source = "../database"

  project_id = var.project_id
  region     = var.region
  network_id = module.networking.network_id

  db_instance_name      = var.db_instance_name
  db_instance_tier      = var.db_instance_tier
  db_edition            = var.db_edition
  db_database_name      = var.db_database_name
  db_master_username    = var.db_master_username
  reader_instance_count = var.reader_instance_count
  replica_zones         = var.replica_zones
}

# Secrets Module - GCP Secret Manager for database credentials
module "secrets" {
  depends_on = [module.database]

  source = "../secrets"

  project_id = var.project_id

  # Database connection details from database module
  db_password = module.database.db_password
  db_host     = module.database.private_ip_address
  db_port     = 5432
  db_name     = module.database.database_name
  db_user     = var.db_master_username
}

module "repository" {
  source = "../repository"

  project_id    = var.project_id
  region        = var.region
  repository_id = var.artifact_repository_id
}

# Cluster Module - GKE Autopilot
module "cluster" {
  depends_on = [
    module.networking,
    module.database,
    module.storage,
    module.secrets,
    module.repository
  ]

  source = "../cluster"

  project_id         = var.project_id
  region             = var.region
  cluster_name       = var.cluster_name
  initial_node_count = var.cluster_initial_node_count
  node_machine_type  = var.cluster_node_machine_type

  # Note: kubernetes_version removed - GKE Autopilot auto-manages version
  network_id                  = module.networking.network_id
  subnet_self_links           = module.networking.subnet_self_links
  cluster_authorized_networks = var.cluster_authorized_networks

  # Integration with other modules
  secret_id                = module.secrets.secret_id
  data_bucket_name         = module.storage.data_bucket_name
  logs_bucket_name         = module.storage.logs_bucket_name
  artifact_repository_name = module.repository.repository_name
}
