# Ansible Playbooks

This directory contains the Ansible playbooks used to install, configure, and demonstrate the OpenShift GitOps components for the workshop. The playbooks provide a repeatable, automated way to deploy the ArgoCD operator, run interactive demos, and tear down components when the workshop is finished.

## Prerequisites

- Ansible and `ansible-playbook` installed on the host running the playbooks
- `oc` CLI installed and configured with cluster-admin privileges
- The inventory file located at `/opt/OpenShift-Virtualization-GitOps/inventory/localhost` (included in this repository)
- Optional: install Ansible requirements (collections/roles) listed in `../requirements.yml`

Install any required collections/roles before running the playbooks:

```bash
ansible-galaxy install -r requirements.yml
```

## Installation and Management Playbooks

- `install-workshop.yaml`
  - Purpose: Complete workshop installation including GitOps operator, SSH keys, and ArgoCD applications
  - Main actions:
    - Creates or updates the GitOps operator subscription
    - Ensures necessary RBAC and cluster role bindings are present
    - Sets up SSH keys for VM access
    - Applies ArgoCD applications for all workshop environments (dev/hml/prd)

- `remove-workshop.yaml`
  - Purpose: Removes ArgoCD applications and optionally the GitOps operator to clean up the workshop environment
  - Main actions:
    - Deletes the ArgoCD Application resources created for the workshop
    - Optionally removes operator subscription and ClusterRoles/ClusterRoleBindings

- `check-workshop-status.yaml`
  - Purpose: Verifies workshop installation status and health
  - Main actions:
    - Checks ArgoCD operator installation and pod health
    - Verifies ArgoCD applications sync status
    - Reports on VM deployment status across all environments

- `cleanup-ssh-known-hosts.yaml`
  - Purpose: Cleans up SSH known_hosts entries for workshop VMs
  - Main actions:
    - Removes conflicting SSH host keys from ~/.ssh/known_hosts
    - Cleans up entries created by virtctl ssh connections
    - Resolves SSH host key verification issues

## Demo Playbooks

- `demo1-manual-change.yaml`
  - Purpose: Demo 1 - Manual Change Detection and Drift Correction
  - Actions:
    - Manually modifies a VM's runStrategy to simulate configuration drift
    - Monitors ArgoCD detection of drift and automatic correction
    - Verifies VM returns to desired state

- `demo2-vm-recovery.yaml`
  - Purpose: Demo 2 - VM Recovery from Data Loss
  - Actions:
    - Completely deletes a VM to simulate data loss
    - Shows ArgoCD detecting missing resources
    - Demonstrates recovery through Git-based sync
    - Verifies complete VM recreation

- `demo3-add-development-vm.yaml`
  - Purpose: Demo 3 - Adding New Development VM via Git Change
  - Actions:
    - Creates new VM definition (vm-web-09) in Git repository
    - Commits and pushes changes to development branch
    - Monitors ArgoCD automatic deployment
    - Verifies new VM creation and functionality

- `demo4-multi-env-management.yaml`
  - Purpose: Demo 4 - Multi-Environment VM Management with Kustomize
  - Actions:
    - Promotes VM changes from development to homologation to production
    - Demonstrates Kustomize overlays for environment-specific configurations
    - Shows centralized base template management
    - Illustrates branch-based promotion strategies

## Cleanup Playbooks

- `cleanup-demo4.yaml`
  - Purpose: Cleanup Demo 4 resources
  - Actions:
    - Removes vm-web-09 from all environments through Git branch promotion
    - Uses the same promotion flow (dev → hml → prod) for consistent cleanup
    - ArgoCD automatically removes VMs from all namespaces

## Support Tasks and Templates

- `tasks/` directory contains reusable task modules:
  - `install-gitops-tasks.yaml` - GitOps operator installation tasks
  - `setup-ssh-key-tasks.yaml` - SSH key generation and configuration
  - `validate-cluster-domain-tasks.yaml` - Cluster domain validation

- `templates/` directory contains Jinja2 templates:
  - `ssh-secret.yaml.j2` - SSH secret template for VM access
  - `ssh-secret-vms.yaml.j2` - VM-specific SSH secret template

## Usage

### Installation

Install the complete workshop:

```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/install-workshop.yaml
```

### Running Demos

Run individual demos:

```bash
# Demo 1: Manual Change Detection
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo1-manual-change.yaml

# Demo 2: VM Recovery
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo2-vm-recovery.yaml

# Demo 3: Add Development VM
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo3-add-development-vm.yaml

# Demo 4: Multi-Environment Management
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/demo4-multi-env-management.yaml
```

### Cleanup

Clean up demo resources:

```bash
# Clean up Demo 4
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-demo4.yaml
```

### Complete Removal

Remove the entire workshop:

```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/remove-workshop.yaml
```

### Status Check

Check workshop status:

```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/check-workshop-status.yaml
```

### SSH Known Hosts Cleanup

Clean up SSH known_hosts for VM connections (resolves SSH host key conflicts):

```bash
ansible-playbook -i /opt/OpenShift-Virtualization-GitOps/inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/cleanup-ssh-known-hosts.yaml
```

## Verification

After running the install playbook, verify the installation with these commands:

```bash
# Check ArgoCD operator and pods
oc get csv -n openshift-operators | grep -i argocd
oc get pods -n openshift-gitops

# Check ArgoCD applications created by the workshop
oc get applications.argoproj.io -n openshift-gitops

# Check VMs across all environments
oc get vm -n workshop-gitops-vms-dev
oc get vm -n workshop-gitops-vms-hml  
oc get vm -n workshop-gitops-vms-prd
```

After running the removal playbook, verify resources were removed:

```bash
oc get applications.argoproj.io -n openshift-gitops || true
oc get pods -n openshift-gitops || true
```

## Troubleshooting

- Permission errors: ensure the `oc` session has cluster-admin privileges and that the Ansible control host can reach the cluster.
- Missing collections/roles: run `ansible-galaxy install -r requirements.yml` and re-run the playbook.
- Playbook failures: rerun with `-vv` to obtain detailed output and check the task that failed. Common failures include timeouts waiting for operator pods to become ready; allow 2-3 minutes after subscription creation for operator installation.
- Git repository access: ensure the Apps repository is properly cloned to `/opt/OpenShift-Virtualization-GitOps-Apps` with appropriate permissions.

## Playbook Internals

- The playbooks are designed to be idempotent; you can safely re-run them to ensure the desired state is applied.
- Demo playbooks include comprehensive status checking and wait conditions for ArgoCD synchronization.
- Git operations are performed directly using shell commands for transparency and control.
- Use `-v` or `-vv` for more verbose Ansible output when debugging.

## See also

- Top-level `README.md` — workshop overview and installation instructions: [../README.md](../README.md)
- Demo scripts documentation: [../demo-scripts/README.md](../demo-scripts/README.md)
- Manual installation manifests and ordering: [../manual-install/README.md](../manual-install/README.md)
- Apps repository (GitHub) — companion Apps project with VM definitions and kustomize overlays: [anibalcoral/OpenShift-Virtualization-GitOps-Apps](https://github.com/anibalcoral/OpenShift-Virtualization-GitOps-Apps)

