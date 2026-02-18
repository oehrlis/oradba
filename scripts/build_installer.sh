#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_installer.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
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

# Remove MkDocs-specific files not needed in installation
rm -rf "$TEMP_TAR_DIR/doc/javascripts"
rm -rf "$TEMP_TAR_DIR/doc/stylesheets"
rm -f "$TEMP_TAR_DIR/doc/index.md"
rm -f "$TEMP_TAR_DIR/doc/oradba-user-guide.pdf" 2> /dev/null || true

# Remove runtime-generated files from payload (must remain local state)
rm -f "$TEMP_TAR_DIR/etc/oradba_homes.conf"
rm -f "$TEMP_TAR_DIR/etc/oratab"
rm -f "$TEMP_TAR_DIR/etc/sid.dummy.conf"

# Copy additional files
cp VERSION README.md LICENSE CHANGELOG.md "$TEMP_TAR_DIR/"

# If build suffix is set, update VERSION file in tarball
if [[ -n "${ORADBA_BUILD_SUFFIX}" ]]; then
    echo "${VERSION}" > "$TEMP_TAR_DIR/VERSION"
fi

# Download extension template from GitHub
echo "Downloading extension template from GitHub..."
mkdir -p templates/oradba_extension
mkdir -p "$TEMP_TAR_DIR/templates/oradba_extension"

EXTENSION_REPO="oehrlis/oradba_extension"
EXTENSION_CACHE_FILE="templates/oradba_extension/extension-template.tar.gz"
EXTENSION_VERSION_FILE="templates/oradba_extension/.version"

# Function to get latest release info from GitHub
get_latest_extension_release() {
    local api_url="https://api.github.com/repos/${EXTENSION_REPO}/releases/latest"

    # Use curl with fallback to wget
    if command -v curl &> /dev/null; then
        curl -sS "${api_url}" 2> /dev/null || echo "{}"
    elif command -v wget &> /dev/null; then
        wget -qO- "${api_url}" 2> /dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Check if we need to download a new version
DOWNLOAD_EXTENSION=false
CACHED_VERSION=""
LATEST_VERSION=""

if [[ -f "${EXTENSION_VERSION_FILE}" ]]; then
    CACHED_VERSION=$(cat "${EXTENSION_VERSION_FILE}" 2> /dev/null || echo "")
fi

echo "  Checking for latest release from ${EXTENSION_REPO}..."
RELEASE_INFO=$(get_latest_extension_release)

if [[ -n "${RELEASE_INFO}" ]] && [[ "${RELEASE_INFO}" != "{}" ]]; then
    LATEST_VERSION=$(echo "${RELEASE_INFO}" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*": *"\(.*\)".*/\1/')
    TARBALL_URL=$(echo "${RELEASE_INFO}" | grep -o '"browser_download_url": "[^"]*extension-template-[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)

    if [[ -n "${LATEST_VERSION}" ]]; then
        echo "  Latest version: ${LATEST_VERSION}"

        if [[ "${CACHED_VERSION}" != "${LATEST_VERSION}" ]] || [[ ! -f "${EXTENSION_CACHE_FILE}" ]]; then
            echo "  New version available, downloading..."
            DOWNLOAD_EXTENSION=true
        else
            echo "  Using cached version: ${CACHED_VERSION}"
        fi
    else
        echo "  Warning: Could not parse version from GitHub API"
    fi
fi

# Download if needed
if [[ "${DOWNLOAD_EXTENSION}" == "true" ]] && [[ -n "${TARBALL_URL}" ]]; then
    echo "  Downloading from: ${TARBALL_URL}"

    if command -v curl &> /dev/null; then
        curl -sS -L "${TARBALL_URL}" -o "${EXTENSION_CACHE_FILE}" || {
            echo "  Warning: Failed to download extension template"
            DOWNLOAD_EXTENSION=false
        }
    elif command -v wget &> /dev/null; then
        wget -q "${TARBALL_URL}" -O "${EXTENSION_CACHE_FILE}" || {
            echo "  Warning: Failed to download extension template"
            DOWNLOAD_EXTENSION=false
        }
    else
        echo "  Warning: Neither curl nor wget available"
        DOWNLOAD_EXTENSION=false
    fi

    if [[ "${DOWNLOAD_EXTENSION}" == "true" ]]; then
        echo "${LATEST_VERSION}" > "${EXTENSION_VERSION_FILE}"
        echo "  ✓ Downloaded extension template ${LATEST_VERSION}"
    fi
fi

# Copy extension template to staging if available
if [[ -f "${EXTENSION_CACHE_FILE}" ]]; then
    echo "  Including extension template in distribution..."
    cp "${EXTENSION_CACHE_FILE}" "$TEMP_TAR_DIR/templates/oradba_extension/extension-template.tar.gz"
    if [[ -f "${EXTENSION_VERSION_FILE}" ]]; then
        cp "${EXTENSION_VERSION_FILE}" "$TEMP_TAR_DIR/templates/oradba_extension/.version"
    fi
else
    echo "  Warning: No extension template available (installer will work, but oradba_extension.sh will need --from-github or --template)"
fi

# Substitute version in installer
echo "Substituting version ${VERSION} in oradba_install.sh..."
# Use temp file for better cross-platform compatibility
sed "s/__VERSION__/${VERSION}/g" "$TEMP_TAR_DIR/bin/oradba_install.sh" > "$TEMP_TAR_DIR/bin/oradba_install.sh.tmp"
mv "$TEMP_TAR_DIR/bin/oradba_install.sh.tmp" "$TEMP_TAR_DIR/bin/oradba_install.sh"

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

    # Generate checksums for all files (excluding checksum file itself and user-modifiable configs)
    find bin lib sql rcv etc templates doc -type f 2> /dev/null | sort | while read -r file; do
        # Skip user-modifiable configuration files
        case "$file" in
            etc/oradba_homes.conf|etc/oradba_customer.conf|etc/oradba_local.conf|etc/sid.*.conf)
                continue
                ;;
        esac
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
# Use temp file for better cross-platform compatibility
sed "s/__VERSION__/${VERSION}/g" "$INSTALLER_OUTPUT" > "$INSTALLER_OUTPUT.tmp"
mv "$INSTALLER_OUTPUT.tmp" "$INSTALLER_OUTPUT"

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
# Use temp file for better cross-platform compatibility
sed "s/SCRIPT_VERSION=\"[^\"]*\"/SCRIPT_VERSION=\"${VERSION}\"/" "$CHECK_SCRIPT_OUTPUT" > "$CHECK_SCRIPT_OUTPUT.tmp"
mv "$CHECK_SCRIPT_OUTPUT.tmp" "$CHECK_SCRIPT_OUTPUT"

# Make check script executable
chmod +x "$CHECK_SCRIPT_OUTPUT"

# Generate SHA256 checksums for distribution artifacts
echo "Generating SHA256 checksums..."

if command -v sha256sum &> /dev/null; then
    sha256sum "$DIST_TARBALL" > "${DIST_TARBALL}.sha256"
    sha256sum "$INSTALLER_OUTPUT" > "${INSTALLER_OUTPUT}.sha256"
    sha256sum "$CHECK_SCRIPT_OUTPUT" > "${CHECK_SCRIPT_OUTPUT}.sha256"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "$DIST_TARBALL" > "${DIST_TARBALL}.sha256"
    shasum -a 256 "$INSTALLER_OUTPUT" > "${INSTALLER_OUTPUT}.sha256"
    shasum -a 256 "$CHECK_SCRIPT_OUTPUT" > "${CHECK_SCRIPT_OUTPUT}.sha256"
else
    echo "Warning: Neither sha256sum nor shasum found - skipping checksum generation"
fi

if [[ -f "${DIST_TARBALL}.sha256" ]]; then
    echo "  ✓ Created ${DIST_TARBALL}.sha256"
    echo "  ✓ Created ${INSTALLER_OUTPUT}.sha256"
    echo "  ✓ Created ${CHECK_SCRIPT_OUTPUT}.sha256"
fi

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo "Distribution: $DIST_TARBALL ($(du -h "$DIST_TARBALL" | cut -f1))"
echo "Installer:    $INSTALLER_OUTPUT ($(du -h "$INSTALLER_OUTPUT" | cut -f1))"
echo "Check Script: $CHECK_SCRIPT_OUTPUT ($(du -h "$CHECK_SCRIPT_OUTPUT" | cut -f1))"
if [[ -f "${DIST_TARBALL}.sha256" ]]; then
    echo ""
    echo "SHA256 Checksums:"
    echo "  - ${DIST_TARBALL}.sha256"
    echo "  - ${INSTALLER_OUTPUT}.sha256"
    echo "  - ${CHECK_SCRIPT_OUTPUT}.sha256"
fi
echo ""
echo "To check system prerequisites:"
echo "  $CHECK_SCRIPT_OUTPUT"
echo ""
echo "To install:"
echo "  $INSTALLER_OUTPUT"
echo ""
echo "For GitHub release, upload:"
echo "  - $DIST_TARBALL"
echo "  - $DIST_TARBALL.sha256"
echo "  - $INSTALLER_OUTPUT"
echo "  - $INSTALLER_OUTPUT.sha256"
echo "  - $CHECK_SCRIPT_OUTPUT"
echo "  - $CHECK_SCRIPT_OUTPUT.sha256"
echo ""
