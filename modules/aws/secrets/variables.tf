# Secrets Module Variables

variable "secret_name" {
  description = "Name for the AWS Secrets Manager secret"
  type        = string
  default     = "crewai/database-credentials"
}

variable "db_password" {
  description = "Database password (from database module)"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}
