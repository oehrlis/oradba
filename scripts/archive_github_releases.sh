#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: archive_github_releases.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 1.0.0
# Purpose....: Add archive notices to old GitHub releases
# Notes......: Updates release descriptions with archive notices for outdated versions
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
REPO="oehrlis/oradba"
DRY_RUN=false
CURRENT_VERSION=""  # Will be fetched from GitHub

# Archived releases (v0.9.4 through v0.18.5 - pre-1.0 releases)
ARCHIVED_RELEASES=(
    v0.9.4 v0.9.5
    v0.10.0 v0.10.1 v0.10.2 v0.10.3 v0.10.4 v0.10.5
    v0.11.0 v0.11.1
    v0.12.0 v0.12.1
    v0.13.0 v0.13.1 v0.13.2 v0.13.3 v0.13.4 v0.13.5
    v0.14.0 v0.14.1 v0.14.2
    v0.15.0
    v0.16.0
    v0.17.0
    v0.18.0 v0.18.1 v0.18.2 v0.18.3 v0.18.4 v0.18.5
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Add archive notices to old GitHub releases.

OPTIONS:
    -d, --dry-run       Show what would be done without making changes
    -h, --help          Show this help message

EXAMPLES:
    # Preview changes
    $(basename "$0") --dry-run

    # Apply changes
    $(basename "$0")

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get the latest release version
echo -e "${BLUE}Fetching latest release...${NC}"
CURRENT_VERSION=$(gh release list --repo "$REPO" --limit 1 --json tagName -q '.[0].tagName' 2>/dev/null)
if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: Could not fetch latest release${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Latest release: $CURRENT_VERSION${NC}"
echo

# Function to archive a release
archive_release() {
    local version=$1
    
    echo -e "${BLUE}Processing $version...${NC}"
    
    # Check if release exists
    if ! gh release view "$version" --repo "$REPO" &> /dev/null; then
        echo -e "  ${YELLOW}⚠️  Release $version not found, skipping${NC}"
        return 0
    fi
    
    # Get current release notes
    local current_body
    current_body=$(gh release view "$version" --repo "$REPO" --json body -q .body)
    
    # Check if already archived
    if echo "$current_body" | grep -q "Archived Release" 2>/dev/null || false; then
        echo -e "  ${YELLOW}⏭️  Already archived, skipping${NC}"
        return 0
    fi
    
    # Create new body with archive notice
    local temp_file="/tmp/release_${version}.md"
    cat > "$temp_file" << EOF
> [!NOTE]
> **Archived Release** - This is an older version. See the [latest release](https://github.com/$REPO/releases/latest) for the current version.

$current_body
EOF
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[DRY RUN] Would update release $version${NC}"
        echo -e "  ${YELLOW}Preview of new content:${NC}"
        head -n 5 "$temp_file"
        echo "  ..."
    else
        # Update the release
        if gh release edit "$version" --repo "$REPO" --notes-file "$temp_file"; then
            echo -e "  ${GREEN}✓ Updated $version${NC}"
        else
            echo -e "  ${RED}✗ Failed to update $version${NC}"
        fi
    fi
    
    rm -f "$temp_file"
}

# Main execution
echo "=========================================="
echo "Archive GitHub Releases"
echo "=========================================="
echo "Repository: $REPO"
echo "Current Version: $CURRENT_VERSION"
echo "Releases to archive: ${#ARCHIVED_RELEASES[@]}"
echo "Dry Run: $DRY_RUN"
echo "=========================================="
echo

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo
fi

# Process each release
count=0
for version in "${ARCHIVED_RELEASES[@]}"; do
    archive_release "$version" || true
    count=$((count + 1))
    
    # Add delay to avoid rate limiting
    if [ "$DRY_RUN" = false ]; then
        sleep 1
    fi
done

echo
echo "=========================================="
echo -e "${GREEN}Completed: Processed $count releases${NC}"
echo "=========================================="

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Run without --dry-run to apply changes${NC}"
fi
