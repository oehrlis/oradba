#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: dbstatus.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
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
if [[ ! -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    echo "ERROR: Cannot find oradba_common.sh library" >&2
    exit 1
fi
source "${ORADBA_BASE}/lib/oradba_common.sh"

# Source database functions library
if [[ ! -f "${ORADBA_BASE}/lib/oradba_db_functions.sh" ]]; then
    oradba_log ERROR "Cannot find oradba_db_functions.sh library"
    exit 1
fi
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

# Script variables
SCRIPT_NAME="$(basename "$0")"
VERSION="0.1.0"

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information and command-line options
# Args....: None
# Returns.: 0 (exits after display)
# Output..: Usage information to stdout
# Notes...: Shows options, examples, and requirements
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: version
# Purpose.: Display script version information
# Args....: None
# Returns.: 0 (exits after display)
# Output..: Version string to stdout
# Notes...: Simple version display and exit
# ------------------------------------------------------------------------------
version() {
    echo "$SCRIPT_NAME version $VERSION"
    exit 0
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Main entry point for database status display
# Args....: [OPTIONS] - Command-line options
# Returns.: 0 on success, 1 on error
# Output..: Database status information to stdout
# Notes...: Parses arguments, validates environment, calls show_database_status
#           Requires ORACLE_HOME and ORACLE_SID (or --sid option)
# ------------------------------------------------------------------------------
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
                oradba_log ERROR "Unknown option: $1"
                usage
                ;;
        esac
    done

    # If SID parameter provided, set ORACLE_SID
    if [[ -n "$ORACLE_SID_PARAM" ]]; then
        export ORACLE_SID="$ORACLE_SID_PARAM"
        oradba_log INFO "Using ORACLE_SID: $ORACLE_SID"
    fi

    # Check required environment
    if [[ -z "$ORACLE_HOME" ]]; then
        oradba_log ERROR "ORACLE_HOME is not set"
        exit 1
    fi

    if [[ -z "$ORACLE_SID" ]]; then
        oradba_log ERROR "ORACLE_SID is not set. Use --sid option or set environment variable."
        exit 1
    fi

    # Display database status
    show_database_status

    return $?
}

# Run main function
main "$@"
