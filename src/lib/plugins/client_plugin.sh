#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: client_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Full Client
# Notes....: Handles Oracle Full Client (not Instant Client)
#            Version 2.0.0: Added 4 new required functions for environment building
# Reference: Architecture Review & Refactoring Plan (Phase 2.1)
#            Questions.md - Client Plugin Decision
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="client"
export plugin_version="1.0.0"
export plugin_description="Oracle Full Client plugin"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect Oracle Full Client installations
# Returns.: 0 on success
# Output..: List of client home paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Check common installation directories
    for base_dir in /u01/app/oracle/product /opt/oracle/product /usr/lib/oracle; do
        if [[ -d "$base_dir" ]]; then
            while IFS= read -r -d '' client_home; do
                if plugin_validate_home "$client_home"; then
                    homes+=("$client_home")
                fi
            done < <(find "$base_dir" -maxdepth 2 -type d -name "client*" -print0 2>/dev/null)
        fi
    done
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is an Oracle Full Client home
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for client-specific files
    # Full client has bin/sqlplus (unlike instant client)
    [[ -f "${home_path}/bin/sqlplus" ]] || [[ -f "${home_path}/bin/sqlplus.exe" ]] || return 1
    
    # Should have network/admin for tnsnames.ora
    [[ -d "${home_path}/network/admin" ]] || [[ -d "${home_path}/network" ]] || return 1
    
    # Should NOT have rdbms directory (that's a database home)
    [[ -d "${home_path}/rdbms" ]] && return 1
    
    # Should NOT be an instant client (those have libclntsh.so directly)
    if [[ ! -d "${home_path}/bin" ]] && [[ -f "${home_path}/libclntsh.so" ]]; then
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for client home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME (unchanged for client)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check client availability
# Args....: $1 - ORACLE_HOME path
#           $2 - Ignored (clients don't have instances)
# Returns.: 0 always (clients don't "run")
# Output..: Status string
# Notes...: Clients are always "available" (not "running" or "stopped")
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    
    # Clients don't have status in the traditional sense (no running services/instances)
    # Return N/A with exit code 0 (successfully determined that status is not applicable)
    echo "N/A"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get Oracle Client metadata
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    # Get version using plugin_get_version
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    else
        echo "version=N/A"
    fi
    
    # Client type
    echo "type=full_client"
    
    # Check for sqlplus
    if [[ -x "${home_path}/bin/sqlplus" ]]; then
        echo "sqlplus=available"
    else
        echo "sqlplus=unavailable"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Clients should NOT show listener status
# Returns.: 1 (never show)
# Notes...: Client homes don't have their own listeners
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover instances for client home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (clients don't have instances)
# Notes...: Clients have no instances to discover
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    # Clients don't have instances
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for client
# Args....: $1 - Input ORACLE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: For client, ORACLE_BASE_HOME typically same as ORACLE_HOME
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    if [[ -n "${ORACLE_BASE_HOME:-}" ]]; then
        echo "${ORACLE_BASE_HOME}"
    else
        echo "${home_path}"
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for Oracle Full Client
# Args....: $1 - ORACLE_HOME
#           $2 - Not used for client
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Builds environment for client tools
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    
    local base_path
    base_path=$(plugin_build_base_path "${home_path}")
    
    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")
    
    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")
    
    echo "ORACLE_BASE_HOME=${base_path}"
    echo "ORACLE_HOME=${home_path}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate client instances
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (clients don't have instances)
# Notes...: Clients have no instances to enumerate
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    # Clients don't have instances
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Clients don't support SID aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for Oracle Full Client
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Full client has bin + OPatch directories
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local oracle_home="$1"
    local new_path=""
    
    if [[ -d "${oracle_home}/bin" ]]; then
        new_path="${oracle_home}/bin"
    fi
    
    if [[ -d "${oracle_home}/OPatch" ]]; then
        new_path="${new_path:+${new_path}:}${oracle_home}/OPatch"
    fi
    
    echo "${new_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for Oracle Full Client
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Prefers lib64 on 64-bit systems, falls back to lib
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local oracle_home="$1"
    local lib_path=""
    
    if [[ -d "${oracle_home}/lib64" ]]; then
        lib_path="${oracle_home}/lib64"
    fi
    
    if [[ -d "${oracle_home}/lib" ]]; then
        lib_path="${lib_path:+${lib_path}:}${oracle_home}/lib"
    fi
    
    echo "${lib_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for Full Client
# Returns.: 0 on success
# Output..: "CLIENT"
# Notes...: Used by oradba_apply_product_config() to load client settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "CLIENT"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for Full Client
# Returns.: 0 on success
# Output..: Space-separated list of required binaries
# Notes...: Full client has sqlplus and tnsping
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "sqlplus tnsping"
    return 0
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Client plugin loaded (v${plugin_version})"
