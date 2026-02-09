#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Reading values from terraform outputs..."

DATA_STORAGE=$(terraform output -raw data_storage_account_name)
LOGS_STORAGE=$(terraform output -raw logs_storage_account_name)
REGISTRY=$(terraform output -raw registry_login_server)

echo "  data_storage_account_name: $DATA_STORAGE"
echo "  logs_storage_account_name: $LOGS_STORAGE"
echo "  registry_login_server:     $REGISTRY"

echo ""
echo "Generating preflights/preflight.yaml..."

sed -e "s|\${DATA_STORAGE_ACCOUNT_NAME}|$DATA_STORAGE|g" \
    -e "s|\${LOGS_STORAGE_ACCOUNT_NAME}|$LOGS_STORAGE|g" \
    -e "s|\${REGISTRY_LOGIN_SERVER}|$REGISTRY|g" \
    "$SCRIPT_DIR/preflights/preflight.yaml.tpl" > "$SCRIPT_DIR/preflights/preflight.yaml"

echo "Done!"
echo ""
echo "Run preflight checks with:"
echo "  kubectl preflight preflights/preflight.yaml"
