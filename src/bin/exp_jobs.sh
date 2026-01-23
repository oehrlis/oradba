#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: exp_jobs.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Monitor DataPump export operations in v$session_longops (wrapper)
# Notes......: Simple wrapper script for monitoring DataPump export operations
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Debug flag
DEBUG_ENABLED=false

# Source common functions if available
if [[ -f "${SCRIPT_DIR}/../lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${SCRIPT_DIR}/../lib/oradba_common.sh"
fi

# Enable debug logging function
debug_log() {
    if [[ "${DEBUG_ENABLED}" == "true" ]] || [[ "${ORADBA_DEBUG}" == "true" ]]; then
        if command -v oradba_log >/dev/null 2>&1; then
            oradba_log DEBUG "${SCRIPT_NAME}: $*"
        else
            echo "DEBUG: ${SCRIPT_NAME}: $*" >&2
        fi
    fi
}

# Check for debug activation early in script
check_debug_activation() {
    # Check environment variable
    [[ "${ORADBA_DEBUG}" == "true" ]] && DEBUG_ENABLED=true
    
    # Check command line arguments for --debug flag
    for arg in "$@"; do
        case "${arg}" in
            --debug|-d)
                DEBUG_ENABLED=true
                debug_log "Debug mode activated via command line flag: ${arg}"
                break
                ;;
        esac
    done
    
    # Log activation method
    if [[ "${DEBUG_ENABLED}" == "true" ]]; then
        if [[ "${ORADBA_DEBUG}" == "true" ]]; then
            debug_log "Debug mode activated via ORADBA_DEBUG environment variable"
        fi
        debug_log "Starting DataPump export monitoring wrapper script"
        debug_log "Script directory: ${SCRIPT_DIR}"
        debug_log "Target script: ${SCRIPT_DIR}/longops.sh"
        debug_log "Operation filter: %EXP%"
        debug_log "Original arguments: $*"
    fi
}

# Check for debug activation
check_debug_activation "$@"

# Filter out debug flags from arguments before passing to longops.sh
filtered_args=()
for arg in "$@"; do
    case "${arg}" in
        --debug|-d)
            debug_log "Removing debug flag from arguments passed to longops.sh: ${arg}"
            ;;
        *)
            filtered_args+=("${arg}")
            ;;
    esac
done

debug_log "Filtered arguments for longops.sh: ${filtered_args[*]}"
debug_log "Executing: ${SCRIPT_DIR}/longops.sh --operation %EXP% ${filtered_args[*]}"

# Execute longops.sh with export filter
if [[ "${DEBUG_ENABLED}" == "true" ]]; then
    # Pass debug flag to longops.sh if debug is enabled
    exec "${SCRIPT_DIR}/longops.sh" --operation "%EXP%" --debug "${filtered_args[@]}"
else
    exec "${SCRIPT_DIR}/longops.sh" --operation "%EXP%" "${filtered_args[@]}"
fi

# --- EOF ----------------------------------------------------------------------
