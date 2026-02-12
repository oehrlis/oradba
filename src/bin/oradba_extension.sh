#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_extension.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Management tool for OraDBA extensions
# Notes......: List, inspect, validate, and manage OraDBA extensions
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

# Debug support
ORADBA_DEBUG="${ORADBA_DEBUG:-false}"
log_debug() {
    if [[ "${ORADBA_DEBUG}" == "true" ]]; then
        echo -e "[DEBUG] $*" >&2
    fi
}
log_debug "Resolved BASE_DIR='${BASE_DIR}'"

# Source required libraries
# shellcheck source=../lib/oradba_common.sh
if [[ -f "${BASE_DIR}/lib/oradba_common.sh" ]]; then
    source "${BASE_DIR}/lib/oradba_common.sh"
    log_debug "Loaded oradba_common.sh"
else
    echo "ERROR: Cannot find oradba_common.sh library" >&2
    exit 1
fi

# shellcheck source=../lib/extensions.sh
if [[ -f "${BASE_DIR}/lib/extensions.sh" ]]; then
    source "${BASE_DIR}/lib/extensions.sh"
    log_debug "Loaded extensions.sh"
else
    echo "ERROR: Cannot find extensions.sh library" >&2
    exit 1
fi

# Set defaults for extension configuration if not already set
export ORADBA_AUTO_DISCOVER_EXTENSIONS="${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
export ORADBA_LOCAL_BASE="${ORADBA_LOCAL_BASE:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if running in a terminal for colored output
if [[ ! -t 1 ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information and command reference
# Args....: None
# Returns.: 0 (exits after display)
# Output..: Usage help to stdout
# Notes...: Shows all extension management commands
#           Includes add, create, list, info, validate, discover, paths, enabled/disabled
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

DESCRIPTION
    Management tool for OraDBA extensions. Provides commands to list, inspect,
    validate, and manage extensions in the OraDBA environment.

COMMANDS
    add <source> [options]
        Add/install an extension from GitHub or local tarball.
        Source formats:
          oehrlis/odb_xyz              GitHub repo (short name, latest release)
          oehrlis/odb_xyz@v1.0.0       GitHub repo with specific version
          https://github.com/...       Full GitHub URL
          /path/to/extension.tar.gz    Local tarball
        Options:
          --name <name>         Override extension name
          --path <dir>          Target directory (default: \${ORADBA_LOCAL_BASE})
          --update              Update existing extension (creates .save for configs)

    create <name> [options]
        Create a new extension from a template.
        Options:
          --path <dir>          Target directory (default: \${ORADBA_LOCAL_BASE})
          --template <file>     Use custom tarball template (.tar.gz or .tgz)
          --from-github         Use latest release from github.com/oehrlis/oradba_extension

    list [--verbose|-v]
        List all discovered extensions with their status, version, and priority.
        Use --verbose for detailed information including paths and metadata.

    info <extension-name>
        Display detailed information about a specific extension including:
        - Name, version, description
        - Path and directories
        - Priority and enabled status
        - Provided capabilities (bin, sql, rcv, etc, lib)

    validate <extension-name|path>
        Validate the structure and configuration of an extension.
        Reports warnings for missing metadata, empty directories, or issues.

    validate-all
        Validate all discovered extensions.

    discover
        Show auto-discovered extensions in \${ORADBA_LOCAL_BASE}.

    paths
        Display the search paths for extensions (auto-discovery and manual).

    enabled
        List only enabled extensions that will be loaded.

    disabled
        List only disabled extensions that will be skipped.

    enable <extension-name>
        Enable a specific extension. Updates the extension's .extension metadata
        file to set enabled: true. Requires reloading the environment to take effect.

    disable <extension-name>
        Disable a specific extension. Updates the extension's .extension metadata
        file to set enabled: false. Requires reloading the environment to take effect.

    help
        Display this help message.

OPTIONS
    -v, --verbose       Show detailed information
    --debug             Enable debug logging (sets ORADBA_LOG_LEVEL=DEBUG)
    -h, --help          Display this help message

ENVIRONMENT VARIABLES
    ORADBA_BASE                     Base directory for OraDBA installation
    ORADBA_LOCAL_BASE               Base directory for local extensions
    ORADBA_AUTO_DISCOVER_EXTENSIONS Enable/disable auto-discovery (true/false)
    ORADBA_EXTENSION_PATHS          Colon-separated list of manual extension paths
    ORADBA_EXT_<NAME>_ENABLED       Enable/disable specific extension (true/false)
    ORADBA_EXT_<NAME>_PRIORITY      Override priority for specific extension

EXAMPLES
    # Create new extension
    $(basename "$0") create mycompany

    # Create with custom template
    $(basename "$0") create mycompany --template /path/to/template.tar.gz

    # Create from GitHub release
    $(basename "$0") create mycompany --from-github

    # Create in custom location
    $(basename "$0") create mycompany --path /opt/oracle/custom

    # List all extensions
    $(basename "$0") list

    # List with details
    $(basename "$0") list --verbose

    # Show info about specific extension
    $(basename "$0") info customer

    # Validate an extension
    $(basename "$0") validate customer

    # Validate all extensions
    $(basename "$0") validate-all

    # Show enabled extensions
    $(basename "$0") enabled

    # Enable an extension
    $(basename "$0") enable customer

    # Disable an extension
    $(basename "$0") disable customer

SEE ALSO
    doc/extension-system.md - Complete extension system documentation

EOF
}

# ----------------------------------------------------------------------------
# Global option pre-parser (captures --debug anywhere)
# ----------------------------------------------------------------------------
preparse_debug_flag() {
    local newargs=()
    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            ORADBA_DEBUG="true"
            export ORADBA_LOG_LEVEL=DEBUG
            log_debug "Debug mode enabled via --debug"
            continue
        fi
        newargs+=("$arg")
    done
    printf '%s
' "${newargs[@]}"
}

# ------------------------------------------------------------------------------
# Function: validate_extension_name
# Purpose.: Validate extension name meets naming requirements
# Args....: $1 - Extension name
# Returns.: 0 if valid, 1 if invalid
# Output..: Error messages to stderr
# Notes...: Requirements: alphanumeric/dash/underscore, starts with letter
#           Example valid names: myext, my_ext, my-ext-123
# ------------------------------------------------------------------------------
validate_extension_name() {
    local name="$1"

    # Check if name is empty
    if [[ -z "${name}" ]]; then
        echo "ERROR: Extension name cannot be empty" >&2
        return 1
    fi

    # Check for invalid characters (allow alphanumeric, dash, underscore)
    if [[ ! "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Extension name can only contain letters, numbers, dashes, and underscores" >&2
        return 1
    fi

    # Check if name starts with a letter
    if [[ ! "${name}" =~ ^[a-zA-Z] ]]; then
        echo "ERROR: Extension name must start with a letter" >&2
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: download_github_release
# Purpose.: Download latest extension template from GitHub
# Args....: $1 - Output file path for downloaded tarball
# Returns.: 0 on success, 1 on failure
# Output..: Download status and tag name to stdout
# Notes...: Downloads from oehrlis/oradba_extension repository
#           Uses GitHub API to find latest release
#           Validates downloaded file is valid gzip archive
#           Falls back through tarball URLs if needed
# ------------------------------------------------------------------------------
download_github_release() {
    local output_file="$1"
    local repo="oehrlis/oradba_extension"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"

    echo "Fetching latest release from GitHub..."

    # Get latest release info
    local release_info
    if ! release_info=$(curl -s "${api_url}"); then
        echo "ERROR: Failed to fetch release information from GitHub" >&2
        return 1
    fi

    # Extract version tag
    local tag_name
    tag_name=$(echo "${release_info}" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ -z "${tag_name}" ]]; then
        echo "ERROR: Could not find release tag" >&2
        return 1
    fi

    echo "Found latest release: ${tag_name}"

    # Extract tarball URL (look for extension-template-*.tar.gz asset)
    local tarball_url
    tarball_url=$(echo "${release_info}" | grep -o '"browser_download_url": "[^"]*extension-template-[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)

    if [[ -z "${tarball_url}" ]]; then
        # Fallback: look for any .tar.gz asset
        tarball_url=$(echo "${release_info}" | grep -o '"browser_download_url": "[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)
    fi

    if [[ -z "${tarball_url}" ]]; then
        # Last fallback: use source tarball_url from release
        tarball_url=$(echo "${release_info}" | grep -o '"tarball_url": "[^"]*"' | head -1 | cut -d'"' -f4)
    fi

    if [[ -z "${tarball_url}" ]]; then
        echo "ERROR: Could not find release tarball URL" >&2
        return 1
    fi

    echo "Downloading from: ${tarball_url}"

    # Download tarball with progress
    if ! curl -L -f -o "${output_file}" "${tarball_url}"; then
        echo "ERROR: Failed to download release tarball" >&2
        return 1
    fi

    # Verify download
    if [[ ! -s "${output_file}" ]]; then
        echo "ERROR: Downloaded file is empty" >&2
        return 1
    fi

    # Verify it's a valid gzip file
    if ! file "${output_file}" | grep -q "gzip compressed"; then
        echo "ERROR: Downloaded file is not a valid gzip archive" >&2
        echo "File type: $(file "${output_file}")" >&2
        return 1
    fi

    echo "Downloaded successfully"

    # Output tag_name to stdout for caller to capture
    echo "${tag_name}"
    return 0
}

# ------------------------------------------------------------------------------
# Function: download_extension_from_github
# Purpose.: Download extension from GitHub repository
# Args....: $1 - Repository (owner/repo format)
#           $2 - Version/tag (optional, uses latest if empty)
#           $3 - Output file path
# Returns.: 0 on success, 1 on failure
# Output..: Download status to stdout, errors to stderr
# Notes...: Tries: specific release → latest release → tags → main/master branch
#           Normalizes GitHub URLs, validates repo format
#           Supports both curl and wget
#           Adds 'v' prefix to versions if missing
# ------------------------------------------------------------------------------
download_extension_from_github() {
    local repo="$1"
    local version="${2:-}"
    local output_file="$3"

    # Normalize repo name (remove github.com prefix if present)
    repo=$(echo "${repo}" | sed 's|^https\?://github.com/||')

    # Validate repo format (should be owner/repo)
    if [[ ! "${repo}" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid GitHub repository format: ${repo}" >&2
        echo "Expected format: owner/repo (e.g., oehrlis/odb_xyz)" >&2
        return 1
    fi

    echo "GitHub repository: ${repo}"

    # Determine version/tag to use
    local api_url
    local download_url
    local tag_name

    if [[ -n "${version}" ]]; then
        # Specific version requested
        echo "Requested version: ${version}"
        # Add 'v' prefix if not present
        [[ "${version}" =~ ^v ]] || version="v${version}"

        # Check if this tag/release exists
        api_url="https://api.github.com/repos/${repo}/releases/tags/${version}"

        if command -v curl > /dev/null 2>&1; then
            download_url=$(curl -fsSL "${api_url}" 2> /dev/null | grep '"tarball_url"' | cut -d'"' -f4 | head -1)
        elif command -v wget > /dev/null 2>&1; then
            download_url=$(wget -qO- "${api_url}" 2> /dev/null | grep '"tarball_url"' | cut -d'"' -f4 | head -1)
        fi

        if [[ -z "${download_url}" ]]; then
            echo "ERROR: Version ${version} not found in ${repo}" >&2
            return 1
        fi
        tag_name="${version}"
    else
        # Get latest release
        echo "Fetching latest release..."
        api_url="https://api.github.com/repos/${repo}/releases/latest"

        local release_info
        if command -v curl > /dev/null 2>&1; then
            release_info=$(curl -fsSL "${api_url}" 2> /dev/null)
        elif command -v wget > /dev/null 2>&1; then
            release_info=$(wget -qO- "${api_url}" 2> /dev/null)
        else
            echo "ERROR: Neither curl nor wget found" >&2
            return 1
        fi

        # Check if release found, otherwise try tags
        if [[ -z "${release_info}" ]] || echo "${release_info}" | grep -q '"message".*"Not Found"'; then
            echo "No releases found, checking for tags..."

            # Try to get latest tag
            api_url="https://api.github.com/repos/${repo}/tags"
            local tags_info
            if command -v curl > /dev/null 2>&1; then
                tags_info=$(curl -fsSL "${api_url}" 2> /dev/null)
            elif command -v wget > /dev/null 2>&1; then
                tags_info=$(wget -qO- "${api_url}" 2> /dev/null)
            fi

            if [[ -n "${tags_info}" ]] && ! echo "${tags_info}" | grep -q '"message".*"Not Found"'; then
                # Get first (latest) tag
                tag_name=$(echo "${tags_info}" | grep '"name"' | cut -d'"' -f4 | head -1)
                download_url=$(echo "${tags_info}" | grep '"tarball_url"' | cut -d'"' -f4 | head -1)

                if [[ -n "${download_url}" ]]; then
                    echo "Found latest tag: ${tag_name}"
                else
                    # No tags either, fallback to main/master branch
                    echo "No tags found, using main branch..."
                    tag_name="main"
                    download_url="https://github.com/${repo}/archive/refs/heads/main.tar.gz"

                    # Check if main branch exists, otherwise try master
                    if command -v curl > /dev/null 2>&1; then
                        if ! curl -fsSL -I "${download_url}" > /dev/null 2>&1; then
                            echo "Trying master branch..."
                            tag_name="master"
                            download_url="https://github.com/${repo}/archive/refs/heads/master.tar.gz"
                        fi
                    fi
                fi
            else
                # No tags, fallback to main/master branch
                echo "No tags found, using main branch..."
                tag_name="main"
                download_url="https://github.com/${repo}/archive/refs/heads/main.tar.gz"

                # Check if main branch exists, otherwise try master
                if command -v curl > /dev/null 2>&1; then
                    if ! curl -fsSL -I "${download_url}" > /dev/null 2>&1; then
                        echo "Trying master branch..."
                        tag_name="master"
                        download_url="https://github.com/${repo}/archive/refs/heads/master.tar.gz"
                    fi
                fi
            fi
        else
            # Release found
            download_url=$(echo "${release_info}" | grep '"tarball_url"' | cut -d'"' -f4 | head -1)
            tag_name=$(echo "${release_info}" | grep '"tag_name"' | cut -d'"' -f4 | head -1)

            if [[ -z "${download_url}" ]]; then
                echo "ERROR: Could not find download URL for latest release" >&2
                return 1
            fi

            echo "Latest release: ${tag_name}"
        fi

        if [[ -z "${download_url}" ]]; then
            echo "ERROR: Could not determine download URL for ${repo}" >&2
            return 1
        fi
    fi

    # Download tarball
    echo "Downloading from: ${download_url}"

    if command -v curl > /dev/null 2>&1; then
        if ! curl -fsSL -o "${output_file}" "${download_url}"; then
            echo "ERROR: Failed to download extension tarball" >&2
            return 1
        fi
    elif command -v wget > /dev/null 2>&1; then
        if ! wget -q -O "${output_file}" "${download_url}"; then
            echo "ERROR: Failed to download extension tarball" >&2
            return 1
        fi
    fi

    echo "Downloaded successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: validate_extension_structure
# Purpose.: Validate extension has proper directory structure
# Args....: $1 - Extension directory path
# Returns.: 0 if valid structure, 1 otherwise
# Output..: None
# Notes...: Valid if has .extension file OR standard directories (bin/sql/rcv/etc/lib)
#           Used to verify downloaded/extracted extensions
# ------------------------------------------------------------------------------
validate_extension_structure() {
    local ext_dir="$1"

    # Check if has .extension file OR expected directories
    if [[ -f "${ext_dir}/.extension" ]]; then
        return 0
    fi

    # Check for expected extension directories
    if [[ -d "${ext_dir}/bin" ]] || [[ -d "${ext_dir}/sql" ]] \
        || [[ -d "${ext_dir}/rcv" ]] || [[ -d "${ext_dir}/etc" ]] \
        || [[ -d "${ext_dir}/lib" ]]; then
        return 0
    fi

    echo "ERROR: Invalid extension structure" >&2
    echo "Extension must contain either:" >&2
    echo "  - .extension metadata file" >&2
    echo "  - One or more of: bin/, sql/, rcv/, etc/, lib/ directories" >&2
    return 1
}

# ------------------------------------------------------------------------------
# Update existing extension
# Usage: update_extension <ext_path> <new_content_dir>
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: update_extension
# Purpose.: Update existing extension with backup of modified files
# Args....: $1 - Extension path (existing installation)
#           $2 - New content directory (extracted from tarball)
# Returns.: 0 on success, 1 on failure
# Output..: Update status to stdout
# Notes...: Creates timestamped backup of entire extension
#           Creates .save backups of modified files (based on checksums)
#           Also preserves user-added files (*.conf not in checksum)
#           Restores all preserved files after copying new content
#           Similar to RPM update behavior for configs
# ------------------------------------------------------------------------------
update_extension() {
    local ext_path="$1"
    local new_content_dir="$2"

    # Create backup directory (use underscore naming to avoid dots in variable names)
    local backup_dir
    backup_dir="${ext_path}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup: ${backup_dir}"

    if ! cp -R "${ext_path}" "${backup_dir}"; then
        echo "ERROR: Failed to create backup" >&2
        return 1
    fi

    # Save modified files and user-added files
    if [[ -f "${ext_path}/.extension.checksum" ]]; then
        echo "Checking for modified and user-added files..."
        cd "${ext_path}" || return 1

        # Check each file against checksum to identify modifications
        while IFS= read -r line; do
            [[ "${line}" =~ ^# ]] && continue
            [[ -z "${line}" ]] && continue

            local checksum
            local filename
            checksum=$(echo "${line}" | awk '{print $1}')
            filename=$(echo "${line}" | awk '{print $2}')

            [[ -f "${filename}" ]] || continue

            # Calculate current checksum
            local current_checksum
            current_checksum=$(sha256sum "${filename}" 2> /dev/null | awk '{print $1}')

            # If modified, create .save file
            if [[ "${current_checksum}" != "${checksum}" ]]; then
                echo "  Preserving modified file: ${filename}"
                mkdir -p "$(dirname "${filename}.save")"
                cp "${filename}" "${filename}.save"
            fi
        done < ".extension.checksum"

        # Find user-added files (exist but not in checksum)
        find . -type f \( -name "*.conf" -o -name "*.sh" -o -name "*.sql" -o -name "*.rcv" -o -name "*.rman" -o -name "*.env" -o -name "*.properties" \) | while read -r user_file; do
            # Remove leading ./
            user_file="${user_file#./}"
            
            # Skip if file is in checksum
            if grep -q " ${user_file}$" ".extension.checksum" 2>/dev/null; then
                continue
            fi
            
            # This is a user-added file, preserve it
            echo "  Preserving user-added file: ${user_file}"
            mkdir -p "$(dirname "${user_file}.save")"
            cp "${user_file}" "${user_file}.save"
        done
    fi

    # Remove old files (except log/, *.save, and backup)
    echo "Removing old files..."
    cd "${ext_path}" || return 1

    # Remove managed directories
    for dir in bin sql rcv etc lib; do
        if [[ -d "${dir}" ]]; then
            # Keep .save files in etc/
            if [[ "${dir}" == "etc" ]]; then
                find etc -type f ! -name "*.save" -delete 2> /dev/null
            else
                rm -rf "${dir}"
            fi
        fi
    done

    # Remove metadata files (new ones will be copied)
    rm -f .extension .extension.checksum .checksumignore

    # Copy new content (using tar to preserve all files including dot files)
    echo "Installing new version..."
    if ! (cd "${new_content_dir}" && tar cf - .) | (cd "${ext_path}" && tar xf -); then
        echo "ERROR: Failed to copy new content" >&2
        echo "Backup available at: ${backup_dir}" >&2
        return 1
    fi

    # Restore .save files to their original names
    # Keep .save backups to match update expectations
    if find "${ext_path}" -name "*.save" -type f | read; then
        echo "Restoring modified and user-added files..."
        cd "${ext_path}" || return 1
        find . -name "*.save" -type f | while read -r save_file; do
            original_name="${save_file%.save}"
            if [[ -e "${original_name}" ]]; then
                continue
            fi
            echo "  Restoring: ${original_name}"
            cp -p "${save_file}" "${original_name}"
        done
    fi

    echo "Update completed. Backup: ${backup_dir}"
    return 0
}

# ------------------------------------------------------------------------------
# Command: create - Create new extension from template
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_create
# Purpose.: Create new extension from template
# Args....: $@ - Command-line options (--path, --template, --from-github)
# Returns.: 0 on success, 1 on failure
# Output..: Creation status and instructions to stdout
# Notes...: Supports custom templates, GitHub templates, or embedded templates
#           Interactive name prompting if not provided
#           Validates name and target path
#           Extracts and renames template files
# ------------------------------------------------------------------------------
cmd_create() {
    local ext_name=""
    local target_path="${ORADBA_LOCAL_BASE}"
    local template_file=""
    local use_github=false
    local temp_dir=""
    local ext_version="0.1.0"
    log_debug "cmd_create invoked with args: '$*'"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --path)
                target_path="$2"
                shift 2
                ;;
            --template)
                template_file="$2"
                shift 2
                ;;
            --from-github)
                use_github=true
                shift
                ;;
            -*)
                echo "ERROR: Unknown option: $1" >&2
                return 1
                ;;
            *)
                if [[ -z "${ext_name}" ]]; then
                    ext_name="$1"
                    shift
                else
                    echo "ERROR: Unexpected argument: $1" >&2
                    return 1
                fi
                ;;
        esac
    done

    # Validate extension name
    if [[ -z "${ext_name}" ]]; then
        echo "ERROR: Extension name is required" >&2
        echo "Usage: $(basename "$0") create <name> [options]" >&2
        return 1
    fi

    if ! validate_extension_name "${ext_name}"; then
        return 1
    fi

    # Validate target path
    if [[ -z "${target_path}" ]]; then
        echo "ERROR: Target path not set. Please set ORADBA_LOCAL_BASE or use --path option" >&2
        return 1
    fi

    if [[ ! -d "${target_path}" ]]; then
        echo "ERROR: Target directory does not exist: ${target_path}" >&2
        echo "Please create it first: mkdir -p ${target_path}" >&2
        return 1
    fi

    # Check if extension already exists
    local ext_path="${target_path}/${ext_name}"
    if [[ -e "${ext_path}" ]]; then
        echo "ERROR: Extension already exists: ${ext_path}" >&2
        return 1
    fi

    # Determine template source
    if [[ "${use_github}" == "true" ]]; then
        echo -e "${BOLD}Creating extension from GitHub release${NC}"
        temp_dir=$(mktemp -d)
        template_file="${temp_dir}/github-release.tar.gz"

        # Capture output: last line is tag_name, others are status messages
        local github_output
        github_output=$(download_github_release "${template_file}")
        local download_status=$?

        if [[ ${download_status} -ne 0 ]]; then
            rm -rf "${temp_dir}"
            return 1
        fi

        # Extract version from last line of output (tag_name)
        ext_version=$(echo "${github_output}" | tail -1)
        # Remove 'v' prefix if present (e.g., v0.1.0 -> 0.1.0)
        ext_version="${ext_version#v}"
        log_debug "Using GitHub template, version='${ext_version}', file='${template_file}'"
    elif [[ -n "${template_file}" ]]; then
        echo -e "${BOLD}Creating extension from custom template${NC}"
        if [[ ! -f "${template_file}" ]]; then
            echo "ERROR: Template file not found: ${template_file}" >&2
            return 1
        fi
        log_debug "Using custom template file='${template_file}'"
    else
        # Use default template from templates/oradba_extension/
        echo -e "${BOLD}Creating extension from default template${NC}"
        template_file="${BASE_DIR}/templates/oradba_extension/extension-template.tar.gz"

        if [[ ! -f "${template_file}" ]]; then
            echo "ERROR: Default template not found: ${template_file}" >&2
            echo "The extension template was not included in this installation." >&2
            echo "" >&2
            echo "Options:" >&2
            echo "  1. Use --from-github to download the latest template" >&2
            echo "  2. Provide a custom template with --template <file>" >&2
            echo "  3. Download template manually: make download-extensions (in oradba source)" >&2
            return 1
        fi

        # Check if version info is available
        local version_file="${BASE_DIR}/templates/oradba_extension/.version"
        if [[ -f "${version_file}" ]]; then
            local template_version
            template_version=$(cat "${version_file}" 2> /dev/null || echo "unknown")
            echo "Template version: ${template_version}"
            # Set extension version from template version (remove 'v' prefix if present)
            ext_version="${template_version#v}"
        fi
        log_debug "Using default template file='${template_file}', version='${ext_version}'"
    fi

    echo ""
    echo "Extension name: ${ext_name}"
    echo "Target location: ${ext_path}"
    echo "Template: ${template_file}"
    echo ""

    # Extract template
    echo "Extracting template..."

    # Create temporary extraction directory
    local extract_dir
    extract_dir=$(mktemp -d)

    # First, check what's in the tarball
    if [[ "${DEBUG:-0}" -eq 1 ]]; then
        echo "DEBUG: Tarball contents:"
        tar -tzf "${template_file}" | head -20
    fi

    if ! tar -xzf "${template_file}" -C "${extract_dir}" 2> /dev/null; then
        echo "ERROR: Failed to extract template" >&2
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    # Find the extracted directory (it might be named differently)
    local extracted_dir
    local item_count
    item_count=$(find "${extract_dir}" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')

    # Check if there's exactly one item and it's a directory
    if [[ ${item_count} -eq 1 ]]; then
        extracted_dir=$(find "${extract_dir}" -mindepth 1 -maxdepth 1 -type d)
        if [[ -z "${extracted_dir}" ]]; then
            # Single item but not a directory
            echo "ERROR: Unexpected template structure" >&2
            rm -rf "${extract_dir}"
            [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
            return 1
        fi
    elif [[ ${item_count} -gt 1 ]]; then
        # Multiple items at root level - files extracted directly
        extracted_dir="${extract_dir}"
        if [[ "${DEBUG:-0}" -eq 1 ]]; then
            echo "DEBUG: Template files extracted directly (no single top-level directory)"
        fi
        log_debug "Template extracted flat into '${extract_dir}'"
    else
        echo "ERROR: No files found in template archive" >&2
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    # Move to target location
    if [[ "${extracted_dir}" == "${extract_dir}" ]]; then
        # Files were extracted directly, create target and move contents
        # Extract directly to the target path instead
        rm -rf "${extract_dir}"
        mkdir -p "${ext_path}"
        if ! tar -xzf "${template_file}" -C "${ext_path}" 2> /dev/null; then
            echo "ERROR: Failed to extract template to target location" >&2
            rm -rf "${ext_path}"
            [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
            return 1
        fi
    else
        # Normal case: directory was extracted
        if ! mv "${extracted_dir}" "${ext_path}"; then
            echo "ERROR: Failed to move extension to target location" >&2
            rm -rf "${extract_dir}"
            [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
            return 1
        fi
        # Clean up temp extraction dir
        rm -rf "${extract_dir}"
    fi

    # Clean up GitHub download temp dir if used
    [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"

    # Update metadata if .extension file exists
    if [[ -f "${ext_path}/.extension" ]]; then
        echo "Updating extension metadata..."
        # Update name (support both key=value and key: value formats)
        sed -i.bak "s/^name[=:].*/name: ${ext_name}/" "${ext_path}/.extension" 2> /dev/null \
            || sed -i '' "s/^name[=:].*/name: ${ext_name}/" "${ext_path}/.extension" 2> /dev/null
        # Update version
        sed -i.bak "s/^version[=:].*/version: ${ext_version}/" "${ext_path}/.extension" 2> /dev/null \
            || sed -i '' "s/^version[=:].*/version: ${ext_version}/" "${ext_path}/.extension" 2> /dev/null
        rm -f "${ext_path}/.extension.bak"

        echo "  Name:    ${ext_name}"
        echo "  Version: ${ext_version}"
        log_debug "Updated metadata for name='${ext_name}', version='${ext_version}'"
    fi

    echo -e "${GREEN}✓ Extension created successfully${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "1. Review and customize the extension:"
    echo "   cd ${ext_path}"
    echo ""
    echo "2. Edit the metadata file:"
    echo "   vi ${ext_path}/.extension"
    echo ""
    echo "3. Customize configuration files:"
    echo "   ls ${ext_path}/etc/"
    echo ""
    echo "4. Add your scripts and SQL files:"
    echo "   - Executables: ${ext_path}/bin/"
    echo "   - SQL scripts: ${ext_path}/sql/"
    echo "   - RMAN scripts: ${ext_path}/rcv/"
    echo "   - Config files: ${ext_path}/etc/"
    echo ""
    echo "5. Reload your environment to discover the extension:"
    echo "   source \${ORADBA_BASE}/bin/oraenv.sh \${ORACLE_SID}"
    echo ""
    echo "6. Verify the extension is loaded:"
    echo "   oradba_extension.sh list"
    echo ""

    return 0
}

# ------------------------------------------------------------------------------
# Command: add - Add/install extension from GitHub or local tarball
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_add
# Purpose.: Add/install extension from source
# Args....: $@ - Source and command-line options
# Returns.: 0 on success, 1 on failure
# Output..: Installation status to stdout
# Notes...: Supports: GitHub repos (owner/repo[@version]), URLs, local tarballs
#           Validates structure, handles updates with --update flag
#           Creates ORADBA_LOCAL_BASE if needed
#           Extracts to target directory
# ------------------------------------------------------------------------------
cmd_add() {
    local source=""
    local target_path="${ORADBA_LOCAL_BASE}"
    local ext_name=""
    local do_update=false
    local temp_dir=""
    local tarball_path=""
    log_debug "cmd_add invoked with args: '$*'"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --path)
                target_path="$2"
                shift 2
                ;;
            --name)
                ext_name="$2"
                shift 2
                ;;
            --update)
                do_update=true
                shift
                ;;
            -*)
                echo "ERROR: Unknown option: $1" >&2
                return 1
                ;;
            *)
                if [[ -z "${source}" ]]; then
                    source="$1"
                    shift
                else
                    echo "ERROR: Unexpected argument: $1" >&2
                    return 1
                fi
                ;;
        esac
    done

    # Validate source
    if [[ -z "${source}" ]]; then
        echo "ERROR: Extension source is required" >&2
        echo "Usage: $(basename "$0") add <source> [options]" >&2
        return 1
    fi

    # Validate target path
    if [[ -z "${target_path}" ]]; then
        echo "ERROR: Target path not set. Please set ORADBA_LOCAL_BASE or use --path option" >&2
        return 1
    fi

    if [[ ! -d "${target_path}" ]]; then
        echo "ERROR: Target directory does not exist: ${target_path}" >&2
        echo "Please create it first: mkdir -p ${target_path}" >&2
        return 1
    fi

    # Determine source type and get tarball
    if [[ -f "${source}" ]]; then
        # Local tarball
        echo -e "${BOLD}Adding extension from local tarball${NC}"
        tarball_path="${source}"
        log_debug "Source type=local file, tarball='${tarball_path}'"

    elif [[ "${source}" =~ ^https?:// ]]; then
        # Full URL - download to temp location
        echo -e "${BOLD}Adding extension from URL${NC}"
        temp_dir=$(mktemp -d)
        tarball_path="${temp_dir}/extension.tar.gz"

        echo "Downloading: ${source}"
        if command -v curl > /dev/null 2>&1; then
            if ! curl -fsSL -o "${tarball_path}" "${source}"; then
                echo "ERROR: Failed to download from URL" >&2
                rm -rf "${temp_dir}"
                return 1
            fi
        elif command -v wget > /dev/null 2>&1; then
            if ! wget -q -O "${tarball_path}" "${source}"; then
                echo "ERROR: Failed to download from URL" >&2
                rm -rf "${temp_dir}"
                return 1
            fi
        else
            echo "ERROR: Neither curl nor wget found" >&2
            rm -rf "${temp_dir}"
            return 1
        fi
        log_debug "Source type=URL, downloaded to '${tarball_path}'"

    else
        # GitHub repo (short format or repo@version)
        echo -e "${BOLD}Adding extension from GitHub${NC}"
        temp_dir=$(mktemp -d)
        tarball_path="${temp_dir}/extension.tar.gz"

        # Parse repo and version
        local repo="${source}"
        local version=""
        if [[ "${source}" =~ @ ]]; then
            repo="${source%@*}"
            version="${source#*@}"
        fi

        # Download from GitHub release
        if ! download_extension_from_github "${repo}" "${version}" "${tarball_path}"; then
            rm -rf "${temp_dir}"
            return 1
        fi
        log_debug "Source type=GitHub repo='${repo}', version='${version:-latest}', tarball='${tarball_path}'"
    fi

    # Validate tarball exists
    if [[ ! -f "${tarball_path}" ]]; then
        echo "ERROR: Tarball not found: ${tarball_path}" >&2
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    echo "Tarball: ${tarball_path}"
    echo ""

    # Extract to temporary location for inspection
    local extract_dir
    extract_dir=$(mktemp -d)

    echo "Extracting tarball..."
    if ! tar -xzf "${tarball_path}" -C "${extract_dir}" 2> /dev/null; then
        echo "ERROR: Failed to extract tarball" >&2
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    # Determine extracted structure
    local extracted_dir
    local item_count
    item_count=$(find "${extract_dir}" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')

    if [[ ${item_count} -eq 1 ]]; then
        extracted_dir=$(find "${extract_dir}" -mindepth 1 -maxdepth 1 -type d)
        if [[ -z "${extracted_dir}" ]]; then
            # Single item but not a directory
            extracted_dir="${extract_dir}"
        fi
    elif [[ ${item_count} -gt 1 ]]; then
        # Multiple items at root level
        extracted_dir="${extract_dir}"
    else
        echo "ERROR: No files found in tarball" >&2
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    # Validate extension structure
    if ! validate_extension_structure "${extracted_dir}"; then
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    # Determine extension name
    if [[ -z "${ext_name}" ]]; then
        # Try to get from .extension file
        if [[ -f "${extracted_dir}/.extension" ]]; then
            ext_name=$(parse_extension_metadata "${extracted_dir}/.extension" "name")
        fi

        # Fall back to directory name from extraction
        if [[ -z "${ext_name}" ]]; then
            if [[ "${extracted_dir}" != "${extract_dir}" ]]; then
                ext_name=$(basename "${extracted_dir}")
            else
                # Extracted flat, use tarball name
                ext_name=$(basename "${tarball_path}" | sed 's/\.tar\.gz$//;s/\.tgz$//')
            fi
        fi
    fi
    log_debug "Determined extension name='${ext_name}'"

    # Validate extension name
    if ! validate_extension_name "${ext_name}"; then
        rm -rf "${extract_dir}"
        [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
        return 1
    fi

    local ext_path="${target_path}/${ext_name}"

    echo "Extension name: ${ext_name}"
    echo "Target location: ${ext_path}"
    echo ""

    # Check if extension exists
    if [[ -e "${ext_path}" ]]; then
        if [[ "${do_update}" != "true" ]]; then
            echo "ERROR: Extension already exists: ${ext_path}" >&2
            echo "Use --update to update existing extension" >&2
            rm -rf "${extract_dir}"
            [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
            return 1
        fi

        # Perform update
        echo "Updating existing extension..."
        if ! update_extension "${ext_path}" "${extracted_dir}"; then
            rm -rf "${extract_dir}"
            [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
            return 1
        fi
        log_debug "Updated existing extension at '${ext_path}'"
    else
        # New installation
        echo "Installing extension..."
        if [[ "${extracted_dir}" == "${extract_dir}" ]]; then
            # Files extracted flat, create target and copy
            mkdir -p "${ext_path}"
            # Use rsync or tar to preserve hidden files
            if command -v rsync &> /dev/null; then
                if ! rsync -a "${extracted_dir}/" "${ext_path}/"; then
                    echo "ERROR: Failed to copy extension files" >&2
                    rm -rf "${ext_path}"
                    rm -rf "${extract_dir}"
                    [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
                    return 1
                fi
            else
                # Fallback: use tar to preserve all files including hidden ones
                if ! (cd "${extracted_dir}" && tar cf - .) | (cd "${ext_path}" && tar xf -); then
                    echo "ERROR: Failed to copy extension files" >&2
                    rm -rf "${ext_path}"
                    rm -rf "${extract_dir}"
                    [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
                    return 1
                fi
            fi
        else
            # Normal directory structure, move it
            if ! mv "${extracted_dir}" "${ext_path}"; then
                echo "ERROR: Failed to move extension to target location" >&2
                rm -rf "${extract_dir}"
                [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"
                return 1
            fi
        fi

        # Enable extension by default
        if [[ -f "${ext_path}/.extension" ]]; then
            # Update or add enabled: true
            if grep -q "^enabled:" "${ext_path}/.extension"; then
                sed -i.bak "s/^enabled:.*/enabled: true/" "${ext_path}/.extension" 2> /dev/null \
                    || sed -i '' "s/^enabled:.*/enabled: true/" "${ext_path}/.extension" 2> /dev/null
            else
                echo "enabled: true" >> "${ext_path}/.extension"
            fi
            rm -f "${ext_path}/.extension.bak"
        fi
        log_debug "Installed new extension to '${ext_path}'"
    fi

    # Clean up
    rm -rf "${extract_dir}"
    [[ -n "${temp_dir}" ]] && rm -rf "${temp_dir}"

    echo -e "${GREEN}✓ Extension added successfully${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "1. Review extension configuration:"
    echo "   cd ${ext_path}"
    echo ""
    echo "2. Check extension info:"
    echo "   oradba_extension.sh info ${ext_name}"
    echo ""
    echo "3. Reload your environment:"
    echo "   source \${ORADBA_BASE}/bin/oraenv.sh \${ORACLE_SID}"
    echo ""
    echo "4. Verify the extension is loaded:"
    echo "   oradba_extension.sh list"
    echo ""

    return 0
}

# ------------------------------------------------------------------------------
# Function: format_status
# Purpose.: Format extension status with color
# Args....: $1 - Status string ("Enabled" or "Disabled")
# Returns.: 0
# Output..: Colored status string to stdout
# Notes...: Green for Enabled, Red for Disabled, Yellow for unknown
#           Uses terminal color codes if TTY detected
# ------------------------------------------------------------------------------
format_status() {
    local status="$1"
    case "${status}" in
        Enabled)
            echo -e "${GREEN}${status}${NC}"
            ;;
        Disabled)
            echo -e "${RED}${status}${NC}"
            ;;
        *)
            echo "${status}"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Command: list - List all extensions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_list
# Purpose.: List all installed extensions with details
# Args....: $@ - Command-line options (--verbose, -v)
# Returns.: 0
# Output..: Formatted table of extensions to stdout
# Notes...: Shows: name, version, priority, status (enabled/disabled)
#           Verbose mode adds: provides (bin/sql/rcv/etc/doc), path
#           Uses get_all_extensions() from extensions.sh library
# ------------------------------------------------------------------------------
cmd_list() {
    local verbose=false
    log_debug "cmd_list invoked with args: '$*'"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v | --verbose)
                verbose=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    echo -e "${BOLD}OraDBA Extensions${NC}"
    echo ""

    # Get all extensions
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    log_debug "Found ${#extensions[@]} extension(s)"

    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        echo ""
        echo "Search locations:"
        echo "  Auto-discovery: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
        if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" == "true" ]]; then
            echo "  Local base: ${ORADBA_LOCAL_BASE:-not set}"
        fi
        if [[ -n "${ORADBA_EXTENSION_PATHS}" ]]; then
            echo "  Manual paths: ${ORADBA_EXTENSION_PATHS}"
        fi
        return 0
    fi

    # Sort by priority
    local sorted
    mapfile -t sorted < <(sort_extensions_by_priority "${extensions[@]}")
    log_debug "Sorted ${#sorted[@]} extension(s) by priority"

    if [[ "${verbose}" == "true" ]]; then
        # Verbose output
        for ext_path in "${sorted[@]}"; do
            local name version description priority enabled_status
            name="$(get_extension_name "${ext_path}")"
            version="$(get_extension_version "${ext_path}")"
            description="$(get_extension_description "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"

            if is_extension_enabled "${name}" "${ext_path}"; then
                enabled_status="Enabled"
            else
                enabled_status="Disabled"
            fi

            echo -e "${CYAN}${name}${NC} (${version})"
            echo "  Status: $(format_status "${enabled_status}")"
            echo "  Priority: ${priority}"
            echo "  Path: ${ext_path}"
            if [[ -n "${description}" ]]; then
                echo "  Description: ${description}"
            fi
            echo ""
        done
    else
        # Compact output - table format
        printf "%-20s %-12s %-10s %-10s\n" "NAME" "VERSION" "PRIORITY" "STATUS"
        printf "%-20s %-12s %-10s %-10s\n" "----" "-------" "--------" "------"

        for ext_path in "${sorted[@]}"; do
            local name version priority enabled_status
            name="$(get_extension_name "${ext_path}")"
            version="$(get_extension_version "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"

            if is_extension_enabled "${name}" "${ext_path}"; then
                enabled_status="Enabled"
            else
                enabled_status="Disabled"
            fi

            printf "%-20s %-12s %-10s " "${name}" "${version}" "${priority}"
            format_status "${enabled_status}"
        done
    fi

    echo ""
    echo "Total: ${#extensions[@]} extension(s)"
}

# ------------------------------------------------------------------------------
# Command: info - Show detailed extension info
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_info
# Purpose.: Display detailed information about specific extension
# Args....: $1 - Extension name
# Returns.: 0 on success, 1 if not found
# Output..: Extension metadata to stdout
# Notes...: Shows: name, version, description, author, status, provides, path
#           Reads from .extension file if available
#           Falls back to directory structure analysis
# ------------------------------------------------------------------------------
cmd_info() {
    local ext_name="$1"

    if [[ -z "${ext_name}" ]]; then
        echo "ERROR: Extension name required" >&2
        echo "Usage: $(basename "$0") info <extension-name>" >&2
        return 1
    fi

    # Find extension
    local extensions ext_path found=false
    mapfile -t extensions < <(get_all_extensions)

    for path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${path}")"
        if [[ "${name}" == "${ext_name}" ]]; then
            ext_path="${path}"
            found=true
            break
        fi
    done

    if [[ "${found}" != "true" ]]; then
        echo "ERROR: Extension '${ext_name}' not found" >&2
        return 1
    fi

    # Show info using library function
    show_extension_info "${ext_path}"
}

# ------------------------------------------------------------------------------
# Command: validate - Validate extension structure
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_validate
# Purpose.: Validate specific extension structure and metadata
# Args....: $1 - Extension name
# Returns.: 0 if valid, 1 if invalid
# Output..: Validation results to stdout
# Notes...: Checks: directory exists, .extension file, required fields, structure
#           Uses get_extension_path() and validate_extension_structure()
#           Provides detailed validation report
# ------------------------------------------------------------------------------
cmd_validate() {
    local target="$1"

    if [[ -z "${target}" ]]; then
        echo "ERROR: Extension name or path required" >&2
        echo "Usage: $(basename "$0") validate <extension-name|path>" >&2
        return 1
    fi

    local ext_path

    # Check if target is a path
    if [[ -d "${target}" ]]; then
        ext_path="${target}"
    else
        # Find extension by name
        local extensions found=false
        mapfile -t extensions < <(get_all_extensions)

        for path in "${extensions[@]}"; do
            local name
            name="$(get_extension_name "${path}")"
            if [[ "${name}" == "${target}" ]]; then
                ext_path="${path}"
                found=true
                break
            fi
        done

        if [[ "${found}" != "true" ]]; then
            echo "ERROR: Extension '${target}' not found" >&2
            return 1
        fi
    fi

    # Validate using library function
    local name
    name="$(basename "${ext_path}")"
    echo -e "${BOLD}Validating extension: ${name}${NC}"
    echo ""

    if validate_extension "${ext_path}"; then
        echo ""
        echo -e "${GREEN}✓ Validation passed${NC}"
        return 0
    else
        echo ""
        echo -e "${YELLOW}⚠ Validation completed with warnings${NC}"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# Command: validate-all - Validate all extensions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_validate_all
# Purpose.: Validate all installed extensions
# Args....: None
# Returns.: 0 if all valid, 1 if any invalid
# Output..: Validation summary for all extensions to stdout
# Notes...: Iterates through all extensions found by get_all_extensions()
#           Reports count of valid/invalid extensions
#           Shows validation status per extension
# ------------------------------------------------------------------------------
cmd_validate_all() {
    echo -e "${BOLD}Validating all extensions${NC}"
    echo ""

    local extensions
    mapfile -t extensions < <(get_all_extensions)

    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi

    local total=${#extensions[@]}
    local passed=0
    local warnings=0

    for ext_path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${ext_path}")"
        echo -e "${CYAN}${name}${NC} (${ext_path})"

        if validate_extension "${ext_path}" 2>&1 | grep -q "Warning"; then
            warnings=$((warnings + 1))
        else
            passed=$((passed + 1))
        fi
        echo ""
    done

    echo "----------------------------------------"
    echo "Total extensions: ${total}"
    echo -e "${GREEN}Passed: ${passed}${NC}"
    if [[ ${warnings} -gt 0 ]]; then
        echo -e "${YELLOW}With warnings: ${warnings}${NC}"
    fi
}

# ------------------------------------------------------------------------------
# Command: discover - Show auto-discovered extensions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_discover
# Purpose.: Discover and list all extensions in search paths
# Args....: None
# Returns.: 0
# Output..: Discovered extensions with paths to stdout
# Notes...: Searches in ORADBA_LOCAL_BASE and configured paths
#           Shows discovery process and results
#           Uses extension auto-discovery mechanism
# ------------------------------------------------------------------------------
cmd_discover() {
    log_debug "cmd_discover invoked"
    echo -e "${BOLD}Auto-Discovery Configuration${NC}"
    echo ""
    echo "Auto-discovery: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
    echo "Local base: ${ORADBA_LOCAL_BASE:-not set}"
    echo ""

    if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" != "true" ]]; then
        echo "Auto-discovery is disabled."
        return 0
    fi

    if [[ -z "${ORADBA_LOCAL_BASE}" || ! -d "${ORADBA_LOCAL_BASE}" ]]; then
        echo "Local base directory not found or not set."
        return 0
    fi

    echo -e "${BOLD}Auto-Discovered Extensions:${NC}"
    echo ""

    local discovered
    mapfile -t discovered < <(discover_extensions)
    log_debug "Discovered ${#discovered[@]} extension(s) in '${ORADBA_LOCAL_BASE:-unset}'"

    if [[ ${#discovered[@]} -eq 0 ]]; then
        echo "No extensions discovered in ${ORADBA_LOCAL_BASE}"
        return 0
    fi

    for ext_path in "${discovered[@]}"; do
        local name
        name="$(basename "${ext_path}")"
        echo "  ${name} -> ${ext_path}"
    done

    echo ""
    echo "Total: ${#discovered[@]} extension(s)"
}

# ------------------------------------------------------------------------------
# Command: paths - Show extension search paths
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_paths
# Purpose.: Display extension search paths
# Args....: None
# Returns.: 0
# Output..: List of extension search paths to stdout
# Notes...: Shows configured ORADBA_LOCAL_BASE and extension directories
#           Indicates which paths are active/available
#           Useful for troubleshooting extension loading
# ------------------------------------------------------------------------------
cmd_paths() {
    log_debug "cmd_paths invoked"
    echo -e "${BOLD}Extension Search Paths${NC}"
    echo ""

    echo "Auto-discovery:"
    echo "  Enabled: ${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}"
    if [[ "${ORADBA_AUTO_DISCOVER_EXTENSIONS:-true}" == "true" ]]; then
        echo "  Base: ${ORADBA_LOCAL_BASE:-not set}"
        if [[ -d "${ORADBA_LOCAL_BASE}" ]]; then
            echo "  Status: ${GREEN}exists${NC}"
        else
            echo "  Status: ${RED}not found${NC}"
        fi
    fi

    echo ""
    echo "Manual paths:"
    if [[ -n "${ORADBA_EXTENSION_PATHS}" ]]; then
        IFS=':' read -ra paths <<< "${ORADBA_EXTENSION_PATHS}"
        for path in "${paths[@]}"; do
            if [[ -d "${path}" ]]; then
                echo "  ${path} ${GREEN}✓${NC}"
            else
                echo "  ${path} ${RED}✗${NC}"
            fi
        done
    else
        echo "  (none configured)"
    fi
}

# ------------------------------------------------------------------------------
# Command: enabled - List enabled extensions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_enabled
# Purpose.: List only enabled extensions
# Args....: None
# Returns.: 0
# Output..: Formatted table of enabled extensions to stdout
# Notes...: Filters extensions by enabled status
#           Shows: name, version, priority
#           Uses is_extension_enabled() check
# ------------------------------------------------------------------------------
cmd_enabled() {
    log_debug "cmd_enabled invoked"
    echo -e "${BOLD}Enabled Extensions${NC}"
    echo ""

    local extensions
    mapfile -t extensions < <(get_all_extensions)
    log_debug "Found ${#extensions[@]} extension(s)"

    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi

    local sorted
    mapfile -t sorted < <(sort_extensions_by_priority "${extensions[@]}")

    local count=0
    printf "%-20s %-12s %-10s\n" "NAME" "VERSION" "PRIORITY"
    printf "%-20s %-12s %-10s\n" "----" "-------" "--------"

    for ext_path in "${sorted[@]}"; do
        local name version priority
        name="$(get_extension_name "${ext_path}")"

        if is_extension_enabled "${name}" "${ext_path}"; then
            version="$(get_extension_version "${ext_path}")"
            priority="$(get_extension_priority "${ext_path}")"
            printf "%-20s %-12s %-10s\n" "${name}" "${version}" "${priority}"
            count=$((count + 1))
        fi
    done

    echo ""
    echo "Total: ${count} enabled extension(s)"
}

# ------------------------------------------------------------------------------
# Command: disabled - List disabled extensions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_disabled
# Purpose.: List only disabled extensions
# Args....: None
# Returns.: 0
# Output..: Formatted table of disabled extensions to stdout
# Notes...: Filters extensions by disabled status
#           Shows: name, version
#           Useful for identifying inactive extensions
# ------------------------------------------------------------------------------
cmd_disabled() {
    log_debug "cmd_disabled invoked"
    echo -e "${BOLD}Disabled Extensions${NC}"
    echo ""

    local extensions
    mapfile -t extensions < <(get_all_extensions)
    log_debug "Found ${#extensions[@]} extension(s)"

    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions found."
        return 0
    fi

    local count=0
    printf "%-20s %-12s\n" "NAME" "VERSION"
    printf "%-20s %-12s\n" "----" "-------"

    for ext_path in "${extensions[@]}"; do
        local name version
        name="$(get_extension_name "${ext_path}")"

        if ! is_extension_enabled "${name}" "${ext_path}"; then
            version="$(get_extension_version "${ext_path}")"
            printf "%-20s %-12s\n" "${name}" "${version}"
            count=$((count + 1))
        fi
    done

    echo ""
    echo "Total: ${count} disabled extension(s)"
}

# ------------------------------------------------------------------------------
# Command: enable - Enable an extension
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_enable
# Purpose.: Enable a specific extension by updating its .extension metadata
# Args....: $1 - Extension name
# Returns.: 0 on success, 1 on error
# Output..: Success/error message to stdout/stderr
# Notes...: Updates enabled: true in .extension file
#           Creates .extension file if missing
#           Prompts user to reload environment
# ------------------------------------------------------------------------------
cmd_enable() {
    local ext_name="$1"
    
    if [[ -z "${ext_name}" ]]; then
        echo "ERROR: Extension name required" >&2
        echo "Usage: $(basename "$0") enable <extension-name>" >&2
        return 1
    fi
    
    log_debug "cmd_enable invoked for '${ext_name}'"
    
    # Find extension (search discovered extensions first)
    local extensions ext_path found=false
    mapfile -t extensions < <(get_all_extensions)
    
    for path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${path}")"
        if [[ "${name}" == "${ext_name}" ]]; then
            ext_path="${path}"
            found=true
            break
        fi
    done
    
    # If not found in discovered extensions, check if directory exists in ORADBA_LOCAL_BASE
    if [[ "${found}" != "true" ]] && [[ -n "${ORADBA_LOCAL_BASE}" ]]; then
        local potential_path="${ORADBA_LOCAL_BASE}/${ext_name}"
        if [[ -d "${potential_path}" ]]; then
            ext_path="${potential_path}"
            found=true
            log_debug "Found undiscovered extension directory: ${potential_path}"
        fi
    fi
    
    if [[ "${found}" != "true" ]]; then
        echo "ERROR: Extension '${ext_name}' not found" >&2
        return 1
    fi
    
    # Update or create .extension file
    local metadata="${ext_path}/.extension"
    if [[ -f "${metadata}" ]]; then
        # Check if already enabled
        if is_extension_enabled "${ext_name}" "${ext_path}"; then
            echo "Extension '${ext_name}' is already enabled"
            return 0
        fi
        
        # Update existing file
        if grep -q "^enabled:" "${metadata}"; then
            # Replace existing enabled line
            sed -i.bak "s/^enabled:.*/enabled: true/" "${metadata}" 2> /dev/null \
                || sed -i '' "s/^enabled:.*/enabled: true/" "${metadata}" 2> /dev/null
        else
            # Add enabled line
            echo "enabled: true" >> "${metadata}"
        fi
        rm -f "${metadata}.bak"
    else
        # Create new metadata file (extension has no metadata yet)
        cat > "${metadata}" << EOF
name: ${ext_name}
enabled: true
EOF
    fi
    
    echo -e "${GREEN}✓ Extension '${ext_name}' enabled successfully${NC}"
    echo ""
    echo "To apply changes, reload your environment:"
    echo "  source \${ORADBA_BASE}/bin/oraenv.sh \${ORACLE_SID}"
    echo ""
    
    return 0
}

# ------------------------------------------------------------------------------
# Command: disable - Disable an extension
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function: cmd_disable
# Purpose.: Disable a specific extension by updating its .extension metadata
# Args....: $1 - Extension name
# Returns.: 0 on success, 1 on error
# Output..: Success/error message to stdout/stderr
# Notes...: Updates enabled: false in .extension file
#           Creates .extension file if missing
#           Prompts user to reload environment
# ------------------------------------------------------------------------------
cmd_disable() {
    local ext_name="$1"
    
    if [[ -z "${ext_name}" ]]; then
        echo "ERROR: Extension name required" >&2
        echo "Usage: $(basename "$0") disable <extension-name>" >&2
        return 1
    fi
    
    log_debug "cmd_disable invoked for '${ext_name}'"
    
    # Find extension (search discovered extensions first)
    local extensions ext_path found=false
    mapfile -t extensions < <(get_all_extensions)
    
    for path in "${extensions[@]}"; do
        local name
        name="$(get_extension_name "${path}")"
        if [[ "${name}" == "${ext_name}" ]]; then
            ext_path="${path}"
            found=true
            break
        fi
    done
    
    # If not found in discovered extensions, check if directory exists in ORADBA_LOCAL_BASE
    if [[ "${found}" != "true" ]] && [[ -n "${ORADBA_LOCAL_BASE}" ]]; then
        local potential_path="${ORADBA_LOCAL_BASE}/${ext_name}"
        if [[ -d "${potential_path}" ]]; then
            ext_path="${potential_path}"
            found=true
            log_debug "Found undiscovered extension directory: ${potential_path}"
        fi
    fi
    
    if [[ "${found}" != "true" ]]; then
        echo "ERROR: Extension '${ext_name}' not found" >&2
        return 1
    fi
    
    # Update or create .extension file
    local metadata="${ext_path}/.extension"
    if [[ -f "${metadata}" ]]; then
        # Check if already disabled
        if ! is_extension_enabled "${ext_name}" "${ext_path}"; then
            echo "Extension '${ext_name}' is already disabled"
            return 0
        fi
        
        # Update existing file
        if grep -q "^enabled:" "${metadata}"; then
            # Replace existing enabled line
            sed -i.bak "s/^enabled:.*/enabled: false/" "${metadata}" 2> /dev/null \
                || sed -i '' "s/^enabled:.*/enabled: false/" "${metadata}" 2> /dev/null
        else
            # Add enabled line
            echo "enabled: false" >> "${metadata}"
        fi
        rm -f "${metadata}.bak"
    else
        # Create new metadata file (extension has no metadata yet)
        cat > "${metadata}" << EOF
name: ${ext_name}
enabled: false
EOF
    fi
    
    echo -e "${GREEN}✓ Extension '${ext_name}' disabled successfully${NC}"
    echo ""
    echo "To apply changes, reload your environment:"
    echo "  source \${ORADBA_BASE}/bin/oraenv.sh \${ORACLE_SID}"
    echo ""
    
    return 0
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Main entry point for extension management tool
# Args....: $1 - Command (add|create|list|info|validate|validate-all|discover|paths|enabled|disabled|enable|disable|help)
#           $@ - Command-specific arguments
# Returns.: 0 on success, 1 on error
# Output..: Command output to stdout, errors to stderr
# Notes...: Dispatcher to cmd_* handler functions
#           Shows usage for unknown commands or help flags
# ------------------------------------------------------------------------------
main() {
    # Parse command
    local command="${1:-help}"
    shift || true

    case "${command}" in
        add)
            cmd_add "$@"
            ;;
        create)
            cmd_create "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        info)
            cmd_info "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        validate-all)
            cmd_validate_all "$@"
            ;;
        discover)
            cmd_discover "$@"
            ;;
        paths)
            cmd_paths "$@"
            ;;
        enabled)
            cmd_enabled "$@"
            ;;
        disabled)
            cmd_disabled "$@"
            ;;
        enable)
            cmd_enable "$@"
            ;;
        disable)
            cmd_disable "$@"
            ;;
        help | -h | --help)
            usage
            ;;
        *)
            echo "ERROR: Unknown command: ${command}" >&2
            echo ""
            usage
            return 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Pre-parse global flags and remove them from args
    mapfile -t _newargs < <(preparse_debug_flag "$@")
    main "${_newargs[@]}"
fi

# EOF
