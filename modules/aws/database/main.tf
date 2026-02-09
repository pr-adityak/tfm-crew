# Database Module - Aurora PostgreSQL Setup
# Direct translation from Ansible 06-aurora-setup.yml

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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Database Security Group
# NOTE: No inline ingress/egress rules - all rules managed as separate resources
resource "aws_security_group" "database" {
  name        = "${var.name_prefix}db-sg"
  description = "CrewAI Aurora PostgreSQL Database Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}db-sg"
  }
}

# Security Group Rules - Managed separately to avoid conflicts with external rule additions
resource "aws_security_group_rule" "database_ingress_vpc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.database.id
  description       = "PostgreSQL access from VPC"
}

resource "aws_security_group_rule" "database_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "Allow all outbound traffic"
}

# DB Subnet Group
resource "aws_db_subnet_group" "database" {
  name        = "${var.name_prefix}${var.db_cluster_identifier}-subnet-group"
  description = "CrewAI Database Subnet Group"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}${var.db_cluster_identifier}-subnet-group"
  }
}

# Generate database password
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "database" {
  cluster_identifier     = var.db_cluster_identifier
  engine                 = "aurora-postgresql"
  engine_version         = var.db_engine_version
  database_name          = var.db_database_name
  master_username        = var.db_master_username
  master_password        = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  # Backup configuration
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"

  # Encryption
  storage_encrypted = true

  # Maintenance window
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # Enable logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Prevent accidental deletion
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.db_cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = var.db_cluster_identifier
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  lifecycle {
    ignore_changes = [
      master_password,
      final_snapshot_identifier
    ]
  }
}

# Aurora Cluster Writer Instance
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.db_cluster_identifier}-writer"
  cluster_identifier = aws_rds_cluster.database.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.database.engine
  engine_version     = aws_rds_cluster.database.engine_version

  tags = {
    Name = "${var.db_cluster_identifier}-writer"
    Role = "writer"
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# Aurora Cluster Reader Instance(s) for High Availability
resource "aws_rds_cluster_instance" "reader" {
  count = var.reader_instance_count

  identifier         = "${var.db_cluster_identifier}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.database.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.database.engine
  engine_version     = aws_rds_cluster.database.engine_version

  # Aurora auto-distributes across AZs
  availability_zone = null

  tags = {
    Name = "${var.db_cluster_identifier}-reader-${count.index + 1}"
    Role = "reader"
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# Validation
resource "null_resource" "validate_subnets" {
  lifecycle {
    precondition {
      condition     = length(var.private_subnet_ids) >= 2
      error_message = "Aurora requires at least 2 private subnets in different Availability Zones. Found ${length(var.private_subnet_ids)} private subnets."
    }
  }
}