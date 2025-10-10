# Demo 3: Adding New Development VM via Git Change

## Overview
This demo demonstrates how to add new Virtual Machines to the environment using GitOps workflow. By adding a new VM definition to Git and updating the kustomization, ArgoCD automatically deploys the new infrastructure without manual OpenShift intervention.

## Prerequisites
- ArgoCD Operator installed and configured
- Workshop GitOps VMs development environment deployed
- Access to Git repository: `OpenShift-Virtualization-GitOps-Apps`
- Git configured for commits and push access to the repository

## Environment Details
- **Namespace**: `workshop-gitops-vms-dev`
- **New VM Name**: `dev-vm-web-09`
- **ArgoCD Application**: `workshop-gitops-vms-dev`
- **Git Repository**: `OpenShift-Virtualization-GitOps-Apps`
- **Target Branch**: `vms-dev`

## Step-by-Step Manual Instructions

### Step 1: Check Current State

1. Check current ArgoCD application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

2. List existing VMs in development environment:
```bash
oc get vm -n workshop-gitops-vms-dev | grep -E "(NAME|dev-vm-web)"
```

3. Verify the new VM doesn't exist yet:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev
```

**Expected Result**: Should show only existing VMs (typically vm-web-01, vm-web-02, vm-web-03), and dev-vm-web-09 should not exist

### Step 2: Navigate to Git Repository

1. Change to your Git repository directory:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps
```

2. Ensure you're on the correct branch:
```bash
git branch --show-current
```

3. Switch to vms-dev branch if needed:
```bash
git checkout vms-dev
```

4. Pull latest changes:
```bash
git pull origin vms-dev
```

**Expected Result**: You should be on the `vms-dev` branch with latest changes

### Step 3: Create New VM Definition

1. Create the new VM file `base/vm-web-09.yaml`:
```bash
cat > base/vm-web-09.yaml << 'EOF'
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-web-09
  labels:
    app: web-server
    workshop: gitops-ocpvirt
  annotations:
    workshop.gitops/config-version: "v4-fedora-firewall-fix"
spec:
  dataVolumeTemplates:
  - apiVersion: cdi.kubevirt.io/v1beta1
    kind: DataVolumeTemplate
    metadata:
      name: vm-web-09
    spec:
      sourceRef:
        kind: DataSource
        name: fedora
        namespace: openshift-virtualization-os-images
      storage:
        resources:
          requests:
            storage: 30Gi
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: vm-web-09
        app: web-server
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            name: default
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.6.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      networks:
      - name: default
        pod: {}
      terminationGracePeriodSeconds: 180
      volumes:
      - dataVolume:
          name: vm-web-09
        name: rootdisk
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            user: cloud-user
            password: redhat123
            chpasswd: { expire: False }
            packages:
              - httpd
              - firewalld
            runcmd:
              - systemctl enable httpd
              - systemctl start httpd
              - echo 'Web Server - VM 09 (Development)' > /var/www/html/index.html
              - systemctl enable firewalld
              - systemctl start firewalld
              - firewall-cmd --permanent --add-service=http || true
              - firewall-cmd --reload || true
        name: cloudinitdisk
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: workshop-ssh-public-key
          propagationMethod:
            noCloud: {}
EOF
```

2. Verify the file was created:
```bash
ls -la base/vm-web-09.yaml
cat base/vm-web-09.yaml | head -20
```

**Expected Result**: File should be created with VM definition

### Step 4: Update Kustomization to Include New VM

1. Update the `base/kustomization.yaml` file:
```bash
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - vm-web-09.yaml
  - vm-web-01.yaml
  - vm-web-02.yaml
  - vm-web-service.yaml
EOF
```

2. Verify the updated kustomization:
```bash
cat base/kustomization.yaml
```

**Expected Result**: Kustomization should include vm-web-09.yaml in the resources list

### Step 5: Commit and Push Changes to Git

1. Check Git status:
```bash
git status
```

2. Add the new files:
```bash
git add .
```

3. Commit the changes:
```bash
git commit -m "feat: add development VM web-09 for expanded testing environment

- Add vm-web-09.yaml with Fedora-based web server configuration
- Update base kustomization to include new VM resource
- Provides additional development capacity for testing scenarios"
```

4. Push changes to repository:
```bash
git push origin vms-dev
```

5. Verify push was successful:
```bash
git log --oneline -1
```

**Expected Result**: Changes should be committed and pushed to the vms-dev branch

### Step 6: Return to OpenShift and Monitor ArgoCD

1. Return to your original working directory:
```bash
cd -
```

2. Force ArgoCD to check for changes:
```bash
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}
```

3. Monitor application status until drift is detected:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

**Expected Result**: Application status should change to "OutOfSync"

### Step 7: Trigger ArgoCD Sync

1. Trigger automatic sync (or wait for auto-sync if enabled):
```bash
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}'
```

2. Monitor sync progress:
```bash
watch oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o jsonpath='{.status.sync.status}'
```

**Expected Result**: Sync should be initiated

### Step 8: Monitor New VM Creation

1. Watch for new VM creation:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev
```

2. Monitor VM status during creation:
```bash
watch oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus"
```

3. Check DataVolume creation:
```bash
oc get dv -n workshop-gitops-vms-dev | grep dev-vm-web-09
```

**Expected Result**: New VM should be created and begin provisioning

### Step 9: Wait for Application Sync Completion

1. Monitor until application returns to Synced state:
```bash
watch oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

**Expected Result**: Application should return to "Synced" status

### Step 10: Verify New VM Deployment

1. Check that the new VM exists and is properly configured:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o custom-columns="NAME:.metadata.name,STATUS:.status.printableStatus,MEMORY:.spec.template.spec.domain.resources.requests.memory"
```

2. Verify VM configuration:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o jsonpath='{.spec.running}'
```
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o jsonpath='{.spec.template.spec.domain.cpu.cores}'
```

3. List all VMs in development environment:
```bash
oc get vm -n workshop-gitops-vms-dev | grep -E "(NAME|dev-vm-web)"
```

4. Check if VM is running (may take time to start):
```bash
oc get vmi dev-vm-web-09 -n workshop-gitops-vms-dev
```

**Expected Result**: 
- New VM should exist with correct configuration
- Development environment should now have 4 VMs
- VM should eventually start running

### Step 11: Final Verification

1. Verify final application status:
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

2. Count total VMs in environment:
```bash
oc get vm -n workshop-gitops-vms-dev --no-headers | wc -l
```

3. Check VM labels and annotations:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o jsonpath='{.metadata.labels}'
```

**Expected Result**: Environment should have expanded from 3 to 4 VMs, all managed by GitOps

## Summary of What Was Demonstrated

✓ **Infrastructure as Code**: New VM defined in Git repository  
✓ **Kustomization Update**: Base configuration updated to include new resource  
✓ **Git Workflow**: Changes committed and pushed through proper Git workflow  
✓ **Automatic Detection**: ArgoCD detected Git changes automatically  
✓ **Automatic Deployment**: New VM deployed without manual OpenShift commands  
✓ **Environment Expansion**: Development environment scaled from 3 to 4 VMs  
✓ **Configuration Consistency**: New VM follows same patterns as existing VMs  

## Key Learning Points

- **Scalability**: Easy to add new infrastructure through Git changes
- **Consistency**: New resources follow established patterns and configurations
- **Audit Trail**: All infrastructure changes tracked in Git history
- **Collaboration**: Multiple team members can propose infrastructure changes via Git
- **Rollback Capability**: Changes can be easily reverted through Git
- **Environment Parity**: Same process works across dev/test/prod environments

## Use Cases

This pattern is valuable for:
- **Environment Scaling**: Adding capacity during peak periods
- **Development**: Creating isolated development VMs for features
- **Testing**: Provisioning test environments for specific scenarios
- **Disaster Recovery**: Quickly recreating lost infrastructure

## Cleanup (Optional)

To remove the new VM after the demo:

1. Remove from kustomization:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps
```

2. Delete the VM file:
```bash
rm base/vm-web-09.yaml
```

3. Commit and push:
```bash
git add -A
```
```bash
git commit -m "cleanup: remove demo VM web-09"
```
```bash
git push origin vms-dev
```

## Troubleshooting

If the demo doesn't work as expected:

1. **Git push fails**: Check repository permissions and authentication
2. **ArgoCD not detecting changes**: Force refresh:
   ```bash
   oc annotate applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops argocd.argoproj.io/refresh="$(date)" --overwrite
   ```
3. **VM creation stuck**: Check DataVolume and storage:
   ```bash
   oc describe dv dev-vm-web-09 -n workshop-gitops-vms-dev
   ```
4. **Kustomization errors**: Validate YAML syntax and indentation