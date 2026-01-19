#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: iclient_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Instant Client
# Notes....: Handles Oracle Instant Client (libclntsh.so based, no bin/)
#            Version 2.0.0: Added 4 new required functions for environment building
# Reference: Architecture Review & Refactoring Plan (Phase 2.1)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="iclient"
export plugin_version="1.0.0"
export plugin_description="Oracle Instant Client plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect Oracle Instant Client installations
# Returns.: 0 on success
# Output..: List of instant client paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check common installation directories
    for base_dir in /usr/lib/oracle /opt/oracle /usr/local/oracle; do
        if [[ -d "$base_dir" ]]; then
            while IFS= read -r -d '' ic_dir; do
                if plugin_validate_home "$ic_dir"; then
                    homes+=("$ic_dir")
                fi
            done < <(find "$base_dir" -maxdepth 3 -type f -name "libclntsh.so*" -print0 2>/dev/null | \
                     xargs -0 dirname | sort -u)
        fi
    done
    
    # Also check LD_LIBRARY_PATH
    if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
        IFS=: read -ra lib_paths <<< "$LD_LIBRARY_PATH"
        for lib_path in "${lib_paths[@]}"; do
            if [[ -d "$lib_path" ]] && plugin_validate_home "$lib_path"; then
                homes+=("$lib_path")
            fi
        done
    fi
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is an Instant Client installation
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    
    # Instant client does NOT have bin/ subdirectory
    # (If it has bin/, it's a full client)
    [[ -d "${home_path}/bin" ]] && return 1
    
    # Should NOT have rdbms directory (that's a database home)
    [[ -d "${home_path}/rdbms" ]] && return 1
    
    # Check for libclntsh.so (instant client signature)
    if [[ -f "${home_path}/libclntsh.so" ]]; then
        return 0
    fi
    # Check for versioned library
    local found=0
    for lib in "${home_path}"/libclntsh.so.*; do
        [[ -f "$lib" ]] && found=1 && break
    done
    [[ $found -eq 1 ]] || return 1
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for instant client
# Args....: $1 - Path to instant client
# Returns.: 0 on success
# Output..: Adjusted path (unchanged for instant client)
# Notes...: Instant client uses ORACLE_HOME directly (no bin/ subdirectory)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check instant client availability
# Args....: $1 - Path to instant client
#           $2 - Ignored (instant clients don't have instances)
# Returns.: 0 if libraries available
# Output..: Status string
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    
    # Check if libclntsh.so is readable
    if [[ -r "${home_path}/libclntsh.so" ]]; then
        echo "available"
        return 0
    fi
    # Check for readable versioned library
    for lib in "${home_path}"/libclntsh.so.*; do
        if [[ -r "$lib" ]]; then
            echo "available"
            return 0
        fi
    done
    echo "unavailable"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get instant client metadata
# Args....: $1 - Path to instant client
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Try to get version from library
    local version="unknown"
    local lib_file="${home_path}/libclntsh.so"
    
    # Check for versioned library
    if [[ -f "${lib_file}" ]]; then
        # Try to extract version from symlink or filename
        if [[ -L "${lib_file}" ]]; then
            local target
            target=$(readlink "${lib_file}")
            version=$(echo "$target" | grep -oP 'libclntsh\.so\.\K[\d.]+' || echo "unknown")
        fi
    else
        # Look for versioned file
        local versioned
        versioned=$(ls "${home_path}"/libclntsh.so.* 2>/dev/null | head -1)
        if [[ -n "$versioned" ]]; then
            version=$(basename "$versioned" | grep -oP 'libclntsh\.so\.\K[\d.]+' || echo "unknown")
        fi
    fi
    
    echo "version=${version}"
    echo "type=instant_client"
    
    # Check for sqlplus (some instant client packages include it)
    if [[ -x "${home_path}/sqlplus" ]]; then
        echo "sqlplus=available"
    else
        echo "sqlplus=unavailable"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Instant clients should NOT show listener status
# Returns.: 1 (never show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover instances
# Args....: $1 - Path to instant client
# Returns.: 0 on success
# Output..: Empty (instant clients don't have instances)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    # Instant clients don't have instances
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Instant clients don't support aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_path
# Purpose.: Get PATH components for Oracle Instant Client
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Instant Client has no bin/ subdirectory - binaries in root
# ------------------------------------------------------------------------------
plugin_build_path() {
    local oracle_home="$1"
    
    # Instant Client: executables are in the root directory
    if [[ -d "${oracle_home}" ]]; then
        echo "${oracle_home}"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for Oracle Instant Client
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Instant Client libraries are in root, lib64, or lib subdirectory
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local oracle_home="$1"
    
    # Check for lib64 first, then lib, then root
    if [[ -d "${oracle_home}/lib64" ]]; then
        echo "${oracle_home}/lib64"
    elif [[ -d "${oracle_home}/lib" ]]; then
        echo "${oracle_home}/lib"
    else
        # Libraries in root directory for Instant Client
        echo "${oracle_home}"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for Instant Client
# Returns.: 0 on success
# Output..: "ICLIENT"
# Notes...: Used by oradba_apply_product_config() to load instant client settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "ICLIENT"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for Instant Client
# Returns.: 0 on success
# Output..: Space-separated list of required binaries
# Notes...: Instant Client has sqlplus if SQL*Plus package installed
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "sqlplus"
    return 0
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Instant Client plugin loaded (v${plugin_version})"
