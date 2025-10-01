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

log "Checking OpenShift connection..."
if ! oc whoami &> /dev/null; then
    log_error "Not connected to OpenShift cluster. Please login with 'oc login'."
    exit 1
fi

log "Removing OpenShift GitOps Workshop resources..."
ansible-playbook -i inventory/localhost playbooks/remove-gitops.yaml

log_success "Workshop removal completed successfully!"