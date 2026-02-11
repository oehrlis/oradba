#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_dbca.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Automated DBCA database creation using response file templates
# Notes......: Provides command-line interface for creating Oracle databases
#              using DBCA response file templates with variable substitution.
#              Supports dry-run mode, custom templates, and template discovery.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
ORADBA_BASE="$(dirname "${SCRIPT_DIR}")"

# Source common library
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library" >&2
    exit 3
fi

# Script variables
VERSION="1.0.0"
readonly DBCA_TEMPLATE_DIR="${ORADBA_BASE}/templates/dbca"

# Default values
DEFAULT_CHARSET="AL32UTF8"
DEFAULT_NCHARSET="AL16UTF16"
DEFAULT_MEMORY_MB="2048"
DEFAULT_PDB_NAME="PDB1"

# Global variables (set by argument parsing)
DB_SID=""
DB_VERSION=""
DB_TEMPLATE="general"
MEMORY_MB="${DEFAULT_MEMORY_MB}"
CHARSET="${DEFAULT_CHARSET}"
NCHARSET="${DEFAULT_NCHARSET}"
PDB_NAME="${DEFAULT_PDB_NAME}"
DATA_DIR=""
FRA_DIR=""
SYS_PASSWORD=""
SYSTEM_PASSWORD=""
CUSTOM_TEMPLATE=""
DRY_RUN="false"
DB_DOMAIN=""
DB_UNIQUE_NAME=""

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information
# Args....: None
# Returns.: Exits with 0
# Output..: Usage text to stdout
# ------------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Create Oracle database using DBCA response file templates.

Options:
    -s, --sid SID              Database SID (required unless --show-templates)
    -h, --oracle-home PATH     Oracle Home (default: \${ORACLE_HOME})
    -b, --oracle-base PATH     Oracle Base (default: \${ORACLE_BASE})
    -v, --version VERSION      Oracle version (19c, 26ai)
    -t, --template TYPE        Template type:
                                 general (default)
                                 container
                                 pluggable
                                 dev
                                 rac
                                 dataguard (19c only)
                                 free (26ai only)
    -d, --data-dir PATH        Database files directory
    -r, --fra-dir PATH         Fast Recovery Area directory
    -m, --memory MB            Total memory in MB (default: ${DEFAULT_MEMORY_MB})
    -c, --charset CHARSET      Character set (default: ${DEFAULT_CHARSET})
    -n, --ncharset NCHARSET    National charset (default: ${DEFAULT_NCHARSET})
    -p, --pdb-name NAME        PDB name (default: ${DEFAULT_PDB_NAME})
    --domain DOMAIN            Database domain (default: auto-detected)
    --db-unique-name NAME      Database unique name (for Data Guard)
    --sys-password PWD         SYS password (prompted if not provided)
    --system-password PWD      SYSTEM password (prompted if not provided)
    --custom-template FILE     Use custom response file
    --dry-run                  Generate response file but don't create database
    --show-templates           List available templates
    -q, --quiet                Quiet mode
    --help                     Show this help

Examples:
    # Create 19c general purpose database
    ${SCRIPT_NAME} --sid ORCL --version 19c

    # Create 19c container database with specific settings
    ${SCRIPT_NAME} --sid ORCL --version 19c --template container \\
                    --memory 4096 --pdb-name PDB1

    # Create 26ai free edition database
    ${SCRIPT_NAME} --sid FREE --version 26ai --template free

    # Dry run (generate response file only)
    ${SCRIPT_NAME} --sid ORCL --version 19c --dry-run

    # List available templates
    ${SCRIPT_NAME} --show-templates

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function: show_templates
# Purpose.: Display available DBCA templates
# Args....: None
# Returns.: 0 on success
# Output..: List of available templates to stdout
# ------------------------------------------------------------------------------
show_templates() {
    oradba_log INFO "Available DBCA Templates:"
    echo ""
    
    for version_dir in "${DBCA_TEMPLATE_DIR}"/*/; do
        local version
        version="$(basename "${version_dir}")"
        [[ "${version}" == "common" || "${version}" == "custom" ]] && continue
        
        echo "Oracle ${version}:"
        if [[ -d "${version_dir}" ]]; then
            find "${version_dir}" -maxdepth 1 -name '*.rsp' -type f 2>/dev/null | sort | while read -r template; do
                local name
                name=$(basename "${template}" .rsp)
                local type=${name##*_}
                printf "  %-15s %s\n" "${type}" "$(basename "${template}")"
            done
        fi
        echo ""
    done
}

# ------------------------------------------------------------------------------
# Function: substitute_variables
# Purpose.: Substitute template variables with actual values
# Args....: $1 - Input template file path
#           $2 - Output response file path
# Returns.: 0 on success, 1 on error
# Output..: Generated response file
# ------------------------------------------------------------------------------
substitute_variables() {
    local template_file="$1"
    local output_file="$2"
    
    if [[ ! -f "${template_file}" ]]; then
        oradba_log ERROR "Template file not found: ${template_file}"
        return 1
    fi
    
    oradba_log INFO "Generating response file from template: ${template_file}"
    
    # Read template and substitute variables
    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Substitute all variables
        line="${line//\{\{ORACLE_SID\}\}/${DB_SID}}"
        line="${line//\{\{ORACLE_HOME\}\}/${ORACLE_HOME}}"
        line="${line//\{\{ORACLE_BASE\}\}/${ORACLE_BASE}}"
        line="${line//\{\{DATA_DIR\}\}/${DATA_DIR}}"
        line="${line//\{\{FRA_DIR\}\}/${FRA_DIR}}"
        line="${line//\{\{DOMAIN\}\}/${DB_DOMAIN}}"
        line="${line//\{\{SYS_PASSWORD\}\}/${SYS_PASSWORD}}"
        line="${line//\{\{SYSTEM_PASSWORD\}\}/${SYSTEM_PASSWORD}}"
        line="${line//\{\{PDB_NAME\}\}/${PDB_NAME}}"
        line="${line//\{\{MEMORY_MB\}\}/${MEMORY_MB}}"
        line="${line//\{\{CHARSET\}\}/${CHARSET}}"
        line="${line//\{\{NCHARSET\}\}/${NCHARSET}}"
        line="${line//\{\{DB_UNIQUE_NAME\}\}/${DB_UNIQUE_NAME}}"
        line="${line//\{\{ASM_DISKGROUP\}\}/${ASM_DISKGROUP:-DATA}}"
        line="${line//\{\{ASM_FRA_DISKGROUP\}\}/${ASM_FRA_DISKGROUP:-FRA}}"
        line="${line//\{\{NODELIST\}\}/${NODELIST:-}}"
        
        echo "${line}"
    done < "${template_file}" > "${output_file}"
    
    oradba_log INFO "Response file generated: ${output_file}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: validate_prerequisites
# Purpose.: Validate prerequisites for database creation
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: Validation messages to log
# ------------------------------------------------------------------------------
validate_prerequisites() {
    oradba_log INFO "Validating prerequisites..."
    
    # Check Oracle Home
    if [[ -z "${ORACLE_HOME}" || ! -d "${ORACLE_HOME}" ]]; then
        oradba_log ERROR "ORACLE_HOME not set or invalid: ${ORACLE_HOME}"
        return 1
    fi
    
    # Check Oracle Base
    if [[ -z "${ORACLE_BASE}" || ! -d "${ORACLE_BASE}" ]]; then
        oradba_log ERROR "ORACLE_BASE not set or invalid: ${ORACLE_BASE}"
        return 1
    fi
    
    # Check dbca executable
    if [[ ! -x "${ORACLE_HOME}/bin/dbca" ]]; then
        oradba_log ERROR "DBCA not found or not executable: ${ORACLE_HOME}/bin/dbca"
        return 1
    fi
    
    # Check if database already exists (basic check)
    if [[ -d "${ORACLE_HOME}/dbs" && -f "${ORACLE_HOME}/dbs/init${DB_SID}.ora" ]]; then
        oradba_log WARN "Database ${DB_SID} may already exist (init file found)"
        oradba_log WARN "Continuing anyway..."
    fi
    
    # Check if oratab entry exists
    if [[ -f "/etc/oratab" ]] && grep -q "^${DB_SID}:" /etc/oratab 2>/dev/null; then
        oradba_log WARN "Database ${DB_SID} found in /etc/oratab"
    fi
    
    # Check disk space for data directory
    if [[ -n "${DATA_DIR}" ]]; then
        local data_dir_parent
        data_dir_parent=$(dirname "${DATA_DIR}")
        if [[ -d "${data_dir_parent}" ]]; then
            local avail_gb
            avail_gb=$(df -BG "${data_dir_parent}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
            if [[ -n "${avail_gb}" ]] && (( avail_gb < 10 )); then
                oradba_log WARN "Low disk space in ${data_dir_parent}: ${avail_gb}GB available"
                oradba_log WARN "Minimum 10GB recommended for database files"
            else
                oradba_log INFO "Available disk space in ${data_dir_parent}: ${avail_gb}GB"
            fi
        fi
    fi
    
    oradba_log INFO "Prerequisites validated successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: create_directories
# Purpose.: Create database directories if they don't exist
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: Directory creation messages to log
# ------------------------------------------------------------------------------
create_directories() {
    oradba_log INFO "Creating database directories..."
    
    # Create data directory
    if [[ ! -d "${DATA_DIR}" ]]; then
        if mkdir -p "${DATA_DIR}" 2>/dev/null; then
            oradba_log INFO "Created data directory: ${DATA_DIR}"
        else
            oradba_log ERROR "Failed to create data directory: ${DATA_DIR}"
            return 1
        fi
    else
        oradba_log INFO "Data directory already exists: ${DATA_DIR}"
    fi
    
    # Create FRA directory
    if [[ ! -d "${FRA_DIR}" ]]; then
        if mkdir -p "${FRA_DIR}" 2>/dev/null; then
            oradba_log INFO "Created FRA directory: ${FRA_DIR}"
        else
            oradba_log ERROR "Failed to create FRA directory: ${FRA_DIR}"
            return 1
        fi
    else
        oradba_log INFO "FRA directory already exists: ${FRA_DIR}"
    fi
    
    oradba_log INFO "Directories created successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: run_dbca
# Purpose.: Execute DBCA with response file
# Args....: $1 - Response file path
# Returns.: 0 on success, 1 on error
# Output..: DBCA output to log
# ------------------------------------------------------------------------------
run_dbca() {
    local response_file="$1"
    
    oradba_log INFO "Starting database creation..."
    oradba_log INFO "Database SID: ${DB_SID}"
    oradba_log INFO "Oracle Home: ${ORACLE_HOME}"
    oradba_log INFO "Response File: ${response_file}"
    echo ""
    
    # Build DBCA command
    local dbca_cmd="${ORACLE_HOME}/bin/dbca -silent -createDatabase -responseFile ${response_file}"
    
    oradba_log INFO "Executing DBCA..."
    oradba_log DEBUG "Command: ${dbca_cmd}"
    
    # Run DBCA and capture output
    if "${ORACLE_HOME}"/bin/dbca -silent -createDatabase -responseFile "${response_file}" 2>&1 | tee -a "${ORADBA_LOG_FILE:-/dev/null}"; then
        echo ""
        oradba_log SUCCESS "Database ${DB_SID} created successfully"
        return 0
    else
        echo ""
        oradba_log ERROR "Database creation failed"
        oradba_log ERROR "Check DBCA logs in: ${ORACLE_BASE}/cfgtoollogs/dbca/${DB_SID}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: detect_domain
# Purpose.: Auto-detect database domain from hostname
# Args....: None
# Returns.: 0 on success
# Output..: Domain name to stdout
# ------------------------------------------------------------------------------
detect_domain() {
    local domain
    domain=$(hostname -d 2>/dev/null)
    if [[ -z "${domain}" ]]; then
        domain="localdomain"
    fi
    echo "${domain}"
}

# ------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose.: Parse command-line arguments
# Args....: $@ - All command-line arguments
# Returns.: 0 on success, 1 on error
# Output..: None (sets global variables)
# ------------------------------------------------------------------------------
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--sid)
                DB_SID="$2"
                shift 2
                ;;
            -h|--oracle-home)
                ORACLE_HOME="$2"
                shift 2
                ;;
            -b|--oracle-base)
                ORACLE_BASE="$2"
                shift 2
                ;;
            -v|--version)
                DB_VERSION="$2"
                shift 2
                ;;
            -t|--template)
                DB_TEMPLATE="$2"
                shift 2
                ;;
            -d|--data-dir)
                DATA_DIR="$2"
                shift 2
                ;;
            -r|--fra-dir)
                FRA_DIR="$2"
                shift 2
                ;;
            -m|--memory)
                MEMORY_MB="$2"
                shift 2
                ;;
            -c|--charset)
                CHARSET="$2"
                shift 2
                ;;
            -n|--ncharset)
                NCHARSET="$2"
                shift 2
                ;;
            -p|--pdb-name)
                PDB_NAME="$2"
                shift 2
                ;;
            --domain)
                DB_DOMAIN="$2"
                shift 2
                ;;
            --db-unique-name)
                DB_UNIQUE_NAME="$2"
                shift 2
                ;;
            --sys-password)
                SYS_PASSWORD="$2"
                shift 2
                ;;
            --system-password)
                SYSTEM_PASSWORD="$2"
                shift 2
                ;;
            --custom-template)
                CUSTOM_TEMPLATE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --show-templates)
                show_templates
                exit 0
                ;;
            -q|--quiet)
                export ORADBA_LOG_LEVEL="WARN"
                shift
                ;;
            --help)
                usage
                ;;
            *)
                oradba_log ERROR "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: validate_arguments
# Purpose.: Validate required arguments are provided
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: Error messages if validation fails
# ------------------------------------------------------------------------------
validate_arguments() {
    local errors=0
    
    # Check required arguments
    if [[ -z "${DB_SID}" ]]; then
        oradba_log ERROR "Database SID is required (--sid)"
        ((errors++))
    fi
    
    if [[ -z "${DB_VERSION}" ]]; then
        oradba_log ERROR "Oracle version is required (--version)"
        ((errors++))
    fi
    
    # Validate version
    if [[ -n "${DB_VERSION}" ]] && [[ ! "${DB_VERSION}" =~ ^(19c|26ai)$ ]]; then
        oradba_log ERROR "Invalid version: ${DB_VERSION} (must be 19c or 26ai)"
        ((errors++))
    fi
    
    # Validate template for version
    if [[ "${DB_VERSION}" == "19c" ]] && [[ "${DB_TEMPLATE}" == "free" ]]; then
        oradba_log ERROR "Template 'free' is not available for 19c"
        ((errors++))
    fi
    
    if [[ "${DB_VERSION}" == "26ai" ]] && [[ "${DB_TEMPLATE}" == "dataguard" ]]; then
        oradba_log ERROR "Template 'dataguard' is not available for 26ai"
        ((errors++))
    fi
    
    if (( errors > 0 )); then
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------
main() {
    # Initialize logging
    init_logging
    
    oradba_log INFO "OraDBA DBCA - Automated Database Creation v${VERSION}"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate arguments
    if ! validate_arguments; then
        oradba_log ERROR "Argument validation failed"
        echo ""
        oradba_log INFO "Use --help for usage information"
        exit 1
    fi
    
    # Set defaults for unspecified values
    DB_DOMAIN="${DB_DOMAIN:-$(detect_domain)}"
    DB_UNIQUE_NAME="${DB_UNIQUE_NAME:-${DB_SID}}"
    DATA_DIR="${DATA_DIR:-${ORACLE_BASE}/oradata/${DB_SID}}"
    FRA_DIR="${FRA_DIR:-${ORACLE_BASE}/fast_recovery_area/${DB_SID}}"
    
    # Prompt for passwords if not provided (only in interactive mode)
    if [[ -z "${SYS_PASSWORD}" ]] && [[ -t 0 ]]; then
        read -rs -p "Enter SYS password: " SYS_PASSWORD
        echo ""
    fi
    
    if [[ -z "${SYSTEM_PASSWORD}" ]] && [[ -t 0 ]]; then
        read -rs -p "Enter SYSTEM password: " SYSTEM_PASSWORD
        echo ""
    fi
    
    # Check if passwords are still empty
    if [[ -z "${SYS_PASSWORD}" ]] || [[ -z "${SYSTEM_PASSWORD}" ]]; then
        oradba_log ERROR "Passwords are required (use --sys-password and --system-password)"
        exit 1
    fi
    
    # Display configuration
    oradba_log INFO "Configuration:"
    oradba_log INFO "  Database SID: ${DB_SID}"
    oradba_log INFO "  Version: ${DB_VERSION}"
    oradba_log INFO "  Template: ${DB_TEMPLATE}"
    oradba_log INFO "  Domain: ${DB_DOMAIN}"
    oradba_log INFO "  Data Directory: ${DATA_DIR}"
    oradba_log INFO "  FRA Directory: ${FRA_DIR}"
    oradba_log INFO "  Memory: ${MEMORY_MB} MB"
    oradba_log INFO "  Character Set: ${CHARSET}"
    oradba_log INFO "  National Character Set: ${NCHARSET}"
    if [[ "${DB_TEMPLATE}" != "pluggable" ]]; then
        oradba_log INFO "  PDB Name: ${PDB_NAME}"
    fi
    echo ""
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    echo ""
    
    # Create directories
    if ! create_directories; then
        exit 1
    fi
    echo ""
    
    # Find template file
    local template_file
    if [[ -n "${CUSTOM_TEMPLATE}" ]]; then
        template_file="${CUSTOM_TEMPLATE}"
        if [[ ! -f "${template_file}" ]]; then
            oradba_log ERROR "Custom template not found: ${template_file}"
            exit 1
        fi
    else
        template_file="${DBCA_TEMPLATE_DIR}/${DB_VERSION}/dbca_${DB_VERSION}_${DB_TEMPLATE}.rsp"
        if [[ ! -f "${template_file}" ]]; then
            oradba_log ERROR "Template not found: ${template_file}"
            oradba_log ERROR "Available templates:"
            show_templates
            exit 1
        fi
    fi
    
    # Generate response file
    local response_file
    response_file="/tmp/dbca_${DB_SID}_$$.rsp"
    
    if ! substitute_variables "${template_file}" "${response_file}"; then
        exit 1
    fi
    echo ""
    
    # Dry run or execute
    if [[ "${DRY_RUN}" == "true" ]]; then
        oradba_log INFO "Dry run mode - response file generated: ${response_file}"
        oradba_log INFO "Would execute: dbca -silent -createDatabase -responseFile ${response_file}"
        echo ""
        oradba_log INFO "Response file preview:"
        echo "----------------------------------------"
        head -20 "${response_file}"
        echo "... (truncated)"
        echo "----------------------------------------"
        oradba_log INFO "Full response file: ${response_file}"
    else
        # Run DBCA
        if run_dbca "${response_file}"; then
            oradba_log SUCCESS "Database ${DB_SID} created successfully"
            echo ""
            oradba_log INFO "Next steps:"
            oradba_log INFO "  1. Check database status: . oraenv (select ${DB_SID})"
            oradba_log INFO "  2. Connect to database: sqlplus / as sysdba"
            oradba_log INFO "  3. Check CDB/PDB status: show pdbs"
        else
            oradba_log ERROR "Failed to create database ${DB_SID}"
            oradba_log ERROR "Response file preserved: ${response_file}"
            exit 1
        fi
        
        # Cleanup response file on success
        if [[ -f "${response_file}" ]]; then
            rm -f "${response_file}"
        fi
    fi
    
    echo ""
    oradba_log INFO "DBCA operation completed"
    return 0
}

# Execute main
main "$@"
