#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_installer.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.18
# Revision...: 0.7.9
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
# Support dev/test builds with suffix (e.g., ORADBA_BUILD_SUFFIX="-dev" make build)
if [[ -n "${ORADBA_BUILD_SUFFIX}" ]]; then
    VERSION="${VERSION}${ORADBA_BUILD_SUFFIX}"
fi
BUILD_DIR="build"
DIST_DIR="dist"
PACKAGE_NAME="oradba-${VERSION}"
DIST_TARBALL="${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
INSTALLER_OUTPUT="${DIST_DIR}/oradba_install.sh"
CHECK_SCRIPT_OUTPUT="${DIST_DIR}/oradba_check.sh"

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

# If build suffix is set, update VERSION file in tarball
if [[ -n "${ORADBA_BUILD_SUFFIX}" ]]; then
    echo "${VERSION}" > "$TEMP_TAR_DIR/VERSION"
fi

# Generate extension template tarballs
echo "Generating extension template tarballs..."
mkdir -p "$TEMP_TAR_DIR/templates/extensions"

# Create tarball for customer extension example
if [[ -d "doc/examples/extensions/customer" ]]; then
    echo "  Creating customer-extension-template.tar.gz..."
    (cd doc/examples/extensions && tar czf - customer) > "$TEMP_TAR_DIR/templates/extensions/customer-extension-template.tar.gz"
else
    echo "  Warning: doc/examples/extensions/customer not found"
fi

# Substitute version in installer
echo "Substituting version ${VERSION} in oradba_install.sh..."
sed -i.bak "s/__VERSION__/${VERSION}/g" "$TEMP_TAR_DIR/bin/oradba_install.sh"
rm -f "$TEMP_TAR_DIR/bin/oradba_install.sh.bak"

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

# Create the distribution tarball (used for both GitHub releases and installer payload)
echo "Creating distribution tarball..."
tar -czf "$DIST_TARBALL" \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='*.tmp' \
    -C "$TEMP_TAR_DIR" \
    .

# Clean up staging directory
rm -rf "$TEMP_TAR_DIR"

echo "Distribution tarball: $(du -h "$DIST_TARBALL" | cut -f1)"

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

# Append base64 encoded payload (reusing the distribution tarball)
echo "Creating installer with embedded payload..."
openssl base64 < "$DIST_TARBALL" >> "$INSTALLER_OUTPUT"

# Make installer executable
chmod +x "$INSTALLER_OUTPUT"

# Copy standalone check script and prepare it
echo "Preparing check script..."
if [[ ! -f "src/bin/oradba_check.sh" ]]; then
    echo "ERROR: src/bin/oradba_check.sh not found"
    exit 1
fi

# Copy check script to output and inject version
cp "src/bin/oradba_check.sh" "$CHECK_SCRIPT_OUTPUT"
sed -i.bak "s/SCRIPT_VERSION=\"[^\"]*\"/SCRIPT_VERSION=\"${VERSION}\"/" "$CHECK_SCRIPT_OUTPUT"
rm -f "${CHECK_SCRIPT_OUTPUT}.bak"

# Make check script executable
chmod +x "$CHECK_SCRIPT_OUTPUT"

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo "Distribution: $DIST_TARBALL ($(du -h "$DIST_TARBALL" | cut -f1))"
echo "Installer:    $INSTALLER_OUTPUT ($(du -h "$INSTALLER_OUTPUT" | cut -f1))"
echo "Check Script: $CHECK_SCRIPT_OUTPUT ($(du -h "$CHECK_SCRIPT_OUTPUT" | cut -f1))"
echo ""
echo "To check system prerequisites:"
echo "  $CHECK_SCRIPT_OUTPUT"
echo ""
echo "To install:"
echo "  $INSTALLER_OUTPUT"
echo ""
echo "For GitHub release, upload:"
echo "  - $DIST_TARBALL"
echo "  - $INSTALLER_OUTPUT"
echo "  - $CHECK_SCRIPT_OUTPUT"
echo ""
