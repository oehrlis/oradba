#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: validate_phase_2_4.sh
# Author...: GitHub Copilot Agent
# Date.....: 2026.01.31
# Purpose..: Validate Phase 2.4 comprehensive audit fixes
# Reference: Issue #141 (Phase 2.4 - Comprehensive Plugin Function Audit)
# Notes....: Validates that all critical sentinel string issues are fixed
# ------------------------------------------------------------------------------

echo "=================================================="
echo "Phase 2.4 Validation Script"
echo "=================================================="
echo ""

# Stub oradba_log to prevent errors
oradba_log() { :; }
export -f oradba_log

total_tests=0
passed_tests=0
failed_tests=0

# Test function
run_test() {
    local test_name="$1"
    local plugin_file="$2"
    local expected_exit="$3"
    
    ((total_tests++))
    
    echo -n "Testing ${test_name}... "
    
    # Source the plugin
    # shellcheck disable=SC1090
    if ! source "$plugin_file" 2>/dev/null; then
        echo "❌ FAIL (could not source plugin)"
        ((failed_tests++))
        return 1
    fi
    
    # Call plugin_check_status - should produce NO output (v0.20.0+)
    local output exit_code
    output=$(plugin_check_status "/fake/home" 2>/dev/null)
    exit_code=$?
    
    # Validate - v0.20.0+ uses exit codes only, NO output strings
    if [[ -z "$output" ]] && [[ $exit_code -eq $expected_exit ]]; then
        echo "✅ PASS (exit $exit_code, no output)"
        ((passed_tests++))
        return 0
    else
        if [[ -n "$output" ]]; then
            echo "❌ FAIL (exit $exit_code but had output: '$output' - should be silent)"
        else
            echo "❌ FAIL (expected exit $expected_exit, got exit $exit_code)"
        fi
        ((failed_tests++))
        return 1
    fi
}

# Test all three fixed stub plugins
echo "1. Testing stub plugin fixes (v0.20.0+ exit codes)"
echo "----------------------------------------------------"
echo "   Note: v0.20.0+ plugins use exit codes ONLY, no output strings"
echo ""
run_test "weblogic_plugin" "src/lib/plugins/weblogic_plugin.sh" 2
run_test "emagent_plugin" "src/lib/plugins/emagent_plugin.sh" 2
run_test "oms_plugin" "src/lib/plugins/oms_plugin.sh" 2
echo ""

# Test for sentinel strings
echo "2. Checking for sentinel strings in plugin files"
echo "------------------------------------------------"
((total_tests++))
if grep -rE 'echo[[:space:]]+"(ERR|N/A|NOT_FOUND)"[[:space:]]*$' src/lib/plugins/*.sh >/dev/null 2>&1; then
    echo "❌ FAIL: Found sentinel strings in plugin outputs"
    echo "   Found in:"
    grep -rn -E 'echo[[:space:]]+"(ERR|N/A|NOT_FOUND)"[[:space:]]*$' src/lib/plugins/*.sh || true
    ((failed_tests++))
else
    echo "✅ PASS: No standalone sentinel strings found"
    ((passed_tests++))
fi
echo ""

# Summary
echo "=================================================="
echo "Summary"
echo "=================================================="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo ""

if [[ $failed_tests -eq 0 ]]; then
    echo "✅ All Phase 2.4 validations PASSED"
    exit 0
else
    echo "❌ Some Phase 2.4 validations FAILED"
    exit 1
fi
