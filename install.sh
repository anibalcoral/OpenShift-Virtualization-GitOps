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

log "Starting OpenShift GitOps Workshop Installation..."

# Check if GUID environment variable is set
if [ -z "$GUID" ]; then
    log_error "GUID environment variable is not set. Please export GUID before running the installation."
    log_error "Example: export GUID=user01"
    exit 1
fi

log "Using GUID: $GUID"

if ! command -v ansible-playbook &> /dev/null; then
    log_error "ansible-playbook not found. Please install Ansible."
    exit 1
fi

if ! command -v oc &> /dev/null; then
    log_error "oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

if ! command -v git &> /dev/null; then
    log_error "git CLI not found. Please install Git."
    exit 1
fi

log "Running Ansible playbook installation..."
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/install-workshop.yaml

log "Deploying Workshop Web Application..."
/opt/OpenShift-Virtualization-GitOps/workshop-app/scripts/deploy.sh

log_success "Workshop installation completed successfully!"
