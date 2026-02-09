# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

# IAM Role Information
output "cluster_iam_role_arn" {
  description = "IAM role ARN used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN used by EKS nodes (Auto Mode or managed node group)"
  value       = aws_iam_role.node.arn
}

# IRSA Information
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "platform_workload_role_arn" {
  description = "IAM role ARN for CrewAI platform workloads (used via IRSA)"
  value       = aws_iam_role.platform_workload.arn
}

output "workload_namespace" {
  description = "Kubernetes namespace configured for platform workloads"
  value       = var.workload_namespace
}

output "workload_service_account" {
  description = "Kubernetes service account name configured for platform workloads"
  value       = var.workload_service_account
}

# AWS Load Balancer Controller
output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

# Managed Node Group Information (only populated when use_managed_node_group = true)
output "node_group_name" {
  description = "Name of the managed node group (null if using Auto Mode)"
  value       = var.use_managed_node_group ? aws_eks_node_group.main[0].node_group_name : null
}

output "node_group_arn" {
  description = "ARN of the managed node group (null if using Auto Mode)"
  value       = var.use_managed_node_group ? aws_eks_node_group.main[0].arn : null
}

output "node_group_status" {
  description = "Status of the managed node group (null if using Auto Mode)"
  value       = var.use_managed_node_group ? aws_eks_node_group.main[0].status : null
}

output "use_managed_node_group" {
  description = "Whether managed node group is being used instead of Auto Mode"
  value       = var.use_managed_node_group
}
