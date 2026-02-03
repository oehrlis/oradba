#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_parser.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-14
# Revision...: 0.19.0
# Purpose....: Parse configuration files (oratab, oradba_homes.conf)
# Notes......: Part of Phase 1 implementation for oradba environment management
#              Implements parsing functions for Oracle environment discovery
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_PARSER_LOADED}" ]] && return 0
readonly ORADBA_ENV_PARSER_LOADED=1

# ------------------------------------------------------------------------------
# Dependency Injection Infrastructure (Phase 4)
# ------------------------------------------------------------------------------

# Associative array for storing dependencies (logger function reference)
# Note: Bash 3.x doesn't support associative arrays, so we use global variables
declare ORADBA_PARSER_LOGGER="${ORADBA_PARSER_LOGGER:-}"

# ------------------------------------------------------------------------------
# Function: oradba_parser_init
# Purpose.: Initialize parser library with optional dependency injection
# Args....: $1 - Logger function name (optional, defaults to "oradba_log")
# Returns.: 0 on success
# Output..: None
# Notes...: Call this function before using parser functions if you want to inject
#           a custom logger. If not called, parser works standalone without logging.
# ------------------------------------------------------------------------------
oradba_parser_init() {
    local logger="${1:-}"
    
    # Store logger function reference
    ORADBA_PARSER_LOGGER="$logger"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: _oradba_parser_log
# Purpose.: Internal logging function that uses injected logger or no-op
# Args....: $1 - Log level (DEBUG, INFO, WARN, ERROR)
#          $@ - Log message
# Returns.: 0 on success
# Output..: None (delegates to injected logger)
# Notes...: Internal use only. Prefix with underscore to indicate private.
# ------------------------------------------------------------------------------
_oradba_parser_log() {
    # If no logger is configured, no-op (silent)
    [[ -z "$ORADBA_PARSER_LOGGER" ]] && return 0
    
    # Call injected logger function
    "$ORADBA_PARSER_LOGGER" "$@"
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_parse_oratab
# Purpose.: Parse /etc/oratab file and find SID entry
# Args....: $1 - SID to find (optional, if empty returns all)
# Returns.: 0 on success, 1 on error
# Output..: Format: SID|ORACLE_HOME|FLAG
# ------------------------------------------------------------------------------
oradba_parse_oratab() {
    local target_sid="$1"
    local oratab_file="${ORATAB_FILE:-/etc/oratab}"
    
    # Check if oratab exists
    if [[ ! -f "$oratab_file" ]]; then
        return 1
    fi
    
    # Parse oratab
    while IFS=: read -r sid oracle_home flag _remainder; do
        # Skip comments and empty lines
        [[ -z "$sid" ]] && continue
        [[ "$sid" =~ ^[[:space:]]*# ]] && continue
        
        # Skip if no HOME specified
        [[ -z "$oracle_home" ]] && continue
        
        # If looking for specific SID (case-insensitive for convenience)
        if [[ -n "$target_sid" ]]; then
            # Convert both to uppercase for comparison
            local sid_upper="${sid^^}"
            local target_upper="${target_sid^^}"
            if [[ "$sid_upper" == "$target_upper" ]]; then
                echo "${sid}|${oracle_home}|${flag:-N}"
                return 0
            fi
        else
            # Return all entries
            echo "${sid}|${oracle_home}|${flag:-N}"
        fi
    done < "$oratab_file"
    
    # If looking for specific SID and not found
    [[ -n "$target_sid" ]] && return 1
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_parse_homes
# Purpose.: Parse oradba_homes.conf file
# Args....: $1 - oradba_homes.conf file path (optional, defaults to ${ORADBA_BASE}/etc/oradba_homes.conf)
#          $2 - NAME or ALIAS to find (optional, if empty returns all)
# Returns.: 0 on success, 1 on error
# Output..: Format: NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION
# Notes...: Format matches actual file: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
# ------------------------------------------------------------------------------
oradba_parse_homes() {
    local homes_file="$1"
    local target_name="$2"
    
    # Default to standard location if not provided
    if [[ -z "$homes_file" ]] || [[ ! -f "$homes_file" ]]; then
        homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    fi
    
    # Check if file exists
    if [[ ! -f "$homes_file" ]]; then
        return 1
    fi
    
    # Parse homes file
    # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
    while IFS=':' read -r name path ptype order alias_name desc version; do
        # Skip comments and empty lines
        [[ -z "$name" ]] && continue
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        name=$(echo "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        path=$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        ptype=$(echo "$ptype" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        order=$(echo "$order" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        alias_name=$(echo "$alias_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        desc=$(echo "$desc" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        version=$(echo "$version" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Set defaults for optional fields
        [[ -z "$order" ]] && order="50"
        [[ -z "$alias_name" ]] && alias_name="$name"
        [[ -z "$version" ]] && version="AUTO"
        
        # If looking for specific home by NAME or ALIAS
        if [[ -n "$target_name" ]]; then
            if [[ "$name" == "$target_name" ]] || [[ "$alias_name" == "$target_name" ]]; then
                echo "${name}|${path}|${ptype}|${order}|${alias_name}|${desc}|${version}"
                return 0
            fi
        else
            # Return all entries
            echo "${name}|${path}|${ptype}|${order}|${alias_name}|${desc}|${version}"
        fi
    done < "$homes_file"
    
    # If looking for specific home and not found
    [[ -n "$target_name" ]] && return 1
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_find_sid
# Purpose.: Find SID in oratab and return entry
# Args....: $1 - SID to find
# Returns.: 0 on success, 1 if not found
# Output..: SID|ORACLE_HOME|FLAG
# ------------------------------------------------------------------------------
oradba_find_sid() {
    local sid="$1"
    
    if [[ -z "$sid" ]]; then
        return 1
    fi
    
    oradba_parse_oratab "$sid"
}

# ------------------------------------------------------------------------------
# Function: oradba_find_home
# Purpose.: Find Oracle Home by NAME, ALIAS, or PATH in oradba_homes.conf
# Args....: $1 - NAME, ALIAS, or PATH to find
#          $2 - oradba_homes.conf file path (optional)
# Returns.: 0 on success, 1 if not found
# Output..: NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION
# ------------------------------------------------------------------------------
oradba_find_home() {
    local search_term="$1"
    local homes_file="$2"
    
    if [[ -z "$search_term" ]]; then
        return 1
    fi
    
    # Try as NAME/ALIAS first
    local result
    result=$(oradba_parse_homes "$homes_file" "$search_term")
    if [[ -n "$result" ]]; then
        echo "$result"
        return 0
    fi
    
    # Try as PATH
    local homes_file_path="${homes_file:-${ORADBA_BASE}/etc/oradba_homes.conf}"
    [[ ! -f "$homes_file_path" ]] && return 1
    
    while IFS=':' read -r name path ptype order alias_name desc version; do
        [[ -z "$name" ]] && continue
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        
        path=$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        if [[ "$path" == "$search_term" ]]; then
            # Trim and set defaults
            name=$(echo "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            ptype=$(echo "$ptype" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            order=$(echo "$order" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            alias_name=$(echo "$alias_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            desc=$(echo "$desc" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            version=$(echo "$version" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [[ -z "$order" ]] && order="50"
            [[ -z "$alias_name" ]] && alias_name="$name"
            [[ -z "$version" ]] && version="AUTO"
            echo "${name}|${path}|${ptype}|${order}|${alias_name}|${desc}|${version}"
            return 0
        fi
    done < "$homes_file_path"
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_get_home_metadata
# Purpose.: Get Oracle Home metadata from oradba_homes.conf
# Args....: $1 - ORACLE_HOME path
#          $2 - Field name (Product|Version|Edition|DB_Type|Position|Dummy_SID|Short_Name|Description)
#          $3 - oradba_homes.conf file path (optional)
# Returns.: 0 on success, 1 if not found
# Output..: Field value
# ------------------------------------------------------------------------------
oradba_get_home_metadata() {
    local oracle_home="$1"
    local field="$2"
    local homes_file="$3"
    
    if [[ -z "$oracle_home" ]] || [[ -z "$field" ]]; then
        return 1
    fi
    
    # Parse the home entry
    local entry
    entry=$(oradba_find_home "$oracle_home" "$homes_file") || return 1
    
    # Split entry into fields (Format: NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION)
    IFS='|' read -r name path ptype order alias_name description version <<< "$entry"
    
    # Return requested field (with backward compatibility for old names)
    case "$field" in
        Name|Short_Name) echo "$name" ;;
        Path)            echo "$path" ;;
        Type|Product)    echo "$ptype" ;;
        Order|Position)  echo "$order" ;;
        Alias|Dummy_SID) echo "$alias_name" ;;
        Description)     echo "$description" ;;
        Version)         echo "$version" ;;
        *)               echo "N/A"; return 0 ;;
    esac
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_list_all_sids
# Purpose.: List all available SIDs from oratab
# Returns.: 0 on success
# Output..: One SID per line
# ------------------------------------------------------------------------------
oradba_list_all_sids() {
    oradba_parse_oratab | cut -d'|' -f1
}

# ------------------------------------------------------------------------------
# Function: oradba_list_all_homes
# Purpose.: List all Oracle Homes from oradba_homes.conf, sorted by order
# Args....: $1 - oradba_homes.conf file path (optional)
# Returns.: 0 on success
# Output..: Format: NAME|PATH|TYPE|ORDER|ALIAS (sorted by order)
# ------------------------------------------------------------------------------
oradba_list_all_homes() {
    local homes_file="$1"
    
    # Parse and sort by order (field 4)
    oradba_parse_homes "$homes_file" | sort -t'|' -k4 -n | while IFS='|' read -r name path ptype order alias_name desc version; do
        echo "${name}|${path}|${ptype}|${order}|${alias_name}"
    done
}

# ------------------------------------------------------------------------------
# Function: oradba_get_product_type
# Purpose.: Determine product type for an Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if cannot determine
# Output..: Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS)
# ------------------------------------------------------------------------------
oradba_get_product_type() {
    local oracle_home="$1"
    
    [[ -z "$oracle_home" ]] && return 1
    [[ ! -d "$oracle_home" ]] && return 1
    
    # First check oradba_homes.conf
    local product
    product=$(oradba_get_home_metadata "$oracle_home" "Type" 2>/dev/null)
    if [[ -n "$product" ]] && [[ "$product" != "N/A" ]]; then
        # Convert to uppercase for consistency
        echo "${product^^}"
        return 0
    fi
    
    # Auto-detect based on directory structure
    # Check for Instant Client (libraries without bin directory, or with libclntsh in root)
    if [[ -f "${oracle_home}/libclntsh.so" ]] || [[ -f "${oracle_home}/libclntsh.dylib" ]]; then
        echo "ICLIENT"
        return 0
    fi
    # Check for versioned libclntsh (e.g., libclntsh.so.19.1)
    if ls "${oracle_home}"/libclntsh.so.* &>/dev/null; then
        echo "ICLIENT"
        return 0
    fi
    
    # Check for lib/lib64 without bin (older Instant Client style)
    if [[ -d "${oracle_home}/lib" ]] || [[ -d "${oracle_home}/lib64" ]]; then
        if [[ ! -d "${oracle_home}/bin" ]]; then
            # Check for actual Oracle client libraries
            if ls "${oracle_home}"/lib*/libclntsh* &>/dev/null; then
                echo "ICLIENT"
                return 0
            fi
        fi
    fi
    
    # Check for full RDBMS installation BEFORE Grid
    # (database homes may include asmcmd for ASM support)
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ -d "${oracle_home}/rdbms" ]]; then
        echo "RDBMS"
        return 0
    fi
    
    # Check for Grid Infrastructure (use Grid-specific binaries only)
    # Note: asmcmd is also in database homes, so check for ocrcheck or crsctl
    if [[ -f "${oracle_home}/bin/ocrcheck" ]] || [[ -f "${oracle_home}/bin/crsctl" ]]; then
        echo "GRID"
        return 0
    fi
    
    # Check for Oracle Client
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ ! -d "${oracle_home}/rdbms" ]]; then
        echo "CLIENT"
        return 0
    fi
    
    # Check for Oracle Unified Directory
    if [[ -d "${oracle_home}/oud" ]] || [[ -f "${oracle_home}/bin/oud-setup" ]]; then
        echo "OUD"
        return 0
    fi
    
    # Check for WebLogic
    if [[ -d "${oracle_home}/wlserver" ]] || [[ -f "${oracle_home}/bin/startWebLogic.sh" ]]; then
        echo "WLS"
        return 0
    fi
    
    # Check for DataSafe (On-Premises Connector structure)
    # DataSafe connectors have oracle_cman_home subdirectory
    if [[ -d "${oracle_home}/oracle_cman_home" ]] && [[ -f "${oracle_home}/setup.py" ]]; then
        echo "DATASAFE"
        return 0
    fi
    if [[ -d "${oracle_home}/datasafe" ]] || [[ -f "${oracle_home}/bin/datasafe" ]]; then
        echo "DATASAFE"
        return 0
    fi
    
    # Cannot determine
    return 1
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
