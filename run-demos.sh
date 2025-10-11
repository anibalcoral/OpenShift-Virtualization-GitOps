#!/bin/bash

set -e

# Source common functions for backward compatibility with remaining bash scripts
source "$(dirname "$0")/demo-scripts/demo-functions.sh"

# Check if GUID environment variable is set
if [ -z "$GUID" ]; then
    log_error "GUID environment variable is not set. Please export GUID before running demos."
    log_error "Example: export GUID=user01"
    exit 1
fi

log "Using GUID: $GUID"

echo "OpenShift GitOps Workshop - Demo Runner"
echo "======================================="
echo "GUID: $GUID"
echo ""
echo "Available demos:"
echo "1. Manual Change Detection and Drift Correction"
echo "2. VM Recovery from Data Loss (Removing and Recreating VM)"
echo "3. Adding New Development VM via Git Change"
echo "4. Multi-Environment VM Management with Kustomize"
echo ""
echo "Utility options:"
echo "a. Run all demos sequentially"
echo "s. Check workshop status"
echo "h. Clean up SSH known_hosts (resolves SSH host key conflicts)"
echo "c. Cleanup Demo 3 resources"
echo "d. Cleanup Demo 4 resources"
echo "q. Quit"
echo ""

# if no parameter has been passed, show menu
if [ $# -eq 0 ]; then
    read -p "Select demo to run (1-4, a, s, h, c, d, q): " choice
else
    choice=$1
fi
echo ""

case $choice in
    1)
        log "Running Demo 1: Manual Change Detection and Drift Correction"
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml -e "guid=$GUID"
        ;;
    2)
        log "Running Demo 2: VM Recovery from Data Loss"
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml -e "guid=$GUID"
        ;;
    3)
        log "Running Demo 3: Adding New Development VM via Git Change"
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml -e "guid=$GUID"
        ;;
    4)
        log "Running Demo 4: Multi-Environment VM Management with Kustomize"
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml -e "guid=$GUID"
        ;;
    s|S)
        log "Checking workshop status..."
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml -e "guid=$GUID"
        ;;
    h|H)
        log "Cleaning up SSH known_hosts for workshop VMs..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-ssh-known-hosts.yaml -e "guid=$GUID"
        ;;
    c|C)
        log "Running Demo 3 cleanup..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml -e "guid=$GUID"
        ;;
    d|D)
        log "Running Demo 4 cleanup..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml -e "guid=$GUID"
        ;;
    q|Q)
        log "Exiting demo runner..."
        exit 0
        ;;
    a|A)
        log "Running all demos sequentially..."
        echo ""
        cd "$(dirname "$0")/.."
        log "Running Demo 1..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml -e "guid=$GUID"
        echo ""
        log "Running Demo 2..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml -e "guid=$GUID"
        echo ""
        log "Running Demo 3..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml -e "guid=$GUID"
        echo ""
        log "Running Demo 4..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml -e "guid=$GUID"
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml -e "guid=$GUID"
        ;;
    *)
        log_error "Invalid choice. Please select 1-4, a, s, h, c, d, or q."
        ;;
esac

echo ""
echo "======================================="
