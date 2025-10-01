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

log "Workshop Alignment Validation"
echo "==============================="

# Check if install.sh and WORKSHOP_GUIDE.md are aligned
ERRORS=0

log "1. Checking SSH key configuration alignment..."
INSTALL_SSH_KEY=$(grep -o "id_rsa" install.sh | head -1)
GUIDE_SSH_KEY=$(grep -o "id_rsa" WORKSHOP_GUIDE.md | head -1)

if [ "$INSTALL_SSH_KEY" = "id_rsa" ] && [ "$GUIDE_SSH_KEY" = "id_rsa" ]; then
    log_success "SSH key configuration is aligned"
else
    log_error "SSH key configuration mismatch"
    ((ERRORS++))
fi

log "2. Checking repository URL alignment..."
INSTALL_REPO=$(grep -o "git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git" install.sh | head -1)
GUIDE_REPO=$(grep -o "git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git" WORKSHOP_GUIDE.md | head -1)

if [ ! -z "$INSTALL_REPO" ] && [ ! -z "$GUIDE_REPO" ]; then
    log_success "Repository URL is aligned"
else
    log_error "Repository URL mismatch"
    ((ERRORS++))
fi

log "3. Checking cluster domain validation..."
if grep -q "validate-cluster-domain.sh" install.sh && grep -q "validate-cluster-domain.sh" WORKSHOP_GUIDE.md; then
    log_success "Cluster domain validation is mentioned in both"
else
    log_error "Cluster domain validation not mentioned consistently"
    ((ERRORS++))
fi

log "4. Checking Ansible playbook execution..."
if grep -q "ansible-playbook.*install-gitops.yaml" install.sh && grep -q "ansible-playbook.*install-gitops.yaml" WORKSHOP_GUIDE.md; then
    log_success "Ansible playbook execution is aligned"
else
    log_error "Ansible playbook execution not aligned"
    ((ERRORS++))
fi

log "5. Checking repository secret creation..."
if grep -q "workshop-gitops-repo" install.sh && grep -q "workshop-gitops-repo" WORKSHOP_GUIDE.md; then
    log_success "Repository secret creation is aligned"
else
    log_error "Repository secret creation not aligned"
    ((ERRORS++))
fi

log "6. Checking ArgoCD access information..."
if grep -q "ArgoCD URL" install.sh && grep -q "ArgoCD URL" WORKSHOP_GUIDE.md; then
    log_success "ArgoCD access information is aligned"
else
    log_error "ArgoCD access information not aligned"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    log_success "All alignment checks passed! ✅"
    log_success "install.sh and WORKSHOP_GUIDE.md are properly aligned"
else
    log_error "Found $ERRORS alignment issues ❌"
    log_error "Please review install.sh and WORKSHOP_GUIDE.md alignment"
    exit 1
fi

log "7. Checking Apps repository structure..."
if [ -d "../OpenShift-Virtualization-GitOps-Apps" ]; then
    cd ../OpenShift-Virtualization-GitOps-Apps
    
    log "Checking base resources..."
    if [ -f "base/kustomization.yaml" ] && [ -f "base/ssh-secret.yaml" ]; then
        log_success "Base resources exist"
    else
        log_error "Missing base resources"
        ((ERRORS++))
    fi
    
    log "Checking overlay structure..."
    for env in dev hml prd; do
        if [ -f "overlays/$env/kustomization.yaml" ]; then
            log_success "Overlay $env exists"
        else
            log_error "Missing overlay $env"
            ((ERRORS++))
        fi
    done
    
    log "Checking VM templates use Fedora..."
    # Only check actual VM files, not service files
    VM_FILES=$(ls base/vm-web-0*.yaml 2>/dev/null | grep -v service || true)
    if [ ! -z "$VM_FILES" ]; then
        FEDORA_COUNT=$(grep -l "name: fedora" $VM_FILES 2>/dev/null | wc -l)
        VM_COUNT=$(echo "$VM_FILES" | wc -w)
        
        if [ "$FEDORA_COUNT" -eq "$VM_COUNT" ] && [ "$VM_COUNT" -gt 0 ]; then
            log_success "All VM templates use Fedora ($FEDORA_COUNT/$VM_COUNT)"
        else
            log_error "Not all VM templates use Fedora ($FEDORA_COUNT/$VM_COUNT)"
            ((ERRORS++))
        fi
    else
        log_warning "No VM template files found"
    fi
    
    cd - >/dev/null
else
    log_warning "Apps repository not found at ../OpenShift-Virtualization-GitOps-Apps"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    log_success "Complete workshop validation passed! 🎉"
else
    log_error "Workshop validation failed with $ERRORS issues"
    exit 1
fi