#!/bin/bash
# Deploy script for GitOps Virtualization Workshop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/../deploy"
NAMESPACE="workshop-gitops"

echo "Deploying GitOps Virtualization Workshop..."
echo "Namespace: ${NAMESPACE}"
echo ""

# Apply all manifests in order
for file in $(ls "${DEPLOY_DIR}"/*.yaml 2>/dev/null | grep -v '.example' | sort); do
    echo "Applying: $(basename "$file")"
    oc apply -f "$file"
done

echo ""
echo "Waiting for deployment to be ready..."
oc rollout status deployment/gitops-workshop -n ${NAMESPACE} --timeout=120s || true

echo ""
echo "Deployment complete!"
echo ""
echo "Workshop URL:"
oc get route gitops-workshop -n ${NAMESPACE} -o jsonpath='{.spec.host}' 2>/dev/null && echo "" || echo "Route not found"
