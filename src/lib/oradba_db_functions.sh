#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_db_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
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
    echo "ERROR: oradba_db_functions.sh requires oradba_common.sh to be sourced first"
    return 1
fi

# ------------------------------------------------------------------------------
# Function: check_database_connection
# Purpose.: Check if database is accessible and return connection status
# Returns.: 0 if connected, 1 if not
# ------------------------------------------------------------------------------
check_database_connection() {
    local result
    result=$(
        sqlplus -s / as sysdba << 'EOF' 2> /dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0
SELECT status FROM v$instance;
EXIT;
EOF
    )

    # If we got any status (STARTED, MOUNTED, OPEN), instance is accessible
    if [[ -n "$result" ]] && [[ "$result" =~ ^(STARTED|MOUNTED|OPEN) ]]; then
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
    sqlplus -s / as sysdba << 'EOF' 2> /dev/null
SET HEADING OFF FEEDBACK OFF VERIFY OFF PAGESIZE 0 TRIMSPOOL ON
SELECT status FROM v$instance;
EXIT;
EOF
}

# ------------------------------------------------------------------------------
# Function: query_instance_info
# Purpose.: Query v$instance and v$parameter (available in NOMOUNT and higher)
# Returns.: Pipe-separated values: INSTANCE_NAME|STATUS|STARTUP_TIME|VERSION|...
# ------------------------------------------------------------------------------
query_instance_info() {
    local query='
SELECT 
    i.instance_name || '\''|'\'' ||
    i.status || '\''|'\'' ||
    TO_CHAR(i.startup_time, '\''YYYY-MM-DD HH24:MI:SS'\'') || '\''|'\'' ||
    i.version || '\''|'\'' ||
    i.edition || '\''|'\'' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = '\''sga_target'\''), 2
    ) || '\''|'\'' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = '\''pga_aggregate_target'\''), 2
    ) || '\''|'\'' ||
    ROUND(
        (SELECT value/1024/1024/1024 FROM v$parameter WHERE name = '\''db_recovery_file_dest_size'\''), 2
    )
FROM v$instance i;'

    execute_db_query "$query" "delimited"
}

# ------------------------------------------------------------------------------
# Function: query_database_info
# Purpose.: Query v$database (available in MOUNT and higher)
# Returns.: Pipe-separated values: DB_NAME|DB_UNIQUE_NAME|DBID|LOG_MODE|...
# ------------------------------------------------------------------------------
query_database_info() {
    local open_mode="$1"

    # Only query if database is at least MOUNTED
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi

    local query="
SELECT 
    d.name || '|' ||
    d.db_unique_name || '|' ||
    d.dbid || '|' ||
    d.log_mode || '|' ||
    d.database_role || '|' ||
    NVL(
        (SELECT value FROM v\$nls_parameters WHERE parameter = 'NLS_CHARACTERSET'),
        'UNKNOWN'
    )
FROM v\$database d;"

    execute_db_query "$query" "delimited"
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

    local query='
SELECT ROUND(SUM(bytes)/1024/1024/1024, 2)
FROM v$datafile;'

    execute_db_query "$query" "raw"
}

# ------------------------------------------------------------------------------
# Function: query_memory_usage
# Purpose.: Query current memory usage (available in MOUNT and OPEN)
# Returns.: SGA|PGA in GB
# ------------------------------------------------------------------------------
query_memory_usage() {
    local open_mode="$1"

    # Query v\$sga and v\$pgastat - works in MOUNT and OPEN states
    # Skip only for STARTED (NOMOUNT)
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi

    local query="
SELECT 
    ROUND(SUM(CASE WHEN name = 'sga' THEN value ELSE 0 END)/1024/1024/1024, 2) || '|' ||
    ROUND(SUM(CASE WHEN name = 'pga' THEN value ELSE 0 END)/1024/1024/1024, 2)
FROM (
    SELECT 'sga' name, SUM(value) value FROM v\$sga
    UNION ALL
    SELECT 'pga' name, value FROM v\$pgastat WHERE name = 'total PGA allocated'
);"

    execute_db_query "$query" "delimited"
}

# ------------------------------------------------------------------------------
# Function: query_sessions_info
# Purpose.: Query session information (available in MOUNT and OPEN)
# Returns.: NON_ORACLE_USERS|NON_ORACLE_SESSIONS|ORACLE_USERS|ORACLE_SESSIONS
# ------------------------------------------------------------------------------
query_sessions_info() {
    local open_mode="$1"

    # Query v\$session - works in MOUNT and OPEN states
    # Skip only for STARTED (NOMOUNT)
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi

    local query="
SELECT 
    COUNT(DISTINCT CASE WHEN username IS NULL THEN sid END) || '|' ||
    COUNT(CASE WHEN username IS NULL THEN sid END) || '|' ||
    COUNT(DISTINCT CASE WHEN username IS NOT NULL THEN username END) || '|' ||
    COUNT(CASE WHEN username IS NOT NULL THEN sid END)
FROM v\$session
WHERE type = 'USER';"

    execute_db_query "$query" "delimited"
}

# ------------------------------------------------------------------------------
# Function: query_pdb_info
# Purpose.: Query pluggable database information (available in OPEN for CDB)
# Returns.: PDB_NAME1(MODE1), PDB_NAME2(MODE2), ...
# ------------------------------------------------------------------------------
query_pdb_info() {
    local open_mode="$1"

    # Query v\$pdbs - works in MOUNT and OPEN states
    # Skip only for STARTED (NOMOUNT)
    if [[ "$open_mode" == "STARTED" ]]; then
        return 1
    fi

    local query="
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
FROM v\$pdbs;"

    execute_db_query "$query" "raw"
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
    startup_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$startup_time" "+%s" 2> /dev/null \
        || date -d "$startup_time" "+%s" 2> /dev/null || echo "0")
    current_epoch=$(date "+%s")
    uptime_seconds=$((current_epoch - startup_epoch))

    local days hours minutes
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    minutes=$(((uptime_seconds % 3600) / 60))

    printf "%s (%dd %dh %dm)" "$startup_time" "$days" "$hours" "$minutes"
}

# ------------------------------------------------------------------------------
# Function: show_oracle_home_status
# Purpose.: Display Oracle Home environment info for non-database homes
# Parameters: None (uses current ORACLE_HOME environment)
# ------------------------------------------------------------------------------
show_oracle_home_status() {
    local product_type
    local product_version
    
    # Get product type from ORADBA_CURRENT_HOME_TYPE if available
    if [[ -n "${ORADBA_CURRENT_HOME_TYPE}" ]]; then
        product_type="${ORADBA_CURRENT_HOME_TYPE}"
    else
        product_type="Oracle Home"
    fi
    
    # Get Oracle version
    product_version=$(get_oracle_version)
    
    echo ""
    echo "-------------------------------------------------------------------------------"
    printf "%-14s : %s\n" "ORACLE_BASE" "${ORACLE_BASE:-Not set}"
    printf "%-14s : %s\n" "ORACLE_HOME" "${ORACLE_HOME:-Not set}"
    printf "%-14s : %s\n" "TNS_ADMIN" "${TNS_ADMIN:-Not set}"
    printf "%-14s : %s\n" "ORACLE_VERSION" "${product_version:-Unknown}"
    echo "-------------------------------------------------------------------------------"
    printf "%-14s : %s\n" "PRODUCT_TYPE" "${product_type}"
    echo "-------------------------------------------------------------------------------"
    echo ""
}

# ------------------------------------------------------------------------------
# Function: show_database_status
# Purpose.: Display comprehensive database status based on open mode
# Parameters: None (uses current ORACLE_SID environment)
# ------------------------------------------------------------------------------
show_database_status() {
    # Check if this is a non-database Oracle Home
    if [[ -n "${ORADBA_CURRENT_HOME_TYPE}" ]] && [[ "${ORADBA_CURRENT_HOME_TYPE}" != "database" ]]; then
        show_oracle_home_status
        return 0
    fi
    
    # Check if this is a dummy SID BEFORE attempting connection
    if is_dummy_sid; then
        # Dummy database - show environment only, no SQL queries
        echo ""
        echo "-------------------------------------------------------------------------------"
        printf "%-15s: %s\n" "ORACLE_BASE" "${ORACLE_BASE:-not set}"
        printf "%-15s: %s\n" "ORACLE_HOME" "${ORACLE_HOME:-not set}"
        printf "%-15s: %s\n" "TNS_ADMIN" "${TNS_ADMIN:-not set}"

        # Try to get version from Oracle Home
        local version=""
        if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
            version=$("${ORACLE_HOME}/bin/sqlplus" -version 2> /dev/null | grep -E 'Release [0-9]+' | sed -n 's/.*Release \([0-9][0-9.]*\).*/\1/p' | head -1)
        fi
        printf "%-15s: %s\n" "ORACLE_VERSION" "${version:-Unknown}"
        echo "-------------------------------------------------------------------------------"
        printf "%-15s: %s\n" "STATUS" "Dummy Database (environment only)"
        echo "-------------------------------------------------------------------------------"
        echo ""
        return 0
    fi

    # Check if we can connect (for real SIDs)
    if ! check_database_connection; then
        # Database not accessible - show environment status
        echo ""
        echo "-------------------------------------------------------------------------------"
        printf "%-15s: %s\n" "ORACLE_BASE" "${ORACLE_BASE:-not set}"
        printf "%-15s: %s\n" "ORACLE_HOME" "${ORACLE_HOME:-not set}"
        printf "%-15s: %s\n" "TNS_ADMIN" "${TNS_ADMIN:-not set}"

        # Try to get version from Oracle Home
        local version=""
        if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
            version=$("${ORACLE_HOME}/bin/sqlplus" -version 2> /dev/null | grep -E 'Release [0-9]+' | sed -n 's/.*Release \([0-9][0-9.]*\).*/\1/p' | head -1)
        fi
        printf "%-15s: %s\n" "ORACLE_VERSION" "${version:-Unknown}"
        echo "-------------------------------------------------------------------------------"
        printf "%-15s: %s\n" "STATUS" "NOT STARTED"
        echo "-------------------------------------------------------------------------------"
        echo ""
        return 0
    fi

    # Get open mode first
    local open_mode
    open_mode=$(get_database_open_mode | tr -d '[:space:]')

    # Query instance info (always available)
    local instance_info
    instance_info=$(query_instance_info)

    if [[ -z "$instance_info" ]]; then
        oradba_log ERROR "Unable to query instance information"
        return 1
    fi

    # Parse instance info
    IFS='|' read -r instance_name db_status startup_time version _ sga_target pga_target fra_size <<< "$instance_info"

    # Start output
    echo ""
    echo "-------------------------------------------------------------------------------"
    # Oracle Environment (show first)
    printf "%-15s: %s\n" "ORACLE_BASE" "${ORACLE_BASE:-not set}"
    printf "%-15s: %s\n" "ORACLE_HOME" "${ORACLE_HOME:-not set}"
    printf "%-15s: %s\n" "TNS_ADMIN" "${TNS_ADMIN:-not set}"
    printf "%-15s: %s\n" "ORACLE_VERSION" "$version"
    printf "%-15s: %s\n" "DB_STATUS" "$db_status"
    echo "-------------------------------------------------------------------------------"

    # Query database info if MOUNTED or OPEN
    local db_info=""
    local db_name="" db_unique_name="" dbid="" log_mode="" db_role="" charset=""
    if [[ "$open_mode" != "STARTED" ]]; then
        db_info=$(query_database_info "$open_mode")

        if [[ -n "$db_info" ]]; then
            IFS='|' read -r db_name db_unique_name dbid log_mode db_role charset <<< "$db_info"
            # Database identity (compact: one or two lines)
            # Show DB_NAME(DBID) and DB_UNIQUE_NAME on one line if they differ
            if [[ "$db_name" == "$db_unique_name" ]]; then
                printf "%-15s: %s (Instance: %s, DBID: %s)\n" "DATABASE" "$db_name" "$instance_name" "$dbid"
            else
                printf "%-15s: %s (DBID: %s)\n" "DB_NAME" "$db_name" "$dbid"
                printf "%-15s: %s (Instance: %s)\n" "DB_UNIQUE_NAME" "$db_unique_name" "$instance_name"
            fi
        else
            oradba_log DEBUG "query_database_info returned empty for open_mode: $open_mode"
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

    # Datafile size (for MOUNT and OPEN)
    if [[ "$open_mode" != "STARTED" ]]; then
        local df_size
        df_size=$(query_datafile_size "$open_mode")
        if [[ -n "$df_size" ]]; then
            # Trim any leading/trailing whitespace
            df_size=$(echo "$df_size" | xargs)
            printf "%-15s: %sG\n" "DATAFILE_SIZE" "$df_size"
        fi
    fi

    # Uptime
    printf "%-15s: %s\n" "UPTIME" "$(format_uptime "$startup_time")"

    # Status display - format depends on open_mode
    if [[ "$open_mode" == "STARTED" ]]; then
        # For NOMOUNT: show single status
        printf "%-15s: %s\n" "STATUS" "$open_mode"
    else
        # For MOUNTED and OPEN: show status with database role
        if [[ -n "$db_role" ]]; then
            printf "%-15s: %s / %s\n" "STATUS" "$open_mode" "$db_role"
        else
            printf "%-15s: %s\n" "STATUS" "$open_mode"
        fi
    fi

    # Session info (for MOUNT and OPEN)
    if [[ "$open_mode" != "STARTED" ]]; then
        local session_info
        session_info=$(query_sessions_info "$open_mode")
        if [[ -n "$session_info" ]]; then
            IFS='|' read -r non_oracle_users non_oracle_sessions oracle_users oracle_sessions <<< "$session_info"
            printf "%-15s: Non-Oracle: %s/%s , Oracle: %s/%s\n" "USERS/SESSIONS" \
                "$non_oracle_users" "$non_oracle_sessions" "$oracle_users" "$oracle_sessions"
        fi
    fi

    # Database details (MOUNT and OPEN)
    if [[ "$open_mode" != "STARTED" && -n "$log_mode" ]]; then
        printf "%-15s: %s\n" "LOG_MODE" "$log_mode"
        printf "%-15s: %s\n" "CHARACTERSET" "${charset:-N/A}"
    fi

    # PDB info (for MOUNT and OPEN)
    if [[ "$open_mode" != "STARTED" ]]; then
        local pdb_info
        pdb_info=$(query_pdb_info "$open_mode" | tr -d '[:space:]')
        if [[ -n "$pdb_info" ]]; then
            printf "%-15s: %s\n" "PDB" "$pdb_info"
        fi
    fi

    echo "-------------------------------------------------------------------------------"
    echo ""
}
