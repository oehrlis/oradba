#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_check.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.14.0
# Purpose....: System prerequisites and Oracle environment verification script
# Notes......: Validates system readiness for OraDBA installation and usage.
#              Can be run standalone BEFORE installation to verify prerequisites,
#              or AFTER installation for environment troubleshooting.
#              Checks system tools, disk space, Oracle environment, and connectivity.
#              Available as standalone script from GitHub releases.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o pipefail

# Script metadata
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.14.0"

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
CHECKS_INFO=0

# Logging functions
log_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

log_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

log_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((CHECKS_WARNING++))
}

log_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
    ((CHECKS_INFO++))
}

log_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "$(printf '%.0s-' $(seq 1 ${#1}))"
}

# Usage information
usage() {
    cat << EOF
OraDBA System Check - Version ${SCRIPT_VERSION}

Validates system prerequisites and Oracle environment readiness.
Can be run BEFORE installation or AFTER for troubleshooting.

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -d, --dir PATH      Check disk space for specific directory
    -q, --quiet         Minimal output (errors only)
    -v, --verbose       Verbose output with additional details
    -h, --help          Show this help message
    --version           Show version information

EXIT CODES:
    0   All critical checks passed
    1   One or more critical checks failed
    2   Invalid usage or arguments

EXAMPLES:
    # Pre-installation check (download from GitHub releases)
    curl -sL https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh | bash

    # Basic system check
    $SCRIPT_NAME

    # Check with specific installation directory
    $SCRIPT_NAME --dir /opt/oradba

    # Verbose output for troubleshooting
    $SCRIPT_NAME --verbose

CHECKS PERFORMED:
    - System tools and utilities (bash, tar, awk, sed, grep)
    - Checksum tools (sha256sum/shasum)
    - Base64 encoder (for installer with embedded payload)
    - Optional tools (rlwrap, curl/wget, less)
    - Disk space availability
    - Oracle environment variables (ORACLE_HOME, ORACLE_BASE, etc.)
    - Oracle binaries and tools (sqlplus, rman, lsnrctl)
    - Database connectivity (if environment configured)
    - Oracle version information
    - OraDBA installation status

DOWNLOAD:
    Standalone version available from GitHub releases:
    https://github.com/oehrlis/oradba/releases

EOF
    exit 0
}

# Parse command line arguments
CHECK_DIR="${HOME}/oradba"
VERBOSE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            CHECK_DIR="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --version)
            echo "OraDBA System Check v${SCRIPT_VERSION}"
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 2
            ;;
    esac
done

# Print banner
if [[ "$QUIET" != "true" ]]; then
    # Calculate padding for centered version text
    version_text="Version ${SCRIPT_VERSION}"
    box_width=60  # Inner width of the box
    version_length=${#version_text}
    padding=$(( (box_width - version_length) / 2 ))
    version_line=$(printf "║%*s%s%*s║" $padding "" "$version_text" $((box_width - version_length - padding)) "")
    
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          OraDBA System Prerequisites Check                 ║${NC}"
    echo -e "${BOLD}${version_line}${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
fi

# =============================================================================
# System Information
# =============================================================================
check_system_info() {
    log_header "System Information"
    
    # OS Type
    local os_type
    os_type=$(uname -s)
    log_info "OS Type: $os_type"
    
    # OS Version
    if [[ -f /etc/os-release ]]; then
        local os_name
        os_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
        log_info "OS Version: $os_name"
    elif [[ "$os_type" == "Darwin" ]]; then
        local os_version
        os_version=$(sw_vers -productVersion)
        log_info "OS Version: macOS $os_version"
    else
        log_info "OS Version: Unable to determine"
    fi
    
    # Hostname
    local hostname
    hostname=$(hostname)
    log_info "Hostname: $hostname"
    
    # Current User
    local current_user
    current_user=$(whoami)
    log_info "Current User: $current_user"
    
    # Shell
    log_info "Shell: $SHELL"
}

# =============================================================================
# System Tools Check
# =============================================================================
check_system_tools() {
    log_header "System Tools"
    
    local tools=(
        "bash:Bash shell"
        "tar:Archive extraction"
        "awk:Text processing"
        "sed:Stream editor"
        "grep:Pattern matching"
        "find:File search"
        "sort:Sorting utility"
    )
    
    local tools_ok=true
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        
        if command -v "$tool" >/dev/null 2>&1; then
            if [[ "$VERBOSE" == "true" ]]; then
                local version
                version=$($tool --version 2>&1 | head -1 || echo "unknown")
                log_pass "$tool found - $desc ($version)"
            else
                log_pass "$tool - $desc"
            fi
        else
            log_fail "$tool missing - $desc"
            tools_ok=false
        fi
    done
    
    # Check for shasum or sha256sum
    if command -v sha256sum >/dev/null 2>&1; then
        log_pass "sha256sum - Checksum verification"
    elif command -v shasum >/dev/null 2>&1; then
        log_pass "shasum - Checksum verification"
    else
        log_fail "sha256sum/shasum missing - Checksum verification"
        tools_ok=false
    fi
    
    # Check for base64 (needed for installer with embedded payload)
    if command -v base64 >/dev/null 2>&1; then
        log_pass "base64 - Payload decoding (installer)"
    else
        log_warn "base64 not found - Required for installer with embedded payload"
        [[ "$VERBOSE" == "true" ]] && log_info "  Note: Not required for tarball installation"
    fi
    
    if [ "$tools_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Optional Tools Check
# =============================================================================
check_optional_tools() {
    log_header "Optional Tools"
    
    # rlwrap
    if command -v rlwrap >/dev/null 2>&1; then
        local rlwrap_version
        rlwrap_version=$(rlwrap -v 2>&1 | head -1 || echo "unknown")
        log_pass "rlwrap found - Enhanced readline support"
        [[ "$VERBOSE" == "true" ]] && log_info "  Version: $rlwrap_version"
    else
        log_warn "rlwrap not found - Install for better CLI experience"
        [[ "$VERBOSE" == "true" ]] && log_info "  Install: yum install rlwrap | apt install rlwrap | brew install rlwrap"
    fi
    
    # less
    if command -v less >/dev/null 2>&1; then
        log_pass "less - Paging support"
    else
        log_warn "less not found - Some scripts use less for paging"
    fi
    
    # curl/wget
    local download_tool=""
    if command -v curl >/dev/null 2>&1; then
        download_tool="curl"
        log_pass "curl - Download support"
    fi
    if command -v wget >/dev/null 2>&1; then
        download_tool="${download_tool:+$download_tool, }wget"
        log_pass "wget - Download support"
    fi
    if [[ -z "$download_tool" ]]; then
        log_warn "curl/wget not found - Required for GitHub installation mode"
    fi
}

# =============================================================================
# Disk Space Check
# =============================================================================
check_disk_space() {
    log_header "Disk Space"
    
    local check_dir="$CHECK_DIR"
    local required_mb=100
    
    # Find existing parent directory
    while [[ ! -d "$check_dir" ]] && [[ "$check_dir" != "/" ]]; do
        check_dir="$(dirname "$check_dir")"
    done
    
    log_info "Checking: $check_dir"
    
    if command -v df >/dev/null 2>&1; then
        local available_mb
        available_mb=$(df -Pm "$check_dir" 2>/dev/null | awk 'NR==2 {print $4}')
        
        if [[ -n "$available_mb" ]] && [[ "$available_mb" =~ ^[0-9]+$ ]]; then
            log_info "Available: ${available_mb} MB"
            log_info "Required: ${required_mb} MB"
            
            if [[ $available_mb -ge $required_mb ]]; then
                log_pass "Sufficient disk space"
            else
                log_fail "Insufficient disk space (need ${required_mb} MB, have ${available_mb} MB)"
                return 1
            fi
        else
            log_warn "Unable to determine disk space"
        fi
    else
        log_warn "df command not found - cannot verify disk space"
    fi
}

# =============================================================================
# Oracle Environment Check
# =============================================================================
check_oracle_environment() {
    log_header "Oracle Environment Variables"
    
    # ORACLE_HOME
    if [[ -n "$ORACLE_HOME" ]]; then
        if [[ -d "$ORACLE_HOME" ]]; then
            log_pass "ORACLE_HOME set and exists: $ORACLE_HOME"
        else
            log_fail "ORACLE_HOME set but directory does not exist: $ORACLE_HOME"
        fi
    else
        log_info "ORACLE_HOME not set (not required for OraDBA installation)"
    fi
    
    # ORACLE_BASE
    if [[ -n "$ORACLE_BASE" ]]; then
        if [[ -d "$ORACLE_BASE" ]]; then
            log_pass "ORACLE_BASE set and exists: $ORACLE_BASE"
        else
            log_warn "ORACLE_BASE set but directory does not exist: $ORACLE_BASE"
        fi
    else
        log_info "ORACLE_BASE not set"
    fi
    
    # ORACLE_SID
    if [[ -n "$ORACLE_SID" ]]; then
        log_pass "ORACLE_SID set: $ORACLE_SID"
    else
        log_info "ORACLE_SID not set"
    fi
    
    # TNS_ADMIN
    if [[ -n "$TNS_ADMIN" ]]; then
        if [[ -d "$TNS_ADMIN" ]]; then
            log_pass "TNS_ADMIN set and exists: $TNS_ADMIN"
        else
            log_warn "TNS_ADMIN set but directory does not exist: $TNS_ADMIN"
        fi
    else
        log_info "TNS_ADMIN not set"
    fi
    
    return 0  # Environment variables are informational
}

# =============================================================================
# Oracle Tools Check
# =============================================================================
check_oracle_tools() {
    log_header "Oracle Tools"
    
    if [[ -z "$ORACLE_HOME" ]]; then
        log_info "ORACLE_HOME not set - skipping Oracle tools check"
        return 0
    fi
    
    local tools=(
        "sqlplus:SQL*Plus"
        "rman:Recovery Manager"
        "lsnrctl:Listener Control"
        "tnsping:TNS Ping"
    )
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        
        if command -v "$tool" >/dev/null 2>&1; then
            local tool_path
            tool_path=$(command -v "$tool")
            log_pass "$tool - $desc"
            [[ "$VERBOSE" == "true" ]] && log_info "  Path: $tool_path"
        else
            log_warn "$tool not found - $desc"
        fi
    done
}

# =============================================================================
# Database Connectivity Check
# =============================================================================
check_database_connectivity() {
    log_header "Database Connectivity"
    
    if [[ -z "$ORACLE_HOME" ]] || [[ -z "$ORACLE_SID" ]]; then
        log_info "ORACLE_HOME or ORACLE_SID not set - skipping connectivity check"
        return 0
    fi
    
    if ! command -v sqlplus >/dev/null 2>&1; then
        log_info "sqlplus not found - skipping connectivity check"
        return 0
    fi
    
    # Check if database process is running
    if pgrep -f "ora_pmon_${ORACLE_SID}" >/dev/null 2>&1 || \
       pgrep -f "db_pmon_${ORACLE_SID}" >/dev/null 2>&1; then
        log_pass "Database process found for $ORACLE_SID"
        
        # Try to connect
        if timeout 5 sqlplus -S / as sysdba <<< "SELECT 'CONNECTION_OK' FROM DUAL;" 2>&1 | grep -q "CONNECTION_OK"; then
            log_pass "Database connection successful"
            
            # Get database version
            if [[ "$VERBOSE" == "true" ]]; then
                local db_version
                db_version=$(sqlplus -S / as sysdba <<< "SELECT banner FROM v\$version WHERE ROWNUM=1;" 2>/dev/null | grep "Oracle")
                [[ -n "$db_version" ]] && log_info "  Version: $db_version"
            fi
        else
            log_warn "Database process found but connection failed"
        fi
    else
        log_info "No database process found for ORACLE_SID: $ORACLE_SID"
    fi
}

# =============================================================================
# Oracle Versions Check
# =============================================================================
check_oracle_versions() {
    log_header "Oracle Versions"
    
    # Check for oraInst.loc to find Oracle Inventory
    local inventory_loc=""
    if [[ -f /etc/oraInst.loc ]]; then
        inventory_loc=$(grep "^inventory_loc=" /etc/oraInst.loc | cut -d'=' -f2)
    elif [[ -f /var/opt/oracle/oraInst.loc ]]; then
        inventory_loc=$(grep "^inventory_loc=" /var/opt/oracle/oraInst.loc | cut -d'=' -f2)
    fi
    
    if [[ -n "$inventory_loc" ]] && [[ -f "$inventory_loc/ContentsXML/inventory.xml" ]]; then
        log_info "Oracle Inventory: $inventory_loc"
        
        # Parse inventory.xml for Oracle Homes
        local homes_found=0
        while IFS= read -r line; do
            if [[ "$line" =~ LOC=\"([^\"]+)\" ]] && [[ "$line" =~ TYPE=\"O\" ]]; then
                local home="${BASH_REMATCH[1]}"
                if [[ -d "$home" ]]; then
                    ((homes_found++))
                    log_info "Oracle Home $homes_found: $home"
                    
                    # Get version if possible
                    if [[ -f "$home/bin/sqlplus" ]] && [[ "$VERBOSE" == "true" ]]; then
                        local version
                        version=$("$home/bin/sqlplus" -version 2>/dev/null | grep "^SQL" | awk '{print $3}')
                        [[ -n "$version" ]] && log_info "  Version: $version"
                    fi
                fi
            fi
        done < "$inventory_loc/ContentsXML/inventory.xml"
        
        if [[ $homes_found -eq 0 ]]; then
            log_info "No Oracle Homes found in inventory"
        fi
    else
        log_info "Oracle Inventory not found"
        
        # Fallback: Check common locations
        local common_locs=(
            "/u01/app/oracle/product"
            "/opt/oracle/product"
            "$HOME/oracle/product"
        )
        
        for loc in "${common_locs[@]}"; do
            if [[ -d "$loc" ]]; then
                log_info "Found Oracle product directory: $loc"
                for version_dir in "$loc"/*; do
                    if [[ -d "$version_dir/bin" ]] && [[ -f "$version_dir/bin/sqlplus" ]]; then
                        log_info "  Oracle Home: $version_dir"
                    fi
                done
            fi
        done
    fi
}

# =============================================================================
# OraDBA Installation Check
# =============================================================================
check_oradba_installation() {
    log_header "OraDBA Installation"
    
    if [[ -d "$CHECK_DIR" ]]; then
        log_pass "OraDBA directory exists: $CHECK_DIR"
        
        # Check for .install_info
        if [[ -f "$CHECK_DIR/.install_info" ]]; then
            log_pass ".install_info found"
            
            if [[ "$VERBOSE" == "true" ]]; then
                while IFS='=' read -r key value; do
                    [[ "$key" =~ ^#.*$ ]] && continue
                    [[ -z "$key" ]] && continue
                    log_info "  $key: $value"
                done < "$CHECK_DIR/.install_info"
            fi
        else
            log_warn ".install_info not found - may not be installed via installer"
        fi
        
        # Check for key directories
        local dirs=("bin" "lib" "sql" "etc")
        local missing_dirs=()
        
        for dir in "${dirs[@]}"; do
            if [[ -d "$CHECK_DIR/$dir" ]]; then
                log_pass "$dir/ directory exists"
            else
                log_warn "$dir/ directory missing"
                missing_dirs+=("$dir")
            fi
        done
        
        if [[ ${#missing_dirs[@]} -gt 0 ]]; then
            log_warn "Incomplete installation - missing directories: ${missing_dirs[*]}"
        fi
    else
        log_info "OraDBA not installed at: $CHECK_DIR"
        log_info "Use --dir to check different location"
    fi
}

# =============================================================================
# Main execution
# =============================================================================

[[ "$QUIET" != "true" ]] && check_system_info

# Critical checks
critical_failed=false

check_system_tools || critical_failed=true
[[ "$QUIET" != "true" ]] && check_optional_tools
check_disk_space || critical_failed=true

# Oracle-related checks (informational)
[[ "$QUIET" != "true" ]] && check_oracle_environment
[[ "$QUIET" != "true" ]] && check_oracle_tools
[[ "$QUIET" != "true" ]] && check_database_connectivity
[[ "$QUIET" != "true" ]] && check_oracle_versions

# OraDBA installation check
[[ "$QUIET" != "true" ]] && check_oradba_installation

# Summary
if [[ "$QUIET" != "true" ]]; then
    log_header "Summary"
    echo -e "  ${GREEN}✓ Passed:${NC}   $CHECKS_PASSED"
    echo -e "  ${RED}✗ Failed:${NC}   $CHECKS_FAILED"
    echo -e "  ${YELLOW}⚠ Warnings:${NC} $CHECKS_WARNING"
    echo -e "  ${BLUE}ℹ Info:${NC}     $CHECKS_INFO"
    echo ""
fi

# Exit status
if [[ "$critical_failed" == "true" ]]; then
    [[ "$QUIET" != "true" ]] && echo -e "${RED}${BOLD}System check FAILED - critical prerequisites missing${NC}"
    exit 1
else
    [[ "$QUIET" != "true" ]] && echo -e "${GREEN}${BOLD}System check PASSED - ready for OraDBA${NC}"
    exit 0
fi
