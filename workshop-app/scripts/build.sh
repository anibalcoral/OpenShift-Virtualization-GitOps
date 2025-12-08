#!/bin/bash
# Build script for GitOps Virtualization Workshop

set -e

IMAGE_NAME="${IMAGE_NAME:-quay.io/chiaretto/gitops-virtualization-workshop}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

cd "$(dirname "$0")/.."

podman build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Dockerfile.unified .

echo ""
echo "Build complete: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To push the image, run:"
echo "  podman push ${IMAGE_NAME}:${IMAGE_TAG}"
