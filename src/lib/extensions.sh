#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: extensions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Extension system library for OraDBA
# Notes......: Provides functions for discovering, loading, and managing
#              OraDBA extensions. Extensions are directories parallel to
#              ORADBA_BASE (e.g., /opt/oracle/local/customer) with optional
#              bin/, sql/, rcv/, etc/ subdirectories.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Requires: oradba_common.sh must be sourced first

# Prevent multiple sourcing
[[ -n "${ORADBA_EXTENSIONS_LOADED}" ]] && return 0
readonly ORADBA_EXTENSIONS_LOADED=1

# ------------------------------------------------------------------------------
# Extension Discovery Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: discover_extensions
# Purpose.: Discover extensions in ORADBA_LOCAL_BASE
# Args....: None
# Returns.: 0 on success
# Output..: List of extension paths (one per line) containing .extension marker file
# ------------------------------------------------------------------------------
discover_extensions() {
    local base_dir="${ORADBA_LOCAL_BASE}"
    local extensions=()

    if [[ -z "${base_dir}" ]]; then
        oradba_log DEBUG "Extension base directory not configured (ORADBA_LOCAL_BASE is empty)"
        return 0
    fi

    if [[ ! -d "${base_dir}" ]]; then
        oradba_log DEBUG "Extension base directory not found: ${base_dir}"
        return 0
    fi

    oradba_log DEBUG "Scanning for extensions in: ${base_dir}"

    # Find directories with .extension marker or content directories
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

        # Check for .extension marker file or content directories (bin/, sql/, rcv/)
        if [[ -f "${dir}/.extension" ]]; then
            extensions+=("${dir}")
            oradba_log DEBUG "Found extension with metadata: ${dir_name}"
        elif [[ -d "${dir}/bin" ]] || [[ -d "${dir}/sql" ]] || [[ -d "${dir}/rcv" ]]; then
            extensions+=("${dir}")
            oradba_log DEBUG "Found extension with content directories: ${dir_name}"
        fi
    done

    # Output one per line (only if array is not empty)
    if [[ ${#extensions[@]} -gt 0 ]]; then
        printf "%s\n" "${extensions[@]}"
    fi
}

# ------------------------------------------------------------------------------
# Function: get_all_extensions
# Purpose.: Get all extensions (auto-discovered + manually configured)
# Args....: None
# Returns.: 0 on success
# Output..: List of extension paths (one per line)
# ------------------------------------------------------------------------------
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
        # Sanitize extension name for use in variable names (replace hyphens with underscores)
        local safe_ext_name="${ext_name//-/_}"
        local config_var="ORADBA_EXT_${safe_ext_name^^}_${property^^}"
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

# ------------------------------------------------------------------------------
# Function: parse_extension_metadata
# Purpose.: Parse extension metadata file for key-value pairs
# Args....: $1 - Metadata file path
#           $2 - Key to retrieve
# Returns.: 0 on success, 1 if file not found
# Output..: Value for the given key, or empty string if not found
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: get_extension_name
# Purpose.: Get extension name from metadata or directory name
# Args....: $1 - Extension path
# Returns.: 0 on success
# Output..: Extension name
# ------------------------------------------------------------------------------
get_extension_name() {
    local ext_path="$1"
    local fallback
    fallback="$(basename "${ext_path}")"
    get_extension_property "${ext_path}" "name" "${fallback}"
}

# ------------------------------------------------------------------------------
# Function: get_extension_version
# Purpose.: Get extension version from metadata
# Args....: $1 - Extension path
# Returns.: 0 on success
# Output..: Version string or "unknown"
# ------------------------------------------------------------------------------
get_extension_version() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "version" "unknown"
}

# ------------------------------------------------------------------------------
# Function: get_extension_description
# Purpose.: Get extension description from metadata
# Args....: $1 - Extension path
# Returns.: 0 on success
# Output..: Description string or empty
# ------------------------------------------------------------------------------
get_extension_description() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "description"
}

# ------------------------------------------------------------------------------
# Function: get_extension_priority
# Purpose.: Get extension priority for sorting
# Args....: $1 - Extension path
# Returns.: 0 on success
# Output..: Priority number (lower = loaded first, default 50)
# ------------------------------------------------------------------------------
get_extension_priority() {
    local ext_path="$1"
    get_extension_property "${ext_path}" "priority" "50" "true"
}

# ------------------------------------------------------------------------------
# Function: is_extension_enabled
# Purpose.: Check if extension is enabled
# Args....: $1 - Extension name
#           $2 - Extension path
# Returns.: 0 if enabled, 1 if disabled
# Output..: None
# ------------------------------------------------------------------------------
is_extension_enabled() {
    local ext_name="$1"
    local ext_path="$2"
    local enabled
    enabled=$(get_extension_property "${ext_path}" "enabled" "true" "true")
    [[ "${enabled}" == "true" ]]
}

# ------------------------------------------------------------------------------
# Function: extension_provides
# Extension Sorting Functions
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: sort_extensions_by_priority
# Purpose.: Sort extensions by priority for loading order
# Args....: $@ - Extension paths (space-separated)
# Returns.: 0 on success
# Output..: Sorted list of extension paths (one per line)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: remove_extension_paths
# Purpose.: Remove extension paths from PATH and SQLPATH
# Args....: None
# Returns.: 0 on success
# Output..: Updates PATH and SQLPATH environment variables
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: deduplicate_path
# Purpose.: Deduplicate PATH (keep first occurrence)
# Args....: None
# Returns.: 0 on success
# Output..: Updates PATH environment variable
# Notes...: Uses oradba_dedupe_path() from oradba_env_builder.sh if available
# ------------------------------------------------------------------------------
deduplicate_path() {
    if command -v oradba_dedupe_path >/dev/null 2>&1; then
        local deduped_path
        deduped_path="$(oradba_dedupe_path "${PATH}")"
        export PATH="${deduped_path}"
    else
        # Fallback if oradba_dedupe_path not available
        local seen=()
        local new_path=""
        IFS=':' read -ra path_parts <<< "${PATH}"
        for part in "${path_parts[@]}"; do
            [[ -z "${part}" ]] && continue
            local found=false
            for seen_part in "${seen[@]}"; do
                if [[ "${part}" == "${seen_part}" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "${found}" == "false" ]]; then
                seen+=("${part}")
                new_path="${new_path:+${new_path}:}${part}"
            fi
        done
        export PATH="${new_path}"
    fi
}

# ------------------------------------------------------------------------------
# Function: deduplicate_sqlpath
# Purpose.: Deduplicate SQLPATH (keep first occurrence)
# Args....: None
# Returns.: 0 on success
# Output..: Updates SQLPATH environment variable
# Notes...: Uses oradba_dedupe_path() from oradba_env_builder.sh if available
# ------------------------------------------------------------------------------
deduplicate_sqlpath() {
    [[ -z "${SQLPATH}" ]] && return 0

    if command -v oradba_dedupe_path >/dev/null 2>&1; then
        local deduped_sqlpath
        deduped_sqlpath="$(oradba_dedupe_path "${SQLPATH}")"
        export SQLPATH="${deduped_sqlpath}"
    else
        # Fallback if oradba_dedupe_path not available
        local seen=()
        local new_sqlpath=""
        IFS=':' read -ra sqlpath_parts <<< "${SQLPATH}"
        for part in "${sqlpath_parts[@]}"; do
            [[ -z "${part}" ]] && continue
            local found=false
            for seen_part in "${seen[@]}"; do
                if [[ "${part}" == "${seen_part}" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "${found}" == "false" ]]; then
                seen+=("${part}")
                new_sqlpath="${new_sqlpath:+${new_sqlpath}:}${part}"
            fi
        done
        export SQLPATH="${new_sqlpath}"
    fi
}

# ------------------------------------------------------------------------------
# Function: load_extensions
# Purpose.: Load all enabled extensions
# Args....: None
# Returns.: 0 on success
# Output..: Updates PATH and SQLPATH with extension directories
# Notes...: Called from oraenv.sh after configuration loading
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: load_extension
# Purpose.: Load single extension
# Args....: $1 - Extension path
# Returns.: 0 on success, 1 on error (with warning)
# Output..: Updates PATH/SQLPATH, sources library files, creates aliases
# ------------------------------------------------------------------------------
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

    # Check what the extension provides (from .extension metadata)
    metadata="${ext_path}/.extension"
    local provides_bin="true"
    local provides_sql="true"
    local provides_rcv="true"
    
    # Read provides section if metadata exists
    if [[ -f "${metadata}" ]]; then
        # Check each provides flag
        provides_bin=$(grep -A5 "^provides:" "${metadata}" | grep "bin:" | awk '{print $2}' | head -1)
        provides_sql=$(grep -A5 "^provides:" "${metadata}" | grep "sql:" | awk '{print $2}' | head -1)
        provides_rcv=$(grep -A5 "^provides:" "${metadata}" | grep "rcv:" | awk '{print $2}' | head -1)
        
        # Default to true if not specified
        provides_bin="${provides_bin:-true}"
        provides_sql="${provides_sql:-true}"
        provides_rcv="${provides_rcv:-true}"
    fi

    # Add to PATH (bin directory) - only if provides bin
    if [[ "${provides_bin}" == "true" ]] && [[ -d "${ext_path}/bin" ]]; then
        # Add to beginning of PATH (after ORADBA_BIN)
        export PATH="${ext_path}/bin:${PATH}"
        oradba_log DEBUG "  Added ${ext_name}/bin to PATH"
    fi

    # Add to SQLPATH (sql directory) - only if provides sql
    if [[ "${provides_sql}" == "true" ]] && [[ -d "${ext_path}/sql" ]]; then
        # Use add_to_sqlpath from oradba_common.sh if available, otherwise append
        if command -v add_to_sqlpath > /dev/null 2>&1; then
            add_to_sqlpath "${ext_path}/sql"
        else
            export SQLPATH="${SQLPATH:+${SQLPATH}:}${ext_path}/sql"
        fi
        oradba_log DEBUG "  Added ${ext_name}/sql to SQLPATH"
    fi

    # Add RMAN search path (rcv directory) - only if provides rcv
    if [[ "${provides_rcv}" == "true" ]] && [[ -d "${ext_path}/rcv" ]]; then
        export ORADBA_RCV_PATHS="${ORADBA_RCV_PATHS:+${ORADBA_RCV_PATHS}:}${ext_path}/rcv"
        oradba_log DEBUG "  Added ${ext_name}/rcv to RMAN search paths"
    fi

    # Create navigation alias (cd<extname> or cde<extname>)
    create_extension_alias "${ext_name}" "${ext_path}"

    # Sanitize extension name for use in variable names (replace hyphens with underscores)
    local safe_ext_name="${ext_name//-/_}"

    # Export extension path variables for reference
    local var_name="ORADBA_EXT_${safe_ext_name^^}_PATH"
    export "${var_name}=${ext_path}"

    # Export <EXTENSION>_BASE variable (e.g., USZ_BASE=/opt/oracle/local/usz)
    local base_var="${safe_ext_name^^}_BASE"
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

# ------------------------------------------------------------------------------
# Function: create_extension_alias
# Purpose.: Create navigation alias for extension
# Args....: $1 - Extension name
#           $2 - Extension path
# Returns.: 0 on success
# Output..: Creates alias like cde<name> (cd extension)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: show_extension_info
# Purpose.: Show detailed information about a specific extension
# Args....: $1 - Extension name or path
# Returns.: 0 on success, 1 on error
# Output..: Detailed extension information including structure and navigation alias
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Function: validate_extension
# Purpose.: Validate extension structure (basic check)
# Args....: $1 - Extension path
# Returns.: 0 if valid, 1 if warnings found
# Output..: Validation messages and warnings
# ------------------------------------------------------------------------------
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
