#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "OpenShift GitOps Workshop - Demo Runner"
echo "======================================="
echo ""
echo "Available demos:"
echo "1. Manual Change Detection and Drift Correction"
echo "2. VM Recovery from Data Loss"
echo "3. Adding New Development VM via Git Change"
echo "4. Initial VM Deployment from Git Repository"
echo "5. Live VM Configuration Update via Git"
echo ""
echo "Utility options:"
echo "s. Check workshop status"
echo "c. Cleanup Demo 3 resources"
echo "q. Quit"
echo ""

while true; do
    read -p "Select demo to run (1-5, s, c, q): " choice
    
    case $choice in
        1)
            log "Running Demo 1: Manual Change Detection and Drift Correction"
            echo ""
            ./demo-scripts/demo1-manual-change.sh
            ;;
        2)
            log "Running Demo 2: VM Recovery from Data Loss"
            echo ""
            ./demo-scripts/demo2-vm-recovery.sh
            ;;
        3)
            log "Running Demo 3: Adding New Development VM via Git Change"
            echo ""
            ./demo-scripts/demo3-add-development-vm.sh
            ;;
        4)
            log "Running Demo 4: Initial VM Deployment from Git Repository"
            echo ""
            ./demo-scripts/demo4-initial-deployment.sh
            ;;
        5)
            log "Running Demo 5: Live VM Configuration Update via Git"
            echo ""
            ./demo-scripts/demo5-live-config-update.sh
            ;;
        s|S)
            log "Checking workshop status..."
            echo ""
            ./demo-scripts/check-status.sh
            ;;
        c|C)
            log "Running Demo 3 cleanup..."
            echo ""
            ./demo-scripts/cleanup-demo3.sh
            ;;
        q|Q)
            log "Exiting demo runner..."
            exit 0
            ;;
        *)
            log_error "Invalid choice. Please select 1-5, s, c, or q."
            ;;
    esac
    
    echo ""
    echo "======================================="
    echo ""
    read -p "Press Enter to continue or Ctrl+C to exit..."
    echo ""
done