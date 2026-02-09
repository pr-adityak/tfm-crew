# Cluster configuration
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB controller"
}

# ALB Controller IAM
variable "alb_controller_role_arn" {
  type        = string
  description = "IAM role ARN for AWS Load Balancer Controller"
}

# Database connection details
variable "db_host" {
  type        = string
  description = "Database host (Aurora cluster endpoint)"
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

# IRSA Service Account configuration
variable "workload_service_account" {
  type        = string
  default     = "crewai-platform-sa"
  description = "Name of the Kubernetes service account for platform workloads"
}

variable "platform_workload_role_arn" {
  type        = string
  description = "IAM role ARN to annotate the platform service account with for IRSA"
}

# Managed Node Group Configuration
variable "use_managed_node_group" {
  description = "Whether using managed node group instead of Auto Mode. When true, VPC CNI, kube-proxy, and CoreDNS addons are installed (Auto Mode handles these automatically)."
  type        = bool
  default     = false
}
