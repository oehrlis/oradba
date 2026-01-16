#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: datasafe_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.16
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Data Safe On-Premises Connector
# Notes....: Consolidates oracle_cman_home logic (was in 8+ files)
# Reference: Architecture Review & Refactoring Plan (Phase 1.2)
#            Fixes Bug #83 (explicit environment)
#            Fixes Bug #84 (listener visibility)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="datasafe"
export plugin_version="1.0.0"
export plugin_description="Oracle Data Safe On-Premises Connector plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect Data Safe connector installations
# Returns.: 0 on success
# Output..: List of connector base paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check running cmctl processes
    while read -r cmctl_line; do
        local pid
        pid=$(echo "${cmctl_line}" | awk '{print $2}')
        if [[ -n "${pid}" ]] && [[ -d "/proc/${pid}" ]]; then
            # Get ORACLE_HOME from process environment
            local home
            home=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep '^ORACLE_HOME=' | cut -d= -f2-)
            if [[ -n "${home}" ]] && [[ -d "${home}" ]]; then
                # DataSafe base is parent of oracle_cman_home
                if [[ "${home}" =~ /oracle_cman_home$ ]]; then
                    homes+=("${home%/oracle_cman_home}")
                else
                    homes+=("${home}")
                fi
            fi
        fi
    done < <(ps -ef | grep "[c]mctl")
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is a Data Safe connector home
# Args....: $1 - Path to validate (base path, not oracle_cman_home)
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local base_path="$1"
    
    [[ ! -d "${base_path}" ]] && return 1
    
    # Check for oracle_cman_home subdirectory
    [[ ! -d "${base_path}/oracle_cman_home" ]] && return 1
    
    # Check for cmctl in oracle_cman_home/bin
    [[ ! -x "${base_path}/oracle_cman_home/bin/cmctl" ]] && return 1
    
    # Check for lib directory
    [[ ! -d "${base_path}/oracle_cman_home/lib" ]] && return 1
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for Data Safe
# Args....: $1 - Base ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME (with /oracle_cman_home)
# Notes...: THIS IS THE KEY FUNCTION - Consolidates logic from 8+ files
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local base_path="$1"
    
    # If oracle_cman_home subdirectory exists, use it
    if [[ -d "${base_path}/oracle_cman_home" ]]; then
        echo "${base_path}/oracle_cman_home"
    else
        # Already pointing to oracle_cman_home or invalid
        echo "${base_path}"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check Data Safe connector status
# Args....: $1 - Base path or oracle_cman_home path
#           $2 - Connector name (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string
# Notes...: Uses EXPLICIT environment (fixes Bug #83)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local base_path="$1"
    local connector_name="${2:-}"
    
    # Adjust to oracle_cman_home if needed
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # Check cmctl exists
    local cmctl="${cman_home}/bin/cmctl"
    if [[ ! -x "${cmctl}" ]]; then
        echo "unavailable"
        return 2
    fi
    
    # Check status with EXPLICIT environment (Bug #83 fix)
    local status
    status=$(ORACLE_HOME="${cman_home}" \
             LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
             "${cmctl}" status 2>/dev/null)
    
    if echo "${status}" | grep -q "READY"; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get Data Safe connector metadata
# Args....: $1 - Base path
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local base_path="$1"
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # Data Safe connectors don't have traditional version detection
    echo "version=N/A"
    echo "type=datasafe_connector"
    
    # Check if cmctl is available
    if [[ -x "${cman_home}/bin/cmctl" ]]; then
        echo "cmctl=available"
    else
        echo "cmctl=unavailable"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Data Safe connectors should NOT show in listener section
# Returns.: 1 (never show)
# Notes...: Fixes Bug #84 - DataSafe uses tnslsnr but it's not a DB listener
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover Data Safe connector instances
# Args....: $1 - Base path
# Returns.: 0 on success
# Output..: List of connector instances
# Notes...: Usually 1:1 relationship (one connector per base)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local base_path="$1"
    
    # Extract connector name from path
    local connector_name
    connector_name=$(basename "${base_path}")
    
    # Check status
    local status
    status=$(plugin_check_status "${base_path}")
    
    echo "${connector_name}|${status}|"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Data Safe connectors don't support aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_adjusted_paths
# Purpose.: Get adjusted PATH and LD_LIBRARY_PATH for Data Safe
# Args....: $1 - Base path
# Returns.: 0 on success
# Output..: PATH and LD_LIBRARY_PATH (one per line)
# Notes...: Helper function for environment setup
# ------------------------------------------------------------------------------
plugin_get_adjusted_paths() {
    local base_path="$1"
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # PATH: oracle_cman_home/bin
    echo "PATH=${cman_home}/bin"
    
    # LD_LIBRARY_PATH: oracle_cman_home/lib
    echo "LD_LIBRARY_PATH=${cman_home}/lib"
    
    return 0
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "DataSafe plugin loaded (v${plugin_version})"
oradba_log DEBUG "Consolidates oracle_cman_home logic (was in 8+ files)"
