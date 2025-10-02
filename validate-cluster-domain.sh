#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Non-interactive mode: always proceed and auto-commit

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

log "Cluster Domain Validation and Configuration Tool"
echo "================================================"

# Check prerequisites
if ! command -v oc &> /dev/null; then
    log_error "oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

if ! oc whoami &> /dev/null; then
    log_error "Not connected to OpenShift cluster. Please login with 'oc login'."
    exit 1
fi

# Check if Apps repository exists
APPS_REPO_PATH="../OpenShift-Virtualization-GitOps-Apps"
if [ ! -d "$APPS_REPO_PATH" ]; then
    log_error "Apps repository not found at $APPS_REPO_PATH"
    log "Please clone the Apps repository: git clone git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git ../OpenShift-Virtualization-GitOps-Apps"
    exit 1
fi

# Detect cluster domain
log "Detecting cluster domain..."
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)

if [ -z "$CLUSTER_DOMAIN" ]; then
    log_error "Could not detect cluster domain."
    exit 1
fi

log_success "Detected cluster domain: $CLUSTER_DOMAIN"

# Check current domain in Apps repository
log "Checking current domain configuration in Apps repository..."
cd "$APPS_REPO_PATH"

# Make sure we're on the correct branch
git checkout vms-dev &>/dev/null

DEV_DOMAIN=$(grep -o "value: dev-workshop-vms\.[^\"]*" overlays/dev/kustomization.yaml | sed 's/value: //' || echo "")
HML_DOMAIN=$(grep -o "value: hml-workshop-vms\.[^\"]*" overlays/hml/kustomization.yaml | sed 's/value: //' || echo "")
PRD_DOMAIN=$(grep -o "value: workshop-vms\.[^\"]*" overlays/prd/kustomization.yaml | sed 's/value: //' || echo "")

echo ""
log "Current domain configuration:"
echo "  Development: $DEV_DOMAIN"
echo "  Homologation: $HML_DOMAIN" 
echo "  Production: $PRD_DOMAIN"
echo ""

EXPECTED_DEV="dev-workshop-vms.$CLUSTER_DOMAIN"
EXPECTED_HML="hml-workshop-vms.$CLUSTER_DOMAIN"
EXPECTED_PRD="workshop-vms.$CLUSTER_DOMAIN"

log "Expected domain configuration:"
echo "  Development: $EXPECTED_DEV"
echo "  Homologation: $EXPECTED_HML"
echo "  Production: $EXPECTED_PRD"
echo ""

# Check if update is needed
UPDATE_NEEDED=false
if [ "$DEV_DOMAIN" != "$EXPECTED_DEV" ] || [ "$HML_DOMAIN" != "$EXPECTED_HML" ] || [ "$PRD_DOMAIN" != "$EXPECTED_PRD" ]; then
    UPDATE_NEEDED=true
fi

if [ "$UPDATE_NEEDED" = true ]; then
    log_warning "Domain configuration update needed!"
    echo ""
    
    # Always proceed in non-interactive mode
    PROCEED=true
    log "Auto-updating domain configuration (non-interactive mode)..."
    
    if [ "$PROCEED" = true ]; then
        log "Updating domain configuration in all environments..."
        
        # Update dev environment
        sed -i.bak "s|value: dev-workshop-vms\.[^\"]*|value: dev-workshop-vms.$CLUSTER_DOMAIN|g" overlays/dev/kustomization.yaml
        
        # Update hml environment  
        sed -i.bak "s|value: hml-workshop-vms\.[^\"]*|value: hml-workshop-vms.$CLUSTER_DOMAIN|g" overlays/hml/kustomization.yaml
        
        # Update prd environment
        sed -i.bak "s|value: workshop-vms\.[^\"]*|value: workshop-vms.$CLUSTER_DOMAIN|g" overlays/prd/kustomization.yaml
        
        # Clean up backup files
        find . -name "*.bak" -delete
        
        log_success "Domain configuration updated!"
        
        # Commit and push changes
        # Always commit and push in non-interactive mode
        COMMIT_PROCEED=true
        log "Auto-committing and pushing changes (non-interactive mode)..."
        
        if [ "$COMMIT_PROCEED" = true ]; then
            log "Committing changes..."
            
            git add .
            git commit -m "feat: update cluster domain to $CLUSTER_DOMAIN

- Update development domain to: $EXPECTED_DEV
- Update homologation domain to: $EXPECTED_HML  
- Update production domain to: $EXPECTED_PRD"
           
#            log "Pushing to vms-dev branch..."
#            git push origin vms-dev
#            
#            # Merge to hml and push
#            log "Merging to vms-hml branch..."
#            git checkout vms-hml
#            git merge vms-dev
#            git push origin vms-hml
#            
#            # Merge to main and push
#            log "Merging to main branch..."
#            git checkout main
#            git merge vms-hml
#            git push origin main
            
            # Switch back to vms-dev
            git checkout vms-dev
            
#            log_success "Changes committed and pushed to all branches!"
        else
            log_warning "Changes made but not committed. Don't forget to commit and push manually."
        fi
    else
        log "Domain configuration update skipped."
    fi
else
    log_success "Domain configuration is already correct!"
fi

echo ""
log "Final configuration:"
echo "  Development: https://dev-workshop-vms.$CLUSTER_DOMAIN"
echo "  Homologation: https://hml-workshop-vms.$CLUSTER_DOMAIN"
echo "  Production: https://workshop-vms.$CLUSTER_DOMAIN"