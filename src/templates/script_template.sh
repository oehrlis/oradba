#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: script_template.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 1.0.0
# Purpose....: Template for creating new bash scripts
# Notes......: Copy this template and modify as needed for new scripts.
#              Update Name, Purpose, and Notes sections appropriately.
#              Uses unified oradba_log() function from oradba_common.sh
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
ORADBA_BASE="$(dirname "$(dirname "${SCRIPT_DIR}")")"

# Source common library
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library" >&2
    exit 3
fi

# Script variables
VERSION="0.1.0"

# ------------------------------------------------------------------------------
# Display usage
# ------------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Description of what this script does.

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
    oradba_log INFO "Starting ${SCRIPT_NAME}"
    
    # Add your script logic here
    # Available log levels: DEBUG, INFO, WARN, ERROR, SUCCESS, FAILURE, SECTION
    
    oradba_log SUCCESS "Completed successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--version)
            echo "${SCRIPT_NAME} version ${VERSION}"
            exit 0
            ;;
        -d|--debug)
            export DEBUG=1
            shift
            ;;
        *)
            oradba_log ERROR "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main
