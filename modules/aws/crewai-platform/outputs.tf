# Storage Outputs
output "s3_data_bucket_name" {
  description = "Name of the S3 data bucket"
  value       = module.storage.s3_data_bucket_name
}

output "s3_data_bucket_arn" {
  description = "ARN of the S3 data bucket"
  value       = module.storage.s3_data_bucket_arn
}

output "s3_logs_bucket_name" {
  description = "Name of the S3 logs bucket"
  value       = module.storage.s3_logs_bucket_name
}

output "s3_logs_bucket_arn" {
  description = "ARN of the S3 logs bucket"
  value       = module.storage.s3_logs_bucket_arn
}

# Network Outputs
output "network_configuration" {
  description = "Complete network configuration"
  value = {
    vpc_id              = module.networking.vpc_id
    vpc_cidr            = module.networking.vpc_cidr
    private_subnet_ids  = module.networking.private_subnet_ids
    public_subnet_ids   = module.networking.public_subnet_ids
    availability_zones  = module.networking.availability_zones
    nat_gateway_ids     = module.networking.nat_gateway_ids
    vpc_endpoints_sg_id = module.networking.vpc_endpoints_security_group_id
    network_validation  = module.networking.network_validation
  }
}

# Secrets Output
output "secrets_configuration" {
  description = "Secrets Manager configuration"
  value = {
    secret_arn  = module.secrets.secret_arn
    secret_name = module.secrets.secret_name
    db_password = module.database.db_password
  }
  sensitive = true
}

# Database Outputs
output "database_configuration" {
  description = "Database connection information (database names managed externally)"
  value = {
    cluster_endpoint        = module.database.cluster_endpoint
    cluster_reader_endpoint = module.database.cluster_reader_endpoint
    port                    = module.database.cluster_port
    reader_instance_count   = module.database.reader_instance_count
    connection_info         = module.database.connection_info
  }
}

# Cluster Outputs
output "cluster_configuration" {
  description = "EKS cluster configuration and connection information"
  value = {
    cluster_name               = module.cluster.cluster_name
    cluster_endpoint           = module.cluster.cluster_endpoint
    cluster_version            = module.cluster.cluster_version
    cluster_arn                = module.cluster.cluster_arn
    cluster_security_group_id  = module.cluster.cluster_security_group_id
    oidc_provider_arn          = module.cluster.oidc_provider_arn
    platform_workload_role_arn = module.cluster.platform_workload_role_arn
    alb_controller_role_arn    = module.cluster.alb_controller_role_arn
    workload_namespace         = module.cluster.workload_namespace
    workload_service_account   = module.cluster.workload_service_account
  }
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.cluster.cluster_certificate_authority_data
  sensitive   = true
}

# Consolidated Output for Easy Reference
output "platform_summary" {
  description = "Summary of key platform resources for quick reference"
  value = {
    region = var.region

    # Key endpoints
    database_endpoint = module.database.cluster_endpoint
    cluster_endpoint  = module.cluster.cluster_endpoint

    # Cluster information
    cluster_name    = module.cluster.cluster_name
    cluster_version = module.cluster.cluster_version

    # Key ARNs
    secret_arn                 = module.secrets.secret_arn
    platform_workload_role_arn = module.cluster.platform_workload_role_arn
    ecr_repository_url         = module.repository.repository_url
    ecr_repository_name        = module.repository.repository_name

    # Network basics
    vpc_id             = module.networking.vpc_id
    private_subnet_ids = module.networking.private_subnet_ids

    # S3 buckets
    data_bucket = module.storage.s3_data_bucket_name
    logs_bucket = module.storage.s3_logs_bucket_name

    # IRSA configuration
    workload_namespace       = module.cluster.workload_namespace
    workload_service_account = module.cluster.workload_service_account
  }
}