output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "subnet_self_links" {
  description = "Self links of the subnets"
  value       = google_compute_subnetwork.private[*].self_link
}

output "subnet_names" {
  description = "Names of the subnets"
  value       = google_compute_subnetwork.private[*].name
}

output "region" {
  description = "Region where resources are deployed"
  value       = var.region
}
