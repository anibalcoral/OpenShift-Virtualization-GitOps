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