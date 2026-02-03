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
#            Implements plugin interface v1.0.0
# Reference: Architecture Review & Refactoring Plan (Phase 2.1)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="iclient"
export plugin_version="1.0.0"
export plugin_interface_version="1.0.0"
export plugin_description="Oracle Instant Client plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect Oracle Instant Client installations
# Returns.: 0 on success
# Output..: List of instant client paths
# Notes...: Excludes libraries found inside other Oracle product homes
#           (e.g., DataSafe oracle_cman_home/lib, Database homes)
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check common installation directories
    for base_dir in /usr/lib/oracle /opt/oracle /usr/local/oracle; do
        # Skip if base directory doesn't exist
        [[ ! -d "$base_dir" ]] && continue
        
        while IFS= read -r -d '' ic_dir; do
            # Validate it's a true Instant Client installation
            if plugin_validate_home "$ic_dir"; then
                # Additional check: exclude if inside another product home
                # Check for DataSafe (oracle_cman_home parent)
                if [[ "$ic_dir" =~ /oracle_cman_home/ ]]; then
                    continue
                fi
                
                # Check for Database home (has bin/oracle or rdbms/)
                local parent_dir
                parent_dir=$(dirname "$ic_dir")
                if [[ -f "${parent_dir}/bin/oracle" ]] || [[ -d "${parent_dir}/rdbms" ]]; then
                    continue
                fi
                
                # Check for full client (has bin/sqlplus but not oracle)
                if [[ -f "${parent_dir}/bin/sqlplus" ]]; then
                    continue
                fi
                
                homes+=("$ic_dir")
            fi
        done < <(find "$base_dir" -maxdepth 3 -type f -name "libclntsh.so*" -print0 2>/dev/null | \
                 xargs -0 dirname 2>/dev/null | sort -u)
    done
    
    # Also check LD_LIBRARY_PATH for standalone Instant Clients
    if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
        IFS=: read -ra lib_paths <<< "$LD_LIBRARY_PATH"
        for lib_path in "${lib_paths[@]}"; do
            if [[ -d "$lib_path" ]] && plugin_validate_home "$lib_path"; then
                # Exclude if inside another product home
                if [[ "$lib_path" =~ /oracle_cman_home/ ]]; then
                    continue
                fi
                
                local parent_dir
                parent_dir=$(dirname "$lib_path")
                if [[ -f "${parent_dir}/bin/oracle" ]] || [[ -d "${parent_dir}/rdbms" ]] || [[ -f "${parent_dir}/bin/sqlplus" ]]; then
                    continue
                fi
                
                homes+=("$lib_path")
            fi
        done
    fi
    
    # Deduplicate and print
    if [[ ${#homes[@]} -gt 0 ]]; then
        printf '%s\n' "${homes[@]}" | sort -u
    fi
    
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
# Returns.: 0 if available (library exists and readable)
#           1 if not applicable
#           2 if unavailable (missing or non-functional)
# Output..: None - status communicated via exit code only
# Notes...: Instant client is software-only, no running service
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    
    # Instant clients don't have status in the traditional sense (no running services/instances)
    # Return exit code 1 (not applicable - software-only product)
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
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for instant client
# Args....: $1 - Input ORACLE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: For instant client, base is same as ORACLE_HOME
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for Oracle Instant Client
# Args....: $1 - ORACLE_HOME
#           $2 - Not used for instant client
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds environment for instant client
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")
    
    echo "ORACLE_HOME=${home_path}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate instant client instances
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (instant clients don't have instances)
# Notes...: Instant clients have no instances
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
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
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for Oracle Instant Client
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Instant Client has no bin/ subdirectory - binaries in root
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
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
# Function: plugin_get_version
# Purpose.: Get Instant Client version
# Args....: $1 - Installation path (ORACLE_HOME)
# Returns.: 0 on success with clean version string to stdout
#           1 when version not applicable (no output)
#           2 on error or unavailable (no output)
# Output..: Version string in X.Y format (e.g., "23.26.0.0.0" or "19.21.0.0.0")
# Notes...: Detection methods (in order):
#           1. sqlplus -version (if sqlplus available)
#           2. Library filenames (libclntsh.so.X.Y, libclntshcore.so.X.Y, libocci.so.X.Y)
#           3. JDBC JAR manifest (ojdbc*.jar)
#           No sentinel strings (ERR, unknown, N/A) in output
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    
    # Validate home path exists
    [[ ! -d "${home_path}" ]] && return 2
    
    # Debug: Log entry point
    if declare -f oradba_log >/dev/null 2>&1; then
        oradba_log DEBUG "plugin_get_version called with home_path: ${home_path}"
    fi
    
    # Method 1: Try sqlplus -version (instant client: sqlplus in root directory)
    if [[ -x "${home_path}/sqlplus" ]]; then
        if declare -f oradba_log >/dev/null 2>&1; then
            oradba_log DEBUG "Found sqlplus at ${home_path}/sqlplus, trying -version"
        fi
        
        local sqlplus_version
        sqlplus_version=$("${home_path}/sqlplus" -version 2>/dev/null | grep -i "Release" | head -1)
        
        if declare -f oradba_log >/dev/null 2>&1; then
            oradba_log DEBUG "sqlplus -version output: ${sqlplus_version}"
        fi
        
        if [[ -n "${sqlplus_version}" ]]; then
            # Extract version like "23.26.0.0.0" or "19.21.0.0.0"
            local ver_str
            ver_str=$(echo "${sqlplus_version}" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+){0,3}' | head -1)
            
            if [[ -n "${ver_str}" ]]; then
                if declare -f oradba_log >/dev/null 2>&1; then
                    oradba_log DEBUG "Extracted version from sqlplus: ${ver_str}"
                fi
                echo "${ver_str}"
                return 0
            fi
        fi
    else
        if declare -f oradba_log >/dev/null 2>&1; then
            oradba_log DEBUG "sqlplus not found at ${home_path}/sqlplus"
        fi
    fi
    
    # Method 2: Extract version from library filenames
    # Check for libclntsh.so.X.Y, libclntshcore.so.X.Y, libocci.so.X.Y
    for lib_base in libclntsh libclntshcore libocci; do
        for lib_file in "${home_path}/${lib_base}.so."*; do
            if [[ -f "${lib_file}" ]]; then
                # Extract version from filename: libclntsh.so.23.1 -> 23.1
                local version_string
                version_string=$(basename "${lib_file}" | grep -oE '[0-9]+\.[0-9]+$')
                
                if [[ -n "${version_string}" ]]; then
                    # Convert to X.Y.0.0.0 format
                    echo "${version_string}.0.0.0"
                    return 0
                fi
            fi
        done
    done
    
    # Method 3: Try JDBC JAR manifest
    for jar_file in "${home_path}"/ojdbc*.jar; do
        if [[ -f "${jar_file}" ]]; then
            local manifest_version
            manifest_version=$(unzip -p "${jar_file}" META-INF/MANIFEST.MF 2>/dev/null | \
                              grep -i "Implementation-Version:" | head -1 | \
                              cut -d: -f2 | tr -d ' \r')
            
            if [[ -n "${manifest_version}" ]]; then
                echo "${manifest_version}"
                return 0
            fi
        fi
    done
    
    # No version found - not applicable
    return 1
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
if declare -f oradba_log >/dev/null 2>&1; then
    oradba_log DEBUG "Instant Client plugin loaded (v${plugin_version})"
fi
