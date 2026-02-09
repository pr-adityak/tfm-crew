apiVersion: troubleshoot.sh/v1beta2
kind: Preflight
metadata:
  name: crewai-azure-preflight
spec:
  collectors:
    # ============================================================================
    # Azure PostgreSQL Connectivity Check
    # Uses database-credentials secret from platform namespace
    # ============================================================================
    - runPod:
        name: postgres-test
        namespace: platform
        podSpec:
          restartPolicy: Never
          containers:
            - name: postgres-test
              image: postgres:16-alpine
              env:
                - name: DB_HOST
                  valueFrom:
                    secretKeyRef:
                      name: database-credentials
                      key: host
                - name: DB_PORT
                  valueFrom:
                    secretKeyRef:
                      name: database-credentials
                      key: port
                - name: DB_NAME
                  valueFrom:
                    secretKeyRef:
                      name: database-credentials
                      key: database
                - name: DB_USER
                  valueFrom:
                    secretKeyRef:
                      name: database-credentials
                      key: username
                - name: DB_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: database-credentials
                      key: password
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting Azure PostgreSQL Connection Test ==="

                  echo "Building connection string..."
                  export PGPASSWORD="${DB_PASSWORD}"

                  echo "Attempting connection to Azure PostgreSQL Flexible Server..."
                  echo "Host: ${DB_HOST}"
                  echo "Port: ${DB_PORT}"
                  echo "Database: ${DB_NAME}"
                  echo "User: ${DB_USER}"

                  VERSION=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT version();" 2>&1)

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not connect to Azure PostgreSQL"
                    echo "$VERSION"
                    exit 1
                  fi

                  echo "Connected successfully!"
                  echo "PostgreSQL version: $VERSION"

                  # Extract major version number (BusyBox-compatible)
                  MAJOR_VERSION=$(echo "$VERSION" | sed -n 's/.*PostgreSQL \([0-9]*\).*/\1/p')
                  echo "Major version detected: $MAJOR_VERSION"

                  if [ -z "$MAJOR_VERSION" ]; then
                    echo "FAIL: Could not parse PostgreSQL version"
                    exit 1
                  fi

                  if [ "$MAJOR_VERSION" -lt 16 ]; then
                    echo "FAIL: PostgreSQL version must be 16.x or higher (found $MAJOR_VERSION.x)"
                    exit 1
                  fi

                  echo "SUCCESS: Azure PostgreSQL connected (PostgreSQL $MAJOR_VERSION.x)"

    # ============================================================================
    # Azure Blob Storage - Data Storage Account Read/Write Test
    # Uses kubelet managed identity with Storage Blob Data Contributor role
    # ============================================================================
    - runPod:
        name: blob-data-test
        namespace: platform
        podSpec:
          restartPolicy: Never
          containers:
            - name: blob-test
              image: mcr.microsoft.com/azure-cli:latest
              env:
                - name: STORAGE_ACCOUNT_NAME
                  value: "${DATA_STORAGE_ACCOUNT_NAME}"
                - name: CONTAINER_NAME
                  value: "data"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting Azure Blob Storage (Data) Read/Write Test ==="

                  echo "Logging in with managed identity..."
                  az login --identity --allow-no-subscriptions 2>&1 || {
                    echo "FAIL: Could not authenticate with managed identity"
                    exit 1
                  }

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test blob to ${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}..."
                  az storage blob upload \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --file "/tmp/${TEST_FILE}" \
                    --auth-mode login 2>&1

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload blob to data storage account"
                    exit 1
                  fi

                  echo "Downloading test blob..."
                  az storage blob download \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --file "/tmp/${TEST_FILE}-downloaded" \
                    --auth-mode login 2>&1

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not download blob from data storage account"
                    exit 1
                  fi

                  echo "Verifying content..."
                  ORIGINAL=$(cat /tmp/${TEST_FILE})
                  DOWNLOADED=$(cat /tmp/${TEST_FILE}-downloaded)
                  if [ "$ORIGINAL" = "$DOWNLOADED" ]; then
                    echo "Content verified successfully"
                  else
                    echo "FAIL: Downloaded content does not match uploaded content"
                    exit 1
                  fi

                  echo "Cleaning up test blob..."
                  az storage blob delete \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --auth-mode login 2>&1

                  echo "SUCCESS: Data storage account read/write validated"

    # ============================================================================
    # Azure Blob Storage - Logs Storage Account Read/Write Test
    # Uses kubelet managed identity with Storage Blob Data Contributor role
    # ============================================================================
    - runPod:
        name: blob-logs-test
        namespace: platform
        podSpec:
          restartPolicy: Never
          containers:
            - name: blob-test
              image: mcr.microsoft.com/azure-cli:latest
              env:
                - name: STORAGE_ACCOUNT_NAME
                  value: "${LOGS_STORAGE_ACCOUNT_NAME}"
                - name: CONTAINER_NAME
                  value: "logs"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting Azure Blob Storage (Logs) Read/Write Test ==="

                  echo "Logging in with managed identity..."
                  az login --identity --allow-no-subscriptions 2>&1 || {
                    echo "FAIL: Could not authenticate with managed identity"
                    exit 1
                  }

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test blob to ${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}..."
                  az storage blob upload \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --file "/tmp/${TEST_FILE}" \
                    --auth-mode login 2>&1

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload blob to logs storage account"
                    exit 1
                  fi

                  echo "Downloading test blob..."
                  az storage blob download \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --file "/tmp/${TEST_FILE}-downloaded" \
                    --auth-mode login 2>&1

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not download blob from logs storage account"
                    exit 1
                  fi

                  echo "Verifying content..."
                  ORIGINAL=$(cat /tmp/${TEST_FILE})
                  DOWNLOADED=$(cat /tmp/${TEST_FILE}-downloaded)
                  if [ "$ORIGINAL" = "$DOWNLOADED" ]; then
                    echo "Content verified successfully"
                  else
                    echo "FAIL: Downloaded content does not match uploaded content"
                    exit 1
                  fi

                  echo "Cleaning up test blob..."
                  az storage blob delete \
                    --account-name "${STORAGE_ACCOUNT_NAME}" \
                    --container-name "${CONTAINER_NAME}" \
                    --name "${TEST_FILE}" \
                    --auth-mode login 2>&1

                  echo "SUCCESS: Logs storage account read/write validated"

    # ============================================================================
    # Azure Container Registry Push Test
    # Uses kubelet managed identity - requires AcrPush role
    # ============================================================================
    - runPod:
        name: acr-push-test
        namespace: platform
        podSpec:
          restartPolicy: Never
          containers:
            - name: acr-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: REGISTRY_LOGIN_SERVER
                  value: "${REGISTRY_LOGIN_SERVER}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting ACR Push Test ==="

                  echo "Getting access token from Azure IMDS..."
                  TOKEN_RESPONSE=$(curl -s -H "Metadata: true" \
                    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" 2>&1)

                  if echo "$TOKEN_RESPONSE" | grep -q '"error"'; then
                    echo "FAIL: Could not get access token from Azure IMDS"
                    echo "$TOKEN_RESPONSE"
                    exit 1
                  fi

                  echo "Exchanging AAD token for ACR refresh token..."
                  AAD_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  ACR_REFRESH=$(curl -s -X POST \
                    "https://${REGISTRY_LOGIN_SERVER}/oauth2/exchange" \
                    -H "Content-Type: application/x-www-form-urlencoded" \
                    -d "grant_type=access_token&service=${REGISTRY_LOGIN_SERVER}&access_token=${AAD_TOKEN}" 2>&1)

                  if echo "$ACR_REFRESH" | grep -q '"error"'; then
                    echo "FAIL: Could not exchange AAD token for ACR token"
                    echo "$ACR_REFRESH"
                    exit 1
                  fi

                  REFRESH_TOKEN=$(echo "$ACR_REFRESH" | grep -o '"refresh_token":"[^"]*' | cut -d'"' -f4)

                  echo "Getting ACR access token for push..."
                  ACR_ACCESS=$(curl -s -X POST \
                    "https://${REGISTRY_LOGIN_SERVER}/oauth2/token" \
                    -H "Content-Type: application/x-www-form-urlencoded" \
                    -d "grant_type=refresh_token&service=${REGISTRY_LOGIN_SERVER}&scope=repository:preflight-test:push,pull&refresh_token=${REFRESH_TOKEN}" 2>&1)

                  ACCESS_TOKEN=$(echo "$ACR_ACCESS" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  if [ -z "$ACCESS_TOKEN" ]; then
                    echo "FAIL: Could not get ACR access token"
                    echo "$ACR_ACCESS"
                    exit 1
                  fi

                  echo "Token retrieved successfully"

                  echo "Pushing alpine image from Docker Hub to ACR..."
                  skopeo copy \
                    docker://docker.io/library/alpine:latest \
                    docker://${REGISTRY_LOGIN_SERVER}/preflight-test:latest \
                    --dest-creds="00000000-0000-0000-0000-000000000000:${ACCESS_TOKEN}"

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not push image to ACR"
                    exit 1
                  fi

                  echo "SUCCESS: ACR push validated"

    # ============================================================================
    # Azure Container Registry Pull Test
    # Uses kubelet managed identity - requires AcrPull role
    # ============================================================================
    - runPod:
        name: acr-pull-test
        namespace: platform
        podSpec:
          restartPolicy: Never
          containers:
            - name: acr-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: REGISTRY_LOGIN_SERVER
                  value: "${REGISTRY_LOGIN_SERVER}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting ACR Pull Test ==="

                  echo "Getting access token from Azure IMDS..."
                  TOKEN_RESPONSE=$(curl -s -H "Metadata: true" \
                    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" 2>&1)

                  if echo "$TOKEN_RESPONSE" | grep -q '"error"'; then
                    echo "FAIL: Could not get access token from Azure IMDS"
                    echo "$TOKEN_RESPONSE"
                    exit 1
                  fi

                  echo "Exchanging AAD token for ACR refresh token..."
                  AAD_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  ACR_REFRESH=$(curl -s -X POST \
                    "https://${REGISTRY_LOGIN_SERVER}/oauth2/exchange" \
                    -H "Content-Type: application/x-www-form-urlencoded" \
                    -d "grant_type=access_token&service=${REGISTRY_LOGIN_SERVER}&access_token=${AAD_TOKEN}" 2>&1)

                  if echo "$ACR_REFRESH" | grep -q '"error"'; then
                    echo "FAIL: Could not exchange AAD token for ACR token"
                    echo "$ACR_REFRESH"
                    exit 1
                  fi

                  REFRESH_TOKEN=$(echo "$ACR_REFRESH" | grep -o '"refresh_token":"[^"]*' | cut -d'"' -f4)

                  echo "Getting ACR access token for pull..."
                  ACR_ACCESS=$(curl -s -X POST \
                    "https://${REGISTRY_LOGIN_SERVER}/oauth2/token" \
                    -H "Content-Type: application/x-www-form-urlencoded" \
                    -d "grant_type=refresh_token&service=${REGISTRY_LOGIN_SERVER}&scope=repository:preflight-test:pull&refresh_token=${REFRESH_TOKEN}" 2>&1)

                  ACCESS_TOKEN=$(echo "$ACR_ACCESS" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  if [ -z "$ACCESS_TOKEN" ]; then
                    echo "FAIL: Could not get ACR access token"
                    echo "$ACR_ACCESS"
                    exit 1
                  fi

                  echo "Token retrieved successfully"

                  echo "Inspecting preflight-test image from ACR..."
                  skopeo inspect \
                    docker://${REGISTRY_LOGIN_SERVER}/preflight-test:latest \
                    --creds="00000000-0000-0000-0000-000000000000:${ACCESS_TOKEN}"

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not pull/inspect image from ACR"
                    exit 1
                  fi

                  echo "SUCCESS: ACR pull validated"

  analyzers:
    # ============================================================================
    # PostgreSQL Connection and Version Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: Azure PostgreSQL Connection
        fileName: postgres-test/postgres-test.log
        regex: 'SUCCESS: Azure PostgreSQL connected'
        outcomes:
          - pass:
              when: "true"
              message: Azure PostgreSQL Flexible Server connection validated successfully
          - fail:
              when: "false"
              message: Failed to connect to Azure PostgreSQL - check database-credentials secret and network connectivity

    # ============================================================================
    # Data Storage Blob Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: Data Storage Account Access
        fileName: blob-data-test/blob-data-test.log
        regex: 'SUCCESS: Data storage account read/write validated'
        outcomes:
          - pass:
              when: "true"
              message: Data storage account read/write access validated successfully
          - fail:
              when: "false"
              message: Failed to access data storage account - check kubelet identity has Storage Blob Data Contributor role

    # ============================================================================
    # Logs Storage Blob Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: Logs Storage Account Access
        fileName: blob-logs-test/blob-logs-test.log
        regex: 'SUCCESS: Logs storage account read/write validated'
        outcomes:
          - pass:
              when: "true"
              message: Logs storage account read/write access validated successfully
          - fail:
              when: "false"
              message: Failed to access logs storage account - check kubelet identity has Storage Blob Data Contributor role

    # ============================================================================
    # ACR Push Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: ACR Push Test
        fileName: acr-push-test/acr-push-test.log
        regex: 'SUCCESS: ACR push validated'
        outcomes:
          - pass:
              when: "true"
              message: Azure Container Registry push validated successfully
          - fail:
              when: "false"
              message: Failed to push to ACR - check kubelet identity has AcrPush role

    # ============================================================================
    # ACR Pull Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: ACR Pull Test
        fileName: acr-pull-test/acr-pull-test.log
        regex: 'SUCCESS: ACR pull validated'
        outcomes:
          - pass:
              when: "true"
              message: Azure Container Registry pull validated successfully
          - fail:
              when: "false"
              message: Failed to pull from ACR - check kubelet identity has AcrPull role and that push test passed first
