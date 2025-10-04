#!/bin/bash

# Quick script to check workshop status using Ansible

set -e

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

echo "Checking workshop status..."
cd "$(dirname "$0")/.."
ansible-playbook -i inventory/localhost playbooks/check-workshop-status.yaml