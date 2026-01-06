#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_version.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.14.0
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
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || readlink "${BASH_SOURCE[0]}")"
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
# Check local version
# ------------------------------------------------------------------------------
check_version() {
    local version_file="${BASE_DIR}/VERSION"
    
    if [[ -f "${version_file}" ]]; then
        cat "${version_file}"
    else
        echo "Unknown"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Verify installation integrity
# ------------------------------------------------------------------------------
check_integrity() {
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
        declare -A reported_files  # Track reported files to avoid duplicates
        
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
    
    # Check extension checksums if available
    check_extension_checksums
    local extension_status=$?
    
    # Return worst status (integrity or extension check failure)
    if [[ ${integrity_result} -ne 0 ]] || [[ ${extension_status} -ne 0 ]]; then
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Check for additional files not in checksum (user modifications)
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
# Check extension checksums if available
# ------------------------------------------------------------------------------
check_extension_checksums() {
    local extensions_dir="${BASE_DIR}/extensions"
    local checked_count=0
    local failed_count=0
    
    # Check if extensions directory exists
    if [[ ! -d "${extensions_dir}" ]]; then
        return 0
    fi
    
    # Look for extension checksum files
    local checksum_files=()
    while IFS= read -r -d '' checksum_file; do
        checksum_files+=("${checksum_file}")
    done < <(find "${extensions_dir}" -maxdepth 2 -type f -name ".*.checksum" -print0)
    
    # Return if no checksum files found
    if [[ ${#checksum_files[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}Extension Integrity Checks:${NC}"
    
    # Check each extension checksum file
    for checksum_file in "${checksum_files[@]}"; do
        local extension_dir
        extension_dir=$(dirname "${checksum_file}")
        
        # Extract extension name from checksum filename (e.g., .myext.checksum -> myext)
        local checksum_basename
        checksum_basename=$(basename "${checksum_file}")
        local ext_name="${checksum_basename#.}"
        ext_name="${ext_name%.checksum}"
        
        ((checked_count++))
        
        # Change to extension directory for relative paths
        cd "${extension_dir}" || continue
        
        # Verify checksums
        local verify_output
        verify_output=$(sha256sum -c "${checksum_file}" 2>&1)
        local verify_status=$?
        
        if [[ ${verify_status} -eq 0 ]]; then
            local file_count
            file_count=$(grep -c '^[^#]' "${checksum_file}")
            echo -e "  ${GREEN}✓${NC} Extension '${ext_name}': verified (${file_count} files)"
        else
            echo -e "  ${RED}✗${NC} Extension '${ext_name}': FAILED"
            ((failed_count++))
            
            # Show which files failed
            while IFS= read -r line; do
                if [[ "$line" =~ FAILED ]]; then
                    local failed_file
                    failed_file=$(echo "$line" | cut -d: -f1)
                    echo "      ${failed_file}: MODIFIED or MISSING"
                fi
            done <<< "$verify_output"
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
# Check for updates online
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
    latest_version=$(curl -s --max-time 10 "${api_url}" 2>/dev/null | \
                     grep '"tag_name":' | \
                     sed -E 's/.*"v?([^"]+)".*/\1/')
    
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
# Show detailed version information
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
    
    echo ""
    check_integrity
    
    return $?
}

# ------------------------------------------------------------------------------
# Display usage
# ------------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

OraDBA version and integrity checking utility

Options:
  -c, --check         Show current version
  -v, --verify        Verify installation integrity (checksums)
      --show-backup   Show backup commands for additional files (use with -v)
  -u, --update-check  Check for available updates online
  -i, --info          Show detailed version information
  -h, --help          Display this help message

Examples:
  $(basename "$0") --check
  $(basename "$0") --verify
  $(basename "$0") --update-check
  $(basename "$0") --info

Exit codes:
  0 - Success
  1 - Error or integrity check failed
  2 - Update available (from --update-check)

EOF
}

# ------------------------------------------------------------------------------
# Main
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
            -c|--check|-v|--verify|-u|--update-check|-i|--info|-h|--help)
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
        -c|--check)
            check_version
            ;;
        -v|--verify)
            check_integrity
            ;;
        -u|--update-check)
            check_updates
            ;;
        -i|--info)
            version_info
            ;;
        -h|--help)
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
