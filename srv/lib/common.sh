#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: common.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: Common library functions for oradba scripts
# Notes......: This library provides reusable functions for logging, validation,
#              Oracle environment management, and configuration parsing.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get the absolute path of the script directory
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Verify Oracle environment variables
verify_oracle_env() {
    local required_vars=("ORACLE_SID" "ORACLE_HOME")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required Oracle environment variables: ${missing_vars[*]}"
        return 1
    fi

    return 0
}

# Get Oracle version
get_oracle_version() {
    if [[ -z "${ORACLE_HOME}" ]]; then
        log_error "ORACLE_HOME not set"
        return 1
    fi

    if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
        "${ORACLE_HOME}/bin/sqlplus" -version | grep -oP 'Release \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
    else
        log_error "sqlplus not found in ORACLE_HOME"
        return 1
    fi
}

# Parse oratab file
parse_oratab() {
    local sid="$1"
    local oratab_file="${2:-/etc/oratab}"

    if [[ ! -f "$oratab_file" ]]; then
        log_error "oratab file not found: $oratab_file"
        return 1
    fi

    grep "^${sid}:" "$oratab_file" | grep -v "^#" | head -1
}

# Export common Oracle environment variables
export_oracle_base_env() {
    # Set common paths if not already set
    export PATH="${ORACLE_HOME}/bin:${PATH}"
    export LD_LIBRARY_PATH="${ORACLE_HOME}/lib:${LD_LIBRARY_PATH:-}"

    # Set TNS_ADMIN if not set
    if [[ -z "${TNS_ADMIN}" ]]; then
        if [[ -d "${ORACLE_HOME}/network/admin" ]]; then
            export TNS_ADMIN="${ORACLE_HOME}/network/admin"
        fi
    fi

    # Set NLS_LANG if not set
    export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.AL32UTF8}"
}

# Validate directory path
validate_directory() {
    local dir="$1"
    local create="${2:-false}"

    if [[ ! -d "$dir" ]]; then
        if [[ "$create" == "true" ]]; then
            mkdir -p "$dir" 2> /dev/null
            if [[ $? -ne 0 ]]; then
                log_error "Failed to create directory: $dir"
                return 1
            fi
            log_info "Created directory: $dir"
        else
            log_error "Directory does not exist: $dir"
            return 1
        fi
    fi

    return 0
}
