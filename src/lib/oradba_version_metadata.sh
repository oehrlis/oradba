#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_version_metadata.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.03.23
# Revision...: 0.21.0
# Purpose....: Version comparison and installation metadata functions
# Notes......: Extracted from oradba_common.sh for cohesion.
#              Requires: oradba_common.sh core functions (oradba_log)
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Prevent multiple sourcing
[[ -n "${ORADBA_VERSION_METADATA_LOADED:-}" ]] && return 0
readonly ORADBA_VERSION_METADATA_LOADED=1

# ------------------------------------------------------------------------------
# Version Management Functions
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Function: get_oradba_version
# Purpose.: Get OraDBA version from VERSION file
# Args....: None
# Returns.: 0 - Version retrieved successfully
#           1 - VERSION file not found
# Output..: Version string (e.g., "1.0.0-dev") or "unknown"
# Notes...: Example: version=$(get_oradba_version)
# ------------------------------------------------------------------------------
get_oradba_version() {
    local version_file="${ORADBA_BASE}/VERSION"

    if [[ -f "${version_file}" ]]; then
        cat "${version_file}" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}


# ------------------------------------------------------------------------------
# Function: version_compare
# Purpose.: Compare two semantic version strings
# Args....: $1 - First version string (e.g., "1.2.3")
#           $2 - Second version string (e.g., "1.2.0")
# Returns.: 0 - Versions are equal
#           1 - First version is greater
#           2 - Second version is greater
# Output..: None
# Notes...: Example: version_compare "1.2.3" "1.2.0"; result=$?  # Returns 1
# ------------------------------------------------------------------------------
version_compare() {
    local v1="$1"
    local v2="$2"

    # Remove leading 'v' if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"

    # Compare each component
    for i in {0..2}; do
        local part1="${v1_parts[$i]:-0}"
        local part2="${v2_parts[$i]:-0}"

        # Remove any non-numeric suffix (e.g., "1-beta")
        part1="${part1%%-*}"
        part2="${part2%%-*}"

        if ((part1 > part2)); then
            return 1
        elif ((part1 < part2)); then
            return 2
        fi
    done

    return 0
}


# ------------------------------------------------------------------------------
# Function: version_meets_requirement
# Purpose.: Check if current version meets minimum requirement
# Args....: $1 - Current version string
#           $2 - Required version string
# Returns.: 0 - Current version meets requirement (>=)
#           1 - Current version does not meet requirement
# Output..: None
# Notes...: Example: if version_meets_requirement "1.2.3" "1.2.0"; then echo "OK"; fi
# ------------------------------------------------------------------------------
version_meets_requirement() {
    local current_version="$1"
    local required_version="$2"

    version_compare "$current_version" "$required_version"
    local result=$?

    # Returns 0 (equal) or 1 (greater) means requirement is met
    [[ $result -eq 0 || $result -eq 1 ]]
}


# ------------------------------------------------------------------------------
# Function: get_install_info
# Purpose.: Get installation metadata value by key
# Args....: $1 - Metadata key to retrieve
# Returns.: 0 - Key found and value retrieved
#           1 - Key not found or .install_info file doesn't exist
# Output..: Value for the specified key
# Notes...: Supports both old format (install_version) and new format (version).
#           Example: install_date=$(get_install_info "install_date")
# ------------------------------------------------------------------------------
get_install_info() {
    local key="$1"
    local install_info="${ORADBA_BASE}/.install_info"

    if [[ -f "${install_info}" ]]; then
        # Try to get value, handle both with and without quotes
        local value
        value=$(grep "^${key}=" "${install_info}" | cut -d= -f2- | sed 's/^"//;s/"$//')
        echo "${value}"
    fi
}


# ------------------------------------------------------------------------------
# Function: set_install_info
# Purpose.: Set installation metadata key-value pair
# Args....: $1 - Metadata key
#           $2 - Metadata value
# Returns.: 0 - Key-value set successfully
#           1 - Failed to write to .install_info file
# Output..: None
# Notes...: Uses lowercase keys without quotes for consistency with installer.
#           Example: set_install_info "install_date" "2026-01-14"
# ------------------------------------------------------------------------------
set_install_info() {
    local key="$1"
    local value="$2"
    local install_info="${ORADBA_BASE}/.install_info"

    # Create or update key
    if [[ -f "${install_info}" ]]; then
        # Update existing key or append
        if grep -q "^${key}=" "${install_info}"; then
            sed -i.bak "s|^${key}=.*|${key}=${value}|" "${install_info}"
            rm -f "${install_info}.bak"
        else
            echo "${key}=${value}" >> "${install_info}"
        fi
    else
        # Create new file
        mkdir -p "$(dirname "${install_info}")"
        echo "${key}=${value}" > "${install_info}"
    fi
}


# ------------------------------------------------------------------------------
# Function: init_install_info
# Purpose.: Initialize installation info file with metadata
# Args....: None
# Returns.: 0 - Installation info initialized successfully
#           1 - Failed to create .install_info file
# Output..: Info message about initialization
# Notes...: Uses lowercase keys without quotes to match installer format.
#           Creates ${ORADBA_BASE}/.install_info with install metadata.
#           Example: init_install_info
# ------------------------------------------------------------------------------
init_install_info() {
    local version="$1"
    local install_info="${ORADBA_BASE}/.install_info"

    cat > "${install_info}" << EOF
install_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
install_version=${version}
install_method=installer
install_user=${USER}
install_prefix=${ORADBA_BASE}
EOF

    oradba_log INFO "Created installation metadata: ${install_info}"
}
