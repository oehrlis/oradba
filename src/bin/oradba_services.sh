#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_services.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
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
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    oradba_log DEBUG "${SCRIPT_NAME}: Sourced oradba_common.sh successfully"
else
    echo "ERROR: Cannot find oradba_common.sh library"
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

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display help for Oracle services orchestration
# Args....: None
# Returns.: Exits with code 1
# Output..: Multi-section help (actions, options, config, examples, env vars)
# Notes...: Shows start/stop/restart/status actions; explains config file usage
# ------------------------------------------------------------------------------
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
    -d, --debug             Enable debug logging
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
    ${SCRIPT_NAME} --debug start            # Start with debug logging
    ORADBA_DEBUG=true ${SCRIPT_NAME} status # Status with debug logging

Environment Variables:
    ORADBA_DEBUG               Enable debug logging (true/false)
    ORADBA_LOG                 Log directory (default: /var/log/oracle)

EOF
    exit 1
}

# ------------------------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------------------------
# Enable file logging to service log
export ORADBA_LOG_FILE="${LOGFILE}"

# ------------------------------------------------------------------------------
# Function: load_config
# Purpose.: Load oradba_services.conf or create from template
# Args....: None
# Returns.: 0 (always succeeds)
# Output..: Log messages for config loading/creation
# Notes...: Sources config file; creates from template if missing; uses defaults if unavailable
# ------------------------------------------------------------------------------
load_config() {
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Attempting to load config from: ${CONFIG_FILE}"
    
    # Copy example config if it doesn't exist
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        local example_file="${ORADBA_BASE}/templates/etc/oradba_services.conf.example"
        oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Config file not found, checking for template: ${example_file}"
        
        if [[ -f "${example_file}" ]]; then
            oradba_log INFO "Configuration file not found, copying from template"
            mkdir -p "$(dirname "${CONFIG_FILE}")"
            cp "${example_file}" "${CONFIG_FILE}"
            oradba_log INFO "Created ${CONFIG_FILE} from template"
            oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Successfully created config from template"
        else
            oradba_log WARN "No configuration template found at ${example_file}"
            oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Template not found, will use defaults"
        fi
    fi
    
    if [[ -f "${CONFIG_FILE}" ]]; then
        oradba_log INFO "Loading configuration from ${CONFIG_FILE}"
        oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Sourcing configuration file"
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Configuration loaded successfully"
    else
        oradba_log INFO "No configuration file found, using defaults"
        oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Using default configuration values"
    fi
    
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - Final config values:"
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - STARTUP_ORDER=${STARTUP_ORDER}"
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - SHUTDOWN_ORDER=${SHUTDOWN_ORDER}"
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - SPECIFIC_DBS=${SPECIFIC_DBS}"
    oradba_log DEBUG "${SCRIPT_NAME}: load_config() - SPECIFIC_LISTENERS=${SPECIFIC_LISTENERS}"
}

# ------------------------------------------------------------------------------
# Function: start_listeners
# Purpose.: Start Oracle listeners using oradba_lsnrctl.sh
# Args....: None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)
# Returns.: 0 on success, 1 on failure
# Output..: Log messages with command execution and results
# Notes...: Constructs oradba_lsnrctl.sh command with options; respects force mode
# ------------------------------------------------------------------------------
start_listeners() {
    oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Starting listener startup process"
    oradba_log INFO "Starting Oracle listeners..."

    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh start"
    oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Base command: ${cmd}"

    # Add force flag if set
    if [[ "${FORCE_MODE}" == "true" ]]; then
        cmd="${cmd} --force"
        oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Added --force flag"
    fi

    # Add listener options
    if [[ -n "${LSNR_OPTIONS}" ]]; then
        cmd="${cmd} ${LSNR_OPTIONS}"
        oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Added listener options: ${LSNR_OPTIONS}"
    fi

    # Add specific listeners if configured
    if [[ -n "${SPECIFIC_LISTENERS}" ]]; then
        cmd="${cmd} ${SPECIFIC_LISTENERS}"
        oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Added specific listeners: ${SPECIFIC_LISTENERS}"
    fi

    oradba_log INFO "Executing: ${cmd}"
    oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Executing command via eval"
    eval "${cmd}"

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_listeners() - Command completed with exit code: ${rc}"
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Listeners started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start listeners (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_listeners
# Purpose.: Stop Oracle listeners using oradba_lsnrctl.sh
# Args....: None (uses FORCE_MODE, LSNR_OPTIONS, SPECIFIC_LISTENERS from config)
# Returns.: 0 on success, 1 on failure
# Output..: Log messages with command execution and results
# Notes...: Constructs oradba_lsnrctl.sh stop command with options
# ------------------------------------------------------------------------------
stop_listeners() {
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Starting listener shutdown process"
    oradba_log INFO "Stopping Oracle listeners..."

    local cmd="${ORADBA_BIN}/oradba_lsnrctl.sh stop"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Base command: ${cmd}"

    # Add force flag if set
    if [[ "${FORCE_MODE}" == "true" ]]; then
        cmd="${cmd} --force"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Added --force flag"
    fi

    # Add listener options
    if [[ -n "${LSNR_OPTIONS}" ]]; then
        cmd="${cmd} ${LSNR_OPTIONS}"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Added listener options: ${LSNR_OPTIONS}"
    fi

    # Add specific listeners if configured
    if [[ -n "${SPECIFIC_LISTENERS}" ]]; then
        cmd="${cmd} ${SPECIFIC_LISTENERS}"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Added specific listeners: ${SPECIFIC_LISTENERS}"
    fi

    oradba_log INFO "Executing: ${cmd}"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Executing command via eval"
    eval "${cmd}"

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listeners() - Command completed with exit code: ${rc}"
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Listeners stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop listeners (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: start_databases
# Purpose.: Start Oracle databases using oradba_dbctl.sh
# Args....: None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)
# Returns.: 0 on success, 1 on failure
# Output..: Log messages with command execution and results
# Notes...: Constructs oradba_dbctl.sh start command with options
# ------------------------------------------------------------------------------
start_databases() {
    oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Starting database startup process"
    oradba_log INFO "Starting Oracle databases..."

    local cmd="${ORADBA_BIN}/oradba_dbctl.sh start"
    oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Base command: ${cmd}"

    # Add force flag if set
    if [[ "${FORCE_MODE}" == "true" ]]; then
        cmd="${cmd} --force"
        oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Added --force flag"
    fi

    # Add database options
    if [[ -n "${DB_OPTIONS}" ]]; then
        cmd="${cmd} ${DB_OPTIONS}"
        oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Added database options: ${DB_OPTIONS}"
    fi

    # Add specific databases if configured
    if [[ -n "${SPECIFIC_DBS}" ]]; then
        cmd="${cmd} ${SPECIFIC_DBS}"
        oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Added specific databases: ${SPECIFIC_DBS}"
    fi

    oradba_log INFO "Executing: ${cmd}"
    oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Executing command via eval"
    eval "${cmd}"

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_databases() - Command completed with exit code: ${rc}"
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Databases started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start databases (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_databases
# Purpose.: Stop Oracle databases using oradba_dbctl.sh
# Args....: None (uses FORCE_MODE, DB_OPTIONS, SPECIFIC_DBS from config)
# Returns.: 0 on success, 1 on failure
# Output..: Log messages with command execution and results
# Notes...: Constructs oradba_dbctl.sh stop command with options
# ------------------------------------------------------------------------------
stop_databases() {
    oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Starting database shutdown process"
    oradba_log INFO "Stopping Oracle databases..."

    local cmd="${ORADBA_BIN}/oradba_dbctl.sh stop"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Base command: ${cmd}"

    # Add force flag if set
    if [[ "${FORCE_MODE}" == "true" ]]; then
        cmd="${cmd} --force"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Added --force flag"
    fi

    # Add database options
    if [[ -n "${DB_OPTIONS}" ]]; then
        cmd="${cmd} ${DB_OPTIONS}"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Added database options: ${DB_OPTIONS}"
    fi

    # Add specific databases if configured
    if [[ -n "${SPECIFIC_DBS}" ]]; then
        cmd="${cmd} ${SPECIFIC_DBS}"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Added specific databases: ${SPECIFIC_DBS}"
    fi

    oradba_log INFO "Executing: ${cmd}"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Executing command via eval"
    eval "${cmd}"

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_databases() - Command completed with exit code: ${rc}"
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Databases stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop databases (exit code: ${rc})"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: show_status
# Purpose.: Show status of all Oracle services (databases and listeners)
# Args....: None
# Returns.: 0 (always succeeds)
# Output..: Combined status output from oradba_dbctl.sh and oradba_lsnrctl.sh
# Notes...: Calls oradba_dbctl.sh status and oradba_lsnrctl.sh status
# ------------------------------------------------------------------------------
show_status() {
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Displaying Oracle services status"
    echo ""
    echo "==========================================" 
    echo "Oracle Services Status"
    echo "==========================================" 
    echo ""

    echo "Listeners:"
    echo "----------"
    local lsnr_cmd="${ORADBA_BIN}/oradba_lsnrctl.sh status"
    if [[ -n "${SPECIFIC_LISTENERS}" ]]; then
        lsnr_cmd="${lsnr_cmd} ${SPECIFIC_LISTENERS}"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Added specific listeners to status check: ${SPECIFIC_LISTENERS}"
    fi
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Executing listener status: ${lsnr_cmd}"
    eval "${lsnr_cmd}"

    echo ""
    echo "Databases:"
    echo "----------"
    local db_cmd="${ORADBA_BIN}/oradba_dbctl.sh status"
    if [[ -n "${SPECIFIC_DBS}" ]]; then
        db_cmd="${db_cmd} ${SPECIFIC_DBS}"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Added specific databases to status check: ${SPECIFIC_DBS}"
    fi
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Executing database status: ${db_cmd}"

    echo ""
}

# ------------------------------------------------------------------------------
# Function: start_all
# Purpose.: Start all Oracle services in configured order
# Args....: None (uses STARTUP_ORDER from config)
# Returns.: 0 if all succeeded, 1 if any failures
# Output..: Log messages for each service startup, final summary
# Notes...: Processes STARTUP_ORDER (default: listener,database); tracks success/failure counts
# ------------------------------------------------------------------------------
start_all() {
    oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Starting all Oracle services in configured order"
    oradba_log INFO "========== Starting Oracle services =========="

    local success=true

    # Parse startup order
    IFS=',' read -ra order <<< "${STARTUP_ORDER}"
    oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Parsed startup order: ${order[*]}"

    for service in "${order[@]}"; do
        oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Processing service: ${service}"
        case "${service}" in
            listener)
                oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Starting listeners"
                if ! start_listeners; then
                    oradba_log ERROR "Listener startup failed"
                    success=false
                fi
                ;;
            database)
                oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Starting databases"
                if ! start_databases; then
                    oradba_log ERROR "Database startup failed"
                    success=false
                fi
                ;;
            *)
                oradba_log WARN "Unknown service in startup order: ${service}"
                oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Unknown service encountered: ${service}"
                ;;
        esac
    done

    if [[ "${success}" == "true" ]]; then
        oradba_log INFO "All services started successfully"
        oradba_log DEBUG "${SCRIPT_NAME}: start_all() - All services completed successfully"
        return 0
    else
        oradba_log ERROR "Some services failed to start"
        oradba_log DEBUG "${SCRIPT_NAME}: start_all() - Some services failed during startup"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_all
# Purpose.: Stop all Oracle services in configured order
# Args....: None (uses SHUTDOWN_ORDER from config)
# Returns.: 0 if all succeeded, 1 if any failures
# Output..: Log messages for each service shutdown, final summary
# Notes...: Processes SHUTDOWN_ORDER (default: database,listener); tracks success/failure counts
# ------------------------------------------------------------------------------
stop_all() {
    oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Stopping all Oracle services in configured order"
    oradba_log INFO "========== Stopping Oracle services =========="

    local success=true

    # Parse shutdown order
    IFS=',' read -ra order <<< "${SHUTDOWN_ORDER}"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Parsed shutdown order: ${order[*]}"

    for service in "${order[@]}"; do
        oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Processing service: ${service}"
        case "${service}" in
            listener)
                oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Stopping listeners"
                if ! stop_listeners; then
                    oradba_log ERROR "Listener shutdown failed"
                    success=false
                fi
                ;;
            database)
                oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Stopping databases"
                if ! stop_databases; then
                    oradba_log ERROR "Database shutdown failed"
                    success=false
                fi
                ;;
            *)
                oradba_log WARN "Unknown service in shutdown order: ${service}"
                oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Unknown service encountered: ${service}"
                ;;
        esac
    done

    if [[ "${success}" == "true" ]]; then
        oradba_log INFO "All services stopped successfully"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - All services completed successfully"
        return 0
    else
        oradba_log ERROR "Some services failed to stop"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_all() - Some services failed during shutdown"
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
        -c | --config)
            CONFIG_FILE="$2"
            oradba_log DEBUG "${SCRIPT_NAME}: Using custom config file: ${CONFIG_FILE}"
            shift 2
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
oradba_log DEBUG "${SCRIPT_NAME}: Configuration loaded and logged"

# Execute action
oradba_log DEBUG "${SCRIPT_NAME}: Executing action: ${ACTION}"
case "${ACTION}" in
    start)
        oradba_log DEBUG "${SCRIPT_NAME}: Calling start_all function"
        if start_all; then
            oradba_log INFO "Oracle services startup completed successfully"
            oradba_log DEBUG "${SCRIPT_NAME}: start_all completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services startup completed with errors"
            oradba_log DEBUG "${SCRIPT_NAME}: start_all failed"
            exit 1
        fi
        ;;
    stop)
        oradba_log DEBUG "${SCRIPT_NAME}: Calling stop_all function"
        if stop_all; then
            oradba_log INFO "Oracle services shutdown completed successfully"
            oradba_log DEBUG "${SCRIPT_NAME}: stop_all completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services shutdown completed with errors"
            oradba_log DEBUG "${SCRIPT_NAME}: stop_all failed"
            exit 1
        fi
        ;;
    restart)
        oradba_log DEBUG "${SCRIPT_NAME}: Calling stop_all, sleep 5, then start_all"
        if stop_all && sleep 5 && start_all; then
            oradba_log INFO "Oracle services restart completed successfully"
            oradba_log DEBUG "${SCRIPT_NAME}: restart sequence completed successfully"
            exit 0
        else
            oradba_log ERROR "Oracle services restart completed with errors"
            oradba_log DEBUG "${SCRIPT_NAME}: restart sequence failed"
            exit 1
        fi
        ;;
    status)
        oradba_log DEBUG "${SCRIPT_NAME}: Calling show_status function"
        show_status
        exit 0
        ;;
esac

# EOF -------------------------------------------------------------------------
