#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: db_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.3.0
# Purpose....: Database query and status functions for Oracle databases
# Notes......: This library provides reusable functions to query database
#              information from v$ views at different database states.
#              Functions handle NOMOUNT, MOUNT, and OPEN states gracefully.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Check if common library is loaded
if ! command -v log_error &> /dev/null; then
    echo "ERROR: db_functions.sh requires common.sh to be sourced first"
    return 1
fi

# ------------------------------------------------------------------------------
# Function: check_database_connection
# Purpose.: Check if database is accessible and return connection status
# Returns.: 0 if connected, 1 if not
# ------------------------------------------------------------------------------
check_database_connection() {
    local result
    result=$(sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0
SELECT 'CONNECTED' FROM dual;
EXIT;
EOF
)
    
    if [[ "$result" =~ CONNECTED ]]; then
        return 0
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: get_database_open_mode
# Purpose.: Get the current database open mode
# Returns.: Open mode string or empty if not accessible
# ------------------------------------------------------------------------------
get_database_open_mode() {
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 TRIMSPOOL ON
SELECT status FROM v$instance;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_instance_info
# Purpose.: Query v$instance and v$parameter (available in NOMOUNT and higher)
# Returns.: Tab-separated values: INSTANCE_NAME|STATUS|STARTUP_TIME|VERSION|...
# ------------------------------------------------------------------------------
query_instance_info() {
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON
SELECT 
    i.instance_name || '|' ||
    i.status || '|' ||
    TO_CHAR(i.startup_time, 'YYYY-MM-DD HH24:MI:SS') || '|' ||
    i.version || '|' ||
    i.edition || '|' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = 'sga_target'), 2
    ) || '|' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = 'pga_aggregate_target'), 2
    ) || '|' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = 'db_recovery_file_dest_size'), 2
    )
FROM v$instance i;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_database_info
# Purpose.: Query v$database (available in MOUNT and higher)
# Returns.: Tab-separated values: DB_NAME|DB_UNIQUE_NAME|DBID|LOG_MODE|...
# ------------------------------------------------------------------------------
query_database_info() {
    local open_mode="$1"
    
    # Only query if database is at least MOUNTED
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi
    
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON
SELECT 
    d.name || '|' ||
    d.db_unique_name || '|' ||
    d.dbid || '|' ||
    d.log_mode || '|' ||
    d.database_role || '|' ||
    NVL(
        (SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET'),
        'UNKNOWN'
    )
FROM v$database d;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_datafile_size
# Purpose.: Query total datafile size (available in MOUNT and higher)
# Returns.: Size in GB
# ------------------------------------------------------------------------------
query_datafile_size() {
    local open_mode="$1"
    
    # Only query if database is at least MOUNTED
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi
    
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 TRIMSPOOL ON
SELECT ROUND(SUM(bytes)/1024/1024/1024, 2)
FROM v$datafile;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_memory_usage
# Purpose.: Query current memory usage (available in OPEN)
# Returns.: SGA|PGA in GB
# ------------------------------------------------------------------------------
query_memory_usage() {
    local open_mode="$1"
    
    # Only query if database is OPEN
    if [[ "$open_mode" != "OPEN" ]]; then
        return 1
    fi
    
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET ECHO OFF TERMOUT ON HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 LINESIZE 200 TRIMSPOOL ON
SELECT ROUND((SELECT SUM(value)/1024/1024/1024 FROM v$sga), 2) || '|' || ROUND((SELECT value/1024/1024/1024 FROM v$pgastat WHERE name = 'total PGA allocated'), 2) FROM dual;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_sessions_info
# Purpose.: Query session information (available in OPEN)
# Returns.: NON_ORACLE_USERS|NON_ORACLE_SESSIONS|ORACLE_USERS|ORACLE_SESSIONS
# ------------------------------------------------------------------------------
query_sessions_info() {
    local open_mode="$1"
    
    # Only query if database is OPEN
    if [[ "$open_mode" != "OPEN" ]]; then
        return 1
    fi
    
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 TRIMSPOOL ON
SELECT 
    COUNT(DISTINCT CASE WHEN username IS NULL THEN sid END) || '|' ||
    COUNT(CASE WHEN username IS NULL THEN sid END) || '|' ||
    COUNT(DISTINCT CASE WHEN username IS NOT NULL THEN username END) || '|' ||
    COUNT(CASE WHEN username IS NOT NULL THEN sid END)
FROM v$session
WHERE type = 'USER';
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_pdb_info
# Purpose.: Query pluggable database information (available in OPEN for CDB)
# Returns.: PDB_NAME1(MODE1), PDB_NAME2(MODE2), ...
# ------------------------------------------------------------------------------
query_pdb_info() {
    local open_mode="$1"
    
    # Only query if database is OPEN
    if [[ "$open_mode" != "OPEN" ]]; then
        return 1
    fi
    
    sqlplus -s / as sysdba << 'EOF' 2>/dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON
SELECT LISTAGG(
    name || '(' || 
    CASE open_mode 
        WHEN 'READ WRITE' THEN 'RW'
        WHEN 'READ ONLY' THEN 'RO'
        WHEN 'MOUNTED' THEN 'MO'
        WHEN 'MIGRATE' THEN 'MI'
        ELSE SUBSTR(open_mode, 1, 2)
    END || ')', 
    ', '
) WITHIN GROUP (ORDER BY name)
FROM v$pdbs;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: format_uptime
# Purpose.: Format uptime from timestamp
# Parameters: startup_time (YYYY-MM-DD HH24:MI:SS)
# Returns.: Formatted string like "2025-12-15 20:37 (0d 0h 8m)"
# ------------------------------------------------------------------------------
format_uptime() {
    local startup_time="$1"
    
    if [[ -z "$startup_time" ]]; then
        echo "Unknown"
        return
    fi
    
    # Calculate uptime using date commands (cross-platform: macOS and Linux)
    local startup_epoch current_epoch uptime_seconds
    # Try macOS format first, then Linux format
    startup_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$startup_time" "+%s" 2>/dev/null || \
                    date -d "$startup_time" "+%s" 2>/dev/null || echo "0")
    current_epoch=$(date "+%s")
    uptime_seconds=$((current_epoch - startup_epoch))
    
    local days hours minutes
    days=$((uptime_seconds / 86400))
    hours=$(( (uptime_seconds % 86400) / 3600 ))
    minutes=$(( (uptime_seconds % 3600) / 60 ))
    
    printf "%s (%dd %dh %dm)" "$startup_time" "$days" "$hours" "$minutes"
}

# ------------------------------------------------------------------------------
# Function: show_database_status
# Purpose.: Display comprehensive database status based on open mode
# Parameters: None (uses current ORACLE_SID environment)
# ------------------------------------------------------------------------------
show_database_status() {
    # Check if we can connect
    if ! check_database_connection; then
        log_error "Cannot connect to database. Is it running?"
        return 1
    fi
    
    # Get open mode first
    local open_mode
    open_mode=$(get_database_open_mode | tr -d '[:space:]')
    
    # Query instance info (always available)
    local instance_info
    instance_info=$(query_instance_info)
    
    if [[ -z "$instance_info" ]]; then
        log_error "Unable to query instance information"
        return 1
    fi
    
    # Parse instance info
    IFS='|' read -r instance_name status startup_time version _ sga_target pga_target fra_size <<< "$instance_info"
    
    # Start output
    echo ""
    echo "-------------------------------------------------------------------------------"
    printf "%-15s: %s\n" "INSTANCE_NAME" "$instance_name"
    
    # Query database info if MOUNTED or OPEN
    if [[ "$open_mode" != "STARTED" ]]; then
        local db_info
        db_info=$(query_database_info "$open_mode")
        
        if [[ -n "$db_info" ]]; then
            IFS='|' read -r db_name db_unique_name dbid log_mode db_role charset <<< "$db_info"
            printf "%-15s: %s\n" "DB_NAME" "$db_name"
            printf "%-15s: %s\n" "DB_UNIQUE_NAME" "$db_unique_name"
            printf "%-15s: %s\n" "DBID" "$dbid"
            
            # Get datafile size
            local df_size
            df_size=$(query_datafile_size "$open_mode" | tr -d '[:space:]')
            if [[ -n "$df_size" && "$df_size" != "0" ]]; then
                printf "%-15s: %sG\n" "DATAFILE_SIZE" "$df_size"
            fi
        fi
    fi
    
    # Memory info
    local mem_usage
    mem_usage=$(query_memory_usage "$open_mode")
    if [[ -n "$mem_usage" ]]; then
        IFS='|' read -r current_sga current_pga <<< "$mem_usage"
        printf "%-15s: %sG SGA / %sG PGA (%sG pga_aggregate_target)\n" "MEMORY_SIZE" "$current_sga" "$current_pga" "$pga_target"
    else
        printf "%-15s: %sG SGA / 0G PGA (%sG pga_aggregate_target)\n" "MEMORY_SIZE" "$sga_target" "$pga_target"
    fi
    
    # FRA size
    printf "%-15s: %sG\n" "FRA_SIZE" "${fra_size:-0}"
    
    # Uptime
    printf "%-15s: %s\n" "UPTIME" "$(format_uptime "$startup_time")"
    
    # Instance status
    printf "%-15s: %s\n" "INSTANCE_STATUS" "$status"
    printf "%-15s: %s\n" "OPEN_MODE" "$open_mode"
    
    # Session info if OPEN
    if [[ "$open_mode" == "OPEN" ]]; then
        local session_info
        session_info=$(query_sessions_info "$open_mode")
        if [[ -n "$session_info" ]]; then
            IFS='|' read -r non_oracle_users non_oracle_sessions oracle_users oracle_sessions <<< "$session_info"
            printf "%-15s: Non-Oracle: %s/%s , Oracle: %s/%s\n" "USERS/SESSIONS" \
                "$non_oracle_users" "$non_oracle_sessions" "$oracle_users" "$oracle_sessions"
        fi
    fi
    
    # Database role and log mode (MOUNT and higher)
    if [[ "$open_mode" != "STARTED" && -n "$db_role" ]]; then
        printf "%-15s: %s\n" "DATABASE_ROLE" "$db_role"
        printf "%-15s: %s\n" "LOG_MODE" "$log_mode"
        printf "%-15s: %s\n" "CHARACTERSET" "$charset"
    fi
    
    # Oracle Home and Version
    printf "%-15s: %s\n" "ORACLE_HOME" "${ORACLE_HOME:-not set}"
    printf "%-15s: %s\n" "ORACLE_BASE" "${ORACLE_BASE:-not set}"
    printf "%-15s: %s\n" "TNS_ADMIN" "${TNS_ADMIN:-not set}"
    printf "%-15s: %s\n" "ORACLE_VERSION" "$version"
    
    # PDB info (OPEN only)
    if [[ "$open_mode" == "OPEN" ]]; then
        local pdb_info
        pdb_info=$(query_pdb_info "$open_mode" | tr -d '[:space:]')
        if [[ -n "$pdb_info" ]]; then
            printf "%-15s: %s\n" "PDB" "$pdb_info"
        fi
    fi
    
    echo "-------------------------------------------------------------------------------"
    echo ""
}
