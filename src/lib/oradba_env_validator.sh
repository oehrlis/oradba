#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_validator.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-14
# Revision...: 0.19.0
# Purpose....: Validate Oracle environment
# Notes......: Part of Phase 1 implementation for oradba environment management
#              Provides product-specific validation functions
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_VALIDATOR_LOADED}" ]] && return 0
readonly ORADBA_ENV_VALIDATOR_LOADED=1

# ------------------------------------------------------------------------------
# Function: oradba_validate_oracle_home
# Purpose.: Check if ORACLE_HOME exists and is valid
# Args....: $1 - ORACLE_HOME (optional, uses $ORACLE_HOME if not provided)
# Returns.: 0 if valid, 1 if not
# ------------------------------------------------------------------------------
# shellcheck disable=SC2120  # Optional argument pattern
oradba_validate_oracle_home() {
    local oracle_home="${1:-${ORACLE_HOME}}"
    
    [[ -z "$oracle_home" ]] && return 1
    [[ ! -d "$oracle_home" ]] && return 1
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_validate_sid
# Purpose.: Check if SID is valid format
# Args....: $1 - SID
# Returns.: 0 if valid, 1 if not
# ------------------------------------------------------------------------------
oradba_validate_sid() {
    local sid="$1"
    
    [[ -z "$sid" ]] && return 1
    
    # SID must start with letter or +ASM
    [[ "$sid" =~ ^[a-zA-Z+] ]] || return 1
    
    # SID can contain alphanumeric and underscore
    [[ "$sid" =~ ^[a-zA-Z+][a-zA-Z0-9_]*$ ]] || return 1
    
    # SID length (typically max 8 chars for old Oracle, but allow longer)
    [[ ${#sid} -le 30 ]] || return 1
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_check_oracle_binaries
# Purpose.: Verify critical Oracle binaries exist
# Args....: $1 - Product type
# Returns.: 0 if all found, 1 if any missing
# Output..: Error messages for missing binaries
# ------------------------------------------------------------------------------
oradba_check_oracle_binaries() {
    local product_type="${1:-RDBMS}"
    local missing=0
    
    case "$product_type" in
        RDBMS)
            # Database binaries
            local binaries=("sqlplus" "tnsping" "lsnrctl")
            for bin in "${binaries[@]}"; do
                if ! command -v "$bin" &> /dev/null; then
                    echo "WARNING: $bin not found in PATH" >&2
                    ((missing++))
                fi
            done
            ;;
            
        CLIENT)
            # Full client binaries
            local binaries=("sqlplus" "tnsping")
            for bin in "${binaries[@]}"; do
                if ! command -v "$bin" &> /dev/null; then
                    echo "WARNING: $bin not found in PATH" >&2
                    ((missing++))
                fi
            done
            ;;
            
        ICLIENT)
            # Instant Client: Check for sqlplus and libraries
            if ! command -v sqlplus &> /dev/null; then
                echo "WARNING: sqlplus not found" >&2
                ((missing++))
            fi
            
            # Check for libraries
            if [[ -z "${LD_LIBRARY_PATH}" ]]; then
                echo "WARNING: LD_LIBRARY_PATH not set" >&2
                ((missing++))
            fi
            ;;
            
        GRID)
            # Grid Infrastructure binaries
            local binaries=("crsctl" "asmcmd" "srvctl")
            for bin in "${binaries[@]}"; do
                if ! command -v "$bin" &> /dev/null; then
                    echo "WARNING: $bin not found in PATH" >&2
                    ((missing++))
                fi
            done
            ;;
            
        DATASAFE)
            # DataSafe: Check for setup.py and python
            if [[ -n "$ORACLE_HOME" ]] && [[ -f "${ORACLE_HOME}/setup.py" ]]; then
                if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
                    echo "WARNING: python not found (needed for DataSafe connector management)" >&2
                    ((missing++))
                fi
            fi
            # DataSafe doesn't have sqlplus - skip that check
            ;;
    esac
    
    [[ $missing -eq 0 ]] && return 0
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_check_db_running
# Purpose.: Check if database is running
# Args....: $1 - SID (optional, uses $ORACLE_SID if not provided)
# Returns.: 0 if running, 1 if not
# ------------------------------------------------------------------------------
oradba_check_db_running() {
    local sid="${1:-${ORACLE_SID}}"
    
    [[ -z "$sid" ]] && return 1
    
    # Check for pmon process
    if pgrep -f "ora_pmon_${sid}" &> /dev/null; then
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_get_db_version
# Purpose.: Detect Oracle version from sqlplus
# Args....: None (uses current environment)
# Returns.: 0 on success
# Output..: Version string (e.g., "19.0.0.0.0")
# ------------------------------------------------------------------------------
oradba_get_db_version() {
    if ! command -v sqlplus &> /dev/null; then
        return 1
    fi
    
    # Get version from sqlplus -V
    local version
    version=$(sqlplus -V 2>/dev/null | grep -o "Release [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | cut -d' ' -f2)
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_get_db_status
# Purpose.: Get database open mode
# Args....: None (uses current environment)
# Returns.: 0 on success
# Output..: Status (OPEN|MOUNTED|NOMOUNT|DOWN)
# ------------------------------------------------------------------------------
oradba_get_db_status() {
    [[ -z "$ORACLE_SID" ]] && echo "DOWN" && return 1
    
    # Check if database is running
    if ! oradba_check_db_running "$ORACLE_SID"; then
        echo "DOWN"
        return 1
    fi
    
    # Query database status
    if command -v sqlplus &> /dev/null; then
        local status
        status=$(sqlplus -s / as sysdba <<EOF 2>/dev/null
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT status FROM v\$instance;
EXIT;
EOF
)
        status=$(echo "$status" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
        
        case "$status" in
            OPEN|MOUNTED|STARTED)
                echo "$status"
                return 0
                ;;
        esac
    fi
    
    # If we can't determine, assume NOMOUNT if pmon is running
    echo "NOMOUNT"
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_validate_environment
# Purpose.: Comprehensive environment validation
# Args....: $1 - Validation level (basic|standard|full) default: standard
# Returns.: 0 if valid, 1 if issues found
# Output..: Validation messages
# ------------------------------------------------------------------------------
oradba_validate_environment() {
    local level="${1:-standard}"
    local errors=0
    local warnings=0
    local product_type="${ORADBA_PRODUCT_TYPE:-RDBMS}"
    
    echo "Validating Oracle environment..."
    echo "Product Type: $product_type"
    echo ""
    
    # Level 1: Basic validation (always performed)
    echo "=== Basic Validation ==="
    
    # Check ORACLE_HOME
    if oradba_validate_oracle_home; then
        echo "✓ ORACLE_HOME is valid: $ORACLE_HOME"
    else
        echo "✗ ERROR: ORACLE_HOME is not valid" >&2
        ((errors++))
        return 1
    fi
    
    # Check ORACLE_SID format
    if [[ -n "$ORACLE_SID" ]]; then
        if oradba_validate_sid "$ORACLE_SID"; then
            echo "✓ ORACLE_SID is valid: $ORACLE_SID"
        else
            echo "✗ ERROR: ORACLE_SID format is invalid" >&2
            ((errors++))
        fi
    fi
    
    # Check PATH
    if [[ "$PATH" =~ $ORACLE_HOME ]]; then
        echo "✓ ORACLE_HOME is in PATH"
    else
        echo "⚠ WARNING: ORACLE_HOME not in PATH" >&2
        ((warnings++))
    fi
    
    # Level 2: Standard validation (check binaries and basic functionality)
    if [[ "$level" == "standard" ]] || [[ "$level" == "full" ]]; then
        echo ""
        echo "=== Standard Validation ==="
        
        # Product-specific binary checks
        if oradba_check_oracle_binaries "$product_type"; then
            echo "✓ All required binaries found"
        else
            ((warnings++))
        fi
        
        # Version detection for RDBMS/CLIENT/ICLIENT
        if [[ "$product_type" =~ ^(RDBMS|CLIENT|ICLIENT)$ ]]; then
            local version
            version=$(oradba_get_db_version)
            if [[ -n "$version" ]]; then
                echo "✓ Oracle version: $version"
            else
                echo "⚠ WARNING: Could not detect Oracle version" >&2
                ((warnings++))
            fi
        fi
        
        # Check Grid status for GRID product type
        if [[ "$product_type" == "GRID" ]]; then
            if command -v crsctl &> /dev/null; then
                if crsctl check crs &> /dev/null 2>&1; then
                    echo "✓ Grid Infrastructure is running"
                else
                    echo "⚠ WARNING: Grid Infrastructure is not running" >&2
                    ((warnings++))
                fi
            fi
        fi
    fi
    
    # Level 3: Full validation (RDBMS-specific database connectivity)
    if [[ "$level" == "full" ]] && [[ "$product_type" == "RDBMS" ]]; then
        echo ""
        echo "=== Full Validation ==="
        
        # Check if database is running
        if oradba_check_db_running "$ORACLE_SID"; then
            echo "✓ Database process is running"
            
            # Check database status
            local db_status
            db_status=$(oradba_get_db_status)
            case "$db_status" in
                OPEN)
                    echo "✓ Database is OPEN and accessible"
                    ;;
                MOUNTED)
                    echo "⚠ Database is MOUNTED" >&2
                    ((warnings++))
                    ;;
                NOMOUNT)
                    echo "⚠ WARNING: Database is in NOMOUNT state" >&2
                    ((warnings++))
                    ;;
                DOWN)
                    echo "⚠ WARNING: Database is not running" >&2
                    ((warnings++))
                    ;;
            esac
        else
            echo "⚠ INFO: Database is not running" >&2
        fi
    fi
    
    echo ""
    echo "=== Summary ==="
    echo "Errors: $errors, Warnings: $warnings"
    
    [[ $errors -eq 0 ]] && return 0
    return 1
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
