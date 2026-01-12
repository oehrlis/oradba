#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: extensions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.13.6
# Purpose....: Extension system library for OraDBA
# Notes......: Provides functions for discovering, loading, and managing
#              OraDBA extensions. Extensions are directories parallel to
#              ORADBA_BASE (e.g., /opt/oracle/local/customer) with optional
#              bin/, sql/, rcv/, etc/ subdirectories.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Requires: common.sh must be sourced first

# ------------------------------------------------------------------------------
# Extension Discovery Functions
# ------------------------------------------------------------------------------

# Discover extensions in ORADBA_LOCAL_BASE
# Scans for directories containing .extension marker file
# Returns: List of extension paths (one per line)
discover_extensions() {
    local base_dir="${ORADBA_LOCAL_BASE}"
    local extensions=()

    if [[ ! -d "${base_dir}" ]]; then
        oradba_log DEBUG "Extension base directory not found: ${base_dir}"
        return 0
    fi

    oradba_log DEBUG "Scanning for extensions in: ${base_dir}"

    # Find directories with .extension marker
    for dir in "${base_dir}"/*; do
        # Skip if not a directory
        [[ ! -d "${dir}" ]] && continue

        local dir_name
        dir_name="$(basename "${dir}")"

        # Skip oradba itself (the main OraDBA installation)
        if [[ "${dir_name}" == "oradba" ]] || [[ "${dir}" == "${ORADBA_BASE}" ]]; then
            oradba_log DEBUG "Skipping main OraDBA directory: ${dir_name}"
            continue
        fi

        # Check for .extension marker file
        if [[ -f "${dir}/.extension" ]]; then
            extensions+=("${dir}")
            oradba_log DEBUG "Found extension with metadata: ${dir_name}"
        elif [[ -d "${dir}/bin" ]] || [[ -d "${dir}/sql" ]] || [[ -d "${dir}/rcv" ]]; then
            # Also discover extensions without metadata if they have expected directories
            extensions+=("${dir}")
            oradba_log DEBUG "Found extension without metadata: ${dir_name}"
        fi
    done

    # Output one per line (only if array is not empty)
    if [[ ${#extensions[@]} -gt 0 ]]; then
        printf "%s\n" "${extensions[@]}"
    fi
}

# Get all extensions (auto-discovered + manually configured)
# Returns: List of extension paths (one per line)
get_all_extensions() {
    local extensions=()

    # Auto-discover extensions if enabled
    if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS}" == "true" ]]; then
        while IFS= read -r ext; do
            [[ -n "${ext}" ]] && extensions+=("${ext}")
        done < <(discover_extensions)
    fi

    # Add manually configured extensions
    if [[ -n "${ORADBA_EXTENSION_PATHS}" ]]; then
        IFS=':' read -ra manual_exts <<< "${ORADBA_EXTENSION_PATHS}"
        for ext in "${manual_exts[@]}"; do
            [[ -n "${ext}" ]] && [[ -d "${ext}" ]] && extensions+=("${ext}")
        done
    fi

    # Remove duplicates while preserving order (only if array is not empty)
    if [[ ${#extensions[@]} -gt 0 ]]; then
        printf "%s\n" "${extensions[@]}" | awk '!seen[$0]++'
    fi
}

# ------------------------------------------------------------------------------
# Extension Metadata Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: get_extension_property
# Purpose.: Unified property accessor for extension metadata
# Syntax..: get_extension_property <ext_path> <property> [fallback] [check_config]
# Params..: ext_path      - Path to extension directory
#           property      - Property name to retrieve (e.g., "name", "version", "priority")
#           fallback      - Optional fallback value if property not found
#           check_config  - Optional "true" to check ORADBA_EXT_<NAME>_<PROPERTY> override
# Returns.: Property value from metadata, config override, or fallback
# Note....: New in v0.13.3 - Eliminates metadata access duplication
# ------------------------------------------------------------------------------
get_extension_property() {
    local ext_path="$1"
    local property="$2"
    local fallback="${3:-}"
    local check_config="${4:-false}"
    local metadata="${ext_path}/.extension"
    local value=""

    # Check config override first (if requested)
    if [[ "${check_config}" == "true" ]]; then
        local ext_name
        ext_name="$(basename "${ext_path}")"
        local config_var="ORADBA_EXT_${ext_name^^}_${property^^}"
        value="${!config_var}"
    fi

    # Fall back to metadata file
    if [[ -z "${value}" ]] && [[ -f "${metadata}" ]]; then
        value=$(parse_extension_metadata "${metadata}" "${property}")
    fi

    # Use fallback if still empty
    if [[ -z "${value}" ]]; then
        value="${fallback}"
    fi

    echo "${value}"
}

# Parse extension metadata file
# Usage: parse_extension_metadata <metadata_file> <key>
# Returns: Value for the given key, or empty string if not found
parse_extension_metadata() {
    local metadata_file="$1"
    local key="$2"

    if [[ ! -f "${metadata_file}" ]]; then
        return 1
    fi

    # Simple key-value parser for YAML-like format
    # Handles: "key: value" or "key:value"
    local value
    value=$(grep "^${key}:" "${metadata_file}" 2> /dev/null | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    echo "${value}"
}

# Get extension name
# Usage: get_extension_name <ext_path>
# Returns: Extension name (from metadata or directory name)
get_extension_name() {
    local ext_path="$1"
    local fallback
    fallback="$(basename "${ext_path}")"
    get_extension_property "${ext_path}" "name" "${fallback}"
}

# Get extension version
# Usage: get_extension_version <ext_path>
# Returns: Version string or "unknown"
get_extension_version() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "version" "unknown"
}

# Get extension description
# Usage: get_extension_description <ext_path>
# Returns: Description string or empty
get_extension_description() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "description"
}

# Get extension priority (for sorting)
# Usage: get_extension_priority <ext_path>
# Returns: Priority number (lower = loaded first, default 50)
get_extension_priority() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "priority" "50" "true"
}

# Check if extension is enabled
# Usage: is_extension_enabled <ext_name> <ext_path>
# Returns: 0 if enabled, 1 if disabled
is_extension_enabled() {
    local ext_name="$1"
    local ext_path="$2"
    local enabled
    enabled=$(get_extension_property "${ext_path}" "enabled" "true" "true")
    [[ "${enabled}" == "true" ]]
}

# Check what directories an extension provides
# Usage: extension_provides <ext_path> <type>
# Types: bin, sql, rcv, etc, lib
# Returns: 0 if provides, 1 if not
extension_provides() {
    local ext_path="$1"
    local type="$2"
    local metadata="${ext_path}/.extension"
    local provides

    # Check metadata first
    if [[ -f "${metadata}" ]]; then
        provides=$(parse_extension_metadata "${metadata}" "provides.${type}" 2> /dev/null)
        if [[ -n "${provides}" ]]; then
            [[ "${provides}" == "true" ]] && return 0 || return 1
        fi
    fi

    # Fall back to checking directory existence
    [[ -d "${ext_path}/${type}" ]]
}

# ------------------------------------------------------------------------------
# Extension Sorting Functions
# ------------------------------------------------------------------------------

# Sort extensions by priority
# Usage: sort_extensions_by_priority <ext_path1> <ext_path2> ...
# Returns: Sorted list of extension paths (one per line)
sort_extensions_by_priority() {
    local extensions=("$@")
    local priorities=()
    local ext priority name

    # Build array of "priority:name:path" for stable sorting
    for ext in "${extensions[@]}"; do
        priority=$(get_extension_priority "${ext}")
        name="$(basename "${ext}")"
        priorities+=("${priority}:${name}:${ext}")
    done

    # Sort numerically by priority (descending), then alphabetically by name (ascending)
    # We reverse priority order because extensions are prepended to PATH
    # So lower priority (50) loads first, higher priority (10) loads last and ends up first in PATH
    printf "%s\n" "${priorities[@]}" | sort -t: -k1,1rn -k2,2 | cut -d: -f3-
}

# ------------------------------------------------------------------------------
# Extension Loading Functions
# ------------------------------------------------------------------------------

# Remove extension paths from PATH/SQLPATH
# Usage: remove_extension_paths
remove_extension_paths() {
    if [[ -n "${ORADBA_LOCAL_BASE}" ]]; then
        # Remove all paths matching ORADBA_LOCAL_BASE/*/bin from PATH (except oradba itself)
        local cleaned_path=""
        IFS=':' read -ra path_parts <<< "${PATH}"
        for part in "${path_parts[@]}"; do
            # Skip if matches extension pattern, but not the main oradba directory
            if [[ "${part}" =~ ^${ORADBA_LOCAL_BASE}/[^/]+/bin$ ]] && [[ "${part}" != "${ORADBA_LOCAL_BASE}/oradba/bin" ]]; then
                oradba_log DEBUG "Removing extension path: ${part}"
                continue
            fi
            cleaned_path="${cleaned_path:+${cleaned_path}:}${part}"
        done
        export PATH="${cleaned_path}"

        # Remove extension paths from SQLPATH (except oradba itself)
        if [[ -n "${SQLPATH}" ]]; then
            local cleaned_sqlpath=""
            IFS=':' read -ra sqlpath_parts <<< "${SQLPATH}"
            for part in "${sqlpath_parts[@]}"; do
                # Skip if matches extension pattern, but not the main oradba directory
                if [[ "${part}" =~ ^${ORADBA_LOCAL_BASE}/[^/]+/sql$ ]] && [[ "${part}" != "${ORADBA_LOCAL_BASE}/oradba/sql" ]]; then
                    oradba_log DEBUG "Removing extension SQLPATH: ${part}"
                    continue
                fi
                cleaned_sqlpath="${cleaned_sqlpath:+${cleaned_sqlpath}:}${part}"
            done
            export SQLPATH="${cleaned_sqlpath}"
        fi
    fi
}

# Deduplicate PATH (keep first occurrence)
# Usage: deduplicate_path
deduplicate_path() {
    local seen=()
    local new_path=""

    IFS=':' read -ra path_parts <<< "${PATH}"
    for part in "${path_parts[@]}"; do
        # Skip empty parts
        [[ -z "${part}" ]] && continue

        # Check if already seen
        local found=false
        for seen_part in "${seen[@]}"; do
            if [[ "${part}" == "${seen_part}" ]]; then
                found=true
                break
            fi
        done

        # Add if not seen
        if [[ "${found}" == "false" ]]; then
            seen+=("${part}")
            new_path="${new_path:+${new_path}:}${part}"
        fi
    done

    export PATH="${new_path}"
}

# Deduplicate SQLPATH (keep first occurrence)
# Usage: deduplicate_sqlpath
deduplicate_sqlpath() {
    [[ -z "${SQLPATH}" ]] && return 0

    local seen=()
    local new_sqlpath=""

    IFS=':' read -ra sqlpath_parts <<< "${SQLPATH}"
    for part in "${sqlpath_parts[@]}"; do
        # Skip empty parts
        [[ -z "${part}" ]] && continue

        # Check if already seen
        local found=false
        for seen_part in "${seen[@]}"; do
            if [[ "${part}" == "${seen_part}" ]]; then
                found=true
                break
            fi
        done

        # Add if not seen
        if [[ "${found}" == "false" ]]; then
            seen+=("${part}")
            new_sqlpath="${new_sqlpath:+${new_sqlpath}:}${part}"
        fi
    done

    export SQLPATH="${new_sqlpath}"
}

# Load all enabled extensions
# Called from oraenv.sh after configuration loading
load_extensions() {
    local extensions=()
    local ext_path

    # Save original PATH/SQLPATH on first run
    if [[ -z "${ORADBA_ORIGINAL_PATH}" ]]; then
        export ORADBA_ORIGINAL_PATH="${PATH}"
        oradba_log DEBUG "Saved original PATH"
    fi
    if [[ -z "${ORADBA_ORIGINAL_SQLPATH}" ]] && [[ -n "${SQLPATH}" ]]; then
        export ORADBA_ORIGINAL_SQLPATH="${SQLPATH}"
        oradba_log DEBUG "Saved original SQLPATH"
    fi

    # Remove any existing extension paths before re-loading
    oradba_log DEBUG "Cleaning extension paths from PATH/SQLPATH"
    remove_extension_paths

    oradba_log DEBUG "Starting extension discovery and loading..."

    # Get all extensions (discovered + manual)
    while IFS= read -r ext_path; do
        [[ -n "${ext_path}" ]] && extensions+=("${ext_path}")
    done < <(get_all_extensions)

    # Check if any extensions found
    if [[ ${#extensions[@]} -eq 0 ]]; then
        oradba_log DEBUG "No extensions found"
        return 0
    fi

    oradba_log DEBUG "Found ${#extensions[@]} extension(s)"

    # Sort by priority and load
    while IFS= read -r ext_path; do
        load_extension "${ext_path}"
    done < <(sort_extensions_by_priority "${extensions[@]}")

    # Deduplicate PATH and SQLPATH to remove any duplicates
    oradba_log DEBUG "Deduplicating PATH and SQLPATH"
    deduplicate_path
    deduplicate_sqlpath

    oradba_log DEBUG "Extension loading complete"
}

# Load single extension
# Usage: load_extension <ext_path>
# Returns: 0 on success, 1 on error (with warning)
load_extension() {
    local ext_path="$1"
    local ext_name metadata

    # Validate path
    if [[ ! -d "${ext_path}" ]]; then
        oradba_log WARN "Extension directory not found: ${ext_path}"
        return 1
    fi

    # Get extension name
    ext_name="$(get_extension_name "${ext_path}")"

    # Check if disabled via config
    if ! is_extension_enabled "${ext_name}" "${ext_path}"; then
        oradba_log DEBUG "Extension '${ext_name}' is disabled, skipping"
        return 0
    fi

    oradba_log DEBUG "Loading extension: ${ext_name} (${ext_path})"

    # Add to PATH (bin directory)
    if [[ -d "${ext_path}/bin" ]]; then
        # Add to beginning of PATH (after ORADBA_BIN)
        export PATH="${ext_path}/bin:${PATH}"
        oradba_log DEBUG "  Added ${ext_name}/bin to PATH"
    fi

    # Add to SQLPATH (sql directory)
    if [[ -d "${ext_path}/sql" ]]; then
        # Use add_to_sqlpath from common.sh if available, otherwise append
        if command -v add_to_sqlpath > /dev/null 2>&1; then
            add_to_sqlpath "${ext_path}/sql"
        else
            export SQLPATH="${SQLPATH:+${SQLPATH}:}${ext_path}/sql"
        fi
        oradba_log DEBUG "  Added ${ext_name}/sql to SQLPATH"
    fi

    # Add RMAN search path (rcv directory)
    if [[ -d "${ext_path}/rcv" ]]; then
        export ORADBA_RCV_PATHS="${ORADBA_RCV_PATHS:+${ORADBA_RCV_PATHS}:}${ext_path}/rcv"
        oradba_log DEBUG "  Added ${ext_name}/rcv to RMAN search paths"
    fi

    # Create navigation alias (cd<extname> or cde<extname>)
    create_extension_alias "${ext_name}" "${ext_path}"

    # Export extension path variables for reference
    local var_name="ORADBA_EXT_${ext_name^^}_PATH"
    export "${var_name}=${ext_path}"

    # Export <EXTENSION>_BASE variable (e.g., USZ_BASE=/opt/oracle/local/usz)
    local base_var="${ext_name^^}_BASE"
    export "${base_var}=${ext_path}"

    # Show version if available
    local version
    version=$(get_extension_version "${ext_path}")
    if [[ "${version}" != "unknown" ]]; then
        oradba_log DEBUG "Loaded extension: ${ext_name} (v${version})"
    else
        oradba_log DEBUG "Loaded extension: ${ext_name}"
    fi

    return 0
}

# Create navigation alias for extension
# Usage: create_extension_alias <ext_name> <ext_path>
create_extension_alias() {
    local ext_name="$1"
    local ext_path="$2"
    local alias_name

    # Create alias like: cde<name> (cd extension)
    alias_name="cde${ext_name}"

    # Use safe_alias if available (respects coexistence mode)
    if command -v safe_alias > /dev/null 2>&1; then
        safe_alias "${alias_name}" "cd '${ext_path}'"
    else
        # Fallback: direct alias
        # shellcheck disable=SC2139  # Intentional: expand at definition time
        alias "${alias_name}=cd '${ext_path}'"
    fi

    oradba_log DEBUG "  Created alias: ${alias_name}"
}

# ------------------------------------------------------------------------------
# Extension Information Functions
# ------------------------------------------------------------------------------

# List all extensions with status
# Usage: list_extensions [--verbose]
list_extensions() {
    local verbose=false
    [[ "$1" == "--verbose" ]] && verbose=true

    local extensions=()
    local ext_path ext_name version enabled priority

    # Get all extensions
    while IFS= read -r ext_path; do
        [[ -n "${ext_path}" ]] && extensions+=("${ext_path}")
    done < <(get_all_extensions)

    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found"
        return 0
    fi

    echo "OraDBA Extensions:"
    echo "=================="
    echo ""

    # Sort by priority
    while IFS= read -r ext_path; do
        ext_name="$(get_extension_name "${ext_path}")"
        version=$(get_extension_version "${ext_path}")
        priority=$(get_extension_priority "${ext_path}")

        # Check enabled status
        if is_extension_enabled "${ext_name}" "${ext_path}"; then
            enabled="✓ enabled"
        else
            enabled="✗ disabled"
        fi

        # Basic info
        printf "%-20s v%-10s [%s] (priority: %s)\n" "${ext_name}" "${version}" "${enabled}" "${priority}"

        # Verbose info
        if [[ "${verbose}" == "true" ]]; then
            echo "  Path: ${ext_path}"
            local desc
            desc=$(get_extension_description "${ext_path}")
            [[ -n "${desc}" ]] && echo "  Description: ${desc}"

            # Show what it provides
            local provides=()
            [[ -d "${ext_path}/bin" ]] && provides+=("bin")
            [[ -d "${ext_path}/sql" ]] && provides+=("sql")
            [[ -d "${ext_path}/rcv" ]] && provides+=("rcv")
            [[ -d "${ext_path}/etc" ]] && provides+=("etc")
            [[ -d "${ext_path}/lib" ]] && provides+=("lib")

            if [[ ${#provides[@]} -gt 0 ]]; then
                echo "  Provides: ${provides[*]}"
            fi
            echo ""
        fi
    done < <(sort_extensions_by_priority "${extensions[@]}")
}

# Show detailed information about a specific extension
# Usage: show_extension_info <ext_name_or_path>
show_extension_info() {
    local ext_identifier="$1"
    local ext_path ext_name version desc author priority enabled

    if [[ -z "${ext_identifier}" ]]; then
        oradba_log ERROR "Extension name or path required"
        return 1
    fi

    # Determine if identifier is a path or name
    if [[ -d "${ext_identifier}" ]]; then
        ext_path="${ext_identifier}"
    else
        # Search by name
        while IFS= read -r path; do
            if [[ "$(get_extension_name "${path}")" == "${ext_identifier}" ]]; then
                ext_path="${path}"
                break
            fi
        done < <(get_all_extensions)
    fi

    if [[ -z "${ext_path}" ]] || [[ ! -d "${ext_path}" ]]; then
        oradba_log ERROR "Extension not found: ${ext_identifier}"
        return 1
    fi

    # Get extension details
    ext_name="$(get_extension_name "${ext_path}")"
    version=$(get_extension_version "${ext_path}")
    desc=$(get_extension_description "${ext_path}")
    priority=$(get_extension_priority "${ext_path}")

    # Get author from metadata
    if [[ -f "${ext_path}/.extension" ]]; then
        author=$(parse_extension_metadata "${ext_path}/.extension" "author")
    fi

    # Check enabled status
    if is_extension_enabled "${ext_name}" "${ext_path}"; then
        enabled="yes"
    else
        enabled="no"
    fi

    # Display information
    echo "Extension Information"
    echo "====================="
    echo ""
    echo "Name:        ${ext_name}"
    echo "Version:     ${version}"
    echo "Enabled:     ${enabled}"
    echo "Priority:    ${priority}"
    [[ -n "${author}" ]] && echo "Author:      ${author}"
    [[ -n "${desc}" ]] && echo "Description: ${desc}"
    echo ""
    echo "Path:        ${ext_path}"
    echo ""

    # Show directory structure
    echo "Structure:"
    [[ -d "${ext_path}/bin" ]] && echo "  ✓ bin/  (scripts added to PATH)"
    [[ -d "${ext_path}/sql" ]] && echo "  ✓ sql/  (scripts added to SQLPATH)"
    [[ -d "${ext_path}/rcv" ]] && echo "  ✓ rcv/  (RMAN scripts)"
    [[ -d "${ext_path}/etc" ]] && echo "  ✓ etc/  (configuration examples)"
    [[ -d "${ext_path}/lib" ]] && echo "  ✓ lib/  (library files)"

    # Show navigation alias
    echo ""
    echo "Navigation alias: cde${ext_name}"
}

# ------------------------------------------------------------------------------
# Extension Validation Functions
# ------------------------------------------------------------------------------

# Validate extension structure (basic check)
# Usage: validate_extension <ext_path>
# Returns: 0 if valid, 1 if warnings found
validate_extension() {
    local ext_path="$1"
    local warnings=0
    local ext_name

    if [[ ! -d "${ext_path}" ]]; then
        echo "ERROR: Directory does not exist: ${ext_path}"
        return 1
    fi

    ext_name="$(basename "${ext_path}")"

    echo "Validating extension: ${ext_name}"
    echo "Path: ${ext_path}"
    echo ""

    # Check for metadata file
    if [[ ! -f "${ext_path}/.extension" ]]; then
        echo "⚠ Warning: No .extension metadata file found"
        echo "  Extension will work but won't have version/priority info"
        ((warnings++))
    else
        echo "✓ Metadata file present"

        # Validate metadata content
        local name version
        name=$(parse_extension_metadata "${ext_path}/.extension" "name")
        version=$(parse_extension_metadata "${ext_path}/.extension" "version")

        [[ -n "${name}" ]] && echo "  Name: ${name}" || {
            echo "  ⚠ Warning: 'name' not set in metadata"
            ((warnings++))
        }
        [[ -n "${version}" ]] && echo "  Version: ${version}" || {
            echo "  ⚠ Warning: 'version' not set in metadata"
            ((warnings++))
        }
    fi

    # Check for at least one content directory
    if [[ ! -d "${ext_path}/bin" ]] && [[ ! -d "${ext_path}/sql" ]] && [[ ! -d "${ext_path}/rcv" ]]; then
        echo "⚠ Warning: No bin/, sql/, or rcv/ directories found"
        echo "  Extension has no content to load"
        ((warnings++))
    fi

    # Check directories
    echo ""
    echo "Directories:"
    [[ -d "${ext_path}/bin" ]] && echo "  ✓ bin/" || echo "  - bin/ (not present)"
    [[ -d "${ext_path}/sql" ]] && echo "  ✓ sql/" || echo "  - sql/ (not present)"
    [[ -d "${ext_path}/rcv" ]] && echo "  ✓ rcv/" || echo "  - rcv/ (not present)"
    [[ -d "${ext_path}/etc" ]] && echo "  ✓ etc/" || echo "  - etc/ (not present)"
    [[ -d "${ext_path}/lib" ]] && echo "  ✓ lib/" || echo "  - lib/ (not present)"

    echo ""
    if [[ ${warnings} -eq 0 ]]; then
        echo "✓ Extension structure is valid"
        return 0
    else
        echo "⚠ ${warnings} warning(s) found"
        return 1
    fi
}

# EOF
