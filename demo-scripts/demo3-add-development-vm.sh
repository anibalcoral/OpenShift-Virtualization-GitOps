#!/bin/bash

set -e

# Demo 3: Adding New Development VM via Git Change
# This script calls the Ansible playbook for Demo 3

echo "🚀 Starting Demo 3: Adding New Development VM via Git Change"
echo "============================================================="

# Navigate to the parent directory to run the Ansible playbook
cd "$(dirname "$0")/.."

# Run the Ansible playbook
ansible-playbook -i inventory/localhost playbooks/demo3-add-development-vm.yaml

echo ""
echo "✅ Demo 3 completed successfully!"
echo "📝 Use './demo-scripts/cleanup-demo3.sh' to clean up the demo artifacts if needed."