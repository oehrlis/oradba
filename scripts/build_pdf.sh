#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build_pdf.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
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
readonly DIST_DIR="${PROJECT_ROOT}/dist"
readonly OUTPUT_PDF="${DIST_DIR}/oradba-user-guide.pdf"
readonly DOC_METADATA="${PROJECT_ROOT}/doc/metadata.yml"
readonly PANDOC_IMAGE="${PANDOC_IMAGE:-oehrlis/pandoc:latest}"
readonly TMP_DOCS_DIR="${DIST_DIR}/.tmp_docs"
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
    if ! command -v docker > /dev/null 2>&1; then
        log_error "Docker not found"
        log_info "Install Docker to generate documentation: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if [[ ! -f "${DOC_METADATA}" ]]; then
        log_error "Metadata file not found: ${DOC_METADATA}"
        exit 1
    fi

    if [[ ! -f "${MKDOCS_CONFIG}" ]]; then
        log_error "mkdocs.yml not found: ${MKDOCS_CONFIG}"
        exit 1
    fi
}

# Prepare documentation sources (mirror Makefile docs-pdf target)
prepare_docs() {
    log_info "Preparing documentation sources..."

    rm -rf "${TMP_DOCS_DIR}"
    mkdir -p "${TMP_DOCS_DIR}"

    local -a ordered_files=()
    while IFS= read -r file; do
        if [[ -f "${DOCS_DIR}/${file}" ]]; then
            if [[ "${file}" == api/* ]]; then
                continue
            fi
            ordered_files+=("${file}")
            cp "${DOCS_DIR}/${file}" "${TMP_DOCS_DIR}/"
        else
            log_warn "File not found: ${file}"
        fi
    done < <(extract_nav_files)

    if [[ ${#ordered_files[@]} -eq 0 ]]; then
        log_error "No markdown files found from mkdocs.yml navigation"
        exit 1
    fi

    for file in "${TMP_DOCS_DIR}"/*.md; do
        sed -i.bak -E 's|\]\(01-introduction\.md\)|](#introduction)|g' "${file}"
        sed -i.bak -E 's|\]\(02-installation\.md\)|](#installation)|g' "${file}"
        sed -i.bak -E 's|\]\(03-quickstart\.md\)|](#quick-start-guide)|g' "${file}"
        sed -i.bak -E 's|\]\(04-environment\.md\)|](#environment-management)|g' "${file}"
        sed -i.bak -E 's|\]\(05-configuration\.md\)|](#configuration-system)|g' "${file}"
        sed -i.bak -E 's|\]\(06-aliases\.md\)|](#alias-reference)|g' "${file}"
        sed -i.bak -E 's|\]\(07-pdb-aliases\.md\)|](#pdb-alias-reference)|g' "${file}"
        sed -i.bak -E 's|\]\(08-sql-scripts\.md\)|](#sql-scripts-reference)|g' "${file}"
        sed -i.bak -E 's|\]\(09-rman-scripts\.md\)|](#rman-script-templates)|g' "${file}"
        sed -i.bak -E 's|\]\(10-functions\.md\)|](#database-functions-library-oradba_db_functions.sh)|g' "${file}"
        sed -i.bak -E 's|\]\(11-rlwrap\.md\)|](#rlwrap-filter-configuration)|g' "${file}"
        sed -i.bak -E 's|\]\(12-troubleshooting\.md\)|](#troubleshooting-guide)|g' "${file}"
        sed -i.bak -E 's|\]\(13-reference\.md\)|](#quick-reference)|g' "${file}"
        sed -i.bak -E 's|\.\./\.\./doc/images/|images/|g' "${file}"
        rm -f "${file}.bak"
    done

    if [[ -d "${DOCS_DIR}/images" ]]; then
        cp -r "${DOCS_DIR}/images" "${TMP_DOCS_DIR}/" 2>/dev/null || true
    fi
}

# Extract file list from mkdocs.yml nav structure
extract_nav_files() {
    log_info "Extracting file list from mkdocs.yml navigation..." >&2

    if command -v python3 > /dev/null 2>&1; then
        python3 << 'EOF' 2> /dev/null && return 0
import sys

try:
    import yaml
except Exception:
    sys.exit(1)

def extract_files(nav, files=None):
    if files is None:
        files = []
    if isinstance(nav, dict):
        for _, value in nav.items():
            if isinstance(value, str):
                files.append(value)
            elif isinstance(value, (list, dict)):
                extract_files(value, files)
    elif isinstance(nav, list):
        for item in nav:
            extract_files(item, files)
    return files

with open('mkdocs.yml', 'r', encoding='utf-8') as f:
    config = yaml.safe_load(f)

files = extract_files(config.get('nav', []))
for f in files:
    print(f)
EOF
    fi

    if command -v yq > /dev/null 2>&1; then
        yq -r '.nav[] | .. | select(tag == "!!str")' "${MKDOCS_CONFIG}" 2>/dev/null | grep '\.md$' || true
        return 0
    fi

    log_warn "PyYAML/yq not available, using grep-based extraction" >&2
    grep -A 100 "^nav:" "${MKDOCS_CONFIG}" \
        | grep "\.md$" \
        | sed -E 's/.*: //' \
        | tr -d ' "'
}

# Build PDF
build_pdf() {
    log_info "Building PDF documentation..."

    mkdir -p "${DIST_DIR}"
    prepare_docs

    local -a ordered_files=()
    while IFS= read -r file; do
        if [[ -f "${TMP_DOCS_DIR}/${file}" ]]; then
            ordered_files+=("${file}")
        fi
    done < <(extract_nav_files)

    if [[ ${#ordered_files[@]} -gt 0 ]]; then
        log_info "Running pandoc in Docker (${PANDOC_IMAGE})..."
        (
            cd "${TMP_DOCS_DIR}" && \
            docker run --rm \
                -v "${PWD}:/workdir" \
                -v "${PROJECT_ROOT}/doc:/doc" \
                -w /workdir \
                "${PANDOC_IMAGE}" \
                "${ordered_files[@]}" -o oradba-user-guide.pdf \
                --metadata-file=/doc/metadata.yml \
                --toc --toc-depth=2 \
                --pdf-engine=xelatex \
                -N --listings 2>&1 | grep -v "Missing character" || true
        )
    else
        log_error "No markdown files found in ${TMP_DOCS_DIR}"
        exit 1
    fi

    if [[ -f "${TMP_DOCS_DIR}/oradba-user-guide.pdf" ]]; then
        mv "${TMP_DOCS_DIR}/oradba-user-guide.pdf" "${OUTPUT_PDF}" 2>/dev/null || true
    fi

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

    rm -rf "${TMP_DOCS_DIR}"

    log_info "Done!"
}

main "$@"
