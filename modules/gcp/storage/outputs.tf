output "data_bucket_name" {
  description = "Name of the data GCS bucket"
  value       = google_storage_bucket.data.name
}

output "data_bucket_url" {
  description = "URL of the data GCS bucket"
  value       = google_storage_bucket.data.url
}

output "logs_bucket_name" {
  description = "Name of the logs GCS bucket"
  value       = google_storage_bucket.logs.name
}

output "logs_bucket_url" {
  description = "URL of the logs GCS bucket"
  value       = google_storage_bucket.logs.url
}
