# ========================================
# REQUIRED CONFIGURATION
# ========================================

variable "project_id" {
  description = "GCP project ID (e.g., my-crewai-project)"
  type        = string
}

variable "region" {
  description = "GCP region for deployment (e.g., us-central1, us-east1, europe-west1)"
  type        = string
}

variable "gcs_data_bucket_name" {
  description = "Globally unique GCS bucket name for application data"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-_]*[a-z0-9]$", var.gcs_data_bucket_name))
    error_message = "GCS bucket name must be valid (lowercase, numbers, hyphens, underscores only)"
  }
}

variable "gcs_logs_bucket_name" {
  description = "Globally unique GCS bucket name for centralized logs"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-_]*[a-z0-9]$", var.gcs_logs_bucket_name))
    error_message = "GCS bucket name must be valid (lowercase, numbers, hyphens, underscores only)"
  }
}

# ========================================
# ADVANCED CONFIGURATION (override defaults if needed)
# ========================================

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC (default: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }
}

variable "zone_count" {
  description = "Number of zones to use (default: 3, minimum 2 for HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.zone_count >= 2 && var.zone_count <= 3
    error_message = "Zone count must be between 2 and 3"
  }
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the GKE cluster (default: crewai-cluster)"
  type        = string
  default     = "crewai-cluster"
}

variable "cluster_initial_node_count" {
  description = "Number of nodes to start the GKE cluster with (default: 1)"
  type        = number
  default     = 1
}

variable "cluster_node_machine_type" {
  description = "Instance type to use for nodes (default: e2-standard-4)"
  type        = string
  default     = "e2-standard-4"
}

# Note: kubernetes_version removed - GKE Autopilot automatically manages version

variable "cluster_authorized_networks" {
  description = "List of CIDR blocks that can access the GKE cluster API endpoint (for kubectl access). Use YOUR_IP/32 for single IPs. Empty list = private-only access"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.cluster_authorized_networks :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All entries must be valid CIDR blocks (e.g., 203.0.113.25/32 for single IP)"
  }
}

# Database Configuration
variable "db_instance_name" {
  description = "Cloud SQL instance name (default: crewai-db)"
  type        = string
  default     = "crewai-db"
}

variable "db_instance_tier" {
  description = "Cloud SQL instance tier (default: db-custom-2-7680 - 2 vCPU, 7.5GB RAM)"
  type        = string
  default     = "db-custom-2-7680"
}

variable "reader_instance_count" {
  description = "Number of Cloud SQL read replica instances for high availability (default: 1)"
  type        = number
  default     = 1
}

variable "replica_zones" {
  description = "List of zones for read replica placement (e.g., ['europe-north1-a', 'europe-north1-b']). Replicas cycle through this list. If empty, GCP auto-selects zones."
  type        = list(string)
  default     = []
}

# Cluster Add-ons Configuration
variable "database_username" {
  description = "Database username (default: postgres)"
  type        = string
  default     = "postgres"
}

variable "database_secret_name" {
  description = "Name of the Kubernetes secret for database credentials (default: crewai-database)"
  type        = string
  default     = "crewai-database"
}

variable "platform_namespace" {
  description = "Namespace for platform resources (default: crewai-platform)"
  type        = string
  default     = "crewai-platform"
}
