#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if version parameter is provided
if [ -z "$1" ]; then
    log_error "Version parameter is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 0.0.367"
    exit 1
fi

VERSION="$1"
TEMP_DIR="/tmp/copilot-install-$$"
DOWNLOAD_URL="https://github.com/github/copilot-cli/releases/download/v${VERSION}/copilot-linux-x64.tar.gz"
INSTALL_DIR="/usr/local/bin"

# Validate version exists
log "Checking if version ${VERSION} exists..."
RELEASE_API_URL="https://api.github.com/repos/github/copilot-cli/releases/tags/v${VERSION}"

RELEASE_DATA=$(curl -sf "${RELEASE_API_URL}")
if [ -z "$RELEASE_DATA" ]; then
    log_error "Version ${VERSION} not found in GitHub releases"
    echo ""
    log "Available recent versions:"
    curl -s "https://api.github.com/repos/github/copilot-cli/releases?per_page=10" | grep '"tag_name":' | sed 's/.*"v\([^"]*\)".*/  \1/' | head -10
    echo ""
    exit 1
fi

# Check if Linux x64 asset exists
if ! echo "$RELEASE_DATA" | grep -q "copilot-linux-x64.tar.gz"; then
    log_error "Linux x64 binary not available for version ${VERSION}"
    echo ""
    log "This version exists but has no downloadable binaries"
    log "Checking for versions with available binaries..."
    echo ""
    
    # Find versions with assets
    for v in $(curl -s "https://api.github.com/repos/github/copilot-cli/releases?per_page=20" | grep '"tag_name":' | sed 's/.*"v\([^"]*\)".*/\1/'); do
        if curl -sf "https://api.github.com/repos/github/copilot-cli/releases/tags/v${v}" | grep -q "copilot-linux-x64.tar.gz"; then
            echo "  ${v} ✓"
        fi
    done | head -10
    echo ""
    exit 1
fi

log "Installing GitHub Copilot CLI version ${VERSION}"

# Create temporary directory
mkdir -p "${TEMP_DIR}"
cd "${TEMP_DIR}"

# Download the release
log "Downloading from ${DOWNLOAD_URL}"
if ! wget -q --show-progress "${DOWNLOAD_URL}"; then
    log_error "Failed to download GitHub Copilot CLI v${VERSION}"
    log_error "The release exists but the download failed"
    log_error "Please check your internet connection or try again later"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Extract the archive
log "Extracting archive..."
tar -xzf "copilot-linux-x64.tar.gz"

# Check if binary exists
if [ ! -f "copilot" ]; then
    log_error "Binary 'copilot' not found in the archive"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Check if we need sudo
if [ -w "${INSTALL_DIR}" ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
    log_warning "Sudo required to install to ${INSTALL_DIR}"
fi

# Remove old version if exists
if [ -f "${INSTALL_DIR}/copilot" ]; then
    log "Removing old version..."
    ${SUDO_CMD} rm -f "${INSTALL_DIR}/copilot"
fi

# Install the binary
log "Installing to ${INSTALL_DIR}..."
${SUDO_CMD} mv copilot "${INSTALL_DIR}/"
${SUDO_CMD} chmod +x "${INSTALL_DIR}/copilot"

# Cleanup
cd /
rm -rf "${TEMP_DIR}"

# Verify installation
if command -v copilot &> /dev/null; then
    INSTALLED_VERSION=$(copilot --version | head -1)
    log "Successfully installed GitHub Copilot CLI"
    log "Version: ${INSTALLED_VERSION}"
    echo ""
    echo "To get started, run:"
    echo "  copilot          # Start interactive mode"
    echo "  copilot --help   # Show help"
else
    log_error "Installation failed - copilot command not found in PATH"
    exit 1
fi
