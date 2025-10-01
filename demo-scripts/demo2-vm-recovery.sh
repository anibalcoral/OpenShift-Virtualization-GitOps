#!/bin/bash

echo "Demo 2: VM Recovery from Data Loss"
echo "===================================="

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-03"

echo "Step 1: Check VM status..."
oc get vm $VM_NAME -n $NAMESPACE

echo ""
echo "Step 2: Access VM console and simulate data corruption..."
echo "In a real scenario, you would:"
echo "- Connect to VM console: oc console -n $NAMESPACE"
echo "- Run destructive command like 'rm -rf /*'"
echo "- VM becomes unresponsive"

echo ""
echo "For this demo, we'll simulate by deleting the VM and its DataVolume..."

echo "Step 3: Delete VM and its persistent storage..."
oc delete vm $VM_NAME -n $NAMESPACE
sleep 5

echo "Deleting associated DataVolume..."
oc delete dv $VM_NAME -n $NAMESPACE 2>/dev/null || echo "DataVolume already deleted"

echo ""
echo "Step 4: Check ArgoCD sync status..."
echo "The application should be 'OutOfSync'"
oc get application workshop-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'

echo ""
echo "Step 5: ArgoCD detects the missing VM and recreates it..."
echo "Monitoring VM recreation with fresh storage..."

for i in {1..60}; do
    if oc get vm $VM_NAME -n $NAMESPACE >/dev/null 2>&1; then
        echo "VM recreated successfully with fresh storage!"
        break
    fi
    echo "Waiting for VM recreation... ($i/60)"
    sleep 10
done

echo ""
echo "Step 6: Check VM status and DataVolume..."
oc get vm $VM_NAME -n $NAMESPACE
sleep 5
echo "Checking DataVolume status..."
oc get dv -n $NAMESPACE | grep $VM_NAME || echo "DataVolume will be created by the VM"

echo ""
echo "Demo 2 completed! The VM was fully recreated with fresh storage from Git definition."
echo "This demonstrates complete disaster recovery using GitOps principles."