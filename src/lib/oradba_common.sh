#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_common.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 0.18.3
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
        DEBUG) level_value=0 ;;
        INFO) level_value=1 ;;
        WARN) level_value=2 ;;
        ERROR) level_value=3 ;;
        SUCCESS) level_value=1 ;; # Same as INFO
        FAILURE) level_value=3 ;; # Same as ERROR
        SECTION) level_value=1 ;; # Same as INFO
        *) level_value=1 ;;       # Default to INFO for unknown levels
    esac

    case "${min_level^^}" in
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
        case "${level^^}" in
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

# ------------------------------------------------------------------------------
# Function: _show_deprecation_warning
# Purpose.: Display deprecation warning for legacy logging functions (internal)
# Args....: $1 - Function name being deprecated
#           $2 - New syntax to use instead
# Returns.: 0 - Always successful
# Output..: Deprecation warning to stderr (if ORADBA_SHOW_DEPRECATION_WARNINGS=true)
# Notes...: Only shows each warning once per session. Internal helper function.
#           Example: _show_deprecation_warning "log_info" "oradba_log INFO"
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: log_info
# Purpose.: Log informational message (DEPRECATED)
# Args....: $* - Message to log
# Returns.: Return code from oradba_log
# Output..: Formatted log message to stdout/file
# Notes...: DEPRECATED in v0.13.1 - Use oradba_log INFO "message" instead.
#           Example: log_info "Database connected successfully"
# ------------------------------------------------------------------------------
log_info() {
    _show_deprecation_warning "log_info" "oradba_log INFO"
    oradba_log INFO "$*"
}

# ------------------------------------------------------------------------------
# Function: log_warn
# Purpose.: Log warning message (DEPRECATED)
# Args....: $* - Warning message to log
# Returns.: Return code from oradba_log
# Output..: Formatted warning message to stderr/file
# Notes...: DEPRECATED in v0.13.1 - Use oradba_log WARN "message" instead.
#           Example: log_warn "Configuration file not found, using defaults"
# ------------------------------------------------------------------------------
log_warn() {
    _show_deprecation_warning "log_warn" "oradba_log WARN"
    oradba_log WARN "$*"
}

# ------------------------------------------------------------------------------
# Function: log_error
# Purpose.: Log error message (DEPRECATED)
# Args....: $* - Error message to log
# Returns.: Return code from oradba_log
# Output..: Formatted error message to stderr/file
# Notes...: DEPRECATED in v0.13.1 - Use oradba_log ERROR "message" instead.
#           Example: log_error "Failed to connect to database"
# ------------------------------------------------------------------------------
log_error() {
    _show_deprecation_warning "log_error" "oradba_log ERROR"
    oradba_log ERROR "$*"
}

# ------------------------------------------------------------------------------
# Function: log_debug
# Purpose.: Log debug message (DEPRECATED)
# Args....: $* - Debug message to log
# Returns.: Return code from oradba_log
# Output..: Formatted debug message (only if ORADBA_LOG_LEVEL=DEBUG)
# Notes...: DEPRECATED in v0.13.1 - Use oradba_log DEBUG "message" instead.
#           Example: log_debug "Entering function: validate_config"
# ------------------------------------------------------------------------------
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
    return 1
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
# Output..: Oracle version string (e.g., 19.0.0.0)
# Notes...: Requires ORACLE_HOME to be set and sqlplus to be executable
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: parse_oratab
# Purpose.: Parse oratab file to get Oracle home path for a SID
# Args....: $1 - Oracle SID to look up
#           $2 - (Optional) Path to oratab file (defaults to get_oratab_path)
# Returns.: 0 if SID found, 1 if not found or error
# Output..: Oracle home path for the specified SID
# Notes...: Skips comment lines and dummy entries (:D flag)
# ------------------------------------------------------------------------------
parse_oratab() {
    local sid="$1"
    local oratab_file="${2:-$(get_oratab_path)}"

    if [[ ! -f "$oratab_file" ]]; then
        oradba_log ERROR "oratab file not found: $oratab_file"
        return 1
    fi

    # Case-insensitive search for SID
    grep -i "^${sid}:" "$oratab_file" | grep -v "^#" | head -1
}

# ------------------------------------------------------------------------------
# Function: generate_sid_lists
# Purpose.: Generate SID lists and aliases from oratab and Oracle Homes config
# Args....: $1 - (Optional) Path to oratab file (defaults to get_oratab_path)
# Returns.: 0 on success, 1 if oratab not found
# Output..: Sets ORADBA_SIDLIST and ORADBA_REALSIDLIST environment variables
# Notes...: SIDLIST includes all SIDs and aliases, REALSIDLIST excludes dummies
# ------------------------------------------------------------------------------
generate_sid_lists() {
    local oratab_file="${1:-$(get_oratab_path)}"

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

    # Add Oracle Home names and aliases to ORADBA_SIDLIST
    local homes_config
    homes_config=$(get_oracle_homes_path 2>/dev/null) || homes_config=""
    if [[ -f "${homes_config}" ]]; then
        while IFS=: read -r name _path _type _order alias_name _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Trim whitespace
            name="${name#"${name%%[![:space:]]*}"}"
            name="${name%"${name##*[![:space:]]}"}"
            alias_name="${alias_name#"${alias_name%%[![:space:]]*}"}"
            alias_name="${alias_name%"${alias_name##*[![:space:]]}"}"
            
            # Add Oracle Home name to all_sids list
            all_sids="${all_sids}${all_sids:+ }${name}"
            
            # Add alias if it exists and is different from name
            if [[ -n "${alias_name}" && "${alias_name}" != "${name}" && ! "${alias_name}" =~ [[:space:]] ]]; then
                all_sids="${all_sids}${all_sids:+ }${alias_name}"
            fi
        done < "${homes_config}"
    fi

    # Export the lists
    export ORADBA_SIDLIST="$all_sids"
    export ORADBA_REALSIDLIST="$real_sids"

    oradba_log DEBUG "ORADBA_SIDLIST: $ORADBA_SIDLIST"
    oradba_log DEBUG "ORADBA_REALSIDLIST: $ORADBA_REALSIDLIST"

    return 0
}

# ------------------------------------------------------------------------------
# Function: generate_oracle_home_aliases
# Purpose.: Create shell aliases for all registered Oracle Homes
# Args....: None
# Returns.: 0 on success
# Output..: Creates shell aliases for Oracle Home switching
# Notes...: Creates aliases for both NAME and ALIAS_NAME entries
#           Example: DBHOMEFREE and rdbms26 both point to same home
# ------------------------------------------------------------------------------
generate_oracle_home_aliases() {
    local homes_config
    
    # Get Oracle Homes config path
    homes_config=$(get_oracle_homes_path 2>/dev/null) || {
        oradba_log DEBUG "Oracle Homes config not found"
        return 0
    }
    
    # Check if Oracle Homes config exists
    if [[ ! -f "${homes_config}" ]]; then
        oradba_log DEBUG "Oracle Homes config not found: ${homes_config}"
        return 0
    fi
    
    local name alias_name
    
    # Parse Oracle Homes config (skip comments and empty lines)
    # File format: NAME:PATH:TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION
    while IFS=: read -r name _path _type _order alias_name _desc _version; do
        # Skip empty lines and comments
        [[ -z "${name}" ]] && continue
        [[ "${name}" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace from fields
        name="${name#"${name%%[![:space:]]*}"}"
        name="${name%"${name##*[![:space:]]}"}"
        alias_name="${alias_name#"${alias_name%%[![:space:]]*}"}"
        alias_name="${alias_name%"${alias_name##*[![:space:]]}"}"
        
        # Create alias for the Oracle Home name (lowercase, consistent with SID aliases)
        local name_lower="${name,,}"
        # shellcheck disable=SC2139
        alias "${name_lower}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${name}"
        oradba_log DEBUG "Created Oracle Home alias: ${name_lower}"
        
        # Create alias for the alias name if it exists and is different from lowercase name
        if [[ -n "${alias_name}" && "${alias_name}" != "${name_lower}" ]]; then
            # shellcheck disable=SC2139
            alias "${alias_name}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${name}"
            oradba_log DEBUG "Created Oracle Home alias: ${alias_name} -> ${name}"
        fi
    done < "${homes_config}"
    
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
    if ! check_database_connection 2> /dev/null; then
        oradba_log DEBUG "No database connection, skipping PDB alias generation"
        return 0
    fi

    # Skip if not a CDB
    local is_cdb
    is_cdb=$(
        sqlplus -s / as sysdba << EOF
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
    pdb_list=$(
        sqlplus -s / as sysdba << EOF
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

# ------------------------------------------------------------------------------
# Function: discover_running_oracle_instances
# Purpose.: Auto-discover running Oracle instances when oratab is empty
# Args....: None
# Returns.: 0 if instances discovered, 1 if none found
# Output..: Prints discovered instances in oratab format (SID:ORACLE_HOME:N)
#           to stdout, one per line
# Notes...: - Only checks processes owned by current user
#           - Detects db_smon_*, ora_pmon_*, asm_smon_* processes
#           - Extracts ORACLE_HOME from /proc/<pid>/exe
#           - Adds temporary entries with startup flag 'N'
#           - Shows warning if Oracle processes run as different user
# ------------------------------------------------------------------------------
discover_running_oracle_instances() {
    local current_user
    current_user=$(id -un)
    
    oradba_log DEBUG "Discovering running Oracle instances for user: $current_user"
    
    # Check for Oracle processes running as different user
    local other_user_processes
    other_user_processes=$(ps -eo user,comm | grep -E "(db_smon_|ora_pmon_|asm_smon_)" | grep -v "^${current_user}" | wc -l)
    
    if [[ "$other_user_processes" -gt 0 ]]; then
        oradba_log WARN "Oracle processes detected running as different user(s)"
        oradba_log WARN "Auto-discovery only works for processes owned by: $current_user"
    fi
    
    # Find Oracle smon/pmon processes for current user
    # Pattern matches: db_smon_FREE, ora_pmon_orcl, asm_smon_+ASM
    local discovered_count=0
    local -A seen_sids  # Track SIDs to avoid duplicates
    
    # Get processes for current user only
    while read -r pid comm; do
        local sid=""
        local oracle_home=""
        
        # Extract SID from process name
        if [[ "$comm" =~ ^db_smon_(.+)$ ]]; then
            sid="${BASH_REMATCH[1]}"
        elif [[ "$comm" =~ ^ora_pmon_(.+)$ ]]; then
            # Convert lowercase pmon SID to uppercase
            sid="${BASH_REMATCH[1]^^}"
        elif [[ "$comm" =~ ^asm_smon_(.+)$ ]]; then
            sid="${BASH_REMATCH[1]}"
        else
            continue
        fi
        
        # Skip if we've already seen this SID
        [[ -n "${seen_sids[$sid]:-}" ]] && continue
        
        # Determine ORACLE_HOME from /proc/<pid>/exe
        if [[ -d "/proc" && -L "/proc/$pid/exe" ]]; then
            local exe_path
            exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
            
            # Extract ORACLE_HOME (everything before /bin/oracle)
            if [[ "$exe_path" =~ ^(.+)/bin/oracle$ ]]; then
                oracle_home="${BASH_REMATCH[1]}"
            elif [[ "$exe_path" =~ ^(.+)/bin/asm$ ]]; then
                # Handle ASM processes
                oracle_home="${BASH_REMATCH[1]}"
            fi
        fi
        
        # If we couldn't determine ORACLE_HOME, try ps environment
        if [[ -z "$oracle_home" ]] && [[ -r "/proc/$pid/environ" ]]; then
            oracle_home=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep "^ORACLE_HOME=" | cut -d= -f2)
        fi
        
        # If still no ORACLE_HOME, skip this instance
        if [[ -z "$oracle_home" || ! -d "$oracle_home" ]]; then
            oradba_log WARN "Could not determine ORACLE_HOME for SID: $sid (PID: $pid)"
            continue
        fi
        
        # Output discovered instance in oratab format
        echo "${sid}:${oracle_home}:N"
        seen_sids[$sid]=1
        ((discovered_count++))
        
        oradba_log INFO "Auto-discovered Oracle instance: $sid ($oracle_home)"
        
    done < <(ps -U "$current_user" -o pid,comm --no-headers 2>/dev/null | grep -E "(db_smon_|ora_pmon_|asm_smon_)")
    
    if [[ $discovered_count -gt 0 ]]; then
        oradba_log INFO "Discovered $discovered_count running Oracle instance(s)"
        oradba_log INFO "These are temporary entries - review and add to oratab if needed"
        return 0
    else
        oradba_log DEBUG "No running Oracle instances found for user: $current_user"
        return 1
    fi
}

# Export common Oracle environment variables
# ------------------------------------------------------------------------------
# Function: export_oracle_base_env
# Purpose.: Export common Oracle environment variables
# Args....: None
# Returns.: 0 - Always successful
# Output..: None (exports variables)
# Notes...: Exports PATH, LD_LIBRARY_PATH, TNS_ADMIN, NLS_LANG, etc.
#           Example: export_oracle_base_env
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Oracle Homes Management Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: get_oracle_homes_path
# Purpose.: Get path to oradba_homes.conf configuration file
# Args....: None
# Returns.: 0 if file exists, 1 if not found
# Output..: Prints path to oradba_homes.conf
# Notes...: Looks for ${ORADBA_BASE}/etc/oradba_homes.conf
# ------------------------------------------------------------------------------
get_oracle_homes_path() {
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"

    if [[ -f "${homes_file}" ]]; then
        echo "${homes_file}"
        return 0
    fi

    return 1
}

# ------------------------------------------------------------------------------
# Function: resolve_oracle_home_name
# Purpose.: Resolve Oracle Home alias to actual NAME from oradba_homes.conf
# Args....: $1 - Name or alias to resolve
# Returns.: 0 on success, 1 if not found or error
# Output..: Actual Oracle Home NAME (or original if not found)
# Notes...: Checks both NAME and ALIAS_NAME columns in oradba_homes.conf
# ------------------------------------------------------------------------------
resolve_oracle_home_name() {
    local name_or_alias="$1"
    local homes_file

    if [[ -z "${name_or_alias}" ]]; then
        echo "${name_or_alias}"
        return 1
    fi

    homes_file=$(get_oracle_homes_path) || {
        echo "${name_or_alias}"
        return 1
    }

    # Parse file and check both NAME and ALIAS_NAME
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        # Check if match is NAME
        if [[ "${h_name}" == "${name_or_alias}" ]]; then
            echo "${h_name}"
            return 0
        fi

        # Check if match is ALIAS_NAME (if alias exists and is not a description)
        if [[ -n "${h_alias}" ]] && [[ ! "${h_alias}" =~ [[:space:]] ]]; then
            if [[ "${h_alias}" == "${name_or_alias}" ]]; then
                echo "${h_name}"
                return 0
            fi
        fi
    done < "${homes_file}"

    # Not found, return original (still valid)
    echo "${name_or_alias}"
    return 0
}

# Arguments:
#   $1 - Home name or alias to parse
# Returns: Space-separated: name path type order alias_name description version
# ------------------------------------------------------------------------------
# Function: parse_oracle_home
# Purpose.: Parse Oracle Home configuration entry from oradba_homes.conf
# Args....: $1 - Oracle Home name or alias to parse
# Returns.: 0 - Successfully parsed
#           1 - Oracle Home not found
# Output..: Space-separated values: name alias type path version
# Notes...: Example: read -r oh_name oh_alias oh_type oh_path oh_version < <(parse_oracle_home "ora19")
#           Returns: "ora19 19c database /u01/app/oracle/product/19.3.0/dbhome_1 19.3.0"
# ------------------------------------------------------------------------------
parse_oracle_home() {
    local name="$1"
    local homes_file
    local actual_name

    if [[ -z "${name}" ]]; then
        log_error "Home name required"
        return 1
    fi

    # Resolve alias to actual name
    actual_name=$(resolve_oracle_home_name "${name}")

    homes_file=$(get_oracle_homes_path) || return 1

    # Parse file: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER[:ALIAS_NAME][:DESCRIPTION][:VERSION]
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        if [[ "${h_name}" == "${actual_name}" ]]; then
            # If h_alias is empty or looks like a description, use h_name as alias
            if [[ -z "${h_alias}" ]] || [[ "${h_alias}" =~ [[:space:]] ]]; then
                # h_alias is actually description, shift values
                h_version="${h_desc}"
                h_desc="${h_alias}"
                h_alias="${h_name}"
            fi
            # Default version to AUTO if not specified
            [[ -z "${h_version}" ]] && h_version="AUTO"
            echo "${h_name} ${h_path} ${h_type} ${h_order} ${h_alias} ${h_desc} ${h_version}"
            return 0
        fi
    done < "${homes_file}"

    return 1
}

# ------------------------------------------------------------------------------
# Function: list_oracle_homes
# Purpose.: List all Oracle Homes from oradba_homes.conf
# Args....: $1 - (Optional) Filter by product type
# Returns.: 0 on success, 1 if config file not found
# Output..: One line per home: NAME PATH TYPE ORDER ALIAS DESCRIPTION VERSION
# Notes...: Output sorted by ORDER (column 4), ascending
# ------------------------------------------------------------------------------
list_oracle_homes() {
    local filter="$1"
    local homes_file

    homes_file=$(get_oracle_homes_path) || return 1

    # Parse and optionally filter
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        # Apply filter if specified
        if [[ -n "${filter}" ]]; then
            [[ "${h_type}" != "${filter}" ]] && continue
        fi

        # If h_alias is empty or looks like a description, use h_name as alias
        if [[ -z "${h_alias}" ]] || [[ "${h_alias}" =~ [[:space:]] ]]; then
            # h_alias is actually description, shift values
            h_version="${h_desc}"
            h_desc="${h_alias}"
            h_alias="${h_name}"
        fi
        
        # Default version to AUTO if not specified
        [[ -z "${h_version}" ]] && h_version="AUTO"

        # Output: name path type order alias_name description version
        echo "${h_name} ${h_path} ${h_type} ${h_order} ${h_alias} ${h_desc} ${h_version}"
    done < "${homes_file}" | sort -k4 -n
}

# ------------------------------------------------------------------------------
# Function: get_oracle_home_path
# Purpose.: Get ORACLE_HOME path for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: ORACLE_HOME path
# Notes...: Reads from oradba_homes.conf, column 2 (PATH)
# ------------------------------------------------------------------------------
get_oracle_home_path() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $2}'
}

# ------------------------------------------------------------------------------
# Function: get_oracle_home_alias
# Purpose.: Get alias name for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: Alias name (or home name if no alias defined)
# Notes...: Reads from oradba_homes.conf, column 5 (ALIAS_NAME)
# ------------------------------------------------------------------------------
get_oracle_home_alias() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $5}'
}

# ------------------------------------------------------------------------------
# Function: get_oracle_home_type
# Purpose.: Get product type for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: Product type (database, client, oud, weblogic, oms, emagent, etc.)
# Notes...: Reads from oradba_homes.conf, column 3 (TYPE)
# ------------------------------------------------------------------------------
get_oracle_home_type() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $3}'
}

# ------------------------------------------------------------------------------
# Function: detect_product_type
# Purpose.: Detect Oracle product type from ORACLE_HOME path
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if unable to detect
# Output..: Product type: database, client, oud, weblogic, oms, emagent,
#           datasafe, or unknown
# Notes...: Checks for specific files/directories to identify product type
# ------------------------------------------------------------------------------
detect_product_type() {
    local oracle_home="$1"

    [[ -z "${oracle_home}" ]] && echo "unknown" && return 1
    [[ ! -d "${oracle_home}" ]] && echo "unknown" && return 1

    # Check for Oracle Unified Directory
    if [[ -f "${oracle_home}/oud/lib/ldapjdk.jar" ]]; then
        echo "oud"
        return 0
    fi

    # Check for WebLogic
    if [[ -f "${oracle_home}/wlserver/server/lib/weblogic.jar" ]]; then
        echo "weblogic"
        return 0
    fi

    # Check for OMS
    if [[ -f "${oracle_home}/sysman/lib/emoms.jar" ]]; then
        echo "oms"
        return 0
    fi

    # Check for EM Agent
    if [[ -f "${oracle_home}/agent_inst/bin/emctl" ]]; then
        echo "emagent"
        return 0
    fi

    # Check for Oracle Client
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ ! -f "${oracle_home}/bin/oracle" ]]; then
        echo "client"
        return 0
    fi

    # Check for Data Safe
    if [[ -f "${oracle_home}/datasafe/lib/datasafe.jar" ]]; then
        echo "datasafe"
        return 0
    fi

    # Check for Database (has sqlplus and oracle binary)
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ -f "${oracle_home}/bin/oracle" ]]; then
        echo "database"
        return 0
    fi

    echo "unknown"
    return 1
}

# Detect Oracle version from ORACLE_HOME
# Arguments:
#   $1 - ORACLE_HOME path
#   $2 - Product type (optional, will detect if not provided)
# Returns: Oracle version in format XXYZ (e.g., 1920 for 19.2.0) or "Unknown" or "ERR"
detect_oracle_version() {
    local oracle_home="$1"
    local product_type="${2:-}"
    local version=""

    [[ -z "${oracle_home}" ]] && echo "Unknown" && return 1
    [[ ! -d "${oracle_home}" ]] && echo "Unknown" && return 1

    # Auto-detect product type if not provided
    if [[ -z "${product_type}" ]]; then
        product_type=$(detect_product_type "${oracle_home}")
    fi

    # For non-database products without version info, return ERR
    if [[ "${product_type}" =~ ^(datasafe|weblogic|oms|emagent|oud)$ ]]; then
        echo "ERR"
        return 0
    fi

    # Method 1: Try sqlplus -version (for database and client homes)
    if [[ -f "${oracle_home}/bin/sqlplus" ]]; then
        local sqlplus_version
        sqlplus_version=$("${oracle_home}/bin/sqlplus" -version 2>/dev/null | grep -i "Release" | head -1)
        
        if [[ -n "${sqlplus_version}" ]]; then
            # Extract version like "19.21.0.0.0" or "23.0.0.0.0"
            local ver_str
            ver_str=$(echo "${sqlplus_version}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            
            if [[ -n "${ver_str}" ]]; then
                # Convert to XXYZ format: 19.21.0.0 -> 1921, 23.0.0.0 -> 2300
                local major minor
                major=$(echo "${ver_str}" | cut -d. -f1)
                minor=$(echo "${ver_str}" | cut -d. -f2)
                # Pad to 2 digits
                printf "%02d%02d" "${major}" "${minor}"
                return 0
            fi
        fi
    fi

    # Method 2: Try OPatch inventory
    if [[ -f "${oracle_home}/OPatch/opatch" ]]; then
        local opatch_version
        opatch_version=$("${oracle_home}/OPatch/opatch" lsinventory 2>/dev/null | grep -i "Oracle Database" | head -1)
        
        if [[ -n "${opatch_version}" ]]; then
            local ver_str
            ver_str=$(echo "${opatch_version}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            
            if [[ -n "${ver_str}" ]]; then
                local major minor
                major=$(echo "${ver_str}" | cut -d. -f1)
                minor=$(echo "${ver_str}" | cut -d. -f2)
                printf "%02d%02d" "${major}" "${minor}"
                return 0
            fi
        fi
    fi

    # Method 3: Try inventory XML
    if [[ -f "${oracle_home}/inventory/ContentsXML/comps.xml" ]]; then
        local xml_version
        xml_version=$(grep -i "VER=" "${oracle_home}/inventory/ContentsXML/comps.xml" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        
        if [[ -n "${xml_version}" ]]; then
            local major minor
            major=$(echo "${xml_version}" | cut -d. -f1)
            minor=$(echo "${xml_version}" | cut -d. -f2)
            printf "%02d%02d" "${major}" "${minor}"
            return 0
        fi
    fi

    # Method 4: Extract from path (e.g., /product/19.0.0.0 or /product/23.26.0.0/client)
    local path_version
    path_version=$(echo "${oracle_home}" | grep -oE '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [[ -n "${path_version}" ]]; then
        local major minor
        major=$(echo "${path_version}" | cut -d. -f1)
        minor=$(echo "${path_version}" | cut -d. -f2)
        printf "%02d%02d" "${major}" "${minor}"
        return 0
    fi

    echo "Unknown"
    return 1
}

# ------------------------------------------------------------------------------
# Function: derive_oracle_base
# Purpose.: Derive ORACLE_BASE from ORACLE_HOME by searching upward
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if unable to derive
# Output..: Derived ORACLE_BASE path
# Notes...: Searches upward for directory containing "product", "oradata",
#           "oraInventory", or "admin" (max 5 levels)
# ------------------------------------------------------------------------------
derive_oracle_base() {
    local oracle_home="$1"
    local current_dir="${oracle_home}"
    
    [[ -z "${oracle_home}" ]] && return 1
    [[ ! -d "${oracle_home}" ]] && return 1
    
    # Walk up the directory tree looking for Oracle base indicators
    while [[ "${current_dir}" != "/" ]]; do
        local parent_dir
        parent_dir="$(dirname "${current_dir}")"
        
        # Check if current dir contains typical Oracle base subdirectories
        if [[ -d "${parent_dir}/product" ]] || \
           [[ -d "${parent_dir}/oradata" ]] || \
           [[ -d "${parent_dir}/oraInventory" ]] || \
           [[ -d "${parent_dir}/admin" ]]; then
            echo "${parent_dir}"
            return 0
        fi
        
        # Stop if we've gone up too far (more than 5 levels)
        local depth=0
        local test_path="${oracle_home}"
        while [[ "${test_path}" != "${parent_dir}" ]] && [[ "${test_path}" != "/" ]]; do
            test_path="$(dirname "${test_path}")"
            ((depth++))
            if [[ ${depth} -gt 5 ]]; then
                break 2
            fi
        done
        
        current_dir="${parent_dir}"
    done
    
    # Fallback: use traditional two-levels-up method
    dirname "$(dirname "${oracle_home}")"
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
# Returns.: 0 - Environment set successfully
#           1 - Oracle Home not found or invalid
# Output..: Debug/error messages via oradba_log
# Notes...: Sets ORACLE_HOME, ORACLE_BASE, PATH, LD_LIBRARY_PATH, etc.
#           Example: set_oracle_home_environment "ora19"
# ------------------------------------------------------------------------------
set_oracle_home_environment() {
    local name="$1"
    local oracle_home="$2"
    local product_type
    local actual_name
    local alias_name

    # Resolve alias to actual name if needed
    actual_name=$(resolve_oracle_home_name "${name}")
    
    # Get ORACLE_HOME if not provided
    if [[ -z "${oracle_home}" ]]; then
        oracle_home=$(get_oracle_home_path "${actual_name}") || return 1
    fi

    # Detect product type
    product_type=$(detect_product_type "${oracle_home}")

    # Set base environment
    export ORACLE_HOME="${oracle_home}"
    export ORADBA_CURRENT_HOME_TYPE="${product_type}"
    
    # Set home tracking variables for PS1
    export ORADBA_CURRENT_HOME="${actual_name}"
    alias_name=$(get_oracle_home_alias "${actual_name}" 2>/dev/null || echo "${actual_name}")
    export ORADBA_CURRENT_HOME_ALIAS="${alias_name}"
    
    # Create alias for this Oracle Home (consistent with SID aliases)
    # Always use actual name in alias target, not the alias itself
    # shellcheck disable=SC2139  # We want the alias to expand now
    alias "${alias_name}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${actual_name}"

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
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
        *)
            log_warn "Unknown product type: ${product_type}"
            export PATH="${ORACLE_HOME}/bin:${PATH}"
            ;;
    esac

    log_debug "Set environment for ${name} (${product_type}): ${ORACLE_HOME}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: is_oracle_home
# Purpose.: Check if given name refers to an Oracle Home (vs database SID)
# Args....: $1 - Name to check (Oracle Home name/alias or SID)
# Returns.: 0 - Name is an Oracle Home
#           1 - Name is not an Oracle Home (likely a SID)
# Output..: None
# Notes...: Example: if is_oracle_home "ora19"; then echo "Oracle Home"; fi
# ------------------------------------------------------------------------------
is_oracle_home() {
    local name="$1"

    [[ -z "${name}" ]] && return 1

    parse_oracle_home "${name}" > /dev/null 2>&1
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

# ------------------------------------------------------------------------------
# Function: get_oradba_version
# Purpose.: Get OraDBA version from VERSION file
# Args....: None
# Returns.: 0 - Version retrieved successfully
#           1 - VERSION file not found
# Output..: Version string (e.g., "1.0.0-dev") or "unknown"
# Notes...: Example: version=$(get_oradba_version)
# ------------------------------------------------------------------------------
get_oradba_version() {
    local version_file="${ORADBA_BASE}/VERSION"

    if [[ -f "${version_file}" ]]; then
        cat "${version_file}" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# Function: version_compare
# Purpose.: Compare two semantic version strings
# Args....: $1 - First version string (e.g., "1.2.3")
#           $2 - Second version string (e.g., "1.2.0")
# Returns.: 0 - Versions are equal
#           1 - First version is greater
#           2 - Second version is greater
# Output..: None
# Notes...: Example: version_compare "1.2.3" "1.2.0"; result=$?  # Returns 1
# ------------------------------------------------------------------------------
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

        if ((part1 > part2)); then
            return 1
        elif ((part1 < part2)); then
            return 2
        fi
    done

    return 0
}

# ------------------------------------------------------------------------------
# Function: version_meets_requirement
# Purpose.: Check if current version meets minimum requirement
# Args....: $1 - Current version string
#           $2 - Required version string
# Returns.: 0 - Current version meets requirement (>=)
#           1 - Current version does not meet requirement
# Output..: None
# Notes...: Example: if version_meets_requirement "1.2.3" "1.2.0"; then echo "OK"; fi
# ------------------------------------------------------------------------------
version_meets_requirement() {
    local current_version="$1"
    local required_version="$2"

    version_compare "$current_version" "$required_version"
    local result=$?

    # Returns 0 (equal) or 1 (greater) means requirement is met
    [[ $result -eq 0 || $result -eq 1 ]]
}

# ------------------------------------------------------------------------------
# Function: get_install_info
# Purpose.: Get installation metadata value by key
# Args....: $1 - Metadata key to retrieve
# Returns.: 0 - Key found and value retrieved
#           1 - Key not found or .install_info file doesn't exist
# Output..: Value for the specified key
# Notes...: Supports both old format (install_version) and new format (version).
#           Example: install_date=$(get_install_info "install_date")
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: set_install_info
# Purpose.: Set installation metadata key-value pair
# Args....: $1 - Metadata key
#           $2 - Metadata value
# Returns.: 0 - Key-value set successfully
#           1 - Failed to write to .install_info file
# Output..: None
# Notes...: Uses lowercase keys without quotes for consistency with installer.
#           Example: set_install_info "install_date" "2026-01-14"
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: init_install_info
# Purpose.: Initialize installation info file with metadata
# Args....: None
# Returns.: 0 - Installation info initialized successfully
#           1 - Failed to create .install_info file
# Output..: Info message about initialization
# Notes...: Uses lowercase keys without quotes to match installer format.
#           Creates ${ORADBA_BASE}/.install_info with install metadata.
#           Example: init_install_info
# ------------------------------------------------------------------------------
init_install_info() {
    local version="$1"
    local install_info="${ORADBA_BASE}/.install_info"

    cat > "${install_info}" << EOF
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
        mkdir -p "${HOME}/.oradba/sql" 2> /dev/null && log_debug "Created user SQL directory: ${HOME}/.oradba/sql"
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
