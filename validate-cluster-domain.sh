#!/bin/bash

# Quick script to validate cluster domain using Ansible

set -e

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

echo "Validating and configuring cluster domain..."
ansible-playbook -i inventory/localhost playbooks/validate-cluster-domain.yaml