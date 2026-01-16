#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: oradba_registry.sh
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.16
# Version..: 0.1.0
# Purpose..: Unified registry API for Oracle installations
# Notes....: Provides abstraction layer over oratab and oradba_homes.conf
# Reference: Architecture Review & Refactoring Plan (Phase 1.1)
# License..: Apache License Version 2.0, January 2004 as shown
#            at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Module Constants
# ------------------------------------------------------------------------------
readonly REGISTRY_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly REGISTRY_FORMAT_VERSION="1"

# Installation object field separator
readonly REGISTRY_FIELD_SEP="|"

# ------------------------------------------------------------------------------
# Function: oradba_registry_get_all
# Purpose.: Get all Oracle installations (databases + homes)
# Args....: None
# Returns.: 0 on success, 1 on error
# Output..: List of installation objects (one per line)
# Format..: type|name|home|version|flags|order|alias|desc
# Notes...: Combines oratab and oradba_homes.conf entries
# ------------------------------------------------------------------------------
oradba_registry_get_all() {
    # shellcheck disable=SC2034
    local -a installations=()
    local oratab_found=false
    local homes_found=false
    
    # 1. Parse oratab (if exists)
    local oratab_path
    oratab_path=$(get_oratab_path 2>/dev/null) || oratab_path="/etc/oratab"
    
    if [[ -f "${oratab_path}" ]] && [[ -r "${oratab_path}" ]]; then
        oratab_found=true
        while IFS=: read -r sid home flags; do
            # Skip comments and empty lines
            [[ "${sid}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${sid}" ]] && continue
            
            # Skip if home doesn't exist
            [[ ! -d "${home}" ]] && continue
            
            # Detect product type and version
            local ptype="database"
            local version="AUTO"
            
            if type -t detect_product_type &>/dev/null; then
                ptype=$(detect_product_type "${home}" 2>/dev/null) || ptype="database"
            fi
            
            # Format: type|name|home|version|flags|order|alias|desc
            printf "%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s\n" \
                "${ptype}" "${sid}" "${home}" "${version}" "${flags:-}" "10" "" "From oratab"
        done < "${oratab_path}"
    fi
    
    # 2. Parse oradba_homes.conf (if exists)
    local homes_path
    homes_path=$(get_oracle_homes_path 2>/dev/null) || homes_path="${ORADBA_PREFIX}/etc/oradba_homes.conf"
    
    if [[ -f "${homes_path}" ]] && [[ -r "${homes_path}" ]]; then
        homes_found=true
        while IFS=: read -r name path ptype order alias desc version; do
            # Skip comments and empty lines
            [[ "${name}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${name}" ]] && continue
            
            # Skip if home doesn't exist
            [[ ! -d "${path}" ]] && continue
            
            # Use detected type if not specified or unknown
            if [[ -z "${ptype}" ]] || [[ "${ptype}" == "unknown" ]]; then
                if type -t detect_product_type &>/dev/null; then
                    ptype=$(detect_product_type "${path}" 2>/dev/null) || ptype="unknown"
                fi
            fi
            
            # Format: type|name|home|version|flags|order|alias|desc
            printf "%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s\n" \
                "${ptype}" "${name}" "${path}" "${version:-AUTO}" "" "${order:-50}" "${alias:-}" "${desc:-From oradba_homes.conf}"
        done < "${homes_path}"
    fi
    
    # 3. Auto-discover if enabled and no entries found
    if [[ "${oratab_found}" == "false" ]] && [[ "${homes_found}" == "false" ]]; then
        if [[ "${ORADBA_AUTO_DISCOVER:-true}" == "true" ]]; then
            oradba_log DEBUG "No registry files found, attempting auto-discovery"
            if type -t oradba_registry_discover_all &>/dev/null; then
                oradba_registry_discover_all
            fi
        fi
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_get_by_name
# Purpose.: Get installation by name (SID or home name)
# Args....: $1 - Installation name to search for
# Returns.: 0 on success, 1 if not found
# Output..: Installation object if found
# ------------------------------------------------------------------------------
oradba_registry_get_by_name() {
    local search_name="$1"
    
    [[ -z "${search_name}" ]] && return 1
    
    local found=false
    while IFS="${REGISTRY_FIELD_SEP}" read -r ptype name home version flags order alias desc; do
        if [[ "${name}" == "${search_name}" ]] || [[ "${alias}" == "${search_name}" ]]; then
            printf "%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s\n" \
                "${ptype}" "${name}" "${home}" "${version}" "${flags}" "${order}" "${alias}" "${desc}"
            found=true
        fi
    done < <(oradba_registry_get_all)
    
    [[ "${found}" == "true" ]] && return 0 || return 1
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_get_by_type
# Purpose.: Get all installations of specific product type
# Args....: $1 - Product type (database, datasafe, client, oud, etc.)
# Returns.: 0 on success
# Output..: List of installation objects matching type
# ------------------------------------------------------------------------------
oradba_registry_get_by_type() {
    local search_type="$1"
    
    [[ -z "${search_type}" ]] && return 1
    
    while IFS="${REGISTRY_FIELD_SEP}" read -r ptype name home version flags order alias desc; do
        if [[ "${ptype}" == "${search_type}" ]]; then
            printf "%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s${REGISTRY_FIELD_SEP}%s\n" \
                "${ptype}" "${name}" "${home}" "${version}" "${flags}" "${order}" "${alias}" "${desc}"
        fi
    done < <(oradba_registry_get_all)
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_get_databases
# Purpose.: Get all database installations
# Returns.: 0 on success
# Output..: List of database installation objects
# ------------------------------------------------------------------------------
oradba_registry_get_databases() {
    oradba_registry_get_by_type "database"
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_get_field
# Purpose.: Extract specific field from installation object
# Args....: $1 - Installation object
#           $2 - Field name (type|name|home|version|flags|order|alias|desc)
# Returns.: 0 on success, 1 on error
# Output..: Field value
# ------------------------------------------------------------------------------
oradba_registry_get_field() {
    local install_obj="$1"
    local field_name="$2"
    
    [[ -z "${install_obj}" ]] && return 1
    [[ -z "${field_name}" ]] && return 1
    
    IFS="${REGISTRY_FIELD_SEP}" read -r ptype name home version flags order alias desc <<< "${install_obj}"
    
    case "${field_name}" in
        type) echo "${ptype}" ;;
        name) echo "${name}" ;;
        home) echo "${home}" ;;
        version) echo "${version}" ;;
        flags) echo "${flags}" ;;
        order) echo "${order}" ;;
        alias) echo "${alias}" ;;
        desc|description) echo "${desc}" ;;
        *) return 1 ;;
    esac
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_discover_all
# Purpose.: Auto-discover Oracle installations on the system
# Returns.: 0 on success
# Output..: List of discovered installation objects
# Notes...: Scans common locations and running processes
# ------------------------------------------------------------------------------
oradba_registry_discover_all() {
    # shellcheck disable=SC2034
    local -a discovered=()
    
    oradba_log DEBUG "Auto-discovery not yet implemented"
    # TODO: Implement auto-discovery in Phase 1.2
    # - Check running pmon/tnslsnr processes
    # - Scan /u01/app/oracle/product, /opt/oracle/product
    # - Use oraInventory if available
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: oradba_registry_validate
# Purpose.: Validate registry format and consistency
# Returns.: 0 if valid, 1 if errors found
# Output..: Validation errors (if any)
# ------------------------------------------------------------------------------
oradba_registry_validate() {
    local errors=0
    local -A seen_names=()
    
    while IFS="${REGISTRY_FIELD_SEP}" read -r ptype name home version flags order alias desc; do
        # Check for duplicate names
        if [[ -n "${seen_names[${name}]:-}" ]]; then
            oradba_log WARN "Duplicate installation name: ${name}"
            ((errors++))
        fi
        seen_names["${name}"]=1
        
        # Check home exists
        if [[ ! -d "${home}" ]]; then
            oradba_log WARN "Installation home not found: ${home} (${name})"
            ((errors++))
        fi
        
        # Check product type is valid
        case "${ptype}" in
            database|datasafe|client|iclient|oud|weblogic|grid|oms|emagent) ;;
            *) oradba_log WARN "Unknown product type: ${ptype} (${name})" && ((errors++)) ;;
        esac
    done < <(oradba_registry_get_all)
    
    if [[ ${errors} -gt 0 ]]; then
        oradba_log ERROR "Registry validation failed with ${errors} error(s)"
        return 1
    fi
    
    oradba_log DEBUG "Registry validation passed"
    return 0
}

# ------------------------------------------------------------------------------
# Module loaded successfully
# ------------------------------------------------------------------------------
oradba_log DEBUG "Module loaded: oradba_registry.sh v${REGISTRY_VERSION}"
