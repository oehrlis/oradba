#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_dbctl.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.10.0
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
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    source "${ORADBA_BASE}/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library"
    exit 1
fi

# Source DB functions
if [[ -f "${ORADBA_BASE}/lib/db_functions.sh" ]]; then
    source "${ORADBA_BASE}/lib/db_functions.sh"
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

# Show usage
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

Environment Variables:
    ORADBA_SHUTDOWN_TIMEOUT    Shutdown timeout in seconds (default: ${DEFAULT_SHUTDOWN_TIMEOUT})
    ORADBA_LOG                 Log directory (default: /var/log/oracle)
    ORATAB                     Path to oratab file (default: /etc/oratab)

EOF
    exit 1
}

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# Get list of databases from oratab
get_databases() {
    local oratab_file="${ORATAB:-/etc/oratab}"
    
    if [[ ! -f "${oratab_file}" ]]; then
        log ERROR "oratab file not found: ${oratab_file}"
        return 1
    fi
    
    # Parse oratab, filter out comments and dummy entries
    grep -v '^#' "${oratab_file}" | grep -v '^$' | while IFS=: read -r sid home flag rest; do
        # Skip dummy entries
        [[ "${flag}" == "D" ]] && continue
        
        echo "${sid}:${home}:${flag}"
    done
}

# Check if database should be auto-started
should_autostart() {
    local sid="$1"
    local oratab_file="${ORATAB:-/etc/oratab}"
    local flag
    
    flag=$(grep "^${sid}:" "${oratab_file}" | cut -d: -f3)
    [[ "${flag}" == "Y" ]]
}

# Ask for justification when operating on all databases
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
    read -p "Please provide justification for this operation: " justification
    
    if [[ -z "${justification}" ]]; then
        log ERROR "Operation cancelled: No justification provided"
        return 1
    fi
    
    log INFO "Justification for ${action} all databases: ${justification}"
    read -p "Continue with operation? (yes/no): " confirm
    
    if [[ "${confirm}" != "yes" ]]; then
        log INFO "Operation cancelled by user"
        return 1
    fi
    
    return 0
}

# Start a database instance
start_database() {
    local sid="$1"
    
    log INFO "Starting database ${sid}..."
    
    # Source environment for this SID
    export ORACLE_SID="${sid}"
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" >/dev/null 2>&1
    else
        log ERROR "Cannot source oraenv.sh for ${sid}"
        return 1
    fi
    
    # Check if database is already running
    local status
    status=$(sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
)
    
    if [[ "${status}" =~ OPEN ]]; then
        log INFO "Database ${sid} is already running"
        return 0
    fi
    
    # Start the database
    sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP;
EXIT;
EOF
    
    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log INFO "Database ${sid} started successfully"
        
        # Open PDBs if requested
        if [[ "${OPEN_PDBS}" == "true" ]]; then
            open_all_pdbs "${sid}"
        fi
        return 0
    else
        log ERROR "Failed to start database ${sid} (exit code: ${rc})"
        return 1
    fi
}

# Open all PDBs
open_all_pdbs() {
    local sid="$1"
    
    log INFO "Opening all PDBs in ${sid}..."
    
    sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR CONTINUE
ALTER PLUGGABLE DATABASE ALL OPEN;
EXIT;
EOF
    
    if [[ $? -eq 0 ]]; then
        log INFO "All PDBs opened successfully in ${sid}"
    else
        log WARN "Some PDBs may have failed to open in ${sid}"
    fi
}

# Stop a database instance
stop_database() {
    local sid="$1"
    
    log INFO "Stopping database ${sid}..."
    
    # Source environment for this SID
    export ORACLE_SID="${sid}"
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" >/dev/null 2>&1
    else
        log ERROR "Cannot source oraenv.sh for ${sid}"
        return 1
    fi
    
    # Check if database is running
    local status
    status=$(sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
)
    
    if [[ ! "${status}" =~ (OPEN|MOUNTED) ]]; then
        log INFO "Database ${sid} is not running"
        return 0
    fi
    
    # Try shutdown immediate with timeout
    log INFO "Attempting shutdown immediate for ${sid} (timeout: ${SHUTDOWN_TIMEOUT}s)"
    
    timeout ${SHUTDOWN_TIMEOUT} sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
WHENEVER SQLERROR CONTINUE
SHUTDOWN IMMEDIATE;
EXIT;
EOF
    
    local rc=$?
    
    if [[ ${rc} -eq 0 ]]; then
        log INFO "Database ${sid} stopped successfully"
        return 0
    elif [[ ${rc} -eq 124 ]]; then
        # Timeout occurred
        log WARN "Shutdown immediate timed out for ${sid}, forcing shutdown abort"
        
        sqlplus -s / as sysdba << EOF >> "${LOGFILE}" 2>&1
SHUTDOWN ABORT;
EXIT;
EOF
        
        if [[ $? -eq 0 ]]; then
            log INFO "Database ${sid} stopped with abort"
            return 0
        else
            log ERROR "Failed to stop database ${sid} even with abort"
            return 1
        fi
    else
        log ERROR "Failed to stop database ${sid} (exit code: ${rc})"
        return 1
    fi
}

# Show database status
show_status() {
    local sid="$1"
    
    # Source environment for this SID
    export ORACLE_SID="${sid}"
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" >/dev/null 2>&1
    else
        echo "${sid}: Unable to source environment"
        return 1
    fi
    
    # Get database status
    local status
    status=$(sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v\$instance WHERE rownum = 1;
EXIT;
EOF
)
    
    if [[ -z "${status}" ]] || [[ "${status}" =~ ERROR ]]; then
        echo "${sid}: NOT RUNNING"
    else
        echo "${sid}: ${status}"
    fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
fi

# Get action
ACTION="$1"
shift

case "${ACTION}" in
    start|stop|restart|status) ;;
    *) usage ;;
esac

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -t|--timeout)
            SHUTDOWN_TIMEOUT="$2"
            shift 2
            ;;
        -p|--open-pdbs)
            OPEN_PDBS=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            SIDS+=("$1")
            shift
            ;;
    esac
done

# Log action
log INFO "========== Starting ${ACTION} operation =========="
log INFO "User: $(whoami), Host: $(hostname)"

# Determine which databases to process
if [[ ${#SIDS[@]} -eq 0 ]]; then
    # No SIDs specified, get all with :Y flag
    log INFO "No SIDs specified, processing all databases with :Y flag"
    
    mapfile -t db_list < <(get_databases)
    
    if [[ ${#db_list[@]} -eq 0 ]]; then
        log ERROR "No databases found in oratab"
        exit 1
    fi
    
    # Filter for :Y flag
    for entry in "${db_list[@]}"; do
        IFS=: read -r sid home flag <<< "${entry}"
        if [[ "${flag}" == "Y" ]]; then
            SIDS+=("${sid}")
        fi
    done
    
    if [[ ${#SIDS[@]} -eq 0 ]]; then
        log ERROR "No databases marked for auto-start (:Y flag) in oratab"
        exit 1
    fi
    
    # Ask for justification when operating on all
    if [[ "${ACTION}" != "status" ]]; then
        if ! ask_justification "${ACTION}" "${#SIDS[@]}"; then
            exit 1
        fi
    fi
else
    # Explicit SIDs provided
    log INFO "Processing specified databases: ${SIDS[*]}"
fi

# Process each database
success_count=0
failure_count=0

for sid in "${SIDS[@]}"; do
    case "${ACTION}" in
        start)
            if start_database "${sid}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        stop)
            if stop_database "${sid}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        restart)
            if stop_database "${sid}" && start_database "${sid}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        status)
            show_status "${sid}"
            ;;
    esac
done

# Summary
if [[ "${ACTION}" != "status" ]]; then
    log INFO "========== Operation completed =========="
    log INFO "Success: ${success_count}, Failures: ${failure_count}"
    
    if [[ ${failure_count} -gt 0 ]]; then
        log WARN "Some databases failed to ${ACTION}"
        exit 1
    fi
fi

log INFO "Done"
exit 0

# EOF -------------------------------------------------------------------------
