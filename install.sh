#!/bin/bash

set -e

echo "Starting OpenShift GitOps Workshop Installation..."

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

if ! command -v oc &> /dev/null; then
    echo "Error: oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

echo "Checking OpenShift connection..."
if ! oc whoami &> /dev/null; then
    echo "Error: Not connected to OpenShift cluster. Please login with 'oc login'."
    exit 1
fi

echo "Detecting cluster domain..."
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)

if [ -z "$CLUSTER_DOMAIN" ]; then
    echo "Error: Could not detect cluster domain."
    exit 1
fi

echo "Detected cluster domain: $CLUSTER_DOMAIN"

echo "Updating configuration files with cluster domain..."
sed -i.bak "s/value: dev-workshop-vms\.apps\..*/value: dev-workshop-vms.$CLUSTER_DOMAIN/" overlays/dev/kustomization.yaml
sed -i.bak "s/value: hml-workshop-vms\.apps\..*/value: hml-workshop-vms.$CLUSTER_DOMAIN/" overlays/hml/kustomization.yaml
sed -i.bak "s/value: workshop-vms\.apps\..*/value: workshop-vms.$CLUSTER_DOMAIN/" overlays/prd/kustomization.yaml
echo "Configuration files updated successfully!"

echo "Installing OpenShift GitOps Operator and configuring workshop..."
./setup-ssh-key.sh
ansible-playbook -i inventory/localhost playbooks/install-gitops.yaml

echo "Creating repository secret for private Git access..."
oc create secret generic workshop-gitops-repo \
  --from-file=sshPrivateKey=/home/$USER/.ssh/id_rsa \
  --from-literal=type=git \
  --from-literal=url=git@github.com:anibalcoral/OpenShift-Virtualization-GitOps.git \
  -n openshift-gitops --dry-run=client -o yaml | oc apply -f -

echo "Labeling repository secret for ArgoCD..."
oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository

echo "ArgoCD will use its default SSH configuration for GitHub..."

echo "Creating ArgoCD applications for GitOps..."
oc apply -f manual-install/04-argocd-app-dev.yaml
oc apply -f manual-install/05-argocd-app-hml.yaml
oc apply -f manual-install/06-argocd-app-prd.yaml

echo "Cleaning up temporary files..."

echo "Installation completed successfully!"
echo ""
echo "Workshop Information:"
echo "====================="
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"
echo ""
echo "Workshop Applications:"
echo "- workshop-vms-dev (Development VMs)"
echo "- workshop-vms-hml (Homologation VMs)"  
echo "- workshop-vms-prd (Production VMs)"
echo ""
echo "Application URLs (after deployment):"
echo "- Development: https://dev-workshop-vms.$CLUSTER_DOMAIN"
echo "- Homologation: https://hml-workshop-vms.$CLUSTER_DOMAIN"
echo "- Production: https://workshop-vms.$CLUSTER_DOMAIN"
echo ""
echo "Next steps:"
echo "1. Access ArgoCD UI using the credentials above"
echo "2. Check workshop status: ./demo-scripts/check-status.sh"
echo "3. Run demo scripts in demo-scripts/ directory"

echo "Cleaning up backup files..."
rm -f overlays/*/kustomization.yaml.bak