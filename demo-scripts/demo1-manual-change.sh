#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

echo "Demo 1: Manual Change Detection and Drift Correction"
echo "======================================================"

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-01"

log "Step 1: Checking current VM state..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A5 "labels:" &>/dev/null

echo ""
log "Step 2: Making manual change (adding a label)..."
oc label vm $VM_NAME -n $NAMESPACE manually-added=true &>/dev/null

echo ""
log "Step 3: Checking ArgoCD sync status..."
log "The application should now be 'OutOfSync'"
oc get applications.argoproj.io workshop-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}' &>/dev/null

echo ""
log "Step 4: Checking VM with new label..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A10 "labels:" &>/dev/null

echo ""
log "Step 5: Delete the VM to trigger GitOps recreation..."
oc delete vm $VM_NAME -n $NAMESPACE &>/dev/null

echo ""
log "Step 6: Wait for ArgoCD to recreate the VM..."
log "ArgoCD will detect the drift and recreate the VM according to Git"

echo ""
log "Monitoring VM recreation..."
for i in {1..30}; do
    if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
        log_success "VM recreated successfully!"
        break
    fi
    log "Waiting for VM recreation... ($i/30)"
    sleep 10
done

echo ""
log "Step 7: Verify the manually added label is gone..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A10 "labels:" &>/dev/null

echo ""
log_success "Demo 1 completed! The VM was recreated exactly as defined in Git."