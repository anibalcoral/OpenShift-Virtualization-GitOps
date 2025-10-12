# Demo 1: Manual Change Detection and Drift Correction

## Overview
This demo demonstrates how ArgoCD detects manual changes made directly to OpenShift resources and automatically corrects the configuration drift by reverting to the state defined in Git. The demo is automated through Ansible playbooks but includes manual step-by-step instructions for educational purposes.

## Prerequisites
- OpenShift GitOps Workshop installed and configured
- GUID environment variable set (`export GUID=your-guid`)
- Workshop GitOps VMs development environment deployed
- Access to OpenShift cluster with `oc` CLI and cluster admin privileges

## Automated Execution

### Using Demo Runner Script
```bash
# Interactive execution
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 1

# Or via menu
/opt/OpenShift-Virtualization-GitOps/run-demos.sh
# Select option: 1
```

### Direct Ansible Playbook Execution
```bash
# Ensure GUID is set
export GUID=your-guid

# Run the demo playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
```

## What the Demo Does

The automated playbook performs these steps:

1. **Initial Status Check**: Verifies the VM exists and is in the correct initial state
2. **Manual Change**: Patches the VM to change `runStrategy` from `Always` to `Halted`
3. **Drift Detection**: Monitors ArgoCD application for drift detection
4. **Self-Healing Verification**: Confirms ArgoCD automatically corrects the drift
5. **Final Validation**: Ensures the VM returns to the desired Git-defined state

## Environment Details
- **GUID**: Dynamic based on environment variable
- **Namespace**: `workshop-gitops-vms-dev`
- **VM Name**: `dev-vm-web-01`
- **ArgoCD Application**: `workshop-gitops-vms-dev`
- **Git Run Strategy**: `Always` (VM should be running)
- **Manual Change**: Set `runStrategy` to `Halted` (stop the VM)

## Step-by-Step Manual Instructions

### Step 1: Check Current VM State and Application Status

1. Check the ArgoCD application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.health.status}'
```

2. Verify the VM exists and is running:
```bash
oc get vm dev-vm-web-01 -n workshop-gitops-vms-dev
```

```bash
oc get vmi dev-vm-web-01 -n workshop-gitops-vms-dev
```

3. Check the current runStrategy (should be "Always"):
```bash
oc get vm dev-vm-web-01 -n workshop-gitops-vms-dev -o jsonpath='{.spec.runStrategy}'
```

**Expected Result**: VM should exist and be running with `runStrategy: Always`

### Step 2: Make Manual Change to Stop the VM

1. Apply a manual change to halt the VM:
```bash
oc patch vm dev-vm-web-01 -n workshop-gitops-vms-dev --type merge -p '{"spec":{"runStrategy":"Halted"}}'
```

2. Verify the change was applied:
```bash
oc get vm dev-vm-web-01 -n workshop-gitops-vms-dev -o jsonpath='{.spec.runStrategy}'
```

**Expected Result**: `runStrategy` should now be "Halted"

### Step 3: Wait for VM to Shut Down

1. Monitor the VirtualMachineInstance deletion:
```bash
oc get vmi dev-vm-web-01 -n workshop-gitops-vms-dev
```

2. Wait for the VMI to be completely removed:
```bash
oc get vmi dev-vm-web-01 -n workshop-gitops-vms-dev
```

**Expected Result**: The VirtualMachineInstance should be deleted, confirming the VM has stopped

### Step 4: Force ArgoCD to Detect the Drift

1. Force application refresh to detect changes:
```bash
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

2. Check application status repeatedly until drift is detected:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

**Expected Result**: Sync status should return to "Synced"

### Step 5: Verify Configuration Restoration

1. Check that the runStrategy has been reverted:
```bash
oc get vm dev-vm-web-01 -n workshop-gitops-vms-dev -o jsonpath='{.spec.runStrategy}'
```

2. Wait for the VM to start again:
```bash
watch oc get vm dev-vm-web-01 -n workshop-gitops-vms-dev -o jsonpath='{.status.printableStatus}'
```

3. Verify the VirtualMachineInstance is running:
```bash
oc get vmi dev-vm-web-01 -n workshop-gitops-vms-dev
```

**Expected Result**: 
- `runStrategy` should be back to "Always"
- VM status should be "Running"
- VirtualMachineInstance should exist and be ready

### Step 6: Final Verification

1. Check final application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

2. List all VMs in the development environment:
```bash
oc get vm -n workshop-gitops-vms-dev
```

**Expected Result**: Application should be "Synced" and "Healthy"

## Summary of What Was Demonstrated

✓ **Manual Change**: Made a direct change to VM configuration (stopped the VM)  
✓ **Drift Detection**: ArgoCD detected the configuration drift (OutOfSync status)  
✓ **Automatic Correction**: ArgoCD automatically reverted the change  
✓ **State Restoration**: VM was restarted with the correct Git-defined configuration  
✓ **GitOps Enforcement**: Demonstrated that Git is the single source of truth  

## Key Learning Points

- **Configuration Drift**: Manual changes to resources are detected by ArgoCD
- **Self-Healing**: GitOps automatically corrects unauthorized changes
- **Audit Trail**: All changes and corrections are logged in ArgoCD
- **Consistency**: Git repository remains the authoritative source of configuration
- **Operational Safety**: Prevents configuration drift in production environments

## Troubleshooting

If the demo doesn't work as expected:

1. **VM not found**: Ensure the development environment is properly deployed
2. **ArgoCD not detecting drift**: Try forcing a refresh with annotation:
   ```bash
   oc annotate applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops argocd.argoproj.io/refresh="$(date)" --overwrite
   ```
3. **VM not starting**: Check VM events and DataVolume status:
   ```bash
   oc describe vm dev-vm-web-01 -n workshop-gitops-vms-dev
   ```
   ```bash
   oc get dv -n workshop-gitops-vms-dev
   ```