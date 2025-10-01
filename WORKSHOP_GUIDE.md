# Workshop Guide: OpenShift GitOps with OpenShift Virtualization

## Over   This step ensures your configuration files use the correct cluster domain. The script automatically detects your cluster's domain and updates all necessary files.

2. **Install OpenShift GitOps Operator and create complete configuration:**is workshop demonstrates how to implement GitOps principles for managing Virtual Machines (VMs) in OpenShift Virtualization using OpenShift GitOps (ArgoCD).

## Architecture

```
Git Repository Structure
├── Main Repository: OpenShift-Virtualization-GitOps
│   ├── Ansible playbooks for GitOps setup
│   ├── Installation and demo scripts
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
├── workshop-vms-prd → Apps repo main branch → overlays/prd → workshop-gitops-vms-prd namespace
├── workshop-vms-hml → Apps repo vms-hml branch → overlays/hml → workshop-gitops-vms-hml namespace
└── workshop-vms-dev → Apps repo vms-dev branch → overlays/dev → workshop-gitops-vms-dev namespace
```

## Installation Options

You have two options to install this workshop:

### Option 1: Automated Installation (Recommended for Quick Setup)

**Prerequisites:**
- SSH key pair generated (`ssh-keygen -t rsa -b 4096 -f ~/.ssh/ocpvirt-gitops-labs`)

```bash
./install.sh
```

**What the automated installation does:**
1. Validates prerequisites (OpenShift login, ansible-playbook, oc CLI)
2. Detects cluster domain automatically using OpenShift API
3. Validates and updates Apps repository domain configuration automatically
4. Installs OpenShift GitOps Operator via Ansible playbook
6. Creates repository secret for private Git access with SSH private key
7. Labels repository secret for ArgoCD recognition
8. Creates ArgoCD applications for all environments (dev, hml, prd)
9. Displays final configuration with correct URLs and credentials
10. Cleans up temporary backup files

### Option 2: Manual Installation (Recommended for Workshop Demonstrations)

For detailed workshop demonstrations, use the pre-created YAML files in the `manual-install/` directory. This approach allows you to explain each step during the workshop.

**Prerequisites:**
- SSH key pair generated (`ssh-keygen -t rsa -b 4096 -f ~/.ssh/ocpvirt-gitops-labs`)
- OpenShift cluster admin access**Manual Installation Steps:**

1. **Detect and update cluster domain:**
   ```bash
   ./validate-cluster-domain.sh
   ```
   This step ensures your configuration files use the correct cluster domain. The script automatically detects your cluster's domain and updates all necessary files.

2. **Install GitOps Operator and create complete configuration:**
   ```bash
   ansible-playbook -i inventory/localhost playbooks/install-gitops.yaml
   ```
   This playbook:
   - Installs the OpenShift GitOps operator
   - Creates RBAC permissions
   - Creates workshop namespaces for all environments (dev, hml, prd)
   - Creates ArgoCD applications for all environments
   - Sets up SSH known hosts for GitHub access

3. **Create Repository Secret for private Git access:**
   ```bash
   oc create secret generic workshop-gitops-repo \
     --from-file=sshPrivateKey=$HOME/.ssh/ocpvirt-gitops-labs \
     --from-literal=type=git \
     --from-literal=url=git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git \
     -n openshift-gitops --dry-run=client -o yaml | oc apply -f -
   
   oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository
   ```

**Alternative: Step-by-step Manual Installation (for detailed workshop demonstrations)**

If you prefer to show each step individually during a workshop demonstration:

1. **Install GitOps Operator:**
   ```bash
   oc apply -f manual-install/01-gitops-operator-subscription.yaml
   ```
   
   Wait for operator installation:
   ```bash
   oc wait --for=condition=Ready pod -l name=argocd-application-controller -n openshift-gitops --timeout=300s
   ```

3. **Create RBAC Permissions:**
   ```bash
   oc apply -f manual-install/02-cluster-role-binding.yaml
   ```

4. **Create Namespaces:**
   ```bash
   oc apply -f manual-install/03-namespaces.yaml
   ```

5. **Create Repository Secret:**
   ```bash
   oc create secret generic workshop-gitops-repo \
     --from-file=sshPrivateKey=$HOME/.ssh/ocpvirt-gitops-labs \
     --from-literal=url=git@github.com:anibalcoral/OpenShift-Virtualization-GitOps-Apps.git \
     --from-literal=type=git \
     -n openshift-gitops --dry-run=client -o yaml | oc apply -f -
   
   oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository
   ```

6. **Create ArgoCD Applications:**
   ```bash
   oc apply -f manual-install/04-argocd-app-dev.yaml
   oc apply -f manual-install/05-argocd-app-hml.yaml
   oc apply -f manual-install/06-argocd-app-prd.yaml
   ```

**All installation methods produce the same final result.**

## Post-Installation: VM Access and Service Verification

After installation, you can access and verify your VMs:

### SSH Access to VMs

VMs are automatically configured with SSH key access. Use the same key pair you configured during installation:

```bash
# Get VM IP addresses
oc get vmi -A

# SSH to web VM (example for dev environment)
ssh cloud-user@<vm-web-ip>
```

### Service Verification

Each environment exposes VM services for external access:

```bash
# Check services in each environment
oc get svc -n workshop-gitops-vms-dev
oc get svc -n workshop-gitops-vms-hml
oc get svc -n workshop-gitops-vms-prd

# Check endpoints to ensure services are working
oc get endpoints -n workshop-gitops-vms-dev
oc get endpoints -n workshop-gitops-vms-hml
oc get endpoints -n workshop-gitops-vms-prd

# Check routes (if created)
oc get routes -A
```

**Service Details:**
- `vm-web-service`: Exposes port 80/8080 from web VMs
- Services use `kubevirt.io/domain` selectors to target VM pods
- External access can be configured via Routes or LoadBalancer services

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

# Run complete verification script
./demo-scripts/check-status.sh
```

### Troubleshooting

**ArgoCD Applications Not Visible:**

If you can't see ArgoCD applications when running `oc get applications -A`, this is due to CRD ambiguity. OpenShift has two different Application CRDs:
- `applications.app.k8s.io` (Kubernetes native)
- `applications.argoproj.io` (ArgoCD)

Always use the specific ArgoCD CRD:
```bash
# Correct command to see ArgoCD applications
oc get applications.argoproj.io -n openshift-gitops

# Alternative with shorthand
oc get app.argoproj.io -n openshift-gitops

# Check available CRDs
oc api-resources | grep applications
```

**VM Not Starting:**
```bash
# Check VM status
oc get vms -A
oc describe vm <vm-name> -n <namespace>

# Check VMI (Virtual Machine Instance)
oc get vmi -A
oc describe vmi <vm-name> -n <namespace>

# Check events
oc get events -n <namespace> --sort-by='.lastTimestamp'
```

**Service Endpoints Empty:**
```bash
# Check endpoints
oc get endpoints -A

# Services target kubevirt.io/domain labels - verify VM pods have these labels
oc get pods -A --show-labels | grep kubevirt.io/domain

# Check service selectors match VM pod labels
oc get svc vm-web-service -n <namespace> -o yaml | grep selector -A 3
```

**SSH Access Issues:**
```bash
# Verify SSH secret exists in each namespace
oc get secret ssh-key-secret -n workshop-gitops-vms-dev
oc get secret ssh-key-secret -n workshop-gitops-vms-hml
oc get secret ssh-key-secret -n workshop-gitops-vms-prd

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
oc patch applications.argoproj.io workshop-vms-dev -n openshift-gitops --type merge --patch '{"operation":{"sync":{"revision":"HEAD"}}}'

# Check application details
oc describe application workshop-vms-dev -n openshift-gitops
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

```bash
export GITHUB_USERNAME="your-github-username"
./install.sh
```

### Option 2: Manual Installation (Recommended for Learning)

For workshop demonstrations and learning purposes, follow these manual steps:

#### Step 1: Set Environment Variables

```bash
# No environment variables needed - repository is preconfigured
```

#### Step 2: Validate Prerequisites

```bash
# Check OpenShift connection
oc whoami

# Verify OpenShift Virtualization is installed
oc get pods -n openshift-cnv

# Check for Fedora data source
oc get datasources -n openshift-virtualization-os-images | grep fedora
```

#### Step 3: Install OpenShift GitOps Operator

```bash
# Install the GitOps operator
oc apply -f manual-install/01-gitops-operator-subscription.yaml
```

#### Step 4: Wait for GitOps Operator Installation

```bash
# Wait for the operator to be ready (usually 1-2 minutes)
oc get csv -n openshift-operators | grep gitops

# Wait for ArgoCD instance to be created (may take 2-3 minutes)
oc get argocd openshift-gitops -n openshift-gitops

# Verify all ArgoCD pods are running
oc get pods -n openshift-gitops
```

**Expected output**: All pods should show `Running` status.

#### Step 5: Create Workshop Namespaces

```bash
# Create all workshop namespaces
oc apply -f manual-install/03-namespaces.yaml
```

#### Step 6: Grant ArgoCD Permissions

```bash
# Configure RBAC permissions for ArgoCD
oc apply -f manual-install/02-cluster-role-binding.yaml
```

#### Step 7: Create Repository Secret for Private Git Access

```bash
# Create secret with your SSH private key
oc create secret generic workshop-gitops-repo \
  --from-file=sshPrivateKey=$HOME/.ssh/ocpvirt-gitops-labs \
  --from-literal=type=git \
  --from-literal=url=git@github.com:$GITHUB_USERNAME/workshop-gitops-ocpvirt.git \
  -n openshift-gitops

# Label the secret for ArgoCD to recognize it
oc label secret workshop-gitops-repo -n openshift-gitops argocd.argoproj.io/secret-type=repository
```

#### Step 9: Create ArgoCD Applications

```bash
# Create ArgoCD applications for each environment
oc apply -f manual-install/04-argocd-app-dev.yaml
oc apply -f manual-install/05-argocd-app-hml.yaml
oc apply -f manual-install/06-argocd-app-prd.yaml

# Verify applications were created
oc get applications.argoproj.io -n openshift-gitops

# Wait for initial sync (may take 1-2 minutes)
watch "oc get applications.argoproj.io -n openshift-gitops"
```

**Expected output**: Applications should show `Synced` and `Healthy` status.

#### Step 10: Verify Installation

```bash
# Get ArgoCD access information
echo "ArgoCD URL: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)"

# Check application status
oc get applications.argoproj.io -n openshift-gitops

# Check workshop status
./demo-scripts/check-status.sh
```

### 3. Verify Installation

```bash
./demo-scripts/check-status.sh
```

## Workshop Environments

### Development Environment (vms-dev branch)
- **Namespace**: `workshop-gitops-vms-dev`
- **VMs**: 
  - `dev-vm-web-01` (1 CPU, 2GB RAM, 30GB disk)
  - `dev-vm-web-02` (1 CPU, 2GB RAM, 30GB disk)
  - `dev-vm-web-03` (1 CPU, 2GB RAM, 30GB disk)
- **Purpose**: Development and testing

### Homologation Environment (vms-hml branch)
- **Namespace**: `workshop-gitops-vms-hml`
- **VMs**:
  - `hml-vm-web-01` (2 CPU, 3GB RAM, 40GB disk)
  - `hml-vm-web-02` (2 CPU, 3GB RAM, 40GB disk)
  - `hml-vm-web-03` (2 CPU, 3GB RAM, 40GB disk)
- **Purpose**: Pre-production testing

### Production Environment (master branch)
- **Namespace**: `workshop-gitops-vms-prd`
- **VMs**:
  - `prd-vm-web-01` (2 CPU, 4GB RAM, 50GB disk)
  - `prd-vm-web-02` (2 CPU, 4GB RAM, 50GB disk)
  - `prd-vm-web-03` (2 CPU, 4GB RAM, 50GB disk)
- **Purpose**: Production workloads

## Demo Scenarios

### Demo 1: Manual Change Detection

Demonstrates how ArgoCD detects and corrects manual changes made outside of Git.

```bash
./demo-scripts/demo1-manual-change.sh
```

**What happens:**
1. Make a manual change to a VM (add a label)
2. ArgoCD detects "OutOfSync" status
3. Delete the VM manually
4. ArgoCD automatically recreates the VM from Git definition
5. Manual changes are lost, Git is the source of truth

### Demo 2: VM Recovery from Data Loss

Demonstrates complete VM recovery after catastrophic failure.

```bash
./demo-scripts/demo2-vm-recovery.sh
```

**What happens:**
1. Simulate VM corruption/data loss
2. Delete the VM and its storage
3. ArgoCD detects missing resources
4. ArgoCD recreates VM with fresh storage
5. Complete recovery from Git definitions

## GitOps Workflow

### 1. Development Process

```bash
# Work on development branch
git checkout vms-dev

# Make changes to base templates or overlays
vim base/vm-web-01.yaml
# or
vim overlays/dev/kustomization.yaml

# Commit changes
git add .
git commit -m "Update VM configuration"
git push origin vms-dev
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
oc patch application workshop-vms-dev -n openshift-gitops --type merge --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Check application details
oc describe application workshop-vms-dev -n openshift-gitops
```

### Regular Monitoring Commands

### Check Application Status
```bash
### Check Application Status
```bash
oc get applications.argoproj.io -n openshift-gitops
```

### Check Sync Status
```bash
oc get applications.argoproj.io workshop-vms-dev -n openshift-gitops -o yaml
```

### Force Sync
```bash
oc patch applications.argoproj.io workshop-vms-dev -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
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

Após completar todos os passos manuais da instalação, verifique se tudo está funcionando:

```bash
# Verificar aplicações do ArgoCD
oc get applications.argoproj.io -n openshift-gitops

# Verificar VMs criadas
oc get vm -A | grep workshop

# Verificar serviços
oc get svc -A | grep workshop

# Executar script de verificação completa
./demo-scripts/check-status.sh
```

### Resultados Esperados

Após a instalação manual, você deve ver:

**Aplicações ArgoCD:**
```
NAME               SYNC STATUS   HEALTH STATUS
workshop-vms-dev   Synced        Healthy
workshop-vms-hml   Synced        Healthy
workshop-vms-prd   Synced        Healthy
```

**Máquinas Virtuais:**
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

**Acesso ao ArgoCD:**
- URL: `https://openshift-gitops-server-openshift-gitops.apps.<seu-cluster>`
- Username: `admin`
- Password: (obtida com o comando no passo 6)

### Próximos Passos na Demonstração

Com o workshop instalado manualmente, você pode demonstrar:

1. **GitOps em Ação**: Fazer alterações nas branches e mostrar a sincronização automática
2. **Detecção de Drift**: Usar o script `./demo-scripts/demo1-manual-change.sh`
3. **Recuperação Automática**: Usar o script `./demo-scripts/demo2-vm-recovery.sh`
4. **Interface do ArgoCD**: Mostrar a interface web com as aplicações sincronizadas
5. **Verificações Contínuas**: Usar `./demo-scripts/check-status.sh` a qualquer momento