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
    oradba_log DEBUG "oraup.sh: Sourced oradba_common.sh from ${ORADBA_BASE}/lib"
fi

# Source status library if available
if [[ -f "${ORADBA_BASE}/lib/oradba_env_status.sh" ]]; then
    # shellcheck source=../lib/oradba_env_status.sh
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
    oradba_log DEBUG "oraup.sh: Sourced oradba_env_status.sh"
fi

# Source registry API if available (Phase 1 - Bug #85 fix)
if [[ -f "${ORADBA_BASE}/lib/oradba_registry.sh" ]]; then
    # shellcheck source=../lib/oradba_registry.sh
    source "${ORADBA_BASE}/lib/oradba_registry.sh"
    oradba_log DEBUG "oraup.sh: Sourced oradba_registry.sh"
fi

# Avoid bulk plugin sourcing to prevent experimental status leakage
oradba_log DEBUG "oraup.sh: Skipping bulk plugin load (using execute_plugin_function_v2)"

# Get oratab file path using centralized function
if type get_oratab_path &> /dev/null; then
    ORATAB_FILE=$(get_oratab_path)
    oradba_log DEBUG "oraup.sh: Using oratab file: ${ORATAB_FILE}"
else
    # Fallback if oradba_common.sh not sourced
    ORATAB_FILE="${ORATAB_FILE:-/etc/oratab}"
    if [[ ! -f "$ORATAB_FILE" ]]; then
        for alt_oratab in "/var/opt/oracle/oratab" "${ORADBA_BASE}/etc/oratab" "${HOME}/.oratab"; do
            if [[ -f "$alt_oratab" ]]; then
                ORATAB_FILE="$alt_oratab"
                oradba_log DEBUG "oraup.sh: Found alternative oratab: ${ORATAB_FILE}"
                break
            fi
        done
    fi
    oradba_log DEBUG "oraup.sh: Using oratab file (fallback): ${ORATAB_FILE}"
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
# Function: get_process_list
# Purpose.: Get cached process list (for batch process detection)
# Returns.: Full process list from ps -ef
# Output..: Process list to stdout
# Notes...: Call once at start, reuse results to avoid repeated ps -ef calls
# ------------------------------------------------------------------------------
get_process_list() {
    ps -ef 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Function: get_db_status
# Purpose.: Get database instance status by checking pmon process
# Args....: $1 - SID name
#           $2 - Optional: cached process list (from get_process_list)
# Returns.: "up" or "down"
# Notes...: If process list is provided, uses it instead of calling ps -ef
# ------------------------------------------------------------------------------
get_db_status() {
    local sid="$1"
    local process_list="${2:-}"
    local sid_lower="${sid,,}"

    # Check for both naming conventions:
    # - Oracle 23ai+: db_pmon_<SID> (uppercase)
    # - Oracle <23ai: ora_pmon_<sid> (lowercase)
    if [[ -n "$process_list" ]]; then
        # Use cached process list
        if echo "$process_list" | grep -v grep | grep -E "(db_pmon_${sid}|ora_pmon_${sid_lower})" > /dev/null 2>&1; then
            echo "up"
        else
            echo "down"
        fi
    else
        # Fall back to calling ps -ef directly
        if ps -ef | grep -v grep | grep -E "(db_pmon_${sid}|ora_pmon_${sid_lower})" > /dev/null 2>&1; then
            echo "up"
        else
            echo "down"
        fi
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
# Purpose.: Get listener status (legacy, kept for backward compatibility)
# Args....: $1 - Listener name (default: LISTENER)
#           $2 - Oracle Home
#           $3 - Optional: cached process list (from get_process_list)
# Returns.: "up" or "down"
# Notes...: Consider using plugin_check_listener_status() for new code
#           If process list is provided, uses it instead of calling ps -ef
# ------------------------------------------------------------------------------
get_listener_status() {
    local listener_name="${1:-LISTENER}"
    local oracle_home="$2"
    local process_list="${3:-}"

    # Check if listener process is running
    if [[ -n "$process_list" ]]; then
        # Use cached process list
        if echo "$process_list" | grep -v grep | grep "tnslsnr ${listener_name}" > /dev/null 2>&1; then
            echo "up"
        else
            echo "down"
        fi
    else
        # Fall back to calling ps -ef directly
        if ps -ef | grep -v grep | grep "tnslsnr ${listener_name}" > /dev/null 2>&1; then
            echo "up"
        else
            echo "down"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: should_show_listener_section
# Purpose.: Check if listener section should be displayed using plugin system
# Args....: $1 - Process list (from get_process_list)
#           $2+ - Array of database homes
# Returns.: 0 if section should be shown, 1 otherwise
# Notes...: Uses plugin_should_show_listener() from database plugin
# ------------------------------------------------------------------------------
should_show_listener_section() {
    local process_list="$1"
    shift
    local -a db_homes=("$@")
    
    # If we have database SIDs, always show (backward compatible)
    if [[ ${#db_homes[@]} -gt 0 ]]; then
        return 0
    fi
    
    # Check for running listeners using cached process list
    if echo "$process_list" | grep "[t]nslsnr" | grep -qv "datasafe\|oracle_cman_home"; then
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: show_oracle_status_registry
# Purpose.: Display Oracle status using registry API (Phase 1)
# Args....: Array of installation objects from registry
# Notes...: Uses plugin system for product-specific behavior
#           Implements batch process detection and parallel status checks
# ------------------------------------------------------------------------------
show_oracle_status_registry() {
    local -a installations=("$@")
    
    oradba_log DEBUG "oraup.sh: show_oracle_status_registry called with ${#installations[@]} installations"
    
    # OPTIMIZATION: Get process list once for batch process detection
    local process_list
    process_list=$(get_process_list)
    oradba_log DEBUG "oraup.sh: Captured process list for batch detection ($(echo "$process_list" | wc -l) lines)"
    
    # Separate by type and source
    local -a database_sids=()      # Real SIDs from oratab (with flags)
    local -a database_homes=()     # Database homes from oracle_homes.conf or dummy entries
    local -a datasafe_homes=()
    local -a other_homes=()
    
    for install in "${installations[@]}"; do
        local ptype flags name
        ptype=$(oradba_registry_get_field "$install" "type")
        flags=$(oradba_registry_get_field "$install" "flags")
        name=$(oradba_registry_get_field "$install" "name")
        
        oradba_log DEBUG "oraup.sh: Processing installation: name=${name}, type=${ptype}, flags=${flags}"
        
        if [[ "$ptype" == "database" ]]; then
            # Distinguish between real SIDs and homes
            if [[ -n "$flags" && "$flags" != "D" ]]; then
                # Real database SID from oratab (has flag Y or N)
                database_sids+=("$install")
                oradba_log DEBUG "oraup.sh: Classified as database SID: ${name}"
            else
                # Database home from oracle_homes.conf (no flags) or dummy entry (flag D)
                database_homes+=("$install")
                oradba_log DEBUG "oraup.sh: Classified as database home: ${name}"
            fi
        elif [[ "$ptype" == "datasafe" ]]; then
            datasafe_homes+=("$install")
            oradba_log DEBUG "oraup.sh: Classified as datasafe: ${name}"
        else
            other_homes+=("$install")
            oradba_log DEBUG "oraup.sh: Classified as other home (${ptype}): ${name}"
        fi
    done
    
    # =========================================================================
    # SECTION 1: Oracle Homes (database homes + other homes, not datasafe)
    # =========================================================================
    # Show database homes from oracle_homes.conf, dummy entries, and other products
    local -a all_homes=("${database_homes[@]}" "${other_homes[@]}")
    
    oradba_log DEBUG "oraup.sh: Section 1 - Oracle Homes: ${#all_homes[@]} total homes"
    
    if [[ ${#all_homes[@]} -gt 0 ]]; then
        echo ""
        echo "Oracle Homes"
        echo "------------------------------------------------------------------------------------------"
        printf "%-20s %-16s %-13s %s\n" "NAME" "TYPE" "STATUS" "ORACLE_HOME"
        echo "------------------------------------------------------------------------------------------"
        
        for home_obj in "${all_homes[@]}"; do
            local name home ptype status flags
            name=$(oradba_registry_get_field "$home_obj" "name")
            home=$(oradba_registry_get_field "$home_obj" "home")
            ptype=$(oradba_registry_get_field "$home_obj" "type")
            flags=$(oradba_registry_get_field "$home_obj" "flags")
            
            # Check if directory exists
            if [[ ! -d "$home" ]]; then
                status="missing"
            elif [[ -z "$(ls -A "$home" 2>/dev/null)" ]]; then
                status="empty"
            elif [[ "$flags" == "D" ]]; then
                # Dummy entry - find the real SID it aliases
                local real_sid=""
                for db_obj in "${database_sids[@]}"; do
                    local db_home
                    db_home=$(oradba_registry_get_field "$db_obj" "home")
                    if [[ "$db_home" == "$home" ]]; then
                        real_sid=$(oradba_registry_get_field "$db_obj" "name")
                        break
                    fi
                done
                if [[ -n "$real_sid" ]]; then
                    status="dummy (→$real_sid)"
                else
                    status="dummy"
                fi
            else
                status="available"
            fi
            
            printf "%-20s %-16s %-13s %s\n" "$name" "$ptype" "$status" "$home"
        done
    fi
    
    # =========================================================================
    # SECTION 2: Database Instances (only real SIDs from oratab)
    # =========================================================================
    if [[ ${#database_sids[@]} -gt 0 ]]; then
        echo ""
        echo "Database Instances"
        echo "------------------------------------------------------------------------------------------"
        printf "%-20s %-16s %-13s %s\n" "SID" "FLAG" "STATUS" "ORACLE_HOME"
        echo "------------------------------------------------------------------------------------------"
        
        for db_obj in "${database_sids[@]}"; do
            local sid home flags
            sid=$(oradba_registry_get_field "$db_obj" "name")
            home=$(oradba_registry_get_field "$db_obj" "home")
            flags=$(oradba_registry_get_field "$db_obj" "flags")
            
            # Get status using cached process list
            local status
            status=$(get_db_status "$sid" "$process_list")
            
            # Get open mode if instance is up
            if [[ "$status" == "up" ]]; then
                local mode
                mode=$(get_db_mode "$sid" "$home")
                status="$mode"
            fi
            
            printf "%-20s %-16s %-13s %s\n" "$sid" "$flags" "$status" "$home"
        done
    fi
    
    # =========================================================================
    # SECTION 3: Listener Status
    # =========================================================================
    # Only show listeners if database installations exist (Issue #99)
    # Skip if only non-database products (DataSafe, Client, Java, etc.)
    local total_databases=$((${#database_sids[@]}))
    local has_database_listeners=false
    
    # Check if any database listeners are actually running (using cached process list)
    if echo "$process_list" | grep "[t]nslsnr" | grep -qv "datasafe\|oracle_cman_home"; then
        has_database_listeners=true
    fi
    
    oradba_log DEBUG "oraup.sh: Listener section check: total_databases=${total_databases}, has_database_listeners=${has_database_listeners}"
    
    if [[ $total_databases -gt 0 ]] || [[ "$has_database_listeners" == "true" ]]; then
        oradba_log DEBUG "oraup.sh: Displaying listener section"
        echo ""
        echo "------------------------------------------------------------------------------------------"
        printf "%-20s %-16s %-13s %s\n" "NAME" "PORT (tcp/tcps)" "STATUS" "ORACLE_HOME"
        echo "------------------------------------------------------------------------------------------"
        
        # Check for running listeners (using cached process list)
        local listener_count=0
        while read -r listener_line; do
            local listener_name listener_home
            # Extract listener name (second-to-last field before -inherit flag)
            listener_name=$(echo "$listener_line" | awk '{print $(NF-1)}')
            
            # Extract Oracle Home from ps output (full path to tnslsnr binary)
            # ps output format: /path/to/oracle_home/bin/tnslsnr LISTENER -inherit
            listener_home=$(echo "$listener_line" | awk '{for(i=1;i<=NF;i++) if($i ~ /tnslsnr$/) print $i}' | sed 's|/bin/tnslsnr$||')
            
            # Get detailed listener status and ports
            # Use lsnrctl from the listener's ORACLE_HOME to ensure compatibility
            local lsnr_status="down"
            local port_display=""
            
            # Try to use plugin for status check if available
            local plugin_file="${ORADBA_BASE}/lib/plugins/database_plugin.sh"
            local use_plugin=false
            
            if [[ -f "${plugin_file}" ]]; then
                # shellcheck source=/dev/null
                source "${plugin_file}" 2>/dev/null
                if declare -f plugin_check_listener_status >/dev/null 2>&1; then
                    use_plugin=true
                fi
            fi
            
            if [[ "$use_plugin" == "true" ]]; then
                # Use plugin to check listener status
                local plugin_status
                if plugin_status=$(plugin_check_listener_status "${listener_home}"); then
                    lsnr_status="$plugin_status"
                    # Map plugin status to display status
                    case "$lsnr_status" in
                        running) lsnr_status="up" ;;
                        stopped) lsnr_status="down" ;;
                        unavailable) lsnr_status="unavailable" ;;
                    esac
                fi
                
                # Still extract ports using traditional method
                if [[ "$lsnr_status" == "up" ]] && [[ -x "${listener_home}/bin/lsnrctl" ]]; then
                    local lsnr_output
                    lsnr_output=$(ORACLE_HOME="${listener_home}" \
                                  LD_LIBRARY_PATH="${listener_home}/lib:${LD_LIBRARY_PATH}" \
                                  "${listener_home}/bin/lsnrctl" status "$listener_name" 2>/dev/null)
                    
                    # Extract ports (keeping existing logic)
                    local endpoints
                    endpoints=$(echo "$lsnr_output" | grep -A 20 "Listening Endpoints Summary" | grep "PROTOCOL=")
                    
                    if [[ -n "$endpoints" ]]; then
                        local -a tcp_ports=()
                        local -a tcps_ports=()
                        
                        while IFS= read -r endpoint; do
                            local protocol port
                            protocol=$(echo "$endpoint" | grep -o "PROTOCOL=[^)]*" | cut -d= -f2 | tr '[:upper:]' '[:lower:]')
                            port=$(echo "$endpoint" | grep -o "PORT=[0-9]*" | cut -d= -f2)
                            
                            if [[ -n "$port" ]]; then
                                if [[ "$protocol" == "tcps" ]]; then
                                    tcps_ports+=("$port")
                                elif [[ "$protocol" == "tcp" ]]; then
                                    tcp_ports+=("$port")
                                fi
                            fi
                        done <<< "$endpoints"
                        
                        # Format: tcp_port/tcps_port or just tcp_port
                        local tcp_str=""
                        local tcps_str=""
                        [[ ${#tcp_ports[@]} -gt 0 ]] && tcp_str=$(IFS=','; echo "${tcp_ports[*]}")
                        [[ ${#tcps_ports[@]} -gt 0 ]] && tcps_str=$(IFS=','; echo "${tcps_ports[*]}")
                        
                        if [[ -n "$tcp_str" && -n "$tcps_str" ]]; then
                            port_display="${tcp_str}/${tcps_str}"
                        elif [[ -n "$tcp_str" ]]; then
                            port_display="$tcp_str"
                        elif [[ -n "$tcps_str" ]]; then
                            port_display="$tcps_str"
                        fi
                    fi
                fi
            else
                # Fallback to traditional method
                if [[ -x "${listener_home}/bin/lsnrctl" ]]; then
                    local lsnr_output
                    # Set full environment for lsnrctl execution from listener's home
                    # Need ORACLE_HOME and LD_LIBRARY_PATH for lsnrctl to work correctly
                    lsnr_output=$(ORACLE_HOME="${listener_home}" \
                                  LD_LIBRARY_PATH="${listener_home}/lib:${LD_LIBRARY_PATH}" \
                                  "${listener_home}/bin/lsnrctl" status "$listener_name" 2>/dev/null)
                    
                    if echo "$lsnr_output" | grep -qi "STATUS of the LISTENER"; then
                        lsnr_status="up"
                        
                        # Extract all ports from Listening Endpoints
                        # Build compact display: tcp_ports/tcps_ports (e.g., 1521/2345 or just 1521)
                        local endpoints
                        endpoints=$(echo "$lsnr_output" | grep -A 20 "Listening Endpoints Summary" | grep "PROTOCOL=")
                        
                        if [[ -n "$endpoints" ]]; then
                            local -a tcp_ports=()
                            local -a tcps_ports=()
                            
                            while IFS= read -r endpoint; do
                                local protocol port
                                protocol=$(echo "$endpoint" | grep -o "PROTOCOL=[^)]*" | cut -d= -f2 | tr '[:upper:]' '[:lower:]')
                                port=$(echo "$endpoint" | grep -o "PORT=[0-9]*" | cut -d= -f2)
                                
                                if [[ -n "$port" ]]; then
                                    if [[ "$protocol" == "tcps" ]]; then
                                        tcps_ports+=("$port")
                                    elif [[ "$protocol" == "tcp" ]]; then
                                        tcp_ports+=("$port")
                                    fi
                                fi
                            done <<< "$endpoints"
                            
                            # Format: tcp_port/tcps_port or just tcp_port
                            local tcp_str=""
                            local tcps_str=""
                            [[ ${#tcp_ports[@]} -gt 0 ]] && tcp_str=$(IFS=','; echo "${tcp_ports[*]}")
                            [[ ${#tcps_ports[@]} -gt 0 ]] && tcps_str=$(IFS=','; echo "${tcps_ports[*]}")
                            
                            if [[ -n "$tcp_str" && -n "$tcps_str" ]]; then
                                port_display="${tcp_str}/${tcps_str}"
                            elif [[ -n "$tcp_str" ]]; then
                                port_display="$tcp_str"
                            elif [[ -n "$tcps_str" ]]; then
                                port_display="$tcps_str"
                            fi
                        fi
                    fi
                fi
            fi
            
            # Use full path for listener home (not [SID] notation)
            printf "%-20s %-16s %-13s %s\n" "$listener_name" "$port_display" "$lsnr_status" "$listener_home"
            ((listener_count++))
        done < <(echo "$process_list" | grep "[t]nslsnr" | grep -v "datasafe\|oracle_cman_home")
        
        if [[ $listener_count -eq 0 ]]; then
            echo "  No database listeners running"
        fi
    fi
    
    # =========================================================================
    # SECTION 4: Data Safe Connectors
    # =========================================================================
    oradba_log DEBUG "oraup.sh: Section 4 - Data Safe Connectors: ${#datasafe_homes[@]} connectors"
    
    if [[ ${#datasafe_homes[@]} -gt 0 ]]; then
        echo ""
        echo "Data Safe Connectors"
        echo "------------------------------------------------------------------------------------------"
        printf "%-20s %-16s %-13s %s\n" "NAME" "PORT (tcp/tcps)" "STATUS" "DATASAFE_BASE_HOME"
        echo "------------------------------------------------------------------------------------------"
        
        # OPTIMIZATION: Parallel status checks for multiple connectors
        # Use arrays to store results in order
        local -a ds_names=()
        local -a ds_homes=()
        local -a ds_statuses=()
        local -a ds_ports=()
        local -a ds_pids=()
        local -a ds_temp_files=()
        
        # Launch all status checks in parallel
        local idx=0
        for ds_obj in "${datasafe_homes[@]}"; do
            local name home
            name=$(oradba_registry_get_field "$ds_obj" "name")
            home=$(oradba_registry_get_field "$ds_obj" "home")
            
            ds_names+=("$name")
            ds_homes+=("$home")
            
            # Check basic conditions first (synchronously for quick failures)
            if [[ ! -d "$home" ]]; then
                ds_statuses+=("unavailable")
                ds_ports+=("n/a")
                ds_pids+=("")
                ds_temp_files+=("")
            elif [[ -z "$(ls -A "$home" 2>/dev/null)" ]]; then
                ds_statuses+=("empty")
                ds_ports+=("n/a")
                ds_pids+=("")
                ds_temp_files+=("")
            else
                # Launch status check in background with temp file for result
                local temp_file
                temp_file=$(mktemp)
                ds_temp_files+=("$temp_file")
                
                # Background job to get status and port
                (
                    local status="unknown"
                    local port_display="n/a"
                    
                    # Export cached process list for plugin to use
                    export ORADBA_CACHED_PS="$process_list"
                    
                    # Get status using plugin system
                    if type -t oradba_get_product_status &>/dev/null; then
                        status=$(oradba_get_product_status "datasafe" "$name" "$home" 2>&1 | grep -v "^\\[" | tr '[:upper:]' '[:lower:]')
                        if [[ -z "$status" ]]; then
                            status="unknown"
                        fi
                    fi
                    
                    # Get port from metadata
                    if type -t execute_plugin_function_v2 &>/dev/null; then
                        local metadata
                        execute_plugin_function_v2 "datasafe" "get_metadata" "${home}" "metadata" "" 2>/dev/null || true
                        if [[ -n "${metadata}" ]]; then
                            local port
                            port=$(echo "${metadata}" | awk -F= '$1=="port" {print $2; exit}')
                            if [[ -n "${port}" ]]; then
                                port_display="${port}"
                            fi
                        fi
                    fi
                    
                    # Write results to temp file
                    echo "${status}|${port_display}" > "$temp_file"
                ) &
                
                ds_pids+=("$!")
                ds_statuses+=("")  # Placeholder
                ds_ports+=("")     # Placeholder
            fi
            
            ((idx++))
        done
        
        # Wait for all background jobs and collect results
        for idx in "${!ds_pids[@]}"; do
            local pid="${ds_pids[$idx]}"
            if [[ -n "$pid" ]]; then
                wait "$pid" 2>/dev/null || true
                
                # Read results from temp file
                local temp_file="${ds_temp_files[$idx]}"
                if [[ -f "$temp_file" ]]; then
                    local result
                    result=$(cat "$temp_file")
                    ds_statuses[idx]="${result%%|*}"
                    ds_ports[idx]="${result#*|}"
                    rm -f "$temp_file"
                else
                    ds_statuses[idx]="unknown"
                    ds_ports[idx]="n/a"
                fi
            fi
        done
        
        # Display results in original order
        for idx in "${!ds_names[@]}"; do
            printf "%-20s %-16s %-13s %s\n" \
                "${ds_names[$idx]}" \
                "${ds_ports[$idx]}" \
                "${ds_statuses[$idx]}" \
                "${ds_homes[$idx]}"
        done
    fi
    
    echo ""
    echo "=========================================================================================="
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
    echo "=========================================================================================="

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

    oradba_log DEBUG "oraup.sh: Starting main function with $# arguments: $*"

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
        oradba_log DEBUG "oraup.sh: Calling show_oracle_status with verbose=${verbose}"
        show_oracle_status "$verbose"
    else
        oradba_log DEBUG "oraup.sh: Quiet mode - skipping status display"
    fi
}

# Run main function
oradba_log DEBUG "oraup.sh: Script started, calling main with arguments: $*"
main "$@"
oradba_log DEBUG "oraup.sh: Script completed"
