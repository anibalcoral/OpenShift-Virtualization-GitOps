#!/bin/bash

# Quick script to validate workshop alignment using Ansible

set -e

echo "Validating workshop alignment..."
ansible-playbook -i inventory/localhost playbooks/validate-workshop-alignment.yaml