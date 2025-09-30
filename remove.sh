#!/bin/bash

set -e

echo "Starting OpenShift GitOps Workshop Removal..."

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

if ! command -v oc &> /dev/null; then
    echo "Error: oc CLI not found. Please install OpenShift CLI."
    exit 1
fi

echo "Checking OpenShift connection..."
if ! oc whoami &> /dev/null; then
    echo "Error: Not connected to OpenShift cluster. Please login with 'oc login'."
    exit 1
fi

echo "Removing OpenShift GitOps Workshop resources..."
ansible-playbook -i inventory/localhost playbooks/remove-gitops.yaml

echo "Workshop removal completed successfully!"