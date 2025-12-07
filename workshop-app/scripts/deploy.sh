#!/bin/bash
# Deploy script for GitOps Virtualization Workshop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/../deploy"
NAMESPACE="workshop-gitops"
GUID="${GUID:-${USER}}"

echo "Deploying GitOps Virtualization Workshop..."
echo "Namespace: ${NAMESPACE}"
echo "GUID: ${GUID}"
echo ""

# Apply namespace first
echo "Creating namespace..."
oc apply -f "${DEPLOY_DIR}/00-namespace.yaml"

# Check for SSH private key
SSH_KEY_PATH="${HOME}/.ssh/ocpvirt-gitops"
if [ ! -f "${SSH_KEY_PATH}" ]; then
    echo "ERROR: SSH private key not found at ${SSH_KEY_PATH}"
    echo "Please ensure the workshop installation has created the SSH key."
    exit 1
fi

echo "Creating SSH private key secret..."
oc create secret generic workshop-ssh-private-key \
    --from-file=id_rsa="${SSH_KEY_PATH}" \
    --namespace="${NAMESPACE}" \
    --dry-run=client -o yaml | oc apply -f -

echo ""
echo "Creating workshop config ConfigMap with GUID..."
oc create configmap workshop-config \
    --from-literal=guid="${GUID}" \
    --namespace="${NAMESPACE}" \
    --dry-run=client -o yaml | oc apply -f -

echo ""

# Apply remaining manifests in order
for file in $(ls "${DEPLOY_DIR}"/*.yaml 2>/dev/null | grep -v '.example' | grep -v '00-namespace.yaml' | grep -v '03b-ssh-private-key-secret.yaml' | grep -v '04b-configmap-config.yaml' | sort); do
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
