#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: datasafe_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Data Safe On-Premises Connector
# Notes....: Consolidates oracle_cman_home logic (was in 8+ files)
#            Version 2.0.0: Added 4 new required functions for environment building
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
    # shellcheck disable=SC2009
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
# Output..: Status string (running|stopped|unavailable)
# Notes...: Multi-layered detection with fallback:
#           1. cmctl show services -c <instance> (most accurate)
#           2. Process-based detection (reliable fallback)
#           3. Python setup.py (last resort)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local base_path="$1"
    local connector_name="${2:-}"
    
    # Adjust to oracle_cman_home if needed
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # Primary Method: cmctl show services command (most accurate)
    local cmctl="${cman_home}/bin/cmctl"
    if [[ -x "${cmctl}" ]]; then
        # Extract instance name from cman.ora
        local instance_name="cust_cman"  # Default for DataSafe
        local cman_conf="${cman_home}/network/admin/cman.ora"
        
        if [[ -f "${cman_conf}" ]]; then
            # Extract instance name from cman.ora (format: instance_name = (configuration...))
            # Match identifier followed by = and opening paren
            local extracted_name
            extracted_name=$(grep -E '^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=[[:space:]]*\(' "${cman_conf}" 2>/dev/null | head -1 | cut -d'=' -f1 | tr -d ' ' || echo "")
            [[ -n "${extracted_name}" ]] && instance_name="${extracted_name}"
        fi
        
        # Use correct command: "show services -c <instance_name>"
        local status
        status=$(ORACLE_HOME="${cman_home}" \
                 LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
                 "${cmctl}" show services -c "${instance_name}" 2>/dev/null)
        
        # Check for explicit stopped/not running messages FIRST (more specific)
        # Use word boundaries to avoid matching "running" in "not running"
        if echo "${status}" | grep -qiE "not running|stopped|TNS-|No services"; then
            echo "stopped"
            return 1
        fi
        
        # Then check for service information in output (running state)
        # Check for positive indicators: Services Summary, READY, started, or "is running"
        if echo "${status}" | grep -qiE "Services Summary|Instance|READY|started|is running"; then
            echo "running"
            return 0
        fi
    fi
    
    # Secondary Method: Process-based detection (reliable fallback)
    # Check for running cmadmin or cmgw processes
    # shellcheck disable=SC2009
    if ps -ef 2>/dev/null | grep -q "${base_path}.*[c]madmin"; then
        echo "running"
        return 0
    fi
    
    # shellcheck disable=SC2009
    if ps -ef 2>/dev/null | grep -q "${base_path}.*[c]mgw"; then
        echo "running"
        return 0
    fi
    
    # Tertiary Method: Python setup.py (last resort)
    if [[ -f "${base_path}/setup.py" ]]; then
        if python3 "${base_path}/setup.py" status 2>/dev/null | grep -qi "already started"; then
            echo "running"
            return 0
        fi
        
        # Check for stopped status
        if python3 "${base_path}/setup.py" status 2>/dev/null | grep -qi "not running\|stopped"; then
            echo "stopped"
            return 1
        fi
    fi
    
    # If no detection method worked, check if it's unavailable
    if [[ ! -x "${cmctl}" ]]; then
        echo "unavailable"
        return 2
    fi
    
    # Default to stopped if cmctl exists but we can't determine status
    echo "stopped"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get Data Safe connector version
# Args....: $1 - Base path
# Returns.: 0 on success with clean version string to stdout
#           1 when version not applicable (no output)
#           2 on error or unavailable (no output)
# Output..: Version string (e.g., "23.4.0.0.0")
# Notes...: Uses cmctl show version command
#           No sentinel strings (ERR, unknown, N/A) in output
# ------------------------------------------------------------------------------
plugin_get_version() {
    local base_path="$1"
    local cman_home
    local version
    
    # Validate base path exists
    [[ ! -d "${base_path}" ]] && return 2
    
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # Check if cmctl is available
    local cmctl="${cman_home}/bin/cmctl"
    [[ ! -x "${cmctl}" ]] && return 2
    
    # Extract instance name from cman.ora
    local instance_name="cust_cman"  # Default
    local cman_conf="${cman_home}/network/admin/cman.ora"
    
    if [[ -f "${cman_conf}" ]]; then
        # Extract instance name from cman.ora (format: instance_name = (configuration...))
        # Match identifier followed by = and opening paren
        local extracted_name
        extracted_name=$(grep -E '^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=[[:space:]]*\(' "${cman_conf}" 2>/dev/null | head -1 | cut -d'=' -f1 | tr -d ' ' || echo "")
        [[ -n "${extracted_name}" ]] && instance_name="${extracted_name}"
    fi
    
    # Get version using cmctl show version -c <instance>
    local version_output
    version_output=$(ORACLE_HOME="${cman_home}" \
                     LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
                     "${cmctl}" show version -c "${instance_name}" 2>/dev/null)
    
    # Parse version from output using sed for portability
    # Expected format: "Oracle Connection Manager Version 23.4.0.0.0"
    version=$(echo "${version_output}" | sed -n 's/.*Version[[:space:]]*\([0-9][0-9.]*\).*/\1/p' | head -1)
    if [[ -n "${version}" ]]; then
        echo "${version}"
        return 0
    fi
    
    # Fallback: try without instance name (older versions)
    version_output=$(ORACLE_HOME="${cman_home}" \
                     LD_LIBRARY_PATH="${cman_home}/lib:${LD_LIBRARY_PATH:-}" \
                     "${cmctl}" version 2>/dev/null)
    
    version=$(echo "${version_output}" | sed -n 's/.*Version[[:space:]]*\([0-9][0-9.]*\).*/\1/p' | head -1)
    if [[ -n "${version}" ]]; then
        echo "${version}"
        return 0
    fi
    
    # No version found - error
    return 2
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
    local version
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    # Get version using plugin_get_version
    if version=$(plugin_get_version "${base_path}"); then
        echo "version=${version}"
    else
        echo "version=N/A"
    fi
    
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
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for Data Safe
# Args....: $1 - Input path (base or oracle_cman_home)
# Returns.: 0 on success
# Output..: Normalized base path (without oracle_cman_home)
# Notes...: DataSafe uses subdirectory structure, return base path
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    # If path ends with oracle_cman_home, return parent
    if [[ "${home_path}" =~ /oracle_cman_home$ ]]; then
        echo "${home_path%/oracle_cman_home}"
    else
        echo "${home_path}"
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for Data Safe connector
# Args....: $1 - Base path
#           $2 - Instance identifier (optional, not used for DataSafe)
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds environment for Data Safe connector
# ------------------------------------------------------------------------------
plugin_build_env() {
    local base_path="$1"
    
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${base_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${base_path}")
    
    echo "ORACLE_BASE_HOME=${base_path}"
    echo "ORACLE_HOME=${cman_home}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate Data Safe connector instances
# Args....: $1 - Base path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: DataSafe typically has one instance per installation
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local base_path="$1"
    # DataSafe: single instance per installation, use basename as instance name
    local instance_name
    instance_name=$(basename "${base_path}")
    echo "${instance_name}||datasafe"
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
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for Data Safe connector
# Args....: $1 - Base path (will be adjusted to oracle_cman_home)
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: DataSafe requires oracle_cman_home/bin
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local base_path="$1"
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    if [[ -d "${cman_home}/bin" ]]; then
        echo "${cman_home}/bin"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for Data Safe connector
# Args....: $1 - Base path (will be adjusted to oracle_cman_home)
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: DataSafe requires oracle_cman_home/lib
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local base_path="$1"
    local cman_home
    cman_home=$(plugin_adjust_environment "${base_path}")
    
    if [[ -d "${cman_home}/lib" ]]; then
        echo "${cman_home}/lib"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for Data Safe
# Returns.: 0 on success
# Output..: "DATASAFE"
# Notes...: Used by oradba_apply_product_config() to load Data Safe settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "DATASAFE"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for Data Safe connector
# Returns.: 0 on success
# Output..: Space-separated list of required binaries
# Notes...: Data Safe uses Connection Manager (cmctl)
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "cmctl"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_adjusted_paths
# Purpose.: Get adjusted PATH and LD_LIBRARY_PATH for Data Safe
# Args....: $1 - Base path
# Returns.: 0 on success
# Output..: PATH and LD_LIBRARY_PATH (one per line)
# Notes...: Helper function for environment setup (legacy, use plugin_build_bin_path/plugin_build_lib_path)
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
