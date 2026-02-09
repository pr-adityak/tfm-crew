# ========================================
# REQUIRED CONFIGURATION
# ========================================

variable "region" {
  description = "AWS region for the deployment (e.g., us-west-2, eu-west-1)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., development, staging, production)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.environment))
    error_message = "Environment must start with a letter and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "s3_data_bucket_name" {
  description = "Globally unique S3 bucket name for application data"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_data_bucket_name))
    error_message = "S3 bucket name must be valid (lowercase, numbers, hyphens only)"
  }
}

variable "s3_logs_bucket_name" {
  description = "Globally unique S3 bucket name for centralized logs"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_logs_bucket_name))
    error_message = "S3 bucket name must be valid (lowercase, numbers, hyphens only)"
  }
}

# ========================================
# ADVANCED CONFIGURATION (override defaults if needed)
# ========================================

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC (default: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }
}

variable "availability_zone_count" {
  description = "Number of availability zones to use (default: 2, minimum 2 for HA)"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 3
    error_message = "Availability zone count must be between 2 and 3"
  }
}

# ========================================
# EXISTING VPC CONFIGURATION
# Use when you want to deploy into an existing VPC instead of creating a new one
# ========================================

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
  description = <<-EOT
    List of existing private subnet IDs (required when use_existing_vpc = true, minimum 2 in different AZs).

    Requirements for existing subnets:
    - Must span at least 2 Availability Zones
    - Should have tag "kubernetes.io/role/internal-elb" = "1" for internal ALBs
    - Must have NAT Gateway or equivalent egress path for internet access
    - Should have sufficient IP space for EKS nodes and pods
  EOT
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = <<-EOT
    List of existing public subnet IDs (optional, needed for internet-facing ALBs).

    Requirements for existing subnets:
    - Should have tag "kubernetes.io/role/elb" = "1" for internet-facing ALBs
  EOT
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
  description = "Name of the EKS cluster (default: crewai-cluster)"
  type        = string
  default     = "crewai-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster (default: 1.32)"
  type        = string
  default     = "1.32"

  validation {
    condition     = can(regex("^1\\.(3[2-9]|[4-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.32 or higher"
  }
}

variable "workload_namespace" {
  description = "Kubernetes namespace for CrewAI platform workloads (default: crewai-platform)"
  type        = string
  default     = "crewai-platform"
}

variable "workload_service_account" {
  description = "Kubernetes service account name for CrewAI platform workloads (default: crewai-platform-sa)"
  type        = string
  default     = "crewai-platform-sa"
}

variable "admin_iam_principals" {
  description = "List of IAM principal ARNs to grant cluster admin access (optional)"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster public API endpoint (for kubectl access). Use YOUR_IP/32 for single IPs. Empty list = private-only access"
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
  description = "Aurora PostgreSQL cluster identifier (default: crewai-db-cluster)"
  type        = string
  default     = "crewai-db-cluster"
}

variable "db_instance_class" {
  description = "Database instance class (default: db.t4g.medium - suitable for dev/staging)"
  type        = string
  default     = "db.t4g.medium"
}

variable "reader_instance_count" {
  description = "Number of Aurora reader instances for high availability (default: 1)"
  type        = number
  default     = 1
}

# Cluster Add-ons Configuration
variable "database_name" {
  description = "Name of the database to create in PostgreSQL (default: crewai)"
  type        = string
  default     = "crewai"
}

variable "database_secret_name" {
  description = "Name of the Kubernetes secret for database credentials (default: crewai-database)"
  type        = string
  default     = "crewai-database"
}

variable "platform_namespace" {
  description = "Namespace for platform resources (default: crewai-platform)"
  type        = string
  default     = "crewai-platform"
}

# ========================================
# MANAGED NODE GROUP CONFIGURATION
# Use when org-wide tagging policies prevent EKS Auto Mode
# ========================================

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
  description = <<-EOT
    Tags to apply to managed node group resources. Required for organizations with mandatory tagging policies.
    These tags are applied to the node group and propagated to EC2 instances.

    Example:
    node_tags = {
      "LINUX-HARDENING-V1" = "ENABLED"
      "Owner"              = "123456"
      "Project Name"       = "MyProject"
      "RGUID"              = "xxx-xxx"
    }
  EOT
  type        = map(string)
  default     = {
    "LINUX-HARDENING-V1" = "ENABLED"
    Name                = "CrewAI EKS Node"
    "Project Name"      = "Crew AI UAT"
    Owner               = "703201358"
    RGUID               = "03F4-FF27-4A5C"
  }
}

variable "kms_key_arn" {
  description = <<-EOT
    KMS key ARN for EBS volume encryption. Required when the AWS account has default EBS encryption
    enabled with a customer-managed KMS key. The node IAM role will be granted permissions to use this key.

    Example: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  EOT
  type        = string
  default     = ""
}
