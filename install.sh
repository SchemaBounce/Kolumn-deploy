#!/bin/bash
set -e

# Kolumn Installation Script
# Usage: curl -fsSL https://schemabounce.github.io/kolumn/install.sh | bash

REPO="schemabounce/Kolumn-deploy"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="kolumn"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    if ! command_exists curl; then
        print_error "curl is required but not installed. Please install curl and try again."
    fi
    
    if ! command_exists grep; then
        print_error "grep is required but not installed."
    fi
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux*) OS="linux" ;;
        darwin*) OS="darwin" ;;
        mingw* | msys* | cygwin*) OS="windows" ;;
        *) print_error "Unsupported operating system: $OS" ;;
    esac
    
    case $ARCH in
        x86_64 | amd64) ARCH="amd64" ;;
        arm64 | aarch64) ARCH="arm64" ;;
        armv7* | armv6*) ARCH="arm" ;;
        i386 | i686) ARCH="386" ;;
        *) print_error "Unsupported architecture: $ARCH" ;;
    esac
    
    print_info "Detected platform: $OS/$ARCH"
}

# Get latest release version
get_latest_version() {
    print_info "Fetching latest Kolumn version..."
    
    LATEST_URL="https://api.github.com/repos/$REPO/releases/latest"
    LATEST_RESPONSE=$(curl -s "$LATEST_URL")
    
    if [ $? -ne 0 ]; then
        print_warning "Failed to fetch latest release information, using default version"
        VERSION="v0.1.0"
        return
    fi
    
    VERSION=$(echo "$LATEST_RESPONSE" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    
    if [ -z "$VERSION" ]; then
        print_warning "Could not determine latest version from releases, using default"
        VERSION="v0.1.0"
        return
    fi
    
    print_info "Latest version: $VERSION"
}

# Download and verify binary
download_binary() {
    BINARY_FILE="kolumn-${OS}-${ARCH}"
    if [ "$OS" = "windows" ]; then
        BINARY_FILE="${BINARY_FILE}.exe"
    fi
    
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$BINARY_FILE"
    
    print_info "Downloading from: $DOWNLOAD_URL"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    TMP_BINARY="$TMP_DIR/$BINARY_NAME"
    
    # Try to download the binary
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_BINARY" 2>/dev/null; then
        print_error "Binary not available for download yet. Kolumn is in early beta development.

📋 To install Kolumn:
   1. Clone the repository: git clone https://github.com/schemabounce/kolumn
   2. Build from source: cd kolumn && go build -o kolumn ./cmd/kolumn
   3. Move to PATH: sudo mv kolumn /usr/local/bin/

📖 Documentation: https://schemabounce.com/kolumn/docs
🐛 Issues: https://github.com/schemabounce/Kolumn-deploy/issues"
    fi
    
    if [ "$OS" = "windows" ]; then
        TMP_BINARY="${TMP_BINARY}.exe"
    fi
    
    # Download binary
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_BINARY"; then
        print_error "Failed to download Kolumn binary"
    fi
    
    # Make executable (not needed on Windows)
    if [ "$OS" != "windows" ]; then
        chmod +x "$TMP_BINARY"
    fi
    
    # Verify binary works
    if ! "$TMP_BINARY" version >/dev/null 2>&1; then
        print_warning "Downloaded binary failed version check, but continuing..."
    fi
    
    echo "$TMP_BINARY"
}

# Install binary
install_binary() {
    local tmp_binary="$1"
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    
    if [ "$OS" = "windows" ]; then
        install_path="${install_path}.exe"
    fi
    
    print_info "Installing to $install_path..."
    
    # Check if we need sudo
    if [ ! -w "$INSTALL_DIR" ]; then
        if command_exists sudo; then
            print_warning "Installing to $INSTALL_DIR requires sudo privileges"
            sudo mv "$tmp_binary" "$install_path"
        else
            print_error "Cannot write to $INSTALL_DIR and sudo is not available"
        fi
    else
        mv "$tmp_binary" "$install_path"
    fi
    
    print_success "Kolumn installed successfully!"
}

# Verify installation
verify_installation() {
    if command_exists kolumn; then
        INSTALLED_VERSION=$(kolumn version 2>/dev/null | grep -o 'v[0-9][^[:space:]]*' | head -1 || echo "unknown")
        print_success "Installation verified! Kolumn $INSTALLED_VERSION is ready to use."
        
        echo ""
        print_info "Next steps:"
        echo "  • Run 'kolumn --help' to see available commands"
        echo "  • Run 'kolumn init' to create a new project"
        echo "  • Visit https://docs.kolumn.com for documentation"
        
    else
        print_warning "Installation completed but 'kolumn' command not found in PATH"
        print_info "You may need to restart your shell or add $INSTALL_DIR to your PATH"
    fi
}

# Cleanup function
cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main installation flow
main() {
    echo ""
    print_info "🚀 Kolumn Installation Script"
    echo ""
    
    check_dependencies
    detect_platform
    get_latest_version
    
    tmp_binary=$(download_binary)
    install_binary "$tmp_binary"
    verify_installation
    
    echo ""
    print_success "🎉 Installation complete!"
}

# Run main function
main "$@"