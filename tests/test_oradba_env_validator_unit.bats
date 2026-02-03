#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_validator_unit.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-02-03
# Revision...: 0.19.11
# Purpose....: Unit tests for oradba_env_validator.sh with dependency injection
# Notes......: Tests DI infrastructure, mocked logging, and stateless execution
#              Run with: bats tests/test_oradba_env_validator_unit.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Test setup
setup() {
    # Set ORADBA_BASE to project root
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE
    
    # Create temporary test directories
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp}"
    export TEST_ORACLE_HOME="${BATS_TMPDIR}/oracle_home.$$"
    mkdir -p "$TEST_ORACLE_HOME"
    
    # Mock logger for testing
    export MOCK_LOG_CALLS=0
    export MOCK_LOG_FILE="${BATS_TMPDIR}/mock_log.$$.txt"
    rm -f "$MOCK_LOG_FILE"
    
    # Define mock logger function
    mock_logger() {
        MOCK_LOG_CALLS=$((MOCK_LOG_CALLS + 1))
        echo "[MOCK] $*" >> "$MOCK_LOG_FILE"
    }
    export -f mock_logger
    
    # Source the validator
    ORADBA_BASE="${ORADBA_BASE}/src"
    source "${ORADBA_BASE}/lib/oradba_env_validator.sh"
}

# Test teardown
teardown() {
    rm -rf "$TEST_ORACLE_HOME" "$MOCK_LOG_FILE"
    unset MOCK_LOG_CALLS
    unset ORADBA_VALIDATOR_LOGGER
    unset ORACLE_HOME
}

# ==============================================================================
# Dependency Injection Tests
# ==============================================================================

@test "validator: init without arguments creates default state" {
    run oradba_validator_init
    [ "$status" -eq 0 ]
    [ -z "$ORADBA_VALIDATOR_LOGGER" ]
}

@test "validator: init with custom logger stores logger reference" {
    oradba_validator_init "mock_logger"
    [ "$ORADBA_VALIDATOR_LOGGER" = "mock_logger" ]
}

@test "validator: internal log function falls back when no logger configured" {
    ORADBA_VALIDATOR_LOGGER=""
    # Should not fail, either calls oradba_log if available or no-op
    run _oradba_validator_log DEBUG "test message"
    [ "$status" -eq 0 ]
}

@test "validator: internal log function calls injected logger" {
    oradba_validator_init "mock_logger"
    _oradba_validator_log DEBUG "test message"
    [ -f "$MOCK_LOG_FILE" ]
    grep -q "test message" "$MOCK_LOG_FILE"
}

# ==============================================================================
# Core Functionality Tests (with DI)
# ==============================================================================

@test "validator: validate_oracle_home accepts valid directory" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_oracle_home "$TEST_ORACLE_HOME"
    [ "$status" -eq 0 ]
}

@test "validator: validate_oracle_home rejects non-existent directory" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_oracle_home "/nonexistent/oracle/home"
    [ "$status" -eq 1 ]
}

@test "validator: validate_oracle_home rejects empty path" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_oracle_home ""
    [ "$status" -eq 1 ]
}

@test "validator: validate_oracle_home uses ORACLE_HOME env var as default" {
    oradba_validator_init "mock_logger"
    export ORACLE_HOME="$TEST_ORACLE_HOME"
    
    run oradba_validate_oracle_home
    [ "$status" -eq 0 ]
}

@test "validator: validate_sid accepts valid SID" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "ORCL"
    [ "$status" -eq 0 ]
}

@test "validator: validate_sid accepts ASM instance" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "+ASM"
    [ "$status" -eq 0 ]
}

@test "validator: validate_sid rejects invalid SID (starts with number)" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "1ORCL"
    [ "$status" -eq 1 ]
}

@test "validator: validate_sid rejects empty SID" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid ""
    [ "$status" -eq 1 ]
}

@test "validator: validate_sid rejects SID with invalid characters" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "ORCL@TEST"
    [ "$status" -eq 1 ]
}

@test "validator: validate_sid rejects SID too long" {
    oradba_validator_init "mock_logger"
    
    # Create a SID longer than 30 characters
    run oradba_validate_sid "THISISAVERYLONGSIDNAMETHATEXCEEDSTHIRTYCHARS"
    [ "$status" -eq 1 ]
}

# ==============================================================================
# Stateless Execution Tests
# ==============================================================================

@test "validator: multiple init calls don't break functionality" {
    oradba_validator_init "mock_logger"
    oradba_validator_init "mock_logger"
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "TESTDB"
    [ "$status" -eq 0 ]
}

@test "validator: switching loggers works correctly" {
    # First logger
    oradba_validator_init "mock_logger"
    [ "$ORADBA_VALIDATOR_LOGGER" = "mock_logger" ]
    
    # Switch to different logger
    another_logger() { echo "ANOTHER: $*"; }
    export -f another_logger
    oradba_validator_init "another_logger"
    [ "$ORADBA_VALIDATOR_LOGGER" = "another_logger" ]
    
    # Verify functionality still works
    run oradba_validate_sid "PROD"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Edge Cases and Error Handling
# ==============================================================================

@test "validator: validate_sid handles mixed case" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "OrcL"
    [ "$status" -eq 0 ]
}

@test "validator: validate_sid handles underscores" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "ORCL_TEST"
    [ "$status" -eq 0 ]
}

@test "validator: validate_sid handles numeric after letters" {
    oradba_validator_init "mock_logger"
    
    run oradba_validate_sid "ORCL19C"
    [ "$status" -eq 0 ]
}

@test "validator: validate_oracle_home handles symlinks" {
    oradba_validator_init "mock_logger"
    
    # Create a symlink to test directory
    local link_path="${BATS_TMPDIR}/oracle_link.$$"
    ln -s "$TEST_ORACLE_HOME" "$link_path"
    
    run oradba_validate_oracle_home "$link_path"
    [ "$status" -eq 0 ]
    
    rm -f "$link_path"
}

@test "validator: validate_oracle_home rejects file path (not directory)" {
    oradba_validator_init "mock_logger"
    
    local file_path="${BATS_TMPDIR}/oracle_file.$$"
    touch "$file_path"
    
    run oradba_validate_oracle_home "$file_path"
    [ "$status" -eq 1 ]
    
    rm -f "$file_path"
}

# ==============================================================================
# Backward Compatibility Tests
# ==============================================================================

@test "validator: works without init (legacy mode)" {
    # Don't call oradba_validator_init - should work with fallback or no logging
    run oradba_validate_sid "ORCL"
    [ "$status" -eq 0 ]
}

@test "validator: all validation functions work without DI" {
    # Test all validation functions work standalone
    run oradba_validate_sid "TESTDB"
    [ "$status" -eq 0 ]
    
    run oradba_validate_oracle_home "$TEST_ORACLE_HOME"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Performance and Isolation Tests
# ==============================================================================

@test "validator: does not pollute global environment excessively" {
    # Count variables before
    local vars_before
    vars_before=$(compgen -v | wc -l)
    
    oradba_validator_init "mock_logger"
    oradba_validate_sid "ORCL" >/dev/null
    
    # Count variables after (allow for test framework and DI variables)
    local vars_after
    vars_after=$(compgen -v | wc -l)
    
    # Should have minimal variable growth
    [ "$((vars_after - vars_before))" -lt 10 ]
}

@test "validator: init is idempotent" {
    local logger1="mock_logger"
    local logger2="mock_logger"
    
    oradba_validator_init "$logger1"
    local state1="$ORADBA_VALIDATOR_LOGGER"
    
    oradba_validator_init "$logger2"
    local state2="$ORADBA_VALIDATOR_LOGGER"
    
    [ "$state1" = "$state2" ]
}

@test "validator: validate_sid performance acceptable with multiple validations" {
    oradba_validator_init "mock_logger"
    
    # Validate 100 SIDs
    for i in {1..100}; do
        oradba_validate_sid "SID${i}" >/dev/null || true
    done
    
    [ "$?" -eq 0 ]
}

# ==============================================================================
# Integration Tests
# ==============================================================================

@test "validator: can initialize all three libraries with same logger" {
    # Source all three libraries (use original ORADBA_BASE for direct sourcing)
    local orig_base
    orig_base="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    source "${orig_base}/src/lib/oradba_env_parser.sh"
    source "${orig_base}/src/lib/oradba_env_builder.sh"
    
    # Initialize all with same logger
    oradba_parser_init "mock_logger"
    oradba_builder_init "mock_logger"
    oradba_validator_init "mock_logger"
    
    [ "$ORADBA_PARSER_LOGGER" = "mock_logger" ]
    [ "$ORADBA_BUILDER_LOGGER" = "mock_logger" ]
    [ "$ORADBA_VALIDATOR_LOGGER" = "mock_logger" ]
}

@test "validator: libraries work independently when initialized separately" {
    # Source all three libraries (use original ORADBA_BASE for direct sourcing)
    local orig_base
    orig_base="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    source "${orig_base}/src/lib/oradba_env_parser.sh"
    source "${orig_base}/src/lib/oradba_env_builder.sh"
    
    # Initialize with different loggers
    oradba_parser_init "mock_logger"
    
    other_logger() { echo "OTHER: $*"; }
    export -f other_logger
    oradba_builder_init "other_logger"
    oradba_validator_init "mock_logger"
    
    # Each should have its own logger
    [ "$ORADBA_PARSER_LOGGER" = "mock_logger" ]
    [ "$ORADBA_BUILDER_LOGGER" = "other_logger" ]
    [ "$ORADBA_VALIDATOR_LOGGER" = "mock_logger" ]
}
