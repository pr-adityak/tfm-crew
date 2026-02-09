# Secrets Module - Database Credentials Only
# Application secrets should be configured in Helm chart values.yaml

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "database_credentials" {
  secret_id = var.secret_name
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    name = var.secret_name
  }
}

resource "google_secret_manager_secret_version" "database_credentials" {
  secret      = google_secret_manager_secret.database_credentials.id
  secret_data = jsonencode({
    db_password = var.db_password
    db_host     = var.db_host
    db_port     = var.db_port
    db_name     = var.db_name
    db_user     = var.db_user
  })

  lifecycle {
    ignore_changes = [secret_data]
  }
}
