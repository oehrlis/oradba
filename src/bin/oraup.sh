#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oraup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.6.1
# Purpose....: Display comprehensive Oracle environment status overview
# Notes......: Shows all Oracle databases, listeners, and processes on the system
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="${ORADBA_BASE:-$(dirname "$SCRIPT_DIR")}"

# Source common library if available
if [[ -f "${ORADBA_BASE}/lib/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "${ORADBA_BASE}/lib/common.sh"
fi

# Get oratab file path using centralized function
if type get_oratab_path &> /dev/null; then
    ORATAB_FILE=$(get_oratab_path)
else
    # Fallback if common.sh not sourced
    ORATAB_FILE="${ORATAB_FILE:-/etc/oratab}"
    if [[ ! -f "$ORATAB_FILE" ]]; then
        for alt_oratab in "/var/opt/oracle/oratab" "${ORADBA_BASE}/etc/oratab" "${HOME}/.oratab"; do
            if [[ -f "$alt_oratab" ]]; then
                ORATAB_FILE="$alt_oratab"
                break
            fi
        done
    fi
fi

# ------------------------------------------------------------------------------
# Function: show_usage
# Purpose.: Display usage information
# ------------------------------------------------------------------------------
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Display comprehensive Oracle environment status overview.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Show verbose output
    -q, --quiet     Minimal output (errors only)

DESCRIPTION:
    Shows all Oracle environments on the system:
    - Oracle Homes (OUD, WebLogic, Client, OMS, etc.)
    - Database instances (from oratab)
    - Running Oracle processes (pmon, listener)
    - Instance status (open/mounted/started/nomount)
    - Listener status
    - Oracle Home locations
    - Startup flags and modes
    
    Supports Oracle 11g through 23ai (both ora_pmon_* and db_pmon_* naming)

EXAMPLES:
    $(basename "$0")                # Show full status
    $(basename "$0") --verbose      # Show detailed information
    $(basename "$0") --quiet        # Minimal output

EOF
}

# ------------------------------------------------------------------------------
# Function: get_db_status
# Purpose.: Get database instance status by checking pmon process
# Returns.: "up" or "down"
# ------------------------------------------------------------------------------
get_db_status() {
    local sid="$1"
    local sid_lower="${sid,,}"

    # Check for both naming conventions:
    # - Oracle 23ai+: db_pmon_<SID> (uppercase)
    # - Oracle <23ai: ora_pmon_<sid> (lowercase)
    if ps -ef | grep -v grep | grep -E "(db_pmon_${sid}|ora_pmon_${sid_lower})" > /dev/null 2>&1; then
        echo "up"
    else
        echo "down"
    fi
}

# ------------------------------------------------------------------------------
# Function: get_db_mode
# Purpose.: Get database open mode (OPEN, MOUNTED, etc.)
# Returns.: Open mode or "n/a"
# ------------------------------------------------------------------------------
get_db_mode() {
    local sid="$1"
    local oracle_home="$2"

    # Check if instance is running
    if [[ "$(get_db_status "$sid")" != "up" ]]; then
        echo "n/a"
        return
    fi

    # Try to get open mode via SQL*Plus
    local mode
    mode=$(
        ORACLE_HOME="$oracle_home" ORACLE_SID="$sid" "$oracle_home/bin/sqlplus" -S / as sysdba 2> /dev/null << EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE
SELECT status FROM v\$instance;
EXIT;
EOF
    )

    # Clean up output
    mode=$(echo "$mode" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if we got a valid result
    if [[ -n "$mode" ]] && [[ "$mode" != "ERROR"* ]] && [[ "$mode" != "ORA-"* ]] && [[ "$mode" != "SP2-"* ]]; then
        echo "$mode" | tr '[:upper:]' '[:lower:]'
    else
        # If v$instance query failed, try v$database for open_mode
        mode=$(
            ORACLE_HOME="$oracle_home" ORACLE_SID="$sid" "$oracle_home/bin/sqlplus" -S / as sysdba 2> /dev/null << EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT open_mode FROM v\$database;
EXIT;
EOF
        )
        mode=$(echo "$mode" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [[ -n "$mode" ]] && [[ "$mode" != "ERROR"* ]] && [[ "$mode" != "ORA-"* ]] && [[ "$mode" != "SP2-"* ]]; then
            echo "$mode" | tr '[:upper:]' '[:lower:]'
        else
            echo "started"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: get_listener_status
# Purpose.: Get listener status
# Returns.: "up" or "down"
# ------------------------------------------------------------------------------
get_listener_status() {
    local listener_name="${1:-LISTENER}"
    local oracle_home="$2"

    # Check if listener process is running
    if ps -ef | grep -v grep | grep "tnslsnr ${listener_name}" > /dev/null 2>&1; then
        echo "up"
    else
        echo "down"
    fi
}

# ------------------------------------------------------------------------------
# Function: get_startup_flag
# Purpose.: Get startup flag from oratab (Y/N/D)
# Returns.: Startup flag
# ------------------------------------------------------------------------------
get_startup_flag() {
    local sid="$1"
    local flag
    flag=$(grep "^${sid}:" "$ORATAB_FILE" 2> /dev/null | cut -d: -f3)
    echo "${flag:-N}"
}

# ------------------------------------------------------------------------------
# Function: show_oracle_status
# Purpose.: Display comprehensive Oracle status overview
# ------------------------------------------------------------------------------
show_oracle_status() {
    local verbose="${1:-false}"

    # Header
    echo ""
    echo "Oracle Environment Status"
    printf "%-17s : %-12s %-11s %s\n" "TYPE (Cluster|DG)" "SID/PROCESS" "STATUS" "HOME"
    echo "---------------------------------------------------------------------------------"

    # Check if oratab exists
    if [[ ! -f "$ORATAB_FILE" ]]; then
        echo ""
        echo "  ⚠ No oratab file found at $ORATAB_FILE"
        echo ""
        echo "  This appears to be a pre-Oracle installation."
        echo "  OraDBA is installed but Oracle Database is not yet present."
        echo ""
        echo "  After installing Oracle:"
        echo "    1. Use 'oradba_setup.sh link-oratab' to link system oratab"
        echo "    2. Or create entries in: ${ORADBA_BASE}/etc/oratab"
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo ""
        return 0
    fi

    # Check if oratab has any entries
    local entry_count
    entry_count=$(grep -cv "^#\|^[[:space:]]*$" "$ORATAB_FILE")

    if [[ "$entry_count" -eq 0 ]]; then
        echo ""
        echo "  ℹ No database entries found in oratab"
        echo ""
        echo "  The oratab file exists but contains no database entries."
        echo "  Add Oracle instances to: $ORATAB_FILE"
        echo ""
        echo "---------------------------------------------------------------------------------"
        echo ""
        return 0
    fi

    # Collect all entries first for sorting
    local -a dummy_entries
    local -a db_entries

    while IFS=: read -r sid oracle_home startup_flag _rest; do
        # Skip comments and empty lines
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$sid" ]] && continue

        # Collect entries based on type
        if [[ "$startup_flag" == "D" ]]; then
            dummy_entries+=("$sid:$oracle_home:$startup_flag")
        else
            db_entries+=("$sid:$oracle_home:$startup_flag")
        fi
    done < "$ORATAB_FILE"

    # Sort both arrays alphabetically by SID
    mapfile -t dummy_entries < <(printf '%s\n' "${dummy_entries[@]}" | sort)
    mapfile -t db_entries < <(printf '%s\n' "${db_entries[@]}" | sort)

    # Display Oracle Homes first (if available)
    if command -v list_oracle_homes &> /dev/null; then
        local -a homes
        mapfile -t homes < <(list_oracle_homes)

        if [[ ${#homes[@]} -gt 0 ]]; then
            echo ""
            echo "Oracle Homes"
            echo "---------------------------------------------------------------------------------"

            for home_line in "${homes[@]}"; do
                # Parse: NAME ORACLE_HOME PRODUCT_TYPE ORDER DESCRIPTION
                read -r name path ptype _order _desc <<< "$home_line"

                # Format product type for display
                local ptype_display
                case "$ptype" in
                    database) ptype_display="Database" ;;
                    oud) ptype_display="OUD" ;;
                    client) ptype_display="Client" ;;
                    weblogic) ptype_display="WebLogic" ;;
                    oms) ptype_display="OMS" ;;
                    emagent) ptype_display="EM Agent" ;;
                    datasafe) ptype_display="Data Safe" ;;
                    *) ptype_display="$ptype" ;;
                esac

                # Check if directory exists
                local status
                if [[ -d "$path" ]]; then
                    status="available"
                else
                    status="missing"
                fi

                printf "%-17s : %-12s %-11s %s\n" "$ptype_display" "$name" "$status" "$path"
            done

            echo ""
        fi
    fi

    # Process dummy entries first
    for entry in "${dummy_entries[@]}"; do
        IFS=: read -r sid oracle_home startup_flag <<< "$entry"
        printf "%-17s : %-12s %-11s %s\n" "Dummy rdbms" "$sid" "n/a" "$oracle_home"
    done

    # Process DB instances
    for entry in "${db_entries[@]}"; do
        IFS=: read -r sid oracle_home startup_flag <<< "$entry"

        # Get status
        local status
        status=$(get_db_status "$sid")

        # Get open mode if instance is up
        if [[ "$status" == "up" ]]; then
            local mode
            mode=$(get_db_mode "$sid" "$oracle_home")
            status="$mode"
        fi

        # Display with startup flag
        printf "%-17s : %-12s %-11s %s\n" "DB-instance (${startup_flag})" "$sid" "$status" "$oracle_home"
    done

    echo ""

    # Check for listeners
    echo "Listener Status"
    echo "---------------------------------------------------------------------------------"

    # Find unique Oracle homes
    local -a oracle_homes
    while IFS=: read -r sid oracle_home startup_flag _rest; do
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$sid" ]] && continue
        [[ -d "$oracle_home" ]] && oracle_homes+=("$oracle_home")
    done < "$ORATAB_FILE"

    # Remove duplicates
    local -a unique_homes
    mapfile -t unique_homes < <(printf '%s\n' "${oracle_homes[@]}" | sort -u)
    oracle_homes=("${unique_homes[@]}")

    # Check for listeners in each Oracle home
    local found_listener=false
    for oh in "${oracle_homes[@]}"; do
        # Check common listener names
        for listener in LISTENER LISTENER_${HOSTNAME%%.*}; do
            local lstatus
            lstatus=$(get_listener_status "$listener" "$oh")

            # Only show listeners that are actually running
            if [[ "$lstatus" == "up" ]]; then
                printf "%-17s : %-12s %-11s %s\n" "Listener" "$listener" "$lstatus" "$oh"
                found_listener=true
            fi
        done
    done

    if [[ "$found_listener" == "false" ]]; then
        # Check for any running listeners
        if ps -ef | grep -v grep | grep "tnslsnr" > /dev/null 2>&1; then
            printf "%-17s : %-12s %-11s %s\n" "Listener" "LISTENER" "up" "(running)"
        else
            printf "%-17s : %-12s %-11s %s\n" "Listener" "LISTENER" "down" "n/a"
        fi
    fi

    echo ""
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local verbose=false
    local quiet=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_usage
                exit 0
                ;;
            -v | --verbose)
                verbose=true
                shift
                ;;
            -q | --quiet)
                quiet=true
                shift
                ;;
            *)
                echo "Error: Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Show status
    if [[ "$quiet" == "false" ]]; then
        show_oracle_status "$verbose"
    fi
}

# Run main function
main "$@"
