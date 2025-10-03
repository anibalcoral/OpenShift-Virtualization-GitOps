#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Workshop Status Checker"
echo "======================="

log "1. Checking ArgoCD Applications..."
echo "-----------------------------------"
oc get applications.argoproj.io -n openshift-gitops | grep workshop-vms &>/dev/null

echo ""
log "2. Checking Application Sync Status..."
echo "---------------------------------------"
for app in workshop-vms-dev workshop-vms-hml workshop-vms-prd; do
    show_app_status $app
done

echo ""
log "3. Checking Workshop Namespaces..."
echo "-----------------------------------"
for ns in workshop-gitops-vms-dev workshop-gitops-vms-hml workshop-gitops-vms-prd; do
    if oc get namespace $ns &>/dev/null; then
        echo "$ns: EXISTS"
    else
        echo "$ns: NOT FOUND"
    fi
done

echo ""
log "4. Checking Virtual Machines..."
echo "--------------------------------"
for ns in workshop-gitops-vms-dev workshop-gitops-vms-hml workshop-gitops-vms-prd; do
    echo "Namespace: $ns"
    oc get vm -n $ns 2>/dev/null || echo "  No VMs found or namespace doesn't exist"
    echo ""
done

echo ""
log "5. Checking VM Services and Endpoints..."
echo "-----------------------------------------"
for ns in workshop-gitops-vms-dev workshop-gitops-vms-hml workshop-gitops-vms-prd; do
    echo "Namespace: $ns"
    services=$(oc get svc -n $ns 2>/dev/null | grep -v NAME | wc -l)
    if [ $services -gt 0 ]; then
        echo "  Services:"
        oc get svc -n $ns --no-headers 2>/dev/null | awk '{print "    " $1 " (" $3 ")"}'
        echo "  Endpoints:"
        oc get endpoints -n $ns --no-headers 2>/dev/null | awk '{print "    " $1 " (" $2 ")"}'
    else
        echo "  No services found or namespace doesn't exist"
    fi
    echo ""
done

echo ""
log "6. Checking SSH Key Configuration..."
echo "-------------------------------------"
# Check dev namespace
ns="workshop-gitops-vms-dev"
ssh_secret=$(oc get secret dev-workshop-ssh-key -n $ns --no-headers 2>/dev/null | wc -l)
if [ $ssh_secret -gt 0 ]; then
    echo "$ns: SSH secret (dev-workshop-ssh-key) EXISTS"
else
    echo "$ns: SSH secret (dev-workshop-ssh-key) NOT FOUND"
fi

# Check hml namespace  
ns="workshop-gitops-vms-hml"
ssh_secret=$(oc get secret hml-workshop-ssh-key -n $ns --no-headers 2>/dev/null | wc -l)
if [ $ssh_secret -gt 0 ]; then
    echo "$ns: SSH secret (hml-workshop-ssh-key) EXISTS"
else
    echo "$ns: SSH secret (hml-workshop-ssh-key) NOT FOUND"
fi

# Check prd namespace
ns="workshop-gitops-vms-prd"  
ssh_secret=$(oc get secret prd-workshop-ssh-key -n $ns --no-headers 2>/dev/null | wc -l)
if [ $ssh_secret -gt 0 ]; then
    echo "$ns: SSH secret (prd-workshop-ssh-key) EXISTS"
else
    echo "$ns: SSH secret (prd-workshop-ssh-key) NOT FOUND"
fi

echo ""
log "7. Checking Routes..."
echo "----------------------"
for ns in workshop-gitops-vms-dev workshop-gitops-vms-hml workshop-gitops-vms-prd; do
    echo "Namespace: $ns"
    oc get routes -n $ns 2>/dev/null || echo "  No routes found or namespace doesn't exist"
    echo ""
done

echo ""
log "8. ArgoCD Access Information..."
echo "-------------------------------"
argocd_route=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null)
if [ ! -z "$argocd_route" ]; then
    echo "ArgoCD URL: https://$argocd_route"
    echo "Username: admin"
    echo "Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d 2>/dev/null)"
else
    echo "ArgoCD not found or not accessible"
fi