variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the deployment"
  type        = string
}

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
