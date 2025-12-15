#!/usr/bin/env bash
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# oraenv.sh - Set Oracle environment for a specific ORACLE_SID
# -----------------------------------------------------------------------
# Copyright (c) 2025 Stefan Oehrli
# Licensed under the Apache License, Version 2.0
# -----------------------------------------------------------------------
# Usage: source oraenv.sh [ORACLE_SID] [OPTIONS]
#
# This script sets up the Oracle environment based on the oratab file
# and configuration files. It should be sourced, not executed.
# -----------------------------------------------------------------------

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source ${0} [ORACLE_SID]"
    exit 1
fi

# Get the directory where this script resides
_ORAENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ORAENV_BASE_DIR="$(dirname "$_ORAENV_SCRIPT_DIR")"

# Source configuration
if [[ -f "${_ORAENV_BASE_DIR}/srv/etc/oradba.conf" ]]; then
    source "${_ORAENV_BASE_DIR}/srv/etc/oradba.conf"
fi

# Source common library
if [[ -f "${_ORAENV_BASE_DIR}/srv/lib/common.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/srv/lib/common.sh"
else
    echo "ERROR: Cannot find common library"
    return 1
fi

# Parse command line arguments
_oraenv_parse_args() {
    local requested_sid=""
    local force_mode=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force_mode=true
                shift
                ;;
            -h|--help)
                _oraenv_usage
                return 1
                ;;
            -*)
                log_error "Unknown option: $1"
                _oraenv_usage
                return 1
                ;;
            *)
                if [[ -z "$requested_sid" ]]; then
                    requested_sid="$1"
                else
                    log_error "Multiple SIDs provided"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    echo "$requested_sid"
}

# Display usage
_oraenv_usage() {
    cat <<EOF
Usage: source oraenv.sh [ORACLE_SID] [OPTIONS]

Set Oracle environment for a specific ORACLE_SID based on oratab.

Arguments:
  ORACLE_SID          Oracle System Identifier (optional, will prompt if not provided)

Options:
  -f, --force         Force environment setup even if validation fails
  -h, --help          Display this help message

Examples:
  source oraenv.sh ORCL
  source oraenv.sh TESTDB
  source oraenv.sh           # Will prompt for SID

Environment Variables:
  ORATAB_FILE        Path to oratab file (default: /etc/oratab)
  ORACLE_BASE        Oracle base directory
  TNS_ADMIN          TNS configuration directory

EOF
}

# Find oratab file
_oraenv_find_oratab() {
    # Check if ORATAB_FILE is set and exists
    if [[ -n "${ORATAB_FILE}" ]] && [[ -f "${ORATAB_FILE}" ]]; then
        echo "${ORATAB_FILE}"
        return 0
    fi
    
    # Check alternative locations
    for oratab in "${ORATAB_ALTERNATIVES[@]}"; do
        if [[ -f "$oratab" ]]; then
            echo "$oratab"
            return 0
        fi
    done
    
    log_error "No oratab file found"
    return 1
}

# Get SID from user
_oraenv_prompt_sid() {
    local oratab_file="$1"
    
    echo ""
    echo "Available Oracle instances from oratab:"
    echo "========================================"
    grep -v "^#" "$oratab_file" | grep -v "^$" | awk -F: '{print "  " $1}'
    echo ""
    
    read -p "Enter ORACLE_SID: " ORACLE_SID
    echo "$ORACLE_SID"
}

# Set Oracle environment
_oraenv_set_environment() {
    local requested_sid="$1"
    local oratab_file="$2"
    
    # Parse oratab entry
    local oratab_entry
    oratab_entry=$(parse_oratab "$requested_sid" "$oratab_file")
    
    if [[ -z "$oratab_entry" ]]; then
        log_error "ORACLE_SID '$requested_sid' not found in $oratab_file"
        return 1
    fi
    
    # Extract ORACLE_HOME from oratab
    local oracle_home
    oracle_home=$(echo "$oratab_entry" | cut -d: -f2)
    
    if [[ ! -d "$oracle_home" ]]; then
        log_error "ORACLE_HOME directory does not exist: $oracle_home"
        return 1
    fi
    
    # Unset previous Oracle environment
    _oraenv_unset_old_env
    
    # Set new environment
    export ORACLE_SID="$requested_sid"
    export ORACLE_HOME="$oracle_home"
    
    # Set ORACLE_BASE if not already set
    if [[ -z "${ORACLE_BASE}" ]]; then
        # Try to derive from ORACLE_HOME
        export ORACLE_BASE="$(dirname "$(dirname "$ORACLE_HOME")")"
    fi
    
    # Set common environment variables
    export_oracle_base_env
    
    # Set startup flag from oratab
    local startup_flag
    startup_flag=$(echo "$oratab_entry" | cut -d: -f3)
    export ORACLE_STARTUP="${startup_flag:-N}"
    
    log_info "Oracle environment set for SID: $ORACLE_SID"
    log_debug "ORACLE_HOME: $ORACLE_HOME"
    log_debug "ORACLE_BASE: $ORACLE_BASE"
    log_debug "TNS_ADMIN: ${TNS_ADMIN:-not set}"
    
    return 0
}

# Unset old Oracle environment variables
_oraenv_unset_old_env() {
    # Remove old ORACLE_HOME from PATH
    if [[ -n "${ORACLE_HOME}" ]]; then
        PATH=$(echo "$PATH" | sed -e "s|${ORACLE_HOME}/bin:||g" -e "s|:${ORACLE_HOME}/bin||g")
        LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | sed -e "s|${ORACLE_HOME}/lib:||g" -e "s|:${ORACLE_HOME}/lib||g")
    fi
    
    export PATH
    export LD_LIBRARY_PATH
}

# Display current Oracle environment
_oraenv_show_environment() {
    cat <<EOF

Oracle Environment:
==================
ORACLE_SID       : ${ORACLE_SID:-not set}
ORACLE_HOME      : ${ORACLE_HOME:-not set}
ORACLE_BASE      : ${ORACLE_BASE:-not set}
TNS_ADMIN        : ${TNS_ADMIN:-not set}
NLS_LANG         : ${NLS_LANG:-not set}
PATH             : ${PATH}

EOF
}

# Main execution
_oraenv_main() {
    local requested_sid
    requested_sid=$(_oraenv_parse_args "$@")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Find oratab file
    local oratab_file
    oratab_file=$(_oraenv_find_oratab)
    
    if [[ $? -ne 0 ]]; then
        log_error "Cannot proceed without oratab file"
        return 1
    fi
    
    log_debug "Using oratab file: $oratab_file"
    
    # Get ORACLE_SID if not provided
    if [[ -z "$requested_sid" ]]; then
        requested_sid=$(_oraenv_prompt_sid "$oratab_file")
        if [[ -z "$requested_sid" ]]; then
            log_error "No ORACLE_SID provided"
            return 1
        fi
    fi
    
    # Set environment
    _oraenv_set_environment "$requested_sid" "$oratab_file"
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        _oraenv_show_environment
    fi
    
    return $result
}

# Run main function with all arguments
_oraenv_main "$@"
