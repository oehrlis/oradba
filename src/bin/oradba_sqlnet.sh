#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_sqlnet.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.24
# Revision...: 0.9.0
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
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Manage SQL*Net configuration files (sqlnet.ora, tnsnames.ora).

Options:
  -i, --install TYPE     Install template (basic|secure)
  -g, --generate SID     Generate tnsnames entry for SID
  -v, --validate         Validate current configuration
  -b, --backup           Backup current configuration
  -t, --test ALIAS       Test TNS alias connection
  -l, --list             List all TNS aliases
  -s, --setup [SID]      Setup centralized TNS_ADMIN structure
  -a, --setup-all        Setup TNS_ADMIN for all databases in oratab
  -h, --help             Show this help message

Templates:
  basic    Basic configuration for development/test
  secure   Production security with encryption

Examples:
  # Install basic sqlnet.ora
  ${SCRIPT_NAME} --install basic

  # Setup centralized TNS_ADMIN structure
  ${SCRIPT_NAME} --setup PRODDB

  # Setup for all databases in oratab
  ${SCRIPT_NAME} --setup-all

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

# Check if Oracle Home is read-only (logical read-only, not physical)
# Oracle's read-only home feature uses ORACLE_BASE_HOME and ORACLE_BASE_CONFIG
# for writable files while ORACLE_HOME remains logically read-only.
# Returns: 0 if read-only, 1 if read-write or unsupported
is_readonly_home() {
    local oracle_home="${1:-${ORACLE_HOME}}"

    if [[ -z "${oracle_home}" ]]; then
        return 1
    fi

    # Check if orabasehome command exists (introduced in Oracle 18c+)
    local orabasehome="${oracle_home}/bin/orabasehome"
    if [[ ! -x "${orabasehome}" ]]; then
        # orabasehome not available = Oracle version doesn't support read-only homes
        return 1
    fi

    # Run orabasehome and check output
    # If output == $ORACLE_HOME → read/write mode (return 1)
    # If output == $ORACLE_BASE/homes/HOME_NAME → read-only mode (return 0)
    local orabase_output
    orabase_output=$("${orabasehome}" 2> /dev/null)

    if [[ "${orabase_output}" == "${oracle_home}" ]]; then
        # Read-write mode
        return 1
    else
        # Read-only mode (output is different from ORACLE_HOME)
        return 0
    fi
}

# Get centralized TNS_ADMIN path
get_central_tns_admin() {
    local sid="${1:-${ORACLE_SID}}"
    local base="${ORACLE_BASE:-/u01/app/oracle}"

    if [[ -n "${sid}" ]]; then
        echo "${base}/network/${sid}/admin"
    else
        echo "${base}/network/admin"
    fi
}

# Create centralized TNS_ADMIN structure
create_tns_structure() {
    local sid="${1:-${ORACLE_SID}}"
    local base="${ORACLE_BASE:-/u01/app/oracle}"
    local tns_admin

    if [[ -n "${sid}" ]]; then
        tns_admin="${base}/network/${sid}"
    else
        tns_admin="${base}/network"
    fi

    echo "Creating TNS_ADMIN structure at ${tns_admin}..." >&2

    # Create directories
    mkdir -p "${tns_admin}/admin" || {
        echo "ERROR: Cannot create ${tns_admin}/admin" >&2
        return 1
    }
    mkdir -p "${tns_admin}/log"
    mkdir -p "${tns_admin}/trace"

    echo "✓ Created ${tns_admin}/admin" >&2
    echo "✓ Created ${tns_admin}/log" >&2
    echo "✓ Created ${tns_admin}/trace" >&2

    # Set permissions
    chmod 755 "${tns_admin}" "${tns_admin}/admin" "${tns_admin}/log" "${tns_admin}/trace"

    echo "${tns_admin}/admin"
}

# Move existing config files to centralized location
migrate_config_files() {
    local source_dir="${1}"
    local target_dir="${2}"
    local moved=0

    if [[ ! -d "${source_dir}" ]]; then
        return 0
    fi

    echo "Migrating configuration files from ${source_dir}..."

    for file in sqlnet.ora tnsnames.ora ldap.ora listener.ora; do
        if [[ -f "${source_dir}/${file}" ]] && [[ ! -L "${source_dir}/${file}" ]]; then
            # Backup in source location
            backup_file "${source_dir}/${file}"

            # Move to target
            if [[ -f "${target_dir}/${file}" ]]; then
                # Target exists, backup it too
                backup_file "${target_dir}/${file}"
            fi

            mv "${source_dir}/${file}" "${target_dir}/${file}"
            echo "✓ Moved ${file} to ${target_dir}"
            ((moved++))
        fi
    done

    if [[ ${moved} -gt 0 ]]; then
        echo "✓ Migrated ${moved} file(s)"
    else
        echo "⚠ No files to migrate"
    fi
}

# Create symlinks from ORACLE_HOME to centralized location
create_symlinks() {
    local oracle_home="${1}"
    local central_admin="${2}"
    local created=0

    if [[ -z "${oracle_home}" ]] || [[ ! -d "${oracle_home}" ]]; then
        echo "ERROR: Invalid ORACLE_HOME: ${oracle_home}" >&2
        return 1
    fi

    local admin_dir="${oracle_home}/network/admin"
    mkdir -p "${admin_dir}" 2> /dev/null || {
        echo "WARNING: Cannot create ${admin_dir}, possibly read-only home" >&2
        return 0
    }

    echo "Creating symlinks in ${admin_dir}..."

    for file in sqlnet.ora tnsnames.ora ldap.ora listener.ora; do
        local link="${admin_dir}/${file}"
        local target="${central_admin}/${file}"

        # Remove existing symlink or regular file
        if [[ -L "${link}" ]]; then
            rm -f "${link}"
        elif [[ -f "${link}" ]]; then
            # Already migrated, shouldn't happen
            echo "⚠ Skipping ${file} (regular file exists)"
            continue
        fi

        # Create symlink only if target exists or for required files
        if [[ -f "${target}" ]] || [[ "${file}" == "sqlnet.ora" ]] || [[ "${file}" == "tnsnames.ora" ]]; then
            ln -sf "${target}" "${link}"
            echo "✓ Created symlink: ${link} -> ${target}"
            ((created++))
        fi
    done

    if [[ ${created} -gt 0 ]]; then
        echo "✓ Created ${created} symlink(s)"
    fi
}

# Update sqlnet.ora with correct log/trace directories
update_sqlnet_paths() {
    local sqlnet_file="${1}"
    local base_dir="${2}"

    if [[ ! -f "${sqlnet_file}" ]]; then
        return 0
    fi

    echo "Updating log/trace directories in ${sqlnet_file}..."

    # Backup before modification
    backup_file "${sqlnet_file}"

    # Update or add log directories
    local log_dir="${base_dir}/log"
    local trace_dir="${base_dir}/trace"

    # Remove existing LOG_DIRECTORY and TRACE_DIRECTORY lines
    sed -i.tmp '/^LOG_DIRECTORY_CLIENT/d' "${sqlnet_file}"
    sed -i.tmp '/^LOG_DIRECTORY_SERVER/d' "${sqlnet_file}"
    sed -i.tmp '/^TRACE_DIRECTORY_CLIENT/d' "${sqlnet_file}"
    sed -i.tmp '/^TRACE_DIRECTORY_SERVER/d' "${sqlnet_file}"
    sed -i.tmp '/^# Log directories/d' "${sqlnet_file}"
    rm -f "${sqlnet_file}.tmp"

    # Add new directories at the end
    cat >> "${sqlnet_file}" << EOF

# Log directories (auto-configured)
LOG_DIRECTORY_CLIENT = ${log_dir}
LOG_DIRECTORY_SERVER = ${log_dir}
TRACE_DIRECTORY_CLIENT = ${trace_dir}
TRACE_DIRECTORY_SERVER = ${trace_dir}
EOF

    echo "✓ Updated log/trace directories"
}

# Setup centralized TNS_ADMIN for a database
setup_tns_admin() {
    local sid="${1:-${ORACLE_SID}}"
    local oracle_home="${2:-${ORACLE_HOME}}"

    if [[ -z "${sid}" ]]; then
        echo "ERROR: ORACLE_SID required (set ORACLE_SID or provide as argument)" >&2
        return 1
    fi

    if [[ -z "${ORACLE_BASE}" ]]; then
        echo "ERROR: ORACLE_BASE must be set" >&2
        return 1
    fi

    echo "========================================"
    echo "Setting up centralized TNS_ADMIN"
    echo "ORACLE_SID:  ${sid}"
    echo "ORACLE_HOME: ${oracle_home}"
    echo "ORACLE_BASE: ${ORACLE_BASE}"
    echo "========================================"
    echo ""

    # Determine if read-only home
    local readonly_home=false
    if [[ -n "${oracle_home}" ]] && is_readonly_home "${oracle_home}"; then
        readonly_home=true
        echo "✓ Detected read-only Oracle Home"
    fi

    # Create centralized structure
    local central_admin
    central_admin=$(create_tns_structure "${sid}") || return 1
    local base_dir
    base_dir=$(dirname "${central_admin}")

    echo ""

    # Migrate files from ORACLE_HOME if exists
    if [[ -n "${oracle_home}" ]] && [[ -d "${oracle_home}/network/admin" ]]; then
        migrate_config_files "${oracle_home}/network/admin" "${central_admin}"
        echo ""
    fi

    # Update sqlnet.ora paths if it exists
    if [[ -f "${central_admin}/sqlnet.ora" ]]; then
        update_sqlnet_paths "${central_admin}/sqlnet.ora" "${base_dir}"
        echo ""
    fi

    # Create symlinks in ORACLE_HOME
    if [[ -n "${oracle_home}" ]] && [[ ! "${readonly_home}" == "true" ]]; then
        create_symlinks "${oracle_home}" "${central_admin}"
        echo ""
    fi

    # Export TNS_ADMIN for current session
    export TNS_ADMIN="${central_admin}"

    echo "========================================"
    echo "✓ Setup complete!"
    echo "TNS_ADMIN: ${central_admin}"
    echo ""
    echo "Add to your profile:"
    echo "  export TNS_ADMIN=${central_admin}"
    echo "========================================"
}

# Setup for all databases in oratab
setup_all_tns_admin() {
    local oratab="${ORATAB:-/etc/oratab}"
    local count=0
    local errors=0

    if [[ ! -f "${oratab}" ]]; then
        echo "ERROR: oratab not found at ${oratab}" >&2
        return 1
    fi

    echo "Setting up TNS_ADMIN for all databases in oratab..."
    echo ""

    # Parse oratab
    # shellcheck disable=SC2034
    while IFS=: read -r sid home start_flag || [[ -n "${sid}" ]]; do
        # Skip comments and empty lines
        [[ "${sid}" =~ ^#.*$ ]] && continue
        [[ -z "${sid}" ]] && continue

        # Skip ASM and agent entries
        [[ "${sid}" =~ ^\+.*$ ]] && continue
        [[ "${sid}" =~ ^agent.*$ ]] && continue

        # Setup for this database
        echo "Processing ${sid}..."
        if setup_tns_admin "${sid}" "${home}"; then
            ((count++))
        else
            ((errors++))
        fi
        echo ""
        echo ""
    done < <(grep -v "^#" "${oratab}" 2> /dev/null)

    echo "========================================"
    echo "Setup Summary:"
    echo "  Success: ${count} database(s)"
    echo "  Errors:  ${errors} database(s)"
    echo "========================================"

    if [[ ${errors} -gt 0 ]]; then
        return 1
    fi
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
        ls -1 "${TEMPLATE_DIR}"/sqlnet.ora.* 2> /dev/null | sed 's|.*/sqlnet.ora.||' >&2
        return 1
    fi

    # Create directory if needed
    mkdir -p "${tns_admin}"

    # Backup existing
    if [[ -f "${target}" ]]; then
        backup_file "${target}"
    fi

    # Copy template with variable substitution
    if command -v envsubst > /dev/null 2>&1; then
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
    hostname=$(hostname -f 2> /dev/null || hostname)
    local port="1521"

    # Check if entry already exists
    if [[ -f "${tnsnames}" ]] && grep -q "^${sid} *=" "${tnsnames}"; then
        echo "WARNING: Entry ${sid} already exists in ${tnsnames}" >&2
        echo "Use --backup first to preserve existing configuration" >&2
        return 1
    fi

    # Append to tnsnames.ora
    cat >> "${tnsnames}" << EOF

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
    if command -v tnsping > /dev/null 2>&1; then
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
        if grep -q "DESCRIPTION" "${tns_admin}/tnsnames.ora" 2> /dev/null; then
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
        -i | --install)
            if [[ -z "${2}" ]]; then
                echo "ERROR: Template type required" >&2
                usage
                exit 1
            fi
            install_sqlnet "${2}"
            ;;
        -g | --generate)
            if [[ -z "${2}" ]]; then
                echo "ERROR: ORACLE_SID required" >&2
                usage
                exit 1
            fi
            generate_tnsnames "${2}"
            ;;
        -t | --test)
            if [[ -z "${2}" ]]; then
                echo "ERROR: TNS alias required" >&2
                usage
                exit 1
            fi
            test_tnsalias "${2}"
            ;;
        -l | --list)
            list_aliases
            ;;
        -v | --validate)
            validate_config
            ;;
        -b | --backup)
            backup_config
            ;;
        -s | --setup)
            setup_tns_admin "${2}"
            ;;
        -a | --setup-all)
            setup_all_tns_admin
            ;;
        -h | --help)
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
