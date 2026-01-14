#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_logging.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.04
# Revision...: 0.13.1
# Purpose....: BATS tests for unified logging system
# Notes......: Run with: bats test_logging.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup before each test
setup() {
    # Get the directory containing the script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
    
    # Source common library
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    
    # Reset environment for each test
    unset ORADBA_LOG_LEVEL
    unset DEBUG
    unset ORADBA_SHOW_DEPRECATION_WARNINGS
}

# ------------------------------------------------------------------------------
# Test: New Unified oradba_log() Function
# ------------------------------------------------------------------------------

@test "oradba_log() function exists" {
    run type -t oradba_log
    [ "$status" -eq 0 ]
    [[ "$output" == "function" ]]
}

@test "oradba_log INFO outputs to stderr" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Test message' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[INFO\] ]]
    [[ "$output" =~ "Test message" ]]
}

@test "oradba_log INFO includes timestamp" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Test' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

@test "oradba_log WARN outputs to stderr" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log WARN 'Warning message' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[WARN\] ]]
    [[ "$output" =~ "Warning message" ]]
}

@test "oradba_log ERROR outputs to stderr" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log ERROR 'Error message' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "Error message" ]]
}

@test "oradba_log DEBUG outputs to stderr when DEBUG=1" {
    run bash -c "export DEBUG=1 && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Debug message' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[DEBUG\] ]]
    [[ "$output" =~ "Debug message" ]]
}

# ------------------------------------------------------------------------------
# Test: Log Level Filtering
# ------------------------------------------------------------------------------

@test "oradba_log DEBUG is filtered by default (no ORADBA_LOG_LEVEL)" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
}

@test "oradba_log INFO is shown by default" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Should appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Should appear" ]]
}

@test "ORADBA_LOG_LEVEL=DEBUG shows all messages" {
    run bash -c "export ORADBA_LOG_LEVEL=DEBUG && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Debug msg' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Debug msg" ]]
}

@test "ORADBA_LOG_LEVEL=INFO filters DEBUG" {
    run bash -c "export ORADBA_LOG_LEVEL=INFO && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
}

@test "ORADBA_LOG_LEVEL=WARN filters INFO and DEBUG" {
    run bash -c "export ORADBA_LOG_LEVEL=WARN && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
    
    run bash -c "export ORADBA_LOG_LEVEL=WARN && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log WARN 'Should appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Should appear" ]]
}

@test "ORADBA_LOG_LEVEL=ERROR filters everything except ERROR" {
    run bash -c "export ORADBA_LOG_LEVEL=ERROR && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log WARN 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
    
    run bash -c "export ORADBA_LOG_LEVEL=ERROR && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log ERROR 'Should appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Should appear" ]]
}

@test "log level is case-insensitive" {
    run bash -c "export ORADBA_LOG_LEVEL=debug && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Test' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test" ]]
}

# ------------------------------------------------------------------------------
# Test: DEBUG=1 Backward Compatibility
# ------------------------------------------------------------------------------

@test "DEBUG=1 enables DEBUG level" {
    run bash -c "export DEBUG=1 && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Debug via DEBUG=1' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Debug via DEBUG=1" ]]
}

@test "DEBUG=1 overrides ORADBA_LOG_LEVEL" {
    run bash -c "export ORADBA_LOG_LEVEL=ERROR DEBUG=1 && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Should appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Should appear" ]]
}

@test "DEBUG=0 does not enable debug" {
    run bash -c "export DEBUG=0 && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log DEBUG 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
}

# ------------------------------------------------------------------------------
# Test: Deprecated Logging Functions (Backward Compatibility)
# ------------------------------------------------------------------------------

@test "log_info() wrapper still works" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_info 'Info message' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[INFO\] ]]
    [[ "$output" =~ "Info message" ]]
}

@test "log_warn() wrapper still works" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_warn 'Warn message' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[WARN\] ]]
    [[ "$output" =~ "Warn message" ]]
}

@test "log_error() wrapper still works" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_error 'Error message' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "Error message" ]]
}

@test "log_debug() wrapper still works" {
    run bash -c "export DEBUG=1 && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_debug 'Debug message' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[DEBUG\] ]]
    [[ "$output" =~ "Debug message" ]]
}

# ------------------------------------------------------------------------------
# Test: Deprecation Warnings
# ------------------------------------------------------------------------------

@test "deprecation warnings disabled by default" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_info 'Test' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "deprecated" ]]
}

@test "deprecation warnings shown when enabled" {
    run bash -c "export ORADBA_SHOW_DEPRECATION_WARNINGS=true && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && log_info 'Test' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "deprecated" ]]
    [[ "$output" =~ "log_info" ]]
    [[ "$output" =~ "oradba_log INFO" ]]
}

@test "deprecation warning shown only once per function" {
    script='
    export ORADBA_SHOW_DEPRECATION_WARNINGS=true
    source '"${PROJECT_ROOT}"'/src/lib/oradba_common.sh
    log_info "First call"
    log_info "Second call"
    log_info "Third call"
    '
    run bash -c "$script" 2>&1
    [ "$status" -eq 0 ]
    
    # Count how many times "deprecated" appears in output
    deprecated_count=$(echo "$output" | grep -c "deprecated" || true)
    [ "$deprecated_count" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Test: Message Formatting
# ------------------------------------------------------------------------------

@test "oradba_log() handles multiple arguments" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Message' 'with' 'multiple' 'parts' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Message with multiple parts" ]]
}

@test "oradba_log() preserves variable expansion" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && VAR='test value' && oradba_log INFO \"Variable: \$VAR\" 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Variable: test value" ]]
}

@test "oradba_log() handles special characters" {
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && oradba_log INFO 'Test \$PATH and \${HOME}' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test" ]]
}

# ------------------------------------------------------------------------------
# Test: Integration with Existing Code
# ------------------------------------------------------------------------------

@test "oradba_log() works with verify_oracle_env" {
    run bash -c "unset ORACLE_SID ORACLE_HOME && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && verify_oracle_env 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "Missing required Oracle environment variables" ]]
}

@test "deprecated functions work in oradba_common.sh context" {
    # Test that existing oradba_common.sh functions using log_* still work
    run bash -c "unset ORACLE_HOME && source ${PROJECT_ROOT}/src/lib/oradba_common.sh && get_oracle_version 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" =~ \[ERROR\] ]]
    [[ "$output" =~ "ORACLE_HOME not set" ]]
}
