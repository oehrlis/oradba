#!/usr/bin/env bash
# ============================================================================
# Script:       validate_test_environment.sh
# Author:       Stefan Oehrli (oes) stefan.oehrli@oradba.com
# Date:         2026.02.11
# Revision:     v0.21.1
# Purpose:      Validate testing environment for OraDBA v0.21.1
# Notes:        Run this script before executing the test suite
#               Works in both development (src/) and installed (no src/) modes
# Reference:    doc/automated_testing.md, doc/manual_testing.md
# License:      Apache-2.0 (see LICENSE file)
# ============================================================================

# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1

# Detect if we're in dev mode (src/) or installed mode (no src/)
if [[ -d "$PROJECT_ROOT/src" ]]; then
    # Development mode
    LIB_DIR="src/lib"
    BIN_DIR="src/bin"
    MODE="development"
else
    # Installed mode
    LIB_DIR="lib"
    BIN_DIR="bin"
    MODE="installed"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version
VERSION_VALUE=""
if [ -f "VERSION" ]; then
    VERSION_VALUE=$(cat VERSION 2>/dev/null || true)
fi

# Counters
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ -n "${VERSION_VALUE}" ]]; then
        echo -e "${BLUE}  OraDBA v${VERSION_VALUE} - Test Environment Validator${NC}"
    else
        echo -e "${BLUE}  OraDBA - Test Environment Validator${NC}"
    fi
    echo -e "${BLUE}  Mode: $MODE${NC}"
    echo -e "${BLUE}  Architecture: Registry API, Plugin System, Environment Libraries${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_section() {
    echo
    echo -e "${BLUE}▸ $1${NC}"
    echo
}

check_pass() {
    ((CHECKS_TOTAL++))
    ((CHECKS_PASSED++))
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    ((CHECKS_TOTAL++))
    ((CHECKS_FAILED++))
    echo -e "  ${RED}✗${NC} $1"
}

check_warn() {
    ((CHECKS_TOTAL++))
    ((CHECKS_WARNED++))
    echo -e "  ${YELLOW}⚠${NC} $1"
}

# ============================================================================
# Validation Checks
# ============================================================================

validate_version_file() {
    print_section "Version File"
    
    if [ -f "VERSION" ]; then
        local version
        version=$(cat VERSION 2>/dev/null || true)
        if [[ -n "${version}" ]] && [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([._-][A-Za-z0-9.-]+)?$ ]]; then
            check_pass "VERSION file exists and contains '${version}'"
        else
            check_warn "VERSION file contains '${version}' (expected semantic version)"
        fi
    else
        check_fail "VERSION file not found"
    fi
}

validate_test_infrastructure() {
    print_section "Test Infrastructure"
    
    # Check BATS files
    BATS_COUNT=$(find tests -name "*.bats" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BATS_COUNT" -eq 37 ]; then
        check_pass "Found 37 BATS test files"
    elif [ "$BATS_COUNT" -ge 37 ]; then
        check_pass "Found $BATS_COUNT BATS test files (37+ expected)"
    else
        check_warn "Found $BATS_COUNT BATS test files (expected 37)"
    fi
    
    # Check .testmap.yml
    if [ -f ".testmap.yml" ]; then
        check_pass ".testmap.yml exists (smart test selection enabled)"
    else
        check_warn ".testmap.yml not found (smart test selection disabled)"
    fi
    
    # Check for BATS executable
    if command -v bats &> /dev/null; then
        BATS_VERSION=$(bats --version 2>/dev/null | head -1)
        check_pass "BATS installed: $BATS_VERSION"
    else
        check_fail "BATS not installed (required for test execution)"
    fi
}

validate_build_system() {
    print_section "Build System"
    
    # Check Makefile
    if [ -f "Makefile" ]; then
        check_pass "Makefile exists"
        
        # Check for key targets
        if grep -q "^test-full:" Makefile; then
            check_pass "Makefile has 'test-full' target"
        else
            check_fail "Makefile missing 'test-full' target"
        fi
        
        if grep -q "^build:" Makefile; then
            check_pass "Makefile has 'build' target"
        else
            check_fail "Makefile missing 'build' target"
        fi
    else
        check_fail "Makefile not found"
    fi
    
    # Check build scripts
    if [ -x "scripts/build_installer.sh" ]; then
        check_pass "build_installer.sh exists and is executable"
    else
        check_fail "build_installer.sh missing or not executable"
    fi
    
    if [ -x "scripts/build_pdf.sh" ]; then
        check_pass "build_pdf.sh exists and is executable"
    else
        check_warn "build_pdf.sh missing or not executable (non-critical)"
    fi
    
    # Check dist directory
    if [ -d "dist" ]; then
        check_pass "dist/ directory exists"
        
        # Check for current build artifacts
        local tarball_name
        if [[ -n "${VERSION_VALUE}" ]]; then
            tarball_name="dist/oradba-${VERSION_VALUE}.tar.gz"
        else
            tarball_name="dist/oradba-<version>.tar.gz"
        fi

        if [ -f "${tarball_name}" ]; then
            SIZE=$(ls -lh "${tarball_name}" | awk '{print $5}')
            check_pass "${tarball_name} exists (${SIZE})"
        else
            check_warn "${tarball_name} not found (run 'make build')"
        fi
        
        if [ -f "dist/oradba_install.sh" ]; then
            SIZE=$(ls -lh "dist/oradba_install.sh" | awk '{print $5}')
            check_pass "dist/oradba_install.sh exists ($SIZE)"
        else
            check_warn "dist/oradba_install.sh not found (run 'make build')"
        fi
        
        if [ -f "dist/oradba_check.sh" ]; then
            SIZE=$(ls -lh "dist/oradba_check.sh" | awk '{print $5}')
            check_pass "dist/oradba_check.sh exists ($SIZE)"
        else
            check_warn "dist/oradba_check.sh not found (run 'make build')"
        fi
    else
        check_warn "dist/ directory not found (run 'make build' to create)"
    fi
}

validate_source_structure() {
    print_section "Source Structure"
    
    # Check core directories
    for dir in ${BIN_DIR} ${LIB_DIR} ${ETC_DIR} src/sql src/rcv src/templates; do
        if [ -d "$dir" ]; then
            check_pass "$dir/ exists"
        else
            check_fail "$dir/ directory missing"
        fi
    done
    
    # Check plugin directory (v0.19.0+)
    if [ -d "${LIB_DIR}/plugins" ]; then
        check_pass "${LIB_DIR}/plugins/ exists (Plugin System v0.19.0+)"
    else
        check_fail "${LIB_DIR}/plugins/ directory missing"
    fi
    
    # Check Registry API (v0.19.0+)
    if [ -f "${LIB_DIR}/oradba_registry.sh" ]; then
        check_pass "Registry API exists (oradba_registry.sh)"
    else
        check_fail "Registry API missing (oradba_registry.sh)"
    fi
    
    # Check environment libraries
    ENV_LIBS=(
        "${LIB_DIR}/oradba_env_parser.sh"
        "${LIB_DIR}/oradba_env_builder.sh"
        "${LIB_DIR}/oradba_env_validator.sh"
        "${LIB_DIR}/oradba_env_config.sh"
        "${LIB_DIR}/oradba_env_status.sh"
        "${LIB_DIR}/oradba_env_changes.sh"
    )
    
    ENV_COUNT=0
    for lib in "${ENV_LIBS[@]}"; do
        if [ -f "$lib" ]; then
            ((ENV_COUNT++))
        fi
    done
    
    if [ $ENV_COUNT -eq 6 ]; then
        check_pass "All 6 environment libraries present"
    else
        check_fail "Only $ENV_COUNT/6 environment libraries found"
    fi
    
    # Check core libraries
    CORE_LIBS=(
        "${LIB_DIR}/oradba_common.sh"
        "${LIB_DIR}/oradba_db_functions.sh"
        "${LIB_DIR}/oradba_aliases.sh"
    )
    
    CORE_COUNT=0
    for lib in "${CORE_LIBS[@]}"; do
        if [ -f "$lib" ]; then
            ((CORE_COUNT++))
        fi
    done
    
    if [ $CORE_COUNT -eq 3 ]; then
        check_pass "All 3 core libraries present"
    else
        check_fail "Only $CORE_COUNT/3 core libraries found"
    fi
    
    # Check plugin files (v0.19.0+)
    PLUGIN_COUNT=$(find ${LIB_DIR}/plugins -name "*_plugin.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PLUGIN_COUNT" -ge 6 ]; then
        check_pass "$PLUGIN_COUNT product plugins found (6+ expected)"
    else
        check_fail "Only $PLUGIN_COUNT product plugins found (expected 6+)"
    fi
    
    # Check plugin interface (v0.19.0+)
    if [ -f "${LIB_DIR}/plugins/plugin_interface.sh" ]; then
        check_pass "Plugin interface exists (plugin_interface.sh)"
    else
        check_fail "Plugin interface missing (plugin_interface.sh)"
    fi
}

validate_documentation() {
    print_section "Documentation"
    
    # Check main documentation files
    if [ -f "README.md" ]; then
        if [[ -n "${VERSION_VALUE}" ]] && grep -q "v${VERSION_VALUE}" README.md; then
            check_pass "README.md contains v${VERSION_VALUE} references"
        else
            check_warn "README.md missing v${VERSION_VALUE:-current} references"
        fi
    else
        check_fail "README.md not found"
    fi
    
    if [ -f "CHANGELOG.md" ]; then
        if [[ -n "${VERSION_VALUE}" ]] && grep -q "\[${VERSION_VALUE}\]" CHANGELOG.md; then
            check_pass "CHANGELOG.md has v${VERSION_VALUE} entries"
        else
            check_warn "CHANGELOG.md missing v${VERSION_VALUE:-current} entries"
        fi
    else
        check_fail "CHANGELOG.md not found"
    fi
    
    # Phase reports and legacy manual testing guide checks removed
}

validate_shell_prerequisites() {
    print_section "Shell & Tools"
    
    # Check bash version
    if [ -n "$BASH_VERSION" ]; then
        BASH_MAJOR=$(echo "$BASH_VERSION" | cut -d. -f1)
        if [ "$BASH_MAJOR" -ge 4 ]; then
            check_pass "Bash version $BASH_VERSION (>= 4.0 required)"
        else
            check_warn "Bash version $BASH_VERSION (4.0+ recommended)"
        fi
    else
        check_fail "Not running in Bash shell"
    fi
    
    # Check shellcheck (for linting)
    if command -v shellcheck &> /dev/null; then
        SHELLCHECK_VERSION=$(shellcheck --version | grep "^version:" | awk '{print $2}')
        check_pass "shellcheck installed: $SHELLCHECK_VERSION"
    else
        check_warn "shellcheck not installed (needed for 'make lint-shell')"
    fi
    
    # Check make
    if command -v make &> /dev/null; then
        MAKE_VERSION=$(make --version 2>/dev/null | head -1)
        check_pass "make installed: $MAKE_VERSION"
    else
        check_fail "make not installed (required for running tests)"
    fi
    
    # Check tar
    if command -v tar &> /dev/null; then
        check_pass "tar installed (needed for distribution builds)"
    else
        check_fail "tar not installed (required for builds)"
    fi
    
    # Check git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version 2>/dev/null)
        check_pass "git installed: $GIT_VERSION"
    else
        check_warn "git not installed (needed for version control)"
    fi
}

validate_git_status() {
    print_section "Git Repository"
    
    if [ -d ".git" ]; then
        check_pass "Git repository initialized"
        
        # Check current branch
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "$BRANCH" ]; then
            check_pass "Current branch: $BRANCH"
        fi
        
        # Check for uncommitted changes
        if [ -z "$(git status --porcelain)" ]; then
            check_pass "No uncommitted changes (clean working tree)"
        else
            UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
            check_warn "$UNCOMMITTED uncommitted change(s) detected"
        fi
        
        # Check recent commits
        RECENT_COMMITS=$(git log --oneline -3 2>/dev/null | head -3)
        if [ -n "$RECENT_COMMITS" ]; then
            echo "  Recent commits:"
            git log --oneline -3 | sed 's/^/    /'
        fi
    else
        check_warn "Not a git repository"
    fi
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Validation Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "  Total Checks:   $CHECKS_TOTAL"
    echo -e "  ${GREEN}Passed:         $CHECKS_PASSED${NC}"
    if [ $CHECKS_WARNED -gt 0 ]; then
        echo -e "  ${YELLOW}Warnings:       $CHECKS_WARNED${NC}"
    fi
    if [ $CHECKS_FAILED -gt 0 ]; then
        echo -e "  ${RED}Failed:         $CHECKS_FAILED${NC}"
    fi
    echo
    
    # Overall status
    if [ $CHECKS_FAILED -eq 0 ]; then
        if [ $CHECKS_WARNED -eq 0 ]; then
            echo -e "${GREEN}✓ Environment is ready for testing!${NC}"
            echo
            echo "Next steps:"
            echo "  1. Run automated tests: make test-full"
            echo "  2. Follow manual testing guide: doc/phase7_manual_testing_guide.md"
            echo
            return 0
        else
            echo -e "${YELLOW}⚠ Environment is mostly ready, but has warnings${NC}"
            echo
            echo "Consider addressing warnings before proceeding with tests."
            echo "Some features may not work correctly."
            echo
            return 1
        fi
    else
        echo -e "${RED}✗ Environment has critical issues${NC}"
        echo
        echo "Fix the failed checks before proceeding with tests."
        echo "Run this script again after making corrections."
        echo
        return 2
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Change to script directory if not already there
    cd "$(dirname "$0")/.." || exit 1
    
    print_header
    
    validate_version_file
    validate_test_infrastructure
    validate_build_system
    validate_source_structure
    validate_documentation
    validate_shell_prerequisites
    validate_git_status
    
    print_summary
    return $?
}

# Run main function
main
exit $?
