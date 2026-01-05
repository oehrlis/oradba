#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_rman.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.13.7
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
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    source "${ORADBA_BASE}/lib/common.sh"
else
    echo "ERROR: Cannot find common.sh library" >&2
    exit 3
fi

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SCRIPT_LOG="${ORADBA_LOG:-/var/log/oracle}/${SCRIPT_NAME%.sh}_${TIMESTAMP}.log"
TEMP_DIR="${TMPDIR:-/tmp}/oradba_rman_$$"
FAILED_SIDS=()
SUCCESSFUL_SIDS=()
PARALLEL_METHOD="background"  # background or gnu_parallel

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
    --format <path>          Backup format string (default: from config)
    --tag <name>             Backup tag name (default: from config)
    --compression <level>    Compression level: LOW|MEDIUM|HIGH (default: from config)
    --backup-path <path>     Backup destination path (default: from config)
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
        RMAN_FORMAT            Backup format string
        RMAN_TAG               Default backup tag
        RMAN_COMPRESSION       Compression level
        RMAN_BACKUP_PATH       Backup destination path (CLI overrides config)
        RMAN_CATALOG           RMAN catalog connection
        RMAN_LOG_DIR           Log directory (default: \${ORADBA_ORA_ADMIN_SID}/log)
        RMAN_NOTIFY_EMAIL      Email for notifications
        RMAN_NOTIFY_ON_SUCCESS Enable success notifications
        RMAN_NOTIFY_ON_ERROR   Enable error notifications

TEMPLATE TAGS
    RMAN scripts support template processing with these tags:
    
    <ALLOCATE_CHANNELS>      Replaced with ALLOCATE CHANNEL commands
    <FORMAT>                 Replaced with FORMAT clause
    <TAG>                    Replaced with TAG clause
    <COMPRESSION>            Replaced with COMPRESSED BACKUPSET clause
    <BACKUP_PATH>            Replaced with backup destination path

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
# Use common.sh's unified log() function with optional file logging
# Enable verbose mode for DEBUG level logging
if [[ "${OPT_VERBOSE}" == "true" ]]; then
    export ORADBA_LOG_LEVEL=DEBUG
fi

# Enable file logging to script log
export ORADBA_LOG_FILE="${SCRIPT_LOG}"

# ------------------------------------------------------------------------------
# Check for GNU parallel availability
# ------------------------------------------------------------------------------
check_parallel_method() {
    if [[ "${OPT_PARALLEL}" == "gnu" ]]; then
        if command -v parallel >/dev/null 2>&1; then
            PARALLEL_METHOD="gnu_parallel"
            log INFO "Using GNU parallel for execution"
        else
            log WARN "GNU parallel not found, falling back to background jobs"
            PARALLEL_METHOD="background"
        fi
    else
        PARALLEL_METHOD="background"
        log DEBUG "Using background jobs for execution"
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
        log WARN "Cannot determine admin directory for ${sid}, using defaults"
        return 1
    fi
    
    if [[ -f "${config_file}" ]]; then
        log DEBUG "Loading RMAN configuration from: ${config_file}"
        # shellcheck source=/dev/null
        source "${config_file}"
        
        # Set backup path if specified in config (CLI overrides config)
        if [[ -z "${OPT_BACKUP_PATH}" && -n "${RMAN_BACKUP_PATH}" ]]; then
            OPT_BACKUP_PATH="${RMAN_BACKUP_PATH}"
            log DEBUG "Using backup path from config: ${OPT_BACKUP_PATH}"
        fi
        
        return 0
    else
        log DEBUG "No RMAN configuration file found: ${config_file}"
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
    local format="${4:-${RMAN_FORMAT:-/backup/%d_%T_%U.bkp}}"
    local tag="${5:-${RMAN_TAG:-BACKUP}}"
    local compression="${6:-${RMAN_COMPRESSION:-MEDIUM}}"
    local backup_path="${7:-${OPT_BACKUP_PATH}}"
    
    log DEBUG "Processing template: ${input_file}"
    log DEBUG "  Channels: ${channels}"
    log DEBUG "  Format: ${format}"
    log DEBUG "  Tag: ${tag}"
    log DEBUG "  Compression: ${compression}"
    [[ -n "${backup_path}" ]] && log DEBUG "  Backup Path: ${backup_path}"
    
    # Build channel allocation block
    local channel_block=""
    for ((i=1; i<=channels; i++)); do
        channel_block+="    ALLOCATE CHANNEL ch${i} DEVICE TYPE DISK;\n"
    done
    
    # Build format clause
    local format_clause="FORMAT '${format}'"
    
    # Build tag clause
    local tag_clause="TAG '${tag}'"
    
    # Build compression clause
    local compression_clause=""
    if [[ -n "${compression}" && "${compression}" != "NONE" ]]; then
        compression_clause="AS COMPRESSED BACKUPSET"
    fi
    
    # Build backup path clause (if specified)
    local backup_path_clause=""
    if [[ -n "${backup_path}" ]]; then
        backup_path_clause="${backup_path}"
    fi
    
    # Process the template
    sed -e "s|<ALLOCATE_CHANNELS>|${channel_block}|g" \
        -e "s|<FORMAT>|${format_clause}|g" \
        -e "s|<TAG>|${tag_clause}|g" \
        -e "s|<COMPRESSION>|${compression_clause}|g" \
        -e "s|<BACKUP_PATH>|${backup_path_clause}|g" \
        "${input_file}" > "${output_file}"
    
    log DEBUG "Template processed successfully: ${output_file}"
}

# ------------------------------------------------------------------------------
# Execute RMAN script for a single SID
# ------------------------------------------------------------------------------
execute_rman_for_sid() {
    local sid="$1"
    local rcv_script="$2"
    
    log INFO "Processing SID: ${sid}"
    
    # Set Oracle environment
    export ORACLE_SID="${sid}"
    export ORAENV_ASK=NO
    
    # Source oraenv if available
    if [[ -f /usr/local/bin/oraenv ]]; then
        # shellcheck source=/dev/null
        source /usr/local/bin/oraenv >/dev/null 2>&1
    elif [[ -f "${ORACLE_HOME}/bin/oraenv" ]]; then
        # shellcheck source=/dev/null
        source "${ORACLE_HOME}/bin/oraenv" >/dev/null 2>&1
    fi
    
    # Validate ORACLE_HOME
    if [[ -z "${ORACLE_HOME}" || ! -d "${ORACLE_HOME}" ]]; then
        log ERROR "ORACLE_HOME not set or invalid for SID: ${sid}"
        return 1
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
    mkdir -p "${log_dir}" 2>/dev/null || true
    
    # Generate log filename
    local script_basename
    script_basename=$(basename "${rcv_script}" .rcv)
    local sid_log="${log_dir}/${script_basename}_${TIMESTAMP}.log"
    
    log INFO "  ORACLE_HOME: ${ORACLE_HOME}"
    log INFO "  Log file: ${sid_log}"
    
    # Find RMAN script
    local rman_script=""
    if [[ -f "${rcv_script}" ]]; then
        rman_script="${rcv_script}"
    elif [[ -f "${ORADBA_BASE}/rcv/${rcv_script}" ]]; then
        rman_script="${ORADBA_BASE}/rcv/${rcv_script}"
    else
        log ERROR "RMAN script not found: ${rcv_script}"
        return 1
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
        log DEBUG "  Using RMAN catalog: ${RMAN_CATALOG}"
    fi
    
    # Dry run mode - enhanced with save and display
    if [[ "${OPT_DRY_RUN}" == "true" ]]; then
        # Save processed script to log directory
        local saved_rcv="${log_dir}/${script_basename}_${TIMESTAMP}.rcv"
        cp "${processed_script}" "${saved_rcv}"
        log INFO "DRY RUN: Processed script saved to: ${saved_rcv}"
        log INFO ""
        log INFO "========== Generated RMAN Script Content =========="
        cat "${processed_script}"
        log INFO "===================================================="
        log INFO ""
        log INFO "DRY RUN: Would execute:"
        log INFO "  ${rman_cmd} ${rman_args} @${processed_script} log=${sid_log}"
        return 0
    fi
    
    # Execute RMAN and capture output
    log INFO "  Executing RMAN script..."
    "${rman_cmd}" ${rman_args} @"${processed_script}" log="${sid_log}" 2>&1 | tee -a "${SCRIPT_LOG}"
    local rman_exit_code=${PIPESTATUS[0]}
    
    # Always save processed script to log directory for troubleshooting
    local saved_rcv="${log_dir}/${script_basename}_${TIMESTAMP}.rcv"
    cp "${processed_script}" "${saved_rcv}"
    log DEBUG "Processed script saved to: ${saved_rcv}"
    
    # Check for RMAN errors in log file
    if grep -q "RMAN-00569" "${sid_log}"; then
        log ERROR "  RMAN execution failed for ${sid}: RMAN-00569 error detected"
        log ERROR "  Check log: ${sid_log}"
        log ERROR "  Processed script: ${saved_rcv}"
        return 1
    elif [[ ${rman_exit_code} -ne 0 ]]; then
        log ERROR "  RMAN execution failed for ${sid}: exit code ${rman_exit_code}"
        log ERROR "  Check log: ${sid_log}"
        log ERROR "  Processed script: ${saved_rcv}"
        return 1
    else
        log INFO "  RMAN execution successful for ${sid}"
        log INFO "  Log: ${sid_log}"
        log INFO "  Processed script: ${saved_rcv}"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# Execute RMAN for multiple SIDs in parallel
# ------------------------------------------------------------------------------
execute_parallel_background() {
    local -a sids=("$@")
    local -a pids=()
    
    log INFO "Starting parallel execution (background jobs) for ${#sids[@]} SID(s)"
    
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
    log INFO "Waiting for ${#pids[@]} background job(s) to complete..."
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done
    
    log INFO "All background jobs completed"
}

# ------------------------------------------------------------------------------
# Execute RMAN for multiple SIDs using GNU parallel
# ------------------------------------------------------------------------------
execute_parallel_gnu() {
    local -a sids=("$@")
    
    log INFO "Starting parallel execution (GNU parallel) for ${#sids[@]} SID(s)"
    
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
    
    log INFO "GNU parallel execution completed"
}

# ------------------------------------------------------------------------------
# Send email notification
# ------------------------------------------------------------------------------
send_notification() {
    local status="$1"
    local email="${2:-${RMAN_NOTIFY_EMAIL}}"
    
    # Check if notifications are enabled
    if [[ -z "${email}" ]]; then
        log DEBUG "No email configured, skipping notification"
        return 0
    fi
    
    if [[ "${status}" == "SUCCESS" && "${RMAN_NOTIFY_ON_SUCCESS}" != "true" ]]; then
        log DEBUG "Success notifications disabled"
        return 0
    fi
    
    if [[ "${status}" == "ERROR" && "${RMAN_NOTIFY_ON_ERROR}" != "true" ]]; then
        log DEBUG "Error notifications disabled"
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
    if command -v mail >/dev/null 2>&1; then
        echo -e "${body}" | mail -s "${subject}" "${email}"
        log INFO "Notification sent to: ${email}"
    elif command -v sendmail >/dev/null 2>&1; then
        {
            echo "To: ${email}"
            echo "Subject: ${subject}"
            echo ""
            echo -e "${body}"
        } | sendmail -t
        log INFO "Notification sent to: ${email}"
    else
        log WARN "No mail command available, cannot send notification"
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
                OPT_PARALLEL="$2"
                shift 2
                ;;
            --backup-path)
                OPT_BACKUP_PATH="$2"
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
            -h|--help)
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
    log INFO "=========================================="
    log INFO "OraDBA RMAN Wrapper Starting"
    log INFO "=========================================="
    log INFO "Script: ${OPT_RCV_SCRIPT}"
    log INFO "SIDs: ${OPT_SIDS}"
    log INFO "Timestamp: ${TIMESTAMP}"
    [[ -n "${OPT_CHANNELS}" ]] && log INFO "Channels: ${OPT_CHANNELS}"
    [[ -n "${OPT_TAG}" ]] && log INFO "Tag: ${OPT_TAG}"
    [[ "${OPT_DRY_RUN}" == "true" ]] && log INFO "Mode: DRY RUN"
    log INFO ""
    
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
    log INFO ""
    log INFO "=========================================="
    log INFO "OraDBA RMAN Wrapper Summary"
    log INFO "=========================================="
    log INFO "Total SIDs: ${#SID_ARRAY[@]}"
    log INFO "Successful: ${#SUCCESSFUL_SIDS[@]}"
    log INFO "Failed: ${#FAILED_SIDS[@]}"
    
    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        log INFO "Failed SIDs: ${FAILED_SIDS[*]}"
    fi
    
    # Send notification
    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        send_notification "ERROR" "${OPT_NOTIFY_EMAIL}"
    else
        send_notification "SUCCESS" "${OPT_NOTIFY_EMAIL}"
    fi
    
    # Cleanup temporary directory (unless --no-cleanup flag is set)
    if [[ "${OPT_NO_CLEANUP}" == "true" ]]; then
        log INFO "Temporary files preserved in: ${TEMP_DIR}"
    else
        rm -rf "${TEMP_DIR}"
    fi
    
    # Exit with appropriate code
    if [[ ${#FAILED_SIDS[@]} -gt 0 ]]; then
        log INFO "Exiting with error code 1"
        exit 1
    else
        log INFO "Exiting with success code 0"
        exit 0
    fi
}

# Execute main function
main "$@"

# --- EOF ----------------------------------------------------------------------
