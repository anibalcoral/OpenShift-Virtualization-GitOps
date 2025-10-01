# OpenShift GitOps with OpenShift Virtualization Workshop

This workshop demonstrates how to use OpenShift GitOps (ArgoCD) to manage Virtual Machines in OpenShift Virtualization using a GitOps approach.

## Prerequisites

- OpenShift cluster with OpenShift Virtualization installed
- Fedora template available in OpenShift Virtualization
- oc CLI tool configured and logged in to your cluster
- ansible-playbook installed
- Git repository access
- SSH key pair generated (`ssh-keygen -t rsa -b 4096`)

**Important**: Before running the workshop, you must configure your SSH key by running `./setup-ssh-key.sh`. This replaces the SSH key template with your public key for VM access.

## Workshop Structure

This workshop uses a multi-branch strategy where each branch represents a different environment:

- **main branch**: Production VMs (workshop-gitops-vms-prd namespace)
- **vms-hml branch**: Staging/Homologation VMs (workshop-gitops-vms-hml namespace)
- **vms-dev branch**: Development VMs (workshop-gitops-vms-dev namespace)

Virtual Machine definitions and Kustomize configurations are stored in a separate repository: [OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps)

## Quick Setup

1. **Generate SSH key pair (if not already done):**
   ```bash
   ssh-keygen -t rsa -b 4096
   ```

2. **Install OpenShift GitOps and configure the workshop:**
   ```bash
   ./install.sh
   ```
   The installation script automatically detects your cluster's application domain and configures routes accordingly.

3. **Validate cluster domain configuration (optional):**
   ```bash
   ./validate-cluster-domain.sh
   ```
   This script will automatically detect your cluster domain and update the Apps repository if needed.

4. **Check workshop status:**
   ```bash
   ./demo-scripts/check-status.sh
   ```

5. **Clean up the workshop environment:**
   ```bash
   ./remove.sh
   ```

## Manual Installation

If you prefer to install components manually or want to understand each step:

1. **Set up SSH key for VM access:**
   ```bash
   ./setup-ssh-key.sh
   ```

2. **Install OpenShift GitOps Operator using Ansible:**
   ```bash
   ansible-playbook -i inventory/localhost playbooks/install-gitops.yaml
   ```

3. **Apply the manual installation manifests:**
   ```bash
   oc apply -f manual-install/01-gitops-operator-subscription.yaml
   oc apply -f manual-install/02-cluster-role-binding.yaml
   oc apply -f manual-install/03-namespaces.yaml
   oc apply -f manual-install/04-argocd-app-dev.yaml
   oc apply -f manual-install/05-argocd-app-hml.yaml
   oc apply -f manual-install/06-argocd-app-prd.yaml
   ```

## Workshop Demos

### Demo 1: Manual Changes Detection
```bash
./demo-scripts/demo1-manual-change.sh
```

Demonstrates:
- Manual changes to VM objects
- "OutOfSync" status in ArgoCD
- Automatic VM recreation from Git

### Demo 2: VM Recovery
```bash
./demo-scripts/demo2-vm-recovery.sh
```

Demonstrates:
- VM corruption/data loss simulation
- Complete VM recovery from Git definitions
- GitOps-based disaster recovery

## ArgoCD Applications

After installation, three ArgoCD applications will be created:

- **workshop-vms-dev**: Manages development VMs from the `vms-dev` branch
- **workshop-vms-hml**: Manages homologation VMs from the `vms-hml` branch  
- **workshop-vms-prd**: Manages production VMs from the `master` branch

Each application uses:
- **Kustomize overlays** for environment-specific configurations
- **Automated sync** with prune and self-heal enabled
- **Auto-creation** of target namespaces

## Accessing ArgoCD

After installation, you can access ArgoCD using:

```bash
# Get ArgoCD URL
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"

# Get ArgoCD admin password
echo "ArgoCD Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"
```

Username: `admin`

## Environment Branches

- **vms-dev**: Development environment (workshop-gitops-vms-dev namespace)
  - dev-vm-web-01 (1 CPU, 2GB RAM, 30GB disk)
  - dev-vm-web-02 (1 CPU, 2GB RAM, 30GB disk)
  - dev-vm-web-03 (1 CPU, 2GB RAM, 30GB disk)

- **vms-hml**: Homologation/Staging environment (workshop-gitops-vms-hml namespace)
  - hml-vm-web-01 (2 CPU, 3GB RAM, 40GB disk)
  - hml-vm-web-02 (2 CPU, 3GB RAM, 40GB disk)
  - hml-vm-web-03 (2 CPU, 3GB RAM, 40GB disk)

- **master**: Production environment (workshop-gitops-vms-prd namespace)
  - prd-vm-web-01 (2 CPU, 4GB RAM, 50GB disk)
  - prd-vm-web-02 (2 CPU, 4GB RAM, 50GB disk)
  - prd-vm-web-03 (2 CPU, 4GB RAM, 50GB disk)

## VM Access

All VMs are configured with SSH access using your public key:

- **Username**: `cloud-user`
- **Password**: `redhat123` (for console access)
- **SSH Access**: Uses your `~/.ssh/id_rsa.pub` key automatically

To access a VM via SSH:
```bash
# Get VM IP address
oc get vmi <vm-name> -n <namespace> -o jsonpath='{.status.interfaces[0].ipAddress}'

# SSH to VM
ssh cloud-user@<vm-ip>
```

## VM Access

All VMs are configured with SSH access using your public key:

- **Username**: `cloud-user`
- **Password**: `redhat123` (for console access)
- **SSH Access**: Uses your `~/.ssh/id_rsa.pub` key automatically

To access a VM via SSH:
```bash
# Get VM IP address
oc get vmi <vm-name> -n <namespace> -o jsonpath='{.status.interfaces[0].ipAddress}'

# SSH to VM
ssh cloud-user@<vm-ip>
```

## Repository Structure

The workshop uses the following repository structure:

```
workshop-gitops-ocpvirt/
├── ansible.cfg                      # Ansible configuration
├── install.sh                       # Automated installation script
├── remove.sh                        # Cleanup script
├── setup-ssh-key.sh                 # SSH key setup script
├── requirements.yml                  # Ansible requirements
├── README.md                         # This file
├── WORKSHOP_GUIDE.md                 # Detailed workshop guide
├── inventory/
│   └── localhost                     # Ansible inventory
├── playbooks/
│   ├── install-gitops.yaml          # GitOps installation playbook
│   └── remove-gitops.yaml           # GitOps removal playbook
├── manual-install/
│   ├── 01-gitops-operator-subscription.yaml
│   ├── 02-cluster-role-binding.yaml
│   ├── 03-namespaces.yaml
│   ├── 04-argocd-app-dev.yaml
│   ├── 05-argocd-app-hml.yaml
│   ├── 06-argocd-app-prd.yaml
│   └── README.md
├── demo-scripts/
│   ├── check-status.sh               # Check workshop status
│   ├── demo1-manual-change.sh        # Manual changes demo
│   └── demo2-vm-recovery.sh          # VM recovery demo
├── base/                             # Base VM templates
│   ├── kustomization.yaml
│   ├── ssh-secret.yaml
│   ├── vm-web-01.yaml
│   ├── vm-web-02.yaml
│   └── vm-web-service.yaml
└── overlays/                         # Environment-specific overlays
    ├── dev/
    │   └── kustomization.yaml
    ├── hml/
    │   └── kustomization.yaml
    └── prd/
        └── kustomization.yaml
```

## Documentation

See `WORKSHOP_GUIDE.md` for detailed workshop instructions and learning objectives.

## Architecture

The workshop implements a complete GitOps workflow where:

- **Each branch represents a different environment** (dev, hml, prd)
- **Kustomize overlays** provide environment-specific configurations
- **Base templates** contain common VM definitions without hardcoded values
- **ArgoCD monitors** each branch and deploys VMs using Kustomize
- **Manual changes are detected** and corrected automatically
- **Complete disaster recovery** is possible from Git definitions

## Kustomize Structure

```
base/                      # Base VM templates (no environment-specific values)
├── kustomization.yaml     # Base kustomization file
├── ssh-secret.yaml        # SSH public key secret for VM access
├── vm-web-01.yaml         # First web server VM template
├── vm-web-02.yaml         # Second web server VM template  
└── vm-web-service.yaml    # Service and route definitions

overlays/                  # Environment-specific customizations
├── dev/                   # Development patches (smaller resources)
│   └── kustomization.yaml
├── hml/                   # Homologation patches (medium resources)
│   └── kustomization.yaml
└── prd/                   # Production patches (larger resources)
    └── kustomization.yaml
```

## Customizing Route URLs

Each environment can have its own custom route URL configured using Kustomize JSON patches. The current configuration includes:

- **Development**: `dev-workshop-vms.apps.example.com`
- **Homologation**: `hml-workshop-vms.apps.example.com`  
- **Production**: `workshop-vms.apps.example.com`

To customize the route URL for an environment, edit the corresponding kustomization file and update the patch:

```yaml
patches:
  - patch: |-
      - op: replace
        path: /spec/to/name
        value: dev-vm-web-service
      - op: add
        path: /spec/host
        value: your-custom-url.apps.your-domain.com
    target:
      kind: Route
      name: vm-web-route
```

The patch performs two operations:
1. **Replace service name**: Updates the service reference to match the environment prefix
2. **Add custom host**: Sets the custom route URL for external access

## Automatic Cluster Domain Detection

The installation process now automatically detects your OpenShift cluster's application domain, eliminating the need to manually configure domain references.

### How It Works

The `install.sh` script queries the cluster's ingress configuration:
```bash
oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}'
```

This automatically detects and configures domains such as:
- `apps.cluster-name.domain.com`
- `apps.joe-quimby.chiarettolabs.com.br`
- Any valid OpenShift cluster application domain

### Domain Management Tools

1. **Automatic configuration during installation:**
   ```bash
   ./install.sh  # Detects and configures domain automatically
   ```

2. **Manual domain validation:**
   ```bash
   ./validate-cluster-domain.sh  # Validate and update domain interactively
   ```

### Final Configuration

After installation, routes are configured as:
- **Development**: `dev-workshop-vms.<your-cluster-domain>`
- **Homologation**: `hml-workshop-vms.<your-cluster-domain>`
- **Production**: `workshop-vms.<your-cluster-domain>`

## Troubleshooting

### Common Issues

1. **ArgoCD applications not syncing:**
   - Check if the target branches exist in the repository
   - Verify SSH key is properly configured
   - Check ArgoCD logs: `oc logs -n openshift-gitops deployment/openshift-gitops-application-controller`

2. **VMs not starting:**
   - Ensure OpenShift Virtualization is properly installed
   - Check if Fedora template is available
   - Verify resource quotas in target namespaces

3. **SSH access issues:**
   - Ensure SSH key was properly set up with `./setup-ssh-key.sh`
   - Check if the SSH secret exists in the target namespace
   - Verify VM has an IP address assigned

### Getting Help

- Check the detailed workshop guide: `WORKSHOP_GUIDE.md`
- Use the status check script: `./demo-scripts/check-status.sh`
- Review ArgoCD UI for application sync status
- Check OpenShift events in target namespaces
