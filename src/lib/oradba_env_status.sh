#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# Name......: oradba_env_status.sh
# Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date......: 2026-01-14
# Version...: 0.20.0
# Purpose...: Service and instance status checking for Oracle environments
# Notes.....: Part of Phase 3 implementation
# ---------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_STATUS_LOADED:-}" ]] && return 0
readonly ORADBA_ENV_STATUS_LOADED=1

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
# Function: oradba_check_datasafe_status
# Purpose.: Check if DataSafe On-Premises Connector is running
# Args....: $1 - ORACLE_HOME (DataSafe connector path)
# Returns.: 0 if running, 1 if not running
# Output..: Status string (RUNNING|STOPPED|UNKNOWN)
# Notes...: Uses direct cmctl command (faster than Python setup.py)
# ------------------------------------------------------------------------------
oradba_check_datasafe_status() {
    local oracle_home="$1"
    
    [[ -z "$oracle_home" ]] && {
        echo "UNKNOWN"
        return 1
    }
    
    # Use datasafe plugin for status check
    local plugin_file="${ORADBA_BASE}/src/lib/plugins/datasafe_plugin.sh"
    if [[ -f "${plugin_file}" ]]; then
        # shellcheck source=/dev/null
        source "${plugin_file}"
        plugin_check_status "${oracle_home}" ""
        return $?
    fi
    
    # Plugin not found - should not happen in normal operation
    oradba_log ERROR "DataSafe plugin not found: ${plugin_file}"
    echo "UNKNOWN"
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
# Purpose.: Get status for any product type
# Args....: $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS)
#          $2 - Instance/SID/Domain name
#          $3 - ORACLE_HOME or product home (optional)
# Returns.: 0 if can determine status, 1 otherwise
# Output..: Status information
# ------------------------------------------------------------------------------
oradba_get_product_status() {
    local product_type="$1"
    local instance_name="$2"
    local home_path="${3:-}"
    
    case "$product_type" in
        RDBMS)
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
        CLIENT|ICLIENT)
            # Client installations don't have services
            echo "N/A"
            return 0
            ;;
        DATASAFE)
            oradba_check_datasafe_status "$home_path"
            ;;
        OUD)
            oradba_check_oud_status "$instance_name"
            ;;
        WLS)
            oradba_check_wls_status "$instance_name"
            ;;
        *)
            echo "UNKNOWN"
            return 1
            ;;
    esac
}
