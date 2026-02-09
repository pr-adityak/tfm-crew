# Azure Infrastructure Preflights

This directory contains [Replicated Troubleshoot](https://troubleshoot.sh/) preflight checks to validate the Azure infrastructure provisioned by Terraform.

## Prerequisites

1. Install the Troubleshoot kubectl plugin:
   ```bash
   kubectl krew install preflight
   ```

2. Ensure your kubeconfig is configured to access the AKS cluster:
   ```bash
   az aks get-credentials --resource-group crewai-rg --name crewai-aks
   ```

## Running Preflights

After `terraform apply` completes, generate and run the preflight checks:

```bash
./generate-preflight.sh
kubectl preflight preflights/preflight.yaml
```

The generator script reads values from Terraform outputs and populates the preflight template.

## What Gets Validated

### 1. Azure PostgreSQL Connectivity
- Verifies pods can connect to the PostgreSQL Flexible Server
- Uses the `database-credentials` secret in the `platform` namespace
- Validates PostgreSQL version is 16.x or higher

### 2. Data Storage Account Access
- Tests read/write access to the data blob storage account
- Uses AKS kubelet managed identity authentication
- Validates `Storage Blob Data Contributor` role is properly assigned

### 3. Logs Storage Account Access
- Tests read/write access to the logs blob storage account
- Uses AKS kubelet managed identity authentication
- Validates `Storage Blob Data Contributor` role is properly assigned

### 4. Azure Container Registry Push
- Tests push access to ACR (pushes alpine image)
- Uses managed identity with AAD token exchange
- Validates `AcrPush` role is properly assigned

### 5. Azure Container Registry Pull
- Tests pull access to ACR (inspects pushed image)
- Uses managed identity with AAD token exchange
- Validates `AcrPull` role is properly assigned

## Troubleshooting

### PostgreSQL Connection Failures
- Verify the `database-credentials` secret exists in `platform` namespace
- Check PostgreSQL Flexible Server firewall rules allow VNet access
- Verify private DNS zone is linked to the VNet

### Storage Account Access Failures
- Verify kubelet identity has `Storage Blob Data Contributor` role
- Check storage account network rules allow VNet access
- Verify private endpoints are correctly configured

### ACR Push Failures
- Verify kubelet identity has `AcrPush` role
- Check ACR network rules allow AKS access
- Verify the registry login server URL is correct

### ACR Pull Failures
- Verify kubelet identity has `AcrPull` role
- Ensure the push test passed first (image must exist)
- Check ACR network rules allow AKS access

## Architecture Notes

This preflight uses Azure-native authentication patterns:
- **Database**: Credentials from Kubernetes secret (provisioned by Terraform)
- **Storage**: Managed identity with `--auth-mode login` (no access keys)
- **ACR**: AAD token exchange via Azure IMDS

## Files

- `preflight.yaml.tpl` - Template with placeholders for Terraform values
- `preflight.yaml` - Generated file (git-ignored), created by `generate-preflight.sh`
