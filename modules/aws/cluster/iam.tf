# ============================================================================
# IAM Roles for EKS (Auto Mode or Managed Node Group)
# ============================================================================
#
# This file defines IAM roles and policies for:
# - Cluster role: Used by EKS control plane
# - Node role: Used by EC2 instances (worker nodes)
#
# The node role policies differ based on deployment mode:
# - Auto Mode: Uses AmazonEKSWorkerNodeMinimalPolicy
# - Managed Node Group: Uses full set of worker policies + optional KMS access
#
# ============================================================================

# Cluster IAM Role - Used by EKS control plane and Auto Mode automation
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = local.node_tags
}

# Attach all 5 required Auto Mode managed policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ])

  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

# Node IAM Role - Used by EC2 instances running as Kubernetes worker nodes
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.node_tags
}

# Attach Auto Mode policy to node role (when NOT using managed node groups)
resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = var.use_managed_node_group ? toset([]) : toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# Attach managed node group policies (when using managed node groups)
# These policies are required for EC2 instances to join the EKS cluster
resource "aws_iam_role_policy_attachment" "node_managed_policies" {
  for_each = var.use_managed_node_group ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]) : toset([])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# Inline policy for ECR read/write access to crewai-enterprise repository
resource "aws_iam_role_policy" "node_ecr_access" {
  name = "${var.cluster_name}-node-ecr-access"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*" # Required for docker login - cannot be scoped
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

# Inline policy for KMS access (required for EBS encryption in enterprise environments)
# This allows the node role to use KMS keys for encrypted EBS volumes
# Only created when using managed node groups AND a KMS key ARN is provided
resource "aws_iam_role_policy" "node_kms_access" {
  count = var.use_managed_node_group && var.kms_key_arn != "" ? 1 : 0

  name = "${var.cluster_name}-node-kms-access"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}
