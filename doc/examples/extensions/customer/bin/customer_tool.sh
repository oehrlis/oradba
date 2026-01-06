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
    oradba_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
    log_info() { oradba_log "INFO" "$@"; }
    log_warn() { oradba_log "WARN" "$@"; }
    log_error() { oradba_log "ERROR" "$@"; }
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
    log_info "Customer Tool - Example Extension"
    log_info "Extension: customer"
    log_info "Path:      ${ORADBA_EXT_CUSTOMER_PATH:-unknown}"
    log_info "Version:   1.0.0"
    echo ""
    
    # Example: Show Oracle environment
    if [[ -n "${ORACLE_SID}" ]]; then
        log_info "Current Oracle Environment:"
        log_info "  ORACLE_SID:  ${ORACLE_SID}"
        log_info "  ORACLE_HOME: ${ORACLE_HOME}"
        log_info "  ORACLE_BASE: ${ORACLE_BASE}"
    else
        log_warn "No Oracle environment set"
        log_info "Run: source oraenv.sh <SID>"
    fi
    
    echo ""
    log_info "This is an example script demonstrating the extension system."
    log_info "Replace this with your own customer-specific tools."
    
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
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main "$@"
