#!/bin/bash
# Undeploy script for GitOps Virtualization Workshop
# This script removes all OpenShift resources including the namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/../deploy"
NAMESPACE="workshop-gitops"

echo "Removing GitOps Virtualization Workshop resources..."
echo "Namespace: ${NAMESPACE}"
echo ""

# Delete ClusterRoleBinding first (cluster-scoped resource)
if [ -f "${DEPLOY_DIR}/03-clusterrolebinding.yaml" ]; then
    echo "Deleting: 03-clusterrolebinding.yaml"
    oc delete -f "${DEPLOY_DIR}/03-clusterrolebinding.yaml" --ignore-not-found=true
fi

# Delete SSH secret if it exists
echo ""
echo "Deleting SSH private key secret..."
oc delete secret workshop-ssh-private-key -n ${NAMESPACE} --ignore-not-found=true

# Delete the namespace (this will delete all resources within it)
echo ""
echo "Deleting namespace: ${NAMESPACE} (this may take a few minutes)..."
oc delete namespace ${NAMESPACE} --ignore-not-found=true

echo ""
echo "Cleanup complete!"
echo ""
echo "Note: Container image remains in registry"
echo "To remove the image manually, use:"
echo "  podman rmi quay.io/chiaretto/gitops-virtualization-workshop:latest"
