# Database connection details
variable "db_host" {
  type        = string
  description = "Database host (CloudSQL private IP)"
}

variable "db_port" {
  type        = number
  description = "Database port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

# Kubernetes secret configuration
variable "database_secret_name" {
  type        = string
  default     = "crewai-database"
  description = "Name of the Kubernetes secret for database credentials"
}

variable "platform_namespace" {
  type        = string
  default     = "crewai-platform"
  description = "Namespace for platform resources (secrets, workloads, etc.)"
}
