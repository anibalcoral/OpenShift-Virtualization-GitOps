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

log "Setting up SSH key for workshop VMs..."

SSH_PUBLIC_KEY_FILE="$HOME/.ssh/ocpvirt-gitops-labs.pub"

if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
    log_error "SSH public key not found at $SSH_PUBLIC_KEY_FILE"
    log_error "Please generate SSH keys with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/ocpvirt-gitops-labs"
    exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_FILE")

log "Updating SSH secret with your public key..."
cat > ../OpenShift-Virtualization-GitOps-Apps/base/ssh-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: workshop-ssh-key
type: Opaque
stringData:
  key: |
    $SSH_PUBLIC_KEY
EOF

log_success "SSH key setup completed!"
log "Your VMs will be accessible via SSH using your private key: $HOME/.ssh/ocpvirt-gitops-labs"