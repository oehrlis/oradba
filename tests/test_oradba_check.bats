#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_check.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.7.1
# Purpose....: BATS tests for oradba_check.sh system prerequisites script
# Notes......: Tests system checks, Oracle environment detection, and validation
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    CHECK_SCRIPT="${PROJECT_ROOT}/src/bin/oradba_check.sh"
    
    # Read expected version from VERSION file
    if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
        EXPECTED_VERSION=$(head -1 "${PROJECT_ROOT}/VERSION")
    else
        EXPECTED_VERSION="0.0.0"
    fi
    
    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Basic Script Tests
# ============================================================================

@test "oradba_check.sh exists and is executable" {
    [ -f "$CHECK_SCRIPT" ]
    [ -x "$CHECK_SCRIPT" ]
}

@test "oradba_check.sh has correct shebang" {
    head -1 "$CHECK_SCRIPT" | grep -q "#!/usr/bin/env bash"
}

@test "oradba_check.sh --help displays usage" {
    run "$CHECK_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA System Check" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
}

@test "oradba_check.sh --version displays version" {
    run "$CHECK_SCRIPT" --version
    [ "$status" -eq 0 ]
    # Check that output contains the expected version from VERSION file
    [[ "$output" =~ ${EXPECTED_VERSION} ]]
}

@test "oradba_check.sh handles invalid option" {
    run "$CHECK_SCRIPT" --invalid-option
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Unknown option" ]]
}

# ============================================================================
# Functionality Tests
# ============================================================================

@test "oradba_check.sh runs basic check successfully" {
    run "$CHECK_SCRIPT" --quiet
    [ "$status" -eq 0 ]
}

@test "oradba_check.sh checks system tools" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "System Tools" ]]
    [[ "$output" =~ "bash" ]]
    [[ "$output" =~ "tar" ]]
    [[ "$output" =~ "awk" ]]
}

@test "oradba_check.sh checks disk space" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Disk Space" ]]
    [[ "$output" =~ "Available:" ]]
}

@test "oradba_check.sh --dir option works" {
    run "$CHECK_SCRIPT" --dir "$TEST_TEMP_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Disk Space" ]]
}

@test "oradba_check.sh displays system information" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "System Information" ]]
    [[ "$output" =~ "OS Type:" ]]
}

@test "oradba_check.sh checks optional tools" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Optional Tools" ]]
}

@test "oradba_check.sh --quiet suppresses non-critical output" {
    run "$CHECK_SCRIPT" --quiet
    [ "$status" -eq 0 ]
    # Should not contain informational sections
    [[ ! "$output" =~ "System Information" ]]
}

@test "oradba_check.sh --verbose shows additional details" {
    run "$CHECK_SCRIPT" --verbose
    [ "$status" -eq 0 ]
    [[ "$output" =~ "System Information" ]]
}

@test "oradba_check.sh displays summary" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Summary" ]]
    [[ "$output" =~ "Passed:" ]]
    [[ "$output" =~ "Failed:" ]]
    [[ "$output" =~ "Warnings:" ]]
}

# ============================================================================
# Oracle Environment Tests
# ============================================================================

@test "oradba_check.sh handles missing Oracle environment gracefully" {
    # Unset Oracle variables
    unset ORACLE_HOME ORACLE_BASE ORACLE_SID
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Oracle Environment" ]]
}

@test "oradba_check.sh checks Oracle tools when ORACLE_HOME set" {
    # Only run if ORACLE_HOME exists
    if [[ -n "$ORACLE_HOME" ]] && [[ -d "$ORACLE_HOME" ]]; then
        run "$CHECK_SCRIPT"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "Oracle Tools" ]]
    else
        skip "ORACLE_HOME not set"
    fi
}

# ============================================================================
# OraDBA Installation Tests
# ============================================================================

@test "oradba_check.sh checks for OraDBA installation" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA Installation" ]]
}

@test "oradba_check.sh detects existing OraDBA installation" {
    # Create a mock installation
    mkdir -p "${TEST_TEMP_DIR}/oradba"/{bin,lib,sql,etc}
    
    # Create .install_info
    cat > "${TEST_TEMP_DIR}/oradba/.install_info" << EOF
install_date=2025-12-17T10:00:00Z
install_version=0.7.0
install_method=embedded
install_user=testuser
install_prefix=${TEST_TEMP_DIR}/oradba
EOF
    
    run "$CHECK_SCRIPT" --dir "${TEST_TEMP_DIR}/oradba"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA directory exists" ]]
    [[ "$output" =~ \.install_info\ found ]]
}

# ============================================================================
# Exit Code Tests
# ============================================================================

@test "oradba_check.sh exits 0 when all checks pass" {
    run "$CHECK_SCRIPT" --quiet
    [ "$status" -eq 0 ]
}

@test "oradba_check.sh exits 2 for invalid arguments" {
    run "$CHECK_SCRIPT" --invalid
    [ "$status" -eq 2 ]
}

# ============================================================================
# Output Format Tests
# ============================================================================

@test "oradba_check.sh uses color codes for terminal output" {
    # Check that ANSI color codes are present when running in terminal
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    # Should have color-coded symbols (✓ ✗ ⚠ ℹ)
    [[ "$output" =~ "✓" ]] || [[ "$output" =~ "✗" ]] || [[ "$output" =~ "⚠" ]] || [[ "$output" =~ "ℹ" ]]
}

@test "oradba_check.sh displays banner" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA System Prerequisites Check" ]]
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "oradba_check.sh can check non-existent directory" {
    run "$CHECK_SCRIPT" --dir "/nonexistent/path/to/oradba"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not installed" ]] || [[ "$output" =~ "Checking:" ]]
}

@test "oradba_check.sh validates all required tools exist" {
    run "$CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "grep" ]]
    [[ "$output" =~ "sed" ]]
    [[ "$output" =~ "awk" ]]
    [[ "$output" =~ "find" ]]
}
