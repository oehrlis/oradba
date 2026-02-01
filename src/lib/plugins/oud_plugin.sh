#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: oud_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Unified Directory (OUD)
# Notes....: Handles OUD installations with instance management
#            Version 2.0.0: Added 4 new required functions for environment building
# Reference: Architecture Review & Refactoring Plan (Phase 2.1)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="oud"
export plugin_version="1.0.0"
export plugin_description="Oracle Unified Directory plugin"

# ------------------------------------------------------------------------------
# Function: get_oud_instance_base
# Purpose.: Get OUD instance base directory following priority order
# Args....: $1 - ORACLE_HOME path (optional, for fallback)
# Returns.: 0 on success
# Output..: Instance base directory path
# Notes...: Priority order:
#           1. $OUD_INSTANCE_BASE (if set and exists)
#           2. $OUD_DATA/instances (if OUD_DATA set and directory exists)
#           3. $ORACLE_DATA/instances (if ORACLE_DATA set and directory exists)
#           4. $ORACLE_BASE/instances (if ORACLE_BASE set and directory exists)
#           5. $ORACLE_HOME/oudBase (fallback)
# ------------------------------------------------------------------------------
get_oud_instance_base() {
    local home_path="${1:-}"
    
    # Priority 1: OUD_INSTANCE_BASE
    if [[ -n "${OUD_INSTANCE_BASE:-}" ]] && [[ -d "${OUD_INSTANCE_BASE}" ]]; then
        echo "${OUD_INSTANCE_BASE}"
        return 0
    fi
    
    # Priority 2: OUD_DATA/instances
    if [[ -n "${OUD_DATA:-}" ]] && [[ -d "${OUD_DATA}/instances" ]]; then
        echo "${OUD_DATA}/instances"
        return 0
    fi
    
    # Priority 3: ORACLE_DATA/instances (same as OUD_DATA per comment)
    if [[ -n "${ORACLE_DATA:-}" ]] && [[ -d "${ORACLE_DATA}/instances" ]]; then
        echo "${ORACLE_DATA}/instances"
        return 0
    fi
    
    # Priority 4: ORACLE_BASE/instances
    if [[ -n "${ORACLE_BASE:-}" ]] && [[ -d "${ORACLE_BASE}/instances" ]]; then
        echo "${ORACLE_BASE}/instances"
        return 0
    fi
    
    # Fallback: ORACLE_HOME/oudBase
    if [[ -n "${home_path}" ]] && [[ -d "${home_path}/oudBase" ]]; then
        echo "${home_path}/oudBase"
        return 0
    fi
    
    # No instance base found
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect OUD installations
# Returns.: 0 on success
# Output..: List of OUD home paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check common OUD installation directories (only if they exist)
    for base_dir in /u01/app/oracle /opt/oracle /u00/app/oracle; do
        # Skip if base directory doesn't exist
        [[ ! -d "$base_dir" ]] && continue
        
        # Find directories named "oud"
        while IFS= read -r -d '' oud_dir; do
            # Validate that it's a real OUD installation
            if plugin_validate_home "$oud_dir"; then
                homes+=("$oud_dir")
            fi
        done < <(find "$base_dir" -maxdepth 5 -type d -name "oud" -print0 2>/dev/null)
        
        # Also check for oudBase directories
        while IFS= read -r -d '' oud_base; do
            local parent_dir
            parent_dir=$(dirname "$oud_base")
            # Validate parent directory as OUD home
            if plugin_validate_home "$parent_dir"; then
                homes+=("$parent_dir")
            fi
        done < <(find "$base_dir" -maxdepth 4 -type d -name "oudBase" -print0 2>/dev/null)
    done
    
    # Deduplicate and print only if we found valid homes
    if [[ ${#homes[@]} -gt 0 ]]; then
        printf '%s\n' "${homes[@]}" | sort -u
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is an OUD installation
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for OUD-specific directories/files
    # OUD has either:
    # 1. setup command (for fresh installations)
    # 2. oudBase directory (for configured installations)
    if [[ -x "${home_path}/setup" ]] || [[ -d "${home_path}/oudBase" ]]; then
        return 0
    fi
    
    # Alternative: Check for OUD library
    if [[ -f "${home_path}/lib/OpenDJ.jar" ]] || [[ -f "${home_path}/lib/opendj-server.jar" ]]; then
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for OUD
# Args....: $1 - Path to OUD home
# Returns.: 0 on success
# Output..: Adjusted path (unchanged for OUD)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check OUD instance status
# Args....: $1 - Path to OUD home
#           $2 - Instance name (optional)
# Returns.: 0 if running
# Output..: Status string
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    
    # Check for running OUD processes
    # OUD typically has java processes with org.opends.server.core.DirectoryServer
    if pgrep -f "org.opends.server.core.DirectoryServer" >/dev/null 2>&1; then
        # If instance name provided, check if it matches
        if [[ -n "$instance_name" ]]; then
            if pgrep -f "org.opends.server.core.DirectoryServer.*${instance_name}" >/dev/null 2>&1; then
                echo "running"
                return 0
            else
                echo "stopped"
                return 1
            fi
        else
            echo "running"
            return 0
        fi
    else
        echo "stopped"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get OUD version
# Args....: $1 - Installation path
# Returns.: 0 on success with clean version string to stdout
#           1 when version not applicable (no output)
#           2 on error or unavailable (no output)
# Output..: Version string (e.g., "12.2.1.4.0")
# Notes...: Detection methods (in order):
#           1. config/buildinfo file
#           2. setup --version command
#           No sentinel strings (ERR, unknown, N/A) in output
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    local version
    
    # Validate home path exists
    [[ ! -d "${home_path}" ]] && return 2
    
    # Check for version file
    if [[ -f "${home_path}/config/buildinfo" ]]; then
        version=$(grep -E "^product.version=" "${home_path}/config/buildinfo" 2>/dev/null | cut -d= -f2)
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # Alternative: Check setup command
    if [[ -x "${home_path}/setup" ]]; then
        version=$("${home_path}/setup" --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+\.\d+')
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # No version found - not applicable
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get OUD metadata
# Args....: $1 - Path to OUD home
# Returns.: 0 on success
# Output..: Key=value pairs
# Notes...: Uses get_oud_instance_base() to count instances
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    local version
    local instance_base
    
    # Get version using plugin_get_version
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    else
        echo "version=N/A"
    fi
    
    echo "type=oud"
    
    # Check for configured instances using instance base
    instance_base=$(get_oud_instance_base "${home_path}")
    if [[ $? -eq 0 ]] && [[ -d "${instance_base}" ]]; then
        local instance_count=0
        while IFS= read -r -d '' instance_dir; do
            ((instance_count++))
        done < <(find "${instance_base}" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
        echo "instances=${instance_count}"
    else
        echo "instances=0"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: OUD should NOT show database listener status
# Returns.: 1 (never show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover OUD instances
# Args....: $1 - Path to OUD home
# Returns.: 0 on success
# Output..: List of instance names
# Notes...: Uses get_oud_instance_base() to determine instance location
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    local instance_base
    
    # Get instance base directory using priority order
    instance_base=$(get_oud_instance_base "${home_path}")
    if [[ $? -ne 0 ]] || [[ ! -d "${instance_base}" ]]; then
        # No instance base found
        return 0
    fi
    
    # List instance directories
    while IFS= read -r -d '' instance_dir; do
        local instance_name
        instance_name=$(basename "$instance_dir")
        echo "$instance_name"
    done < <(find "${instance_base}" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for OUD
# Args....: $1 - Input ORACLE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: For OUD, base is same as ORACLE_HOME
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for Oracle Unified Directory
# Args....: $1 - ORACLE_HOME
#           $2 - OUD instance name (optional)
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds environment for OUD instance
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    local instance="${2:-}"
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")
    
    echo "ORACLE_HOME=${home_path}"
    [[ -n "${instance}" ]] && echo "OUD_INSTANCE=${instance}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate all OUD instances for this installation
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: OUD can have multiple instances per installation
#           Instances discovered using get_oud_instance_base() priority order:
#           1. $OUD_INSTANCE_BASE
#           2. $OUD_DATA/instances
#           3. $ORACLE_DATA/instances
#           4. $ORACLE_BASE/instances
#           5. $ORACLE_HOME/oudBase (fallback)
#           Status is determined by checking for running OUD processes
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    local instance_base
    
    # Get instance base directory using priority order
    instance_base=$(get_oud_instance_base "${home_path}")
    if [[ $? -ne 0 ]] || [[ ! -d "${instance_base}" ]]; then
        # No instance base found - valid for fresh installations
        return 0
    fi
    
    # Enumerate instance directories in instance base
    while IFS= read -r -d '' instance_dir; do
        local instance_name
        instance_name=$(basename "$instance_dir")
        
        # Check instance status
        local status
        if pgrep -f "org.opends.server.core.DirectoryServer.*${instance_name}" >/dev/null 2>&1; then
            status="running"
        else
            status="stopped"
        fi
        
        # Build metadata
        local metadata="path=${instance_dir}"
        
        # Output in required format: instance_name|status|additional_metadata
        echo "${instance_name}|${status}|${metadata}"
    done < <(find "${instance_base}" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: OUD instances can have aliases
# Returns.: 0 (supports aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_display_name
# Purpose.: Get display name for OUD instance
# Args....: $1 - Instance name
# Returns.: 0 on success
# Output..: Display name
# ------------------------------------------------------------------------------
plugin_get_display_name() {
    local instance_name="$1"
    echo "OUD:${instance_name}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for Oracle Unified Directory
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: OUD has bin directory with management tools
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local oracle_home="$1"
    
    if [[ -d "${oracle_home}/bin" ]]; then
        echo "${oracle_home}/bin"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for Oracle Unified Directory
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: OUD has lib directory
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local oracle_home="$1"
    
    if [[ -d "${oracle_home}/lib" ]]; then
        echo "${oracle_home}/lib"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for OUD
# Returns.: 0 on success
# Output..: "OUD"
# Notes...: Used by oradba_apply_product_config() to load OUD settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "OUD"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for OUD
# Returns.: 0 on success
# Output..: Space-separated list of required binaries
# Notes...: OUD has oud-setup and other management tools
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "oud-setup"
    return 0
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
if declare -f oradba_log >/dev/null 2>&1; then
    oradba_log DEBUG "OUD plugin loaded (v${plugin_version})"
fi
