#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_services.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
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
    start       Start Oracle services (listener and/or database)
    stop        Stop Oracle services (database and/or listener)
    restart     Restart Oracle services
    status      Show status of Oracle services

Options:
    -f, --force             Force operation without confirmation
    -c, --config FILE       Use alternate configuration file
    -h, --help              Show this help message

Configuration:
    Default config: ${ORADBA_BASE}/etc/oradba_services.conf
    
    Variables:
        STARTUP_ORDER          Service startup order (default: listener,database)
        SHUTDOWN_ORDER         Service shutdown order (default: database,listener)
        SPECIFIC_DBS           Specific database SIDs to control
        SPECIFIC_LISTENERS     Specific listeners to control
        DB_OPTIONS             Additional options for database control
        LSNR_OPTIONS           Additional options for listener control

Examples:
    ${SCRIPT_NAME} start                    # Start all services
    ${SCRIPT_NAME} stop --force             # Stop all without confirmation
    ${SCRIPT_NAME} restart                  # Restart all services
    ${SCRIPT_NAME} status                   # Show status

Environment Variables:
    ORADBA_LOG                 Log directory (default: /var/log/oracle)

EOF
    exit 1
}

# ------------------------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------------------------
# Enable file logging to service log
export ORADBA_LOG_FILE="${LOGFILE}"

# Load configuration file
load_config() {
    # Copy example config if it doesn't exist
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        local example_file="${ORADBA_BASE}/templates/etc/oradba_services.conf.example"
        if [[ -f "${example_file}" ]]; then
            oradba_log INFO "Configuration file not found, copying from template"
            mkdir -p "$(dirname "${CONFIG_FILE}")"
            cp "${example_file}" "${CONFIG_FILE}"
            oradba_log INFO "Created ${CONFIG_FILE} from template"
        else
            oradba_log WARN "No configuration template found at ${example_file}"
        fi
    fi
    
    if [[ -f "${CONFIG_FILE}" ]]; then
        oradba_log INFO "Loading configuration from ${CONFIG_FILE}"
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    else
        oradba_log INFO "No configuration file found, using defaults"
    fi
}

# Start listeners
start_listeners() {
    oradba_log INFO "Starting Oracle listeners..."

    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh start"

    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"

    # Add listener options
    [[ -n "${LSNR_OPTIONS}" ]] && cmd="${cmd} ${LSNR_OPTIONS}"

    # Add specific listeners if configured
    [[ -n "${SPECIFIC_LISTENERS}" ]] && cmd="${cmd} ${SPECIFIC_LISTENERS}"

    oradba_log INFO "Executing: ${cmd}"
    eval "${cmd}"

    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Listeners started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start listeners (exit code: ${rc})"
        return 1
    fi
}

# Stop listeners
stop_listeners() {
    oradba_log INFO "Stopping Oracle listeners..."

    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh stop"

    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"

    # Add listener options
    [[ -n "${LSNR_OPTIONS}" ]] && cmd="${cmd} ${LSNR_OPTIONS}"

    # Add specific listeners if configured
    [[ -n "${SPECIFIC_LISTENERS}" ]] && cmd="${cmd} ${SPECIFIC_LISTENERS}"

    oradba_log INFO "Executing: ${cmd}"
    eval "${cmd}"

    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Listeners stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop listeners (exit code: ${rc})"
        return 1
    fi
}

# Start databases
start_databases() {
    oradba_log INFO "Starting Oracle databases..."

    local cmd="${ORADBA_BIN}/oradba_dbctl.sh start"

    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"

    # Add database options
    [[ -n "${DB_OPTIONS}" ]] && cmd="${cmd} ${DB_OPTIONS}"

    # Add specific databases if configured
    [[ -n "${SPECIFIC_DBS}" ]] && cmd="${cmd} ${SPECIFIC_DBS}"

    oradba_log INFO "Executing: ${cmd}"
    eval "${cmd}"

    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Databases started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start databases (exit code: ${rc})"
        return 1
    fi
}

# Stop databases
stop_databases() {
    oradba_log INFO "Stopping Oracle databases..."

    local cmd="${ORADBA_BIN}/oradba_dbctl.sh stop"

    # Add force flag if set
    [[ "${FORCE_MODE}" == "true" ]] && cmd="${cmd} --force"

    # Add database options
    [[ -n "${DB_OPTIONS}" ]] && cmd="${cmd} ${DB_OPTIONS}"

    # Add specific databases if configured
    [[ -n "${SPECIFIC_DBS}" ]] && cmd="${cmd} ${SPECIFIC_DBS}"

    oradba_log INFO "Executing: ${cmd}"
    eval "${cmd}"

    local rc=$?
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Databases stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop databases (exit code: ${rc})"
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
    oradba_log INFO "========== Starting Oracle services =========="

    local success=true

    # Parse startup order
    IFS=',' read -ra order <<< "${STARTUP_ORDER}"

    for service in "${order[@]}"; do
        case "${service}" in
            listener)
                if ! start_listeners; then
                    oradba_log ERROR "Listener startup failed"
                    success=false
                fi
                ;;
            database)
                if ! start_databases; then
                    oradba_log ERROR "Database startup failed"
                    success=false
                fi
                ;;
            *)
                oradba_log WARN "Unknown service in startup order: ${service}"
                ;;
        esac
    done

    if [[ "${success}" == "true" ]]; then
        oradba_log INFO "All services started successfully"
        return 0
    else
        oradba_log ERROR "Some services failed to start"
        return 1
    fi
}

# Stop all services
stop_all() {
    oradba_log INFO "========== Stopping Oracle services =========="

    local success=true

    # Parse shutdown order
    IFS=',' read -ra order <<< "${SHUTDOWN_ORDER}"

    for service in "${order[@]}"; do
        case "${service}" in
            listener)
                if ! stop_listeners; then
                    oradba_log ERROR "Listener shutdown failed"
                    success=false
                fi
                ;;
            database)
                if ! stop_databases; then
                    oradba_log ERROR "Database shutdown failed"
                    success=false
                fi
                ;;
            *)
                oradba_log WARN "Unknown service in shutdown order: ${service}"
                ;;
        esac
    done

    if [[ "${success}" == "true" ]]; then
        oradba_log INFO "All services stopped successfully"
        return 0
    else
        oradba_log ERROR "Some services failed to stop"
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
    start | stop | restart | status) ;;
    *) usage ;;
esac

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f | --force)
            FORCE_MODE=true
            shift
            ;;
        -c | --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h | --help)
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
oradba_log INFO "========== Starting ${ACTION} operation =========="
oradba_log INFO "User: $(whoami), Host: $(hostname)"
oradba_log INFO "Startup order: ${STARTUP_ORDER}"
oradba_log INFO "Shutdown order: ${SHUTDOWN_ORDER}"

# Execute action
case "${ACTION}" in
    start)
        if start_all; then
            oradba_log INFO "Oracle services startup completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services startup completed with errors"
            exit 1
        fi
        ;;
    stop)
        if stop_all; then
            oradba_log INFO "Oracle services shutdown completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services shutdown completed with errors"
            exit 1
        fi
        ;;
    restart)
        if stop_all && sleep 5 && start_all; then
            oradba_log INFO "Oracle services restart completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services restart completed with errors"
            exit 1
        fi
        ;;
    status)
        show_status
        exit 0
        ;;
esac

# EOF -------------------------------------------------------------------------
