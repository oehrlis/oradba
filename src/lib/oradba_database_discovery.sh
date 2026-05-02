#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_database_discovery.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.03.23
# Revision...: 0.21.0
# Purpose....: Oracle database and instance discovery functions
# Notes......: Extracted from oradba_common.sh for cohesion.
#              Requires: oradba_common.sh core functions, oradba_home_discovery.sh
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_DATABASE_DISCOVERY_LOADED:-}" ]] && return 0
readonly ORADBA_DATABASE_DISCOVERY_LOADED=1


# ------------------------------------------------------------------------------
# Function: parse_oratab
# Purpose.: Parse oratab file to get Oracle home path for a SID
# Args....: $1 - Oracle SID to look up
#           $2 - (Optional) Path to oratab file (defaults to get_oratab_path)
# Returns.: 0 if SID found, 1 if not found or error
# Output..: Oracle home path for the specified SID
# Notes...: Skips comment lines and dummy entries (:D flag)
# ------------------------------------------------------------------------------
parse_oratab() {
    local sid="$1"
    local oratab_file="${2:-$(get_oratab_path)}"

    if [[ ! -f "$oratab_file" ]]; then
        oradba_log ERROR "oratab file not found: $oratab_file"
        return 1
    fi

    # Case-insensitive search for SID
    grep -i "^${sid}:" "$oratab_file" | grep -v "^#" | head -1
}


# ------------------------------------------------------------------------------
# Function: generate_sid_lists
# Purpose.: Generate SID lists and aliases from oratab and Oracle Homes config
# Args....: $1 - (Optional) Path to oratab file (defaults to get_oratab_path)
# Returns.: 0 on success, 1 if oratab not found
# Output..: Sets ORADBA_SIDLIST and ORADBA_REALSIDLIST environment variables
# Notes...: SIDLIST includes all SIDs and aliases, REALSIDLIST excludes dummies
# ------------------------------------------------------------------------------
generate_sid_lists() {
    local oratab_file="${1:-$(get_oratab_path)}"
    local load_aliases="${ORADBA_LOAD_ALIASES:-true}"

    # Check if oratab exists
    if [[ ! -f "$oratab_file" ]]; then
        oradba_log DEBUG "oratab file not found: $oratab_file"
        export ORADBA_SIDLIST=""
        export ORADBA_REALSIDLIST=""
        return 1
    fi

    local all_sids=""
    local real_sids=""

    # Parse oratab, skip comments and empty lines
    while IFS=: read -r oratab_sid _oracle_home startup_flag; do
        # Skip empty lines and comments
        [[ -z "$oratab_sid" ]] && continue
        [[ "$oratab_sid" =~ ^[[:space:]]*# ]] && continue

        # Skip ASM instances (start with +)
        [[ "$oratab_sid" =~ ^\+ ]] && continue

        # Add to all SIDs list
        all_sids="${all_sids}${all_sids:+ }${oratab_sid}"

        # Add to real SIDs list if startup flag is Y or N (not D for DGMGRL dummy)
        if [[ "$startup_flag" =~ ^[YyNn] ]]; then
            real_sids="${real_sids}${real_sids:+ }${oratab_sid}"
        fi

        # Create alias for this SID (lowercase) only when alias loading is enabled
        if [[ "${load_aliases}" == "true" ]]; then
            local sid_lower
            sid_lower="${oratab_sid,,}" 2>/dev/null || sid_lower=$(printf '%s' "${oratab_sid}" | tr '[:upper:]' '[:lower:]')
            # shellcheck disable=SC2139
            alias "${sid_lower}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${oratab_sid}"
        fi

    done < <(grep -v "^#" "$oratab_file" | grep -v "^[[:space:]]*$")

    # Auto-sync database homes from oratab to oradba_homes.conf (first login)
    # Only when ORADBA_AUTO_DISCOVER_ORATAB=true (opt-in behavior)
    # Use one-time sync guard to avoid repeating costly sync in same shell session
    if [[ "${ORADBA_AUTO_DISCOVER_ORATAB:-false}" == "true" ]] && [[ "${ORADBA_REGISTRY_SYNC_DONE:-false}" != "true" ]]; then
        # Source registry module if not already loaded
        if ! type -t oradba_registry_sync_oratab &>/dev/null; then
            local registry_lib="${ORADBA_BASE}/lib/oradba_registry.sh"
            [[ ! -f "${registry_lib}" ]] && registry_lib="${ORADBA_BASE}/lib/oradba_registry.sh"
            if [[ -f "${registry_lib}" ]]; then
                # shellcheck source=/dev/null
                source "${registry_lib}" 2>/dev/null
            fi
        fi
        if type -t oradba_registry_sync_oratab &>/dev/null; then
            local homes_added
            homes_added=$(oradba_registry_sync_oratab 2>/dev/null)
            if [[ -n "${homes_added}" ]] && [[ ${homes_added} -gt 0 ]]; then
                echo "INFO: Automatically added ${homes_added} database home(s) from oratab to oradba_homes.conf" >&2
            fi
            export ORADBA_REGISTRY_SYNC_DONE=true
        fi
    elif [[ "${ORADBA_AUTO_DISCOVER_ORATAB:-false}" != "true" ]]; then
        oradba_log DEBUG "Skipping oratab->homes sync (ORADBA_AUTO_DISCOVER_ORATAB=${ORADBA_AUTO_DISCOVER_ORATAB:-false})"
    fi

    # Add Oracle Home names and aliases to ORADBA_SIDLIST
    local homes_config
    homes_config=$(get_oracle_homes_path 2>/dev/null) || homes_config=""
    if [[ -f "${homes_config}" ]]; then
        while IFS=: read -r name _path _type _order alias_name _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Trim whitespace
            name="${name#"${name%%[![:space:]]*}"}"
            name="${name%"${name##*[![:space:]]}"}"
            alias_name="${alias_name#"${alias_name%%[![:space:]]*}"}"
            alias_name="${alias_name%"${alias_name##*[![:space:]]}"}"
            
            # Add Oracle Home name to all_sids list
            all_sids="${all_sids}${all_sids:+ }${name}"
            
            # Add alias if it exists and is different from name
            if [[ -n "${alias_name}" && "${alias_name}" != "${name}" && ! "${alias_name}" =~ [[:space:]] ]]; then
                all_sids="${all_sids}${all_sids:+ }${alias_name}"
            fi
        done < "${homes_config}"
    fi

    # Export the lists
    export ORADBA_SIDLIST="$all_sids"
    export ORADBA_REALSIDLIST="$real_sids"

    oradba_log DEBUG "ORADBA_SIDLIST: $ORADBA_SIDLIST"
    oradba_log DEBUG "ORADBA_REALSIDLIST: $ORADBA_REALSIDLIST"

    return 0
}


# ------------------------------------------------------------------------------
# Function: generate_pdb_aliases
# Purpose.: Generate aliases for PDBs in the current CDB
# Args....: None
# Returns.: 0 on success
# Output..: Creates shell aliases for each PDB and exports ORADBA_PDBLIST
# ------------------------------------------------------------------------------
generate_pdb_aliases() {
    # Skip if disabled
    if [[ "${ORADBA_NO_PDB_ALIASES}" == "true" ]]; then
        oradba_log DEBUG "PDB aliases disabled (ORADBA_NO_PDB_ALIASES=true)"
        return 0
    fi

    # Skip if no database connection
    if ! check_database_connection 2> /dev/null; then
        oradba_log DEBUG "No database connection, skipping PDB alias generation"
        return 0
    fi

    # Skip if not a CDB
    local is_cdb
    is_cdb=$(
        sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF TIMING OFF TIME OFF SQLPROMPT "" TRIMSPOOL ON TRIMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT cdb FROM v\$database;
EXIT
EOF
    )

    if [[ "${is_cdb}" != "YES" ]]; then
        oradba_log DEBUG "Not a CDB, skipping PDB alias generation"
        return 0
    fi

    # Get list of PDBs
    local pdb_list
    pdb_list=$(
        sqlplus -s / as sysdba << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF TIMING OFF TIME OFF SQLPROMPT "" TRIMSPOOL ON TRIMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED' ORDER BY name;
EXIT
EOF
    )

    # Create aliases for each PDB
    while IFS= read -r pdb_name; do
        # Skip empty lines
        [[ -z "$pdb_name" ]] && continue

        # Create lowercase alias
        local pdb_lower
        pdb_lower="${pdb_name,,}" 2>/dev/null || pdb_lower=$(printf '%s' "${pdb_name}" | tr '[:upper:]' '[:lower:]')

        # Create alias to set ORADBA_PDB and connect
        # shellcheck disable=SC2139
        alias "${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"

        # Create alias with 'pdb' prefix for clarity
        # shellcheck disable=SC2139
        alias "pdb${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"

        oradba_log DEBUG "Created PDB alias: ${pdb_lower} -> ${pdb_name}"
    done <<< "$pdb_list"

    # Export the PDB list
    export ORADBA_PDBLIST="${pdb_list//$'\n'/ }"
    oradba_log DEBUG "ORADBA_PDBLIST: $ORADBA_PDBLIST"

    return 0
}

# ------------------------------------------------------------------------------
# Function: discover_running_oracle_instances
# Purpose.: Auto-discover running Oracle instances when oratab is empty
# Args....: None
# Returns.: 0 if instances discovered, 1 if none found
# Output..: Prints discovered instances in oratab format (SID:ORACLE_HOME:N)
#           to stdout, one per line
# Notes...: - Only checks processes owned by current user
#           - Detects db_smon_*, ora_pmon_*, asm_smon_* processes
#           - Extracts ORACLE_HOME from /proc/<pid>/exe
#           - Adds temporary entries with startup flag 'N'
#           - Shows warning if Oracle processes run as different user
# ------------------------------------------------------------------------------
discover_running_oracle_instances() {
    local current_user
    current_user=$(id -un)
    
    oradba_log DEBUG "Discovering running Oracle instances for user: $current_user"
    
    # Check for Oracle processes running as different user
    local other_user_processes
    other_user_processes=$(ps -eo user,comm | grep -E "(db_smon_|ora_pmon_|asm_smon_)" | grep -v "^${current_user}" | wc -l)
    
    if [[ "$other_user_processes" -gt 0 ]]; then
        oradba_log WARN "Oracle processes detected running as different user(s)"
        oradba_log WARN "Auto-discovery only works for processes owned by: $current_user"
    fi
    
    # Find Oracle smon/pmon processes for current user
    # Pattern matches: db_smon_FREE, ora_pmon_orcl, asm_smon_+ASM
    local discovered_count=0
    local -A seen_sids  # Track SIDs to avoid duplicates
    
    # Get processes for current user only
    while read -r pid comm; do
        local sid=""
        local oracle_home=""
        
        # Extract SID from process name
        if [[ "$comm" =~ ^db_smon_(.+)$ ]]; then
            sid="${BASH_REMATCH[1]}"
        elif [[ "$comm" =~ ^ora_pmon_(.+)$ ]]; then
            # Convert lowercase pmon SID to uppercase
            sid="${BASH_REMATCH[1]^^}" 2>/dev/null || sid=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
        elif [[ "$comm" =~ ^asm_smon_(.+)$ ]]; then
            sid="${BASH_REMATCH[1]}"
        else
            continue
        fi
        
        # Skip if we've already seen this SID
        [[ -n "${seen_sids[$sid]:-}" ]] && continue
        
        # Determine ORACLE_HOME from /proc/<pid>/exe
        if [[ -d "/proc" && -L "/proc/$pid/exe" ]]; then
            local exe_path
            exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
            
            # Extract ORACLE_HOME (everything before /bin/oracle)
            if [[ "$exe_path" =~ ^(.+)/bin/oracle$ ]]; then
                oracle_home="${BASH_REMATCH[1]}"
            elif [[ "$exe_path" =~ ^(.+)/bin/asm$ ]]; then
                # Handle ASM processes
                oracle_home="${BASH_REMATCH[1]}"
            fi
        fi
        
        # If we couldn't determine ORACLE_HOME, try ps environment
        if [[ -z "$oracle_home" ]] && [[ -r "/proc/$pid/environ" ]]; then
            oracle_home=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep "^ORACLE_HOME=" | cut -d= -f2)
        fi
        
        # If still no ORACLE_HOME, skip this instance
        if [[ -z "$oracle_home" || ! -d "$oracle_home" ]]; then
            oradba_log WARN "Could not determine ORACLE_HOME for SID: $sid (PID: $pid)"
            continue
        fi
        
        # Output discovered instance in oratab format
        echo "${sid}:${oracle_home}:N"
        seen_sids[$sid]=1
        ((discovered_count++))
        
        oradba_log INFO "Auto-discovered Oracle instance: $sid ($oracle_home)"
        
    done < <(ps -U "$current_user" -o pid,comm --no-headers 2>/dev/null | grep -E "(db_smon_|ora_pmon_|asm_smon_)")
    
    if [[ $discovered_count -gt 0 ]]; then
        oradba_log INFO "Discovered $discovered_count running Oracle instance(s)"
        oradba_log INFO "These are temporary entries - review and add to oratab if needed"
        return 0
    else
        oradba_log DEBUG "No running Oracle instances found for user: $current_user"
        return 1
    fi
}


# Persist discovered instances to oratab
# ------------------------------------------------------------------------------
# Function: persist_discovered_instances
# Purpose.: Write auto-discovered instances to oratab file with fallback
# Args....: $1 - Discovered oratab entries (multi-line string)
#           $2 - Target oratab file (optional, defaults to ORATAB_FILE)
# Returns.: 0 - Successfully persisted
#           1 - Failed to persist
# Output..: Appends entries to oratab, logs warnings/info
# Notes...: - Tries system oratab first (e.g., /etc/oratab)
#           - Falls back to local oratab if permission denied
#           - Checks for duplicates before adding
#           - Updates ORATAB_FILE if fallback used
#           Example: persist_discovered_instances "$discovered_data"
persist_discovered_instances() {
    local discovered_oratab="$1"
    local oratab_file="${2:-${ORATAB_FILE}}"
    
    # Validate input
    if [[ -z "$discovered_oratab" ]]; then
        oradba_log DEBUG "No discovered instances to persist"
        return 1
    fi
    
    # Check if oratab file exists
    if [[ ! -f "$oratab_file" ]]; then
        oradba_log WARN "Oratab file does not exist: $oratab_file"
        # Try to create it if we have permissions
        if ! touch "$oratab_file" 2>/dev/null; then
            oradba_log WARN "Cannot create oratab file: $oratab_file (permission denied)"
            oratab_file="${ORADBA_PREFIX}/etc/oratab"
        fi
    fi
    
    # Try to write to target oratab
    if [[ -w "$oratab_file" ]]; then
        local added_count=0
        
        # Add each discovered instance if not already present
        while IFS=: read -r sid oracle_home startup_flag; do
            [[ -z "$sid" ]] && continue
            
            # Check for duplicate
            if grep -q "^${sid}:" "$oratab_file" 2>/dev/null; then
                oradba_log DEBUG "Instance $sid already in $oratab_file - skipping"
            else
                echo "${sid}:${oracle_home}:${startup_flag}" >> "$oratab_file"
                oradba_log INFO "Added $sid to $oratab_file"
                ((added_count++))
            fi
        done <<< "$discovered_oratab"
        
        if [[ $added_count -gt 0 ]]; then
            oradba_log INFO "Successfully added $added_count instance(s) to $oratab_file"
            return 0
        else
            oradba_log INFO "All discovered instances already exist in $oratab_file"
            return 0
        fi
    else
        # Permission denied - fallback to local oratab
        local local_oratab="${ORADBA_PREFIX}/etc/oratab"
        
        oradba_log WARN "Cannot write to system oratab: $oratab_file (permission denied)"
        oradba_log WARN "Falling back to local oratab: $local_oratab"
        
        # Create local oratab if it doesn't exist
        if [[ ! -f "$local_oratab" ]]; then
            if ! touch "$local_oratab" 2>/dev/null; then
                oradba_log ERROR "Cannot create local oratab: $local_oratab"
                return 1
            fi
            oradba_log INFO "Created local oratab: $local_oratab"
        fi
        
        # Check if local oratab is writable
        if [[ ! -w "$local_oratab" ]]; then
            oradba_log ERROR "Local oratab is not writable: $local_oratab"
            return 1
        fi
        
        local added_count=0
        
        # Add entries to local oratab
        while IFS=: read -r sid oracle_home startup_flag; do
            [[ -z "$sid" ]] && continue
            
            # Check for duplicate
            if grep -q "^${sid}:" "$local_oratab" 2>/dev/null; then
                oradba_log DEBUG "Instance $sid already in local oratab - skipping"
            else
                echo "${sid}:${oracle_home}:${startup_flag}" >> "$local_oratab"
                oradba_log INFO "Added $sid to local oratab: $local_oratab"
                ((added_count++))
            fi
        done <<< "$discovered_oratab"
        
        if [[ $added_count -gt 0 ]]; then
            oradba_log WARN "Added $added_count instance(s) to local oratab"
            oradba_log WARN "ACTION REQUIRED: Manually sync entries from $local_oratab to $oratab_file"
            oradba_log WARN "Suggested command: sudo cat $local_oratab >> $oratab_file"
            
            # Update ORATAB_FILE to point to local version for current session
            export ORATAB_FILE="$local_oratab"
            oradba_log INFO "ORATAB_FILE updated to: $local_oratab (current session only)"
            
            return 0
        else
            oradba_log INFO "All discovered instances already exist in local oratab"
            return 0
        fi
    fi
}
