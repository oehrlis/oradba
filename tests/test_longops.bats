#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_longops.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.19
# Revision...: 0.8.1
# Purpose....: BATS tests for longops.sh monitoring utility
# Notes......: Tests operation filtering, watch mode, and argument parsing
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Find project root
    if [[ -f "VERSION" ]]; then
        PROJECT_ROOT="$(pwd)"
    elif [[ -f "../VERSION" ]]; then
        PROJECT_ROOT="$(cd .. && pwd)"
    else
        skip "Cannot find project root"
    fi
    
    LONGOPS_SCRIPT="${PROJECT_ROOT}/src/bin/longops.sh"
    
    # Skip if script doesn't exist
    [[ -f "$LONGOPS_SCRIPT" ]] || skip "longops.sh not found"
}

# ------------------------------------------------------------------------------
# Basic functionality tests
# ------------------------------------------------------------------------------

@test "longops.sh exists and is executable" {
    [[ -x "$LONGOPS_SCRIPT" ]]
}

@test "longops.sh has valid bash syntax" {
    run bash -n "$LONGOPS_SCRIPT"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh --help shows usage" {
    run "$LONGOPS_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ Usage: ]]
    [[ "$output" =~ longops.sh ]]
}

@test "longops.sh -h shows usage" {
    run "$LONGOPS_SCRIPT" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ Usage: ]]
}

@test "longops.sh help output includes OPTIONS section" {
    run "$LONGOPS_SCRIPT" --help
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "-o" ]]
    [[ "$output" =~ "-w" ]]
    [[ "$output" =~ "-i" ]]
}

@test "longops.sh help output includes EXAMPLES section" {
    run "$LONGOPS_SCRIPT" --help
    [[ "$output" =~ "EXAMPLES:" ]]
}

@test "longops.sh help output mentions operation filtering" {
    run "$LONGOPS_SCRIPT" --help
    [[ "$output" =~ "operation" || "$output" =~ "OPERATION" ]]
}

@test "longops.sh help output mentions watch mode" {
    run "$LONGOPS_SCRIPT" --help
    [[ "$output" =~ "watch" || "$output" =~ "continuous" ]]
}

# ------------------------------------------------------------------------------
# Argument parsing tests
# ------------------------------------------------------------------------------

@test "longops.sh accepts -o option" {
    run bash -c "grep -q '\-o.*--operation' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh accepts -w option" {
    run bash -c "grep -q '\-w.*--watch' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh accepts -i option" {
    run bash -c "grep -q '\-i.*--interval' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh has parse_args function" {
    run bash -c "grep -q 'parse_args()' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh has main function" {
    run bash -c "grep -q '^main()' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Script structure tests
# ------------------------------------------------------------------------------

@test "longops.sh uses modern bash shebang" {
    run head -n 1 "$LONGOPS_SCRIPT"
    [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "longops.sh has set -o pipefail" {
    run bash -c "grep -q 'set -o pipefail' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh declares SCRIPT_NAME as readonly" {
    run bash -c "grep -q 'readonly SCRIPT_NAME' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh has monitor_longops function" {
    run bash -c "grep -q 'monitor_longops()' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh has display_header function" {
    run bash -c "grep -q 'display_header()' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh contains SQL query for v\$session_longops" {
    run bash -c "grep -qi 'v\$session_longops' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh has run_monitor function for watch mode" {
    run bash -c "grep -q 'run_monitor()' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Configuration and dependencies
# ------------------------------------------------------------------------------

@test "longops.sh checks for sqlplus availability" {
    run bash -c "grep -qi 'sqlplus' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh handles ORACLE_HOME environment" {
    skip "Oracle environment not required for CI"
}

@test "longops.sh uses snake_case function naming" {
    run bash -c "grep -E '^[A-Z][a-z]+\(\)' '$LONGOPS_SCRIPT'"
    [[ "$status" -ne 0 ]]
}

# ------------------------------------------------------------------------------
# Error handling tests
# ------------------------------------------------------------------------------

@test "longops.sh has error handling for invalid arguments" {
    run bash -c "grep -q 'Invalid.*option\\|Unknown.*option' '$LONGOPS_SCRIPT'"
    [[ "$status" -eq 0 ]]
}

@test "longops.sh validates Oracle connection" {
    skip "Oracle connection validation requires Oracle installation"
}

# ------------------------------------------------------------------------------
# Integration tests (conditional on Oracle availability)
# ------------------------------------------------------------------------------

@test "longops.sh gracefully handles missing Oracle environment" {
    # This test verifies the script doesn't crash without Oracle
    # We expect it to exit with error or show proper message
    if [[ -z "$ORACLE_HOME" ]]; then
        run timeout 2 "$LONGOPS_SCRIPT" 2>&1 || true
        # Should not have bash errors
        [[ ! "$output" =~ line\ [0-9]+: ]]
    else
        skip "Oracle environment is available"
    fi
}
