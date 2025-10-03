#!/bin/bash

set -e

# Source common functions
# Assuming the demo-functions.sh file exists and contains the logging and wait functions.
# NOTE: You will need to add the two new functions: wait_for_vmi_deleted and wait_for_vmi_status
source "$(dirname "$0")/demo-functions.sh"

echo "Demo 1: Manual Change Detection and Drift Correction"
echo "======================================================"

# --- Configuration Variables ---
NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-01"
APP_NAME="workshop-vms-dev"
GIT_RUN_STRATEGY="Always"    # The runStrategy defined in the Git repository
MANUAL_RUN_STRATEGY="Halted" # The runStrategy we will apply manually to stop the VM

# --- Helper Functions (add these to demo-functions.sh or keep them here) ---

# Waits for the VirtualMachineInstance (VMI) associated with a VM to be deleted
wait_for_vmi_deleted() {
    local vm_name=$1
    local namespace=$2
    local timeout=$3
    log "--> Waiting up to $timeout seconds for VMI '$vm_name' to be deleted..."
    if ! oc wait --for=delete vmi/$vm_name -n $namespace --timeout=${timeout}s &>/dev/null; then
        log_warning "Timed out waiting for VMI deletion. It might have been deleted already."
    else
        log_success "VMI '$vm_name' confirmed deleted."
    fi
}

# Waits for the VirtualMachineInstance (VMI) to reach the 'Running' phase
wait_for_vmi_status() {
    local vm_name=$1
    local namespace=$2
    local timeout=$3
    log "--> Waiting up to $timeout seconds for VMI '$vm_name' to be 'Running'..."
    if ! oc wait --for=condition=Ready vmi/$vm_name -n $namespace --timeout=${timeout}s; then
        log_error "Timed out waiting for VMI '$vm_name' to become Ready."
        exit 1
    else
        log_success "VMI '$vm_name' is Running."
    fi
}

# --- Main Script ---

log "Step 1: Checking current VM state and application sync status..."
show_app_status $APP_NAME
if ! oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_error "VM '$VM_NAME' not found in namespace '$NAMESPACE'"
    exit 1
fi
log_success "VM '$VM_NAME' exists."
wait_for_vmi_status $VM_NAME $NAMESPACE 180 # Ensure VM is running before we start

echo ""
log "Step 2: Making a manual change (setting runStrategy to '$MANUAL_RUN_STRATEGY')..."
log "This will cause the running Virtual Machine Instance (VMI) to shut down."
oc patch vm $VM_NAME -n $NAMESPACE --type merge -p "{\"spec\":{\"runStrategy\":\"$MANUAL_RUN_STRATEGY\"}}"
log_success "VM '$VM_NAME' patched to be Halted."

echo ""
log "Step 2.1: Waiting for the VMI to be shut down to confirm the manual change took effect..."
wait_for_vmi_deleted $VM_NAME $NAMESPACE 60

echo ""
log "Step 3: Forcing application refresh in ArgoCD and waiting for it to detect the drift..."
oc patch applications.argoproj.io $APP_NAME -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
wait_for_sync_status $APP_NAME "OutOfSync" 30
log_success "ArgoCD has detected the drift!"

echo ""
log "Step 4: Triggering an ArgoCD sync to correct the drift..."
# The sync will revert the runStrategy to the state defined in Git ("Always")
oc patch applications.argoproj.io $APP_NAME -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
log_success "ArgoCD sync triggered."

echo ""
log "Step 5: Waiting for the application to return to a 'Synced' state..."
wait_for_sync_status $APP_NAME "Synced" 60

echo ""
log "Step 6: Verifying that the VM's runStrategy and running state have been restored by GitOps..."
RESTORED_STRATEGY=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.spec.runStrategy}')
if [[ "$RESTORED_STRATEGY" != "$GIT_RUN_STRATEGY" ]]; then
    log_error "runStrategy was not reverted to '$GIT_RUN_STRATEGY'! GitOps correction failed."
    exit 1
fi
log_success "VM runStrategy correctly reverted to '$GIT_RUN_STRATEGY'."

# Now, wait for the virtualization controller to start the VM again
wait_for_vmi_status $VM_NAME $NAMESPACE 180

echo ""
log_success "Demo 1 completed! The VM was stopped and automatically restarted by GitOps."
echo ""
log "Summary:"
log "========="
log "✓ A manual change to the VM spec (runStrategy: Halted) was made."
log "✓ The running VM instance (VMI) was terminated as a result."
log "✓ ArgoCD detected this fundamental configuration drift (OutOfSync state)."
log "✓ A sync was triggered to enforce the state from Git."
log "✓ ArgoCD automatically corrected the VM's runStrategy back to 'Always'."
log "✓ OpenShift Virtualization automatically started the VM again."
log "✓ The application returned to a healthy and Synced state."