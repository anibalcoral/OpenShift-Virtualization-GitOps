# Manual Installation Files

This directory contains the YAML files for manual installation of the GitOps Workshop in sequential order.

## Prerequisites

1. OpenShift cluster with Virtualization enabled
2. Cluster admin access
3. SSH key configured for GitHub access
4. GITHUB_USERNAME environment variable set

## Installation Steps

Execute the files in the following order:

### Step 1: Install GitOps Operator
```bash
oc apply -f 01-gitops-operator-subscription.yaml
```
Wait for operator installation (2-3 minutes):
```bash
oc wait --for=condition=Ready pod -l name=argocd-application-controller -n openshift-gitops --timeout=300s
```

### Step 2: Create Repository Secret
```bash
oc create secret generic workshop-gitops-repo \
  --from-file=sshPrivateKey=$HOME/.ssh/id_rsa \
  --from-literal=url=git@github.com:${GITHUB_USERNAME}/workshop-gitops-ocpvirt.git \
  --from-literal=type=git \
  -n openshift-gitops

oc label secret workshop-gitops-repo argocd.argoproj.io/secret-type=repository -n openshift-gitops
```

### Step 3: Configure RBAC
```bash
oc apply -f 02-cluster-role-binding.yaml
```

### Step 4: Create Namespaces
```bash
oc apply -f 03-namespaces.yaml
```

### Step 5: Create ArgoCD Applications
```bash
oc apply -f 04-argocd-app-dev.yaml
oc apply -f 05-argocd-app-hml.yaml
oc apply -f 06-argocd-app-prd.yaml
```

### Step 6: Get ArgoCD Access Information
```bash
# Get ArgoCD URL
oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'

# Get admin password
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=- --keys=admin.password 2>/dev/null
```

## Verification

Check the installation:
```bash
# Check applications
oc get applications -n openshift-gitops

# Check VMs
oc get vm -A | grep workshop

# Run complete status check
../demo-scripts/check-status.sh
```

## Cleanup

To remove everything:
```bash
../remove.sh
```