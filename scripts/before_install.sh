#!/bin/bash
set -e

echo "=== Pre-deployment health check ==="

# Verify AWS CLI is available
aws --version

# Verify Docker is running
docker info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Docker is not running"
  exit 1
fi

# Check ECS cluster is reachable
aws ecs describe-clusters \
    --clusters $ECS_CLUSTER \
    --region $AWS_REGION \
    --query 'clusters[0].status' \
    --output text

echo "=== Pre-deployment checks passed ==="
