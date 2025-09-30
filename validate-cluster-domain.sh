#!/bin/bash

set -e

echo "OpenShift Cluster Domain Validator"
echo "=================================="

detect_cluster_domain() {
    if ! oc whoami &>/dev/null; then
        echo "Error: Not logged into OpenShift."
        echo "Run: oc login <cluster-url>"
        return 1
    fi
    
    local domain=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}' 2>/dev/null)
    if [ -z "$domain" ]; then
        echo "Error: Could not detect cluster domain."
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

echo "Detected cluster domain: $CLUSTER_DOMAIN"

CURRENT_DOMAIN=$(check_current_domain)

echo "Current domain in files: $CURRENT_DOMAIN"

if [ "$CURRENT_DOMAIN" = "INCONSISTENT" ]; then
    echo "Warning: Inconsistent domains between files!"
    echo "Running automatic correction..."
elif [ "$CURRENT_DOMAIN" = "$CLUSTER_DOMAIN" ]; then
    echo "Domain is already correct in configuration files."
    exit 0
fi

echo ""
read -p "Update files to use '$CLUSTER_DOMAIN'? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating files..."
    
    cp overlays/dev/kustomization.yaml overlays/dev/kustomization.yaml.backup
    cp overlays/hml/kustomization.yaml overlays/hml/kustomization.yaml.backup
    cp overlays/prd/kustomization.yaml overlays/prd/kustomization.yaml.backup
    
    sed -i "s/value: dev-workshop-vms\.apps\..*/value: dev-workshop-vms.$CLUSTER_DOMAIN/" overlays/dev/kustomization.yaml
    sed -i "s/value: hml-workshop-vms\.apps\..*/value: hml-workshop-vms.$CLUSTER_DOMAIN/" overlays/hml/kustomization.yaml
    sed -i "s/value: workshop-vms\.apps\..*/value: workshop-vms.$CLUSTER_DOMAIN/" overlays/prd/kustomization.yaml
    
    echo "  overlays/dev/kustomization.yaml"
    echo "  overlays/hml/kustomization.yaml"
    echo "  overlays/prd/kustomization.yaml"
    
    echo ""
    echo "Update completed!"
    echo "Backups saved with .backup extension"
    
else
    echo "Update cancelled by user."
    exit 1
fi

echo ""
echo "Configuration summary:"
echo "  Development: dev-workshop-vms.$CLUSTER_DOMAIN"
echo "  Homologation: hml-workshop-vms.$CLUSTER_DOMAIN"  
echo "  Production: workshop-vms.$CLUSTER_DOMAIN"
echo ""
echo "To restore original configurations, run:"
echo "  mv overlays/dev/kustomization.yaml.backup overlays/dev/kustomization.yaml"
echo "  mv overlays/hml/kustomization.yaml.backup overlays/hml/kustomization.yaml"
echo "  mv overlays/prd/kustomization.yaml.backup overlays/prd/kustomization.yaml"