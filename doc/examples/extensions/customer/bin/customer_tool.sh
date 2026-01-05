#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: customer_tool.sh
# Author.....: <Your Name> <your.email@example.com>
# Editor.....: <Your Name>
# Date.......: $(date '+%Y.%m.%d')
# Revision...: 1.0.0
# Purpose....: Example customer tool script
# Notes......: This script is automatically added to PATH when extension loads
#              Replace with your own customer-specific tools
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Detect OraDBA base (extension is in local/customer/bin/)
ORADBA_BASE="$(dirname "$(dirname "$(dirname "${SCRIPT_DIR}")")")"

# Source common functions if available
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_BASE}/lib/common.sh"
else
    # Fallback logging if common.sh not available
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fi

# ------------------------------------------------------------------------------
# Display usage
# ------------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Example customer tool demonstrating OraDBA extension system.

Options:
  -h, --help          Display this help message
  -v, --version       Display version information
  -d, --debug         Enable debug mode

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --debug

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------
main() {
    log SECTION "Customer Tool - Example Extension"
    log INFO "Extension: customer"
    log INFO "Path:      ${ORADBA_EXT_CUSTOMER_PATH:-unknown}"
    log INFO "Version:   1.0.0"
    echo ""
    
    # Example: Show Oracle environment
    if [[ -n "${ORACLE_SID}" ]]; then
        log INFO "Current Oracle Environment:"
        log INFO "  ORACLE_SID:  ${ORACLE_SID}"
        log INFO "  ORACLE_HOME: ${ORACLE_HOME}"
        log INFO "  ORACLE_BASE: ${ORACLE_BASE}"
    else
        log WARN "No Oracle environment set"
        log INFO "Run: source oraenv.sh <SID>"
    fi
    
    echo ""
    log INFO "This is an example script demonstrating the extension system."
    log INFO "Replace this with your own customer-specific tools."
    
    return 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--version)
            echo "${SCRIPT_NAME} version 1.0.0"
            exit 0
            ;;
        -d|--debug)
            export DEBUG=1
            shift
            ;;
        *)
            log ERROR "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main "$@"
