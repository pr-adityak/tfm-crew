# ========================================
# AUTO-DETECTION INFORMATION
# ========================================

output "terraform_runner_info" {
  description = "Information about the Terraform runner (auto-detected)"
  value = {
    iam_identity = data.aws_caller_identity.current.arn
    public_ip    = local.terraform_runner_cidr
    note         = "These values were automatically detected and added to cluster access lists"
  }
}

# ========================================
# CLUSTER CONFIGURATION
# ========================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.crewai_platform.cluster_configuration.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster API"
  value       = module.crewai_platform.cluster_configuration.cluster_endpoint
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.crewai_platform.cluster_configuration.cluster_name}"
}

# ========================================
# WORKLOAD CONFIGURATION
# ========================================

output "workload_namespace" {
  description = "Kubernetes namespace for platform workloads"
  value       = module.crewai_platform.platform_summary.workload_namespace
}

output "workload_service_account" {
  description = "Kubernetes service account for platform workloads"
  value       = module.crewai_platform.platform_summary.workload_service_account
}

output "platform_workload_role_arn" {
  description = "IAM role ARN for IRSA-enabled workloads"
  value       = module.crewai_platform.platform_summary.platform_workload_role_arn
}

# ========================================
# DATABASE CONFIGURATION
# ========================================

output "database_endpoint" {
  description = "Endpoint for Aurora PostgreSQL cluster"
  value       = module.crewai_platform.database_configuration.cluster_endpoint
}

# ========================================
# STORAGE CONFIGURATION
# ========================================

output "s3_data_bucket" {
  description = "Name of the S3 data bucket"
  value       = module.crewai_platform.s3_data_bucket_name
}

output "s3_logs_bucket" {
  description = "Name of the S3 logs bucket"
  value       = module.crewai_platform.s3_logs_bucket_name
}

output "ecr_repository_url" {
  description = "URL for ECR container repository"
  value       = module.crewai_platform.platform_summary.ecr_repository_url
}

# ========================================
# PLATFORM SUMMARY
# ========================================

output "platform_summary" {
  description = "Complete summary of all CrewAI platform resources"
  value       = module.crewai_platform.platform_summary
}
