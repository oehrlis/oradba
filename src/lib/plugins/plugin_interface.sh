#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: plugin_interface.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.16
# Version..: 1.0.0
# Purpose..: Plugin interface template for product-specific behavior
# Notes....: All product plugins must implement these functions
# Reference: Architecture Review & Refactoring Plan (Phase 1.2)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Plugin Metadata (REQUIRED)
# ------------------------------------------------------------------------------
# shellcheck disable=SC2034
plugin_name=""              # Product type identifier (database, datasafe, etc.)
# shellcheck disable=SC2034
plugin_version=""           # Plugin version (semantic versioning)
# shellcheck disable=SC2034
plugin_description=""       # Human-readable description

# ------------------------------------------------------------------------------
# Required Plugin Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect installations of this product type
# Args....: None
# Returns.: 0 on success
# Output..: List of installation paths (one per line)
# Notes...: Used for auto-discovery when no registry files exist
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    oradba_log ERROR "plugin_detect_installation not implemented in ${plugin_name}"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is a valid ORACLE_HOME for this product
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# Output..: None
# Notes...: Checks for product-specific files/directories
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    oradba_log ERROR "plugin_validate_home not implemented in ${plugin_name}"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for product-specific requirements
# Args....: $1 - Original ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME path
# Notes...: Example: DataSafe appends /oracle_cman_home
#           Most products return the path unchanged
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if product instance is running
# Args....: $1 - Installation path
#           $2 - Instance name (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Uses explicit environment (not current shell environment)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    oradba_log ERROR "plugin_check_status not implemented in ${plugin_name}"
    echo "unavailable"
    return 2
}

# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get product metadata (version, features, etc.)
# Args....: $1 - Installation path
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Example output:
#           version=19.21.0.0.0
#           edition=Enterprise
#           patchlevel=221018
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    echo "version=unknown"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Determine if this product's tnslsnr should appear in listener section
# Args....: $1 - Installation path
# Returns.: 0 if should show, 1 if should not show
# Notes...: Database listeners: return 0
#           DataSafe connectors: return 1 (they use tnslsnr but aren't DB listeners)
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    local home_path="$1"
    # Default: don't show listener (override in product plugins)
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover all instances for this Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: List of instances (one per line)
# Format..: instance_name|status|additional_metadata
# Notes...: Handles 1:many relationships (RAC, WebLogic, OUD)
#           Example: PROD1|running|node1
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    # Default: single instance with same name as home
    # Override in products with multiple instances (RAC, WebLogic, OUD)
    return 0
}

# ------------------------------------------------------------------------------
# Optional Plugin Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: plugin_get_display_name
# Purpose.: Get custom display name for instance
# Args....: $1 - Installation name
# Returns.: 0 on success
# Output..: Display name
# Notes...: Optional - defaults to installation name
# ------------------------------------------------------------------------------
plugin_get_display_name() {
    local name="$1"
    echo "${name}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Whether this product supports SID-like aliases
# Returns.: 0 if supports aliases, 1 if not
# Notes...: Databases support aliases, most other products don't
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Get product version from ORACLE_HOME
# Args....: $1 - Installation path
# Returns.: 0 on success
# Output..: Version string (e.g., 19.21.0.0.0)
# Notes...: Called by plugin_get_metadata, can be overridden for efficiency
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    
    # Try version file first
    local version_file="${home_path}/inventory/ContentsXML/comps.xml"
    if [[ -f "${version_file}" ]]; then
        grep -oP 'VER="\K[^"]+' "${version_file}" 2>/dev/null | head -1
        return $?
    fi
    
    # Fallback to opatch if available
    if [[ -x "${home_path}/OPatch/opatch" ]]; then
        "${home_path}/OPatch/opatch" version 2>/dev/null | \
            grep -oP 'OPatch Version: \K[\d.]+' | head -1
        return $?
    fi
    
    echo "unknown"
    return 1
}

# ------------------------------------------------------------------------------
# Plugin Interface Loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Plugin interface template loaded (v1.0.0)"
