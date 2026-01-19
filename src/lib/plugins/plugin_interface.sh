#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: plugin_interface.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 2.0.0
# Purpose..: Plugin interface template for product-specific behavior
# Notes....: All product plugins must implement these functions
#            Version 2.0.0: Added 4 new required functions for environment building
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
# Function: plugin_build_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns the directories to add to PATH for this product
#           Example (RDBMS): /u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch
#           Example (ICLIENT): /u01/app/oracle/instantclient_19_21
#           Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/bin
# ------------------------------------------------------------------------------
plugin_build_path() {
    local home_path="$1"
    oradba_log ERROR "plugin_build_path not implemented in ${plugin_name}"
    echo "${home_path}/bin"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Returns the directories to add to LD_LIBRARY_PATH (or equivalent)
#           Example (RDBMS): /u01/app/oracle/product/19/lib
#           Example (ICLIENT): /u01/app/oracle/instantclient_19_21
#           Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/lib
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    oradba_log ERROR "plugin_build_lib_path not implemented in ${plugin_name}"
    echo "${home_path}/lib"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for this product
# Args....: None
# Returns.: 0 on success
# Output..: Configuration section name (uppercase)
# Notes...: Used by oradba_apply_product_config() to load product-specific settings
#           Example: "RDBMS", "DATASAFE", "CLIENT", "ICLIENT", "OUD", "WLS"
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    oradba_log ERROR "plugin_get_config_section not implemented in ${plugin_name}"
    echo "UNKNOWN"
    return 1
}

# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for this product
# Args....: None
# Returns.: 0 on success
# Output..: Space-separated list of required binary names
# Notes...: Used by oradba_check_oracle_binaries() to validate installation
#           Example (RDBMS): "sqlplus tnsping lsnrctl"
#           Example (DATASAFE): "cmctl"
#           Example (CLIENT): "sqlplus tnsping"2
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    oradba_log ERROR "plugin_get_required_binaries not implemented in ${plugin_name}"
    echo ""
    return 1
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
