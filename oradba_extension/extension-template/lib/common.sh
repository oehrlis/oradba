#!/usr/bin/env bash
# Shared helpers for the extension template

# shellcheck disable=SC2034 # shellcheck sees these as unused in this library
EXTENSION_NAME="${EXTENSION_NAME:-extension-template}"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    local level="$1"; shift
    printf '[%s] %s %s\n' "$(timestamp)" "$level" "$*"
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

ensure_oracle_env() {
    if [[ -z "${ORACLE_SID:-}" ]]; then
        log_warn "ORACLE_SID is not set. Source oraenv.sh <SID> to load an Oracle environment."
        return 1
    fi
    return 0
}
