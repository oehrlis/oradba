#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_dsctl.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.23
# Revision...: 
# Purpose....: Data Safe connector start/stop control script
# Notes......: Can be used interactively or in runlevel/systemd scripts
#              Honors oradba_homes.conf autostart flag, supports explicit connector override
#              Uses cmctl for connector management
# Usage......: oradba_dsctl.sh {start|stop|restart|status} [OPTIONS] [CONNECTOR1 CONNECTOR2 ...]
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

# Source DataSafe plugin
if [[ -f "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh" ]]; then
    # shellcheck source=../lib/plugins/datasafe_plugin.sh
    source "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
    oradba_log DEBUG "${SCRIPT_NAME}: Sourced datasafe_plugin.sh successfully"
else
    oradba_log WARN "${SCRIPT_NAME}: datasafe_plugin.sh not found, continuing with limited functionality"
fi

# Source registry API
if [[ -f "${ORADBA_BASE}/lib/oradba_registry.sh" ]]; then
    # shellcheck source=../lib/oradba_registry.sh
    source "${ORADBA_BASE}/lib/oradba_registry.sh"
    oradba_log DEBUG "${SCRIPT_NAME}: Sourced oradba_registry.sh successfully"
fi

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
DEFAULT_SHUTDOWN_TIMEOUT=180
SHUTDOWN_TIMEOUT=${ORADBA_SHUTDOWN_TIMEOUT:-$DEFAULT_SHUTDOWN_TIMEOUT}
FORCE_MODE=false
ACTION=""
CONNECTORS=()
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
# Notes...: Shows action modes (start/stop/restart/status), timeout config, connector selection
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} {start|stop|restart|status} [OPTIONS] [CONNECTOR1 CONNECTOR2 ...]

Actions:
    start       Start Data Safe connector(s)
    stop        Stop Data Safe connector(s)
    restart     Restart Data Safe connector(s)
    status      Show status of Data Safe connector(s)

Options:
    -f, --force             Force operation without confirmation
    -t, --timeout SECONDS   Shutdown timeout (default: ${DEFAULT_SHUTDOWN_TIMEOUT}s)
    -d, --debug             Enable debug logging
    -h, --help              Show this help message

Arguments:
    CONNECTOR               Specific connector name(s) to control
                           If not specified, processes all connectors with autostart enabled

Examples:
    ${SCRIPT_NAME} start                    # Start all connectors with autostart enabled
    ${SCRIPT_NAME} start cman01 cman02      # Start specific connectors
    ${SCRIPT_NAME} stop --force             # Stop all without confirmation
    ${SCRIPT_NAME} restart cman01           # Restart specific connector
    ${SCRIPT_NAME} status                   # Show status of all connectors
    ${SCRIPT_NAME} --debug start cman01     # Start with debug logging
    ORADBA_DEBUG=true ${SCRIPT_NAME} status # Status with debug logging

Environment Variables:
    ORADBA_DEBUG               Enable debug logging (true/false)
    ORADBA_SHUTDOWN_TIMEOUT    Shutdown timeout in seconds (default: ${DEFAULT_SHUTDOWN_TIMEOUT})
    ORADBA_LOG                 Log directory (default: /var/log/oracle)
    ORADBA_BASE                OraDBA base directory

Notes:
    - Connectors are registered in \${ORADBA_BASE}/etc/oradba_homes.conf
    - Uses cmctl command for connector management
    - Supports autostart flag (Y) in oradba_homes.conf

EOF
    exit 1
}

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# ------------------------------------------------------------------------------
# Function: get_connectors
# Purpose.: Get Data Safe connectors from registry
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: One line per connector: NAME:HOME:AUTOSTART (excludes dummy entries)
# Notes...: Uses oradba_registry API to get datasafe type installations
# ------------------------------------------------------------------------------
get_connectors() {
    oradba_log DEBUG "${SCRIPT_NAME}: get_connectors() - Reading connectors from registry"

    # Check if registry API is available
    if ! type -t oradba_registry_get_by_type &>/dev/null; then
        oradba_log ERROR "Registry API not available"
        return 1
    fi

    # Get all datasafe installations from registry
    local entry_count=0
    while IFS='|' read -r ptype name home version flags order alias desc; do
        ((entry_count++))
        oradba_log DEBUG "${SCRIPT_NAME}: get_connectors() - Found entry ${entry_count}: NAME=${name}, HOME=${home}, FLAGS=${flags}"
        
        # Convert flags format - look for Y flag for autostart
        # oradba_homes.conf has no flags; treat all datasafe entries as enabled
        local autostart="N"
        if [[ -z "${flags}" ]] || [[ "${flags}" =~ Y ]]; then
            autostart="Y"
        fi

        echo "${name}:${home}:${autostart}"
    done < <(oradba_registry_get_by_type "datasafe" 2>/dev/null)
    
    oradba_log DEBUG "${SCRIPT_NAME}: get_connectors() - Processed ${entry_count} entries from registry"
    return 0
}

# ------------------------------------------------------------------------------
# Function: ask_justification
# Purpose.: Prompt for justification when operating on multiple connectors
# Args....: $1 - Action name (start/stop/restart), $2 - Connector count
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
    echo "WARNING: About to ${action} ALL connectors"
    echo "=========================================="
    echo "This will affect ${count} connector(s)"
    echo ""
    read -r -p "Please provide justification for this operation: " justification

    if [[ -z "${justification}" ]]; then
        oradba_log ERROR "Operation cancelled: No justification provided"
        return 1
    fi

    oradba_log INFO "Justification for ${action} all connectors: ${justification}"
    read -r -p "Continue with operation? (yes/no): " confirm

    if [[ "${confirm}" != "yes" ]]; then
        oradba_log INFO "Operation cancelled by user"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: get_cman_instance_name
# Purpose.: Extract CMAN instance name from cman.ora configuration
# Args....: $1 - Connector home path
# Returns.: 0 on success, 1 if cman.ora not found
# Output..: CMAN instance name (defaults to "cust_cman" if not found)
# Notes...: Parses first non-comment line with = sign from cman.ora
# ------------------------------------------------------------------------------
get_cman_instance_name() {
    local connector_home="$1"
    local cman_home
    
    # Adjust to oracle_cman_home if needed
    if type -t plugin_adjust_environment &>/dev/null; then
        cman_home=$(plugin_adjust_environment "${connector_home}")
    else
        cman_home="${connector_home}/oracle_cman_home"
    fi
    
    local cman_conf="${cman_home}/network/admin/cman.ora"
    local instance_name="cust_cman"  # Default for DataSafe
    
    if [[ -f "${cman_conf}" ]]; then
        # Extract first non-comment line with = sign (instance name)
        local extracted_name
        extracted_name=$(grep -E '^[[:space:]]*[^#].*=' "${cman_conf}" 2>/dev/null | head -1 | cut -d'=' -f1 | tr -d ' ' || echo "")
        if [[ -n "${extracted_name}" ]]; then
            instance_name="${extracted_name}"
            oradba_log DEBUG "${SCRIPT_NAME}: get_cman_instance_name() - Extracted instance name: ${instance_name}"
        fi
    else
        oradba_log DEBUG "${SCRIPT_NAME}: get_cman_instance_name() - cman.ora not found, using default: ${instance_name}"
    fi
    
    echo "${instance_name}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: start_connector
# Purpose.: Start a Data Safe connector instance
# Args....: $1 - Connector name, $2 - Connector home path
# Returns.: 0 on success, 1 on failure
# Output..: Status messages via oradba_log
# Notes...: Uses cmctl startup command; checks if already running first
# ------------------------------------------------------------------------------
start_connector() {
    local name="$1"
    local home="$2"
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Starting connector '${name}'"

    oradba_log INFO "Starting connector ${name}..."

    # Adjust to oracle_cman_home if needed
    local cman_home
    if type -t plugin_adjust_environment &>/dev/null; then
        cman_home=$(plugin_adjust_environment "${home}")
    else
        cman_home="${home}/oracle_cman_home"
    fi
    
    # Set TNS_ADMIN for this specific connector before any plugin operations
    export TNS_ADMIN="${cman_home}/network/admin"
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Set TNS_ADMIN=${TNS_ADMIN}"
    
    local cmctl="${cman_home}/bin/cmctl"
    
    # Validate cmctl exists
    if [[ ! -x "${cmctl}" ]]; then
        oradba_log ERROR "cmctl not found or not executable: ${cmctl}"
        return 1
    fi

    # Check if connector is already running
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Checking current status"
    local status_exit_code=0
    if type -t plugin_check_status &>/dev/null; then
        plugin_check_status "${home}" "${name}" >/dev/null 2>&1
        status_exit_code=$?
    else
        # Fallback status check using cmctl
        local instance_name
        instance_name=$(get_cman_instance_name "${home}")
        if ORACLE_HOME="${cman_home}" \
           LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
           "${cmctl}" show services -c "${instance_name}" 2>/dev/null | grep -qiE "Services Summary|READY|running"; then
            status_exit_code=0
        else
            status_exit_code=1
        fi
    fi
    
    # Convert exit code to status string for logging
    local status
    case ${status_exit_code} in
        0) status="running" ;;
        1) status="stopped" ;;
        2) status="unavailable" ;;
        *) status="unknown" ;;
    esac
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Current status: '${status}' (exit: ${status_exit_code})"

    # Exit code 0 = running, 1 = stopped, 2 = unavailable
    if [[ ${status_exit_code} -eq 0 ]]; then
        oradba_log INFO "Connector ${name} is already running"
        oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Connector already running, skipping startup"
        return 0
    fi

    # Get CMAN instance name
    local instance_name
    instance_name=$(get_cman_instance_name "${home}")
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Using instance name: ${instance_name}"

    # Start the connector
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - Executing cmctl startup command"
    local output
    output=$(ORACLE_HOME="${cman_home}" \
             LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
             "${cmctl}" startup -c "${instance_name}" 2>&1)
    
    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - cmctl startup completed with exit code: ${rc}"
    
    # Log output to logfile
    echo "${output}" >> "${LOGFILE}" 2>&1
    
    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Connector ${name} started successfully"
        return 0
    else
        oradba_log ERROR "Failed to start connector ${name} (exit code: ${rc})"
        oradba_log DEBUG "${SCRIPT_NAME}: start_connector() - cmctl output: ${output}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: stop_connector
# Purpose.: Stop a Data Safe connector instance with timeout and fallback
# Args....: $1 - Connector name, $2 - Connector home path
# Returns.: 0 on success, 1 on failure
# Output..: Status messages via oradba_log
# Notes...: Uses cmctl shutdown command; attempts graceful shutdown with timeout
# ------------------------------------------------------------------------------
stop_connector() {
    local name="$1"
    local home="$2"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Stopping connector '${name}'"

    oradba_log INFO "Stopping connector ${name}..."

    # Adjust to oracle_cman_home if needed
    local cman_home
    if type -t plugin_adjust_environment &>/dev/null; then
        cman_home=$(plugin_adjust_environment "${home}")
    else
        cman_home="${home}/oracle_cman_home"
    fi
    
    # Set TNS_ADMIN for this specific connector before any plugin operations
    export TNS_ADMIN="${cman_home}/network/admin"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Set TNS_ADMIN=${TNS_ADMIN}"
    
    local cmctl="${cman_home}/bin/cmctl"
    
    # Validate cmctl exists
    if [[ ! -x "${cmctl}" ]]; then
        oradba_log ERROR "cmctl not found or not executable: ${cmctl}"
        return 1
    fi

    # Check if connector is running
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Checking current status"
    local status_exit_code=0
    if type -t plugin_check_status &>/dev/null; then
        plugin_check_status "${home}" "${name}" >/dev/null 2>&1
        status_exit_code=$?
    else
        # Fallback status check using cmctl
        local instance_name
        instance_name=$(get_cman_instance_name "${home}")
        if ORACLE_HOME="${cman_home}" \
           LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
           "${cmctl}" show services -c "${instance_name}" 2>/dev/null | grep -qiE "Services Summary|READY|running"; then
            status_exit_code=0
        else
            status_exit_code=1
        fi
    fi
    
    # Convert exit code to status string for logging
    local status
    case ${status_exit_code} in
        0) status="running" ;;
        1) status="stopped" ;;
        2) status="unavailable" ;;
        *) status="unknown" ;;
    esac
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Current status: '${status}' (exit: ${status_exit_code})"

    # Exit code 0 = running, 1 = stopped, 2 = unavailable
    if [[ ${status_exit_code} -ne 0 ]]; then
        oradba_log INFO "Connector ${name} is not running"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Connector not running, skipping shutdown"
        return 0
    fi

    # Get CMAN instance name
    local instance_name
    instance_name=$(get_cman_instance_name "${home}")
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Using instance name: ${instance_name}"

    # Try shutdown with timeout
    oradba_log INFO "Attempting shutdown for ${name} (timeout: ${SHUTDOWN_TIMEOUT}s)"
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Executing cmctl shutdown with ${SHUTDOWN_TIMEOUT}s timeout"

    local output
    output=$(timeout "${SHUTDOWN_TIMEOUT}" \
             bash -c "ORACLE_HOME='${cman_home}' LD_LIBRARY_PATH='${cman_home}/lib:${LD_LIBRARY_PATH:-}' '${cmctl}' shutdown -c '${instance_name}'" 2>&1)

    local rc=$?
    oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - cmctl shutdown completed with exit code: ${rc}"

    # Log output to logfile
    echo "${output}" >> "${LOGFILE}" 2>&1

    if [[ ${rc} -eq 0 ]]; then
        oradba_log INFO "Connector ${name} stopped successfully"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Shutdown completed successfully"
        return 0
    elif [[ ${rc} -eq 124 ]]; then
        # Timeout occurred - try to kill processes
        oradba_log WARN "Shutdown timed out for ${name}, attempting to kill processes"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Timeout occurred, attempting process kill"

        # Try to kill cmadmin and cmgw processes
        # Try to kill cmadmin and cmgw processes
        # shellcheck disable=SC2009
        local pids
        pids=$(ps -ef | grep "[c]madmin.*${name}" | awk '{print $2}' || echo "")
        if [[ -n "${pids}" ]]; then
            for pid in ${pids}; do
                oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Killing cmadmin process: ${pid}"
                kill -9 "${pid}" 2>/dev/null || true
            done
        fi
        
        # shellcheck disable=SC2009
        pids=$(ps -ef | grep "[c]mgw.*${name}" | awk '{print $2}' || echo "")
        if [[ -n "${pids}" ]]; then
            for pid in ${pids}; do
                oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Killing cmgw process: ${pid}"
                kill -9 "${pid}" 2>/dev/null || true
            done
        fi

        oradba_log INFO "Connector ${name} stopped with force kill"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - Force kill completed"
        return 0
    else
        oradba_log ERROR "Failed to stop connector ${name} (exit code: ${rc})"
        oradba_log DEBUG "${SCRIPT_NAME}: stop_connector() - cmctl output: ${output}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: show_status
# Purpose.: Display current status of a connector
# Args....: $1 - Connector name, $2 - Connector home path
# Returns.: 0 on success, 1 on error
# Output..: One line: "NAME: STATUS"
# Notes...: Uses plugin_check_status from datasafe_plugin if available
# ------------------------------------------------------------------------------
show_status() {
    local name="$1"
    local home="$2"
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Checking status for connector '${name}'"

    # Adjust to oracle_cman_home and set TNS_ADMIN for this specific connector
    local cman_home
    if type -t plugin_adjust_environment &>/dev/null; then
        cman_home=$(plugin_adjust_environment "${home}")
    else
        cman_home="${home}/oracle_cman_home"
    fi
    export TNS_ADMIN="${cman_home}/network/admin"
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Set TNS_ADMIN=${TNS_ADMIN}"

    # Get connector status via exit code
    local status_exit_code
    if type -t plugin_check_status &>/dev/null; then
        plugin_check_status "${home}" "${name}" >/dev/null 2>&1
        status_exit_code=$?
    else
        # Fallback status check using cmctl
        local cmctl="${cman_home}/bin/cmctl"
        
        if [[ ! -x "${cmctl}" ]]; then
            status_exit_code=2
        else
            local instance_name
            instance_name=$(get_cman_instance_name "${home}")
            if ORACLE_HOME="${cman_home}" \
               LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
               "${cmctl}" show services -c "${instance_name}" 2>/dev/null | grep -qiE "Services Summary|READY|running"; then
                status_exit_code=0
            else
                status_exit_code=1
            fi
        fi
    fi
    
    # Convert exit code to status string: 0=running, 1=stopped, 2=unavailable
    local status
    case ${status_exit_code} in
        0) status="running" ;;
        1) status="stopped" ;;
        2) status="unavailable" ;;
        *) status="unknown" ;;
    esac
    
    oradba_log DEBUG "${SCRIPT_NAME}: show_status() - Status: '${status}' (exit: ${status_exit_code})"

    # Format status for output
    local status_upper
    status_upper=$(echo "${status}" | tr '[:lower:]' '[:upper:]')
    echo "${name}: ${status_upper}"
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
            CONNECTORS+=("$1")
            oradba_log DEBUG "${SCRIPT_NAME}: Added connector to process: $1"
            shift
            ;;
    esac
done

# Log action
oradba_log INFO "========== Starting ${ACTION} operation =========="
oradba_log INFO "User: $(whoami), Host: $(hostname)"

# Determine which connectors to process
if [[ ${#CONNECTORS[@]} -eq 0 ]]; then
    # No connectors specified, get all connectors from registry
    oradba_log INFO "No connectors specified, processing all connectors in registry"
    oradba_log DEBUG "${SCRIPT_NAME}: Reading connectors from registry"

    mapfile -t conn_list < <(get_connectors)
    oradba_log DEBUG "${SCRIPT_NAME}: Found ${#conn_list[@]} connector entries in registry"

    if [[ ${#conn_list[@]} -eq 0 ]]; then
        oradba_log ERROR "No Data Safe connectors found in registry"
        oradba_log INFO "Register connectors in \${ORADBA_BASE}/etc/oradba_homes.conf"
        exit 1
    fi

    # Build arrays for processing (all datasafe entries)
    declare -A CONNECTOR_HOMES
    for entry in "${conn_list[@]}"; do
        IFS=: read -r name home autostart <<< "${entry}"
        oradba_log DEBUG "${SCRIPT_NAME}: Checking connector entry - NAME: ${name}, HOME: ${home}, AUTOSTART: ${autostart}"
        CONNECTORS+=("${name}")
        CONNECTOR_HOMES["${name}"]="${home}"
        oradba_log DEBUG "${SCRIPT_NAME}: Added connector '${name}' to processing list"
    done

    if [[ ${#CONNECTORS[@]} -eq 0 ]]; then
        oradba_log ERROR "No Data Safe connectors found in registry"
        exit 1
    fi

    oradba_log DEBUG "${SCRIPT_NAME}: Selected ${#CONNECTORS[@]} connectors for processing: ${CONNECTORS[*]}"

    # Ask for justification when operating on all
    if [[ "${ACTION}" != "status" ]]; then
        oradba_log DEBUG "${SCRIPT_NAME}: Requesting justification for ${ACTION} operation on ${#CONNECTORS[@]} connectors"
        if ! ask_justification "${ACTION}" "${#CONNECTORS[@]}"; then
            oradba_log DEBUG "${SCRIPT_NAME}: User cancelled operation during justification prompt"
            exit 1
        fi
        oradba_log DEBUG "${SCRIPT_NAME}: User confirmed operation"
    fi
else
    # Explicit connectors provided - get their homes from registry
    oradba_log INFO "Processing specified connectors: ${CONNECTORS[*]}"
    oradba_log DEBUG "${SCRIPT_NAME}: ${#CONNECTORS[@]} explicit connector(s) provided by user"
    
    declare -A CONNECTOR_HOMES
    for connector in "${CONNECTORS[@]}"; do
        # Look up home path from registry
        if type -t oradba_registry_get_by_name &>/dev/null; then
            entry=$(oradba_registry_get_by_name "${connector}")
            if [[ -n "${entry}" ]]; then
                # shellcheck disable=SC2034
                IFS='|' read -r ptype name home version flags order alias desc <<< "${entry}"
                CONNECTOR_HOMES["${connector}"]="${home}"
                oradba_log DEBUG "${SCRIPT_NAME}: Found connector '${connector}' at: ${home}"
            else
                oradba_log ERROR "Connector '${connector}' not found in registry"
                exit 1
            fi
        else
            oradba_log ERROR "Registry API not available"
            exit 1
        fi
    done
fi

# Process each connector
success_count=0
failure_count=0

oradba_log DEBUG "${SCRIPT_NAME}: Starting to process ${#CONNECTORS[@]} connector(s) for action: ${ACTION}"

for connector in "${CONNECTORS[@]}"; do
    oradba_log DEBUG "${SCRIPT_NAME}: Processing connector '${connector}' with action '${ACTION}'"
    
    # Get connector home
    connector_home="${CONNECTOR_HOMES[${connector}]}"
    
    case "${ACTION}" in
        start)
            if start_connector "${connector}" "${connector_home}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully started connector '${connector}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to start connector '${connector}'"
            fi
            ;;
        stop)
            if stop_connector "${connector}" "${connector_home}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully stopped connector '${connector}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to stop connector '${connector}'"
            fi
            ;;
        restart)
            oradba_log DEBUG "${SCRIPT_NAME}: Restarting connector '${connector}' (stop then start)"
            if stop_connector "${connector}" "${connector_home}" && start_connector "${connector}" "${connector_home}"; then
                ((success_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Successfully restarted connector '${connector}'"
            else
                ((failure_count++))
                oradba_log DEBUG "${SCRIPT_NAME}: Failed to restart connector '${connector}'"
            fi
            ;;
        status)
            oradba_log DEBUG "${SCRIPT_NAME}: Checking status for connector '${connector}'"
            show_status "${connector}" "${connector_home}"
            ;;
    esac
done

oradba_log DEBUG "${SCRIPT_NAME}: Completed processing all connectors - Success: ${success_count}, Failures: ${failure_count}"

# Summary
if [[ "${ACTION}" != "status" ]]; then
    oradba_log INFO "========== Operation completed =========="
    oradba_log INFO "Success: ${success_count}, Failures: ${failure_count}"

    if [[ ${failure_count} -gt 0 ]]; then
        oradba_log WARN "Some connectors failed to ${ACTION}"
        exit 1
    fi
fi

oradba_log INFO "Done"
exit 0

# EOF -------------------------------------------------------------------------
