# Networking Module Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = local.vpc_cidr
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = local.private_subnet_cidrs
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

# Gateway Outputs (null/empty when using existing VPC)
output "internet_gateway_id" {
  description = "ID of the Internet Gateway (null when using existing VPC)"
  value       = var.use_existing_vpc ? null : aws_internet_gateway.main[0].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (empty when using existing VPC)"
  value       = var.use_existing_vpc ? [] : aws_nat_gateway.main[*].id
}

output "nat_eip_public_ips" {
  description = "Public IP addresses of NAT Gateways (empty when using existing VPC)"
  value       = var.use_existing_vpc ? [] : aws_eip.nat[*].public_ip
}

# Route Table Outputs (null/empty when using existing VPC)
output "public_route_table_id" {
  description = "ID of the public route table (null when using existing VPC)"
  value       = var.use_existing_vpc ? null : aws_route_table.public[0].id
}

output "private_route_table_ids" {
  description = "List of private route table IDs (empty when using existing VPC)"
  value       = var.use_existing_vpc ? [] : aws_route_table.private[*].id
}

# Security Group Outputs
output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints (null when endpoints not created)"
  value       = local.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

# VPC Endpoint Outputs
output "vpc_endpoint_secretsmanager_id" {
  description = "ID of the Secrets Manager VPC endpoint (null when endpoints not created)"
  value       = local.create_vpc_endpoints ? aws_vpc_endpoint.secretsmanager[0].id : null
}

output "vpc_endpoint_logs_id" {
  description = "ID of the CloudWatch Logs VPC endpoint (null when endpoints not created)"
  value       = local.create_vpc_endpoints ? aws_vpc_endpoint.logs[0].id : null
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 Gateway VPC endpoint (null when using existing VPC)"
  value       = local.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

# Consolidated VPC endpoint IDs for dependency tracking
output "vpc_endpoint_ids" {
  description = "IDs of all VPC endpoints for dependency tracking (null values when not created)"
  value = {
    secretsmanager = local.create_vpc_endpoints ? aws_vpc_endpoint.secretsmanager[0].id : null
    logs           = local.create_vpc_endpoints ? aws_vpc_endpoint.logs[0].id : null
    s3             = local.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
  }
}

# Validation Outputs (matching Ansible's validation approach)
output "network_validation" {
  description = "Network configuration validation"
  value = {
    vpc_dns_enabled         = var.use_existing_vpc ? data.aws_vpc.existing[0].enable_dns_hostnames && data.aws_vpc.existing[0].enable_dns_support : aws_vpc.main[0].enable_dns_hostnames && aws_vpc.main[0].enable_dns_support
    public_subnet_count     = length(local.public_subnet_ids)
    private_subnet_count    = length(local.private_subnet_ids)
    availability_zone_count = length(distinct(local.availability_zones))
    nat_gateway_count       = var.use_existing_vpc ? null : length(aws_nat_gateway.main)
    meets_ha_requirements   = length(local.private_subnet_ids) >= 2 && length(distinct(local.availability_zones)) >= 2
    using_existing_vpc      = var.use_existing_vpc
  }
}
