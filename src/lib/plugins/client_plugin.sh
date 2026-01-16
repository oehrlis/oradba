#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: client_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.16
# Version..: 1.0.0
# Purpose..: Plugin for Oracle Full Client
# Notes....: Handles Oracle Full Client (not Instant Client)
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
    
    # Clients don't run like databases or services
    # Just check if sqlplus is executable
    if [[ -x "${home_path}/bin/sqlplus" ]]; then
        echo "available"
        return 0
    else
        echo "unavailable"
        return 1
    fi
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
    
    # Get version
    local version
    version=$(plugin_get_version "${home_path}")
    echo "version=${version}"
    
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
# Function: plugin_supports_aliases
# Purpose.: Clients don't support SID aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Client plugin loaded (v${plugin_version})"
