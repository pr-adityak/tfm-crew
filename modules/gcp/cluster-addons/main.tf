# Cluster Add-ons Module - Database Kubernetes Secret

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Platform Namespace
resource "kubernetes_namespace" "platform" {
  metadata {
    name = var.platform_namespace
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
