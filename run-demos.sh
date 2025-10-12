#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

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
echo "c. Cleanup Demo 4 resources"
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
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
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
    4)
        log "Running Demo 4: Multi-Environment VM Management with Kustomize"
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml
        ;;
    s|S)
        log "Checking workshop status..."
        echo ""
        cd "$(dirname "$0")/.."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml
        ;;
    h|H)
        log "Cleaning up SSH known_hosts for workshop VMs..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-ssh-known-hosts.yaml
        ;;
    c|C)
        log "Running Demo 4 cleanup..."
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
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
        log "Running Demo 4..."
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml
        echo ""
        ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
        ;;
    *)
        log_error "Invalid choice. Please select 1-4, a, s, h, c, d, or q."
        ;;
esac

echo ""
echo "======================================="
