#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_lsnrctl.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.10.0
# Purpose....: Oracle listener start/stop control script
# Notes......: Can be used interactively or in runlevel/systemd scripts
#              Supports multiple listeners across different Oracle homes
#              Requires oracle user privileges
# Usage......: oradba_lsnrctl.sh {start|stop|restart|status} [LISTENER1 ...]
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
FORCE_MODE=false
ACTION=""
LISTENERS=()
LOGFILE="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}.log"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Show usage
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} {start|stop|restart|status} [OPTIONS] [LISTENER1 LISTENER2 ...]

Actions:
    start       Start Oracle listener(s)
    stop        Stop Oracle listener(s)
    restart     Restart Oracle listener(s)
    status      Show status of Oracle listener(s)

Options:
    -f, --force             Force operation without confirmation
    -h, --help              Show this help message

Arguments:
    LISTENER                Specific listener name(s) to control
                           If not specified, starts default listener from first Oracle home

Examples:
    ${SCRIPT_NAME} start                    # Start default listener
    ${SCRIPT_NAME} start LISTENER LISTENER2 # Start specific listeners
    ${SCRIPT_NAME} stop --force             # Stop all without confirmation
    ${SCRIPT_NAME} status                   # Show status of all listeners

Environment Variables:
    ORADBA_LOG                 Log directory (default: /var/log/oracle)
    ORATAB                     Path to oratab file (default: /etc/oratab)
    TNS_ADMIN                  TNS configuration directory

EOF
    exit 1
}

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# Get first Oracle home from oratab
get_first_oracle_home() {
    local oratab_file="${ORATAB:-/etc/oratab}"

    if [[ ! -f "${oratab_file}" ]]; then
        oradba_log ERROR "oratab file not found: ${oratab_file}"
        return 1
    fi

    # Get first valid Oracle home
    local oracle_home
    oracle_home=$(grep -v '^#' "${oratab_file}" | grep -v '^$' | grep -v ':D$' | head -1 | cut -d: -f2)

    if [[ -z "${oracle_home}" ]]; then
        oradba_log ERROR "No Oracle home found in oratab"
        return 1
    fi

    echo "${oracle_home}"
}

# Set Oracle environment for listener operations
set_listener_env() {
    local listener_name="$1"
    local oracle_home

    # Get Oracle home - try from listener configuration or use first from oratab
    oracle_home=$(get_first_oracle_home)

    if [[ -z "${oracle_home}" ]]; then
        oradba_log ERROR "Cannot determine Oracle home"
        return 1
    fi

    export ORACLE_HOME="${oracle_home}"
    export PATH="${ORACLE_HOME}/bin:${PATH}"

    # Set TNS_ADMIN if not already set
    if [[ -z "${TNS_ADMIN}" ]]; then
        if [[ -d "${ORACLE_HOME}/network/admin" ]]; then
            export TNS_ADMIN="${ORACLE_HOME}/network/admin"
        fi
    fi

    return 0
}

# Get list of running listeners
get_running_listeners() {
    set_listener_env "LISTENER"

    # Get list of listeners from lsnrctl
    lsnrctl services 2> /dev/null | grep "^Listener" | awk '{print $2}' | sort -u
}

# Ask for justification when operating on all listeners
ask_justification() {
    local action="$1"
    local count="$2"

    if [[ "${FORCE_MODE}" == "true" ]]; then
        return 0
    fi

    echo ""
    echo "=========================================="
    echo "WARNING: About to ${action} ALL listeners"
    echo "=========================================="
    echo "This will affect ${count} listener(s)"
    echo ""
    read -p "Please provide justification for this operation: " justification

    if [[ -z "${justification}" ]]; then
        oradba_log ERROR "Operation cancelled: No justification provided"
        return 1
    fi

    oradba_log INFO "Justification for ${action} all listeners: ${justification}"
    read -p "Continue with operation? (yes/no): " confirm

    if [[ "${confirm}" != "yes" ]]; then
        oradba_log INFO "Operation cancelled by user"
        return 1
    fi

    return 0
}

# Start a listener
start_listener() {
    local listener_name="$1"

    oradba_log INFO "Starting listener ${listener_name}..."

    # Set environment
    if ! set_listener_env "${listener_name}"; then
        oradba_log ERROR "Failed to set environment for ${listener_name}"
        return 1
    fi

    # Check if listener is already running
    lsnrctl status "${listener_name}" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} is already running"
        return 0
    fi

    # Start the listener
    lsnrctl start "${listener_name}" >> "${LOGFILE}" 2>&1

    if [[ $? -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start listener ${listener_name}"
        return 1
    fi
}

# Stop a listener
stop_listener() {
    local listener_name="$1"

    oradba_log INFO "Stopping listener ${listener_name}..."

    # Set environment
    if ! set_listener_env "${listener_name}"; then
        oradba_log ERROR "Failed to set environment for ${listener_name}"
        return 1
    fi

    # Check if listener is running
    lsnrctl status "${listener_name}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        oradba_log INFO "Listener ${listener_name} is not running"
        return 0
    fi

    # Stop the listener
    lsnrctl stop "${listener_name}" >> "${LOGFILE}" 2>&1

    if [[ $? -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop listener ${listener_name}"
        return 1
    fi
}

# Show listener status
show_status() {
    local listener_name="$1"

    # Set environment
    if ! set_listener_env "${listener_name}"; then
        echo "${listener_name}: Unable to set environment"
        return 1
    fi

    # Get listener status
    lsnrctl status "${listener_name}" 2>&1 | grep -q "is not running"
    if [[ $? -eq 0 ]]; then
        echo "${listener_name}: NOT RUNNING"
    else
        lsnrctl status "${listener_name}" 2>&1 | grep -A1 "Listening Endpoints" | tail -1 | sed "s/^/${listener_name}: /"
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
        -h | --help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            LISTENERS+=("$1")
            shift
            ;;
    esac
done

# Log action
oradba_log INFO "========== Starting ${ACTION} operation =========="
oradba_log INFO "User: $(whoami), Host: $(hostname)"

# Determine which listeners to process
if [[ ${#LISTENERS[@]} -eq 0 ]]; then
    # No listeners specified, use default
    oradba_log INFO "No listeners specified, using default LISTENER"
    LISTENERS=("LISTENER")

    # For status, show all running listeners
    if [[ "${ACTION}" == "status" ]]; then
        mapfile -t running < <(get_running_listeners)
        if [[ ${#running[@]} -gt 0 ]]; then
            LISTENERS=("${running[@]}")
        fi
    fi
else
    # Explicit listeners provided
    oradba_log INFO "Processing specified listeners: ${LISTENERS[*]}"

    # Ask for justification if multiple listeners
    if [[ ${#LISTENERS[@]} -gt 1 ]] && [[ "${ACTION}" != "status" ]]; then
        if ! ask_justification "${ACTION}" "${#LISTENERS[@]}"; then
            exit 1
        fi
    fi
fi

# Process each listener
success_count=0
failure_count=0

for listener in "${LISTENERS[@]}"; do
    case "${ACTION}" in
        start)
            if start_listener "${listener}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        stop)
            if stop_listener "${listener}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        restart)
            if stop_listener "${listener}" && start_listener "${listener}"; then
                ((success_count++))
            else
                ((failure_count++))
            fi
            ;;
        status)
            show_status "${listener}"
            ;;
    esac
done

# Summary
if [[ "${ACTION}" != "status" ]]; then
    oradba_log INFO "========== Operation completed =========="
    oradba_log INFO "Success: ${success_count}, Failures: ${failure_count}"

    if [[ ${failure_count} -gt 0 ]]; then
        oradba_log WARN "Some listeners failed to ${ACTION}"
        exit 1
    fi
fi

oradba_log INFO "Done"
exit 0

# EOF -------------------------------------------------------------------------
