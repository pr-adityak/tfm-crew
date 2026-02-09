# ============================================================================
# Cluster Add-ons Module
# ============================================================================
#
# This module installs:
#
# 1. EKS Addons (only when use_managed_node_group = true):
#    - VPC CNI: Pod networking
#    - kube-proxy: Network proxy on each node
#    - CoreDNS: Cluster DNS
#    Note: Auto Mode handles these automatically; only needed for managed node groups
#
# 2. AWS Load Balancer Controller:
#    - Required for ALB/NLB ingress resources
#
# 3. Platform Resources:
#    - Namespace for CrewAI workloads
#    - Service account with IRSA annotation
#    - Database connection secret
#
# ============================================================================

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
  }
}

# ============================================================================
# EKS Addons for Managed Node Groups
# These are required when using managed node groups (Auto Mode handles them automatically)
# ============================================================================

# VPC CNI Addon - Provides pod networking
resource "aws_eks_addon" "vpc_cni" {
  count = var.use_managed_node_group ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# kube-proxy Addon - Provides network proxy on each node
resource "aws_eks_addon" "kube_proxy" {
  count = var.use_managed_node_group ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# CoreDNS Addon - Provides cluster DNS
resource "aws_eks_addon" "coredns" {
  count = var.use_managed_node_group ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # CoreDNS requires VPC CNI and kube-proxy to be ready first
  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy
  ]
}

# ============================================================================
# AWS Load Balancer Controller
# ============================================================================

# AWS Load Balancer Controller Helm Chart
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # When using managed node groups, wait for core addons to be ready
  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.coredns
  ]
}

# Platform Namespace
resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
  }
}

# Platform Workload Service Account with IRSA annotation
resource "kubernetes_service_account" "platform_workload" {
  metadata {
    name      = var.workload_service_account
    namespace = kubernetes_namespace.platform.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.platform_workload_role_arn
    }
  }
}

# Database Connection Kubernetes Secret
resource "kubernetes_secret" "database" {
  metadata {
    name      = var.database_secret_name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    DB_HOST     = var.db_host
    DB_PORT     = tostring(var.db_port)
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_URI      = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"
  }
}
