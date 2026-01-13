#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_pdf.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.13
# Revision...: 
# Purpose....: Build PDF documentation from markdown files using pandoc
# Notes......: Reads order from mkdocs.yml navigation structure
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -euo pipefail

# Configuration
declare SCRIPT_DIR
declare PROJECT_ROOT
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR PROJECT_ROOT
readonly DOCS_DIR="${PROJECT_ROOT}/src/doc"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly OUTPUT_PDF="${BUILD_DIR}/oradba-documentation.pdf"
readonly MKDOCS_CONFIG="${PROJECT_ROOT}/mkdocs.yml"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v pandoc > /dev/null 2>&1; then
        missing+=("pandoc")
    fi

    if ! command -v yq > /dev/null 2>&1; then
        log_warn "yq not found, using python yaml parser instead"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Install with: brew install pandoc yq"
        exit 1
    fi
}

# Extract file list from mkdocs.yml nav structure
extract_nav_files() {
    log_info "Extracting file list from mkdocs.yml navigation..."

    # Try Python with PyYAML first
    if command -v python3 > /dev/null 2>&1; then
        python3 << 'EOF' 2> /dev/null && return 0
import yaml
import sys

def extract_files(nav, files=[]):
    if isinstance(nav, dict):
        for key, value in nav.items():
            if isinstance(value, str):
                files.append(value)
            elif isinstance(value, (list, dict)):
                extract_files(value, files)
    elif isinstance(nav, list):
        for item in nav:
            extract_files(item, files)
    return files

try:
    with open('mkdocs.yml', 'r') as f:
        config = yaml.safe_load(f)
    
    files = extract_files(config.get('nav', []))
    for f in files:
        print(f)
except Exception as e:
    sys.exit(1)
EOF
    fi

    # Fallback: simple grep-based extraction
    log_warn "PyYAML not available, using grep-based extraction"
    grep -A 100 "^nav:" "${MKDOCS_CONFIG}" \
        | grep "\.md$" \
        | sed -E 's/.*: //' \
        | tr -d ' "'
}

# Build PDF
build_pdf() {
    log_info "Building PDF documentation..."

    # Create build directory
    mkdir -p "${BUILD_DIR}"

    # Get ordered file list
    local files=()
    while IFS= read -r file; do
        if [[ -f "${DOCS_DIR}/${file}" ]]; then
            files+=("${DOCS_DIR}/${file}")
        else
            log_warn "File not found: ${file}"
        fi
    done < <(extract_nav_files)

    if [[ ${#files[@]} -eq 0 ]]; then
        log_error "No markdown files found"
        exit 1
    fi

    log_info "Found ${#files[@]} files to process"

    # Build pandoc command
    local pandoc_opts=(
        --from=markdown
        --to=pdf
        --output="${OUTPUT_PDF}"
        --toc
        --toc-depth=3
        --number-sections
        --highlight-style=tango
        --pdf-engine=xelatex
        -V geometry:margin=1in
        -V documentclass=report
        -V fontsize=11pt
        -V colorlinks=true
        -V linkcolor=blue
        -V urlcolor=blue
        -V toccolor=black
    )

    # Add metadata if VERSION file exists
    if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
        local version
        version=$(cat "${PROJECT_ROOT}/VERSION")
        pandoc_opts+=(-V "version=${version}")
    fi

    # Execute pandoc
    log_info "Running pandoc..."
    pandoc "${pandoc_opts[@]}" "${files[@]}"

    if [[ -f "${OUTPUT_PDF}" ]]; then
        local size
        size=$(du -h "${OUTPUT_PDF}" | cut -f1)
        log_info "PDF created successfully: ${OUTPUT_PDF} (${size})"
    else
        log_error "PDF creation failed"
        exit 1
    fi
}

# Main
main() {
    log_info "OraDBA Documentation PDF Builder"
    log_info "================================"

    cd "${PROJECT_ROOT}"

    check_dependencies
    build_pdf

    log_info "Done!"
}

main "$@"
