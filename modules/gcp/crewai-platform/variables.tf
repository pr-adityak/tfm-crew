# Required Core Variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the deployment"
  type        = string
}

# GCS Bucket Configuration
variable "gcs_data_bucket_name" {
  description = "Globally unique GCS bucket name for application data"
  type        = string
}

variable "gcs_logs_bucket_name" {
  description = "Globally unique GCS bucket name for centralized logs"
  type        = string
}

# Networking Configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "crewai-network"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "zone_count" {
  description = "Number of zones to use (minimum 2 for HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.zone_count >= 2 && var.zone_count <= 3
    error_message = "Zone count must be between 2 and 3"
  }
}

# Repository Configuration
variable "artifact_repository_id" {
  description = "ID of the Google Artifact Repository used by CrewAI builder"
  type        = string
  default     = "crewai-enterprise"
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "crewai-cluster"
}

variable "cluster_initial_node_count" {
  description = "Number of nodes to start the cluster with"
  type        = number
  default     = 1
}

variable "cluster_node_machine_type" {
  description = "Type of instance to use for cluster's nodes"
  type        = string
  default     = "e2-standard-4"
}

# Note: kubernetes_version removed - GKE Autopilot automatically manages version

variable "cluster_authorized_networks" {
  description = "List of CIDR blocks that can access the GKE cluster API endpoint. Use YOUR_IP/32 for single IPs. Empty list = private-only access"
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
  description = "Cloud SQL instance name"
  type        = string
  default     = "crewai-db"
}

variable "db_instance_tier" {
  description = "Cloud SQL instance tier (machine type). Use db-custom-<CPU>-<RAM> format or a predefined tier from GCP."
  type        = string
  default     = "db-custom-2-7680"
}

variable "db_edition" {
  description = "Cloud SQL edition (ENTERPRISE or ENTERPRISE_PLUS)"
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.db_edition)
    error_message = "Edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "db_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "crewai"
}

variable "db_master_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "reader_instance_count" {
  description = "Number of Cloud SQL read replica instances for high availability"
  type        = number
  default     = 1
}

variable "replica_zones" {
  description = "List of zones for read replica placement. Replicas cycle through this list. If empty, GCP auto-selects zones for optimal HA distribution."
  type        = list(string)
  default     = []
}
