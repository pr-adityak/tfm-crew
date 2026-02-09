#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Reading values from terraform outputs..."

# Get individual outputs
PLATFORM_NAMESPACE=$(terraform output -raw workload_namespace)
REGISTRY_URI=$(terraform output -raw registry_uri)
GCS_DATA_BUCKET=$(terraform output -raw gcs_data_bucket)
GCS_LOGS_BUCKET=$(terraform output -raw gcs_logs_bucket)

echo "  platform_namespace: $PLATFORM_NAMESPACE"
echo "  registry_uri:       $REGISTRY_URI"
echo "  gcs_data_bucket:    $GCS_DATA_BUCKET"
echo "  gcs_logs_bucket:    $GCS_LOGS_BUCKET"

echo ""
echo "Generating preflights/preflight.yaml..."

sed -e "s|\${PLATFORM_NAMESPACE}|$PLATFORM_NAMESPACE|g" \
    -e "s|\${REGISTRY_URI}|$REGISTRY_URI|g" \
    -e "s|\${GCS_DATA_BUCKET}|$GCS_DATA_BUCKET|g" \
    -e "s|\${GCS_LOGS_BUCKET}|$GCS_LOGS_BUCKET|g" \
    "$SCRIPT_DIR/preflights/preflight.yaml.tpl" > "$SCRIPT_DIR/preflights/preflight.yaml"

echo "Done!"
echo ""
echo "Run preflight checks with:"
echo "  kubectl preflight preflights/preflight.yaml"
