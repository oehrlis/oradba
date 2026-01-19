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
# Function: plugin_detect_installation
# Purpose.: Auto-detect OUD installations
# Returns.: 0 on success
# Output..: List of OUD home paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check common OUD installation directories
    for base_dir in /u01/app/oracle /opt/oracle /u00/app/oracle; do
        if [[ -d "$base_dir" ]]; then
            while IFS= read -r -d '' oud_dir; do
                # OUD home usually has structure: product/OUD_version/oud
                if plugin_validate_home "$oud_dir"; then
                    homes+=("$oud_dir")
                fi
            done < <(find "$base_dir" -maxdepth 5 -type d -name "oud" -print0 2>/dev/null)
            
            # Also check for oudBase directories
            while IFS= read -r -d '' oud_base; do
                local parent_dir
                parent_dir=$(dirname "$oud_base")
                if plugin_validate_home "$parent_dir"; then
                    homes+=("$parent_dir")
                fi
            done < <(find "$base_dir" -maxdepth 4 -type d -name "oudBase" -print0 2>/dev/null)
        fi
    done
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
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
# Function: plugin_get_metadata
# Purpose.: Get OUD metadata
# Args....: $1 - Path to OUD home
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Try to get version
    local version="unknown"
    
    # Check for version file
    if [[ -f "${home_path}/config/buildinfo" ]]; then
        version=$(grep -E "^product.version=" "${home_path}/config/buildinfo" 2>/dev/null | cut -d= -f2)
    fi
    
    # Alternative: Check setup command
    if [[ -z "$version" || "$version" == "unknown" ]] && [[ -x "${home_path}/setup" ]]; then
        version=$("${home_path}/setup" --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
    fi
    
    echo "version=${version}"
    echo "type=oud"
    
    # Check for configured instances
    if [[ -d "${home_path}/oudBase" ]]; then
        local instance_count=0
        while IFS= read -r -d '' instance_dir; do
            ((instance_count++))
        done < <(find "${home_path}/oudBase" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
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
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    
    # Check for oudBase directory with instances
    if [[ ! -d "${home_path}/oudBase" ]]; then
        return 0
    fi
    
    # List instance directories
    while IFS= read -r -d '' instance_dir; do
        local instance_name
        instance_name=$(basename "$instance_dir")
        echo "$instance_name"
    done < <(find "${home_path}/oudBase" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    
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
# Function: plugin_build_path
# Purpose.: Get PATH components for Oracle Unified Directory
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: OUD has bin directory with management tools
# ------------------------------------------------------------------------------
plugin_build_path() {
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
oradba_log DEBUG "OUD plugin loaded (v${plugin_version})"
