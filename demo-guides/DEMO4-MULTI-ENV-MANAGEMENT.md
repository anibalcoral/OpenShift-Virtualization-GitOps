# Demo 4: Multi-Environment VM Management with Kustomize

## Overview
This demo demonstrates advanced GitOps practices for managing Virtual Machines across multiple environments (development, homologation, and production) using Kustomize overlays and Git branch promotion strategies. It showcases how to efficiently manage environment-specific configurations while maintaining consistency across environments through manual sync operations. The demo is automated through Ansible playbooks but includes manual step-by-step instructions for educational purposes.

## Prerequisites
- OpenShift GitOps Workshop installed and configured
- GUID environment variable set (`export GUID=user01`)
- Workshop GitOps VMs deployed in all environments (dev, hml, prd)
- Access to Git repository: `OpenShift-Virtualization-GitOps-Apps`
- Git configured for commits and push access to the repository
- Demo 3 completed (dev-vm-web-09 exists in development environment)

## What the Demo Does

1. **Environment Status Check**: Verifies all ArgoCD applications and current VMs in each environment
2. **Development to Homologation Promotion**: 
   - Merges development branch changes into homologation branch
   - Updates Kustomize overlays for environment-specific configurations
   - Monitors ArgoCD sync for homologation environment
3. **Homologation to Production Promotion**:
   - Merges homologation branch changes into production branch
   - Applies production-specific Kustomize patches
   - Monitors ArgoCD sync for production environment
4. **Verification**: Confirms VMs are deployed in all environments with correct configurations
5. **Environment Comparison**: Shows differences in VM configurations across environments (CPU, memory, naming)

## Environment Details
- **GUID**: Dynamic based on environment variable
- **Development Namespace**: `workshop-gitops-vms-dev`
- **Homologation Namespace**: `workshop-gitops-vms-hml`
- **Production Namespace**: `workshop-gitops-vms-prd`
- **ArgoCD Applications**: 
  - `workshop-gitops-vms-dev` (targets `vms-dev-GUID` branch)
  - `workshop-gitops-vms-hml` (targets `vms-hml-GUID` branch)
  - `workshop-gitops-vms-prd` (targets `vms-prd-GUID` branch)
- **Git Repository**: `OpenShift-Virtualization-GitOps-Apps`

## Kustomize Environment Strategy

The demo showcases how Kustomize overlays provide environment-specific configurations:

- **Development**: Lower resource allocation, development naming prefix
- **Homologation**: Medium resource allocation, homologation naming prefix  
- **Production**: Higher resource allocation, production naming prefix, enhanced monitoring

## Step-by-Step Manual Instructions

### Step 1: Verify Current State

1. Check all ArgoCD applications status:
```bash
oc get applications -n openshift-gitops | grep workshop-gitops-vms
```

2. List VMs in development environment:
```bash
oc get vm -n workshop-gitops-vms-dev | grep -E "(NAME|vm-web)"
```

3. List VMs in homologation environment:
```bash
oc get vm -n workshop-gitops-vms-hml | grep -E "(NAME|vm-web)"
```

4. List VMs in production environment:
```bash
oc get vm -n workshop-gitops-vms-prd | grep -E "(NAME|vm-web)"
```

5. Verify that dev-vm-web-09 exists in development:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev --no-headers 2>/dev/null || echo "Not found"
```

6. Verify that hml-vm-web-09 does not exist in homologation (expected):
```bash
oc get vm hml-vm-web-09 -n workshop-gitops-vms-hml --no-headers 2>/dev/null || echo "Not found (expected)"
```

7. Verify that prd-vm-web-09 does not exist in production (expected):
```bash
oc get vm prd-vm-web-09 -n workshop-gitops-vms-prd --no-headers 2>/dev/null || echo "Not found (expected)"
```

**Expected Result**: dev-vm-web-09 should exist only in development environment

### Step 2: Navigate to Git Repository and Check Branches

1. Change to your Git repository directory:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps
```

2. Check available branches:
```bash
git branch -a | grep $GUID
```

3. Check Git status:
```bash
git status
```

4. Ensure you're on the vms-dev-GUID branch:
```bash
git checkout vms-dev-$GUID
```

**Expected Result**: You should be on vms-dev-GUID branch with no uncommitted changes

### Step 3: Promote Development Changes to Homologation

1. Checkout homologation branch:
```bash
git checkout vms-hml-$GUID
```

2. Merge development branch into homologation:
```bash
git merge vms-dev-$GUID
```

3. Push the changes:
```bash
git push origin vms-hml-$GUID
```

4. Force ArgoCD to detect and sync the changes:
```bash
oc patch applications workshop-gitops-vms-hml -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}' &>/dev/null
```

5. Verify the VM was created in homologation:
```bash
watch "oc get vm -n workshop-gitops-vms-hml | grep hml-vm-web-09"
```

**Expected Result**: hml-vm-web-09 should be created in the homologation environment

### Step 4: Promote Homologation Changes to Production

1. Checkout production branch:
```bash
git checkout vms-prd-$GUID
```

2. Merge homologation branch into production:
```bash
git merge vms-hml-$GUID
```

3. Push the changes:
```bash
git push origin vms-prd-$GUID
```

4. Force ArgoCD to detect and sync the changes:
```bash
oc patch applications workshop-gitops-vms-prd -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}' &>/dev/null
```

5. Verify the VM was created in production:
```bash
watch "oc get vm -n workshop-gitops-vms-prd | grep prd-vm-web-09"
```

**Expected Result**: prd-vm-web-09 should be created in the production environment

### Step 5: Verify Multi-Environment Deployment

1. Check dev-vm-web-09 in development:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev --no-headers 2>/dev/null || echo "Not found"
```

2. Check hml-vm-web-09 in homologation:
```bash
oc get vm hml-vm-web-09 -n workshop-gitops-vms-hml --no-headers 2>/dev/null || echo "Not found"
```

3. Check prd-vm-web-09 in production:
```bash
oc get vm prd-vm-web-09 -n workshop-gitops-vms-prd --no-headers 2>/dev/null || echo "Not found"
```

4. Check development configuration using Kustomize:
```bash
oc kustomize overlays/dev | grep -A 5 -B 5 "vm-web-09"
```

5. Check homologation configuration using Kustomize:
```bash
oc kustomize overlays/hml | grep -A 5 -B 5 "vm-web-09"
```

6. Check production configuration using Kustomize:
```bash
oc kustomize overlays/prd | grep -A 5 -B 5 "vm-web-09"
```

**Expected Result**: All three environments should have their respective VM instances with proper naming prefixes and namespace configurations

## Demo Summary

This demo demonstrates several key GitOps and Kustomize concepts:

1. **Branch-based Environment Promotion**: Changes flow from `vms-dev` → `vms-hml` → `vms-prd` (production)
2. **Kustomize Overlays**: Environment-specific configurations without code duplication
3. **Centralized Base Management**: Common changes applied once in base templates manually propagate to all environments
4. **Consistent Multi-Environment Deployment**: Same base configuration with environment-specific customizations
5. **GitOps Control**: ArgoCD detects and applies changes across all environments through manual sync operations

## Key Learning Points

- **DRY Principle**: Don't Repeat Yourself - manage common configurations in base templates
- **Safe Promotion**: Use Git branches to control promotion flow between environments
- **Environment Isolation**: Each environment maintains its own namespace and configurations
- **Manual Synchronization**: ArgoCD ensures environments stay in sync with their respective Git branches through manual sync operations
- **Configuration Management**: Kustomize provides a declarative way to manage environment differences

### Verification Commands

1. Check all ArgoCD applications:
```bash
oc get applications -n openshift-gitops
```

2. Check VM status in development:
```bash
oc get vm -n workshop-gitops-vms-dev | grep vm-web-09
```

3. Check VM status in homologation:
```bash
oc get vm -n workshop-gitops-vms-hml | grep vm-web-09
```

4. Check VM status in production:
```bash
oc get vm -n workshop-gitops-vms-prd | grep vm-web-09
```

5. Check Git branch status:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps && git log --oneline -1
```

## Cleanup

To clean up the resources created in this demo:

1. Navigate to the Apps repository:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps
```

2. Checkout development branch:
```bash
git checkout vms-dev-$GUID
```

3. Remove the VM file:
```bash
git rm base/vm-web-09.yaml
```

4. Remove VM from kustomization:
```bash
sed -i '/vm-web-09.yaml/d' base/kustomization.yaml
```

5. Commit the changes:
```bash
git commit -m "Remove vm-web-09 from development"
```

6. Push to development branch:
```bash
git push origin vms-dev-$GUID
```

7. Checkout homologation branch:
```bash
git checkout vms-hml-$GUID
```

8. Merge development into homologation:
```bash
git merge vms-dev-$GUID -m "Remove vm-web-09 from homologation"
```

9. Push to homologation branch:
```bash
git push origin vms-hml-$GUID
```

10. Checkout production branch:
```bash
git checkout vms-prd-$GUID
```

11. Merge homologation into production:
```bash
git merge vms-hml-$GUID -m "Remove vm-web-09 from production"
```

12. Push to production branch:
```bash
git push origin vms-prd-$GUID
```

Wait for ArgoCD to sync and remove the VMs from all environments through manual sync operations.
