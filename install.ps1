# Kolumn Installation Script for Windows
# Usage: irm https://schemabounce.github.io/Kolumn-deploy/install.ps1 | iex

$ErrorActionPreference = "Stop"

$REPO = "schemabounce/Kolumn-deploy"
$BASE_URL = "https://github.com/$REPO/releases/latest/download"
$VERSION_URL = "https://schemabounce.github.io/Kolumn-deploy/releases/latest/version.json"

# Default install directory
$INSTALL_DIR = "$env:LOCALAPPDATA\Kolumn"

Write-Host "`n  Kolumn Installer for Windows" -ForegroundColor Yellow
Write-Host "  ==============================`n" -ForegroundColor Yellow

# Detect architecture
$ARCH = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
} else {
    Write-Host "  Unsupported: 32-bit Windows is not supported" -ForegroundColor Red
    exit 1
}

Write-Host "  Detected architecture: $ARCH" -ForegroundColor Cyan

# Get latest version
Write-Host "  Fetching latest version..." -ForegroundColor Cyan
try {
    $versionInfo = Invoke-RestMethod -Uri $VERSION_URL -UseBasicParsing
    $VERSION = $versionInfo.version
    if (-not $VERSION) {
        throw "Version not found in response"
    }
} catch {
    Write-Host "  Failed to get latest version: $_" -ForegroundColor Red
    exit 1
}

Write-Host "  Latest version: $VERSION" -ForegroundColor Green

# Create install directory if it doesn't exist
if (-not (Test-Path $INSTALL_DIR)) {
    Write-Host "  Creating install directory: $INSTALL_DIR" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

# Download executable
$PACKAGE = "kolumn-windows-$ARCH.exe"
$DOWNLOAD_URL = "$BASE_URL/$PACKAGE"
$DEST_PATH = "$INSTALL_DIR\kolumn.exe"

Write-Host "  Downloading $PACKAGE..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $DEST_PATH -UseBasicParsing
} catch {
    Write-Host "  Failed to download: $_" -ForegroundColor Red
    exit 1
}

# Also download the provider if available
$PROVIDER_PACKAGE = "kolumn-provider-kolumn-windows-$ARCH.exe"
$PROVIDER_URL = "$BASE_URL/$PROVIDER_PACKAGE"
$PROVIDER_DEST = "$INSTALL_DIR\kolumn-provider-kolumn.exe"

Write-Host "  Downloading provider plugin..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $PROVIDER_URL -OutFile $PROVIDER_DEST -UseBasicParsing -ErrorAction SilentlyContinue
    Write-Host "  Provider plugin downloaded" -ForegroundColor Green
} catch {
    Write-Host "  Provider plugin not available (optional)" -ForegroundColor Yellow
}

# Add to PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    Write-Host "  Adding $INSTALL_DIR to PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$INSTALL_DIR", "User")
    $env:Path = "$env:Path;$INSTALL_DIR"
    Write-Host "  PATH updated (restart terminal for full effect)" -ForegroundColor Yellow
}

# Verify installation
Write-Host "  Verifying installation..." -ForegroundColor Cyan
try {
    $versionOutput = & $DEST_PATH version 2>&1
    Write-Host "`n  Kolumn $VERSION installed successfully!" -ForegroundColor Green
    Write-Host "  Location: $DEST_PATH" -ForegroundColor Cyan
    Write-Host "`n  To get started, run: kolumn --help" -ForegroundColor Yellow
    Write-Host "  (You may need to restart your terminal)`n" -ForegroundColor Yellow
} catch {
    Write-Host "  Installation verification failed: $_" -ForegroundColor Red
    exit 1
}
