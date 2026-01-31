#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: plugin_interface.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.19
# Version..: 1.0.0
# Purpose..: Plugin interface template for product-specific behavior
# Notes....: All product plugins must implement these functions
#            See doc/plugin-standards.md for complete interface specification
#            Interface version: v1.0.0 (January 2026)
# Reference: Architecture Review & Refactoring Plan (Phase 1.2)
#            doc/plugin-standards.md - Plugin interface specification
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
# Universal Core Functions (REQUIRED)
# ------------------------------------------------------------------------------
# NOTE: All plugins must implement these 13 universal core functions:
#       1.  plugin_detect_installation  - Auto-discover installations
#       2.  plugin_validate_home        - Validate installation path
#       3.  plugin_adjust_environment   - Adjust ORACLE_HOME if needed
#       4.  plugin_build_base_path      - Resolve ORACLE_BASE_HOME vs ORACLE_HOME
#       5.  plugin_build_env            - Build environment variables
#       6.  plugin_check_status         - Check service/instance status
#       7.  plugin_get_metadata         - Get installation metadata
#       8.  plugin_discover_instances   - Discover instances/domains
#       9.  plugin_get_instance_list    - Enumerate instances/domains
#       10. plugin_supports_aliases     - Support SID-like aliases?
#       11. plugin_build_bin_path       - Get PATH components
#       12. plugin_build_lib_path       - Get LD_LIBRARY_PATH components
#       13. plugin_get_config_section   - Get config section name
#
#       See doc/plugin-standards.md for:
#       - Complete function specifications
#       - Return value standards (exit codes + stdout)
#       - Extension patterns for optional functions
#       - Best practices and examples
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect installations of this product type
# Args....: None
# Returns.: 0 on success
# Output..: List of installation paths (one per line)
# Notes...: Used for auto-discovery when no registry files exist
#           See doc/plugin-standards.md for return value conventions
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
#           See plugin-standards.md for validation strategies
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
# Notes...: Example: DataSafe appends /oracle_cman_home; align ORACLE_HOME with ORACLE_BASE_HOME if needed
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve actual installation base (ORACLE_BASE_HOME-aware)
# Args....: $1 - Input ORACLE_HOME or ORACLE_BASE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: Use when ORACLE_HOME differs from installation base
#           See plugin-standards.md for detailed specification
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    # Default: return input path as base
    # Products with ORACLE_BASE_HOME should override this
    echo "${home_path}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for the product/instance
# Args....: $1 - ORACLE_HOME
#           $2 - Instance/domain identifier (optional)
# Returns.: 0 on success, 1 if not applicable, 2 if unavailable
# Output..: Key=value pairs (one per line)
# Notes...: Builds complete environment: ORACLE_HOME, PATH, LD_LIBRARY_PATH, etc.
#           See plugin-standards.md for detailed specification
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    local instance="${2:-}"
    
    oradba_log ERROR "plugin_build_env not implemented in ${plugin_name}"
    return 2
}

# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if product instance is running
# Args....: $1 - Installation path
#           $2 - Instance name (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Uses explicit environment (not current shell environment)
#           See plugin-standards.md for exit code standards (0=running, 1=stopped, 2=unavailable)
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
    echo "version="
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover all instances for this Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: List of instances (one per line)
# Format..: instance_name|status|additional_metadata
# Notes...: Handles 1:many relationships (RAC, WebLogic, OUD)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    # Default: no instances
    return 0
}

# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate all instances/domains for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: Mandatory for multi-instance products (database, middleware, etc.)
#           See plugin-standards.md for detailed specification
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    # Default: return empty list (no instances)
    # Override for multi-instance products (database, RAC, WebLogic, OUD)
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
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns the directories to add to PATH for this product
#           Example (RDBMS): /u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch
#           Example (ICLIENT): /u01/app/oracle/instantclient_19_21
#           Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/bin
#           See plugin-standards.md for detailed specification
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local home_path="$1"
    oradba_log ERROR "plugin_build_bin_path not implemented in ${plugin_name}"
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
#           Example (CLIENT): "sqlplus tnsping"
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    oradba_log ERROR "plugin_get_required_binaries not implemented in ${plugin_name}"
    echo ""
    return 1
}

# ------------------------------------------------------------------------------
# Category-Specific Mandatory Functions
# ------------------------------------------------------------------------------
# NOTE: These functions are mandatory for specific product categories:
#       - plugin_check_listener_status: Database and listener-based products
#       See doc/plugin-standards.md for category requirements
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: plugin_check_listener_status
# Purpose.: Check listener status for products with listener components
# Args....: $1 - Installation path (ORACLE_HOME)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Category-specific: mandatory for database and listener-based products
#           Separate from plugin_check_status (instance status)
#           Listener lifecycle is managed per Oracle Home, not per instance
#           See plugin-standards.md for detailed specification
# ------------------------------------------------------------------------------
plugin_check_listener_status() {
    local home_path="$1"
    # Default: not applicable for non-listener products
    echo "unavailable"
    return 2
}

# ------------------------------------------------------------------------------
# Optional Plugin Functions
# ------------------------------------------------------------------------------
# NOTE: Optional functions have default implementations but can be overridden:
#       - plugin_get_display_name: Custom display name for instance
#       - plugin_get_version: Product version detection (has default implementation)
#       - plugin_get_required_binaries: Required binaries list (optional)
#       See doc/plugin-standards.md for extension patterns
# ------------------------------------------------------------------------------

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
# Function: plugin_check_listener_status
# Purpose.: Report listener status for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Listener lifecycle is distinct from instance lifecycle; category-specific
# ------------------------------------------------------------------------------
plugin_check_listener_status() {
    local home_path="$1"
    oradba_log ERROR "plugin_check_listener_status not implemented in ${plugin_name}"
    echo "unavailable"
    return 2
}

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
# Function: plugin_get_version
# Purpose.: Get product version from ORACLE_HOME
# Args....: $1 - Installation path
# Returns.: 0 on success with clean version string to stdout
#           1 when version not applicable (no output)
#           2 on error or unavailable (no output)
# Output..: Version string on success only (e.g., "19.21.0.0.0")
# Notes...: Called by plugin_get_metadata, can be overridden for efficiency
#           No sentinel strings (ERR, unknown, N/A) in output
#           See plugin-standards.md for exit code contract details
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    local version
    
    # Validate home path exists
    [[ ! -d "${home_path}" ]] && return 2
    
    # Try version file first
    local version_file="${home_path}/inventory/ContentsXML/comps.xml"
    if [[ -f "${version_file}" ]]; then
        version=$(grep -oP 'VER="\K[^"]+' "${version_file}" 2>/dev/null | head -1)
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # Fallback to opatch if available
    if [[ -x "${home_path}/OPatch/opatch" ]]; then
        version=$("${home_path}/OPatch/opatch" version 2>/dev/null | \
                  grep -oP 'OPatch Version: \K[\d.]+' | head -1)
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # No version found - not applicable
    return 1
}

# ------------------------------------------------------------------------------
# Plugin Interface Loaded
# ------------------------------------------------------------------------------
oradba_log DEBUG "Plugin interface template loaded (v1.0.0)"
