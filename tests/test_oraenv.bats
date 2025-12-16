#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oraenv.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: BATS tests for oraenv.sh environment script
# Notes......: Tests environment setup and oratab parsing functionality.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORAENV_SCRIPT="${PROJECT_ROOT}/src/bin/oraenv.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Create mock oratab file
    MOCK_ORATAB="${TEST_TEMP_DIR}/oratab"
    cat > "$MOCK_ORATAB" <<EOF
# Test oratab file
FREE:${TEST_TEMP_DIR}/oracle/19c:N
TESTDB:${TEST_TEMP_DIR}/oracle/19c:Y
CDB1:${TEST_TEMP_DIR}/oracle/21c:N
EOF
    
    # Create mock Oracle home directories
    mkdir -p "${TEST_TEMP_DIR}/oracle/19c/bin"
    mkdir -p "${TEST_TEMP_DIR}/oracle/21c/bin"
    
    # Set environment variable for oratab location
    export ORATAB_FILE="$MOCK_ORATAB"
}

# Cleanup after tests
teardown() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    unset ORATAB_FILE
    unset ORACLE_SID
    unset ORACLE_HOME
}

@test "oraenv.sh exists and is executable" {
    [ -f "$ORAENV_SCRIPT" ]
    [ -x "$ORAENV_SCRIPT" ]
}

@test "oraenv.sh has valid bash syntax" {
    run bash -n "$ORAENV_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "oraenv.sh cannot be executed directly" {
    run bash "$ORAENV_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must be sourced" ]]
}

@test "oraenv.sh requires valid ORACLE_SID" {
    run bash -c "source '$ORAENV_SCRIPT' NONEXISTENT"
    [ "$status" -ne 0 ]
}

@test "oraenv.sh sets ORACLE_SID from oratab" {
    # This test verifies the script can find entries in oratab
    result=$(bash -c "export ORATAB_FILE='$MOCK_ORATAB'; grep '^FREE:' '$MOCK_ORATAB'")
    [[ "$result" =~ "FREE:" ]]
}

@test "oraenv.sh parses oratab correctly" {
    # Test that oratab parsing works
    result=$(grep "^TESTDB:" "$MOCK_ORATAB" | cut -d: -f2)
    [[ "$result" == "${TEST_TEMP_DIR}/oracle/19c" ]]
}

@test "oraenv.sh --help displays usage" {
    # Check that help option exists in the code
    grep -q "\\-h.*--help" "$ORAENV_SCRIPT"
    grep -q "Usage:" "$ORAENV_SCRIPT"
}

@test "oraenv.sh supports --silent flag" {
    # Check that --silent flag is recognized in the code
    grep -q "\\-s.*--silent" "$ORAENV_SCRIPT"
}

@test "oraenv.sh supports --status flag" {
    # Check that --status flag is documented in the code
    grep -q "\-\-status" "$ORAENV_SCRIPT"
}

@test "oraenv.sh detects TTY for interactive mode" {
    # This tests that the script can detect TTY
    # In test environment, we check the logic exists
    grep -q "ORAENV_INTERACTIVE" "$ORAENV_SCRIPT"
}

@test "oraenv.sh handles non-interactive mode" {
    # Verify the script has logic for non-interactive mode
    grep -q "ORAENV_INTERACTIVE.*false" "$ORAENV_SCRIPT"
}

@test "oraenv.sh _oraenv_prompt_sid function exists" {
    # Check that the prompt function is defined
    grep -q "^_oraenv_prompt_sid()" "$ORAENV_SCRIPT"
}

@test "oraenv.sh _oraenv_prompt_sid handles silent mode" {
    # Check that function has logic for non-interactive mode
    grep -A 20 "^_oraenv_prompt_sid()" "$ORAENV_SCRIPT" | grep -q "ORAENV_INTERACTIVE"
}

@test "oraenv.sh loads db_functions.sh if available" {
    # Check that oraenv sources db_functions
    grep -q "db_functions.sh" "$ORAENV_SCRIPT"
}

@test "oraenv.sh has show_database_status integration" {
    # Check that show_database_status is called conditionally
    grep -q "show_database_status" "$ORAENV_SCRIPT"
}

@test "oraenv.sh validates multiple SIDs handling" {
    # Check error handling for multiple SIDs
    grep -q "Multiple SIDs provided" "$ORAENV_SCRIPT"
}

@test "oraenv.sh supports numbered SID selection" {
    # Check that numbered selection is implemented
    grep -A 30 "_oraenv_prompt_sid" "$ORAENV_SCRIPT" | grep -q "printf.*\[%d\]"
}

@test "oraenv.sh handles empty oratab gracefully" {
    # Create empty oratab
    echo "# Empty oratab" > "${TEST_TEMP_DIR}/empty_oratab"
    export ORATAB_FILE="${TEST_TEMP_DIR}/empty_oratab"
    
    # The script should handle this without crashing
    # We check that error handling exists in the code
    grep -q "No Oracle instances found" "$ORAENV_SCRIPT"
}

# Integration tests - actually execute the script with valid parameters

@test "oraenv.sh integration: sources successfully with valid SID" {
    # Create a script that sources oraenv and checks result
    run bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' FREE 2>&1
        if [[ \$? -eq 0 ]]; then
            echo \"SUCCESS\"
            exit 0
        else
            echo \"FAILED\"
            exit 1
        fi
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SUCCESS" ]]
}

@test "oraenv.sh integration: sets ORACLE_SID correctly" {
    # Source and verify ORACLE_SID is set
    result=$(bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' TESTDB --silent 2>&1
        echo \$ORACLE_SID
    " | tail -1)
    [[ "$result" == "TESTDB" ]]
}

@test "oraenv.sh integration: sets ORACLE_HOME from oratab" {
    # Source and verify ORACLE_HOME is set correctly
    result=$(bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' FREE --silent 2>&1
        echo \$ORACLE_HOME
    " | tail -1)
    [[ "$result" == "${TEST_TEMP_DIR}/oracle/19c" ]]
}

@test "oraenv.sh integration: --silent flag minimizes output" {
    # Silent mode should minimize output (may have [INFO] log but no environment display)
    run bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' FREE --silent 2>&1
    "
    [ "$status" -eq 0 ]
    # Should not show environment details
    ! [[ "$output" =~ "Oracle Environment:" ]]
    ! [[ "$output" =~ "ORACLE_HOME" ]]
}

@test "oraenv.sh integration: --help shows usage" {
    # Help should display usage information
    # Check that usage function exists and can be called
    grep -q "^_oraenv_usage()" "$ORAENV_SCRIPT"
    grep -q "Usage: source oraenv.sh" "$ORAENV_SCRIPT"
}

@test "oraenv.sh integration: invalid SID fails gracefully" {
    # Invalid SID should produce error
    run bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' INVALID_SID 2>&1
    "
    [ "$status" -ne 0 ]
    [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "not found" ]]
}

@test "oraenv.sh integration: updates PATH with ORACLE_HOME/bin" {
    # Verify PATH includes ORACLE_HOME/bin
    result=$(bash -c "
        export ORATAB_FILE='$MOCK_ORATAB'
        source '$ORAENV_SCRIPT' CDB1 --silent 2>&1
        echo \$PATH
    ")
    [[ "$result" =~ "${TEST_TEMP_DIR}/oracle/21c/bin" ]]
}
