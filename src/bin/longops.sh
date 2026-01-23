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

# Default values
WATCH_MODE=false
WATCH_INTERVAL=5
OPERATION_FILTER=""
SHOW_ALL=false
SID_LIST=""

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information, options, examples, and common operation patterns
# Args....: None
# Returns.: Exits with code 0
# Output..: Usage text, options, examples, pattern reference to stdout
# Notes...: Shows watch mode, operation filters, interval config, common patterns for RMAN/DataPump
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [SID...]

Monitor long-running operations in v\$session_longops.

OPTIONS:
    -o, --operation PATTERN  Filter operations by pattern (e.g., RMAN%, %EXP%, %IMP%)
    -a, --all               Show all operations (completed and running)
    -w, --watch             Watch mode - continuously monitor operations
    -i, --interval SECONDS  Watch interval in seconds (default: 5)
    -d, --debug             Enable debug logging
    -h, --help              Show this help message

ARGUMENTS:
    SID...                 Oracle SID(s) to monitor (default: \$ORACLE_SID)

EXAMPLES:
    # Monitor RMAN operations in current database
    ${SCRIPT_NAME} -o "RMAN%"

    # Monitor DataPump exports continuously with debug
    ${SCRIPT_NAME} -o "%EXP%" -w --debug

    # Monitor DataPump imports with 10 second interval
    ${SCRIPT_NAME} -o "%IMP%" -w -i 10

    # Monitor all long operations in multiple databases
    ${SCRIPT_NAME} -a ORCL FREE CDB1

    # Monitor specific operation pattern with debug
    ${SCRIPT_NAME} -o "%Backup%" --debug

COMMON OPERATION PATTERNS:
    RMAN%           - RMAN backup/restore operations
    %EXP%           - DataPump export operations
    %IMP%           - DataPump import operations
    %Backup%        - All backup operations
    %Restore%       - All restore operations
    %Table Scan%    - Full table scan operations

DEBUG MODE:
    Enable with --debug flag or ORADBA_DEBUG=true environment variable.
    Shows SQL query construction, filter application, environment sourcing.

Press Ctrl+C to exit watch mode.

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function: parse_args
# Purpose.: Parse command line arguments and set mode flags
# Args....: Command line arguments (passed as "$@")
# Returns.: Exits on unknown option
# Output..: Error messages to stderr for invalid options
# Notes...: Sets OPERATION_FILTER, SHOW_ALL, WATCH_MODE, WATCH_INTERVAL, SID_LIST globals
# ------------------------------------------------------------------------------
parse_args() {
    debug_log "Starting argument parsing with: $*"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o | --operation)
                OPERATION_FILTER="$2"
                debug_log "Set operation filter: ${OPERATION_FILTER}"
                shift 2
                ;;
            -a | --all)
                SHOW_ALL=true
                debug_log "Enabled show all operations mode"
                shift
                ;;
            -w | --watch)
                WATCH_MODE=true
                debug_log "Enabled watch mode"
                shift
                ;;
            -i | --interval)
                WATCH_INTERVAL="$2"
                debug_log "Set watch interval: ${WATCH_INTERVAL} seconds"
                shift 2
                ;;
            -d | --debug)
                DEBUG_ENABLED=true
                debug_log "Debug mode activated via command line flag"
                shift
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
                debug_log "Added SID to monitoring list: $1"
                shift
                ;;
        esac
    done
    
    debug_log "Argument parsing complete. Final settings:"
    debug_log "  Operation filter: ${OPERATION_FILTER:-<none>}"
    debug_log "  Show all: ${SHOW_ALL}"
    debug_log "  Watch mode: ${WATCH_MODE}"
    debug_log "  Watch interval: ${WATCH_INTERVAL}"
    debug_log "  SID list: ${SID_LIST:-<empty>}"
}

# ------------------------------------------------------------------------------
# Function: monitor_longops
# Purpose.: Query v$session_longops for a specific SID and display results
# Args....: $1 - Oracle SID
# Returns.: 0 on success
# Output..: Formatted table with operation name, user, progress%, elapsed/remaining time, message to stdout
# Notes...: Applies OPERATION_FILTER and SHOW_ALL filters; calculates elapsed/remaining minutes
# ------------------------------------------------------------------------------
monitor_longops() {
    local sid=$1
    local where_clause=""

    debug_log "Starting monitor_longops for SID: ${sid}"
    
    # Build WHERE clause based on filters
    if [[ -n "${OPERATION_FILTER}" ]]; then
        where_clause="opname LIKE '${OPERATION_FILTER}'"
        debug_log "Applied operation filter: ${OPERATION_FILTER}"
    fi

    if [[ "${SHOW_ALL}" != "true" ]]; then
        if [[ -n "${where_clause}" ]]; then
            where_clause="${where_clause} AND totalwork != 0 AND sofar <> totalwork"
        else
            where_clause="totalwork != 0 AND sofar <> totalwork"
        fi
        debug_log "Applied running operations filter (excluding completed)"
    else
        debug_log "Show all operations enabled (including completed)"
    fi

    # Add WHERE keyword if we have conditions
    if [[ -n "${where_clause}" ]]; then
        where_clause="WHERE ${where_clause}"
        debug_log "Final WHERE clause: ${where_clause}"
    else
        debug_log "No WHERE clause filters applied"
    fi

    debug_log "Executing SQL query against v\$session_longops"
    debug_log "Current ORACLE_SID: ${ORACLE_SID:-<not set>}"
    debug_log "Current ORACLE_HOME: ${ORACLE_HOME:-<not set>}"

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
    local sqlplus_exit_code=$?
    debug_log "SQL query completed with exit code: ${sqlplus_exit_code}"
}

# ------------------------------------------------------------------------------
# Function: display_header
# Purpose.: Display formatted header with timestamp and database info
# Args....: $1 - Oracle SID
# Returns.: None
# Output..: Header line with SID, hostname, timestamp, operation filter to stdout
# Notes...: Shows monitoring context for watch mode refreshes
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: run_monitor
# Purpose.: Execute monitoring for all specified SIDs (single shot or watch mode)
# Args....: None (uses global SID_LIST, ORACLE_SID, WATCH_MODE, WATCH_INTERVAL)
# Returns.: 0 on success, 1 if no SID specified
# Output..: Monitoring results for each SID to stdout
# Notes...: Watch mode clears screen and loops with WATCH_INTERVAL; sources oraenv per SID
# ------------------------------------------------------------------------------
run_monitor() {
    local sid_to_monitor="${SID_LIST:-${ORACLE_SID}}"

    debug_log "Starting run_monitor function"
    debug_log "SID_LIST: ${SID_LIST:-<empty>}"
    debug_log "ORACLE_SID: ${ORACLE_SID:-<not set>}"
    debug_log "Final SID to monitor: ${sid_to_monitor:-<none>}"

    # Check if we have a SID
    if [[ -z "${sid_to_monitor}" ]]; then
        echo "Error: No Oracle SID specified and ORACLE_SID is not set." >&2
        echo "Use -h or --help for usage information." >&2
        debug_log "ERROR: No SID available for monitoring"
        exit 1
    fi

    # Watch mode - continuous monitoring
    if [[ "${WATCH_MODE}" == "true" ]]; then
        debug_log "Starting watch mode with interval ${WATCH_INTERVAL} seconds"
        
        # Trap Ctrl+C for clean exit
        trap 'echo ""; echo "Monitoring stopped."; debug_log "Watch mode stopped by user"; exit 0' INT TERM

        echo "Starting watch mode (Ctrl+C to exit)..."
        echo ""

        local iteration=1
        while true; do
            debug_log "Watch mode iteration ${iteration}"
            
            # Clear screen
            clear

            # Loop over SID list
            for sid in ${sid_to_monitor}; do
                debug_log "Processing SID: ${sid} in watch mode"
                display_header "${sid}"

                # Source Oracle environment if oraenv.sh is available
                if [[ -f "${SCRIPT_DIR}/oraenv.sh" ]]; then
                    debug_log "Sourcing Oracle environment for SID: ${sid}"
                    # shellcheck source=oraenv.sh
                    if source "${SCRIPT_DIR}/oraenv.sh" "${sid}" > /dev/null 2>&1; then
                        debug_log "Successfully sourced environment for SID: ${sid}"
                    else
                        debug_log "WARNING: Failed to source environment for SID: ${sid}"
                    fi
                else
                    debug_log "oraenv.sh not found, using current environment"
                fi

                monitor_longops "${sid}"
                echo ""
            done

            echo "Next refresh in ${WATCH_INTERVAL} seconds... (Ctrl+C to exit)"
            debug_log "Sleeping for ${WATCH_INTERVAL} seconds before next iteration"
            sleep "${WATCH_INTERVAL}"
            iteration=$((iteration + 1))
        done
    else
        debug_log "Starting single run mode"
        # Single run mode
        for sid in ${sid_to_monitor}; do
            debug_log "Processing SID: ${sid} in single run mode"
            echo "================================================================================"
            echo "Long Operations for ${sid}"
            echo "================================================================================"

            # Source Oracle environment if oraenv.sh is available
            if [[ -f "${SCRIPT_DIR}/oraenv.sh" ]]; then
                debug_log "Sourcing Oracle environment for SID: ${sid}"
                # shellcheck source=oraenv.sh
                if source "${SCRIPT_DIR}/oraenv.sh" "${sid}" > /dev/null 2>&1; then
                    debug_log "Successfully sourced environment for SID: ${sid}"
                else
                    debug_log "WARNING: Failed to source environment for SID: ${sid}"
                fi
            else
                debug_log "oraenv.sh not found, using current environment"
            fi

            monitor_longops "${sid}"
            echo ""
        done
        debug_log "Single run mode completed"
    fi
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Orchestrate long operations monitoring workflow
# Args....: Command line arguments (passed as "$@")
# Returns.: Exit code from run_monitor
# Output..: Depends on watch/filter modes
# Notes...: Workflow: parse args → run monitor; defaults to $ORACLE_SID if no SIDs specified
# ------------------------------------------------------------------------------
main() {
    # Check for debug activation early
    [[ "${ORADBA_DEBUG}" == "true" ]] && DEBUG_ENABLED=true
    
    debug_log "Starting longops.sh with arguments: $*"
    debug_log "Initial environment - ORACLE_SID: ${ORACLE_SID:-<not set>}, ORACLE_HOME: ${ORACLE_HOME:-<not set>}"
    debug_log "Script directory: ${SCRIPT_DIR}"
    debug_log "Common library available: $(if [[ -f "${SCRIPT_DIR}/../lib/oradba_common.sh" ]]; then echo "yes"; else echo "no"; fi)"
    debug_log "oraenv.sh available: $(if [[ -f "${SCRIPT_DIR}/oraenv.sh" ]]; then echo "yes"; else echo "no"; fi)"
    
    parse_args "$@"
    run_monitor
}

main "$@"

# --- EOF ----------------------------------------------------------------------
