#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

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
        a|A)
            log "Running all demos sequentially..."
            echo ""
            ./demo-scripts/demo1-manual-change.sh
            echo ""
            ./demo-scripts/demo2-vm-recovery.sh
            echo ""
            ./demo-scripts/demo3-add-development-vm.sh
            echo ""
            ./demo-scripts/cleanup-demo3.sh
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