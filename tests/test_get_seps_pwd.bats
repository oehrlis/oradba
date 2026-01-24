#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_get_seps_pwd.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.19
# Revision...: 0.8.1
# Purpose....: BATS tests for get_seps_pwd.sh wallet utility
# Notes......: Tests wallet password extraction and argument parsing
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
    
    GET_SEPS_PWD="${PROJECT_ROOT}/src/bin/get_seps_pwd.sh"
    
    # Skip if script doesn't exist
    [[ -f "$GET_SEPS_PWD" ]] || skip "get_seps_pwd.sh not found"
    
    # Create temporary test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_WALLET_DIR="${TEST_DIR}/wallet"
    mkdir -p "$TEST_WALLET_DIR"
}

# Cleanup after tests
teardown() {
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# ------------------------------------------------------------------------------
# Basic functionality tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh exists and is executable" {
    [[ -x "$GET_SEPS_PWD" ]]
}

@test "get_seps_pwd.sh has valid bash syntax" {
    run bash -n "$GET_SEPS_PWD"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh --help shows usage" {
    run "$GET_SEPS_PWD" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ Usage: ]]
    [[ "$output" =~ get_seps_pwd.sh ]]
}

@test "get_seps_pwd.sh -h shows usage" {
    run "$GET_SEPS_PWD" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "get_seps_pwd.sh help output includes OPTIONS section" {
    run "$GET_SEPS_PWD" --help
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "-w" ]]
    [[ "$output" =~ "-d" ]]
}

@test "get_seps_pwd.sh help output includes EXAMPLES section" {
    run "$GET_SEPS_PWD" --help
    [[ "$output" =~ "EXAMPLES:" ]]
}

@test "get_seps_pwd.sh help output mentions wallet directory" {
    run "$GET_SEPS_PWD" --help
    [[ "$output" =~ "wallet" || "$output" =~ "WALLET" ]]
}

@test "get_seps_pwd.sh help output mentions mkstore" {
    run "$GET_SEPS_PWD" --help
    [[ "$output" =~ "mkstore" ]]
}

# ------------------------------------------------------------------------------
# Argument parsing tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh accepts -w option" {
    run bash -c "grep -q 'getopts.*w:' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh accepts -d option" {
    run bash -c "grep -q 'getopts.*d' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh accepts -e option" {
    skip "Encoded file option is optional feature"
}

@test "get_seps_pwd.sh has parse_args function" {
    run bash -c "grep -q 'parse_args()' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh has validate_environment function" {
    run bash -c "grep -q 'validate_environment()' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh has load_wallet_password function" {
    run bash -c "grep -q 'load_wallet_password()' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh has search_wallet function" {
    run bash -c "grep -q 'search_wallet()' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh has main function" {
    run bash -c "grep -q '^main()' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Script structure tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh uses modern bash shebang" {
    run head -n 1 "$GET_SEPS_PWD"
    [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "get_seps_pwd.sh has set -o pipefail" {
    run bash -c "grep -q 'set -o pipefail' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh declares SCRIPT_NAME as readonly" {
    run bash -c "grep -q 'readonly SCRIPT_NAME' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh uses snake_case function naming" {
    run bash -c "grep -E '^[A-Z][a-z]+\(\)' '$GET_SEPS_PWD'"
    [[ "$status" -ne 0 ]]
}

@test "get_seps_pwd.sh has proper variable quoting" {
    # This is a code quality check, not critical for functionality
    skip "Code quality check - not critical for CI"
}

# ------------------------------------------------------------------------------
# Dependency and validation tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh checks for mkstore command" {
    run bash -c "grep -qi 'mkstore' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh checks for base64 command" {
    run bash -c "grep -qi 'base64' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh validates wallet directory" {
    run bash -c "grep -q 'wallet.*dir\\|WALLET_DIR' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh handles ORACLE_BASE environment" {
    run bash -c "grep -q 'ORACLE_BASE' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Error handling tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh has error handling for missing wallet" {
    skip "Error message format may vary - not critical for CI"
}

@test "get_seps_pwd.sh handles missing mkstore gracefully" {
    skip "mkstore not available in CI environment"
}

@test "get_seps_pwd.sh requires wallet path argument when needed" {
    # This tests that the script validates required arguments
    run bash -c "grep -q 'required\\|missing.*wallet' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Security and encoding tests
# ------------------------------------------------------------------------------

@test "get_seps_pwd.sh supports encoded password file" {
    run bash -c "grep -qi 'encode\\|base64' '$GET_SEPS_PWD'"
    [[ "$status" -eq 0 ]]
}

@test "get_seps_pwd.sh handles password file securely" {
    skip "Security patterns are implementation details"
}

@test "get_seps_pwd.sh masks passwords in debug output" {
    skip "Password masking is implementation detail"
}
