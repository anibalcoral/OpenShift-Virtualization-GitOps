#!/bin/bash
# Undeploy script for GitOps Virtualization Workshop
# This script removes all OpenShift resources but keeps the container image in the registry

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/../deploy"

echo "Removing GitOps Virtualization Workshop resources..."
echo ""

# Check if resources exist before attempting to delete
NAMESPACE=$(oc project -q 2>/dev/null || echo "")
if [ -z "$NAMESPACE" ]; then
    echo "Error: Not connected to OpenShift cluster or no project selected"
    exit 1
fi

echo "Current namespace: $NAMESPACE"
echo ""

# Delete resources in reverse order (opposite of deployment)
MANIFESTS=(
    "07-route.yaml"
    "06-service.yaml"
    "05-deployment.yaml"
    "04-configmap-guides.yaml"
    "03-clusterrolebinding.yaml"
    "02-serviceaccount.yaml"
)

for manifest in "${MANIFESTS[@]}"; do
    file="${DEPLOY_DIR}/${manifest}"
    if [ -f "$file" ]; then
        echo "Deleting: $manifest"
        oc delete -f "$file" --ignore-not-found=true
    else
        echo "Skipping: $manifest (file not found)"
    fi
done

echo ""
echo "Cleanup complete!"
echo ""
echo "Note: Container image remains in registry"
echo "To remove the image manually, use:"
echo "  podman rmi quay.io/chiaretto/gitops-virtualization-workshop:latest"
