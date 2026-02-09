# CrewAI Infrastructure - Terraform Deployment

## Prerequisites

### Required Software
- [Terraform](https://www.terraform.io/downloads) >= 1.13.4
- [AWS CLI](https://aws.amazon.com/cli/) (for credential configuration)

### AWS Permissions
**Current Requirement**: The user or role running Terraform must have `AdministratorAccess` policy attached.

> **Note**: We are working on documenting minimal required permissions. For now, administrator access ensures all resources can be created successfully.

## Quick Start

### Step 1: Configure AWS Credentials

Set up your AWS credentials using one of these methods:

#### Option A: Using AWS CLI Profile (Recommended)
```bash
aws configure --profile crewai
# Enter your AWS Access Key ID and Secret Access Key when prompted
# Set your preferred region (e.g., us-east-1)
```

Then export the profile:
```bash
export AWS_PROFILE=crewai
```

#### Option B: Using Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
export AWS_REGION="us-east-1"  # or your preferred region
```

### Step 2: Configure Terraform Variables

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your specific values:
- Update S3 bucket names (must be globally unique)
- Add your CrewAI secrets from 1Password
- Configure authentication provider if needed

### Step 3: Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the infrastructure
terraform apply
```

When prompted, type `yes` to confirm the deployment.

## Configuration Guide

### Required Variables
These must be set in your `terraform.tfvars`:

| Variable | Description | Example |
|----------|-------------|---------|
| `region` | AWS region for deployment | `us-east-1` |
| `environment` | Environment name | `production` |
| `s3_data_bucket_name` | Unique S3 bucket for data | `crewai-data-prod-12345` |
| `s3_logs_bucket_name` | Unique S3 bucket for logs | `crewai-logs-prod-12345` |
| `platform_master_key` | Platform key from 1Password | `[secret]` |
| `github_token` | GitHub token from 1Password | `[secret]` |

### Optional Variables
These have sensible defaults but can be customized:

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zone_count` | Number of AZs for HA | `2` |
| `db_instance_class` | Database instance type | `db.t4g.medium` |
| `alb_is_public` | Make ALB internet-facing | `false` |

## Module Architecture

The infrastructure is organized into reusable modules:

```
terraform/
├── main.tf                 # Root configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
└── modules/
    ├── crewai-platform/  # Main platform module
    ├── networking/       # VPC, subnets, ALB
    ├── database/         # Aurora PostgreSQL
    ├── storage/          # S3 buckets
    ├── secrets/          # Secrets Manager
    ├── ecr/             # Container registries
    └── iam/             # IAM roles and policies
```

## Key Resources Created

This Terraform configuration creates:

- **Networking**: VPC with public/private subnets across multiple AZs
- **Database**: Aurora PostgreSQL cluster
- **Storage**: S3 buckets for data and logs
- **Container Registry**: ECR repositories for Docker images
- **Load Balancer**: Application Load Balancer with HTTPS support
- **Secrets**: AWS Secrets Manager for sensitive configuration
- **IAM**: Roles and policies for service permissions

### Useful Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show planned changes
terraform plan

# Apply specific targets
terraform apply -target=module.crewai_platform.module.networking

# Destroy infrastructure (WARNING: deletes everything)
terraform destroy
```

