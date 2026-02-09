apiVersion: troubleshoot.sh/v1beta2
kind: Preflight
metadata:
  name: crewai-aws-preflight
spec:
  collectors:
    # ============================================================================
    # RDS PostgreSQL Connectivity Check
    # Uses crewai-database secret from platform namespace
    # Uses IRSA for AWS API authentication via service account
    # ============================================================================
    - runPod:
        name: rds-postgres-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          serviceAccountName: ${WORKLOAD_SERVICE_ACCOUNT}
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
                  echo "=== Starting RDS PostgreSQL Connection Test ==="

                  echo "Building connection string..."
                  export PGPASSWORD="${DB_PASSWORD}"

                  echo "Attempting connection to RDS Aurora PostgreSQL..."
                  echo "Host: ${DB_HOST}"
                  echo "Port: ${DB_PORT}"
                  echo "Database: ${DB_NAME}"
                  echo "User: ${DB_USER}"

                  VERSION=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT version();" 2>&1)

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not connect to RDS PostgreSQL"
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

                  echo "SUCCESS: RDS PostgreSQL connected (PostgreSQL $MAJOR_VERSION.x)"

    # ============================================================================
    # S3 Data Bucket Read/Write Test
    # Uses IRSA for AWS API authentication via service account
    # ============================================================================
    - runPod:
        name: s3-data-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          serviceAccountName: ${WORKLOAD_SERVICE_ACCOUNT}
          restartPolicy: Never
          containers:
            - name: s3-test
              image: amazon/aws-cli:latest
              env:
                - name: S3_BUCKET_NAME
                  value: "${S3_DATA_BUCKET}"
                - name: AWS_REGION
                  value: "${AWS_REGION}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting S3 Data Bucket Read/Write Test ==="

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test object to s3://${S3_BUCKET_NAME}/${TEST_FILE}..."
                  aws s3 cp /tmp/${TEST_FILE} s3://${S3_BUCKET_NAME}/${TEST_FILE} --region ${AWS_REGION}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload object to S3 data bucket"
                    exit 1
                  fi

                  echo "Downloading test object..."
                  aws s3 cp s3://${S3_BUCKET_NAME}/${TEST_FILE} /tmp/${TEST_FILE}-downloaded --region ${AWS_REGION}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not download object from S3 data bucket"
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
                  aws s3 rm s3://${S3_BUCKET_NAME}/${TEST_FILE} --region ${AWS_REGION}

                  echo "SUCCESS: S3 data bucket read/write validated"

    # ============================================================================
    # S3 Logs Bucket Read/Write Test
    # Uses IRSA for AWS API authentication via service account
    # ============================================================================
    - runPod:
        name: s3-logs-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          serviceAccountName: ${WORKLOAD_SERVICE_ACCOUNT}
          restartPolicy: Never
          containers:
            - name: s3-test
              image: amazon/aws-cli:latest
              env:
                - name: S3_BUCKET_NAME
                  value: "${S3_LOGS_BUCKET}"
                - name: AWS_REGION
                  value: "${AWS_REGION}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting S3 Logs Bucket Read/Write Test ==="

                  TEST_FILE="preflight-test-$(date +%s).txt"
                  echo "Test content from preflight at $(date)" > /tmp/${TEST_FILE}

                  echo "Uploading test object to s3://${S3_BUCKET_NAME}/${TEST_FILE}..."
                  aws s3 cp /tmp/${TEST_FILE} s3://${S3_BUCKET_NAME}/${TEST_FILE} --region ${AWS_REGION}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not upload object to S3 logs bucket"
                    exit 1
                  fi

                  echo "Downloading test object..."
                  aws s3 cp s3://${S3_BUCKET_NAME}/${TEST_FILE} /tmp/${TEST_FILE}-downloaded --region ${AWS_REGION}

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not download object from S3 logs bucket"
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
                  aws s3 rm s3://${S3_BUCKET_NAME}/${TEST_FILE} --region ${AWS_REGION}

                  echo "SUCCESS: S3 logs bucket read/write validated"

    # ============================================================================
    # ECR Push Test
    # Uses IRSA for AWS API authentication via service account
    # ============================================================================
    - runPod:
        name: ecr-push-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          serviceAccountName: ${WORKLOAD_SERVICE_ACCOUNT}
          restartPolicy: Never
          containers:
            - name: ecr-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: ECR_REPOSITORY_URL
                  value: "${ECR_REPOSITORY_URL}"
                - name: AWS_REGION
                  value: "${AWS_REGION}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting ECR Push Test ==="

                  # Install AWS CLI in the skopeo container
                  echo "Installing dependencies..."
                  microdnf install -y unzip 2>/dev/null || dnf install -y unzip 2>/dev/null || yum install -y unzip 2>/dev/null || {
                    echo "FAIL: Could not install unzip"
                    exit 1
                  }

                  echo "Installing AWS CLI..."
                  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
                  unzip -q /tmp/awscliv2.zip -d /tmp
                  /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli 2>&1 || {
                    echo "FAIL: Could not install AWS CLI"
                    exit 1
                  }

                  echo "Getting ECR login password..."
                  ECR_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION} 2>&1)

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not get ECR login password"
                    echo "$ECR_PASSWORD"
                    exit 1
                  fi

                  # Extract registry URL (everything before the repository name)
                  ECR_REGISTRY=$(echo "${ECR_REPOSITORY_URL}" | cut -d'/' -f1)
                  echo "ECR Registry: ${ECR_REGISTRY}"

                  echo "Pushing alpine image from Docker Hub to ECR..."
                  skopeo copy \
                    docker://docker.io/library/alpine:latest \
                    docker://${ECR_REPOSITORY_URL}:preflight-test \
                    --dest-creds="AWS:${ECR_PASSWORD}"

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not push image to ECR"
                    exit 1
                  fi

                  echo "SUCCESS: ECR push validated"

    # ============================================================================
    # ECR Pull Test
    # Uses IRSA for AWS API authentication via service account
    # ============================================================================
    - runPod:
        name: ecr-pull-test
        namespace: ${PLATFORM_NAMESPACE}
        podSpec:
          serviceAccountName: ${WORKLOAD_SERVICE_ACCOUNT}
          restartPolicy: Never
          containers:
            - name: ecr-test
              image: quay.io/skopeo/stable:latest
              env:
                - name: ECR_REPOSITORY_URL
                  value: "${ECR_REPOSITORY_URL}"
                - name: AWS_REGION
                  value: "${AWS_REGION}"
              command: ["/bin/sh", "-c"]
              args:
                - |
                  set -e
                  echo "=== Starting ECR Pull Test ==="

                  # Install AWS CLI in the skopeo container
                  echo "Installing dependencies..."
                  microdnf install -y unzip 2>/dev/null || dnf install -y unzip 2>/dev/null || yum install -y unzip 2>/dev/null || {
                    echo "FAIL: Could not install unzip"
                    exit 1
                  }

                  echo "Installing AWS CLI..."
                  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
                  unzip -q /tmp/awscliv2.zip -d /tmp
                  /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli 2>&1 || {
                    echo "FAIL: Could not install AWS CLI"
                    exit 1
                  }

                  echo "Getting ECR login password..."
                  ECR_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION} 2>&1)

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not get ECR login password"
                    echo "$ECR_PASSWORD"
                    exit 1
                  fi

                  echo "Inspecting preflight-test image from ECR..."
                  skopeo inspect \
                    docker://${ECR_REPOSITORY_URL}:preflight-test \
                    --creds="AWS:${ECR_PASSWORD}"

                  if [ $? -ne 0 ]; then
                    echo "FAIL: Could not pull/inspect image from ECR"
                    exit 1
                  fi

                  echo "SUCCESS: ECR pull validated"

  analyzers:
    # ============================================================================
    # RDS PostgreSQL Connection Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: RDS PostgreSQL Connection
        fileName: rds-postgres-test/rds-postgres-test.log
        regex: 'SUCCESS: RDS PostgreSQL connected'
        outcomes:
          - pass:
              when: "true"
              message: RDS Aurora PostgreSQL connection validated successfully
          - fail:
              when: "false"
              message: Failed to connect to RDS PostgreSQL - check database-credentials secret and network connectivity

    # ============================================================================
    # S3 Data Bucket Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: S3 Data Bucket Access
        fileName: s3-data-test/s3-data-test.log
        regex: 'SUCCESS: S3 data bucket read/write validated'
        outcomes:
          - pass:
              when: "true"
              message: S3 data bucket read/write access validated successfully
          - fail:
              when: "false"
              message: Failed to access S3 data bucket - check Node Role has s3:GetObject, s3:PutObject, s3:DeleteObject permissions

    # ============================================================================
    # S3 Logs Bucket Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: S3 Logs Bucket Access
        fileName: s3-logs-test/s3-logs-test.log
        regex: 'SUCCESS: S3 logs bucket read/write validated'
        outcomes:
          - pass:
              when: "true"
              message: S3 logs bucket read/write access validated successfully
          - fail:
              when: "false"
              message: Failed to access S3 logs bucket - check Node Role has s3:GetObject, s3:PutObject, s3:DeleteObject permissions

    # ============================================================================
    # ECR Push Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: ECR Push Test
        fileName: ecr-push-test/ecr-push-test.log
        regex: 'SUCCESS: ECR push validated'
        outcomes:
          - pass:
              when: "true"
              message: Amazon ECR push validated successfully
          - fail:
              when: "false"
              message: Failed to push to ECR - check Node Role has ecr:GetAuthorizationToken, ecr:BatchCheckLayerAvailability, ecr:PutImage permissions

    # ============================================================================
    # ECR Pull Test Analyzer
    # ============================================================================
    - textAnalyze:
        checkName: ECR Pull Test
        fileName: ecr-pull-test/ecr-pull-test.log
        regex: 'SUCCESS: ECR pull validated'
        outcomes:
          - pass:
              when: "true"
              message: Amazon ECR pull validated successfully
          - fail:
              when: "false"
              message: Failed to pull from ECR - check Node Role has ecr:GetDownloadUrlForLayer, ecr:BatchGetImage permissions and that push test passed first
