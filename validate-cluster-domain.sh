#!/bin/bash

# Quick script to validate cluster domain using Ansible

set -e

echo "Validating and configuring cluster domain..."
ansible-playbook -i inventory/localhost playbooks/validate-cluster-domain.yaml