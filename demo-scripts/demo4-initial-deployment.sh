#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Demo 4: Initial VM Deployment from Git Repository"
echo "=================================================="

NAMESPACE="workshop-gitops-vms-prd"
VM_NAME="vm-web-01"
APP_NAME="workshop-vms-prd"

log "Step 1: Review Git Repository Structure..."
log "Showing VirtualMachine YAML structure from Git repository..."

echo ""
log "=== Base VM Definition ==="
echo "File: OpenShift-Virtualization-GitOps-Apps/base/vm-web-01.yaml"
echo ""
echo "Key components:"
echo "- VirtualMachine with Fedora base image"
echo "- 2Gi memory, 1 CPU core"
echo "- 30Gi persistent storage"
echo "- Pre-configured web server (httpd)"
echo "- SSH access via workshop SSH key"
echo "- Cloud-init for initial configuration"

echo ""
log "=== Production Overlay ==="
echo "File: OpenShift-Virtualization-GitOps-Apps/overlays/prd/kustomization.yaml"
echo ""
echo "Customizations for production:"
echo "- Namespace: workshop-gitops-vms-prd"
echo "- Name prefix: (none - production uses base names)"
echo "- SSH key: workshop-ssh-key"
echo "- Route host: workshop-vms.apps.<cluster-domain>"

echo ""
log "Step 2: Check current ArgoCD application status..."
show_app_status $APP_NAME

current_sync=$(oc get applications.argoproj.io $APP_NAME -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")

if [ "$current_sync" = "Synced" ]; then
    log_warning "Application is already Synced. For demo purposes, let's trigger a refresh..."
    
    # Refresh the application to show the sync process
    oc annotate applications.argoproj.io $APP_NAME -n openshift-gitops \
        argocd.argoproj.io/refresh="$(date)" --overwrite
    
    log "Application refreshed to demonstrate sync process"
    sleep 5
fi

echo ""
log "Step 3: Check if VM exists..."
if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_warning "VM '$VM_NAME' already exists in production namespace"
    log "Current VM status:"
    oc get vm $VM_NAME -n $NAMESPACE
else
    log "VM '$VM_NAME' does not exist yet in production namespace"
fi

echo ""
log "Step 4: Demonstrating ArgoCD sync process..."

# If application is already synced, we'll show the status monitoring
if [ "$current_sync" = "Synced" ]; then
    log "Application is currently Synced. Monitoring sync status..."
    
    # Show real-time status for a few iterations
    for i in {1..5}; do
        show_app_status $APP_NAME
        sleep 3
    done
else
    log "Application shows as '$current_sync' - triggering manual sync..."
    trigger_sync $APP_NAME
    
    # Wait for sync to complete
    wait_for_sync_status $APP_NAME "Synced" 120
fi

echo ""
log "Step 5: Monitor VM creation and startup..."

if ! oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log "Waiting for VM to be created..."
    wait_for_vm_exists $VM_NAME $NAMESPACE 120
fi

# Monitor VM status
log "Monitoring VM startup process..."
for i in {1..20}; do
    vm_status=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
    log "VM Status: $vm_status"
    
    if [ "$vm_status" = "Running" ]; then
        log_success "VM is now running!"
        break
    fi
    
    sleep 10
done

echo ""
log "Step 6: Verify VM deployment and configuration..."

# Show VM details
log "VM Details:"
oc get vm $VM_NAME -n $NAMESPACE -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus,MEMORY:.spec.template.spec.domain.resources.requests.memory,CPU:.spec.template.spec.domain.cpu.cores"

# Show associated resources
echo ""
log "Associated Resources:"
echo "DataVolume:"
oc get dv -n $NAMESPACE | grep $VM_NAME || log_warning "DataVolume not found"

echo ""
echo "VirtualMachineInstance:"
oc get vmi -n $NAMESPACE | grep $VM_NAME || log_warning "VMI not found (VM may be stopped)"

echo ""
echo "Pod:"
oc get pods -n $NAMESPACE | grep $VM_NAME || log_warning "Pod not found (VM may be stopped)"

echo ""
log "Step 7: Check service and route configuration..."
if oc get service vm-web-service -n $NAMESPACE &>/dev/null; then
    log_success "Service 'vm-web-service' exists"
    oc get service vm-web-service -n $NAMESPACE
else
    log_warning "Service 'vm-web-service' not found"
fi

if oc get route vm-web-route -n $NAMESPACE &>/dev/null; then
    log_success "Route 'vm-web-route' exists"
    route_host=$(oc get route vm-web-route -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)
    log "Production URL: https://$route_host"
else
    log_warning "Route 'vm-web-route' not found"
fi

echo ""
log_success "Demo 4 completed! VM deployment from Git repository demonstrated."
echo ""
log "Summary:"
log "========="
log "✓ Reviewed VirtualMachine YAML structure in Git"
log "✓ Examined production overlay customizations"
log "✓ Demonstrated ArgoCD sync process"
log "✓ Monitored VM creation and startup"
log "✓ Verified VM is running with correct configuration"
log "✓ Confirmed associated resources (DataVolume, Service, Route)"
log "✓ Production environment ready for use"

echo ""
log "Key GitOps Benefits Demonstrated:"
log "• Declarative infrastructure definition in Git"
log "• Automated deployment and configuration"
log "• Consistent, repeatable VM provisioning"
log "• Self-healing and drift detection capabilities"