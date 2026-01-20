#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-15
# Revision...: 1.0.0
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
readonly SCRIPT_VERSION="1.0.0"

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

# Source registry library (for auto-sync)
if [[ -f "${ORADBA_BASE}/lib/oradba_registry.sh" ]]; then
    # shellcheck source=../lib/oradba_registry.sh
    source "${ORADBA_BASE}/lib/oradba_registry.sh"
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
            # Sync database homes from oratab first
            if type -t oradba_registry_sync_oratab &>/dev/null; then
                oradba_registry_sync_oratab >/dev/null 2>&1
            fi
            
            echo "=== Oracle Homes (from oradba_homes.conf) ==="
            echo ""
            if [[ -f "$homes_file" ]]; then
                oradba_list_all_homes | while IFS='|' read -r name path ptype _order alias_name; do
                    local display_name="${alias_name:-$name}"
                    printf "  %-15s %-10s %s\n" "$display_name" "$ptype" "$path"
                done
            else
                echo "  No oradba_homes.conf file found"
            fi
            ;;
            
        all|*)
            # Sync database homes from oratab first
            if type -t oradba_registry_sync_oratab &>/dev/null; then
                oradba_registry_sync_oratab >/dev/null 2>&1
            fi
            
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
                oradba_list_all_homes | while IFS='|' read -r name path ptype _order alias_name; do
                    local display_name="${alias_name:-$name}"
                    printf "  %-15s %-10s %s\n" "$display_name" "$ptype" "$path"
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
    
    # Auto-sync database homes from oratab
    if type -t oradba_registry_sync_oratab &>/dev/null; then
        oradba_registry_sync_oratab >/dev/null 2>&1
    fi
    
    # Try to find target in oradba_homes.conf first (by name or alias)
    local home_entry
    if [[ -f "$homes_file" ]] && home_entry=$(grep -v "^#\|^$" "$homes_file" | grep -E "^${target}:|:${target}:" | head -1); then
        # Found in oradba_homes.conf - extract details
        IFS=':' read -r name path ptype _order alias_name desc version <<< "$home_entry"
        echo "=== Oracle Home Information ==="
        echo "Name: ${alias_name:-$name}"
        echo "Path: $path"
        echo "Product: $ptype"
        [[ -n "$version" ]] && echo "Version: $version"
        [[ -n "$desc" ]] && echo "Description: $desc"
        
        # Check if home exists
        if [[ ! -d "$path" ]]; then
            echo "Warning: Oracle Home does not exist"
        fi
        echo ""
        return 0
    # Check if it's a path (Oracle Home)
    elif [[ -d "$target" ]]; then
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
# Purpose.: Validate current Oracle environment or specified target
# ------------------------------------------------------------------------------
cmd_validate() {
    local target="${1:-}"
    local level="${2:-standard}"
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    # Auto-sync database homes from oratab
    if type -t oradba_registry_sync_oratab &>/dev/null; then
        oradba_registry_sync_oratab >/dev/null 2>&1
    fi
    
    # If target specified, try to resolve it
    local validate_home="$ORACLE_HOME"
    local validate_sid="${ORACLE_SID:-}"
    local target_name=""
    local product_type=""
    
    if [[ -n "$target" ]]; then
        # Try oradba_homes.conf first
        local home_entry
        if [[ -f "$homes_file" ]] && home_entry=$(grep -v "^#\|^$" "$homes_file" | grep -E "^${target}:|:${target}:" | head -1); then
            IFS=':' read -r name path ptype _order _alias _desc _version <<< "$home_entry"
            validate_home="$path"
            target_name="$name"
            product_type="$ptype"
            validate_sid=""  # Oracle Homes don't have SID
            
            # Apply DataSafe adjustment via plugin if needed
            if [[ "$product_type" == "datasafe" ]]; then
                local plugin_file="${ORADBA_BASE}/src/lib/plugins/datasafe_plugin.sh"
                if [[ -f "${plugin_file}" ]]; then
                    # shellcheck source=/dev/null
                    source "${plugin_file}"
                    validate_home=$(plugin_adjust_environment "${validate_home}")
                elif [[ -d "${validate_home}/oracle_cman_home" ]]; then
                    # Fallback
                    validate_home="${validate_home}/oracle_cman_home"
                fi
            fi
        else
            # Try oratab
            local sid_info
            sid_info=$(oradba_find_sid "$target")
            if [[ $? -eq 0 ]]; then
                IFS='|' read -r sid home _flag <<< "$sid_info"
                validate_home="$home"
                validate_sid="$sid"
                target_name="$sid"
            else
                echo "ERROR: Target '$target' not found in oratab or oradba_homes.conf" >&2
                return 1
            fi
        fi
    fi
    
    if [[ -z "$validate_home" ]]; then
        echo "ERROR: No Oracle environment set (ORACLE_HOME not defined)" >&2
        echo "Run: source oraenv.sh <SID> or specify a target" >&2
        return 1
    fi
    
    echo "=== Validating Oracle Environment ==="
    if [[ -n "$target_name" ]]; then
        echo "Target: $target_name"
    fi
    echo "ORACLE_SID: ${validate_sid:-not set}"
    echo "ORACLE_HOME: $validate_home"
    [[ -n "$product_type" ]] && echo "Product Type: $product_type"
    echo ""
    
    # Temporarily set ORACLE_HOME and ORACLE_SID if validating a different target
    local saved_oracle_home="$ORACLE_HOME"
    local saved_oracle_sid="$ORACLE_SID"
    export ORACLE_HOME="$validate_home"
    [[ -n "$validate_sid" ]] && export ORACLE_SID="$validate_sid" || unset ORACLE_SID
    
    if command -v oradba_validate_environment &>/dev/null; then
        oradba_validate_environment "$level"
        local result=$?
        export ORACLE_HOME="$saved_oracle_home"
        [[ -n "$saved_oracle_sid" ]] && export ORACLE_SID="$saved_oracle_sid" || unset ORACLE_SID
        return $result
    else
        echo "ERROR: Validation library not available" >&2
        export ORACLE_HOME="$saved_oracle_home"
        [[ -n "$saved_oracle_sid" ]] && export ORACLE_SID="$saved_oracle_sid" || unset ORACLE_SID
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: cmd_status
# Purpose.: Check status of Oracle instance/service
# ------------------------------------------------------------------------------
cmd_status() {
    local target="${1:-}"
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    # Auto-sync database homes from oratab
    if type -t oradba_registry_sync_oratab &>/dev/null; then
        oradba_registry_sync_oratab >/dev/null 2>&1
    fi
    
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
    
    # Try to find target in oradba_homes.conf first
    local oracle_sid oracle_home product_type
    local home_entry
    if [[ -f "$homes_file" ]] && home_entry=$(grep -v "^#\|^$" "$homes_file" | grep -E "^${target}:|:${target}:" | head -1); then
        # Found in oradba_homes.conf
        IFS=':' read -r name path ptype _order _alias _desc _version <<< "$home_entry"
        oracle_sid="$name"
        oracle_home="$path"
        product_type="${ptype^^}"
    else
        # Get SID info from oratab
        local sid_info
        sid_info=$(oradba_find_sid "$target")
        
        if [[ $? -ne 0 ]] || [[ -z "$sid_info" ]]; then
            echo "ERROR: Target '$target' not found in oratab or oradba_homes.conf"
            return 1
        fi
        
        # Parse SID info (format: SID|ORACLE_HOME|FLAG)
        local _oracle_flag
        IFS='|' read -r oracle_sid oracle_home _oracle_flag <<< "$sid_info"
        
        # Detect product type
        product_type=$(oradba_get_product_type "$oracle_home")
    fi
    
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
# Function: main
# Purpose.: Main entry point for Oracle Environment management utility
# Args....: $1 - Command (list|show|status|validate|changes|version|help)
#           $@ - Command-specific options and arguments
# Returns.: 0 on success, 1 on error
# Output..: Command output to stdout, errors to stderr
# Notes...: Dispatches to cmd_* handler functions for each command
#           Shows usage for unknown commands or help flags
#           Can be sourced or executed directly
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
