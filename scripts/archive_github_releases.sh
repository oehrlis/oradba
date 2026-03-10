#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: archive_github_releases.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.03.10
# Revision...: 1.1.0
# Purpose....: Add archive notices to old GitHub releases
# Notes......: Dynamically fetches all releases and archives everything except
#              the N most recent ones (configurable via --keep).
#              Requires GitHub CLI (gh) and an authenticated session.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# 2026.03.10 oehrli - rewrite: replace hardcoded list with dynamic discovery
# 2026.02.11 oehrli - initial version
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
REPO="oehrlis/oradba"
DRY_RUN=false
KEEP=3          # Keep this many most-recent releases un-archived
BEFORE_VERSION="" # Archive everything before this explicit version tag

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Dynamically add archive notices to old GitHub releases.

All releases except the most recent --keep releases are marked with an archive
notice. Alternatively, use --before to archive everything prior to a specific
version tag.

OPTIONS:
    -d, --dry-run           Show what would be done without making changes
    -k, --keep N            Keep N most recent releases un-archived (default: ${KEEP})
    -b, --before VERSION    Archive all releases older than VERSION (e.g. v0.22.0)
    -r, --repo REPO         GitHub repository (default: ${REPO})
    -h, --help              Show this help message

EXAMPLES:
    # Preview: archive all but the 3 latest releases
    $(basename "$0") --dry-run

    # Archive all but the 5 latest releases
    $(basename "$0") --keep 5

    # Archive everything before v0.22.0
    $(basename "$0") --before v0.22.0

    # Apply to a different fork
    $(basename "$0") --repo myorg/oradba

EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -k|--keep)
            KEEP="$2"
            shift 2
            ;;
        -b|--before)
            BEFORE_VERSION="$2"
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Dependency checks
# ------------------------------------------------------------------------------
if ! command -v gh > /dev/null 2>&1; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}" >&2
    echo "Install with: brew install gh"
    exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
    echo -e "${RED}Error: Not authenticated with GitHub${NC}" >&2
    echo "Run: gh auth login"
    exit 1
fi

# ------------------------------------------------------------------------------
# Function: archive_release
# Purpose.: Add archive notice to a single release if not already present
# Args....: $1 - Version tag (e.g. v0.18.5)
# Returns.: 0 on success
# Output..: Status messages
# ------------------------------------------------------------------------------
archive_release() {
    local version="$1"
    local temp_file="/tmp/oradba_release_${version}.md"

    echo -e "${BLUE}Processing ${version}...${NC}"

    # Check if release exists
    if ! gh release view "${version}" --repo "${REPO}" > /dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠  Release ${version} not found, skipping${NC}"
        return 0
    fi

    # Get current release body
    local current_body
    current_body=$(gh release view "${version}" --repo "${REPO}" --json body -q .body)

    # Skip if already archived
    if echo "${current_body}" | grep -q "Archived Release" 2>/dev/null; then
        echo -e "  ${YELLOW}⏭  Already archived, skipping${NC}"
        return 0
    fi

    # Build new body with archive notice prepended
    cat > "${temp_file}" << EOF
> [!NOTE]
> **Archived Release** - This is an older version. See the [latest release](https://github.com/${REPO}/releases/latest) for the current version.

${current_body}
EOF

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY RUN] Would prepend archive notice to ${version}${NC}"
        echo -e "  ${YELLOW}Preview:${NC}"
        head -n 4 "${temp_file}" | sed 's/^/    /'
        echo "    ..."
    else
        if gh release edit "${version}" --repo "${REPO}" --notes-file "${temp_file}"; then
            echo -e "  ${GREEN}✓ Updated ${version}${NC}"
        else
            echo -e "  ${RED}✗ Failed to update ${version}${NC}"
        fi
        # Brief pause to avoid GitHub API rate limiting
        sleep 1
    fi

    rm -f "${temp_file}"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
echo "=========================================="
echo "OraDBA Archive GitHub Releases"
echo "=========================================="
echo "Repository : ${REPO}"
if [[ -n "${BEFORE_VERSION}" ]]; then
    echo "Mode       : archive before ${BEFORE_VERSION}"
else
    echo "Mode       : keep ${KEEP} most recent, archive the rest"
fi
echo "Dry Run    : ${DRY_RUN}"
echo "=========================================="
echo

if [[ "${DRY_RUN}" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN MODE — no changes will be made${NC}"
    echo
fi

# Fetch all release tags ordered newest-first (GitHub returns them that way)
echo -e "${BLUE}Fetching release list from ${REPO}...${NC}"
mapfile -t ALL_TAGS < <(
    gh release list --repo "${REPO}" --limit 200 --json tagName -q '.[].tagName'
)

total="${#ALL_TAGS[@]}"
echo -e "${GREEN}✓ Found ${total} releases${NC}"
echo

# Determine which tags to archive
declare -a TO_ARCHIVE=()

if [[ -n "${BEFORE_VERSION}" ]]; then
    # --before mode: archive everything strictly older than the named version
    found_boundary=false
    for tag in "${ALL_TAGS[@]}"; do
        if [[ "${tag}" == "${BEFORE_VERSION}" ]]; then
            found_boundary=true
            continue
        fi
        if [[ "${found_boundary}" == "true" ]]; then
            TO_ARCHIVE+=("${tag}")
        fi
    done
    if [[ "${found_boundary}" == "false" ]]; then
        echo -e "${RED}Error: --before version '${BEFORE_VERSION}' not found in release list${NC}" >&2
        exit 1
    fi
else
    # --keep mode: archive everything after the first KEEP releases
    if [[ "${KEEP}" -ge "${total}" ]]; then
        echo -e "${YELLOW}Nothing to archive — fewer releases than --keep ${KEEP}${NC}"
        exit 0
    fi
    TO_ARCHIVE=("${ALL_TAGS[@]:${KEEP}}")
fi

if [[ "${#TO_ARCHIVE[@]}" -eq 0 ]]; then
    echo -e "${YELLOW}Nothing to archive.${NC}"
    exit 0
fi

echo "Releases to archive: ${#TO_ARCHIVE[@]}"
echo

count=0
for version in "${TO_ARCHIVE[@]}"; do
    archive_release "${version}" || true
    ((count++)) || true
done

echo
echo "=========================================="
echo -e "${GREEN}Completed: processed ${count} release(s)${NC}"
echo "=========================================="

if [[ "${DRY_RUN}" == "true" ]]; then
    echo -e "${YELLOW}Run without --dry-run to apply changes${NC}"
fi
# - End of script --------------------------------------------------------------
