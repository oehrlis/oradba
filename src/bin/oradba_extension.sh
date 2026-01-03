#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_extension.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.02
# Revision...: 0.13.0
# Purpose....: Management tool for OraDBA extensions
# Notes......: List, inspect, validate, and manage OraDBA extensions
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o pipefail

# Determine ORADBA_BASE
if [[ -n "${ORADBA_BASE}" ]]; then
    BASE_DIR="${ORADBA_BASE}"
elif [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Script is symlinked, resolve to actual location
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || readlink "${BASH_SOURCE[0]}")"
    BASE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
else
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Source required libraries
# shellcheck source=../lib/common.sh
if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    source "${BASE_DIR}/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library" >&2
    exit 1
fi

# shellcheck source=../lib/extensions.sh
if [[ -f "${BASE_DIR}/lib/extensions.sh" ]]; then
    source "${BASE_DIR}/lib/extensions.sh"
else
    echo "ERROR: Cannot find extensions.sh library" >&2
    exit 1
fi

# Set defaults for extension configuration if not already set
export ORADBA_AUTO_DISCOVER_EXTENSIONS="${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
export ORADBA_LOCAL_BASE="${ORADBA_LOCAL_BASE:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if running in a terminal for colored output
if [[ ! -t 1 ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ------------------------------------------------------------------------------
# Display usage information
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

DESCRIPTION
    Management tool for OraDBA extensions. Provides commands to list, inspect,
    validate, and manage extensions in the OraDBA environment.

COMMANDS
    list [--verbose|-v]
        List all discovered extensions with their status, version, and priority.
        Use --verbose for detailed information including paths and metadata.

    info <extension-name>
        Display detailed information about a specific extension including:
        - Name, version, description
        - Path and directories
        - Priority and enabled status
        - Provided capabilities (bin, sql, rcv, etc, lib)

    validate <extension-name|path>
        Validate the structure and configuration of an extension.
        Reports warnings for missing metadata, empty directories, or issues.

    validate-all
        Validate all discovered extensions.

    discover
        Show auto-discovered extensions in \${ORADBA_LOCAL_BASE}.

    paths
        Display the search paths for extensions (auto-discovery and manual).

    enabled
        List only enabled extensions that will be loaded.

    disabled
        List only disabled extensions that will be skipped.

    help
        Display this help message.

OPTIONS
    -v, --verbose       Show detailed information
    -h, --help          Display this help message

ENVIRONMENT VARIABLES
    ORADBA_BASE                     Base directory for OraDBA installation
    ORADBA_LOCAL_BASE               Base directory for local extensions
    ORADBA_AUTO_DISCOVER_EXTENSIONS Enable/disable auto-discovery (true/false)
    ORADBA_EXTENSION_PATHS          Colon-separated list of manual extension paths
    ORADBA_EXT_<NAME>_ENABLED       Enable/disable specific extension (true/false)
    ORADBA_EXT_<NAME>_PRIORITY      Override priority for specific extension

EXAMPLES
    # List all extensions
    $(basename "$0") list

    # List with details
    $(basename "$0") list --verbose

    # Show info about specific extension
    $(basename "$0") info customer

    # Validate an extension
    $(basename "$0") validate customer

    # Validate all extensions
    $(basename "$0") validate-all

    # Show enabled extensions
    $(basename "$0") enabled

SEE ALSO
    doc/extension-system.md - Complete extension system documentation

EOF
}

# ------------------------------------------------------------------------------
# Format status with color
# ------------------------------------------------------------------------------
format_status() {
    local status="$1"
    case "${status}" in
        Enabled)
            echo -e "${GREEN}${status}${NC}"
            ;;
        Disabled)
            echo -e "${RED}${status}${NC}"
            ;;
        *)
            echo "${status}"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Command: list - List all extensions
# ------------------------------------------------------------------------------
cmd_list() {
    local verbose=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    echo -e "${BOLD}OraDBA Extensions${NC}"
    echo ""
    
    # Get all extensions
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    
    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        echo ""
        echo "Search locations:"
        echo "  Auto-discovery: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
        if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" == "true" ]]; then
            echo "  Local base: ${ORADBA_LOCAL_BASE:-not set}"
        fi
        if [[ -n "${ORADBA_EXTENSION_PATHS}" ]]; then
            echo "  Manual paths: ${ORADBA_EXTENSION_PATHS}"
        fi
        return 0
    fi
    
    # Sort by priority
    local sorted
    mapfile -t sorted < <(sort_extensions_by_priority "${extensions[@]}")
    
    if [[ "${verbose}" == "true" ]]; then
        # Verbose output
        for ext_path in "${sorted[@]}"; do
            local name version description priority enabled_status
            name="$(get_extension_name "${ext_path}")"
            version="$(get_extension_version "${ext_path}")"
            description="$(get_extension_description "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"
            
            if is_extension_enabled "${name}" "${ext_path}"; then
                enabled_status="Enabled"
            else
                enabled_status="Disabled"
            fi
            
            echo -e "${CYAN}${name}${NC} (${version})"
            echo "  Status: $(format_status "${enabled_status}")"
            echo "  Priority: ${priority}"
            echo "  Path: ${ext_path}"
            if [[ -n "${description}" ]]; then
                echo "  Description: ${description}"
            fi
            echo ""
        done
    else
        # Compact output - table format
        printf "%-20s %-12s %-10s %-10s\n" "NAME" "VERSION" "PRIORITY" "STATUS"
        printf "%-20s %-12s %-10s %-10s\n" "----" "-------" "--------" "------"
        
        for ext_path in "${sorted[@]}"; do
            local name version priority enabled_status
            name="$(get_extension_name "${ext_path}")"
            version="$(get_extension_version "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"
            
            if is_extension_enabled "${name}" "${ext_path}"; then
                enabled_status="Enabled"
            else
                enabled_status="Disabled"
            fi
            
            printf "%-20s %-12s %-10s " "${name}" "${version}" "${priority}"
            format_status "${enabled_status}"
        done
    fi
    
    echo ""
    echo "Total: ${#extensions[@]} extension(s)"
}

# ------------------------------------------------------------------------------
# Command: info - Show detailed extension info
# ------------------------------------------------------------------------------
cmd_info() {
    local ext_name="$1"
    
    if [[ -z "${ext_name}" ]]; then
        echo "ERROR: Extension name required" >&2
        echo "Usage: $(basename "$0") info <extension-name>" >&2
        return 1
    fi
    
    # Find extension
    local extensions ext_path found=false
    mapfile -t extensions < <(get_all_extensions)
    
    for path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${path}")"
        if [[ "${name}" == "${ext_name}" ]]; then
            ext_path="${path}"
            found=true
            break
        fi
    done
    
    if [[ "${found}" != "true" ]]; then
        echo "ERROR: Extension '${ext_name}' not found" >&2
        return 1
    fi
    
    # Show info using library function
    show_extension_info "${ext_path}"
}

# ------------------------------------------------------------------------------
# Command: validate - Validate extension structure
# ------------------------------------------------------------------------------
cmd_validate() {
    local target="$1"
    
    if [[ -z "${target}" ]]; then
        echo "ERROR: Extension name or path required" >&2
        echo "Usage: $(basename "$0") validate <extension-name|path>" >&2
        return 1
    fi
    
    local ext_path
    
    # Check if target is a path
    if [[ -d "${target}" ]]; then
        ext_path="${target}"
    else
        # Find extension by name
        local extensions found=false
        mapfile -t extensions < <(get_all_extensions)
        
        for path in "${extensions[@]}"; do
            local name
            name="$(get_extension_name "${path}")"
            if [[ "${name}" == "${target}" ]]; then
                ext_path="${path}"
                found=true
                break
            fi
        done
        
        if [[ "${found}" != "true" ]]; then
            echo "ERROR: Extension '${target}' not found" >&2
            return 1
        fi
    fi
    
    # Validate using library function
    local name
    name="$(basename "${ext_path}")"
    echo -e "${BOLD}Validating extension: ${name}${NC}"
    echo ""
    
    if validate_extension "${ext_path}"; then
        echo ""
        echo -e "${GREEN}✓ Validation passed${NC}"
        return 0
    else
        echo ""
        echo -e "${YELLOW}⚠ Validation completed with warnings${NC}"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# Command: validate-all - Validate all extensions
# ------------------------------------------------------------------------------
cmd_validate_all() {
    echo -e "${BOLD}Validating all extensions${NC}"
    echo ""
    
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    
    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi
    
    local total=${#extensions[@]}
    local passed=0
    local warnings=0
    
    for ext_path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${ext_path}")"
        echo -e "${CYAN}${name}${NC} (${ext_path})"
        
        if validate_extension "${ext_path}" 2>&1 | grep -q "Warning"; then
            warnings=$((warnings + 1))
        else
            passed=$((passed + 1))
        fi
        echo ""
    done
    
    echo "----------------------------------------"
    echo "Total extensions: ${total}"
    echo -e "${GREEN}Passed: ${passed}${NC}"
    if [[ ${warnings} -gt 0 ]]; then
        echo -e "${YELLOW}With warnings: ${warnings}${NC}"
    fi
}

# ------------------------------------------------------------------------------
# Command: discover - Show auto-discovered extensions
# ------------------------------------------------------------------------------
cmd_discover() {
    echo -e "${BOLD}Auto-Discovery Configuration${NC}"
    echo ""
    echo "Auto-discovery: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
    echo "Local base: ${ORADBA_LOCAL_BASE:-not set}"
    echo ""
    
    if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" != "true" ]]; then
        echo "Auto-discovery is disabled."
        return 0
    fi
    
    if [[ -z "${ORADBA_LOCAL_BASE}" || ! -d "${ORADBA_LOCAL_BASE}" ]]; then
        echo "Local base directory not found or not set."
        return 0
    fi
    
    echo -e "${BOLD}Auto-Discovered Extensions:${NC}"
    echo ""
    
    local discovered
    mapfile -t discovered < <(discover_extensions)
    
    if [[ ${#discovered[@]} -eq 0 ]]; then
        echo "No extensions discovered in ${ORADBA_LOCAL_BASE}"
        return 0
    fi
    
    for ext_path in "${discovered[@]}"; do
        local name
        name="$(basename "${ext_path}")"
        echo "  ${name} -> ${ext_path}"
    done
    
    echo ""
    echo "Total: ${#discovered[@]} extension(s)"
}

# ------------------------------------------------------------------------------
# Command: paths - Show extension search paths
# ------------------------------------------------------------------------------
cmd_paths() {
    echo -e "${BOLD}Extension Search Paths${NC}"
    echo ""
    
    echo "Auto-discovery:"
    echo "  Enabled: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
    if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" == "true" ]]; then
        echo "  Base: ${ORADBA_LOCAL_BASE:-not set}"
        if [[ -d "${ORADBA_LOCAL_BASE}" ]]; then
            echo "  Status: ${GREEN}exists${NC}"
        else
            echo "  Status: ${RED}not found${NC}"
        fi
    fi
    
    echo ""
    echo "Manual paths:"
    if [[ -n "${ORADBA_EXTENSION_PATHS}" ]]; then
        IFS=':' read -ra paths <<< "${ORADBA_EXTENSION_PATHS}"
        for path in "${paths[@]}"; do
            if [[ -d "${path}" ]]; then
                echo "  ${path} ${GREEN}✓${NC}"
            else
                echo "  ${path} ${RED}✗${NC}"
            fi
        done
    else
        echo "  (none configured)"
    fi
}

# ------------------------------------------------------------------------------
# Command: enabled - List enabled extensions
# ------------------------------------------------------------------------------
cmd_enabled() {
    echo -e "${BOLD}Enabled Extensions${NC}"
    echo ""
    
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    
    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi
    
    local sorted
    mapfile -t sorted < <(sort_extensions_by_priority "${extensions[@]}")
    
    local count=0
    printf "%-20s %-12s %-10s\n" "NAME" "VERSION" "PRIORITY"
    printf "%-20s %-12s %-10s\n" "----" "-------" "--------"
    
    for ext_path in "${sorted[@]}"; do
        local name version priority
        name="$(get_extension_name "${ext_path}")"
        
        if is_extension_enabled "${name}" "${ext_path}"; then
            version="$(get_extension_version "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"
            printf "%-20s %-12s %-10s\n" "${name}" "${version}" "${priority}"
            count=$((count + 1))
        fi
    done
    
    echo ""
    echo "Total: ${count} enabled extension(s)"
}

# ------------------------------------------------------------------------------
# Command: disabled - List disabled extensions
# ------------------------------------------------------------------------------
cmd_disabled() {
    echo -e "${BOLD}Disabled Extensions${NC}"
    echo ""
    
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    
    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi
    
    local count=0
    printf "%-20s %-12s\n" "NAME" "VERSION"
    printf "%-20s %-12s\n" "----" "-------"
    
    for ext_path in "${extensions[@]}"; do
        local name version
        name="$(get_extension_name "${ext_path}")"
        
        if ! is_extension_enabled "${name}" "${ext_path}"; then
            version="$(get_extension_version "${ext_path}")"
            printf "%-20s %-12s\n" "${name}" "${version}"
            count=$((count + 1))
        fi
    done
    
    echo ""
    echo "Total: ${count} disabled extension(s)"
}

# ------------------------------------------------------------------------------
# Main entry point
# ------------------------------------------------------------------------------
main() {
    # Parse command
    local command="${1:-help}"
    shift || true
    
    case "${command}" in
        list)
            cmd_list "$@"
            ;;
        info)
            cmd_info "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        validate-all)
            cmd_validate_all "$@"
            ;;
        discover)
            cmd_discover "$@"
            ;;
        paths)
            cmd_paths "$@"
            ;;
        enabled)
            cmd_enabled "$@"
            ;;
        disabled)
            cmd_disabled "$@"
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "ERROR: Unknown command: ${command}" >&2
            echo ""
            usage
            return 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# EOF
