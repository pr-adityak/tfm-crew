terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  # S3 Backend for Remote State Storage
  # REQUIRED: Create S3 bucket before running terraform init (see docs/aws.md)
  # OPTIONAL: Comment out this entire backend block to use local state instead
  backend "s3" {
    bucket  = "YOUR-UNIQUE-STATE-BUCKET-NAME" # Replace with your bucket name
    key     = "crewai/terraform.tfstate"
    region  = "us-east-1" # Match your deployment region
    encrypt = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "CrewAI"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================================
# Auto-detection of Terraform runner identity and network
# ============================================================================

# Get current AWS identity running Terraform
data "aws_caller_identity" "current" {}

# Detect public IP of machine running Terraform
data "http" "terraform_runner_ip" {
  url = "https://checkip.amazonaws.com"

  lifecycle {
    # If IP detection fails, we'll handle it gracefully
    postcondition {
      condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}", chomp(self.response_body)))
      error_message = "Failed to detect valid public IP address"
    }
  }
}

locals {
  # Clean up the detected IP and format as CIDR
  terraform_runner_cidr = "${chomp(data.http.terraform_runner_ip.response_body)}/32"

  # Merge auto-detected values with user-provided ones
  all_admin_principals = distinct(concat(
    [data.aws_caller_identity.current.arn],
    var.admin_iam_principals
  ))

  all_public_access_cidrs = distinct(concat(
    [local.terraform_runner_cidr],
    var.cluster_endpoint_public_access_cidrs
  ))
}

# ============================================================================
# Data sources for cluster authentication with proper dependencies
# ============================================================================

# Data source for cluster info - waits for cluster to exist
data "aws_eks_cluster" "cluster" {
  name = module.crewai_platform.cluster_configuration.cluster_name

  # Critical: Wait for the platform module to complete before trying to read
  depends_on = [module.crewai_platform]
}

# Kubernetes provider with exec auth for better reliability
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  # Use exec auth instead of token - runs aws eks get-token when needed
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", var.region, "--cluster-name", data.aws_eks_cluster.cluster.name]
  }
}

# Helm provider with exec auth for better reliability
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    # Use exec auth instead of token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--region", var.region, "--cluster-name", data.aws_eks_cluster.cluster.name]
    }
  }
}

# ============================================================================
# CrewAI Platform Module
# This module encapsulates the complete CrewAI platform infrastructure
module "crewai_platform" {
  source = "../../modules/aws/crewai-platform"

  # Core Configuration
  region = var.region

  # S3 Storage
  s3_data_bucket_name = var.s3_data_bucket_name
  s3_logs_bucket_name = var.s3_logs_bucket_name

  # Network Configuration (optional overrides)
  vpc_cidr                = var.vpc_cidr
  availability_zone_count = var.availability_zone_count

  # Existing VPC Configuration (optional - use to deploy into existing VPC)
  use_existing_vpc            = var.use_existing_vpc
  existing_vpc_id             = var.existing_vpc_id
  existing_private_subnet_ids = var.existing_private_subnet_ids
  existing_public_subnet_ids  = var.existing_public_subnet_ids
  create_vpc_endpoints        = var.create_vpc_endpoints

  # Cluster Configuration
  cluster_name             = var.cluster_name
  kubernetes_version       = var.kubernetes_version
  workload_namespace       = var.workload_namespace
  workload_service_account = var.workload_service_account
  admin_iam_principals     = local.all_admin_principals # Now includes Terraform runner automatically

  # Database Configuration (optional overrides)
  db_cluster_identifier = var.db_cluster_identifier
  db_instance_class     = var.db_instance_class
  reader_instance_count = var.reader_instance_count

  # Cluster API endpoint access
  cluster_endpoint_public_access_cidrs = local.all_public_access_cidrs # Now includes Terraform runner IP

  # Managed Node Group Configuration (for org tagging policies)
  use_managed_node_group = var.use_managed_node_group
  node_instance_types    = var.node_instance_types
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  node_desired_size      = var.node_desired_size
  node_tags              = var.node_tags
  kms_key_arn            = var.kms_key_arn
}

# ============================================================================
# CrewAI Cluster Add-ons Module
# Installs AWS Load Balancer Controller and creates database Kubernetes secret
module "crewai_cluster_addons" {
  source = "../../modules/aws/cluster-addons"

  # Cluster configuration
  cluster_name = module.crewai_platform.cluster_configuration.cluster_name
  region       = var.region
  vpc_id       = module.crewai_platform.network_configuration.vpc_id

  # ALB Controller IAM
  alb_controller_role_arn = module.crewai_platform.cluster_configuration.alb_controller_role_arn

  # Database connection
  db_host     = module.crewai_platform.database_configuration.connection_info.host
  db_port     = module.crewai_platform.database_configuration.connection_info.port
  db_name     = var.database_name
  db_username = module.crewai_platform.database_configuration.connection_info.username
  db_password = module.crewai_platform.secrets_configuration.db_password

  # Optional overrides
  database_secret_name = var.database_secret_name
  platform_namespace   = var.platform_namespace

  # IRSA Service Account configuration
  workload_service_account   = var.workload_service_account
  platform_workload_role_arn = module.crewai_platform.cluster_configuration.platform_workload_role_arn

  # Managed Node Group - installs required EKS addons (VPC CNI, kube-proxy, CoreDNS)
  use_managed_node_group = var.use_managed_node_group

  # Ensure cluster exists before attempting to install add-ons
  depends_on = [module.crewai_platform]
}
# ============================================================================
