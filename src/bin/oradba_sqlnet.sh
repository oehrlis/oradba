#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_sqlnet.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.19
# Revision...: 0.1.0
# Purpose....: Manage SQL*Net configuration files (sqlnet.ora, tnsnames.ora, ldap.ora)
# Notes......: Provides installation, generation, validation, and testing of SQL*Net configs
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o pipefail

# Script metadata
# shellcheck disable=SC2034
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC2034
SCRIPT_VERSION="0.1.0"

# Determine ORADBA_BASE
if [[ -n "${ORADBA_BASE}" ]]; then
    : # ORADBA_BASE already set
elif [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
    ORADBA_BASE="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    echo "ERROR: Cannot determine ORADBA_BASE" >&2
    exit 1
fi

# Template directory
TEMPLATE_DIR="${ORADBA_BASE}/templates/sqlnet"

# Functions
# ------------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Manage SQL*Net configuration files (sqlnet.ora, tnsnames.ora).

Options:
  -i, --install TYPE     Install template (basic|secure)
  -g, --generate SID     Generate tnsnames entry for SID
  -v, --validate         Validate current configuration
  -b, --backup           Backup current configuration
  -t, --test ALIAS       Test TNS alias connection
  -l, --list             List all TNS aliases
  -h, --help             Show this help message

Templates:
  basic    Basic configuration for development/test
  secure   Production security with encryption

Examples:
  # Install basic sqlnet.ora
  ${SCRIPT_NAME} --install basic

  # Generate tnsnames entry for ORCL
  ${SCRIPT_NAME} --generate ORCL

  # Test connection
  ${SCRIPT_NAME} --test ORCL

  # List all aliases
  ${SCRIPT_NAME} --list

  # Validate configuration
  ${SCRIPT_NAME} --validate
EOF
}

# Get TNS_ADMIN directory
get_tns_admin() {
    if [[ -n "${TNS_ADMIN}" ]]; then
        echo "${TNS_ADMIN}"
    elif [[ -n "${ORACLE_HOME}" ]]; then
        echo "${ORACLE_HOME}/network/admin"
    else
        echo "${HOME}/.oracle/network/admin"
    fi
}

# Backup file with timestamp
backup_file() {
    local file="${1}"
    local backup
    backup="${file}.$(date +%Y%m%d_%H%M%S).bak"
    
    if [[ -f "${file}" ]]; then
        cp "${file}" "${backup}"
        echo "✓ Backed up to ${backup}"
        return 0
    fi
    return 1
}

# Install sqlnet.ora template
install_sqlnet() {
    local type="${1:-basic}"
    local template="${TEMPLATE_DIR}/sqlnet.ora.${type}"
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local target="${tns_admin}/sqlnet.ora"

    if [[ ! -f "${template}" ]]; then
        echo "ERROR: Template not found: ${template}" >&2
        echo "Available templates:" >&2
        # shellcheck disable=SC2012
        ls -1 "${TEMPLATE_DIR}"/sqlnet.ora.* 2>/dev/null | sed 's|.*/sqlnet.ora.||' >&2
        return 1
    fi

    # Create directory if needed
    mkdir -p "${tns_admin}"

    # Backup existing
    if [[ -f "${target}" ]]; then
        backup_file "${target}"
    fi

    # Copy template with variable substitution
    if command -v envsubst >/dev/null 2>&1; then
        envsubst < "${template}" > "${target}"
    else
        # Manual substitution if envsubst not available
        sed -e "s|\${ORACLE_BASE}|${ORACLE_BASE:-/u01/app/oracle}|g" \
            -e "s|\${ORACLE_SID}|${ORACLE_SID:-orcl}|g" \
            "${template}" > "${target}"
    fi
    
    chmod 644 "${target}"
    echo "✓ Installed sqlnet.ora (${type}) to ${target}"
}

# Generate tnsnames entry
generate_tnsnames() {
    local sid="${1}"
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local tnsnames="${tns_admin}/tnsnames.ora"

    if [[ -z "${sid}" ]]; then
        echo "ERROR: ORACLE_SID required" >&2
        return 1
    fi

    # Create directory if needed
    mkdir -p "${tns_admin}"

    # Get hostname
    local hostname
    hostname=$(hostname -f 2>/dev/null || hostname)
    local port="1521"

    # Check if entry already exists
    if [[ -f "${tnsnames}" ]] && grep -q "^${sid} *=" "${tnsnames}"; then
        echo "WARNING: Entry ${sid} already exists in ${tnsnames}" >&2
        echo "Use --backup first to preserve existing configuration" >&2
        return 1
    fi

    # Append to tnsnames.ora
    cat >> "${tnsnames}" <<EOF

# Auto-generated entry for ${sid} - $(date)
${sid} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${hostname})(PORT = ${port}))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${sid})
    )
  )
EOF

    chmod 644 "${tnsnames}"
    echo "✓ Added ${sid} to ${tnsnames}"
}

# Test TNS alias
test_tnsalias() {
    local alias="${1}"

    if [[ -z "${alias}" ]]; then
        echo "ERROR: TNS alias required" >&2
        return 1
    fi

    echo "Testing connection to ${alias}..."
    echo ""

    # Use tnsping
    if command -v tnsping >/dev/null 2>&1; then
        echo "=== TNS Ping Test ==="
        tnsping "${alias}" 3
        echo ""
    else
        echo "WARNING: tnsping not found in PATH" >&2
    fi

    # Try resolving the alias
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local tnsnames="${tns_admin}/tnsnames.ora"
    
    if [[ -f "${tnsnames}" ]]; then
        echo "=== TNS Entry ==="
        awk "/^${alias} *=/,/^\)$/" "${tnsnames}"
    else
        echo "WARNING: tnsnames.ora not found at ${tnsnames}" >&2
    fi
}

# List TNS aliases
list_aliases() {
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local tnsnames="${tns_admin}/tnsnames.ora"

    if [[ ! -f "${tnsnames}" ]]; then
        echo "ERROR: tnsnames.ora not found at ${tnsnames}" >&2
        return 1
    fi

    echo "TNS Aliases in ${tnsnames}:"
    echo "========================================"
    grep -E "^[A-Z0-9_]+ *=" "${tnsnames}" | sed 's/ *=.*//' | sort | nl
}

# Validate configuration
validate_config() {
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local errors=0

    echo "Validating SQL*Net configuration..."
    echo "TNS_ADMIN: ${tns_admin}"
    echo ""

    # Check sqlnet.ora
    if [[ -f "${tns_admin}/sqlnet.ora" ]]; then
        echo "✓ sqlnet.ora exists"
        if [[ -r "${tns_admin}/sqlnet.ora" ]]; then
            echo "✓ sqlnet.ora is readable"
        else
            echo "✗ sqlnet.ora permissions issue" >&2
            ((errors++))
        fi
    else
        echo "✗ sqlnet.ora not found" >&2
        ((errors++))
    fi

    # Check tnsnames.ora
    if [[ -f "${tns_admin}/tnsnames.ora" ]]; then
        echo "✓ tnsnames.ora exists"
        
        # Basic syntax check
        if grep -q "DESCRIPTION" "${tns_admin}/tnsnames.ora" 2>/dev/null; then
            echo "✓ tnsnames.ora appears to have valid entries"
        fi
    else
        echo "⚠ tnsnames.ora not found (optional)" >&2
    fi

    # Check ORACLE_HOME
    if [[ -n "${ORACLE_HOME}" ]]; then
        echo "✓ ORACLE_HOME is set: ${ORACLE_HOME}"
    else
        echo "⚠ ORACLE_HOME not set" >&2
    fi

    echo ""
    if [[ ${errors} -eq 0 ]]; then
        echo "✓ Configuration validation passed"
        return 0
    else
        echo "✗ Configuration validation failed with ${errors} error(s)" >&2
        return 1
    fi
}

# Backup all configuration files
backup_config() {
    local tns_admin
    tns_admin="$(get_tns_admin)"
    local backup_count=0

    echo "Backing up SQL*Net configuration files..."
    
    for file in sqlnet.ora tnsnames.ora ldap.ora; do
        if [[ -f "${tns_admin}/${file}" ]]; then
            backup_file "${tns_admin}/${file}"
            ((backup_count++))
        fi
    done

    if [[ ${backup_count} -eq 0 ]]; then
        echo "No configuration files found to backup" >&2
        return 1
    fi

    echo "✓ Backed up ${backup_count} file(s)"
}

# Main
# ------------------------------------------------------------------------------

main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    case "${1}" in
        -i|--install)
            if [[ -z "${2}" ]]; then
                echo "ERROR: Template type required" >&2
                usage
                exit 1
            fi
            install_sqlnet "${2}"
            ;;
        -g|--generate)
            if [[ -z "${2}" ]]; then
                echo "ERROR: ORACLE_SID required" >&2
                usage
                exit 1
            fi
            generate_tnsnames "${2}"
            ;;
        -t|--test)
            if [[ -z "${2}" ]]; then
                echo "ERROR: TNS alias required" >&2
                usage
                exit 1
            fi
            test_tnsalias "${2}"
            ;;
        -l|--list)
            list_aliases
            ;;
        -v|--validate)
            validate_config
            ;;
        -b|--backup)
            backup_config
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: ${1}" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"

# --- EOF ----------------------------------------------------------------------
