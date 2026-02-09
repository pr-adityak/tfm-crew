# IAM Roles for Service Accounts (IRSA)
# Allows Kubernetes pods to assume IAM roles for AWS service access

# Get OIDC provider certificate for cluster
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create OIDC provider for the cluster
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc-provider"
  }
}

# IAM Role for CrewAI Platform workload pods
# This role will be assumed by Kubernetes service accounts in the specified namespace
resource "aws_iam_role" "platform_workload" {
  name = "${var.cluster_name}-platform-workload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:${var.workload_namespace}:${var.workload_service_account}"
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-platform-workload-role"
  }
}

# Policy granting workload access to S3 data and logs buckets
resource "aws_iam_role_policy" "platform_s3_access" {
  name = "s3-access"
  role = aws_iam_role.platform_workload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.s3_data_bucket_arn,
        "${var.s3_data_bucket_arn}/*",
        var.s3_logs_bucket_arn,
        "${var.s3_logs_bucket_arn}/*"
      ]
    }]
  })
}

# Policy granting workload access to Secrets Manager
resource "aws_iam_role_policy" "platform_secrets_access" {
  name = "secrets-access"
  role = aws_iam_role.platform_workload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = var.secrets_manager_secret_arn
    }]
  })
}

# Policy granting workload access to ECR repository
resource "aws_iam_role_policy" "platform_ecr_access" {
  name = "ecr-access"
  role = aws_iam_role.platform_workload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
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
