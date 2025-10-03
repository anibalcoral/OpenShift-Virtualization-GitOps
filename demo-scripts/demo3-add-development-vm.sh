#!/bin/bash

set -e

# Source common functions
source "$(dirname "$0")/demo-functions.sh"

echo "Demo 3: Adding New Development VM via Git Change"
echo "================================================="

NAMESPACE="workshop-gitops-vms-dev"
VM_NAME="dev-vm-web-09"
APP_NAME="workshop-vms-dev"
APPS_REPO_PATH="/home/lchiaret/git/OpenShift-Virtualization-GitOps-Apps"

log "Step 1: Check current state - should only have 2 VMs..."
show_app_status $APP_NAME

log "Current VMs in development environment:"
oc get vm -n $NAMESPACE | grep -E "(NAME|dev-vm-web)" || log_warning "No VMs found"

if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_warning "VM '$VM_NAME' already exists - demo may have been run before"
fi

echo ""
log "Step 2: Adding vm-web-09.yaml to base directory..."

# Create vm-web-09.yaml in base directory
cat > "$APPS_REPO_PATH/base/vm-web-09.yaml" << 'EOF'
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-web-09
  labels:
    app: web-server
    workshop: gitops-ocpvirt
  annotations:
    workshop.gitops/config-version: "v4-fedora-firewall-fix"
spec:
  dataVolumeTemplates:
  - apiVersion: cdi.kubevirt.io/v1beta1
    kind: DataVolumeTemplate
    metadata:
      name: vm-web-09
    spec:
      sourceRef:
        kind: DataSource
        name: fedora
        namespace: openshift-virtualization-os-images
      storage:
        resources:
          requests:
            storage: 30Gi
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/size: small
        kubevirt.io/domain: vm-web-09
        app: web-server
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            name: default
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.6.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      networks:
      - name: default
        pod: {}
      terminationGracePeriodSeconds: 180
      volumes:
      - dataVolume:
          name: vm-web-09
        name: rootdisk
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            user: cloud-user
            password: redhat123
            chpasswd: { expire: False }
            packages:
              - httpd
              - firewalld
            runcmd:
              - systemctl enable httpd
              - systemctl start httpd
              - echo 'Web Server - VM 03 (Development)' > /var/www/html/index.html
              - systemctl enable firewalld
              - systemctl start firewalld
              - firewall-cmd --permanent --add-service=http || true
              - firewall-cmd --reload || true
        name: cloudinitdisk
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: workshop-ssh-key
          propagationMethod:
            noCloud: {}
EOF

log_success "Created vm-web-09.yaml in base directory"

echo ""
log "Step 3: Updating kustomization.yaml to include new VM..."

# Update base kustomization.yaml
cat > "$APPS_REPO_PATH/base/kustomization.yaml" << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - vm-web-09.yaml
  - ssh-secret.yaml
  - vm-web-01.yaml
  - vm-web-02.yaml
  - vm-web-03.yaml
  - vm-web-service.yaml
EOF

log_success "Updated base/kustomization.yaml to include vm-web-09.yaml"

echo ""
log "Step 4: Committing changes to Git repository..."

cd "$APPS_REPO_PATH"

# Check if we're on the vms-dev branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "vms-dev" ]; then
    log "Switching to vms-dev branch..."
    git checkout vms-dev
fi

# Add and commit changes
git add base/vm-web-09.yaml base/kustomization.yaml
git commit -m "feat: add development VM web-09 for expanded testing environment

- Add vm-web-09.yaml with Fedora-based web server configuration
- Update base kustomization to include new VM resource
- Provides additional development capacity for testing scenarios"

git push origin vms-dev

log_success "Changes committed and pushed to vms-dev branch"

log "Step 4.1: Triggering an ArgoCD sync to correct the drift..."
oc patch applications.argoproj.io $APP_NAME -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
log_success "ArgoCD sync triggered."

echo ""
log "Step 5: Waiting for ArgoCD to detect Git changes..."

# Return to original directory
cd -

# Wait for ArgoCD to detect the change
wait_for_sync_status $APP_NAME "OutOfSync" 60

echo ""
log "Step 6: Triggering ArgoCD sync (simulating automatic sync)..."
trigger_sync $APP_NAME

echo ""
log "Step 7: Waiting for new VM to be created..."
wait_for_vm_exists $VM_NAME $NAMESPACE 120

echo ""
log "Step 8: Waiting for application to return to Synced state..."
wait_for_sync_status $APP_NAME "Synced" 60

echo ""
log "Step 9: Verifying the new VM is running..."

if oc get vm $VM_NAME -n $NAMESPACE &>/dev/null; then
    log_success "VM '$VM_NAME' successfully created"
    
    # Show VM status
    vm_status=$(oc get vm $VM_NAME -n $NAMESPACE -o jsonpath='{.status.printableStatus}' 2>/dev/null || echo "Unknown")
    log "VM Status: $vm_status"
    
    # Show all VMs in dev environment
    echo ""
    log "All VMs in development environment:"
    oc get vm -n $NAMESPACE | grep -E "(NAME|dev-vm-web)"
else
    log_error "VM '$VM_NAME' creation failed"
    exit 1
fi

echo ""
log_success "Demo 3 completed! New development VM added via Git changes."
echo ""
log "Summary:"
log "========="
log "✓ New VM definition added to Git repository"
log "✓ Base kustomization updated to include new resource"
log "✓ Changes committed and pushed to vms-dev branch"
log "✓ ArgoCD detected Git changes (OutOfSync state)"
log "✓ ArgoCD automatically deployed new VM"
log "✓ Development environment now has 3 VMs for expanded testing"
log "✓ Application returned to Synced state"