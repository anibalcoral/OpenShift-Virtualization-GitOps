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

log "Detecting cluster domain..."
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)

if [ -z "$CLUSTER_DOMAIN" ]; then
    log_error "Could not detect cluster domain."
    exit 1
fi

log_success "Detected cluster domain: $CLUSTER_DOMAIN"

log "Updating configuration files with cluster domain..."
sed -i.bak "s/value: dev-workshop-vms\.apps\..*/value: dev-workshop-vms.$CLUSTER_DOMAIN/" overlays/dev/kustomization.yaml
sed -i.bak "s/value: hml-workshop-vms\.apps\..*/value: hml-workshop-vms.$CLUSTER_DOMAIN/" overlays/hml/kustomization.yaml
sed -i.bak "s/value: workshop-vms\.apps\..*/value: workshop-vms.$CLUSTER_DOMAIN/" overlays/prd/kustomization.yaml
log_success "Configuration files updated successfully!"

log "Installing OpenShift GitOps Operator and configuring workshop..."
./setup-ssh-key.sh
ansible-playbook -i inventory/localhost playbooks/install-gitops.yaml

log "Creating repository secret for private Git access..."
oc create secret generic workshop-gitops-repo \
  --from-file=sshPrivateKey=/home/$USER/.ssh/id_rsa \
  --from-literal=type=git \
  --from-literal=url=git@github.com:anibalcoral/OpenShift-Virtualization-GitOps.git \
  -n openshift-gitops --dry-run=client -o yaml | oc apply -f - &>/dev/null

log "Labeling repository secret for ArgoCD..."
oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository &>/dev/null

log "Cleaning up temporary files..."

log_success "Installation completed successfully!"
echo ""
log "Workshop Information:"
log "====================="
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"
echo ""
log "Workshop Applications:"
echo "- workshop-vms-dev (Development VMs)"
echo "- workshop-vms-hml (Homologation VMs)"  
echo "- workshop-vms-prd (Production VMs)"
echo ""
log "Application URLs (after deployment):"
echo "- Development: https://dev-workshop-vms.$CLUSTER_DOMAIN"
echo "- Homologation: https://hml-workshop-vms.$CLUSTER_DOMAIN"
echo "- Production: https://workshop-vms.$CLUSTER_DOMAIN"
echo ""
log "Next steps:"
echo "1. Access ArgoCD UI using the credentials above"
echo "2. Check workshop status: ./demo-scripts/check-status.sh"
echo "3. Run demo scripts in demo-scripts/ directory"

log "Cleaning up backup files..."
rm -f overlays/*/kustomization.yaml.bak