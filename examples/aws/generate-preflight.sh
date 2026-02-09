#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Reading values from terraform outputs..."

# Get platform summary as JSON for easier parsing
PLATFORM_SUMMARY=$(terraform output -json platform_summary)

# Extract individual values using jq
S3_DATA_BUCKET=$(echo "$PLATFORM_SUMMARY" | jq -r '.data_bucket')
S3_LOGS_BUCKET=$(echo "$PLATFORM_SUMMARY" | jq -r '.logs_bucket')
ECR_REPOSITORY_URL=$(echo "$PLATFORM_SUMMARY" | jq -r '.ecr_repository_url')
AWS_REGION=$(echo "$PLATFORM_SUMMARY" | jq -r '.region')
PLATFORM_NAMESPACE=$(echo "$PLATFORM_SUMMARY" | jq -r '.workload_namespace')
WORKLOAD_SERVICE_ACCOUNT=$(echo "$PLATFORM_SUMMARY" | jq -r '.workload_service_account')

echo "  s3_data_bucket:     $S3_DATA_BUCKET"
echo "  s3_logs_bucket:     $S3_LOGS_BUCKET"
echo "  ecr_repository_url: $ECR_REPOSITORY_URL"
echo "  aws_region:         $AWS_REGION"
echo "  platform_namespace: $PLATFORM_NAMESPACE"
echo "  service_account:    $WORKLOAD_SERVICE_ACCOUNT"

echo ""
echo "Generating preflights/preflight.yaml..."

sed -e "s|\${S3_DATA_BUCKET}|$S3_DATA_BUCKET|g" \
    -e "s|\${S3_LOGS_BUCKET}|$S3_LOGS_BUCKET|g" \
    -e "s|\${ECR_REPOSITORY_URL}|$ECR_REPOSITORY_URL|g" \
    -e "s|\${AWS_REGION}|$AWS_REGION|g" \
    -e "s|\${PLATFORM_NAMESPACE}|$PLATFORM_NAMESPACE|g" \
    -e "s|\${WORKLOAD_SERVICE_ACCOUNT}|$WORKLOAD_SERVICE_ACCOUNT|g" \
    "$SCRIPT_DIR/preflights/preflight.yaml.tpl" > "$SCRIPT_DIR/preflights/preflight.yaml"

echo "Done!"
echo ""
echo "Run preflight checks with:"
echo "  kubectl preflight preflights/preflight.yaml"
