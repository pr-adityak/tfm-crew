variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the deployment"
  type        = string
}

variable "repository_id" {
  description = "ID of the repository"
  type        = string
  default     = "crewai-enterprise"
}
