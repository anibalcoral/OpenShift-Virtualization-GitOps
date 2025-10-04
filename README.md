# OpenShift GitOps with OpenShift Virtualization Workshop

This workshop demonstrates how to use OpenShift GitOps (ArgoCD) to manage Virtual Machines in OpenShift Virtualization using a GitOps approach. The workshop includes automated Ansible-based installation, multiple environment configurations, and practical demos showing GitOps capabilities.

## Prerequisites

Before starting the workshop, ensure you have:

- **OpenShift cluster** with OpenShift Virtualization operator installed and configured
- **oc CLI tool** installed and configured with cluster-admin privileges
- **ansible-playbook** installed (for automated installation)
- **Git access** to the companion Apps repository
- Both repositories cloned locally:
  ```bash
  git clone git@github.com:anibalcoral/OpenShift-Virtualization-GitOps.git
  git clone git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git
  ```

**Note**: The Apps repository must be cloned as a sibling directory (`../OpenShift-Virtualization-GitOps-Apps`) for domain validation scripts to work correctly.

## Workshop Architecture

This workshop uses a **dual-repository strategy** with **multi-branch environments**:

### Repository Structure
- **Configuration Repository** (this repo): Contains installation scripts, Ansible playbooks, and workshop demos
- **Applications Repository**: Contains VM definitions and Kustomize configurations for each environment

### Environment Strategy
- **vms-dev branch**: Development VMs (workshop-gitops-vms-dev namespace)
- **vms-hml branch**: Homologation/Staging VMs (workshop-gitops-vms-hml namespace)  
- **main branch**: Production VMs (workshop-gitops-vms-prd namespace)

Each environment uses Kustomize overlays for environment-specific resource configurations (CPU, memory, disk, naming prefixes).

## Installation

### Automated Installation (Recommended)

**Complete installation:**
```bash
./install.sh
```

**Individual Ansible playbooks:**
```bash
# Install complete workshop
ansible-playbook -i inventory/localhost playbooks/install-workshop.yaml

# Or run individual components
ansible-playbook -i inventory/localhost playbooks/validate-cluster-domain.yaml
ansible-playbook -i inventory/localhost playbooks/setup-ssh-key.yaml
ansible-playbook -i inventory/localhost playbooks/install-gitops.yaml
```

### Manual Installation (for Learning)

For step-by-step installation or troubleshooting:

```bash
# Apply manual manifests in order
oc apply -f manual-install/01-gitops-operator-subscription.yaml
oc apply -f manual-install/02-cluster-role-binding.yaml
oc apply -f manual-install/03-namespaces.yaml
oc apply -f manual-install/04-argocd-app-dev.yaml
oc apply -f manual-install/05-argocd-app-hml.yaml
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
# Quick status check
./demo-scripts/check-status.sh

# Or use Ansible playbook directly
ansible-playbook -i inventory/localhost playbooks/check-workshop-status.yaml
```

## Workshop Demonstrations

### Demo 1: Manual Change Detection and Drift Correction
```bash
# Using Ansible playbook
ansible-playbook -i inventory/localhost playbooks/demo1-manual-change.yaml

# Or using interactive runner
./demo-scripts/run-demos.sh
```
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
ansible-playbook -i inventory/localhost playbooks/demo2-vm-recovery.yaml

# Or using interactive runner
./demo-scripts/run-demos.sh
```
**Demonstrates:**
- Complete VM deletion (simulating data loss)
- ArgoCD detecting missing resources
- Recovery through Git-based re-sync
- Complete VM recreation and functionality

### Demo 3: Adding New Development VM via Git Change
```bash
# Using Ansible playbook
ansible-playbook -i inventory/localhost playbooks/demo3-add-development-vm.yaml

# Or using script wrapper
./demo-scripts/demo3-add-development-vm.sh

# Or using interactive runner
./demo-scripts/run-demos.sh
```
**Demonstrates:**
- Git-based workflow for infrastructure changes
- Adding new VM definitions via Git commits
- Automatic deployment through ArgoCD
- Environment-specific customizations

### Interactive Demo Runner
```bash
./demo-scripts/run-demos.sh
```
Provides a menu-driven interface to run all demos and utilities.

### Demo Cleanup
```bash
# Clean up Demo 3 artifacts
./demo-scripts/cleanup-demo3.sh

# Or use Ansible directly
ansible-playbook -i inventory/localhost playbooks/cleanup-demo3.yaml
```

## Cleanup

### Complete Workshop Removal
```bash
./remove.sh
```

**Or use Ansible playbooks directly:**
```bash
# Remove workshop resources only
ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml

# Remove workshop resources and GitOps operator
ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml -e remove_operator=true
```

### Status Monitoring
```bash
# Quick status check
./demo-scripts/check-status.sh

# Direct Ansible playbook
ansible-playbook -i inventory/localhost playbooks/check-workshop-status.yaml

# OpenShift CLI monitoring
oc get applications.argoproj.io -n openshift-gitops
oc get vm -A | grep workshop-gitops
```

### Run All Demos Interactively
```bash
./demo-scripts/run-demos.sh
```

## ArgoCD Applications

The workshop creates three ArgoCD applications:

- **workshop-vms-dev**: Manages development VMs from the `vms-dev` branch
- **workshop-vms-hml**: Manages homologation VMs from the `vms-hml` branch  
- **workshop-vms-prd**: Manages production VMs from the `main` branch

Each application:
- Points to a specific branch in the Apps repository
- Uses **Kustomize overlays** for environment-specific configurations
- Has **automated sync** enabled with prune and self-heal
- **Auto-creates** target namespaces if they don't exist

## Environment Details

### Development Environment (vms-dev branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: 
  - `dev-vm-web-01` (1 CPU, 2GB RAM, 30GB disk)
  - `dev-vm-web-02` (1 CPU, 2GB RAM, 30GB disk)
- **Route**: `https://dev-workshop-vms.<cluster-domain>`

### Homologation Environment (vms-hml branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**: 
  - `hml-vm-web-01` (2 CPU, 3GB RAM, 40GB disk)
  - `hml-vm-web-02` (2 CPU, 3GB RAM, 40GB disk)
- **Route**: `https://hml-workshop-vms.<cluster-domain>`

### Production Environment (main branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**: 
  - `prd-vm-web-01` (2 CPU, 4GB RAM, 50GB disk)
  - `prd-vm-web-02` (2 CPU, 4GB RAM, 50GB disk)
- **Route**: `https://workshop-vms.<cluster-domain>`

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

## Automatic Domain Configuration

The workshop automatically detects and configures your OpenShift cluster's application domain, eliminating manual configuration.

### How Domain Detection Works

1. **Cluster Query**: The installation queries the cluster's ingress configuration
2. **Automatic Updates**: Detected domains are automatically configured in route definitions within the Apps repository
3. **Support for Any Domain**: Works with any valid OpenShift application domain pattern:
   - `apps.cluster-name.domain.com`
   - `apps.sandbox.x8y9.p1.openshiftapps.com`
   - Custom enterprise domains

### Domain Validation Tools

- **Automatic during installation**: `./install.sh` (detects and configures automatically)
- **Manual validation**: `./validate-cluster-domain.sh` (validates and updates domains)

## Cleanup and Maintenance

### Complete Workshop Removal

**Choose removal method:**
```bash
./remove.sh
# Select option 1 (Ansible) or option 2 (Bash)
```

**Or use Ansible playbooks directly:**
```bash
# Remove workshop resources only
ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml

# Remove workshop resources and GitOps operator
ansible-playbook -i inventory/localhost playbooks/remove-workshop.yaml -e remove_operator=true
```

### Status Monitoring

**Ansible method:**
```bash
ansible-playbook -i inventory/localhost playbooks/check-workshop-status.yaml
```

**Bash method:**
```bash
./demo-scripts/check-status.sh
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
├── install.sh                           # Interactive installation script (Ansible/Bash)
├── remove.sh                            # Interactive cleanup script (Ansible/Bash)
├── validate-cluster-domain.sh           # Domain detection and validation (Bash)
├── validate-cluster-domain-ansible.sh   # Domain validation (Ansible wrapper)
├── setup-ssh-key.sh                     # SSH key configuration (Bash)
├── setup-ssh-key-ansible.sh            # SSH key setup (Ansible wrapper)
├── ansible.cfg                          # Ansible configuration
├── requirements.yml                     # Ansible requirements
├── WORKSHOP_GUIDE.md                    # Detailed workshop instructions
├── README.md                            # This file
├── inventory/
│   └── localhost                        # Ansible inventory for localhost
├── playbooks/
│   ├── install-gitops.yaml             # GitOps operator installation
│   ├── remove-gitops.yaml              # GitOps operator removal
│   └── templates/                       # Ansible templates
├── inventory/
│   └── localhost                        # Ansible inventory for localhost
├── playbooks/                           # Ansible playbooks
│   ├── install-workshop.yaml           # Complete workshop installation
│   ├── install-gitops.yaml             # GitOps operator installation  
│   ├── remove-workshop.yaml            # Complete workshop removal
│   ├── remove-gitops.yaml              # GitOps operator removal (legacy)
│   ├── validate-cluster-domain.yaml    # Cluster domain validation
│   ├── setup-ssh-key.yaml              # SSH key configuration
│   ├── check-workshop-status.yaml      # Workshop status checker
│   ├── demo1-manual-change.yaml        # Demo 1: Manual change detection
│   ├── demo2-vm-recovery.yaml          # Demo 2: VM recovery
│   ├── demo-utilities.yaml             # Demo utility functions
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
    ├── run-demos.sh                     # Interactive demo runner (Ansible/Bash)
    ├── check-status.sh                  # Workshop status checker (Bash)
    ├── check-status-ansible.sh          # Workshop status checker (Ansible wrapper)
    ├── demo1-manual-change.sh           # Demo 1: Manual change detection (Bash)
    ├── demo1-manual-change-ansible.sh   # Demo 1: Ansible wrapper
    ├── demo2-vm-recovery.sh             # Demo 2: VM recovery (Bash)
    ├── demo2-vm-recovery-ansible.sh     # Demo 2: Ansible wrapper
    ├── demo3-add-development-vm.sh      # Demo 3: Adding new VMs (Bash)
    ├── cleanup-demo3.sh                 # Demo 3 cleanup
    ├── demo-functions.sh                # Common demo functions (Bash)
    ├── DEMO1-MANUAL-CHANGE.md           # Demo 1 documentation
    ├── DEMO2-VM-RECOVERY.md             # Demo 2 documentation
    └── DEMO3-ADD-DEVELOPMENT-VM.md      # Demo 3 documentation

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
   oc describe applications.argoproj.io workshop-vms-dev -n openshift-gitops
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
   oc get routes -A | grep workshop-vms
   ```

4. **SSH Access Problems**
   ```bash
   # Check if SSH secret exists
   oc get secret -n <namespace> | grep ssh
   
   # Verify VM has IP address
   oc get vmi -n <namespace>
   
   # Test VM console access first
   virtctl console <vm-name> -n <namespace>

   # Test SSH to Virtual Machine
   virtctl ssh cloud-user@<vm-name>
   ```

### Workshop Validation Commands

```bash
# Comprehensive status check
./demo-scripts/check-status.sh

# Verify all workshop components
oc get applications.argoproj.io -n openshift-gitops | grep workshop-vms
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
- **Apps Repository**: [OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps) contains VM definitions and Kustomize configurations

## Workshop Learning Objectives

This workshop teaches:
- GitOps principles applied to virtual machine management
- Multi-environment deployments using branch-based strategies
- Kustomize for environment-specific configurations
- ArgoCD for continuous deployment and drift detection
- OpenShift Virtualization VM lifecycle management
- Infrastructure as Code best practices for virtualized workloads
