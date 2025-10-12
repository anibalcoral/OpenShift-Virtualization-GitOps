# OpenShift GitOps with OpenShift Virtualization Workshop

This workshop demonstrates how to use OpenShift GitOps (ArgoCD) to manage Virtual Machines in OpenShift Virtualization using a GitOps approach. The workshop includes automated installation, multiple environment configurations, and practical demos showing GitOps capabilities.

## Table of Contents

- [OpenShift GitOps with OpenShift Virtualization Workshop](#openshift-gitops-with-openshift-virtualization-workshop)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
- [Workshop Architecture](#workshop-architecture)
    - [Repository Structure](#repository-structure)
    - [Environment Strategy](#environment-strategy)
  - [Installation](#installation)
    - [Automated Installation](#automated-installation)
    - [Manual Installation (for Learning)](#manual-installation-for-learning)
  - [Verification](#verification)
  - [Workshop Demonstrations](#workshop-demonstrations)
    - [Demo 1: Manual Change Detection and Drift Correction](#demo-1-manual-change-detection-and-drift-correction)
    - [Demo 2: VM Recovery from Data Loss](#demo-2-vm-recovery-from-data-loss)
    - [Demo 3: Adding New Development VM via Git Change](#demo-3-adding-new-development-vm-via-git-change)
    - [Demo 4: Multi-Environment VM Management with Kustomize](#demo-4-multi-environment-vm-management-with-kustomize)
    - [Demo 3 and Demo 4 Cleanup](#demo-3-and-demo-4-cleanup)
    - [Status Monitoring](#status-monitoring)
    - [Run All Demos (TODO: Fix demo3)](#run-all-demos-todo-fix-demo3)
  - [ArgoCD Applications](#argocd-applications)
  - [Environment Details](#environment-details)
    - [Development Environment (vms-dev-GUID branch)](#development-environment-vms-dev-guid-branch)
    - [Homologation Environment (vms-hml-GUID branch)](#homologation-environment-vms-hml-guid-branch)
    - [Production Environment (vms-prd-GUID branch)](#production-environment-vms-prd-guid-branch)
  - [Virtual Machine Configuration](#virtual-machine-configuration)
    - [VM Templates](#vm-templates)
    - [Resource Scaling by Environment](#resource-scaling-by-environment)
    - [Accessing Virtual Machines](#accessing-virtual-machines)
  - [Cleanup and Maintenance](#cleanup-and-maintenance)
    - [Complete Workshop Removal](#complete-workshop-removal)
    - [Status Monitoring](#status-monitoring-1)
  - [Repository Structure and Files](#repository-structure-and-files)
  - [GitOps Workflow and Kustomize Strategy](#gitops-workflow-and-kustomize-strategy)
    - [Kustomize Configuration Pattern](#kustomize-configuration-pattern)
    - [Example Environment Customization](#example-environment-customization)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues and Solutions](#common-issues-and-solutions)
    - [Workshop Validation Commands](#workshop-validation-commands)
  - [Additional Resources](#additional-resources)
  - [Workshop Learning Objectives](#workshop-learning-objectives)

## Prerequisites

Before starting the workshop, ensure you have:

- **OpenShift cluster** with OpenShift Virtualization operator installed and configured
- **oc CLI tool** installed and configured with cluster-admin privileges
- **Git access** to the companion Apps repository
- **GUID environment variable** set to a unique identifier (e.g., your username)
  ```bash
  # Ignore this step if you are running at the bastion lab node
  export GUID=user01
  ```

**Before you Begin**

- To run this lab you will need a playbook called `setup-workshop-repos.yaml` that is not included in this repository. If you would like to run this lab, please contact [@anibalcoral](https://github.com/anibalcoral) or [@lgchiaretto](https://github.com/lgchiaretto).


**Note**: The Apps repository is cloned and the install cluster will change the branches to `-GUID` to be unique to prevent conflicts with other workshops participants.

# Workshop Architecture

This workshop uses a **dual-repository strategy** with **multi-branch environments**:

### Repository Structure
- **Configuration Repository** (this repo): Contains installation scripts and workshop demos
- **Applications Repository**: Contains VM definitions and Kustomize configurations for each environment

### Environment Strategy
- **vms-dev-GUID branch**: Development VMs (workshop-gitops-vms-dev namespace)
- **vms-hml-GUID branch**: Homologation/Staging VMs (workshop-gitops-vms-hml namespace)  
- **vms-prd-GUID branch**: Production VMs (workshop-gitops-vms-prd namespace)

Each GUID gets its own set of branches to ensure isolation between workshops participants.
Each environment uses Kustomize overlays for environment-specific resource configurations (CPU, memory, disk, naming prefixes).

## Installation

### Automated Installation

**Complete installation:**
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
./install.sh
```

**Individual Ansible playbooks:**
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/install-workshop.yaml
```

### Manual Installation (for Learning)

For step-by-step installation or troubleshooting:


- Before applying you have to edit and replace GUID on all playbooks
- Apply manual manifests in order

```bash
oc apply -f manual-install-files/01-gitops-operator-subscription.yaml
```
```bash
oc apply -f manual-install-files/02-cluster-role-binding.yaml
```
```bash
oc apply -f manual-install-files/03-namespaces.yaml
```
```bash
oc apply -f manual-install-files/04-argocd-app-dev.yaml
```
```bash
oc apply -f manual-install-files/05-argocd-app-hml.yaml
```
```bash
oc apply -f manual-install-files/06-argocd-app-prd.yaml
```

## Verification

**Access ArgoCD UI:**
```bash
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "Username: admin"
echo "Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"
```

**Check workshop status:**
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s
```
```bash
# Or directly with Ansible
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml
```

## Workshop Demonstrations

### Demo 1: Manual Change Detection and Drift Correction
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 1
```
```bash
# Or directly with Ansible
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml
```

**Step By Step to run Demo 1**

Using the doc [DEMO1-MANUAL-CHANGE.md](demo-guides/DEMO1-MANUAL-CHANGE.md)

- Manual modifications to VM resources
- ArgoCD detecting "OutOfSync" status
- Automatic drift correction and resource recreation

**Demonstrates:**
- Manual configuration changes to VMs
- ArgoCD detecting configuration drift (OutOfSync status)
- Automatic self-healing and drift correction
- VM returning to desired state from Git

### Demo 2: VM Recovery from Data Loss
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 2
```
```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml
```

**Step By Step to run Demo 2**

Using the doc [DEMO2-VM-RECOVERY.md](demo-guides/DEMO2-VM-RECOVERY.md)

**Demonstrates:**
- Complete VM deletion (simulating data loss)
- ArgoCD detecting missing resources
- Recovery through Git-based re-sync
- Complete VM recreation and functionality

### Demo 3: Adding New Development VM via Git Change

```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 3
```

```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml
```
**Step By Step to run Demo 3**

Using the doc [DEMO3-ADD-DEVELOPMENT-VM.md](demo-guides/DEMO3-ADD-DEVELOPMENT-VM.md)

**Demonstrates:**
- Git-based workflow for infrastructure changes
- Adding new VM definitions via Git commits
- Automatic deployment through ArgoCD
- Environment-specific customizations

### Demo 4: Multi-Environment VM Management with Kustomize
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 4
```
```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml
```
**Step By Step to run Demo 4**

Using the doc [DEMO4-MULTI-ENV-MANAGEMENT.md](demo-guides/DEMO4-MULTI-ENV-MANAGEMENT.md)

**Demonstrates:**
- Branch-based environment promotion (dev → hml → prod)
- Kustomize overlays for environment-specific configurations
- Centralized base template management across environments
- GitOps promotion strategies and multi-environment consistency

### Demo 3 and Demo 4 Cleanup
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh d
```
```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

### Status Monitoring
```bash
# Using demo runner
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s

# Direct Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml

# OpenShift CLI monitoring
oc get applications -n openshift-gitops
oc get vm -A | grep workshop-gitops
```

### Run All Demos (TODO: Fix demo3)
```bash
/opt/OpenShift-Virtualization-GitOps/run-demos.sh a
```

## ArgoCD Applications

The workshop creates three ArgoCD applications:

- **workshop-gitops-vms-dev**: Manages development VMs from the `vms-dev` branch
- **workshop-gitops-vms-hml**: Manages homologation VMs from the `vms-hml` branch  
- **workshop-gitops-vms-prd**: Manages production VMs from the `main` branch

Each application:
- Points to a specific branch in the Apps repository
- Uses **Kustomize overlays** for environment-specific configurations
- Has **automated sync** disabled

## Environment Details

### Development Environment (vms-dev-GUID branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: 
  - `dev-vm-web-01` (1 CPU, 2GB RAM)
  - `dev-vm-web-02` (1 CPU, 2GB RAM)
- **Route**: `https://dev-workshop-gitops-vms.<cluster-domain>`

### Homologation Environment (vms-hml-GUID branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**: 
  - `hml-vm-web-01` (1 CPU, 2GB RAM)
  - `hml-vm-web-02` (1 CPU, 2GB RAM)
- **Route**: `https://hml-workshop-gitops-vms.<cluster-domain>`

### Production Environment (vms-prd-GUID branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**: 
  - `prd-vm-web-01` (2 CPU, 4GB RAM)
  - `prd-vm-web-02` (2 CPU, 4GB RAM)
- **Route**: `https://workshop-gitops-vms.<cluster-domain>`

## Virtual Machine Configuration

Each environment deploys identical VMs with environment-specific resource allocations:

### VM Templates
- **Base Image**: Fedora cloud image
- **Default User**: `cloud-user` 
- **Default Password**: `redhat123`
- **Applications**: Environment-specific web applications
- **SSH Access**: Configured with workshop SSH keys
- **Networking**: LoadBalancer services with external routes

### Resource Scaling by Environment
- **Development**: 1 vCPU, 2Gi RAM, 30Gi storage per VM
- **Homologation**: 2 vCPU, 4Gi RAM, 30Gi storage per VM  
- **Production**: 4 vCPU, 8Gi RAM, 50Gi storage per VM
- **Storage**: Persistent volumes with environment-specific sizes

### Accessing Virtual Machines

1. **Via OpenShift Console**: Navigate to Virtualization → VirtualMachines
2. **Via CLI**: 
   ```bash
   oc get vm -n <namespace>
   virtctl console <vm-name> -n <namespace>
   ```
3. **Via SSH** (after VM is running):
   ```bash
   virtctl ssh cloud-user@<vm-name> -n <namespace>
   ```
4. **Via Web Routes**: Access the web application through the configured routes

## Cleanup and Maintenance

### Complete Workshop Removal

**Choose removal method:**
```bash
./remove.sh
```

**Or use Ansible playbooks directly:**
```bash
# Remove workshop resources only
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/remove-workshop.yaml
```

### Status Monitoring

**Ansible method:**
```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml
```

**ArgoCD UI monitoring:**
```bash
oc get applications -n openshift-gitops
oc get vm -A | grep workshop-gitops
```

## Repository Structure and Files

This repository contains the workshop configuration and automation:

```bash
OpenShift-Virtualization-GitOps/          # Main workshop repository
├── install.sh                           # Installation script
├── remove.sh                            # Cleanup script
├── run-demos.sh                         # Interactive demo runner
├── ansible.cfg                          # Ansible configuration
├── requirements.yml                     # Ansible requirements
├── README.md                            # This file
├── inventory/
│   └── localhost                        # Ansible inventory for localhost
├── playbooks/                           # Ansible playbooks
│   ├── install-workshop.yaml           # Complete workshop installation
│   ├── remove-workshop.yaml            # Complete workshop removal
│   ├── validate-cluster-domain.yaml    # Cluster domain validation
│   ├── setup-ssh-key.yaml              # SSH key configuration
│   ├── check-workshop-status.yaml      # Workshop status checker
│   ├── demo1-manual-change.yaml        # Demo 1: Manual change detection
│   ├── demo2-vm-recovery.yaml          # Demo 2: VM recovery
│   ├── demo3-add-development-vm.yaml   # Demo 3: Add Virtual Machine
│   ├── demo4-multi-env-management.yaml # Demo 4: Multi-environment management
│   ├── cleanup-demo4.yaml              # Demo 4 cleanup
│   └── templates/                      # Ansible templates
│       └── ssh-secret.yaml.j2         # SSH secret template
├── manual-install-files/                      # Manual installation manifests
│   ├── 01-gitops-operator-subscription.yaml
│   ├── 02-cluster-role-binding.yaml
│   ├── 03-namespaces.yaml
│   ├── 04-argocd-app-dev.yaml
│   ├── 05-argocd-app-hml.yaml
│   ├── 06-argocd-app-prd.yaml
│   └── README.md
└── demo-guides/                         # Workshop demonstration guides
    ├── WORKSHOP_GUIDE.md                    # Detailed workshop instructions
    ├── DEMO1-MANUAL-CHANGE.md           # Demo 1 documentation
    ├── DEMO2-VM-RECOVERY.md             # Demo 2 documentation
    ├── DEMO3-ADD-DEVELOPMENT-VM.md      # Demo 3 documentation
    └── DEMO4-MULTI-ENV-MANAGEMENT.md    # Demo 4 documentation

OpenShift-Virtualization-GitOps-Apps/    # Companion Apps repository
├── base/                                # Base VM templates and resources
│   ├── kustomization.yaml              # Base Kustomize configuration
│   ├── vm-web-01.yaml                  # Web server VM 01 definition
│   ├── vm-web-02.yaml                  # Web server VM 02 definition
│   └── vm-web-service.yaml             # Service and route definitions
└── overlays/                           # Environment-specific customizations
    ├── dev/                            # Development patches (smaller resources)
    │   └── kustomization.yaml
    ├── hml/                            # Homologation patches (medium resources)
    │   └── kustomization.yaml
    └── prd/                            # Production patches (larger resources)
        └── kustomization.yaml
```

## GitOps Workflow and Kustomize Strategy

### Kustomize Configuration Pattern

The workshop uses Kustomize to manage environment-specific configurations:

1. **Base Templates**: Define common VM structure without environment-specific values
2. **Environment Overlays**: Apply patches for CPU, memory, disk, naming, and routing
3. **JSON Patches**: Modify specific fields like resource requirements and hostnames

### Example Environment Customization

**Development Overlay** (`overlays/dev/kustomization.yaml`):
```yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/domain/resources/requests/memory
        value: 2Gi
      - op: replace  
        path: /spec/template/spec/domain/cpu/sockets
        value: 1
    target:
      kind: VirtualMachine
```

**Production Overlay** (`overlays/prd/kustomization.yaml`):
```yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/domain/resources/requests/memory
        value: 4Gi
      - op: replace
        path: /spec/template/spec/domain/cpu/sockets  
        value: 2
    target:
      kind: VirtualMachine
```

## Troubleshooting

### Common Issues and Solutions

1. **ArgoCD Applications Not Syncing**
   ```bash
   # Check application status
   oc get applications -n openshift-gitops
   
   # Check ArgoCD controller logs
   oc logs -n openshift-gitops deployment/openshift-gitops-application-controller
   
   # Verify repository access
   oc describe applications workshop-gitops-vms-dev -n openshift-gitops
   ```

2. **Virtual Machines Not Starting**
   ```bash
   # Check VM status and events
   oc get vm -n <namespace>
   oc describe vm <vm-name> -n <namespace>
   
   # Check OpenShift Virtualization operator status
   oc get csv -n openshift-cnv | grep kubevirt
   
   # Verify Fedora template availability
   oc get templates -n openshift | grep fedora
   ```

3. **Domain Configuration Issues**
   ```bash
   # Re-run domain validation
   ./validate-cluster-domain.sh
   
   # Check current cluster domain
   oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}'
   
   # Verify route configuration
   oc get routes -A | grep workshop-gitops-vms
   ```

4. **SSH Access Problems**
   ```bash
   # Check if SSH secret exists
   oc get secret -n <namespace> | grep ssh
   
   # Verify VM has IP address
   oc get vmi -n <namespace>
   
   # Test VM console access first
   virtctl console <vm-name> -n <namespace>

   # Clean up SSH known_hosts conflicts (common issue)
   ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-ssh-known-hosts.yaml

   # Test SSH to Virtual Machine
   virtctl ssh cloud-user@<vm-name>
   ```

### Workshop Validation Commands

```bash
# Comprehensive status check
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s

# Verify all workshop components
oc get applications -n openshift-gitops | grep workshop-gitops-vms
oc get namespaces | grep workshop-gitops
oc get vm -A | grep workshop-gitops

# Check ArgoCD health
oc get pods -n openshift-gitops
oc get routes -n openshift-gitops
```

## Additional Resources

- **Demo Documentation**: Individual demo guides available in `demo-guides/DEMO*.md` files
 - **Detailed Workshop Guide**: See [WORKSHOP_GUIDE.md](demo-guides/WORKSHOP_GUIDE.md) for comprehensive learning objectives and step-by-step instructions
 - **Demo Documentation**: Individual demo guides available:
    - [DEMO1-MANUAL-CHANGE.md](demo-guides/DEMO1-MANUAL-CHANGE.md)
    - [DEMO2-VM-RECOVERY.md](demo-guides/DEMO2-VM-RECOVERY.md)
    - [DEMO3-ADD-DEVELOPMENT-VM.md](demo-guides/DEMO3-ADD-DEVELOPMENT-VM.md)
    - [DEMO4-MULTI-ENV-MANAGEMENT.md](demo-guides/DEMO4-MULTI-ENV-MANAGEMENT.md)
- **Apps Repository**: [OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps) contains VM definitions and Kustomize configurations

## Workshop Learning Objectives

This workshop teaches:
- GitOps principles applied to virtual machine management
- Multi-environment deployments using branch-based strategies
- Kustomize for environment-specific configurations
- ArgoCD for continuous deployment and drift detection
- OpenShift Virtualization VM lifecycle management
- Infrastructure as Code best practices for virtualized workloads
