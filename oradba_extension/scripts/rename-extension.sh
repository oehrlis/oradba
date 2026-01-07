#!/usr/bin/env bash
# Rename the extension template after cloning/forking.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$ROOT_DIR"
OLD_NAME="extension-template"
NEW_NAME=""
DESCRIPTION=""
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: ./scripts/rename-extension.sh --name <newname> [options]

Options:
  --name <newname>        New extension name (required)
  --description <text>    Update description in .extension
  --current-name <name>   Current template directory name (default: extension-template)
  --workdir <path>        Root directory containing the extension (default: repo root)
  --dry-run               Show actions without applying changes
  --help                  Show this help
EOF
    exit 0
}

replace_tokens() {
    local file="$1" old="$2" new="$3" old_upper="$4" new_upper="$5" description="$6"
    python3 - "$file" "$old" "$new" "$old_upper" "$new_upper" "$description" <<'PY'
from pathlib import Path
import sys

path, old, new, old_upper, new_upper, description = sys.argv[1:]
text = Path(path).read_text()
text = text.replace(old, new).replace(old_upper, new_upper)

if description and Path(path).name == ".extension":
    import re
    if re.search(r"^description:", text, flags=re.MULTILINE):
        text = re.sub(r"^description:.*$", f"description: {description}", text, flags=re.MULTILINE)
    else:
        text = text.strip() + f"\ndescription: {description}\n"

Path(path).write_text(text)
PY
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            NEW_NAME="$2"; shift 2 ;;
        --description)
            DESCRIPTION="$2"; shift 2 ;;
        --current-name)
            OLD_NAME="$2"; shift 2 ;;
        --workdir)
            WORKDIR="$(cd "$2" && pwd)"; shift 2 ;;
        --dry-run)
            DRY_RUN=true; shift ;;
        --help)
            usage ;;
        *)
            echo "Unknown option: $1" >&2
            usage ;;
    esac
done

if [[ -z "$NEW_NAME" ]]; then
    echo "--name is required." >&2
    usage
fi

if [[ ! "$NEW_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid extension name. Use letters, numbers, hyphens, or underscores." >&2
    exit 1
fi

OLD_DIR="${WORKDIR}/${OLD_NAME}"
NEW_DIR="${WORKDIR}/${NEW_NAME}"

if [[ ! -d "$OLD_DIR" ]]; then
    echo "Extension directory not found: $OLD_DIR" >&2
    exit 1
fi

if [[ "$OLD_DIR" != "$NEW_DIR" && -e "$NEW_DIR" ]]; then
    echo "Target directory already exists: $NEW_DIR" >&2
    exit 1
fi

OLD_UPPER=$(echo "$OLD_NAME" | tr '[:lower:]-' '[:upper:]_')
NEW_UPPER=$(echo "$NEW_NAME" | tr '[:lower:]-' '[:upper:]_')

FILES=(
    "${WORKDIR}/README.md"
    "${OLD_DIR}/README.md"
    "${OLD_DIR}/.extension"
)

CONFIG_FILE="${OLD_DIR}/etc/${OLD_NAME}.conf.example"
if [[ -f "$CONFIG_FILE" ]]; then
    FILES+=("$CONFIG_FILE")
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: would rename ${OLD_NAME} -> ${NEW_NAME} in ${WORKDIR}"
    printf 'Files to update:\n'
    printf ' - %s\n' "${FILES[@]}"
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Config file rename: ${CONFIG_FILE} -> ${OLD_DIR}/etc/${NEW_NAME}.conf.example"
    fi
    if [[ "$OLD_DIR" != "$NEW_DIR" ]]; then
        echo "Directory rename: ${OLD_DIR} -> ${NEW_DIR}"
    fi
    exit 0
fi

for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        replace_tokens "$file" "$OLD_NAME" "$NEW_NAME" "$OLD_UPPER" "$NEW_UPPER" "$DESCRIPTION"
    fi
done

if [[ -f "$CONFIG_FILE" ]]; then
    mv "$CONFIG_FILE" "${OLD_DIR}/etc/${NEW_NAME}.conf.example"
fi

if [[ "$OLD_DIR" != "$NEW_DIR" ]]; then
    mv "$OLD_DIR" "$NEW_DIR"
fi

echo "Renamed extension to: $NEW_NAME"
if [[ -n "$DESCRIPTION" ]]; then
    echo "Updated description to: $DESCRIPTION"
fi
