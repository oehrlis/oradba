#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: __VERSION__
# Purpose....: Universal installer for oradba toolset
# Notes......: Can install from embedded payload, local tarball, or GitHub releases.
#              When distributed with embedded payload, provides self-extracting installer.
#              When installed (without payload), can be used for --local, --github, --update.
#              Default installation prefix: ${ORACLE_BASE}/local/oradba
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

Installation Modes:
  Default             Install from embedded payload (if available)
  --local PATH        Install from local tarball file
  --github            Install latest release from GitHub
  --github --version  Install specific version from GitHub

Options:
  --prefix PATH       Installation prefix (default: $DEFAULT_PREFIX)
  --user USER         Run as specific user (requires sudo)
  --version VERSION   Specify version for --github mode
  --no-examples       Don't install example files
  -h, --help          Display this help message
  -v, --show-version  Display installer version information

Examples:
  # Install from embedded payload (if available)
  $0
  
  # Install from local tarball (air-gapped)
  $0 --local /tmp/oradba-0.6.1.tar.gz
  
  # Install latest from GitHub
  $0 --github
  
  # Install specific version from GitHub
  $0 --github --version 0.6.0
  
  # Custom installation prefix
  $0 --prefix /usr/local/oradba
  
  # Install as different user
  sudo $0 --prefix /opt/oradba --user oracle

EOF
    exit 0
}

# Check mandatory system tools
check_required_tools() {
    local requirements_met=true
    
    echo "Checking Required Tools"
    echo "-----------------------"
    
    # Mandatory tools
    local required_tools=(
        "bash:Bash shell"
        "tar:Archive extraction"
        "awk:Text processing"
        "sed:Stream editor"
        "grep:Pattern matching"
    )
    
    # Check for shasum or sha256sum (platform dependent)
    if command -v sha256sum >/dev/null 2>&1; then
        log_info "sha256sum found (checksum verification)"
    elif command -v shasum >/dev/null 2>&1; then
        log_info "shasum found (checksum verification)"
    else
        log_error "Neither sha256sum nor shasum found - required for checksum verification"
        requirements_met=false
    fi
    
    # Check base64 (needed for embedded payload)
    if [[ "$INSTALL_MODE" == "embedded" ]]; then
        if command -v base64 >/dev/null 2>&1; then
            log_info "base64 found (payload decoding)"
        else
            log_error "base64 not found - required for embedded payload"
            requirements_met=false
        fi
    fi
    
    # Check download tools (needed for GitHub mode)
    if [[ "$INSTALL_MODE" == "github" ]]; then
        if command -v curl >/dev/null 2>&1; then
            log_info "curl found (GitHub downloads)"
        elif command -v wget >/dev/null 2>&1; then
            log_info "wget found (GitHub downloads)"
        else
            log_error "Neither curl nor wget found - required for GitHub downloads"
            requirements_met=false
        fi
    fi
    
    # Check each required tool
    for tool_info in "${required_tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        
        if command -v "$tool" >/dev/null 2>&1; then
            log_info "$tool found ($desc)"
        else
            log_error "$tool not found - required for $desc"
            requirements_met=false
        fi
    done
    
    echo ""
    
    if [[ "$requirements_met" == "false" ]]; then
        log_error "Required tools missing. Please install missing components."
        return 1
    fi
    
    return 0
}

# Check optional tools
check_optional_tools() {
    echo "Checking Optional Tools"
    echo "-----------------------"
    
    local warnings=0
    
    # Check for rlwrap (optional but recommended)
    if command -v rlwrap >/dev/null 2>&1; then
        local rlwrap_version
        rlwrap_version=$(rlwrap -v 2>&1 | head -1 || echo "unknown")
        log_info "rlwrap found: ${rlwrap_version}"
    else
        log_warn "rlwrap not found (optional)"
        echo "  Many oradba aliases (sqh, rman, etc.) provide enhanced"
        echo "  readline support with rlwrap. Install for better CLI experience."
        echo "  Install: yum install rlwrap | apt install rlwrap | brew install rlwrap"
        ((warnings++)) || true  # Prevent set -e from exiting on arithmetic
        echo ""
    fi
    
    # Check for less (optional pager)
    if command -v less >/dev/null 2>&1; then
        log_info "less found (paging support)"
    else
        log_warn "less not found (optional)"
        echo "  Some scripts use 'less' for paging output."
        ((warnings++)) || true  # Prevent set -e from exiting on arithmetic
    fi
    
    echo ""
    
    if [[ $warnings -gt 0 ]]; then
        log_info "Optional tools missing: $warnings"
        log_info "Installation will continue, but some features may be limited"
    else
        log_info "All optional tools available"
    fi
    
    echo ""
    return 0  # Explicitly return success
}

# Check disk space
check_disk_space() {
    local install_dir="$1"
    local required_mb=100
    
    echo "Checking Disk Space"
    echo "-------------------"
    
    # Get the directory to check (use parent if target doesn't exist)
    local check_dir="$install_dir"
    if [[ ! -d "$check_dir" ]]; then
        check_dir="$(dirname "$install_dir")"
        # Keep going up until we find an existing directory
        while [[ ! -d "$check_dir" ]] && [[ "$check_dir" != "/" ]]; do
            check_dir="$(dirname "$check_dir")"
        done
    fi
    
    log_info "Checking space in: $check_dir"
    
    # Get available space in MB (cross-platform)
    local available_mb
    if command -v df >/dev/null 2>&1; then
        # Try to get available space
        available_mb=$(df -Pm "$check_dir" 2>/dev/null | awk 'NR==2 {print $4}')
        
        if [[ -z "$available_mb" ]] || ! [[ "$available_mb" =~ ^[0-9]+$ ]]; then
            log_warn "Could not determine available disk space"
            return 0  # Continue anyway
        fi
        
        log_info "Available space: ${available_mb} MB"
        log_info "Required space: ${required_mb} MB"
        
        if [[ $available_mb -lt $required_mb ]]; then
            log_error "Insufficient disk space"
            log_error "Available: ${available_mb} MB, Required: ${required_mb} MB"
            return 1
        fi
        
        log_info "Sufficient disk space available"
    else
        log_warn "df command not found - cannot verify disk space"
    fi
    
    echo ""
    return 0
}

# Check write permissions
check_permissions() {
    local install_dir="$1"
    
    echo "Checking Permissions"
    echo "--------------------"
    
    # Check if we need to create parent directories
    local parent_dir="$(dirname "$install_dir")"
    
    if [[ -d "$install_dir" ]]; then
        # Directory exists, check if writable
        if [[ -w "$install_dir" ]]; then
            log_info "Installation directory is writable: $install_dir"
        else
            log_error "Installation directory exists but is not writable: $install_dir"
            log_info "Run with sudo or choose a different --prefix"
            return 1
        fi
    elif [[ -d "$parent_dir" ]]; then
        # Parent exists, check if we can create subdirectory
        if [[ -w "$parent_dir" ]]; then
            log_info "Parent directory is writable: $parent_dir"
            log_info "Will create: $install_dir"
        else
            log_error "Cannot create installation directory (parent not writable)"
            log_error "Parent: $parent_dir"
            log_info "Run with sudo or choose a different --prefix"
            return 1
        fi
    else
        # Need to create parent directories
        log_info "Will create directory tree: $install_dir"
        
        # Find first existing parent
        local test_dir="$parent_dir"
        while [[ ! -d "$test_dir" ]] && [[ "$test_dir" != "/" ]]; do
            test_dir="$(dirname "$test_dir")"
        done
        
        if [[ -w "$test_dir" ]]; then
            log_info "Base directory is writable: $test_dir"
        else
            log_error "Cannot create installation directory tree"
            log_error "Base directory not writable: $test_dir"
            log_info "Run with sudo or choose a different --prefix"
            return 1
        fi
    fi
    
    echo ""
    return 0
}

# Run all pre-flight checks
run_preflight_checks() {
    local install_dir="$1"
    
    echo "========================================="
    echo "Pre-flight Checks"
    echo "========================================="
    echo ""
    
    # Check required tools
    if ! check_required_tools; then
        exit 1
    fi
    
    # Check optional tools (warnings only)
    check_optional_tools
    
    # Check disk space
    if ! check_disk_space "$install_dir"; then
        exit 1
    fi
    
    # Check permissions
    if ! check_permissions "$install_dir"; then
        exit 1
    fi
    
    log_info "All pre-flight checks passed"
    echo "========================================="
    echo ""
}

# Parse arguments
INSTALL_PREFIX="$DEFAULT_PREFIX"
INSTALL_USER=""
INSTALL_EXAMPLES=true
INSTALL_MODE="auto"  # auto, embedded, local, github
LOCAL_TARBALL=""
GITHUB_VERSION=""

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
        --local)
            INSTALL_MODE="local"
            LOCAL_TARBALL="$2"
            shift 2
            ;;
        --github)
            INSTALL_MODE="github"
            shift
            ;;
        --version)
            GITHUB_VERSION="$2"
            shift 2
            ;;
        --no-examples)
            INSTALL_EXAMPLES=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        -v|--show-version)
            echo "oradba installer version $INSTALLER_VERSION"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate arguments
if [[ "$INSTALL_MODE" == "local" ]] && [[ -z "$LOCAL_TARBALL" ]]; then
    log_error "--local requires a path to tarball file"
    usage
fi

if [[ -n "$GITHUB_VERSION" ]] && [[ "$INSTALL_MODE" != "github" ]]; then
    log_error "--version can only be used with --github"
    usage
fi

# Auto-detect installation mode
if [[ "$INSTALL_MODE" == "auto" ]]; then
    # Check if payload marker exists in this script
    if grep -q "^__PAYLOAD_BEGINS__" "$0" 2>/dev/null; then
        INSTALL_MODE="embedded"
        log_info "Detected embedded payload"
    else
        log_error "No embedded payload found and no installation mode specified"
        log_error "Use --local or --github to specify installation source"
        exit 1
    fi
fi

# Extract from embedded payload
extract_embedded_payload() {
    log_info "Extracting embedded payload..."
    local payload_line
    payload_line=$(awk '/^__PAYLOAD_BEGINS__/ {print NR + 1; exit 0; }' "$0")
    
    if [[ -z "$payload_line" ]]; then
        log_error "Payload marker not found in installer"
        return 1
    fi
    
    # Decode base64 (use --decode for cross-platform compatibility)
    tail -n +${payload_line} "$0" | base64 --decode | tar -xz -C "$TEMP_DIR"
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to extract embedded payload"
        return 1
    fi
    
    log_info "Embedded payload extracted successfully"
    return 0
}

# Extract from local tarball
extract_local_tarball() {
    local tarball="$1"
    
    log_info "Validating local tarball: $tarball"
    
    # Check if file exists
    if [[ ! -f "$tarball" ]]; then
        log_error "Tarball not found: $tarball"
        return 1
    fi
    
    # Check if file is readable
    if [[ ! -r "$tarball" ]]; then
        log_error "Tarball not readable: $tarball"
        return 1
    fi
    
    log_info "Extracting local tarball..."
    if tar -xzf "$tarball" -C "$TEMP_DIR" 2>/dev/null; then
        log_info "Local tarball extracted successfully"
        return 0
    else
        log_error "Failed to extract tarball (may be corrupted or not a valid gzip archive)"
        return 1
    fi
}

# Download and extract from GitHub
extract_github_release() {
    local version="$1"
    local download_url
    local tarball_name
    
    # Determine download URL
    if [[ -z "$version" ]]; then
        log_info "Fetching latest release from GitHub..."
        download_url="https://github.com/oehrlis/oradba/releases/latest/download/oradba.tar.gz"
        tarball_name="oradba-latest.tar.gz"
    else
        log_info "Fetching version ${version} from GitHub..."
        download_url="https://github.com/oehrlis/oradba/releases/download/v${version}/oradba-${version}.tar.gz"
        tarball_name="oradba-${version}.tar.gz"
    fi
    
    local tarball_path="${TEMP_DIR}/${tarball_name}"
    
    # Check for download tool
    local download_cmd=""
    if command -v curl >/dev/null 2>&1; then
        download_cmd="curl"
    elif command -v wget >/dev/null 2>&1; then
        download_cmd="wget"
    else
        log_error "Neither curl nor wget found - cannot download from GitHub"
        log_info "Please install curl or wget, or use --local with a downloaded tarball"
        return 1
    fi
    
    # Download tarball
    log_info "Downloading from: ${download_url}"
    if [[ "$download_cmd" == "curl" ]]; then
        if ! curl -L -f -o "$tarball_path" "$download_url" 2>/dev/null; then
            log_error "Failed to download from GitHub"
            [[ -n "$version" ]] && log_info "Version ${version} may not exist. Check: https://github.com/oehrlis/oradba/releases"
            return 1
        fi
    else
        if ! wget -q -O "$tarball_path" "$download_url" 2>/dev/null; then
            log_error "Failed to download from GitHub"
            [[ -n "$version" ]] && log_info "Version ${version} may not exist. Check: https://github.com/oehrlis/oradba/releases"
            return 1
        fi
    fi
    
    log_info "Download completed: $(du -h "$tarball_path" | cut -f1)"
    
    # Extract downloaded tarball
    log_info "Extracting downloaded tarball..."
    if tar -xzf "$tarball_path" -C "$TEMP_DIR" 2>/dev/null; then
        rm -f "$tarball_path"  # Clean up downloaded file
        log_info "GitHub release extracted successfully"
        return 0
    else
        log_error "Failed to extract downloaded tarball"
        return 1
    fi
}

echo "========================================="
echo "oradba Installer v${INSTALLER_VERSION}"
echo "========================================="
echo "Installation mode: $INSTALL_MODE"
echo "Installation prefix: $INSTALL_PREFIX"
[[ -n "$INSTALL_USER" ]] && echo "Install user: $INSTALL_USER"
[[ "$INSTALL_MODE" == "local" ]] && echo "Local tarball: $LOCAL_TARBALL"
[[ "$INSTALL_MODE" == "github" ]] && [[ -n "$GITHUB_VERSION" ]] && echo "GitHub version: $GITHUB_VERSION"
echo ""

# Run pre-flight checks
run_preflight_checks "$INSTALL_PREFIX"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
log_info "Created temporary directory: $TEMP_DIR"

# Extract based on installation mode
case "$INSTALL_MODE" in
    embedded)
        extract_embedded_payload || exit 1
        ;;
    local)
        extract_local_tarball "$LOCAL_TARBALL" || exit 1
        ;;
    github)
        extract_github_release "$GITHUB_VERSION" || exit 1
        ;;
    *)
        log_error "Unknown installation mode: $INSTALL_MODE"
        exit 1
        ;;
esac

# Create installation directory
if [[ ! -d "$INSTALL_PREFIX" ]]; then
    log_info "Creating installation directory: $INSTALL_PREFIX"
    mkdir -p "$INSTALL_PREFIX"
fi

# Copy files
log_info "Installing files..."
cp -r "$TEMP_DIR"/* "$INSTALL_PREFIX/"
# Also copy hidden files (like .oradba.checksum)
cp -r "$TEMP_DIR"/.[!.]* "$INSTALL_PREFIX/" 2>/dev/null || true

# Create logs directory
mkdir -p "$INSTALL_PREFIX/logs"

# Create installation metadata
log_info "Creating installation metadata..."
cat > "$INSTALL_PREFIX/.install_info" <<METADATA
install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
install_version=${INSTALLER_VERSION}
install_method=${INSTALL_MODE}
install_user=${INSTALL_USER:-${USER}}
install_prefix=${INSTALL_PREFIX}
METADATA

# Set ownership if user specified
if [[ -n "$INSTALL_USER" ]]; then
    log_info "Setting ownership to $INSTALL_USER"
    chown -R "$INSTALL_USER" "$INSTALL_PREFIX"
fi

# Make scripts executable
log_info "Setting permissions..."
find "$INSTALL_PREFIX/bin" -type f -name "*.sh" -exec chmod +x {} \;

# Verify installation integrity
log_info "Verifying installation integrity..."
if [[ -x "$INSTALL_PREFIX/bin/oradba_version.sh" ]]; then
    # Run checksum verification with ORADBA_BASE set
    if ORADBA_BASE="$INSTALL_PREFIX" "$INSTALL_PREFIX/bin/oradba_version.sh" --verify >/dev/null 2>&1; then
        log_info "Installation integrity verified"
    else
        log_error "Installation integrity verification FAILED"
        log_error "Some files may be corrupted or missing"
        echo ""
        echo "Running detailed verification:"
        ORADBA_BASE="$INSTALL_PREFIX" "$INSTALL_PREFIX/bin/oradba_version.sh" --verify
        echo ""
        log_error "Installation completed but verification failed"
        log_error "Installation directory: $INSTALL_PREFIX"
        exit 1
    fi
else
    log_warn "oradba_version.sh not found - skipping integrity verification"
fi

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
