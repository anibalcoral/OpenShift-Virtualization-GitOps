#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Demo 2: VM Recovery from Data Loss"
echo "===================================="

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-02"
APP_NAME="workshop-vms-dev"

log "Step 1: Check VM status and application sync state..."
show_app_status $APP_NAME
if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_success "VM '$VM_NAME' exists in namespace '$NAMESPACE'"
else
    log_error "VM '$VM_NAME' not found in namespace '$NAMESPACE'"
    exit 1
fi

echo ""
log "Step 2: Access VM console and simulate data corruption..."
log "In a real scenario, you would:"
log "- Connect to VM console: oc console -n $NAMESPACE"
log "- Run destructive command like 'rm -rf /*'"
log "- VM becomes unresponsive"

echo ""
log "For this demo, we'll simulate by deleting the VM and its DataVolume..."

log "Step 3: Delete VM and its persistent storage..."
oc delete vm $VM_NAME -n $NAMESPACE
log_success "VM '$VM_NAME' deleted"

# Wait a moment for VM deletion to propagate
sleep 5

log "Deleting associated DataVolume..."
if oc get dv $VM_NAME -n $NAMESPACE &>/dev/null; then
    oc delete dv $VM_NAME -n $NAMESPACE
    log_success "DataVolume '$VM_NAME' deleted"
else
    log_warning "DataVolume '$VM_NAME' not found or already deleted"
fi

echo ""
log "Step 4: Wait for ArgoCD to detect the missing resources..."
wait_for_sync_status $APP_NAME "OutOfSync" 30

log "Step 4.1: Triggering an ArgoCD sync to correct the drift..."
trigger_sync $APP_NAME
log_success "ArgoCD sync triggered."

echo ""
log "Step 5: ArgoCD detects the missing VM and recreates it..."
log "Monitoring VM recreation with fresh storage..."
wait_for_vm_exists $VM_NAME $NAMESPACE 120

echo ""
log "Step 6: Wait for application to return to Synced state..."
wait_for_sync_status $APP_NAME "Synced" 60

echo ""
log "Step 7: Verify VM and storage recreation..."
if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_success "VM '$VM_NAME' successfully recreated"
else
    log_error "VM '$VM_NAME' recreation failed"
    exit 1
fi

sleep 5
if oc get dv -n $NAMESPACE | grep $VM_NAME &>/dev/null; then
    log_success "DataVolume for '$VM_NAME' recreated"
else
    log_warning "DataVolume for '$VM_NAME' will be created when VM starts"
fi

echo ""
log_success "Demo 2 completed! The VM was fully recreated with fresh storage from Git definition."
echo ""
log "Summary:"
log "========="
log "✓ VM and persistent storage completely deleted (simulating data corruption)"
log "✓ ArgoCD detected missing resources (OutOfSync state)"
log "✓ ArgoCD automatically recreated VM with fresh storage"
log "✓ Complete disaster recovery using GitOps principles"
log "✓ Application returned to Synced state"