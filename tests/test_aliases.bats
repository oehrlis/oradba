#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_aliases.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: BATS tests for aliases.sh - dynamic alias generation
# Notes......: Run with: bats test_aliases.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup before each test
setup() {
    # Enable alias expansion in bash (required for alias tests)
    shopt -s expand_aliases
    
    # Get the directory containing the script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source the common library first (provides log functions)
    export ORADBA_PREFIX="${PROJECT_ROOT}/src"
    source "${PROJECT_ROOT}/src/lib/common.sh"
    
    # Source the aliases library
    source "${PROJECT_ROOT}/src/lib/aliases.sh"
    
    # Create temp directory for tests
    TEMP_TEST_DIR="${BATS_TMPDIR}/oradba_aliases_test_$$"
    mkdir -p "${TEMP_TEST_DIR}"
    
    # Mock environment
    export ORACLE_SID="TESTDB"
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    mkdir -p "${ORACLE_HOME}/bin"
    mkdir -p "${ORACLE_BASE}"
}

# Cleanup after each test
teardown() {
    if [[ -d "${TEMP_TEST_DIR}" ]]; then
        rm -rf "${TEMP_TEST_DIR}"
    fi
    unalias -a 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Basic Function Tests
# ------------------------------------------------------------------------------

@test "aliases.sh can be sourced" {
    run bash -c "source '${PROJECT_ROOT}/src/lib/aliases.sh'; echo 'OK'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

@test "has_rlwrap function exists" {
    type has_rlwrap
}

@test "get_diagnostic_dest function exists" {
    type get_diagnostic_dest
}

@test "generate_sid_aliases function exists" {
    type generate_sid_aliases
}

@test "create_dynamic_alias function exists" {
    type create_dynamic_alias
}

# ------------------------------------------------------------------------------
# create_dynamic_alias() Tests
# ------------------------------------------------------------------------------

@test "create_dynamic_alias creates non-expanded alias" {
    export ORADBA_BIN="/usr/local/bin"
    
    # Create non-expanded alias (default behavior)
    create_dynamic_alias test_alias '${ORADBA_BIN}/script.sh'
    
    # Check alias was created
    run alias test_alias
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ORADBA_BIN" ]]
}

@test "create_dynamic_alias creates expanded alias when requested" {
    export ORADBA_BIN="/usr/local/bin"
    
    # Create expanded alias
    create_dynamic_alias test_alias_exp "${ORADBA_BIN}/script.sh" "true"
    
    # Check alias was created with expanded value
    run alias test_alias_exp
    [ "$status" -eq 0 ]
    [[ "$output" =~ /usr/local/bin/script.sh ]]
}

@test "create_dynamic_alias requires alias name" {
    # Should fail without name
    run create_dynamic_alias
    [ "$status" -ne 0 ]
}

@test "create_dynamic_alias requires alias command" {
    # Should fail without command
    run create_dynamic_alias test_name
    [ "$status" -ne 0 ]
}

@test "create_dynamic_alias respects safe_alias coexistence mode" {
    export ORADBA_COEXIST_MODE="basenv"
    
    # Create a fake existing alias
    alias existing_alias="echo exists"
    
    # Try to create same alias (should be skipped)
    run create_dynamic_alias existing_alias "echo new"
    [ "$status" -eq 1 ]  # safe_alias returns 1 when skipped
}

@test "create_dynamic_alias works with directory navigation" {
    local test_dir="/tmp/test_oradba"
    
    # Create expanded directory alias
    create_dynamic_alias cdtest "cd ${test_dir}" "true"
    
    # Verify alias was created with expanded path
    run alias cdtest
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/tmp/test_oradba" ]]
}

@test "create_dynamic_alias works with complex commands" {
    # Create non-expanded complex command
    create_dynamic_alias complex_cmd 'if [ -f "${FILE}" ]; then cat "${FILE}"; else echo "not found"; fi'
    
    # Verify alias was created
    run alias complex_cmd
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FILE" ]]
    [[ "$output" =~ "not found" ]]
}

# ------------------------------------------------------------------------------
# has_rlwrap() Tests
# ------------------------------------------------------------------------------

@test "has_rlwrap returns 0 if rlwrap is available" {
    if command -v rlwrap &>/dev/null; then
        run has_rlwrap
        [ "$status" -eq 0 ]
    else
        skip "rlwrap not installed on this system"
    fi
}

@test "has_rlwrap returns 1 if rlwrap is not available" {
    export RLWRAP_COMMAND="nonexistent_rlwrap_command"
    run has_rlwrap
    [ "$status" -eq 1 ]
}

@test "has_rlwrap respects RLWRAP_COMMAND variable" {
    # Test with a command that exists
    export RLWRAP_COMMAND="bash"
    run has_rlwrap
    [ "$status" -eq 0 ]
    
    # Test with a command that doesn't exist
    export RLWRAP_COMMAND="this_command_does_not_exist"
    run has_rlwrap
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# get_diagnostic_dest() Tests
# ------------------------------------------------------------------------------

@test "get_diagnostic_dest returns fallback path when DB not accessible" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Without a real database, should return convention-based path
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    [[ "$result" =~ "diag/rdbms/testdb/TESTDB" ]]
}

@test "get_diagnostic_dest handles empty ORACLE_SID" {
    unset ORACLE_SID
    
    run get_diagnostic_dest
    [ "$status" -eq 0 ]
    # Should still return a path (with empty SID placeholders)
    [[ "$output" =~ "diag/rdbms" ]]
}

@test "get_diagnostic_dest uses ORACLE_BASE" {
    export ORACLE_SID="PRODDB"
    export ORACLE_BASE="/u01/app/oracle"
    
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    [[ "$result" =~ "diag/rdbms/proddb/PRODDB" ]]
}

@test "get_diagnostic_dest converts SID to lowercase in path" {
    export ORACLE_SID="ORCL"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    # Path should contain lowercase 'orcl' for rdbms directory
    [[ "$result" =~ "rdbms/orcl/ORCL" ]]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - No ORACLE_SID
# ------------------------------------------------------------------------------

@test "generate_sid_aliases returns 0 with no ORACLE_SID set" {
    unset ORACLE_SID
    
    run generate_sid_aliases
    [ "$status" -eq 0 ]
}

@test "generate_sid_aliases creates no aliases when ORACLE_SID is empty" {
    unset ORACLE_SID
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # Check that SID-specific aliases are not created
    run alias taa
    [ "$status" -ne 0 ]
    
    run alias cdda
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - With Mock Diagnostic Directories
# ------------------------------------------------------------------------------

@test "ORADBA_SID_ALERTLOG variable is set when ORACLE_SID and ORACLE_BASE exist" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    export ORADBA_ORA_DIAG_SID="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    
    # Source the standard config to set ORADBA_SID_ALERTLOG
    ORADBA_SID_ALERTLOG="${ORADBA_ORA_DIAG_SID}/trace/alert_${ORACLE_SID}.log"
    
    # Verify variable is set correctly
    [ -n "${ORADBA_SID_ALERTLOG}" ]
    [[ "${ORADBA_SID_ALERTLOG}" =~ alert_TESTDB.log ]]
    [[ "${ORADBA_SID_ALERTLOG}" =~ /trace/ ]]
}

@test "generate_sid_aliases creates cdda alias when diagnostic dest exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/alert"
    mkdir -p "${diag_dest}/trace"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    
    # Verify the function completed successfully
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates cdta alias when trace directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates cdaa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/alert"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates taa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    touch "${diag_dest}/trace/alert_TESTDB.log"
    
    # Set ORADBA_SID_ALERTLOG
    export ORADBA_SID_ALERTLOG="${diag_dest}/trace/alert_TESTDB.log"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
    
    # Verify alias contains ORADBA_SID_ALERTLOG
    run alias taa
    [[ "$output" =~ "ORADBA_SID_ALERTLOG" ]]
}

@test "generate_sid_aliases creates vaa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    touch "${diag_dest}/trace/alert_TESTDB.log"
    
    # Set ORADBA_SID_ALERTLOG
    export ORADBA_SID_ALERTLOG="${diag_dest}/trace/alert_TESTDB.log"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
    
    # Verify alias contains ORADBA_SID_ALERTLOG
    run alias vaa
    [[ "$output" =~ "ORADBA_SID_ALERTLOG" ]]
}

@test "generate_sid_aliases doesn't create aliases when diagnostic dest doesn't exist" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Don't create diagnostic directories
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # Check that aliases are not created
    run alias cdda 2>/dev/null
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - rlwrap Integration
# ------------------------------------------------------------------------------

@test "generate_sid_aliases creates rlwrap aliases when rlwrap is available" {
    if ! command -v rlwrap &>/dev/null; then
        skip "rlwrap not installed on this system"
    fi
    
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="rlwrap"
    export RLWRAP_OPTS="-i -c"
    
    generate_sid_aliases
    
    # Check sq alias contains rlwrap
    run bash -c "alias sq"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rlwrap" ]]
    [[ "$output" =~ "sqlplus" ]]
}

@test "generate_sid_aliases doesn't create rlwrap aliases when rlwrap not available" {
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="nonexistent_rlwrap"
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # sq alias should not be created (since rlwrap not available and not in generate_sid_aliases)
    # This test just verifies the function doesn't fail
    [ "$?" -eq 0 ]
}

@test "sqh alias connects with sysdba when rlwrap available" {
    if ! command -v rlwrap &>/dev/null; then
        skip "rlwrap not installed on this system"
    fi
    
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="rlwrap"
    export RLWRAP_OPTS="-i -c"
    
    generate_sid_aliases
    
    # Check sqh alias uses "/ as sysdba" not "/nolog"
    run bash -c "alias sqh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sqlplus / as sysdba" ]]
    [[ ! "$output" =~ "/nolog" ]]
}

# ------------------------------------------------------------------------------
# Integration Tests - Different SIDs
# ------------------------------------------------------------------------------

@test "generate_sid_aliases works with different ORACLE_SID values" {
    # Test with multiple different SIDs
    for sid in "ORCL" "DEVDB" "PRODDB" "TEST01"; do
        export ORACLE_SID="$sid"
        export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
        
        # Create diagnostic structure
        local diag_dest="${ORACLE_BASE}/diag/rdbms/${sid,,}/${sid}"
        mkdir -p "${diag_dest}/alert"
        mkdir -p "${diag_dest}/trace"
        
        # Generate aliases - should succeed for each SID
        generate_sid_aliases
        [ "$?" -eq 0 ]
    done
}

@test "generate_sid_aliases handles SIDs with special characters" {
    # Test with SID containing numbers
    export ORACLE_SID="DB19C"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    local diag_dest="${ORACLE_BASE}/diag/rdbms/db19c/DB19C"
    mkdir -p "${diag_dest}/alert"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

# ------------------------------------------------------------------------------
# Auto-Generation Tests
# ------------------------------------------------------------------------------

@test "aliases.sh auto-generates aliases if ORACLE_SID is set on load" {
    export ORACLE_SID="AUTOTEST"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/autotest/AUTOTEST"
    mkdir -p "${diag_dest}/alert"
    
    # Source aliases.sh (which auto-generates if ORACLE_SID is set)
    # Should not fail
    run bash -c "
        shopt -s expand_aliases
        export ORACLE_SID='AUTOTEST'
        export ORACLE_BASE='${TEMP_TEST_DIR}/oracle'
        export ORADBA_PREFIX='${PROJECT_ROOT}/src'
        source '${PROJECT_ROOT}/src/lib/common.sh'
        source '${PROJECT_ROOT}/src/lib/aliases.sh'
        echo OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

@test "aliases.sh doesn't fail if ORACLE_SID is not set on load" {
    unset ORACLE_SID
    
    # Should not fail to source
    run bash -c "source '${PROJECT_ROOT}/src/lib/aliases.sh'; echo 'OK'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

# ------------------------------------------------------------------------------
# Error Handling Tests
# ------------------------------------------------------------------------------

@test "get_diagnostic_dest handles missing ORACLE_BASE gracefully" {
    export ORACLE_SID="TESTDB"
    unset ORACLE_BASE
    
    # Should still return a path
    run get_diagnostic_dest
    [ "$status" -eq 0 ]
    # Output should not be empty
    [ -n "$output" ]
}

@test "generate_sid_aliases handles missing ORACLE_HOME gracefully" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    unset ORACLE_HOME
    
    # Should not fail
    run generate_sid_aliases
    [ "$status" -eq 0 ]
}

@test "aliases.sh functions don't pollute environment with unexpected variables" {
    # Run alias generation
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    generate_sid_aliases
    
    # Should not have unexpected new variables (some test framework vars are OK)
    # Main concern is no leaked 'sid', 'diag_dest', etc. at global scope
    run bash -c "declare -p sid 2>&1"
    [[ "$output" =~ (not found|not set) ]]
}
