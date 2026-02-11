#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: sync_to_peers.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Sync files/folders from current host to peer hosts
# Notes......: Uses rsync over ssh to synchronize files across peer hosts.
#              Configuration can be loaded from environment, etc/ folder or CLI.
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
readonly SCRIPT_BASE
readonly SCRIPT_ETC_DIR="${SCRIPT_BASE}/etc"
readonly SCRIPT_CONF="${SCRIPT_ETC_DIR}/${SCRIPT_NAME%.sh}.conf"

# Source common functions
if [[ -f "${SCRIPT_BASE}/lib/oradba_common.sh" ]]; then
    source "${SCRIPT_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library"
    exit 1
fi

# Default values
PEER_HOSTS_DEFAULT=()
SSH_USER_DEFAULT="oracle"
SSH_PORT_DEFAULT="22"
RSYNC_OPTS="-az"
# shellcheck disable=SC2034  # DRYRUN tracked but effect is in RSYNC_OPTS
DRYRUN=false
VERBOSE=false
DEBUG=false
# shellcheck disable=SC2034  # DELETE tracked but effect is in RSYNC_OPTS
DELETE=false
QUIET=false
REMOTE_BASE=""
CONFIG_FILE=""
LOADED_CONFIG=""
SYNC_SUCCESS=()
SYNC_FAILURE=()

# ------------------------------------------------------------------------------
# Function: load_config
# Purpose.: Load configuration from multiple sources (script config, alt config, CLI config)
# Args....: None
# Returns.: None (sets global vars)
# Output..: None
# Notes...: Sources ${SCRIPT_CONF}, ${ETC_BASE}/*.conf, ${CONFIG_FILE}; sets SSH_USER, SSH_PORT, PEER_HOSTS
# ------------------------------------------------------------------------------
load_config() {
    local config_files=()

    # Script-specific config
    if [[ -f "${SCRIPT_CONF}" ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPT_CONF}"
        config_files+=("${SCRIPT_CONF}")
    fi

    # Alternative config location
    if [[ -n "${ETC_BASE}" && -d "${ETC_BASE}" ]]; then
        local alt_conf="${ETC_BASE}/${SCRIPT_NAME%.sh}.conf"
        if [[ -f "${alt_conf}" ]]; then
            # shellcheck source=/dev/null
            source "${alt_conf}"
            config_files+=("${alt_conf}")
        fi
    fi

    # CLI-specified config
    if [[ -n "${CONFIG_FILE}" && -f "${CONFIG_FILE}" ]]; then
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        config_files+=("${CONFIG_FILE}")
    fi

    # Join config files with comma
    LOADED_CONFIG=$(
        IFS=,
        echo "${config_files[*]}"
    )

    # Use env vars or fall back to defaults
    SSH_USER="${SSH_USER:-${SSH_USER_DEFAULT}}"
    SSH_PORT="${SSH_PORT:-${SSH_PORT_DEFAULT}}"
    PEER_HOSTS=("${PEER_HOSTS[@]:-${PEER_HOSTS_DEFAULT[@]}}")
}

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information, options, examples
# Args....: None
# Returns.: Exits with code 0
# Output..: Usage text, configuration summary, examples to stdout
# Notes...: Shows rsync options, peer hosts, SSH config; demonstrates common use cases
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] <file-or-folder>

Sync files/folders from current host to peer hosts using rsync.

OPTIONS:
    -n                     Dry run (simulate rsync)
    -v                     Enable verbose output
    -d                     Enable debug mode
    -D                     Delete remote files not present locally
    -q                     Quiet mode (suppress non-error output)
    -H "host1 host2"       Space-separated list of peer hosts
    -r <remote_base>       Remote base path (default: absolute source path)
    -c <config_file>       Load additional config file
    -h                     Show this help message

CONFIGURATION:
    SSH_USER.......: ${SSH_USER}
    SSH_PORT.......: ${SSH_PORT}
    PEER_HOSTS.....: ${PEER_HOSTS[*]}
    RSYNC_OPTS.....: ${RSYNC_OPTS}
    Config files...: ${LOADED_CONFIG:-none}

EXAMPLES:
    # Sync tnsnames.ora to all peers
    ${SCRIPT_NAME} -v \$ORACLE_BASE/network/admin/tnsnames.ora

    # Sync directory with delete option
    ${SCRIPT_NAME} -D -H "db01 db02" -r /tmp/config /etc/yum.repos.d/

    # Dry run verbose sync
    ${SCRIPT_NAME} -nv /opt/oracle/wallet

NOTES:
    - Requires ssh and rsync on all hosts
    - SSH keys must be configured for passwordless access
    - Source path is converted to absolute path

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function: should_log
# Purpose.: Determine if a log message should be displayed based on level and mode
# Args....: $1 - Log level (DEBUG/INFO/WARN/ERROR)
# Returns.: 0 if should log, 1 if should suppress
# Output..: None
# Notes...: Suppresses non-ERROR if QUIET=true; suppresses DEBUG if DEBUG=false
# ------------------------------------------------------------------------------
should_log() {
    local level="$1"
    [[ "${QUIET}" == "true" && "${level}" != "ERROR" ]] && return 1
    [[ "${level}" == "DEBUG" && "${DEBUG}" != "true" ]] && return 1
    return 0
}

# ------------------------------------------------------------------------------
# Function: parse_args
# Purpose.: Parse command line arguments and validate required parameters
# Args....: Command line arguments (passed as "$@")
# Returns.: Exits on validation failure
# Output..: Error messages to stderr
# Notes...: Sets DRYRUN, VERBOSE, DEBUG, DELETE, QUIET, PEER_HOSTS, REMOTE_BASE, SOURCE; validates source exists
# ------------------------------------------------------------------------------
# shellcheck disable=SC2034  # DRYRUN and DELETE tracked but effect is in RSYNC_OPTS
parse_args() {
    while getopts ":nvdDqH:r:c:h" opt; do
        case "${opt}" in
            n)
                DRYRUN=true
                RSYNC_OPTS+=" --dry-run"
                ;;
            v)
                VERBOSE=true
                RSYNC_OPTS+=" -v"
                ;;
            d) DEBUG=true ;;
            D)
                DELETE=true
                RSYNC_OPTS+=" --delete"
                ;;
            q) QUIET=true ;;
            H) IFS=' ' read -r -a PEER_HOSTS <<< "${OPTARG}" ;;
            r) REMOTE_BASE="${OPTARG}" ;;
            c) CONFIG_FILE="${OPTARG}" ;;
            h) usage ;;
            *) usage ;;
        esac
    done
    shift $((OPTIND - 1))

    SOURCE="$1"

    # Validate required argument
    if [[ -z "${SOURCE}" ]]; then
        echo "Error: Source file or folder is required." >&2
        usage
    fi

    # Check source exists
    if [[ ! -e "${SOURCE}" ]]; then
        should_log ERROR && oradba_log ERROR "Source '${SOURCE}' does not exist."
        exit 1
    fi

    # Validate peer hosts
    if [[ ${#PEER_HOSTS[@]} -eq 0 ]]; then
        should_log ERROR && oradba_log ERROR "PEER_HOSTS is empty. Configure via environment, config file, or -H option."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Function: perform_sync
# Purpose.: Execute rsync to each peer host
# Args....: None (uses global SOURCE, PEER_HOSTS, REMOTE_BASE, RSYNC_OPTS)
# Returns.: 0 if all syncs succeed, 1 if any fails
# Output..: Status messages via oradba_log; rsync output if verbose
# Notes...: Skips local host; converts to absolute paths; tracks success/failure arrays
# ------------------------------------------------------------------------------
perform_sync() {
    local abs_source
    local rsync_source
    local this_host

    # Get absolute path
    abs_source=$(realpath "${SOURCE}")

    # Determine rsync source (add trailing slash for directories)
    if [[ -d "${abs_source}" ]]; then
        rsync_source="${abs_source%/}/"
    else
        rsync_source="${abs_source}"
    fi

    this_host=$(hostname -s)
    should_log INFO && oradba_log INFO "Starting sync of '${rsync_source}' from ${this_host} to peers..."

    # Sync to each peer host
    for host in "${PEER_HOSTS[@]}"; do
        # Skip self
        if [[ "${host}" == "${this_host}" ]]; then
            should_log DEBUG && oradba_log DEBUG "Skipping self (${this_host})"
            continue
        fi

        # Determine target path
        local target_path="${REMOTE_BASE}"
        [[ -z "${target_path}" ]] && target_path="${abs_source}"

        # Execute rsync
        should_log INFO && oradba_log INFO "Syncing to ${host}:${target_path} ..."
        # shellcheck disable=SC2086
        if rsync ${RSYNC_OPTS} -e "ssh -p ${SSH_PORT}" "${rsync_source}" "${SSH_USER}@${host}:${target_path}"; then
            should_log INFO && oradba_log INFO "Sync to ${host} completed"
            SYNC_SUCCESS+=("${host}")
        else
            should_log ERROR && oradba_log ERROR "Failed to sync to ${host}"
            SYNC_FAILURE+=("${host}")
        fi
    done

    should_log INFO && oradba_log INFO "Sync operation finished."
}

# ------------------------------------------------------------------------------
# Function: show_summary
# Purpose.: Display synchronization results summary
# Args....: None (uses global SYNC_SUCCESS, SYNC_FAILURE, VERBOSE, QUIET)
# Returns.: None
# Output..: Success/failure counts and lists to stdout (if verbose mode)
# Notes...: Shows local host, successful peers, failed peers; only in verbose mode
# ------------------------------------------------------------------------------
show_summary() {
    if [[ "${VERBOSE}" == "true" && "${QUIET}" != "true" ]]; then
        local this_host
        this_host=$(hostname -s)

        should_log INFO && oradba_log INFO "--- Sync Summary ---"
        should_log INFO && oradba_log INFO "Local  : ${this_host}"
        should_log INFO && oradba_log INFO "Success: ${SYNC_SUCCESS[*]:-none}"
        should_log INFO && oradba_log INFO "Failed : ${SYNC_FAILURE[*]:-none}"
    fi
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Orchestrate sync-to-peers workflow
# Args....: Command line arguments (passed as "$@")
# Returns.: Exit code 0 if all syncs succeed, 1 if any fail
# Output..: Depends on verbose/quiet mode
# Notes...: Workflow: load config → parse args → perform sync → show summary; exits 1 if failures exist
# ------------------------------------------------------------------------------
main() {
    load_config
    parse_args "$@"
    perform_sync
    show_summary

    # Exit with error if any sync failed
    [[ ${#SYNC_FAILURE[@]} -gt 0 ]] && exit 1
    exit 0
}

main "$@"

# --- EOF ----------------------------------------------------------------------
