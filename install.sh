#!/bin/bash
set -e

# Kolumn Installation Script
INSTALL_DIR="/usr/local/bin"
REPO="schemabounce/Kolumn-deploy"
BASE_URL="https://github.com/${REPO}/releases/latest/download"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installing Kolumn...${NC}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

case $OS in
    linux) ;;
    darwin) ;;
    *) echo -e "${RED}❌ Unsupported OS: $OS${NC}"; exit 1 ;;
esac

# Download and install
VERSION_INFO=$(curl -s "https://api.github.com/repos/schemabounce/Kolumn-deploy/releases/latest")
VERSION=$(echo "$VERSION_INFO" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 | sed 's/^v//')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Failed to get latest version${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Latest version: $VERSION${NC}"

PACKAGE="kolumn-${VERSION}-${OS}-${ARCH}.tar.gz"
DOWNLOAD_URL="${BASE_URL}/${PACKAGE}"

echo -e "${YELLOW}⬇️  Downloading ${PACKAGE}...${NC}"
curl -fsSL "$DOWNLOAD_URL" -o "/tmp/${PACKAGE}"

echo -e "${YELLOW}📂 Extracting to ${INSTALL_DIR}...${NC}"
cd /tmp && tar -xzf "${PACKAGE}"

sudo mv "kolumn-${VERSION}-${OS}-${ARCH}/kolumn" "${INSTALL_DIR}/"
sudo mv "kolumn-${VERSION}-${OS}-${ARCH}/kolumn-provider-kolumn" "${INSTALL_DIR}/"
sudo chmod +x "${INSTALL_DIR}/kolumn" "${INSTALL_DIR}/kolumn-provider-kolumn"

rm -rf "/tmp/kolumn-${VERSION}-${OS}-${ARCH}" "/tmp/${PACKAGE}"

echo -e "${YELLOW}🧪 Verifying installation...${NC}"
if "${INSTALL_DIR}/kolumn" version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Kolumn ${VERSION} installed successfully!${NC}"
    echo -e "${BLUE}🎯 Try: kolumn --help${NC}"
else
    echo -e "${RED}❌ Installation verification failed${NC}"
    exit 1
fi
