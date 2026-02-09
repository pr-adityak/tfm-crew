variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "crewai-cluster"
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_self_links" {
  description = "List of subnet self links"
  type        = list(string)
}

variable "cluster_authorized_networks" {
  description = "List of CIDR blocks that can access the cluster API endpoint (for kubectl). Empty list = private-only access"
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

# Integration with other modules
variable "secret_id" {
  description = "Secret Manager secret ID (for IAM binding)"
  type        = string
}

variable "data_bucket_name" {
  description = "GCS data bucket name (for IAM binding)"
  type        = string
}

variable "logs_bucket_name" {
  description = "GCS logs bucket name (for IAM binding)"
  type        = string
}

variable "initial_node_count" {
  description = "Number of nodes to start the cluster with"
  type        = number
}

variable "node_machine_type" {
  description = "Type of instance to use for cluster's nodes"
  type        = string
}

variable "artifact_repository_name" {
  description = "Name of the Google Artifact Repository for the CrewAI Builder"
  type        = string
}
