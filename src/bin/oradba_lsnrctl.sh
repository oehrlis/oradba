#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_lsnrctl.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
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
FORCE_MODE=false
ACTION=""
LISTENERS=()
LOGFILE="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}.log"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display help for Oracle listener control
# Args....: None
# Returns.: Exits with code 1
# Output..: Multi-section help (actions, options, arguments, examples, env vars)
# Notes...: Shows start/stop/restart/status actions; supports multiple listeners
# ------------------------------------------------------------------------------
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
    -d, --debug             Enable debug logging
    -h, --help              Show this help message

Arguments:
    LISTENER                Specific listener name(s) to control
                           If not specified, starts default listener from first Oracle home

Examples:
    ${SCRIPT_NAME} start                    # Start default listener
    ${SCRIPT_NAME} start LISTENER LISTENER2 # Start specific listeners
    ${SCRIPT_NAME} stop --force             # Stop all without confirmation
    ${SCRIPT_NAME} status                   # Show status of all listeners
    ${SCRIPT_NAME} --debug start LISTENER   # Start with debug logging
    ORADBA_DEBUG=true ${SCRIPT_NAME} status # Status with debug logging

Environment Variables:
    ORADBA_DEBUG               Enable debug logging (true/false)
    ORADBA_LOG                 Log directory (default: /var/log/oracle)
    ORATAB                     Path to oratab file (default: /etc/oratab)
    TNS_ADMIN                  TNS configuration directory

EOF
    exit 1
}

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# ------------------------------------------------------------------------------
# Function: get_first_oracle_home
# Purpose.: Get first valid Oracle Home from oratab
# Args....: None (reads from ${ORATAB} or /etc/oratab)
# Returns.: 0 on success, 1 if oratab not found or no valid home
# Output..: Oracle Home path to stdout
# Notes...: Skips entries marked :D (dummy); returns first active database home
# ------------------------------------------------------------------------------
get_first_oracle_home() {
    local oratab_file="${ORATAB:-/etc/oratab}"
    oradba_log DEBUG "${SCRIPT_NAME}: get_first_oracle_home() - Reading oratab from: ${oratab_file}"

    if [[ ! -f "${oratab_file}" ]]; then
        oradba_log ERROR "oratab file not found: ${oratab_file}"
        return 1
    fi

    # Get first valid Oracle home
    local oracle_home
    oracle_home=$(grep -v '^#' "${oratab_file}" | grep -v '^$' | grep -v ':D$' | head -1 | cut -d: -f2)
    oradba_log DEBUG "${SCRIPT_NAME}: get_first_oracle_home() - Extracted Oracle Home: ${oracle_home}"

    if [[ -z "${oracle_home}" ]]; then
        oradba_log ERROR "No Oracle home found in oratab"
        return 1
    fi

    echo "${oracle_home}"
}

# ------------------------------------------------------------------------------
# Function: set_listener_env
# Purpose.: Set Oracle environment for listener operations (ORACLE_HOME, PATH, TNS_ADMIN)
# Args....: $1 - Listener name (currently unused, reserved for future)
# Returns.: 0 on success, 1 if cannot determine Oracle Home
# Output..: None (sets environment variables)
# Notes...: Gets Oracle Home from get_first_oracle_home; exports ORACLE_HOME, PATH, TNS_ADMIN
# ------------------------------------------------------------------------------
set_listener_env() {
    local listener_name="$1"
    local oracle_home
    oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Setting environment for listener '${listener_name}'"

    # Get Oracle home - try from listener configuration or use first from oratab
    oracle_home=$(get_first_oracle_home)
    oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Oracle Home determined: ${oracle_home}"

    if [[ -z "${oracle_home}" ]]; then
        oradba_log ERROR "Cannot determine Oracle home"
        return 1
    fi

    export ORACLE_HOME="${oracle_home}"
    export PATH="${ORACLE_HOME}/bin:${PATH}"
    oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Set ORACLE_HOME=${ORACLE_HOME}"
    oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Updated PATH to include ${ORACLE_HOME}/bin"

    # Set TNS_ADMIN if not already set
    if [[ -z "${TNS_ADMIN}" ]]; then
        if [[ -d "${ORACLE_HOME}/network/admin" ]]; then
            export TNS_ADMIN="${ORACLE_HOME}/network/admin"
            oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Set TNS_ADMIN=${TNS_ADMIN}"
        else
            oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - TNS_ADMIN directory not found: ${ORACLE_HOME}/network/admin"
        fi
    else
        oradba_log DEBUG "${SCRIPT_NAME}: set_listener_env() - Using existing TNS_ADMIN=${TNS_ADMIN}"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: get_running_listeners
# Purpose.: Get list of all currently running listeners
# Args....: None
# Returns.: 0 (always succeeds)
# Output..: List of listener names (one per line, sorted, unique)
# Notes...: Uses lsnrctl services to detect running listeners; parses output for names
# ------------------------------------------------------------------------------
get_running_listeners() {
    set_listener_env "LISTENER"

    # Get list of listeners from lsnrctl
    lsnrctl services 2> /dev/null | grep "^Listener" | awk '{print $2}' | sort -u
}

# ------------------------------------------------------------------------------
# Function: ask_justification
# Purpose.: Prompt for justification when operating on all listeners (safety check)
# Args....: $1 - Action name (start/stop/restart), $2 - Count of affected listeners
# Returns.: 0 if user confirms, 1 if cancelled or no justification
# Output..: Warning banner, prompts for justification and confirmation
# Notes...: Skipped if FORCE_MODE=true; requires "yes" confirmation to proceed
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: start_listener
# Purpose.: Start specified Oracle listener
# Args....: $1 - Listener name
# Returns.: 0 on success, 1 if failed to set env or start
# Output..: Log messages; lsnrctl output redirected to LOGFILE
# Notes...: Checks if already running first; uses lsnrctl start
# ------------------------------------------------------------------------------
start_listener() {
    local listener_name="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - Starting listener '${listener_name}'"

    oradba_log INFO "Starting listener ${listener_name}..."

    # Set environment
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - Setting environment for listener"
    if ! set_listener_env "${listener_name}"; then
        oradba_log ERROR "Failed to set environment for ${listener_name}"
        return 1
    fi

    # Check if listener is already running
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - Checking if listener is already running"
    lsnrctl status "${listener_name}" > /dev/null 2>&1
    local status_rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - lsnrctl status exit code: ${status_rc}"
    
    if [[ ${status_rc} -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} is already running"
        oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - Listener already running, skipping startup"
        return 0
    fi

    # Start the listener
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - Executing lsnrctl start command"
    lsnrctl start "${listener_name}" >> "${LOGFILE}" 2>&1
    local start_rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_listener() - lsnrctl start exit code: ${start_rc}"

    if [[ ${start_rc} -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start listener ${listener_name}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_listener
# Purpose.: Stop specified Oracle listener
# Args....: $1 - Listener name
# Returns.: 0 on success, 1 if failed to set env or stop
# Output..: Log messages; lsnrctl output redirected to LOGFILE
# Notes...: Checks if running first; uses lsnrctl stop
# ------------------------------------------------------------------------------
stop_listener() {
    local listener_name="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - Stopping listener '${listener_name}'"

    oradba_log INFO "Stopping listener ${listener_name}..."

    # Set environment
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - Setting environment for listener"
    if ! set_listener_env "${listener_name}"; then
        oradba_log ERROR "Failed to set environment for ${listener_name}"
        return 1
    fi

    # Check if listener is running
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - Checking if listener is running"
    lsnrctl status "${listener_name}" > /dev/null 2>&1
    local status_rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - lsnrctl status exit code: ${status_rc}"
    
    if [[ ${status_rc} -ne 0 ]]; then
        oradba_log INFO "Listener ${listener_name} is not running"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - Listener not running, skipping shutdown"
        return 0
    fi

    # Stop the listener
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - Executing lsnrctl stop command"
    lsnrctl stop "${listener_name}" >> "${LOGFILE}" 2>&1
    local stop_rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_listener() - lsnrctl stop exit code: ${stop_rc}"

    if [[ ${stop_rc} -eq 0 ]]; then
        oradba_log INFO "Listener ${listener_name} stopped successfully"
        return 0
    else
        oradba_log ERROR "Failed to stop listener ${listener_name}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: show_status
# Purpose.: Display status of specified listener
# Args....: $1 - Listener name
# Returns.: 0 on success, 1 if failed to set environment
# Output..: Status output from lsnrctl status
# Notes...: Uses lsnrctl status to display listener information
# ------------------------------------------------------------------------------
show_status() {
    local listener_name="$1"
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Checking status for listener '${listener_name}'"

    # Set environment
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Setting environment for listener"
    if ! set_listener_env "${listener_name}"; then
        echo "${listener_name}: Unable to set environment"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Failed to set environment"
        return 1
    fi

    # Get listener status
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Executing lsnrctl status to check if running"
    lsnrctl status "${listener_name}" 2>&1 | grep -q "is not running"
    local not_running=$?
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - 'not running' check result: ${not_running}"
    
    if [[ ${not_running} -eq 0 ]]; then
        echo "${listener_name}: NOT RUNNING"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Listener is not running"
    else
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Extracting listening endpoints info"
        local endpoints
        endpoints=$(lsnrctl status "${listener_name}" 2>&1 | grep -A1 "Listening Endpoints" | tail -1 | sed "s/^/${listener_name}: /")
        echo "${endpoints}"
        oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Listener endpoints: ${endpoints}"
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
            LISTENERS+=("$1")
            oradba_log DEBUG "${SCRIPT_NAME}: Added listener to process: $1"
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
    oradba_log DEBUG "${SCRIPT_NAME}: No specific listeners provided, defaulting to 'LISTENER'"
    LISTENERS=("LISTENER")

    # For status, show all running listeners
    if [[ "${ACTION}" == "status" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: Status action detected, checking for running listeners"
        mapfile -t running < <(get_running_listeners)
        if [[ ${#running[@]} -gt 0 ]]; then
            LISTENERS=("${running[@]}")
            oradba_log DEBUG "${SCRIPT_NAME}: Found ${#running[@]} running listeners: ${running[*]}"
        else
            oradba_log DEBUG "${SCRIPT_NAME}: No running listeners found, keeping default"
        fi
    fi
else
    # Explicit listeners provided
    oradba_log INFO "Processing specified listeners: ${LISTENERS[*]}"
    oradba_log DEBUG "${SCRIPT_NAME}: ${#LISTENERS[@]} explicit listener(s) provided by user"

    # Ask for justification if multiple listeners
    if [[ ${#LISTENERS[@]} -gt 1 ]] && [[ "${ACTION}" != "status" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: Requesting justification for ${ACTION} operation on ${#LISTENERS[@]} listeners"
        if ! ask_justification "${ACTION}" "${#LISTENERS[@]}"; then
            oradba_log DEBUG "${SCRIPT_NAME}: User cancelled operation during justification prompt"
            exit 1
        fi
        oradba_log DEBUG "${SCRIPT_NAME}: User confirmed operation"
    fi
fi

# Process each listener
success_count=0
failure_count=0

oradba_log DEBUG "${SCRIPT_NAME}: Starting to process ${#LISTENERS[@]} listener(s) for action: ${ACTION}"

for listener in "${LISTENERS[@]}"; do
    oradba_log DEBUG "${SCRIPT_NAME}: Processing listener '${listener}' with action '${ACTION}'"
    case "${ACTION}" in
        start)
            if start_listener "${listener}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully started listener '${listener}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to start listener '${listener}'"
            fi
            ;;
        stop)
            if stop_listener "${listener}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully stopped listener '${listener}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to stop listener '${listener}'"
            fi
            ;;
        restart)
            oradba_log DEBUG "${SCRIPT_NAME}: Restarting listener '${listener}' (stop then start)"
            if stop_listener "${listener}" && start_listener "${listener}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully restarted listener '${listener}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to restart listener '${listener}'"
            fi
            ;;
        status)
            oradba_log DEBUG "${SCRIPT_NAME}: Checking status for listener '${listener}'"
            show_status "${listener}"
            ;;
    esac
done

oradba_log DEBUG "${SCRIPT_NAME}: Completed processing all listeners - Success: ${success_count}, Failures: ${failure_count}"

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
