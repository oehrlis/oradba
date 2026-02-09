#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_builder.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-14
# Revision...: 0.19.0
# Purpose....: Build Oracle environment variables
# Notes......: Part of Phase 1 implementation for oradba environment management
#              Constructs PATH, LD_LIBRARY_PATH, and product-specific variables
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_BUILDER_LOADED}" ]] && return 0
readonly ORADBA_ENV_BUILDER_LOADED=1

# ------------------------------------------------------------------------------
# Dependency Injection Infrastructure (Phase 4)
# ------------------------------------------------------------------------------

# Global variable for storing logger dependency
declare ORADBA_BUILDER_LOGGER="${ORADBA_BUILDER_LOGGER:-}"

# ------------------------------------------------------------------------------
# Function: oradba_builder_init
# Purpose.: Initialize builder library with optional dependency injection
# Args....: $1 - Logger function name (optional, defaults to "oradba_log")
# Returns.: 0 on success
# Output..: None
# Notes...: Call this function before using builder functions if you want to inject
#           a custom logger. If not called, falls back to oradba_log if available.
# ------------------------------------------------------------------------------
oradba_builder_init() {
    local logger="${1:-}"
    
    # Store logger function reference
    ORADBA_BUILDER_LOGGER="$logger"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: _oradba_builder_log
# Purpose.: Internal logging function that uses injected logger or fallback
# Args....: $1 - Log level (DEBUG, INFO, WARN, ERROR)
#          $@ - Log message
# Returns.: 0 on success
# Output..: None (delegates to injected logger)
# Notes...: Internal use only. Falls back to oradba_log if available, or no-op.
# ------------------------------------------------------------------------------
_oradba_builder_log() {
    # Priority 1: Use injected logger if configured
    if [[ -n "$ORADBA_BUILDER_LOGGER" ]]; then
        "$ORADBA_BUILDER_LOGGER" "$@"
        return 0
    fi
    
    # Priority 2: Fall back to oradba_log if available (backward compatibility)
    if declare -f oradba_log &>/dev/null; then
        oradba_log "$@"
        return 0
    fi
    
    # Priority 3: No-op (silent)
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_dedupe_path
# Purpose.: Remove duplicate entries from PATH-like variables
# Args....: $1 - Path string (colon-separated)
# Returns.: Deduplicated path string
# ------------------------------------------------------------------------------
oradba_dedupe_path() {
    local input_path="$1"
    local -a seen_paths
    local -a result_paths
    local dir
    
    # Split on colon and process each directory
    IFS=':' read -ra dirs <<< "$input_path"
    for dir in "${dirs[@]}"; do
        # Skip empty entries
        [[ -z "$dir" ]] && continue
        
        # Check if we've seen this path before
        local already_seen=0
        for seen in "${seen_paths[@]}"; do
            if [[ "$dir" == "$seen" ]]; then
                already_seen=1
                break
            fi
        done
        
        # Add if not seen
        if [[ $already_seen -eq 0 ]]; then
            seen_paths+=("$dir")
            result_paths+=("$dir")
        fi
    done
    
    # Join with colons
    local IFS=':'
    echo "${result_paths[*]}"
}

# Require parser functions
if [[ -z "${ORADBA_ENV_PARSER_LOADED}" ]]; then
    if [[ -f "${ORADBA_BASE}/lib/oradba_env_parser.sh" ]]; then
        # shellcheck source=./oradba_env_parser.sh
        source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
    else
        echo "ERROR: oradba_env_parser.sh not found" >&2
        return 1
    fi
fi

# Require config functions (Phase 2)
if [[ -z "${ORADBA_ENV_CONFIG_LOADED}" ]]; then
    if [[ -f "${ORADBA_BASE}/lib/oradba_env_config.sh" ]]; then
        # shellcheck source=./oradba_env_config.sh
        source "${ORADBA_BASE}/lib/oradba_env_config.sh"
    fi
fi

# Require extensions library
if [[ -z "${ORADBA_EXTENSIONS_LOADED}" ]]; then
    if [[ -f "${ORADBA_BASE}/lib/extensions.sh" ]]; then
        # shellcheck source=./extensions.sh
        source "${ORADBA_BASE}/lib/extensions.sh"
    fi
fi

# ------------------------------------------------------------------------------
# Function: oradba_clean_path
# Purpose.: Remove Oracle-related directories from PATH
# Args....: None
# Returns.: 0 on success
# Output..: Cleaned PATH exported
# ------------------------------------------------------------------------------
oradba_clean_path() {
    local new_path=""
    local IFS=":"
    
    for dir in $PATH; do
        # Skip Oracle directories
        [[ "$dir" =~ /oracle/ ]] && continue
        [[ "$dir" =~ /grid/ ]] && continue
        [[ "$dir" =~ instantclient ]] && continue
        
        # Add to new path
        if [[ -n "$new_path" ]]; then
            new_path="${new_path}:"
        fi
        new_path="${new_path}${dir}"
    done
    
    export PATH="$new_path"
}

# ------------------------------------------------------------------------------
# Function: oradba_add_oracle_path
# Purpose.: Add Oracle binaries to PATH using plugin system
# Args....: $1 - ORACLE_HOME
#          $2 - Product type (optional, lowercase: database, client, iclient, etc.)
# Returns.: 0 on success
# Notes...: Uses plugin_build_bin_path() from product-specific plugins
#           Falls back to basic bin directory for unknown products
# ------------------------------------------------------------------------------
oradba_add_oracle_path() {
    local oracle_home="$1"
    local product_type="${2:-database}"
    local new_path=""
    
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Convert product type to lowercase for plugin matching
    product_type="${product_type,,}"
    
    # Map old uppercase types to plugin names
    case "$product_type" in
        rdbms|grid) product_type="database" ;;
        wls|weblogic) product_type="weblogic" ;;
    esac
    
    # Use v2 wrapper for isolated plugin execution (Phase 3)
    if execute_plugin_function_v2 "${product_type}" "build_bin_path" "${oracle_home}" "new_path"; then
        _oradba_builder_log DEBUG "Plugin ${product_type}: PATH components = ${new_path}"
    else
        _oradba_builder_log DEBUG "Plugin ${product_type}: plugin_build_bin_path failed or N/A, using fallback"
        new_path=""
    fi
    
    # Fallback if plugin not found or failed
    if [[ -z "$new_path" ]]; then
        _oradba_builder_log DEBUG "Using fallback PATH for ${product_type}"
        if [[ -d "${oracle_home}/bin" ]]; then
            new_path="${oracle_home}/bin"
        elif [[ -d "$oracle_home" ]]; then
            # Instant Client: binaries in root
            new_path="$oracle_home"
        fi
    fi
    
    # Add paths to PATH only if directories exist AND not already in PATH
    # Handle both single paths and colon-separated path lists
    if [[ -n "$new_path" ]]; then
        [[ "${ORADBA_DEBUG:-false}" == "true" ]] && echo "DEBUG: oradba_add_oracle_path - new_path: $new_path" >&2
        [[ "${ORADBA_DEBUG:-false}" == "true" ]] && echo "DEBUG: oradba_add_oracle_path - Current PATH before: $PATH" >&2
        
        IFS=':' read -ra path_array <<< "$new_path"
        for dir in "${path_array[@]}"; do
            # Only add if directory exists and not already in PATH
            if [[ -d "$dir" ]] && [[ ":${PATH}:" != *":${dir}:"* ]]; then
                [[ "${ORADBA_DEBUG:-false}" == "true" ]] && echo "DEBUG: oradba_add_oracle_path - Adding: $dir" >&2
                export PATH="${dir}:${PATH}"
            else
                [[ "${ORADBA_DEBUG:-false}" == "true" ]] && echo "DEBUG: oradba_add_oracle_path - Skipping: $dir" >&2
            fi
        done
        
        [[ "${ORADBA_DEBUG:-false}" == "true" ]] && echo "DEBUG: oradba_add_oracle_path - Current PATH after: $PATH" >&2
    fi
}

# ------------------------------------------------------------------------------
# Function: oradba_set_lib_path
# Purpose.: Set library path using plugin system
# Args....: $1 - ORACLE_HOME
#          $2 - Product type (optional, lowercase: database, client, iclient, etc.)
# Returns.: 0 on success
# Notes...: Uses plugin_build_lib_path() from product-specific plugins
#           Falls back to basic lib/lib64 detection for unknown products#           Cleans old Oracle/Grid/InstantClient paths before setting new ones
#           Preserves non-Oracle library paths from existing environment# ------------------------------------------------------------------------------
oradba_set_lib_path() {
    local oracle_home="$1"
    local product_type="${2:-database}"
    local lib_path=""
    local lib_var="LD_LIBRARY_PATH"
    
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Determine platform library variable
    case "$(uname -s)" in
        HP-UX)  lib_var="SHLIB_PATH" ;;
        AIX)    lib_var="LIBPATH" ;;
        Darwin) lib_var="DYLD_LIBRARY_PATH" ;;
    esac
    
    # Convert product type to lowercase for plugin matching
    product_type="${product_type,,}"
    
    # Map old uppercase types to plugin names
    case "$product_type" in
        rdbms|grid) product_type="database" ;;
        wls|weblogic) product_type="weblogic" ;;
    esac
    
    # Use v2 wrapper for isolated plugin execution (Phase 3)
    if execute_plugin_function_v2 "${product_type}" "build_lib_path" "${oracle_home}" "lib_path"; then
        _oradba_builder_log DEBUG "Plugin ${product_type}: LIB_PATH components = ${lib_path}"
    else
        _oradba_builder_log DEBUG "Plugin ${product_type}: plugin_build_lib_path failed or N/A, using fallback"
        lib_path=""
    fi
    
    # Fallback if plugin not found or failed
    if [[ -z "$lib_path" ]]; then
        _oradba_builder_log DEBUG "Using fallback LIB_PATH for ${product_type}"
        if [[ -d "${oracle_home}/lib64" ]]; then
            lib_path="${oracle_home}/lib64"
        fi
        if [[ -d "${oracle_home}/lib" ]]; then
            lib_path="${lib_path:+${lib_path}:}${oracle_home}/lib"
        fi
        # For instant client, libraries are in ORACLE_HOME root
        if [[ "${product_type}" == "iclient" && -z "${lib_path}" ]]; then
            lib_path="${oracle_home}"
        fi
    fi
    
    # Clean existing Oracle library paths from the environment
    eval "local existing=\"\${${lib_var}}\""
    if [[ -n "$existing" ]]; then
        _oradba_builder_log DEBUG "Cleaning ${lib_var}: ${existing}"
        local cleaned_path=""
        local IFS=":"
        for dir in $existing; do
            # Skip Oracle-related directories
            if [[ "$dir" =~ /oracle/ ]] || [[ "$dir" =~ /grid/ ]] || [[ "$dir" =~ instantclient ]]; then
                _oradba_builder_log DEBUG "Removing old Oracle path: ${dir}"
                continue
            fi
            
            # Add to cleaned path
            cleaned_path="${cleaned_path:+${cleaned_path}:}${dir}"
        done
        _oradba_builder_log DEBUG "Cleaned ${lib_var}: ${cleaned_path}"
        
        # Append cleaned non-Oracle paths to new Oracle paths
        if [[ -n "$cleaned_path" ]]; then
            lib_path="${lib_path:+${lib_path}:}${cleaned_path}"
        fi
    fi
    
    # Deduplicate library path
    lib_path="$(oradba_dedupe_path "$lib_path")"
    
    _oradba_builder_log DEBUG "Final ${lib_var} to be exported: ${lib_path}"
    
    # Export library path variable (always export, even if empty)
    # This ensures we clear old values from previous environments
    export ${lib_var}="$lib_path"
}

# ------------------------------------------------------------------------------
# Function: oradba_detect_rooh
# Purpose.: Detect Read-Only Oracle Home
# Args....: $1 - ORACLE_HOME
# Returns.: 0 if ROOH, 1 if not ROOH or cannot determine
# Output..: Sets ORACLE_BASE, ORADBA_ROOH, ORADBA_DBS
# ------------------------------------------------------------------------------
oradba_detect_rooh() {
    local oracle_home="$1"
    local oracle_base=""
    local is_rooh=0
    
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Check for orabasetab file (12.2+)
    if [[ -f "${oracle_home}/install/orabasetab" ]]; then
        # Format: ORACLE_HOME:ORACLE_BASE:ORACLE_HOME_NAME:Y/N
        # Last field Y = Read-Only Home
        while IFS=: read -r home base _name rooh_flag; do
            if [[ "$home" == "$oracle_home" ]]; then
                oracle_base="$base"
                if [[ "$rooh_flag" == "Y" ]]; then
                    is_rooh=1
                fi
                break
            fi
        done < "${oracle_home}/install/orabasetab"
    fi
    
    # If ORACLE_BASE not found in orabasetab, derive it
    if [[ -z "$oracle_base" ]]; then
        # Standard: /u01/app/oracle/product/... → /u01/app/oracle
        oracle_base=$(dirname "$(dirname "$oracle_home")")
    fi
    
    # Export variables
    export ORACLE_BASE="${oracle_base}"
    export ORADBA_ROOH="${is_rooh}"
    
    # Set dbs directory based on ROOH
    if [[ $is_rooh -eq 1 ]]; then
        export ORADBA_DBS="${oracle_base}/dbs"
    else
        export ORADBA_DBS="${oracle_home}/dbs"
    fi
    
    return $is_rooh
}

# ------------------------------------------------------------------------------
# Function: oradba_is_asm_instance
# Purpose.: Check if SID is an ASM instance
# Args....: $1 - SID
# Returns.: 0 if ASM, 1 if not
# ------------------------------------------------------------------------------
oradba_is_asm_instance() {
    local sid="$1"
    [[ "$sid" =~ ^\+ASM ]] && return 0
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_set_oracle_vars
# Purpose.: Set core Oracle environment variables
# Args....: $1 - ORACLE_SID
#          $2 - ORACLE_HOME
#          $3 - Product type
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_set_oracle_vars() {
    local oracle_sid="$1"
    local oracle_home="$2"
    local product_type="$3"
    
    [[ -z "$oracle_sid" ]] && return 1
    [[ -z "$oracle_home" ]] && return 1
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Apply product-specific adjustments via plugin system
    local datasafe_parent=""
    local adjusted_home="${oracle_home}"
    
    if [[ "$product_type" == "DATASAFE" ]]; then
        # Use v2 wrapper for isolated plugin execution (Phase 3)
        if execute_plugin_function_v2 "datasafe" "adjust_environment" "${oracle_home}" "adjusted_home"; then
            datasafe_parent="${oracle_home}"
        elif [[ -d "${oracle_home}/oracle_cman_home" ]]; then
            # Fallback
            datasafe_parent="${oracle_home}"
            adjusted_home="${oracle_home}/oracle_cman_home"
        fi
    fi
    
    oracle_home="${adjusted_home}"
    
    # Core Oracle variables
    export ORACLE_SID="$oracle_sid"
    export ORACLE_HOME="$oracle_home"
    
    # Export DataSafe parent directory if applicable
    if [[ -n "$datasafe_parent" ]]; then
        export DATASAFE_INSTALL_DIR="$datasafe_parent"
    fi
    
    # Detect and set ORACLE_BASE
    oradba_detect_rooh "$oracle_home"
    
    # Set ORACLE_UNQNAME (for databases)
    if [[ "$product_type" == "RDBMS" ]]; then
        export ORACLE_UNQNAME="${ORACLE_UNQNAME:-${oracle_sid}}"
    fi
    
    # Set TNS_ADMIN
    if [[ "$product_type" == "RDBMS" ]] || [[ "$product_type" == "CLIENT" ]]; then
        if [[ -d "${oracle_home}/network/admin" ]]; then
            export TNS_ADMIN="${oracle_home}/network/admin"
        elif [[ -d "${ORACLE_BASE}/network/admin" ]]; then
            export TNS_ADMIN="${ORACLE_BASE}/network/admin"
        fi
    elif [[ "$product_type" == "DATASAFE" ]]; then
        if [[ -d "${oracle_home}/network/admin" ]]; then
            export TNS_ADMIN="${oracle_home}/network/admin"
        elif [[ -n "${DATASAFE_INSTALL_DIR:-}" ]] && [[ -d "${DATASAFE_INSTALL_DIR}/network/admin" ]]; then
            export TNS_ADMIN="${DATASAFE_INSTALL_DIR}/network/admin"
        fi
    elif [[ "$product_type" == "ICLIENT" ]]; then
        # Instant Client: TNS_ADMIN usually in separate location
        export TNS_ADMIN="${TNS_ADMIN:-${ORADBA_BASE}/network/admin}"
    fi
    
    # Set NLS variables
    export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.AL32UTF8}"
    export NLS_DATE_FORMAT="${NLS_DATE_FORMAT:-YYYY-MM-DD HH24:MI:SS}"
    
    # Set ORA_NLS10 for older versions (optional)
    if [[ -d "${oracle_home}/nls/data" ]]; then
        export ORA_NLS10="${oracle_home}/nls/data"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_set_asm_environment
# Purpose.: Set ASM-specific environment variables
# Args....: None (uses ORACLE_SID, ORACLE_HOME)
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_set_asm_environment() {
    # ASM uses sysasm privilege instead of sysdba
    export ORACLE_SYSASM="TRUE"
    
    # Set GRID_HOME if not already set
    if [[ -z "$GRID_HOME" ]]; then
        export GRID_HOME="$ORACLE_HOME"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_set_product_environment
# Purpose.: Set product-specific environment variables
# Args....: $1 - Product type
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_set_product_environment() {
    local product_type="$1"
    
    case "$product_type" in
        GRID)
            export GRID_HOME="${ORACLE_HOME}"
            ;;
            
        DATASAFE)
            # DATASAFE_HOME points to connector home (same as ORACLE_HOME)
            export DATASAFE_HOME="${ORACLE_HOME}"
            
            # DATASAFE_INSTALL_DIR already set in oradba_set_oracle_vars if applicable
            
            if [[ -d "${ORACLE_HOME}/config" ]]; then
                export DATASAFE_CONFIG="${ORACLE_HOME}/config"
            fi
            ;;
            
        OUD)
            # OUD instance home
            if [[ -d "${ORACLE_HOME}/instances/${ORACLE_SID}" ]]; then
                export OUD_INSTANCE_HOME="${ORACLE_HOME}/instances/${ORACLE_SID}"
                export OUD_INSTANCE_CONFIG="${OUD_INSTANCE_HOME}/OUD/config"
            fi
            ;;
            
        WLS)
            # WebLogic Server variables
            export WLS_HOME="${ORACLE_HOME}/wlserver"
            if [[ -n "${WLS_DOMAIN_BASE}" ]]; then
                export DOMAIN_HOME="${WLS_DOMAIN_BASE}/${ORACLE_SID}"
            fi
            ;;
    esac
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_product_needs_client
# Purpose.: Determine if a product type needs external client tools
# Args....: $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)
# Returns.: 0 if product needs client, 1 if it has its own client
# ------------------------------------------------------------------------------
oradba_product_needs_client() {
    local product_type="$1"
    
    # Products without their own Oracle client tools
    case "${product_type}" in
        DATASAFE|OUD|WLS|WEBLOGIC|OMS|EMAGENT)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: oradba_resolve_client_home
# Purpose.: Resolve client home path from ORADBA_CLIENT_PATH_FOR_NON_CLIENT setting
# Args....: None (reads ORADBA_CLIENT_PATH_FOR_NON_CLIENT env var)
# Returns.: 0 on success, 1 if no client found
# Output..: Prints resolved client home path
# Notes...: Accepts DATABASE, CLIENT, or ICLIENT product types
#           (all have client tools like sqlplus, sqlldr, etc.)
# ------------------------------------------------------------------------------
oradba_resolve_client_home() {
    local setting="${ORADBA_CLIENT_PATH_FOR_NON_CLIENT:-none}"
    local homes_file
    local client_home=""
    
    # Handle "none" - no client needed
    [[ "${setting}" == "none" ]] && return 1
    
    # Get oracle homes config file
    if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
        homes_file=$(get_oracle_homes_path 2>/dev/null) || homes_file=""
    else
        homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
    fi
    
    [[ ! -f "${homes_file}" ]] && return 1
    
    # Handle "auto" - find first CLIENT or ICLIENT
    if [[ "${setting}" == "auto" ]]; then
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
        while IFS=':' read -r name path ptype _order alias _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Convert type to uppercase for comparison
            local ptype_upper="${ptype^^}"
            
            # Check if it's a client type or database (databases have client tools)
            if [[ "${ptype_upper}" == "CLIENT" ]] || [[ "${ptype_upper}" == "ICLIENT" ]] || [[ "${ptype_upper}" == "DATABASE" ]]; then
                # Validate directory exists
                if [[ -d "${path}" ]]; then
                    client_home="${path}"
                    break
                fi
            fi
        done < <(grep -v "^#\|^$" "${homes_file}")
    else
        # Handle specific client name (could be name or alias)
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
        while IFS=':' read -r name path ptype _order alias _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Convert type to uppercase for comparison
            local ptype_upper="${ptype^^}"
            
            # Match by name or alias
            if [[ "${name}" == "${setting}" ]] || [[ "${alias}" == "${setting}" ]]; then
                # Validate it has client tools (database, client, or instant client)
                if [[ "${ptype_upper}" == "CLIENT" ]] || [[ "${ptype_upper}" == "ICLIENT" ]] || [[ "${ptype_upper}" == "DATABASE" ]]; then
                    # Validate directory exists
                    if [[ -d "${path}" ]]; then
                        client_home="${path}"
                        break
                    fi
                fi
            fi
        done < <(grep -v "^#\|^$" "${homes_file}")
    fi
    
    # Return result
    if [[ -n "${client_home}" ]] && [[ -d "${client_home}" ]]; then
        echo "${client_home}"
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_add_client_path
# Purpose.: Add client tools to PATH for non-client products
# Args....: $1 - Current product type (uppercase)
# Returns.: 0 on success or not needed, 1 on error
# Notes...: Appends client bin directory to PATH after existing entries
# ------------------------------------------------------------------------------
oradba_add_client_path() {
    local product_type="$1"
    local client_home=""
    local client_bin=""
    
    # Check if product needs client tools
    if ! oradba_product_needs_client "${product_type}"; then
        _oradba_builder_log DEBUG "Product ${product_type} has built-in client, skipping client path"
        return 0
    fi
    
    # Resolve client home
    client_home=$(oradba_resolve_client_home) || {
        _oradba_builder_log DEBUG "No client home configured or found for ${product_type}"
        return 0
    }
    
    _oradba_builder_log DEBUG "Resolved client home: ${client_home}"
    
    # Determine bin directory based on client type
    # Check if it's instant client (no bin subdirectory)
    # Use a loop to check for libclntsh.so* files (avoid SC2144)
    local is_iclient=0
    if [[ ! -d "${client_home}/bin" ]]; then
        for lib_file in "${client_home}"/libclntsh.so*; do
            if [[ -f "$lib_file" ]]; then
                is_iclient=1
                break
            fi
        done
    fi
    
    if [[ $is_iclient -eq 1 ]]; then
        # Instant client - add home directly
        client_bin="${client_home}"
    else
        # Regular client - add bin subdirectory
        client_bin="${client_home}/bin"
    fi
    
    # Validate bin directory exists
    if [[ ! -d "${client_bin}" ]]; then
        _oradba_builder_log WARN "Client bin directory not found: ${client_bin}"
        return 1
    fi
    
    # Export ORACLE_CLIENT_HOME
    export ORACLE_CLIENT_HOME="${client_home}"
    _oradba_builder_log DEBUG "Exported ORACLE_CLIENT_HOME=${ORACLE_CLIENT_HOME}"
    
    # Check if already in PATH
    if [[ ":${PATH}:" == *":${client_bin}:"* ]]; then
        _oradba_builder_log DEBUG "Client path already in PATH: ${client_bin}"
        return 0
    fi
    
    # Append to PATH (after current entries)
    export PATH="${PATH}:${client_bin}"
    _oradba_builder_log DEBUG "Added client path for ${product_type}: ${client_bin}"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_product_needs_java
# Purpose.: Determine if a product type needs Java (JAVA_HOME)
# Args....: $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)
# Returns.: 0 if product needs Java, 1 if it has its own or doesn't need Java
# ------------------------------------------------------------------------------
oradba_product_needs_java() {
    local product_type="$1"
    
    # Products that typically need Java but may not ship it
    # (or users want to override the shipped Java)
    case "${product_type}" in
        DATASAFE|OUD|WLS|WEBLOGIC|OMS|EMAGENT)
            return 0
            ;;
        *)
            # DATABASE and CLIENT products ship Java in $ORACLE_HOME/java
            # but users might want to override it
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: oradba_resolve_java_home
# Purpose.: Resolve Java home path from ORADBA_JAVA_PATH_FOR_NON_JAVA setting
# Args....: $1 - Current ORACLE_HOME (optional, for auto-detection of $ORACLE_HOME/java)
# Returns.: 0 on success, 1 if no Java found
# Output..: Prints resolved Java home path
# Notes...: Supports "auto", "none", or named Java from oradba_homes.conf
# ------------------------------------------------------------------------------
oradba_resolve_java_home() {
    local current_oracle_home="${1:-}"
    local setting="${ORADBA_JAVA_PATH_FOR_NON_JAVA:-none}"
    local homes_file
    local java_home=""
    
    # Handle "none" - no Java needed
    [[ "${setting}" == "none" ]] && return 1
    
    # Handle "auto" - find Java automatically
    if [[ "${setting}" == "auto" ]]; then
        # First, check $ORACLE_HOME/java if ORACLE_HOME is set
        if [[ -n "${current_oracle_home}" ]] && [[ -d "${current_oracle_home}/java" ]]; then
            local java_in_home="${current_oracle_home}/java"
            if [[ -x "${java_in_home}/bin/java" ]]; then
                _oradba_builder_log DEBUG "Found Java in ORACLE_HOME: ${java_in_home}"
                echo "${java_in_home}"
                return 0
            fi
        fi
        
        # Get oracle homes config file
        if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
            homes_file=$(get_oracle_homes_path 2>/dev/null) || homes_file=""
        else
            homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
        fi
        
        [[ ! -f "${homes_file}" ]] && return 1
        
        # Find first JAVA type in oradba_homes.conf
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
        while IFS=':' read -r name path ptype _order alias _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Convert type to uppercase for comparison
            local ptype_upper="${ptype^^}"
            
            # Check if it's a Java type
            if [[ "${ptype_upper}" == "JAVA" ]]; then
                # Validate directory exists and has java binary
                if [[ -d "${path}" ]] && [[ -x "${path}/bin/java" ]]; then
                    java_home="${path}"
                    _oradba_builder_log DEBUG "Found Java in oradba_homes.conf: ${java_home}"
                    break
                fi
            fi
        done < <(grep -v "^#\|^$" "${homes_file}")
    else
        # Handle specific Java name (could be name or alias)
        # Get oracle homes config file
        if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
            homes_file=$(get_oracle_homes_path 2>/dev/null) || homes_file=""
        else
            homes_file="${ORADBA_BASE}/etc/oradba_homes.conf"
        fi
        
        [[ ! -f "${homes_file}" ]] && return 1
        
        # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
        while IFS=':' read -r name path ptype _order alias _desc _version; do
            # Skip empty lines and comments
            [[ -z "${name}" ]] && continue
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            
            # Convert type to uppercase for comparison
            local ptype_upper="${ptype^^}"
            
            # Match by name or alias
            if [[ "${name}" == "${setting}" ]] || [[ "${alias}" == "${setting}" ]]; then
                # Validate it's a Java type
                if [[ "${ptype_upper}" == "JAVA" ]]; then
                    # Validate directory exists and has java binary
                    if [[ -d "${path}" ]] && [[ -x "${path}/bin/java" ]]; then
                        java_home="${path}"
                        _oradba_builder_log DEBUG "Resolved Java home by name '${setting}': ${java_home}"
                        break
                    fi
                fi
            fi
        done < <(grep -v "^#\|^$" "${homes_file}")
    fi
    
    # Return result
    if [[ -n "${java_home}" ]] && [[ -d "${java_home}" ]]; then
        echo "${java_home}"
        return 0
    fi
    
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_add_java_path
# Purpose.: Add Java to JAVA_HOME and PATH for products that need it
# Args....: $1 - Current product type (uppercase)
#           $2 - Current ORACLE_HOME (optional, for auto-detection)
# Returns.: 0 on success or not needed, 1 on error
# Notes...: Prepends Java bin directory to PATH (takes precedence)
#           Exports JAVA_HOME environment variable
# ------------------------------------------------------------------------------
oradba_add_java_path() {
    local product_type="$1"
    local current_oracle_home="${2:-}"
    local java_home=""
    local java_bin=""
    
    # Check if product needs Java or if user wants to override
    # If ORADBA_JAVA_PATH_FOR_NON_JAVA is set to anything other than "none",
    # we honor it regardless of product type (allows override for DATABASE/CLIENT)
    local setting="${ORADBA_JAVA_PATH_FOR_NON_JAVA:-none}"
    if [[ "${setting}" == "none" ]]; then
        # Only auto-detect for products that need Java
        if ! oradba_product_needs_java "${product_type}"; then
            _oradba_builder_log DEBUG "Product ${product_type} has built-in Java or doesn't need it, skipping"
            return 0
        fi
    fi
    
    # Resolve Java home
    java_home=$(oradba_resolve_java_home "${current_oracle_home}") || {
        _oradba_builder_log DEBUG "No Java home configured or found for ${product_type}"
        return 0
    }
    
    _oradba_builder_log DEBUG "Resolved Java home: ${java_home}"
    
    # Set Java bin directory
    if [[ -d "${java_home}/bin" ]]; then
        java_bin="${java_home}/bin"
    else
        _oradba_builder_log WARN "Java bin directory not found: ${java_home}/bin"
        return 1
    fi
    
    # Export JAVA_HOME
    export JAVA_HOME="${java_home}"
    _oradba_builder_log DEBUG "Exported JAVA_HOME=${JAVA_HOME}"
    
    # Check if already in PATH
    if [[ ":${PATH}:" == *":${java_bin}:"* ]]; then
        _oradba_builder_log DEBUG "Java path already in PATH: ${java_bin}"
        return 0
    fi
    
    # Prepend to PATH (before current entries so it takes precedence)
    export PATH="${java_bin}:${PATH}"
    _oradba_builder_log DEBUG "Added Java path for ${product_type}: ${java_bin}"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_build_environment
# Purpose.: Main function to build complete environment
# Args....: $1 - SID or ORACLE_HOME
# Returns.: 0 on success, 1 on error
# ------------------------------------------------------------------------------
oradba_build_environment() {
    local target="$1"
    local oracle_sid=""
    local oracle_home=""
    local product_type=""
    
    [[ -z "$target" ]] && return 1
    
    # Determine if target is SID or ORACLE_HOME
    if [[ -d "$target" ]]; then
        # Target is a path (ORACLE_HOME)
        oracle_home="$target"
        
        # Get metadata from oradba_homes.conf
        product_type=$(oradba_get_product_type "$oracle_home")
        
        # Set SID to dummy SID if available
        oracle_sid=$(oradba_get_home_metadata "$oracle_home" "Dummy_SID" 2>/dev/null)
        oracle_sid="${oracle_sid:-dummy}"
        
    else
        # Target is SID
        oracle_sid="$target"
        
        # Check if ASM instance
        if oradba_is_asm_instance "$oracle_sid"; then
            product_type="GRID"
        fi
        
        # Find in oratab
        local oratab_entry
        oratab_entry=$(oradba_find_sid "$oracle_sid")
        if [[ $? -eq 0 ]]; then
            IFS='|' read -r sid home _flag <<< "$oratab_entry"
            oracle_home="$home"
            
            # Determine product type
            if [[ -z "$product_type" ]]; then
                product_type=$(oradba_get_product_type "$oracle_home")
            fi
        else
            return 1
        fi
    fi
    
    # Validate we have required info
    [[ -z "$oracle_home" ]] && return 1
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Clean existing Oracle paths
    oradba_clean_path
    
    # Set core Oracle variables
    oradba_set_oracle_vars "$oracle_sid" "$oracle_home" "$product_type" || return 1
    
    # Set PATH
    oradba_add_oracle_path "$oracle_home" "$product_type"
    
    # Set library path
    oradba_set_lib_path "$oracle_home" "$product_type"
    
    # Set product-specific environment
    oradba_set_product_environment "$product_type"
    
    # Special handling for ASM
    if oradba_is_asm_instance "$oracle_sid"; then
        oradba_set_asm_environment
    fi
    
    # Apply configuration files (Phase 2)
    if command -v oradba_apply_product_config &>/dev/null; then
        oradba_apply_product_config "$product_type" "$oracle_sid"
    fi
    
    # Add Java path for products that need it (e.g., DataSafe, OUD, WebLogic)
    # This happens BEFORE client path so Java takes precedence (prepended to PATH)
    # Pass oracle_home for auto-detection of $ORACLE_HOME/java
    oradba_add_java_path "$product_type" "$oracle_home"
    
    # Add client path for non-client products (e.g., DataSafe, OUD, WebLogic)
    # This happens after product PATH setup and config files, but before deduplication
    oradba_add_client_path "$product_type"
    
    # Final PATH deduplication after all configs loaded
    # This ensures custom PATH additions from config files are deduplicated
    # Must happen AFTER config files to catch any PATH modifications they make
    local final_path final_lib_path
    final_path="$(oradba_dedupe_path "$PATH")"
    export PATH="$final_path"
    
    # Also deduplicate library paths if they exist
    if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
        final_lib_path="$(oradba_dedupe_path "$LD_LIBRARY_PATH")"
        export LD_LIBRARY_PATH="$final_lib_path"
    fi
    if [[ -n "${LIBPATH:-}" ]]; then
        final_lib_path="$(oradba_dedupe_path "$LIBPATH")"
        export LIBPATH="$final_lib_path"
    fi
    if [[ -n "${SHLIB_PATH:-}" ]]; then
        final_lib_path="$(oradba_dedupe_path "$SHLIB_PATH")"
        export SHLIB_PATH="$final_lib_path"
    fi
    if [[ -n "${DYLD_LIBRARY_PATH:-}" ]]; then
        final_lib_path="$(oradba_dedupe_path "$DYLD_LIBRARY_PATH")"
        export DYLD_LIBRARY_PATH="$final_lib_path"
    fi
    
    # Load extensions after Oracle environment is fully set up
    # Extensions are loaded based on priority (mixed with Oracle paths)
    # Default priority: 50 (loaded after Oracle paths)
    if command -v load_extensions >/dev/null 2>&1; then
        load_extensions
    fi
    
    # Set tracking variables
    export ORADBA_ENV_LOADED=1
    export ORADBA_CURRENT_SID="$oracle_sid"
    export ORADBA_CURRENT_HOME="$oracle_home"
    export ORADBA_PRODUCT_TYPE="$product_type"
    
    return 0
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
