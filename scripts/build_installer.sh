#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_installer.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.6.1
# Purpose....: Build self-contained installer with base64 payload and version management
# Notes......: Creates a single executable installer with embedded tarball.
#              Packages src/ directory and creates distribution installer.
#              Generates .install_info metadata and .oradba.checksum for integrity.
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

# Create tarball of src directory contents (without src/ wrapper)
# First create a temporary directory to combine everything
TEMP_TAR_DIR="${BUILD_DIR}/tar_staging"
mkdir -p "$TEMP_TAR_DIR"

# Copy src contents
cp -r src/* "$TEMP_TAR_DIR/"

# Copy additional files
cp VERSION README.md LICENSE CHANGELOG.md "$TEMP_TAR_DIR/"

# Note: oradba_install.sh is already included in src/bin/

echo "Generating installation metadata template..."
# Generate install info template (will be updated during installation)
{
    echo "# OraDBA Installation Information"
    echo "# This file will be updated during installation"
    echo "# Build: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "install_date="
    echo "install_version=${VERSION}"
    echo "install_method="
    echo "install_user="
    echo "install_prefix="
} > "$TEMP_TAR_DIR/.install_info"

echo "Generating checksums..."
# Generate checksum file with SHA256 for all installed files
{
    echo "# OraDBA Installation Checksums"
    echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Version: ${VERSION}"
    echo "#"
    
    # Change to staging directory to generate relative paths
    cd "$TEMP_TAR_DIR" || exit 1
    
    # Generate checksums for all files (excluding checksum file itself)
    find bin lib sql rcv etc templates doc -type f 2>/dev/null | sort | while read -r file; do
        sha256sum "$file"
    done
    
    # Also checksum the VERSION and .install_info files
    sha256sum VERSION .install_info
    
    cd - > /dev/null || exit 1
} > "$TEMP_TAR_DIR/.oradba.checksum"

echo "Checksum file created with $(grep -c '^[^#]' "$TEMP_TAR_DIR/.oradba.checksum") entries"

# Create the final tarball
tar -czf "$PAYLOAD_FILE" \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='*.tmp' \
    -C "$TEMP_TAR_DIR" \
    .

# Clean up staging directory
rm -rf "$TEMP_TAR_DIR"

echo "Payload size: $(du -h "$PAYLOAD_FILE" | cut -f1)"

# Copy standalone installer and prepare it
echo "Preparing installer script..."
if [[ ! -f "src/bin/oradba_install.sh" ]]; then
    echo "ERROR: src/bin/oradba_install.sh not found"
    exit 1
fi

# Copy installer to output and inject version
cp "src/bin/oradba_install.sh" "$INSTALLER_OUTPUT"
sed -i.bak "s/__VERSION__/${VERSION}/g" "$INSTALLER_OUTPUT"
rm -f "${INSTALLER_OUTPUT}.bak"

# Append base64 encoded payload
echo "Creating installer with embedded payload..."
openssl base64 < "$PAYLOAD_FILE" >> "$INSTALLER_OUTPUT"

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
