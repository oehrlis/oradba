#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: database_plugin.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Version....: 1.0.0
# Purpose....: Plugin for Oracle Database homes (RDBMS)
# Notes......: Handles database detection, status checking, and environment
#              Implements plugin interface v1.0.0
# Reference..: Architecture Review & Refactoring Plan (Phase 1.2)
# License....: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="database"
export plugin_version="1.0.0"
export plugin_interface_version="1.0.0"
export plugin_description="Oracle Database (RDBMS) plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect database installations
# Returns.: 0 on success
# Output..: List of ORACLE_HOME paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check running pmon processes
    while read -r pmon_line; do
        local sid
        sid=$(echo "${pmon_line}" | grep -oP 'pmon_\K\w+')
        [[ -z "${sid}" ]] && continue
        
        # Try to get ORACLE_HOME from process environment
        local pid
        pid=$(echo "${pmon_line}" | awk '{print $2}')
        if [[ -n "${pid}" ]] && [[ -d "/proc/${pid}" ]]; then
            local home
            home=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep '^ORACLE_HOME=' | cut -d= -f2-)
            if [[ -n "${home}" ]] && [[ -d "${home}" ]]; then
                homes+=("${home}")
            fi
        fi
    done < <(ps -ef | grep "[p]mon_")
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is a database home
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for database-specific directories
    [[ -d "${home_path}/rdbms" ]] || return 1
    [[ -d "${home_path}/bin" ]] || return 1
    
    # Check for sqlplus or oracle executables
    [[ -f "${home_path}/bin/sqlplus" ]] || [[ -f "${home_path}/bin/oracle" ]] || return 1
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for database home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME (unchanged for database)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if database instance is running
# Args....: $1 - ORACLE_HOME path
#           $2 - SID (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable/error
# Output..: None - status communicated via exit code only
# Notes...: Returns 2 if oracle binary is missing
#           Can return metadata for mounted/nomount states in future enhancement
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local sid="${2:-}"
    
    # Validate ORACLE_HOME exists and has oracle binary
    if [[ ! -d "${home_path}" ]] || [[ ! -f "${home_path}/bin/oracle" ]]; then
        return 2
    fi
    
    if [[ -z "${sid}" ]]; then
        # No SID specified, check if any pmon from this home
        while read -r pmon_line; do
            local pid
            pid=$(echo "${pmon_line}" | awk '{print $2}')
            if [[ -n "${pid}" ]] && [[ -d "/proc/${pid}" ]]; then
                local proc_home
                proc_home=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep '^ORACLE_HOME=' | cut -d= -f2-)
                if [[ "${proc_home}" == "${home_path}" ]]; then
                    return 0
                fi
            fi
        done < <(ps -ef | grep "[p]mon_")
        return 1
    else
        # Specific SID requested
        if ps -ef | grep -q "[p]mon_${sid}$"; then
            return 0
        else
            return 1
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get database metadata
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    # Get version using plugin_get_version
    # Only output version if available (no sentinel strings)
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    fi
    
    # Detect edition
    if [[ -f "${home_path}/bin/oracle" ]]; then
        if strings "${home_path}/bin/oracle" 2>/dev/null | grep -q "Enterprise Edition"; then
            echo "edition=Enterprise"
        elif strings "${home_path}/bin/oracle" 2>/dev/null | grep -q "Standard Edition"; then
            echo "edition=Standard"
        elif strings "${home_path}/bin/oracle" 2>/dev/null | grep -q "Express Edition"; then
            echo "edition=Express"
        else
            echo "edition=unknown"
        fi
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Database homes should show listener status
# Returns.: 0 (always show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_listener_status
# Purpose.: Check listener status for database Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Listener lifecycle is separate from instance lifecycle
#           Uses lsnrctl status to check listener state
# ------------------------------------------------------------------------------
plugin_check_listener_status() {
    local home_path="$1"
    local lsnrctl="${home_path}/bin/lsnrctl"
    
    # Check if lsnrctl exists
    [[ ! -x "${lsnrctl}" ]] && {
        echo "unavailable"
        return 2
    }
    
    # Check listener status using lsnrctl
    # Set minimal environment for the command
    local status_output
    status_output=$(ORACLE_HOME="${home_path}" \
                    LD_LIBRARY_PATH="${home_path}/lib:${LD_LIBRARY_PATH:-}" \
                    "${lsnrctl}" status 2>/dev/null)
    local exit_code=$?
    
    # Parse output - listener is running if we get a successful status
    if [[ ${exit_code} -eq 0 ]] && echo "${status_output}" | grep -q "Instance.*status READY"; then
        echo "running"
        return 0
    elif [[ ${exit_code} -eq 0 ]] || echo "${status_output}" | grep -q "Connecting to"; then
        # If we got a connection attempt or partial output, listener might be running
        echo "running"
        return 0
    else
        # Listener is not running
        echo "stopped"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover database instances for this home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: List of instances with status
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    
    # Find all running instances from this home
    while read -r pmon_line; do
        local sid
        sid=$(echo "${pmon_line}" | grep -oP 'pmon_\K\w+')
        [[ -z "${sid}" ]] && continue
        
        local pid
        pid=$(echo "${pmon_line}" | awk '{print $2}')
        if [[ -n "${pid}" ]] && [[ -d "/proc/${pid}" ]]; then
            local proc_home
            proc_home=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep '^ORACLE_HOME=' | cut -d= -f2-)
            if [[ "${proc_home}" == "${home_path}" ]]; then
                echo "${sid}|running|"
            fi
        fi
    done < <(ps -ef | grep "[p]mon_")
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base (ORACLE_BASE_HOME-aware)
# Args....: $1 - Input ORACLE_HOME or ORACLE_BASE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: For database, prefer ORACLE_BASE_HOME if set, otherwise use ORACLE_HOME
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    # If ORACLE_BASE_HOME is provided via env, prefer it
    if [[ -n "${ORACLE_BASE_HOME:-}" ]]; then
        echo "${ORACLE_BASE_HOME}"
    else
        echo "${home_path}"
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for database instance
# Args....: $1 - ORACLE_HOME
#           $2 - ORACLE_SID (optional)
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds complete environment for database instance
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    local instance="${2:-}"
    
    local base_path
    base_path=$(plugin_build_base_path "${home_path}")
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")
    
    echo "ORACLE_BASE_HOME=${base_path}"
    echo "ORACLE_HOME=${home_path}"
    [[ -n "${instance}" ]] && echo "ORACLE_SID=${instance}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate all database instances for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: Reads oratab for instances using this ORACLE_HOME
#           Handles D (dummy) flag - sets status=stopped and metadata=dummy
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    local oratab_file="${ORATAB_FILE:-/etc/oratab}"
    
    [[ ! -f "${oratab_file}" ]] && return 0
    
    # Find all SIDs using this ORACLE_HOME
    while IFS=: read -r sid oh autostart; do
        # Skip comments and empty lines
        [[ "${sid}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${sid}" ]] && continue
        
        # Match ORACLE_HOME
        if [[ "${oh}" == "${home_path}" ]]; then
            local status
            local metadata="autostart=${autostart}"
            
            # Handle D (dummy) flag - mark as stopped with dummy flag
            if [[ "${autostart}" == "D" ]]; then
                status="stopped"
                metadata="${metadata},dummy=true"
            else
                # Check actual status for non-dummy instances
                if ps -ef | grep -q "[p]mon_${sid}$"; then
                    status="running"
                else
                    status="stopped"
                fi
            fi
            
            echo "${sid}|${status}|${metadata}"
        fi
    done < "${oratab_file}"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Databases support SID aliases
# Returns.: 0 (supports aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for database installations
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns bin and OPatch directories
#           If GRID_HOME exists and differs from ORACLE_HOME, includes Grid bin
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local oracle_home="$1"
    local new_path=""
    
    # Full database installation: bin + OPatch
    if [[ -d "${oracle_home}/bin" ]]; then
        new_path="${oracle_home}/bin"
    fi
    
    if [[ -d "${oracle_home}/OPatch" ]]; then
        new_path="${new_path:+${new_path}:}${oracle_home}/OPatch"
    fi
    
    # If GRID_HOME exists and differs from ORACLE_HOME, add Grid bin
    if [[ -n "${GRID_HOME:-}" ]] && [[ "${GRID_HOME}" != "${oracle_home}" ]]; then
        if [[ -d "${GRID_HOME}/bin" ]]; then
            new_path="${new_path:+${new_path}:}${GRID_HOME}/bin"
        fi
    fi
    
    echo "${new_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for database installations
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Prefers lib64 on 64-bit systems, falls back to lib
#           If GRID_HOME exists and differs from ORACLE_HOME, includes Grid lib
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local oracle_home="$1"
    local lib_path=""
    
    # Prefer lib64 on 64-bit systems
    if [[ -d "${oracle_home}/lib64" ]]; then
        lib_path="${oracle_home}/lib64"
    fi
    
    if [[ -d "${oracle_home}/lib" ]]; then
        lib_path="${lib_path:+${lib_path}:}${oracle_home}/lib"
    fi
    
    # If GRID_HOME exists and differs, add Grid libraries
    if [[ -n "${GRID_HOME:-}" ]] && [[ "${GRID_HOME}" != "${oracle_home}" ]]; then
        if [[ -d "${GRID_HOME}/lib" ]]; then
            lib_path="${lib_path:+${lib_path}:}${GRID_HOME}/lib"
        fi
    fi
    
    echo "${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for database
# Returns.: 0 on success
# Output..: "RDBMS"
# Notes...: Used by oradba_apply_product_config() to load database settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "RDBMS"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for database
# Returns.: 0 on success
# Output..: Space-separated list of required binaries
# Notes...: Core database tools that should be available
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "sqlplus tnsping lsnrctl"
    return 0
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
if declare -f oradba_log >/dev/null 2>&1; then
    oradba_log DEBUG "Database plugin loaded (v${plugin_version})"
fi
