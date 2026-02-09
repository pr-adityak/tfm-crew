# Registry Module - Google Artifact Registry for Crew AI builder

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

resource "google_artifact_registry_repository" "repository" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "registry used by crew ai builder"
  format        = "DOCKER"
}
