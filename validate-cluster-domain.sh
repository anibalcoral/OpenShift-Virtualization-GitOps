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

log "OpenShift Cluster Domain Validator"
echo "=================================="

detect_cluster_domain() {
    if ! oc whoami &>/dev/null; then
        log_error "Not logged into OpenShift."
        log_error "Run: oc login <cluster-url>"
        return 1
    fi
    
    local domain=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)
    if [ -z "$domain" ]; then
        log_error "Could not detect cluster domain."
        return 1
    fi
    
    echo "$domain"
}

check_current_domain() {
    local current_dev=$(grep -o "dev-workshop-vms\.apps\.[^[:space:]]*" overlays/dev/kustomization.yaml | cut -d'.' -f2-)
    local current_hml=$(grep -o "hml-workshop-vms\.apps\.[^[:space:]]*" overlays/hml/kustomization.yaml | cut -d'.' -f2-)
    local current_prd=$(grep -o "workshop-vms\.apps\.[^[:space:]]*" overlays/prd/kustomization.yaml | cut -d'.' -f2-)
    
    if [ "$current_dev" = "$current_hml" ] && [ "$current_hml" = "$current_prd" ]; then
        echo "$current_dev"
    else
        echo "INCONSISTENT"
    fi
}

CLUSTER_DOMAIN=$(detect_cluster_domain)
if [ $? -ne 0 ]; then
    exit 1
fi

log "Detected cluster domain: $CLUSTER_DOMAIN"

CURRENT_DOMAIN=$(check_current_domain)

log "Current domain in files: $CURRENT_DOMAIN"

if [ "$CURRENT_DOMAIN" = "INCONSISTENT" ]; then
    log_warning "Inconsistent domains between files!"
    log "Running automatic correction..."
elif [ "$CURRENT_DOMAIN" = "$CLUSTER_DOMAIN" ]; then
    log_success "Domain is already correct in configuration files."
    exit 0
fi

echo ""
read -p "Update files to use '$CLUSTER_DOMAIN'? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Updating files..."
    
    cp overlays/dev/kustomization.yaml overlays/dev/kustomization.yaml.backup
    cp overlays/hml/kustomization.yaml overlays/hml/kustomization.yaml.backup
    cp overlays/prd/kustomization.yaml overlays/prd/kustomization.yaml.backup
    
    sed -i "s/value: dev-workshop-vms\.apps\..*/value: dev-workshop-vms.$CLUSTER_DOMAIN/" overlays/dev/kustomization.yaml &>/dev/null
    sed -i "s/value: hml-workshop-vms\.apps\..*/value: hml-workshop-vms.$CLUSTER_DOMAIN/" overlays/hml/kustomization.yaml &>/dev/null
    sed -i "s/value: workshop-vms\.apps\..*/value: workshop-vms.$CLUSTER_DOMAIN/" overlays/prd/kustomization.yaml &>/dev/null
    
    log_success "Updated overlays/dev/kustomization.yaml"
    log_success "Updated overlays/hml/kustomization.yaml"
    log_success "Updated overlays/prd/kustomization.yaml"
    
    echo ""
    log_success "Update completed!"
    log "Backups saved with .backup extension"
    
else
    log_warning "Update cancelled by user."
    exit 1
fi

echo ""
log "Configuration summary:"
echo "  Development: dev-workshop-vms.$CLUSTER_DOMAIN"
echo "  Homologation: hml-workshop-vms.$CLUSTER_DOMAIN"  
echo "  Production: workshop-vms.$CLUSTER_DOMAIN"
echo ""
log "To restore original configurations, run:"
echo "  mv overlays/dev/kustomization.yaml.backup overlays/dev/kustomization.yaml"
echo "  mv overlays/hml/kustomization.yaml.backup overlays/hml/kustomization.yaml"
echo "  mv overlays/prd/kustomization.yaml.backup overlays/prd/kustomization.yaml"