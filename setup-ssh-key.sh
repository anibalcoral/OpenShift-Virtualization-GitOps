#!/bin/bash

# Quick script to setup SSH keys using Ansible

set -e

if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook not found. Please install Ansible."
    exit 1
fi

echo "Setting up SSH keys for workshop VMs..."
ansible-playbook -i inventory/localhost playbooks/setup-ssh-key.yaml