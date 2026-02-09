# Storage Module - GCS Buckets for data and logs

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

resource "google_storage_bucket" "data" {
  name          = var.data_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Encryption is automatic with Google-managed keys (no block needed)

  public_access_prevention = "enforced"

  labels = {
    purpose = "application-data"
    name    = var.data_bucket_name
  }
}

resource "google_storage_bucket" "logs" {
  name          = var.logs_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Encryption is automatic with Google-managed keys (no block needed)

  public_access_prevention = "enforced"

  labels = {
    purpose = "centralized-logging"
    name    = var.logs_bucket_name
  }
}
