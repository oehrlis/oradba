#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_home_discovery.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.03.23
# Revision...: 0.21.0
# Purpose....: Oracle Home discovery and management functions
# Notes......: Extracted from oradba_common.sh for cohesion.
#              Requires: oradba_common.sh core functions
#              (oradba_log, execute_plugin_function_v2, validate_directory)
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_HOME_DISCOVERY_LOADED:-}" ]] && return 0
readonly ORADBA_HOME_DISCOVERY_LOADED=1


# ------------------------------------------------------------------------------
# Function: generate_oracle_home_aliases
# Purpose.: Create shell aliases for all registered Oracle Homes
# Args....: None
# Returns.: 0 on success
# Output..: Creates shell aliases for Oracle Home switching
# Notes...: Creates aliases for both NAME and ALIAS_NAME entries
#           Example: DBHOMEFREE and rdbms26 both point to same home
# ------------------------------------------------------------------------------
generate_oracle_home_aliases() {
    local homes_config

    if [[ "${ORADBA_LOAD_ALIASES:-true}" != "true" ]]; then
        oradba_log DEBUG "Skipping Oracle Home alias generation (ORADBA_LOAD_ALIASES=${ORADBA_LOAD_ALIASES:-true})"
        return 0
    fi

    # Auto-sync database homes from oratab (ensures homes available for aliases)
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
        oradba_log DEBUG "Skipping oratab->homes sync for aliases (ORADBA_AUTO_DISCOVER_ORATAB=${ORADBA_AUTO_DISCOVER_ORATAB:-false})"
    fi
    
    # Get Oracle Homes config path
    homes_config=$(get_oracle_homes_path 2>/dev/null) || {
        oradba_log DEBUG "Oracle Homes config not found"
        return 0
    }
    
    # Check if Oracle Homes config exists
    if [[ ! -f "${homes_config}" ]]; then
        oradba_log DEBUG "Oracle Homes config not found: ${homes_config}"
        return 0
    fi
    
    local name alias_name
    
    # Parse Oracle Homes config (skip comments and empty lines)
    # File format: NAME:PATH:TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION
    while IFS=: read -r name _path _type _order alias_name _desc _version; do
        # Skip empty lines and comments
        [[ -z "${name}" ]] && continue
        [[ "${name}" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace from fields
        name="${name#"${name%%[![:space:]]*}"}"
        name="${name%"${name##*[![:space:]]}"}"
        alias_name="${alias_name#"${alias_name%%[![:space:]]*}"}"
        alias_name="${alias_name%"${alias_name##*[![:space:]]}"}"
        
        # Create alias for the Oracle Home name (lowercase, consistent with SID aliases)
        local name_lower
        name_lower=$(printf '%s' "${name}" | tr '[:upper:]' '[:lower:]')
        # shellcheck disable=SC2139
        alias "${name_lower}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${name}"
        oradba_log DEBUG "Created Oracle Home alias: ${name_lower}"
        
        # Create alias for the alias name if it exists and is different from lowercase name
        if [[ -n "${alias_name}" && "${alias_name}" != "${name_lower}" ]]; then
            # shellcheck disable=SC2139
            alias "${alias_name}"=". ${ORADBA_PREFIX}/bin/oraenv.sh ${name}"
            oradba_log DEBUG "Created Oracle Home alias: ${alias_name} -> ${name}"
        fi
    done < "${homes_config}"
    
    return 0
}

# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Oracle Homes Management Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: get_oracle_homes_path
# Purpose.: Get path to oradba_homes.conf configuration file
# Args....: None
# Returns.: 0 if file exists, 1 if not found
# Output..: Prints path to oradba_homes.conf
# Notes...: Looks for ${ORADBA_BASE}/etc/oradba_homes.conf
# ------------------------------------------------------------------------------
get_oracle_homes_path() {
    local homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"

    if [[ -f "${homes_file}" ]]; then
        echo "${homes_file}"
        return 0
    fi

    return 1
}


# ------------------------------------------------------------------------------
# Function: resolve_oracle_home_name
# Purpose.: Resolve Oracle Home alias to actual NAME from oradba_homes.conf
# Args....: $1 - Name or alias to resolve
# Returns.: 0 on success, 1 if not found or error
# Output..: Actual Oracle Home NAME (or original if not found)
# Notes...: Checks both NAME and ALIAS_NAME columns in oradba_homes.conf
# ------------------------------------------------------------------------------
resolve_oracle_home_name() {
    local name_or_alias="$1"
    local homes_file

    if [[ -z "${name_or_alias}" ]]; then
        echo "${name_or_alias}"
        return 1
    fi

    homes_file=$(get_oracle_homes_path) || {
        echo "${name_or_alias}"
        return 1
    }

    # Parse file and check both NAME and ALIAS_NAME
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        # Check if match is NAME
        if [[ "${h_name}" == "${name_or_alias}" ]]; then
            echo "${h_name}"
            return 0
        fi

        # Check if match is ALIAS_NAME (if alias exists and is not a description)
        if [[ -n "${h_alias}" ]] && [[ ! "${h_alias}" =~ [[:space:]] ]]; then
            if [[ "${h_alias}" == "${name_or_alias}" ]]; then
                echo "${h_name}"
                return 0
            fi
        fi
    done < "${homes_file}"

    # Not found, return original (still valid)
    echo "${name_or_alias}"
    return 0
}


# ------------------------------------------------------------------------------
# Function: parse_oracle_home
# Purpose.: Parse Oracle Home configuration entry from oradba_homes.conf
# Args....: $1 - Oracle Home name or alias to parse
# Returns.: 0 - Successfully parsed
#           1 - Oracle Home not found
# Output..: Space-separated values: name alias type path version
# Notes...: Example: read -r oh_name oh_alias oh_type oh_path oh_version < <(parse_oracle_home "ora19")
#           Returns: "ora19 19c database /u01/app/oracle/product/19.3.0/dbhome_1 19.3.0"
# ------------------------------------------------------------------------------
parse_oracle_home() {
    local name="$1"
    local homes_file
    local actual_name

    if [[ -z "${name}" ]]; then
        oradba_log ERROR "Home name required"
        return 1
    fi

    # Resolve alias to actual name
    actual_name=$(resolve_oracle_home_name "${name}")

    homes_file=$(get_oracle_homes_path) || return 1

    # Parse file: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER[:ALIAS_NAME][:DESCRIPTION][:VERSION]
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        if [[ "${h_name}" == "${actual_name}" ]]; then
            # If h_alias is empty or looks like a description, use h_name as alias
            if [[ -z "${h_alias}" ]] || [[ "${h_alias}" =~ [[:space:]] ]]; then
                # h_alias is actually description, shift values
                h_version="${h_desc}"
                h_desc="${h_alias}"
                h_alias="${h_name}"
            fi
            # Default version to AUTO if not specified
            [[ -z "${h_version}" ]] && h_version="AUTO"
            echo "${h_name} ${h_path} ${h_type} ${h_order} ${h_alias} ${h_desc} ${h_version}"
            return 0
        fi
    done < "${homes_file}"

    return 1
}


# ------------------------------------------------------------------------------
# Function: list_oracle_homes
# Purpose.: List all Oracle Homes from oradba_homes.conf
# Args....: $1 - (Optional) Filter by product type
# Returns.: 0 on success, 1 if config file not found
# Output..: One line per home: NAME PATH TYPE ORDER ALIAS DESCRIPTION VERSION
# Notes...: Output sorted by ORDER (column 4), ascending
# ------------------------------------------------------------------------------
list_oracle_homes() {
    local filter="$1"
    local homes_file

    homes_file=$(get_oracle_homes_path) || return 1

    # Parse and optionally filter
    while IFS=: read -r h_name h_path h_type h_order h_alias h_desc h_version; do
        # Skip comments and empty lines
        [[ "${h_name}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${h_name}" ]] && continue

        # Apply filter if specified
        if [[ -n "${filter}" ]]; then
            [[ "${h_type}" != "${filter}" ]] && continue
        fi

        # If h_alias is empty or looks like a description, use h_name as alias
        if [[ -z "${h_alias}" ]] || [[ "${h_alias}" =~ [[:space:]] ]]; then
            # h_alias is actually description, shift values
            h_version="${h_desc}"
            h_desc="${h_alias}"
            h_alias="${h_name}"
        fi
        
        # Default version to AUTO if not specified
        [[ -z "${h_version}" ]] && h_version="AUTO"

        # Output: name|path|type|order|alias_name|description|version (pipe-delimited to preserve spaces in description)
        echo "${h_name}|${h_path}|${h_type}|${h_order}|${h_alias}|${h_desc}|${h_version}"
    done < "${homes_file}" | sort -t'|' -k4 -n
}


# ------------------------------------------------------------------------------
# Function: get_oracle_home_path
# Purpose.: Get ORACLE_HOME path for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: ORACLE_HOME path
# Notes...: Reads from oradba_homes.conf, column 2 (PATH)
# ------------------------------------------------------------------------------
get_oracle_home_path() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $2}'
}


# ------------------------------------------------------------------------------
# Function: get_oracle_home_alias
# Purpose.: Get alias name for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: Alias name (or home name if no alias defined)
# Notes...: Reads from oradba_homes.conf, column 5 (ALIAS_NAME)
# ------------------------------------------------------------------------------
get_oracle_home_alias() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $5}'
}


# ------------------------------------------------------------------------------
# Function: get_oracle_home_type
# Purpose.: Get product type for a registered Oracle Home
# Args....: $1 - Oracle Home name
# Returns.: 0 on success, 1 if not found
# Output..: Product type (database, client, oud, weblogic, oms, emagent, etc.)
# Notes...: Reads from oradba_homes.conf, column 3 (TYPE)
# ------------------------------------------------------------------------------
get_oracle_home_type() {
    local name="$1"
    local home_info

    home_info=$(parse_oracle_home "${name}") || return 1
    echo "${home_info}" | awk '{print $3}'
}


# ------------------------------------------------------------------------------
# Function: detect_product_type
# Purpose.: Detect Oracle product type from ORACLE_HOME path
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if unable to detect
# Output..: Product type: database, client, iclient, java, oud, weblogic, oms,
#           emagent, datasafe, or unknown
# Notes...: Checks for specific files/directories to identify product type
# ------------------------------------------------------------------------------
detect_product_type() {
    local oracle_home="$1"

    [[ -z "${oracle_home}" ]] && echo "unknown" && return 1
    [[ ! -d "${oracle_home}" ]] && echo "unknown" && return 1

    # Check for Java/JDK installations (standalone, not embedded in DB/client)
    if [[ -x "${oracle_home}/bin/java" ]]; then
        # Check if it's ONLY Java (not a database or client with Java embedded)
        if [[ ! -f "${oracle_home}/bin/sqlplus" ]] && [[ ! -f "${oracle_home}/bin/oracle" ]]; then
            # Additional check: if this is jre subdirectory inside a JDK, skip it
            local parent_dir
            parent_dir=$(dirname "${oracle_home}")
            if [[ "$(basename "${oracle_home}")" == "jre" ]] && [[ -x "${parent_dir}/bin/javac" ]]; then
                # This is jre inside a JDK, don't detect as standalone Java
                echo "unknown"
                return 1
            fi
            echo "java"
            return 0
        fi
    fi

    # Check for Oracle Unified Directory
    if [[ -f "${oracle_home}/oud/lib/ldapjdk.jar" ]]; then
        echo "oud"
        return 0
    fi

    # Check for WebLogic
    if [[ -f "${oracle_home}/wlserver/server/lib/weblogic.jar" ]]; then
        echo "weblogic"
        return 0
    fi

    # Check for OMS
    if [[ -f "${oracle_home}/sysman/lib/emoms.jar" ]]; then
        echo "oms"
        return 0
    fi

    # Check for EM Agent
    if [[ -f "${oracle_home}/agent_inst/bin/emctl" ]]; then
        echo "emagent"
        return 0
    fi

    # Check for Data Safe On-Premises Connector (check BEFORE Instant Client)
    # Data Safe has oracle_cman_home subdirectory with cmctl binary
    if [[ -d "${oracle_home}/oracle_cman_home" ]] && [[ -x "${oracle_home}/oracle_cman_home/bin/cmctl" ]]; then
        echo "datasafe"
        return 0
    fi
    # Alternative check: connector.conf and setup.py files
    if [[ -f "${oracle_home}/connector.conf" ]] && [[ -f "${oracle_home}/setup.py" ]]; then
        echo "datasafe"
        return 0
    fi

    # Check for Instant Client (libraries without bin directory)
    # Instant Client has libclntsh in root or lib directories
    # IMPORTANT: Exclude if inside DataSafe oracle_cman_home or other product homes
    if [[ "${oracle_home}" =~ /oracle_cman_home/ ]]; then
        # This is inside DataSafe, not a standalone Instant Client
        echo "unknown"
        return 1
    fi
    
    if [[ -f "${oracle_home}/libclntsh.so" ]] || [[ -f "${oracle_home}/libclntsh.dylib" ]]; then
        echo "iclient"
        return 0
    fi
    # Check for versioned libclntsh (e.g., libclntsh.so.19.1)
    shopt -s nullglob
    local -a versioned_libs=("${oracle_home}"/libclntsh.so.*)
    shopt -u nullglob
    if [[ ${#versioned_libs[@]} -gt 0 ]]; then
        echo "iclient"
        return 0
    fi
    # Check for lib/lib64 without bin (older Instant Client style)
    if [[ -d "${oracle_home}/lib" ]] || [[ -d "${oracle_home}/lib64" ]]; then
        if [[ ! -d "${oracle_home}/bin" ]]; then
            # Check for actual Oracle client libraries
            shopt -s nullglob
            local -a lib_files=("${oracle_home}"/lib*/libclntsh*)
            shopt -u nullglob
            if [[ ${#lib_files[@]} -gt 0 ]]; then
                echo "iclient"
                return 0
            fi
        fi
    fi

    # Check for Oracle Client
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ ! -f "${oracle_home}/bin/oracle" ]]; then
        echo "client"
        return 0
    fi

    # Check for Database (has sqlplus and oracle binary)
    if [[ -f "${oracle_home}/bin/sqlplus" ]] && [[ -f "${oracle_home}/bin/oracle" ]]; then
        echo "database"
        return 0
    fi

    echo "unknown"
    return 1
}


# ------------------------------------------------------------------------------
# Function: detect_oracle_version
# Purpose.: Detect Oracle version from ORACLE_HOME path
# Args....: $1 - ORACLE_HOME path
#           $2 - Product type (optional, will detect if not provided)
# Returns.: 0 on success, 1 on error (no version detected)
# Output..: Oracle version in format XXYZ (e.g., 1920 for 19.2.0, 2301 for 23.1)
#           No output on error (follows exit code contract)
# Notes...: Delegates to product plugin if available, otherwise uses fallback methods
#           Plugin detection via plugin_get_version() (returns X.Y.Z.W format)
#           Fallback methods: sqlplus, OPatch, inventory XML, path parsing
# ------------------------------------------------------------------------------
detect_oracle_version() {
    local oracle_home="$1"
    local product_type="${2:-}"
    local version=""

    [[ -z "${oracle_home}" ]] && return 1
    [[ ! -d "${oracle_home}" ]] && return 1

    # Auto-detect product type if not provided
    if [[ -z "${product_type}" ]]; then
        product_type=$(detect_product_type "${oracle_home}")
    fi

    # Try plugin-based version detection first (subshell isolated)
    local plugin_version
    if execute_plugin_function_v2 "${product_type}" "get_version" "${oracle_home}" "plugin_version"; then
        oradba_log DEBUG "Plugin returned version: ${plugin_version}"
        # Convert X.Y.Z.W format to XXYZ format
        local major minor
        major="${plugin_version%%.*}"
        local _maj_rest="${plugin_version#*.}"; minor="${_maj_rest%%.*}"
        oradba_log DEBUG "Converting ${plugin_version} to format: ${major}${minor}"
        printf "%02d%02d" "${major}" "${minor}"
        return 0
    else
        oradba_log DEBUG "Plugin get_version not available (exit $?)"
    fi

    # Fallback: Generic version detection methods
    
    # Method 1: Try sqlplus -version
    local sqlplus_bin=""
    if [[ -f "${oracle_home}/bin/sqlplus" ]]; then
        sqlplus_bin="${oracle_home}/bin/sqlplus"
    fi
    
    if [[ -n "${sqlplus_bin}" ]]; then
        local sqlplus_version
        sqlplus_version=$("${sqlplus_bin}" -version 2>/dev/null | grep -i "Release" | head -1)
        
        if [[ -n "${sqlplus_version}" ]]; then
            # Extract version like "19.21.0.0.0" or "23.0.0.0.0" or "23.26.0.0.0"
            local ver_str
            ver_str=$(echo "${sqlplus_version}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            
            if [[ -n "${ver_str}" ]]; then
                # Convert to XXYZ format: 19.21.0.0 -> 1921, 23.26.0.0 -> 2326
                local major minor
                major="${ver_str%%.*}"
                local _maj_rest="${ver_str#*.}"; minor="${_maj_rest%%.*}"
                # Pad to 2 digits
                printf "%02d%02d" "${major}" "${minor}"
                return 0
            fi
        fi
    fi

    # Method 2: Try OPatch inventory
    if [[ -f "${oracle_home}/OPatch/opatch" ]]; then
        local opatch_version
        opatch_version=$("${oracle_home}/OPatch/opatch" lsinventory 2>/dev/null | grep -i "Oracle Database" | head -1)
        
        if [[ -n "${opatch_version}" ]]; then
            local ver_str
            ver_str=$(echo "${opatch_version}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            
            if [[ -n "${ver_str}" ]]; then
                local major minor
                major="${ver_str%%.*}"
                local _maj_rest="${ver_str#*.}"; minor="${_maj_rest%%.*}"
                printf "%02d%02d" "${major}" "${minor}"
                return 0
            fi
        fi
    fi

    # Method 3: Try inventory XML
    if [[ -f "${oracle_home}/inventory/ContentsXML/comps.xml" ]]; then
        local xml_version
        xml_version=$(grep -i "VER=" "${oracle_home}/inventory/ContentsXML/comps.xml" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        
        if [[ -n "${xml_version}" ]]; then
            local major minor
            major="${xml_version%%.*}"
            local _maj_rest="${xml_version#*.}"; minor="${_maj_rest%%.*}"
            printf "%02d%02d" "${major}" "${minor}"
            return 0
        fi
    fi

    # Method 4: Extract from path (e.g., /product/19.0.0.0 or /product/23.26.0.0/client)
    local path_version
    path_version=$(echo "${oracle_home}" | grep -oE '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [[ -n "${path_version}" ]]; then
        local major minor
        major="${path_version%%.*}"
        local _maj_rest="${path_version#*.}"; minor="${_maj_rest%%.*}"
        printf "%02d%02d" "${major}" "${minor}"
        return 0
    fi

    # No version detected - return error without output
    return 1
}


# ------------------------------------------------------------------------------
# Function: derive_oracle_base
# Purpose.: Derive ORACLE_BASE from ORACLE_HOME by searching upward
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if unable to derive
# Output..: Derived ORACLE_BASE path
# Notes...: Searches upward for directory containing "product", "oradata",
#           "oraInventory", or "admin" (max 5 levels)
# ------------------------------------------------------------------------------
derive_oracle_base() {
    local oracle_home="$1"
    local current_dir="${oracle_home}"
    
    [[ -z "${oracle_home}" ]] && return 1
    [[ ! -d "${oracle_home}" ]] && return 1
    
    # Walk up the directory tree looking for Oracle base indicators
    while [[ "${current_dir}" != "/" ]]; do
        local parent_dir
        parent_dir="$(dirname "${current_dir}")"
        
        # Check if current dir contains typical Oracle base subdirectories
        if [[ -d "${parent_dir}/product" ]] || \
           [[ -d "${parent_dir}/oradata" ]] || \
           [[ -d "${parent_dir}/oraInventory" ]] || \
           [[ -d "${parent_dir}/admin" ]]; then
            echo "${parent_dir}"
            return 0
        fi
        
        # Stop if we've gone up too far (more than 5 levels)
        local depth=0
        local test_path="${oracle_home}"
        while [[ "${test_path}" != "${parent_dir}" ]] && [[ "${test_path}" != "/" ]]; do
            test_path="$(dirname "${test_path}")"
            ((depth++))
            if [[ ${depth} -gt 5 ]]; then
                break 2
            fi
        done
        
        current_dir="${parent_dir}"
    done
    
    # Fallback: use traditional two-levels-up method
    dirname "$(dirname "${oracle_home}")"
}


# ------------------------------------------------------------------------------
# Function: is_oracle_home
# Purpose.: Check if given name refers to an Oracle Home (vs database SID)
# Args....: $1 - Name to check (Oracle Home name/alias or SID)
# Returns.: 0 - Name is an Oracle Home
#           1 - Name is not an Oracle Home (likely a SID)
# Output..: None
# Notes...: Example: if is_oracle_home "ora19"; then echo "Oracle Home"; fi
# ------------------------------------------------------------------------------
is_oracle_home() {
    local name="$1"

    [[ -z "${name}" ]] && return 1

    parse_oracle_home "${name}" > /dev/null 2>&1
}


# ------------------------------------------------------------------------------
# Function: is_subdirectory_of_oracle_home
# Purpose.: Check if path is a subdirectory of a valid Oracle Home
# Args....: $1 - Path to check
#           $2 - Array of already-validated Oracle Home paths (passed by reference)
# Returns.: 0 if is subdirectory, 1 if not
# Output..: None
# Notes...: Used to avoid false positives in discovery (e.g., dbhomeFree/jdk)
#           Checks if path is beneath any Oracle Home in the validated list
# ------------------------------------------------------------------------------
is_subdirectory_of_oracle_home() {
    local check_path="$1"
    shift
    local -a validated_homes=("$@")
    
    # Check if this path is a subdirectory of any validated Oracle Home
    for oracle_home in "${validated_homes[@]}"; do
        # Compare canonical paths (resolve symlinks)
        local canonical_home canonical_check
        canonical_home=$(cd "${oracle_home}" 2>/dev/null && pwd -P) || continue
        canonical_check=$(cd "${check_path}" 2>/dev/null && pwd -P) || continue
        
        # Check if check_path starts with oracle_home path
        if [[ "${canonical_check}" == "${canonical_home}"/* ]]; then
            return 0  # Is a subdirectory
        fi
    done
    
    return 1  # Not a subdirectory
}


# ------------------------------------------------------------------------------
# Function: is_bundled_component
# Purpose.: Check if directory is a common bundled component of Oracle Home
# Args....: $1 - Directory basename
# Returns.: 0 if bundled component, 1 if not
# Output..: None
# Notes...: Excludes common subdirectories found in Oracle Homes
#           Examples: jdk, jre, lib, inventory, OPatch, etc.
# ------------------------------------------------------------------------------
is_bundled_component() {
    local dir_name="$1"
    
    # Common bundled directories that should not be detected as separate homes
    case "${dir_name}" in
        jdk|jre|lib|lib64|inventory|OPatch|oraInst.loc|oui|\
        network|rdbms|bin|sqlplus|sqldeveloper|odbc|jdbc|\
        assistants|clone|ctx|cv|dbjava|demo|has|hs|install|\
        md|nls|oc4j|olap|oml|oracore|oraolap|owb|\
        precomp|racg|slax|srvm|sysman|ucp|wwg|xdk)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


# ------------------------------------------------------------------------------
# Function: auto_discover_oracle_homes
# Purpose.: Auto-discover Oracle Homes and add to oradba_homes.conf
# Args....: $1 - Discovery paths (optional, defaults to ORADBA_DISCOVERY_PATHS)
#           $2 - Silent mode flag (optional, "true" for silent, default: false)
# Returns.: 0 on success, 1 on error
# Output..: Discovery summary (unless silent)
# Notes...: Issue #70 - Unified auto-discovery function
#           Used by both oraenv.sh initialization and oradba_homes.sh discover
#           Silently skips already registered homes (no duplicates)
#           Uses plugin system's detect_product_type() and plugin_validate_home()
#           Excludes subdirectories of validated Oracle Homes (fixes false positives)
#           Generates home names using generate_home_name() logic
#           Only adds homes if not already in oradba_homes.conf
# ------------------------------------------------------------------------------
auto_discover_oracle_homes() {
    local discovery_paths="${1:-${ORADBA_DISCOVERY_PATHS}}"
    local silent="${2:-false}"
    local found_count=0
    local added_count=0
    local skipped_count=0
    local -a validated_homes=()  # Track validated Oracle Homes to avoid subdirectory detection
    
    # Check if ORACLE_BASE is set and use it as default discovery path
    if [[ -z "${discovery_paths}" ]]; then
        if [[ -n "${ORACLE_BASE}" ]]; then
            discovery_paths="${ORACLE_BASE}/product"
        else
            [[ "${silent}" != "true" ]] && oradba_log WARN "No discovery paths configured"
            return 1
        fi
    fi
    
    # Get config file path
    local config_file
    if ! config_file=$(get_oracle_homes_path 2>/dev/null); then
        config_file="${ORADBA_BASE:-${ORADBA_PREFIX}}/etc/oradba_homes.conf"
    fi
    
    # Ensure config directory exists
    local config_dir
    config_dir=$(dirname "${config_file}")
    [[ ! -d "${config_dir}" ]] && mkdir -p "${config_dir}"

    # Initialize config with header if missing or empty
    if [[ ! -s "${config_file}" ]]; then
        local template_file
        template_file="${ORADBA_BASE}/templates/etc/oradba_homes.conf.template"
        if [[ ! -f "${template_file}" ]]; then
            template_file="${ORADBA_PREFIX}/templates/etc/oradba_homes.conf.template"
        fi

        if [[ -f "${template_file}" ]]; then
            awk '
                /^# Your Oracle Homes Configuration/ { print; exit }
                /^#/ || /^$/ { print }
            ' "${template_file}" > "${config_file}"
            printf "\n" >> "${config_file}"
        else
            cat > "${config_file}" << 'EOF'
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# ------------------------------------------------------------------------------
# Name.......: oradba_homes.conf
# Purpose....: Oracle Homes registry (auto-generated)
# Notes......: One entry per line, colon-delimited
# Format.....: NAME:ORACLE_HOME:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
# ------------------------------------------------------------------------------

# Your Oracle Homes Configuration

EOF
        fi
    fi
    
    # Start discovery
    [[ "${silent}" != "true" ]] && {
        echo ""
        echo "Auto-discovering Oracle Homes..."
        echo "================================================================================"
        echo "Search paths: ${discovery_paths}"
        echo ""
    }
    
    # Process each discovery path
    for base_dir in ${discovery_paths}; do
        [[ ! -d "${base_dir}" ]] && continue
        
        # Find directories up to 3 levels deep
        while IFS= read -r -d '' dir; do
            # Skip symbolic links
            [[ -L "${dir}" ]] && continue
            
            # Skip if this is a subdirectory of an already-validated Oracle Home
            if is_subdirectory_of_oracle_home "${dir}" "${validated_homes[@]}"; then
                [[ "${silent}" != "true" ]] && oradba_log DEBUG "Skipping subdirectory of Oracle Home: ${dir}"
                continue
            fi
            
            # Skip common bundled components
            local dir_name
            dir_name=$(basename "${dir}")
            if is_bundled_component "${dir_name}"; then
                [[ "${silent}" != "true" ]] && oradba_log DEBUG "Skipping bundled component: ${dir}"
                continue
            fi
            
            # Detect product type using common function
            local ptype
            ptype=$(detect_product_type "${dir}")
            
            # Skip unknown types
            [[ "${ptype}" == "unknown" ]] && continue
            
            # Validate using plugin system before counting as found
            local plugin_file="${ORADBA_BASE}/lib/plugins/${ptype}_plugin.sh"
            local is_valid_home=false
            
            if [[ -f "${plugin_file}" ]]; then
                # Source plugin and validate
                # shellcheck source=/dev/null
                source "${plugin_file}" 2>/dev/null || true
                
                if declare -f plugin_validate_home >/dev/null 2>&1; then
                    if plugin_validate_home "${dir}" 2>/dev/null; then
                        is_valid_home=true
                        # Add to validated homes list to exclude its subdirectories
                        validated_homes+=("${dir}")
                    else
                        [[ "${silent}" != "true" ]] && oradba_log DEBUG "Plugin validation failed: ${dir} (${ptype})"
                        continue
                    fi
                else
                    # No validation function - accept based on detect_product_type
                    is_valid_home=true
                    validated_homes+=("${dir}")
                fi
            else
                # No plugin - accept based on detect_product_type (backward compatible)
                is_valid_home=true
                validated_homes+=("${dir}")
            fi
            
            [[ "${is_valid_home}" == "false" ]] && continue
            
            ((found_count++))
            
            # Generate home name from path and product type
            local dir_name home_name
            dir_name=$(basename "${dir}")
            
            # Generate home name using same logic as oradba_homes.sh
            case "${ptype}" in
                java)
                    # Normalize Java/JDK/JRE names to lowercase jdkNNN or jreNNN
                    if [[ "${dir_name}" =~ ^[Jj][Dd][Kk][-_]?([0-9]+) ]]; then
                        home_name="jdk${BASH_REMATCH[1]}"
                    elif [[ "${dir_name}" =~ ^[Jj][Rr][Ee][-_]?([0-9]+) ]]; then
                        home_name="jre${BASH_REMATCH[1]}"
                    elif [[ "${dir_name}" =~ ^[Jj]ava[-_]?([0-9]+) ]]; then
                        home_name="jdk${BASH_REMATCH[1]}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf "%s" "${home_name}" | tr "[:upper:]" "[:lower:]")
                    fi
                    ;;
                iclient)
                    # Normalize instant client names to lowercase iclientNNN
                    if [[ "${dir_name}" =~ instantclient[-_]?([0-9]+) ]]; then
                        local version="${BASH_REMATCH[1]}"
                        version="${version%%[_.-]*}"
                        home_name="iclient${version}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf "%s" "${home_name}" | tr "[:upper:]" "[:lower:]")
                    fi
                    ;;
                datasafe)
                    # DataSafe connectors: sequential naming dscon1, dscon2, ...
                    local counter=1
                    if [[ -f "${config_file}" ]]; then
                        while grep -q "^dscon${counter}:" "${config_file}" 2>/dev/null; do
                            ((counter++))
                        done
                    fi
                    home_name="dscon${counter}"
                    ;;
                oud)
                    # OUD instances: normalize to oudNNN
                    if [[ "${dir_name}" =~ [Oo][Uu][Dd][-_]?([0-9]+) ]]; then
                        home_name="oud${BASH_REMATCH[1]}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf "%s" "${home_name}" | tr "[:upper:]" "[:lower:]")
                    fi
                    ;;
                database)
                    # Database homes: normalize to rdbmsNNNN
                    if [[ "${dir_name}" =~ ([0-9]{2,4}) ]]; then
                        local version="${BASH_REMATCH[1]}"
                        # If 4 digits (e.g., 1918), keep as-is; if 2-3 digits (e.g., 19), pad
                        [[ ${#version} -eq 2 ]] && version="${version}00"
                        [[ ${#version} -eq 3 ]] && version="${version}0"
                        home_name="rdbms${version}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf '%s' "${home_name}" | tr '[:lower:]' '[:upper:]')
                    fi
                    ;;
                client)
                    # Full client: clientNNNN
                    if [[ "${dir_name}" =~ ([0-9]{2,4}) ]]; then
                        local version="${BASH_REMATCH[1]}"
                        [[ ${#version} -eq 2 ]] && version="${version}00"
                        [[ ${#version} -eq 3 ]] && version="${version}0"
                        home_name="client${version}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf '%s' "${home_name}" | tr '[:lower:]' '[:upper:]')
                    fi
                    ;;
                weblogic)
                    # WebLogic: wlsNNNN
                    if [[ "${dir_name}" =~ ([0-9]{2,4}) ]]; then
                        home_name="wls${BASH_REMATCH[1]}"
                    else
                        home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                        home_name=$(printf '%s' "${home_name}" | tr '[:lower:]' '[:upper:]')
                    fi
                    ;;
                *)
                    # Other products: use uppercase (backward compatible)
                    home_name="${dir_name//./_}"; home_name="${home_name//-/_}"
                    home_name=$(printf '%s' "${home_name}" | tr '[:lower:]' '[:upper:]')
                    ;;
            esac
            
            # Check if already registered (by name or path)
            local already_exists=false
            if [[ -f "${config_file}" ]]; then
                # Check by name (first field)
                if grep -q "^${home_name}:" "${config_file}"; then
                    already_exists=true
                    [[ "${silent}" != "true" ]] && echo "  [SKIP] ${home_name} (${ptype}) - already registered"
                # Check by path (second field)
                elif grep -q ":${dir}:" "${config_file}"; then
                    local existing_name
                    existing_name=$(grep ":${dir}:" "${config_file}" | head -1 | cut -d':' -f1)
                    already_exists=true

                    # Migrate legacy DataSafe names to sequential dsconN
                    if [[ "${ptype}" == "datasafe" ]] && [[ "${existing_name}" != "${home_name}" ]] && [[ ! "${existing_name}" =~ ^dscon[0-9]+$ ]]; then
                        local tmp_file
                        tmp_file="${config_file}.tmp"
                        if awk -F: -v OFS=: -v path="${dir}" -v new_name="${home_name}" '$2 == path { $1 = new_name } { print }' "${config_file}" > "${tmp_file}"; then
                            mv "${tmp_file}" "${config_file}"
                            existing_name="${home_name}"
                        else
                            rm -f "${tmp_file}"
                        fi
                    fi

                    [[ "${silent}" != "true" ]] && echo "  [SKIP] ${home_name} (${ptype}) - path registered as '${existing_name}'"
                fi
            fi
            
            if [[ "${already_exists}" == "true" ]]; then
                ((skipped_count++))
                continue
            fi
            
            # Add to config file
            # Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION
            local order=$((50 + found_count * 10))
            echo "${home_name}:${dir}:${ptype}:${order}::Auto-discovered ${ptype}:AUTO" >> "${config_file}"
            
            [[ "${silent}" != "true" ]] && echo "  [ADD] ${home_name} (${ptype}) - ${dir}"
            ((added_count++))
            
        done < <(find "${base_dir}" -maxdepth 3 -type d -print0 2>/dev/null)
    done
    
    # Summary
    [[ "${silent}" != "true" ]] && {
        echo ""
        echo "Discovery Summary:"
        echo "  Found:   ${found_count} Oracle Home(s)"
        echo "  Skipped: ${skipped_count} already registered"
        echo "  Added:   ${added_count} new Oracle Home(s)"
        echo ""
        if [[ ${added_count} -gt 0 ]]; then
            echo "Note: Discovered entries can be customized in ${config_file}"
            echo "      You can edit the file to change names, order, or descriptions."
            echo ""
        fi
    }
    
    # Log summary
    if [[ ${added_count} -gt 0 ]]; then
        oradba_log INFO "Auto-discovery added ${added_count} Oracle Home(s) to ${config_file}"
    elif [[ ${found_count} -gt 0 ]]; then
        oradba_log DEBUG "Auto-discovery found ${found_count} Oracle Home(s), all already registered"
    else
        oradba_log DEBUG "Auto-discovery found no Oracle Homes in ${discovery_paths}"
    fi
    
    return 0
}
