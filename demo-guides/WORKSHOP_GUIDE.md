# Workshop Guide: OpenShift GitOps with OpenShift Virtualization

This workshop demonstrates how to implement GitOps principles for managing Virtual Machines (VMs) in OpenShift Virtualization using OpenShift GitOps (ArgoCD).

## Table of Contents

- [Workshop Guide: OpenShift GitOps with OpenShift Virtualization](#workshop-guide-openshift-gitops-with-openshift-virtualization)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Learning Objectives](#learning-objectives)
    - [Architecture](#architecture)
    - [Workshop Environments](#workshop-environments)
   - [Development Environment (vms-dev-GUID branch)](#development-environment-vms-dev-guid-branch)
   - [Homologation Environment (vms-hml-GUID branch)](#homologation-environment-vms-hml-guid-branch)
   - [Production Environment (vms-prd-GUID branch)](#production-environment-vms-prd-guid-branch)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [Automated Installation](#automated-installation)
    - [Manual Installation](#manual-installation)
    - [Installation Verification](#installation-verification)
  - [Workshop Demonstrations](#workshop-demonstrations)
    - [Demo 1: Manual Change Detection and Drift Correction](#demo-1-manual-change-detection-and-drift-correction)
    - [Demo 2: VM Recovery from Data Loss](#demo-2-vm-recovery-from-data-loss)
    - [Demo 3: Adding New Development VM via Git Change](#demo-3-adding-new-development-vm-via-git-change)
    - [Demo 4: Multi-Environment VM Management with Kustomize](#demo-4-multi-environment-vm-management-with-kustomize)
  - [GitOps Workflow](#gitops-workflow)
    - [Development Process](#development-process)
    - [Promotion to Homologation](#promotion-to-homologation)
    - [Promotion to Production](#promotion-to-production)
  - [VM Access and Service Verification](#vm-access-and-service-verification)
    - [SSH Access to VMs](#ssh-access-to-vms)
    - [Service Verification](#service-verification)
  - [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
    - [Status Checking](#status-checking)
    - [Common Issues and Solutions](#common-issues-and-solutions)
      - [SSH Access Issues](#ssh-access-issues)
      - [ArgoCD Application Issues](#argocd-application-issues)
      - [GitOps Operator Issues](#gitops-operator-issues)
      - [Repository Access Issues](#repository-access-issues)
      - [Application Sync Issues](#application-sync-issues)
    - [Regular Monitoring Commands](#regular-monitoring-commands)
      - [Check Application Status](#check-application-status)
      - [Check Sync Status](#check-sync-status)
      - [Force Sync](#force-sync)
      - [Access ArgoCD UI](#access-argocd-ui)
  - [Cleanup](#cleanup)
    - [Cleanup Demo 3 or Demo 4](#cleanup-demo-3-or-demo-4)
    - [Complete Workshop Removal](#complete-workshop-removal)
    - [Manual Cleanup](#manual-cleanup)
  - [Best Practices and Technical Details](#best-practices-and-technical-details)
    - [VM Templates](#vm-templates)
    - [ArgoCD Configuration Details](#argocd-configuration-details)
    - [Best Practices Demonstrated](#best-practices-demonstrated)

## Overview

### Learning Objectives

After completing this workshop, participants will understand:
- How to implement GitOps for VM management
- ArgoCD configuration and application management
- Git-based workflow for infrastructure changes
- Manual drift detection and correction
- Disaster recovery using GitOps principles
- Environment promotion strategies
- Multi-environment deployments using branch-based strategies
- Kustomize for environment-specific configurations
- OpenShift Virtualization VM lifecycle management
- Infrastructure as Code best practices for virtualized workloads

### Architecture

```bash
Git Repository Structure
├── Main Repository: OpenShift-Virtualization-GitOps
│   ├── Installation scripts (install.sh, remove.sh)
│   ├── Demo automation (run-demos.sh)
│   ├── Manual installation YAML files
│   └── Workshop documentation
└── Apps Repository: OpenShift-Virtualization-GitOps-Apps
   ├── vms-prd-GUID branch (Production VMs) → overlays/prd
   ├── vms-hml-GUID branch (Homologation VMs) → overlays/hml
   └── vms-dev-GUID branch (Development VMs) → overlays/dev

Kustomize Structure (in Apps Repository)
├── base/ (Base VM templates)
│   ├── vm-web-01.yaml
│   ├── vm-web-02.yaml
│   └── vm-web-service.yaml
└── overlays/ (Environment-specific customizations)
    ├── dev/ (Development patches)
    ├── hml/ (Homologation patches)
    └── prd/ (Production patches)

ArgoCD Applications
├── workshop-gitops-vms-prd → Apps repo vms-prd-GUID branch → overlays/prd → workshop-gitops-vms-prd namespace
├── workshop-gitops-vms-hml → Apps repo vms-hml-GUID branch → overlays/hml → workshop-gitops-vms-hml namespace
└── workshop-gitops-vms-dev → Apps repo vms-dev-GUID branch → overlays/dev → workshop-gitops-vms-dev namespace
```

### Workshop Environments

The workshop creates three environments with different resource allocations:

#### Development Environment (vms-dev-GUID branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: `dev-vm-web-01`, `dev-vm-web-02`
- **Resources**: 2 CPU, 2GB RAM, 30GB disk per VM
- **Purpose**: Development and testing

#### Homologation Environment (vms-hml-GUID branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**: `hml-vm-web-01`, `hml-vm-web-02`
- **Resources**: 2 CPU, 4GB RAM, 30GB disk per VM
- **Purpose**: Pre-production testing

#### Production Environment (vms-prd-GUID branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**: `prd-vm-web-01`, `prd-vm-web-02`
- **Resources**: 4 CPU, 8GB RAM, 50GB disk per VM
- **Purpose**: Production workloads

## Prerequisites

1. OpenShift cluster with OpenShift Virtualization installed
2. oc CLI configured and logged in
3. ansible-playbook installed
4. Git repositories configured

## Installation

### Automated Installation

**Run Installation**
```bash
./install.sh
```

**What the automated installation does:**
1. Validates prerequisites (oc CLI and cluster login)
2. Installs OpenShift GitOps Operator
3. Creates RBAC permissions
4. Creates workshop namespaces for all environments (dev, hml, prd)
5. Creates ArgoCD applications for all environments
6. Displays ArgoCD credentials for access

### Manual Installation

For detailed workshop demonstrations, you can install components step by step using the pre-created YAML files:

1. **Install GitOps Operator:**
   ```bash
   oc apply -f manual-install-files/01-gitops-operator-subscription.yaml
   ```

2. **Create RBAC Permissions:**
   ```bash
   oc apply -f manual-install-files/02-cluster-role-binding.yaml
   ```

3. **Create Namespaces:**
   ```bash
   oc apply -f manual-install-files/03-namespaces.yaml
   ```

4. **Create ArgoCD Applications:**
   ```bash
   oc apply -f manual-install-files/04-argocd-app-dev.yaml
   oc apply -f manual-install-files/05-argocd-app-hml.yaml
   oc apply -f manual-install-files/06-argocd-app-prd.yaml
   ```

### Installation Verification

After installation, verify everything is working:

```bash
# Check ArgoCD Applications
oc get applications -n openshift-gitops

# Check VMs in each environment
oc get vms -n workshop-gitops-vms-dev
oc get vms -n workshop-gitops-vms-hml  
oc get vms -n workshop-gitops-vms-prd

# Check VM status (should show Running)
oc get vmi -A

# Run complete verification using the demo script
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s
```

**Expected Results after successful installation:**

ArgoCD Applications:
```bash
NAME                        SYNC STATUS   HEALTH STATUS
workshop-gitops-vms-dev     Synced        Healthy
workshop-gitops-vms-hml     Synced        Healthy
workshop-gitops-vms-prd     Synced        Healthy
```

Virtual Machines:
```bash
NAMESPACE                   NAME            STATUS
workshop-gitops-vms-dev     dev-vm-web-01   Running
workshop-gitops-vms-dev     dev-vm-web-02   Running
workshop-gitops-vms-hml     hml-vm-web-01   Running
workshop-gitops-vms-hml     hml-vm-web-02   Running
workshop-gitops-vms-prd     prd-vm-web-01   Running
workshop-gitops-vms-prd     prd-vm-web-02   Running
```

## Workshop Demonstrations

The workshop includes four comprehensive demonstrations that showcase GitOps capabilities in action. All demonstrations are automated through Ansible playbooks that provide consistent, reproducible results.

**Interactive Demo Runner**

Use the main demo script for a menu-driven interface:

```bash
/opt/OpenShift-Virtualization-GitOps/run-demos.sh
```

**Available options**:
- `1-4`: Execute individual demos with full automation
- `a`: Run all demos sequentially with validation between each
- `s`: Check comprehensive workshop status across all environments
- `c`: Cleanup Demo 4 resources for repeatability
- `q`: Quit the demo runner

### Demo 1: Manual Change Detection and Drift Correction

**Purpose**: Demonstrate how ArgoCD detects and corrects configuration drift automatically.

**Execution Methods**:
1. **Using demo runner** (recommended):
   ```bash
   /opt/OpenShift-Virtualization-GitOps/run-demos.sh 1
   ```

2. **Direct Ansible execution**:
   ```bash
   ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
   ```

**What the demo does**:
- Shows current VM configuration (runStrategy: Always)
- Makes a manual change to stop the VM (runStrategy: Halted)
- ArgoCD detects the drift and corrects it through manual sync
- VM returns to desired state defined in Git

**Learning Objectives**:
- Configuration drift detection through ArgoCD monitoring
- Manual sync and remediation capabilities
- GitOps principles ensuring desired state convergence

### Demo 2: VM Recovery from Data Loss

**Purpose**: Demonstrate complete disaster recovery capabilities through Git-based reconstruction.

**Execution Methods**:
1. **Using demo runner** (recommended):
   ```bash
   /opt/OpenShift-Virtualization-GitOps/run-demos.sh 2
   ```

2. **Direct Ansible execution**:
   ```bash
   ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml
   ```

**What the demo does**:
- Completely deletes a VM and its storage (simulating catastrophic data loss)
- ArgoCD detects missing resources and health degradation
- Automatically recreates the entire VM infrastructure from Git definitions
- Verifies complete functionality restoration

**Learning Objectives**:
- Disaster recovery through declarative infrastructure
- Infrastructure as Code providing robust backup strategy
- GitOps ensuring consistent recovery processes

### Demo 3: Adding New Development VM via Git Change

**Purpose**: Demonstrate infrastructure provisioning through Git-based workflows and automation.

**Execution Methods**:
1. **Using demo runner** (recommended):
   ```bash
   /opt/OpenShift-Virtualization-GitOps/run-demos.sh 3
   ```

2. **Direct Ansible execution**:
   ```bash
   ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml
   ```

**What the demo does**:
- Creates new VM definition in Git repository
- Updates Kustomize configuration to include new VM
- Commits and pushes changes to development branch
- ArgoCD detects and deploys the new VM through manual sync
- Provides cleanup automation for demo repeatability

**Learning Objectives**:
- Git-based infrastructure provisioning workflows
- Code review and approval processes for infrastructure changes
- Manual deployment through controlled synchronization

### Demo 4: Multi-Environment VM Management with Kustomize

**Purpose**: Demonstrate advanced GitOps practices for managing VMs across multiple environments using Kustomize overlays and Git branch promotion strategies.

**Execution Methods**:
1. **Using demo runner** (recommended):
   ```bash
   /opt/OpenShift-Virtualization-GitOps/run-demos.sh 4
   ```

2. **Direct Ansible execution**:
   ```bash
   ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml
   ```

**What the demo does**:
- Promotes VM changes from development → homologation → production environments
- Demonstrates environment-specific configurations using Kustomize overlays  
- Shows centralized base template management across environments
- Illustrates branch-based promotion strategies in GitOps workflows
- Validates different resource allocations per environment

**Learning Objectives**:
- Multi-environment GitOps workflows and promotion strategies
- Kustomize overlays for environment-specific configurations
- Safe promotion pipelines using Git branch strategies
- DRY (Don't Repeat Yourself) principles in infrastructure management

## GitOps Workflow

### Development Process

```bash
# Work on development branch
git checkout vms-dev-$GUID

# Make changes to base templates or overlays
vim base/vm-web-01.yaml
# or
vim overlays/dev/kustomization.yaml

# Commit changes
git add .
git commit -m "Update VM configuration"
git push origin vms-dev-$GUID
```

### Promotion to Homologation

```bash
git checkout vms-hml-$GUID
```

```bash
git merge vms-dev-$GUID
```

```bash
git push origin vms-hml-$GUID
```

### Promotion to Production

```bash
git checkout vms-prd-$GUID
```

```bash
git merge vms-hml-$GUID
```

```bash
git push origin vms-prd-$GUID
```

## VM Access and Service Verification

### SSH Access to VMs

VMs are automatically configured with SSH key access:

```bash
virtctl ssh cloud-user@<vm-name>
```

### Service Verification

Each environment exposes VM services for external access:

```bash
# Check services in each environment
oc get svc -n workshop-gitops-vms-dev
oc get svc -n workshop-gitops-vms-hml
oc get svc -n workshop-gitops-vms-prd

# Check routes (if created)
oc get routes -A

# Check endpoints
oc get endpoints -A

# Services target kubevirt.io/domain labels - verify VM pods have these labels
oc get pods -A --show-labels | grep kubevirt.io/domain

# Check service selectors match VM pod labels
oc get svc vm-web-service -n <namespace> -o yaml | grep selector -A 3
```

## Monitoring and Troubleshooting

### Status Checking

Check the current state of all workshop components across environments:

```bash
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s
```

This shows:
- ArgoCD application status
- Virtual machines in each environment
- Sync status and health

### Common Issues and Solutions

#### SSH Access Issues
```bash
# Verify SSH secret exists in each namespace
oc get secret workshop-gitops-vms-dev -n workshop-gitops-vms-dev
oc get secret workshop-gitops-vms-hml -n workshop-gitops-vms-hml
oc get secret workshop-gitops-vms-prd -n workshop-gitops-vms-prd

# Check VM accessCredentials configuration
oc get vm <vm-name> -n <namespace> -o yaml | grep -A 10 accessCredentials

# Clean known hosts
/opt/OpenShift-Virtualization-GitOps/run-demos.sh h
```

#### ArgoCD Application Issues
```bash
# Check application status
oc get applications -n openshift-gitops

# Force application sync if needed
oc patch applications workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"spec":{"syncPolicy":{"automated":null}},"operation":{"sync":{"revision":"HEAD","prune":true,"dryRun":false}}}'

# Check application details
oc describe applications workshop-gitops-vms-dev -n openshift-gitops
```

#### GitOps Operator Issues
```bash
# Check operator installation status
oc get csv -n openshift-operators | grep gitops

# Check operator pods
oc get pods -n openshift-operators | grep gitops

# Check ArgoCD pods
oc get pods -n openshift-gitops
```

#### Repository Access Issues
```bash
# Verify repository secret exists
oc get secret workshop-gitops-repo -n openshift-gitops

# Check secret labels
oc get secret workshop-gitops-repo -n openshift-gitops -o yaml | grep labels -A5

# Test Git connectivity from ArgoCD
oc exec deployment/openshift-gitops-repo-server -n openshift-gitops -- git ls-remote git@github.com:anibalcoral/OpenShift-Virtualization-GitOps.git
```

#### Application Sync Issues
```bash
# Force application sync
oc patch applications workshop-gitops-vms-dev -n openshift-gitops --type merge --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Check application details
oc describe applications workshop-gitops-vms-dev -n openshift-gitops
```

### Regular Monitoring Commands

#### Check Application Status
```bash
oc get applications -n openshift-gitops
```

#### Check Sync Status
```bash
oc get applications workshop-gitops-vms-dev -n openshift-gitops -o yaml
```

#### Force Sync
```bash
oc patch applications workshop-gitops-vms-dev -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
```

#### Access ArgoCD UI
```bash
# Get ArgoCD URL
oc get route openshift-gitops-server -n openshift-gitops

# Get admin password
oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d
```

## Cleanup

### Cleanup Demo 3 or Demo 4

```bash
./run-demos.sh c
```

### Complete Workshop Removal

```bash
./remove.sh
```

This will:
1. Remove all ArgoCD applications
2. Delete all workshop namespaces and VMs
3. Remove cluster role bindings
4. Optionally remove the GitOps operator

### Manual Cleanup

If needed, you can remove individual components:

```bash
# Remove ArgoCD applications
oc delete -f manual-install-files/06-argocd-app-prd.yaml
oc delete -f manual-install-files/05-argocd-app-hml.yaml
oc delete -f manual-install-files/04-argocd-app-dev.yaml

# Remove namespaces (this removes all VMs)
oc delete namespace workshop-gitops-vms-dev
oc delete namespace workshop-gitops-vms-hml
oc delete namespace workshop-gitops-vms-prd

# Remove RBAC
oc delete -f manual-install-files/02-cluster-role-binding.yaml
```

## Best Practices and Technical Details

### VM Templates

All VMs use the Fedora template with cloud-init for initial configuration:
- Default user: `cloud-user`
- Default password: `redhat123`
- SSH access configured
- Environment-specific applications installed

### ArgoCD Configuration Details

Each ArgoCD application is configured with:
- **Automatic Sync**: Disabled

### Best Practices Demonstrated

1. **Infrastructure as Code**: All VM definitions stored in Git
2. **Environment Separation**: Different branches for different environments
3. **Manual Deployment**: Changes deployed via ArgoCD manual sync operations
4. **Drift Detection**: Manual changes detected and corrected
5. **Disaster Recovery**: Complete environment recovery from Git
6. **Security**: Proper RBAC and namespace isolation