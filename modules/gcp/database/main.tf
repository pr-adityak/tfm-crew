# Database Module - Cloud SQL PostgreSQL

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

# Generate database password
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.db_instance_name}-private-ip"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id
}

# Private VPC connection for Cloud SQL
# NOTE: deletion_policy = "ABANDON" is required due to GCP provider limitation.
# The provider's deleteConnection API fails with "Producer services still using this connection"
# even after Cloud SQL instances are fully deleted. This is a known issue with provider 5.x+.
# ABANDON removes the resource from Terraform state without deleting the underlying GCP resource.
# The VPC peering will remain in GCP and must be manually cleaned up if needed.
# See: https://github.com/hashicorp/terraform-provider-google/issues/16275
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  deletion_policy = "ABANDON"
}

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = var.db_instance_name
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_16"

  # Deletion protection
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.db_instance_tier
    edition           = var.db_edition # Cloud SQL edition (ENTERPRISE or ENTERPRISE_PLUS)
    availability_type = "REGIONAL"     # HA enabled across zones
    disk_type         = "PD_SSD"
    disk_size         = 100
    disk_autoresize   = true

    # Private IP configuration
    ip_configuration {
      ipv4_enabled    = false # No public IP
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY" # Enforce SSL/TLS encryption
    }

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day  = 7 # Sunday
      hour = 4
    }

    # Database flags for PostgreSQL optimization
    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }

  # Ensure VPC connection is created first
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create database
resource "google_sql_database" "database" {
  name     = var.db_database_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

# Create database user
resource "google_sql_user" "db_user" {
  name     = var.db_master_username
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Read Replicas
resource "google_sql_database_instance" "read_replica" {
  count = var.reader_instance_count

  name                 = "${var.db_instance_name}-replica-${count.index + 1}"
  project              = var.project_id
  region               = var.region
  database_version     = "POSTGRES_16"
  master_instance_name = google_sql_database_instance.main.name

  # Deletion protection (must match primary)
  deletion_protection = var.deletion_protection

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.db_instance_tier
    edition           = var.db_edition # Cloud SQL edition (must match primary)
    availability_type = var.replica_availability_type
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    # Private IP configuration (same as primary)
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY" # Enforce SSL/TLS encryption
    }

    # Zone placement - if replica_zones provided, cycle through them; otherwise GCP auto-selects
    dynamic "location_preference" {
      for_each = length(var.replica_zones) > 0 ? [1] : []
      content {
        zone = var.replica_zones[count.index % length(var.replica_zones)]
      }
    }
  }

  depends_on = [
    google_sql_database_instance.main,
    google_service_networking_connection.private_vpc_connection
  ]

  # IMPORTANT: Cloud SQL automatically tunes database_flags (like max_connections) for replicas.
  # Ignore changes to prevent Terraform from trying to remove GCP-managed flags.
  lifecycle {
    ignore_changes = [
      settings[0].database_flags
    ]
  }
}
