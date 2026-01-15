#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: docker_automated_tests.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.15
# Revision...: 1.0.0
# Purpose....: Automated testing for OraDBA in Oracle 26ai Free Docker container
# Notes......: Partially automates manual tests from doc/manual_testing.md
#              Designed to run inside Oracle 26ai Free Docker container
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e  # Exit on error

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_FILE="${TEST_RESULTS_FILE:-/tmp/oradba_test_results_$(date +%Y%m%d_%H%M%S).log}"
INSTALL_PREFIX="${ORADBA_TEST_PREFIX:-/opt/oradba}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

log_info() {
    local msg="${BLUE}[INFO]${NC} $*"
    echo -e "$msg"
    echo -e "$msg" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
}

log_success() {
    local msg="${GREEN}[PASS]${NC} $*"
    echo -e "$msg"
    echo -e "$msg" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
}

log_error() {
    local msg="${RED}[FAIL]${NC} $*"
    echo -e "$msg"
    echo -e "$msg" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
}

log_skip() {
    local msg="${YELLOW}[SKIP]${NC} $*"
    echo -e "$msg"
    echo -e "$msg" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
}

log_section() {
    echo ""
    echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo "================================================================================"
    echo "================================================================================" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}$*${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo "================================================================================"
    echo "================================================================================" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
}

# Test result tracking
test_start() {
    ((TESTS_TOTAL++))
    log_info "Test $TESTS_TOTAL: $*"
}

test_pass() {
    ((TESTS_PASSED++))
    log_success "$*"
}

test_fail() {
    ((TESTS_FAILED++))
    log_error "$*"
}

test_skip() {
    ((TESTS_SKIPPED++))
    log_skip "$*"
}

# Check if command/file exists
check_exists() {
    local item="$1"
    local type="${2:-file}"  # file or command
    
    if [[ "$type" == "command" ]]; then
        if command -v "$item" &> /dev/null; then
            return 0
        fi
    else
        if [[ -e "$item" ]]; then
            return 0
        fi
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Test: Installation
# ------------------------------------------------------------------------------

test_installation() {
    log_section "INSTALLATION TESTS"
    
    # Test 1: Build artifacts
    test_start "Build artifacts exist"
    if [[ -f "$PROJECT_ROOT/dist/oradba_install.sh" ]]; then
        test_pass "oradba_install.sh found"
    else
        test_fail "oradba_install.sh not found - run 'make build' first"
        # Skip remaining installation tests if installer not found
        log_info "Skipping remaining installation tests"
        return 0
    fi
    
    # Test 2: Installation
    test_start "Fresh installation to $INSTALL_PREFIX"
    if "$PROJECT_ROOT/dist/oradba_install.sh" --prefix "$INSTALL_PREFIX" --silent >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "Installation completed"
    else
        test_fail "Installation failed"
        # Skip remaining tests if installation failed
        log_info "Skipping remaining installation tests"
        return 0
    fi
    
    # Test 3: Directory structure
    test_start "Installation directory structure"
    local required_dirs=("bin" "lib" "etc" "sql" "rcv" "templates")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$INSTALL_PREFIX/$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        test_pass "All required directories present"
    else
        test_fail "Missing directories: ${missing_dirs[*]}"
    fi
    
    # Test 4: VERSION file
    test_start "VERSION file exists and readable"
    if [[ -f "$INSTALL_PREFIX/VERSION" ]]; then
        local version
        version=$(cat "$INSTALL_PREFIX/VERSION")
        test_pass "VERSION: $version"
    else
        test_fail "VERSION file not found"
    fi
    
    # Test 5: Core libraries
    test_start "Core environment libraries"
    local required_libs=(
        "oradba_env_builder.sh"
        "oradba_env_changes.sh"
        "oradba_env_config.sh"
        "oradba_env_parser.sh"
        "oradba_env_status.sh"
        "oradba_env_validator.sh"
    )
    local missing_libs=()
    
    for lib in "${required_libs[@]}"; do
        if [[ ! -f "$INSTALL_PREFIX/lib/$lib" ]]; then
            missing_libs+=("$lib")
        fi
    done
    
    if [[ ${#missing_libs[@]} -eq 0 ]]; then
        test_pass "All 6 environment libraries present"
    else
        test_fail "Missing libraries: ${missing_libs[*]}"
    fi
    
    # Test 6: Configuration files
    test_start "Core configuration files"
    local required_configs=("oradba_core.conf" "oradba_standard.conf")
    local missing_configs=()
    
    for conf in "${required_configs[@]}"; do
        if [[ ! -f "$INSTALL_PREFIX/etc/$conf" ]]; then
            missing_configs+=("$conf")
        fi
    done
    
    if [[ ${#missing_configs[@]} -eq 0 ]]; then
        test_pass "Core configuration files present"
    else
        test_fail "Missing configs: ${missing_configs[*]}"
    fi
}

# ------------------------------------------------------------------------------
# Test: Environment Loading
# ------------------------------------------------------------------------------

test_environment_loading() {
    log_section "ENVIRONMENT LOADING TESTS"
    
    # Detect Oracle SID
    local oracle_sid=""
    if [[ -f /etc/oratab ]]; then
        oracle_sid=$(grep -v "^#" /etc/oratab | grep -v "^$" | head -1 | cut -d: -f1)
    fi
    
    if [[ -z "$oracle_sid" ]]; then
        # Try to find running instance
        oracle_sid=$(ps -ef | grep -E "(db_smon_|ora_pmon_)" | grep -v grep | head -1 | awk '{print $NF}' | sed 's/.*_//')
    fi
    
    if [[ -z "$oracle_sid" ]]; then
        test_skip "No Oracle SID found - skipping environment tests"
        return 0
    fi
    
    log_info "Using Oracle SID: $oracle_sid"
    
    # Test 1: Source oraenv.sh
    test_start "Source oraenv.sh with SID: $oracle_sid"
    if source "$INSTALL_PREFIX/bin/oraenv.sh" "$oracle_sid" >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "oraenv.sh sourced successfully"
    else
        test_fail "Failed to source oraenv.sh"
        return 1
    fi
    
    # Test 2: ORACLE_SID set
    test_start "ORACLE_SID environment variable"
    if [[ "$ORACLE_SID" == "$oracle_sid" ]]; then
        test_pass "ORACLE_SID=$ORACLE_SID"
    else
        test_fail "ORACLE_SID not set correctly (expected: $oracle_sid, got: ${ORACLE_SID:-unset})"
    fi
    
    # Test 3: ORACLE_HOME set
    test_start "ORACLE_HOME environment variable"
    if [[ -n "$ORACLE_HOME" && -d "$ORACLE_HOME" ]]; then
        test_pass "ORACLE_HOME=$ORACLE_HOME"
    else
        test_fail "ORACLE_HOME not set or invalid: ${ORACLE_HOME:-unset}"
    fi
    
    # Test 4: ORACLE_BASE set
    test_start "ORACLE_BASE environment variable"
    if [[ -n "$ORACLE_BASE" && -d "$ORACLE_BASE" ]]; then
        test_pass "ORACLE_BASE=$ORACLE_BASE"
    else
        test_fail "ORACLE_BASE not set or invalid: ${ORACLE_BASE:-unset}"
    fi
    
    # Test 5: PATH updated
    test_start "PATH includes ORACLE_HOME/bin"
    if echo "$PATH" | grep -q "$ORACLE_HOME/bin"; then
        test_pass "ORACLE_HOME/bin in PATH"
    else
        test_fail "ORACLE_HOME/bin not in PATH"
    fi
    
    # Test 6: Libraries loaded
    test_start "Environment libraries loaded"
    local libs_loaded=0
    local libs_expected=6
    
    [[ -n "${ORADBA_ENV_PARSER_LOADED}" ]] && ((libs_loaded++))
    [[ -n "${ORADBA_ENV_BUILDER_LOADED}" ]] && ((libs_loaded++))
    [[ -n "${ORADBA_ENV_VALIDATOR_LOADED}" ]] && ((libs_loaded++))
    [[ -n "${ORADBA_ENV_CONFIG_LOADED}" ]] && ((libs_loaded++))
    [[ -n "${ORADBA_ENV_STATUS_LOADED}" ]] && ((libs_loaded++))
    [[ -n "${ORADBA_ENV_CHANGES_LOADED}" ]] && ((libs_loaded++))
    
    if [[ $libs_loaded -eq $libs_expected ]]; then
        test_pass "All $libs_expected libraries loaded"
    else
        test_fail "Only $libs_loaded/$libs_expected libraries loaded"
    fi
}

# ------------------------------------------------------------------------------
# Test: Auto-Discovery
# ------------------------------------------------------------------------------

test_auto_discovery() {
    log_section "AUTO-DISCOVERY TESTS"
    
    # Backup oratab
    test_start "Backup oratab"
    if [[ -f /etc/oratab ]]; then
        if sudo cp /etc/oratab /etc/oratab.backup_autodiscovery 2>/dev/null; then
            test_pass "oratab backed up"
        else
            test_skip "Cannot backup oratab (no sudo) - skipping auto-discovery tests"
            return 0
        fi
    else
        test_skip "No oratab file - skipping auto-discovery tests"
        return 0
    fi
    
    # Check for running instances
    test_start "Verify Oracle instance is running"
    if ps -ef | grep -E "(db_smon_|ora_pmon_)" | grep -v grep > /dev/null; then
        local instance_count
        instance_count=$(ps -ef | grep -E "(db_smon_|ora_pmon_)" | grep -v grep | wc -l)
        test_pass "$instance_count Oracle instance(s) running"
    else
        test_skip "No running Oracle instances - skipping auto-discovery tests"
        sudo mv /etc/oratab.backup_autodiscovery /etc/oratab 2>/dev/null
        return 0
    fi
    
    # Clear oratab
    test_start "Clear oratab for auto-discovery test"
    if sudo bash -c 'grep "^#" /etc/oratab > /etc/oratab.tmp && mv /etc/oratab.tmp /etc/oratab' 2>/dev/null; then
        test_pass "oratab cleared (comments preserved)"
    else
        test_fail "Failed to clear oratab"
        sudo mv /etc/oratab.backup_autodiscovery /etc/oratab 2>/dev/null
        return 1
    fi
    
    # Test auto-discovery in oraup.sh
    test_start "Auto-discovery via oraup.sh"
    local oraup_output
    oraup_output=$("$INSTALL_PREFIX/bin/oraup.sh" 2>&1)
    
    if echo "$oraup_output" | grep -q "Auto-discovered.*Oracle instance"; then
        test_pass "Auto-discovery detected running instances"
    else
        test_fail "Auto-discovery did not detect instances"
        log_info "oraup.sh output:"
        echo "$oraup_output" >> "$TEST_RESULTS_FILE"
    fi
    
    # Test persistence to oratab
    test_start "Auto-discovered instance persisted to oratab"
    local entry_count
    entry_count=$(grep -cv "^#\|^[[:space:]]*$" /etc/oratab 2>/dev/null || echo 0)
    
    if [[ $entry_count -gt 0 ]]; then
        test_pass "$entry_count instance(s) added to oratab"
        log_info "oratab entries:"
        grep -v "^#\|^[[:space:]]*$" /etc/oratab >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    else
        # Check local oratab fallback
        if [[ -f "$INSTALL_PREFIX/etc/oratab" ]]; then
            local_entries=$(grep -cv "^#\|^[[:space:]]*$" "$INSTALL_PREFIX/etc/oratab" 2>/dev/null || echo 0)
            if [[ $local_entries -gt 0 ]]; then
                test_pass "Instance(s) saved to local oratab (fallback)"
            else
                test_fail "No instances saved to system or local oratab"
            fi
        else
            test_fail "No instances saved to oratab"
        fi
    fi
    
    # Restore oratab
    test_start "Restore original oratab"
    if sudo mv /etc/oratab.backup_autodiscovery /etc/oratab 2>/dev/null; then
        test_pass "oratab restored"
    else
        test_fail "Failed to restore oratab"
    fi
}

# ------------------------------------------------------------------------------
# Test: Oracle Homes Management
# ------------------------------------------------------------------------------

test_oracle_homes() {
    log_section "ORACLE HOMES MANAGEMENT TESTS"
    
    # Test 1: List command
    test_start "List Oracle Homes"
    if "$INSTALL_PREFIX/bin/oradba_homes.sh" list >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "List command successful"
    else
        test_fail "List command failed"
    fi
    
    # Detect ORACLE_HOME
    if [[ -z "$ORACLE_HOME" ]]; then
        # Try to find it
        if [[ -f /etc/oratab ]]; then
            ORACLE_HOME=$(grep -v "^#" /etc/oratab | grep -v "^$" | head -1 | cut -d: -f2)
        fi
    fi
    
    if [[ -z "$ORACLE_HOME" || ! -d "$ORACLE_HOME" ]]; then
        test_skip "No valid ORACLE_HOME found - skipping add/show tests"
        return 0
    fi
    
    # Test 2: Add Oracle Home
    test_start "Add Oracle Home to registry"
    local test_home_name
    test_home_name="test_free26ai_$(date +%s)"
    
    if "$INSTALL_PREFIX/bin/oradba_homes.sh" add \
        --name "$test_home_name" \
        --path "$ORACLE_HOME" \
        --type "database" \
        --alias "test26ai" \
        --desc "Test Oracle 26ai Free" >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "Home registered: $test_home_name"
    else
        test_fail "Failed to register home"
        return 1
    fi
    
    # Test 3: Show home details
    test_start "Show Oracle Home details"
    if "$INSTALL_PREFIX/bin/oradba_homes.sh" show "$test_home_name" >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "Show command successful"
    else
        test_fail "Show command failed"
    fi
    
    # Test 4: Export/Import
    test_start "Export Oracle Homes configuration"
    local export_file="/tmp/oradba_homes_export_$$.conf"
    
    if "$INSTALL_PREFIX/bin/oradba_homes.sh" export > "$export_file" 2>&1; then
        test_pass "Export successful: $export_file"
        
        # Verify export format
        if grep -q "^$test_home_name:" "$export_file"; then
            test_pass "Export contains registered home"
        else
            test_fail "Export missing registered home"
        fi
        
        rm -f "$export_file"
    else
        test_fail "Export failed"
    fi
    
    # Test 5: Remove test home (cleanup)
    test_start "Remove test Oracle Home"
    if "$INSTALL_PREFIX/bin/oradba_homes.sh" remove "$test_home_name" --yes >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "Home removed: $test_home_name"
    else
        test_fail "Failed to remove home (may not support remove command yet)"
    fi
}

# ------------------------------------------------------------------------------
# Test: Database Status
# ------------------------------------------------------------------------------

test_database_status() {
    log_section "DATABASE STATUS TESTS"
    
    # Test 1: oraup.sh command
    test_start "oraup.sh displays status"
    if "$INSTALL_PREFIX/bin/oraup.sh" >> "$TEST_RESULTS_FILE" 2>&1; then
        test_pass "oraup.sh executed successfully"
    else
        test_fail "oraup.sh failed"
    fi
    
    # Test 2: Check for required sections
    test_start "Status output has required sections"
    local status_output
    status_output=$("$INSTALL_PREFIX/bin/oraup.sh" 2>&1)
    local has_sections=true
    
    if ! echo "$status_output" | grep -q "Oracle Environment Status"; then
        has_sections=false
        log_error "Missing 'Oracle Environment Status' header"
    fi
    
    # Should have either "Oracle Homes" or "Database Instances" section
    if ! echo "$status_output" | grep -qE "(Oracle Homes|Database Instances)"; then
        has_sections=false
        log_error "Missing Oracle Homes or Database Instances section"
    fi
    
    if [[ "$has_sections" == "true" ]]; then
        test_pass "Status output properly formatted"
    else
        test_fail "Status output missing required sections"
    fi
    
    # Test 3: Listener status (if running)
    if ps -ef | grep -v grep | grep "tnslsnr" > /dev/null 2>&1; then
        test_start "Listener status displayed"
        if echo "$status_output" | grep -q "Listener Status"; then
            test_pass "Listener status section present"
        else
            test_fail "Listener status section missing (listener is running)"
        fi
    else
        test_skip "No listener running - skipping listener status test"
    fi
}

# ------------------------------------------------------------------------------
# Test: Common Aliases
# ------------------------------------------------------------------------------

test_aliases() {
    log_section "ALIASES AND FUNCTIONS TESTS"
    
    # Source environment first
    if [[ -n "$ORACLE_SID" ]]; then
        source "$INSTALL_PREFIX/bin/oraenv.sh" "$ORACLE_SID" >> "$TEST_RESULTS_FILE" 2>&1 || true
    fi
    
    # Test common aliases
    local aliases=("sq" "cdh" "cda" "cdb" "taa")
    
    for alias_name in "${aliases[@]}"; do
        test_start "Alias: $alias_name"
        if type "$alias_name" &> /dev/null; then
            test_pass "$alias_name is available"
        else
            test_fail "$alias_name not found"
        fi
    done
}

# ------------------------------------------------------------------------------
# Test Summary
# ------------------------------------------------------------------------------

print_summary() {
    log_section "TEST SUMMARY"
    
    echo ""
    echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo "Total Tests:   $TESTS_TOTAL"
    echo "Total Tests:   $TESTS_TOTAL" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo -e "${GREEN}Passed:        $TESTS_PASSED${NC}"
    echo -e "${GREEN}Passed:        $TESTS_PASSED${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo -e "${RED}Failed:        $TESTS_FAILED${NC}"
    echo -e "${RED}Failed:        $TESTS_FAILED${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo -e "${YELLOW}Skipped:       $TESTS_SKIPPED${NC}"
    echo -e "${YELLOW}Skipped:       $TESTS_SKIPPED${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo ""
    echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    
    local pass_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi
    
    echo "Pass Rate:     ${pass_rate}%"
    echo "Pass Rate:     ${pass_rate}%" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    echo ""
    echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
        echo -e "${GREEN}✓ ALL TESTS PASSED${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
        echo ""
        echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
        echo "Results saved to: $TEST_RESULTS_FILE"
        return 0
    else
        echo -e "${RED}✗ SOME TESTS FAILED${NC}"
        echo -e "${RED}✗ SOME TESTS FAILED${NC}" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
        echo ""
        echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
        echo "Results saved to: $TEST_RESULTS_FILE"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------

main() {
    log_section "OraDBA Automated Tests - Oracle 26ai Free Docker"
    log_info "Test Results: $TEST_RESULTS_FILE"
    log_info "Installation Prefix: $INSTALL_PREFIX"
    log_info "Project Root: $PROJECT_ROOT"
    echo ""
    echo "" >> "$TEST_RESULTS_FILE" 2>/dev/null || true
    
    # Run test suites
    test_installation
    test_environment_loading
    test_auto_discovery
    test_oracle_homes
    test_database_status
    test_aliases
    
    # Print summary
    print_summary
}

# Run main
main "$@"
