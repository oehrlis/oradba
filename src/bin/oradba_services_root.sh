#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_services_root.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.10.0
# Purpose....: Root wrapper for Oracle service management
# Notes......: Executes oradba_services.sh as oracle user
#              Used by systemd/init.d for service startup
#              Requires root privileges
# Usage......: oradba_services_root.sh {start|stop|restart|status}
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="$(dirname "${SCRIPT_DIR}")"
ORACLE_USER="${ORACLE_USER:-oracle}"
SERVICES_SCRIPT="${ORADBA_BASE}/bin/oradba_services.sh"
LOGFILE="/var/log/oracle/oradba_services_root.log"

# Source common functions
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    source "${ORADBA_BASE}/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library"
    exit 1
fi

# Enable file logging
export ORADBA_LOG_FILE="${LOGFILE}"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Check if running as root
check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root"
        exit 1
    fi
}

# Check if oracle user exists
check_oracle_user() {
    if ! id "${ORACLE_USER}" >/dev/null 2>&1; then
        log_message "ERROR" "User ${ORACLE_USER} does not exist"
        exit 1
    fi
}

# Check if services script exists
check_services_script() {
    if [[ ! -f "${SERVICES_SCRIPT}" ]]; then
        log_message "ERROR" "Services script not found: ${SERVICES_SCRIPT}"
        exit 1
    fi
    
    if [[ ! -x "${SERVICES_SCRIPT}" ]]; then
        log_message "ERROR" "Services script is not executable: ${SERVICES_SCRIPT}"
        exit 1
    fi
}

# Execute command as oracle user
run_as_oracle() {
    local action="$1"
    
    log_message "INFO" "Executing ${action} as user ${ORACLE_USER}"
    
    # Execute services script as oracle user
    su - "${ORACLE_USER}" -c "${SERVICES_SCRIPT} ${action} --force"
    
    local rc=$?
    
    if [[ ${rc} -eq 0 ]]; then
        log_message "INFO" "Command completed successfully"
        return 0
    else
        log_message "ERROR" "Command failed with exit code ${rc}"
        return ${rc}
    fi
}

# Show usage
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} {start|stop|restart|status}

Actions:
    start       Start Oracle services (listeners and databases)
    stop        Stop Oracle services (databases and listeners)
    restart     Restart Oracle services
    status      Show status of Oracle services

Description:
    Root wrapper script for Oracle service management.
    Executes ${SERVICES_SCRIPT} as user ${ORACLE_USER}.
    
Environment Variables:
    ORACLE_USER     Oracle OS user (default: oracle)

Configuration:
    ORADBA_BASE     Automatically detected from script installation directory
                    Current: ${ORADBA_BASE}

Examples:
    ${SCRIPT_NAME} start    # Start all Oracle services
    ${SCRIPT_NAME} stop     # Stop all Oracle services
    ${SCRIPT_NAME} status   # Show service status

Notes:
    - Must be run as root
    - Operations are logged to ${LOGFILE}
    - Uses --force flag to skip confirmations
    - Suitable for systemd/init.d service integration

EOF
    exit 1
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
fi

ACTION="$1"

case "${ACTION}" in
    start|stop|restart|status) ;;
    -h|--help) usage ;;
    *) 
        echo "Unknown action: ${ACTION}"
        usage 
        ;;
esac

# Perform checks
log_message "INFO" "========== Oracle Services ${ACTION} =========="
log_message "INFO" "Executed by: $(whoami), Host: $(hostname)"

check_root
check_oracle_user
check_services_script

# Execute action
if run_as_oracle "${ACTION}"; then
    log_message "INFO" "Oracle services ${ACTION} completed successfully"
    exit 0
else
    log_message "ERROR" "Oracle services ${ACTION} failed"
    exit 1
fi

# EOF -------------------------------------------------------------------------
