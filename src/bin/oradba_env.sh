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

# Set ORADBA_PREFIX and config dir for config loading
export ORADBA_PREFIX="${ORADBA_BASE}"
export ORADBA_CONFIG_DIR="${ORADBA_BASE}/etc"

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

if [[ -f "${ORADBA_BASE}/lib/oradba_env_output.sh" ]]; then
    # shellcheck source=../lib/oradba_env_output.sh
    source "${ORADBA_BASE}/lib/oradba_env_output.sh"
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
# Function: resolve_datasafe_env
# Purpose.: Resolve Data Safe environment paths for display
# Args....: $1 - Data Safe base install path
# Output..: install_dir|oracle_home|tns_admin|java_home
# ------------------------------------------------------------------------------
resolve_datasafe_env() {
    local base_path="$1"
    local install_dir="$1"
    local oracle_home=""
    local tns_admin=""
    local java_home=""

    if [[ -f "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh" ]]; then
        # shellcheck source=/dev/null
        source "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
        if command -v plugin_adjust_environment &>/dev/null; then
            oracle_home=$(plugin_adjust_environment "${base_path}")
        fi
    fi

    if [[ -z "${oracle_home}" ]]; then
        if [[ -d "${base_path}/oracle_cman_home" ]]; then
            oracle_home="${base_path}/oracle_cman_home"
        else
            oracle_home="${base_path}"
        fi
    fi

    if [[ -d "${oracle_home}/network/admin" ]]; then
        tns_admin="${oracle_home}/network/admin"
    elif [[ -d "${base_path}/network/admin" ]]; then
        tns_admin="${base_path}/network/admin"
    fi

    if [[ -f "${ORADBA_BASE}/lib/oradba_env_builder.sh" ]]; then
        if ! command -v oradba_resolve_java_home &>/dev/null; then
            # shellcheck source=/dev/null
            source "${ORADBA_BASE}/lib/oradba_env_builder.sh" 2>/dev/null || true
        fi
        if command -v oradba_resolve_java_home &>/dev/null; then
            java_home=$(oradba_resolve_java_home "${oracle_home}" 2>/dev/null || true)
        fi
    fi

    if [[ -z "${java_home}" ]]; then
        local candidate
        for candidate in "${oracle_home}/java" "${oracle_home}/jre" "${oracle_home}/jdk" \
                         "${base_path}/java" "${base_path}/jre" "${base_path}/jdk"; do
            if [[ -x "${candidate}/bin/java" ]]; then
                java_home="${candidate}"
                break
            fi
        done
    fi

    echo "${install_dir}|${oracle_home}|${tns_admin}|${java_home}"
}

# ------------------------------------------------------------------------------
# Function: resolve_default_tns_admin
# Purpose.: Resolve non-DataSafe TNS_ADMIN for display
# Args....: $1 - Oracle Home path
# Output..: TNS_ADMIN path (may be empty)
# ------------------------------------------------------------------------------
resolve_default_tns_admin() {
    local oracle_home="$1"
    local tns_admin=""

    if [[ -n "${ORADBA_TNS_ADMIN}" ]]; then
        tns_admin="${ORADBA_TNS_ADMIN}"
    elif [[ -n "${ORACLE_BASE}" ]]; then
        tns_admin="${ORACLE_BASE}/network/admin"
    elif [[ -n "${oracle_home}" ]]; then
        tns_admin="${oracle_home}/network/admin"
    fi

    echo "${tns_admin}"
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
                printf "%-20s %-16s %s\n" "SID" "FLAG" "ORACLE_HOME"
                echo "--------------------------------------------------------------------------------"
                oradba_parse_oratab | while IFS='|' read -r sid home flag; do
                    # Translate flag to human-readable format
                    local flag_display="$flag"
                    case "$flag" in
                        D) flag_display="DUMMY" ;;
                        Y) flag_display="AUTO-START" ;;
                        N) flag_display="MANUAL" ;;
                    esac
                    printf "%-20s %-16s %s\n" "$sid" "$flag_display" "$home"
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
}

# ------------------------------------------------------------------------------
# Function: cmd_show
# Purpose.: Show detailed information about SID or Home
# ------------------------------------------------------------------------------
cmd_show() {
    local target="${1:-${ORACLE_SID}}"
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    
    if [[ -z "$target" ]]; then
        echo "ERROR: No SID or Oracle Home specified and ORACLE_SID not set" >&2
        return 1
    fi
    
    # Auto-sync database homes from oratab
    if type -t oradba_registry_sync_oratab &>/dev/null; then
        oradba_registry_sync_oratab >/dev/null 2>&1
    fi
    
    # Try to find target in oradba_homes.conf first (by name or alias)
    local home_entry
    if [[ -f "$homes_file" ]]; then
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESC:VERSION
        # Match only if target is the NAME (field 1) or ALIAS (field 5)
        while IFS=':' read -r name path ptype _order alias_name desc version; do
            if [[ "$name" == "$target" ]] || [[ "$alias_name" == "$target" ]]; then
                home_entry="$name:$path:$ptype:$_order:$alias_name:$desc:$version"
                break
            fi
        done < <(grep -v "^#\|^$" "$homes_file")
    fi
    
    if [[ -n "$home_entry" ]]; then
        # Found in oradba_homes.conf - extract details
        IFS=':' read -r name path ptype _order alias_name desc version <<< "$home_entry"
        local oracle_base=""
        local tns_admin=""
        local datasafe_home=""

        oracle_base="$(derive_oracle_base "${path}" 2>/dev/null || true)"

        if [[ "${ptype}" == "datasafe" ]]; then
            datasafe_home="${path}"
        else
            local saved_base="${ORACLE_BASE:-}"
            ORACLE_BASE="${oracle_base}"
            if command -v load_config &>/dev/null; then
                load_config "${name}" >/dev/null 2>&1 || true
            fi
            tns_admin="$(resolve_default_tns_admin "${path}")"
            ORACLE_BASE="${saved_base}"
        fi
        
        if [[ ! -d "$path" ]]; then
            echo "Warning: Oracle Home does not exist"
        fi

        ORACLE_BASE="${oracle_base}" \
        TNS_ADMIN="${tns_admin}" \
        DATASAFE_HOME="${datasafe_home}" \
        show_oracle_home_status "${ptype}" "${path}" "" "false"
        return 0
    # Check if it's a SID in oratab
    elif type -t parse_oratab &>/dev/null; then
        local oratab_entry
        oratab_entry=$(parse_oratab "$target" 2>/dev/null)
        if [[ -n "$oratab_entry" ]]; then
            # Found in oratab - parse SID:HOME:FLAG format
            IFS=':' read -r sid path flag <<< "$oratab_entry"
            local oracle_base=""
            local tns_admin=""
            local detected_type="database"

            if type -t detect_product_type &>/dev/null; then
                detected_type=$(detect_product_type "$path")
            fi

            oracle_base="$(derive_oracle_base "${path}" 2>/dev/null || true)"
            if [[ -d "$path" ]]; then
                local saved_base="${ORACLE_BASE:-}"
                ORACLE_BASE="${oracle_base}"
                if command -v load_config &>/dev/null; then
                    load_config "${sid}" >/dev/null 2>&1 || true
                fi
                tns_admin="$(resolve_default_tns_admin "${path}")"
                ORACLE_BASE="${saved_base}"
            else
                echo "Warning: Oracle Home does not exist"
            fi

            ORACLE_BASE="${oracle_base}" \
            TNS_ADMIN="${tns_admin}" \
            show_oracle_home_status "${detected_type}" "${path}" "${sid}" "false"
            return 0
        fi
    fi
    
    # Check if it's a path (Oracle Home)
    if [[ -d "$target" ]]; then
        # It's an Oracle Home path
        local product=""
        local oracle_base=""
        local tns_admin=""

        product=$(oradba_get_home_metadata "$target" "Product" 2>/dev/null)
        if [[ -z "$product" ]] || [[ "$product" == "N/A" ]]; then
            product=$(oradba_get_product_type "$target")
        fi

        oracle_base="$(derive_oracle_base "${target}" 2>/dev/null || true)"
        if [[ -n "${product}" ]] && [[ "${product}" != "datasafe" ]]; then
            local saved_base="${ORACLE_BASE:-}"
            ORACLE_BASE="${oracle_base}"
            tns_admin="$(resolve_default_tns_admin "${target}")"
            ORACLE_BASE="${saved_base}"
        fi

        local datasafe_home=""
        if [[ "${product}" == "datasafe" ]]; then
            datasafe_home="${target}"
        fi

        ORACLE_BASE="${oracle_base}" \
        TNS_ADMIN="${tns_admin}" \
        DATASAFE_HOME="${datasafe_home}" \
        show_oracle_home_status "${product}" "${target}" "" "false"
    else
        # Not found anywhere
        echo "ERROR: Target '$target' not found in oradba_homes.conf or oratab" >&2
        echo "" >&2
        echo "Available targets:" >&2
        echo "  - Database SIDs from /etc/oratab" >&2
        echo "  - Oracle Homes from ${homes_file}" >&2
        return 1
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
        if [[ -f "$homes_file" ]]; then
            # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESC:VERSION
            # Match only if target is the NAME (field 1) or ALIAS (field 5)
            while IFS=':' read -r name path ptype _order _alias _desc _version; do
                if [[ "$name" == "$target" ]] || [[ "$_alias" == "$target" ]]; then
                    home_entry="$name:$path:$ptype:$_order:$_alias:$_desc:$_version"
                    break
                fi
            done < <(grep -v "^#\|^$" "$homes_file")
        fi
        
        if [[ -n "$home_entry" ]]; then
            IFS=':' read -r name path ptype _order _alias _desc _version <<< "$home_entry"
            validate_home="$path"
            target_name="$name"
            product_type="$ptype"
            validate_sid=""  # Oracle Homes don't have SID
            
            # Apply DataSafe adjustment via plugin if needed
            if [[ "$product_type" == "datasafe" ]]; then
                local plugin_file="${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
                if [[ -f "${plugin_file}" ]]; then
                    # shellcheck source=/dev/null
                    source "${plugin_file}"
                    validate_home=$(plugin_adjust_environment "${validate_home}")
                elif [[ -d "${validate_home}/oracle_cman_home" ]]; then
                    # Fallback
                    validate_home="${validate_home}/oracle_cman_home"
                fi
            fi
        # Try oratab for database SIDs
        elif type -t parse_oratab &>/dev/null; then
            local oratab_entry
            oratab_entry=$(parse_oratab "$target" 2>/dev/null)
            if [[ -n "$oratab_entry" ]]; then
                IFS=':' read -r sid home _flag <<< "$oratab_entry"
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
    if [[ -f "$homes_file" ]]; then
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESC:VERSION
        # Match only if target is the NAME (field 1) or ALIAS (field 5)
        while IFS=':' read -r name path ptype _order _alias _desc _version; do
            if [[ "$name" == "$target" ]] || [[ "$_alias" == "$target" ]]; then
                home_entry="$name:$path:$ptype:$_order:$_alias:$_desc:$_version"
                break
            fi
        done < <(grep -v "^#\|^$" "$homes_file")
    fi
    
    if [[ -n "$home_entry" ]]; then
        # Found in oradba_homes.conf
        IFS=':' read -r name path ptype _order _alias _desc _version <<< "$home_entry"
        oracle_sid="$name"
        oracle_home="$path"
        product_type="$ptype"
    # Try oratab for database SIDs
    elif type -t parse_oratab &>/dev/null; then
        local oratab_entry
        oratab_entry=$(parse_oratab "$target" 2>/dev/null)
        
        if [[ -z "$oratab_entry" ]]; then
            echo "ERROR: Target '$target' not found in oratab or oradba_homes.conf"
            return 1
        fi
        
        # Parse oratab entry (format: SID:ORACLE_HOME:FLAG)
        local _oracle_flag
        IFS=':' read -r oracle_sid oracle_home _oracle_flag <<< "$oratab_entry"
        
        # Detect product type
        if type -t detect_product_type &>/dev/null; then
            product_type=$(detect_product_type "$oracle_home")
        else
            product_type="database"
        fi
    else
        echo "ERROR: Target '$target' not found in oratab or oradba_homes.conf"
        return 1
    fi
    
    local product_type_lower="${product_type,,}"

    if [[ "${product_type_lower}" == "database" || "${product_type_lower}" == "rdbms" || "${product_type_lower}" == "grid" || "${product_type_lower}" == "asm" ]]; then
        local saved_home="${ORACLE_HOME:-}"
        local saved_sid="${ORACLE_SID:-}"
        local saved_type="${ORADBA_CURRENT_HOME_TYPE:-}"
        local saved_base="${ORACLE_BASE:-}"
        local saved_tns="${TNS_ADMIN:-}"

        ORACLE_HOME="${oracle_home}"
        ORACLE_SID="${oracle_sid}"
        ORADBA_CURRENT_HOME_TYPE="database"
        ORACLE_BASE="$(derive_oracle_base "${oracle_home}" 2>/dev/null || true)"
        if command -v load_config &>/dev/null; then
            load_config "${oracle_sid}" >/dev/null 2>&1 || true
        fi
        TNS_ADMIN="$(resolve_default_tns_admin "${oracle_home}")"

        show_database_status

        ORACLE_HOME="${saved_home}"
        ORACLE_SID="${saved_sid}"
        ORADBA_CURRENT_HOME_TYPE="${saved_type}"
        ORACLE_BASE="${saved_base}"
        TNS_ADMIN="${saved_tns}"
        return 0
    fi

    local oracle_base=""
    local tns_admin=""
    local datasafe_home=""

    oracle_base="$(derive_oracle_base "${oracle_home}" 2>/dev/null || true)"
    if [[ "${product_type_lower}" == "datasafe" ]]; then
        datasafe_home="${oracle_home}"
    else
        local saved_base="${ORACLE_BASE:-}"
        ORACLE_BASE="${oracle_base}"
        if command -v load_config &>/dev/null; then
            load_config "${oracle_sid}" >/dev/null 2>&1 || true
        fi
        tns_admin="$(resolve_default_tns_admin "${oracle_home}")"
        ORACLE_BASE="${saved_base}"
    fi

    ORACLE_BASE="${oracle_base}" \
    TNS_ADMIN="${tns_admin}" \
    DATASAFE_HOME="${datasafe_home}" \
    show_oracle_home_status "${product_type}" "${oracle_home}" "${oracle_sid}" "true"
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
