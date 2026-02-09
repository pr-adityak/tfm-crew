# Cluster Module - GKE Standard with Node Service Accounts

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# GKE Standard Cluster with default node pool
resource "google_container_cluster" "main" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  # Default node pool with 3 nodes
  initial_node_count = var.initial_node_count

  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.node_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Network configuration
  network    = var.network_id
  subnetwork = var.subnet_self_links[0]

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Control plane endpoint is public but restricted
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master authorized networks (kubectl access control)
  dynamic "master_authorized_networks_config" {
    for_each = length(var.cluster_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.cluster_authorized_networks
        content {
          cidr_block   = cidr_blocks.value
          display_name = "Authorized network ${cidr_blocks.key}"
        }
      }
    }
  }


  # Release channel for automatic upgrades
  release_channel {
    channel = "REGULAR"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "04:00"
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Deletion protection
  deletion_protection = false # Set to true for production
}

# Google Service Account for GKE nodes
resource "google_service_account" "node_sa" {
  account_id   = "crewai-node-sa"
  project      = var.project_id
  display_name = "CrewAI GKE Node Service Account"
  description  = "Service account attached to GKE nodes for CrewAI platform"
}

# Grant Secret Manager access to workload SA
resource "google_secret_manager_secret_iam_member" "workload_secret_accessor" {
  project   = var.project_id
  secret_id = var.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.node_sa.email}"
}

# Grant Cloud SQL Client role to workload SA
resource "google_project_iam_member" "workload_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.node_sa.email}"
}

# Grant Storage Object Admin on data bucket
resource "google_storage_bucket_iam_member" "workload_data_bucket" {
  bucket = var.data_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.node_sa.email}"
}

# Grant Storage Object Admin on logs bucket
resource "google_storage_bucket_iam_member" "workload_logs_bucket" {
  bucket = var.logs_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.node_sa.email}"
}

# Grant Artifact Registry writer on repository
resource "google_artifact_registry_repository_iam_member" "workload_repository_writer" {
  project    = var.project_id
  location   = var.region
  repository = var.artifact_repository_name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.node_sa.email}"
}

# Grant default node service account role (recommended by GCP for non-degraded operations)
resource "google_project_iam_member" "node_sa_default_node_service_account" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.node_sa.email}"
}
