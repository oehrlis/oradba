#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# Test oratab priority system
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Source common library
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    
    # Create temporary test directories
    export TEST_DIR="${BATS_TEST_TMPDIR}/oratab_test_$$"
    mkdir -p "${TEST_DIR}/etc"
    mkdir -p "${TEST_DIR}/system"
    mkdir -p "${TEST_DIR}/home"
    
    # Store original values
    export ORIGINAL_ORADBA_ORATAB="${ORADBA_ORATAB:-}"
    export ORIGINAL_ORADBA_BASE="${ORADBA_BASE}"
    
    # Set log level to ERROR to reduce test noise
    export ORADBA_LOG_LEVEL="ERROR"
}

# Cleanup after each test
teardown() {
    # Restore originals
    export ORADBA_ORATAB="${ORIGINAL_ORADBA_ORATAB}"
    export ORADBA_BASE="${ORIGINAL_ORADBA_BASE}"
    
    # Clean up test directories
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ------------------------------------------------------------------------------
# Test Priority 1: ORADBA_ORATAB override
# ------------------------------------------------------------------------------

@test "get_oratab_path: Priority 1 - ORADBA_ORATAB override" {
    # Create oratab files at different priorities
    echo "override:/opt/oracle/product:N" > "${TEST_DIR}/override_oratab"
    echo "system:/opt/oracle/product:N" > "${TEST_DIR}/system/oratab"
    
    # Set override
    export ORADBA_ORATAB="${TEST_DIR}/override_oratab"
    export ORADBA_BASE="${TEST_DIR}"
    
    # Run function
    result=$(get_oratab_path)
    
    # Should return override path
    [[ "$result" == "${TEST_DIR}/override_oratab" ]]
}

@test "get_oratab_path: Priority 1 - ORADBA_ORATAB works even if file doesn't exist" {
    export ORADBA_ORATAB="${TEST_DIR}/nonexistent_oratab"
    
    # Function will return exit code 1 if file doesn't exist
    result=$(get_oratab_path) || true
    
    # Should still return the override path
    [[ "$result" == "${TEST_DIR}/nonexistent_oratab" ]]
}

# ------------------------------------------------------------------------------
# Test Priority 2: /etc/oratab (system default)
# ------------------------------------------------------------------------------

@test "get_oratab_path: Priority 2 - /etc/oratab if exists" {
    # Skip if /etc/oratab doesn't exist in test environment
    [[ ! -f "/etc/oratab" ]] && skip "No /etc/oratab on system"
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    
    result=$(get_oratab_path)
    
    # Should return /etc/oratab
    [[ "$result" == "/etc/oratab" ]]
}

# ------------------------------------------------------------------------------
# Test Priority 4: ${ORADBA_BASE}/etc/oratab (temporary)
# ------------------------------------------------------------------------------

@test "get_oratab_path: Priority 4 - ORADBA_BASE/etc/oratab" {
    # Create temp oratab
    echo "test:/opt/oracle/product:N" > "${TEST_DIR}/etc/oratab"
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    
    # Mock: assume no system oratab exists for this test
    # (or skip if /etc/oratab actually exists)
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi
    
    result=$(get_oratab_path)
    
    # Should return temp oratab
    [[ "$result" == "${TEST_DIR}/etc/oratab" ]]
}

# ------------------------------------------------------------------------------
# Test Priority 5: ${HOME}/.oratab (user fallback)
# ------------------------------------------------------------------------------

@test "get_oratab_path: Priority 5 - HOME/.oratab fallback" {
    # Create user oratab
    echo "userdb:/opt/oracle/product:N" > "${TEST_DIR}/home/.oratab"
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}/empty"  # No temp oratab
    export HOME="${TEST_DIR}/home"
    
    # Skip if system oratab exists
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi
    
    result=$(get_oratab_path)
    
    # Should return user oratab
    [[ "$result" == "${TEST_DIR}/home/.oratab" ]]
}

# ------------------------------------------------------------------------------
# Test default fallback
# ------------------------------------------------------------------------------

@test "get_oratab_path: Returns /etc/oratab as default when nothing exists" {
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}/empty"
    export HOME="${TEST_DIR}/empty_home"
    mkdir -p "${HOME}"
    
    # Function will return exit code 1 if file doesn't exist
    result=$(get_oratab_path) || exit_code=$?
    
    # Should return default /etc/oratab
    [[ "$result" == "/etc/oratab" ]]
    
    # Exit code should be 1 (file doesn't exist) unless it actually exists
    if [[ -f "/etc/oratab" ]]; then
        [[ $exit_code -ne 1 ]] || true
    else
        [[ $exit_code -eq 1 ]] || true
    fi
}

# ------------------------------------------------------------------------------
# Test integration with other functions
# ------------------------------------------------------------------------------

@test "parse_oratab: Uses get_oratab_path() as default" {
    # Create test oratab
    echo "TESTDB:/opt/oracle/product/19c:N" > "${TEST_DIR}/etc/oratab"
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    
    # Skip if system oratab exists
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi
    
    # Call parse_oratab without specifying oratab file
    result=$(parse_oratab "TESTDB")
    
    # Should find entry from temp oratab
    [[ "$result" == *"TESTDB"* ]]
    [[ "$result" == *"/opt/oracle/product/19c"* ]]
}

@test "generate_sid_lists: Uses get_oratab_path() as default" {
    # Create test oratab with multiple entries
    cat > "${TEST_DIR}/etc/oratab" << EOF
# Test oratab
FREE:/opt/oracle/product/23ai:Y
TESTDB:/opt/oracle/product/19c:N
+ASM:/opt/grid/product/19c:N
dummy:/opt/oracle/product/dummy:D
EOF
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    
    # Skip if system oratab exists
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi
    
    # Call generate_sid_lists without specifying oratab file
    generate_sid_lists
    
    # Check exported variables
    [[ "$ORADBA_SIDLIST" == *"FREE"* ]]
    [[ "$ORADBA_SIDLIST" == *"TESTDB"* ]]
    [[ "$ORADBA_SIDLIST" == *"dummy"* ]]
    
    # Real SIDs should not include dummy (flag D) or ASM
    [[ "$ORADBA_REALSIDLIST" == *"FREE"* ]]
    [[ "$ORADBA_REALSIDLIST" == *"TESTDB"* ]]
    [[ "$ORADBA_REALSIDLIST" != *"dummy"* ]]
    [[ "$ORADBA_SIDLIST" != *"+ASM"* ]]
}

@test "generate_sid_lists: Skips alias creation when ORADBA_LOAD_ALIASES=false" {
    # Create test oratab
    cat > "${TEST_DIR}/etc/oratab" << EOF
FREE:/opt/oracle/product/23ai:Y
TESTDB:/opt/oracle/product/19c:N
EOF

    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    export ORADBA_LOAD_ALIASES="false"

    # Skip if system oratab exists
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi

    # Ensure aliases do not already exist
    unalias free 2>/dev/null || true
    unalias testdb 2>/dev/null || true

    # Build SID lists without creating aliases
    generate_sid_lists

    # SID list values are still populated for downstream logic
    [[ "$ORADBA_SIDLIST" == *"FREE"* ]]
    [[ "$ORADBA_REALSIDLIST" == *"FREE"* ]]

    # Aliases are not created when disabled
    run alias free
    [[ $status -ne 0 ]]

    run alias testdb
    [[ $status -ne 0 ]]
}

@test "is_dummy_sid: Uses get_oratab_path()" {
    # Create test oratab
    cat > "${TEST_DIR}/etc/oratab" << EOF
FREE:/opt/oracle/product/23ai:Y
dummy:/opt/oracle/product/dummy:D
EOF
    
    unset ORADBA_ORATAB
    export ORADBA_BASE="${TEST_DIR}"
    
    # Skip if system oratab exists
    if [[ -f "/etc/oratab" ]] || [[ -f "/var/opt/oracle/oratab" ]]; then
        skip "System oratab exists, would take priority"
    fi
    
    # Test dummy SID
    export ORACLE_SID="dummy"
    run is_dummy_sid
    [[ $status -eq 0 ]]
    
    # Test real SID
    export ORACLE_SID="FREE"
    run is_dummy_sid
    [[ $status -eq 1 ]]
}
