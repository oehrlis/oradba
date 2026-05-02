#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_common.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Common library functions for oradba scripts
# Notes......: This library provides reusable functions for logging, validation,
#              Oracle environment management, and configuration parsing.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: get_script_dir
# Purpose.: Get the absolute path of the script directory
# Args....: None
# Returns.: 0 on success
# Output..: Absolute directory path
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: init_logging
# Purpose.: Initialize logging infrastructure and create log directories
# Args....: None
# Returns.: 0 on success
# Output..: Creates ORADBA_LOG_DIR, sets ORADBA_LOG_FILE, ORADBA_ERROR_LOG
# Notes...: Falls back to ${HOME}/.oradba/logs if /var/log not writable
# ------------------------------------------------------------------------------
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
        if ! mkdir -p "$log_dir" 2> /dev/null; then
            # Fallback to user directory if system location fails
            log_dir="${HOME}/.oradba/logs"
            mkdir -p "$log_dir" 2> /dev/null || {
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

# ------------------------------------------------------------------------------
# Function: init_session_log
# Purpose.: Initialize session-specific log file for current execution
# Args....: None
# Returns.: 0 on success
# Output..: Sets ORADBA_SESSION_LOG environment variable
# ------------------------------------------------------------------------------
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
    cat > "$session_log" << EOF
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
        readonly LOG_COLOR_TRACE="\033[0;35m"   # Magenta
        readonly LOG_COLOR_DEBUG="\033[0;36m"   # Cyan
        readonly LOG_COLOR_INFO="\033[0;34m"    # Blue
        readonly LOG_COLOR_WARN="\033[0;33m"    # Yellow
        readonly LOG_COLOR_ERROR="\033[0;31m"   # Red
        readonly LOG_COLOR_SUCCESS="\033[0;32m" # Green
        readonly LOG_COLOR_FAILURE="\033[1;31m" # Bold Red
        readonly LOG_COLOR_SECTION="\033[1;37m" # Bold White
        readonly LOG_COLOR_RESET="\033[0m"      # Reset
    else
        # No colors for non-TTY or when disabled
        readonly LOG_COLOR_TRACE=""
        readonly LOG_COLOR_DEBUG=""
        readonly LOG_COLOR_INFO=""
        readonly LOG_COLOR_WARN=""
        readonly LOG_COLOR_ERROR=""
        readonly LOG_COLOR_SUCCESS=""
        readonly LOG_COLOR_FAILURE=""
        readonly LOG_COLOR_SECTION=""
        readonly LOG_COLOR_RESET=""
    fi
fi # End of readonly variables guard

# Unified logging function with level-based filtering
# Usage: oradba_log <LEVEL> <message>
# ------------------------------------------------------------------------------
# Function: oradba_log
# Purpose.: Modern unified logging function with level filtering and color support
# Args....: $1 - Log level (TRACE|DEBUG|INFO|WARN|ERROR|SUCCESS|FAILURE|SECTION)
#           $@ - Log message (remaining arguments)
# Returns.: 0 - Always successful
# Output..: Formatted log message to stderr (and optional log files)
# Notes...: Respects ORADBA_LOG_LEVEL for filtering (default: INFO)
#           Supports color output (disable with ORADBA_NO_COLOR=1)
#           Dual logging to ORADBA_LOG_FILE and ORADBA_SESSION_LOG
#           Legacy DEBUG=1 support for backward compatibility
#           TRACE level is finer than DEBUG for very detailed diagnostics
#           Replaces deprecated log_info/log_warn/log_error/log_debug functions
# ------------------------------------------------------------------------------
oradba_log() {
    local level="$1"
    shift
    local message="$*"
    local level_upper
    local min_level_upper

    # Default log level is INFO if not set
    local min_level="${ORADBA_LOG_LEVEL:-INFO}"
    case "${level}" in
        trace|TRACE)     level_upper="TRACE"   ;;
        debug|DEBUG)     level_upper="DEBUG"   ;;
        info|INFO)       level_upper="INFO"    ;;
        warn|WARN)       level_upper="WARN"    ;;
        error|ERROR)     level_upper="ERROR"   ;;
        success|SUCCESS) level_upper="SUCCESS" ;;
        failure|FAILURE) level_upper="FAILURE" ;;
        section|SECTION) level_upper="SECTION" ;;
        *)               level_upper="${level}" ;;
    esac

    # Legacy DEBUG=1 support - if DEBUG is set, enable DEBUG level
    if [[ "${DEBUG:-0}" == "1" ]] && [[ "${min_level}" != "DEBUG" ]] && [[ "${min_level}" != "TRACE" ]]; then
        min_level="DEBUG"
    fi

    # ORADBA_PLUGIN_DEBUG support - enable DEBUG level for plugin diagnostics
    if [[ "${ORADBA_PLUGIN_DEBUG:-false}" == "true" ]] && [[ "${min_level}" != "DEBUG" ]] && [[ "${min_level}" != "TRACE" ]]; then
        min_level="DEBUG"
    fi

    # Recompute normalized minimum level after compatibility overrides
    case "${min_level}" in
        trace|TRACE)     min_level_upper="TRACE" ;;
        debug|DEBUG)     min_level_upper="DEBUG" ;;
        info|INFO)       min_level_upper="INFO"  ;;
        warn|WARN)       min_level_upper="WARN"  ;;
        error|ERROR)     min_level_upper="ERROR" ;;
        *)               min_level_upper="${min_level}" ;;
    esac

    # Convert levels to numeric values for comparison
    local level_value=0
    local min_level_value=0

    case "${level_upper}" in
        TRACE) level_value=-1 ;;
        DEBUG) level_value=0 ;;
        INFO) level_value=1 ;;
        WARN) level_value=2 ;;
        ERROR) level_value=3 ;;
        SUCCESS) level_value=1 ;; # Same as INFO
        FAILURE) level_value=3 ;; # Same as ERROR
        SECTION) level_value=1 ;; # Same as INFO
        *) level_value=1 ;;       # Default to INFO for unknown levels
    esac

    case "${min_level_upper}" in
        TRACE) min_level_value=-1 ;;
        DEBUG) min_level_value=0 ;;
        INFO) min_level_value=1 ;;
        WARN) min_level_value=2 ;;
        ERROR) min_level_value=3 ;;
        *) min_level_value=1 ;; # Default to INFO
    esac

    # Only log if message level meets minimum threshold
    if [[ ${level_value} -ge ${min_level_value} ]]; then
        # Select color based on level
        local color=""
        case "${level_upper}" in
            TRACE) color="${LOG_COLOR_TRACE}" ;;
            DEBUG) color="${LOG_COLOR_DEBUG}" ;;
            INFO) color="${LOG_COLOR_INFO}" ;;
            WARN) color="${LOG_COLOR_WARN}" ;;
            ERROR) color="${LOG_COLOR_ERROR}" ;;
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
            log_line="[${level_upper}] ${timestamp} [${caller}] - ${message}"
        else
            log_line="[${level_upper}] ${timestamp} - ${message}"
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
    result=$(
        sqlplus -s / as sysdba 2>&1 << EOF
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

# ------------------------------------------------------------------------------
# oratab Priority & Detection
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: get_oratab_path
# Purpose.: Determine the correct oratab file path using priority order
# Args....: None
# Returns.: 0 if oratab found, 1 if not found
# Output..: Prints path to oratab file (even if doesn't exist)
# Notes...: Priority: ORADBA_ORATAB > /etc/oratab > /var/opt/oracle/oratab >
#           ${ORADBA_BASE}/etc/oratab > ${HOME}/.oratab
# ------------------------------------------------------------------------------
get_oratab_path() {
    local oratab_path=""

    # Priority 1: Explicit override
    if [[ -n "${ORADBA_ORATAB:-}" ]]; then
        oratab_path="$ORADBA_ORATAB"
        oradba_log DEBUG "Using ORADBA_ORATAB override: $oratab_path"
        echo "$oratab_path"
        [[ -f "$oratab_path" ]] && return 0 || return 1
    fi

    # Priority 2: System default
    if [[ -f "/etc/oratab" ]]; then
        oratab_path="/etc/oratab"
        oradba_log DEBUG "Using system oratab: $oratab_path"
        echo "$oratab_path"
        return 0
    fi

    # Priority 3: Solaris/AIX location
    if [[ -f "/var/opt/oracle/oratab" ]]; then
        oratab_path="/var/opt/oracle/oratab"
        oradba_log DEBUG "Using Solaris/AIX oratab: $oratab_path"
        echo "$oratab_path"
        return 0
    fi

    # Priority 4: OraDBA temporary oratab (pre-Oracle installations)
    if [[ -n "${ORADBA_BASE:-}" ]] && [[ -f "${ORADBA_BASE}/etc/oratab" ]]; then
        oratab_path="${ORADBA_BASE}/etc/oratab"
        oradba_log DEBUG "Using OraDBA temporary oratab: $oratab_path"
        echo "$oratab_path"
        return 0
    fi

    # Priority 5: User fallback
    if [[ -f "${HOME}/.oratab" ]]; then
        oratab_path="${HOME}/.oratab"
        oradba_log DEBUG "Using user oratab: $oratab_path"
        echo "$oratab_path"
        return 0
    fi

    # No oratab found - return default for new installations
    oratab_path="/etc/oratab"
    oradba_log DEBUG "No oratab found, returning default: $oratab_path"
    echo "$oratab_path"
    return 0
}

# ------------------------------------------------------------------------------
# Function: is_dummy_sid
# Purpose.: Check if current Oracle SID is marked as dummy/template in oratab
# Args....: None (uses ORACLE_SID environment variable)
# Returns.: 0 if SID is dummy (:D flag in oratab), 1 otherwise
# Output..: None
# Notes...: Dummy entries are marked with ':D' flag in oratab file
# ------------------------------------------------------------------------------
is_dummy_sid() {
    local sid="${ORACLE_SID}"
    local oratab_file
    oratab_file=$(get_oratab_path)

    [[ -z "$sid" ]] && return 1
    [[ ! -f "$oratab_file" ]] && return 1

    # Check if SID exists in oratab with :D flag
    if grep -q "^${sid}:.*:D" "$oratab_file" 2> /dev/null; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Function: command_exists
# Purpose.: Check if a command is available in PATH
# Args....: $1 - Command name to check
# Returns.: 0 if command exists, 1 otherwise
# Output..: None
# ------------------------------------------------------------------------------
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Coexistence Mode Functions (TVD BasEnv / DB*Star)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: alias_exists
# Purpose.: Check if an alias or command already exists
# Args....: $1 - Alias or command name to check
# Returns.: 0 if exists (as alias or command), 1 if not
# Output..: None
# Notes...: Checks both shell aliases and commands in PATH
# ------------------------------------------------------------------------------
alias_exists() {
    local name="$1"

    # Check if it's an alias
    if alias "${name}" &> /dev/null; then
        return 0
    fi

    # Check if it's a command in PATH
    if command -v "${name}" &> /dev/null; then
        return 0
    fi

    return 1
}

# ------------------------------------------------------------------------------
# Function: safe_alias
# Purpose.: Create alias respecting coexistence mode with other Oracle environments
# Args....: $1 - Alias name
#           $2 - Alias value/command
# Returns.: 0 - Alias created successfully
#           1 - Alias skipped (coexistence mode and already exists)
#           2 - Error creating alias
# Output..: Debug message if alias skipped
# Notes...: Respects ORADBA_COEXIST_MODE and ORADBA_FORCE settings.
#           Example: safe_alias "ora19" "set_oracle_env 19.0.0"
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: verify_oracle_env
# Purpose.: Verify required Oracle environment variables are set
# Args....: None
# Returns.: 0 if all required vars set, 1 if any missing
# Output..: Error message listing missing variables
# Notes...: Checks ORACLE_SID and ORACLE_HOME
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: get_oracle_version
# Purpose.: Retrieve Oracle database version from sqlplus
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: Oracle version string (e.g., 19.0.0.0 or 23.26.0.0)
# Notes...: Uses sqlplus if available, otherwise delegates to detect_oracle_version()
#           for plugin-based detection (library filenames, JDBC JAR, etc.)
# ------------------------------------------------------------------------------
get_oracle_version() {
    if [[ -z "${ORACLE_HOME}" ]]; then
        oradba_log ERROR "ORACLE_HOME not set"
        return 1
    fi

    # Check for sqlplus in bin/ (database/client) or root (instant client)
    local sqlplus_bin=""
    if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
        sqlplus_bin="${ORACLE_HOME}/bin/sqlplus"
    elif [[ -x "${ORACLE_HOME}/sqlplus" ]]; then
        sqlplus_bin="${ORACLE_HOME}/sqlplus"
    fi
    
    if [[ -n "${sqlplus_bin}" ]]; then
        local _sql_ver
        _sql_ver=$("${sqlplus_bin}" -version 2>/dev/null | grep -E 'Release [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ "${_sql_ver}" =~ Release[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
        return $?
    else
        # No sqlplus - try plugin-based detection (instant client basic, datasafe, etc.)
        oradba_log DEBUG "sqlplus not found, trying plugin-based version detection"
        
        # Try to use ORADBA_CURRENT_HOME_TYPE if set, otherwise detect
        local product_type="${ORADBA_CURRENT_HOME_TYPE:-}"
        if [[ -z "${product_type}" ]]; then
            product_type=$(detect_product_type "${ORACLE_HOME}")
            oradba_log DEBUG "Detected product type: ${product_type}"
        fi
        
        local version_code
        if version_code=$(detect_oracle_version "${ORACLE_HOME}" "${product_type}"); then
            # Convert XXYZ format back to X.Y.Z.W format for display
            # Example: 2326 -> 23.26.0.0
            local major="${version_code:0:2}"
            local minor="${version_code:2:2}"
            # Remove leading zeros
            major=$((10#${major}))
            minor=$((10#${minor}))
            echo "${major}.${minor}.0.0"
            return 0
        else
            oradba_log ERROR "Version detection failed"
            return 1
        fi
    fi
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


# ------------------------------------------------------------------------------
# Function: validate_directory
# Purpose.: Validate directory exists and optionally create it
# Args....: $1 - Directory path to validate
#           $2 - Create flag (optional): "create" to create if missing
# Returns.: 0 - Directory exists or was created successfully
#           1 - Directory doesn't exist (and create flag not set)
#           2 - Failed to create directory
# Output..: Error messages to stderr if directory validation/creation fails
# Notes...: Example: validate_directory "/u01/app/oracle" "create"
# ------------------------------------------------------------------------------
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


# Set environment variables for an Oracle Home
# Arguments:
#   $1 - Oracle Home name or alias
#   $2 - ORACLE_HOME path (optional, will be detected if not provided)
# Sets: ORACLE_HOME and product-specific variables
# ------------------------------------------------------------------------------
# Function: set_oracle_home_environment
# Purpose.: Set environment variables for a specific Oracle Home
# Args....: $1 - Oracle Home name or alias
#           $2 - Oracle Home path (optional, will lookup if not provided)
#           $3 - Defer path config helpers (optional, true/false; default: false)
# Returns.: 0 - Environment set successfully
#           1 - Oracle Home not found or invalid
# Output..: Debug/error messages via oradba_log
# Notes...: Sets ORACLE_HOME, ORACLE_BASE, PATH, LD_LIBRARY_PATH, etc.
#           Example: set_oracle_home_environment "ora19"
# ------------------------------------------------------------------------------
set_oracle_home_environment() {
    local name="$1"
    local oracle_home="$2"
    local defer_path_config="${3:-false}"
    local product_type
    local actual_name
    local alias_name

    # Resolve alias to actual name if needed
    actual_name=$(resolve_oracle_home_name "${name}")
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.resolve_name"
    fi
    
    # Get ORACLE_HOME if not provided
    if [[ -z "${oracle_home}" ]]; then
        oracle_home=$(get_oracle_home_path "${actual_name}") || return 1
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.resolve_path"
    fi

    # Get product type from config first, fall back to detection
    if product_type=$(get_oracle_home_type "${actual_name}" 2>/dev/null) && [[ -n "${product_type}" ]] && [[ "${product_type}" != "unknown" ]]; then
        # Successfully got type from config
        :
    else
        # Fallback to filesystem detection
        product_type=$(detect_product_type "${oracle_home}")
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.detect_type"
    fi

    # Apply product-specific adjustments via plugin system
    local adjusted_home="${oracle_home}"
    local datasafe_install_dir=""
    
    if [[ "${product_type}" == "datasafe" ]]; then
        # Load datasafe plugin for oracle_cman_home adjustment
        local plugin_file="${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
        if [[ -f "${plugin_file}" ]]; then
            # shellcheck source=/dev/null
            source "${plugin_file}"
            datasafe_install_dir="${oracle_home}"
            adjusted_home=$(plugin_adjust_environment "${oracle_home}")
            oradba_log DEBUG "DataSafe detected: ORACLE_HOME adjusted via plugin (${adjusted_home})"
        else
            # Fallback to old logic if plugin not available
            if [[ -d "${oracle_home}/oracle_cman_home" ]]; then
                datasafe_install_dir="${oracle_home}"
                adjusted_home="${oracle_home}/oracle_cman_home"
                oradba_log DEBUG "DataSafe detected: ORACLE_HOME adjusted to oracle_cman_home (fallback)"
            fi
        fi
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.adjust_product_home"
    fi

    # Set base environment
    export ORACLE_HOME="${adjusted_home}"
    export ORADBA_CURRENT_HOME_TYPE="${product_type}"
    
    # Set library path using plugin system (Phase 4+)
    if command -v oradba_set_lib_path &>/dev/null; then
        oradba_log DEBUG "Calling oradba_set_lib_path for ${product_type}: ${adjusted_home}"
        oradba_set_lib_path "${adjusted_home}" "${product_type}"
    else
        oradba_log WARN "oradba_set_lib_path not available - library path not set via plugin system"
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.set_lib_path"
    fi
    
    # Set DataSafe-specific variables if applicable
    if [[ -n "${datasafe_install_dir}" ]]; then
        export DATASAFE_HOME="${oracle_home}"
        export DATASAFE_INSTALL_DIR="${datasafe_install_dir}"
        if [[ -d "${adjusted_home}/config" ]]; then
            export DATASAFE_CONFIG="${adjusted_home}/config"
        fi
    fi
    
    # Set home tracking variables for PS1
    export ORADBA_CURRENT_HOME="${actual_name}"
    alias_name=$(get_oracle_home_alias "${actual_name}" 2>/dev/null || echo "${actual_name}")
    export ORADBA_CURRENT_HOME_ALIAS="${alias_name}"
    
    # Create alias for this Oracle Home (consistent with SID aliases)
    # Always use actual name in alias target, not the alias itself
    # shellcheck disable=SC2139  # We want the alias to expand now
    alias "${alias_name}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${actual_name}"
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.create_alias"
    fi

    # Clean old Oracle paths from PATH before adding new ones (Phase 4+)
    # Skip when deferred (oraenv already called _oraenv_unset_old_env)
    if [[ "${defer_path_config}" != "true" ]] && command -v oradba_clean_path &>/dev/null; then
        oradba_clean_path
    fi

    # Set product-specific environment variables
    case "${product_type}" in
        database)
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        oud)
            export PATH="${ORACLE_HOME}/oud/bin:${PATH}"
            export INSTANCE_HOME="${ORACLE_HOME}/asinst_1"
            ;;
        client)
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        iclient)
            # Instant Client: Add ORACLE_HOME to PATH (no bin subdirectory)
            export PATH="${ORACLE_HOME}:${PATH}"
            ;;
        weblogic)
            export WL_HOME="${ORACLE_HOME}/wlserver"
            export PATH="${WL_HOME}/server/bin:${PATH}"
            ;;
        oms)
            ORACLE_HOSTNAME=$(hostname -f)
            export ORACLE_HOSTNAME
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        emagent)
            export AGENT_HOME="${ORACLE_HOME}"
            export PATH="${AGENT_HOME}/bin:${PATH}"
            ;;
        datasafe)
            # ORACLE_HOME now points to oracle_cman_home, so just add bin
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        java)
            # Java/JDK installation
            export JAVA_HOME="${ORACLE_HOME}"
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        *)
            oradba_log WARN "Unknown product type: ${product_type}"
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
    esac
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.apply_base_path"
    fi

    # Add client path for non-client products if configured
    # Check if the product needs external client tools
    case "${product_type}" in
        datasafe|oud|weblogic|oms|emagent|java)
            # Source env_builder if available to use helper functions
    esac

    # Add Java/client paths and dedupe unless deferred to caller
    if [[ "${defer_path_config}" != "true" ]]; then
        # Add Java path for products that need it if configured
        # This happens BEFORE client path so Java takes precedence
        case "${product_type}" in
            datasafe|oud|weblogic|oms|emagent)
                # Source env_builder if available to use helper functions
                if [[ -f "${ORADBA_PREFIX}/lib/oradba_env_builder.sh" ]]; then
                    # Only source if not already loaded
                    if ! command -v oradba_add_java_path &>/dev/null; then
                        # shellcheck source=/dev/null
                        source "${ORADBA_PREFIX}/lib/oradba_env_builder.sh" 2>/dev/null
                    fi

                    # Add Java path if function is available
                    if command -v oradba_add_java_path &>/dev/null; then
                        # Convert to uppercase for function call
                        local product_upper
                        product_upper="${product_type^^}" 2>/dev/null || product_upper=$(printf '%s' "${product_type}" | tr '[:lower:]' '[:upper:]')
                        # Pass ORACLE_HOME for auto-detection of $ORACLE_HOME/java
                        oradba_add_java_path "${product_upper}" "${ORACLE_HOME}" 2>/dev/null || true
                    fi
                fi
                ;;
        esac

        # Add client path for non-client products if configured
        # Check if the product needs external client tools
        case "${product_type}" in
            datasafe|oud|weblogic|oms|emagent)
                # Source env_builder if available to use helper functions
                if [[ -f "${ORADBA_PREFIX}/lib/oradba_env_builder.sh" ]]; then
                    # Only source if not already loaded
                    if ! command -v oradba_add_client_path &>/dev/null; then
                        # shellcheck source=/dev/null
                        source "${ORADBA_PREFIX}/lib/oradba_env_builder.sh" 2>/dev/null
                    fi

                    # Add client path if function is available
                    if command -v oradba_add_client_path &>/dev/null; then
                        # Convert to uppercase for function call
                        local product_upper
                        product_upper="${product_type^^}" 2>/dev/null || product_upper=$(printf '%s' "${product_type}" | tr '[:lower:]' '[:upper:]')
                        oradba_add_client_path "${product_upper}" 2>/dev/null || true
                    fi
                fi
                ;;
        esac

        # Deduplicate PATH after all additions
        if command -v oradba_dedupe_path &>/dev/null; then
            PATH="$(oradba_dedupe_path "${PATH}")"
            export PATH
        fi
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "set_home.finalize_path"
    fi

    oradba_log DEBUG "Set environment for ${name} (${product_type}): ${ORACLE_HOME}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: cleanup_previous_sid_config
# Purpose.: Unset variables from previous SID-specific configuration
# Args....: None
# Returns.: 0 - Always successful
# Output..: Debug messages about cleanup
# Notes...: Uses ORADBA_PREV_SID_VARS to track and unset variables set by
#           previous SID configuration. This ensures clean environment isolation
#           when switching between SIDs.
# ------------------------------------------------------------------------------
cleanup_previous_sid_config() {
    if [[ -n "${ORADBA_PREV_SID_VARS:-}" ]]; then
        oradba_log DEBUG "Cleaning up variables from previous SID configuration"
        
        # Unset each variable that was set by previous SID config
        local var
        for var in ${ORADBA_PREV_SID_VARS}; do
            # Skip critical Oracle and OraDBA variables
            case "$var" in
                ORACLE_SID|ORACLE_HOME|ORACLE_BASE|ORADBA_*|PATH|LD_LIBRARY_PATH|TNS_ADMIN|NLS_LANG)
                    continue
                    ;;
                *)
                    oradba_log DEBUG "Unsetting SID-specific variable: $var"
                    unset "$var"
                    ;;
            esac
        done
        
        # Clear the tracking variable
        unset ORADBA_PREV_SID_VARS
    fi
}

# ------------------------------------------------------------------------------
# Function: capture_sid_config_vars
# Purpose.: Capture variables set by SID-specific configuration
# Args....: $1 - SID configuration file path
# Returns.: 0 - Successfully captured variables
#           1 - Configuration file not found
# Output..: None (sets ORADBA_PREV_SID_VARS)
# Notes...: Compares environment before and after loading SID config to track
#           which variables were added. Stores list in ORADBA_PREV_SID_VARS for
#           cleanup when switching SIDs.
# ------------------------------------------------------------------------------
capture_sid_config_vars() {
    local sid_config="$1"
    
    [[ ! -f "$sid_config" ]] && return 1
    
    # Get current exported variables (variable names only)
    local vars_before
    vars_before=$(compgen -e | sort)
    
    # Source the SID config
    set -a
    # shellcheck source=/dev/null
    source "$sid_config"
    set +a
    
    # Get variables after loading config
    local vars_after
    vars_after=$(compgen -e | sort)
    
    # Find new variables (difference)
    local new_vars
    new_vars=$(comm -13 <(echo "$vars_before") <(echo "$vars_after") | tr '\n' ' ')
    
    # Store for cleanup on next SID switch
    export ORADBA_PREV_SID_VARS="$new_vars"
    
    oradba_log DEBUG "Captured SID-specific variables: ${new_vars:-<none>}"
    
    return 0
}

# Configuration Management
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: load_config_file
# Purpose.: Load single configuration file with error handling
# Args....: $1 - Configuration file path
#           $2 - Required flag (optional): "required" to fail if file missing
# Returns.: 0 - File loaded successfully (or optional and not found)
#           1 - Required file not found or failed to source
# Output..: Debug messages about file loading
# Notes...: Automatically logs debug messages and handles shellcheck source disable.
#           Example: load_config_file "${ORADBA_BASE}/etc/oradba_core.conf" "required"
# ------------------------------------------------------------------------------
load_config_file() {
    local file_path="${1:?Config file path required}"
    local required="${2:-false}"

    if [[ -f "${file_path}" ]]; then
        oradba_log DEBUG "Loading config: ${file_path}"
        
        # Save PATH before sourcing to detect and remove duplicates
        local path_before="${PATH}"
        
        # shellcheck source=/dev/null
        source "${file_path}"
        
        # Deduplicate PATH if it changed
        if [[ "${PATH}" != "${path_before}" ]]; then
            # Use oradba_dedupe_path if available (Phase 2), otherwise use awk
            if command -v oradba_dedupe_path &>/dev/null; then
                PATH="$(oradba_dedupe_path "${PATH}")"
            else
                # Fallback deduplication using awk (portable)
                PATH="$(echo "${PATH}" | awk -v RS=: -v ORS=: '!seen[$0]++' | sed 's/:$//')"
            fi
            export PATH
        fi
        
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

# ------------------------------------------------------------------------------
# Function: load_config
# Purpose.: Load hierarchical configuration files in priority order (6 levels)
# Args....: $1 - ORACLE_SID (optional, loads SID-specific config if provided)
# Returns.: 0 - Configuration loaded successfully
#           1 - Failed to load required configuration files
# Output..: Debug messages about which files are loaded
# Notes...: Loads in order: core → standard → customer → default → sid-specific.
#           Later configs override earlier settings.
#           Example: load_config "ORCL"  # Loads all configs + ORCL-specific
# ------------------------------------------------------------------------------
load_config() {
    local sid="${1:-${ORACLE_SID}}"
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"

    oradba_log DEBUG "Loading OraDBA configuration for SID: ${sid:-<none>}"

    # Clean up variables from previous SID configuration
    # This ensures environment isolation when switching between SIDs
    cleanup_previous_sid_config
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.cleanup_previous_sid_config"
    fi

    # Enable auto-export of all variables (set -a)
    # This ensures all variables in config files are exported to environment
    # even if 'export' keyword is forgotten
    set -a

    # 1. Load core configuration (required)
    if ! load_config_file "${config_dir}/oradba_core.conf" "true"; then
        set +a
        return 1
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.oradba_core.conf"
    fi

    # 2. Load standard configuration (required, but warn if missing)
    if ! load_config_file "${config_dir}/oradba_standard.conf"; then
        oradba_log WARN "Standard configuration not found: ${config_dir}/oradba_standard.conf"
    fi
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.oradba_standard.conf"
    fi

    # 3. Load customer configuration (optional)
    load_config_file "${config_dir}/oradba_customer.conf"
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.oradba_customer.conf"
    fi

    # 4. Load default SID configuration (optional)
    load_config_file "${config_dir}/sid._DEFAULT_.conf"
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.sid._DEFAULT_.conf"
    fi

    # Disable auto-export before SID config (we'll track variables manually)
    set +a

    # 5. Load SID-specific configuration with variable tracking
    if [[ -n "${sid}" ]]; then
        local sid_config="${config_dir}/sid.${sid}.conf"

        # Check if SID config exists
        if [[ -f "${sid_config}" ]]; then
            # Config exists - load it with variable tracking
            capture_sid_config_vars "${sid_config}"
        else
            # Config doesn't exist - check if we should auto-create it
            if [[ "${ORADBA_AUTO_CREATE_SID_CONFIG}" == "true" ]]; then
                # Check if this is a real SID (not a dummy SID with startup flag 'D')
                # Use word boundary regex pattern for proper matching
                if [[ " ${ORADBA_REALSIDLIST} " =~ (^|[[:space:]])${sid}($|[[:space:]]) ]]; then
                    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] Auto-create enabled, config_dir=${config_dir}, template should be at: ${ORADBA_PREFIX}/templates/etc/sid.ORACLE_SID.conf.example" >&2
                    oradba_log DEBUG "ORADBA_AUTO_CREATE_SID_CONFIG is true, attempting to create config"
                    if create_sid_config "${sid}"; then
                        # Source the newly created config file with variable tracking
                        capture_sid_config_vars "${sid_config}"
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
    if command -v _oraenv_profile_mark &>/dev/null; then
        _oraenv_profile_mark "load_config.sid.${sid:-none}.conf"
    fi

    oradba_log DEBUG "Configuration loading complete"
    return 0
}

# ------------------------------------------------------------------------------
# Function: create_sid_config
# Purpose.: Create SID-specific configuration file from template
# Args....: $1 - ORACLE_SID for which to create configuration
# Returns.: 0 - Configuration file created successfully
#           1 - Failed to create configuration file
# Output..: Info messages about file creation
# Notes...: Creates ${ORADBA_BASE}/etc/sid.ORCL.conf from template.
#           Only tracks static metadata (DB_NAME, DBID, etc), not dynamic state.
#           Example: create_sid_config "ORCL"
# ------------------------------------------------------------------------------
create_sid_config() {
    local sid="$1"
    [[ "${ORADBA_DEBUG}" == "true" ]] && echo "[DEBUG] create_sid_config called with SID=${sid}" >&2
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    local sid_config="${config_dir}/sid.${sid}.conf"
    local example_config="${ORADBA_PREFIX}/templates/etc/sid.ORACLE_SID.conf.example"
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
    local sid_lower
    sid_lower="${sid,,}" 2>/dev/null || sid_lower=$(printf '%s' "${sid}" | tr '[:upper:]' '[:lower:]')
    if sed "s/ORCL/${sid}/g; s/orcl/${sid_lower}/g; s/Date.......: .*/Date.......: $(date '+%Y.%m.%d')/; s/Auto-created on first environment switch/Auto-created: $(date '+%Y-%m-%d %H:%M:%S')/" \
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
# SQLPATH Management Functions (#11)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: configure_sqlpath
# Purpose.: Configure SQLPATH for SQL*Plus script discovery with priority order
# Args....: None
# Returns.: 0 - SQLPATH configured successfully
# Output..: None (exports SQLPATH variable)
# Notes...: Priority: 1. Current dir, 2. OraDBA SQL, 3. SID-specific SQL,
#           4. Oracle RDBMS admin, 5. Oracle sqlplus admin, 6. User custom SQL,
#           7. Custom SQLPATH from config, 8. Existing SQLPATH (if preserve enabled).
#           Example: configure_sqlpath
# ------------------------------------------------------------------------------
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
        mkdir -p "${HOME}/.oradba/sql" 2> /dev/null && oradba_log DEBUG "Created user SQL directory: ${HOME}/.oradba/sql"
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
    SQLPATH=$(printf "%s\n" "${sqlpath_parts[@]}" | awk '!seen[$0]++' | paste -sd ':' -)
    export SQLPATH

    oradba_log DEBUG "SQLPATH configured: ${SQLPATH}"
}

# ------------------------------------------------------------------------------
# Function: show_sqlpath
# Purpose.: Display current SQLPATH directories with existence check
# Args....: None
# Returns.: 0 on success, 1 if SQLPATH not set
# Output..: Numbered list of SQLPATH directories with status indicators
# Notes...: Shows [✓] for existing directories, [✗ not found] for missing ones
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: show_path
# Purpose.: Display current PATH directories with existence check
# Args....: None
# Returns.: 0 on success, 1 if PATH not set
# Output..: Numbered list of PATH directories with status indicators
# Notes...: Shows [✓] for existing directories, [✗ not found] for missing ones
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: show_config
# Purpose.: Display OraDBA configuration hierarchy and load order
# Args....: None
# Returns.: 0 on success
# Output..: Formatted display of configuration files with status
# Notes...: Shows Phase 1-4 config hierarchy: core → standard → customer →
#           local → SID-specific, with [✓ loaded] or [✗ MISSING] status
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: add_to_sqlpath
# Purpose.: Add directory to SQLPATH if not already present
# Args....: $1 - Directory path to add to SQLPATH
# Returns.: 0 - Directory added or already in SQLPATH
#           1 - Directory doesn't exist
# Output..: Debug message if directory added
# Notes...: Example: add_to_sqlpath "/u01/app/oracle/dba/sql"
# ------------------------------------------------------------------------------
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
        oradba_log DEBUG "Directory already in SQLPATH: ${new_path}"
        return 0
    fi

    # Add to SQLPATH
    if [[ -z "${SQLPATH}" ]]; then
        export SQLPATH="${new_path}"
    else
        export SQLPATH="${SQLPATH}:${new_path}"
    fi

    oradba_log DEBUG "Added to SQLPATH: ${new_path}"
}

# ------------------------------------------------------------------------------
# Function: is_plugin_debug_enabled
# Purpose.: Check if plugin debug mode is enabled
# Args....: None
# Returns.: 0 if plugin debug enabled, 1 otherwise
# Output..: None
# Notes...: Plugin debug enabled when ORADBA_PLUGIN_DEBUG=true OR ORADBA_LOG_LEVEL=DEBUG/TRACE
# ------------------------------------------------------------------------------
is_plugin_debug_enabled() {
    # Check if ORADBA_PLUGIN_DEBUG is explicitly set to true
    if [[ "${ORADBA_PLUGIN_DEBUG:-false}" == "true" ]]; then
        return 0
    fi
    
    # Check if ORADBA_LOG_LEVEL is DEBUG or TRACE
    local log_level="${ORADBA_LOG_LEVEL:-INFO}"
    local log_level_upper
    case "${log_level}" in
        trace|TRACE) log_level_upper="TRACE" ;;
        debug|DEBUG) log_level_upper="DEBUG" ;;
        info|INFO)   log_level_upper="INFO"  ;;
        warn|WARN)   log_level_upper="WARN"  ;;
        error|ERROR) log_level_upper="ERROR" ;;
        *)           log_level_upper="${log_level}" ;;
    esac
    if [[ "${log_level_upper}" == "DEBUG" ]] || [[ "${log_level_upper}" == "TRACE" ]]; then
        return 0
    fi
    
    # Legacy DEBUG=1 support
    if [[ "${DEBUG:-0}" == "1" ]]; then
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: is_plugin_trace_enabled
# Purpose.: Check if plugin trace mode is enabled (more verbose than debug)
# Args....: None
# Returns.: 0 if plugin trace enabled, 1 otherwise
# Output..: None
# Notes...: Plugin trace enabled only when ORADBA_LOG_LEVEL=TRACE
# ------------------------------------------------------------------------------
is_plugin_trace_enabled() {
    local log_level="${ORADBA_LOG_LEVEL:-INFO}"
    local log_level_upper
    case "${log_level}" in
        trace|TRACE) log_level_upper="TRACE" ;;
        debug|DEBUG) log_level_upper="DEBUG" ;;
        info|INFO)   log_level_upper="INFO"  ;;
        warn|WARN)   log_level_upper="WARN"  ;;
        error|ERROR) log_level_upper="ERROR" ;;
        *)           log_level_upper="${log_level}" ;;
    esac
    if [[ "${log_level_upper}" == "TRACE" ]]; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Function: sanitize_sensitive_data
# Purpose.: Sanitize sensitive data from log output (passwords, connection strings)
# Args....: $1 - Text to sanitize
# Returns.: 0 - Always successful
# Output..: Sanitized text to stdout
# Notes...: Masks passwords in common formats (sqlplus, rman, connection strings)
#           Pattern examples:
#             - sqlplus user/pass@db -> sqlplus user/***@db
#             - rman target user/pass -> rman target user/***
#             - PASSWORD=secret -> PASSWORD=***
#             - pwd=secret -> pwd=***
# ------------------------------------------------------------------------------
sanitize_sensitive_data() {
    local text="$1"
    
    # Apply all sanitization patterns in a single sed command for efficiency
    echo "$text" | sed -E \
        -e 's/(PASSWORD|PWD|PASSWD)="[^"]*"/\1="***"/g' \
        -e "s/(PASSWORD|PWD|PASSWD)='[^']*'/\1='***'/g" \
        -e 's|([^[:space:]]+)/[^@[:space:]]+(@[^[:space:]]*)?|\1/***\2|g' \
        -e 's/(password|pwd|passwd)=([^[:space:]&;|"'\''=]+)/\1=***/gi'
}

# ------------------------------------------------------------------------------
# Function: execute_plugin_function_v2
# Purpose.: Execute a plugin function in an isolated subshell with minimal env
# Args....: $1 - product type (plugin name, e.g., database, datasafe)
#           $2 - function name (without plugin_ prefix)
#           $3 - ORACLE_HOME / base path (use "NOARGS" for no-arg functions)
#           $4 - result variable name (optional)
#           $5 - extra argument (optional)
# Returns.: Exit code from plugin function
# Output..: Stdout from plugin function (or stored in result variable)
# Notes...: Adds subshell isolation (Phase 3) and minimal ORACLE_HOME/LD_LIBRARY_PATH
#           For no-arg functions (e.g., plugin_get_config_section), pass "NOARGS" as oracle_home
# ------------------------------------------------------------------------------
execute_plugin_function_v2() {
    local product_type="$1"
    local function_name="$2"
    local oracle_home="$3"
    local result_var_name="${4:-}"
    local extra_arg="${5:-}"

    [[ -z "${function_name}" ]] && return 1
    [[ -z "${product_type}" ]] && return 1
    [[ -z "${oracle_home}" ]] && return 1

    local oradba_base="${ORADBA_BASE}"
    if [[ -z "${oradba_base}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        oradba_base="$(cd "${script_dir}/../.." && pwd)"
    fi

    local plugin_file="${oradba_base}/lib/plugins/${product_type}_plugin.sh"
    if [[ ! -f "${plugin_file}" ]]; then
        plugin_file="${oradba_base}/lib/plugins/${product_type}_plugin.sh"
        [[ ! -f "${plugin_file}" ]] && { oradba_log DEBUG "Plugin not found: ${product_type}_plugin.sh"; return 1; }
    fi

    local plugin_function="plugin_${function_name}"
    
    # Debug logging: Log plugin call details
    if is_plugin_debug_enabled; then
        local sanitized_args="plugin=${product_type}, function=${function_name}"
        if [[ "${oracle_home}" != "NOARGS" ]]; then
            sanitized_args="${sanitized_args}, oracle_home=${oracle_home}"
        fi
        if [[ -n "${extra_arg}" ]]; then
            sanitized_args="${sanitized_args}, extra_arg=$(sanitize_sensitive_data "${extra_arg}")"
        fi
        oradba_log DEBUG "Plugin call: ${sanitized_args}"
    fi
    
    local output
    local stderr_output
    
    # Create temp files for capturing stderr
    local temp_stderr
    temp_stderr=$(mktemp 2>/dev/null)
    
    # Verify mktemp succeeded - fail safely if not
    if [[ -z "${temp_stderr}" ]] || [[ ! -f "${temp_stderr}" ]]; then
        oradba_log ERROR "Failed to create temporary file for plugin stderr capture"
        return 2
    fi
    
    # Set up trap to ensure cleanup happens (use single quotes to defer expansion)
    # shellcheck disable=SC2064
    trap "rm -f '${temp_stderr}' 2>/dev/null" RETURN
    
    # Handle no-arg functions vs functions that take oracle_home
    if [[ "${oracle_home}" == "NOARGS" ]]; then
        # No-arg function (e.g., plugin_get_config_section)
        
        # Debug logging: Log environment snapshot
        if is_plugin_debug_enabled; then
            oradba_log DEBUG "Plugin env (no-arg): ORACLE_HOME=${ORACLE_HOME:-<unset>}, LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-<unset>}"
        fi
        
        output=$(
            # Set minimal Oracle environment from current context
            export ORACLE_HOME="${ORACLE_HOME:-}"
            export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
            # Unset inherited environment variables to prevent cross-contamination
            # TNS_ADMIN: Each product should use its own ORACLE_HOME/network/admin
            # plugin_status: Prevent experimental status from leaking between plugins
            unset TNS_ADMIN
            unset plugin_status
            # Note: Don't use set -euo pipefail here - plugins need flexibility
            # shellcheck disable=SC1090
            source "${plugin_file}" 2>"${temp_stderr}" || exit 1
            # Check if plugin is experimental
            if [[ -n "${plugin_status:-}" ]] && [[ "${plugin_status}" == "EXPERIMENTAL" ]]; then
                # Log to stderr so it doesn't pollute stdout
                echo "WARNING: Skipping experimental plugin: ${product_type}" >&2
                exit 1
            fi
            # Warn if plugin declares a different interface version than expected
            if [[ -n "${plugin_interface_version:-}" ]] && [[ "${plugin_interface_version}" != "1.0.0" ]]; then
                echo "WARNING: Plugin ${product_type} declares interface_version=${plugin_interface_version} (expected 1.0.0) — compatibility not guaranteed" >&2
            fi
            if ! declare -F "${plugin_function}" >/dev/null 2>&1; then
                exit 1
            fi
            "${plugin_function}" 2>>"${temp_stderr}"
        )
    else
        # Function takes oracle_home as argument
        
        # Debug logging: Log environment snapshot
        if is_plugin_debug_enabled; then
            local lib_path="${LD_LIBRARY_PATH:-${oracle_home}/lib}"
            oradba_log DEBUG "Plugin env: ORACLE_HOME=${oracle_home}, LD_LIBRARY_PATH=${lib_path}, TNS_ADMIN=<unset>, PATH=${PATH:-<unset>}"
        fi
        
        output=$(
            ORACLE_HOME="${oracle_home}"
            export ORACLE_HOME
            if [[ -z "${LD_LIBRARY_PATH:-}" ]]; then
                LD_LIBRARY_PATH="${oracle_home}/lib"
                export LD_LIBRARY_PATH
            fi
            # Unset inherited environment variables to prevent cross-contamination
            # TNS_ADMIN: Each product should use its own ORACLE_HOME/network/admin
            # plugin_status: Prevent experimental status from leaking between plugins
            unset TNS_ADMIN
            unset plugin_status
            # Note: Don't use set -euo pipefail here - plugins need flexibility
            # shellcheck disable=SC1090
            source "${plugin_file}" 2>"${temp_stderr}" || exit 1
            # Check if plugin is experimental
            if [[ -n "${plugin_status:-}" ]] && [[ "${plugin_status}" == "EXPERIMENTAL" ]]; then
                # Log to stderr so it doesn't pollute stdout
                echo "WARNING: Skipping experimental plugin: ${product_type}" >&2
                exit 1
            fi
            # Warn if plugin declares a different interface version than expected
            if [[ -n "${plugin_interface_version:-}" ]] && [[ "${plugin_interface_version}" != "1.0.0" ]]; then
                echo "WARNING: Plugin ${product_type} declares interface_version=${plugin_interface_version} (expected 1.0.0) — compatibility not guaranteed" >&2
            fi
            if ! declare -F "${plugin_function}" >/dev/null 2>&1; then
                exit 1
            fi
            if [[ -n "${extra_arg}" ]]; then
                "${plugin_function}" "${oracle_home}" "${extra_arg}" 2>>"${temp_stderr}"
            else
                "${plugin_function}" "${oracle_home}" 2>>"${temp_stderr}"
            fi
        )
    fi
    local exit_code=$?
    
    # Read stderr output if available (trap will clean up)
    if [[ -f "${temp_stderr}" ]]; then
        stderr_output=$(<"${temp_stderr}")
    fi
    
    # Trace logging: Log raw stdout/stderr
    if is_plugin_trace_enabled; then
        if [[ -n "${output}" ]]; then
            oradba_log TRACE "Plugin stdout: $(sanitize_sensitive_data "${output}")"
        fi
        if [[ -n "${stderr_output}" ]]; then
            oradba_log TRACE "Plugin stderr: $(sanitize_sensitive_data "${stderr_output}")"
        fi
    fi
    
    # Debug logging: Log exit code
    if is_plugin_debug_enabled; then
        oradba_log DEBUG "Plugin exit: code=${exit_code}, plugin=${product_type}, function=${function_name}"
    fi

    if [[ -n "${result_var_name}" ]]; then
        eval "${result_var_name}=\"\${output}\""
    else
        [[ -n "${output}" ]] && echo "${output}"
    fi

    return ${exit_code}
}

# ------------------------------------------------------------------------------
# Load sub-libraries (extracted from oradba_common.sh for cohesion)
# Resolve path from this file's location so it works regardless of ORADBA_BASE
# ------------------------------------------------------------------------------
_ORADBA_COMMON_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${_ORADBA_COMMON_DIR}/oradba_home_discovery.sh"
# shellcheck disable=SC1091
source "${_ORADBA_COMMON_DIR}/oradba_database_discovery.sh"
# shellcheck disable=SC1091
source "${_ORADBA_COMMON_DIR}/oradba_version_metadata.sh"
unset _ORADBA_COMMON_DIR
