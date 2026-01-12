#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: dbstatus.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: Display Oracle database status information
# Notes......: This script displays comprehensive database status including
#              instance state, uptime, database mode, and resource usage.
#              Works with databases in NOMOUNT, MOUNT, and OPEN states.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="$(dirname "$SCRIPT_DIR")"

# Source common library
if [[ ! -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    echo "ERROR: Cannot find common.sh library" >&2
    exit 1
fi
source "${ORADBA_BASE}/lib/common.sh"

# Source database functions library
if [[ ! -f "${ORADBA_BASE}/lib/db_functions.sh" ]]; then
    log_error "Cannot find db_functions.sh library"
    exit 1
fi
source "${ORADBA_BASE}/lib/db_functions.sh"

# Script variables
SCRIPT_NAME="$(basename "$0")"
VERSION="0.1.0"

# Display usage
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Display Oracle database status information including instance state, uptime,
database mode, and resource usage.

Options:
  -h, --help          Display this help message
  -v, --version       Display version information
  -d, --debug         Enable debug mode
  -s, --sid SID       Display status for specific ORACLE_SID

The script requires ORACLE_HOME and ORACLE_SID to be set, or specify SID with --sid.
Works with databases in NOMOUNT, MOUNT, and OPEN states.

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME --sid FREE
  $SCRIPT_NAME --debug

EOF
    exit 0
}

# Display version
version() {
    echo "$SCRIPT_NAME version $VERSION"
    exit 0
}

# Main script
main() {
    local ORACLE_SID_PARAM=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                usage
                ;;
            -v | --version)
                version
                ;;
            -d | --debug)
                set -x
                shift
                ;;
            -s | --sid)
                ORACLE_SID_PARAM="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # If SID parameter provided, set ORACLE_SID
    if [[ -n "$ORACLE_SID_PARAM" ]]; then
        export ORACLE_SID="$ORACLE_SID_PARAM"
        log_info "Using ORACLE_SID: $ORACLE_SID"
    fi

    # Check required environment
    if [[ -z "$ORACLE_HOME" ]]; then
        log_error "ORACLE_HOME is not set"
        exit 1
    fi

    if [[ -z "$ORACLE_SID" ]]; then
        log_error "ORACLE_SID is not set. Use --sid option or set environment variable."
        exit 1
    fi

    # Display database status
    show_database_status

    return $?
}

# Run main function
main "$@"
