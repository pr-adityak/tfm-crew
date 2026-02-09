# Secrets Module - Database Credentials Only
# Application secrets should be configured in Helm chart values.yaml

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Store database credentials in Secrets Manager
resource "aws_secretsmanager_secret" "database_credentials" {
  name        = var.secret_name
  description = "CrewAI Platform Database Credentials"

  recovery_window_in_days = 0

  tags = {
    Name = var.secret_name
  }
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    db_password = var.db_password
    db_host     = var.db_host
    db_port     = var.db_port
    db_name     = var.db_name
    db_user     = var.db_user
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
