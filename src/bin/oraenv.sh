#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oraenv.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: Set Oracle environment for a specific ORACLE_SID
# Notes......: This script sets up the Oracle environment based on the oratab
#              file and hierarchical configuration files. Must be sourced.
#              Usage: source oraenv.sh [ORACLE_SID] [OPTIONS]
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source ${0} [ORACLE_SID]"
    exit 1
fi

# Get the directory where this script resides
_ORAENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ORAENV_BASE_DIR="$(dirname "$_ORAENV_SCRIPT_DIR")"

# Set ORADBA_PREFIX for configuration loading
export ORADBA_PREFIX="${_ORAENV_BASE_DIR}"
export ORADBA_CONFIG_DIR="${ORADBA_PREFIX}/etc"

# Source common library first (provides load_config function)
if [[ -f "${_ORAENV_BASE_DIR}/lib/common.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/common.sh"
else
    echo "ERROR: Cannot find common library at ${_ORAENV_BASE_DIR}/lib/common.sh"
    return 1
fi

# Load core configuration (provides base settings for oratab, paths, etc.)
# Note: Full hierarchical config (including SID-specific) is loaded after setting ORACLE_SID
if [[ -f "${ORADBA_CONFIG_DIR}/oradba_core.conf" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_CONFIG_DIR}/oradba_core.conf"
else
    echo "ERROR: Cannot find core configuration at ${ORADBA_CONFIG_DIR}/oradba_core.conf"
    return 1
fi

# Source database functions library (optional, only if available)
if [[ -f "${_ORAENV_BASE_DIR}/lib/db_functions.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/db_functions.sh"
fi

# Global variables - declared at script level so they persist across functions
# shellcheck disable=SC2034  # Used across functions in _oraenv_parse_args and _oraenv_main
SHOW_ENV=true
SHOW_STATUS=false
ORAENV_STATUS_ONLY=false
ORAENV_INTERACTIVE=true
REQUESTED_SID=""

# Parse command line arguments
_oraenv_parse_args() {
    # shellcheck disable=SC2034  # Reserved for future use
    local force_mode=false
    
    # Detect if running in interactive mode (with TTY)
    if [[ -t 0 ]]; then
        ORAENV_INTERACTIVE=true
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_STATUS=true  # Default to showing status in interactive mode
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_ENV=true     # Show environment info
    else
        ORAENV_INTERACTIVE=false
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_STATUS=false  # Default to silent in non-interactive mode
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_ENV=false
    fi
    
    ORAENV_STATUS_ONLY=false  # Flag for --status option

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f | --force)
                # shellcheck disable=SC2034  # Reserved for future use
                force_mode=true
                shift
                ;;
            -s | --silent)
                ORAENV_INTERACTIVE=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_STATUS=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_ENV=false
                shift
                ;;
            --status)
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_STATUS=true
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_ENV=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                ORAENV_STATUS_ONLY=true
                shift
                ;;
            -h | --help)
                _oraenv_usage
                return 1
                ;;
            -*)
                log_error "Unknown option: $1"
                _oraenv_usage
                return 1
                ;;
            *)
                if [[ -z "$REQUESTED_SID" ]]; then
                    REQUESTED_SID="$1"
                else
                    log_error "Multiple SIDs provided"
                    return 1
                fi
                shift
                ;;
        esac
    done
}

# Display usage
_oraenv_usage() {
    # Output to stderr so it's visible when sourced
    cat >&2 << EOF
Usage: source oraenv.sh [ORACLE_SID] [OPTIONS]

Set Oracle environment for a specific ORACLE_SID based on oratab.

Arguments:
  ORACLE_SID          Oracle System Identifier (optional)

Options:
  -s, --silent        Silent mode: no prompts, no status display
  --status            Force showing detailed database status
  -f, --force         Force environment setup even if validation fails
  -h, --help          Display this help message

Behavior:
  Interactive (TTY): 
    - With SID: Sets environment and shows database status
    - Without SID: Prompts for selection and shows status
  
  Non-interactive (no TTY) or --silent:
    - With SID: Sets environment silently
    - Without SID: Uses first entry from oratab silently

Examples:
  source oraenv.sh FREE              # Interactive: with status
  source oraenv.sh FREE --silent     # Silent: no status
  source oraenv.sh                   # Interactive: prompt for SID
  echo "..." | source oraenv.sh      # Non-interactive: first SID, silent

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

# Get SID from user (interactive) or first SID (non-interactive)
_oraenv_prompt_sid() {
    local oratab_file="$1"
    
    # Get list of available SIDs
    local -a sids
    mapfile -t sids < <(grep -v "^#" "$oratab_file" | grep -v "^$" | awk -F: '{print $1}')
    
    # Check if we found any SIDs
    if [[ ${#sids[@]} -eq 0 ]]; then
        log_error "No Oracle instances found in $oratab_file"
        return 1
    fi
    
    # If non-interactive mode, return first SID
    if [[ "$ORAENV_INTERACTIVE" != "true" ]]; then
        echo "${sids[0]}"
        return 0
    fi
    
    # Display list to stderr so it appears before the prompt
    {
        echo ""
        echo "Available Oracle instances from oratab:"
        echo "========================================"
        
        # Display SIDs with numbers
        local i
        for i in "${!sids[@]}"; do
            printf "  [%d] %s\n" "$((i + 1))" "${sids[$i]}"
        done
        echo ""
    } >&2
    
    # Prompt for selection
    local selection
    read -p "Enter ORACLE_SID or number [1-${#sids[@]}]: " selection
    
    # Check if user entered a number
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#sids[@]} ]]; then
        # User entered a valid number
        echo "${sids[$((selection - 1))]}"
    elif [[ -n "$selection" ]]; then
        # User entered a SID name directly
        echo "$selection"
    else
        log_error "No ORACLE_SID selected"
        return 1
    fi
}

# Set Oracle environment
_oraenv_set_environment() {
    local requested_sid="$1"
    local oratab_file="$2"

    # Parse oratab entry (case-insensitive)
    local oratab_entry
    oratab_entry=$(parse_oratab "$requested_sid" "$oratab_file")

    if [[ -z "$oratab_entry" ]]; then
        log_error "ORACLE_SID '$requested_sid' not found in $oratab_file"
        return 1
    fi

    # Extract actual SID from oratab (preserves uppercase from oratab)
    local actual_sid
    actual_sid=$(echo "$oratab_entry" | cut -d: -f1)
    
    # Extract ORACLE_HOME from oratab
    local oracle_home
    oracle_home=$(echo "$oratab_entry" | cut -d: -f2)

    if [[ ! -d "$oracle_home" ]]; then
        log_error "ORACLE_HOME directory does not exist: $oracle_home"
        return 1
    fi

    # Unset previous Oracle environment
    _oraenv_unset_old_env

    # Set new environment (use actual SID from oratab to preserve case)
    export ORACLE_SID="$actual_sid"
    export ORACLE_HOME="$oracle_home"

    # Set ORACLE_BASE if not already set
    if [[ -z "${ORACLE_BASE}" ]]; then
        # Try to derive from ORACLE_HOME
        local derived_base
        derived_base="$(dirname "$(dirname "$ORACLE_HOME")")"
        export ORACLE_BASE="${derived_base}"
    fi

    # Set common environment variables
    export_oracle_base_env

    # Set startup flag from oratab
    local startup_flag
    startup_flag=$(echo "$oratab_entry" | cut -d: -f3)
    export ORACLE_STARTUP="${startup_flag:-N}"

    # Load hierarchical configuration for this SID
    # This reloads all configs in order: core -> standard -> customer -> default -> sid-specific
    # Later configs override earlier settings, including aliases
    load_config "$actual_sid"

    # Configure SQLPATH for SQL script discovery (#11)
    if [[ "${ORADBA_CONFIGURE_SQLPATH}" != "false" ]]; then
        configure_sqlpath
    fi

    log_debug "Oracle environment set for SID: $ORACLE_SID"
    log_debug "ORACLE_HOME: $ORACLE_HOME"
    log_debug "ORACLE_BASE: $ORACLE_BASE"
    log_debug "TNS_ADMIN: ${TNS_ADMIN:-not set}"
    log_debug "SQLPATH: ${SQLPATH:-not set}"

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
    cat << EOF

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
    _oraenv_parse_args "$@"

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
    if [[ -z "$REQUESTED_SID" ]]; then
        REQUESTED_SID=$(_oraenv_prompt_sid "$oratab_file")
        if [[ -z "$REQUESTED_SID" ]]; then
            log_error "No ORACLE_SID provided"
            return 1
        fi
    fi

    # Set environment
    _oraenv_set_environment "$REQUESTED_SID" "$oratab_file"
    local result=$?

    if [[ $result -eq 0 ]]; then
        # Handle different display modes
        if [[ "$ORAENV_STATUS_ONLY" == "true" ]] && command -v show_database_status &> /dev/null; then
            # --status flag: show only database status
            show_database_status
        elif [[ "$SHOW_STATUS" == "true" ]] && command -v show_database_status &> /dev/null; then
            # Interactive mode with status
            show_database_status
        fi
        # Silent mode or no status: show nothing
    fi

    return $result
}

# Run main function with all arguments
_oraenv_main "$@"
