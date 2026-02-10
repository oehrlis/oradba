#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_version.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Version and integrity checking utility for OraDBA installation
# Notes......: Provides version info, integrity verification, and update checking
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o pipefail

# Determine ORADBA_BASE
if [[ -n "${ORADBA_BASE}" ]]; then
    BASE_DIR="${ORADBA_BASE}"
elif [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Script is symlinked, resolve to actual location
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2> /dev/null || readlink "${BASH_SOURCE[0]}")"
    BASE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
else
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verbose mode flag
VERBOSE=false

# Check if running in a terminal for colored output
if [[ ! -t 1 ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    # shellcheck disable=SC2034
    BLUE=''
    NC=''
fi

# ------------------------------------------------------------------------------
# Function: check_version
# Purpose.: Read and return OraDBA version from VERSION file
# Args....: None
# Returns.: 0 if version found, 1 if VERSION file missing
# Output..: Version string (e.g., "1.2.3") or "Unknown"
# Notes...: Reads ${BASE_DIR}/VERSION; fallback for missing file
# ------------------------------------------------------------------------------
check_version() {
    local version_file="${BASE_DIR}/VERSION"

    if [[ -f "${version_file}" ]]; then
        cat "${version_file}"
    else
        echo "unknown"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Function: get_checksum_exclusions
# Purpose.: Parse .checksumignore file and generate awk exclusion patterns
# Args....: $1 - extension_path (extension directory containing .checksumignore)
# Returns.: 0 (always succeeds)
# Output..: Space-separated awk patterns for field 2 matching (e.g., "$2 ~ /^log\// || $2 ~ /^\.extension$/")
# Notes...: Always excludes .extension, .checksumignore, log/; converts glob patterns (* to .*, ? to .)
# ------------------------------------------------------------------------------
get_checksum_exclusions() {
    local extension_path="$1"
    local ignore_file="${extension_path}/.checksumignore"
    local patterns=()

    # Always exclude .extension and .checksumignore files
    patterns+=('$2 ~ /^\.extension$/')
    patterns+=('$2 ~ /^\.checksumignore$/')

    # Default: exclude log/ directory
    patterns+=('$2 ~ /^log\//')

    # If .checksumignore exists, parse it
    if [[ -f "${ignore_file}" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*# ]] && continue

            # Trim whitespace
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$line" ]] && continue

            # Convert glob pattern to awk regex
            # Replace * with .* for regex matching
            local pattern="$line"

            # Escape special regex characters except * and ?
            pattern=$(echo "$pattern" | sed 's/\./\\./g') # Escape dots

            # Convert glob wildcards to regex
            pattern=$(echo "$pattern" | sed 's/\*/.*/g') # * -> .*
            pattern=$(echo "$pattern" | sed 's/?/./g')   # ? -> .

            # If pattern ends with /, match directory contents
            if [[ "$pattern" == */ ]]; then
                # Remove trailing / and add it back in the regex to avoid double /
                pattern="${pattern%/}"
                patterns+=("\$2 ~ /^${pattern}\\//")
            else
                # Match exact file or pattern
                patterns+=("\$2 ~ /^${pattern}$/")
            fi
        done < "${ignore_file}"
    fi

    # Combine patterns with ||
    local combined=""
    for ((i = 0; i < ${#patterns[@]}; i++)); do
        if [[ $i -eq 0 ]]; then
            combined="${patterns[$i]}"
        else
            combined="${combined} || ${patterns[$i]}"
        fi
    done

    echo "$combined"
}

# ------------------------------------------------------------------------------
# Function: check_integrity
# Purpose.: Verify OraDBA installation integrity using SHA256 checksums
# Args....: $1 - skip_extensions (optional, defaults to "false"; if "true", skip extension verification)
# Returns.: 0 if all files verified, 1 if any mismatches or missing files
# Output..: Success/failure status, file counts, detailed error list for failures
# Notes...: Reads .oradba.checksum; excludes .install_info; calls check_additional_files and check_extension_checksums
# ------------------------------------------------------------------------------
check_integrity() {
    local skip_extensions="${1:-false}"
    local checksum_file="${BASE_DIR}/.oradba.checksum"

    if [[ ! -f "${checksum_file}" ]]; then
        echo -e "${RED}✗ ERROR: Checksum file not found${NC}"
        echo "  Expected: ${checksum_file}"
        echo "  This installation may be incomplete or from an older version."
        return 1
    fi

    echo "Verifying installation integrity..."
    echo ""

    # Change to base directory for relative paths
    cd "${BASE_DIR}" || return 1

    # Verify checksums and capture output
    # Exclude .install_info as it's modified during installation
    local verify_output
    verify_output=$(grep -v '\.install_info$' "${checksum_file}" | sha256sum -c - 2>&1)
    local verify_status=$?

    local integrity_result=0

    if [[ ${verify_status} -eq 0 ]]; then
        local file_count
        file_count=$(grep -v '^\.install_info$' "${checksum_file}" | grep -c '^[^#]')
        echo -e "${GREEN}✓ Installation integrity verified${NC}"
        echo "  All ${file_count} files match their checksums"
        echo "  (Excluding .install_info which is updated during installation)"
        integrity_result=0
    else
        echo -e "${RED}✗ Installation integrity check FAILED${NC}"
        echo "  Files have been modified, corrupted, or are missing"
        echo ""

        # Parse and format the output more cleanly
        local missing_count=0
        local modified_count=0
        declare -A reported_files # Track reported files to avoid duplicates

        echo "Modified or missing files:"
        while IFS= read -r line; do
            # Skip OK lines and empty lines
            if [[ "$line" =~ ": OK"$ ]] || [[ -z "$line" ]]; then
                continue
            fi

            # Parse sha256sum error messages for missing files
            if [[ "$line" =~ ^sha256sum:[[:space:]]+(.+):[[:space:]]+No[[:space:]]+such[[:space:]]+file ]]; then
                local file="${BASH_REMATCH[1]}"
                # Remove leading space if present
                file="${file# }"
                # Skip if already reported
                if [[ -z "${reported_files[$file]}" ]]; then
                    echo "  \$ORADBA_BASE/${file}: MISSING"
                    ((missing_count++))
                    reported_files[$file]=1
                fi
                continue
            fi

            # Skip other sha256sum warnings
            if [[ "$line" =~ ^sha256sum: ]]; then
                continue
            fi

            # Parse different failure types
            if [[ "$line" =~ ^(.+):[[:space:]]*FAILED[[:space:]]*open[[:space:]]*or[[:space:]]*read$ ]]; then
                # File not found or can't be read
                local file="${BASH_REMATCH[1]}"
                # Skip if already reported
                if [[ -z "${reported_files[$file]}" ]]; then
                    echo "  \$ORADBA_BASE/${file}: MISSING"
                    ((missing_count++))
                    reported_files[$file]=1
                fi
            elif [[ "$line" =~ ^(.+):[[:space:]]*FAILED$ ]]; then
                # Checksum mismatch
                local file="${BASH_REMATCH[1]}"
                # Skip if already reported
                if [[ -z "${reported_files[$file]}" ]]; then
                    echo "  \$ORADBA_BASE/${file}: MODIFIED"
                    ((modified_count++))
                    reported_files[$file]=1
                fi
            fi
        done <<< "$verify_output"

        # Summary
        echo ""
        echo "Summary:"
        [[ $modified_count -gt 0 ]] && echo "  Modified files: ${modified_count}"
        [[ $missing_count -gt 0 ]] && echo "  Missing files:  ${missing_count}"
        echo "  Total issues:   $((modified_count + missing_count))"
        integrity_result=1
    fi

    # Always check for additional files regardless of integrity check result
    check_additional_files

    # Check extension checksums if available (unless skipped)
    local extension_status=0
    if [[ "${skip_extensions}" != "true" ]]; then
        check_extension_checksums
        extension_status=$?
    fi

    # Return worst status (integrity or extension check failure)
    if [[ ${integrity_result} -ne 0 ]] || [[ ${extension_status} -ne 0 ]]; then
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: check_additional_files
# Purpose.: Detect user-added files not in official checksum (customizations)
# Args....: None (uses ${BASE_DIR})
# Returns.: None (always succeeds, informational)
# Output..: Warning list of additional files in managed directories (bin, doc, etc, lib, rcv, sql, templates)
# Notes...: Helps identify user customizations before updates; shows backup commands if SHOW_BACKUP=true
# ------------------------------------------------------------------------------
check_additional_files() {
    local checksum_file="${BASE_DIR}/.oradba.checksum"
    local managed_dirs=("bin" "doc" "etc" "lib" "rcv" "sql" "templates")
    local additional_files=()

    # Extract file list from checksum file
    local checksummed_files
    checksummed_files=$(grep -v '^#' "${checksum_file}" | awk '{print $2}' | sort)

    # Check each managed directory
    for dir in "${managed_dirs[@]}"; do
        if [[ ! -d "${BASE_DIR}/${dir}" ]]; then
            continue
        fi

        # Find all files in directory
        while IFS= read -r -d '' file; do
            local rel_path="${file#${BASE_DIR}/}"

            # Skip if file is in checksum list
            if echo "${checksummed_files}" | grep -qxF "${rel_path}"; then
                continue
            fi

            additional_files+=("${rel_path}")
        done < <(find "${BASE_DIR}/${dir}" -type f -print0)
    done

    # Report additional files if found
    if [[ ${#additional_files[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ Additional files detected (not part of installation):${NC}"
        echo "  These files may have been created or modified by the user."
        echo "  Installation directory: ${BASE_DIR}"
        echo "  Consider backing them up before updating."
        echo ""
        for file in "${additional_files[@]}"; do
            echo "  \$ORADBA_BASE/${file}"
        done

        # Show backup commands if requested
        if [[ "${SHOW_BACKUP}" == "true" ]]; then
            echo ""
            echo "  Backup commands:"
            for file in "${additional_files[@]}"; do
                echo "  cp -p \"\$ORADBA_BASE/${file}\" \"\$ORADBA_BASE/${file}.bak\""
            done
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: check_extension_checksums
# Purpose.: Verify integrity of all enabled extensions using their .extension.checksum files
# Args....: None (scans ${BASE_DIR}/extensions and ${ORADBA_LOCAL_BASE})
# Returns.: 0 if all extensions verified, 1 if any failures
# Output..: Success/failure status for each enabled extension, verbose details in VERBOSE mode
# Notes...: Checks only enabled extensions; respects .checksumignore; verifies managed dirs (bin,sql,rcv,etc,lib)
# ------------------------------------------------------------------------------
check_extension_checksums() {
    local checked_count=0
    local failed_count=0
    local checksum_files=()

    # Check extensions in ORADBA_BASE/extensions
    if [[ -d "${BASE_DIR}/extensions" ]]; then
        while IFS= read -r -d '' checksum_file; do
            checksum_files+=("${checksum_file}")
        done < <(find "${BASE_DIR}/extensions" -maxdepth 2 -type f -name ".extension.checksum" -print0)
    fi

    # Check extensions in ORADBA_LOCAL_BASE if set and different
    if [[ -n "${ORADBA_LOCAL_BASE}" ]] && [[ -d "${ORADBA_LOCAL_BASE}" ]] && [[ "${ORADBA_LOCAL_BASE}" != "${BASE_DIR}/extensions" ]]; then
        while IFS= read -r -d '' checksum_file; do
            local checksum_dir
            checksum_dir=$(dirname "${checksum_file}")

            # Skip if this is the main OraDBA installation directory
            if [[ "$(cd "${checksum_dir}" && pwd)" == "$(cd "${BASE_DIR}" && pwd)" ]]; then
                continue
            fi

            # Skip if this is inside the main OraDBA directory (not an extension)
            if [[ "${checksum_dir}" == "${BASE_DIR}"* ]] && [[ "${checksum_dir}" != "${BASE_DIR}/extensions"* ]]; then
                continue
            fi

            checksum_files+=("${checksum_file}")
        done < <(find "${ORADBA_LOCAL_BASE}" -maxdepth 2 -type f -name ".extension.checksum" -print0)
    fi

    # Return if no checksum files found
    if [[ ${#checksum_files[@]} -eq 0 ]]; then
        return 0
    fi

    # First pass: check which extensions are enabled
    local enabled_extensions=()
    for checksum_file in "${checksum_files[@]}"; do
        local extension_dir
        extension_dir=$(dirname "${checksum_file}")
        local ext_name
        ext_name=$(basename "${extension_dir}")

        if is_extension_enabled "${ext_name}" "${extension_dir}" 2> /dev/null; then
            enabled_extensions+=("${checksum_file}")
        fi
    done

    # Return if no enabled extensions with checksums
    if [[ ${#enabled_extensions[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo -e "${BLUE}Extension Integrity Checks:${NC}"
    echo "  Managed directories: bin, sql, rcv, etc, lib"
    echo "  (Other directories like doc/ and templates/ are not verified)"

    # Check each enabled extension checksum file
    for checksum_file in "${enabled_extensions[@]}"; do
        local extension_dir
        extension_dir=$(dirname "${checksum_file}")

        # Extract extension name from directory name
        local ext_name
        ext_name=$(basename "${extension_dir}")

        ((checked_count++))

        # Change to extension directory for relative paths
        cd "${extension_dir}" || continue

        # Get exclusion patterns from .checksumignore
        local exclusions
        exclusions=$(get_checksum_exclusions "${extension_dir}")

        # Verify checksums (apply exclusions from .checksumignore)
        # Checksum format is: hash  filename
        local verify_output
        verify_output=$(awk "!(${exclusions}) {print}" "${checksum_file}" | sha256sum -c - 2>&1)
        local verify_status=$?

        if [[ ${verify_status} -eq 0 ]]; then
            local file_count
            file_count=$(awk "!(${exclusions}) && !/^#/ {print}" "${checksum_file}" | wc -l | tr -d ' ')
            echo -e "  ${GREEN}✓${NC} Extension '${ext_name}': verified (${file_count} files)"
        else
            echo -e "  ${RED}✗${NC} Extension '${ext_name}': FAILED"
            ((failed_count++))

            # Show details in verbose mode
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "      Modified or missing files:"
                while IFS= read -r line; do
                    if [[ "$line" =~ FAILED ]]; then
                        local failed_file
                        failed_file=$(echo "$line" | cut -d: -f1)
                        echo "        \${${ext_name^^}_BASE}/${failed_file}"
                    fi
                done <<< "$verify_output"
            fi
        fi

        # Check for additional files not in checksum (only in verbose mode)
        # This runs regardless of checksum pass/fail status
        if [[ "${VERBOSE}" == "true" ]]; then
            local checksummed_files
            checksummed_files=$(awk "!(${exclusions}) && !/^#/ {print \$2}" "${checksum_file}" | sort)

            local additional_files=()
            local managed_dirs=("bin" "sql" "rcv" "etc" "lib")

            for dir in "${managed_dirs[@]}"; do
                [[ ! -d "${dir}" ]] && continue

                while IFS= read -r -d '' file; do
                    local rel_path="${file#./}"
                    if ! echo "${checksummed_files}" | grep -qxF "${rel_path}"; then
                        additional_files+=("${rel_path}")
                    fi
                done < <(find "${dir}" -type f ! -name ".*" -print0 2> /dev/null)
            done

            if [[ ${#additional_files[@]} -gt 0 ]]; then
                echo "      Additional files (not in checksum):"
                for file in "${additional_files[@]}"; do
                    echo "        \${${ext_name^^}_BASE}/${file}"
                done
            fi
        fi
    done

    # Return to base directory
    cd "${BASE_DIR}" || return 1

    # Return status
    if [[ ${failed_count} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ ${failed_count} of ${checked_count} extensions failed integrity check${NC}"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: show_installed_extensions
# Purpose.: Display list of all installed extensions with status indicators
# Args....: None (sources lib/extensions.sh)
# Returns.: 0 (always succeeds)
# Output..: Formatted extension list: name, version, enabled/disabled status, checksum status (✓/✗)
# Notes...: Sorted by priority; shows checksum status for enabled extensions; uses extensions.sh library
# ------------------------------------------------------------------------------
show_installed_extensions() {
    # Source extensions library if available
    if [[ -f "${BASE_DIR}/lib/extensions.sh" ]]; then
        # shellcheck source=../lib/extensions.sh
        source "${BASE_DIR}/lib/extensions.sh"
    else
        return 0
    fi

    # Get all extensions
    local extensions
    mapfile -t extensions < <(get_all_extensions 2> /dev/null)

    if [[ ${#extensions[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo "Installed Extensions:"

    # Sort by priority
    local sorted
    mapfile -t sorted < <(sort_extensions_by_priority "${extensions[@]}" 2> /dev/null)

    for ext_path in "${sorted[@]}"; do
        local name version enabled_status checksum_status
        name=$(get_extension_name "${ext_path}" 2> /dev/null)
        version=$(get_extension_version "${ext_path}" 2> /dev/null)

        # Check if enabled
        if is_extension_enabled "${name}" "${ext_path}" 2> /dev/null; then
            enabled_status="enabled"
        else
            enabled_status="disabled"
        fi

        # Check for checksum file and verify (only for enabled extensions)
        checksum_status=""
        if [[ "${enabled_status}" == "enabled" ]] && [[ -f "${ext_path}/.extension.checksum" ]]; then
            local checksum_file="${ext_path}/.extension.checksum"

            # Get exclusion patterns from .checksumignore
            local exclusions
            exclusions=$(get_checksum_exclusions "${ext_path}")

            # Verify checksums (apply exclusions from .checksumignore)
            # Checksum format is: hash  filename - use awk to filter by filename field
            if (cd "${ext_path}" && awk "!(${exclusions}) {print}" "${checksum_file}" | sha256sum -c - &> /dev/null); then
                checksum_status=" ${GREEN}✓${NC}"
            else
                checksum_status=" ${RED}✗${NC}"
            fi
        fi

        printf "  %-20s %-10s [%s]" "${name}" "v${version}" "${enabled_status}"
        echo -e "${checksum_status}"
    done
}

# ------------------------------------------------------------------------------
# Function: check_updates
# Purpose.: Query GitHub API for latest OraDBA release and compare with installed version
# Args....: None
# Returns.: 0 if up-to-date, 1 if check failed, 2 if update available
# Output..: Current vs latest version, download instructions if update available
# Notes...: Uses curl with 10s timeout; queries api.github.com/repos/oehrlis/oradba/releases/latest
# ------------------------------------------------------------------------------
check_updates() {
    local current_version
    local latest_version
    local api_url="https://api.github.com/repos/oehrlis/oradba/releases/latest"

    current_version=$(check_version)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ ERROR: Could not determine current version${NC}"
        return 1
    fi

    echo "Checking for updates..."
    echo ""

    # Query GitHub API for latest release
    latest_version=$(curl -s --max-time 10 "${api_url}" 2> /dev/null \
        | grep '"tag_name":' \
        | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [[ -z "${latest_version}" ]]; then
        echo -e "${YELLOW}⚠ Could not check for updates${NC}"
        echo "  Network error or GitHub API unavailable"
        echo "  Current version: ${current_version}"
        return 1
    fi

    echo "Current version: ${current_version}"
    echo "Latest version:  ${latest_version}"
    echo ""

    # Compare versions
    if [[ "${current_version}" == "${latest_version}" ]]; then
        echo -e "${GREEN}✓ You are running the latest version${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Update available: ${current_version} → ${latest_version}${NC}"
        echo ""
        echo "Download the latest version:"
        echo "  https://github.com/oehrlis/oradba/releases/latest"
        echo ""
        echo "Or use curl:"
        echo "  curl -L https://github.com/oehrlis/oradba/releases/download/v${latest_version}/oradba_install.sh -o oradba_install.sh"
        return 2
    fi
}

# ------------------------------------------------------------------------------
# Function: version_info
# Purpose.: Display comprehensive version information, installation details, and integrity check
# Args....: None
# Returns.: Return code from check_integrity (0 if verified, 1 if failed)
# Output..: Version, install path, installation metadata, installed extensions, integrity status
# Notes...: Reads .install_info for details; calls show_installed_extensions and check_integrity
# ------------------------------------------------------------------------------
version_info() {
    local version
    local install_info="${BASE_DIR}/.install_info"

    version=$(check_version)

    echo "OraDBA Version Information"
    echo "=========================="
    echo "Version:       ${version}"
    echo "Install Path:  ${BASE_DIR}"

    if [[ -f "${install_info}" ]]; then
        echo ""
        echo "Installation Details:"
        while IFS='=' read -r key value; do
            case "${key}" in
                install_date)
                    echo "  Installed:     ${value}"
                    ;;
                install_version)
                    echo "  Version:       ${value}"
                    ;;
                install_method)
                    echo "  Method:        ${value}"
                    ;;
                install_user)
                    echo "  User:          ${value}"
                    ;;
                coexist_mode)
                    echo "  Coexist Mode:  ${value}"
                    ;;
                basenv_detected)
                    echo "  BasEnv:        ${value}"
                    ;;
            esac
        done < "${install_info}"
    fi

    # Show installed extensions
    show_installed_extensions

    echo ""
    check_integrity

    return $?
}

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display comprehensive help information for version utility
# Args....: None
# Returns.: None (prints to stdout)
# Output..: Multi-section help (options, examples, exit codes)
# Notes...: Shows all command-line options for version checking, verification, updates
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

OraDBA version and integrity checking utility

Options:
  -c, --check         Show current version
  -v, --verify        Verify installation integrity (checksums)
  --verify-core       Verify core installation only (skip extensions)
  --verbose           Show detailed file list for failed checks
      --show-backup   Show backup commands for additional files (use with -v)
  -u, --update-check  Check for available updates online
  -i, --info          Show detailed version information
  -h, --help          Display this help message

Examples:
  $(basename "$0") --check
  $(basename "$0") --verify
  $(basename "$0") --verify --verbose
  $(basename "$0") --info --verbose
  $(basename "$0") --update-check

Exit codes:
  0 - Success
  1 - Error or integrity check failed
  2 - Update available (from --update-check)

EOF
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Entry point and command-line argument dispatcher
# Args....: $@ - Command-line arguments (see usage for options)
# Returns.: Depends on selected operation (0 success, 1 error, 2 update available)
# Output..: Depends on selected operation (check/verify/update-check/info/help)
# Notes...: Defaults to version_info if no action specified; parses --verbose and --show-backup flags
# ------------------------------------------------------------------------------
main() {
    # Parse options
    SHOW_BACKUP="false"
    ACTION=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --show-backup)
                SHOW_BACKUP="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            -c | --check | -v | --verify | --verify-core | -u | --update-check | -i | --info | -h | --help)
                ACTION="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # If no action specified, show info
    if [[ -z "${ACTION}" ]]; then
        version_info
        exit $?
    fi

    case "${ACTION}" in
        -c | --check)
            check_version
            ;;
        -v | --verify)
            check_integrity
            ;;
        --verify-core)
            check_integrity true
            ;;
        -u | --update-check)
            check_updates
            ;;
        -i | --info)
            version_info
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}ERROR: Unknown option: $1${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"
