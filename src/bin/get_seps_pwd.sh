#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: get_seps_pwd.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Extract password for a given connect string from Oracle Wallet
# Notes......: Uses mkstore to retrieve passwords from Oracle Wallet.
#              Password must be entered only once.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o pipefail

# Script directory and name
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
SCRIPT_BASE="$(dirname "${SCRIPT_DIR}")"
# shellcheck disable=SC2034  # Used for potential future extension
readonly SCRIPT_BASE

# Source common functions
if [[ -f "${SCRIPT_BASE}/lib/oradba_common.sh" ]]; then
    source "${SCRIPT_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library"
    exit 1
fi

# Default values
WALLET_DIR="${cdn:-${ORACLE_BASE}/network}/wallet"
WALLET_PASSWORD="${WALLET_PASSWORD:-}"
CONNECT_STRING=""
QUIET=false
DEBUG=false
CHECK=false

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information and examples
# Args....: None
# Returns.: Exits with code 0
# Output..: Usage text, options, examples, notes to stdout
# Notes...: Shows required connect string option, optional wallet dir, check/quiet modes
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} -s <connect_string> [OPTIONS]

Extract password for a connect string from Oracle Wallet.

REQUIRED:
    -s <connect_string>   Database alias (TNS name) to match

OPTIONS:
    -c                   Check if password exists (don't output password)
    -q                   Quiet mode (output only the password)
    -d                   Enable debug mode
    -w <wallet_dir>      Wallet directory (default: ${WALLET_DIR})
    -h                   Show this help message

EXAMPLES:
    # Get password for connect string
    ${SCRIPT_NAME} -s ORCL

    # Check if password exists
    ${SCRIPT_NAME} -s FREE -c

    # Get password quietly (for scripts)
    ${SCRIPT_NAME} -s CDB1 -q

    # Use custom wallet directory
    ${SCRIPT_NAME} -s TESTDB -w /u01/app/oracle/wallet

NOTES:
    - Requires Oracle Client with mkstore utility
    - Wallet password can be provided via WALLET_PASSWORD environment variable
    - Wallet password can be stored in ${WALLET_DIR}/.wallet_pwd (base64 encoded)
    - If not provided, password will be prompted interactively

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function: should_log
# Purpose.: Determine if a log message should be displayed based on level and mode
# Args....: $1 - Log level (DEBUG/INFO/ERROR)
# Returns.: 0 if should log, 1 if should suppress
# Output..: None
# Notes...: Suppresses DEBUG if DEBUG=false; suppresses all if QUIET=true
# ------------------------------------------------------------------------------
should_log() {
    local level="$1"
    [[ "${level}" == "DEBUG" && "${DEBUG}" != "true" ]] && return 1
    [[ "${QUIET}" == "true" ]] && return 1
    return 0
}

# ------------------------------------------------------------------------------
# Function: get_entry
# Purpose.: Retrieve a wallet entry value by key using mkstore
# Args....: $1 - Wallet entry key
# Returns.: 0 on success
# Output..: Entry value to stdout
# Notes...: Uses mkstore -viewEntry; filters output to extract value after '= '
# ------------------------------------------------------------------------------
get_entry() {
    local key="$1"
    echo "${WALLET_PASSWORD}" | mkstore -wrl "${WALLET_DIR}" -viewEntry "${key}" 2> /dev/null \
        | grep -i "${key}" | awk -F '= ' '{print $2}'
}

# ------------------------------------------------------------------------------
# Function: parse_args
# Purpose.: Parse command line arguments and validate required parameters
# Args....: Command line arguments (passed as "$@")
# Returns.: Exits if validation fails, otherwise returns 0
# Output..: Error message to stderr if connect string missing
# Notes...: Sets global vars CONNECT_STRING, CHECK, QUIET, DEBUG, WALLET_DIR
# ------------------------------------------------------------------------------
parse_args() {
    while getopts "s:qcdw:h" opt; do
        case "${opt}" in
            s) CONNECT_STRING="${OPTARG}" ;;
            c) CHECK=true ;;
            q) QUIET=true ;;
            d) DEBUG=true ;;
            w) WALLET_DIR="${OPTARG}" ;;
            h) usage ;;
            *) usage ;;
        esac
    done

    # Validate required parameters
    if [[ -z "${CONNECT_STRING}" ]]; then
        echo "Error: Connect string (-s) is required." >&2
        usage
    fi
}

# ------------------------------------------------------------------------------
# Function: validate_environment
# Purpose.: Validate wallet directory existence and mkstore availability
# Args....: None
# Returns.: Exits with code 1 on validation failure
# Output..: Error messages via oradba_log
# Notes...: Checks wallet dir exists and is readable; checks mkstore command available
# ------------------------------------------------------------------------------
validate_environment() {
    # Check wallet directory
    if [[ ! -d "${WALLET_DIR}" ]]; then
        oradba_log ERROR "Wallet directory '${WALLET_DIR}' does not exist."
        exit 1
    fi

    if [[ ! -r "${WALLET_DIR}" ]]; then
        oradba_log ERROR "Wallet directory '${WALLET_DIR}' is not readable."
        exit 1
    fi

    # Check mkstore command
    if ! command -v mkstore &> /dev/null; then
        oradba_log ERROR "mkstore command not found. Please ensure Oracle Client is installed."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Function: load_wallet_password
# Purpose.: Load wallet password from file, environment, or interactive prompt
# Args....: None
# Returns.: None (sets global WALLET_PASSWORD)
# Output..: Debug message if loaded from file; prompt if interactive
# Notes...: Tries ${WALLET_DIR}/.wallet_pwd (base64), then env var, then prompts
# ------------------------------------------------------------------------------
load_wallet_password() {
    # Try to load from encoded file
    if [[ -f "${WALLET_DIR}/.wallet_pwd" ]]; then
        WALLET_PASSWORD=$(base64 -d "${WALLET_DIR}/.wallet_pwd" 2> /dev/null)
        oradba_log DEBUG "Loaded wallet password from ${WALLET_DIR}/.wallet_pwd"
    fi

    # Prompt if not loaded
    if [[ -z "${WALLET_PASSWORD}" ]]; then
        read -s -p "Enter wallet password: " WALLET_PASSWORD
        echo
    fi
}

# ------------------------------------------------------------------------------
# Function: search_wallet
# Purpose.: Search wallet for connect string and retrieve password
# Args....: None (uses global CONNECT_STRING)
# Returns.: 0 if found, 1 if not found
# Output..: Password (quiet mode) or status messages (normal mode) to stdout
# Notes...: Case-insensitive search; supports check mode (verify only) and quiet mode (password only)
# ------------------------------------------------------------------------------
search_wallet() {
    local connect_string_lower="${CONNECT_STRING,,}"

    # Count connect string entries
    local count
    count=$(echo "${WALLET_PASSWORD}" | mkstore -wrl "${WALLET_DIR}" -list 2> /dev/null \
        | grep -c "oracle.security.client.connect_string")

    oradba_log DEBUG "Found ${count} connect string entries in wallet."

    if [[ ${count} -eq 0 ]]; then
        oradba_log ERROR "No connect strings found in wallet."
        exit 1
    fi

    # Search for matching connect string
    for i in $(seq 1 "${count}"); do
        local alias
        alias=$(get_entry "oracle.security.client.connect_string${i}")

        if [[ "${alias,,}" == "${connect_string_lower}" ]]; then
            should_log INFO && oradba_log INFO "Found connect string '${CONNECT_STRING}' in wallet."

            # Check mode - just verify existence
            if [[ "${CHECK}" == "true" ]]; then
                should_log INFO && oradba_log INFO "Password exists for connect string '${CONNECT_STRING}'."
                return 0
            fi

            # Retrieve password
            local password
            password=$(get_entry "oracle.security.client.password${i}")

            # Output based on mode
            if [[ "${QUIET}" == "true" ]]; then
                echo "${password}"
            else
                should_log INFO && oradba_log INFO "Match found for connect string '${CONNECT_STRING}':"
                should_log INFO && oradba_log INFO "  Password: ${password}"
            fi
            return 0
        fi
    done

    # No match found
    should_log ERROR && oradba_log ERROR "Connect string '${CONNECT_STRING}' not found in wallet."
    return 1
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Orchestrate wallet password retrieval workflow
# Args....: Command line arguments (passed as "$@")
# Returns.: Exit code from search_wallet (0 success, 1 failure)
# Output..: Depends on mode (quiet/check/normal)
# Notes...: Workflow: parse args → validate → load password → search wallet
# ------------------------------------------------------------------------------
main() {
    parse_args "$@"
    validate_environment
    load_wallet_password
    search_wallet
}

main "$@"

# --- EOF ----------------------------------------------------------------------
