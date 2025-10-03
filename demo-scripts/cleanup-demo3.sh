#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Demo Cleanup: Removing Demo 3 Development VM"
echo "============================================="

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-09"
APP_NAME="workshop-vms-dev"
APPS_REPO_PATH="/home/lchiaret/git/OpenShift-Virtualization-GitOps-Apps"

log "Cleaning up Demo 3 resources..."

# Check if VM exists
if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log "VM '$VM_NAME' found - will be removed via Git changes"
else
    log "VM '$VM_NAME' not found in cluster"
fi

echo ""
log "Step 1: Removing vm-web-09.yaml from Git repository..."

cd "$APPS_REPO_PATH"

# Switch to vms-dev branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "vms-dev" ]; then
    log "Switching to vms-dev branch..."
    git checkout vms-dev
fi

# Remove vm-web-09.yaml if it exists
if [ -f "base/vm-web-09.yaml" ]; then
    rm base/vm-web-09.yaml
    log_success "Removed base/vm-web-09.yaml"
else
    log_warning "base/vm-web-09.yaml not found"
fi

echo ""
log "Step 2: Updating kustomization.yaml to remove vm-web-09..."

# Restore original kustomization.yaml without vm-web-09
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ssh-secret.yaml
  - vm-web-01.yaml
  - vm-web-02.yaml
  - vm-web-service.yaml
EOF

log_success "Updated base/kustomization.yaml to remove vm-web-09.yaml"

echo ""
log "Step 3: Committing cleanup changes..."

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
    log_warning "No changes to commit - cleanup may have already been done"
else
    git add -A
    git commit -m "cleanup: remove development VM web-09

- Remove vm-web-09.yaml from base directory
- Update kustomization to exclude vm-web-09
- Restore development environment to original 2-VM configuration"

    git push origin vms-dev
    log_success "Cleanup changes committed and pushed"
fi

echo ""
log "Step 4: Wait for ArgoCD to detect and apply cleanup..."

cd -

log "Step 4.1: Triggering an ArgoCD sync to correct the drift (with prune)..."
oc patch applications.argoproj.io $APP_NAME -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD","prune":true}}}'
log_success "ArgoCD sync with prune triggered."


# Wait for VM to be deleted
if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log "Waiting for VM '$VM_NAME' to be deleted..."
    wait_for_vm_deleted $VM_NAME $NAMESPACE 120
fi

# Wait for application to return to synced state
# wait_for_sync_status $APP_NAME "Synced" 60

echo ""
log "Step 5: Verify cleanup completion..."

if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_error "VM '$VM_NAME' still exists - cleanup failed"
    exit 1
else
    log_success "VM '$VM_NAME' successfully removed"
fi

# Show remaining VMs
log "Remaining VMs in development environment:"
oc get vm -n $NAMESPACE | grep -E "(NAME|dev-vm-web)" || log_warning "No VMs found"

echo ""
log_success "Demo 3 cleanup completed successfully!"
echo ""
log "Summary:"
log "========="
log "✓ Removed vm-web-09.yaml from Git repository"
log "✓ Updated kustomization.yaml to exclude vm-web-09"
log "✓ Committed and pushed cleanup changes"
log "✓ ArgoCD detected and applied cleanup"
log "✓ VM dev-vm-web-09 removed from cluster"
log "✓ Development environment restored to 2-VM baseline"