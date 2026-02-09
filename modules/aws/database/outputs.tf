# Database Module Outputs

# Cluster Outputs
output "cluster_id" {
  description = "ID of the Aurora cluster"
  value       = aws_rds_cluster.database.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = aws_rds_cluster.database.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.database.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.database.reader_endpoint
}

output "cluster_port" {
  description = "Port number for the database"
  value       = aws_rds_cluster.database.port
}

# Database Configuration
output "master_username" {
  description = "Master username for the database"
  value       = aws_rds_cluster.database.master_username
}

# Security Group
output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# Subnet Group
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.database.name
}

# Instance Information
output "writer_instance_id" {
  description = "ID of the writer instance"
  value       = aws_rds_cluster_instance.writer.id
}

output "writer_instance_endpoint" {
  description = "Endpoint of the writer instance"
  value       = aws_rds_cluster_instance.writer.endpoint
}

# Reader Instance Information
output "reader_instance_ids" {
  description = "IDs of the reader instances"
  value       = aws_rds_cluster_instance.reader[*].id
}

output "reader_instance_endpoints" {
  description = "Endpoints of the reader instances"
  value       = aws_rds_cluster_instance.reader[*].endpoint
}

output "reader_instance_count" {
  description = "Number of reader instances deployed"
  value       = var.reader_instance_count
}

# Connection String Components (for application configuration)
output "connection_info" {
  description = "Database connection information for applications (database names managed externally)"
  value = {
    host     = aws_rds_cluster.database.endpoint
    port     = aws_rds_cluster.database.port
    username = aws_rds_cluster.database.master_username
  }
}

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}