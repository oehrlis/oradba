#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_services.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.1.0
# Purpose....: Orchestrate Oracle database and listener services
# Notes......: Uses oradba_dbctl.sh and oradba_lsnrctl.sh for operations
#              Can be configured via oradba_services.conf
#              Requires oracle user privileges
# Usage......: oradba_services.sh {start|stop|restart|status}
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

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
CONFIG_FILE="${ORADBA_BASE}/etc/oradba_services.conf"
FORCE_MODE=false
ACTION=""
LOGFILE="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}.log"

# Default configuration
STARTUP_ORDER="listener,database"
SHUTDOWN_ORDER="database,listener"
SPECIFIC_DBS=""
SPECIFIC_LISTENERS=""
DB_OPTIONS=""
LSNR_OPTIONS=""

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Show usage
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} {start|stop|restart|status} [OPTIONS]

Actions:
    start       Start all Oracle services (listeners and databases)
    stop        Stop all Oracle services (databases and listeners)
    restart     Restart all Oracle services
    status      Show status of all Oracle services

Options:
    -f, --force             Force operation without confirmation
    -c, --config FILE       Use alternate configuration file
    -h, --help              Show this help message

Configuration:
    Configuration file: ${CONFIG_FILE}
    
    Variables:
        STARTUP_ORDER       Order of service startup (default: listener,database)
        SHUTDOWN_ORDER      Order of service shutdown (default: database,listener)
        SPECIFIC_DBS        Space-separated list of specific databases
        SPECIFIC_LISTENERS  Space-separated list of specific listeners
        DB_OPTIONS          Additional options for oradba_dbctl.sh
        LSNR_OPTIONS        Additional options for oradba_lsnrctl.sh

Examples:
    ${SCRIPT_NAME} start                # Start all Oracle services
    ${SCRIPT_NAME} stop --force         # Stop all without confirmation
    ${SCRIPT_NAME} status               # Show status of all services
    ${SCRIPT_NAME} restart              # Restart all services

Environment Variables:
    ORADBA_LOG          Log directory (default: /var/log/oracle)

EOF
    exit 1
}

# Log message to file and stdout
log_message() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "${LOGFILE}")" 2>/dev/null
    
    # Log to file
    echo "[${timestamp}] [${level}] ${message}" >> "${LOGFILE}" 2>/dev/null
    
    # Log to stdout with color
    case "${level}" in
        INFO)  echo -e "\033[0;32m[INFO]\033[0m ${message}" ;;
        WARN)  echo -e "\033[0;33m[WARN]\033[0m ${message}" ;;
        ERROR) echo -e "\033[0;31m[ERROR]\033[0m ${message}" ;;
        *)     echo "[${level}] ${message}" ;;
    esac
}

# Load configuration file
load_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        log_message INFO "Loading configuration from ${CONFIG_FILE}"
        source "${CONFIG_FILE}"
    else
        log_message INFO "No configuration file found, using defaults"
    fi
}

# Start listeners
start_listeners() {
    log_message INFO "Starting Oracle listeners..."
    
    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh start"
    
    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"
    
    # Add listener options
    [[ -n "${LSNR_OPTIONS}" ]] && cmd="${cmd} ${LSNR_OPTIONS}"
    
    # Add specific listeners if configured
    [[ -n "${SPECIFIC_LISTENERS}" ]] && cmd="${cmd} ${SPECIFIC_LISTENERS}"
    
    log_message INFO "Executing: ${cmd}"
    eval "${cmd}"
    
    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log_message INFO "Listeners started successfully"
        return 0
    else
        log_message ERROR "Failed to start listeners (exit code: ${rc})"
        return 1
    fi
}

# Stop listeners
stop_listeners() {
    log_message INFO "Stopping Oracle listeners..."
    
    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh stop"
    
    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"
    
    # Add listener options
    [[ -n "${LSNR_OPTIONS}" ]] && cmd="${cmd} ${LSNR_OPTIONS}"
    
    # Add specific listeners if configured
    [[ -n "${SPECIFIC_LISTENERS}" ]] && cmd="${cmd} ${SPECIFIC_LISTENERS}"
    
    log_message INFO "Executing: ${cmd}"
    eval "${cmd}"
    
    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log_message INFO "Listeners stopped successfully"
        return 0
    else
        log_message ERROR "Failed to stop listeners (exit code: ${rc})"
        return 1
    fi
}

# Start databases
start_databases() {
    log_message INFO "Starting Oracle databases..."
    
    local cmd="${ORADBA_BIN}/oradba_dbctl.sh start"
    
    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"
    
    # Add database options
    [[ -n "${DB_OPTIONS}" ]] && cmd="${cmd} ${DB_OPTIONS}"
    
    # Add specific databases if configured
    [[ -n "${SPECIFIC_DBS}" ]] && cmd="${cmd} ${SPECIFIC_DBS}"
    
    log_message INFO "Executing: ${cmd}"
    eval "${cmd}"
    
    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log_message INFO "Databases started successfully"
        return 0
    else
        log_message ERROR "Failed to start databases (exit code: ${rc})"
        return 1
    fi
}

# Stop databases
stop_databases() {
    log_message INFO "Stopping Oracle databases..."
    
    local cmd="${ORADBA_BIN}/oradba_dbctl.sh stop"
    
    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"
    
    # Add database options
    [[ -n "${DB_OPTIONS}" ]] && cmd="${cmd} ${DB_OPTIONS}"
    
    # Add specific databases if configured
    [[ -n "${SPECIFIC_DBS}" ]] && cmd="${cmd} ${SPECIFIC_DBS}"
    
    log_message INFO "Executing: ${cmd}"
    eval "${cmd}"
    
    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log_message INFO "Databases stopped successfully"
        return 0
    else
        log_message ERROR "Failed to stop databases (exit code: ${rc})"
        return 1
    fi
}

# Show status
show_status() {
    echo ""
    echo "=========================================="
    echo "Oracle Services Status"
    echo "=========================================="
    echo ""
    
    echo "Listeners:"
    echo "----------"
    local lsnr_cmd="${ORADBA_BIN}/oradba_lsnrctl.sh status"
    [[ -n "${SPECIFIC_LISTENERS}" ]] && lsnr_cmd="${lsnr_cmd} ${SPECIFIC_LISTENERS}"
    eval "${lsnr_cmd}"
    
    echo ""
    echo "Databases:"
    echo "----------"
    local db_cmd="${ORADBA_BIN}/oradba_dbctl.sh status"
    [[ -n "${SPECIFIC_DBS}" ]] && db_cmd="${db_cmd} ${SPECIFIC_DBS}"
    eval "${db_cmd}"
    
    echo ""
}

# Start all services
start_all() {
    log_message INFO "========== Starting Oracle services =========="
    
    local success=true
    
    # Parse startup order
    IFS=',' read -ra order <<< "${STARTUP_ORDER}"
    
    for service in "${order[@]}"; do
        case "${service}" in
            listener)
                if ! start_listeners; then
                    log_message ERROR "Listener startup failed"
                    success=false
                fi
                ;;
            database)
                if ! start_databases; then
                    log_message ERROR "Database startup failed"
                    success=false
                fi
                ;;
            *)
                log_message WARN "Unknown service in startup order: ${service}"
                ;;
        esac
    done
    
    if [[ "${success}" == "true" ]]; then
        log_message INFO "All services started successfully"
        return 0
    else
        log_message ERROR "Some services failed to start"
        return 1
    fi
}

# Stop all services
stop_all() {
    log_message INFO "========== Stopping Oracle services =========="
    
    local success=true
    
    # Parse shutdown order
    IFS=',' read -ra order <<< "${SHUTDOWN_ORDER}"
    
    for service in "${order[@]}"; do
        case "${service}" in
            listener)
                if ! stop_listeners; then
                    log_message ERROR "Listener shutdown failed"
                    success=false
                fi
                ;;
            database)
                if ! stop_databases; then
                    log_message ERROR "Database shutdown failed"
                    success=false
                fi
                ;;
            *)
                log_message WARN "Unknown service in shutdown order: ${service}"
                ;;
        esac
    done
    
    if [[ "${success}" == "true" ]]; then
        log_message INFO "All services stopped successfully"
        return 0
    else
        log_message ERROR "Some services failed to stop"
        return 1
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
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            echo "Unexpected argument: $1"
            usage
            ;;
    esac
done

# Load configuration
load_config

# Log action
log_message INFO "========== Starting ${ACTION} operation =========="
log_message INFO "User: $(whoami), Host: $(hostname)"
log_message INFO "Startup order: ${STARTUP_ORDER}"
log_message INFO "Shutdown order: ${SHUTDOWN_ORDER}"

# Execute action
case "${ACTION}" in
    start)
        if start_all; then
            log_message INFO "Oracle services startup completed successfully"
            exit 0
        else
            log_message ERROR "Oracle services startup completed with errors"
            exit 1
        fi
        ;;
    stop)
        if stop_all; then
            log_message INFO "Oracle services shutdown completed successfully"
            exit 0
        else
            log_message ERROR "Oracle services shutdown completed with errors"
            exit 1
        fi
        ;;
    restart)
        if stop_all && sleep 5 && start_all; then
            log_message INFO "Oracle services restart completed successfully"
            exit 0
        else
            log_message ERROR "Oracle services restart completed with errors"
            exit 1
        fi
        ;;
    status)
        show_status
        exit 0
        ;;
esac

# EOF -------------------------------------------------------------------------
