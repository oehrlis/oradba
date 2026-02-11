#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_dbctl.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Database start/stop control script for Oracle instances
# Notes......: Can be used interactively or in runlevel/systemd scripts
#              Honors oratab :Y flag by default, supports explicit SID override
#              Requires oracle user privileges
# Usage......: oradba_dbctl.sh {start|stop|restart|status} [SID1 SID2 ...]
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Source OraDBA libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BIN="${SCRIPT_DIR}"
ORADBA_BASE="$(dirname "${ORADBA_BIN}")"

# Source common functions
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    oradba_log DEBUG "${SCRIPT_NAME}: Sourced oradba_common.sh successfully"
else
    echo "ERROR: Cannot find oradba_common.sh library"
    exit 1
fi

# Source DB functions
if [[ -f "${ORADBA_BASE}/lib/oradba_db_functions.sh" ]]; then
    # shellcheck source=../lib/oradba_db_functions.sh
    source "${ORADBA_BASE}/lib/oradba_db_functions.sh"
    oradba_log DEBUG "${SCRIPT_NAME}: Sourced oradba_db_functions.sh successfully"
else
    oradba_log DEBUG "${SCRIPT_NAME}: oradba_db_functions.sh not found, continuing without DB functions"
fi

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
DEFAULT_SHUTDOWN_TIMEOUT=180
SHUTDOWN_TIMEOUT=${ORADBA_SHUTDOWN_TIMEOUT:-$DEFAULT_SHUTDOWN_TIMEOUT}
FORCE_MODE=false
OPEN_PDBS=false
ACTION=""
SIDS=()
LOGFILE="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}.log"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information and examples
# Args....: None
# Returns.: Exits with code 1
# Output..: Usage text, options, examples, environment variables to stdout
# Notes...: Shows action modes (start/stop/restart/status), timeout config, SID selection
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} {start|stop|restart|status} [OPTIONS] [SID1 SID2 ...]

Actions:
    start       Start Oracle database instance(s)
    stop        Stop Oracle database instance(s)
    restart     Restart Oracle database instance(s)
    status      Show status of Oracle database instance(s)

Options:
    -f, --force             Force operation without confirmation
    -t, --timeout SECONDS   Shutdown timeout (default: ${DEFAULT_SHUTDOWN_TIMEOUT}s)
    -p, --open-pdbs         Explicitly open all PDBs after startup
    -d, --debug             Enable debug logging
    -h, --help              Show this help message

Arguments:
    SID                     Specific database SID(s) to control
                           If not specified, processes all databases with :Y flag in oratab

Examples:
    ${SCRIPT_NAME} start                    # Start all databases marked :Y
    ${SCRIPT_NAME} start ORCL CDB1          # Start specific databases
    ${SCRIPT_NAME} stop --force             # Stop all without confirmation
    ${SCRIPT_NAME} restart PRODDB           # Restart specific database
    ${SCRIPT_NAME} status                   # Show status of all databases
    ${SCRIPT_NAME} --debug start ORCL       # Start with debug logging
    ORADBA_DEBUG=true ${SCRIPT_NAME} status # Status with debug logging

Environment Variables:
    ORADBA_DEBUG               Enable debug logging (true/false)
    ORADBA_SHUTDOWN_TIMEOUT    Shutdown timeout in seconds (default: ${DEFAULT_SHUTDOWN_TIMEOUT})
    ORADBA_LOG                 Log directory (default: /var/log/oracle)
    ORATAB                     Path to oratab file (default: /etc/oratab)

EOF
    exit 1
}

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# ------------------------------------------------------------------------------
# Function: get_databases
# Purpose.: Parse oratab to extract database entries
# Args....: None
# Returns.: 0 on success, 1 if oratab not found
# Output..: One line per database: SID:HOME:FLAG (excludes comments, empty lines, dummy entries)
# Notes...: Filters out entries with flag=D; reads from ${ORATAB:-/etc/oratab}
# ------------------------------------------------------------------------------
get_databases() {
    local oratab_file="${ORATAB:-/etc/oratab}"
    oradba_log DEBUG "${SCRIPT_NAME}: get_databases() - Reading oratab from: ${oratab_file}"

    if [[ ! -f "${oratab_file}" ]]; then
        oradba_log ERROR "oratab file not found: ${oratab_file}"
        return 1
    fi

    # Parse oratab, filter out comments and dummy entries
    local entry_count=0
    grep -v '^#' "${oratab_file}" | grep -v '^$' | while IFS=: read -r sid home flag rest; do
        ((entry_count++))
        oradba_log DEBUG "${SCRIPT_NAME}: get_databases() - Found entry ${entry_count}: SID=${sid}, HOME=${home}, FLAG=${flag}"
        
        # Skip dummy entries
        if [[ "${flag}" == "D" ]]; then
            oradba_log DEBUG "${SCRIPT_NAME}: get_databases() - Skipping dummy entry: ${sid}"
            continue
        fi

        echo "${sid}:${home}:${flag}"
    done
    
    oradba_log DEBUG "${SCRIPT_NAME}: get_databases() - Processed ${entry_count} entries from oratab"
}

# ------------------------------------------------------------------------------
# Function: should_autostart
# Function: ask_justification
# Purpose.: Prompt for justification when operating on multiple databases
# Args....: $1 - Action name (start/stop/restart), $2 - Database count
# Returns.: 0 if confirmed, 1 if cancelled or no justification
# Output..: Warning banner, prompts for justification and confirmation to stdout
# Notes...: Skipped if FORCE_MODE=true; logs justification; requires 'yes' to proceed
# ------------------------------------------------------------------------------
ask_justification() {
    local action="$1"
    local count="$2"

    if [[ "${FORCE_MODE}" == "true" ]]; then
        return 0
    fi

    echo ""
    echo "=========================================="
    echo "WARNING: About to ${action} ALL databases"
    echo "=========================================="
    echo "This will affect ${count} database(s)"
    echo ""
    read -r -p "Please provide justification for this operation: " justification

    if [[ -z "${justification}" ]]; then
        oradba_log ERROR "Operation cancelled: No justification provided"
        return 1
    fi

    oradba_log INFO "Justification for ${action} all databases: ${justification}"
    read -r -p "Continue with operation? (yes/no): " confirm

    if [[ "${confirm}" != "yes" ]]; then
        oradba_log INFO "Operation cancelled by user"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: start_database
# Purpose.: Start an Oracle database instance
# Args....: $1 - Database SID
# Returns.: 0 on success, 1 on failure
# Output..: Status messages via oradba_log, SQL output to ${LOGFILE}
# Notes...: Sources environment for SID; checks if already running; executes STARTUP; optionally opens PDBs
# ------------------------------------------------------------------------------
start_database() {
    local sid="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Starting database '${sid}'"

    oradba_log INFO "Starting database ${sid}..."

    # Source environment for this SID
    export ORACLE_SID="${sid}"
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Set ORACLE_SID to '${sid}'"
    
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Sourcing environment from oraenv.sh"
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" > /dev/null 2>&1
        oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Environment sourced, ORACLE_HOME=${ORACLE_HOME}"
    else
        oradba_log ERROR "Cannot source oraenv.sh for ${sid}"
        return 1
    fi

    # Check if database is already running
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Checking current database status"
    local status
    status=$(
        sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
    )
    
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Current status: '${status}'"

    if [[ "${status}" =~ OPEN ]]; then
        oradba_log INFO "Database ${sid} is already running"
        oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Database already running, skipping startup"
        return 0
    fi

    # Start the database
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Executing STARTUP command via sqlplus"
    sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP;
EXIT;
EOF

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_database() - STARTUP command completed with exit code: ${rc}"
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Database ${sid} started successfully"

        # Open PDBs if requested
        if [[ "${OPEN_PDBS}" == "true" ]]; then
            oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Opening all PDBs as requested"
            open_all_pdbs "${sid}"
        else
            oradba_log DEBUG "${SCRIPT_NAME}: start_database() - Skipping PDB opening (not requested)"
        fi
        return 0
    else
        oradba_log ERROR "Failed to start database ${sid} (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: open_all_pdbs
# Purpose.: Open all pluggable databases in a CDB
# Args....: $1 - Database SID (must be CDB)
# Returns.: None (always succeeds)
# Output..: Status messages via oradba_log, SQL output to ${LOGFILE}
# Notes...: Executes ALTER PLUGGABLE DATABASE ALL OPEN; checks for failures; warns if some PDBs fail
# ------------------------------------------------------------------------------
open_all_pdbs() {
    local sid="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: open_all_pdbs() - Opening all PDBs in CDB '${sid}'"

    oradba_log INFO "Opening all PDBs in ${sid}..."

    oradba_log DEBUG "${SCRIPT_NAME}: open_all_pdbs() - Executing ALTER PLUGGABLE DATABASE ALL OPEN"
    sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR CONTINUE
ALTER PLUGGABLE DATABASE ALL OPEN;
EXIT;
EOF

    oradba_log DEBUG "${SCRIPT_NAME}: open_all_pdbs() - Checking PDB status after open command"
    if sqlplus -s / as sysdba <<< "SELECT COUNT(*) FROM v\$pdbs WHERE open_mode != 'READ WRITE';" | grep -q '^0$'; then
        oradba_log INFO "All PDBs opened successfully in ${sid}"
        oradba_log DEBUG "${SCRIPT_NAME}: open_all_pdbs() - All PDBs are in READ WRITE mode"
    else
        oradba_log WARN "Some PDBs may have failed to open in ${sid}"
        oradba_log DEBUG "${SCRIPT_NAME}: open_all_pdbs() - Some PDBs are not in READ WRITE mode"
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_database
# Purpose.: Stop an Oracle database instance with timeout and fallback
# Args....: $1 - Database SID
# Returns.: 0 on success, 1 on failure
# Output..: Status messages via oradba_log, SQL output to ${LOGFILE}
# Notes...: Tries SHUTDOWN IMMEDIATE with ${SHUTDOWN_TIMEOUT}; falls back to SHUTDOWN ABORT on timeout
# ------------------------------------------------------------------------------
stop_database() {
    local sid="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Stopping database '${sid}'"

    oradba_log INFO "Stopping database ${sid}..."

    # Source environment for this SID
    export ORACLE_SID="${sid}"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Set ORACLE_SID to '${sid}'"
    
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Sourcing environment from oraenv.sh"
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" > /dev/null 2>&1
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Environment sourced, ORACLE_HOME=${ORACLE_HOME}"
    else
        oradba_log ERROR "Cannot source oraenv.sh for ${sid}"
        return 1
    fi

    # Check if database is running
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Checking current database status"
    local status
    status=$(
        sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
    )
    
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Current status: '${status}'"

    if [[ ! "${status}" =~ (OPEN|MOUNTED) ]]; then
        oradba_log INFO "Database ${sid} is not running"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Database not running, skipping shutdown"
        return 0
    fi

    # Try shutdown immediate with timeout
    oradba_log INFO "Attempting shutdown immediate for ${sid} (timeout: ${SHUTDOWN_TIMEOUT}s)"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Executing SHUTDOWN IMMEDIATE with ${SHUTDOWN_TIMEOUT}s timeout"

    timeout "${SHUTDOWN_TIMEOUT}" sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR CONTINUE
SHUTDOWN IMMEDIATE;
EXIT;
EOF

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - SHUTDOWN IMMEDIATE completed with exit code: ${rc}"

    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Database ${sid} stopped successfully"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Shutdown completed successfully"
        return 0
    elif [[ ${rc} -eq 124 ]]; then
        # Timeout occurred
        oradba_log WARN "Shutdown immediate timed out for ${sid}, forcing shutdown abort"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Timeout occurred, attempting SHUTDOWN ABORT"

        sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
SHUTDOWN ABORT;
EXIT;
EOF
        local abort_rc=$?
        oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - SHUTDOWN ABORT completed with exit code: ${abort_rc}"
        
        if [[ ${abort_rc} -eq 0 ]]; then
            oradba_log INFO "Database ${sid} stopped with abort"
            oradba_log DEBUG "${SCRIPT_NAME}: stop_database() - Shutdown abort completed successfully"
            return 0
        else
            oradba_log ERROR "Failed to stop database ${sid} even with abort"
            return 1
        fi
    else
        oradba_log ERROR "Failed to stop database ${sid} (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: show_status
# Purpose.: Display current status of a database instance
# Args....: $1 - Database SID
# Returns.: 0 on success, 1 if environment sourcing fails
# Output..: One line: "SID: STATUS" or "SID: NOT RUNNING"
# Notes...: Queries v$instance for status (OPEN/MOUNTED/etc.); sources environment per SID
# ------------------------------------------------------------------------------
show_status() {
    local sid="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Checking status for database '${sid}'"

    # Source environment for this SID
    export ORACLE_SID="${sid}"
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Set ORACLE_SID to '${sid}'"
    
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        # shellcheck source=oraenv.sh
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Sourcing environment from oraenv.sh"
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" > /dev/null 2>&1
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Environment sourced, ORACLE_HOME=${ORACLE_HOME}"
    else
        echo "${sid}: Unable to source environment"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Failed to source oraenv.sh"
        return 1
    fi

    # Get database status
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Querying v\$instance for status"
    local status
    status=$(
        sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
    )
    
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Query result: '${status}'"

    if [[ -z "${status}" ]] || [[ "${status}" =~ ERROR ]]; then
        echo "${sid}: NOT RUNNING"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Database not running or query failed"
    else
        echo "${sid}: ${status}"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Database status: ${status}"
    fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
fi

# Check for global --debug flag first
for arg in "$@"; do
    if [[ "$arg" == "--debug" ]] || [[ "$arg" == "-d" ]]; then
        export ORADBA_LOG_LEVEL=DEBUG
        oradba_log DEBUG "${SCRIPT_NAME}: Debug mode enabled via CLI flag"
        break
    fi
done

# Check for ORADBA_DEBUG environment variable
if [[ "${ORADBA_DEBUG}" == "true" ]]; then
    export ORADBA_LOG_LEVEL=DEBUG
    oradba_log DEBUG "${SCRIPT_NAME}: Debug mode enabled via ORADBA_DEBUG environment variable"
fi

# Get action
ACTION="$1"
shift
oradba_log DEBUG "${SCRIPT_NAME}: Action specified: ${ACTION}"

case "${ACTION}" in
    start | stop | restart | status) ;;
    *) usage ;;
esac

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f | --force)
            FORCE_MODE=true
            oradba_log DEBUG "${SCRIPT_NAME}: Force mode enabled"
            shift
            ;;
        -t | --timeout)
            SHUTDOWN_TIMEOUT="$2"
            oradba_log DEBUG "${SCRIPT_NAME}: Shutdown timeout set to ${SHUTDOWN_TIMEOUT}s"
            shift 2
            ;;
        -p | --open-pdbs)
            OPEN_PDBS=true
            oradba_log DEBUG "${SCRIPT_NAME}: Open PDDs mode enabled"
            shift
            ;;
        -d | --debug)
            export ORADBA_LOG_LEVEL=DEBUG
            oradba_log DEBUG "${SCRIPT_NAME}: Debug mode enabled via CLI flag"
            shift
            ;;
        -h | --help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            SIDS+=("$1")
            oradba_log DEBUG "${SCRIPT_NAME}: Added SID to process: $1"
            shift
            ;;
    esac
done

# Log action
oradba_log INFO "========== Starting ${ACTION} operation =========="
oradba_log INFO "User: $(whoami), Host: $(hostname)"

# Determine which databases to process
if [[ ${#SIDS[@]} -eq 0 ]]; then
    # No SIDs specified, get all with :Y flag
    oradba_log INFO "No SIDs specified, processing all databases with :Y flag"
    oradba_log DEBUG "${SCRIPT_NAME}: Reading databases from oratab file"

    mapfile -t db_list < <(get_databases)
    oradba_log DEBUG "${SCRIPT_NAME}: Found ${#db_list[@]} database entries in oratab"

    if [[ ${#db_list[@]} -eq 0 ]]; then
        oradba_log ERROR "No databases found in oratab"
        exit 1
    fi

    # Filter for :Y flag
    for entry in "${db_list[@]}"; do
        IFS=: read -r sid home flag <<< "${entry}"
        oradba_log DEBUG "${SCRIPT_NAME}: Checking database entry - SID: ${sid}, HOME: ${home}, FLAG: ${flag}"
        if [[ "${flag}" == "Y" ]]; then
            SIDS+=("${sid}")
            oradba_log DEBUG "${SCRIPT_NAME}: Added SID '${sid}' to processing list (auto-start enabled)"
        fi
    done

    if [[ ${#SIDS[@]} -eq 0 ]]; then
        oradba_log ERROR "No databases marked for auto-start (:Y flag) in oratab"
        exit 1
    fi

    oradba_log DEBUG "${SCRIPT_NAME}: Selected ${#SIDS[@]} databases for processing: ${SIDS[*]}"

    # Ask for justification when operating on all
    if [[ "${ACTION}" != "status" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: Requesting justification for ${ACTION} operation on ${#SIDS[@]} databases"
        if ! ask_justification "${ACTION}" "${#SIDS[@]}"; then
            oradba_log DEBUG "${SCRIPT_NAME}: User cancelled operation during justification prompt"
            exit 1
        fi
        oradba_log DEBUG "${SCRIPT_NAME}: User confirmed operation"
    fi
else
    # Explicit SIDs provided
    oradba_log INFO "Processing specified databases: ${SIDS[*]}"
    oradba_log DEBUG "${SCRIPT_NAME}: ${#SIDS[@]} explicit SID(s) provided by user"
fi

# Process each database
success_count=0
failure_count=0

oradba_log DEBUG "${SCRIPT_NAME}: Starting to process ${#SIDS[@]} database(s) for action: ${ACTION}"

for sid in "${SIDS[@]}"; do
    oradba_log DEBUG "${SCRIPT_NAME}: Processing database '${sid}' with action '${ACTION}'"
    case "${ACTION}" in
        start)
            if start_database "${sid}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully started database '${sid}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to start database '${sid}'"
            fi
            ;;
        stop)
            if stop_database "${sid}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully stopped database '${sid}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to stop database '${sid}'"
            fi
            ;;
        restart)
            oradba_log DEBUG "${SCRIPT_NAME}: Restarting database '${sid}' (stop then start)"
            if stop_database "${sid}" && start_database "${sid}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully restarted database '${sid}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to restart database '${sid}'"
            fi
            ;;
        status)
            oradba_log DEBUG "${SCRIPT_NAME}: Checking status for database '${sid}'"
            show_status "${sid}"
            ;;
    esac
done

oradba_log DEBUG "${SCRIPT_NAME}: Completed processing all databases - Success: ${success_count}, Failures: ${failure_count}"

# Summary
if [[ "${ACTION}" != "status" ]]; then
    oradba_log INFO "========== Operation completed =========="
    oradba_log INFO "Success: ${success_count}, Failures: ${failure_count}"

    if [[ ${failure_count} -gt 0 ]]; then
        oradba_log WARN "Some databases failed to ${ACTION}"
        exit 1
    fi
fi

oradba_log INFO "Done"
exit 0

# EOF -------------------------------------------------------------------------
