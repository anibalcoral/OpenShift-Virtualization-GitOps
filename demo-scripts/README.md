# Demo Scripts

This directory contains interactive demo scripts for the OpenShift GitOps with OpenShift Virtualization workshop. The scripts use direct OpenShift commands to demonstrate ArgoCD behaviors (drift detection, recovery, and Git-based provisioning).

## Contents

**Utility Functions:**
- `demo-functions.sh` - Shared helper functions used by the bash scripts

**Documentation:**
- `DEMO1-MANUAL-CHANGE.md` - Demo 1 detailed documentation
- `DEMO2-VM-RECOVERY.md` - Demo 2 detailed documentation  
- `DEMO3-ADD-DEVELOPMENT-VM.md` - Demo 3 detailed documentation
- `DEMO4-MULTI-ENV-MANAGEMENT.md` - Demo 4 detailed documentation

## Demo Summaries

**Demo 1: Manual Change Detection and Drift Correction**
- Manually modifies a VM's runStrategy
- Shows ArgoCD detecting configuration drift
- Demonstrates automatic self-healing correction
- Verifies VM returns to desired state

**Demo 2: VM Recovery from Data Loss**  
- Completely deletes a VM (simulating data loss)
- Shows ArgoCD detecting missing resources
- Demonstrates recovery through Git-based sync
- Verifies complete VM recreation and functionality

**Demo 3: Adding New Development VM via Git Change**
- Adds a new VM definition to the development environment
- Shows git-based workflow for infrastructure changes
- Demonstrates automatic deployment through ArgoCD
- Includes cleanup utilities for demo repeatability

**Demo 4: Multi-Environment VM Management with Kustomize**
- Promotes VM changes through development → homologation → production environments
- Demonstrates Kustomize overlays for environment-specific configurations
- Shows centralized base template management across environments
- Illustrates branch-based promotion strategies in GitOps workflows

## Ansible Playbook Equivalents

The demo scripts call these Ansible playbooks:

```bash
# Workshop status checking
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml

# Demo 1: Manual change detection
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