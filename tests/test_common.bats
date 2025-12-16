#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_common.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: BATS tests for common library functions
# Notes......: Tests logging, validation, and Oracle-specific functions.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Get the directory containing the test script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source the common library
    source "${PROJECT_ROOT}/src/lib/common.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
}

# Cleanup after tests
teardown() {
    # Remove temporary test directory
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "get_script_dir returns valid directory" {
    local script_dir=$(get_script_dir)
    [ -d "$script_dir" ]
}

@test "log_info outputs correct format" {
    run log_info "Test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[INFO\] ]]
    [[ "$output" =~ "Test message" ]]
}

@test "log_error outputs to stderr" {
    run log_error "Error message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "Error message" ]]
}

@test "command_exists detects existing commands" {
    run command_exists "bash"
    [ "$status" -eq 0 ]
}

@test "command_exists fails for non-existing commands" {
    run command_exists "nonexistentcommand123456"
    [ "$status" -eq 1 ]
}

@test "validate_directory succeeds for existing directory" {
    run validate_directory "$TEST_TEMP_DIR"
    [ "$status" -eq 0 ]
}

@test "validate_directory fails for non-existing directory" {
    run validate_directory "${TEST_TEMP_DIR}/nonexistent"
    [ "$status" -eq 1 ]
}

@test "validate_directory creates directory when requested" {
    local new_dir="${TEST_TEMP_DIR}/newdir"
    run validate_directory "$new_dir" "true"
    [ "$status" -eq 0 ]
    [ -d "$new_dir" ]
}

@test "parse_oratab finds valid entry" {
    # Create mock oratab file
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
# Mock oratab file
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/19.0.0/dbhome_2:Y
EOF
    
    run parse_oratab "FREE" "$mock_oratab"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N" ]]
}

@test "parse_oratab fails for non-existing SID" {
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
EOF
    
    run parse_oratab "NONEXISTENT" "$mock_oratab"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse_oratab ignores commented lines" {
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
#COMMENTED:/path/to/oracle:N
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
EOF
    
    run parse_oratab "COMMENTED" "$mock_oratab"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
