# Demo 4: Multi-Environment VM Management with Kustomize

## Overview
This demo demonstrates advanced GitOps practices for managing Virtual Machines across multiple environments (development, homologation, and production) using Kustomize overlays and Git branch promotion strategies. It showcases how to efficiently manage environment-specific configurations while maintaining consistency across environments. The demo is automated through Ansible playbooks but includes manual step-by-step instructions for educational purposes.

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
  - `workshop-gitops-vms-dev` (targets `vms-dev-{guid}` branch)
  - `workshop-gitops-vms-hml` (targets `vms-hml-{guid}` branch)
  - `workshop-gitops-vms-prd` (targets `vms-prd-{guid}` branch)
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

2. List VMs in all environments to confirm current state:
```bash
echo "=== Development Environment ==="
oc get vm -n workshop-gitops-vms-dev | grep -E "(NAME|vm-web)"

echo "=== Homologation Environment ==="
oc get vm -n workshop-gitops-vms-hml | grep -E "(NAME|vm-web)"

echo "=== Production Environment ==="
oc get vm -n workshop-gitops-vms-prd | grep -E "(NAME|vm-web)"
```

3. Verify that dev-vm-web-09 exists only in development:
```bash
echo "Checking dev-vm-web-09 in development:"
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev --no-headers 2>/dev/null || echo "Not found"

echo "Checking hml-vm-web-09 in homologation:"
oc get vm hml-vm-web-09 -n workshop-gitops-vms-hml --no-headers 2>/dev/null || echo "Not found (expected)"

echo "Checking prd-vm-web-09 in production:"
oc get vm prd-vm-web-09 -n workshop-gitops-vms-prd --no-headers 2>/dev/null || echo "Not found (expected)"
```

**Expected Result**: dev-vm-web-09 should exist only in development environment

### Step 2: Navigate to Git Repository and Check Branches

1. Change to your Git repository directory:
```bash
cd /opt/OpenShift-Virtualization-GitOps-Apps
```

2. Check current branch and available branches:
```bash
git branch -a
git status
```

3. Ensure you're on the vms-dev branch:
```bash
git checkout vms-dev-$GUID
```

**Expected Result**: You should be on vms-dev branch with no uncommitted changes

### Step 3: Promote Development Changes to Homologation

1. Create a merge to homologation branch:
```bash
git checkout vms-hml-$GUID
git merge vms-dev-$GUID
```

2. Push the changes:
```bash
git push origin vms-hml-$GUID
```

3. Wait for ArgoCD to detect and sync the changes:
```bash
echo "Waiting for ArgoCD to sync homologation environment..."
# Monitor the sync status
watch -n 5 "oc get applications workshop-gitops-vms-hml -n openshift-gitops -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'"
```

4. Verify the VM was created in homologation:
```bash
oc get vm -n workshop-gitops-vms-hml | grep hml-vm-web-09
```

**Expected Result**: hml-vm-web-09 should be created in the homologation environment

### Step 4: Promote Homologation Changes to Production

1. Merge homologation to main (production):
```bash
git checkout vms-prd-$GUID
git merge vms-hml-$GUID
```

2. Push the changes:
```bash
git push origin vms-prd-$GUID
```

3. Wait for ArgoCD to sync production environment:
```bash
echo "Waiting for ArgoCD to sync production environment..."
# Monitor the sync status
watch -n 5 "oc get applications workshop-gitops-vms-prd -n openshift-gitops -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'"
```

4. Verify the VM was created in production:
```bash
oc get vm -n workshop-gitops-vms-prd | grep prd-vm-web-09
```

**Expected Result**: prd-vm-web-09 should be created in the production environment

### Step 5: Verify Multi-Environment Deployment

1. List all vm-web-09 instances across environments:
```bash
echo "=== VM Web 09 Across All Environments ==="
echo "Development:"
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev --no-headers 2>/dev/null || echo "Not found"

echo "Homologation:"
oc get vm hml-vm-web-09 -n workshop-gitops-vms-hml --no-headers 2>/dev/null || echo "Not found"

echo "Production:"
oc get vm prd-vm-web-09 -n workshop-gitops-vms-prd --no-headers 2>/dev/null || echo "Not found"
```

2. Compare configurations between environments using Kustomize:
```bash
echo "=== Development Configuration ==="
kubectl kustomize overlays/dev | grep -A 5 -B 5 "vm-web-09"

echo "=== Homologation Configuration ==="
kubectl kustomize overlays/hml | grep -A 5 -B 5 "vm-web-09"

echo "=== Production Configuration ==="
kubectl kustomize overlays/prd | grep -A 5 -B 5 "vm-web-09"
```

**Expected Result**: All three environments should have their respective VM instances with proper naming prefixes and namespace configurations

### Step 6: Demonstrate Centralized Base Management

1. Go back to development branch to make a base change:
```bash
git checkout vms-dev-$GUID
```

2. Add a new annotation to the base VM template:
```bash
# Edit the base vm-web-09.yaml file to add a new annotation
sed -i '/workshop.gitops\/config-version/a\    workshop.gitops/demo4-timestamp: "'$(date +%Y%m%d-%H%M%S)'"' base/vm-web-09.yaml
```

3. Commit the change:
```bash
git add base/vm-web-09.yaml
git commit -m "Add demo4 timestamp annotation to vm-web-09 base template"
git push origin vms-dev-$GUID
```

4. Wait for development environment to sync:
```bash
echo "Waiting for development environment to sync..."
watch -n 5 "oc get applications workshop-gitops-vms-dev -n openshift-gitops -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'"
```

5. Verify the annotation was added in development:
```bash
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o yaml | grep -A 3 -B 3 "demo4-timestamp"
```

**Expected Result**: The new annotation should appear in the development VM

### Step 7: Promote Base Changes Through All Environments

1. Promote the base change to homologation:
```bash
git checkout vms-hml-$GUID
git merge vms-dev-$GUID
git push origin vms-hml-$GUID
```

2. Promote to production:
```bash
git checkout vms-prd-$GUID
git merge vms-hml-$GUID
git push origin vms-prd-$GUID
```

3. Wait for all environments to sync and verify the annotation exists in all VMs:
```bash
echo "=== Checking annotations across all environments ==="
echo "Development:"
oc get vm dev-vm-web-09 -n workshop-gitops-vms-dev -o yaml | grep "demo4-timestamp" || echo "Not found"

echo "Homologation:"
oc get vm hml-vm-web-09 -n workshop-gitops-vms-hml -o yaml | grep "demo4-timestamp" || echo "Not found"

echo "Production:"
oc get vm prd-vm-web-09 -n workshop-gitops-vms-prd -o yaml | grep "demo4-timestamp" || echo "Not found"
```

**Expected Result**: The same annotation should appear in all three environments, demonstrating how base template changes propagate through the promotion pipeline

### Step 8: Demonstrate Environment-Specific Differences

1. Show how Kustomize handles environment-specific configurations:
```bash
echo "=== Resource Names Across Environments ==="
oc get vm -n workshop-gitops-vms-dev | grep vm-web-09
oc get vm -n workshop-gitops-vms-hml | grep vm-web-09  
oc get vm -n workshop-gitops-vms-prd | grep vm-web-09

echo "=== Services Across Environments ==="
oc get svc -n workshop-gitops-vms-dev | grep vm-web-service
oc get svc -n workshop-gitops-vms-hml | grep vm-web-service
oc get svc -n workshop-gitops-vms-prd | grep vm-web-service

echo "=== Routes Across Environments ==="
oc get route -n workshop-gitops-vms-dev | grep vm-web-route
oc get route -n workshop-gitops-vms-hml | grep vm-web-route
oc get route -n workshop-gitops-vms-prd | grep vm-web-route
```

**Expected Result**: Each environment should have appropriately prefixed resources (dev-, hml-, prd-) in their respective namespaces

## Demo Summary

This demo demonstrates several key GitOps and Kustomize concepts:

1. **Branch-based Environment Promotion**: Changes flow from `vms-dev` → `vms-hml` → `main` (production)
2. **Kustomize Overlays**: Environment-specific configurations without code duplication
3. **Centralized Base Management**: Common changes applied once in base templates automatically propagate to all environments
4. **Consistent Multi-Environment Deployment**: Same base configuration with environment-specific customizations
5. **GitOps Automation**: ArgoCD automatically detects and applies changes across all environments

## Key Learning Points

- **DRY Principle**: Don't Repeat Yourself - manage common configurations in base templates
- **Safe Promotion**: Use Git branches to control promotion flow between environments
- **Environment Isolation**: Each environment maintains its own namespace and configurations
- **Automated Synchronization**: ArgoCD ensures environments stay in sync with their respective Git branches
- **Configuration Management**: Kustomize provides a declarative way to manage environment differences

### Verification Commands

```bash
# Check all ArgoCD applications
oc get applications -n openshift-gitops

# Check VM status across environments
for ns in workshop-gitops-vms-dev workshop-gitops-vms-hml workshop-gitops-vms-prd; do
  echo "=== Namespace: $ns ==="
  oc get vm -n $ns | grep vm-web-09
done

# Check Git branch status
cd /opt/OpenShift-Virtualization-GitOps-Apps
git log --oneline --graph --branches
```

## Cleanup

To clean up the resources created in this demo:

```bash
# Remove vm-web-09 from all branches (optional)
cd /opt/OpenShift-Virtualization-GitOps-Apps

# Remove from development
git checkout vms-dev-$GUID
git rm base/vm-web-09.yaml
sed -i '/vm-web-09.yaml/d' base/kustomization.yaml
git commit -m "Remove vm-web-09 from development"
git push origin vms-dev-$GUID

# Promote removal through environments
git checkout vms-hml-$GUID
git merge vms-dev-$GUID -m "Remove vm-web-09 from homologation"
git push origin vms-hml-$GUID

git checkout vms-prd-$GUID
git merge vms-hml-$GUID -m "Remove vm-web-09 from production"
git push origin vms-prd-$GUID
```

Wait for ArgoCD to sync and remove the VMs from all environments automatically.