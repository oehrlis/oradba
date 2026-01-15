#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_sid_variable_isolation.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.14
# Purpose....: Manual test for SID-specific variable isolation
# Notes......: Tests that custom variables in sid.<SID>.conf are cleaned up
#              when switching to a different SID environment
# Usage......: bash tests/manual/test_sid_variable_isolation.sh
# ------------------------------------------------------------------------------

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Determine ORADBA_BASE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="$(cd "$SCRIPT_DIR/../.." && pwd)"
export ORADBA_BASE
export ORADBA_PREFIX="$ORADBA_BASE/src"

info "ORADBA_BASE: $ORADBA_BASE"
info ""
info "==================================================================="
info "MANUAL TEST INSTRUCTIONS"
info "==================================================================="
info ""
info "This test requires an actual Oracle environment with multiple SIDs."
info ""
info "Setup:"
info "  1. Ensure you have at least 2 SIDs in /etc/oratab (e.g., FREE, PROD)"
info "  2. Create sid.FREE.conf with: export CUSTOM_FREE=valueFromFree"
info "  3. Create sid.PROD.conf with: export CUSTOM_PROD=valueFromProd"
info ""
info "Test procedure:"
info "  1. source \$ORADBA_BASE/bin/oraenv.sh FREE"
info "  2. echo \"\$CUSTOM_FREE\"  # Should show: valueFromFree"
info "  3. echo \"\$CUSTOM_PROD\"  # Should show: <empty>"
info "  4. source \$ORADBA_BASE/bin/oraenv.sh PROD"
info "  5. echo \"\$CUSTOM_FREE\"  # Should show: <empty> (CLEANED UP!)"
info "  6. echo \"\$CUSTOM_PROD\"  # Should show: valueFromProd"
info ""
info "Expected behavior:"
info "  - SID-specific variables should be UNSET when switching SIDs"
info "  - Only current SID's variables should be present"
info ""
info "==================================================================="
info "AUTOMATED TEST (Unit Test Only)"
info "==================================================================="
info ""

# Create test directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

info "Test directory: $TEST_DIR"

# Create minimal test configs
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/sid.TEST1.conf" << 'EOF'
# Test SID 1 configuration
export CUSTOM_VAR_TEST1="value_from_test1"
export SHARED_VAR="test1_value"
export TEST1_ONLY="only_in_test1"
EOF

cat > "$TEST_DIR/sid.TEST2.conf" << 'EOF'
# Test SID 2 configuration
export CUSTOM_VAR_TEST2="value_from_test2"
export SHARED_VAR="test2_value"
export TEST2_ONLY="only_in_test2"
EOF

info "Test configurations created"
echo ""
echo "========================================="
echo "Unit Test: Variable Tracking Functions"
echo "========================================="

# Define test functions directly (simpler than sourcing full library)
cleanup_previous_sid_config() {
    if [[ -n "${ORADBA_PREV_SID_VARS:-}" ]]; then
        local var
        for var in ${ORADBA_PREV_SID_VARS}; do
            case "$var" in
                ORACLE_SID|ORACLE_HOME|ORACLE_BASE|ORADBA_*|PATH|LD_LIBRARY_PATH|TNS_ADMIN|NLS_LANG)
                    continue
                    ;;
                *)
                    unset "$var"
                    ;;
            esac
        done
        unset ORADBA_PREV_SID_VARS
    fi
}

capture_sid_config_vars() {
    local sid_config="$1"
    [[ ! -f "$sid_config" ]] && return 1
    
    local vars_before
    vars_before=$(compgen -e | sort)
    
    set -a
    # shellcheck disable=SC1090
    source "$sid_config"
    set +a
    
    local vars_after
    vars_after=$(compgen -e | sort)
    
    local new_vars
    new_vars=$(comm -13 <(echo "$vars_before") <(echo "$vars_after") | tr '\n' ' ')
    
    export ORADBA_PREV_SID_VARS="$new_vars"
    
    return 0
}

# Test 1: Load first SID config
info "Loading TEST1 configuration..."
capture_sid_config_vars "$TEST_DIR/sid.TEST1.conf"

((TESTS_RUN++))
if [[ "${CUSTOM_VAR_TEST1:-}" == "value_from_test1" ]]; then
    pass "TEST1: CUSTOM_VAR_TEST1 is set"
else
    fail "TEST1: CUSTOM_VAR_TEST1 not set (got: '${CUSTOM_VAR_TEST1:-<unset>}')"
fi

((TESTS_RUN++))
if [[ "${TEST1_ONLY:-}" == "only_in_test1" ]]; then
    pass "TEST1: TEST1_ONLY is set"
else
    fail "TEST1: TEST1_ONLY not set (got: '${TEST1_ONLY:-<unset>}')"
fi

# Test 2: Switch to second SID config
info "Switching to TEST2 configuration..."
cleanup_previous_sid_config
capture_sid_config_vars "$TEST_DIR/sid.TEST2.conf"

((TESTS_RUN++))
if [[ -z "${CUSTOM_VAR_TEST1:-}" ]]; then
    pass "TEST2: CUSTOM_VAR_TEST1 was cleaned up"
else
    fail "TEST2: CUSTOM_VAR_TEST1 still set (got: '${CUSTOM_VAR_TEST1}')"
fi

((TESTS_RUN++))
if [[ -z "${TEST1_ONLY:-}" ]]; then
    pass "TEST2: TEST1_ONLY was cleaned up"
else
    fail "TEST2: TEST1_ONLY still set (got: '${TEST1_ONLY}')"
fi

((TESTS_RUN++))
if [[ "${CUSTOM_VAR_TEST2:-}" == "value_from_test2" ]]; then
    pass "TEST2: CUSTOM_VAR_TEST2 is set"
else
    fail "TEST2: CUSTOM_VAR_TEST2 not set (got: '${CUSTOM_VAR_TEST2:-<unset>}')"
fi

# Test 3: Switch back to first SID
info "Switching back to TEST1 configuration..."
cleanup_previous_sid_config
capture_sid_config_vars "$TEST_DIR/sid.TEST1.conf"

((TESTS_RUN++))
if [[ -z "${CUSTOM_VAR_TEST2:-}" ]]; then
    pass "TEST1 (2nd time): CUSTOM_VAR_TEST2 was cleaned up"
else
    fail "TEST1 (2nd time): CUSTOM_VAR_TEST2 still set (got: '${CUSTOM_VAR_TEST2}')"
fi

((TESTS_RUN++))
if [[ "${CUSTOM_VAR_TEST1:-}" == "value_from_test1" ]]; then
    pass "TEST1 (2nd time): CUSTOM_VAR_TEST1 is set again"
else
    fail "TEST1 (2nd time): CUSTOM_VAR_TEST1 not set (got: '${CUSTOM_VAR_TEST1:-<unset>}')"
fi

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All automated tests passed!${NC}"
    echo ""
    info "To fully test with real Oracle environments, follow the manual"
    info "test instructions shown at the beginning of this script output."
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed!${NC}"
    exit 1
fi

