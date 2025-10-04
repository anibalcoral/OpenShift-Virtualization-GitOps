#!/bin/bash

# Quick script to validate workshop alignment using Ansible

set -e

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

echo "Validating workshop alignment..."
ansible-playbook -i inventory/localhost playbooks/validate-workshop-alignment.yaml