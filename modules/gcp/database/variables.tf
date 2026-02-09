variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud SQL instance"
  type        = string
}

variable "network_id" {
  description = "VPC network ID for private IP configuration"
  type        = string
}

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
  description = "Number of read replica instances"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying the database instance"
  type        = bool
  default     = false
}

variable "replica_availability_type" {
  description = "Availability type for read replicas (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.replica_availability_type)
    error_message = "Replica availability type must be ZONAL or REGIONAL."
  }
}

variable "replica_zones" {
  description = "List of zones for read replica placement. Replicas cycle through this list. If empty, GCP auto-selects zones for optimal HA distribution."
  type        = list(string)
  default     = []
}
