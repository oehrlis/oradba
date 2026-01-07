#!/usr/bin/env bash
# Build a distributable tarball for the OraDBA extension template.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSION_DIR="${ROOT_DIR}/extension-template"
DIST_DIR="${ROOT_DIR}/dist"
VERSION_FILE="${ROOT_DIR}/VERSION"

CHECKSUM=true
DRY_RUN=false
VERSION=""

usage() {
    cat <<'EOF'
Usage: ./scripts/build.sh [options]

Builds a tarball for the extension template and writes a SHA256 checksum.
Options:
  --extension <path>   Path to the extension directory (default: extension-template)
  --dist <path>        Output directory for artifacts (default: dist/)
  --version <value>    Override version (default: read from VERSION or .extension)
  --skip-checksum      Do not create checksum file
  --dry-run            Show actions without writing files
  --help               Show this help
EOF
    exit 0
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

read_metadata_value() {
    local key="$1" file="$2"
    if [[ -f "$file" ]]; then
        awk -F':' -v k="$key" '$1 ~ "^"k"$" {gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+/, "", $2); print $2}' "$file" | head -n1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --extension)
            EXTENSION_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        --dist)
            DIST_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --skip-checksum)
            CHECKSUM=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

if [[ ! -d "$EXTENSION_DIR" ]]; then
    echo "Extension directory not found: $EXTENSION_DIR" >&2
    exit 1
fi

EXTENSION_NAME="$(basename "$EXTENSION_DIR")"

META_FILE="${EXTENSION_DIR}/.extension"
META_NAME="$(read_metadata_value "name" "$META_FILE")"
META_VERSION="$(read_metadata_value "version" "$META_FILE")"

if [[ -n "$META_NAME" ]]; then
    EXTENSION_NAME="$META_NAME"
fi

if [[ -z "$VERSION" ]]; then
    if [[ -f "$VERSION_FILE" ]]; then
        VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
    elif [[ -n "$META_VERSION" ]]; then
        VERSION="$META_VERSION"
    else
        echo "Version not provided and VERSION file missing" >&2
        exit 1
    fi
fi

TARBALL="${DIST_DIR}/${EXTENSION_NAME}-${VERSION}.tar.gz"
CHECKSUM_FILE="${TARBALL}.sha256"

echo "Extension : $EXTENSION_NAME"
echo "Version   : $VERSION"
echo "Source    : $EXTENSION_DIR"
echo "Artifacts :"
echo "  - $TARBALL"
if [[ "$CHECKSUM" == true ]]; then
    echo "  - $CHECKSUM_FILE"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run enabled; no files written."
    exit 0
fi

mkdir -p "$DIST_DIR"

tar -czf "$TARBALL" -C "$(dirname "$EXTENSION_DIR")" "$(basename "$EXTENSION_DIR")"
echo "Created tarball: $TARBALL"

if [[ "$CHECKSUM" == true ]]; then
    if command_exists sha256sum; then
        sha256sum "$TARBALL" > "$CHECKSUM_FILE"
    else
        shasum -a 256 "$TARBALL" > "$CHECKSUM_FILE"
    fi
    echo "Created checksum: $CHECKSUM_FILE"
fi
