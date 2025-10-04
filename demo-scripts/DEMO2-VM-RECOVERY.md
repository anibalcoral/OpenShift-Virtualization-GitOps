# Demo 2: VM Recovery from Data Loss

## Overview
This demo demonstrates how GitOps can recover from complete VM and data loss scenarios. By deleting both the VM and its persistent storage, we simulate catastrophic data corruption or hardware failure, then show how ArgoCD automatically recreates the entire VM infrastructure from Git definitions.

## Prerequisites
- ArgoCD Operator installed and configured
- Workshop GitOps VMs development environment deployed
- Access to OpenShift cluster with `oc` CLI

## Environment Details
- **Namespace**: `workshop-gitops-vms-dev`
- **VM Name**: `dev-vm-web-02`
- **ArgoCD Application**: `workshop-gitops-vms-dev`
- **Scenario**: Complete VM and storage deletion (simulating data corruption)

## Step-by-Step Manual Instructions

### Step 1: Check Current VM State and Application Status

1. Check the ArgoCD application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

2. Verify the VM exists and its current state:
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev
```
```bash
oc get vmi dev-vm-web-02 -n workshop-gitops-vms-dev
```

3. Check associated DataVolume:
```bash
oc get dv -n workshop-gitops-vms-dev | grep dev-vm-web-02
```

4. Check VM pod if running:
```bash
oc get pods -n workshop-gitops-vms-dev | grep dev-vm-web-02
```

**Expected Result**: VM should exist and be properly configured with associated storage

### Step 2: Simulate Data Corruption Scenario

> **Note**: In a real scenario, you would access the VM console and run destructive commands like `rm -rf /*`, making the VM unresponsive. For this demo, we simulate by deleting the VM and storage directly.

1. Document current VM configuration before deletion:
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev -o yaml > /tmp/vm-backup.yaml
```

2. Delete the VM:
```bash
oc delete vm dev-vm-web-02 -n workshop-gitops-vms-dev
```

3. Verify VM deletion:
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev
```

**Expected Result**: VM should be deleted (command should return "not found")

### Step 3: Delete Persistent Storage

1. Wait a moment for VM deletion to propagate:
```bash
sleep 5
```

2. Check if DataVolume still exists:
```bash
oc get dv dev-vm-web-02 -n workshop-gitops-vms-dev
```

3. Delete the DataVolume to simulate complete data loss:
```bash
oc delete dv dev-vm-web-02 -n workshop-gitops-vms-dev
```

4. Verify DataVolume deletion:
```bash
oc get dv dev-vm-web-02 -n workshop-gitops-vms-dev
```

**Expected Result**: Both VM and DataVolume should be completely removed

### Step 4: Wait for ArgoCD to Detect Missing Resources

1. Monitor application sync status until drift is detected:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

2. You can force a refresh if needed:
```bash
oc annotate applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops argocd.argoproj.io/refresh="$(date)" --overwrite
```

**Expected Result**: Application sync status should change to "OutOfSync"

### Step 5: Trigger ArgoCD Sync for Recovery

1. Trigger manual sync to recreate the missing resources:
```bash
oc patch applications.argoproj.io $app_name -n $namespace --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}' &>/dev/null
```

2. Monitor the sync process:
```bash
watch oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

**Expected Result**: ArgoCD should start recreating the missing VM

### Step 6: Monitor VM Recreation

1. Watch for VM recreation:
```bash
# Run this command repeatedly until VM appears
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev
```

2. Monitor VM status during creation:
```bash
watch oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus"
```

3. Check for DataVolume recreation:
```bash
oc get dv -n workshop-gitops-vms-dev | grep dev-vm-web-02
```

**Expected Result**: VM should be recreated and start initializing

### Step 7: Wait for Application Sync Completion

1. Monitor until application returns to Synced state:
```bash
watch oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

2. Check application health:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.health.status}'
```

**Expected Result**: Application should return to "Synced" and "Healthy" status

### Step 8: Verify Complete Recovery

1. Confirm VM exists and is properly configured:
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus,MEMORY:.spec.template.spec.domain.resources.requests.memory"
```

2. Check DataVolume status:
```bash
oc get dv -n workshop-gitops-vms-dev | grep dev-vm-web-02
```

3. Verify VM configuration matches Git definition:
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev -o jsonpath='{.spec.runStrategy}'
```
```bash
oc get vm dev-vm-web-02 -n workshop-gitops-vms-dev -o jsonpath='{.spec.template.spec.domain.resources.requests.memory}'
```

4. Check if VM is running (may take time to start):
```bash
oc get vmi dev-vm-web-02 -n workshop-gitops-vms-dev
```

**Expected Result**: 
- VM should be recreated with correct configuration
- DataVolume should be recreated
- VM should eventually start running

### Step 9: Final Verification

1. List all VMs in the development environment:
```bash
oc get vm -n workshop-gitops-vms-dev
```

2. Check final application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

3. Verify the recreated VM has fresh storage:
```bash
oc describe dv dev-vm-web-02 -n workshop-gitops-vms-dev | grep -A 5 "Source:"
```

**Expected Result**: All resources should be recreated and application should be healthy

## Summary of What Was Demonstrated

✓ **Complete Data Loss**: Simulated catastrophic failure by deleting VM and storage  
✓ **Detection**: ArgoCD detected missing critical resources (OutOfSync status)  
✓ **Automatic Recovery**: ArgoCD automatically recreated all missing resources  
✓ **Fresh Storage**: New DataVolume created with clean base image  
✓ **Full Restoration**: Complete infrastructure recovered from Git definitions  
✓ **Disaster Recovery**: Demonstrated GitOps-based disaster recovery capabilities  

## Key Learning Points

- **Disaster Recovery**: GitOps provides automatic disaster recovery capabilities
- **Infrastructure as Code**: VM definitions in Git enable complete recreation
- **No Data Loss Prevention**: While data is lost, infrastructure is quickly restored
- **Consistency**: Recovered VM matches exact Git specification
- **Automation**: No manual intervention required for infrastructure recovery
- **Audit Trail**: Recovery process is logged and traceable

## Use Cases

This pattern is valuable for:
- **Disaster Recovery**: Recovering from hardware failures
- **Environment Refresh**: Creating clean development environments
- **Compliance**: Ensuring infrastructure matches approved configurations
- **Testing**: Validating complete deployment processes

## Troubleshooting

If the demo doesn't work as expected:

1. **VM not recreating**: Check ArgoCD application events:
   ```bash
   oc describe applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops
   ```

2. **DataVolume creation issues**: Check storage class and CSI driver:
   ```bash
   oc get storageclass
   ```
   ```bash
   oc get pods -n openshift-storage
   ```

3. **VM stuck in provisioning**: Check DataVolume and CDI pods:
   ```bash
   oc describe dv dev-vm-web-02 -n workshop-gitops-vms-dev
   ```
   ```bash
   oc get pods -n openshift-cnv | grep cdi
   ```

4. **Force sync if needed**:
   ```bash
   oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}'
   ```