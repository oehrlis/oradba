#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oradba_aliases.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 0.18.3
# Purpose....: Dynamic alias generation functions for OraDBA
# Notes......: Sourced from oradba_standard.conf. Generates SID-specific aliases
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Create dynamic alias with automatic expansion handling
# Usage: create_dynamic_alias <name> <command> [expand]
# Parameters:
#   name    - Alias name
#   command - Alias command/value
#   expand  - "true" to expand variables at definition time (default: "false")
# Returns: Exit code from safe_alias (0=created, 1=skipped, 2=error)
# Notes: When expand=true, variables in command are expanded immediately.
#        Automatically handles shellcheck SC2139 suppression for expanded aliases.
create_dynamic_alias() {
    local name="${1:?Alias name required}"
    local command="${2:?Alias command required}"
    local expand="${3:-false}"

    if [[ "${expand}" == "true" ]]; then
        # shellcheck disable=SC2139  # Intentional: expand at definition
        safe_alias "${name}" "${command}"
    else
        safe_alias "${name}" "${command}"
    fi
}

# Get diagnostic_dest from database or fallback to convention
# Usage: get_diagnostic_dest
# Returns: path to diagnostic_dest directory
get_diagnostic_dest() {
    local diag_dest=""
    local sid="${ORACLE_SID:-}"

    # Try to query database if ORACLE_SID is set and database is available
    if [[ -n "${sid}" ]] && [[ -n "${ORACLE_HOME}" ]] && [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
        # Query database for diagnostic_dest (suppress all errors)
        diag_dest=$(
            sqlplus -S / as sysdba << EOF 2>&1 | grep -v "^ERROR:" | grep -v "^SP2-" | grep -v "^ORA-" | head -1
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT value FROM v\$parameter WHERE name = 'diagnostic_dest';
EXIT;
EOF
        )

        # Clean up result (remove whitespace and check if it's a valid path)
        diag_dest=$(echo "${diag_dest}" | tr -d '[:space:]')

        # If result contains error indicators or is too short, clear it
        if [[ "${diag_dest}" =~ (ERROR|ORA-|SP2-|Help:) ]] || [[ ${#diag_dest} -lt 5 ]]; then
            diag_dest=""
        fi
    fi

    # Fallback to convention-based path if query failed
    if [[ -z "${diag_dest}" ]] || [[ "${diag_dest}" == "no rows selected" ]]; then
        diag_dest="${ORACLE_BASE}/diag/rdbms/${sid,,}/${sid}"
    fi

    echo "${diag_dest}"
}

# Check if rlwrap is available
# Usage: has_rlwrap
# Returns: 0 if rlwrap is available, 1 otherwise
has_rlwrap() {
    command -v "${RLWRAP_COMMAND:-rlwrap}" &> /dev/null
}

# ------------------------------------------------------------------------------
# Function: oradba_tnsping
# Purpose.: Wrapper for tnsping that falls back to sqlplus -P for Instant Client
# Args....: All arguments passed to tnsping/sqlplus -P
# Returns.: Exit code from tnsping or sqlplus -P
# Notes...: sqlplus -P limitations:
#           - Does NOT support full connect descriptors like "(DESCRIPTION=...)"
#           - Supports: TNS names (FREE, FREE.world), EZ Connect (host:port/service)
#           - Shows notice in verbose/debug mode when falling back to sqlplus -P
# ------------------------------------------------------------------------------
oradba_tnsping() {
    # Only work if ORACLE_HOME is set
    if [[ -z "${ORACLE_HOME}" ]]; then
        echo "Error: ORACLE_HOME not set" >&2
        return 1
    fi

    local tnsping_cmd="${ORACLE_HOME}/bin/tnsping"
    local target="$1"
    
    # Validate that a target was provided
    if [[ -z "${target}" ]]; then
        echo "Usage: tnsping <tnsname|host:port/service>" >&2
        return 1
    fi
    
    # Check if native tnsping exists
    if [[ -x "${tnsping_cmd}" ]]; then
        "${tnsping_cmd}" "$@"
    else
        # Instant Client fallback: check if target looks like a connect descriptor
        if [[ "${target}" =~ ^\(DESCRIPTION ]]; then
            echo "Error: sqlplus -P does not support full connect descriptors" >&2
            echo "       Use TNS name or EZ Connect format: host:port/service" >&2
            return 1
        fi
        
        # Find sqlplus (could be in bin/ or directly in ORACLE_HOME for IC)
        local sqlplus_cmd=""
        if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
            sqlplus_cmd="${ORACLE_HOME}/bin/sqlplus"
        elif [[ -x "${ORACLE_HOME}/sqlplus" ]]; then
            sqlplus_cmd="${ORACLE_HOME}/sqlplus"
        else
            echo "Error: Neither tnsping nor sqlplus found in ORACLE_HOME" >&2
            return 1
        fi
        
        # Show notice in verbose/debug mode
        if [[ "${ORADBA_LOG_LEVEL}" == "DEBUG" ]] || [[ "${DEBUG}" == "1" ]] || [[ "${ORADBA_VERBOSE}" == "true" ]]; then
            echo "Notice: Using sqlplus -P (tnsping not available in Instant Client)" >&2
        fi
        
        # Use sqlplus -P
        "${sqlplus_cmd}" -P "$@"
    fi
}

# ------------------------------------------------------------------------------
# Dynamic Alias Generation
# ------------------------------------------------------------------------------

# Generate SID-specific aliases based on current ORACLE_SID
# Usage: generate_sid_aliases
# Creates: taa, vaa, via, cdd, cddt, cdda aliases
generate_sid_aliases() {
    local sid="${ORACLE_SID:-}"

    # Only generate aliases if ORACLE_SID is set
    if [[ -z "${sid}" ]]; then
        return 0
    fi

    # Get diagnostic_dest
    local diag_dest
    diag_dest=$(get_diagnostic_dest)

    # Generate trace file aliases (tail/view/edit alert log and trace files)
    if [[ -d "${diag_dest}" ]]; then
        # Set alert log file path variable
        local trace_dir="${diag_dest}/trace"
        local alertlog_file="${trace_dir}/alert_${sid}.log"

        # Override ORADBA_SID_ALERTLOG with queried path if different
        if [[ -f "${alertlog_file}" ]] && [[ "${alertlog_file}" != "${ORADBA_SID_ALERTLOG}" ]]; then
            export ORADBA_SID_ALERTLOG="${alertlog_file}"
        fi

        # Alert log aliases using ORADBA_SID_ALERTLOG
        create_dynamic_alias taa 'if [ -f "${ORADBA_SID_ALERTLOG}" ]; then tail -f -n 50 ${ORADBA_SID_ALERTLOG}; else echo "ORADBA_SID_ALERTLOG not defined or file not found"; fi'
        create_dynamic_alias vaa 'if [ -f "${ORADBA_SID_ALERTLOG}" ]; then less ${ORADBA_SID_ALERTLOG}; else echo "ORADBA_SID_ALERTLOG not defined or file not found"; fi'
        create_dynamic_alias via 'if [ -f "${ORADBA_SID_ALERTLOG}" ]; then vi ${ORADBA_SID_ALERTLOG}; else echo "ORADBA_SID_ALERTLOG not defined or file not found"; fi'

        # Diagnostic dest directory (cdd)
        create_dynamic_alias cdd "cd ${diag_dest}" "true"

        # Trace directory (cddt)
        if [[ -d "${trace_dir}" ]]; then
            create_dynamic_alias cddt "cd ${trace_dir}" "true"
        fi

        # Alert directory (cdda)
        local alert_dir="${diag_dest}/alert"
        if [[ -d "${alert_dir}" ]]; then
            create_dynamic_alias cdda "cd ${alert_dir}" "true"
        fi
    fi

    # SQL*Plus with rlwrap if available
    if has_rlwrap; then
        create_dynamic_alias sq "${RLWRAP_COMMAND} ${RLWRAP_OPTS} sqlplus / as sysdba" "true"
        create_dynamic_alias sqh "${RLWRAP_COMMAND} ${RLWRAP_OPTS} sqlplus / as sysdba" "true"
    fi

    # TNS ping wrapper (supports both native tnsping and Instant Client sqlplus -P)
    create_dynamic_alias tnsping 'oradba_tnsping'

    # ------------------------------------------------------------------------------
    # Service Management Aliases
    # ------------------------------------------------------------------------------
    # Convenient shortcuts for Oracle service management

    # Database control aliases
    create_dynamic_alias dbctl '${ORADBA_BIN}/oradba_dbctl.sh'
    create_dynamic_alias dbstart '${ORADBA_BIN}/oradba_dbctl.sh start'
    create_dynamic_alias dbstop '${ORADBA_BIN}/oradba_dbctl.sh stop'
    create_dynamic_alias dbrestart '${ORADBA_BIN}/oradba_dbctl.sh restart'

    # Listener control wrapper (renamed to avoid conflict with Oracle's lsnrctl)
    create_dynamic_alias listener '${ORADBA_BIN}/oradba_lsnrctl.sh'
    create_dynamic_alias lsnrstart '${ORADBA_BIN}/oradba_lsnrctl.sh start'
    create_dynamic_alias lsnrstop '${ORADBA_BIN}/oradba_lsnrctl.sh stop'
    create_dynamic_alias lsnrrestart '${ORADBA_BIN}/oradba_lsnrctl.sh restart'
    create_dynamic_alias lsnrstatus '${ORADBA_BIN}/oradba_lsnrctl.sh status'

    # Combined services aliases
    create_dynamic_alias orastart '${ORADBA_BIN}/oradba_services.sh start'
    create_dynamic_alias orastop '${ORADBA_BIN}/oradba_services.sh stop'
    create_dynamic_alias orarestart '${ORADBA_BIN}/oradba_services.sh restart'
    create_dynamic_alias orastatus '${ORADBA_BIN}/oradba_services.sh status'
}

# ------------------------------------------------------------------------------
# Base Directory Aliases
# ------------------------------------------------------------------------------

# Generate OraDBA base directory alias
# Usage: generate_base_aliases
# Creates: cdbase alias
generate_base_aliases() {
    # OraDBA base directory alias
    if [[ -n "${ORADBA_BASE}" ]] && [[ -d "${ORADBA_BASE}" ]]; then
        create_dynamic_alias cdbase "cd ${ORADBA_BASE}" "true"
    fi
}

# ------------------------------------------------------------------------------
# Auto-generate aliases on load
# ------------------------------------------------------------------------------

# Generate base aliases
generate_base_aliases

# Generate aliases for current ORACLE_SID if set
if [[ -n "${ORACLE_SID}" ]]; then
    generate_sid_aliases
fi
