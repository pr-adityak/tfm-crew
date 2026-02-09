# Networking Module - Creates VPC infrastructure or uses existing VPC
# Based on requirements gleaned from Ansible playbooks

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# ========================================
# DATA SOURCES FOR EXISTING VPC
# ========================================

# Fetch existing VPC when use_existing_vpc = true
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

# Fetch existing private subnets
data "aws_subnet" "existing_private" {
  count = var.use_existing_vpc ? length(var.existing_private_subnet_ids) : 0
  id    = var.existing_private_subnet_ids[count.index]
}

# Fetch existing public subnets (if provided)
data "aws_subnet" "existing_public" {
  count = var.use_existing_vpc ? length(var.existing_public_subnet_ids) : 0
  id    = var.existing_public_subnet_ids[count.index]
}

# ========================================
# LOCALS - Unified outputs for both modes
# ========================================

locals {
  # Determine subnet count for new VPC creation
  subnet_count = min(length(data.aws_availability_zones.available.names), max(2, var.az_count))

  # VPC values - use existing or created
  vpc_id   = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id
  vpc_cidr = var.use_existing_vpc ? data.aws_vpc.existing[0].cidr_block : aws_vpc.main[0].cidr_block

  # Subnet values - use existing or created
  private_subnet_ids   = var.use_existing_vpc ? var.existing_private_subnet_ids : aws_subnet.private[*].id
  public_subnet_ids    = var.use_existing_vpc ? var.existing_public_subnet_ids : aws_subnet.public[*].id
  private_subnet_cidrs = var.use_existing_vpc ? data.aws_subnet.existing_private[*].cidr_block : aws_subnet.private[*].cidr_block
  public_subnet_cidrs  = var.use_existing_vpc ? data.aws_subnet.existing_public[*].cidr_block : aws_subnet.public[*].cidr_block
  availability_zones   = var.use_existing_vpc ? data.aws_subnet.existing_private[*].availability_zone : aws_subnet.private[*].availability_zone

  # Determine if VPC endpoints should be created
  # Create endpoints when: creating new VPC OR (using existing VPC AND create_vpc_endpoints is true)
  create_vpc_endpoints = !var.use_existing_vpc || var.create_vpc_endpoints

  # For S3 gateway endpoint, we need route table IDs
  # When using existing VPC, we don't have route tables so S3 endpoint cannot be created
  create_s3_endpoint = !var.use_existing_vpc
}

# ========================================
# VPC RESOURCES (only when creating new VPC)
# ========================================

# VPC with DNS enabled (from 01-prerequisites.yml lines 158-163)
resource "aws_vpc" "main" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for VPC endpoints
  enable_dns_support   = true # Required for VPC endpoints

  tags = {
    Name = "${var.name_prefix}vpc"
  }
}

# Internet Gateway for public subnet connectivity
resource "aws_internet_gateway" "main" {
  count = var.use_existing_vpc ? 0 : 1

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.name_prefix}igw"
  }
}

# Public Subnets - One per AZ (minimum 2, max based on available AZs)
# Using /27 or larger as gleaned from Ansible (minimum 8 IPs requirement)
resource "aws_subnet" "public" {
  count = var.use_existing_vpc ? 0 : local.subnet_count

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.public_subnet_newbits, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.name_prefix}public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Type                     = "public"
    "kubernetes.io/role/elb" = "1" # Required for AWS Load Balancer Controller to discover subnets for internet-facing ALBs
  }
}

# Private Subnets - One per AZ (matching public subnets for ALB requirements)
# Larger /20 subnets (4096 IPs) to support compute workloads with many IPs
# Example with default /16 VPC: 10.0.16.0/20, 10.0.32.0/20, 10.0.48.0/20
resource "aws_subnet" "private" {
  count = var.use_existing_vpc ? 0 : local.subnet_count

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.private_subnet_newbits, count.index + 1) # Offset by 1 to start at 10.0.16.0/20
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                              = "${var.name_prefix}private-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1" # Required for AWS Load Balancer Controller to discover subnets for internal ALBs
  }
}

# Elastic IPs for NAT Gateways - One per AZ for high availability
resource "aws_eip" "nat" {
  count = var.use_existing_vpc ? 0 : local.subnet_count

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways for private subnet internet access - One per AZ for high availability
resource "aws_nat_gateway" "main" {
  count = var.use_existing_vpc ? 0 : local.subnet_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name_prefix}nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  count = var.use_existing_vpc ? 0 : 1

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.name_prefix}public-rt"
    Type = "public"
  }
}

# Public route to Internet Gateway
resource "aws_route" "public_internet" {
  count = var.use_existing_vpc ? 0 : 1

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = var.use_existing_vpc ? 0 : length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables - One per AZ for better isolation
resource "aws_route_table" "private" {
  count = var.use_existing_vpc ? 0 : length(aws_subnet.private)

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.name_prefix}private-rt-${count.index + 1}"
    Type = "private"
  }
}

# Private routes to NAT Gateway - Each route table uses its corresponding NAT gateway
resource "aws_route" "private_nat" {
  count = var.use_existing_vpc ? 0 : length(aws_route_table.private)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Associate private subnets with their route tables
resource "aws_route_table_association" "private" {
  count = var.use_existing_vpc ? 0 : length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ========================================
# VPC ENDPOINTS (conditional)
# ========================================

# Security group for VPC endpoints (from 01-prerequisites.yml lines 206-219)
resource "aws_security_group" "vpc_endpoints" {
  count = local.create_vpc_endpoints ? 1 : 0

  name        = "${var.name_prefix}vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTPS from VPC resources"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}vpc-endpoints-sg"
  }

  # Ensure proper cleanup during destroy
  lifecycle {
    create_before_destroy = false
  }

  revoke_rules_on_delete = true
}

# VPC Endpoints for AWS services (from 01-prerequisites.yml)
# Secrets Manager endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  count = local.create_vpc_endpoints ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}secretsmanager-endpoint"
  }

  depends_on = [
    aws_security_group.vpc_endpoints
  ]
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "logs" {
  count = local.create_vpc_endpoints ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}logs-endpoint"
  }

  depends_on = [
    aws_security_group.vpc_endpoints
  ]
}

# S3 Gateway endpoint (attached to route tables)
# Only created when creating new VPC (requires route table IDs)
resource "aws_vpc_endpoint" "s3" {
  count = local.create_s3_endpoint ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = {
    Name = "${var.name_prefix}s3-endpoint"
  }

  depends_on = [
    aws_route_table.private
  ]
}
