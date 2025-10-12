# Demo Guides

This directory contains comprehensive guides for the OpenShift GitOps with OpenShift Virtualization workshop demos. All demos are executed through Ansible playbooks that provide automated and reproducible demonstrations of ArgoCD behaviors (drift detection, recovery, and Git-based provisioning).

## Contents

**Demo Documentation:**
- `DEMO1-MANUAL-CHANGE.md` - Demo 1 detailed guide and manual instructions
- `DEMO2-VM-RECOVERY.md` - Demo 2 detailed guide and manual instructions  
- `DEMO3-ADD-DEVELOPMENT-VM.md` - Demo 3 detailed guide and manual instructions
- `DEMO4-MULTI-ENV-MANAGEMENT.md` - Demo 4 detailed guide and manual instructions

## Demo Summaries

**Demo 1: Manual Change Detection and Drift Correction**
- Manually modifies a VM's runStrategy using Kubernetes API
- Shows ArgoCD detecting configuration drift automatically
- Demonstrates automatic self-healing correction through Git sync
- Verifies VM returns to desired state defined in Git repository

**Demo 2: VM Recovery from Data Loss**  
- Completely deletes a VM resource (simulating data loss or accidental deletion)
- Shows ArgoCD detecting missing resources in cluster
- Demonstrates complete recovery through Git-based synchronization
- Verifies VM recreation with all original configurations and functionality

**Demo 3: Adding New Development VM via Git Change**
- Adds a new VM definition to the development environment through Git workflow
- Shows git-based infrastructure as code workflow for VM management
- Demonstrates automatic deployment through ArgoCD Git polling and sync
- Includes automated cleanup utilities for demo repeatability

**Demo 4: Multi-Environment VM Management with Kustomize**
- Promotes VM changes through development → homologation → production environments
- Demonstrates Kustomize overlays for environment-specific VM configurations
- Shows centralized base template management across multiple environments
- Illustrates branch-based promotion strategies in GitOps workflows

## Execution Methods

### Automated Execution via Demo Runner

Use the demo runner script for interactive execution:

```bash
# Interactive menu
/opt/OpenShift-Virtualization-GitOps/run-demos.sh

# Run specific demo
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 1
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 2
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 3
/opt/OpenShift-Virtualization-GitOps/run-demos.sh 4

# Run all demos sequentially
/opt/OpenShift-Virtualization-GitOps/run-demos.sh a

# Check workshop status
/opt/OpenShift-Virtualization-GitOps/run-demos.sh s

# Clean up Demo 4 resources
/opt/OpenShift-Virtualization-GitOps/run-demos.sh c
```

### Direct Ansible Playbook Execution

Execute demos directly using Ansible for automation or integration purposes:

```bash
# Demo 1: Manual change detection and drift correction
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml

# Demo 2: VM recovery from data loss
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml

# Demo 3: Adding new development VM via Git change
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml

# Demo 4: Multi-environment VM management with Kustomize
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml

# Workshop status checking
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml

# Demo 4 cleanup
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

## Prerequisites

- OpenShift cluster with Virtualization operator installed
- OpenShift GitOps (ArgoCD) operator installed
- GUID environment variable set (`export GUID=your-guid`)
- Both repositories cloned to `/opt/` directory
- Cluster admin access with `oc` CLI authenticated

## Architecture Integration

The demos work with the dual-repository GitOps architecture:

- **Main Repository**: Contains installation scripts, playbooks, and demo automation
- **Apps Repository**: Contains VM definitions with Kustomize overlays for environment-specific configurations
- **Branch Strategy**: Development (`vms-dev-{guid}`) → Homologation (`vms-hml-{guid}`) → Production (`vms-prd-{guid}`)
- **Namespace Strategy**: Each environment deploys to separate namespaces (`workshop-gitops-vms-{dev,hml,prd}`)

Each demo playbook includes detailed logging, status checking, and verification steps to ensure successful execution and educational value.
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml

# Demo 2: VM recovery
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml

# Demo 3: Add development VM
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml

# Demo 4: Multi-environment management
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml

# Demo 4 cleanup: Remove multi-environment VMs
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

## Features

- **Automated demos**: Each demo runs automatically with clear status output
- **ArgoCD validation**: Scripts verify ArgoCD applications and sync status
- **VM lifecycle management**: Complete VM creation, modification, and deletion workflows
- **Git integration**: Demo 3 includes Git workflow for infrastructure changes
- **Cleanup utilities**: Helper scripts to reset demo environments

## Cleanup

Demo 4 create Git changes and cluster resources. Clean up using:

```bash
# Clean up Demo 4  
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

The cleanup processes:

**Demo 4 Cleanup:**
- Removes vm-web-09 from all environments through Git branch promotion
- Uses the same promotion flow (dev → hml → prod) for consistent cleanup
- ArgoCD automatically removes VMs from all namespaces
- Maintains GitOps principles during cleanup process

## See also

- Top-level `README.md` — workshop overview and installation instructions: [../README.md](../README.md)
- `manual-install/README.md` — manual installation manifest ordering: [manual-install/README.md](../manual-install/README.md)
- Apps repository (GitHub) — companion Apps project with VM definitions and kustomize overlays: [anibalcoral/OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps)