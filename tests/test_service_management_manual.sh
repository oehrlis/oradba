#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_service_management_manual.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.1.0
# Purpose....: Manual test script for service management functionality
# Notes......: Interactive testing of oradba_dbctl, oradba_lsnrctl, oradba_services
# Usage......: ./test_service_management_manual.sh
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# Find test directory and source common functions
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${TEST_DIR}")"
ORADBA_BASE="${PROJECT_ROOT}/src"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
    ((TESTS_RUN++))
}

print_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

pause_test() {
    echo ""
    read -r -p "Press Enter to continue to next test..."
    echo ""
}

# ------------------------------------------------------------------------------
# Test Functions
# ------------------------------------------------------------------------------

test_scripts_exist() {
    print_header "Testing Script Existence"
    
    local scripts=(
        "src/bin/oradba_dbctl.sh"
        "src/bin/oradba_lsnrctl.sh"
        "src/bin/oradba_services.sh"
        "src/bin/oradba_services_root.sh"
    )
    
    for script in "${scripts[@]}"; do
        print_test "Check if ${script} exists"
        if [[ -f "${PROJECT_ROOT}/${script}" ]]; then
            print_pass "${script} exists"
        else
            print_fail "${script} not found"
        fi
    done
}

test_scripts_executable() {
    print_header "Testing Script Permissions"
    
    local scripts=(
        "src/bin/oradba_dbctl.sh"
        "src/bin/oradba_lsnrctl.sh"
        "src/bin/oradba_services.sh"
        "src/bin/oradba_services_root.sh"
    )
    
    for script in "${scripts[@]}"; do
        print_test "Check if ${script} is executable"
        if [[ -x "${PROJECT_ROOT}/${script}" ]]; then
            print_pass "${script} is executable"
        else
            print_fail "${script} is not executable"
        fi
    done
}

test_help_output() {
    print_header "Testing Help Output"
    
    local scripts=(
        "src/bin/oradba_dbctl.sh"
        "src/bin/oradba_lsnrctl.sh"
        "src/bin/oradba_services.sh"
    )
    
    for script in "${scripts[@]}"; do
        print_test "${script} --help displays usage"
        if "${PROJECT_ROOT}/${script}" --help 2>&1 | grep -q "Usage:"; then
            print_pass "Help output contains usage information"
        else
            print_fail "Help output missing or incomplete"
        fi
    done
}

test_config_file() {
    print_header "Testing Configuration File"
    
    print_test "Check if oradba_services.conf exists"
    if [[ -f "${PROJECT_ROOT}/src/etc/oradba_services.conf" ]]; then
        print_pass "Configuration file exists"
    else
        print_fail "Configuration file not found"
    fi
    
    print_test "Check configuration file syntax"
    if bash -n "${PROJECT_ROOT}/src/etc/oradba_services.conf" 2>/dev/null; then
        print_pass "Configuration file has valid syntax"
    else
        print_fail "Configuration file has syntax errors"
    fi
}

test_templates() {
    print_header "Testing Service Templates"
    
    print_test "Check if systemd template exists"
    if [[ -f "${PROJECT_ROOT}/src/templates/systemd/oradba.service" ]]; then
        print_pass "systemd template exists"
    else
        print_fail "systemd template not found"
    fi
    
    print_test "Check if init.d template exists"
    if [[ -f "${PROJECT_ROOT}/src/templates/init.d/oradba" ]]; then
        print_pass "init.d template exists"
        
        if [[ -x "${PROJECT_ROOT}/src/templates/init.d/oradba" ]]; then
            print_pass "init.d template is executable"
        else
            print_fail "init.d template is not executable"
        fi
    else
        print_fail "init.d template not found"
    fi
}

test_aliases() {
    print_header "Testing Aliases in oradba_aliases.sh"
    
    print_test "Check if service management aliases are defined"
    if grep -q "alias dbctl=" "${ORADBA_BASE}/lib/oradba_aliases.sh"; then
        print_pass "Database control aliases found"
    else
        print_fail "Database control aliases missing"
    fi
    
    if grep -q "alias listener=" "${ORADBA_BASE}/lib/oradba_aliases.sh"; then
        print_pass "Listener control aliases found"
    else
        print_fail "Listener control aliases missing"
    fi
    
    if grep -q "alias orastart=" "${ORADBA_BASE}/lib/oradba_aliases.sh"; then
        print_pass "Combined service aliases found"
    else
        print_fail "Combined service aliases missing"
    fi
}

test_documentation() {
    print_header "Testing Documentation"
    
    print_test "Check if service management documentation exists"
    if [[ -f "${PROJECT_ROOT}/src/doc/17-service-management.md" ]]; then
        print_pass "Documentation file exists"
        
        # Check for key sections
        if grep -q "## Overview" "${PROJECT_ROOT}/src/doc/17-service-management.md"; then
            print_pass "Documentation contains Overview section"
        else
            print_fail "Documentation missing Overview section"
        fi
        
        if grep -q "## Database Control" "${PROJECT_ROOT}/src/doc/17-service-management.md"; then
            print_pass "Documentation contains Database Control section"
        else
            print_fail "Documentation missing Database Control section"
        fi
        
        if grep -q "## System Integration" "${PROJECT_ROOT}/src/doc/17-service-management.md"; then
            print_pass "Documentation contains System Integration section"
        else
            print_fail "Documentation missing System Integration section"
        fi
    else
        print_fail "Documentation file not found"
    fi
}

interactive_dbctl_test() {
    print_header "Interactive Database Control Test"
    
    print_info "This test requires a running Oracle environment"
    print_info "Skip if no Oracle database is available"
    echo ""
    read -r -p "Do you have Oracle databases available for testing? (y/n): " response
    
    if [[ "${response}" != "y" ]]; then
        print_info "Skipping interactive database tests"
        return
    fi
    
    print_test "Test dbctl status command"
    "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" status || true
    pause_test
    
    print_info "Review the output above"
    read -r -p "Did the status command work correctly? (y/n): " response
    if [[ "${response}" == "y" ]]; then
        print_pass "Database status command works"
    else
        print_fail "Database status command failed"
    fi
}

interactive_lsnrctl_test() {
    print_header "Interactive Listener Control Test"
    
    print_info "This test requires Oracle listener to be available"
    echo ""
    read -r -p "Do you have Oracle listener available for testing? (y/n): " response
    
    if [[ "${response}" != "y" ]]; then
        print_info "Skipping interactive listener tests"
        return
    fi
    
    print_test "Test lsnrctl status command"
    "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" status || true
    pause_test
    
    print_info "Review the output above"
    read -r -p "Did the listener status command work correctly? (y/n): " response
    if [[ "${response}" == "y" ]]; then
        print_pass "Listener status command works"
    else
        print_fail "Listener status command failed"
    fi
}

interactive_services_test() {
    print_header "Interactive Combined Services Test"
    
    print_test "Test oradba_services status command"
    "${PROJECT_ROOT}/src/bin/oradba_services.sh" status || true
    pause_test
    
    print_info "Review the output above"
    read -r -p "Did the combined services status work correctly? (y/n): " response
    if [[ "${response}" == "y" ]]; then
        print_pass "Combined services status works"
    else
        print_fail "Combined services status failed"
    fi
}

# ------------------------------------------------------------------------------
# Main Test Execution
# ------------------------------------------------------------------------------

print_header "OraDBA Service Management - Manual Tests"
print_info "Project Root: ${PROJECT_ROOT}"
print_info "Test Directory: ${TEST_DIR}"

# Run automated tests
test_scripts_exist
test_scripts_executable
test_help_output
test_config_file
test_templates
test_aliases
test_documentation

# Run interactive tests if user wants
echo ""
read -r -p "Run interactive tests with Oracle environment? (y/n): " response
if [[ "${response}" == "y" ]]; then
    interactive_dbctl_test
    interactive_lsnrctl_test
    interactive_services_test
else
    print_info "Skipping interactive tests"
fi

# Print summary
print_header "Test Summary"
echo "Tests Run:    ${TESTS_RUN}"
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

# EOF -------------------------------------------------------------------------
