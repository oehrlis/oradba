#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: common.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.14.0
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
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# ------------------------------------------------------------------------------
# Unified Logging System
# ------------------------------------------------------------------------------

# Initialize logging infrastructure
# Creates log directory and sets up log file paths
# Falls back to user home directory if system directory not writable
init_logging() {
    local log_dir="${ORADBA_LOG_DIR:-}"
    
    # Determine log directory
    if [[ -z "$log_dir" ]]; then
        if [[ -w "/var/log" ]]; then
            log_dir="/var/log/oradba"
        else
            log_dir="${HOME}/.oradba/logs"
        fi
    fi
    
    # Create directory if needed
    if [[ ! -d "$log_dir" ]]; then
        if ! mkdir -p "$log_dir" 2>/dev/null; then
            # Fallback to user directory if system location fails
            log_dir="${HOME}/.oradba/logs"
            mkdir -p "$log_dir" 2>/dev/null || {
                echo "[ERROR] Failed to create log directory: $log_dir" >&2
                return 1
            }
        fi
    fi
    
    export ORADBA_LOG_DIR="$log_dir"
    
    # Set main log file if not already set
    if [[ -z "${ORADBA_LOG_FILE:-}" ]]; then
        export ORADBA_LOG_FILE="${log_dir}/oradba.log"
    fi
    
    # Debug output (only if DEBUG level enabled)
    if [[ "${ORADBA_LOG_LEVEL:-INFO}" == "DEBUG" ]] || [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - Logging initialized: ${log_dir}" >&2
    fi
    
    return 0
}

# Initialize session logging
# Creates individual log file for current session with metadata header
init_session_log() {
    # Only create session log if enabled and logging is initialized
    if [[ "${ORADBA_SESSION_LOGGING:-false}" != "true" ]]; then
        return 0
    fi
    
    # Ensure logging directory exists
    local log_dir="${ORADBA_LOG_DIR:-}"
    if [[ -z "$log_dir" ]]; then
        init_logging || return 1
        log_dir="${ORADBA_LOG_DIR}"
    fi
    
    # Create session log file
    local session_log
    session_log="${log_dir}/session_$(date +%Y%m%d_%H%M%S)_$$.log"
    export ORADBA_SESSION_LOG="$session_log"
    
    # Write session header
    cat > "$session_log" <<EOF
# ------------------------------------------------------------------------------
# OraDBA Session Log
# ------------------------------------------------------------------------------
# Started....: $(date '+%Y-%m-%d %H:%M:%S')
# User.......: ${USER}
# Host.......: $(hostname)
# PID........: $$
# ORACLE_SID.: ${ORACLE_SID:-none}
# ORACLE_HOME: ${ORACLE_HOME:-none}
# ------------------------------------------------------------------------------

EOF
    
    # Set as primary log file for dual logging
    if [[ "${ORADBA_SESSION_LOG_ONLY:-false}" == "true" ]]; then
        export ORADBA_LOG_FILE="$session_log"
    fi
    
    return 0
}

# Color codes for TTY output (auto-detected)
# Prevent re-initialization of readonly variables (check if already defined)
if [[ -z "${LOG_COLOR_DEBUG+x}" ]]; then
    export ORADBA_COMMON_SOURCED="true"
    
    if [[ -t 2 ]] && [[ "${ORADBA_NO_COLOR:-0}" != "1" ]]; then
        # Colors enabled for TTY stderr
        readonly LOG_COLOR_DEBUG="\033[0;36m"     # Cyan
        readonly LOG_COLOR_INFO="\033[0;34m"      # Blue
        readonly LOG_COLOR_WARN="\033[0;33m"      # Yellow
        readonly LOG_COLOR_ERROR="\033[0;31m"     # Red
        readonly LOG_COLOR_SUCCESS="\033[0;32m"   # Green
        readonly LOG_COLOR_FAILURE="\033[1;31m"   # Bold Red
        readonly LOG_COLOR_SECTION="\033[1;37m"   # Bold White
        readonly LOG_COLOR_RESET="\033[0m"        # Reset
    else
        # No colors for non-TTY or when disabled
        readonly LOG_COLOR_DEBUG=""
        readonly LOG_COLOR_INFO=""
        readonly LOG_COLOR_WARN=""
        readonly LOG_COLOR_ERROR=""
        readonly LOG_COLOR_SUCCESS=""
        readonly LOG_COLOR_FAILURE=""
        readonly LOG_COLOR_SECTION=""
        readonly LOG_COLOR_RESET=""
    fi
fi  # End of readonly variables guard

# Unified logging function with level-based filtering
# Usage: oradba_log <LEVEL> <message>
# Levels: DEBUG, INFO, WARN, ERROR, SUCCESS, FAILURE, SECTION
# Environment variables:
#   ORADBA_LOG_LEVEL - Minimum log level (DEBUG|INFO|WARN|ERROR, default: INFO)
#   ORADBA_LOG_FILE - Optional log file path for persistent logging
#   ORADBA_NO_COLOR - Set to 1 to disable color output
#   DEBUG=1 - Legacy support, enables DEBUG level
# All output goes to stderr for clean separation from script output
oradba_log() {
    local level="$1"
    shift
    local message="$*"
    
    # Default log level is INFO if not set
    local min_level="${ORADBA_LOG_LEVEL:-INFO}"
    
    # Legacy DEBUG=1 support - if DEBUG is set, enable DEBUG level
    if [[ "${DEBUG:-0}" == "1" ]] && [[ "${min_level}" != "DEBUG" ]]; then
        min_level="DEBUG"
    fi
    
    # Convert levels to numeric values for comparison
    local level_value=0
    local min_level_value=0
    
    case "${level^^}" in
        DEBUG)   level_value=0 ;;
        INFO)    level_value=1 ;;
        WARN)    level_value=2 ;;
        ERROR)   level_value=3 ;;
        SUCCESS) level_value=1 ;; # Same as INFO
        FAILURE) level_value=3 ;; # Same as ERROR
        SECTION) level_value=1 ;; # Same as INFO
        *) level_value=1 ;; # Default to INFO for unknown levels
    esac
    
    case "${min_level^^}" in
        DEBUG) min_level_value=0 ;;
        INFO)  min_level_value=1 ;;
        WARN)  min_level_value=2 ;;
        ERROR) min_level_value=3 ;;
        *) min_level_value=1 ;; # Default to INFO
    esac
    
    # Only log if message level meets minimum threshold
    if [[ ${level_value} -ge ${min_level_value} ]]; then
        # Select color based on level
        local color=""
        case "${level^^}" in
            DEBUG)   color="${LOG_COLOR_DEBUG}" ;;
            INFO)    color="${LOG_COLOR_INFO}" ;;
            WARN)    color="${LOG_COLOR_WARN}" ;;
            ERROR)   color="${LOG_COLOR_ERROR}" ;;
            SUCCESS) color="${LOG_COLOR_SUCCESS}" ;;
            FAILURE) color="${LOG_COLOR_FAILURE}" ;;
            SECTION) color="${LOG_COLOR_SECTION}" ;;
        esac
        
        # Format log message
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        
        # Add caller information if enabled
        local log_line
        if [[ "${ORADBA_LOG_SHOW_CALLER:-false}" == "true" ]]; then
            local caller="${BASH_SOURCE[2]##*/}:${BASH_LINENO[1]}"
            log_line="[${level^^}] ${timestamp} [${caller}] - ${message}"
        else
            log_line="[${level^^}] ${timestamp} - ${message}"
        fi
        
        # Output to stderr with color if enabled
        if [[ -n "${color}" ]]; then
            echo -e "${color}${log_line}${LOG_COLOR_RESET}" >&2
        else
            echo "${log_line}" >&2
        fi
        
        # Optional file logging (without color codes)
        if [[ -n "${ORADBA_LOG_FILE:-}" ]]; then
            echo "${log_line}" >> "${ORADBA_LOG_FILE}"
        fi
        
        # Dual logging: also write to session log if different from main log
        if [[ -n "${ORADBA_SESSION_LOG:-}" ]] && [[ "${ORADBA_SESSION_LOG}" != "${ORADBA_LOG_FILE:-}" ]]; then
            echo "${log_line}" >> "${ORADBA_SESSION_LOG}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Deprecated Logging Functions (Backward Compatibility Wrappers)
# ------------------------------------------------------------------------------
# These functions are deprecated and will be removed in v0.14.0
# Use: oradba_log INFO "message" instead of log_info "message"
#      oradba_log WARN "message" instead of log_warn "message"
#      oradba_log ERROR "message" instead of log_error "message"
#      oradba_log DEBUG "message" instead of log_debug "message"
# ------------------------------------------------------------------------------

# Show deprecation warning if opt-in enabled
_show_deprecation_warning() {
    local func_name="$1"
    local new_syntax="$2"
    
    # Only show warnings if explicitly enabled
    if [[ "${ORADBA_SHOW_DEPRECATION_WARNINGS:-false}" == "true" ]]; then
        # Track if we've already shown this warning in this session
        local warning_var="ORADBA_DEPRECATION_SHOWN_${func_name}"
        if [[ "${!warning_var}" != "true" ]]; then
            echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - ${func_name}() is deprecated, use ${new_syntax} instead (see CHANGELOG v0.13.1)" >&2
            export "${warning_var}=true"
        fi
    fi
}

# Deprecated: log_info - use oradba_log INFO instead
log_info() {
    _show_deprecation_warning "log_info" "oradba_log INFO"
    oradba_log INFO "$*"
}

# Deprecated: log_warn - use oradba_log WARN instead
log_warn() {
    _show_deprecation_warning "log_warn" "oradba_log WARN"
    oradba_log WARN "$*"
}

# Deprecated: log_error - use oradba_log ERROR instead
log_error() {
    _show_deprecation_warning "log_error" "oradba_log ERROR"
    oradba_log ERROR "$*"
}

# Deprecated: log_debug - use oradba_log DEBUG instead
log_debug() {
    _show_deprecation_warning "log_debug" "oradba_log DEBUG"
    oradba_log DEBUG "$*"
}

# ------------------------------------------------------------------------------
# Function: execute_db_query
# Purpose.: Execute SQL*Plus query with standardized configuration and formatting
# Syntax..: execute_db_query <query> [format]
# Params..: query  - SQL query to execute (can be multiline)
#           format - Output format: 'raw' (default) or 'delimited'
# Returns.: Query results in specified format
# Note....: New in v0.13.2 - Eliminates SQL*Plus boilerplate duplication
# ------------------------------------------------------------------------------
execute_db_query() {
    local query="$1"
    local format="${2:-raw}"
    
    # Validate parameters
    if [[ -z "$query" ]]; then
        oradba_log ERROR "execute_db_query: No query provided"
        return 1
    fi
    
    # Validate format
    if [[ "$format" != "raw" ]] && [[ "$format" != "delimited" ]]; then
        oradba_log ERROR "execute_db_query: Invalid format '$format' (must be 'raw' or 'delimited')"
        return 1
    fi
    
    # Execute query with standard SQL*Plus configuration
    local result
    result=$(sqlplus -s / as sysdba 2>&1 << EOF
SET PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL
SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""
SET SERVEROUTPUT OFF TERMOUT ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
${query}
EXIT;
EOF
)
    
    local exit_code=$?
    
    # Check for SQL*Plus errors
    if [[ $exit_code -ne 0 ]]; then
        oradba_log DEBUG "execute_db_query: SQL*Plus exited with code $exit_code"
        return 1
    fi
    
    # Filter out SQL*Plus noise (errors, warnings, empty lines)
    result=$(echo "$result" | grep -v "^SP2-\|^ORA-\|^ERROR\|^no rows selected\|^Connected to:")
    
    # Process based on format
    case "$format" in
        raw)
            # Return raw output, trimmed
            echo "$result" | sed '/^[[:space:]]*$/d'
            ;;
        delimited)
            # Return pipe-delimited output, clean lines only
            echo "$result" | grep "|" | head -1
            ;;
    esac
    
    # Return success if we got any output
    [[ -n "$result" ]] && return 0 || return 1
}

# Check if current ORACLE_SID is a dummy database (oratab flag :D)
# Returns: 0 if dummy, 1 if not dummy or can't determine
is_dummy_sid() {
    local sid="${ORACLE_SID}"
    local oratab_file="${ORATAB:-/etc/oratab}"
    
    [[ -z "$sid" ]] && return 1
    [[ ! -f "$oratab_file" ]] && return 1
    
    # Check if SID exists in oratab with :D flag
    if grep -q "^${sid}:.*:D" "$oratab_file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Coexistence Mode Functions (TVD BasEnv / DB*Star)
# ------------------------------------------------------------------------------

# Detect if TVD BasEnv or DB*Star is active
# Checks for BE_HOME environment variable or .BE_HOME file in home directory
# Returns: 0 if detected, 1 if not detected
detect_basenv() {
    # Check if BE_HOME is already set
    if [[ -n "${BE_HOME}" ]]; then
        return 0
    fi
    
    # Check for .BE_HOME file in home directory
    if [[ -f "${HOME}/.BE_HOME" ]]; then
        return 0
    fi
    
    # Check for .TVDPERL_HOME file (another basenv marker)
    if [[ -f "${HOME}/.TVDPERL_HOME" ]]; then
        return 0
    fi
    
    return 1
}

# Check if an alias or command already exists
# Usage: alias_exists alias_name
# Returns: 0 if exists, 1 if not
alias_exists() {
    local name="$1"
    
    # Check if it's an alias
    if alias "${name}" &>/dev/null; then
        return 0
    fi
    
    # Check if it's a command in PATH
    if command -v "${name}" &>/dev/null; then
        return 0
    fi
    
    return 1
}

# Safe alias creation - respects coexistence mode
# Usage: safe_alias alias_name "alias_value"
# Returns: 0 if created, 1 if skipped (coexist mode and exists), 2 if error
safe_alias() {
    local name="$1"
    local value="$2"
    
    # If force mode is enabled, always create the alias
    if [[ "${ORADBA_FORCE:-0}" == "1" ]]; then
        # shellcheck disable=SC2139,SC2140
        alias "${name}=${value}"
        return 0
    fi
    
    # In coexistence mode, skip if alias already exists
    if [[ "${ORADBA_COEXIST_MODE}" == "basenv" ]]; then
        if alias_exists "${name}"; then
            # Silently skip (basenv has priority)
            oradba_log DEBUG "Skipping alias '${name}' (exists in basenv, coexist mode active)"
            return 1
        fi
    fi
    
    # Create the alias
    # shellcheck disable=SC2139,SC2140
    alias "${name}=${value}"
    return 0
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
        oradba_log ERROR "Missing required Oracle environment variables: ${missing_vars[*]}"
        return 1
    fi

    return 0
}

# Get Oracle version
get_oracle_version() {
    if [[ -z "${ORACLE_HOME}" ]]; then
        oradba_log ERROR "ORACLE_HOME not set"
        return 1
    fi

    if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
        "${ORACLE_HOME}/bin/sqlplus" -version | grep -oP 'Release \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
    else
        oradba_log ERROR "sqlplus not found in ORACLE_HOME"
        return 1
    fi
}

# Parse oratab file
parse_oratab() {
    local sid="$1"
    local oratab_file="${2:-/etc/oratab}"

    if [[ ! -f "$oratab_file" ]]; then
        oradba_log ERROR "oratab file not found: $oratab_file"
        return 1
    fi

    # Case-insensitive search for SID
    grep -i "^${sid}:" "$oratab_file" | grep -v "^#" | head -1
}

# Generate SID lists and aliases from oratab
# Usage: generate_sid_lists [oratab_file]
generate_sid_lists() {
    local oratab_file="${1:-/etc/oratab}"
    
    # Check if oratab exists
    if [[ ! -f "$oratab_file" ]]; then
        oradba_log DEBUG "oratab file not found: $oratab_file"
        export ORADBA_SIDLIST=""
        export ORADBA_REALSIDLIST=""
        return 1
    fi
    
    local all_sids=""
    local real_sids=""
    
    # Parse oratab, skip comments and empty lines
    while IFS=: read -r oratab_sid _oracle_home startup_flag; do
        # Skip empty lines and comments
        [[ -z "$oratab_sid" ]] && continue
        [[ "$oratab_sid" =~ ^[[:space:]]*# ]] && continue
        
        # Skip ASM instances (start with +)
        [[ "$oratab_sid" =~ ^\+ ]] && continue
        
        # Add to all SIDs list
        all_sids="${all_sids}${all_sids:+ }${oratab_sid}"
        
        # Add to real SIDs list if startup flag is Y or N (not D for DGMGRL dummy)
        if [[ "$startup_flag" =~ ^[YyNn] ]]; then
            real_sids="${real_sids}${real_sids:+ }${oratab_sid}"
        fi
        
        # Create alias for this SID (lowercase)
        local sid_lower="${oratab_sid,,}"
        # shellcheck disable=SC2139
        alias "${sid_lower}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${oratab_sid}"
        
    done < <(grep -v "^#" "$oratab_file" | grep -v "^[[:space:]]*$")
    
    # Export the lists
    export ORADBA_SIDLIST="$all_sids"
    export ORADBA_REALSIDLIST="$real_sids"
    
    oradba_log DEBUG "ORADBA_SIDLIST: $ORADBA_SIDLIST"
    oradba_log DEBUG "ORADBA_REALSIDLIST: $ORADBA_REALSIDLIST"
    
    return 0
}

# Usage: generate_pdb_aliases
# Generate aliases for PDBs in the current CDB
generate_pdb_aliases() {
    # Skip if disabled
    if [[ "${ORADBA_NO_PDB_ALIASES}" == "true" ]]; then
        oradba_log DEBUG "PDB aliases disabled (ORADBA_NO_PDB_ALIASES=true)"
        return 0
    fi
    
    # Skip if no database connection
    if ! check_database_connection 2>/dev/null; then
        oradba_log DEBUG "No database connection, skipping PDB alias generation"
        return 0
    fi
    
    # Skip if not a CDB
    local is_cdb
    is_cdb=$(sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF TIMING OFF TIME OFF SQLPROMPT "" TRIMSPOOL ON TRIMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT cdb FROM v\$database;
EXIT
EOF
)
    
    if [[ "${is_cdb}" != "YES" ]]; then
        oradba_log DEBUG "Not a CDB, skipping PDB alias generation"
        return 0
    fi
    
    # Get list of PDBs
    local pdb_list
    pdb_list=$(sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF TIMING OFF TIME OFF SQLPROMPT "" TRIMSPOOL ON TRIMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED' ORDER BY name;
EXIT
EOF
)
    
    # Create aliases for each PDB
    while IFS= read -r pdb_name; do
        # Skip empty lines
        [[ -z "$pdb_name" ]] && continue
        
        # Create lowercase alias
        local pdb_lower="${pdb_name,,}"
        
        # Create alias to set ORADBA_PDB and connect
        # shellcheck disable=SC2139
        alias "${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"
        
        # Create alias with 'pdb' prefix for clarity
        # shellcheck disable=SC2139
        alias "pdb${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"
        
        oradba_log DEBUG "Created PDB alias: ${pdb_lower} -> ${pdb_name}"
    done <<< "$pdb_list"
    
    # Export the PDB list
    export ORADBA_PDBLIST="${pdb_list//$'\n'/ }"
    oradba_log DEBUG "ORADBA_PDBLIST: $ORADBA_PDBLIST"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: load_rman_catalog_connection
# Purpose.: Load and validate RMAN catalog connection string
# Returns.: 0 on success, 1 if no catalog configured
# Notes...: Updates ORADBA_RMAN_CATALOG_CONNECTION for use in aliases
#           Catalog format: catalog user/password@tnsalias
#           or catalog user@tnsalias (prompts for password)
# ------------------------------------------------------------------------------
load_rman_catalog_connection() {
    oradba_log DEBUG "Checking RMAN catalog configuration"
    
    # Check if catalog is configured
    if [[ -z "${ORADBA_RMAN_CATALOG}" ]]; then
        oradba_log DEBUG "No RMAN catalog configured (ORADBA_RMAN_CATALOG not set)"
        export ORADBA_RMAN_CATALOG_CONNECTION=""
        return 1
    fi
    
    # Validate catalog connection string format
    # Expected: user/password@tnsalias or user@tnsalias
    if [[ ! "${ORADBA_RMAN_CATALOG}" =~ ^[a-zA-Z0-9_]+(@|/) ]]; then
        oradba_log WARN "Invalid RMAN catalog format: ${ORADBA_RMAN_CATALOG}"
        oradba_log WARN "Expected: user/password@tnsalias or user@tnsalias"
        export ORADBA_RMAN_CATALOG_CONNECTION=""
        return 1
    fi
    
    # Build the full catalog connection string for RMAN
    export ORADBA_RMAN_CATALOG_CONNECTION="catalog ${ORADBA_RMAN_CATALOG}"
    oradba_log DEBUG "RMAN catalog connection: ${ORADBA_RMAN_CATALOG_CONNECTION}"
    
    return 0
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
                oradba_log ERROR "Failed to create directory: $dir"
                return 1
            fi
            oradba_log INFO "Created directory: $dir"
        else
            oradba_log ERROR "Directory does not exist: $dir"
            return 1
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Configuration Management
# ------------------------------------------------------------------------------

# Load single configuration file with automatic logging and error handling
# Usage: load_config_file <file_path> [required]
# Parameters:
#   file_path - Full path to configuration file
#   required  - "true" for required (return error if missing), "false" for optional (default: "false")
# Returns: 0 if loaded successfully or skipped (optional), 1 if failed (required file missing)
# Notes: Automatically logs debug messages and handles shellcheck source disable
load_config_file() {
    local file_path="${1:?Config file path required}"
    local required="${2:-false}"
    
    if [[ -f "${file_path}" ]]; then
        oradba_log DEBUG "Loading config: ${file_path}"
        # shellcheck source=/dev/null
        source "${file_path}"
        return 0
    else
        if [[ "${required}" == "true" ]]; then
            oradba_log ERROR "Required configuration not found: ${file_path}"
            return 1
        else
            oradba_log DEBUG "Optional configuration not found: ${file_path}"
            return 0
        fi
    fi
}

# Load hierarchical configuration files
# Usage: load_config [ORACLE_SID]
# Loads configuration in order: core -> standard -> customer -> default -> sid-specific
# Later configs override earlier settings
load_config() {
    local sid="${1:-${ORACLE_SID}}"
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    
    oradba_log DEBUG "Loading OraDBA configuration for SID: ${sid:-<none>}"
    
    # Enable auto-export of all variables (set -a)
    # This ensures all variables in config files are exported to environment
    # even if 'export' keyword is forgotten
    set -a
    
    # 1. Load core configuration (required)
    if ! load_config_file "${config_dir}/oradba_core.conf" "true"; then
        set +a
        return 1
    fi
    
    # 2. Load standard configuration (required, but warn if missing)
    if ! load_config_file "${config_dir}/oradba_standard.conf"; then
        oradba_log WARN "Standard configuration not found: ${config_dir}/oradba_standard.conf"
    fi
    
    # 3. Load customer configuration (optional)
    load_config_file "${config_dir}/oradba_customer.conf"
    
    # 4. Load default SID configuration (optional)
    load_config_file "${config_dir}/sid._DEFAULT_.conf"
    
    # 5. Load SID-specific configuration (optional)
    if [[ -n "${sid}" ]]; then
        local sid_config="${config_dir}/sid.${sid}.conf"
        
        # Check if SID config exists
        if [[ -f "${sid_config}" ]]; then
            # Config exists - load it
            load_config_file "${sid_config}"
        else
            # Config doesn't exist - check if we should auto-create it
            if [[ "${ORADBA_AUTO_CREATE_SID_CONFIG}" == "true" ]]; then
                # Check if this is a real SID (not a dummy SID with startup flag 'D')
                # Use word boundary regex pattern for proper matching
                if [[ " ${ORADBA_REALSIDLIST} " =~ (^|[[:space:]])${sid}($|[[:space:]]) ]]; then
                    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] Auto-create enabled, config_dir=${config_dir}, template should be at: ${config_dir}/sid.ORACLE_SID.conf.example" >&2
                    oradba_log DEBUG "ORADBA_AUTO_CREATE_SID_CONFIG is true, attempting to create config"
                    if create_sid_config "${sid}"; then
                        # Source the newly created config file
                        load_config_file "${sid_config}"
                    else
                        echo "[WARN] Failed to auto-create SID config for ${sid}" >&2
                        oradba_log WARN "Failed to auto-create SID config for ${sid}"
                    fi
                else
                    oradba_log DEBUG "SID ${sid} is a dummy SID (not in ORADBA_REALSIDLIST), skipping auto-create"
                    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] Skipping auto-create for dummy SID: ${sid}" >&2
                fi
            else
                oradba_log DEBUG "ORADBA_AUTO_CREATE_SID_CONFIG is not true (value: '${ORADBA_AUTO_CREATE_SID_CONFIG}')"
            fi
        fi
    fi
    
    # Disable auto-export (set +a)
    set +a
    
    oradba_log DEBUG "Configuration loading complete"
    return 0
}

# Create SID-specific configuration file with database metadata
# Only tracks static metadata: DB_NAME, DB_UNIQUE_NAME, DBID, DB_VERSION, NLS_LANG
# Does not track dynamic state like DB_ROLE or OPEN_MODE
# Usage: create_sid_config <ORACLE_SID>
create_sid_config() {
    local sid="$1"
    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] create_sid_config called with SID=${sid}" >&2
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    local sid_config="${config_dir}/sid.${sid}.conf"
    local example_config="${config_dir}/sid.ORACLE_SID.conf.example"
    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] Will create: ${sid_config} from template: ${example_config}" >&2
    
    # Check if config directory is writable
    if [[ ! -w "${config_dir}" ]]; then
        echo "[ERROR] Config directory is not writable: ${config_dir}" >&2
        oradba_log ERROR "Config directory is not writable: ${config_dir}"
        oradba_log ERROR "Cannot create SID configuration file. Run with appropriate permissions."
        return 1
    fi
    
    # User-visible message (write to stderr to bypass any redirections)
    echo "" >&2
    echo "[INFO] Auto-creating SID configuration for ${sid}..." >&2
    
    # Check if example template exists - use it as base
    if [[ ! -f "${example_config}" ]]; then
        echo "[ERROR] Template not found: ${example_config}" >&2
        oradba_log ERROR "Template not found: ${example_config}"
        return 1
    fi
    
    oradba_log DEBUG "Using template: ${example_config}"
    # Copy example and replace ORCL with actual SID
    if sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g; s/Date.......: .*/Date.......: $(date '+%Y.%m.%d')/; s/Auto-created on first environment switch/Auto-created: $(date '+%Y-%m-%d %H:%M:%S')/" \
        "${example_config}" > "${sid_config}"; then
        echo "[INFO] ✓ Created SID configuration: ${sid_config}" >&2
        oradba_log INFO "Created SID configuration: ${sid_config}"
        return 0
    else
        echo "[ERROR] Failed to create config from template" >&2
        oradba_log ERROR "Failed to create config from template"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Version Management Functions
# ------------------------------------------------------------------------------

# Get OraDBA version from VERSION file
get_oradba_version() {
    local version_file="${ORADBA_BASE}/VERSION"
    
    if [[ -f "${version_file}" ]]; then
        cat "${version_file}" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

# Compare two semantic versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
version_compare() {
    local v1="$1"
    local v2="$2"
    
    # Remove leading 'v' if present
    v1="${v1#v}"
    v2="${v2#v}"
    
    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # Compare each component
    for i in {0..2}; do
        local part1="${v1_parts[$i]:-0}"
        local part2="${v2_parts[$i]:-0}"
        
        # Remove any non-numeric suffix (e.g., "1-beta")
        part1="${part1%%-*}"
        part2="${part2%%-*}"
        
        if (( part1 > part2 )); then
            return 1
        elif (( part1 < part2 )); then
            return 2
        fi
    done
    
    return 0
}

# Check if version meets minimum requirement
# Usage: version_meets_requirement "0.6.1" "0.6.0"
version_meets_requirement() {
    local current_version="$1"
    local required_version="$2"
    
    version_compare "$current_version" "$required_version"
    local result=$?
    
    # Returns 0 (equal) or 1 (greater) means requirement is met
    [[ $result -eq 0 || $result -eq 1 ]]
}

# Get installation metadata
# Supports both old format (install_version) and new format (version)
get_install_info() {
    local key="$1"
    local install_info="${ORADBA_BASE}/.install_info"
    
    if [[ -f "${install_info}" ]]; then
        # Try to get value, handle both with and without quotes
        local value
        value=$(grep "^${key}=" "${install_info}" | cut -d= -f2- | sed 's/^"//;s/"$//')
        echo "${value}"
    fi
}

# Set installation metadata
# Uses lowercase keys without quotes for consistency with installer
set_install_info() {
    local key="$1"
    local value="$2"
    local install_info="${ORADBA_BASE}/.install_info"
    
    # Create or update key
    if [[ -f "${install_info}" ]]; then
        # Update existing key or append
        if grep -q "^${key}=" "${install_info}"; then
            sed -i.bak "s|^${key}=.*|${key}=${value}|" "${install_info}"
            rm -f "${install_info}.bak"
        else
            echo "${key}=${value}" >> "${install_info}"
        fi
    else
        # Create new file
        mkdir -p "$(dirname "${install_info}")"
        echo "${key}=${value}" > "${install_info}"
    fi
}

# Initialize installation info file
# Uses lowercase keys without quotes to match installer format
init_install_info() {
    local version="$1"
    local install_info="${ORADBA_BASE}/.install_info"
    
    cat > "${install_info}" <<EOF
install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
install_version=${version}
install_method=installer
install_user=${USER}
install_prefix=${ORADBA_BASE}
EOF
    
    oradba_log INFO "Created installation metadata: ${install_info}"
}

# ------------------------------------------------------------------------------
# SQLPATH Management Functions (#11)
# ------------------------------------------------------------------------------

# Configure SQLPATH for SQL*Plus script discovery
# Usage: configure_sqlpath
# Builds SQLPATH with priority:
#   1. Current directory (pwd)
#   2. OraDBA SQL scripts
#   3. SID-specific SQL directory (if exists)
#   4. Oracle RDBMS admin scripts
#   5. Oracle sqlplus admin scripts
#   6. User custom SQL directory
#   7. Custom SQLPATH from config
#   8. Existing SQLPATH entries (if preserve enabled)
configure_sqlpath() {
    local sqlpath_parts=()
    
    # 1. Current directory (standard Oracle behavior)
    sqlpath_parts+=(".")
    
    # 2. OraDBA SQL scripts
    if [[ -d "${ORADBA_PREFIX}/sql" ]]; then
        sqlpath_parts+=("${ORADBA_PREFIX}/sql")
    fi
    
    # 3. SID-specific SQL directory (if exists and enabled)
    if [[ "${ORADBA_SID_SPECIFIC_SQL}" == "true" ]] && [[ -n "${ORACLE_SID}" ]] && [[ -d "${ORADBA_PREFIX}/sql/${ORACLE_SID}" ]]; then
        sqlpath_parts+=("${ORADBA_PREFIX}/sql/${ORACLE_SID}")
    fi
    
    # 4. Oracle RDBMS admin scripts (catproc.sql, etc.)
    if [[ -n "${ORACLE_HOME}" ]] && [[ -d "${ORACLE_HOME}/rdbms/admin" ]]; then
        sqlpath_parts+=("${ORACLE_HOME}/rdbms/admin")
    fi
    
    # 5. Oracle sqlplus admin scripts
    if [[ -n "${ORACLE_HOME}" ]] && [[ -d "${ORACLE_HOME}/sqlplus/admin" ]]; then
        sqlpath_parts+=("${ORACLE_HOME}/sqlplus/admin")
    fi
    
    # 6. User custom SQL directory (create if needed)
    if [[ "${ORADBA_CREATE_USER_SQL_DIR}" == "true" ]] && [[ ! -d "${HOME}/.oradba/sql" ]]; then
        mkdir -p "${HOME}/.oradba/sql" 2>/dev/null && log_debug "Created user SQL directory: ${HOME}/.oradba/sql"
    fi
    if [[ -d "${HOME}/.oradba/sql" ]]; then
        sqlpath_parts+=("${HOME}/.oradba/sql")
    fi
    
    # 7. Custom SQLPATH from config (append)
    if [[ -n "${ORADBA_CUSTOM_SQLPATH}" ]]; then
        IFS=':' read -ra custom_paths <<< "${ORADBA_CUSTOM_SQLPATH}"
        sqlpath_parts+=("${custom_paths[@]}")
    fi
    
    # 8. Preserve existing SQLPATH entries (optional)
    if [[ -n "${SQLPATH}" ]] && [[ "${ORADBA_PRESERVE_SQLPATH}" == "true" ]]; then
        IFS=':' read -ra existing_paths <<< "${SQLPATH}"
        sqlpath_parts+=("${existing_paths[@]}")
    fi
    
    # Build colon-separated SQLPATH, removing duplicates while preserving order
    SQLPATH=$(printf "%s\n" "${sqlpath_parts[@]}" | awk '!seen[$0]++' | paste -sd:)
    export SQLPATH
    
    oradba_log DEBUG "SQLPATH configured: ${SQLPATH}"
}

# Display current SQLPATH directories
# Usage: show_sqlpath
show_sqlpath() {
    if [[ -z "${SQLPATH}" ]]; then
        echo "SQLPATH is not set"
        return 1
    fi
    
    echo "SQLPATH Directories:"
    echo "==================="
    local count=1
    IFS=':' read -ra paths <<< "${SQLPATH}"
    for path in "${paths[@]}"; do
        if [[ -d "${path}" ]]; then
            printf "%2d. %-60s [✓]\n" "${count}" "${path}"
        else
            printf "%2d. %-60s [✗ not found]\n" "${count}" "${path}"
        fi
        ((count++))
    done
}

# Display current PATH directories (mirrors show_sqlpath output)
# Usage: show_path
show_path() {
    if [[ -z "${PATH}" ]]; then
        echo "PATH is not set"
        return 1
    fi
    
    echo "PATH Directories:"
    echo "================="
    local count=1
    IFS=':' read -ra paths <<< "${PATH}"
    for path in "${paths[@]}"; do
        if [[ -d "${path}" ]]; then
            printf "%2d. %-60s [✓]\n" "${count}" "${path}"
        else
            printf "%2d. %-60s [✗ not found]\n" "${count}" "${path}"
        fi
        ((count++))
    done
}

# Display OraDBA configuration hierarchy and load order
# Usage: show_config
show_config() {
    local sid="${ORACLE_SID:-<not set>}"
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    
    echo "OraDBA Configuration Hierarchy:"
    echo "================================"
    echo "SID: ${sid}"
    echo "Config Directory: ${config_dir}"
    echo ""
    echo "Load Order (later configs override earlier):"
    echo "---------------------------------------------"
    
    local count=1
    local config_file
    local status
    
    # 1. Core configuration (required)
    config_file="${config_dir}/oradba_core.conf"
    if [[ -f "${config_file}" ]]; then
        status="[✓ loaded]"
    else
        status="[✗ MISSING - REQUIRED]"
    fi
    printf "%2d. %-50s %s\n" "${count}" "oradba_core.conf" "${status}"
    ((count++))
    
    # 2. Standard configuration (required)
    config_file="${config_dir}/oradba_standard.conf"
    if [[ -f "${config_file}" ]]; then
        status="[✓ loaded]"
    else
        status="[✗ MISSING - REQUIRED]"
    fi
    printf "%2d. %-50s %s\n" "${count}" "oradba_standard.conf" "${status}"
    ((count++))
    
    # 3. Customer configuration (optional)
    config_file="${config_dir}/oradba_customer.conf"
    if [[ -f "${config_file}" ]]; then
        status="[✓ loaded]"
    else
        status="[- not configured]"
    fi
    printf "%2d. %-50s %s\n" "${count}" "oradba_customer.conf (optional)" "${status}"
    ((count++))
    
    # 4. Default SID configuration (optional)
    config_file="${config_dir}/sid._DEFAULT_.conf"
    if [[ -f "${config_file}" ]]; then
        status="[✓ loaded]"
    else
        status="[- not configured]"
    fi
    printf "%2d. %-50s %s\n" "${count}" "sid._DEFAULT_.conf (optional)" "${status}"
    ((count++))
    
    # 5. SID-specific configuration (optional)
    if [[ "${sid}" != "<not set>" ]]; then
        config_file="${config_dir}/sid.${sid}.conf"
        if [[ -f "${config_file}" ]]; then
            status="[✓ loaded]"
        else
            status="[- not configured]"
        fi
        printf "%2d. %-50s %s\n" "${count}" "sid.${sid}.conf (optional)" "${status}"
    else
        printf "%2d. %-50s %s\n" "${count}" "sid.<SID>.conf (optional)" "[- no SID set]"
    fi
    
    echo ""
    echo "For more information: oradba help config"
}

# Add directory to SQLPATH
# Usage: add_to_sqlpath <directory>
add_to_sqlpath() {
    local new_path="${1}"
    
    if [[ -z "${new_path}" ]]; then
        oradba_log ERROR "Directory path required"
        return 1
    fi
    
    if [[ ! -d "${new_path}" ]]; then
        oradba_log ERROR "Directory does not exist: ${new_path}"
        return 1
    fi
    
    # Check if already in SQLPATH
    if [[ ":${SQLPATH}:" == *":${new_path}:"* ]]; then
        oradba_log INFO "Directory already in SQLPATH: ${new_path}"
        return 0
    fi
    
    # Add to SQLPATH
    if [[ -z "${SQLPATH}" ]]; then
        export SQLPATH="${new_path}"
    else
        export SQLPATH="${SQLPATH}:${new_path}"
    fi
    
    oradba_log INFO "Added to SQLPATH: ${new_path}"
}

# Show version information
show_version_info() {
    local version
    version=$(get_oradba_version)
    
    echo "OraDBA Version: ${version}"
    
    if [[ -f "${ORADBA_BASE}/.install_info" ]]; then
        echo ""
        echo "Installation Details:"
        echo "  Installed: $(get_install_info "install_date")"
        echo "  Method: $(get_install_info "install_method")"
        echo "  User: $(get_install_info "install_user")"
        echo "  Prefix: $(get_install_info "install_prefix")"
    fi
}
