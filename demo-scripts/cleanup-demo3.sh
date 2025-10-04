#!/bin/bash

set -e

# Demo 3 Cleanup: Removing Development VM via Git Change
# This script calls the Ansible playbook for Demo 3 cleanup

echo "🧹 Starting Demo 3 Cleanup: Removing Development VM via Git Change"
echo "=================================================================="

# Navigate to the parent directory to run the Ansible playbook
cd "$(dirname "$0")/.."

# Run the Ansible playbook
ansible-playbook -i inventory/localhost playbooks/cleanup-demo3.yaml

echo ""
echo "Demo 3 cleanup completed successfully!"
echo "📝 Development environment restored to baseline (2 VMs)."