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
# Purpose.: Add Oracle binaries to PATH
# Args....: $1 - ORACLE_HOME
#          $2 - Product type (optional)
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_add_oracle_path() {
    local oracle_home="$1"
    local product_type="${2:-RDBMS}"
    local new_path=""
    
    [[ ! -d "$oracle_home" ]] && return 1
    
    case "$product_type" in
        RDBMS|CLIENT|GRID)
            # Full installations: bin + OPatch
            if [[ -d "${oracle_home}/bin" ]]; then
                new_path="${oracle_home}/bin"
            fi
            
            if [[ -d "${oracle_home}/OPatch" ]]; then
                new_path="${new_path:+${new_path}:}${oracle_home}/OPatch"
            fi
            
            # If RDBMS with separate Grid, add Grid bin
            if [[ "$product_type" == "RDBMS" ]] && [[ -n "$GRID_HOME" ]] && [[ "$GRID_HOME" != "$oracle_home" ]]; then
                if [[ -d "${GRID_HOME}/bin" ]]; then
                    new_path="${new_path:+${new_path}:}${GRID_HOME}/bin"
                fi
            fi
            ;;
            
        ICLIENT)
            # Instant Client: No bin directory, libraries only
            # sqlplus may be in the lib directory
            if [[ -d "$oracle_home" ]]; then
                new_path="$oracle_home"
            fi
            ;;
            
        DATASAFE)
            # DataSafe: oracle_cman_home/bin directory
            if [[ -d "${oracle_home}/oracle_cman_home/bin" ]]; then
                new_path="${oracle_home}/oracle_cman_home/bin"
            elif [[ -d "${oracle_home}/bin" ]]; then
                new_path="${oracle_home}/bin"
            fi
            ;;
            
        OUD)
            # OUD: bin directory
            if [[ -d "${oracle_home}/bin" ]]; then
                new_path="${oracle_home}/bin"
            fi
            ;;
            
        WLS)
            # WebLogic: wlserver/server/bin
            if [[ -d "${oracle_home}/wlserver/server/bin" ]]; then
                new_path="${oracle_home}/wlserver/server/bin"
            elif [[ -d "${oracle_home}/server/bin" ]]; then
                new_path="${oracle_home}/server/bin"
            fi
            ;;
    esac
    
    # Prepend to PATH only if directory exists
    if [[ -n "$new_path" ]] && [[ -d "$new_path" ]]; then
        export PATH="${new_path}:${PATH}"
        # Deduplicate PATH to avoid repeated entries
        export PATH="$(oradba_dedupe_path "$PATH")"
    fi
}

# ------------------------------------------------------------------------------
# Function: oradba_set_lib_path
# Purpose.: Set library path (LD_LIBRARY_PATH, SHLIB_PATH, etc.)
# Args....: $1 - ORACLE_HOME
#          $2 - Product type (optional)
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_set_lib_path() {
    local oracle_home="$1"
    local product_type="${2:-RDBMS}"
    local lib_path=""
    local lib_var="LD_LIBRARY_PATH"
    
    [[ ! -d "$oracle_home" ]] && return 1
    
    # Determine platform library variable
    case "$(uname -s)" in
        HP-UX)  lib_var="SHLIB_PATH" ;;
        AIX)    lib_var="LIBPATH" ;;
        Darwin) lib_var="DYLD_LIBRARY_PATH" ;;
    esac
    
    # Add Oracle libraries based on product type
    case "$product_type" in
        RDBMS|CLIENT|GRID)
            # Prefer lib64 on 64-bit systems
            if [[ -d "${oracle_home}/lib64" ]]; then
                lib_path="${oracle_home}/lib64"
            fi
            
            if [[ -d "${oracle_home}/lib" ]]; then
                lib_path="${lib_path:+${lib_path}:}${oracle_home}/lib"
            fi
            
            # Add Grid libraries if separate
            if [[ -n "$GRID_HOME" ]] && [[ "$GRID_HOME" != "$oracle_home" ]]; then
                if [[ -d "${GRID_HOME}/lib" ]]; then
                    lib_path="${lib_path:+${lib_path}:}${GRID_HOME}/lib"
                fi
            fi
            ;;
            
        ICLIENT)
            # Instant Client: libraries in root directory
            if [[ -d "${oracle_home}/lib64" ]]; then
                lib_path="${oracle_home}/lib64"
            elif [[ -d "${oracle_home}/lib" ]]; then
                lib_path="${oracle_home}/lib"
            else
                # Root directory for Instant Client
                lib_path="${oracle_home}"
            fi
            ;;
            
        DATASAFE)
            # DataSafe: oracle_cman_home/lib directory
            if [[ -d "${oracle_home}/oracle_cman_home/lib" ]]; then
                lib_path="${oracle_home}/oracle_cman_home/lib"
            elif [[ -d "${oracle_home}/lib" ]]; then
                lib_path="${oracle_home}/lib"
            fi
            ;;
            
        OUD|WLS)
            # These products may have lib directories
            if [[ -d "${oracle_home}/lib" ]]; then
                lib_path="${oracle_home}/lib"
            fi
            ;;
    esac
    
    # Preserve existing library path
    eval "local existing=\"\${${lib_var}}\""
    if [[ -n "$existing" ]]; then
        lib_path="${lib_path:+${lib_path}:}${existing}"
    fi
        # Deduplicate library path
    lib_path=\"$(oradba_dedupe_path \"$lib_path\")\"
        # Export library path variable
    if [[ -n "$lib_path" ]]; then
        export ${lib_var}="$lib_path"
    fi
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
    
    # Core Oracle variables
    export ORACLE_SID="$oracle_sid"
    export ORACLE_HOME="$oracle_home"
    
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
            export DATASAFE_HOME="${ORACLE_HOME}"
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
    
    # Set tracking variables
    export ORADBA_ENV_LOADED=1
    export ORADBA_CURRENT_SID="$oracle_sid"
    export ORADBA_CURRENT_HOME="$oracle_home"
    export ORADBA_PRODUCT_TYPE="$product_type"
    
    return 0
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
