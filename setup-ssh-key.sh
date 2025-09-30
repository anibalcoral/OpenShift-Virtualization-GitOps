#!/bin/bash

set -e

echo "Setting up SSH key for workshop VMs..."

SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_rsa.pub"

if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
    echo "Error: SSH public key not found at $SSH_PUBLIC_KEY_FILE"
    echo "Please generate SSH keys with: ssh-keygen -t rsa -b 4096"
    exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_FILE")

echo "Updating SSH secret with your public key..."
cat > base/ssh-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: workshop-ssh-key
type: Opaque
stringData:
  key: |
    $SSH_PUBLIC_KEY
EOF

echo "SSH key setup completed!"
echo "Your VMs will be accessible via SSH using your private key: $HOME/.ssh/id_rsa"