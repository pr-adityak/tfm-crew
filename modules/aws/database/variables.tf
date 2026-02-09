# Database Module Variables

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "crewai-"
}

variable "vpc_id" {
  description = "ID of the VPC where database will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for security group rules)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the database subnet group"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for Aurora database high availability."
  }
}

# Database Configuration
variable "db_cluster_identifier" {
  description = "Aurora PostgreSQL cluster identifier for the main database"
  type        = string
  default     = "crewai-cluster"
}

variable "db_instance_class" {
  description = "Database instance class for Aurora PostgreSQL instances"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for Aurora compatibility (minimum 15.10)"
  type        = string
  default     = "16.6"
  validation {
    condition     = can(regex("^1[56]\\.", var.db_engine_version))
    error_message = "Aurora PostgreSQL engine version must be 15.x or 16.x"
  }
}

variable "db_master_username" {
  description = "Database master username for administrative access"
  type        = string
  default     = "postgres"
}

variable "reader_instance_count" {
  description = "Number of Aurora reader instances for high availability and read scaling"
  type        = number
  default     = 1
  validation {
    condition     = var.reader_instance_count >= 0 && var.reader_instance_count <= 15
    error_message = "Reader instance count must be between 0 and 15 (Aurora maximum)."
  }
}

variable "db_database_name" {
  description = "Name of the initial database to create in PostgreSQL"
  type        = string
  default     = "crewai"
}

