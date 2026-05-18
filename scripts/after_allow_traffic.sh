#!/bin/bash
set -e

echo "=== Post-deployment health check ==="

# Wait for service to stabilize
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION

# Confirm running task count matches desired
RUNNING=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].runningCount' \
    --output text)

DESIRED=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].desiredCount' \
    --output text)

if [ "$RUNNING" != "$DESIRED" ]; then
  echo "ERROR: Running tasks ($RUNNING) != Desired ($DESIRED)"
  exit 1
fi

echo "=== Deployment verified. $RUNNING/$DESIRED tasks running ==="
