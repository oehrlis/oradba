#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: longops.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Monitor long-running operations in v$session_longops
# Notes......: Generic script for monitoring RMAN, DataPump, and other operations
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o errexit
set -o pipefail

# Script directory and sourcing common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Source common functions if available
if [[ -f "${SCRIPT_DIR}/../lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${SCRIPT_DIR}/../lib/oradba_common.sh"
fi

# Default values
WATCH_MODE=false
WATCH_INTERVAL=5
OPERATION_FILTER=""
SHOW_ALL=false
SID_LIST=""

# Usage function
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [SID...]

Monitor long-running operations in v\$session_longops.

OPTIONS:
    -o, --operation PATTERN  Filter operations by pattern (e.g., RMAN%, %EXP%, %IMP%)
    -a, --all               Show all operations (completed and running)
    -w, --watch             Watch mode - continuously monitor operations
    -i, --interval SECONDS  Watch interval in seconds (default: 5)
    -h, --help             Show this help message

ARGUMENTS:
    SID...                 Oracle SID(s) to monitor (default: \$ORACLE_SID)

EXAMPLES:
    # Monitor RMAN operations in current database
    ${SCRIPT_NAME} -o "RMAN%"

    # Monitor DataPump exports continuously
    ${SCRIPT_NAME} -o "%EXP%" -w

    # Monitor DataPump imports with 10 second interval
    ${SCRIPT_NAME} -o "%IMP%" -w -i 10

    # Monitor all long operations in multiple databases
    ${SCRIPT_NAME} -a ORCL FREE CDB1

    # Monitor specific operation pattern
    ${SCRIPT_NAME} -o "%Backup%"

COMMON OPERATION PATTERNS:
    RMAN%           - RMAN backup/restore operations
    %EXP%           - DataPump export operations
    %IMP%           - DataPump import operations
    %Backup%        - All backup operations
    %Restore%       - All restore operations
    %Table Scan%    - Full table scan operations

Press Ctrl+C to exit watch mode.

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o | --operation)
                OPERATION_FILTER="$2"
                shift 2
                ;;
            -a | --all)
                SHOW_ALL=true
                shift
                ;;
            -w | --watch)
                WATCH_MODE=true
                shift
                ;;
            -i | --interval)
                WATCH_INTERVAL="$2"
                shift 2
                ;;
            -h | --help)
                usage
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                echo "Use -h or --help for usage information." >&2
                exit 1
                ;;
            *)
                SID_LIST="${SID_LIST} $1"
                shift
                ;;
        esac
    done
}

# Function to monitor longops for a single SID
monitor_longops() {
    local sid=$1
    local where_clause=""

    # Build WHERE clause based on filters
    if [[ -n "${OPERATION_FILTER}" ]]; then
        where_clause="opname LIKE '${OPERATION_FILTER}'"
    fi

    if [[ "${SHOW_ALL}" != "true" ]]; then
        if [[ -n "${where_clause}" ]]; then
            where_clause="${where_clause} AND totalwork != 0 AND sofar <> totalwork"
        else
            where_clause="totalwork != 0 AND sofar <> totalwork"
        fi
    fi

    # Add WHERE keyword if we have conditions
    if [[ -n "${where_clause}" ]]; then
        where_clause="WHERE ${where_clause}"
    fi

    # Execute SQL query
    sqlplus -S /nolog << EOF
SET ECHO OFF
SET FEEDBACK OFF
SET HEADING ON
SET PAGESIZE 100
SET LINESIZE 160
SET TRIMOUT ON
SET TRIMSPOOL ON
CONNECT / AS SYSDBA

COLUMN sid           FORMAT 9999       HEADING "SID"
COLUMN serial#       FORMAT 99999      HEADING "Ser#"
COLUMN sofar         FORMAT 999999999  HEADING "So Far"
COLUMN totalwork     FORMAT 999999999  HEADING "Total"
COLUMN pct_complete  FORMAT 999.9      HEADING "Pct%"
COLUMN opname        FORMAT A30        HEADING "Operation" WORD_WRAPPED
COLUMN time_remain   FORMAT A11        HEADING "Remaining"
COLUMN message       FORMAT A50        HEADING "Message" WORD_WRAPPED

SELECT 
    sid,
    serial#,
    sofar,
    totalwork,
    ROUND(sofar / DECODE(totalwork, 0, 1, totalwork) * 100, 1) AS pct_complete,
    SUBSTR(opname, 1, 30) AS opname,
    LPAD(TO_CHAR(TRUNC(time_remaining/3600)), 3, '0') || ':' ||
    LPAD(TO_CHAR(TRUNC(MOD(time_remaining, 3600)/60)), 2, '0') || ':' ||
    LPAD(TO_CHAR(MOD(MOD(time_remaining, 3600), 60)), 2, '0') AS time_remain,
    SUBSTR(message, 1, 50) AS message
FROM 
    v\$session_longops
${where_clause}
ORDER BY 
    start_time DESC, sid;

EXIT;
EOF
}

# Function to display header in watch mode
display_header() {
    local sid=$1
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "================================================================================"
    echo "Long Operations Monitor - ${sid} - ${timestamp}"
    if [[ -n "${OPERATION_FILTER}" ]]; then
        echo "Filter: ${OPERATION_FILTER}"
    fi
    echo "================================================================================"
}

# Main monitoring function
run_monitor() {
    local sid_to_monitor="${SID_LIST:-${ORACLE_SID}}"

    # Check if we have a SID
    if [[ -z "${sid_to_monitor}" ]]; then
        echo "Error: No Oracle SID specified and ORACLE_SID is not set." >&2
        echo "Use -h or --help for usage information." >&2
        exit 1
    fi

    # Watch mode - continuous monitoring
    if [[ "${WATCH_MODE}" == "true" ]]; then
        # Trap Ctrl+C for clean exit
        trap 'echo ""; echo "Monitoring stopped."; exit 0' INT TERM

        echo "Starting watch mode (Ctrl+C to exit)..."
        echo ""

        while true; do
            # Clear screen
            clear

            # Loop over SID list
            for sid in ${sid_to_monitor}; do
                display_header "${sid}"

                # Source Oracle environment if oraenv.sh is available
                if [[ -f "${SCRIPT_DIR}/oraenv.sh" ]]; then
                    # shellcheck source=oraenv.sh
                    source "${SCRIPT_DIR}/oraenv.sh" "${sid}" > /dev/null 2>&1 || true
                fi

                monitor_longops "${sid}"
                echo ""
            done

            echo "Next refresh in ${WATCH_INTERVAL} seconds... (Ctrl+C to exit)"
            sleep "${WATCH_INTERVAL}"
        done
    else
        # Single run mode
        for sid in ${sid_to_monitor}; do
            echo "================================================================================"
            echo "Long Operations for ${sid}"
            echo "================================================================================"

            # Source Oracle environment if oraenv.sh is available
            if [[ -f "${SCRIPT_DIR}/oraenv.sh" ]]; then
                # shellcheck source=oraenv.sh
                source "${SCRIPT_DIR}/oraenv.sh" "${sid}" > /dev/null 2>&1 || true
            fi

            monitor_longops "${sid}"
            echo ""
        done
    fi
}

# Main execution
main() {
    parse_args "$@"
    run_monitor
}

main "$@"

# --- EOF ----------------------------------------------------------------------
