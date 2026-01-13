#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_setup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Setup helper for post-installation configuration tasks
# Notes......: Provides utilities for linking oratab, checking installation,
#              and displaying configuration after Oracle is installed
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="${ORADBA_BASE:-$(dirname "$SCRIPT_DIR")}"

# Source common library
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "${ORADBA_BASE}/lib/common.sh"
else
    echo "ERROR: Cannot find common library at ${ORADBA_BASE}/lib/common.sh" >&2
    exit 1
fi

# Initialize logging
init_logging

# ------------------------------------------------------------------------------
# Display usage information
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Setup helper for OraDBA post-installation configuration tasks.

COMMANDS:
  link-oratab       Create symlink from /etc/oratab to OraDBA temp oratab
  check             Validate OraDBA installation
  show-config       Display current OraDBA configuration
  help              Display this help message

OPTIONS:
  -f, --force       Force operation (for link-oratab: overwrite existing)
  -v, --verbose     Verbose output
  -h, --help        Display this help message

EXAMPLES:
  # Link system oratab after Oracle installation
  $(basename "$0") link-oratab

  # Force recreate symlink
  $(basename "$0") link-oratab --force

  # Check installation health
  $(basename "$0") check

  # Show configuration
  $(basename "$0") show-config

DESCRIPTION:
  This utility helps with post-installation setup tasks, particularly
  for environments where OraDBA was installed before Oracle Database.

  The 'link-oratab' command is most useful after installing Oracle on
  a system where OraDBA was already installed. It removes the temporary
  oratab and creates a symlink to the system oratab.

EOF
}

# ------------------------------------------------------------------------------
# Link oratab: Replace temp oratab with symlink to system oratab
# ------------------------------------------------------------------------------
cmd_link_oratab() {
    local force_mode="${1:-false}"
    local temp_oratab="${ORADBA_BASE}/etc/oratab"
    local system_oratab="/etc/oratab"

    oradba_log INFO "Linking system oratab..."

    # Check if system oratab exists
    if [[ ! -f "$system_oratab" ]]; then
        oradba_log ERROR "System oratab not found: $system_oratab"
        oradba_log INFO "Oracle may not be installed yet"
        return 1
    fi

    # Check if temp oratab location exists
    if [[ ! -e "$temp_oratab" ]]; then
        oradba_log WARN "No oratab found at: $temp_oratab"
        oradba_log INFO "Creating symlink..."
        if ln -sf "$system_oratab" "$temp_oratab"; then
            oradba_log INFO "✓ Symlink created: $temp_oratab -> $system_oratab"
            return 0
        else
            oradba_log ERROR "Failed to create symlink"
            return 1
        fi
    fi

    # Check if it's already a symlink to the correct location
    if [[ -L "$temp_oratab" ]]; then
        local link_target
        link_target=$(readlink "$temp_oratab")
        if [[ "$link_target" == "$system_oratab" ]]; then
            oradba_log INFO "✓ Symlink already exists and is correct"
            oradba_log INFO "  $temp_oratab -> $system_oratab"
            return 0
        else
            oradba_log WARN "Existing symlink points to: $link_target"
            if [[ "$force_mode" == "true" ]]; then
                oradba_log INFO "Force mode: Recreating symlink..."
                rm -f "$temp_oratab"
                if ln -sf "$system_oratab" "$temp_oratab"; then
                    oradba_log INFO "✓ Symlink recreated: $temp_oratab -> $system_oratab"
                    return 0
                else
                    oradba_log ERROR "Failed to recreate symlink"
                    return 1
                fi
            else
                oradba_log ERROR "Use --force to overwrite existing symlink"
                return 1
            fi
        fi
    fi

    # It's a regular file (temp oratab)
    if [[ -f "$temp_oratab" ]]; then
        oradba_log INFO "Found temporary oratab file"

        # Backup temp oratab
        local backup_file
        backup_file="${temp_oratab}.backup.$(date +%Y%m%d_%H%M%S)"
        oradba_log INFO "Creating backup: $backup_file"
        if ! cp "$temp_oratab" "$backup_file"; then
            oradba_log ERROR "Failed to create backup"
            return 1
        fi

        # Check if temp oratab has custom entries
        if grep -qv "^#" "$temp_oratab" 2> /dev/null; then
            oradba_log WARN "Temporary oratab contains database entries:"
            grep -v "^#" "$temp_oratab" | grep -v "^[[:space:]]*$" | while read -r line; do
                oradba_log WARN "  $line"
            done
            oradba_log INFO "These entries are backed up in: $backup_file"
            oradba_log INFO "You may need to manually add them to $system_oratab"
        fi

        # Remove temp oratab and create symlink
        if [[ "$force_mode" == "true" ]] || [[ ! -s "$temp_oratab" ]] || grep -q "^dummy:" "$temp_oratab"; then
            rm -f "$temp_oratab"
            if ln -sf "$system_oratab" "$temp_oratab"; then
                oradba_log INFO "✓ Temporary oratab replaced with symlink"
                oradba_log INFO "  $temp_oratab -> $system_oratab"
                oradba_log INFO "  Backup saved: $backup_file"
                return 0
            else
                oradba_log ERROR "Failed to create symlink"
                oradba_log INFO "Restoring from backup..."
                cp "$backup_file" "$temp_oratab"
                return 1
            fi
        else
            oradba_log ERROR "Temporary oratab contains data. Use --force to replace"
            oradba_log INFO "Or manually merge entries into $system_oratab first"
            return 1
        fi
    fi

    oradba_log ERROR "Unexpected state for: $temp_oratab"
    return 1
}

# ------------------------------------------------------------------------------
# Check OraDBA installation health
# ------------------------------------------------------------------------------
cmd_check() {
    local exit_code=0

    echo ""
    echo "==================================================================="
    echo "OraDBA Installation Check"
    echo "==================================================================="
    echo ""

    # Check ORADBA_BASE
    echo "Installation Location:"
    if [[ -d "$ORADBA_BASE" ]]; then
        echo "  ✓ ORADBA_BASE: $ORADBA_BASE"
    else
        echo "  ✗ ORADBA_BASE not found: $ORADBA_BASE"
        exit_code=1
    fi
    echo ""

    # Check core directories
    echo "Core Directories:"
    for dir in bin lib etc sql templates; do
        if [[ -d "${ORADBA_BASE}/${dir}" ]]; then
            echo "  ✓ ${dir}/"
        else
            echo "  ✗ ${dir}/ (missing)"
            exit_code=1
        fi
    done
    echo ""

    # Check key scripts
    echo "Key Scripts:"
    for script in oradba_install.sh oraenv.sh oraup.sh oradba_extension.sh; do
        if [[ -f "${ORADBA_BASE}/bin/${script}" ]] && [[ -x "${ORADBA_BASE}/bin/${script}" ]]; then
            echo "  ✓ ${script}"
        else
            echo "  ✗ ${script} (missing or not executable)"
            exit_code=1
        fi
    done
    echo ""

    # Check oratab
    echo "oratab Configuration:"
    local oratab_path
    oratab_path=$(get_oratab_path)
    if [[ -f "$oratab_path" ]]; then
        echo "  ✓ oratab found: $oratab_path"
        if [[ -L "$oratab_path" ]]; then
            local link_target
            link_target=$(readlink "$oratab_path")
            echo "    (symlink to: $link_target)"
        fi

        # Count database entries
        local db_count
        db_count=$(grep -v "^#" "$oratab_path" | grep -v "^[[:space:]]*$" | grep -vc "^dummy:")
        if [[ $db_count -gt 0 ]]; then
            echo "  ✓ Database entries: $db_count"
        else
            echo "  ⚠ No database entries found (pre-Oracle installation?)"
        fi
    else
        echo "  ✗ oratab not found: $oratab_path"
        exit_code=1
    fi
    echo ""

    # Check Oracle environment
    echo "Oracle Environment:"
    if [[ -n "${ORACLE_HOME:-}" ]]; then
        echo "  ✓ ORACLE_HOME: $ORACLE_HOME"
    else
        echo "  ⚠ ORACLE_HOME not set"
    fi

    if [[ -n "${ORACLE_BASE:-}" ]]; then
        echo "  ✓ ORACLE_BASE: $ORACLE_BASE"
    else
        echo "  ⚠ ORACLE_BASE not set"
    fi

    if [[ -n "${ORACLE_SID:-}" ]]; then
        echo "  ✓ ORACLE_SID: $ORACLE_SID"
    else
        echo "  ⚠ ORACLE_SID not set"
    fi
    echo ""

    # Check extensions
    if [[ -d "${ORADBA_BASE}/extensions" ]]; then
        echo "Extensions:"
        local ext_count
        ext_count=$(find "${ORADBA_BASE}/extensions" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | wc -l | tr -d ' ')
        if [[ $ext_count -gt 0 ]]; then
            echo "  ✓ Installed extensions: $ext_count"
            find "${ORADBA_BASE}/extensions" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | while read -r ext; do
                if [[ -f "${ORADBA_BASE}/extensions/${ext}/.extension" ]]; then
                    local enabled
                    enabled=$(grep -q "^enabled=true" "${ORADBA_BASE}/extensions/${ext}/.extension" 2> /dev/null && echo "enabled" || echo "disabled")
                    echo "    - ${ext} (${enabled})"
                fi
            done
        else
            echo "  ℹ No extensions installed"
        fi
        echo ""
    fi

    # Summary
    echo "==================================================================="
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ Installation check passed"
    else
        echo "✗ Installation check found issues"
    fi
    echo "==================================================================="
    echo ""

    return $exit_code
}

# ------------------------------------------------------------------------------
# Show OraDBA configuration
# ------------------------------------------------------------------------------
cmd_show_config() {
    echo ""
    echo "==================================================================="
    echo "OraDBA Configuration"
    echo "==================================================================="
    echo ""

    echo "Installation:"
    echo "  ORADBA_BASE:       ${ORADBA_BASE}"
    echo "  ORADBA_PREFIX:     ${ORADBA_PREFIX:-$ORADBA_BASE}"
    echo "  Version:           $(cat "${ORADBA_BASE}/VERSION" 2> /dev/null || echo "unknown")"
    echo ""

    echo "Configuration Files:"
    echo "  Core config:       ${ORADBA_BASE}/etc/oradba_core.conf"
    echo "  Local config:      ${ORADBA_BASE}/etc/oradba_local.conf"
    [[ -n "${ORACLE_SID:-}" ]] && echo "  SID config:        ${ORADBA_BASE}/etc/sid.${ORACLE_SID}.conf"
    echo ""

    echo "oratab:"
    local oratab_path
    oratab_path=$(get_oratab_path)
    echo "  Path:              $oratab_path"
    if [[ -L "$oratab_path" ]]; then
        echo "  Type:              symlink"
        echo "  Target:            $(readlink "$oratab_path")"
    elif [[ -f "$oratab_path" ]]; then
        echo "  Type:              file"
    else
        echo "  Type:              not found"
    fi

    # Priority override
    [[ -n "${ORADBA_ORATAB:-}" ]] && echo "  Override:          $ORADBA_ORATAB"
    echo ""

    echo "Oracle Environment:"
    echo "  ORACLE_BASE:       ${ORACLE_BASE:-<not set>}"
    echo "  ORACLE_HOME:       ${ORACLE_HOME:-<not set>}"
    echo "  ORACLE_SID:        ${ORACLE_SID:-<not set>}"
    echo "  TNS_ADMIN:         ${TNS_ADMIN:-<not set>}"
    echo ""

    echo "Extensions:"
    echo "  Auto-discover:     ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-false}"
    if [[ -d "${ORADBA_BASE}/extensions" ]]; then
        local ext_count
        ext_count=$(find "${ORADBA_BASE}/extensions" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | wc -l | tr -d ' ')
        echo "  Installed:         $ext_count"
    fi
    echo ""

    echo "Logging:"
    echo "  Log level:         ${ORADBA_LOG_LEVEL:-INFO}"
    echo "  Log directory:     ${ORADBA_LOG_DIR:-<not set>}"
    echo ""

    echo "==================================================================="
    echo ""
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local command=""
    local force_mode=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            link-oratab | check | show-config | help)
                command="$1"
                shift
                ;;
            -f | --force)
                force_mode=true
                shift
                ;;
            -v | --verbose)
                export ORADBA_LOG_LEVEL="DEBUG"
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                oradba_log ERROR "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Default to help if no command
    if [[ -z "$command" ]]; then
        usage
        exit 0
    fi

    # Execute command
    case "$command" in
        link-oratab)
            cmd_link_oratab "$force_mode"
            ;;
        check)
            cmd_check
            ;;
        show-config)
            cmd_show_config
            ;;
        help)
            usage
            exit 0
            ;;
        *)
            oradba_log ERROR "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
