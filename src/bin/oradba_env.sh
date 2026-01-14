#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-14
# Revision...: 0.19.0
# Purpose....: Oracle environment management utility
# Notes......: Provides commands to list, validate, and manage Oracle environments
#              Part of Phase 1 implementation
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script metadata
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPT_VERSION="0.20.0"

# Setup ORADBA_BASE
ORADBA_BASE="$(dirname "$SCRIPT_DIR")"
export ORADBA_BASE

# Source required libraries
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${ORADBA_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find common library" >&2
    exit 1
fi

if [[ -f "${ORADBA_BASE}/lib/oradba_env_parser.sh" ]]; then
    # shellcheck source=../lib/oradba_env_parser.sh
    source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
else
    echo "ERROR: Cannot find oradba_env_parser.sh library" >&2
    exit 1
fi

if [[ -f "${ORADBA_BASE}/lib/oradba_env_validator.sh" ]]; then
    # shellcheck source=../lib/oradba_env_validator.sh
    source "${ORADBA_BASE}/lib/oradba_env_validator.sh"
fi

# Source Phase 3 libraries (optional)
if [[ -f "${ORADBA_BASE}/lib/oradba_env_status.sh" ]]; then
    # shellcheck source=../lib/oradba_env_status.sh
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
fi

if [[ -f "${ORADBA_BASE}/lib/oradba_env_changes.sh" ]]; then
    # shellcheck source=../lib/oradba_env_changes.sh
    source "${ORADBA_BASE}/lib/oradba_env_changes.sh"
fi

# Set ORATAB_FILE dynamically if not already set
if [[ -z "${ORATAB_FILE}" ]]; then
    ORATAB_FILE="$(get_oratab_path 2>/dev/null || echo "/etc/oratab")"
    export ORATAB_FILE
fi

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Oracle Environment Management Utility - Version ${SCRIPT_VERSION}

Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  list [sids|homes|all]    List available Oracle SIDs and/or Oracle Homes
  show <SID|HOME>          Show detailed information about SID or Oracle Home
  status [SID]             Check status of Oracle instances/services
  validate [level]         Validate current Oracle environment
                           Levels: basic, standard (default), full
  changes                  Check for configuration file changes
  help                     Display this help message
  version                  Display version information

Examples:
  ${SCRIPT_NAME} list                    # List all SIDs and Homes
  ${SCRIPT_NAME} list sids               # List only database SIDs
  ${SCRIPT_NAME} list homes              # List only Oracle Homes
  ${SCRIPT_NAME} show ORCL               # Show details for ORCL SID
  ${SCRIPT_NAME} show /u01/app/oracle/product/19c
  ${SCRIPT_NAME} status                  # Check status of current SID
  ${SCRIPT_NAME} status ORCL             # Check status of specific SID
  ${SCRIPT_NAME} validate                # Validate current environment
  ${SCRIPT_NAME} validate full           # Full validation with database checks
  ${SCRIPT_NAME} changes                 # Check for config changes

Environment Variables:
  ORATAB_FILE            Path to oratab file (default: /etc/oratab)
  ORACLE_SID             Current Oracle SID
  ORACLE_HOME            Current Oracle Home

EOF
}

# ------------------------------------------------------------------------------
# Function: cmd_list
# Purpose.: List available SIDs and/or Homes
# ------------------------------------------------------------------------------
cmd_list() {
    local what="${1:-all}"
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    case "$what" in
        sids)
            echo "=== Oracle Database SIDs (from oratab) ==="
            echo ""
            if [[ -f "$ORATAB_FILE" ]]; then
                oradba_parse_oratab | while IFS='|' read -r sid home flag; do
                    printf "  %-15s %s\n" "$sid" "$home"
                done
            else
                echo "  No oratab file found at: $ORATAB_FILE"
            fi
            ;;
            
        homes)
            echo "=== Oracle Homes (from oradba_homes.conf) ==="
            echo ""
            if [[ -f "$homes_file" ]]; then
                oradba_list_all_homes | while IFS='|' read -r home product short_name; do
                    printf "  %-12s %-10s %s\n" "$short_name" "$product" "$home"
                done
            else
                echo "  No oradba_homes.conf file found"
            fi
            ;;
            
        all|*)
            # List SIDs
            echo "=== Oracle Database SIDs (from oratab) ==="
            echo ""
            if [[ -f "$ORATAB_FILE" ]]; then
                oradba_parse_oratab | while IFS='|' read -r sid home flag; do
                    local product="RDBMS"
                    if [[ "$sid" =~ ^\+ASM ]]; then
                        product="GRID"
                    fi
                    printf "  %-15s %-10s %s\n" "$sid" "$product" "$home"
                done
            else
                echo "  No oratab file found at: $ORATAB_FILE"
            fi
            
            echo ""
            # List Homes
            echo "=== Oracle Homes (from oradba_homes.conf) ==="
            echo ""
            if [[ -f "$homes_file" ]]; then
                oradba_list_all_homes | while IFS='|' read -r home product short_name; do
                    printf "  %-12s %-10s %s\n" "$short_name" "$product" "$home"
                done
            else
                echo "  No oradba_homes.conf file found"
                echo "  Template available at: ${ORADBA_BASE}/templates/etc/oradba_homes.conf.template"
            fi
            ;;
    esac
    
    echo ""
}

# ------------------------------------------------------------------------------
# Function: cmd_show
# Purpose.: Show detailed information about SID or Home
# ------------------------------------------------------------------------------
cmd_show() {
    local target="$1"
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    if [[ -z "$target" ]]; then
        echo "ERROR: No SID or Oracle Home specified" >&2
        return 1
    fi
    
    # Check if it's a path (Oracle Home) or SID
    if [[ -d "$target" ]]; then
        # It's an Oracle Home path
        echo "=== Oracle Home Information ==="
        echo "Path: $target"
        
        # Get metadata from oradba_homes.conf
        local product version edition
        product=$(oradba_get_home_metadata "$target" "Product" 2>/dev/null)
        if [[ -n "$product" ]] && [[ "$product" != "N/A" ]]; then
            version=$(oradba_get_home_metadata "$target" "Version")
            edition=$(oradba_get_home_metadata "$target" "Edition")
            echo "Product: $product"
            echo "Version: $version"
            echo "Edition: $edition"
        else
            # Auto-detect
            product=$(oradba_get_product_type "$target")
            echo "Product: $product (auto-detected)"
        fi
        
    else
        # It's a SID
        echo "=== Oracle SID Information ==="
        echo "SID: $target"
        
        # Find in oratab
        local entry
        entry=$(oradba_find_sid "$target")
        if [[ $? -eq 0 ]]; then
            IFS='|' read -r sid home flag <<< "$entry"
            echo "Oracle Home: $home"
            echo "Auto-Start: $flag"
            
            # Check if home exists
            if [[ -d "$home" ]]; then
                local product
                product=$(oradba_get_product_type "$home")
                echo "Product Type: $product"
                
                # Check if database is running
                if command -v oradba_check_db_running &>/dev/null; then
                    if oradba_check_db_running "$sid"; then
                        echo "Status: RUNNING"
                    else
                        echo "Status: DOWN"
                    fi
                fi
            else
                echo "Warning: Oracle Home does not exist"
            fi
        else
            echo "ERROR: SID '$target' not found in oratab" >&2
            return 1
        fi
    fi
    
    echo ""
}

# ------------------------------------------------------------------------------
# Function: cmd_validate
# Purpose.: Validate current Oracle environment
# ------------------------------------------------------------------------------
cmd_validate() {
    local level="${1:-standard}"
    
    if [[ -z "$ORACLE_HOME" ]]; then
        echo "ERROR: No Oracle environment set (ORACLE_HOME not defined)" >&2
        echo "Run: source oraenv.sh <SID>" >&2
        return 1
    fi
    
    echo "=== Validating Oracle Environment ==="
    echo "ORACLE_SID: ${ORACLE_SID:-not set}"
    echo "ORACLE_HOME: $ORACLE_HOME"
    echo ""
    
    if command -v oradba_validate_environment &>/dev/null; then
        oradba_validate_environment "$level"
    else
        echo "ERROR: Validation library not available" >&2
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: cmd_status
# Purpose.: Check status of Oracle instance/service
# ------------------------------------------------------------------------------
cmd_status() {
    local target="${1:-}"
    
    # If status library not loaded, inform user
    if ! command -v oradba_get_product_status &>/dev/null; then
        echo "Status checking not available (oradba_env_status.sh not found)"
        return 1
    fi
    
    # Use current SID if none specified
    if [[ -z "$target" ]]; then
        target="${ORACLE_SID:-}"
        if [[ -z "$target" ]]; then
            echo "ERROR: No SID specified and ORACLE_SID not set"
            return 1
        fi
    fi
    
    # Get SID info from oratab
    local sid_info
    sid_info=$(oradba_find_sid "$target")
    
    if [[ $? -ne 0 ]] || [[ -z "$sid_info" ]]; then
        echo "ERROR: SID '$target' not found in oratab"
        return 1
    fi
    
    # Parse SID info (format: SID|ORACLE_HOME|FLAG)
    local oracle_sid oracle_home _oracle_flag
    IFS='|' read -r oracle_sid oracle_home _oracle_flag <<< "$sid_info"
    
    # Detect product type
    local product_type
    product_type=$(oradba_detect_product_type "$oracle_home")
    
    echo "=== Oracle Instance/Service Status ==="
    echo "SID:          $oracle_sid"
    echo "HOME:         $oracle_home"
    echo "Product Type: $product_type"
    echo ""
    
    # Get status
    local status
    status=$(oradba_get_product_status "$product_type" "$oracle_sid" "$oracle_home")
    
    echo "Status:       $status"
    
    # Check listener if RDBMS
    if [[ "$product_type" == "RDBMS" || "$product_type" == "GRID" ]]; then
        local listener_status
        listener_status=$(oradba_check_listener_status "LISTENER" "$oracle_home" 2>/dev/null || echo "UNKNOWN")
        echo "Listener:     $listener_status"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: cmd_changes
# Purpose.: Check for configuration file changes
# ------------------------------------------------------------------------------
cmd_changes() {
    # If changes library not loaded, inform user
    if ! command -v oradba_check_config_changes &>/dev/null; then
        echo "Change detection not available (oradba_env_changes.sh not found)"
        return 1
    fi
    
    echo "=== Configuration Change Detection ==="
    echo ""
    
    local changes
    changes=$(oradba_check_config_changes)
    
    if [[ -n "$changes" ]]; then
        echo "Changed files detected:"
        echo "$changes"
        return 0
    else
        echo "No configuration changes detected."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: cmd_version
# Purpose.: Display version information
# ------------------------------------------------------------------------------
cmd_version() {
    cat << EOF
Oracle Environment Management Utility
Version: ${SCRIPT_VERSION}
Part of OraDBA Project
https://github.com/oehrlis/oradba
EOF
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        list)
            cmd_list "$@"
            ;;
        show)
            cmd_show "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        changes)
            cmd_changes "$@"
            ;;
        version)
            cmd_version
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "ERROR: Unknown command: $command" >&2
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main if executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
