#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: select_tests.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.10.0
# Purpose....: Smart test selection based on changed files
# Notes......: Reads .testmap.yml to determine which tests to run
#              Uses git diff for local changes, supports CI integration
# Usage......: select_tests.sh [--base BRANCH] [--dry-run] [--full]
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -o errexit
set -o pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
TESTMAP_FILE="${PROJECT_ROOT}/.testmap.yml"
TEST_DIR="${PROJECT_ROOT}/tests"

BASE_BRANCH="${BASE_BRANCH:-origin/main}"
DRY_RUN=false
FULL_MODE=false
VERBOSE=false

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Smart test selection based on changed files.

Options:
    --base BRANCH       Base branch for comparison (default: origin/main)
    --dry-run          Show which tests would run without executing
    --full             Run all tests (ignore changes)
    --verbose          Show detailed output
    -h, --help         Show this help message

Examples:
    $(basename "$0")                    # Smart selection against origin/main
    $(basename "$0") --base HEAD~1      # Compare against last commit
    $(basename "$0") --dry-run          # Show what would run
    $(basename "$0") --full             # Run all tests

EOF
    exit 0
}

oradba_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[select_tests] $*" >&2
    fi
}

log_info() {
    echo "[INFO] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Parse YAML file for test mappings
parse_testmap() {
    if [[ ! -f "$TESTMAP_FILE" ]]; then
        log_error "Test map file not found: $TESTMAP_FILE"
        return 1
    fi

    oradba_log "Parsing test map from $TESTMAP_FILE"
    return 0
}

# Get always-run tests from config
get_always_run_tests() {
    if [[ ! -f "$TESTMAP_FILE" ]]; then
        return 0
    fi

    # Parse always_run section from YAML
    awk '
        /^always_run:/ { in_section=1; next }
        in_section && /^  - / { 
            gsub(/^  - /, ""); 
            print 
        }
        in_section && /^[^ ]/ { exit }
    ' "$TESTMAP_FILE"
}

# Get tests for a specific source file
get_tests_for_file() {
    local source_file="$1"

    if [[ ! -f "$TESTMAP_FILE" ]]; then
        return 0
    fi

    # Simple YAML parsing - look for file in mappings section
    awk -v file="$source_file" '
        /^mappings:/ { in_mappings=1; next }
        in_mappings && $0 ~ "^  " file ":" { 
            in_file=1
            next 
        }
        in_file && /^    - / { 
            gsub(/^    - /, "")
            print
        }
        in_file && /^  [^ ]/ { in_file=0 }
        /^[^ ]/ && !/^mappings:/ { in_mappings=0 }
    ' "$TESTMAP_FILE"
}

# Get tests matching pattern
get_tests_for_pattern() {
    local changed_file="$1"

    if [[ ! -f "$TESTMAP_FILE" ]]; then
        return 0
    fi

    # Check patterns section
    # This is simplified - for complex patterns, consider using yq or python
    oradba_log "Checking patterns for: $changed_file"

    # Pattern matching logic would go here
    # For now, handle some common patterns directly

    # Test files run themselves
    if [[ "$changed_file" =~ ^tests/test_(.+)\.bats$ ]]; then
        echo "test_${BASH_REMATCH[1]}.bats"
        return 0
    fi

    # Documentation doesn't need tests
    if [[ "$changed_file" =~ ^(doc|src/doc)/.*\.md$ ]]; then
        return 0
    fi

    # SQL/RMAN scripts don't have tests
    if [[ "$changed_file" =~ ^src/(sql|rcv)/ ]]; then
        return 0
    fi

    # Templates affect service management
    if [[ "$changed_file" =~ ^src/templates/ ]]; then
        echo "test_service_management.bats"
        return 0
    fi

    # Makefile affects installer
    if [[ "$changed_file" == "Makefile" ]]; then
        echo "test_installer.bats"
        return 0
    fi

    # VERSION file
    if [[ "$changed_file" == "VERSION" ]]; then
        echo "test_installer.bats"
        echo "test_oradba_version.bats"
        return 0
    fi
}

# Get changed files using git
get_changed_files() {
    local base="$1"

    if ! command -v git > /dev/null 2>&1; then
        log_warn "git not found, cannot detect changes"
        return 1
    fi

    if [[ ! -d "${PROJECT_ROOT}/.git" ]]; then
        log_warn "Not a git repository, cannot detect changes"
        return 1
    fi

    # Check if base branch exists
    if ! git rev-parse --verify "$base" > /dev/null 2>&1; then
        log_warn "Base branch '$base' not found, trying 'main'"
        base="main"
        if ! git rev-parse --verify "$base" > /dev/null 2>&1; then
            log_warn "Branch 'main' not found either, using HEAD"
            base="HEAD"
        fi
    fi

    oradba_log "Comparing against: $base"

    # Get changed files (both staged and unstaged)
    {
        # Uncommitted changes
        git diff --name-only "$base" 2> /dev/null
        # Staged changes
        git diff --name-only --cached 2> /dev/null
    } | sort -u
}

# Select tests based on changed files
select_tests() {
    local changed_files=()

    # Get changed files
    log_info "Detecting changed files..."
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            changed_files+=("$file")
            oradba_log "Changed: $file"
        fi
    done < <(get_changed_files "$BASE_BRANCH")

    if [[ ${#changed_files[@]} -eq 0 ]]; then
        log_warn "No changed files detected"
        log_info "Running only always-run tests (no code changes)"
        # Only run always-run tests, not full suite
        while IFS= read -r test; do
            if [[ -n "$test" ]]; then
                echo "$test"
            fi
        done < <(get_always_run_tests)
        return 0
    fi

    log_info "Found ${#changed_files[@]} changed file(s)"

    # Collect unique test files
    declare -A test_set

    # Always include core tests
    while IFS= read -r test; do
        if [[ -n "$test" ]]; then
            test_set["$test"]=1
            oradba_log "Always run: $test"
        fi
    done < <(get_always_run_tests)

    # Get tests for each changed file
    for file in "${changed_files[@]}"; do
        # Try direct mapping first
        while IFS= read -r test; do
            if [[ -n "$test" ]]; then
                test_set["$test"]=1
                oradba_log "Mapped $file -> $test"
            fi
        done < <(get_tests_for_file "$file")

        # Try pattern matching
        while IFS= read -r test; do
            if [[ -n "$test" ]]; then
                test_set["$test"]=1
                oradba_log "Pattern matched $file -> $test"
            fi
        done < <(get_tests_for_pattern "$file")
    done

    # Output unique test files
    for test in "${!test_set[@]}"; do
        if [[ -f "${TEST_DIR}/${test}" ]]; then
            echo "$test"
        else
            log_warn "Test file not found: ${TEST_DIR}/${test}"
        fi
    done | sort
}

# Get all test files
get_all_tests() {
    find "$TEST_DIR" -name "test_*.bats" -type f -exec basename {} \; | sort
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --full)
            FULL_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h | --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Full mode - return all tests
if [[ "$FULL_MODE" == "true" ]]; then
    log_info "Full mode: selecting all tests"
    get_all_tests
    exit 0
fi

# Parse test map
if ! parse_testmap; then
    log_warn "Could not parse test map, falling back to full test suite"
    get_all_tests
    exit 0
fi

# Select tests based on changes
selected_tests=()
while IFS= read -r test; do
    selected_tests+=("$test")
done < <(select_tests)

# Fallback to always-run tests if no tests selected (e.g., only images/docs changed)
if [[ ${#selected_tests[@]} -eq 0 ]]; then
    log_warn "No tests selected (likely only non-code files changed)"
    log_info "Running only always-run tests as fallback"
    while IFS= read -r test; do
        selected_tests+=("$test")
    done < <(get_always_run_tests)
fi

# Output results
if [[ "$DRY_RUN" == "true" ]]; then
    echo "=========================================="
    echo "DRY RUN: Would execute ${#selected_tests[@]} test file(s):"
    echo "=========================================="
    printf '%s\n' "${selected_tests[@]}"
    echo "=========================================="
    echo "Total: ${#selected_tests[@]} tests"
else
    # Output test files (one per line for make to consume)
    printf '%s\n' "${selected_tests[@]}"
fi

exit 0
