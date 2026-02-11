#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_status.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Service and instance status checking for Oracle environments
# Notes......: Part of Phase 3 implementation
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_STATUS_LOADED:-}" ]] && return 0
readonly ORADBA_ENV_STATUS_LOADED=1

# Ensure oradba_common.sh is sourced (provides execute_plugin_function_v2)
# This must be done outside any subshell to avoid set -euo pipefail issues
if ! type -t execute_plugin_function_v2 >/dev/null 2>&1; then
    # Try to source it if ORADBA_BASE is set
    if [[ -n "${ORADBA_BASE:-}" ]] && [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
        # shellcheck source=oradba_common.sh
        source "${ORADBA_BASE}/lib/oradba_common.sh" || {
            # If sourcing fails, log error but don't fail the library load
            echo "[ERROR] Failed to source oradba_common.sh" >&2
        }
    fi
fi

# ------------------------------------------------------------------------------
# Function: oradba_check_db_status
# Purpose.: Check if Oracle database instance is running
# Args....: $1 - ORACLE_SID
#          $2 - ORACLE_HOME (optional, uses current if not specified)
# Returns.: 0 if running, 1 if not running or cannot determine
# Output..: Status string (OPEN|MOUNTED|NOMOUNT|SHUTDOWN|UNKNOWN)
# ------------------------------------------------------------------------------
oradba_check_db_status() {
    local sid="$1"
    local oracle_home="${2:-${ORACLE_HOME}}"
    
    [[ -z "$sid" ]] && return 1
    [[ -z "$oracle_home" ]] && return 1
    
    # Check if sqlplus exists
    [[ ! -x "${oracle_home}/bin/sqlplus" ]] && return 1
    
    # Try to connect and get status
    local status
    status=$("${oracle_home}/bin/sqlplus" -S / as sysdba <<EOF 2>/dev/null
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF ECHO OFF
SELECT status FROM v\$instance WHERE instance_name = UPPER('${sid}');
EXIT;
EOF
    )
    
    # Clean up output
    status=$(echo "$status" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    
    # Determine status
    case "$status" in
        OPEN)
            echo "OPEN"
            return 0
            ;;
        MOUNTED)
            echo "MOUNTED"
            return 0
            ;;
        NOMOUNT)
            echo "NOMOUNT"
            return 0
            ;;
        *)
            echo "SHUTDOWN"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: oradba_check_asm_status
# Purpose.: Check if ASM instance is running
# Args....: $1 - ASM instance name (e.g., +ASM, +ASM1)
#          $2 - ORACLE_HOME (optional, uses current if not specified)
# Returns.: 0 if running, 1 if not running
# Output..: Status string (STARTED|MOUNTED|SHUTDOWN)
# ------------------------------------------------------------------------------
oradba_check_asm_status() {
    local asm_sid="$1"
    local oracle_home="${2:-${ORACLE_HOME}}"
    
    [[ -z "$asm_sid" ]] && return 1
    [[ ! "$asm_sid" =~ ^\+ASM ]] && return 1
    
    # Check if sqlplus exists
    [[ ! -x "${oracle_home}/bin/sqlplus" ]] && return 1
    
    # Try to connect to ASM
    local status
    status=$("${oracle_home}/bin/sqlplus" -S / as sysasm <<EOF 2>/dev/null
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF ECHO OFF
SELECT status FROM v\$instance WHERE instance_name = UPPER('${asm_sid}');
EXIT;
EOF
    )
    
    # Clean up output
    status=$(echo "$status" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    
    # Determine status
    case "$status" in
        STARTED|MOUNTED)
            echo "$status"
            return 0
            ;;
        *)
            echo "SHUTDOWN"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: oradba_check_listener_status
# Purpose.: Check if Oracle listener is running
# Args....: $1 - Listener name (optional, defaults to LISTENER)
#          $2 - ORACLE_HOME (optional, uses current if not specified)
# Returns.: 0 if running, 1 if not running
# Output..: Status string (RUNNING|STOPPED)
# ------------------------------------------------------------------------------
oradba_check_listener_status() {
    local listener="${1:-LISTENER}"
    local oracle_home="${2:-${ORACLE_HOME}}"
    
    [[ -z "$oracle_home" ]] && return 1
    
    # Check if lsnrctl exists
    [[ ! -x "${oracle_home}/bin/lsnrctl" ]] && return 1
    
    # Try to get listener status
    local output
    output=$("${oracle_home}/bin/lsnrctl" status "$listener" 2>&1)
    
    if echo "$output" | grep -qi "Instance.*ready"; then
        echo "RUNNING"
        return 0
    else
        echo "STOPPED"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: oradba_check_process_running
# Purpose.: Check if a process is running (generic check)
# Args....: $1 - Process pattern to search for
# Returns.: 0 if running, 1 if not
# Output..: Number of matching processes
# ------------------------------------------------------------------------------
oradba_check_process_running() {
    local pattern="$1"
    
    [[ -z "$pattern" ]] && return 1
    
    local count
    # Use pgrep if available, otherwise fall back to ps/grep
    if command -v pgrep &>/dev/null; then
        count=$(pgrep -f "$pattern" 2>/dev/null | wc -l | tr -d ' ')
    else
        # shellcheck disable=SC2009
        count=$(ps -ef | grep -c "[${pattern:0:1}]${pattern:1}")
    fi
    
    echo "$count"
    [[ $count -gt 0 ]] && return 0
    return 1
}



# ------------------------------------------------------------------------------
# Function: oradba_check_oud_status
# Purpose.: Check if Oracle Unified Directory instance is running
# Args....: $1 - OUD instance name/path
# Returns.: 0 if running, 1 if not running
# Output..: Status string (RUNNING|STOPPED|UNKNOWN)
# ------------------------------------------------------------------------------
oradba_check_oud_status() {
    local oud_instance="$1"
    
    [[ -z "$oud_instance" ]] && {
        echo "UNKNOWN"
        return 1
    }
    
    # Check for OUD process
    if oradba_check_process_running "OUD" >/dev/null; then
        echo "RUNNING"
        return 0
    fi
    
    # Try status command if available
    if [[ -x "${oud_instance}/bin/status" ]]; then
        if "${oud_instance}/bin/status" 2>/dev/null | grep -qi "running"; then
            echo "RUNNING"
            return 0
        else
            echo "STOPPED"
            return 1
        fi
    fi
    
    echo "UNKNOWN"
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_check_wls_status
# Purpose.: Check if WebLogic Server is running
# Args....: $1 - Domain home path
# Returns.: 0 if running, 1 if not running
# Output..: Status string (RUNNING|STOPPED|UNKNOWN)
# ------------------------------------------------------------------------------
oradba_check_wls_status() {
    local domain_home="$1"
    
    [[ -z "$domain_home" ]] && {
        echo "UNKNOWN"
        return 1
    }
    
    # Check for WebLogic processes
    if oradba_check_process_running "weblogic.Server" >/dev/null; then
        echo "RUNNING"
        return 0
    fi
    
    # Check admin server specifically
    if oradba_check_process_running "weblogic.Name=AdminServer" >/dev/null; then
        echo "RUNNING"
        return 0
    fi
    
    echo "STOPPED"
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_get_product_status
# Purpose.: Get status for any product type using plugin system
# Args....: $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS or lowercase)
#          $2 - Instance/SID/Domain name
#          $3 - ORACLE_HOME or product home (optional)
# Returns.: 0 if can determine status, 1 otherwise
# Output..: Status information
# Notes...: Uses plugin_check_status() from product-specific plugins
#           Falls back to product-specific functions for unknown products
# ------------------------------------------------------------------------------
oradba_get_product_status() {
    local product_type="$1"
    local instance_name="$2"
    local home_path="${3:-}"
    local status=""
    
    # Convert to lowercase for plugin matching
    local plugin_type="${product_type,,}"
    
    # Map old types to plugin names
    case "$plugin_type" in
        rdbms|grid) plugin_type="database" ;;
        wls) plugin_type="weblogic" ;;
    esac
    
    # Try to use plugin for status check
    local status_result=""
    local plugin_exit_code=0
    execute_plugin_function_v2 "${plugin_type}" "check_status" "${home_path}" "status_result" "${instance_name}" 2>/dev/null
    plugin_exit_code=$?
    
    # Plugin exit code contract:
    # 0 = running/success/available (with status text on stdout)
    #     - For services: "running" indicates the service is active
    #     - For software-only products (client/iclient): "N/A" indicates status not applicable
    # 1 = stopped/not-applicable (with status text on stdout)
    # 2 = unavailable/cannot determine (with status text on stdout)
    # For all product types, if plugin returned output, use it with the exit code
    if [[ -n "${status_result}" ]]; then
        echo "${status_result}"
        return ${plugin_exit_code}
    fi
    
    # Check if plugin exists before trying to call it
    local oradba_base="${ORADBA_BASE}"
    if [[ -z "${oradba_base}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        oradba_base="$(cd "${script_dir}/../.." && pwd)"
    fi
    
    oradba_log DEBUG "oradba_get_product_status: product_type=${product_type}, plugin_type=${plugin_type}, home=${home_path}"
    oradba_log DEBUG "oradba_get_product_status: ORADBA_BASE=${oradba_base}"
    
    local plugin_file="${oradba_base}/lib/plugins/${plugin_type}_plugin.sh"
    if [[ ! -f "${plugin_file}" ]]; then
        oradba_log DEBUG "oradba_get_product_status: Plugin not found at ${plugin_file}, trying alternate path"
        plugin_file="${oradba_base}/lib/plugins/${plugin_type}_plugin.sh"
    fi
    
    oradba_log DEBUG "oradba_get_product_status: Checking plugin file: ${plugin_file}"
    
    # Only try plugin if it exists
    if [[ -f "${plugin_file}" ]]; then
        oradba_log DEBUG "oradba_get_product_status: Plugin file found, executing check_status"
        # Try to use plugin for status check
        # Note: Plugins now return status via exit code only (no output)
        # 0=running/available, 1=stopped/N/A, 2=unavailable/error
        local plugin_exit_code=0
        
        # Check if execute_plugin_function_v2 is available
        if ! type -t execute_plugin_function_v2 >/dev/null 2>&1; then
            oradba_log ERROR "oradba_get_product_status: execute_plugin_function_v2 not available!"
            echo "unavailable"
            return 2
        fi
        
        # Execute plugin with error capture for debugging
        local plugin_stderr
        plugin_stderr=$(execute_plugin_function_v2 "${plugin_type}" "check_status" "${home_path}" "" "${instance_name}" 2>&1 >/dev/null)
        plugin_exit_code=$?
        
        if [[ -n "${plugin_stderr}" ]]; then
            oradba_log DEBUG "oradba_get_product_status: Plugin stderr: ${plugin_stderr}"
        fi
        
        oradba_log DEBUG "oradba_get_product_status: Plugin check_status exit code: ${plugin_exit_code}"
        
        # Map exit codes to status strings for backward compatibility
        case ${plugin_exit_code} in
            0)
                # Running/available
                oradba_log DEBUG "oradba_get_product_status: Plugin returned 0 (running)"
                echo "running"
                return 0
                ;;
            1)
                # Stopped/N/A - differentiate by product type
                # Software-only products (client, iclient, java) return N/A with success exit code
                # Service products (database, datasafe, oud, weblogic) return stopped with exit 1
                oradba_log DEBUG "oradba_get_product_status: Plugin returned 1 (stopped/N/A)"
                case "${plugin_type}" in
                    client|iclient|java)
                        echo "N/A"
                        return 0
                        ;;
                    *)
                        echo "stopped"
                        return 1
                        ;;
                esac
                ;;
            2)
                # Unavailable/error
                oradba_log DEBUG "oradba_get_product_status: Plugin returned 2 (unavailable)"
                echo "unavailable"
                return 2
                ;;
            *)
                # Unexpected exit code - fall through to legacy functions
                oradba_log WARN "oradba_get_product_status: Plugin check_status returned unexpected code ${plugin_exit_code}, using fallback"
                ;;
        esac
    else
        oradba_log WARN "oradba_get_product_status: Plugin file not found: ${plugin_file}"
    fi
    
    # Fallback to legacy product-specific functions if plugin doesn't exist or returned unexpected code
    oradba_log WARN "oradba_get_product_status: Using fallback status check for ${product_type} (plugin system failed)"
    case "${product_type^^}" in
        RDBMS|DATABASE)
            oradba_check_db_status "$instance_name" "$home_path"
            ;;
        ASM)
            oradba_check_asm_status "$instance_name" "$home_path"
            ;;
        GRID)
            # Check both database and ASM if ASM instance
            if [[ "$instance_name" =~ ^\+ASM ]]; then
                oradba_check_asm_status "$instance_name" "$home_path"
            else
                oradba_check_db_status "$instance_name" "$home_path"
            fi
            ;;
        OUD)
            oradba_check_oud_status "$instance_name"
            ;;
        WLS|WEBLOGIC)
            oradba_check_wls_status "$instance_name"
            ;;
        DATASAFE)
            # DataSafe has no legacy function - report unavailable
            oradba_log ERROR "oradba_get_product_status: DataSafe plugin failed and no legacy function available"
            echo "unavailable"
            return 2
            ;;
        *)
            oradba_log ERROR "oradba_get_product_status: Unknown product type '${product_type}' - no plugin or legacy function"
            echo "UNKNOWN"
            return 1
            ;;
    esac
}
