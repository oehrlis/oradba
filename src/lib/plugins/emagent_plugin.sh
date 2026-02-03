#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: emagent_plugin.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.20
# Version..: 1.0.0
# Purpose..: Plugin stub for Oracle Enterprise Manager Agent
# Notes....: EXPERIMENTAL - Minimal stub implementation
#            Full support to be added later
#            Version detection not applicable (returns exit 1)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata
# ------------------------------------------------------------------------------
export plugin_name="emagent"
export plugin_version="1.0.0"
export plugin_interface_version="1.0.0"
export plugin_status="EXPERIMENTAL"
export plugin_description="Oracle Enterprise Manager Agent plugin (EXPERIMENTAL STUB)"

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect EM Agent installations
# Returns.: 0 on success
# Output..: List of agent paths
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    # Stub - minimal implementation
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is an EM Agent installation
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    [[ ! -d "${home_path}" ]] && return 1
    [[ -f "${home_path}/agent_inst/bin/emctl" ]] && return 0
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust environment for EM Agent
# Args....: $1 - Path to agent home
# Returns.: 0 on success
# Output..: Adjusted path (unchanged for agent)
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check EM Agent status
# Args....: $1 - Path to agent home
#           $2 - Ignored
# Returns.: 0 if running, 1 if stopped/N/A, 2 if unavailable/error
# Output..: None - status communicated via exit code only
# Notes...: Stub implementation - returns 1 (not applicable)
# ------------------------------------------------------------------------------
plugin_check_status() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get EM Agent metadata
# Args....: $1 - Path to agent home
# Returns.: 0 on success
# Output..: Key=value pairs
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    echo "product=emagent"
    echo "version=N/A"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: EM Agent should NOT show listener status
# Returns.: 1 (never show)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover instances
# Args....: $1 - Path to agent home
# Returns.: 0 on success
# Output..: Empty (stub)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base for EM Agent
# Args....: $1 - Input path
# Returns.: 0 on success
# Output..: Base path
# Notes...: Stub implementation
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for EM Agent
# Args....: $1 - Installation path
#           $2 - Instance (optional)
# Returns.: 0 on success
# Output..: Key=value pairs
# Notes...: Stub implementation
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    echo "ORACLE_HOME=${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate EM Agent instances
# Args....: $1 - Installation path
# Returns.: 0 on success
# Output..: Empty (stub)
# Notes...: Stub implementation - will be implemented in Phase 3
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    # Stub: EM Agent instance enumeration not implemented yet
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: EM Agent doesn't support aliases
# Returns.: 1 (no aliases)
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for EM Agent
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (no binaries added to PATH)
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for EM Agent
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Empty (no libraries added)
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for EM Agent
# Returns.: 0 on success
# Output..: "EMAGENT"
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "EMAGENT"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for EM Agent
# Returns.: 0 on success
# Output..: Empty (stub)
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get EM Agent version
# Args....: $1 - Installation path
# Returns.: 1 (version not applicable for stub)
# Output..: No output
# Notes...: EM Agent version detection not implemented in stub
#           Returns exit code 1 (N/A) per plugin standards
# ------------------------------------------------------------------------------
plugin_get_version() {
    return 1
}

# ------------------------------------------------------------------------------
# Plugin loaded
# ------------------------------------------------------------------------------
if declare -f oradba_log >/dev/null 2>&1; then
    oradba_log DEBUG "EM Agent plugin loaded (stub v${plugin_version})"
fi
