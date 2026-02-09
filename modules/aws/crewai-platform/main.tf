# CrewAI Platform Module
# This module encapsulates the complete CrewAI platform infrastructure

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Storage Module - S3 Buckets (simplified to match Ansible)
module "storage" {
  source = "../storage"

  data_bucket_name = var.s3_data_bucket_name
  logs_bucket_name = var.s3_logs_bucket_name
}

# Repository Module - ECR for CrewAI Builder
module "repository" {
  source = "../repository"
}

# Networking Module - Creates VPC infrastructure or uses existing VPC
# Combines VPC, subnets, gateways, routes, and endpoints
module "networking" {
  source = "../networking"

  name_prefix = var.network_name_prefix
  vpc_cidr    = var.vpc_cidr
  az_count    = var.availability_zone_count
  region      = var.region

  # Existing VPC configuration
  use_existing_vpc            = var.use_existing_vpc
  existing_vpc_id             = var.existing_vpc_id
  existing_private_subnet_ids = var.existing_private_subnet_ids
  existing_public_subnet_ids  = var.existing_public_subnet_ids
  create_vpc_endpoints        = var.create_vpc_endpoints
}

# Database Module - Aurora PostgreSQL
module "database" {
  depends_on = [module.networking]

  source = "../database"

  # Network configuration
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr
  private_subnet_ids = module.networking.private_subnet_ids

  # Database configuration
  db_cluster_identifier = var.db_cluster_identifier
  db_instance_class     = var.db_instance_class
  db_engine_version     = var.db_engine_version
  db_master_username    = var.db_master_username
  db_database_name      = var.db_database_name
  reader_instance_count = var.reader_instance_count
}

# Secrets Module - AWS Secrets Manager for database credentials
module "secrets" {
  depends_on = [module.database]

  source = "../secrets"

  # Database connection details from database module
  db_password = module.database.db_password
  db_host     = module.database.connection_info.host
  db_port     = module.database.connection_info.port
  db_name     = var.db_database_name
  db_user     = module.database.connection_info.username
}

# Cluster Module - EKS Auto Mode
module "cluster" {

  depends_on = [
    module.networking,
    module.database,
    module.storage,
    module.secrets,
    module.repository
  ]

  source = "../cluster"

  # Cluster configuration
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Networking from existing resources
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr
  private_subnet_ids = module.networking.private_subnet_ids

  # Integration with existing resources for IRSA and security groups
  database_security_group_id = module.database.security_group_id
  s3_data_bucket_arn         = module.storage.s3_data_bucket_arn
  s3_logs_bucket_arn         = module.storage.s3_logs_bucket_arn
  secrets_manager_secret_arn = module.secrets.secret_arn

  # IRSA configuration
  workload_namespace       = var.workload_namespace
  workload_service_account = var.workload_service_account

  # Cluster admin access
  admin_iam_principals = var.admin_iam_principals

  # Cluster API endpoint access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # ECR repository for builder
  ecr_repository_arn = module.repository.repository_arn

  # Managed Node Group Configuration (for org tagging policies)
  use_managed_node_group = var.use_managed_node_group
  node_instance_types    = var.node_instance_types
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  node_desired_size      = var.node_desired_size
  node_tags              = var.node_tags
  kms_key_arn            = var.kms_key_arn
}
