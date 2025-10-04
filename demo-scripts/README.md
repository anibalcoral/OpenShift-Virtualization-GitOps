# Demo Scripts

This directory contains interactive and helper scripts used in the workshop demos. The scripts automate the common demo tasks used during the OpenShift GitOps with OpenShift Virtualization workshop and provide a reproducible way to demonstrate ArgoCD behaviours (drift detection, recovery and Git-based provisioning).

## Contents

- `run-demos.sh` - Interactive runner that walks through the three workshop demos.
- `check-status.sh` - Consolidated status checker for ArgoCD applications, namespaces and VMs.
- `demo1-manual-change.sh` - Demo 1: Make a manual change to a VM and show ArgoCD self-heal.
- `demo2-vm-recovery.sh` - Demo 2: Simulate VM + storage loss and show GitOps recovery.
- `demo3-add-development-vm.sh` - Demo 3: Add a new VM by editing the Apps repo and show auto-deploy.
- `cleanup-demo3.sh` - Helper to remove demo artifacts created by Demo 3 (if applicable).
- `demo-functions.sh` - Shared helper functions used by the demo scripts.
- `[DEMO1-MANUAL-CHANGE.md](DEMO1-MANUAL-CHANGE.md)`, `[DEMO2-VM-RECOVERY.md](DEMO2-VM-RECOVERY.md)`, `[DEMO3-ADD-DEVELOPMENT-VM.md](DEMO3-ADD-DEVELOPMENT-VM.md)` - Detailed, step-by-step documentation for each demo.

## Quick Start

These scripts expect you have the workshop prerequisites in place (see repository `README.md`). Minimal checklist:

- `oc` CLI configured and logged in with cluster-admin privileges
- ArgoCD operator installed and the three ArgoCD applications created (see `manual-install/`)
- Both repositories cloned locally and accessible:
  ```bash
  ../OpenShift-Virtualization-GitOps-Apps
  ```

Run the interactive demos runner:

```bash
./run-demos.sh
```

Or run a single demo directly, for example:

```bash
./demo1-manual-change.sh
```

## Demo Summaries

Demo 1 — Manual Change Detection and Drift Correction
- Demonstrates ArgoCD detecting manual changes to VM resources (e.g. setting `runStrategy: Halted`) and automatically restoring the Git-declared state. See the full walkthrough: [DEMO1-MANUAL-CHANGE.md](DEMO1-MANUAL-CHANGE.md)

Demo 2 — VM Recovery from Data Loss
- Demonstrates deleting a VM and its DataVolume to simulate data loss, then shows ArgoCD recreating the VM and storage from Git. See the full walkthrough: [DEMO2-VM-RECOVERY.md](DEMO2-VM-RECOVERY.md)

Demo 3 — Adding New Development VM via Git Change
- Demonstrates the Git workflow to add a new VM to the `OpenShift-Virtualization-GitOps-Apps` repo and how ArgoCD applies the change automatically. See the full walkthrough: [DEMO3-ADD-DEVELOPMENT-VM.md](DEMO3-ADD-DEVELOPMENT-VM.md)

## How the Scripts Work

- The scripts call `oc` for cluster operations and patch/annotate ArgoCD Applications to force refreshes when needed.
- `demo-functions.sh` contains common helpers used by the demos (status checks, wait loops, logging helpers).
- The demos are intentionally interactive and verbose to make them suitable for live workshops and training.

## Troubleshooting

If a demo does not behave as expected, try these checks:

1. Verify ArgoCD status and application sync:
   ```bash
   oc get applications.argoproj.io -n openshift-gitops
   ```
   ```bash
   oc describe applications.argoproj.io workshop-vms-dev -n openshift-gitops
   ```

2. Check VMs and DataVolumes in the target namespace:
   ```bash
   oc get vm -n workshop-gitops-vms-dev
   ```
   ```bash
   oc get dv -n workshop-gitops-vms-dev
   ```

3. Force an ArgoCD refresh if changes are not detected:
   ```bash
   oc annotate applications.argoproj.io workshop-vms-dev -n openshift-gitops argocd.argoproj.io/refresh="$(date)" --overwrite
   ```

4. If DataVolumes fail, verify storage class and CDI pods:
   ```bash
   oc get storageclass
   ```
   ```bash
   oc get pods -n openshift-cnv | grep cdi
   ```

## Cleanup

Some demos create Git changes (Demo 3). Clean up using the provided helper or by reverting the Git commits you created.

- Use `cleanup-demo3.sh` to remove demo resources in the cluster (if provided).
- Revert or remove files from `OpenShift-Virtualization-GitOps-Apps` and push the cleanup commit to the appropriate branch.

## See also

- Top-level `README.md` — workshop overview and installation instructions
- `manual-install/README.md` — manual installation manifest ordering
- `../OpenShift-Virtualization-GitOps-Apps` — companion Apps repository with VM definitions and kustomize overlays

````
