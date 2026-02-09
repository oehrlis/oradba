#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.15
# Revision...: 1.0.0
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
ORADBA_DEBUG="${ORADBA_DEBUG:-false}"  # Debug mode (can be set via env or --debug flag)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# Function: determine_default_prefix
# Purpose.: Auto-detect default OraDBA installation prefix from Oracle environment
# Args....: None
# Returns.: 0 on success, 1 if detection failed
# Output..: Installation prefix path to stdout (e.g., /opt/oracle/local/oradba)
# Notes...: Priority: ORACLE_BASE > ORACLE_HOME > oratab > /opt/oracle > fail
#           Checks orabasetab, envVars.properties for ORACLE_BASE
#           Falls back to path derivation and common locations
# ------------------------------------------------------------------------------
determine_default_prefix() {
    # Priority 1: ORACLE_BASE is set
    if [[ -n "${ORACLE_BASE}" ]]; then
        [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] oradba_install.sh: Using ORACLE_BASE: ${ORACLE_BASE}/local/oradba" >&2
        echo "${ORACLE_BASE}/local/oradba"
        return 0
    fi

    # Priority 2: Derive from ORACLE_HOME
    if [[ -n "${ORACLE_HOME}" ]]; then
        # Try orabasetab first
        if [[ -f "${ORACLE_HOME}/install/orabasetab" ]]; then
            local oracle_base
            oracle_base=$(grep "^${ORACLE_HOME}:" "${ORACLE_HOME}/install/orabasetab" 2> /dev/null | cut -d: -f2)
            if [[ -n "$oracle_base" ]]; then
                echo "${oracle_base}/local/oradba"
                return 0
            fi
        fi

        # Try envVars.properties
        if [[ -f "${ORACLE_HOME}/install/envVars.properties" ]]; then
            local oracle_base
            oracle_base=$(grep "^ORACLE_BASE=" "${ORACLE_HOME}/install/envVars.properties" 2> /dev/null | cut -d= -f2)
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
                    oracle_base=$(grep "^${first_home}:" "${first_home}/install/orabasetab" 2> /dev/null | cut -d: -f2)
                    if [[ -n "$oracle_base" ]]; then
                        echo "${oracle_base}/local/oradba"
                        return 0
                    fi
                fi

                # Try envVars.properties
                if [[ -f "${first_home}/install/envVars.properties" ]]; then
                    local oracle_base
                    oracle_base=$(grep "^ORACLE_BASE=" "${first_home}/install/envVars.properties" 2> /dev/null | cut -d= -f2)
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

    # Priority 4: Check if /opt/oracle exists (common default location)
    if [[ -d "/opt/oracle" ]]; then
        echo "/opt/oracle/local/oradba"
        return 0
    fi

    # Priority 5: Cannot determine - return empty (will require explicit parameter)
    echo ""
    return 1
}

DEFAULT_PREFIX=$(determine_default_prefix) || true

# ------------------------------------------------------------------------------
# Function: log_info
# Purpose.: Display informational message with green [INFO] prefix
# Args....: $* - Message text
# Returns.: 0
# Output..: Colored message to stdout
# Notes...: Simple installer logging, not the full oradba_log system
# ------------------------------------------------------------------------------
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

# ------------------------------------------------------------------------------
# Function: log_warn
# Purpose.: Display warning message with yellow [WARN] prefix
# Args....: $* - Message text
# Returns.: 0
# Output..: Colored message to stdout
# Notes...: Simple installer logging
# ------------------------------------------------------------------------------
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# ------------------------------------------------------------------------------
# Function: log_error
# Purpose.: Display error message with red [ERROR] prefix
# Args....: $* - Message text
# Returns.: 0
# Output..: Colored message to stderr
# Notes...: Simple installer logging
# ------------------------------------------------------------------------------
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ------------------------------------------------------------------------------
# Function: log_debug
# Purpose.: Display debug message with [DEBUG] prefix when debug mode is enabled
# Args....: $* - Message text
# Returns.: 0
# Output..: Debug message to stderr (only if ORADBA_DEBUG=true)
# Notes...: Enable via ORADBA_DEBUG=true or --debug flag
# ------------------------------------------------------------------------------
log_debug() {
    if [[ "${ORADBA_DEBUG}" == "true" ]]; then
        echo -e "[DEBUG] $*" >&2
    fi
}

# ------------------------------------------------------------------------------
# Function: check_archived_version
# Purpose.: Check if version is pre-1.0 archived release and display notice
# Args....: $1 - Version string (e.g., "0.16.0")
# Returns.: 0 if archived (pre-1.0), 1 otherwise
# Output..: Archived version notice to stdout
# Notes...: All 0.x.x versions are considered archived
#           Displays upgrade recommendation for production use
# ------------------------------------------------------------------------------
check_archived_version() {
    local version="$1"
    
    # Check if version starts with 0. (any 0.x.x version is pre-1.0)
    if [[ "$version" =~ ^0\. ]]; then
        echo ""
        log_info "========================================================"
        log_info "NOTE: Version ${version} is an archived pre-1.0 release"
        log_info "========================================================"
        log_info "This version is maintained for historical reference only."
        log_info "For production use, consider upgrading to v1.0.0 or later."
        log_info "Release notes: https://github.com/oehrlis/oradba/releases/tag/v${version}"
        echo ""
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: cleanup
# Purpose.: Remove temporary directory on script exit
# Args....: None
# Returns.: 0
# Output..: None
# Notes...: Called automatically via trap EXIT
#           Removes TEMP_DIR if set and exists
# ------------------------------------------------------------------------------
cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# ------------------------------------------------------------------------------
# Function: backup_modified_files
# Purpose.: Backup modified configuration files before update
# Args....: $1 - Installation prefix directory
# Returns.: 0
# Output..: Backup status messages to stdout
# Notes...: Similar to RPM behavior - saves modified files with .save extension
#           Compares checksums from .oradba.checksum file
#           Only backs up etc/ files and .conf files
#           Skips backup if .oradba.checksum doesn't exist (fresh install)
# ------------------------------------------------------------------------------
backup_modified_files() {
    local install_prefix="$1"
    local backed_up_count=0

    # Only relevant if this is an update/upgrade
    if [[ ! -f "$install_prefix/.oradba.checksum" ]]; then
        return 0
    fi

    log_info "Checking for modified configuration files..."

    # Get list of files that should be checked
    local checksum_file="$install_prefix/.oradba.checksum"

    # Check each file in the checksum
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue

        # Skip .install_info (always modified during installation)
        [[ "$line" =~ \.install_info ]] && continue

        # Skip user-managed configuration files (not in checksum, but defensive check)
        [[ "$line" =~ etc/oradba_homes\.conf ]] && continue
        [[ "$line" =~ etc/oradba_customer\.conf ]] && continue
        [[ "$line" =~ etc/oradba_local\.conf ]] && continue
        [[ "$line" =~ etc/sid\..+\.conf ]] && continue

        # Parse checksum line: <hash>  <filepath> (two spaces)
        # Skip lines that don't match expected format
        [[ "$line" =~ ^[a-f0-9]{64}\ \ .+ ]] || continue

        local expected_hash="${line%%  *}"
        local filepath="${line#*  }"
        local fullpath="$install_prefix/$filepath"

        # Skip if file doesn't exist
        [[ ! -f "$fullpath" ]] && continue

        # Calculate current checksum
        local current_hash
        if command -v sha256sum > /dev/null 2>&1; then
            current_hash=$(sha256sum "$fullpath" 2> /dev/null | awk '{print $1}')
        elif command -v shasum > /dev/null 2>&1; then
            current_hash=$(shasum -a 256 "$fullpath" 2> /dev/null | awk '{print $1}')
        else
            log_warn "Cannot verify checksums - no checksum tool available"
            return 0
        fi

        # If file is modified, create backup
        if [[ "$current_hash" != "$expected_hash" ]]; then
            # Only backup configuration files in etc/ and user-modifiable files
            if [[ "$filepath" =~ ^etc/ ]] || [[ "$filepath" =~ \.conf$ ]] || [[ "$filepath" =~ \.example$ ]]; then
                log_warn "Backing up modified file: $filepath"
                cp -p "$fullpath" "$fullpath.save"
                echo "  → Saved as: ${filepath}.save"
                backed_up_count=$((backed_up_count + 1))
            fi
        fi
    done < "$checksum_file"

    if [[ $backed_up_count -gt 0 ]]; then
        echo ""
        log_info "Backed up $backed_up_count modified configuration file(s)"
        log_info "Your changes are preserved in .save files"
        echo ""
    else
        log_info "No modified configuration files found"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display installer usage information and examples
# Args....: None
# Returns.: 0 (exits after display)
# Output..: Usage help to stdout
# Notes...: Shows installation modes, location options, examples
#           Includes pre-Oracle installation instructions
# ------------------------------------------------------------------------------
usage() {
    # Determine default prefix for display
    local display_prefix="${DEFAULT_PREFIX:-<requires --prefix, --base, or --user-level>}"

    cat << EOF
Usage: $0 [OPTIONS]

Install oradba - Oracle Database Administration Toolset v${INSTALLER_VERSION}

Installation Modes:
  Default             Install from embedded payload (if available)
  --local PATH        Install from local tarball file
  --github            Install latest release from GitHub
  --github --version  Install specific version from GitHub
  --update            Update existing installation (preserves config)

Installation Location Options:
  --prefix PATH       Direct installation path (installs to PATH)
  --base PATH         Oracle Base directory (installs to PATH/local/oradba)
  --user-level        User-level install to ~/oradba (no root required)
  
  Default: ${display_prefix}
  
  Priority: --prefix > --user-level > --base > auto-detect

Other Options:
  --user USER               Run as specific user (requires sudo)
  --version VERSION         Specify version for --github mode
  --dummy-home PATH         Set dummy ORACLE_HOME for pre-Oracle installations
  --silent                  Silent mode (no interactive prompts, no profile update)
  --force                   Force update even if same version
  --update-profile          Update shell profile for automatic environment loading
  --no-update-profile       Don't update shell profile (default: prompt user)
  --auto-discover-oratab    Auto-discover database homes from oratab on login
  --auto-discover-products  Auto-discover all Oracle products on login (db, datasafe, java, etc.)
  --debug                   Enable debug logging (shows detailed operation steps)
  -h, --help                Display this help message
  -v, --show-version        Display installer version information

Examples:
  # Install from embedded payload (if available)
  $0
  
  # Install to user home directory (no Oracle required)
  $0 --user-level
  
  # Install with custom Oracle Base
  $0 --base /opt/oracle
  
  # Install with custom prefix
  $0 --prefix /usr/local/oradba
  
  # Install from local tarball (air-gapped)
  $0 --local /tmp/oradba-0.16.0.tar.gz
  
  # Install latest from GitHub
  $0 --github
  
  # Install specific version from GitHub
  $0 --github --version 0.16.0
  
  # Update existing installation
  $0 --update
  
  # Pre-Oracle installation with dummy entry
  $0 --base /opt/oracle --dummy-home /opt/oracle/product/dummy
  
  # Update from local tarball
  $0 --update --local /path/to/oradba-0.17.0.tar.gz
  
  # Update from specific GitHub version
  $0 --update --github --version 0.17.0
  
  # Install as different user
  sudo $0 --prefix /opt/oradba --user oracle
  
  # Install with oratab auto-discovery enabled
  $0 --user-level --update-profile --auto-discover-oratab
  
  # Install with full product discovery enabled
  $0 --user-level --update-profile --auto-discover-products

Pre-Oracle Installation:
  When installing before Oracle, use --user-level, --prefix, or --base to
  specify installation location. A temporary oratab will be created in
  \${ORADBA_BASE}/etc/oratab. After Oracle installation, create a symlink:
    ln -sf /etc/oratab \${ORADBA_BASE}/etc/oratab

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function: check_required_tools
# Purpose.: Verify required system tools are available
# Args....: None
# Returns.: 0 if all required tools present, 1 otherwise
# Output..: Tool check results to stdout
# Notes...: Checks: bash, tar, awk, sed, grep, sha256sum/shasum
#           Mode-specific: base64 (embedded), curl/wget (github)
#           Installation cannot proceed if required tools missing
# ------------------------------------------------------------------------------
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
    if command -v sha256sum > /dev/null 2>&1; then
        log_info "sha256sum found (checksum verification)"
    elif command -v shasum > /dev/null 2>&1; then
        log_info "shasum found (checksum verification)"
    else
        log_error "Neither sha256sum nor shasum found - required for checksum verification"
        requirements_met=false
    fi

    # Check base64 (needed for embedded payload)
    if [[ "$INSTALL_MODE" == "embedded" ]]; then
        if command -v base64 > /dev/null 2>&1; then
            log_info "base64 found (payload decoding)"
        else
            log_error "base64 not found - required for embedded payload"
            requirements_met=false
        fi
    fi

    # Check download tools (needed for GitHub mode)
    if [[ "$INSTALL_MODE" == "github" ]]; then
        if command -v curl > /dev/null 2>&1; then
            log_info "curl found (GitHub downloads)"
        elif command -v wget > /dev/null 2>&1; then
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

        if command -v "$tool" > /dev/null 2>&1; then
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

# ------------------------------------------------------------------------------
# Function: check_optional_tools
# Purpose.: Check for optional tools and warn if missing
# Args....: None
# Returns.: 0 (always successful, warnings only)
# Output..: Optional tool status and installation hints to stdout
# Notes...: Checks: rlwrap, less, crontab
#           Installation continues even if optional tools missing
#           Provides installation commands for missing tools
# ------------------------------------------------------------------------------
check_optional_tools() {
    echo "Checking Optional Tools"
    echo "-----------------------"

    local warnings=0

    # Check for rlwrap (optional but recommended)
    if command -v rlwrap > /dev/null 2>&1; then
        local rlwrap_version
        rlwrap_version=$(rlwrap -v 2>&1 | head -1 || echo "unknown")
        log_info "rlwrap found: ${rlwrap_version}"
    else
        log_warn "rlwrap not found (optional)"
        echo "  Many oradba aliases (sqh, rman, etc.) provide enhanced"
        echo "  readline support with rlwrap. Install for better CLI experience."
        echo "  Install: yum install rlwrap | apt install rlwrap | brew install rlwrap"
        ((warnings++)) || true # Prevent set -e from exiting on arithmetic
        echo ""
    fi

    # Check for less (optional pager)
    if command -v less > /dev/null 2>&1; then
        log_info "less found (paging support)"
    else
        log_warn "less not found (optional)"
        echo "  Some scripts use 'less' for paging output."
        ((warnings++)) || true # Prevent set -e from exiting on arithmetic
    fi

    # Check for crontab (optional for save_cron alias)
    if command -v crontab > /dev/null 2>&1; then
        log_info "crontab found (cron job management)"
    else
        log_warn "crontab not found (optional)"
        echo "  The 'save_cron' alias requires crontab to backup cron jobs."
        ((warnings++)) || true # Prevent set -e from exiting on arithmetic
    fi

    echo ""

    if [[ $warnings -gt 0 ]]; then
        log_info "Optional tools missing: $warnings"
        log_info "Installation will continue, but some features may be limited"
    else
        log_info "All optional tools available"
    fi

    echo ""
    return 0 # Explicitly return success
}

# ------------------------------------------------------------------------------
# Function: check_disk_space
# Purpose.: Verify sufficient disk space for installation
# Args....: $1 - Installation directory path
# Returns.: 0 if sufficient space, 1 otherwise
# Output..: Disk space check results to stdout
# Notes...: Requires 100MB free space
#           Checks parent directories if target doesn't exist
#           Warns if unable to determine space (continues anyway)
# ------------------------------------------------------------------------------
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
    if command -v df > /dev/null 2>&1; then
        # Try to get available space
        available_mb=$(df -Pm "$check_dir" 2> /dev/null | awk 'NR==2 {print $4}')

        if [[ -z "$available_mb" ]] || ! [[ "$available_mb" =~ ^[0-9]+$ ]]; then
            log_warn "Could not determine available disk space"
            return 0 # Continue anyway
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

# ------------------------------------------------------------------------------
# Function: check_permissions
# Purpose.: Verify write permissions for installation directory
# Args....: $1 - Installation directory path
# Returns.: 0 if writable, 1 otherwise
# Output..: Permission check results to stdout
# Notes...: Checks target directory or creates test file in parent
#           Suggests sudo if permissions insufficient
# ------------------------------------------------------------------------------
check_permissions() {
    local install_dir="$1"

    echo "Checking Permissions"
    echo "--------------------"

    # Check if we need to create parent directories
    local parent_dir
    parent_dir="$(dirname "$install_dir")"

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

# Detect user's shell profile file
# ------------------------------------------------------------------------------
# Function: detect_profile_file
# Purpose.: Detect appropriate shell profile file for current user
# Args....: None
# Returns.: 0
# Output..: Profile file path to stdout
# Notes...: Priority: ~/.bash_profile > ~/.profile > ~/.zshrc > create ~/.bash_profile
#           .bashrc intentionally skipped (non-login shells)
#           Creates .bash_profile if no profile exists
# ------------------------------------------------------------------------------
detect_profile_file() {
    local profile=""

    # Priority 1: bash_profile (for login shells - sources bashrc if needed)
    if [[ -f "${HOME}/.bash_profile" ]]; then
        profile="${HOME}/.bash_profile"
    # Priority 2: profile (generic POSIX for login shells)
    elif [[ -f "${HOME}/.profile" ]]; then
        profile="${HOME}/.profile"
    # Priority 3: zshrc (if using zsh)
    elif [[ -f "${HOME}/.zshrc" ]]; then
        profile="${HOME}/.zshrc"
    # Create bash_profile if none exist (will be loaded by login shells)
    # Note: .bashrc is not checked as it's only for non-login shells
    # and should be sourced by .bash_profile when needed
    else
        profile="${HOME}/.bash_profile"
    fi

    echo "$profile"
}

# ------------------------------------------------------------------------------
# Function: profile_has_oradba
# Purpose.: Check if profile already has OraDBA integration
# Args....: $1 - Profile file path
# Returns.: 0 if integrated, 1 otherwise
# Output..: None
# Notes...: Checks for OraDBA marker comment or oraenv.sh source
#           Prevents duplicate profile entries
# ------------------------------------------------------------------------------
profile_has_oradba() {
    local profile_file="$1"

    if [[ ! -f "$profile_file" ]]; then
        return 1
    fi

    # Check for OraDBA marker or oraenv.sh source
    if grep -q "# OraDBA Environment Integration" "$profile_file" 2> /dev/null \
        || grep -q "oraenv.sh" "$profile_file" 2> /dev/null; then
        return 0
    fi

    return 1
}

# ------------------------------------------------------------------------------
# Function: update_profile
# Purpose.: Add OraDBA auto-loading to shell profile
# Args....: $1 - Installation prefix directory
# Returns.: 0 on success, 1 on error
# Output..: Profile update status and manual instructions to stdout
# Notes...: Interactive prompt if TTY available (unless --silent or --update-profile)
#           Creates backup of profile before modification
#           Adds oraenv.sh sourcing and oraup.sh status display
#           Respects UPDATE_PROFILE variable (yes/no/auto)
#           Exports ORADBA_AUTO_DISCOVER_ORATAB=true if ENABLE_ORATAB_DISCOVERY is set
#           Exports ORADBA_AUTO_DISCOVER_PRODUCTS=true if ENABLE_PRODUCT_DISCOVERY is set
# ------------------------------------------------------------------------------
update_profile() {
    local install_prefix="$1"
    local profile_file
    profile_file=$(detect_profile_file)

    echo ""
    echo "==========================================="
    echo "Shell Profile Integration"
    echo "==========================================="
    echo ""

    # Check if already integrated
    if profile_has_oradba "$profile_file"; then
        log_info "OraDBA already integrated in: $profile_file"
        log_info "Skipping profile update to avoid duplicates"
        return 0
    fi

    # Determine if we should update
    local should_update="$UPDATE_PROFILE"

    if [[ "$should_update" == "auto" ]] && [[ -t 0 ]] && [[ -t 1 ]]; then
        # Interactive mode with TTY - ask user
        echo "OraDBA can automatically load the Oracle environment on shell startup."
        echo ""
        echo "This will add the following to: $profile_file"
        echo "  - Automatic sourcing of oraenv.sh (uses first SID from oratab)"
        echo "  - Display Oracle environment status on login (if interactive)"
        echo ""
        read -t 30 -p "Update shell profile? [y/N]: " -n 1 -r 2> /dev/null
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            should_update="yes"
        else
            should_update="no"
        fi
    elif [[ "$should_update" == "auto" ]]; then
        # Non-interactive or no TTY - don't update by default
        should_update="no"
    fi

    if [[ "$should_update" != "yes" ]]; then
        log_info "Skipping profile update"
        echo ""
        echo "To manually add OraDBA to your profile, add these lines to $profile_file:"
        echo ""
        echo "  # OraDBA Environment Integration"
        if [[ "$ENABLE_ORATAB_DISCOVERY" == "true" ]]; then
            echo "  export ORADBA_AUTO_DISCOVER_ORATAB=\"true\""
            echo ""
        fi
        if [[ "$ENABLE_PRODUCT_DISCOVERY" == "true" ]]; then
            echo "  export ORADBA_AUTO_DISCOVER_PRODUCTS=\"true\""
            echo ""
        fi
        echo "  if [ -f \"${install_prefix}/bin/oraenv.sh\" ]; then"
        echo "      # Load first Oracle SID from oratab (silent mode)"
        echo "      source \"${install_prefix}/bin/oraenv.sh\" --silent"
        echo "      # Show environment status on interactive shells"
        echo "      if [[ \$- == *i* ]] && command -v oraup.sh >/dev/null 2>&1; then"
        echo "          oraup.sh"
        echo "      fi"
        echo "  fi"
        echo ""
        return 0
    fi

    # Create profile file if it doesn't exist
    if [[ ! -f "$profile_file" ]]; then
        touch "$profile_file" || {
            log_error "Cannot create profile file: $profile_file"
            return 1
        }
    fi

    # Backup profile
    cp "$profile_file" "${profile_file}.backup.$(date +%Y%m%d_%H%M%S)" || {
        log_warn "Could not create backup of profile file"
    }

    # Add OraDBA integration
    cat >> "$profile_file" << EOF

# OraDBA Environment Integration (added $(date '+%Y-%m-%d'))
EOF

    # Add oratab discovery export if enabled
    if [[ "$ENABLE_ORATAB_DISCOVERY" == "true" ]]; then
        cat >> "$profile_file" << 'EOF'
export ORADBA_AUTO_DISCOVER_ORATAB="true"

EOF
    fi

    # Add product discovery export if enabled
    if [[ "$ENABLE_PRODUCT_DISCOVERY" == "true" ]]; then
        cat >> "$profile_file" << 'EOF'
export ORADBA_AUTO_DISCOVER_PRODUCTS="true"

EOF
    fi

    # Add oraenv.sh sourcing
    cat >> "$profile_file" << EOF
if [ -f "${install_prefix}/bin/oraenv.sh" ]; then
    # Load first Oracle SID from oratab (silent mode)
    source "${install_prefix}/bin/oraenv.sh" --silent
    # Show environment status on interactive shells
    if [[ \$- == *i* ]] && command -v oraup.sh >/dev/null 2>&1; then
        oraup.sh
    fi
fi
EOF

    if [[ $? -eq 0 ]]; then
        log_info "Profile updated successfully: $profile_file"
        log_info "Backup created: ${profile_file}.backup.$(date +%Y%m%d_%H%M%S)"
        echo ""
        echo "The Oracle environment will be loaded automatically on next login"
        echo "To activate now, run: source $profile_file"
    else
        log_error "Failed to update profile file"
        return 1
    fi

    echo ""
    return 0
}

# ------------------------------------------------------------------------------
# Function: run_preflight_checks
# Purpose.: Execute all pre-installation validation checks
# Args....: $1 - Installation directory path
# Returns.: 0 if all checks pass, 1 on failure
# Output..: Check results and status to stdout
# Notes...: Runs: required tools, optional tools, disk space, permissions
#           Stops installation if critical checks fail
#           Optional tool checks only warn, don't block
# ------------------------------------------------------------------------------
run_preflight_checks() {
    local install_dir="$1"

    echo "==========================================="
    echo "Pre-flight Checks"
    echo "==========================================="
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
    echo "==========================================="
    echo ""
}

# Check if running from within an oradba installation directory
# This prevents the script from overwriting itself during installation
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../VERSION" ]] && [[ -d "${SCRIPT_DIR}/../etc" ]] && [[ -d "${SCRIPT_DIR}/../lib" ]]; then
    SCRIPT_INSTALL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
    if [[ "$(pwd)" == "${SCRIPT_INSTALL_DIR}"* ]]; then
        log_error "Cannot run installer from within an OraDBA installation directory"
        log_error "Current directory: $(pwd)"
        log_error "Installation directory: ${SCRIPT_INSTALL_DIR}"
        log_error ""
        log_error "Please change to a different directory (e.g., \$HOME or /tmp):"
        log_error "  cd \$HOME && ${SCRIPT_INSTALL_DIR}/bin/oradba_install.sh $*"
        log_error ""
        log_error "Or copy the installer elsewhere first:"
        log_error "  cp ${SCRIPT_INSTALL_DIR}/bin/oradba_install.sh /tmp/"
        log_error "  cd /tmp && ./oradba_install.sh $*"
        exit 1
    fi
fi

# Parse arguments
INSTALL_PREFIX=""        # Will be set based on --prefix, --base, --user-level, or DEFAULT_PREFIX
ORACLE_BASE_PARAM=""     # For --base parameter
USER_LEVEL_INSTALL=false # For --user-level parameter
INSTALL_USER=""
# shellcheck disable=SC2034  # Used for future enhancement
INSTALL_EXAMPLES=true
INSTALL_MODE="auto" # auto, embedded, local, github
LOCAL_TARBALL=""
GITHUB_VERSION=""
DUMMY_ORACLE_HOME="" # For pre-Oracle installations
UPDATE_MODE=false
FORCE_UPDATE=false
UPDATE_PROFILE="auto" # auto, yes, no
ENABLE_ORATAB_DISCOVERY=false # Flag for --auto-discover-oratab (database homes only)
ENABLE_PRODUCT_DISCOVERY=false # Flag for --auto-discover-products (all Oracle products)
SILENT_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --base)
            ORACLE_BASE_PARAM="$2"
            shift 2
            ;;
        --user-level)
            USER_LEVEL_INSTALL=true
            shift
            ;;
        --dummy-home)
            DUMMY_ORACLE_HOME="$2"
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
            shift
            [[ -n "$GITHUB_VERSION" ]] && shift
            ;;
        --update)
            UPDATE_MODE=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --update-profile)
            UPDATE_PROFILE="yes"
            shift
            ;;
        --no-update-profile)
            UPDATE_PROFILE="no"
            shift
            ;;
        --auto-discover-oratab)
            ENABLE_ORATAB_DISCOVERY=true
            shift
            ;;
        --auto-discover-products)
            ENABLE_PRODUCT_DISCOVERY=true
            shift
            ;;
        --silent)
            SILENT_MODE=true
            UPDATE_PROFILE="no" # Silent mode implies no profile update prompts
            shift
            ;;
        --debug)
            ORADBA_DEBUG="true"
            log_debug "oradba_install.sh: Debug mode enabled via --debug flag"
            shift
            ;;
        -h | --help)
            usage
            ;;
        -v | --show-version)
            echo "oradba installer version $INSTALLER_VERSION"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

log_debug "oradba_install.sh: CLI parsing complete"
log_debug "oradba_install.sh: INSTALL_MODE=${INSTALL_MODE}, UPDATE_MODE=${UPDATE_MODE}"
log_debug "oradba_install.sh: USER_PREFIX=${USER_PREFIX}, ORACLE_BASE_ARG=${ORACLE_BASE_ARG}, USER_LEVEL=${USER_LEVEL}"
log_debug "oradba_install.sh: GITHUB_VERSION=${GITHUB_VERSION}, LOCAL_TARBALL=${LOCAL_TARBALL}"

# Validate arguments (before checking prefix requirements)
if [[ "$INSTALL_MODE" == "local" ]] && [[ -z "$LOCAL_TARBALL" ]]; then
    log_error "--local requires a path to tarball file"
    usage
fi

if [[ -n "$GITHUB_VERSION" ]] && [[ "$INSTALL_MODE" != "github" ]]; then
    log_error "--version can only be used with --github"
    usage
fi

# Determine final INSTALL_PREFIX based on priority
# Priority: --prefix > --user-level > --base > DEFAULT_PREFIX
if [[ -z "$INSTALL_PREFIX" ]]; then
    if [[ "$USER_LEVEL_INSTALL" == "true" ]]; then
        INSTALL_PREFIX="$HOME/oradba"
        log_info "User-level installation selected: $INSTALL_PREFIX"
    elif [[ -n "$ORACLE_BASE_PARAM" ]]; then
        INSTALL_PREFIX="${ORACLE_BASE_PARAM}/local/oradba"
        log_info "Using Oracle Base parameter: $ORACLE_BASE_PARAM"
        log_info "Installation prefix: $INSTALL_PREFIX"
    elif [[ -n "$DEFAULT_PREFIX" ]]; then
        INSTALL_PREFIX="$DEFAULT_PREFIX"
    else
        # No prefix could be determined
        log_error "Cannot determine installation location"
        log_error ""
        log_error "Oracle environment not detected. Please specify installation location:"
        log_error ""
        log_error "  Option 1: User-level install (no Oracle required)"
        log_error "    $0 --user-level"
        log_error ""
        log_error "  Option 2: Specify Oracle Base directory"
        log_error "    $0 --base /opt/oracle"
        log_error ""
        log_error "  Option 3: Specify direct installation path"
        log_error "    $0 --prefix /custom/path"
        log_error ""
        log_error "For more information, run: $0 --help"
        exit 1
    fi
fi

# Auto-detect installation mode
if [[ "$INSTALL_MODE" == "auto" ]]; then
    # Check if payload marker exists in this script
    if grep -q "^__PAYLOAD_BEGINS__" "$0" 2> /dev/null; then
        # Verify there's actual payload data after the marker
        payload_line=$(awk '/^__PAYLOAD_BEGINS__/ {print NR + 1; exit 0; }' "$0")
        payload_lines=$(tail -n +"${payload_line}" "$0" 2> /dev/null | wc -l)

        if [[ ${payload_lines} -gt 10 ]]; then
            INSTALL_MODE="embedded"
            log_info "Detected embedded payload"
        else
            log_error "Payload marker found but no payload data present"
            log_error "This installer requires a source for installation:"
            log_error ""
            log_error "  Option 1: Use a local tarball"
            log_error "    $0 --local /path/to/oradba-x.y.z.tar.gz"
            log_error ""
            log_error "  Option 2: Download from GitHub"
            log_error "    $0 --github [--version x.y.z]"
            log_error ""
            log_error "For more information, run: $0 --help"
            exit 1
        fi
    else
        log_error "No embedded payload found and no installation mode specified"
        log_error "This installer requires a source for installation:"
        log_error ""
        log_error "  Option 1: Use a local tarball"
        log_error "    $0 --local /path/to/oradba-x.y.z.tar.gz"
        log_error ""
        log_error "  Option 2: Download from GitHub"
        log_error "    $0 --github [--version x.y.z]"
        log_error ""
        log_error "For more information, run: $0 --help"
        exit 1
    fi
fi

# ============================================================================
# Update Functions
# ============================================================================

# Compare two semantic versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
# ------------------------------------------------------------------------------
# Function: version_compare
# Purpose.: Compare two semantic version strings
# Args....: $1 - First version (e.g., "1.2.3")
#           $2 - Second version (e.g., "1.2.4")
# Returns.: 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
# Output..: None
# Notes...: Handles versions with or without 'v' prefix
#           Compares major.minor.patch numerically
#           Ignores pre-release suffixes (e.g., -beta)
# ------------------------------------------------------------------------------
version_compare() {
    local v1="$1"
    local v2="$2"

    # Remove leading 'v' if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"

    # Compare each component
    for i in {0..2}; do
        local part1="${v1_parts[$i]:-0}"
        local part2="${v2_parts[$i]:-0}"

        # Remove any non-numeric suffix
        part1="${part1%%-*}"
        part2="${part2%%-*}"

        if ((part1 > part2)); then
            return 1
        elif ((part1 < part2)); then
            return 2
        fi
    done

    return 0
}

# ------------------------------------------------------------------------------
# Function: get_installed_version
# Purpose.: Get currently installed OraDBA version
# Args....: $1 - Installation directory path
# Returns.: 0
# Output..: Version string to stdout (or "unknown" if not found)
# Notes...: Reads version from VERSION file in install directory
#           Returns "unknown" if VERSION file missing
# ------------------------------------------------------------------------------
get_installed_version() {
    local install_dir="$1"
    local version_file="${install_dir}/VERSION"

    if [[ -f "$version_file" ]]; then
        cat "$version_file" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# Function: check_existing_installation
# Purpose.: Check if OraDBA is already installed at target location
# Args....: $1 - Installation directory path
# Returns.: 0 if installed, 1 otherwise
# Output..: None
# Notes...: Verifies directory exists and contains VERSION file and bin/ directory
#           Used to determine if doing fresh install or update
# ------------------------------------------------------------------------------
check_existing_installation() {
    local install_dir="$1"

    if [[ ! -d "$install_dir" ]]; then
        return 1
    fi

    # Check for key files
    if [[ ! -f "${install_dir}/VERSION" ]] || [[ ! -d "${install_dir}/bin" ]]; then
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: backup_installation
# Purpose.: Create timestamped backup of existing installation
# Args....: $1 - Installation directory path
# Returns.: 0 on success, 1 on failure
# Output..: Backup directory path to stdout, status to stderr
# Notes...: Creates .backup.YYYYMMDD_HHMMSS directory
#           Full recursive copy of entire installation
#           Used before updates to enable rollback
# ------------------------------------------------------------------------------
backup_installation() {
    local install_dir="$1"
    local backup_dir
    backup_dir="${install_dir}.backup.$(date +%Y%m%d_%H%M%S)"

    log_info "Creating backup: $backup_dir"

    if ! cp -r "$install_dir" "$backup_dir"; then
        log_error "Failed to create backup"
        return 1
    fi

    log_info "Backup created successfully"
    echo "$backup_dir"
    return 0
}

# ------------------------------------------------------------------------------
# Function: restore_from_backup
# Purpose.: Restore installation from backup directory
# Args....: $1 - Installation directory path
#           $2 - Backup directory path
# Returns.: 0 on success, 1 on failure
# Output..: Restore status to stdout
# Notes...: Removes failed installation first
#           Renames backup directory back to original location
#           Used for rollback if update fails
# ------------------------------------------------------------------------------
restore_from_backup() {
    local install_dir="$1"
    local backup_dir="$2"

    log_info "Restoring from backup: $backup_dir"

    # Remove failed installation
    if [[ -d "$install_dir" ]]; then
        rm -rf "$install_dir"
    fi

    # Restore backup
    if ! mv "$backup_dir" "$install_dir"; then
        log_error "Failed to restore from backup"
        return 1
    fi

    log_info "Restore completed successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: preserve_configs
# Purpose.: Save user configuration files before update
# Args....: $1 - Installation directory path
#           $2 - Temporary config directory path
# Returns.: 0
# Output..: Preserved file list to stdout
# Notes...: Preserves: .install_info, etc/oradba.conf, oratab.example
#           Copies to temporary directory for restoration after update
#           Used to maintain user customizations across updates
# ------------------------------------------------------------------------------
preserve_configs() {
    local install_dir="$1"
    local temp_config_dir="$2"

    log_info "Preserving configuration files..."

    mkdir -p "$temp_config_dir"

    # Files to preserve
    local preserve_files=(
        ".install_info"
        "etc/oradba.conf"
        "templates/etc/oratab.example"
    )

    for file in "${preserve_files[@]}"; do
        local src="${install_dir}/${file}"
        if [[ -f "$src" ]]; then
            local dest="${temp_config_dir}/${file}"
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            log_info "Preserved: $file"
        fi
    done

    return 0
}

# ------------------------------------------------------------------------------
# Function: restore_configs
# Purpose.: Restore preserved configuration files after update
# Args....: $1 - Installation directory path
#           $2 - Temporary config directory path
# Returns.: 0
# Output..: Restored file list to stdout
# Notes...: Restores files preserved by preserve_configs function
#           Creates parent directories as needed
#           Removes temporary directory after restoration
# ------------------------------------------------------------------------------
restore_configs() {
    local install_dir="$1"
    local temp_config_dir="$2"

    log_info "Restoring configuration files..."

    if [[ ! -d "$temp_config_dir" ]]; then
        log_warn "No preserved configurations found"
        return 0
    fi

    # Restore preserved files
    find "$temp_config_dir" -type f | while read -r src; do
        local rel_path="${src#"${temp_config_dir}"/}"
        local dest="${install_dir}/${rel_path}"

        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        log_info "Restored: $rel_path"
    done

    # Clean up temp directory
    rm -rf "$temp_config_dir"

    return 0
}

# ------------------------------------------------------------------------------
# Function: perform_update
# Purpose.: Execute update of existing OraDBA installation
# Args....: None (uses global variables)
# Returns.: 0 on success, 1 on failure
# Output..: Update progress and status to stdout
# Notes...: Orchestrates: backup, preserve configs, extract new version, restore configs
#           Version comparison with --force override
#           Automatic rollback on failure
#           Preserves user customizations
# ------------------------------------------------------------------------------
perform_update() {
    local install_dir="$INSTALL_PREFIX"
    local current_version
    local new_version="$INSTALLER_VERSION"
    local backup_dir
    local config_dir

    echo "==========================================="
    echo "OraDBA Update Process"
    echo "==========================================="
    echo ""

    # Check if installation exists
    if ! check_existing_installation "$install_dir"; then
        log_error "No existing installation found at: $install_dir"
        log_error "Use regular installation mode instead"
        exit 1
    fi

    # Get current version
    current_version=$(get_installed_version "$install_dir")

    # Try to get new version from extracted tarball (for GitHub/local installs)
    if [[ -f "$TEMP_DIR/VERSION" ]]; then
        new_version=$(cat "$TEMP_DIR/VERSION" 2> /dev/null || echo "$INSTALLER_VERSION")
    elif [[ -n "$TEMP_DIR" ]]; then
        # Look for VERSION file in extracted directory structure
        local extracted_version
        extracted_version=$(find "$TEMP_DIR" -name "VERSION" -type f 2> /dev/null | head -1)
        if [[ -n "$extracted_version" ]]; then
            new_version=$(cat "$extracted_version" 2> /dev/null || echo "$INSTALLER_VERSION")
        fi
    fi

    log_info "Current version: $current_version"
    log_info "New version: $new_version"

    # Compare versions
    version_compare "$new_version" "$current_version"
    local cmp_result=$?

    if [[ $cmp_result -eq 0 ]]; then
        if [[ "$FORCE_UPDATE" != "true" ]]; then
            log_info "Already running latest version ($current_version)"
            log_info "Use --force to reinstall same version"
            exit 0
        else
            log_info "Force update enabled - reinstalling version $current_version"
        fi
    elif [[ $cmp_result -eq 2 ]]; then
        log_warn "New version ($new_version) is older than installed ($current_version)"
        if [[ "$FORCE_UPDATE" != "true" ]]; then
            log_error "Use --force to downgrade"
            exit 1
        fi
        log_info "Force downgrade enabled"
    else
        log_info "Upgrading from $current_version to $new_version"
    fi

    # Create backup
    backup_dir=$(backup_installation "$install_dir")
    if [[ $? -ne 0 ]]; then
        log_error "Backup failed - aborting update"
        exit 1
    fi

    # Preserve configurations
    config_dir=$(mktemp -d)
    preserve_configs "$install_dir" "$config_dir"

    # Remove old installation (keep backup)
    log_info "Removing old installation..."
    rm -rf "$install_dir"

    echo ""
    echo "Proceeding with installation..."
    echo ""

    # Return backup and config directories for use in main flow
    echo "$backup_dir|$config_dir"
}

# Extract from embedded payload
# ------------------------------------------------------------------------------
# Function: extract_embedded_payload
# Purpose.: Extract OraDBA from embedded base64 payload
# Args....: None (reads from $0 - the installer script itself)
# Returns.: 0 on success, 1 on failure
# Output..: Extraction status to stdout
# Notes...: Looks for __PAYLOAD_BEGINS__ marker in script
#           Decodes base64 and extracts tar.gz to TEMP_DIR
#           Includes filesystem sync and retry logic for containers
#           Suggests alternative methods if payload missing/corrupted
# ------------------------------------------------------------------------------
extract_embedded_payload() {
    log_info "Extracting embedded payload..."
    local payload_line
    payload_line=$(awk '/^__PAYLOAD_BEGINS__/ {print NR + 1; exit 0; }' "$0")

    if [[ -z "$payload_line" ]]; then
        log_error "Payload marker not found in installer"
        log_error "Use --local or --github to specify installation source"
        return 1
    fi

    # Decode base64 (use --decode for cross-platform compatibility)
    if ! tail -n +"${payload_line}" "$0" | base64 --decode | tar -xz -C "$TEMP_DIR" 2> /dev/null; then
        log_error "Failed to extract embedded payload"
        log_error "The payload may be missing or corrupted"
        log_error ""
        log_error "Alternative installation methods:"
        log_error "  1. Download from GitHub: $0 --github"
        log_error "  2. Use local tarball: $0 --local /path/to/oradba-x.y.z.tar.gz"
        return 1
    fi

    # Ensure all file operations are synced to disk
    sync
    # Longer delay for Docker/containerized environments where filesystem sync can be slower
    sleep 1
    
    # Verify critical files exist and are readable (especially installer script)
    local max_retries=5
    local retry_count=0
    while [[ $retry_count -lt $max_retries ]]; do
        if [[ -f "$TEMP_DIR/bin/oradba_install.sh" ]] && [[ -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
            break
        fi
        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $max_retries ]]; then
            sleep 0.5
        fi
    done
    
    # Final verification
    if [[ ! -f "$TEMP_DIR/bin/oradba_install.sh" ]] || [[ ! -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
        log_error "Extraction completed but critical files not accessible"
        log_error "This may indicate filesystem sync issues in containerized environments"
        return 1
    fi

    log_info "Embedded payload extracted successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: prompt_oracle_base
# Purpose.: Interactively prompt for Oracle Base directory if not specified
# Args....: None (sets global ORACLE_BASE_PARAM)
# Returns.: 0 on success, 1 on error
# Output..: Prompt and validation messages to stdout
# Notes...: Skipped if ORACLE_BASE_PARAM set, silent mode, or ORACLE_BASE detected
#           Validates absolute path and parent directory permissions
#           Default: /opt/oracle
# ------------------------------------------------------------------------------
prompt_oracle_base() {
    # Skip if already set or in silent mode
    if [[ -n "$ORACLE_BASE_PARAM" ]] || [[ "$SILENT_MODE" == "true" ]]; then
        return 0
    fi

    # Skip if we detected Oracle installation (should have been caught already)
    if [[ -n "$ORACLE_BASE" ]]; then
        ORACLE_BASE_PARAM="$ORACLE_BASE"
        return 0
    fi

    # Interactive prompt
    local default_base="/opt/oracle"
    echo ""
    echo "Oracle Base directory not specified and could not be auto-detected."
    echo "This directory will be used for the temporary oratab and dummy ORACLE_HOME."
    echo ""
    read -rp "Oracle Base directory [${default_base}]: " input_base

    # Use default if empty
    input_base="${input_base:-$default_base}"

    # Validate the path is absolute
    if [[ ! "$input_base" =~ ^/ ]]; then
        log_error "Oracle Base must be an absolute path: ${input_base}"
        return 1
    fi

    # Check if parent directory exists and is writable
    local parent_dir="${input_base%/*}"
    if [[ ! -d "$parent_dir" ]]; then
        log_error "Parent directory does not exist: ${parent_dir}"
        return 1
    fi

    if [[ ! -w "$parent_dir" ]]; then
        log_error "No write permission to parent directory: ${parent_dir}"
        log_info "You may need to run with sudo or choose a different location"
        return 1
    fi

    # Set the parameter
    ORACLE_BASE_PARAM="$input_base"
    log_info "Using Oracle Base: ${ORACLE_BASE_PARAM}"

    return 0
}

# ------------------------------------------------------------------------------
# Function: validate_write_permissions
# Purpose.: Validate write permissions for installation target
# Args....: $1 - Target installation path
# Returns.: 0 if writable, 1 otherwise
# Output..: Permission errors and suggestions to stderr
# Notes...: Checks target if exists, otherwise checks parent directory
#           Suggests sudo or alternative location if no permissions
#           Handles root directory edge case
# ------------------------------------------------------------------------------
validate_write_permissions() {
    local target_path="$1"

    # If target exists, check if writable
    if [[ -e "$target_path" ]]; then
        if [[ ! -w "$target_path" ]]; then
            log_error "No write permission to existing directory: ${target_path}"
            log_info "You may need to run with sudo or choose a different location using --prefix"
            return 1
        fi
        return 0
    fi

    # Target doesn't exist - check parent directory
    local parent_dir="${target_path%/*}"

    # Handle case where parent_dir is empty (root level)
    if [[ -z "$parent_dir" ]]; then
        parent_dir="/"
    fi

    # Check if parent exists
    if [[ ! -d "$parent_dir" ]]; then
        log_error "Parent directory does not exist: ${parent_dir}"
        log_info "Please create the parent directory first or choose a different location"
        return 1
    fi

    # Check if parent is writable
    if [[ ! -w "$parent_dir" ]]; then
        log_error "No write permission to parent directory: ${parent_dir}"
        log_info "You may need to run with sudo or choose a different location using --prefix"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: create_temp_oratab
# Purpose.: Create temporary oratab for pre-Oracle installations
# Args....: $1 - Installation prefix directory
# Returns.: 0
# Output..: Oratab creation status and symlink instructions to stdout
# Notes...: Creates etc/oratab in OraDBA directory if /etc/oratab missing
#           Adds dummy entry if --dummy-home specified
#           Provides instructions for symlinking after Oracle install
#           Supports air-gapped and pre-Oracle environments
# ------------------------------------------------------------------------------
create_temp_oratab() {
    local install_prefix="$1"
    local oratab_path="${install_prefix}/etc/oratab"

    # Check if /etc/oratab exists
    if [[ -f "/etc/oratab" ]]; then
        # System oratab exists - create symlink if possible
        if [[ ! -e "$oratab_path" ]]; then
            log_info "Creating symlink to /etc/oratab"
            if ln -sf "/etc/oratab" "$oratab_path" 2> /dev/null; then
                log_info "  Symlink created: ${oratab_path} -> /etc/oratab"
                return 0
            else
                log_warn "  Could not create symlink (will use temp oratab)"
            fi
        else
            log_info "oratab already exists at ${oratab_path}"
            return 0
        fi
    fi

    # No system oratab or couldn't create symlink - create temporary oratab
    if [[ ! -f "$oratab_path" ]]; then
        log_info "Creating temporary oratab for pre-Oracle installation"

        # Determine Oracle Base for dummy entry
        local dummy_base="${ORACLE_BASE_PARAM}"
        if [[ -z "$dummy_base" ]] && [[ "$USER_LEVEL_INSTALL" != "true" ]]; then
            # Try to derive from install prefix
            if [[ "$install_prefix" == */local/oradba ]]; then
                dummy_base="${install_prefix%/local/oradba}"
            else
                dummy_base="/opt/oracle"
            fi
        fi

        # Use custom dummy home or create default
        local dummy_home="${DUMMY_ORACLE_HOME:-${dummy_base}/product/dummy}"

        cat > "$oratab_path" << 'ORATAB_HEADER'
# ==============================================================================
# Temporary oratab file for OraDBA
# ==============================================================================
# This file will be used until Oracle is installed and /etc/oratab is available.
#
# After Oracle installation, you have two options:
#
#   Option 1: Create symlink (recommended if you have write permission):
ORATAB_HEADER

        {
            echo "#     rm -f ${oratab_path}"
            echo "#     ln -sf /etc/oratab ${oratab_path}"
            echo "#"
            echo "#   Option 2: Use oradba_setup.sh helper:"
            echo "#     oradba_setup.sh --link-oratab"
            echo "#"
            echo "# =============================================================================="
            echo ""
        } >> "$oratab_path"

        # Determine if we should add dummy entry
        # Only add dummy if:
        # 1. Explicitly requested via --dummy-home OR
        # 2. No /etc/oratab exists AND no Oracle products found
        local should_add_dummy=false
        
        if [[ -n "$DUMMY_ORACLE_HOME" ]]; then
            # Explicitly requested
            should_add_dummy=true
        elif [[ ! -f "/etc/oratab" ]]; then
            # No system oratab - check if any Oracle products exist
            local has_oracle_products=false
            
            # Check common product locations
            if [[ -n "${dummy_base}" ]]; then
                for check_dir in "${dummy_base}/product" "/u01/app/oracle/product" "/opt/oracle/product"; do
                    if [[ -d "${check_dir}" ]]; then
                        # Count directories that look like Oracle products
                        local product_count
                        product_count=$(find "${check_dir}" -maxdepth 2 -type f \( -name "oracle" -o -name "sqlplus" -o -name "cmctl" -o -name "java" \) 2>/dev/null | wc -l)
                        if [[ ${product_count:-0} -gt 0 ]]; then
                            has_oracle_products=true
                            break
                        fi
                    fi
                done
            fi
            
            # Only add dummy if no Oracle products found
            if [[ "${has_oracle_products}" == "false" ]]; then
                should_add_dummy=true
            fi
        fi

        # Add dummy entry if needed
        if [[ "${should_add_dummy}" == "true" ]]; then
            log_info "  Adding dummy Oracle entry: dummy:${dummy_home}:N"
            echo "# Dummy entry for pre-Oracle environment" >> "$oratab_path"
            echo "# This entry will be hidden from status displays once real Oracle products are found" >> "$oratab_path"
            echo "# To hide this entry from oraup status display:" >> "$oratab_path"
            echo "#   1. Set ORADBA_SHOW_DUMMY_ENTRIES=false in oradba_customer.conf, OR" >> "$oratab_path"
            echo "#   2. Remove this entry once Oracle is installed" >> "$oratab_path"
            echo "dummy:${dummy_home}:N" >> "$oratab_path"
        else
            log_info "  Oracle products detected - dummy entry not needed"
        fi

        log_info "  Temporary oratab created: ${oratab_path}"
        if [[ ! -f "/etc/oratab" ]]; then
            log_warn "  No /etc/oratab found - you're in pre-Oracle installation mode"
            log_warn "  After installing Oracle, create symlink or add entries to ${oratab_path}"
        fi
    fi

    return 0
}

# Extract from local tarball
# ------------------------------------------------------------------------------
# Function: extract_local_tarball
# Purpose.: Extract OraDBA from local tarball file
# Args....: $1 - Path to local tarball file
# Returns.: 0 on success, 1 on failure
# Output..: Extraction status to stdout
# Notes...: Validates file exists and is readable
#           Extracts to TEMP_DIR with filesystem sync for containers
#           Includes retry logic for slow filesystem sync
#           Used for air-gapped installations
# ------------------------------------------------------------------------------
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
    if tar -xzf "$tarball" -C "$TEMP_DIR" 2> /dev/null; then
        # Ensure all file operations are synced to disk
        sync
        # Longer delay for Docker/containerized environments where filesystem sync can be slower
        sleep 1
        
        # Verify critical files exist and are readable (especially installer script)
        local max_retries=5
        local retry_count=0
        while [[ $retry_count -lt $max_retries ]]; do
            if [[ -f "$TEMP_DIR/bin/oradba_install.sh" ]] && [[ -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
                break
            fi
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                sleep 0.5
            fi
        done
        
        # Final verification
        if [[ ! -f "$TEMP_DIR/bin/oradba_install.sh" ]] || [[ ! -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
            log_error "Extraction completed but critical files not accessible"
            log_error "This may indicate filesystem sync issues in containerized environments"
            return 1
        fi
        
        log_info "Local tarball extracted successfully"
        return 0
    else
        log_error "Failed to extract tarball (may be corrupted or not a valid gzip archive)"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: extract_github_release
# Purpose.: Download and extract OraDBA from GitHub releases
# Args....: $1 - Version string (optional, uses latest if empty)
# Returns.: 0 on success, 1 on failure
# Output..: Download and extraction status to stdout
# Notes...: Queries GitHub API for latest version if not specified
#           Supports curl or wget for downloads
#           Includes archived version notice for 0.x releases
#           Verifies download and extracts to TEMP_DIR
# ------------------------------------------------------------------------------
extract_github_release() {
    local version="$1"
    local download_url
    local tarball_name

    # Determine download URL
    if [[ -z "$version" ]]; then
        log_info "Fetching latest release from GitHub..."
        # Get latest release version and construct download URL
        local latest_version
        local api_response
        api_response=$(curl -sL https://api.github.com/repos/oehrlis/oradba/releases/latest)
        
        # Check for API errors (rate limiting, etc.)
        if echo "$api_response" | grep -q '"message".*"API rate limit exceeded"'; then
            log_error "GitHub API rate limit exceeded"
            log_info "You can either:"
            log_info "  1. Wait a few minutes and try again"
            log_info "  2. Use authenticated requests (set GITHUB_TOKEN)"
            log_info "  3. Download manually from: https://github.com/oehrlis/oradba/releases/latest"
            log_info "  4. Install specific version: $0 --github --version 0.19.0"
            return 1
        fi
        
        latest_version=$(echo "$api_response" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
        if [[ -n "$latest_version" ]]; then
            download_url="https://github.com/oehrlis/oradba/releases/latest/download/oradba-${latest_version}.tar.gz"
            tarball_name="oradba-${latest_version}.tar.gz"
        else
            log_error "Failed to determine latest version"
            log_info "API response: $(echo "$api_response" | head -c 200)"
            return 1
        fi
    else
        log_info "Fetching version ${version} from GitHub..."
        
        # Normalize version: strip leading 'v' if present
        version="${version#v}"
        
        # Check if this is an archived version
        check_archived_version "$version"
        
        download_url="https://github.com/oehrlis/oradba/releases/download/v${version}/oradba-${version}.tar.gz"
        tarball_name="oradba-${version}.tar.gz"
    fi

    local tarball_path="${TEMP_DIR}/${tarball_name}"

    # Check for download tool
    local download_cmd=""
    if command -v curl > /dev/null 2>&1; then
        download_cmd="curl"
    elif command -v wget > /dev/null 2>&1; then
        download_cmd="wget"
    else
        log_error "Neither curl nor wget found - cannot download from GitHub"
        log_info "Please install curl or wget, or use --local with a downloaded tarball"
        return 1
    fi

    # Download tarball
    log_info "Downloading from: ${download_url}"
    if [[ "$download_cmd" == "curl" ]]; then
        if ! curl -L -f -o "$tarball_path" "$download_url" 2> /dev/null; then
            log_error "Failed to download from GitHub"
            [[ -n "$version" ]] && log_info "Version ${version} may not exist. Check: https://github.com/oehrlis/oradba/releases"
            return 1
        fi
    else
        if ! wget -q -O "$tarball_path" "$download_url" 2> /dev/null; then
            log_error "Failed to download from GitHub"
            [[ -n "$version" ]] && log_info "Version ${version} may not exist. Check: https://github.com/oehrlis/oradba/releases"
            return 1
        fi
    fi

    # Get file size for logging
    local tarball_size
    tarball_size=$(du -h "$tarball_path" 2> /dev/null | cut -f1)
    log_info "Download completed: ${tarball_size}"

    # Extract downloaded tarball
    log_info "Extracting downloaded tarball..."
    if tar -xzf "$tarball_path" -C "$TEMP_DIR" 2> /dev/null; then
        # Ensure all file operations are synced to disk
        sync
        # Longer delay for Docker/containerized environments where filesystem sync can be slower
        sleep 1
        
        # Verify critical files exist and are readable (especially installer script)
        local max_retries=5
        local retry_count=0
        while [[ $retry_count -lt $max_retries ]]; do
            if [[ -f "$TEMP_DIR/bin/oradba_install.sh" ]] && [[ -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
                break
            fi
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                sleep 0.5
            fi
        done
        
        # Final verification
        if [[ ! -f "$TEMP_DIR/bin/oradba_install.sh" ]] || [[ ! -r "$TEMP_DIR/bin/oradba_install.sh" ]]; then
            log_error "Extraction completed but critical files not accessible"
            log_error "This may indicate filesystem sync issues in containerized environments"
            return 1
        fi
        
        rm -f "$tarball_path" # Clean up downloaded file
        log_info "GitHub release extracted successfully"
        return 0
    else
        log_error "Failed to extract downloaded tarball"
        return 1
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

# Handle update mode
BACKUP_DIR=""
CONFIG_DIR=""
if [[ "$UPDATE_MODE" == "true" ]]; then
    # Perform update pre-checks and backup (capture last line with paths, show rest)
    UPDATE_INFO=$(perform_update 2>&1 | tee /dev/stderr | tail -1)
    BACKUP_DIR="${UPDATE_INFO%%|*}"
    CONFIG_DIR="${UPDATE_INFO##*|}"
else
    echo "==========================================="
    echo "oradba Installer v${INSTALLER_VERSION}"
    echo "==========================================="
    echo "Installation mode: $INSTALL_MODE"
    echo "Installation prefix: $INSTALL_PREFIX"
    [[ -n "$INSTALL_USER" ]] && echo "Install user: $INSTALL_USER"
    [[ "$INSTALL_MODE" == "local" ]] && echo "Local tarball: $LOCAL_TARBALL"
    [[ "$INSTALL_MODE" == "github" ]] && [[ -n "$GITHUB_VERSION" ]] && echo "GitHub version: $GITHUB_VERSION"
    echo ""
fi

# Run pre-flight checks
run_preflight_checks "$INSTALL_PREFIX"

# Validate write permissions to installation prefix
validate_write_permissions "$INSTALL_PREFIX" || exit 1

# Prompt for Oracle Base only if:
#   - No system oratab exists (/etc/oratab or /var/opt/oracle/oratab)
#   - Not in silent mode
#   - No ORACLE_BASE_PARAM set
#   - Not a user-level install
# This is needed for creating the dummy entry in temp oratab
if [[ ! -f "/etc/oratab" ]] && [[ ! -f "/var/opt/oracle/oratab" ]] \
    && [[ "$SILENT_MODE" != "true" ]] \
    && [[ -z "$ORACLE_BASE_PARAM" ]] \
    && [[ "$USER_LEVEL_INSTALL" != "true" ]]; then
    # Pre-Oracle installation scenario - prompt for Oracle Base
    prompt_oracle_base || exit 1
fi

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

# Update INSTALLER_VERSION from extracted VERSION file (for github/local modes)
if [[ -f "$TEMP_DIR/VERSION" ]]; then
    INSTALLER_VERSION=$(cat "$TEMP_DIR/VERSION" | tr -d '[:space:]')
    log_info "Detected version: $INSTALLER_VERSION"
fi

# Create installation directory
if [[ ! -d "$INSTALL_PREFIX" ]]; then
    log_info "Creating installation directory: $INSTALL_PREFIX"
    mkdir -p "$INSTALL_PREFIX"
fi

# Backup modified configuration files before overwriting
backup_modified_files "$INSTALL_PREFIX"

# Copy files
log_info "Installing files..."
cp -r "$TEMP_DIR"/* "$INSTALL_PREFIX/"
# Also copy hidden files (like .oradba.checksum)
cp -r "$TEMP_DIR"/.[!.]* "$INSTALL_PREFIX/" 2> /dev/null || true

# Create log directory
mkdir -p "$INSTALL_PREFIX/log"

# Create temporary oratab if needed (for pre-Oracle installations)
create_temp_oratab "$INSTALL_PREFIX"

# Detect TVD BasEnv / DB*Star coexistence
log_info "Checking for TVD BasEnv / DB*Star..."
BASENV_DETECTED="no"
COEXIST_MODE="standalone"

# Check for basenv markers
if [[ -f "${HOME}/.BE_HOME" ]] || [[ -f "${HOME}/.TVDPERL_HOME" ]] || [[ -n "${BE_HOME}" ]]; then
    BASENV_DETECTED="yes"
    COEXIST_MODE="basenv"
    log_info "TVD BasEnv / DB*Star detected - enabling coexistence mode"
    log_info "OraDBA will not override existing basenv aliases and settings"

    # Show basenv details if available
    if [[ -n "${BE_HOME}" ]]; then
        log_info "  BE_HOME: ${BE_HOME}"
    elif [[ -f "${HOME}/.BE_HOME" ]]; then
        # shellcheck disable=SC1090
        source "${HOME}/.BE_HOME" 2> /dev/null && log_info "  BE_HOME: ${BE_HOME}"
    fi
else
    log_info "No TVD BasEnv / DB*Star detected - standalone mode"
fi

# Create or update oradba_local.conf with coexistence mode
log_info "Configuring coexistence mode..."

# Derive ORACLE_BASE from installation prefix
# Priority:
#   1. Explicit ORACLE_BASE_PARAM (from --base parameter)
#   2. Derive from INSTALL_PREFIX if it follows standard pattern (/path/to/base/local/oradba)
#   3. Don't set (let oradba_standard.conf default take effect)
ORACLE_BASE_LINE="# ORACLE_BASE not set - will use default from oradba_standard.conf"
if [[ -n "$ORACLE_BASE_PARAM" ]]; then
    # Explicit --base parameter was used
    ORACLE_BASE_LINE="export ORACLE_BASE=\"${ORACLE_BASE_PARAM}\""
    log_info "Using ORACLE_BASE from --base parameter: ${ORACLE_BASE_PARAM}"
elif [[ "$INSTALL_PREFIX" == */local/oradba ]]; then
    # Standard installation pattern: /path/to/base/local/oradba
    derived_base="${INSTALL_PREFIX%/local/oradba}"
    ORACLE_BASE_LINE="export ORACLE_BASE=\"${derived_base}\""
    log_info "Derived ORACLE_BASE from installation path: ${derived_base}"
fi

cat > "$INSTALL_PREFIX/etc/oradba_local.conf" << LOCALCONF
# ------------------------------------------------------------------------------
# OraDBA Local Configuration
# ------------------------------------------------------------------------------
# This file is auto-generated during installation and contains local
# system-specific settings. It overrides settings from oradba_core.conf.

# Coexistence mode (auto-detected during installation)
# Values: basenv, standalone
export ORADBA_COEXIST_MODE="${COEXIST_MODE}"

# Oracle Base directory (derived from installation location)
# Overrides the default in oradba_standard.conf
${ORACLE_BASE_LINE}

# Installation metadata
ORADBA_INSTALL_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ORADBA_INSTALL_VERSION="${INSTALLER_VERSION}"
ORADBA_INSTALL_METHOD="${INSTALL_MODE}"
ORADBA_BASENV_DETECTED="${BASENV_DETECTED}"

# To force OraDBA aliases even in coexistence mode, uncomment:
# export ORADBA_FORCE=1
LOCALCONF

# Create installation metadata
log_info "Creating installation metadata..."
cat > "$INSTALL_PREFIX/.install_info" << METADATA
install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
install_version=${INSTALLER_VERSION}
install_method=${INSTALL_MODE}
install_user=${INSTALL_USER:-${USER}}
install_prefix=${INSTALL_PREFIX}
coexist_mode=${COEXIST_MODE}
basenv_detected=${BASENV_DETECTED}
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
    # Run checksum verification with ORADBA_BASE set (skip extension checks during install)
    if ORADBA_BASE="$INSTALL_PREFIX" "$INSTALL_PREFIX/bin/oradba_version.sh" --verify-core > /dev/null 2>&1; then
        log_info "Installation integrity verified"
    else
        log_error "Installation integrity verification FAILED"
        log_error "Some files may be corrupted or missing"
        echo ""
        echo "Running detailed verification:"
        ORADBA_BASE="$INSTALL_PREFIX" "$INSTALL_PREFIX/bin/oradba_version.sh" --verify-core
        echo ""

        # Rollback if this was an update
        if [[ "$UPDATE_MODE" == "true" ]] && [[ -n "$BACKUP_DIR" ]]; then
            log_error "Update failed - rolling back to previous version"
            restore_from_backup "$INSTALL_PREFIX" "$BACKUP_DIR"
            log_info "Rollback completed - previous version restored"
            exit 1
        fi

        log_error "Installation completed but verification failed"
        log_error "Installation directory: $INSTALL_PREFIX"
        exit 1
    fi
else
    log_warn "oradba_version.sh not found - skipping integrity verification"
fi

# Restore preserved configurations if updating
if [[ "$UPDATE_MODE" == "true" ]] && [[ -n "$CONFIG_DIR" ]]; then
    restore_configs "$INSTALL_PREFIX" "$CONFIG_DIR"

    # Update install_info with new version and date (replace existing metadata lines)
    sed -i.bak "s|^install_date=.*|install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)|" "$INSTALL_PREFIX/.install_info"
    sed -i.bak "s|^install_version=.*|install_version=${INSTALLER_VERSION}|" "$INSTALL_PREFIX/.install_info"
    sed -i.bak "s|^install_method=.*|install_method=update|" "$INSTALL_PREFIX/.install_info"
    rm -f "$INSTALL_PREFIX/.install_info.bak"

    # Remove backup if update successful
    if [[ -n "$BACKUP_DIR" ]] && [[ -d "$BACKUP_DIR" ]]; then
        log_info "Update successful - removing backup"
        rm -rf "$BACKUP_DIR"
    fi
fi

# Note: Not creating symlink to avoid conflict with Oracle's /usr/local/bin/oraenv
# Users should explicitly use oraenv.sh or create their own aliases

# Profile integration (issue #24)
update_profile "$INSTALL_PREFIX"

# Installation complete
# Get actual installed version for display
INSTALLED_VERSION=$(cat "$INSTALL_PREFIX/VERSION" 2> /dev/null || echo "$INSTALLER_VERSION")

echo ""
echo "==========================================="
if [[ "$UPDATE_MODE" == "true" ]]; then
    log_info "Update completed successfully!"
    echo "==========================================="
    echo ""
    echo "oradba has been updated at: $INSTALL_PREFIX"
    echo "New version: $INSTALLED_VERSION"
    echo ""
    echo "Configuration files have been preserved"
else
    log_info "Installation completed successfully!"
    echo "==========================================="
    echo ""
    echo "oradba has been installed to: $INSTALL_PREFIX"
fi
echo ""
echo "To set Oracle environment (use oraenv.sh to avoid conflict with Oracle's oraenv):"
echo "  source $INSTALL_PREFIX/bin/oraenv.sh [ORACLE_SID]"
echo ""
echo "Or add to your profile for easier access:"
echo "  alias oraenv='source $INSTALL_PREFIX/bin/oraenv.sh'"
echo ""
echo "Documentation: $INSTALL_PREFIX/README.md"
echo ""

exit 0

__PAYLOAD_BEGINS__
