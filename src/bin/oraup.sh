#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oraup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.5.1
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

# Default oratab location
ORATAB_FILE="${ORATAB_FILE:-/etc/oratab}"

# Check for alternative oratab locations
if [[ ! -f "$ORATAB_FILE" ]]; then
    for alt_oratab in "/var/opt/oracle/oratab" "${HOME}/.oratab"; do
        if [[ -f "$alt_oratab" ]]; then
            ORATAB_FILE="$alt_oratab"
            break
        fi
    done
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
    Shows all Oracle databases, listeners, and processes on the system:
    - Database instances (from oratab)
    - Running Oracle processes (pmon, listener)
    - Listener status
    - Oracle Home locations
    - Startup flags and modes

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
    if ps -ef | grep -v grep | grep "ora_pmon_${sid}" > /dev/null 2>&1; then
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
    mode=$(ORACLE_HOME="$oracle_home" ORACLE_SID="$sid" "$oracle_home/bin/sqlplus" -S / as sysdba 2>/dev/null <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT open_mode FROM v\$database;
EXIT;
EOF
)
    
    # Clean up output
    mode=$(echo "$mode" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ -n "$mode" ]] && [[ "$mode" != "ERROR"* ]] && [[ "$mode" != "ORA-"* ]]; then
        echo "$mode" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
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
    flag=$(grep "^${sid}:" "$ORATAB_FILE" 2>/dev/null | cut -d: -f3)
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
    echo "Oracle Environment Status Overview"
    echo "============================================================================="
    printf "%-18s : %-15s %-11s %s\n" "TYPE (Cluster|DG)" "SID/PROCESS" "STATUS" "HOME"
    echo "-----------------------------------------------------------------------------"
    
    # Check if oratab exists
    if [[ ! -f "$ORATAB_FILE" ]]; then
        echo "Warning: oratab file not found at $ORATAB_FILE"
        echo "============================================================================="
        return 1
    fi
    
    # Process oratab entries
    while IFS=: read -r sid oracle_home startup_flag _rest; do
        # Skip comments and empty lines
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$sid" ]] && continue
        
        # Determine type
        local db_type="DB-instance"
        local display_flag="$startup_flag"
        
        if [[ "$startup_flag" == "D" ]]; then
            db_type="Dummy rdbms"
            display_flag="n/a"
        fi
        
        # Get status
        local status
        if [[ "$startup_flag" == "D" ]]; then
            status="n/a"
        else
            status=$(get_db_status "$sid")
            
            # Get open mode if instance is up
            if [[ "$status" == "up" ]]; then
                local mode
                mode=$(get_db_mode "$sid" "$oracle_home")
                status="$mode"
            fi
        fi
        
        # Display startup flags for DB instances
        local type_display="$db_type"
        if [[ "$db_type" == "DB-instance" ]]; then
            type_display="${db_type} (${startup_flag}|${display_flag})"
        fi
        
        printf "%-18s : %-15s %-11s %s\n" "$type_display" "$sid" "$status" "$oracle_home"
        
    done < "$ORATAB_FILE"
    
    echo ""
    
    # Check for listeners
    echo "Listener Status"
    echo "-----------------------------------------------------------------------------"
    
    # Find unique Oracle homes
    local -a oracle_homes
    while IFS=: read -r sid oracle_home startup_flag _rest; do
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$sid" ]] && continue
        [[ -d "$oracle_home" ]] && oracle_homes+=("$oracle_home")
    done < "$ORATAB_FILE"
    
    # Remove duplicates
    oracle_homes=($(printf '%s\n' "${oracle_homes[@]}" | sort -u))
    
    # Check for listeners in each Oracle home
    local found_listener=false
    for oh in "${oracle_homes[@]}"; do
        # Check common listener names
        for listener in LISTENER LISTENER_${HOSTNAME%%.*}; do
            local lstatus
            lstatus=$(get_listener_status "$listener" "$oh")
            
            if [[ "$lstatus" == "up" ]] || ps -ef | grep -v grep | grep "tnslsnr" | grep -q "$oh"; then
                printf "%-18s : %-15s %-11s %s\n" "Listener" "$listener" "$lstatus" "$oh"
                found_listener=true
            fi
        done
    done
    
    if [[ "$found_listener" == "false" ]]; then
        # Check for any running listeners
        if ps -ef | grep -v grep | grep "tnslsnr" > /dev/null 2>&1; then
            local listener_proc
            listener_proc=$(ps -ef | grep -v grep | grep "tnslsnr" | head -1)
            printf "%-18s : %-15s %-11s %s\n" "Listener" "LISTENER" "up" "(running)"
        else
            printf "%-18s : %-15s %-11s %s\n" "Listener" "LISTENER" "down" "n/a"
        fi
    fi
    
    echo "============================================================================="
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
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
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
