# Workshop Guide: OpenShift GitOps with OpenShift Virtualization

This workshop demonstrates how to implement GitOps principles for managing Virtual Machines (VMs) in OpenShift Virtualization using OpenShift GitOps (ArgoCD).

## Architecture

```
Git Repository Structure
├── Main Repository: OpenShift-Virtualization-GitOps
│   ├── Installation scripts (install.sh, remove.sh)
│   ├── Demo scripts (demo-scripts/run-demos.sh)
│   ├── Manual installation YAML files
│   └── Workshop documentation
└── Apps Repository: OpenShift-Virtualization-GitOps-Apps
    ├── main branch (Production VMs) → overlays/prd
    ├── vms-hml branch (Homologation VMs) → overlays/hml
    └── vms-dev branch (Development VMs) → overlays/dev

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
├── workshop-gitops-vms-prd → Apps repo main branch → overlays/prd → workshop-gitops-vms-prd namespace
├── workshop-gitops-vms-hml → Apps repo vms-hml branch → overlays/hml → workshop-gitops-vms-hml namespace
└── workshop-gitops-vms-dev → Apps repo vms-dev branch → overlays/dev → workshop-gitops-vms-dev namespace
```

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

### Manual Installation (for Workshop Demonstrations)

For detailed workshop demonstrations, use the pre-created YAML files:

1. **Install GitOps Operator:**
   ```bash
   oc apply -f manual-install/01-gitops-operator-subscription.yaml
   ```

2. **Create RBAC Permissions:**
   ```bash
   oc apply -f manual-install/02-cluster-role-binding.yaml
   ```

3. **Create Namespaces:**
   ```bash
   oc apply -f manual-install/03-namespaces.yaml
   ```

4. **Create ArgoCD Applications:**
   ```bash
   oc apply -f manual-install/04-argocd-app-dev.yaml
   oc apply -f manual-install/05-argocd-app-hml.yaml
   oc apply -f manual-install/06-argocd-app-prd.yaml
   ```
   ```bash
   oc apply -f manual-install/02-cluster-role-binding.yaml
   ```

3. **Create Namespaces:**
   ```bash
   oc apply -f manual-install/03-namespaces.yaml
   ```

4. **Create Repository Secret:**
   ```bash
   oc create secret generic workshop-gitops-repo \
     --from-file=sshPrivateKey=$HOME/.ssh/ocpvirt-gitops \
     --from-literal=url=git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git \
     --from-literal=type=git \
     -n openshift-gitops --dry-run=client -o yaml | oc apply -f -
   
   oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository
   ```

5. **Create ArgoCD Applications:**
   ```bash
   oc apply -f manual-install/04-argocd-app-dev.yaml
   oc apply -f manual-install/05-argocd-app-hml.yaml
   oc apply -f manual-install/06-argocd-app-prd.yaml
   ```

## Post-Installation: VM Access and Service Verification

After installation, you can access and verify your VMs:

### Installation Verification

```bash
# Check ArgoCD Applications
oc get applications.argoproj.io -n openshift-gitops

# Check VMs in each environment
oc get vms -n workshop-gitops-vms-dev
oc get vms -n workshop-gitops-vms-hml  
oc get vms -n workshop-gitops-vms-prd

# Check VM status (should show Running)
oc get vmi -A

# Run complete verification using the demo script
./run-demos.sh s
```

### SSH Access to VMs

VMs are automatically configured with SSH key access:

```bash
# Get VM IP addresses
oc get vmi -A

# SSH to web VM (example for dev environment)
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
```
oc get endpoints -A

# Services target kubevirt.io/domain labels - verify VM pods have these labels
oc get pods -A --show-labels | grep kubevirt.io/domain

# Check service selectors match VM pod labels
oc get svc vm-web-service -n <namespace> -o yaml | grep selector -A 3
```

**SSH Access Issues:**
```bash
# Verify SSH secret exists in each namespace
oc get secret workshop-gitops-vms-dev -n workshop-gitops-vms-dev
oc get secret workshop-gitops-vms-hml -n workshop-gitops-vms-hml
oc get secret workshop-gitops-vms-prd -n workshop-gitops-vms-prd

# Check VM accessCredentials configuration
oc get vm <vm-name> -n <namespace> -o yaml | grep -A 10 accessCredentials

# SSH keys are pre-configured in the Apps repository SSH secret
# No additional setup needed
```

**ArgoCD Application Issues:**
```bash
# Check application status
oc get applications.argoproj.io -n openshift-gitops

# Force application sync if needed
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge -p '{"spec":{"syncPolicy":{"automated":null}},"operation":{"sync":{"revision":"HEAD","prune":true,"dryRun":false}}}'

# Check application details
oc describe applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops
```

**Detailed Manual Steps:**
Follow the instructions below, or use the individual YAML files in `manual-install/` directory for step-by-step execution.

## Prerequisites

1. OpenShift cluster with OpenShift Virtualization installed
2. oc CLI configured and logged in
3. ansible-playbook installed
4. Git repository configured with your GitHub username

## Setup Instructions

### Option 1: Automated Installation (Recommended for Quick Start)

## Workshop Demonstrations

The workshop includes three main demonstrations that show GitOps capabilities in action:

### Demo 1: Manual Change Detection and Drift Correction

**Purpose**: Demonstrate how ArgoCD detects and corrects configuration drift.

**Steps**:
1. Use the demo runner:
   ```bash
   ./run-demos.sh 1
   ```

2. This will:
   - Show current VM configuration
   - Make a manual change to VM resources (scale CPU to 4 cores)
   - ArgoCD will detect the drift and automatically correct it

**Learning Objectives**:
- Configuration drift detection
- Automatic self-healing
- GitOps principles in action

### Demo 2: VM Recovery from Data Loss

**Purpose**: Demonstrate how ArgoCD can recover from complete resource deletion.

**Steps**:
1. Use the demo runner:
   ```bash
   ./run-demos.sh 2
   ```

2. This will:
   - Delete a VM completely (simulating data loss)
   - ArgoCD will detect the missing resource
   - Automatically recreate the VM from Git

**Learning Objectives**:
- Disaster recovery capabilities
- Infrastructure as Code benefits
- Declarative resource management

### Demo 3: Adding New Development VM via Git Change

**Purpose**: Demonstrate infrastructure provisioning through Git commits.

**Steps**:
1. Use the demo runner:
   ```bash
   ./run-demos.sh 3
   ```

2. This provides instructions for:
   - Manual Git operations to add new VMs
   - Updating Kustomize configurations
   - ArgoCD automatically deploying changes

**Learning Objectives**:
- Git-based infrastructure provisioning
- Code review workflows for infrastructure
- Environment-specific configurations

### Demo 4: Multi-Environment VM Management with Kustomize

**Purpose**: Demonstrate advanced GitOps practices for managing VMs across multiple environments using Kustomize overlays and Git branch promotion.

**Steps**:
1. Use the demo runner:
   ```bash
   ./run-demos.sh 4
   ```

2. This demonstrates:
   - Promoting VM changes from development → homologation → production
   - Environment-specific configurations using Kustomize overlays
   - Centralized base template management
   - Branch-based promotion strategies

**Learning Objectives**:
- Multi-environment GitOps workflows
- Kustomize for environment-specific configurations
- Safe promotion pipelines using Git branches
- DRY principle in infrastructure management

### Interactive Demo Runner

The main demo script provides a menu-driven interface:

```bash
./run-demos.sh
```

**Available options**:
- `1-4`: Individual demos
- `a`: Run all demos sequentially  
- `s`: Check workshop status
- `c`: Cleanup Demo 3 resources
- `d`: Cleanup Demo 4 resources
- `q`: Quit

### Status Checking

Check the current state of all workshop components:

```bash
./run-demos.sh s
```

This shows:
- ArgoCD application status
- Virtual machines in each environment
- Sync status and health
echo "ArgoCD Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"

# Check application status
oc get applications.argoproj.io -n openshift-gitops

# Check workshop status
## Workshop Environments

The workshop creates three environments with different resource allocations:

### Development Environment (vms-dev branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: `dev-vm-web-01`, `dev-vm-web-02`, `dev-vm-web-09`
- **Resources**: 1 CPU, 2GB RAM, 30GB disk per VM
- **Purpose**: Development and testing

### Homologation Environment (vms-hml branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**: `hml-vm-web-01`, `hml-vm-web-02`, `hml-vm-web-09`
- **Resources**: 2 CPU, 3GB RAM, 40GB disk per VM
- **Purpose**: Pre-production testing

### Production Environment (main branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**: `prd-vm-web-01`, `prd-vm-web-02`, `prd-vm-web-09`
- **Resources**: 2 CPU, 4GB RAM, 50GB disk per VM
- **Purpose**: Production workloads

## Cleanup

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
oc delete -f manual-install/06-argocd-app-prd.yaml
oc delete -f manual-install/05-argocd-app-hml.yaml
oc delete -f manual-install/04-argocd-app-dev.yaml

# Remove namespaces (this removes all VMs)
oc delete namespace workshop-gitops-vms-dev
oc delete namespace workshop-gitops-vms-hml
oc delete namespace workshop-gitops-vms-prd

# Remove RBAC
oc delete -f manual-install/02-cluster-role-binding.yaml

# Remove GitOps operator (optional)
oc delete -f manual-install/01-gitops-operator-subscription.yaml
```

## Learning Objectives

This workshop teaches:
- GitOps principles applied to virtual machine management
- Multi-environment deployments using branch-based strategies
- Kustomize for environment-specific configurations
- ArgoCD for continuous deployment and drift detection
- OpenShift Virtualization VM lifecycle management
- Infrastructure as Code best practices for virtualized workloads

## Additional Resources

- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **OpenShift Virtualization**: https://docs.openshift.com/container-platform/latest/virt/about-virt.html
- **Kustomize**: https://kustomize.io/

Demonstrates the complete GitOps deployment process from scratch.

```bash
./demo-scripts/demo4-initial-deployment.sh
```

**What happens:**
1. Review VirtualMachine YAML structure in Git
2. Examine production overlay customizations
3. Show ArgoCD application in "OutOfSync" state
4. Trigger manual sync in ArgoCD
5. Monitor VM creation and startup process
6. Verify all associated resources (DataVolume, Service, Route)

### Demo 5: Live VM Configuration Update via Git

Demonstrates live infrastructure updates through Git workflow.

```bash
./demo-scripts/demo5-live-config-update.sh
```

**What happens:**
1. Check current VM configuration (2Gi memory)
2. Edit VM configuration in Git (change to 4Gi memory)
3. Commit and push changes to vms-hml branch
4. ArgoCD automatically detects Git changes
5. ArgoCD applies configuration update to running VM
6. VM restarts with new memory configuration
7. Configuration automatically restored to baseline after demo

### Running All Demos

Use the interactive demo runner to easily run any demo:

```bash
./run-demos.sh
```

This script provides a menu-driven interface to run any demo or check workshop status.

## GitOps Workflow

### 1. Development Process

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

### 2. Promotion to Homologation

```bash
# Create merge request from vms-dev to vms-hml
# After approval and merge, changes appear in homologation environment automatically
```

### 3. Promotion to Production

```bash
# Create merge request from vms-hml to master
# After approval and merge, changes appear in production environment automatically
```

## ArgoCD Configuration Details

Each ArgoCD application is configured with:
- **Automatic Sync**: Enabled
- **Self Heal**: Enabled (corrects manual changes)
- **Prune**: Enabled (removes resources not in Git)
- **Namespace Creation**: Automatic

## Monitoring and Troubleshooting

### Manual Installation Troubleshooting

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
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops --type merge --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Check application details
oc describe applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops
```

### Regular Monitoring Commands

### Check Application Status
```bash
oc get applications.argoproj.io -n openshift-gitops
```

### Check Sync Status
```bash
oc get applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -o yaml
```

### Force Sync
```bash
oc patch applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
```

### Access ArgoCD UI
```bash
# Get ArgoCD URL
oc get route openshift-gitops-server -n openshift-gitops

# Get admin password
oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d
```

## VM Templates

All VMs use the RHEL 9 template with cloud-init for initial configuration:
- Default user: `cloud-user`
- Default password: `redhat123`
- SSH access configured
- Environment-specific applications installed

## Cleanup

To remove all workshop resources:

```bash
./remove.sh
```

## Best Practices Demonstrated

1. **Infrastructure as Code**: All VM definitions stored in Git
2. **Environment Separation**: Different branches for different environments
3. **Automated Deployment**: Changes automatically deployed via ArgoCD
4. **Drift Detection**: Manual changes detected and corrected
5. **Disaster Recovery**: Complete environment recovery from Git
6. **Security**: Proper RBAC and namespace isolation

## Learning Objectives

After completing this workshop, participants will understand:
- How to implement GitOps for VM management
- ArgoCD configuration and application management
- Git-based workflow for infrastructure changes
- Automated drift detection and correction
- Disaster recovery using GitOps principles
- Environment promotion strategies

## Manual Installation Verification

After completing all manual installation steps, verify everything is working:

```bash
# Check ArgoCD applications
oc get applications.argoproj.io -n openshift-gitops

# Check created VMs
oc get vm -A | grep workshop

# Check services
oc get svc -A | grep workshop

```

### Expected Results

After the manual installation, you should see:

**ArgoCD Applications:**
```
NAME               SYNC STATUS   HEALTH STATUS
workshop-gitops-vms-dev   Synced        Healthy
workshop-gitops-vms-hml   Synced        Healthy
workshop-gitops-vms-prd   Synced        Healthy
```

**Virtual Machines:**
```
NAMESPACE                   NAME            STATUS
workshop-gitops-vms-dev     dev-vm-web-01   Running
workshop-gitops-vms-dev     dev-vm-web-02   Running
workshop-gitops-vms-dev     dev-vm-web-03   Running
workshop-gitops-vms-hml     hml-vm-web-01   Running
workshop-gitops-vms-hml     hml-vm-web-02   Running
workshop-gitops-vms-hml     hml-vm-web-03   Running
workshop-gitops-vms-prd     prd-vm-web-01   Running
workshop-gitops-vms-prd     prd-vm-web-02   Running
workshop-gitops-vms-prd     prd-vm-web-03   Running
```

**Access to ArgoCD:**
- URL: `https://openshift-gitops-server-openshift-gitops.apps.<your-cluster>`
- Username: `admin`
- Password: (obtained with the command in step 10)

### Next Steps in the Demonstration

With the workshop installed manually, you can demonstrate:

1. **GitOps in Action**: Make changes in the branches and show automatic synchronization
2. **Drift Detection**: Use `ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml`
3. **Automatic Recovery**: Use `ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml`
4. **Git-based Provisioning**: Use `ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml`
5. **ArgoCD Interface**: Show the web UI with synchronized applications