# OpenShift GitOps with OpenShift Virtualization Workshop

This workshop demonstrates how to use OpenShift GitOps (ArgoCD) to manage Virtual Machines in OpenShift Virtualization using a GitOps approach. The workshop includes automated installation, multiple environment configurations, and practical demos showing GitOps capabilities.

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


**Note**: The Apps repository is cloned and the install cluster will change the branches to `-$GUID` to be unique to prevent conflicts with other workshops participants.

# Workshop Architecture

This workshop uses a **dual-repository strategy** with **multi-branch environments**:

### Repository Structure
- **Configuration Repository** (this repo): Contains installation scripts and workshop demos
- **Applications Repository**: Contains VM definitions and Kustomize configurations for each environment

### Environment Strategy
- **vms-dev-{{ guid }} branch**: Development VMs (workshop-gitops-vms-dev namespace)
- **vms-hml-{{ guid }} branch**: Homologation/Staging VMs (workshop-gitops-vms-hml namespace)  
- **vms-prd-{{ guid }} branch**: Production VMs (workshop-gitops-vms-prd namespace)

Each GUID gets its own set of branches while sharing common namespaces to ensure isolation between workshop participants.
Each environment uses Kustomize overlays for environment-specific resource configurations (CPU, memory, disk, naming prefixes).

## Security Considerations

**SSH Key Management:**
- The `setup-ssh-key.yaml` playbook automatically generates and configures SSH keys
- SSH keys are generated locally and only the public key is used in VM configurations
- The `ssh-secret.yaml` file contains only a placeholder - real keys are populated during setup

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
# Install complete workshop
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/install-workshop.yaml -e "guid=$GUID"
```
```
# Or run individual components
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/validate-cluster-domain.yaml -e "guid=$GUID"
```
```
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/setup-ssh-key.yaml -e "guid=$GUID"
```

### Manual Installation (for Learning)

For step-by-step installation or troubleshooting:


- Replace {GUID} with your actual GUID in manual install files
- Apply manual manifests in order
- Before applying you have to edit and replace {GUID} on all playbooks
```bash
oc apply -f manual-install/01-gitops-operator-subscription.yaml
```
```
oc apply -f manual-install/02-cluster-role-binding.yaml
```
```
oc apply -f manual-install/03-namespaces.yaml
```
```
oc apply -f manual-install/04-argocd-app-dev.yaml
```
```
oc apply -f manual-install/05-argocd-app-hml.yaml
```
```
oc apply -f manual-install/06-argocd-app-prd.yaml
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
# Using interactive demo runner
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
./run-demos.sh s
```
```
# Or directly with Ansible
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml -e "guid=$GUID"
```

## Workshop Demonstrations

### Demo 1: Manual Change Detection and Drift Correction
```bash
# Using Ansible playbook
export GUID=user01  # Not necessary if you are running at bastion lab
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml -e "guid=$GUID"

# Using interactive runner (requires GUID environment variable)
export GUID=user01
./run-demos.sh
# Select option '1'

# Direct using run-demos.sh with parameter
./run-demos.sh 1
```

**Step By Step to run Demo 1**

Using the doc [DEMO1-MANUAL-CHANGE.md](demo-scripts/DEMO1-MANUAL-CHANGE.md)

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
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml

# Or using interactive runner
./run-demos.sh
# Select option '2'

# Direct using run-demos.sh with parameter
./run-demos.sh 2
```

**Step By Step to run Demo 2**

Using the doc [DEMO2-VM-RECOVERY.md](demo-scripts/DEMO2-VM-RECOVERY.md)

**Demonstrates:**
- Complete VM deletion (simulating data loss)
- ArgoCD detecting missing resources
- Recovery through Git-based re-sync
- Complete VM recreation and functionality

### Demo 3: Adding New Development VM via Git Change
```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml

# Or using interactive runner
./run-demos.sh
# Select option '3'

# Direct using run-demos.sh with parameter
./run-demos.sh 3

```
**Step By Step to run Demo 3**

Using the doc [DEMO3-ADD-DEVELOPMENT-VM.md](demo-scripts/DEMO3-ADD-DEVELOPMENT-VM.md)

**Demonstrates:**
- Git-based workflow for infrastructure changes
- Adding new VM definitions via Git commits
- Automatic deployment through ArgoCD
- Environment-specific customizations

### Demo 4: Multi-Environment VM Management with Kustomize
```bash
# Using Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml

# Or using interactive runner
./run-demos.sh
# Select option '4'

# Direct using run-demos.sh with parameter
./run-demos.sh 4

```
**Step By Step to run Demo 4**

Using the doc [DEMO4-MULTI-ENV-MANAGEMENT.md](demo-scripts/DEMO4-MULTI-ENV-MANAGEMENT.md)

**Demonstrates:**
- Branch-based environment promotion (dev → hml → prod)
- Kustomize overlays for environment-specific configurations
- Centralized base template management across environments
- GitOps promotion strategies and multi-environment consistency

### Interactive Demo Runner
```bash
./run-demos.sh
```
Provides a menu-driven interface to run all demos and utilities.

### Demo 3 Cleanup
```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml
```

### Demo 4 Cleanup
```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

## Cleanup

**Complete Workshop Removal**
```bash
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
./remove.sh
```

**Or use Ansible playbooks directly:**
```bash
# Remove workshop resources only
export GUID=user01  # Not necessary if you are running at bastion lab
```
```
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/remove-workshop.yaml -e "guid=$GUID"
```

### Status Monitoring
```bash
# Using interactive demo runner
./run-demos.sh
# Select option 's' to check status

# Direct Ansible playbook
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml -e "guid=$GUID"

# OpenShift CLI monitoring
oc get applications.argoproj.io -n openshift-gitops
oc get vm -A | grep workshop-gitops
```

### Run All Demos
```bash
./run-demos.sh a
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

### Development Environment (vms-dev branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: 
  - `dev-vm-web-01` (1 CPU, 2GB RAM, 30GB disk)
  - `dev-vm-web-02` (1 CPU, 2GB RAM, 30GB disk)
- **Route**: `https://dev-workshop-gitops-vms.<cluster-domain>`

### Homologation Environment (vms-hml branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**: 
  - `hml-vm-web-01` (2 CPU, 3GB RAM, 40GB disk)
  - `hml-vm-web-02` (2 CPU, 3GB RAM, 40GB disk)
- **Route**: `https://hml-workshop-gitops-vms.<cluster-domain>`

### Production Environment (main branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**: 
  - `prd-vm-web-01` (2 CPU, 4GB RAM, 50GB disk)
  - `prd-vm-web-02` (2 CPU, 4GB RAM, 50GB disk)
- **Route**: `https://workshop-gitops-vms.<cluster-domain>`

## Virtual Machine Configuration

Each environment deploys identical VMs with environment-specific resource allocations:

### VM Templates
- **Base Image**: RHEL 9 cloud image
- **Default User**: `cloud-user` 
- **Default Password**: `redhat123`
- **Applications**: Environment-specific web applications
- **SSH Access**: Configured with workshop SSH keys
- **Networking**: LoadBalancer services with external routes

### Resource Scaling by Environment
- **Development**: 1 vCPU, 2Gi RAM, 10Gi storage per VM
- **Homologation**: 2 vCPU, 4Gi RAM, 20Gi storage per VM  
- **Production**: 4 vCPU, 8Gi RAM, 40Gi storage per VM
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
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/remove-workshop.yaml -e "guid=$GUID"
```

### Status Monitoring

**Ansible method:**
```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml -e "guid=$GUID"
```

**ArgoCD UI monitoring:**
```bash
oc get applications.argoproj.io -n openshift-gitops
oc get vm -A | grep workshop-gitops
```

## Repository Structure and Files

This repository contains the workshop configuration and automation:

```
OpenShift-Virtualization-GitOps/          # Main workshop repository
├── install.sh                           # Installation script
├── remove.sh                            # Cleanup script
├── run-demos.sh                         # Interactive demo runner
├── ansible.cfg                          # Ansible configuration
├── requirements.yml                     # Ansible requirements
├── WORKSHOP_GUIDE.md                    # Detailed workshop instructions
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
│   ├── cleanup-demo3.yaml              # Demo 3 cleanup
│   ├── cleanup-demo4.yaml              # Demo 4 cleanup
│   └── templates/                      # Ansible templates
│       └── ssh-secret.yaml.j2         # SSH secret template
├── manual-install/                      # Manual installation manifests
│   ├── 01-gitops-operator-subscription.yaml
│   ├── 02-cluster-role-binding.yaml
│   ├── 03-namespaces.yaml
│   ├── 04-argocd-app-dev.yaml
│   ├── 05-argocd-app-hml.yaml
│   ├── 06-argocd-app-prd.yaml
│   └── README.md
└── demo-scripts/                        # Workshop demonstration scripts
    ├── demo-functions.sh                # Common demo functions
    ├── DEMO1-MANUAL-CHANGE.md           # Demo 1 documentation
    ├── DEMO2-VM-RECOVERY.md             # Demo 2 documentation
    ├── DEMO3-ADD-DEVELOPMENT-VM.md      # Demo 3 documentation
    └── DEMO4-MULTI-ENV-MANAGEMENT.md    # Demo 4 documentation

OpenShift-Virtualization-GitOps-Apps/    # Companion Apps repository
├── base/                                # Base VM templates and resources
│   ├── kustomization.yaml              # Base Kustomize configuration
│   ├── ssh-secret.yaml                 # SSH secret template
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
        path: /spec/template/spec/domain/cpu/cores
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
        path: /spec/template/spec/domain/cpu/cores  
        value: 2
    target:
      kind: VirtualMachine
```

## Troubleshooting

### Common Issues and Solutions

1. **ArgoCD Applications Not Syncing**
   ```bash
   # Check application status
   oc get applications.argoproj.io -n openshift-gitops
   
   # Check ArgoCD controller logs
   oc logs -n openshift-gitops deployment/openshift-gitops-application-controller
   
   # Verify repository access
   oc describe applications.argoproj.io workshop-gitops-vms-dev -n openshift-gitops
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
./run-demos.sh
# Select option 's' for status check

# Verify all workshop components
oc get applications.argoproj.io -n openshift-gitops | grep workshop-gitops-vms
oc get namespaces | grep workshop-gitops
oc get vm -A | grep workshop-gitops

# Check ArgoCD health
oc get pods -n openshift-gitops
oc get routes -n openshift-gitops
```

## Additional Resources

- **Detailed Workshop Guide**: See `WORKSHOP_GUIDE.md` for comprehensive learning objectives and step-by-step instructions
- **Demo Documentation**: Individual demo guides available in `demo-scripts/DEMO*.md` files
 - **Detailed Workshop Guide**: See [WORKSHOP_GUIDE.md](WORKSHOP_GUIDE.md) for comprehensive learning objectives and step-by-step instructions
 - **Demo Documentation**: Individual demo guides available:
    - [DEMO1-MANUAL-CHANGE.md](demo-scripts/DEMO1-MANUAL-CHANGE.md)
    - [DEMO2-VM-RECOVERY.md](demo-scripts/DEMO2-VM-RECOVERY.md)
    - [DEMO3-ADD-DEVELOPMENT-VM.md](demo-scripts/DEMO3-ADD-DEVELOPMENT-VM.md)
    - [DEMO4-MULTI-ENV-MANAGEMENT.md](demo-scripts/DEMO4-MULTI-ENV-MANAGEMENT.md)
- **Apps Repository**: [OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps) contains VM definitions and Kustomize configurations

## Workshop Learning Objectives

This workshop teaches:
- GitOps principles applied to virtual machine management
- Multi-environment deployments using branch-based strategies
- Kustomize for environment-specific configurations
- ArgoCD for continuous deployment and drift detection
- OpenShift Virtualization VM lifecycle management
- Infrastructure as Code best practices for virtualized workloads
