#!/bin/bash

set -e

# Source common functions for backward compatibility with remaining bash scripts
source "$(dirname "$0")/demo-scripts/demo-functions.sh"

echo "OpenShift GitOps Workshop - Demo Runner"
echo "======================================="
echo ""
echo "Available demos:"
echo "1. Manual Change Detection and Drift Correction"
echo "2. VM Recovery from Data Loss (Removing and Recreating VM)"
echo "3. Adding New Development VM via Git Change"
echo ""
echo "Utility options:"
echo "a. Run all demos sequentially"
echo "s. Check workshop status"
echo "c. Cleanup Demo 3 resources"
echo "q. Quit"
echo ""

# if no parameter has been passed, show menu
if [ $# -eq 0 ]; then
    read -p "Select demo to run (1-3, a, s, c, q): " choice
else
    choice=$1
fi
echo ""

case $choice in
    1)
        log "Running Demo 1: Manual Change Detection and Drift Correction"
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps//opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
        ;;
    2)
        log "Running Demo 2: VM Recovery from Data Loss"
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml
        ;;
    3)
        log "Running Demo 3: Adding New Development VM via Git Change"
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml
        ;;
    s|S)
        log "Checking workshop status..."
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml
        ;;
    c|C)
        log "Running Demo 3 cleanup..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml
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
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
        echo ""
        log "Running Demo 2..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml
        echo ""
        log "Running Demo 3..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml
        ;;
    *)
        log_error "Invalid choice. Please select 1-3, a, s, c, or q."
        ;;
esac

echo ""
echo "======================================="
