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

# Parse command line arguments
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
                log_error "Unknown option: $1"
                _oraenv_usage
                return 1
                ;;
            *)
                if [[ -z "$REQUESTED_SID" ]]; then
                    REQUESTED_SID="$1"
                else
                    log_error "Multiple SIDs provided"
                    return 1
                fi
                shift
                ;;
        esac
    done
}

# Display usage
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

# Find oratab file
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

    log_error "No oratab file found"
    return 1
}

# Get SID from user (interactive) or first SID (non-interactive)
_oraenv_prompt_sid() {
    local oratab_file="$1"

    # Get list of available SIDs from oratab
    local -a sids
    mapfile -t sids < <(grep -v "^#" "$oratab_file" | grep -v "^$" | awk -F: '{print $1}')

    # Get list of Oracle Homes if available
    local -a homes
    if command -v list_oracle_homes &> /dev/null; then
        mapfile -t homes < <(list_oracle_homes | awk '{print $1}')
    fi

    local total_entries=$((${#sids[@]} + ${#homes[@]}))

    # Check if we found any SIDs or Homes
    if [[ $total_entries -eq 0 ]]; then
        # Try auto-discovery if enabled
        if [[ "${ORADBA_AUTO_DISCOVER_INSTANCES:-true}" == "true" ]] && command -v discover_running_oracle_instances &> /dev/null; then
            local discovered_oratab
            discovered_oratab=$(discover_running_oracle_instances 2>/dev/null)
            
            if [[ -n "$discovered_oratab" ]]; then
                log_info "Auto-discovered running Oracle instances (not in oratab)"
                
                # Extract SIDs from discovered entries (filter empty lines)
                mapfile -t sids < <(echo "$discovered_oratab" | awk -F: 'NF>0 {print $1}')
                
                # Recalculate total entries
                local discovered_count=${#sids[@]}
                
                if [[ $discovered_count -eq 0 ]]; then
                    log_error "No Oracle instances or homes found"
                    return 1
                fi
                
                total_entries=$discovered_count
            else
                log_error "No Oracle instances or homes found"
                return 1
            fi
        else
            log_error "No Oracle instances or homes found"
            return 1
        fi
    fi

    # If non-interactive mode, return first entry (SID or Home)
    if [[ "$ORAENV_INTERACTIVE" != "true" ]]; then
        if [[ ${#sids[@]} -gt 0 ]]; then
            echo "${sids[0]}"
        else
            echo "${homes[0]}"
        fi
        return 0
    fi

    # Display list to stderr so it appears before the prompt
    {
        echo ""
        echo "Available Oracle instances and homes:"
        echo "========================================"

        local counter=1

        # Display Oracle Homes first (if any)
        if [[ ${#homes[@]} -gt 0 ]]; then
            echo ""
            echo "Oracle Homes:"
            for home in "${homes[@]}"; do
                local home_type=""
                if command -v get_oracle_home_type &> /dev/null; then
                    home_type=$(get_oracle_home_type "$home" 2> /dev/null || echo "")
                fi
                printf "  [%d] %-20s (%s)\n" "$counter" "$home" "${home_type}"
                ((counter++))
            done
        fi

        # Display Database SIDs
        if [[ ${#sids[@]} -gt 0 ]]; then
            echo ""
            echo "Database SIDs:"
            for sid in "${sids[@]}"; do
                printf "  [%d] %s\n" "$counter" "$sid"
                ((counter++))
            done
        fi
        echo ""
    } >&2

    # Prompt for selection
    local selection
    read -p "Enter name or number [1-${total_entries}]: " selection

    # Check if user entered a number
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le $total_entries ]]; then
        # User entered a valid number
        local idx=$((selection - 1))
        if [[ $idx -lt ${#homes[@]} ]]; then
            # Selected an Oracle Home
            echo "${homes[$idx]}"
        else
            # Selected a database SID
            local sid_idx=$((idx - ${#homes[@]}))
            echo "${sids[$sid_idx]}"
        fi
    elif [[ -n "$selection" ]]; then
        # User entered a name directly
        echo "$selection"
    else
        log_error "No selection made"
        return 1
    fi
}

# Set Oracle environment
_oraenv_set_environment() {
    local requested_sid="$1"
    local oratab_file="$2"

    # Check if this is an Oracle Home (not a database SID)
    if command -v is_oracle_home &> /dev/null && is_oracle_home "$requested_sid"; then
        log_debug "Setting environment for Oracle Home: $requested_sid"

        # Unset previous Oracle environment
        _oraenv_unset_old_env

        # Set Oracle Home environment using Oracle Homes management
        if command -v set_oracle_home_environment &> /dev/null; then
            set_oracle_home_environment "$requested_sid"
            if [[ $? -ne 0 ]]; then
                log_error "Failed to set Oracle Home environment for: $requested_sid"
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

            log_debug "Oracle Home environment set: $requested_sid"
            log_debug "ORACLE_HOME: $ORACLE_HOME"
            log_debug "Product Type: $(get_oracle_home_type "$requested_sid" 2> /dev/null || echo "unknown")"

            return 0
        else
            log_error "Oracle Homes functions not available"
            return 1
        fi
    fi

    # Not an Oracle Home - proceed with normal database SID lookup
    # Parse oratab entry (case-insensitive)
    local oratab_entry
    oratab_entry=$(parse_oratab "$requested_sid" "$oratab_file")

    if [[ -z "$oratab_entry" ]]; then
        # Try auto-discovery if oratab is empty and feature is enabled
        if [[ "${ORADBA_AUTO_DISCOVER_INSTANCES:-true}" == "true" ]]; then
            local entry_count
            entry_count=$(grep -cv "^#\|^[[:space:]]*$" "$oratab_file" 2>/dev/null) || entry_count=0
            
            if [[ "$entry_count" -eq 0 ]]; then
                local discovered_oratab
                discovered_oratab=$(discover_running_oracle_instances 2>/dev/null)
                
                if [[ -n "$discovered_oratab" ]]; then
                    log_info "Auto-discovered running Oracle instances (not in oratab)"
                    
                    # Persist discovered instances to oratab
                    if command -v persist_discovered_instances &> /dev/null; then
                        persist_discovered_instances "$discovered_oratab" "$oratab_file"
                    else
                        log_info "These are temporary entries - add them to $oratab_file if needed"
                    fi
                    
                    # If no SID was requested, use first discovered instance
                    if [[ -z "$requested_sid" ]]; then
                        oratab_entry=$(echo "$discovered_oratab" | head -n1)
                        log_info "Auto-selecting first discovered instance: $(echo "$oratab_entry" | cut -d: -f1)"
                    else
                        # Try to find requested SID in discovered instances (case-insensitive)
                        # Use awk for more robust matching
                        oratab_entry=$(echo "$discovered_oratab" | awk -F: -v sid="$requested_sid" 'tolower($1) == tolower(sid) {print; exit}')
                        
                        if [[ -z "$oratab_entry" ]]; then
                            log_debug "SID '$requested_sid' not found in discovered instances"
                            log_debug "Discovered entries: $discovered_oratab"
                        else
                            log_info "Found discovered instance: $(echo "$oratab_entry" | cut -d: -f1)"
                        fi
                    fi
                fi
            fi
        fi
        
        # Still no entry found after discovery attempt
        if [[ -z "$oratab_entry" ]]; then
            log_error "ORACLE_SID '$requested_sid' not found in $oratab_file"
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
        log_warn "ORACLE_HOME directory does not exist: $oracle_home"
        log_warn "This may be a dummy entry or Oracle is not yet installed"
        log_info "Continuing with environment setup..."
        # Don't return error - allow setting env even if HOME doesn't exist
    fi
    
    # Apply product-specific adjustments via plugin system
    local datasafe_install_dir=""
    local adjusted_home="${oracle_home}"
    
    # Check if this is a DataSafe installation
    if [[ -d "${oracle_home}/oracle_cman_home" ]]; then
        local plugin_file="${ORADBA_BASE}/src/lib/plugins/datasafe_plugin.sh"
        if [[ -f "${plugin_file}" ]]; then
            # shellcheck source=/dev/null
            source "${plugin_file}"
            datasafe_install_dir="${oracle_home}"
            adjusted_home=$(plugin_adjust_environment "${oracle_home}")
            log_debug "DataSafe detected: ORACLE_HOME adjusted via plugin"
        else
            # Fallback to old logic
            datasafe_install_dir="${oracle_home}"
            adjusted_home="${oracle_home}/oracle_cman_home"
            log_debug "DataSafe detected: ORACLE_HOME adjusted to oracle_cman_home (fallback)"
        fi
    fi
    
    oracle_home="${adjusted_home}"

    # Unset previous Oracle environment
    _oraenv_unset_old_env

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
        # Try to derive from ORACLE_HOME using intelligent method
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

    # Load hierarchical configuration for this SID
    # This reloads all configs in order: core -> standard -> customer -> default -> sid-specific
    # Later configs override earlier settings, including aliases
    load_config "$actual_sid"

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

    log_debug "Oracle environment set for SID: $ORACLE_SID"
    log_debug "ORACLE_HOME: $ORACLE_HOME"
    log_debug "ORACLE_BASE: $ORACLE_BASE"
    log_debug "TNS_ADMIN: ${TNS_ADMIN:-not set}"
    log_debug "SQLPATH: ${SQLPATH:-not set}"

    return 0
}

# Unset old Oracle environment variables
_oraenv_unset_old_env() {
    # Remove old ORACLE_HOME from PATH
    if [[ -n "${ORACLE_HOME}" ]]; then
        PATH=$(echo "$PATH" | sed -e "s|${ORACLE_HOME}/bin:||g" -e "s|:${ORACLE_HOME}/bin||g")
        LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | sed -e "s|${ORACLE_HOME}/lib:||g" -e "s|:${ORACLE_HOME}/lib||g")
    fi

    export PATH
    export LD_LIBRARY_PATH
}

# Display current Oracle environment
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

# Main execution
_oraenv_main() {
    _oraenv_parse_args "$@"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Find oratab file
    local oratab_file
    oratab_file=$(_oraenv_find_oratab)

    if [[ $? -ne 0 ]]; then
        log_warn "No oratab file found - running in no-Oracle mode"
        log_info "OraDBA is installed but Oracle Database is not detected"
        log_info "After installing Oracle, use: oradba_setup.sh link-oratab"

        # Set minimal environment for no-Oracle mode
        export ORACLE_SID="${REQUESTED_SID:-dummy}"
        export ORACLE_HOME="${ORACLE_HOME:-${ORADBA_PREFIX}/dummy}"
        export ORACLE_BASE="${ORACLE_BASE:-${ORADBA_PREFIX%/local/oradba}}"
        export ORADBA_NO_ORACLE_MODE=true

        log_info "Minimal Oracle environment set (no-Oracle mode):"
        log_info "  ORACLE_SID:  ${ORACLE_SID}"
        log_info "  ORACLE_HOME: ${ORACLE_HOME}"
        log_info "  ORACLE_BASE: ${ORACLE_BASE}"

        return 0
    fi

    log_debug "Using oratab file: $oratab_file"

    # Get ORACLE_SID if not provided
    if [[ -z "$REQUESTED_SID" ]]; then
        REQUESTED_SID=$(_oraenv_prompt_sid "$oratab_file")
        if [[ -z "$REQUESTED_SID" ]]; then
            log_error "No ORACLE_SID provided"
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
