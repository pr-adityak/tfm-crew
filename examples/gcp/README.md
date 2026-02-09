# CrewAI Infrastructure - GCP Deployment

This example demonstrates deploying the CrewAI platform infrastructure on Google Cloud Platform (GCP) using Terraform.

## Prerequisites

### Required Software
- [Terraform](https://www.terraform.io/downloads) >= 1.13.4
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) (for authentication and cluster access)

### GCP Requirements
- GCP Project with billing enabled
- Project Owner or Editor role (for initial deployment)

## Quick Start

### Step 1: Authenticate with GCP

```bash
# Authenticate with your Google account
gcloud auth login

# Set your default project
gcloud config set project YOUR_PROJECT_ID

# Set up Application Default Credentials for Terraform
gcloud auth application-default login
```

### Step 2: Enable Required APIs

```bash
# Enable required GCP APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable storage-api.googleapis.com
```

### Step 3: Configure Terraform Variables

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your specific values:
- Update `project_id` with your GCP project ID
- Update GCS bucket names (must be globally unique)
- Add your CrewAI secrets from 1Password
- Configure authentication provider if needed

### Step 4: Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the infrastructure
terraform apply
```

When prompted, type `yes` to confirm the deployment.

### Step 5: Configure kubectl Access

After deployment completes, configure kubectl to access your GKE cluster:

```bash
# Get cluster credentials (command shown in terraform output)
gcloud container clusters get-credentials crewai-cluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID

# Verify cluster access
kubectl get nodes
```

### Step 6: Set Up Workload Identity

Create the Kubernetes namespace and service account for CrewAI workloads:

```bash
# Create namespace
kubectl create namespace crewai-platform

# Create service account
kubectl create serviceaccount crewai-platform-sa -n crewai-platform

# Annotate service account for Workload Identity
# (Replace with the actual service account email from terraform output)
kubectl annotate serviceaccount crewai-platform-sa \
  -n crewai-platform \
  iam.gke.io/gcp-service-account=crewai-workload@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

## Configuration Guide

### Required Variables

These must be set in your `terraform.tfvars`:

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP project ID | `my-crewai-project` |
| `region` | GCP region for deployment | `us-central1` |
| `gcs_data_bucket_name` | Unique GCS bucket for data | `crewai-data-prod-12345` |
| `gcs_logs_bucket_name` | Unique GCS bucket for logs | `crewai-logs-prod-12345` |
| `platform_master_key` | Platform key from 1Password | `[secret]` |
| `github_token` | GitHub token from 1Password | `[secret]` |

### Optional Variables

These have sensible defaults but can be customized:

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `zone_count` | Number of zones for HA | `3` |
| `cluster_name` | GKE cluster name | `crewai-cluster` |
| `kubernetes_version` | Kubernetes version | `1.31` |
| `db_instance_tier` | Cloud SQL instance tier | `db-n1-standard-2` |
| `reader_instance_count` | Number of read replicas | `1` |

## Infrastructure Components

This deployment creates:

- **Networking**: VPC with private subnets across 3 zones, Cloud NAT for egress
- **Cluster**: GKE Autopilot (fully managed Kubernetes) with Workload Identity
- **Database**: Cloud SQL PostgreSQL with high availability and read replicas
- **Storage**: GCS buckets for data and logs with versioning and encryption
- **Secrets**: Secret Manager for sensitive configuration
- **IAM**: Service accounts and IAM bindings for Workload Identity

## Key Features

### GKE Autopilot

- Fully managed Kubernetes nodes (no node pool management)
- Automatic scaling based on pod resource requests
- Built-in security best practices
- Pay only for requested pod resources

### Workload Identity

Kubernetes pods automatically receive GCP credentials via Workload Identity:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: crewai-platform
spec:
  serviceAccountName: crewai-platform-sa  # Uses Workload Identity
  containers:
  - name: app
    image: gcr.io/my-project/my-app
    # Pod automatically has access to:
    # - Secret Manager (read secrets)
    # - Cloud SQL (database connections)
    # - GCS buckets (read/write data)
```

### Private Networking

- GKE nodes have no public IPs (private-only)
- Private Google Access enabled (pods reach GCP APIs via private network)
- Cloud NAT for internet egress (package downloads, webhooks)
- Cloud SQL uses private IP only (VPC peering)

## Accessing the Database

### From GKE Pods (Recommended)

Pods with Workload Identity can connect directly using the private IP:

```yaml
env:
- name: DB_HOST
  value: "10.x.x.x"  # Cloud SQL private IP (from terraform output)
- name: DB_NAME
  value: "crewai"
- name: DB_USER
  value: "postgres"
```

### From Local Machine (Development)

Use Cloud SQL Proxy for local development:

```bash
# Install Cloud SQL Proxy
gcloud components install cloud-sql-proxy

# Start proxy (replace with your connection name from terraform output)
cloud-sql-proxy YOUR_PROJECT:REGION:crewai-db &

# Connect via localhost
psql "host=127.0.0.1 port=5432 dbname=crewai user=postgres"
```

## Useful Commands

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show planned changes
terraform plan

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output value
terraform output cluster_name

# Destroy infrastructure (WARNING: deletes everything)
terraform destroy
```

## Troubleshooting

### API Not Enabled Error

If you see "API not enabled" errors, enable the required APIs:

```bash
gcloud services enable compute.googleapis.com container.googleapis.com sqladmin.googleapis.com servicenetworking.googleapis.com secretmanager.googleapis.com storage-api.googleapis.com
```

### Insufficient Permissions

Ensure your user or service account has the necessary IAM roles:
- `roles/owner` or `roles/editor` for initial deployment
- `roles/container.clusterAdmin` for GKE management
- `roles/cloudsql.admin` for Cloud SQL management
- `roles/compute.networkAdmin` for VPC management

### GCS Bucket Name Already Taken

GCS bucket names are globally unique. If your chosen name is taken:
- Add a unique suffix (e.g., your project ID or random string)
- Try a different naming pattern

### Cluster Access Issues

If you can't access the cluster with kubectl:

```bash
# Verify you're authenticated
gcloud auth list

# Verify project is set
gcloud config get-value project

# Get cluster credentials again
gcloud container clusters get-credentials crewai-cluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID

# Verify kubectl context
kubectl config current-context
```

### Workload Identity Not Working

Verify the service account annotation:

```bash
kubectl get serviceaccount crewai-platform-sa -n crewai-platform -o yaml

# Should show annotation:
# iam.gke.io/gcp-service-account: crewai-workload@PROJECT.iam.gserviceaccount.com
```

## Cost Estimation

Approximate monthly costs for this infrastructure (us-central1 region):

| Component | Configuration | Estimated Cost |
|-----------|--------------|----------------|
| GKE Autopilot | ~5 vCPU, ~20GB RAM | $150-200/month |
| Cloud SQL | db-n1-standard-2 + 1 replica | $300-350/month |
| Cloud NAT | 1 gateway + data processing | $40-60/month |
| GCS | 100GB data + 50GB logs | $5-10/month |
| Secret Manager | 1 secret, 1000 accesses/month | <$1/month |
| **Total** | | **~$500-620/month** |

**Notes:**
- GKE Autopilot charges based on actual pod resource requests, not allocated capacity
- Cloud SQL costs include backups and point-in-time recovery
- Cloud NAT charges per gateway hour + data processing fees
- GCS charges for storage + operations (minimal for typical use)

## Security Best Practices

- **Secrets**: Never commit `terraform.tfvars` to version control (add to `.gitignore`)
- **State**: Use GCS backend with encryption for remote state storage
- **Access**: Use least-privilege IAM roles for production
- **Networks**: Keep cluster API endpoint private or restrict to known IPs
- **Auditing**: Enable Cloud Audit Logs for compliance and monitoring

## Next Steps

1. Deploy CrewAI platform workloads to the cluster
2. Configure Ingress for HTTP(S) load balancing
3. Set up Cloud Monitoring and Cloud Logging
4. Configure Cloud Armor for DDoS protection
5. Implement backup and disaster recovery procedures

## Support

For issues or questions:
- Check Terraform output for helpful next-step commands
- Review GCP documentation: https://cloud.google.com/docs
- Check CrewAI platform documentation

## Cleanup

To destroy all infrastructure:

```bash
# WARNING: This will delete everything
terraform destroy
```

**Note:** Cloud SQL instances create final snapshots before deletion. These snapshots incur storage costs until manually deleted.
