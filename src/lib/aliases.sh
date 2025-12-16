#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: aliases.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: Dynamic alias generation functions for OraDBA
# Notes......: Sourced from oradba_standard.conf. Generates SID-specific aliases
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Get diagnostic_dest from database or fallback to convention
# Usage: get_diagnostic_dest
# Returns: path to diagnostic_dest directory
get_diagnostic_dest() {
    local diag_dest=""
    local sid="${ORACLE_SID:-}"
    
    # Try to query database if ORACLE_SID is set and database is available
    if [[ -n "${sid}" ]] && [[ -n "${ORACLE_HOME}" ]]; then
        # Query database for diagnostic_dest
        diag_dest=$(sqlplus -S / as sysdba <<EOF 2>/dev/null
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT value FROM v\$parameter WHERE name = 'diagnostic_dest';
EXIT;
EOF
        )
        
        # Clean up result (remove whitespace)
        diag_dest=$(echo "${diag_dest}" | tr -d '[:space:]')
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
# Dynamic Alias Generation
# ------------------------------------------------------------------------------

# Generate SID-specific aliases based on current ORACLE_SID
# Usage: generate_sid_aliases
# Creates: taa, vaa, cdda, cdta, cdaa aliases
generate_sid_aliases() {
    local sid="${ORACLE_SID:-}"
    
    # Only generate aliases if ORACLE_SID is set
    if [[ -z "${sid}" ]]; then
        return 0
    fi
    
    # Get diagnostic_dest
    local diag_dest
    diag_dest=$(get_diagnostic_dest)
    
    # Generate trace file aliases (tail/view alert log and trace files)
    if [[ -d "${diag_dest}" ]]; then
        # Alert log directory
        local alert_dir="${diag_dest}/alert"
        if [[ -d "${alert_dir}" ]]; then
            # tail alert log
            alias taa="tail -f ${alert_dir}/log.xml 2>/dev/null || tail -f ${alert_dir}/alert_${sid}.log"
            # view/less alert log
            alias vaa="less ${alert_dir}/log.xml 2>/dev/null || less ${alert_dir}/alert_${sid}.log"
        fi
        
        # Diagnostic dest directory
        alias cdda="cd ${diag_dest}"
        
        # Trace directory
        local trace_dir="${diag_dest}/trace"
        if [[ -d "${trace_dir}" ]]; then
            alias cdta="cd ${trace_dir}"
        fi
        
        # Alert directory
        if [[ -d "${alert_dir}" ]]; then
            alias cdaa="cd ${alert_dir}"
        fi
    fi
    
    # SQL*Plus with rlwrap if available
    if has_rlwrap; then
        alias sq="${RLWRAP_COMMAND} ${RLWRAP_OPTS} sqlplus / as sysdba"
        alias sqh="${RLWRAP_COMMAND} ${RLWRAP_OPTS} sqlplus /nolog"
    fi
}

# ------------------------------------------------------------------------------
# Auto-generate aliases on load
# ------------------------------------------------------------------------------

# Generate aliases for current ORACLE_SID if set
if [[ -n "${ORACLE_SID}" ]]; then
    generate_sid_aliases
fi
