# Networking Module - Creates VPC infrastructure for GKE

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Get available zones in the region
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

# VPC with custom subnet mode
resource "google_compute_network" "main" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnets - One per zone with secondary ranges for GKE pods and services
resource "google_compute_subnetwork" "private" {
  count = min(length(data.google_compute_zones.available.names), var.zone_count)

  name    = "${var.network_name}-subnet-${data.google_compute_zones.available.names[count.index]}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id

  # Primary CIDR for nodes
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, count.index * 3)

  # Enable Private Google Access (allows pods to reach Google APIs via private IPs)
  private_ip_google_access = true

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods-${data.google_compute_zones.available.names[count.index]}"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, count.index * 3 + 1)
  }

  secondary_ip_range {
    range_name    = "services-${data.google_compute_zones.available.names[count.index]}"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, count.index * 3 + 2)
  }

  # IMPORTANT: GKE (both Autopilot and Standard) automatically manages secondary IP ranges
  # for pods and services. Ignore changes to prevent Terraform from removing GKE-managed ranges.
  lifecycle {
    ignore_changes = [
      secondary_ip_range
    ]
  }
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "main" {
  name    = "${var.network_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT for private subnet egress
resource "google_compute_router_nat" "main" {
  name    = "${var.network_name}-nat"
  project = var.project_id
  region  = var.region
  router  = google_compute_router.main.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
# Allow internal VPC traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  priority      = 1000
}

# Allow GKE control plane to nodes communication
# GKE control plane uses specific ranges, this allows health checks and other control plane traffic
resource "google_compute_firewall" "allow_gke_control_plane" {
  name    = "${var.network_name}-allow-gke-control-plane"
  project = var.project_id
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  # GKE control plane ranges for different regions
  source_ranges = [
    "35.235.240.0/20" # GKE control plane global range
  ]

  priority = 1000
}

# Deny all inbound from internet by default (implicit, but explicit for clarity)
resource "google_compute_firewall" "deny_all" {
  name    = "${var.network_name}-deny-all"
  project = var.project_id
  network = google_compute_network.main.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65535
}
