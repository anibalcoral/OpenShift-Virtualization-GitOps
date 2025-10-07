# Demo Scripts

This directory contains interactive demo scripts for the OpenShift GitOps with OpenShift Virtualization workshop. The scripts use direct OpenShift commands to demonstrate ArgoCD behaviors (drift detection, recovery, and Git-based provisioning).

## Contents

**Interactive Runners:**
- `run-demos.sh` - Interactive runner that walks through the three workshop demos

**Utility Functions:**
- `demo-functions.sh` - Shared helper functions used by the bash scripts

**Documentation:**
- `DEMO1-MANUAL-CHANGE.md` - Demo 1 detailed documentation
- `DEMO2-VM-RECOVERY.md` - Demo 2 detailed documentation  
- `DEMO3-ADD-DEVELOPMENT-VM.md` - Demo 3 detailed documentation

## Quick Start

**Interactive Demo Runner:**
```bash
./run-demos.sh
```
This provides a menu to select and run demos.

**Available Options:**
- `1` - Demo 1: Manual Change Detection and Drift Correction
- `2` - Demo 2: VM Recovery from Data Loss
- `3` - Demo 3: Adding New Development VM via Git Change
- `a` - Run all demos sequentially
- `s` - Check workshop status
- `q` - Quit

**Status Checking:**
```bash
./run-demos.sh
# Select option 's' for status check
```

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

## Ansible Playbook Equivalents

The demo scripts call these Ansible playbooks:

```bash
# Workshop status checking
ansible-playbook -i ../inventory/localhost ..//opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml

# Demo 1: Manual change detection
ansible-playbook -i ../inventory/localhost ..//opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml

# Demo 2: VM recovery
ansible-playbook -i ../inventory/localhost ..//opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml

# Demo 3: Add development VM
ansible-playbook -i ../inventory/localhost ..//opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml

# Demo 3 cleanup: Remove development VM
ansible-playbook -i ../inventory/localhost ..//opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml
```

## How the Scripts Work

- The scripts call Ansible playbooks for Demos 1 and 2, providing structured automation
- Demo 3 still uses bash script with direct `oc` commands and Git operations
- `demo-functions.sh` contains common helpers used by the bash scripts
- The demos are intentionally interactive and verbose to make them suitable for live workshops and training

## Features

- **Automated demos**: Each demo runs automatically with clear status output
- **ArgoCD validation**: Scripts verify ArgoCD applications and sync status
- **VM lifecycle management**: Complete VM creation, modification, and deletion workflows
- **Git integration**: Demo 3 includes Git workflow for infrastructure changes
- **Cleanup utilities**: Helper scripts to reset demo environments

## Cleanup

Demo 3 creates Git changes and cluster resources. Clean up using:

```bash
# Use cleanup script
./cleanup-demo3.sh

# Or call Ansible directly
cd .. && ansible-playbook -i inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo3.yaml
```

The cleanup process:
- Removes vm-web-09.yaml from Git repository
- Updates kustomization.yaml to exclude the VM
- Commits and pushes cleanup changes
- Triggers ArgoCD sync with prune to remove cluster resources
- Restores development environment to baseline (2 VMs)

## See also

- Top-level `README.md` — workshop overview and installation instructions: [../README.md](../README.md)
- `manual-install/README.md` — manual installation manifest ordering: [manual-install/README.md](../manual-install/README.md)
- Apps repository (GitHub) — companion Apps project with VM definitions and kustomize overlays: [anibalcoral/OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps)