#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_installer.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.3.0
# Purpose....: Build self-contained installer with base64 payload
# Notes......: Creates a single executable installer with embedded tarball.
#              Packages src/ directory and creates distribution installer.
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

# Create installer script
cat > "$INSTALLER_OUTPUT" << 'INSTALLER_HEADER'
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: __VERSION__
# Purpose....: Self-contained installer with embedded payload
# Notes......: This installer can automatically detect ORACLE_BASE and ORACLE_HOME
#              to determine the installation prefix. Default: ${ORACLE_BASE}/local/oradba
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# Variables
INSTALLER_VERSION="__VERSION__"
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine default installation prefix
determine_default_prefix() {
    # Priority 1: ORACLE_BASE is set
    if [[ -n "${ORACLE_BASE}" ]]; then
        echo "${ORACLE_BASE}/local/oradba"
        return 0
    fi
    
    # Priority 2: Derive from ORACLE_HOME
    if [[ -n "${ORACLE_HOME}" ]]; then
        # Try orabasetab first
        if [[ -f "${ORACLE_HOME}/install/orabasetab" ]]; then
            local oracle_base
            oracle_base=$(grep "^${ORACLE_HOME}:" "${ORACLE_HOME}/install/orabasetab" 2>/dev/null | cut -d: -f2)
            if [[ -n "$oracle_base" ]]; then
                echo "${oracle_base}/local/oradba"
                return 0
            fi
        fi
        
        # Try envVars.properties
        if [[ -f "${ORACLE_HOME}/install/envVars.properties" ]]; then
            local oracle_base
            oracle_base=$(grep "^ORACLE_BASE=" "${ORACLE_HOME}/install/envVars.properties" 2>/dev/null | cut -d= -f2)
            if [[ -n "$oracle_base" ]]; then
                echo "${oracle_base}/local/oradba"
                return 0
            fi
        fi
        
        # Fallback: derive from ORACLE_HOME path (e.g., /opt/oracle/product/... -> /opt/oracle)
        local derived_base
        derived_base="$(dirname "$(dirname "$ORACLE_HOME")")"
        if [[ -n "$derived_base" ]]; then
            echo "${derived_base}/local/oradba"
            return 0
        fi
    fi
    
    # Priority 3: Try to get ORACLE_HOME from oratab (use first SID)
    for oratab_file in /etc/oratab /var/opt/oracle/oratab; do
        if [[ -f "$oratab_file" ]]; then
            local first_home
            first_home=$(grep -v "^#" "$oratab_file" | grep -v "^$" | head -1 | cut -d: -f2)
            if [[ -n "$first_home" && -d "$first_home" ]]; then
                # Try orabasetab
                if [[ -f "${first_home}/install/orabasetab" ]]; then
                    local oracle_base
                    oracle_base=$(grep "^${first_home}:" "${first_home}/install/orabasetab" 2>/dev/null | cut -d: -f2)
                    if [[ -n "$oracle_base" ]]; then
                        echo "${oracle_base}/local/oradba"
                        return 0
                    fi
                fi
                
                # Try envVars.properties
                if [[ -f "${first_home}/install/envVars.properties" ]]; then
                    local oracle_base
                    oracle_base=$(grep "^ORACLE_BASE=" "${first_home}/install/envVars.properties" 2>/dev/null | cut -d= -f2)
                    if [[ -n "$oracle_base" ]]; then
                        echo "${oracle_base}/local/oradba"
                        return 0
                    fi
                fi
                
                # Fallback: derive from path
                local derived_base
                derived_base="$(dirname "$(dirname "$first_home")")"
                if [[ -n "$derived_base" ]]; then
                    echo "${derived_base}/local/oradba"
                    return 0
                fi
            fi
        fi
    done
    
    # Priority 4: Fallback to HOME
    echo "${HOME}/local/oradba"
}

DEFAULT_PREFIX=$(determine_default_prefix)

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

# Check and create base directory if needed
INSTALL_BASE_DIR="$(dirname "$INSTALL_PREFIX")"
if [[ ! -d "$INSTALL_BASE_DIR" ]]; then
    log_info "Base directory does not exist: $INSTALL_BASE_DIR"
    if mkdir -p "$INSTALL_BASE_DIR" 2>/dev/null; then
        log_info "Created base directory: $INSTALL_BASE_DIR"
    else
        log_error "Cannot create base directory: $INSTALL_BASE_DIR"
        log_info "Please create it manually or run with appropriate privileges"
        log_info "Or use --prefix to specify a different location"
        exit 1
    fi
fi

# Check permissions
if [[ ! -w "$INSTALL_BASE_DIR" ]] && [[ "$EUID" -ne 0 ]]; then
    log_error "Installation to $INSTALL_PREFIX requires root privileges"
    log_info "The base directory $INSTALL_BASE_DIR is not writable"
    log_info "Please run with sudo or choose a different prefix with --prefix"
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

# Decode base64 (use --decode for cross-platform compatibility)
tail -n +${PAYLOAD_LINE} "$0" | base64 --decode | tar -xz -C "$TEMP_DIR"

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
find "$INSTALL_PREFIX/bin" -type f -name "*.sh" -exec chmod +x {} \;

# Create symbolic link for oraenv.sh
if [[ -w "/usr/local/bin" ]] || [[ "$EUID" -eq 0 ]]; then
    log_info "Creating symbolic link in /usr/local/bin"
    ln -sf "$INSTALL_PREFIX/bin/oraenv.sh" /usr/local/bin/oraenv 2>/dev/null || true
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
echo "  source $INSTALL_PREFIX/bin/oraenv.sh [ORACLE_SID]"
echo ""
echo "Or if symbolic link was created:"
echo "  source oraenv [ORACLE_SID]"
echo ""
echo "Documentation: $INSTALL_PREFIX/README.md"
echo ""

exit 0

__PAYLOAD_BEGINS__
INSTALLER_HEADER

# Replace version placeholder (use a temp file for portability)
echo "Injecting version number..."
sed "s/__VERSION__/${VERSION}/g" "$INSTALLER_OUTPUT" > "${INSTALLER_OUTPUT}.tmp"
mv "${INSTALLER_OUTPUT}.tmp" "$INSTALLER_OUTPUT"

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
