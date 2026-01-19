#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oraenv.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Set Oracle environment for a specific ORACLE_SID
# Notes......: This script sets up the Oracle environment based on the oratab
#              file and hierarchical configuration files. Must be sourced.
#              Usage: source oraenv.sh [ORACLE_SID] [OPTIONS]
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source ${0} [ORACLE_SID]"
    exit 1
fi

# Get the directory where this script resides
_ORAENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ORAENV_BASE_DIR="$(dirname "$_ORAENV_SCRIPT_DIR")"

# Set ORADBA_PREFIX for configuration loading
export ORADBA_PREFIX="${_ORAENV_BASE_DIR}"
export ORADBA_CONFIG_DIR="${ORADBA_PREFIX}/etc"

# Source common library first (provides load_config function)
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_common.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_common.sh"
else
    echo "ERROR: Cannot find common library at ${_ORAENV_BASE_DIR}/lib/oradba_common.sh"
    return 1
fi

# Source registry API (Phase 1 - provides unified installation access)
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_registry.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_ORAENV_BASE_DIR}/lib/oradba_registry.sh"
fi

# Load core configuration (provides base settings for oratab, paths, etc.)
# Note: Full hierarchical config (including SID-specific) is loaded after setting ORACLE_SID
# Use load_config_file from oradba_common.sh for unified config loading
if ! load_config_file "${ORADBA_CONFIG_DIR}/oradba_core.conf" "true"; then
    return 1
fi

# Load local configuration (created during installation, contains coexistence mode)
load_config_file "${ORADBA_CONFIG_DIR}/oradba_local.conf"

# Set ORATAB_FILE dynamically if not already set
if [[ -z "${ORATAB_FILE}" ]]; then
    ORATAB_FILE="$(get_oratab_path)"
    export ORATAB_FILE
fi

# Source database functions library (optional, only if available)
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_db_functions.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_db_functions.sh"
fi

# Source extension system library (optional, only if enabled)
if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS}" == "true" ]] && [[ -f "${_ORAENV_BASE_DIR}/lib/extensions.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/extensions.sh"
fi

# Source new environment management libraries (Phase 1 - v0.19.0)
export ORADBA_BASE="${_ORAENV_BASE_DIR}"
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_env_parser.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_env_parser.sh"
fi
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_env_builder.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_env_builder.sh"
fi
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_env_validator.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_env_validator.sh"
fi

# Source configuration management library (Phase 2)
if [[ -f "${_ORAENV_BASE_DIR}/lib/oradba_env_config.sh" ]]; then
    source "${_ORAENV_BASE_DIR}/lib/oradba_env_config.sh"
fi

# Global variables - declared at script level so they persist across functions
# shellcheck disable=SC2034  # Used across functions in _oraenv_parse_args and _oraenv_main
SHOW_ENV=true
SHOW_STATUS=false
ORAENV_STATUS_ONLY=false
ORAENV_INTERACTIVE=true
REQUESTED_SID=""

# ------------------------------------------------------------------------------
# Function: _oraenv_parse_args
# Purpose.: Parse command line arguments for oraenv.sh
# Args....: $@ - All command line arguments
# Returns.: 0 on success, 1 on error
# Output..: Sets global variables: REQUESTED_SID, SHOW_ENV, SHOW_STATUS, 
#           ORAENV_INTERACTIVE, ORAENV_STATUS_ONLY
# Notes...: Detects TTY for interactive mode, processes --silent, --status,
#           --force, and --help flags
# ------------------------------------------------------------------------------
_oraenv_parse_args() {
    # shellcheck disable=SC2034  # Reserved for future use
    local force_mode=false

    # Detect if running in interactive mode (with TTY)
    if [[ -t 0 ]]; then
        ORAENV_INTERACTIVE=true
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_STATUS=true # Default to showing status in interactive mode
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_ENV=true # Show environment info
    else
        ORAENV_INTERACTIVE=false
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_STATUS=false # Default to silent in non-interactive mode
        # shellcheck disable=SC2034  # Global variables used in _oraenv_main
        SHOW_ENV=false
    fi

    ORAENV_STATUS_ONLY=false # Flag for --status option

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f | --force)
                # shellcheck disable=SC2034  # Reserved for future use
                force_mode=true
                shift
                ;;
            -s | --silent)
                ORAENV_INTERACTIVE=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_STATUS=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_ENV=false
                shift
                ;;
            --status)
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_STATUS=true
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                SHOW_ENV=false
                # shellcheck disable=SC2034  # Global variables used in _oraenv_main
                ORAENV_STATUS_ONLY=true
                shift
                ;;
            -h | --help)
                _oraenv_usage
                return 1
                ;;
            -*)
                oradba_log ERROR "Unknown option: $1"
                _oraenv_usage
                return 1
                ;;
            *)
                if [[ -z "$REQUESTED_SID" ]]; then
                    REQUESTED_SID="$1"
                else
                    oradba_log ERROR "Multiple SIDs provided"
                    return 1
                fi
                shift
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Function: _oraenv_usage
# Purpose.: Display usage information for oraenv.sh
# Args....: None
# Returns.: None (outputs to stderr)
# Output..: Usage message with arguments, options, examples, and environment
#           variable documentation
# Notes...: Output goes to stderr so it's visible when script is sourced
# ------------------------------------------------------------------------------
_oraenv_usage() {
    # Output to stderr so it's visible when sourced
    cat >&2 << EOF
Usage: source oraenv.sh [NAME] [OPTIONS]

Set Oracle environment for a database SID or Oracle Home.

Arguments:
  NAME                Database SID or Oracle Home name (optional)

Options:
  -s, --silent        Silent mode: no prompts, no status display
  --status            Force showing detailed database status
  -f, --force         Force environment setup even if validation fails
  -h, --help          Display this help message

Behavior:
  Interactive (TTY): 
    - With NAME: Sets environment and shows database status (for SIDs)
    - Without NAME: Prompts for selection from SIDs and Oracle Homes
  
  Non-interactive (no TTY) or --silent:
    - With NAME: Sets environment silently
    - Without NAME: Uses first entry (Oracle Home or SID) silently

Examples:
  source oraenv.sh FREE              # Database SID: with status
  source oraenv.sh OUD12             # Oracle Home: silent setup
  source oraenv.sh FREE --silent     # Silent: no status
  source oraenv.sh                   # Interactive: prompt for selection
  echo "..." | source oraenv.sh      # Non-interactive: first entry, silent

Environment Variables:
  ORADBA_ORATAB      Override oratab file location (highest priority)
  ORATAB_FILE        Path to oratab file (default: auto-detected)
  ORACLE_BASE        Oracle base directory
  TNS_ADMIN          TNS configuration directory

  oratab Priority:
    1. \$ORADBA_ORATAB (explicit override)
    2. /etc/oratab (system default)
    3. /var/opt/oracle/oratab (Solaris/AIX)
    4. \${ORADBA_BASE}/etc/oratab (temporary for pre-Oracle)
    5. \${HOME}/.oratab (user fallback)

EOF
}

# ------------------------------------------------------------------------------
# Function: _oraenv_find_oratab
# Purpose.: Locate the oratab file using standard search paths
# Args....: None
# Returns.: 0 on success (oratab found), 1 on error (not found)
# Output..: Echoes path to oratab file if found
# Notes...: Checks ORATAB_FILE variable first, then uses get_oratab_path(),
#           finally falls back to ORATAB_ALTERNATIVES array. Sets ORATAB_FILE
#           environment variable when found.
# ------------------------------------------------------------------------------
_oraenv_find_oratab() {
    # Check if ORATAB_FILE is set and exists
    if [[ -n "${ORATAB_FILE}" ]] && [[ -f "${ORATAB_FILE}" ]]; then
        echo "${ORATAB_FILE}"
        return 0
    fi

    # Use centralized get_oratab_path() function if available
    if type get_oratab_path &> /dev/null; then
        local oratab_path
        oratab_path=$(get_oratab_path)
        if [[ -f "$oratab_path" ]]; then
            echo "$oratab_path"
            return 0
        fi
    fi

    # Fallback: Check alternative locations
    for oratab in "${ORATAB_ALTERNATIVES[@]}"; do
        if [[ -f "$oratab" ]]; then
            echo "$oratab"
            return 0
        fi
    done

    oradba_log ERROR "No oratab file found"
    return 1
}

# ------------------------------------------------------------------------------
# Function: _oraenv_gather_available_entries
# Purpose.: Gather available database SIDs and Oracle Homes from registry
# Args....: $1 - Path to oratab file
#           $2 - Name reference to SIDs array
#           $3 - Name reference to Homes array
# Returns.: 0 on success, 1 if no entries found
# Output..: Populates referenced arrays with available entries
# Notes...: Uses registry API (Phase 1) first, falls back to auto-discovery
#           if enabled. Separates database SIDs from non-database Oracle Homes.
# ------------------------------------------------------------------------------
_oraenv_gather_available_entries() {
    local oratab_file="$1"
    local -n sids_ref="$2"
    local -n homes_ref="$3"
    
    # Try registry API first (Phase 1)
    if type -t oradba_registry_get_databases &>/dev/null; then
        # Get database SIDs from registry
        mapfile -t sids_ref < <(oradba_registry_get_databases 2>/dev/null | cut -d'|' -f2)
        
        # Get non-database homes from registry
        local all_entries
        all_entries=$(oradba_registry_get_all 2>/dev/null)
        if [[ -n "${all_entries}" ]]; then
            while IFS='|' read -r ptype name home version flags order alias desc; do
                # Skip database types (already in sids)
                [[ "${ptype}" == "database" ]] && continue
                homes_ref+=("${name}")
            done <<< "${all_entries}"
        fi
    fi

    local total_entries=$((${#sids_ref[@]} + ${#homes_ref[@]}))

    # If no entries found, try auto-discovery
    if [[ $total_entries -eq 0 ]]; then
        if [[ "${ORADBA_AUTO_DISCOVER_INSTANCES:-true}" == "true" ]] && command -v discover_running_oracle_instances &> /dev/null; then
            local discovered_oratab
            discovered_oratab=$(discover_running_oracle_instances 2>/dev/null)
            
            if [[ -n "$discovered_oratab" ]]; then
                oradba_log INFO "Auto-discovered running Oracle instances (not in oratab)"
                
                # Extract SIDs from discovered entries (filter empty lines)
                mapfile -t sids_ref < <(echo "$discovered_oratab" | awk -F: 'NF>0 {print $1}')
                
                if [[ ${#sids_ref[@]} -eq 0 ]]; then
                    oradba_log ERROR "No Oracle instances or homes found"
                    return 1
                fi
            else
                oradba_log ERROR "No Oracle instances or homes found"
                return 1
            fi
        else
            oradba_log ERROR "No Oracle instances or homes found"
            return 1
        fi
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: _oraenv_display_selection_menu
# Purpose.: Display interactive selection menu for SIDs and Oracle Homes
# Args....: $1 - Name reference to SIDs array
#           $2 - Name reference to Homes array
# Returns.: None (outputs to stderr)
# Output..: Formatted menu with numbered entries showing Oracle Homes (with type)
#           and Database SIDs. Menu is output to stderr for interactive prompting.
# Notes...: Oracle Homes are listed first, then database SIDs. Each entry is
#           numbered sequentially for user selection.
# ------------------------------------------------------------------------------
_oraenv_display_selection_menu() {
    # shellcheck disable=SC2178
    local -n sids_ref="$1"
    # shellcheck disable=SC2178
    local -n homes_ref="$2"
    
    # Display list to stderr so it appears before the prompt
    {
        echo ""
        echo "Available Oracle instances and homes:"
        echo "========================================"

        local counter=1

        # Display Oracle Homes first (if any)
        if [[ ${#homes_ref[@]} -gt 0 ]]; then
            echo ""
            echo "Oracle Homes:"
            for home in "${homes_ref[@]}"; do
                local home_type=""
                if command -v get_oracle_home_type &> /dev/null; then
                    home_type=$(get_oracle_home_type "$home" 2> /dev/null || echo "")
                fi
                printf "  [%d] %-20s (%s)\n" "$counter" "$home" "${home_type}"
                ((counter++))
            done
        fi

        # Display Database SIDs
        if [[ ${#sids_ref[@]} -gt 0 ]]; then
            echo ""
            echo "Database SIDs:"
            for sid in "${sids_ref[@]}"; do
                printf "  [%d] %s\n" "$counter" "$sid"
                ((counter++))
            done
        fi
        echo ""
    } >&2
}

# ------------------------------------------------------------------------------
# Function: _oraenv_parse_user_selection
# Purpose.: Parse and validate user selection from interactive prompt
# Args....: $1 - User selection (number or name)
#           $2 - Total number of available entries
#           $3 - Name reference to SIDs array
#           $4 - Name reference to Homes array
# Returns.: 0 on success, 1 if no selection made
# Output..: Echoes selected SID or Oracle Home name
# Notes...: Accepts either numeric selection (1-N) or direct name entry.
#           Numeric selection maps to arrays (Homes first, then SIDs).
# ------------------------------------------------------------------------------
_oraenv_parse_user_selection() {
    local selection="$1"
    local total_entries="$2"
    # shellcheck disable=SC2178
    local -n sids_ref="$3"
    # shellcheck disable=SC2178
    local -n homes_ref="$4"
    
    # Check if user entered a number
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le $total_entries ]]; then
        # User entered a valid number
        local idx=$((selection - 1))
        if [[ $idx -lt ${#homes_ref[@]} ]]; then
            # Selected an Oracle Home
            echo "${homes_ref[$idx]}"
        else
            # Selected a database SID
            local sid_idx=$((idx - ${#homes_ref[@]}))
            echo "${sids_ref[$sid_idx]}"
        fi
    elif [[ -n "$selection" ]]; then
        # User entered a name directly
        echo "$selection"
    else
        oradba_log ERROR "No selection made"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: _oraenv_prompt_sid
# Purpose.: Get SID from user (interactive) or first entry (non-interactive)
# Args....: $1 - Path to oratab file
# Returns.: 0 on success, 1 on error
# Output..: Selected SID or Oracle Home name
# ------------------------------------------------------------------------------
_oraenv_prompt_sid() {
    local oratab_file="$1"

    # Gather available SIDs and Oracle Homes
    local -a sids
    local -a homes
    
    if ! _oraenv_gather_available_entries "$oratab_file" sids homes; then
        return 1
    fi

    local total_entries=$((${#sids[@]} + ${#homes[@]}))

    # If non-interactive mode, return first entry (SID or Home)
    if [[ "$ORAENV_INTERACTIVE" != "true" ]]; then
        if [[ ${#sids[@]} -gt 0 ]]; then
            echo "${sids[0]}"
        else
            echo "${homes[0]}"
        fi
        return 0
    fi

    # Display selection menu
    _oraenv_display_selection_menu sids homes

    # Prompt for selection
    local selection
    read -p "Enter name or number [1-${total_entries}]: " selection

    # Parse and return user selection
    _oraenv_parse_user_selection "$selection" "$total_entries" sids homes
}

# ------------------------------------------------------------------------------
# Function: _oraenv_handle_oracle_home
# Purpose.: Setup environment for an Oracle Home (non-database installation)
# Args....: $1 - Oracle Home name from oradba_homes.conf
# Returns.: 0 on success, 1 on error
# Output..: Exports ORACLE_HOME, ORACLE_BASE, ORACLE_SID (empty for non-DB),
#           and other Oracle environment variables
# Notes...: Uses set_oracle_home_environment() from Oracle Homes management.
#           Unsets previous environment, derives ORACLE_BASE, loads hierarchical
#           configuration, and logs environment details.
# ------------------------------------------------------------------------------
_oraenv_handle_oracle_home() {
    local requested_sid="$1"
    
    oradba_log DEBUG "Setting environment for Oracle Home: $requested_sid"

    # Unset previous Oracle environment
    _oraenv_unset_old_env

    # Set Oracle Home environment using Oracle Homes management
    if command -v set_oracle_home_environment &> /dev/null; then
        set_oracle_home_environment "$requested_sid"
        if [[ $? -ne 0 ]]; then
            oradba_log ERROR "Failed to set Oracle Home environment for: $requested_sid"
            return 1
        fi

        # Set ORACLE_SID to empty for non-database homes
        export ORACLE_SID=""

        # Set ORACLE_BASE if not already set
        if [[ -z "${ORACLE_BASE}" ]]; then
            local derived_base
            derived_base="$(derive_oracle_base "$ORACLE_HOME")"
            export ORACLE_BASE="${derived_base}"
        fi

        # Set common environment variables
        export_oracle_base_env

        # Load hierarchical configuration for this Oracle Home
        load_config "$requested_sid"

        oradba_log DEBUG "Oracle Home environment set: $requested_sid"
        oradba_log DEBUG "ORACLE_HOME: $ORACLE_HOME"
        oradba_log DEBUG "Product Type: $(get_oracle_home_type "$requested_sid" 2> /dev/null || echo "unknown")"

        return 0
    else
        oradba_log ERROR "Oracle Homes functions not available"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: _oraenv_lookup_oratab_entry
# Purpose.: Lookup database entry from registry or oratab file
# Args....: $1 - Requested SID name
#           $2 - Path to oratab file
# Returns.: None (outputs via echo)
# Output..: Echoes oratab entry in format "SID:HOME:FLAGS" if found, empty if not
# Notes...: Uses registry API (Phase 1) first via oradba_registry_get_by_name(),
#           falls back to direct oratab parsing with parse_oratab(). Converts
#           registry format to oratab format for compatibility.
# ------------------------------------------------------------------------------
_oraenv_lookup_oratab_entry() {
    local requested_sid="$1"
    local oratab_file="$2"
    local oratab_entry=""
    
    # Try registry API first (Phase 1)
    if type -t oradba_registry_get_by_name &>/dev/null; then
        local registry_entry
        registry_entry=$(oradba_registry_get_by_name "$requested_sid" 2>/dev/null)
        
        if [[ -n "${registry_entry}" ]]; then
            # Parse registry format: type|name|home|version|flags|order|alias|desc
            local ptype name home flags
            local version order alias desc
            # shellcheck disable=SC2034  # version, order, alias, desc intentionally unused
            IFS='|' read -r ptype name home version flags order alias desc <<< "${registry_entry}"
            # Convert to oratab format for compatibility: sid:home:flags
            oratab_entry="${name}:${home}:${flags}"
            oradba_log DEBUG "Found entry in registry: ${requested_sid} -> ${home}"
        fi
    fi
    
    # Fallback to direct oratab parsing if registry didn't find it
    if [[ -z "${oratab_entry}" ]]; then
        oratab_entry=$(parse_oratab "$requested_sid" "$oratab_file")
    fi
    
    echo "${oratab_entry}"
}

# ------------------------------------------------------------------------------
# Function: _oraenv_auto_discover_instances
# Purpose.: Auto-discover running Oracle instances when oratab is empty
# Args....: $1 - Requested SID name (optional, for targeted discovery)
#           $2 - Path to oratab file
# Returns.: None (outputs via echo)
# Output..: Echoes discovered oratab entry in format "SID:HOME:FLAGS"
# Notes...: Only runs if ORADBA_AUTO_DISCOVER_INSTANCES=true and oratab is empty.
#           Uses discover_running_oracle_instances() to find running processes.
#           Case-insensitive SID matching with awk. Optionally persists discoveries
#           to oratab via persist_discovered_instances().
# ------------------------------------------------------------------------------
_oraenv_auto_discover_instances() {
    local requested_sid="$1"
    local oratab_file="$2"
    local oratab_entry=""
    
    # Check if auto-discovery is enabled
    if [[ "${ORADBA_AUTO_DISCOVER_INSTANCES:-true}" != "true" ]]; then
        return 1
    fi
    
    # Check if oratab is empty
    local entry_count
    entry_count=$(grep -cv "^#\|^[[:space:]]*$" "$oratab_file" 2>/dev/null) || entry_count=0
    
    if [[ "$entry_count" -ne 0 ]]; then
        return 1
    fi
    
    # Attempt discovery
    local discovered_oratab
    discovered_oratab=$(discover_running_oracle_instances 2>/dev/null)
    
    if [[ -z "$discovered_oratab" ]]; then
        return 1
    fi
    
    oradba_log INFO "Auto-discovered running Oracle instances (not in oratab)"
    
    # Persist discovered instances to oratab
    if command -v persist_discovered_instances &> /dev/null; then
        persist_discovered_instances "$discovered_oratab" "$oratab_file"
    else
        oradba_log INFO "These are temporary entries - add them to $oratab_file if needed"
    fi
    
    # If no SID was requested, use first discovered instance
    if [[ -z "$requested_sid" ]]; then
        oratab_entry=$(echo "$discovered_oratab" | head -n1)
        oradba_log INFO "Auto-selecting first discovered instance: $(echo "$oratab_entry" | cut -d: -f1)"
    else
        # Try to find requested SID in discovered instances (case-insensitive)
        oratab_entry=$(echo "$discovered_oratab" | awk -F: -v sid="$requested_sid" 'tolower($1) == tolower(sid) {print; exit}')
        
        if [[ -z "$oratab_entry" ]]; then
            oradba_log DEBUG "SID '$requested_sid' not found in discovered instances"
            oradba_log DEBUG "Discovered entries: $discovered_oratab"
        else
            oradba_log INFO "Found discovered instance: $(echo "$oratab_entry" | cut -d: -f1)"
        fi
    fi
    
    echo "${oratab_entry}"
}

# ------------------------------------------------------------------------------
# Function: _oraenv_apply_product_adjustments
# Purpose.: Apply product-specific path adjustments (e.g., DataSafe plugin)
# Args....: $1 - Oracle Home path from oratab
# Returns.: None (outputs via echo)
# Output..: Echoes "adjusted_home|datasafe_install_dir" pipe-delimited values
# Notes...: Detects DataSafe installations by oracle_cman_home subdirectory,
#           sources datasafe_plugin.sh, and calls plugin_adjust_environment().
#           Returns original path if no adjustments needed. Plugin system allows
#           extensible product-specific environment handling.
# ------------------------------------------------------------------------------
_oraenv_apply_product_adjustments() {
    local oracle_home="$1"
    local adjusted_home="${oracle_home}"
    local datasafe_install_dir=""
    
    # Check if this is a DataSafe installation using plugin
    if [[ -d "${oracle_home}/oracle_cman_home" ]]; then
        local plugin_file="${ORADBA_BASE}/src/lib/plugins/datasafe_plugin.sh"
        if [[ -f "${plugin_file}" ]]; then
            # shellcheck source=/dev/null
            source "${plugin_file}"
            datasafe_install_dir="${oracle_home}"
            adjusted_home=$(plugin_adjust_environment "${oracle_home}")
            oradba_log DEBUG "DataSafe detected: ORACLE_HOME adjusted via plugin"
        fi
    fi
    
    # Output: adjusted_home|datasafe_install_dir
    echo "${adjusted_home}|${datasafe_install_dir}"
}

# ------------------------------------------------------------------------------
# Function: _oraenv_setup_environment_variables
# Purpose.: Setup Oracle environment variables for database instance
# Args....: $1 - Actual SID from oratab (preserves case)
#           $2 - Oracle Home path (after product adjustments)
#           $3 - Complete oratab entry (SID:HOME:FLAGS)
#           $4 - DataSafe install directory (optional, empty if not DataSafe)
# Returns.: None (exports environment variables)
# Output..: Exports ORACLE_SID, ORACLE_HOME, ORACLE_BASE, ORACLE_STARTUP,
#           and optional DataSafe variables (DATASAFE_HOME, DATASAFE_INSTALL_DIR,
#           DATASAFE_CONFIG). Derives ORACLE_BASE if not set.
# Notes...: Calls export_oracle_base_env() for common Oracle environment setup.
#           Startup flag (Y/N) extracted from oratab entry field 3.
# ------------------------------------------------------------------------------
_oraenv_setup_environment_variables() {
    local actual_sid="$1"
    local oracle_home="$2"
    local oratab_entry="$3"
    local datasafe_install_dir="$4"
    
    # Set new environment (use actual SID from oratab to preserve case)
    export ORACLE_SID="$actual_sid"
    export ORACLE_HOME="$oracle_home"
    
    # Set DataSafe-specific variables if applicable
    if [[ -n "$datasafe_install_dir" ]]; then
        export DATASAFE_HOME="$oracle_home"
        export DATASAFE_INSTALL_DIR="$datasafe_install_dir"
        if [[ -d "${oracle_home}/config" ]]; then
            export DATASAFE_CONFIG="${oracle_home}/config"
        fi
    fi

    # Set ORACLE_BASE if not already set
    if [[ -z "${ORACLE_BASE}" ]]; then
        local derived_base
        derived_base="$(derive_oracle_base "$ORACLE_HOME")"
        export ORACLE_BASE="${derived_base}"
    fi

    # Set common environment variables
    export_oracle_base_env

    # Set startup flag from oratab
    local startup_flag
    startup_flag=$(echo "$oratab_entry" | cut -d: -f3)
    export ORACLE_STARTUP="${startup_flag:-N}"
}

# ------------------------------------------------------------------------------
# Function: _oraenv_load_configurations
# Purpose.: Load hierarchical configurations and extensions for environment
# Args....: $1 - SID or Oracle Home name identifier
# Returns.: None (modifies environment)
# Output..: Loads configuration hierarchy: core → standard → customer → default
#           → sid-specific. Configures SQLPATH and loads extensions.
# Notes...: Calls load_config() for hierarchical config merging. Later configs
#           override earlier ones including aliases. Configures SQLPATH unless
#           ORADBA_CONFIGURE_SQLPATH=false. Loads extensions via load_extensions()
#           unless in basenv coexistence mode (unless ORADBA_EXTENSIONS_IN_COEXIST=true).
# ------------------------------------------------------------------------------
_oraenv_load_configurations() {
    local identifier="$1"
    
    # Load hierarchical configuration
    # This reloads all configs in order: core -> standard -> customer -> default -> sid-specific
    # Later configs override earlier settings, including aliases
    load_config "$identifier"

    # Configure SQLPATH for SQL script discovery (#11)
    if [[ "${ORADBA_CONFIGURE_SQLPATH}" != "false" ]]; then
        configure_sqlpath
    fi

    # Load extensions (skip in coexistence mode unless forced) (#15)
    if [[ "${ORADBA_COEXIST_MODE}" != "basenv" ]] || [[ "${ORADBA_EXTENSIONS_IN_COEXIST}" == "true" ]]; then
        if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS}" == "true" ]] && command -v load_extensions &> /dev/null; then
            load_extensions
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: _oraenv_set_environment
# Purpose.: Set Oracle environment for a database SID or Oracle Home
# Args....: $1 - Requested SID or Oracle Home name
#           $2 - Path to oratab file
# Returns.: 0 on success, 1 on error
# ------------------------------------------------------------------------------
_oraenv_set_environment() {
    local requested_sid="$1"
    local oratab_file="$2"

    # Check if this is an Oracle Home (not a database SID)
    if command -v is_oracle_home &> /dev/null && is_oracle_home "$requested_sid"; then
        _oraenv_handle_oracle_home "$requested_sid"
        return $?
    fi

    # Not an Oracle Home - proceed with normal database SID lookup
    local oratab_entry
    oratab_entry=$(_oraenv_lookup_oratab_entry "$requested_sid" "$oratab_file")

    # Try auto-discovery if not found
    if [[ -z "$oratab_entry" ]]; then
        oratab_entry=$(_oraenv_auto_discover_instances "$requested_sid" "$oratab_file")
        
        # Still no entry found after discovery attempt
        if [[ -z "$oratab_entry" ]]; then
            oradba_log ERROR "ORACLE_SID '$requested_sid' not found in $oratab_file"
            return 1
        fi
    fi

    # Extract actual SID from oratab (preserves uppercase from oratab)
    local actual_sid
    actual_sid=$(echo "$oratab_entry" | cut -d: -f1)

    # Extract ORACLE_HOME from oratab
    local oracle_home
    oracle_home=$(echo "$oratab_entry" | cut -d: -f2)

    if [[ ! -d "$oracle_home" ]]; then
        oradba_log WARN "ORACLE_HOME directory does not exist: $oracle_home"
        oradba_log WARN "This may be a dummy entry or Oracle is not yet installed"
        oradba_log INFO "Continuing with environment setup..."
        # Don't return error - allow setting env even if HOME doesn't exist
    fi
    
    # Apply product-specific adjustments via plugin system
    local adjustments datasafe_install_dir
    adjustments=$(_oraenv_apply_product_adjustments "$oracle_home")
    oracle_home=$(echo "$adjustments" | cut -d'|' -f1)
    datasafe_install_dir=$(echo "$adjustments" | cut -d'|' -f2)

    # Unset previous Oracle environment
    _oraenv_unset_old_env

    # Setup environment variables
    _oraenv_setup_environment_variables "$actual_sid" "$oracle_home" "$oratab_entry" "$datasafe_install_dir"

    # Load configurations and extensions
    _oraenv_load_configurations "$actual_sid"

    oradba_log DEBUG "Oracle environment set for SID: $ORACLE_SID"
    oradba_log DEBUG "ORACLE_HOME: $ORACLE_HOME"
    oradba_log DEBUG "ORACLE_BASE: $ORACLE_BASE"
    oradba_log DEBUG "TNS_ADMIN: ${TNS_ADMIN:-not set}"
    oradba_log DEBUG "SQLPATH: ${SQLPATH:-not set}"

    return 0
}

# ------------------------------------------------------------------------------
# Function: _oraenv_unset_old_env
# Purpose.: Unset previous Oracle environment variables before setting new ones
# Args....: None
# Returns.: None (modifies environment)
# Output..: Removes old ORACLE_HOME paths from PATH and LD_LIBRARY_PATH
# Notes...: Uses sed to remove both "$ORACLE_HOME/bin:" and ":$ORACLE_HOME/bin"
#           patterns to handle paths at beginning, middle, or end of PATH/LD_LIBRARY_PATH.
#           Prevents PATH pollution when switching between Oracle environments.
# ------------------------------------------------------------------------------
_oraenv_unset_old_env() {
    # Remove old ORACLE_HOME from PATH
    if [[ -n "${ORACLE_HOME}" ]]; then
        PATH=$(echo "$PATH" | sed -e "s|${ORACLE_HOME}/bin:||g" -e "s|:${ORACLE_HOME}/bin||g")
        LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | sed -e "s|${ORACLE_HOME}/lib:||g" -e "s|:${ORACLE_HOME}/lib||g")
    fi

    export PATH
    export LD_LIBRARY_PATH
}

# ------------------------------------------------------------------------------
# Function: _oraenv_show_environment
# Purpose.: Display current Oracle environment variables
# Args....: None
# Returns.: None (outputs to stdout)
# Output..: Formatted display of key Oracle environment variables:
#           ORACLE_SID, ORACLE_HOME, ORACLE_BASE, TNS_ADMIN, NLS_LANG, PATH
# Notes...: Shows "not set" for unset variables. Used in interactive mode to
#           confirm environment setup. PATH is displayed in full.
# ------------------------------------------------------------------------------
_oraenv_show_environment() {
    cat << EOF

Oracle Environment:
==================
ORACLE_SID       : ${ORACLE_SID:-not set}
ORACLE_HOME      : ${ORACLE_HOME:-not set}
ORACLE_BASE      : ${ORACLE_BASE:-not set}
TNS_ADMIN        : ${TNS_ADMIN:-not set}
NLS_LANG         : ${NLS_LANG:-not set}
PATH             : ${PATH}

EOF
}

# ------------------------------------------------------------------------------
# Function: _oraenv_main
# Purpose.: Main orchestration function for oraenv.sh
# Args....: $@ - All command line arguments
# Returns.: 0 on success, 1 on error
# Output..: Sets Oracle environment, optionally displays status and environment
# Notes...: Workflow: 1) Parse arguments, 2) Find oratab, 3) Get/prompt for SID,
#           4) Set environment, 5) Show environment (if SHOW_ENV=true),
#           6) Show database status (if SHOW_STATUS=true and available).
#           Handles no-Oracle mode when oratab not found. Must be sourced, not executed.
# ------------------------------------------------------------------------------
_oraenv_main() {
    _oraenv_parse_args "$@"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Find oratab file
    local oratab_file
    oratab_file=$(_oraenv_find_oratab)

    if [[ $? -ne 0 ]]; then
        oradba_log WARN "No oratab file found - running in no-Oracle mode"
        oradba_log INFO "OraDBA is installed but Oracle Database is not detected"
        oradba_log INFO "After installing Oracle, use: oradba_setup.sh link-oratab"

        # Set minimal environment for no-Oracle mode
        export ORACLE_SID="${REQUESTED_SID:-dummy}"
        export ORACLE_HOME="${ORACLE_HOME:-${ORADBA_PREFIX}/dummy}"
        export ORACLE_BASE="${ORACLE_BASE:-${ORADBA_PREFIX%/local/oradba}}"
        export ORADBA_NO_ORACLE_MODE=true

        oradba_log INFO "Minimal Oracle environment set (no-Oracle mode):"
        oradba_log INFO "  ORACLE_SID:  ${ORACLE_SID}"
        oradba_log INFO "  ORACLE_HOME: ${ORACLE_HOME}"
        oradba_log INFO "  ORACLE_BASE: ${ORACLE_BASE}"

        return 0
    fi

    oradba_log DEBUG "Using oratab file: $oratab_file"

    # Get ORACLE_SID if not provided
    if [[ -z "$REQUESTED_SID" ]]; then
        REQUESTED_SID=$(_oraenv_prompt_sid "$oratab_file")
        if [[ -z "$REQUESTED_SID" ]]; then
            oradba_log ERROR "No ORACLE_SID provided"
            return 1
        fi
    fi

    # Set environment
    _oraenv_set_environment "$REQUESTED_SID" "$oratab_file"
    local result=$?

    if [[ $result -eq 0 ]]; then
        # Handle different display modes
        if [[ "$ORAENV_STATUS_ONLY" == "true" ]] && command -v show_database_status &> /dev/null; then
            # --status flag: show only database status
            show_database_status
        elif [[ "$SHOW_STATUS" == "true" ]] && command -v show_database_status &> /dev/null; then
            # Interactive mode with status
            show_database_status
        fi
        # Silent mode or no status: show nothing
    fi

    return $result
}

# Run main function with all arguments
_oraenv_main "$@"
