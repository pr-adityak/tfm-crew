# ECR Repository for CrewAI Builder
terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_ecr_repository" "crewai_enterprise" {
  name = var.repository_name

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = var.repository_name
    Description = "Container registry for CrewAI builder"
  }
}
