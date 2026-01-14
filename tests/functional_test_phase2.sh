#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# ---------------------------------------------------------------------------
# Functional test for Phase 2: Configuration Management
# Tests the integrated configuration system with real scenarios
# ---------------------------------------------------------------------------

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    if [ -n "${2:-}" ]; then
        echo "  Expected: $2"
    fi
    if [ -n "${3:-}" ]; then
        echo "  Got: $3"
    fi
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_DIR="${TMPDIR:-/tmp}/oradba_phase2_test_$$"

setup_test_env() {
    info "Setting up test environment in: ${TEST_DIR}"
    
    # Create test directory structure
    mkdir -p "${TEST_DIR}/etc/sid"
    mkdir -p "${TEST_DIR}/lib"
    
    # Copy libraries
    cp "${PROJECT_ROOT}/src/lib/oradba_env_parser.sh" "${TEST_DIR}/lib/"
    cp "${PROJECT_ROOT}/src/lib/oradba_env_builder.sh" "${TEST_DIR}/lib/"
    cp "${PROJECT_ROOT}/src/lib/oradba_env_validator.sh" "${TEST_DIR}/lib/"
    cp "${PROJECT_ROOT}/src/lib/oradba_env_config.sh" "${TEST_DIR}/lib/"
    
    # Set ORADBA_BASE
    export ORADBA_BASE="${TEST_DIR}"
    export ORACLE_BASE="/u01/app/oracle"
    export ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
    export ORACLE_SID="TESTDB"
    
    # Source libraries
    source "${TEST_DIR}/lib/oradba_env_parser.sh"
    source "${TEST_DIR}/lib/oradba_env_builder.sh"
    source "${TEST_DIR}/lib/oradba_env_validator.sh"
    source "${TEST_DIR}/lib/oradba_env_config.sh"
}

cleanup_test_env() {
    info "Cleaning up test environment"
    rm -rf "${TEST_DIR}"
}

# Test 1: Basic configuration loading
test_basic_config_loading() {
    info "Test 1: Basic configuration loading"
    
    # Create core config
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
export PAGER=less

[RDBMS]
export SQLPATH=/opt/oracle/sqlpath
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
EOF
    
    # Apply config
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Verify
    if [ "${EDITOR}" = "vi" ] && [ "${PAGER}" = "less" ]; then
        pass "DEFAULT section variables exported correctly"
    else
        fail "DEFAULT section variables not exported" "vi, less" "${EDITOR}, ${PAGER}"
    fi
    
    if [ "${SQLPATH}" = "/opt/oracle/sqlpath" ]; then
        pass "RDBMS section variables exported correctly"
    else
        fail "RDBMS section variables not exported" "/opt/oracle/sqlpath" "${SQLPATH:-<unset>}"
    fi
}

# Test 2: Configuration hierarchy (core < standard < local)
test_config_hierarchy() {
    info "Test 2: Configuration hierarchy"
    
    # Create configs with different values
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=core
export CORE_ONLY=core_value
EOF
    
    cat > "${TEST_DIR}/etc/oradba_standard.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=standard
export STANDARD_ONLY=standard_value
EOF
    
    cat > "${TEST_DIR}/etc/oradba_local.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=local
export LOCAL_ONLY=local_value
EOF
    
    # Apply config
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Verify hierarchy
    if [ "${TEST_PRIORITY}" = "local" ]; then
        pass "Configuration hierarchy works (local overrides standard/core)"
    else
        fail "Configuration hierarchy broken" "local" "${TEST_PRIORITY}"
    fi
    
    if [ "${CORE_ONLY}" = "core_value" ] && \
       [ "${STANDARD_ONLY}" = "standard_value" ] && \
       [ "${LOCAL_ONLY}" = "local_value" ]; then
        pass "All config levels loaded correctly"
    else
        fail "Not all config levels loaded"
    fi
}

# Test 3: Product-specific sections
test_product_sections() {
    info "Test 3: Product-specific sections"
    
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export DEFAULT_VAR=default

[RDBMS]
export RDBMS_VAR=rdbms_value

[CLIENT]
export CLIENT_VAR=client_value

[GRID]
export GRID_VAR=grid_value
EOF
    
    # Test RDBMS
    oradba_apply_product_config "RDBMS" "TESTDB"
    if [ "${DEFAULT_VAR}" = "default" ] && [ "${RDBMS_VAR}" = "rdbms_value" ]; then
        pass "RDBMS product section loaded correctly"
    else
        fail "RDBMS product section not loaded correctly"
    fi
    unset RDBMS_VAR CLIENT_VAR GRID_VAR
    
    # Test CLIENT
    oradba_apply_product_config "CLIENT" "TESTDB"
    if [ "${CLIENT_VAR}" = "client_value" ]; then
        pass "CLIENT product section loaded correctly"
    else
        fail "CLIENT product section not loaded correctly"
    fi
    unset CLIENT_VAR
    
    # Test GRID
    oradba_apply_product_config "GRID" "+ASM1"
    if [ "${GRID_VAR}" = "grid_value" ]; then
        pass "GRID product section loaded correctly"
    else
        fail "GRID product section not loaded correctly"
    fi
}

# Test 4: SID-specific configuration
test_sid_specific_config() {
    info "Test 4: SID-specific configuration"
    
    # Create generic config
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export GENERIC_VAR=generic_value

[RDBMS]
export SQLPATH=/generic/sqlpath
EOF
    
    # Create SID-specific config
    cat > "${TEST_DIR}/etc/sid/sid.TESTDB.conf" <<'EOF'
[DEFAULT]
export SID_SPECIFIC_VAR=sid_value

[RDBMS]
export SQLPATH=/sid/specific/sqlpath
export SID_RDBMS_VAR=sid_rdbms_value
EOF
    
    # Apply config
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Verify SID-specific config overrides generic
    if [ "${SQLPATH}" = "/sid/specific/sqlpath" ]; then
        pass "SID-specific config overrides generic config"
    else
        fail "SID-specific config didn't override generic" "/sid/specific/sqlpath" "${SQLPATH}"
    fi
    
    if [ "${SID_SPECIFIC_VAR}" = "sid_value" ] && \
       [ "${SID_RDBMS_VAR}" = "sid_rdbms_value" ]; then
        pass "SID-specific variables loaded correctly"
    else
        fail "SID-specific variables not loaded"
    fi
    
    if [ "${GENERIC_VAR}" = "generic_value" ]; then
        pass "Generic variables still accessible"
    else
        fail "Generic variables lost"
    fi
}

# Test 5: Variable expansion
test_variable_expansion() {
    info "Test 5: Variable expansion"
    
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<EOF
[RDBMS]
export EXPANDED_PATH="\${ORACLE_HOME}/bin"
export EXPANDED_SID="\${ORACLE_SID}_backup"
export EXPANDED_BASE="\${ORACLE_BASE}/admin"
EOF
    
    # Apply config
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Verify expansions
    if [ "${EXPANDED_PATH}" = "${ORACLE_HOME}/bin" ]; then
        pass "ORACLE_HOME variable expanded correctly"
    else
        fail "ORACLE_HOME not expanded" "${ORACLE_HOME}/bin" "${EXPANDED_PATH}"
    fi
    
    if [ "${EXPANDED_SID}" = "${ORACLE_SID}_backup" ]; then
        pass "ORACLE_SID variable expanded correctly"
    else
        fail "ORACLE_SID not expanded"
    fi
    
    if [ "${EXPANDED_BASE}" = "${ORACLE_BASE}/admin" ]; then
        pass "ORACLE_BASE variable expanded correctly"
    else
        fail "ORACLE_BASE not expanded"
    fi
}

# Test 6: Alias creation
test_alias_creation() {
    info "Test 6: Alias creation"
    
    shopt -s expand_aliases
    
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[RDBMS]
alias sqlplus='sqlplus -S'
alias sqldba='sqlplus / as sysdba'
alias dbs='cd ${ORACLE_HOME}/dbs'
EOF
    
    # Apply config
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Check if aliases exist
    if alias sqlplus 2>/dev/null | grep -q "sqlplus -S"; then
        pass "sqlplus alias created"
    else
        fail "sqlplus alias not created"
    fi
    
    if alias sqldba 2>/dev/null | grep -q "as sysdba"; then
        pass "sqldba alias created"
    else
        fail "sqldba alias not created"
    fi
}

# Test 7: Configuration validation
test_config_validation() {
    info "Test 7: Configuration validation"
    
    # Valid config
    cat > "${TEST_DIR}/etc/test_valid.conf" <<'EOF'
[DEFAULT]
export VAR1=value1
alias ll='ls -la'

[RDBMS]
export VAR2=value2
EOF
    
    if oradba_validate_config_file "${TEST_DIR}/etc/test_valid.conf" > /dev/null 2>&1; then
        pass "Valid config file passes validation"
    else
        fail "Valid config file failed validation"
    fi
    
    # Invalid section syntax
    cat > "${TEST_DIR}/etc/test_invalid.conf" <<'EOF'
[DEFAULT
export VAR1=value1
EOF
    
    if ! oradba_validate_config_file "${TEST_DIR}/etc/test_invalid.conf" > /dev/null 2>&1; then
        pass "Invalid section syntax detected"
    else
        fail "Invalid section syntax not detected"
    fi
    
    # Invalid variable syntax
    cat > "${TEST_DIR}/etc/test_invalid2.conf" <<'EOF'
[DEFAULT]
INVALID LINE WITHOUT EXPORT
EOF
    
    if ! oradba_validate_config_file "${TEST_DIR}/etc/test_invalid2.conf" > /dev/null 2>&1; then
        pass "Invalid variable syntax detected"
    else
        fail "Invalid variable syntax not detected"
    fi
}

# Test 8: ASM configuration
test_asm_config() {
    info "Test 8: ASM configuration"
    
    cat > "${TEST_DIR}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export DEFAULT_VAR=default

[ASM]
export ASM_VAR=asm_value
export ORACLE_SYSASM=SYSASM
EOF
    
    # Apply ASM config
    oradba_apply_product_config "ASM" "+ASM1"
    
    if [ "${ASM_VAR}" = "asm_value" ]; then
        pass "ASM section loaded correctly"
    else
        fail "ASM section not loaded" "asm_value" "${ASM_VAR:-<unset>}"
    fi
    
    if [ "${ORACLE_SYSASM}" = "SYSASM" ]; then
        pass "ASM-specific variables set"
    else
        fail "ASM-specific variables not set"
    fi
}

# Test 9: Section listing
test_section_listing() {
    info "Test 9: Section listing"
    
    cat > "${TEST_DIR}/etc/test_sections.conf" <<'EOF'
[DEFAULT]
export VAR1=value1

[RDBMS]
export VAR2=value2

[CLIENT]
export VAR3=value3

[GRID]
export VAR4=value4
EOF
    
    local sections
    sections=$(oradba_list_config_sections "${TEST_DIR}/etc/test_sections.conf")
    
    if echo "$sections" | grep -q "DEFAULT" && \
       echo "$sections" | grep -q "RDBMS" && \
       echo "$sections" | grep -q "CLIENT" && \
       echo "$sections" | grep -q "GRID"; then
        pass "All sections listed correctly"
    else
        fail "Section listing incomplete" "DEFAULT, RDBMS, CLIENT, GRID" "$sections"
    fi
}

# Test 10: Config value extraction
test_config_value_extraction() {
    info "Test 10: Config value extraction"
    
    cat > "${TEST_DIR}/etc/test_extract.conf" <<'EOF'
[DEFAULT]
export EDITOR=vim
export PAGER=less

[RDBMS]
export SQLPATH=/opt/oracle/sqlpath
EOF
    
    local editor
    editor=$(oradba_get_config_value "${TEST_DIR}/etc/test_extract.conf" "DEFAULT" "EDITOR")
    
    if [ "$editor" = "vim" ]; then
        pass "Config value extracted correctly"
    else
        fail "Config value extraction failed" "vim" "$editor"
    fi
    
    local sqlpath
    sqlpath=$(oradba_get_config_value "${TEST_DIR}/etc/test_extract.conf" "RDBMS" "SQLPATH")
    
    if [ "$sqlpath" = "/opt/oracle/sqlpath" ]; then
        pass "Product-specific value extracted correctly"
    else
        fail "Product-specific value extraction failed"
    fi
}

# Main test execution
main() {
    echo "========================================"
    echo "OraDBA Phase 2 Functional Tests"
    echo "Configuration Management System"
    echo "========================================"
    echo ""
    
    setup_test_env
    
    test_basic_config_loading
    test_config_hierarchy
    test_product_sections
    test_sid_specific_config
    test_variable_expansion
    test_alias_creation
    test_config_validation
    test_asm_config
    test_section_listing
    test_config_value_extraction
    
    cleanup_test_env
    
    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main
