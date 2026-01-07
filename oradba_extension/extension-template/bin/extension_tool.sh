#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA Extension Template
# Name.......: extension_tool.sh
# Purpose....: Example tool shipped with the template extension.
# Notes......: Replace the sample logic with your own extension functionality.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load shared helpers
if [[ -f "${EXTENSION_ROOT}/lib/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "${EXTENSION_ROOT}/lib/common.sh"
else
    log_info()  { printf '[%s] INFO %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
    log_warn()  { printf '[%s] WARN %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
    log_error() { printf '[%s] ERROR %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
    ensure_oracle_env() { [[ -n "${ORACLE_SID:-}" ]]; }
fi

EXTENSION_NAME="${EXTENSION_NAME:-extension-template}"
EXTENSION_VERSION="${EXTENSION_VERSION:-0.1.0}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--help] [--debug]

Sample OraDBA extension tool. Extend or replace this script with your own logic.

Options:
  --help     Show this help message
  --debug    Enable verbose logging

Environment (set by OraDBA when extension loads):
  ORADBA_EXT_${EXTENSION_NAME^^}_PATH   Path to this extension
  PATH, SQLPATH, ORADBA_RCV_PATHS       Include extension bin/sql/rcv
EOF
    exit 0
}

main() {
    log_info "Running template tool from ${EXTENSION_NAME} v${EXTENSION_VERSION}"
    log_info "Extension path: ${ORADBA_EXT_${EXTENSION_NAME^^}_PATH:-${EXTENSION_ROOT}}"

    if ensure_oracle_env; then
        log_info "Oracle environment detected: ORACLE_SID=${ORACLE_SID}"
    else
        log_warn "Oracle environment not detected. Set ORACLE_SID/ORACLE_HOME if required."
    fi

    log_info "Replace this message with your extension logic."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage ;;
        --debug) set -x; shift ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

main "$@"
