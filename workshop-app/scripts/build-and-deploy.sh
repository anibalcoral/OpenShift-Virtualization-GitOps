#!/bin/bash

set -e

IMAGE_NAME="${IMAGE_NAME:-quay.io/chiaretto/gitops-virtualization-workshop}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAMESPACE="${NAMESPACE:-workshop-gitops}"
DEPLOYMENT="${DEPLOYMENT:-gitops-workshop}"

echo "=========================================="
echo "Build and Deploy GitOps Virtualization Workshop"
echo "=========================================="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Namespace: ${NAMESPACE}"
echo "Deployment: ${DEPLOYMENT}"
echo ""

# Step 1: Build the image
echo "Step 1: Building image..."
cd "$(dirname "$0")/.."
bash scripts/build.sh

# Step 2: Push to registry
echo ""
echo "Step 2: Pushing image to registry..."
podman push "${IMAGE_NAME}:${IMAGE_TAG}"

# Step 3: Deploy to OpenShift
echo ""
echo "Step 3: Deploying to OpenShift..."
bash scripts/deploy.sh

# Step 4: Rollout restart
echo ""
echo "Step 4: Rolling out deployment..."
oc rollout restart deployment/${DEPLOYMENT} -n ${NAMESPACE}
oc rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=5m

echo ""
echo "=========================================="
echo "✓ Build and deploy completed successfully!"
echo "=========================================="
echo ""
echo "Application URL:"
oc get route ${DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='https://{.spec.host}' 2>/dev/null && echo "" || echo "Route not found"