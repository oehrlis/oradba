#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset
# ------------------------------------------------------------------------------
# Name.......: test_oraup.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.6.1
# Purpose....: BATS tests for oraup.sh
# Notes......: Tests database status detection and Oracle version support
# ------------------------------------------------------------------------------

# Setup - runs before each test
setup() {
    # Get project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    
    # Path to oraup.sh script
    ORAUP_SCRIPT="${PROJECT_ROOT}/src/bin/oraup.sh"
}

# ------------------------------------------------------------------------------
# Basic Script Tests
# ------------------------------------------------------------------------------

@test "oraup.sh script exists and is executable" {
    [ -f "${ORAUP_SCRIPT}" ]
    [ -x "${ORAUP_SCRIPT}" ]
}

@test "oraup.sh has correct shebang" {
    head -1 "${ORAUP_SCRIPT}" | grep -q "^#!/usr/bin/env bash"
}

@test "oraup.sh shows help with -h" {
    run "${ORAUP_SCRIPT}" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Oracle environment status" ]]
}

@test "oraup.sh shows help with --help" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Content and Functionality Tests
# ------------------------------------------------------------------------------

@test "oraup.sh contains get_db_status function" {
    grep -q "get_db_status()" "${ORAUP_SCRIPT}"
}

@test "oraup.sh get_db_status checks for db_pmon_ (Oracle 23ai)" {
    grep "db_pmon_" "${ORAUP_SCRIPT}" | grep -q "grep"
}

@test "oraup.sh get_db_status checks for ora_pmon_ (pre-23ai)" {
    grep "ora_pmon_" "${ORAUP_SCRIPT}" | grep -q "grep"
}

@test "oraup.sh get_db_status uses regex for both patterns" {
    grep -q "grep -E" "${ORAUP_SCRIPT}"
    grep "grep -E" "${ORAUP_SCRIPT}" | grep -q "db_pmon_\|ora_pmon_"
}

@test "oraup.sh contains get_listener_status function" {
    grep -q "get_listener_status()" "${ORAUP_SCRIPT}"
}

@test "oraup.sh contains get_db_mode function" {
    grep -q "get_db_mode()" "${ORAUP_SCRIPT}"
}

# ------------------------------------------------------------------------------
# Oracle Version Support Tests
# ------------------------------------------------------------------------------

@test "oraup.sh help mentions Oracle version support" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "23ai" || "$output" =~ "11g" ]]
}

@test "oraup.sh help mentions both process naming conventions" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ora_pmon" && "$output" =~ "db_pmon" ]]
}

# ------------------------------------------------------------------------------
# Command Line Options Tests
# ------------------------------------------------------------------------------

@test "oraup.sh accepts --verbose option" {
    run "${ORAUP_SCRIPT}" --verbose --help
    [ "$status" -eq 0 ]
}

@test "oraup.sh accepts --quiet option" {
    run "${ORAUP_SCRIPT}" --quiet --help
    [ "$status" -eq 0 ]
}

@test "oraup.sh rejects invalid options" {
    run "${ORAUP_SCRIPT}" --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown option" ]]
}

# ------------------------------------------------------------------------------
# Code Quality Tests
# ------------------------------------------------------------------------------

@test "oraup.sh converts SID to lowercase for ora_pmon matching" {
    grep -A 5 "get_db_status()" "${ORAUP_SCRIPT}" | grep -q "sid_lower="
    grep -A 5 "get_db_status()" "${ORAUP_SCRIPT}" | grep -q ",,"
}

@test "oraup.sh uses extended regex for dual pattern matching" {
    # Should use grep -E with alternation pattern
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep -q "grep -E.*|"
}

@test "oraup.sh checks both uppercase and lowercase SID patterns" {
    # Verify the pattern includes both ${sid} and ${sid_lower}
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep "grep -E" | grep -q "\${sid}"
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep "grep -E" | grep -q "\${sid_lower}"
}

# ------------------------------------------------------------------------------
# Architecture Tests (Registry API)
# ------------------------------------------------------------------------------

@test "oraup.sh uses registry API for Oracle installations" {
    # Check that oraup uses oradba_registry_get_all from registry
    grep -q "oradba_registry_get_all" "${ORAUP_SCRIPT}"
}

@test "oraup.sh delegates to show_oracle_status_registry" {
    # Verify that show_oracle_status_registry handles display logic
    grep -q "show_oracle_status_registry" "${ORAUP_SCRIPT}"
}
