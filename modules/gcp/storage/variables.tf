variable "data_bucket_name" {
  description = "Globally unique GCS bucket name for application data"
  type        = string
}

variable "logs_bucket_name" {
  description = "Globally unique GCS bucket name for centralized logs"
  type        = string
}

variable "region" {
  description = "GCP region for bucket location"
  type        = string
}
