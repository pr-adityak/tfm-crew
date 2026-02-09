output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.crewai_enterprise.name
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.crewai_enterprise.arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.crewai_enterprise.repository_url
}
