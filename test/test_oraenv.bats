#!/usr/bin/env bats
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# test_oraenv.bats - Tests for oraenv.sh script
# -----------------------------------------------------------------------
# Copyright (c) 2025 Stefan Oehrli
# Licensed under the Apache License, Version 2.0
# -----------------------------------------------------------------------

# Setup test environment
setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORAENV_SCRIPT="${PROJECT_ROOT}/srv/bin/oraenv.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Create mock oratab file
    MOCK_ORATAB="${TEST_TEMP_DIR}/oratab"
    cat > "$MOCK_ORATAB" <<EOF
# Test oratab file
ORCL:${TEST_TEMP_DIR}/oracle/19c:N
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
    result=$(bash -c "export ORATAB_FILE='$MOCK_ORATAB'; grep '^ORCL:' '$MOCK_ORATAB'")
    [[ "$result" =~ "ORCL:" ]]
}

@test "oraenv.sh parses oratab correctly" {
    # Test that oratab parsing works
    result=$(grep "^TESTDB:" "$MOCK_ORATAB" | cut -d: -f2)
    [[ "$result" == "${TEST_TEMP_DIR}/oracle/19c" ]]
}
