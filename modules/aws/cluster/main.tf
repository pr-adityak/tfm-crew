# ============================================================================
# EKS Cluster Module
# ============================================================================
#
# This module supports two deployment modes:
#
# 1. AUTO MODE (default): use_managed_node_group = false
#    - Uses EKS Auto Mode with built-in "general-purpose" node pool
#    - Fully managed compute, storage, and networking
#    - Simpler configuration, less operational overhead
#    - LIMITATION: Cannot add custom tags to Auto Mode node pools
#
# 2. MANAGED NODE GROUP: use_managed_node_group = true
#    - Uses aws_eks_node_group for full control over EC2 instances
#    - Supports custom tags via var.node_tags (required for org tagging policies)
#    - Requires VPC CNI, kube-proxy, and CoreDNS addons (installed via cluster-addons)
#    - Supports KMS encryption for EBS volumes via var.kms_key_arn
#
# Usage:
#   # Default Auto Mode
#   use_managed_node_group = false
#
#   # Managed Node Group with custom tags
#   use_managed_node_group = true
#   node_tags = {
#     "LINUX-HARDENING-V1" = "ENABLED"
#     "Owner"              = "123456"
#   }
#   kms_key_arn = "arn:aws:kms:region:account:key/key-id"
#
# ============================================================================

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  # Merge default tags with user-provided tags from var.node_tags
  # User-provided tags take precedence over defaults
  node_tags = merge(
    {
      Name = "${var.cluster_name}-node"
    },
    var.node_tags
  )
}

# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane and nodes"
  vpc_id      = var.vpc_id

  # Allow cluster to communicate with Aurora database
  egress {
    description     = "PostgreSQL to Aurora database"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.database_security_group_id]
  }

  # Allow HTTPS to VPC endpoints (Secrets Manager, CloudWatch Logs)
  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic (required for node communication, internet access via NAT)
  egress {
    description = "All traffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.node_tags

  lifecycle {
    create_before_destroy = false
  }

  revoke_rules_on_delete = true
}

# Update Aurora security group to allow access from EKS cluster
resource "aws_security_group_rule" "aurora_from_cluster" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = aws_security_group.cluster.id
  description              = "PostgreSQL from EKS cluster"
}

# EKS Cluster with Auto Mode
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  # Required for Auto Mode: disable bootstrap of self-managed addons
  bootstrap_self_managed_addons = false

  # Access configuration for Auto Mode
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  # EKS Auto Mode Configuration (when NOT using managed node groups)
  # Enables fully managed compute, storage, and networking
  dynamic "compute_config" {
    for_each = var.use_managed_node_group ? [] : [1]
    content {
      enabled       = true
      node_pools    = ["general-purpose"]
      node_role_arn = aws_iam_role.node.arn
    }
  }

  # Disabled compute config (when using managed node groups for tagging compliance)
  dynamic "compute_config" {
    for_each = var.use_managed_node_group ? [1] : []
    content {
      enabled = false
    }
  }

  # Auto Mode networking configuration (enabled only when using Auto Mode)
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = var.use_managed_node_group ? false : true
    }
  }

  # Auto Mode storage configuration (enabled only when using Auto Mode)
  storage_config {
    block_storage {
      enabled = var.use_managed_node_group ? false : true
    }
  }

  vpc_config {
    subnet_ids = var.private_subnet_ids

    # Enable both private and public access for operational flexibility
    # Pods use private endpoint (no NAT), operators can use public endpoint with IP whitelist
    # If cluster_endpoint_public_access_cidrs is empty, public access is disabled (private-only)
    endpoint_private_access = true
    endpoint_public_access  = length(var.cluster_endpoint_public_access_cidrs) > 0
    public_access_cidrs     = length(var.cluster_endpoint_public_access_cidrs) > 0 ? var.cluster_endpoint_public_access_cidrs : null

    security_group_ids = [aws_security_group.cluster.id]
  }

  # Ensure IAM roles are created and policies attached before cluster
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policies,
    aws_iam_role_policy_attachment.node_policies
  ]

  tags = local.node_tags
}

# Grant cluster access to administrator IAM users/roles
resource "aws_eks_access_entry" "admin_users" {
  for_each = toset(var.admin_iam_principals)

  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = each.value
  kubernetes_groups = []
  type              = "STANDARD"
}

# Grant cluster admin permissions to administrator users
resource "aws_eks_access_policy_association" "admin_users" {
  for_each = toset(var.admin_iam_principals)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_users]
}

# ============================================================================
# Managed Node Group (alternative to Auto Mode for tagging compliance)
# Only created when use_managed_node_group = true
# ============================================================================

resource "aws_eks_node_group" "main" {
  count = var.use_managed_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Full tag support - applies mandatory tags to EC2 instances
  tags = local.node_tags

  # Ensure cluster and IAM policies are ready before creating node group
  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.node_managed_policies,
    aws_iam_role_policy.node_kms_access
  ]
}
