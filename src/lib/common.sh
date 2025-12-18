#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: common.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: Common library functions for oradba scripts
# Notes......: This library provides reusable functions for logging, validation,
#              Oracle environment management, and configuration parsing.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get the absolute path of the script directory
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# Logging functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Verify Oracle environment variables
verify_oracle_env() {
    local required_vars=("ORACLE_SID" "ORACLE_HOME")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required Oracle environment variables: ${missing_vars[*]}"
        return 1
    fi

    return 0
}

# Get Oracle version
get_oracle_version() {
    if [[ -z "${ORACLE_HOME}" ]]; then
        log_error "ORACLE_HOME not set"
        return 1
    fi

    if [[ -x "${ORACLE_HOME}/bin/sqlplus" ]]; then
        "${ORACLE_HOME}/bin/sqlplus" -version | grep -oP 'Release \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1
    else
        log_error "sqlplus not found in ORACLE_HOME"
        return 1
    fi
}

# Parse oratab file
parse_oratab() {
    local sid="$1"
    local oratab_file="${2:-/etc/oratab}"

    if [[ ! -f "$oratab_file" ]]; then
        log_error "oratab file not found: $oratab_file"
        return 1
    fi

    # Case-insensitive search for SID
    grep -i "^${sid}:" "$oratab_file" | grep -v "^#" | head -1
}

# Generate SID lists and aliases from oratab
# Usage: generate_sid_lists [oratab_file]
generate_sid_lists() {
    local oratab_file="${1:-/etc/oratab}"
    
    # Check if oratab exists
    if [[ ! -f "$oratab_file" ]]; then
        log_debug "oratab file not found: $oratab_file"
        export ORADBA_SIDLIST=""
        export ORADBA_REALSIDLIST=""
        return 1
    fi
    
    local all_sids=""
    local real_sids=""
    
    # Parse oratab, skip comments and empty lines
    while IFS=: read -r sid _oracle_home startup_flag; do
        # Skip empty lines and comments
        [[ -z "$sid" ]] && continue
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        
        # Skip ASM instances (start with +)
        [[ "$sid" =~ ^\+ ]] && continue
        
        # Add to all SIDs list
        all_sids="${all_sids}${all_sids:+ }${sid}"
        
        # Add to real SIDs list if startup flag is Y or N (not D for DGMGRL dummy)
        if [[ "$startup_flag" =~ ^[YyNn] ]]; then
            real_sids="${real_sids}${real_sids:+ }${sid}"
        fi
        
        # Create alias for this SID (lowercase)
        local sid_lower="${sid,,}"
        # shellcheck disable=SC2139
        alias "${sid_lower}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${sid}"
        
    done < <(grep -v "^#" "$oratab_file" | grep -v "^[[:space:]]*$")
    
    # Export the lists
    export ORADBA_SIDLIST="$all_sids"
    export ORADBA_REALSIDLIST="$real_sids"
    
    log_debug "ORADBA_SIDLIST: $ORADBA_SIDLIST"
    log_debug "ORADBA_REALSIDLIST: $ORADBA_REALSIDLIST"
    
    return 0
}

# Usage: generate_pdb_aliases
# Generate aliases for PDBs in the current CDB
generate_pdb_aliases() {
    # Skip if disabled
    if [[ "${ORADBA_NO_PDB_ALIASES}" == "true" ]]; then
        log_debug "PDB aliases disabled (ORADBA_NO_PDB_ALIASES=true)"
        return 0
    fi
    
    # Skip if no database connection
    if ! check_database_connection 2>/dev/null; then
        log_debug "No database connection, skipping PDB alias generation"
        return 0
    fi
    
    # Skip if not a CDB
    local is_cdb
    is_cdb=$(sqlplus -s / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF TIMING OFF TIME OFF SQLPROMPT "" TRIMSPOOL ON TRIMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT cdb FROM v\$database;
EXIT
EOF
)
    
    if [[ "${is_cdb}" != "YES" ]]; then
        log_debug "Not a CDB, skipping PDB alias generation"
        return 0
    fi
    
    # Get list of PDBs
    local pdb_list
    pdb_list=$(sqlplus -s / as sysdba <<EOF
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
        local pdb_lower="${pdb_name,,}"
        
        # Create alias to set ORADBA_PDB and connect
        # shellcheck disable=SC2139
        alias "${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"
        
        # Create alias with 'pdb' prefix for clarity
        # shellcheck disable=SC2139
        alias "pdb${pdb_lower}"="export ORADBA_PDB='${pdb_name}'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=${pdb_name};'"
        
        log_debug "Created PDB alias: ${pdb_lower} -> ${pdb_name}"
    done <<< "$pdb_list"
    
    # Export the PDB list
    export ORADBA_PDBLIST="${pdb_list//$'\n'/ }"
    log_debug "ORADBA_PDBLIST: $ORADBA_PDBLIST"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: load_rman_catalog_connection
# Purpose.: Load and validate RMAN catalog connection string
# Returns.: 0 on success, 1 if no catalog configured
# Notes...: Updates ORADBA_RMAN_CATALOG_CONNECTION for use in aliases
#           Catalog format: catalog user/password@tnsalias
#           or catalog user@tnsalias (prompts for password)
# ------------------------------------------------------------------------------
load_rman_catalog_connection() {
    log_debug "Checking RMAN catalog configuration"
    
    # Check if catalog is configured
    if [[ -z "${ORADBA_RMAN_CATALOG}" ]]; then
        log_debug "No RMAN catalog configured (ORADBA_RMAN_CATALOG not set)"
        export ORADBA_RMAN_CATALOG_CONNECTION=""
        return 1
    fi
    
    # Validate catalog connection string format
    # Expected: user/password@tnsalias or user@tnsalias
    if [[ ! "${ORADBA_RMAN_CATALOG}" =~ ^[a-zA-Z0-9_]+(@|/) ]]; then
        log_warn "Invalid RMAN catalog format: ${ORADBA_RMAN_CATALOG}"
        log_warn "Expected: user/password@tnsalias or user@tnsalias"
        export ORADBA_RMAN_CATALOG_CONNECTION=""
        return 1
    fi
    
    # Build the full catalog connection string for RMAN
    export ORADBA_RMAN_CATALOG_CONNECTION="catalog ${ORADBA_RMAN_CATALOG}"
    log_debug "RMAN catalog connection: ${ORADBA_RMAN_CATALOG_CONNECTION}"
    
    return 0
}

# Export common Oracle environment variables
export_oracle_base_env() {
    # Set common paths if not already set
    export PATH="${ORACLE_HOME}/bin:${PATH}"
    export LD_LIBRARY_PATH="${ORACLE_HOME}/lib:${LD_LIBRARY_PATH:-}"

    # Set TNS_ADMIN if not set
    if [[ -z "${TNS_ADMIN}" ]]; then
        if [[ -d "${ORACLE_HOME}/network/admin" ]]; then
            export TNS_ADMIN="${ORACLE_HOME}/network/admin"
        fi
    fi

    # Set NLS_LANG if not set
    export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.AL32UTF8}"
}

# Validate directory path
validate_directory() {
    local dir="$1"
    local create="${2:-false}"

    if [[ ! -d "$dir" ]]; then
        if [[ "$create" == "true" ]]; then
            mkdir -p "$dir" 2> /dev/null
            if [[ $? -ne 0 ]]; then
                log_error "Failed to create directory: $dir"
                return 1
            fi
            log_info "Created directory: $dir"
        else
            log_error "Directory does not exist: $dir"
            return 1
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Configuration Management
# ------------------------------------------------------------------------------

# Load hierarchical configuration files
# Usage: load_config [ORACLE_SID]
# Loads configuration in order: core -> standard -> customer -> default -> sid-specific
# Later configs override earlier settings
load_config() {
    local sid="${1:-${ORACLE_SID}}"
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    
    log_debug "Loading OraDBA configuration for SID: ${sid:-<none>}"
    
    # Enable auto-export of all variables (set -a)
    # This ensures all variables in config files are exported to environment
    # even if 'export' keyword is forgotten
    set -a
    
    # 1. Load core configuration (required)
    local core_config="${config_dir}/oradba_core.conf"
    if [[ -f "${core_config}" ]]; then
        log_debug "Loading core config: ${core_config}"
        # shellcheck source=/dev/null
        source "${core_config}"
    else
        log_error "Core configuration not found: ${core_config}"
        set +a
        return 1
    fi
    
    # 2. Load standard configuration (required)
    local standard_config="${config_dir}/oradba_standard.conf"
    if [[ -f "${standard_config}" ]]; then
        log_debug "Loading standard config: ${standard_config}"
        # shellcheck source=/dev/null
        source "${standard_config}"
    else
        log_warn "Standard configuration not found: ${standard_config}"
    fi
    
    # 3. Load customer configuration (optional)
    local customer_config="${config_dir}/oradba_customer.conf"
    if [[ -f "${customer_config}" ]]; then
        log_debug "Loading customer config: ${customer_config}"
        # shellcheck source=/dev/null
        source "${customer_config}"
    fi
    
    # 4. Load default SID configuration (optional)
    local default_config="${config_dir}/sid._DEFAULT_.conf"
    if [[ -f "${default_config}" ]]; then
        log_debug "Loading default SID config: ${default_config}"
        # shellcheck source=/dev/null
        source "${default_config}"
    fi
    
    # 5. Load SID-specific configuration (optional)
    if [[ -n "${sid}" ]]; then
        local sid_config="${config_dir}/sid.${sid}.conf"
        if [[ -f "${sid_config}" ]]; then
            log_debug "Loading SID config: ${sid_config}"
            # shellcheck source=/dev/null
            source "${sid_config}"
        else
            log_debug "SID-specific config not found: ${sid_config}"
            
            # Auto-create SID config if enabled
            if [[ "${ORADBA_AUTO_CREATE_SID_CONFIG}" == "true" ]]; then
                create_sid_config "${sid}"
            fi
        fi
    fi
    
    # Disable auto-export (set +a)
    set +a
    
    log_debug "Configuration loading complete"
    return 0
}

# Create SID-specific configuration file with database metadata
# Usage: create_sid_config <ORACLE_SID>
create_sid_config() {
    local sid="$1"
    local config_dir="${ORADBA_CONFIG_DIR:-${ORADBA_PREFIX}/etc}"
    local sid_config="${config_dir}/sid.${sid}.conf"
    local example_config="${config_dir}/sid.ORCL.conf.example"
    
    log_info "Creating SID-specific configuration: ${sid_config}"
    
    # Check if example template exists - use it as base
    if [[ -f "${example_config}" ]]; then
        log_info "Using template: ${example_config}"
        # Copy example and replace ORCL with actual SID
        sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g; s/Date.......: .*/Date.......: $(date '+%Y.%m.%d')/; s/Auto-created on first environment switch/Auto-created: $(date '+%Y-%m-%d %H:%M:%S')/" \
            "${example_config}" > "${sid_config}"
        
        # Source the newly created config
        if [[ -f "${sid_config}" ]]; then
            log_info "Created SID configuration from template: ${sid_config}"
            # shellcheck source=/dev/null
            source "${sid_config}"
            return 0
        fi
    fi
    
    # Fallback: Create config from database metadata or defaults
    log_debug "Template not found, creating from database metadata"
    
    # Initialize variables with defaults
    local db_name="${sid}"
    local db_unique_name="${sid}"
    local dbid=""
    local db_role="PRIMARY"
    local open_mode="READ WRITE"
    local diagnostic_dest="${ORACLE_BASE}/diag/rdbms/${sid,,}/${sid}"
    
    # Check if database is accessible before querying
    local db_accessible=false
    if command -v sqlplus >/dev/null 2>&1; then
        local conn_test
        conn_test=$(sqlplus -S / as sysdba <<'EOF' 2>&1
SET PAGESIZE 0 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL
SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""
SET SERVEROUTPUT OFF TERMOUT ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
SELECT 'OK' FROM dual;
EXIT;
EOF
        )
        if [[ "${conn_test}" == "OK" ]]; then
            db_accessible=true
        fi
    fi
    
    # Query database for metadata only if accessible
    if [[ "${db_accessible}" == "true" ]]; then
        local db_info
        db_info=$(sqlplus -S / as sysdba 2>&1 <<'EOF' | grep -v "^Connected" | grep -v "^Elapsed:" | grep -v "^ERROR:" | grep -v "^SP2-" | grep -v "^ORA-" | grep -v "^Help:" | grep -v "^Usage:" | grep -v "^where" | tr -d '\n'
SET PAGESIZE 0 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL
SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""
SET SERVEROUTPUT OFF TERMOUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT SQL.SQLCODE
SELECT 
    name || '|' || 
    db_unique_name || '|' || 
    dbid || '|' || 
    database_role || '|' || 
    open_mode
FROM v$database;
EXIT;
EOF
        )
        
        local diag_dest_query
        diag_dest_query=$(sqlplus -S / as sysdba <<'EOF' 2>&1 | grep -v "^Connected" | grep -v "^Elapsed:" | grep -v "^ERROR:" | grep -v "^SP2-" | grep -v "^ORA-" | tr -d '\n'
SET PAGESIZE 0 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL
SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""
SET SERVEROUTPUT OFF TERMOUT ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
SELECT value FROM v$parameter WHERE name = 'diagnostic_dest';
EXIT;
EOF
        )
        
        # Parse database info only if query succeeded (contains pipe separator)
        if [[ "${db_info}" == *"|"* ]]; then
            IFS='|' read -r db_name db_unique_name dbid db_role open_mode <<< "${db_info}"
            # Clean up values
            db_name=$(echo "${db_name}" | tr -d '[:space:]')
            db_unique_name=$(echo "${db_unique_name}" | tr -d '[:space:]')
            dbid=$(echo "${dbid}" | tr -d '[:space:]')
            db_role=$(echo "${db_role}" | tr -d '[:space:]')
            open_mode=$(echo "${open_mode}" | tr -d '[:space:]')
        fi
        
        # Update diagnostic_dest if query succeeded (check for errors and minimum length)
        if [[ -n "${diag_dest_query}" ]] && [[ "${diag_dest_query}" != *"ERROR"* ]] && [[ "${diag_dest_query}" != *"ORA-"* ]] && [[ "${diag_dest_query}" != *"SP2-"* ]] && [[ ${#diag_dest_query} -gt 5 ]]; then
            diagnostic_dest=$(echo "${diag_dest_query}" | tr -d '[:space:]')
        fi
    else
        log_warn "Database not accessible, using default values for SID configuration"
    fi
    
    # Create configuration file
    cat > "${sid_config}" <<EOF
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: sid.${sid}.conf
# Auto-created: $(date '+%Y-%m-%d %H:%M:%S')
# Purpose....: SID-specific configuration for ${sid} database
# Notes......: Auto-generated from database metadata. Customize as needed.
# ------------------------------------------------------------------------------

# Database Identity (from v\$database)
# Only set if successfully retrieved from database
EOF

    # Only add database metadata if successfully retrieved (no errors)
    if [[ -n "${db_name}" ]] && [[ "${db_name}" != "ERROR:"* ]] && [[ "${db_name}" != *"ORA-"* ]]; then
        cat >> "${sid_config}" <<EOF
ORADBA_DB_NAME="${db_name}"
EOF
    fi
    
    if [[ -n "${db_unique_name}" ]] && [[ "${db_unique_name}" != "ERROR:"* ]] && [[ "${db_unique_name}" != *"ORA-"* ]]; then
        cat >> "${sid_config}" <<EOF
ORADBA_DB_UNIQUE_NAME="${db_unique_name}"
EOF
    fi
    
    if [[ -n "${dbid}" ]] && [[ "${dbid}" != "ERROR:"* ]] && [[ "${dbid}" != *"ORA-"* ]]; then
        cat >> "${sid_config}" <<EOF
ORADBA_DBID="${dbid}"
EOF
    fi
    
    # Only set role/mode if not default values (to keep config clean)
    if [[ -n "${db_role}" ]] && [[ "${db_role}" != "PRIMARY" ]] && [[ "${db_role}" != "ERROR:"* ]]; then
        cat >> "${sid_config}" <<EOF
ORADBA_DB_ROLE="${db_role}"
EOF
    fi
    
    if [[ -n "${open_mode}" ]] && [[ "${open_mode}" != "READ WRITE" ]] && [[ "${open_mode}" != "READWRITE" ]] && [[ "${open_mode}" != "ERROR:"* ]]; then
        cat >> "${sid_config}" <<EOF
ORADBA_DB_OPEN_MODE="${open_mode}"
EOF
    fi
    
    # Only set diagnostic dest if successfully retrieved
    if [[ -n "${diagnostic_dest}" ]] && [[ "${diagnostic_dest}" != "ERROR:"* ]] && [[ "${diagnostic_dest}" != *"ORA-"* ]] && [[ "${diagnostic_dest}" != *"SP2-"* ]]; then
        cat >> "${sid_config}" <<EOF

# Diagnostic destination (from v\$parameter)
ORADBA_DIAGNOSTIC_DEST="${diagnostic_dest}"
EOF
    fi
    
    # Add NLS and backup settings
    cat >> "${sid_config}" <<EOF

# NLS Settings (customize if needed)
# NLS_LANG="${NLS_LANG}"
# NLS_DATE_FORMAT="${NLS_DATE_FORMAT}"

# Backup settings (customize as needed)
# ORADBA_DB_BACKUP_DIR="${ORACLE_BASE}/backup/${sid}"
# ORADBA_BACKUP_RETENTION=7
EOF
    
    if [[ -f "${sid_config}" ]]; then
        log_info "Created SID configuration: ${sid_config}"
        # Source the newly created config
        # shellcheck source=/dev/null
        source "${sid_config}"
        return 0
    else
        log_error "Failed to create SID configuration: ${sid_config}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Version Management Functions
# ------------------------------------------------------------------------------

# Get OraDBA version from VERSION file
get_oradba_version() {
    local version_file="${ORADBA_BASE}/VERSION"
    
    if [[ -f "${version_file}" ]]; then
        cat "${version_file}" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

# Compare two semantic versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
version_compare() {
    local v1="$1"
    local v2="$2"
    
    # Remove leading 'v' if present
    v1="${v1#v}"
    v2="${v2#v}"
    
    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # Compare each component
    for i in {0..2}; do
        local part1="${v1_parts[$i]:-0}"
        local part2="${v2_parts[$i]:-0}"
        
        # Remove any non-numeric suffix (e.g., "1-beta")
        part1="${part1%%-*}"
        part2="${part2%%-*}"
        
        if (( part1 > part2 )); then
            return 1
        elif (( part1 < part2 )); then
            return 2
        fi
    done
    
    return 0
}

# Check if version meets minimum requirement
# Usage: version_meets_requirement "0.6.1" "0.6.0"
version_meets_requirement() {
    local current_version="$1"
    local required_version="$2"
    
    version_compare "$current_version" "$required_version"
    local result=$?
    
    # Returns 0 (equal) or 1 (greater) means requirement is met
    [[ $result -eq 0 || $result -eq 1 ]]
}

# Get installation metadata
# Supports both old format (install_version) and new format (version)
get_install_info() {
    local key="$1"
    local install_info="${ORADBA_BASE}/.install_info"
    
    if [[ -f "${install_info}" ]]; then
        # Try to get value, handle both with and without quotes
        local value
        value=$(grep "^${key}=" "${install_info}" | cut -d= -f2- | sed 's/^"//;s/"$//')
        echo "${value}"
    fi
}

# Set installation metadata
# Uses lowercase keys without quotes for consistency with installer
set_install_info() {
    local key="$1"
    local value="$2"
    local install_info="${ORADBA_BASE}/.install_info"
    
    # Create or update key
    if [[ -f "${install_info}" ]]; then
        # Update existing key or append
        if grep -q "^${key}=" "${install_info}"; then
            sed -i.bak "s|^${key}=.*|${key}=${value}|" "${install_info}"
            rm -f "${install_info}.bak"
        else
            echo "${key}=${value}" >> "${install_info}"
        fi
    else
        # Create new file
        mkdir -p "$(dirname "${install_info}")"
        echo "${key}=${value}" > "${install_info}"
    fi
}

# Initialize installation info file
# Uses lowercase keys without quotes to match installer format
init_install_info() {
    local version="$1"
    local install_info="${ORADBA_BASE}/.install_info"
    
    cat > "${install_info}" <<EOF
install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
install_version=${version}
install_method=installer
install_user=${USER}
install_prefix=${ORADBA_BASE}
EOF
    
    log_info "Created installation metadata: ${install_info}"
}

# ------------------------------------------------------------------------------
# SQLPATH Management Functions (#11)
# ------------------------------------------------------------------------------

# Configure SQLPATH for SQL*Plus script discovery
# Usage: configure_sqlpath
# Builds SQLPATH with priority:
#   1. Current directory (pwd)
#   2. OraDBA SQL scripts
#   3. SID-specific SQL directory (if exists)
#   4. Oracle RDBMS admin scripts
#   5. Oracle sqlplus admin scripts
#   6. User custom SQL directory
#   7. Custom SQLPATH from config
#   8. Existing SQLPATH entries (if preserve enabled)
configure_sqlpath() {
    local sqlpath_parts=()
    
    # 1. Current directory (standard Oracle behavior)
    sqlpath_parts+=(".")
    
    # 2. OraDBA SQL scripts
    if [[ -d "${ORADBA_PREFIX}/sql" ]]; then
        sqlpath_parts+=("${ORADBA_PREFIX}/sql")
    fi
    
    # 3. SID-specific SQL directory (if exists and enabled)
    if [[ "${ORADBA_SID_SPECIFIC_SQL}" == "true" ]] && [[ -n "${ORACLE_SID}" ]] && [[ -d "${ORADBA_PREFIX}/sql/${ORACLE_SID}" ]]; then
        sqlpath_parts+=("${ORADBA_PREFIX}/sql/${ORACLE_SID}")
    fi
    
    # 4. Oracle RDBMS admin scripts (catproc.sql, etc.)
    if [[ -n "${ORACLE_HOME}" ]] && [[ -d "${ORACLE_HOME}/rdbms/admin" ]]; then
        sqlpath_parts+=("${ORACLE_HOME}/rdbms/admin")
    fi
    
    # 5. Oracle sqlplus admin scripts
    if [[ -n "${ORACLE_HOME}" ]] && [[ -d "${ORACLE_HOME}/sqlplus/admin" ]]; then
        sqlpath_parts+=("${ORACLE_HOME}/sqlplus/admin")
    fi
    
    # 6. User custom SQL directory (create if needed)
    if [[ "${ORADBA_CREATE_USER_SQL_DIR}" == "true" ]] && [[ ! -d "${HOME}/.oradba/sql" ]]; then
        mkdir -p "${HOME}/.oradba/sql" 2>/dev/null && log_debug "Created user SQL directory: ${HOME}/.oradba/sql"
    fi
    if [[ -d "${HOME}/.oradba/sql" ]]; then
        sqlpath_parts+=("${HOME}/.oradba/sql")
    fi
    
    # 7. Custom SQLPATH from config (append)
    if [[ -n "${ORADBA_CUSTOM_SQLPATH}" ]]; then
        IFS=':' read -ra custom_paths <<< "${ORADBA_CUSTOM_SQLPATH}"
        sqlpath_parts+=("${custom_paths[@]}")
    fi
    
    # 8. Preserve existing SQLPATH entries (optional)
    if [[ -n "${SQLPATH}" ]] && [[ "${ORADBA_PRESERVE_SQLPATH}" == "true" ]]; then
        IFS=':' read -ra existing_paths <<< "${SQLPATH}"
        sqlpath_parts+=("${existing_paths[@]}")
    fi
    
    # Build colon-separated SQLPATH, removing duplicates while preserving order
    SQLPATH=$(printf "%s\n" "${sqlpath_parts[@]}" | awk '!seen[$0]++' | paste -sd:)
    export SQLPATH
    
    log_debug "SQLPATH configured: ${SQLPATH}"
}

# Display current SQLPATH directories
# Usage: show_sqlpath
show_sqlpath() {
    if [[ -z "${SQLPATH}" ]]; then
        echo "SQLPATH is not set"
        return 1
    fi
    
    echo "SQLPATH Directories:"
    echo "==================="
    local count=1
    IFS=':' read -ra paths <<< "${SQLPATH}"
    for path in "${paths[@]}"; do
        if [[ -d "${path}" ]]; then
            printf "%2d. %-60s [✓]\n" "${count}" "${path}"
        else
            printf "%2d. %-60s [✗ not found]\n" "${count}" "${path}"
        fi
        ((count++))
    done
}

# Add directory to SQLPATH
# Usage: add_to_sqlpath <directory>
add_to_sqlpath() {
    local new_path="${1}"
    
    if [[ -z "${new_path}" ]]; then
        log_error "Directory path required"
        return 1
    fi
    
    if [[ ! -d "${new_path}" ]]; then
        log_error "Directory does not exist: ${new_path}"
        return 1
    fi
    
    # Check if already in SQLPATH
    if [[ ":${SQLPATH}:" == *":${new_path}:"* ]]; then
        log_info "Directory already in SQLPATH: ${new_path}"
        return 0
    fi
    
    # Add to SQLPATH
    if [[ -z "${SQLPATH}" ]]; then
        export SQLPATH="${new_path}"
    else
        export SQLPATH="${SQLPATH}:${new_path}"
    fi
    
    log_info "Added to SQLPATH: ${new_path}"
}

# Show version information
show_version_info() {
    local version
    version=$(get_oradba_version)
    
    echo "OraDBA Version: ${version}"
    
    if [[ -f "${ORADBA_BASE}/.install_info" ]]; then
        echo ""
        echo "Installation Details:"
        echo "  Installed: $(get_install_info "install_date")"
        echo "  Method: $(get_install_info "install_method")"
        echo "  User: $(get_install_info "install_user")"
        echo "  Prefix: $(get_install_info "install_prefix")"
    fi
}
