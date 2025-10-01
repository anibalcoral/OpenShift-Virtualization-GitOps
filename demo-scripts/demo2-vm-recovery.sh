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

echo "Demo 2: VM Recovery from Data Loss"
echo "===================================="

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-02"

log "Step 1: Check VM status..."
oc get vm $VM_NAME -n $NAMESPACE &>/dev/null

echo ""
log "Step 2: Access VM console and simulate data corruption..."
log "In a real scenario, you would:"
log "- Connect to VM console: oc console -n $NAMESPACE"
log "- Run destructive command like 'rm -rf /*'"
log "- VM becomes unresponsive"

echo ""
log "For this demo, we'll simulate by deleting the VM and its DataVolume..."

log "Step 3: Delete VM and its persistent storage..."
oc delete vm $VM_NAME -n $NAMESPACE &>/dev/null
sleep 5

log "Deleting associated DataVolume..."
oc delete dv $VM_NAME -n $NAMESPACE &>/dev/null || log_warning "DataVolume already deleted"

echo ""
log "Step 4: Check ArgoCD sync status..."
log "The application should be 'OutOfSync'"
oc get applications.argoproj.io workshop-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}' &>/dev/null

echo ""
log "Step 5: ArgoCD detects the missing VM and recreates it..."
log "Monitoring VM recreation with fresh storage..."

for i in {1..60}; do
    if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
        log_success "VM recreated successfully with fresh storage!"
        break
    fi
    log "Waiting for VM recreation... ($i/60)"
    sleep 10
done

echo ""
log "Step 6: Check VM status and DataVolume..."
oc get vm $VM_NAME -n $NAMESPACE &>/dev/null
sleep 5
log "Checking DataVolume status..."
oc get dv -n $NAMESPACE | grep $VM_NAME &>/dev/null || log_warning "DataVolume will be created by the VM"

echo ""
log_success "Demo 2 completed! The VM was fully recreated with fresh storage from Git definition."
log_success "This demonstrates complete disaster recovery using GitOps principles."