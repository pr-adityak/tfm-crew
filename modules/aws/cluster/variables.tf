# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "crewai-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^1\\.(3[2-9]|[4-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.32 or higher"
  }
}

variable "admin_iam_principals" {
  description = "List of IAM principal ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}

# Networking Configuration
variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability"
  }
}

# Integration with Existing Resources
variable "database_security_group_id" {
  description = "Security group ID of the Aurora PostgreSQL database"
  type        = string
}

variable "s3_data_bucket_arn" {
  description = "ARN of the S3 data bucket for workload access via IRSA"
  type        = string
}

variable "s3_logs_bucket_arn" {
  description = "ARN of the S3 logs bucket for workload access via IRSA"
  type        = string
}

variable "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret for workload access via IRSA"
  type        = string
}

# Cluster API Access
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

# IRSA Configuration
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

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository for node IAM policy"
  type        = string
}

# Managed Node Group Configuration
# Use this when org-wide tagging policies prevent Auto Mode node pools from working
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
  description = "Tags to apply to managed node group resources. Required for organizations with mandatory tagging policies. These tags are applied to the node group and propagated to EC2 instances."
  type        = map(string)
  default     = {}

  # Example:
  # node_tags = {
  #   "LINUX-HARDENING-V1" = "ENABLED"
  #   "Owner"              = "123456"
  #   "Project Name"       = "MyProject"
  #   "RGUID"              = "xxx-xxx"
  # }
}

variable "kms_key_arn" {
  description = "KMS key ARN for EBS volume encryption. Required when the AWS account has default EBS encryption enabled with a customer-managed KMS key."
  type        = string
  default     = ""

  # Example: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}
