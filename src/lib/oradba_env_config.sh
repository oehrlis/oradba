#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_env_config.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-14
# Revision...: 0.19.1
# Purpose....: Configuration file processing for Oracle environment management
# Notes......: Part of Phase 2 implementation - section-based config processing
#              Handles DEFAULT, RDBMS, CLIENT, ICLIENT, GRID, ASM, DATASAFE, OUD, WLS sections
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_ENV_CONFIG_LOADED}" ]] && return 0
readonly ORADBA_ENV_CONFIG_LOADED=1

# ------------------------------------------------------------------------------
# Function: oradba_apply_config_section
# Purpose.: Apply configuration from a specific section in config file
# Args....: $1 - Config file path
#          $2 - Section name (DEFAULT|RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS)
# Returns.: 0 on success, 1 if file not found
# ------------------------------------------------------------------------------
oradba_apply_config_section() {
    local config_file="$1"
    local section="$2"
    
    [[ ! -f "$config_file" ]] && return 1
    
    local in_section=0
    local line
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line="${line##*([[:space:]])}"
        line="${line%%*([[:space:]])}"
        
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Check for section headers [SECTION]
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [[ "$current_section" == "$section" ]]; then
                in_section=1
            else
                in_section=0
            fi
            continue
        fi
        
        # Process lines in active section
        if [[ $in_section -eq 1 ]]; then
            # Handle export statements
            if [[ "$line" =~ ^export[[:space:]] ]]; then
                eval "$line" 2>/dev/null
            # Handle aliases
            elif [[ "$line" =~ ^alias[[:space:]] ]]; then
                eval "$line" 2>/dev/null
            # Handle direct variable assignments
            elif [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
                eval "export $line" 2>/dev/null
            fi
        fi
    done < "$config_file"
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_load_generic_configs
# Purpose.: Load all generic configuration files in order
# Args....: $1 - Section name to apply (optional, defaults to DEFAULT)
# Returns.: 0 on success
# Output..: Exports variables from configuration files
# ------------------------------------------------------------------------------
oradba_load_generic_configs() {
    local section="${1:-DEFAULT}"
    local config_dir="${ORADBA_BASE}/etc"
    
    # Configuration files in load order
    local config_files=(
        "${config_dir}/oradba_core.conf"
        "${config_dir}/oradba_standard.conf"
        "${config_dir}/oradba_local.conf"
        "${config_dir}/oradba_customer.conf"
    )
    
    # Load each config file with specified section
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            oradba_apply_config_section "$config_file" "$section"
        fi
    done
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_load_sid_config
# Purpose.: Load SID-specific configuration file
# Args....: $1 - SID or instance name
#          $2 - Section name to load from SID config (optional, defaults to DEFAULT)
# Returns.: 0 on success, 1 if config not found
# ------------------------------------------------------------------------------
oradba_load_sid_config() {
    local sid="$1"
    local section="${2:-DEFAULT}"
    local config_file="${ORADBA_BASE}/etc/sid/sid.${sid}.conf"
    
    [[ ! -f "$config_file" ]] && return 1
    
    # Apply DEFAULT section first
    oradba_apply_config_section "$config_file" "DEFAULT"
    
    # Apply product-specific section if different from DEFAULT
    if [[ "$section" != "DEFAULT" ]]; then
        oradba_apply_config_section "$config_file" "$section"
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_apply_product_config
# Purpose.: Apply configuration for specific product type
# Args....: $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS)
#          $2 - SID (optional, for ASM detection)
# Returns.: 0 on success
# ------------------------------------------------------------------------------
oradba_apply_product_config() {
    local product_type="$1"
    local sid="${2:-${ORACLE_SID}}"
    
    # First apply DEFAULT section
    oradba_load_generic_configs "DEFAULT"
    
    # Apply product-specific section
    case "$product_type" in
        RDBMS)
            oradba_load_generic_configs "RDBMS"
            
            # Check if it's an ASM instance
            if [[ "$sid" =~ ^\+ASM ]]; then
                oradba_load_generic_configs "ASM"
            fi
            ;;
        CLIENT)
            oradba_load_generic_configs "CLIENT"
            ;;
        ICLIENT)
            oradba_load_generic_configs "ICLIENT"
            ;;
        GRID)
            oradba_load_generic_configs "GRID"
            
            # Grid homes also support ASM
            if [[ "$sid" =~ ^\+ASM ]]; then
                oradba_load_generic_configs "ASM"
            fi
            ;;
        ASM)
            # ASM can be standalone or part of RDBMS/GRID
            oradba_load_generic_configs "ASM"
            ;;
        DATASAFE)
            oradba_load_generic_configs "DATASAFE"
            ;;
        OUD)
            oradba_load_generic_configs "OUD"
            ;;
        WLS)
            oradba_load_generic_configs "WLS"
            ;;
    esac
    
    # Finally, apply SID-specific config if exists
    if [[ -n "$sid" ]]; then
        oradba_load_sid_config "$sid" "$product_type" 2>/dev/null || true
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_expand_variables
# Purpose.: Expand variables in a string (simple implementation)
# Args....: $1 - String with variables
# Returns.: 0 on success
# Output..: Expanded string
# ------------------------------------------------------------------------------
oradba_expand_variables() {
    local input="$1"
    
    # Use eval for variable expansion
    # Note: This is safe within the controlled config file context
    eval "echo \"$input\"" 2>/dev/null
}

# ------------------------------------------------------------------------------
# Function: oradba_list_config_sections
# Purpose.: List all sections defined in a config file
# Args....: $1 - Config file path
# Returns.: 0 on success
# Output..: Section names, one per line
# ------------------------------------------------------------------------------
oradba_list_config_sections() {
    local config_file="$1"
    
    [[ ! -f "$config_file" ]] && return 1
    
    grep -o '^\[[^]]*\]' "$config_file" | tr -d '[]' | sort -u
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_validate_config_file
# Purpose.: Validate configuration file syntax
# Args....: $1 - Config file path
# Returns.: 0 if valid, 1 if errors found
# Output..: Error messages for invalid syntax
# ------------------------------------------------------------------------------
oradba_validate_config_file() {
    local config_file="$1"
    local errors=0
    local line_num=0
    
    [[ ! -f "$config_file" ]] && {
        echo "ERROR: Config file not found: $config_file" >&2
        return 1
    }
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Remove leading/trailing whitespace
        line="${line##*([[:space:]])}"
        line="${line%%*([[:space:]])}"
        
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Check for malformed section headers (starts with [ but doesn't end with ])
        if [[ "$line" =~ ^\[ ]] && [[ ! "$line" =~ ^\[[^]]+\]$ ]]; then
            echo "ERROR: Invalid section syntax at line $line_num: $line" >&2
            ((errors++))
            continue
        fi
        
        # Check section headers
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            local section="${BASH_REMATCH[1]}"
            # Validate section name
            if [[ ! "$section" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
                echo "WARNING: Invalid section name at line $line_num: [$section]" >&2
            fi
            continue
        fi
        
        # Validate variable assignments
        if [[ "$line" =~ ^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            continue
        fi
        
        # Validate aliases
        if [[ "$line" =~ ^alias[[:space:]] ]]; then
            continue
        fi
        
        # If we get here, syntax is invalid
        echo "ERROR: Invalid syntax at line $line_num: $line" >&2
        ((errors++))
    done < "$config_file"
    
    [[ $errors -eq 0 ]] && return 0
    return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_get_config_value
# Purpose.: Get a specific variable value from config section
# Args....: $1 - Config file path
#          $2 - Section name
#          $3 - Variable name
# Returns.: 0 on success, 1 if not found
# Output..: Variable value
# ------------------------------------------------------------------------------
oradba_get_config_value() {
    local config_file="$1"
    local section="$2"
    local var_name="$3"
    
    [[ ! -f "$config_file" ]] && return 1
    
    local in_section=0
    local line
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line="${line##*([[:space:]])}"
        line="${line%%*([[:space:]])}"
        
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [[ "$current_section" == "$section" ]]; then
                in_section=1
            else
                in_section=0
            fi
            continue
        fi
        
        # Look for variable in active section
        if [[ $in_section -eq 1 ]]; then
            if [[ "$line" =~ ^(export[[:space:]]+)?${var_name}=(.*)$ ]]; then
                local value="${BASH_REMATCH[2]}"
                # Remove quotes if present
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                echo "$value"
                return 0
            fi
        fi
    done < "$config_file"
    
    return 1
}

# Functions are available when this library is sourced
# No need to export - reduces environment pollution
