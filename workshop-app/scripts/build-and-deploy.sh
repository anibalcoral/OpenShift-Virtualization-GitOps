#!/bin/bash

set -e

echo "========================================"
echo "Build e Deploy Completo"
echo "========================================"
echo

if [ -z "$1" ]; then
    # Default image name if not provided
    IMAGE_NAME="quay.io/chiaretto/workshop-userroom:latest"
else
    IMAGE_NAME=$1
fi


echo "Passo 1: Build da imagem"
echo "------------------------"
./scripts/build.sh "$IMAGE_NAME"

echo "Passo 2: Push da imagem" 
echo "-----------------------"
podman push "$IMAGE_NAME"

echo "Passo 3: Deploy no OpenShift"
echo "----------------------------"
./scripts/deploy.sh "$IMAGE_NAME"

echo
echo "✓ Build e deploy concluídos!"

echo "Rollout deployment..."
oc rollout restart deployment/gitops-workshop -n workshop-gitops
oc rollout status deployment/gitops-workshop -n workshop-gitops