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
    
    # Try GitHub API first
    LATEST_URL="https://api.github.com/repos/$REPO/releases/latest"
    LATEST_RESPONSE=$(curl -s --fail --max-time 10 "$LATEST_URL" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$LATEST_RESPONSE" ]; then
        VERSION=$(echo "$LATEST_RESPONSE" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        if [ -n "$VERSION" ]; then
            print_info "Latest version from GitHub API: $VERSION"
            return
        fi
    fi
    
    # Fallback 1: Try to get version from GitHub Pages version.json
    print_info "Trying GitHub Pages version info..."
    VERSION_JSON_URL="https://schemabounce.github.io/Kolumn-deploy/releases/latest/version.json"
    VERSION_RESPONSE=$(curl -s --fail --max-time 10 "$VERSION_JSON_URL" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$VERSION_RESPONSE" ]; then
        VERSION=$(echo "$VERSION_RESPONSE" | grep -o '"version": "[^"]*' | cut -d'"' -f4)
        if [ -n "$VERSION" ] && [ "$VERSION" != "null" ]; then
            # Ensure version has v prefix
            if [[ ! "$VERSION" =~ ^v ]]; then
                VERSION="v$VERSION"
            fi
            print_info "Latest version from GitHub Pages: $VERSION"
            return
        fi
    fi
    
    # Fallback 2: Try to detect from GitHub releases page
    print_info "Trying GitHub releases page..."
    RELEASES_PAGE=$(curl -s --fail --max-time 10 "https://github.com/$REPO/releases" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$RELEASES_PAGE" ]; then
        VERSION=$(echo "$RELEASES_PAGE" | grep -o 'releases/tag/v[0-9][^"]*' | head -1 | sed 's/releases\/tag\///')
        if [ -n "$VERSION" ]; then
            print_info "Latest version from releases page: $VERSION"
            return
        fi
    fi
    
    # Fallback 3: Use current development version
    print_warning "Could not determine latest version from any source"
    print_info "This usually means Kolumn is in early development"
    
    # Try a reasonable default based on current timestamp
    DEV_VERSION="v0.1.0-dev.$(date +%Y%m%d)"
    
    print_info "Using development version: $DEV_VERSION"
    print_info "Note: You may want to build from source instead:"
    echo "  git clone https://github.com/schemabounce/kolumn"
    echo "  cd kolumn && make build"
    
    VERSION="$DEV_VERSION"
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
    
    if [ "$OS" = "windows" ]; then
        TMP_BINARY="${TMP_BINARY}.exe"
    fi
    
    # Try to download the binary with better error handling
    HTTP_CODE=$(curl -w "%{http_code}" -fsSL "$DOWNLOAD_URL" -o "$TMP_BINARY" 2>/dev/null)
    CURL_EXIT_CODE=$?
    
    if [ $CURL_EXIT_CODE -ne 0 ] || [ "$HTTP_CODE" -ge 400 ]; then
        case "$HTTP_CODE" in
            404)
                print_error "Binary not found for $VERSION on $OS/$ARCH platform.

📋 This usually means:
   • The release hasn't been published yet
   • Your platform ($OS/$ARCH) isn't supported in this release
   • The version ($VERSION) doesn't exist

💡 Alternative installation methods:
   1. 🔧 Build from source:
      git clone https://github.com/schemabounce/kolumn
      cd kolumn && make build
      sudo mv bin/kolumn /usr/local/bin/

   2. 📦 Check available releases:
      https://github.com/$REPO/releases

   3. 🐛 Report issues:
      https://github.com/$REPO/issues"
                ;;
            403)
                print_error "Access denied. This might be a rate limit issue.
Please wait a few minutes and try again."
                ;;
            *)
                print_error "Download failed (HTTP $HTTP_CODE). 
Please check your internet connection and try again."
                ;;
        esac
    fi
    
    # Verify file was downloaded and has content
    if [ ! -f "$TMP_BINARY" ] || [ ! -s "$TMP_BINARY" ]; then
        print_error "Downloaded file is empty or doesn't exist"
    fi
    
    # Make executable (not needed on Windows)
    if [ "$OS" != "windows" ]; then
        chmod +x "$TMP_BINARY"
    fi
    
    # Verify binary works - more lenient check
    if ! "$TMP_BINARY" --help >/dev/null 2>&1; then
        print_warning "Binary validation failed, but continuing installation..."
        print_info "You can verify after installation with: kolumn version"
    else
        print_success "Binary validation passed!"
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