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

log "Starting OpenShift GitOps Workshop Removal..."

if ! command -v ansible-playbook &> /dev/null; then
    log_error "ansible-playbook not found. Please install Ansible."
    exit 1
fi

if ! command -v oc &> /dev/null; then
    log_error "oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

echo ""
echo "Remove GitOps operator as well?"
echo "1. Remove only workshop resources (Recommended)"
echo "2. Remove workshop resources and GitOps operator"
echo ""
read -p "Select option (1-2): " operator_choice

case $operator_choice in
    1)
        log "Running Ansible playbook removal (preserving GitOps operator)..."
        ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml
        ;;
    2)
        log "Running Ansible playbook removal (including GitOps operator)..."
        ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml -e remove_operator=true
        ;;
    *)
        log_error "Invalid choice. Using default (preserve operator)."
        ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml
        ;;
esac