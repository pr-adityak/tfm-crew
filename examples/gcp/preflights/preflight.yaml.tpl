apiVersion: troubleshoot.sh/v1beta2
kind: Preflight
metadata:
  name: crewai-gcp-preflight
spec:
  collectors:
    # ============================================================================
    # CloudSQL PostgreSQL Connectivity Check
    # Uses crewai-database secret from platform namespace
    # ============================================================================
    - runPod:
        name: cloudsql-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          restartPolicy: Never
          containers:
            - name: postgres-test
              image: postgres:16-alpine
              env:
                - name: DB_HOST
                  valueFrom:
                    secretKeyRef:
                      name: crewai-database
                      key: DB_HOST
                - name: DB_PORT
                  valueFrom:
                    secretKeyRef:
                      name: crewai-database
                      key: DB_PORT
                - name: DB_NAME
                  valueFrom:
                    secretKeyRef:
                      name: crewai-database
                      key: DB_NAME
                - name: DB_USER
                  valueFrom:
                    secretKeyRef:
                      name: crewai-database
                      key: DB_USER
                - name: DB_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: crewai-database
                      key: DB_PASSWORD
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting CloudSQL Connection Test ==="

                  echo "Building connection string..."
                  export PGPASSWORD="${DB_PASSWORD}"

                  echo "Attempting connection to CloudSQL..."
                  echo "Host: ${DB_HOST}"
                  echo "Port: ${DB_PORT}"
                  echo "Database: ${DB_NAME}"
                  echo "User: ${DB_USER}"

                  VERSION=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT version();" 2>&1)

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not connect to CloudSQL"
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

                  # Test write capability
                  echo "Testing write capability..."
                  WRITE_TEST=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT 1;" 2>&1)
                  if [ $? -ne 0 ]; then
                    echo "FAIL: Write test failed"
                    echo "$WRITE_TEST"
                    exit 1
                  fi

                  echo "SUCCESS: CloudSQL connected (PostgreSQL $MAJOR_VERSION.x)"

    # ============================================================================
    # GCS Data Bucket Read/Write Test
    # Uses node service account via GKE metadata service
    # ============================================================================
    - runPod:
        name: gcs-data-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          restartPolicy: Never
          containers:
            - name: gcs-test
              image: google/cloud-sdk:slim
              env:
                - name: GCS_BUCKET_NAME
                  value: "${GCS_DATA_BUCKET}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting GCS Data Bucket Read/Write Test ==="

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test object to gs://${GCS_BUCKET_NAME}/${TEST_FILE}..."
                  gsutil cp /tmp/${TEST_FILE} gs://${GCS_BUCKET_NAME}/${TEST_FILE}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload object to GCS data bucket"
                    exit 1
                  fi

                  echo "Downloading test object..."
                  gsutil cp gs://${GCS_BUCKET_NAME}/${TEST_FILE} /tmp/${TEST_FILE}-downloaded

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not download object from GCS data bucket"
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

                  echo "Cleaning up test object..."
                  gsutil rm gs://${GCS_BUCKET_NAME}/${TEST_FILE}

                  echo "SUCCESS: GCS data bucket read/write validated"

    # ============================================================================
    # GCS Logs Bucket Write Test
    # Uses node service account via GKE metadata service
    # Note: Logs bucket only has objectCreator role (write-only by design)
    # ============================================================================
    - runPod:
        name: gcs-logs-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          restartPolicy: Never
          containers:
            - name: gcs-test
              image: google/cloud-sdk:slim
              env:
                - name: GCS_BUCKET_NAME
                  value: "${GCS_LOGS_BUCKET}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting GCS Logs Bucket Write Test ==="

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test object to gs://${GCS_BUCKET_NAME}/${TEST_FILE}..."
                  gsutil cp /tmp/${TEST_FILE} gs://${GCS_BUCKET_NAME}/${TEST_FILE}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload object to GCS logs bucket"
                    exit 1
                  fi

                  echo "SUCCESS: GCS logs bucket write validated"

    # ============================================================================
    # Google Artifact Registry Push Test
    # Uses node service account via GKE metadata service
    # ============================================================================
    - runPod:
        name: gar-push-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          restartPolicy: Never
          containers:
            - name: gar-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: REGISTRY_URI
                  value: "${REGISTRY_URI}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting GAR Push Test ==="

                  echo "Authenticating to GAR using node service account..."
                  # Get access token from GKE metadata service
                  TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
                    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token | \
                    grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  if [ -z "$TOKEN" ]; then
                    echo "FAIL: Could not get access token from metadata service"
                    exit 1
                  fi

                  echo "Token retrieved successfully"

                  echo "Copying alpine from Docker Hub to GAR..."
                  skopeo copy \
                    docker://docker.io/library/alpine:latest \
                    docker://${REGISTRY_URI}/preflight-test:latest \
                    --dest-creds=oauth2accesstoken:${TOKEN}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not push image to GAR"
                    exit 1
                  fi

                  echo "SUCCESS: GAR push validated"

    # ============================================================================
    # Google Artifact Registry Pull Test
    # Uses node service account via GKE metadata service
    # ============================================================================
    - runPod:
        name: gar-pull-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          restartPolicy: Never
          containers:
            - name: gar-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: REGISTRY_URI
                  value: "${REGISTRY_URI}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting GAR Pull Test ==="

                  echo "Authenticating to GAR using node service account..."
                  # Get access token from GKE metadata service
                  TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
                    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token | \
                    grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

                  if [ -z "$TOKEN" ]; then
                    echo "FAIL: Could not get access token from metadata service"
                    exit 1
                  fi

                  echo "Token retrieved successfully"

                  echo "Inspecting preflight-test image from GAR..."
                  skopeo inspect \
                    docker://${REGISTRY_URI}/preflight-test:latest \
                    --creds=oauth2accesstoken:${TOKEN}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not pull/inspect image from GAR"
                    exit 1
                  fi

                  echo "SUCCESS: GAR pull validated"

  analyzers:
    # ============================================================================
    # CloudSQL Connection Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: CloudSQL Connection
        fileName: cloudsql-test/cloudsql-test.log
        regex: 'SUCCESS: CloudSQL connected'
        outcomes:
          - pass:
              when: "true"
              message: CloudSQL connection validated successfully
          - fail:
              when: "false"
              message: Failed to connect to CloudSQL - check crewai-database secret and network connectivity

    # ============================================================================
    # GCS Data Bucket Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: GCS Data Bucket Access
        fileName: gcs-data-test/gcs-data-test.log
        regex: 'SUCCESS: GCS data bucket read/write validated'
        outcomes:
          - pass:
              when: "true"
              message: GCS data bucket read/write access validated successfully
          - fail:
              when: "false"
              message: Failed to access GCS data bucket - check node service account has roles/storage.objectAdmin

    # ============================================================================
    # GCS Logs Bucket Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: GCS Logs Bucket Access
        fileName: gcs-logs-test/gcs-logs-test.log
        regex: 'SUCCESS: GCS logs bucket write validated'
        outcomes:
          - pass:
              when: "true"
              message: GCS logs bucket write access validated successfully
          - fail:
              when: "false"
              message: Failed to write to GCS logs bucket - check node service account has roles/storage.objectCreator

    # ============================================================================
    # GAR Push Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: GAR Push Test
        fileName: gar-push-test/gar-push-test.log
        regex: 'SUCCESS: GAR push validated'
        outcomes:
          - pass:
              when: "true"
              message: Artifact Registry push validated successfully
          - fail:
              when: "false"
              message: Failed to push to Artifact Registry - check node service account has roles/artifactregistry.writer

    # ============================================================================
    # GAR Pull Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: GAR Pull Test
        fileName: gar-pull-test/gar-pull-test.log
        regex: 'SUCCESS: GAR pull validated'
        outcomes:
          - pass:
              when: "true"
              message: Artifact Registry pull validated successfully
          - fail:
              when: "false"
              message: Failed to pull from Artifact Registry - check node service account has roles/artifactregistry.reader and that push test passed first
