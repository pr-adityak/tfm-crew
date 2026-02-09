# Required Core Variables
variable "region" {
  description = "AWS region for the deployment"
  type        = string
}

# S3 Bucket Configuration
variable "s3_data_bucket_name" {
  description = "Globally unique S3 bucket name for application data"
  type        = string
}

variable "s3_logs_bucket_name" {
  description = "Globally unique S3 bucket name for centralized logs"
  type        = string
}

# Networking Configuration
variable "network_name_prefix" {
  description = "Prefix for all network resource names"
  type        = string
  default     = "crewai-"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to use (minimum 2 for HA)"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2
    error_message = "At least 2 availability zones are required for high availability"
  }
}

# Existing VPC Configuration
# Use when deploying into an existing VPC instead of creating a new one
variable "use_existing_vpc" {
  description = "Use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of existing VPC (required when use_existing_vpc = true)"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs (required when use_existing_vpc = true, minimum 2 in different AZs)"
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs (optional, for internet-facing ALBs)"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints when using existing VPC (Secrets Manager, CloudWatch Logs, S3). Set to false if endpoints already exist."
  type        = bool
  default     = true
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "crewai-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "workload_namespace" {
  description = "Kubernetes namespace for CrewAI platform workloads"
  type        = string
  default     = "crewai-platform"
}

variable "workload_service_account" {
  description = "Kubernetes service account name for CrewAI platform workloads"
  type        = string
  default     = "crewai-platform-sa"
}

variable "admin_iam_principals" {
  description = "List of IAM principal ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster public API endpoint. Use YOUR_IP/32 for single IPs. Empty list = private-only access"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All entries must be valid CIDR blocks (e.g., 98.252.207.16/32 for single IP, 203.0.113.0/24 for range)"
  }
}

# Database Configuration
variable "db_cluster_identifier" {
  description = "Aurora PostgreSQL cluster identifier"
  type        = string
  default     = "crewai-db-cluster"
}

variable "db_instance_class" {
  description = "Database instance class for Aurora PostgreSQL"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for Aurora"
  type        = string
  default     = "16.6"
}

variable "db_master_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_database_name" {
  description = "Name of the database to create in PostgreSQL"
  type        = string
  default     = "crewai"
}

variable "reader_instance_count" {
  description = "Number of Aurora reader instances for high availability"
  type        = number
  default     = 1
}

# Managed Node Group Configuration
# Use when org-wide tagging policies prevent EKS Auto Mode
variable "use_managed_node_group" {
  description = "Use managed node group instead of Auto Mode (required for org tagging policies that block Auto Mode)"
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "Instance types for the managed node group (only used when use_managed_node_group = true)"
  type        = list(string)
  default     = ["m6i.xlarge"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group"
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group"
  type        = number
  default     = 3
}

variable "node_tags" {
  description = "Tags to apply to managed node group resources. Required for organizations with mandatory tagging policies."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for EBS volume encryption. Required when the AWS account has default EBS encryption enabled."
  type        = string
  default     = ""
}
