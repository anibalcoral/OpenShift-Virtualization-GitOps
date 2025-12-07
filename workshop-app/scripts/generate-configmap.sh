#!/bin/bash
# Generate ConfigMap from markdown files in demo-guides directory
# This script creates a ConfigMap with all DEMO*.md files as guides

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="${SCRIPT_DIR}/.."
GITOPS_DIR="${APP_DIR}/.."
GUIDES_DIR="${GITOPS_DIR}/demo-guides"
OUTPUT_FILE="${APP_DIR}/deploy/04-configmap-guides.yaml"

echo "Generating ConfigMap from guides in: ${GUIDES_DIR}"

# Start the ConfigMap
cat > "${OUTPUT_FILE}" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: workshop-guides
  namespace: workshop-gitops
  labels:
    app: gitops-workshop
data:
EOF

# Find all DEMO*.md files and add them to the ConfigMap
counter=1
for file in $(ls "${GUIDES_DIR}"/DEMO*.md 2>/dev/null | sort); do
    filename=$(basename "$file")
    padded_counter=$(printf "%02d" $counter)
    key="${padded_counter}-${filename}"
    
    echo "  Adding: ${key}"
    
    # Add the file to ConfigMap with proper indentation
    echo "  ${key}: |" >> "${OUTPUT_FILE}"
    
    # Read file and indent each line with 4 spaces
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "    ${line}" >> "${OUTPUT_FILE}"
    done < "$file"
    
    echo "" >> "${OUTPUT_FILE}"
    
    counter=$((counter + 1))
done

echo ""
echo "ConfigMap generated: ${OUTPUT_FILE}"
echo "Total guides: $((counter - 1))"
