#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_version.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.4.0
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
    local verify_output
    verify_output=$(sha256sum -c "${checksum_file}" 2>&1)
    local verify_status=$?
    
    if [[ ${verify_status} -eq 0 ]]; then
        local file_count
        file_count=$(grep -c '^[^#]' "${checksum_file}")
        echo -e "${GREEN}✓ Installation integrity verified${NC}"
        echo "  All ${file_count} files match their checksums"
        return 0
    else
        echo -e "${RED}✗ Installation integrity check FAILED${NC}"
        echo "  Files have been modified, corrupted, or are missing"
        echo ""
        echo "Modified or missing files:"
        echo "${verify_output}" | grep -v ": OK$" | sed 's/^/  /'
        return 1
    fi
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
                    echo "  Installed:   ${value}"
                    ;;
                install_version)
                    echo "  Installed:   ${value}"
                    ;;
                install_method)
                    echo "  Method:      ${value}"
                    ;;
                install_user)
                    echo "  User:        ${value}"
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
    if [[ $# -eq 0 ]]; then
        version_info
        exit $?
    fi
    
    case "$1" in
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
