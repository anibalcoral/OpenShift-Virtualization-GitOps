# Ansible Playbooks

This directory contains the Ansible playbooks used to install and remove the OpenShift GitOps components for the workshop. The playbooks provide a repeatable, automated way to deploy the ArgoCD operator and related configuration, or to tear down those components when the workshop is finished.

## Prerequisites

- Ansible and `ansible-playbook` installed on the host running the playbooks
- `oc` CLI installed and configured with cluster-admin privileges
- The inventory file located at `../inventory/localhost` (included in this repository)
- Optional: install Ansible requirements (collections/roles) listed in `../requirements.yml`

Install any required collections/roles before running the playbooks:

```bash
ansible-galaxy install -r requirements.yml
```

## Playbooks

- `install-gitops.yaml`
  - Purpose: Installs the OpenShift GitOps (ArgoCD) operator and performs initial configuration required for the workshop. This playbook mirrors the automated installation performed by `./install.sh` and applies the manual manifests in the correct order.
  - Main actions:
    - Creates or updates the GitOps operator subscription
    - Ensures necessary RBAC and cluster role bindings are present
    - Applies ArgoCD applications for the workshop environments (dev/hml/prd)

- `remove-gitops.yaml`
  - Purpose: Removes ArgoCD applications and optionally the GitOps operator to clean up the workshop environment.
  - Main actions:
    - Deletes the ArgoCD Application resources created for the workshop
    - Optionally removes operator subscription and ClusterRoles/ClusterRoleBindings

## Usage

Run the install playbook:

```bash
ansible-playbook -i inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/install-gitops.yaml
```

Run the removal playbook:

```bash
ansible-playbook -i inventory/localhost /opt/OpenShift-Virtualization-GitOps/playbooks/remove-gitops.yaml
```

Notes:
- The playbooks are written to be idempotent; you can safely re-run them to ensure the desired state is applied.
- Use `-v` or `-vv` for more verbose Ansible output when debugging.

## Verification

After running the install playbook, verify the installation with these commands:

```bash
# Check ArgoCD operator and pods
oc get csv -n openshift-operators | grep -i argocd
oc get pods -n openshift-gitops

# Check ArgoCD applications created by the workshop
oc get applications.argoproj.io -n openshift-gitops
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

## Playbook internals

- The playbooks are simple, single-play, host-local playbooks that call `oc` and apply Kubernetes manifests. They are intentionally explicit and minimal to keep the workshop reproducible and transparent.
- Templates used by the playbooks are located in the `templates/` directory if any parameterized manifests are needed.

## See also

- Top-level `README.md` — workshop overview and installation instructions: [../README.md](../README.md)
- Manual installation manifests and ordering: [../manual-install/README.md](../manual-install/README.md)

