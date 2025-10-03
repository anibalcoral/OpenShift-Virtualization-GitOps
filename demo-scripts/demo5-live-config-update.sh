#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Demo 5: Live VM Configuration Update via Git"
echo "============================================="

NAMESPACE="workshop-gitops-vms-hml"
VM_NAME="hml-vm-web-01"
APP_NAME="workshop-vms-hml"
APPS_REPO_PATH="/home/lchiaret/git/OpenShift-Virtualization-GitOps-Apps"

log "Step 1: Check current VM configuration..."
show_app_status $APP_NAME

if ! oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_error "VM '$VM_NAME' not found in namespace '$NAMESPACE'"
    log "Please ensure the homologation environment is deployed first"
    exit 1
fi

# Show current memory configuration
current_memory=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.domain.resources.requests.memory}' 2>/dev/null || echo "Unknown")
log "Current VM memory configuration: $current_memory"

vm_status=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
log "Current VM status: $vm_status"

echo ""
log "Step 2: Modify VM configuration in Git repository..."

# Switch to homologation branch
cd "$APPS_REPO_PATH"

current_branch=$(git branch --show-current)
if [ "$current_branch" != "vms-hml" ]; then
    log "Switching to vms-hml branch..."
    git checkout vms-hml
fi

# Backup original file
cp base/vm-web-01.yaml base/vm-web-01.yaml.backup

log "Updating VM memory from 2Gi to 4Gi in vm-web-01.yaml..."

# Update memory configuration using sed
sed -i 's/memory: 2Gi/memory: 4Gi/' base/vm-web-01.yaml

# Verify the change
if grep -q "memory: 4Gi" base/vm-web-01.yaml; then
    log_success "Memory configuration updated to 4Gi"
else
    log_error "Failed to update memory configuration"
    exit 1
fi

echo ""
log "Step 3: Show the diff of changes..."
echo "=== Git Diff ==="
git diff base/vm-web-01.yaml || log_warning "No diff available"

echo ""
log "Step 4: Commit and push changes to Git..."

git add base/vm-web-01.yaml
git commit -m "feat: increase VM memory from 2Gi to 4Gi for homologation environment

- Update vm-web-01 memory allocation for better performance testing
- Change applies to homologation environment for validation
- Memory increase supports more intensive testing scenarios"

git push origin vms-hml

log_success "Changes committed and pushed to vms-hml branch"

echo ""
log "Step 5: Return to main directory and wait for ArgoCD to detect changes..."

# Return to original directory
cd -

# Wait for ArgoCD to detect the change
wait_for_sync_status $APP_NAME "OutOfSync" 60

echo ""
log "Step 6: Monitor automatic ArgoCD sync..."
log "ArgoCD will automatically detect and apply the configuration change"

# For automatic sync, we wait for it to happen
# If auto-sync is not enabled, you could trigger it manually with: trigger_sync $APP_NAME

# Wait for sync to complete
wait_for_sync_status $APP_NAME "Synced" 120

echo ""
log "Step 7: Verify VM configuration update..."

# Check if VM was restarted due to memory change
log "Checking VM status after configuration update..."
sleep 10

# Memory changes typically require VM restart
vm_status_after=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
log "VM status after update: $vm_status_after"

# Verify new memory configuration
new_memory=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.domain.resources.requests.memory}' 2>/dev/null || echo "Unknown")
log "Updated VM memory configuration: $new_memory"

if [ "$new_memory" = "4Gi" ]; then
    log_success "Memory configuration successfully updated to 4Gi"
else
    log_error "Memory configuration update failed. Current: $new_memory"
fi

echo ""
log "Step 8: Monitor VM restart process..."

# If VM needs restart, monitor it
if [ "$vm_status_after" != "Running" ]; then
    log "VM is restarting due to memory configuration change..."
    
    # Wait for VM to be running again
    for i in {1..30}; do
        current_status=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
        log "VM Status: $current_status ($i/30)"
        
        if [ "$current_status" = "Running" ]; then
            log_success "VM is running again with new configuration!"
            break
        fi
        
        sleep 10
    done
else
    log_success "VM configuration updated without restart (hot-pluggable change)"
fi

echo ""
log "Step 9: Verify final state..."

# Show final VM details
log "Final VM Configuration:"
oc get vm $VM_NAME -n $NAMESPACE -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus,MEMORY:.spec.template.spec.domain.resources.requests.memory,CPU:.spec.template.spec.domain.cpu.cores"

# Check if VirtualMachineInstance reflects the change
if oc get vmi $VM_NAME -n $NAMESPACE &>/dev/null; then
    vmi_memory=$(oc get vmi $VM_NAME -n $NAMESPACE -o jsonpath='{.spec.domain.resources.requests.memory}' 2>/dev/null || echo "Unknown")
    log "VirtualMachineInstance memory: $vmi_memory"
fi

echo ""
log_success "Demo 5 completed! VM configuration updated via Git changes."
echo ""
log "Summary:"
log "========="
log "✓ Modified VM memory configuration in Git (2Gi → 4Gi)"
log "✓ Committed and pushed changes to vms-hml branch"
log "✓ ArgoCD automatically detected Git changes"
log "✓ ArgoCD applied configuration update to running VM"
log "✓ VM configuration successfully updated"
log "✓ System demonstrates live infrastructure updates via GitOps"

echo ""
log "Key GitOps Benefits Demonstrated:"
log "• Configuration changes through Git workflow"
log "• Automatic detection and application of changes"
log "• Live updates to running infrastructure"
log "• Audit trail of all configuration changes"
log "• Consistent configuration management across environments"

echo ""
log "Cleanup: Restoring original configuration..."

# Restore original configuration
cd "$APPS_REPO_PATH"
if [ -f base/vm-web-01.yaml.backup ]; then
    cp base/vm-web-01.yaml.backup base/vm-web-01.yaml
    rm base/vm-web-01.yaml.backup
    
    git add base/vm-web-01.yaml
    git commit -m "restore: revert VM memory back to 2Gi

- Restore original memory configuration after demo
- Maintains consistent baseline configuration"
    
    git push origin vms-hml
    
    log_success "Original configuration restored"
fi

cd -