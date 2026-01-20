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
# Notes...: Uses plugin_build_path() from product-specific plugins
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
    
    # Try to load and use plugin
    local plugin_file="${ORADBA_BASE}/src/lib/plugins/${product_type}_plugin.sh"
    if [[ -f "${plugin_file}" ]]; then
        # shellcheck source=/dev/null
        source "${plugin_file}" 2>/dev/null
        
        # Call plugin function if it exists
        if declare -f plugin_build_path >/dev/null 2>&1; then
            new_path=$(plugin_build_path "${oracle_home}")
            oradba_log DEBUG "Plugin ${product_type}: PATH components = ${new_path}"
        fi
    fi
    
    # Fallback if plugin not found or failed
    if [[ -z "$new_path" ]]; then
        oradba_log DEBUG "Using fallback PATH for ${product_type}"
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
    
    # Try to load and use plugin
    local plugin_file="${ORADBA_BASE}/src/lib/plugins/${product_type}_plugin.sh"
    if [[ -f "${plugin_file}" ]]; then
        # shellcheck source=/dev/null
        source "${plugin_file}" 2>/dev/null
        
        # Call plugin function if it exists
        if declare -f plugin_build_lib_path >/dev/null 2>&1; then
            lib_path=$(plugin_build_lib_path "${oracle_home}")
            oradba_log DEBUG "Plugin ${product_type}: LIB_PATH components = ${lib_path}"
        fi
    fi
    
    # Fallback if plugin not found or failed
    if [[ -z "$lib_path" ]]; then
        oradba_log DEBUG "Using fallback LIB_PATH for ${product_type}"
        if [[ -d "${oracle_home}/lib64" ]]; then
            lib_path="${oracle_home}/lib64"
        fi
        if [[ -d "${oracle_home}/lib" ]]; then
            lib_path="${lib_path:+${lib_path}:}${oracle_home}/lib"
        fi
    fi
    
    # Clean existing Oracle library paths from the environment
    eval "local existing=\"\${${lib_var}}\""
    if [[ -n "$existing" ]]; then
        oradba_log DEBUG "Cleaning ${lib_var}: ${existing}"
        local cleaned_path=""
        local IFS=":"
        for dir in $existing; do
            # Skip Oracle-related directories
            if [[ "$dir" =~ /oracle/ ]] || [[ "$dir" =~ /grid/ ]] || [[ "$dir" =~ instantclient ]]; then
                oradba_log DEBUG "Removing old Oracle path: ${dir}"
                continue
            fi
            
            # Add to cleaned path
            cleaned_path="${cleaned_path:+${cleaned_path}:}${dir}"
        done
        oradba_log DEBUG "Cleaned ${lib_var}: ${cleaned_path}"
        
        # Append cleaned non-Oracle paths to new Oracle paths
        if [[ -n "$cleaned_path" ]]; then
            lib_path="${lib_path:+${lib_path}:}${cleaned_path}"
        fi
    fi
    
    # Deduplicate library path
    lib_path="$(oradba_dedupe_path "$lib_path")"
    
    oradba_log DEBUG "Final ${lib_var} to be exported: ${lib_path}"
    
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
        local plugin_file="${ORADBA_BASE}/src/lib/plugins/datasafe_plugin.sh"
        if [[ -f "${plugin_file}" ]]; then
            # shellcheck source=/dev/null
            source "${plugin_file}"
            datasafe_parent="${oracle_home}"
            adjusted_home=$(plugin_adjust_environment "${oracle_home}")
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
        while IFS=';' read -r oracle_home product_type _version _edition _db_type _position _dummy_sid short_name _desc; do
            # Skip empty lines and comments
            [[ -z "${oracle_home}" ]] && continue
            [[ "${oracle_home}" =~ ^[[:space:]]*# ]] && continue
            
            # Check if it's a client type
            if [[ "${product_type}" == "CLIENT" ]] || [[ "${product_type}" == "ICLIENT" ]]; then
                # Validate directory exists
                if [[ -d "${oracle_home}" ]]; then
                    client_home="${oracle_home}"
                    break
                fi
            fi
        done < "${homes_file}"
    else
        # Handle specific client name (could be short name or full name)
        # Search in homes file by short name
        while IFS=';' read -r oracle_home product_type _version _edition _db_type _position _dummy_sid short_name _desc; do
            # Skip empty lines and comments
            [[ -z "${oracle_home}" ]] && continue
            [[ "${oracle_home}" =~ ^[[:space:]]*# ]] && continue
            
            # Match by short name
            if [[ "${short_name}" == "${setting}" ]]; then
                # Validate it's a client type
                if [[ "${product_type}" == "CLIENT" ]] || [[ "${product_type}" == "ICLIENT" ]]; then
                    # Validate directory exists
                    if [[ -d "${oracle_home}" ]]; then
                        client_home="${oracle_home}"
                        break
                    fi
                fi
            fi
        done < "${homes_file}"
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
        oradba_log DEBUG "Product ${product_type} has built-in client, skipping client path"
        return 0
    fi
    
    # Resolve client home
    client_home=$(oradba_resolve_client_home) || {
        oradba_log DEBUG "No client home configured or found for ${product_type}"
        return 0
    }
    
    oradba_log DEBUG "Resolved client home: ${client_home}"
    
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
        oradba_log WARN "Client bin directory not found: ${client_bin}"
        return 1
    fi
    
    # Check if already in PATH
    if [[ ":${PATH}:" == *":${client_bin}:"* ]]; then
        oradba_log DEBUG "Client path already in PATH: ${client_bin}"
        return 0
    fi
    
    # Append to PATH (after current entries)
    export PATH="${PATH}:${client_bin}"
    oradba_log DEBUG "Added client path for ${product_type}: ${client_bin}"
    
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
    
    # Set tracking variables
    export ORADBA_ENV_LOADED=1
    export ORADBA_CURRENT_SID="$oracle_sid"
    export ORADBA_CURRENT_HOME="$oracle_home"
    export ORADBA_PRODUCT_TYPE="$product_type"
    
    return 0
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
