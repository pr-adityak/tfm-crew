terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  backend "gcs" {
    bucket = "YOUR-UNIQUE-STATE-BUCKET-NAME" # Replace with your bucket name
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# Auto-detection of Terraform runner identity and network
# ============================================================================

# Get current GCP identity running Terraform
data "google_client_openid_userinfo" "current" {}

# Detect public IP of machine running Terraform
data "http" "terraform_runner_ip" {
  url = "https://checkip.amazonaws.com"

  lifecycle {
    # If IP detection fails, we'll handle it gracefully
    postcondition {
      condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}", chomp(self.response_body)))
      error_message = "Failed to detect valid public IP address"
    }
  }
}

locals {
  # Clean up the detected IP and format as CIDR
  terraform_runner_cidr = "${chomp(data.http.terraform_runner_ip.response_body)}/32"

  # Merge auto-detected values with user-provided ones
  all_authorized_networks = distinct(concat(
    [local.terraform_runner_cidr],
    var.cluster_authorized_networks
  ))
}

# ============================================================================
# Data sources for cluster authentication with proper dependencies
# ============================================================================

# Data source for cluster info - waits for cluster to exist
data "google_container_cluster" "cluster" {
  name     = module.crewai_platform.cluster_configuration.cluster_name
  location = module.crewai_platform.cluster_configuration.cluster_location

  # Critical: Wait for the platform module to complete before trying to read
  depends_on = [module.crewai_platform]
}

data "google_client_config" "default" {}

# Kubernetes provider for cluster add-ons
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

# ============================================================================
# CrewAI Platform Module
# This module encapsulates the complete CrewAI platform infrastructure
module "crewai_platform" {
  source = "../../modules/gcp/crewai-platform"

  # Core Configuration
  project_id = var.project_id
  region     = var.region

  # GCS Storage
  gcs_data_bucket_name = var.gcs_data_bucket_name
  gcs_logs_bucket_name = var.gcs_logs_bucket_name

  # Network Configuration (optional overrides)
  vpc_cidr   = var.vpc_cidr
  zone_count = var.zone_count

  # Cluster Configuration
  cluster_name                = var.cluster_name
  cluster_initial_node_count  = var.cluster_initial_node_count
  cluster_node_machine_type   = var.cluster_node_machine_type
  cluster_authorized_networks = local.all_authorized_networks # Now includes Terraform runner IP automatically

  # Database Configuration (optional overrides)
  db_instance_name      = var.db_instance_name
  db_instance_tier      = var.db_instance_tier
  reader_instance_count = var.reader_instance_count
  replica_zones         = var.replica_zones
}

# ============================================================================
# CrewAI Cluster Add-ons Module
# Creates database Kubernetes secret
module "crewai_cluster_addons" {
  source = "../../modules/gcp/cluster-addons"

  # Database connection
  db_host     = module.crewai_platform.database_configuration.private_ip_address
  db_port     = 5432
  db_name     = module.crewai_platform.database_configuration.database_name
  db_username = var.database_username
  db_password = module.crewai_platform.secrets_configuration.db_password

  # Optional overrides
  database_secret_name = var.database_secret_name
  platform_namespace   = var.platform_namespace

  # Ensure cluster exists before attempting to install add-ons
  depends_on = [module.crewai_platform]
}
# ============================================================================
