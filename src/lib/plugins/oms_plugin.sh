#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: oms_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.20
# Version..: 1.0.0
# Purpose..: Plugin stub for Oracle Enterprise Manager OMS
# Notes....: Minimal stub implementation - full support to be added later
#            Version detection not applicable (returns "ERR")
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="oms"
export plugin_version="1.0.0"
export plugin_description="Oracle Enterprise Manager OMS plugin (stub)"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect OMS installations
# Returns.: 0 on success
# Output..: List of OMS paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    # Stub - minimal implementation
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is an OMS installation
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    [[ -f "${home_path}/sysman/lib/emoms.jar" ]] && return 0
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for OMS
# Args....: $1 - Path to OMS home
# Returns.: 0 on success
# Output..: Adjusted path (unchanged for OMS)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check OMS status
# Args....: $1 - Path to OMS home
#           $2 - Ignored
# Returns.: 0 on success
# Output..: Status string
# ------------------------------------------------------------------------------
plugin_check_status() {
    echo "N/A"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get OMS metadata
# Args....: $1 - Path to OMS home
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    echo "product=oms"
    echo "version=N/A"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: OMS should NOT show listener status
# Returns.: 1 (never show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover instances
# Args....: $1 - Path to OMS home
# Returns.: 0 on success
# Output..: Empty (stub)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: OMS doesn't support aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_path
# Purpose.: Get PATH components for OMS
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (no binaries added to PATH)
# ------------------------------------------------------------------------------
plugin_build_path() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for OMS
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (no libraries added)
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for OMS
# Returns.: 0 on success
# Output..: "OMS"
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "OMS"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for OMS
# Returns.: 0 on success
# Output..: Empty (stub)
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get OMS version
# Args....: $1 - Installation path
# Returns.: 1 (version not applicable for stub)
# Output..: No output
# Notes...: OMS version detection not implemented in stub
#           Returns exit code 1 (N/A) per plugin standards
# ------------------------------------------------------------------------------
plugin_get_version() {
    return 1
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "OMS plugin loaded (stub v${plugin_version})"
