#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_installer.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: Build self-contained installer with base64 payload
# Notes......: Creates a single executable installer with embedded tarball.
#              Packages srv/ directory and creates distribution installer.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

# Variables
VERSION=$(cat VERSION 2> /dev/null || echo "0.1.0")
BUILD_DIR="build"
DIST_DIR="dist"
PACKAGE_NAME="oradba-${VERSION}"
PAYLOAD_FILE="${BUILD_DIR}/${PACKAGE_NAME}.tar.gz"
INSTALLER_OUTPUT="${DIST_DIR}/oradba_install.sh"

echo "========================================="
echo "Building oradba installer v${VERSION}"
echo "========================================="

# Create directories
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Clean previous builds
rm -rf "${BUILD_DIR:?}/"*
rm -f "$INSTALLER_OUTPUT"

echo "Creating payload..."

# Create tarball of srv directory
tar -czf "$PAYLOAD_FILE" \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='*.tmp' \
    srv/ \
    VERSION \
    README.md \
    LICENSE \
    CHANGELOG.md

echo "Payload size: $(du -h "$PAYLOAD_FILE" | cut -f1)"

# Create installer script
cat > "$INSTALLER_OUTPUT" << 'INSTALLER_HEADER'
#!/usr/bin/env bash
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# Self-contained installer with embedded payload
# -----------------------------------------------------------------------
# Copyright (c) 2025 Stefan Oehrli
# Licensed under the Apache License, Version 2.0
# -----------------------------------------------------------------------

set -e

# Variables
INSTALLER_VERSION="__VERSION__"
DEFAULT_PREFIX="/opt/oradba"
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Display usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install oradba - Oracle Database Administration Toolset v${INSTALLER_VERSION}

Options:
  --prefix PATH       Installation prefix (default: $DEFAULT_PREFIX)
  --user USER         Run as specific user (requires sudo)
  --no-examples       Don't install example files
  -h, --help          Display this help message
  -v, --version       Display version information

Examples:
  $0
  $0 --prefix /usr/local/oradba
  sudo $0 --prefix /opt/oradba --user oracle

EOF
    exit 0
}

# Parse arguments
INSTALL_PREFIX="$DEFAULT_PREFIX"
INSTALL_USER=""
INSTALL_EXAMPLES=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --user)
            INSTALL_USER="$2"
            shift 2
            ;;
        --no-examples)
            INSTALL_EXAMPLES=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        -v|--version)
            echo "oradba installer version $INSTALLER_VERSION"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check permissions
if [[ ! -w "$(dirname "$INSTALL_PREFIX")" ]] && [[ "$EUID" -ne 0 ]]; then
    log_error "Installation to $INSTALL_PREFIX requires root privileges"
    log_info "Please run with sudo or choose a different prefix"
    exit 1
fi

echo "========================================="
echo "oradba Installer v${INSTALLER_VERSION}"
echo "========================================="
echo "Installation prefix: $INSTALL_PREFIX"
[[ -n "$INSTALL_USER" ]] && echo "Install user: $INSTALL_USER"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
log_info "Created temporary directory: $TEMP_DIR"

# Extract payload
log_info "Extracting payload..."
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ {print NR + 1; exit 0; }' "$0")
tail -n +${PAYLOAD_LINE} "$0" | base64 -d | tar -xz -C "$TEMP_DIR"

# Create installation directory
if [[ ! -d "$INSTALL_PREFIX" ]]; then
    log_info "Creating installation directory: $INSTALL_PREFIX"
    mkdir -p "$INSTALL_PREFIX"
fi

# Copy files
log_info "Installing files..."
cp -r "$TEMP_DIR"/* "$INSTALL_PREFIX/"

# Create logs directory
mkdir -p "$INSTALL_PREFIX/logs"

# Set ownership if user specified
if [[ -n "$INSTALL_USER" ]]; then
    log_info "Setting ownership to $INSTALL_USER"
    chown -R "$INSTALL_USER" "$INSTALL_PREFIX"
fi

# Make scripts executable
log_info "Setting permissions..."
find "$INSTALL_PREFIX/srv/bin" -type f -name "*.sh" -exec chmod +x {} \;

# Create symbolic link for oraenv.sh
if [[ -w "/usr/local/bin" ]] || [[ "$EUID" -eq 0 ]]; then
    log_info "Creating symbolic link in /usr/local/bin"
    ln -sf "$INSTALL_PREFIX/srv/bin/oraenv.sh" /usr/local/bin/oraenv 2>/dev/null || true
fi

# Installation complete
echo ""
echo "========================================="
log_info "Installation completed successfully!"
echo "========================================="
echo ""
echo "oradba has been installed to: $INSTALL_PREFIX"
echo ""
echo "To use oraenv:"
echo "  source $INSTALL_PREFIX/srv/bin/oraenv.sh [ORACLE_SID]"
echo ""
echo "Or if symbolic link was created:"
echo "  source oraenv [ORACLE_SID]"
echo ""
echo "Documentation: $INSTALL_PREFIX/README.md"
echo ""

exit 0

__PAYLOAD_BEGINS__
INSTALLER_HEADER

# Replace version placeholder
sed -i.bak "s/__VERSION__/$VERSION/g" "$INSTALLER_OUTPUT" && rm "${INSTALLER_OUTPUT}.bak"

# Append base64 encoded payload
echo "Creating installer with embedded payload..."
base64 "$PAYLOAD_FILE" >> "$INSTALLER_OUTPUT"

# Make installer executable
chmod +x "$INSTALLER_OUTPUT"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo "Installer: $INSTALLER_OUTPUT"
echo "Size: $(du -h "$INSTALLER_OUTPUT" | cut -f1)"
echo ""
echo "To install:"
echo "  $INSTALLER_OUTPUT"
echo ""
