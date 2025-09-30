#!/bin/bash

echo "Demo 1: Manual Change Detection and Drift Correction"
echo "======================================================"

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-01"

echo "Step 1: Checking current VM state..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A5 "labels:"

echo ""
echo "Step 2: Making manual change (adding a label)..."
oc label vm $VM_NAME -n $NAMESPACE manually-added=true

echo ""
echo "Step 3: Checking ArgoCD sync status..."
echo "The application should now be 'OutOfSync'"
oc get application workshop-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'

echo ""
echo "Step 4: Checking VM with new label..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A10 "labels:"

echo ""
echo "Step 5: Delete the VM to trigger GitOps recreation..."
oc delete vm $VM_NAME -n $NAMESPACE

echo ""
echo "Step 6: Wait for ArgoCD to recreate the VM..."
echo "ArgoCD will detect the drift and recreate the VM according to Git"

echo ""
echo "Monitoring VM recreation..."
for i in {1..30}; do
    if oc get vm $VM_NAME -n $NAMESPACE >/dev/null 2>&1; then
        echo "VM recreated successfully!"
        break
    fi
    echo "Waiting for VM recreation... ($i/30)"
    sleep 10
done

echo ""
echo "Step 7: Verify the manually added label is gone..."
oc get vm $VM_NAME -n $NAMESPACE -o yaml | grep -A10 "labels:"

echo ""
echo "Demo 1 completed! The VM was recreated exactly as defined in Git."