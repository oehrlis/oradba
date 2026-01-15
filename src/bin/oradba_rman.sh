#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_rman.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: RMAN wrapper script for automated backup/recovery operations
# Notes......: Supports parallel execution, template processing, and notifications
#              Configuration: ${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf
#              Logs: ${ORADBA_ORA_ADMIN_SID}/log/<script>_YYYYMMDD_HHMMSS.log
# Usage......: oradba_rman.sh --sid DB01 --rcv backup_full.rcv
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Script directory and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
ORADBA_BIN="${SCRIPT_DIR}"
ORADBA_BASE="$(dirname "${ORADBA_BIN}")"

# Source common functions
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    source "${ORADBA_BASE}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library" >&2
    exit 3
fi

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SCRIPT_LOG="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}_${TIMESTAMP}.log"

# Create log directory if it doesn't exist
LOG_DIR="$(dirname "${SCRIPT_LOG}")"
if [[ ! -d "${LOG_DIR}" ]]; then
    if ! mkdir -p "${LOG_DIR}" 2>/dev/null; then
        # If we can't create the default log directory, use temp directory
        SCRIPT_LOG="${TMPDIR:-/tmp}/${SCRIPT_NAME%.sh}_${TIMESTAMP}.log"
    fi
fi

TEMP_DIR="${TMPDIR:-/tmp}/oradba_rman_$$"
FAILED_SIDS=()
SUCCESSFUL_SIDS=()
PARALLEL_METHOD="background" # background or gnu_parallel

# Command-line parameters
OPT_SIDS=""
OPT_RCV_SCRIPT=""
OPT_CHANNELS=""
OPT_FORMAT=""
OPT_TAG=""
OPT_COMPRESSION=""
OPT_NOTIFY_EMAIL=""
OPT_PARALLEL="background"
OPT_DRY_RUN=false
OPT_VERBOSE=false
OPT_BACKUP_PATH=""
OPT_NO_CLEANUP=false
OPT_TABLESPACES=""
OPT_DATAFILES=""
OPT_PLUGGABLE_DATABASE=""

# ------------------------------------------------------------------------------
# Usage information
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} --sid <SID[,SID,...]> --rcv <script.rcv> [OPTIONS]

DESCRIPTION
    RMAN wrapper script for automated backup and recovery operations.
    Supports parallel execution across multiple databases, template processing
    for dynamic RMAN scripts, and email notifications on success/error.

REQUIRED ARGUMENTS
    --sid <SID[,SID,...]>    Oracle SID(s) to process (comma-separated for multiple)
    --rcv <script>           RMAN script to execute (.rcv extension)

OPTIONS
    --channels <n>           Number of allocation channels (default: from config)
    --format <pattern>       Backup format pattern (filename only, default: from config)
    --tag <name>             Backup tag name (default: from config)
    --compression <level>    Compression level: LOW|MEDIUM|HIGH (default: from config)
    --backup-path <path>     Backup destination path (if not set, uses Fast Recovery Area)
    --tablespaces <names>    Tablespace names (comma-separated, e.g., USERS,TOOLS)
    --datafiles <numbers>    Datafile numbers or paths (comma-separated, e.g., 1,2,3)
    --pdb <names>            Pluggable database names (comma-separated, e.g., PDB1,PDB2)
    --notify <email>         Email address for notifications (default: from config)
    --parallel <method>      Parallel method: background|gnu (default: background)
    --dry-run                Show what would be executed without running
    --no-cleanup             Keep temporary files after execution
    --verbose                Show detailed output
    -h, --help               Display this help message

CONFIGURATION
    Per-SID configuration file: \${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf
    
    Variables:
        RMAN_CHANNELS          Number of allocation channels
        RMAN_BACKUP_PATH       Backup destination path (if empty, uses Fast Recovery Area)
        RMAN_FORMAT            Backup format pattern (filename only, no path)
        RMAN_TAG               Default backup tag
        RMAN_COMPRESSION       Compression level
        RMAN_CATALOG           RMAN catalog connection
        RMAN_LOG_DIR           Log directory (default: \${ORADBA_ORA_ADMIN_SID}/log)
        RMAN_TABLESPACES       Tablespace names for selective backup
        RMAN_DATAFILES         Datafile numbers/paths for selective backup
        RMAN_PLUGGABLE_DATABASE  PDB names for container database backups
        RMAN_NOTIFY_EMAIL      Email for notifications
        RMAN_NOTIFY_ON_SUCCESS Enable success notifications
        RMAN_NOTIFY_ON_ERROR   Enable error notifications

TEMPLATE TAGS
    RMAN scripts support template processing with these tags:
    
    <ALLOCATE_CHANNELS>      Replaced with ALLOCATE CHANNEL commands
    <RELEASE_CHANNELS>       Replaced with RELEASE CHANNEL commands
    <FORMAT>                 Replaced with FORMAT clause
    <TAG>                    Replaced with TAG clause
    <COMPRESSION>            Replaced with COMPRESSED BACKUPSET clause
    <BACKUP_PATH>            Replaced with backup path (or \${ORADBA_ORA_ADMIN_SID}/backup/)
    <ORACLE_SID>             Replaced with current Oracle SID
    <START_DATE>             Replaced with timestamp (YYYYMMDD_HHMMSS)
    <SPFILE_BACKUP>          Replaced with pfile creation command (or removed if disabled)
    <BACKUP_KEEP_TIME>       Replaced with KEEP clause for long-term retention
    <RESTORE_POINT>          Replaced with restore point creation command

LOGGING
    Script log:  \${ORADBA_LOG}/oradba_rman_<timestamp>.log
    SID logs:    \${ORADBA_ORA_ADMIN_SID}/log/<script>_<timestamp>.log

EXIT CODES
    0    All operations successful
    1    One or more operations failed
    2    Invalid usage or arguments
    3    Critical error (cannot start)

EXAMPLES
    # Single database backup
    ${SCRIPT_NAME} --sid DB01 --rcv backup_full.rcv

    # Multiple databases in parallel
    ${SCRIPT_NAME} --sid DB01,DB02 --rcv backup_full.rcv --channels 4

    # With custom backup tag and notification
    ${SCRIPT_NAME} --sid PROD --rcv backup_full.rcv --tag DAILY --notify dba@example.com

    # With custom backup path
    ${SCRIPT_NAME} --sid PROD --rcv backup_full.rcv --backup-path /backup/prod

    # Backup specific tablespaces
    ${SCRIPT_NAME} --sid PROD --rcv bck_inc0_ts.rcv --tablespaces USERS,TOOLS

    # Backup specific datafiles
    ${SCRIPT_NAME} --sid PROD --rcv bck_inc0_df.rcv --datafiles 1,2,3

    # Backup specific pluggable databases
    ${SCRIPT_NAME} --sid CDB1 --rcv bck_inc0_pdb.rcv --pdb PDB1,PDB2

    # Dry run to see what would be executed (saves and displays script)
    ${SCRIPT_NAME} --sid DB01 --rcv backup_full.rcv --dry-run

    # Keep temporary files for troubleshooting
    ${SCRIPT_NAME} --sid DB01 --rcv backup_full.rcv --no-cleanup

    # Use GNU parallel if available
    ${SCRIPT_NAME} --sid DB01,DB02,DB03 --rcv backup_full.rcv --parallel gnu

SEE ALSO
    rmanc, rmanh, rmanch - RMAN connection aliases
    doc/09-rman-scripts.md - RMAN script documentation

EOF
}

# ------------------------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------------------------
# Use oradba_common.sh's unified oradba_log() function with optional file logging
# Enable file logging to script log
export ORADBA_LOG_FILE="${SCRIPT_LOG}"

# ------------------------------------------------------------------------------
# Check for GNU parallel availability
# ------------------------------------------------------------------------------
check_parallel_method() {
    if [[ "${OPT_PARALLEL}" == "gnu" ]]; then
        if command -v parallel > /dev/null 2>&1; then
            PARALLEL_METHOD="gnu_parallel"
            oradba_log INFO "Using GNU parallel for execution"
        else
            oradba_log WARN "GNU parallel not found, falling back to background jobs"
            PARALLEL_METHOD="background"
        fi
    else
        PARALLEL_METHOD="background"
        oradba_log DEBUG "Using background jobs for execution"
    fi
}

# ------------------------------------------------------------------------------
# Load SID-specific RMAN configuration
# ------------------------------------------------------------------------------
load_rman_config() {
    local sid="$1"
    local config_file

    # Determine admin directory
    if [[ -n "${ORADBA_ORA_ADMIN_SID}" ]]; then
        config_file="${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf"
    elif [[ -n "${ORACLE_BASE}" ]]; then
        config_file="${ORACLE_BASE}/admin/${sid}/etc/oradba_rman.conf"
    else
        oradba_log WARN "Cannot determine admin directory for ${sid}, using defaults"
        return 1
    fi

    if [[ -f "${config_file}" ]]; then
        oradba_log DEBUG "Loading RMAN configuration from: ${config_file}"
        # shellcheck source=/dev/null
        source "${config_file}"

        # Set backup path if specified in config (CLI overrides config)
        if [[ -z "${OPT_BACKUP_PATH}" && -n "${RMAN_BACKUP_PATH}" ]]; then
            OPT_BACKUP_PATH="${RMAN_BACKUP_PATH}"
            oradba_log DEBUG "Using backup path from config: ${OPT_BACKUP_PATH}"
        fi

        return 0
    else
        oradba_log DEBUG "No RMAN configuration file found: ${config_file}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Process template tags in RMAN script
# ------------------------------------------------------------------------------
process_template() {
    local input_file="$1"
    local output_file="$2"
    local channels="${3:-${RMAN_CHANNELS:-2}}"
    local format="${4:-${RMAN_FORMAT:-%d_%T_%U.bkp}}"
    local tag="${5:-${RMAN_TAG:-BACKUP}}"
    local compression="${6:-${RMAN_COMPRESSION:-MEDIUM}}"
    local backup_path="${7:-${OPT_BACKUP_PATH:-${RMAN_BACKUP_PATH}}}"

    oradba_log DEBUG "Processing template: ${input_file}"
    oradba_log DEBUG "  Channels: ${channels}"
    oradba_log DEBUG "  Format: ${format}"
    oradba_log DEBUG "  Tag: ${tag}"
    oradba_log DEBUG "  Compression: ${compression}"
    [[ -n "${backup_path}" ]] && oradba_log DEBUG "  Backup Path: ${backup_path}"

    # Check if input file exists, or create a dummy template for dry-run mode
    if [[ ! -f "${input_file}" ]]; then
        if [[ "${OPT_DRY_RUN}" == "true" ]]; then
            oradba_log DEBUG "Input file missing in dry-run mode, creating dummy template"
            # Create a minimal dummy template for dry-run processing
            cat > "${input_file}" <<'EOF'
# Dummy RMAN template for dry-run mode
RUN {
    <ALLOCATE_CHANNELS>
    BACKUP <COMPRESSION> DATABASE <FORMAT> <TAG>;
    <RELEASE_CHANNELS>
}
EOF
        else
            oradba_log ERROR "Template file not found: ${input_file}"
            return 1
        fi
    fi

    # Build channel allocation block
    local channel_block=""
    for ((i = 1; i <= channels; i++)); do
        channel_block+="ALLOCATE CHANNEL ch${i} DEVICE TYPE DISK;"$'\n'
    done
    # Remove trailing newline
    channel_block="${channel_block%$'\n'}"

    # Build channel release block
    local release_block=""
    for ((i = 1; i <= channels; i++)); do
        release_block+="RELEASE CHANNEL ch${i};"$'\n'
    done
    # Remove trailing newline
    release_block="${release_block%$'\n'}"

    # Build format clause
    # If backup_path is set, combine it with format; otherwise use format only (FRA)
    local format_clause
    if [[ -n "${backup_path}" ]]; then
        # Ensure trailing slash
        [[ "${backup_path}" != */ ]] && backup_path="${backup_path}/"
        format_clause="FORMAT '${backup_path}${format}'"
    else
        # No path specified - RMAN will use Fast Recovery Area
        format_clause="FORMAT '${format}'"
    fi

    # Build tag clause
    local tag_clause="TAG '${tag}'"

    # Build compression clause
    local compression_clause=""
    if [[ -n "${compression}" && "${compression}" != "NONE" ]]; then
        compression_clause="AS COMPRESSED BACKUPSET"
    fi

    # Build backup path for SQL commands (with trailing slash)
    # If no path specified, use admin backup directory for text files
    local backup_path_tag
    if [[ -n "${backup_path}" ]]; then
        # User specified a path - use it for both RMAN and SQL commands
        backup_path_tag="${backup_path}"
        [[ "${backup_path_tag}" != */ ]] && backup_path_tag="${backup_path_tag}/"
    else
        # No path specified - use admin backup directory for SQL-generated files
        # RMAN FORMAT will use FRA, but SQL commands need a filesystem path
        if [[ -z "${ORADBA_ORA_ADMIN_SID}" ]]; then
            oradba_log ERROR "ORADBA_ORA_ADMIN_SID not set - cannot determine backup directory"
            return 1
        fi
        backup_path_tag="${ORADBA_ORA_ADMIN_SID}/backup/"

        # Create backup directory if it doesn't exist
        if [[ ! -d "${ORADBA_ORA_ADMIN_SID}/backup" ]]; then
            oradba_log DEBUG "Creating backup directory: ${ORADBA_ORA_ADMIN_SID}/backup"
            mkdir -p "${ORADBA_ORA_ADMIN_SID}/backup" || {
                oradba_log ERROR "Failed to create backup directory: ${ORADBA_ORA_ADMIN_SID}/backup"
                return 1
            }
        fi
    fi

    # Build timestamp for file naming
    local start_date
    start_date="$(date '+%Y%m%d_%H%M%S')"

    # Get Oracle SID
    local oracle_sid="${ORACLE_SID:-ORCL}"

    # Build SET commands block (Option 3: Hybrid approach)
    local set_commands=""
    if [[ -n "${RMAN_SET_COMMANDS_FILE}" && -f "${RMAN_SET_COMMANDS_FILE}" ]]; then
        # Use external file
        set_commands="@${RMAN_SET_COMMANDS_FILE}"
        oradba_log DEBUG "  Using SET commands file: ${RMAN_SET_COMMANDS_FILE}"
    elif [[ -n "${RMAN_SET_COMMANDS_INLINE}" ]]; then
        # Use inline commands
        set_commands="${RMAN_SET_COMMANDS_INLINE}"
        oradba_log DEBUG "  Using inline SET commands"
    fi

    # Build TABLESPACES clause (comma-separated list)
    local tablespaces_clause=""
    local tablespaces="${OPT_TABLESPACES:-${RMAN_TABLESPACES}}"
    if [[ -n "${tablespaces}" ]]; then
        # Convert comma-separated list to RMAN format: TABLESPACE ts1, ts2, ts3
        tablespaces_clause="TABLESPACE ${tablespaces//,/, }"
        oradba_log DEBUG "  Tablespaces: ${tablespaces}"
    fi

    # Build DATAFILES clause (comma-separated numbers or paths)
    local datafiles_clause=""
    local datafiles="${OPT_DATAFILES:-${RMAN_DATAFILES}}"
    if [[ -n "${datafiles}" ]]; then
        # Convert comma-separated list to RMAN format: DATAFILE 1, 2, 3 or '/path1', '/path2'
        # Check if first item looks like a path (contains /)
        if [[ "${datafiles}" == */* ]]; then
            # Quoted paths
            datafiles_clause="DATAFILE ${datafiles//,/, }"
        else
            # Numeric IDs
            datafiles_clause="DATAFILE ${datafiles//,/, }"
        fi
        oradba_log DEBUG "  Datafiles: ${datafiles}"
    fi

    # Build PLUGGABLE DATABASE clause (CLI overrides config)
    local pluggable_database_clause=""
    local pluggable_database="${OPT_PLUGGABLE_DATABASE:-${RMAN_PLUGGABLE_DATABASE}}"
    if [[ -n "${pluggable_database}" ]]; then
        pluggable_database_clause="PLUGGABLE DATABASE ${pluggable_database//,/, }"
        oradba_log DEBUG "  Pluggable Databases: ${pluggable_database}"
    fi

    # Build SECTION SIZE clause (replaces full BACKUP command segment)
    # If set: "SECTION SIZE 10G" - otherwise empty for regular backup
    local section_size_clause=""
    if [[ -n "${RMAN_SECTION_SIZE}" ]]; then
        section_size_clause="SECTION SIZE ${RMAN_SECTION_SIZE}"
        oradba_log DEBUG "  Section Size: ${RMAN_SECTION_SIZE}"
    fi

    # Build ARCHIVE RANGE clause
    local archive_range="${RMAN_ARCHIVE_RANGE:-ALL}"
    oradba_log DEBUG "  Archive Range: ${archive_range}"

    # Build ARCHIVE PATTERN clause
    local archive_pattern_clause=""
    if [[ -n "${RMAN_ARCHIVE_PATTERN}" ]]; then
        archive_pattern_clause="${RMAN_ARCHIVE_PATTERN}"
        oradba_log DEBUG "  Archive Pattern: ${RMAN_ARCHIVE_PATTERN}"
    fi

    # Build RESYNC CATALOG clause
    local resync_catalog_clause=""
    if [[ "${RMAN_RESYNC_CATALOG}" == "true" && -n "${RMAN_CATALOG}" ]]; then
        resync_catalog_clause="RESYNC CATALOG;"
        oradba_log DEBUG "  Catalog Resync: Enabled"
    else
        # Comment out the resync command
        resync_catalog_clause="# RESYNC CATALOG;"
    fi

    # Build custom parameter clauses
    local custom_param_1="${RMAN_CUSTOM_PARAM_1:-}"
    local custom_param_2="${RMAN_CUSTOM_PARAM_2:-}"
    local custom_param_3="${RMAN_CUSTOM_PARAM_3:-}"
    [[ -n "${custom_param_1}" ]] && oradba_log DEBUG "  Custom Param 1: ${custom_param_1}"
    [[ -n "${custom_param_2}" ]] && oradba_log DEBUG "  Custom Param 2: ${custom_param_2}"
    [[ -n "${custom_param_3}" ]] && oradba_log DEBUG "  Custom Param 3: ${custom_param_3}"

    # Build SPFILE backup command (pfile creation)
    local spfile_backup_clause=""
    local spfile_backup_enabled="${RMAN_SPFILE_BACKUP:-true}"
    if [[ "${spfile_backup_enabled}" == "true" ]]; then
        # Use single quotes to avoid sed quoting issues - RMAN accepts either
        spfile_backup_clause="sql 'create pfile=''${backup_path_tag}init_${oracle_sid}_${start_date}'' from spfile';"
        oradba_log DEBUG "  SPFILE Backup: Enabled"
    else
        oradba_log DEBUG "  SPFILE Backup: Disabled"
    fi

    # Build BACKUP_KEEP_TIME clause
    local backup_keep_time="${RMAN_BACKUP_KEEP_TIME:-}"
    [[ -n "${backup_keep_time}" ]] && oradba_log DEBUG "  Backup Keep Time: ${backup_keep_time}"

    # Build RESTORE_POINT clause
    local restore_point="${RMAN_RESTORE_POINT:-}"
    [[ -n "${restore_point}" ]] && oradba_log DEBUG "  Restore Point: ${restore_point}"

    # Process the template
    # Use @ as delimiter instead of / to avoid conflicts with file paths
    if [[ "${spfile_backup_enabled}" == "true" ]]; then
        # SPFILE backup enabled - substitute the tag with the command
        sed -e "s@<SPFILE_BACKUP>@${spfile_backup_clause}@g" \
            -e "s@<ALLOCATE_CHANNELS>@${channel_block}@g" \
            -e "s@<RELEASE_CHANNELS>@${release_block}@g" \
            -e "s@<FORMAT>@${format_clause}@g" \
            -e "s@<TAG>@${tag_clause}@g" \
            -e "s@<COMPRESSION>@${compression_clause}@g" \
            -e "s@<BACKUP_PATH>@${backup_path_tag}@g" \
            -e "s@<BCK_PATH>@${backup_path_tag}@g" \
            -e "s@<ORACLE_SID>@${oracle_sid}@g" \
            -e "s@<START_DATE>@${start_date}@g" \
            -e "s@#<SET_COMMANDS>@${set_commands}@g" \
            -e "s@<SET_COMMANDS>@${set_commands}@g" \
            -e "s@<TABLESPACES>@${tablespaces_clause}@g" \
            -e "s@<DATAFILES>@${datafiles_clause}@g" \
            -e "s@<PLUGGABLE_DATABASE>@${pluggable_database_clause}@g" \
            -e "s@<SECTION_SIZE>@${section_size_clause}@g" \
            -e "s@<ARCHIVE_RANGE>@${archive_range}@g" \
            -e "s@<ARCHIVE_PATTERN>@${archive_pattern_clause}@g" \
            -e "s@<RESYNC_CATALOG>@${resync_catalog_clause}@g" \
            -e "s@<BACKUP_KEEP_TIME>@${backup_keep_time}@g" \
            -e "s@<RESTORE_POINT>@${restore_point}@g" \
            -e "s@<CUSTOM_PARAM_1>@${custom_param_1}@g" \
            -e "s@<CUSTOM_PARAM_2>@${custom_param_2}@g" \
            -e "s@<CUSTOM_PARAM_3>@${custom_param_3}@g" \
            "${input_file}" > "${output_file}"
    else
        # SPFILE backup disabled - remove lines containing the tag
        sed -e "/<SPFILE_BACKUP>/d" \
            -e "s@<ALLOCATE_CHANNELS>@${channel_block}@g" \
            -e "s@<RELEASE_CHANNELS>@${release_block}@g" \
            -e "s@<FORMAT>@${format_clause}@g" \
            -e "s@<TAG>@${tag_clause}@g" \
            -e "s@<COMPRESSION>@${compression_clause}@g" \
            -e "s@<BACKUP_PATH>@${backup_path_tag}@g" \
            -e "s@<BCK_PATH>@${backup_path_tag}@g" \
            -e "s@<ORACLE_SID>@${oracle_sid}@g" \
            -e "s@<START_DATE>@${start_date}@g" \
            -e "s@#<SET_COMMANDS>@${set_commands}@g" \
            -e "s@<SET_COMMANDS>@${set_commands}@g" \
            -e "s@<TABLESPACES>@${tablespaces_clause}@g" \
            -e "s@<DATAFILES>@${datafiles_clause}@g" \
            -e "s@<PLUGGABLE_DATABASE>@${pluggable_database_clause}@g" \
            -e "s@<SECTION_SIZE>@${section_size_clause}@g" \
            -e "s@<ARCHIVE_RANGE>@${archive_range}@g" \
            -e "s@<ARCHIVE_PATTERN>@${archive_pattern_clause}@g" \
            -e "s@<RESYNC_CATALOG>@${resync_catalog_clause}@g" \
            -e "s@<BACKUP_KEEP_TIME>@${backup_keep_time}@g" \
            -e "s@<RESTORE_POINT>@${restore_point}@g" \
            -e "s@<CUSTOM_PARAM_1>@${custom_param_1}@g" \
            -e "s@<CUSTOM_PARAM_2>@${custom_param_2}@g" \
            -e "s@<CUSTOM_PARAM_3>@${custom_param_3}@g" \
            "${input_file}" > "${output_file}"
    fi

    oradba_log DEBUG "Template processed successfully: ${output_file}"
}

# ------------------------------------------------------------------------------
# Execute RMAN script for a single SID
# ------------------------------------------------------------------------------
execute_rman_for_sid() {
    local sid="$1"
    local rcv_script="$2"

    oradba_log INFO "Processing SID:     ${sid}"

    # Set Oracle environment using OraDBA oraenv.sh wrapper
    export ORACLE_SID="${sid}"
    if [[ -f "${ORADBA_BIN}/oraenv.sh" ]]; then
        # shellcheck source=oraenv.sh
        source "${ORADBA_BIN}/oraenv.sh" "${sid}" > /dev/null 2>&1
    else
        oradba_log ERROR "Cannot source oraenv.sh for ${sid}"
        return 1
    fi

    # Validate ORACLE_HOME (skip in dry-run mode for test environments)
    if [[ -z "${ORACLE_HOME}" || ! -d "${ORACLE_HOME}" ]]; then
        if [[ "${OPT_DRY_RUN}" == "true" ]]; then
            oradba_log WARN "ORACLE_HOME not set or invalid for SID: ${sid} (dry-run mode)"
            # In dry-run mode, use a dummy ORACLE_HOME for validation
            export ORACLE_HOME="/opt/oracle/product/dummy"
        else
            oradba_log ERROR "ORACLE_HOME not set or invalid for SID: ${sid}"
            return 1
        fi
    fi

    # Set ORADBA_ORA_ADMIN_SID if not already set (needed for template processing)
    if [[ -z "${ORADBA_ORA_ADMIN_SID}" && -n "${ORACLE_BASE}" ]]; then
        export ORADBA_ORA_ADMIN_SID="${ORACLE_BASE}/admin/${sid}"
        oradba_log DEBUG "Set ORADBA_ORA_ADMIN_SID to: ${ORADBA_ORA_ADMIN_SID}"
    elif [[ -z "${ORADBA_ORA_ADMIN_SID}" && "${OPT_DRY_RUN}" == "true" ]]; then
        # In dry-run mode without ORACLE_BASE, use a dummy path
        export ORADBA_ORA_ADMIN_SID="${ORADBA_BASE}/admin/${sid}"
        oradba_log DEBUG "Dry-run mode: Set ORADBA_ORA_ADMIN_SID to: ${ORADBA_ORA_ADMIN_SID}"
    fi

    # Validate admin directory exists (create if needed in dry-run mode)
    if [[ -n "${ORADBA_ORA_ADMIN_SID}" && ! -d "${ORADBA_ORA_ADMIN_SID}" ]]; then
        if [[ "${OPT_DRY_RUN}" == "true" ]]; then
            oradba_log DEBUG "Creating admin directory for dry-run: ${ORADBA_ORA_ADMIN_SID}"
            mkdir -p "${ORADBA_ORA_ADMIN_SID}/log" "${ORADBA_ORA_ADMIN_SID}/backup" || {
                oradba_log WARN "Cannot create admin directory in dry-run mode: ${ORADBA_ORA_ADMIN_SID}"
            }
        else
            oradba_log ERROR "Admin directory does not exist: ${ORADBA_ORA_ADMIN_SID}"
            oradba_log ERROR "Expected structure: \${ORACLE_BASE}/admin/${sid}"
            return 1
        fi
    fi

    # Load SID-specific configuration
    load_rman_config "${sid}"

    # Determine log directory
    local log_dir
    if [[ -n "${RMAN_LOG_DIR}" ]]; then
        log_dir="${RMAN_LOG_DIR}"
    elif [[ -n "${ORADBA_ORA_ADMIN_SID}" ]]; then
        log_dir="${ORADBA_ORA_ADMIN_SID}/log"
    elif [[ -n "${ORACLE_BASE}" ]]; then
        log_dir="${ORACLE_BASE}/admin/${sid}/log"
    else
        log_dir="${ORADBA_LOG:-/var/log/oracle}"
    fi

    # Create log directory if needed
    mkdir -p "${log_dir}" 2> /dev/null || true

    # Generate log filename
    local script_basename
    script_basename=$(basename "${rcv_script}" .rcv)
    local sid_log="${log_dir}/${script_basename}_${TIMESTAMP}.log"

    oradba_log INFO "  ORACLE_HOME:      ${ORACLE_HOME}"
    oradba_log INFO "  Log file:         ${sid_log}"

    # Find RMAN script (more lenient in dry-run mode)
    local rman_script=""
    if [[ -f "${rcv_script}" ]]; then
        rman_script="${rcv_script}"
    elif [[ -f "${ORADBA_BASE}/rcv/${rcv_script}" ]]; then
        rman_script="${ORADBA_BASE}/rcv/${rcv_script}"
    else
        if [[ "${OPT_DRY_RUN}" == "true" ]]; then
            oradba_log WARN "RMAN script not found: ${rcv_script} (dry-run mode, continuing)"
            # In dry-run mode, use the specified path even if file doesn't exist
            rman_script="${rcv_script}"
        else
            oradba_log ERROR "RMAN script not found: ${rcv_script}"
            return 1
        fi
    fi

    # Process template to temporary file
    local processed_script="${TEMP_DIR}/${sid}_${script_basename}.rcv"
    process_template "${rman_script}" "${processed_script}" \
        "${OPT_CHANNELS}" "${OPT_FORMAT}" "${OPT_TAG}" "${OPT_COMPRESSION}"

    # Build RMAN command
    local rman_cmd="${ORACLE_HOME}/bin/rman"
    local rman_args="target /"

    # Add catalog if configured
    if [[ -n "${RMAN_CATALOG}" ]]; then
        rman_args+=" catalog ${RMAN_CATALOG}"
        oradba_log DEBUG "  Using RMAN catalog: ${RMAN_CATALOG}"
    fi

    # Dry run mode - enhanced with save and display
    if [[ "${OPT_DRY_RUN}" == "true" ]]; then
        # Save processed script to log directory
        local saved_rcv="${log_dir}/${script_basename}_${TIMESTAMP}.rcv"
        cp "${processed_script}" "${saved_rcv}"
        oradba_log INFO "DRY RUN: Processed script saved to: ${saved_rcv}"
        oradba_log INFO ""
        oradba_log INFO "========== Generated RMAN Script Content =========="
        cat "${processed_script}"
        oradba_log INFO "===================================================="
        oradba_log INFO ""
        oradba_log INFO "DRY RUN: Would execute:"
        oradba_log INFO "  ${rman_cmd} ${rman_args} @${processed_script} log=${sid_log}"
        return 0
    fi

    # Execute RMAN and capture output
    oradba_log INFO "  Executing RMAN script..."
    "${rman_cmd}" ${rman_args} @"${processed_script}" log="${sid_log}" 2>&1 | tee -a "${SCRIPT_LOG}"
    local rman_exit_code=${PIPESTATUS[0]}

    # Always save processed script to log directory for troubleshooting
    local saved_rcv="${log_dir}/${script_basename}_${TIMESTAMP}.rcv"
    cp "${processed_script}" "${saved_rcv}"
    oradba_log DEBUG "Processed script saved to: ${saved_rcv}"

    # Check for RMAN errors in log file
    if grep -q "RMAN-00569" "${sid_log}"; then
        oradba_log ERROR "  RMAN execution failed for ${sid}: RMAN-00569 error detected"
        oradba_log ERROR "  Check log: ${sid_log}"
        oradba_log ERROR "  Processed script: ${saved_rcv}"
        return 1
    elif [[ ${rman_exit_code} -ne 0 ]]; then
        oradba_log ERROR "  RMAN execution failed for ${sid}: exit code ${rman_exit_code}"
        oradba_log ERROR "  Check log: ${sid_log}"
        oradba_log ERROR "  Processed script: ${saved_rcv}"
        return 1
    else
        oradba_log INFO "  RMAN execution successful for ${sid}"
        oradba_log INFO "  Log:              ${sid_log}"
        oradba_log INFO "  Processed script: ${saved_rcv}"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# Execute RMAN for multiple SIDs in parallel
# ------------------------------------------------------------------------------
execute_parallel_background() {
    local -a sids=("$@")
    local -a pids=()

    oradba_log INFO "Starting parallel execution (background jobs) for ${#sids[@]} SID(s)"

    # Start background job for each SID
    for sid in "${sids[@]}"; do
        (
            if execute_rman_for_sid "${sid}" "${OPT_RCV_SCRIPT}"; then
                echo "${sid}" >> "${TEMP_DIR}/success.txt"
            else
                echo "${sid}" >> "${TEMP_DIR}/failed.txt"
            fi
        ) &
        pids+=($!)
    done

    # Wait for all jobs to complete
    oradba_log INFO "Waiting for ${#pids[@]} background job(s) to complete..."
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done

    oradba_log INFO "All background jobs completed"
}

# ------------------------------------------------------------------------------
# Execute RMAN for multiple SIDs using GNU parallel
# ------------------------------------------------------------------------------
execute_parallel_gnu() {
    local -a sids=("$@")

    oradba_log INFO "Starting parallel execution (GNU parallel) for ${#sids[@]} SID(s)"

    # Export function and variables for parallel
    export -f execute_rman_for_sid load_rman_config process_template
    export OPT_RCV_SCRIPT OPT_CHANNELS OPT_FORMAT OPT_TAG OPT_COMPRESSION OPT_DRY_RUN OPT_VERBOSE
    export ORADBA_BASE SCRIPT_LOG TEMP_DIR TIMESTAMP

    # Execute using GNU parallel
    printf '%s\n' "${sids[@]}" | parallel --will-cite "
        if execute_rman_for_sid {} '${OPT_RCV_SCRIPT}'; then
            echo {} >> ${TEMP_DIR}/success.txt
        else
            echo {} >> ${TEMP_DIR}/failed.txt
        fi
    "

    oradba_log INFO "GNU parallel execution completed"
}

# ------------------------------------------------------------------------------
# Send email notification
# ------------------------------------------------------------------------------
send_notification() {
    local status="$1"
    local email="${2:-${RMAN_NOTIFY_EMAIL}}"

    # Check if notifications are enabled
    if [[ -z "${email}" ]]; then
        oradba_log DEBUG "No email configured, skipping notification"
        return 0
    fi

    if [[ "${status}" == "SUCCESS" && "${RMAN_NOTIFY_ON_SUCCESS}" != "true" ]]; then
        oradba_log DEBUG "Success notifications disabled"
        return 0
    fi

    if [[ "${status}" == "ERROR" && "${RMAN_NOTIFY_ON_ERROR}" != "true" ]]; then
        oradba_log DEBUG "Error notifications disabled"
        return 0
    fi

    # Build email subject and body
    local subject
    subject="RMAN ${status}: ${OPT_RCV_SCRIPT} [$(hostname)]"
    local body=""

    body+="RMAN Operation Status: ${status}\n"
    body+="Script: ${OPT_RCV_SCRIPT}\n"
    body+="Timestamp: $(date '+%Y-%m-%d %H:%M:%S')\n"
    body+="Hostname: $(hostname)\n"
    body+="\n"

    if [[ ${#SUCCESSFUL_SIDS[@]} -gt 0 ]]; then
        body+="Successful SIDs (${#SUCCESSFUL_SIDS[@]}):\n"
        printf '  - %s\n' "${SUCCESSFUL_SIDS[@]}" >> "${body}"
    fi

    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        body+="Failed SIDs (${#FAILED_SIDS[@]}):\n"
        printf '  - %s\n' "${FAILED_SIDS[@]}" >> "${body}"
    fi

    body+="\nScript Log: ${SCRIPT_LOG}\n"

    # Send email using mail command
    if command -v mail > /dev/null 2>&1; then
        echo -e "${body}" | mail -s "${subject}" "${email}"
        oradba_log INFO "Notification sent to: ${email}"
    elif command -v sendmail > /dev/null 2>&1; then
        {
            echo "To: ${email}"
            echo "Subject: ${subject}"
            echo ""
            echo -e "${body}"
        } | sendmail -t
        oradba_log INFO "Notification sent to: ${email}"
    else
        oradba_log WARN "No mail command available, cannot send notification"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------
main() {
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sid)
                OPT_SIDS="$2"
                shift 2
                ;;
            --rcv)
                OPT_RCV_SCRIPT="$2"
                shift 2
                ;;
            --channels)
                OPT_CHANNELS="$2"
                shift 2
                ;;
            --format)
                OPT_FORMAT="$2"
                shift 2
                ;;
            --tag)
                OPT_TAG="$2"
                shift 2
                ;;
            --compression)
                OPT_COMPRESSION="$2"
                shift 2
                ;;
            --notify)
                OPT_NOTIFY_EMAIL="$2"
                shift 2
                ;;
            --parallel)
                case "$2" in
                    background|gnu)
                        OPT_PARALLEL="$2"
                        ;;
                    *)
                        echo "ERROR: Invalid parallel method: $2 (must be background or gnu)" >&2
                        exit 2
                        ;;
                esac
                shift 2
                ;;
            --backup-path)
                OPT_BACKUP_PATH="$2"
                shift 2
                ;;
            --tablespaces)
                OPT_TABLESPACES="$2"
                shift 2
                ;;
            --datafiles)
                OPT_DATAFILES="$2"
                shift 2
                ;;
            --pdb | --pluggable-database)
                OPT_PLUGGABLE_DATABASE="$2"
                shift 2
                ;;
            --dry-run)
                OPT_DRY_RUN=true
                shift
                ;;
            --no-cleanup)
                OPT_NO_CLEANUP=true
                shift
                ;;
            --verbose)
                OPT_VERBOSE=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                usage
                exit 2
                ;;
        esac
    done

    # Enable verbose mode for DEBUG level logging
    if [[ "${OPT_VERBOSE}" == "true" ]]; then
        export ORADBA_LOG_LEVEL=DEBUG
    fi

    # Validate required arguments
    if [[ -z "${OPT_SIDS}" ]]; then
        echo "ERROR: --sid is required" >&2
        usage
        exit 2
    fi

    if [[ -z "${OPT_RCV_SCRIPT}" ]]; then
        echo "ERROR: --rcv is required" >&2
        usage
        exit 2
    fi

    # Create temporary directory
    mkdir -p "${TEMP_DIR}" || {
        echo "ERROR: Cannot create temporary directory: ${TEMP_DIR}" >&2
        exit 3
    }

    # Initialize log
    oradba_log INFO "=========================================="
    oradba_log INFO "OraDBA RMAN Wrapper Starting"
    oradba_log INFO "=========================================="
    oradba_log INFO "Script:             ${OPT_RCV_SCRIPT}"
    oradba_log INFO "SIDs:               ${OPT_SIDS}"
    oradba_log INFO "Timestamp:          ${TIMESTAMP}"
    [[ -n "${OPT_CHANNELS}" ]] && oradba_log INFO "Channels:           ${OPT_CHANNELS}"
    [[ -n "${OPT_BACKUP_PATH}" ]] && oradba_log INFO "Backup Path:        ${OPT_BACKUP_PATH}"
    [[ -n "${OPT_PLUGGABLE_DATABASE}" ]] && oradba_log INFO "Pluggable Databases: ${OPT_PLUGGABLE_DATABASE}"
    [[ -n "${OPT_TABLESPACES}" ]] && oradba_log INFO "Tablespaces:        ${OPT_TABLESPACES}"
    [[ -n "${OPT_DATAFILES}" ]] && oradba_log INFO "Datafiles:          ${OPT_DATAFILES}"
    [[ -n "${OPT_FORMAT}" ]] && oradba_log INFO "Format:             ${OPT_FORMAT}"
    [[ -n "${OPT_COMPRESSION}" ]] && oradba_log INFO "Compression:        ${OPT_COMPRESSION}"
    [[ -n "${OPT_TAG}" ]] && oradba_log INFO "Tag:                ${OPT_TAG}"
    [[ -n "${OPT_PARALLEL}" ]] && oradba_log INFO "Parallel:           ${OPT_PARALLEL}"
    [[ -n "${OPT_NOTIFY_EMAIL}" ]] && oradba_log INFO "Notification Email: ${OPT_NOTIFY_EMAIL}"
    [[ "${OPT_DRY_RUN}" == "true" ]] && oradba_log INFO "Mode:               DRY RUN"
    oradba_log INFO ""

    # Check parallel method
    check_parallel_method

    # Split SIDs into array
    IFS=',' read -ra SID_ARRAY <<< "${OPT_SIDS}"

    # Execute based on number of SIDs
    if [[ ${#SID_ARRAY[@]} -eq 1 ]]; then
        # Single SID - execute directly
        if execute_rman_for_sid "${SID_ARRAY[0]}" "${OPT_RCV_SCRIPT}"; then
            SUCCESSFUL_SIDS+=("${SID_ARRAY[0]}")
        else
            FAILED_SIDS+=("${SID_ARRAY[0]}")
        fi
    else
        # Multiple SIDs - execute in parallel
        if [[ "${PARALLEL_METHOD}" == "gnu_parallel" ]]; then
            execute_parallel_gnu "${SID_ARRAY[@]}"
        else
            execute_parallel_background "${SID_ARRAY[@]}"
        fi

        # Read results
        [[ -f "${TEMP_DIR}/success.txt" ]] && mapfile -t SUCCESSFUL_SIDS < "${TEMP_DIR}/success.txt"
        [[ -f "${TEMP_DIR}/failed.txt" ]] && mapfile -t FAILED_SIDS < "${TEMP_DIR}/failed.txt"
    fi

    # Summary
    oradba_log INFO ""
    oradba_log INFO "=========================================="
    oradba_log INFO "OraDBA RMAN Wrapper Summary"
    oradba_log INFO "=========================================="
    oradba_log INFO "Total SIDs:    ${#SID_ARRAY[@]}"
    oradba_log INFO "Successful:    ${#SUCCESSFUL_SIDS[@]}"
    oradba_log INFO "Failed:        ${#FAILED_SIDS[@]}"

    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        oradba_log INFO "Failed SIDs: ${FAILED_SIDS[*]}"
    fi

    # Send notification
    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        send_notification "ERROR" "${OPT_NOTIFY_EMAIL}"
    else
        send_notification "SUCCESS" "${OPT_NOTIFY_EMAIL}"
    fi

    # Cleanup temporary directory (unless --no-cleanup flag is set)
    if [[ "${OPT_NO_CLEANUP}" == "true" ]]; then
        oradba_log INFO "Temporary files preserved in: ${TEMP_DIR}"
    else
        rm -rf "${TEMP_DIR}"
    fi

    # Exit with appropriate code
    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        oradba_log INFO "Exiting with error code 1"
        exit 1
    else
        oradba_log INFO "Exiting with success code 0"
        exit 0
    fi
}

# Execute main function
main "$@"

# --- EOF ----------------------------------------------------------------------
