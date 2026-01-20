#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oraup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Display comprehensive Oracle environment status overview
# Notes......: Shows all Oracle databases, listeners, and processes on the system
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="${ORADBA_BASE:-$(dirname "$SCRIPT_DIR")}"

# Source common library if available
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${ORADBA_BASE}/lib/oradba_common.sh"
fi

# Source status library if available
if [[ -f "${ORADBA_BASE}/lib/oradba_env_status.sh" ]]; then
    # shellcheck source=../lib/oradba_env_status.sh
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
fi

# Source registry API if available (Phase 1 - Bug #85 fix)
if [[ -f "${ORADBA_BASE}/lib/oradba_registry.sh" ]]; then
    # shellcheck source=../lib/oradba_registry.sh
    source "${ORADBA_BASE}/lib/oradba_registry.sh"
fi

# Load plugins if available
if [[ -d "${ORADBA_BASE}/lib/plugins" ]]; then
    for plugin in "${ORADBA_BASE}/lib/plugins/"*.sh; do
        # shellcheck source=/dev/null
        [[ -f "$plugin" ]] && [[ "$plugin" != */plugin_interface.sh ]] && source "$plugin"
    done
fi

# Get oratab file path using centralized function
if type get_oratab_path &> /dev/null; then
    ORATAB_FILE=$(get_oratab_path)
else
    # Fallback if oradba_common.sh not sourced
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
# Function: show_oracle_status_registry
# Purpose.: Display Oracle status using registry API (Phase 1)
# Args....: Array of installation objects from registry
# Notes...: Uses plugin system for product-specific behavior
# ------------------------------------------------------------------------------
show_oracle_status_registry() {
    local -a installations=("$@")
    
    # Separate by type
    local -a databases=()
    local -a datasafe_homes=()
    local -a other_homes=()
    
    for install in "${installations[@]}"; do
        local ptype
        ptype=$(oradba_registry_get_field "$install" "type")
        
        if [[ "$ptype" == "database" ]]; then
            databases+=("$install")
        elif [[ "$ptype" == "datasafe" ]]; then
            datasafe_homes+=("$install")
        else
            other_homes+=("$install")
        fi
    done
    
    # =========================================================================
    # SECTION 1: Oracle Homes (unique database and other homes, not datasafe)
    # =========================================================================
    # Build unique homes list: prefer dummy entries, then first SID for each path
    declare -A seen_homes
    local -a unique_homes=()
    
    # First pass: Add dummy entries (flag 'D')
    for db_obj in "${databases[@]}"; do
        local home flags
        home=$(oradba_registry_get_field "$db_obj" "home")
        flags=$(oradba_registry_get_field "$db_obj" "flags")
        
        if [[ "$flags" == "D" ]] && [[ -z "${seen_homes[$home]}" ]]; then
            unique_homes+=("$db_obj")
            seen_homes[$home]="1"
        fi
    done
    
    # Second pass: Add first SID for paths without dummy
    for db_obj in "${databases[@]}"; do
        local home flags
        home=$(oradba_registry_get_field "$db_obj" "home")
        flags=$(oradba_registry_get_field "$db_obj" "flags")
        
        if [[ "$flags" != "D" ]] && [[ -z "${seen_homes[$home]}" ]]; then
            unique_homes+=("$db_obj")
            seen_homes[$home]="1"
        fi
    done
    
    # Add other (non-database, non-datasafe) homes
    for home_obj in "${other_homes[@]}"; do
        unique_homes+=("$home_obj")
    done
    
    if [[ ${#unique_homes[@]} -gt 0 ]]; then
        echo ""
        echo "Oracle Homes"
        echo "---------------------------------------------------------------------------------"
        printf "%-20s %-15s %-12s %s\n" "NAME" "TYPE" "STATUS" "PATH"
        echo "---------------------------------------------------------------------------------"
        
        for home_obj in "${unique_homes[@]}"; do
            local name home ptype status
            name=$(oradba_registry_get_field "$home_obj" "name")
            home=$(oradba_registry_get_field "$home_obj" "home")
            ptype=$(oradba_registry_get_field "$home_obj" "type")
            
            # Check if directory exists
            if [[ ! -d "$home" ]]; then
                status="missing"
            elif [[ -z "$(ls -A "$home" 2>/dev/null)" ]]; then
                status="empty"
            else
                status="available"
            fi
            
            printf "%-20s %-15s %-12s %s\n" "$name" "$ptype" "$status" "$home"
        done
    fi
    
    # =========================================================================
    # SECTION 2: Database Instances (only real SIDs, not dummies)
    # =========================================================================
    if [[ ${#databases[@]} -gt 0 ]]; then
        echo ""
        echo "Database Instances"
        echo "---------------------------------------------------------------------------------"
        printf "%-20s %-8s %-12s %s\n" "SID" "FLAG" "STATUS" "ORACLE_HOME"
        echo "---------------------------------------------------------------------------------"
        
        for db_obj in "${databases[@]}"; do
            local sid home flags
            sid=$(oradba_registry_get_field "$db_obj" "name")
            home=$(oradba_registry_get_field "$db_obj" "home")
            flags=$(oradba_registry_get_field "$db_obj" "flags")
            
            # Skip dummy entries - they're not real SIDs
            [[ "$flags" == "D" ]] && continue
            
            # Get status
            local status
            status=$(get_db_status "$sid")
            
            # Get open mode if instance is up
            if [[ "$status" == "up" ]]; then
                local mode
                mode=$(get_db_mode "$sid" "$home")
                status="$mode"
            fi
            
            printf "%-20s %-8s %-12s %s\n" "$sid" "$flags" "$status" "$home"
        done
    fi
    
    # =========================================================================
    # SECTION 3: Listener Status
    # =========================================================================
    if [[ ${#databases[@]} -gt 0 ]]; then
        echo ""
        echo "Listener Status"
        echo "---------------------------------------------------------------------------------"
        printf "%-20s %-12s %-15s %s\n" "NAME" "STATUS" "PORT" "ORACLE_HOME"
        echo "---------------------------------------------------------------------------------"
        
        # Check for running listeners
        local listener_count=0
        while read -r listener_line; do
            local listener_name listener_home
            # Extract listener name (second-to-last field before -inherit flag)
            listener_name=$(echo "$listener_line" | awk '{print $(NF-1)}')
            
            # Extract Oracle Home from ps output (full path to tnslsnr binary)
            # ps output format: /path/to/oracle_home/bin/tnslsnr LISTENER -inherit
            listener_home=$(echo "$listener_line" | awk '{for(i=1;i<=NF;i++) if($i ~ /tnslsnr$/) print $i}' | sed 's|/bin/tnslsnr$||')
            
            # Get detailed listener status, port, and protocol
            local lsnr_status="down"
            local lsnr_port=""
            local lsnr_protocol=""
            
            if command -v lsnrctl &>/dev/null; then
                local lsnr_output
                lsnr_output=$(lsnrctl status "$listener_name" 2>/dev/null)
                
                if echo "$lsnr_output" | grep -qi "STATUS of the LISTENER"; then
                    lsnr_status="up"
                    
                    # Extract port and protocol from Listening Endpoints
                    # Look for both TCP and TCPS protocols
                    local endpoints
                    endpoints=$(echo "$lsnr_output" | grep -A 20 "Listening Endpoints Summary" | grep "PROTOCOL=")
                    
                    if [[ -n "$endpoints" ]]; then
                        # Extract first TCP or TCPS port
                        lsnr_protocol=$(echo "$endpoints" | grep -o "PROTOCOL=[^)]*" | head -1 | cut -d= -f2)
                        lsnr_port=$(echo "$endpoints" | grep -o "PORT=[0-9]*" | head -1 | cut -d= -f2)
                    fi
                fi
            fi
            
            # Format port display
            local port_display=""
            if [[ -n "$lsnr_port" ]]; then
                port_display="${lsnr_protocol}:${lsnr_port}"
            fi
            
            # Use full path for listener home (not [SID] notation)
            printf "%-20s %-12s %-15s %s\n" "$listener_name" "$lsnr_status" "$port_display" "$listener_home"
            ((listener_count++))
        done < <(ps -ef | grep "[t]nslsnr" | grep -v "datasafe\|oracle_cman_home")
        
        if [[ $listener_count -eq 0 ]]; then
            echo "  No database listeners running"
        fi
    fi
    
    # =========================================================================
    # SECTION 4: Data Safe Connectors
    # =========================================================================
    if [[ ${#datasafe_homes[@]} -gt 0 ]]; then
        echo ""
        echo "Data Safe Connectors"
        echo "---------------------------------------------------------------------------------"
        printf "%-20s %-12s %s\n" "NAME" "STATUS" "PATH"
        echo "---------------------------------------------------------------------------------"
        
        for ds_obj in "${datasafe_homes[@]}"; do
            local name home status
            name=$(oradba_registry_get_field "$ds_obj" "name")
            home=$(oradba_registry_get_field "$ds_obj" "home")
            
            # Check if directory exists first
            if [[ ! -d "$home" ]]; then
                status="missing"
            elif [[ -z "$(ls -A "$home" 2>/dev/null)" ]]; then
                status="empty"
            else
                # Use DataSafe plugin to check status
                if type -t plugin_check_status &>/dev/null; then
                    status=$(plugin_check_status "$home")
                else
                    status="available"
                fi
            fi
            
            printf "%-20s %-12s %s\n" "$name" "$status" "$home"
        done
    fi
    
    echo ""
    echo "================================================================================="
    echo ""
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
    echo "================================================================================="

    # Use registry API if available (Phase 1 - Bug #85 fix)
    if type -t oradba_registry_get_all &>/dev/null; then
        # Get all installations from unified registry
        local -a all_installations
        mapfile -t all_installations < <(oradba_registry_get_all)
        
        if [[ ${#all_installations[@]} -eq 0 ]]; then
            echo ""
            echo "  ℹ No Oracle installations found"
            echo ""
            echo "  No entries found in oratab or oradba_homes.conf."
            echo "  OraDBA is installed but Oracle products are not registered."
            echo ""
            echo "  After installing Oracle:"
            echo "    1. Database: Add to oratab (/etc/oratab or ${ORADBA_BASE}/etc/oratab)"
            echo "    2. Other products: Add to ${ORADBA_BASE}/etc/oradba_homes.conf"
            echo "    3. Or enable auto-discovery: ORADBA_AUTO_DISCOVER=true"
            echo ""
            echo "---------------------------------------------------------------------------------"
            echo ""
            return 0
        fi
        
        # Process installations using registry
        show_oracle_status_registry "${all_installations[@]}"
        return 0
    fi

    # Note: This code path is only reached if registry API loading failed,
    # which should not happen in normal operation. Registry is always available.
    echo ""
    echo "  ⚠ Registry API not available (unexpected error)"
    echo ""
    echo "  Please check OraDBA installation integrity."
    echo ""
    return 1
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Main entry point for Oracle status display utility
# Args....: [OPTIONS] - Command-line flags (-h|--help, -v|--verbose, -q|--quiet)
# Returns.: 0 on success, 1 on error
# Output..: Oracle status information to stdout (unless --quiet)
# Notes...: Quick status display for current Oracle environment
#           Shows databases, listeners, and Oracle Homes status
#           Part of oraenv/oraup quick environment switching workflow
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
