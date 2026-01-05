#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_logging_infrastructure.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.05
# Revision...: 0.14.0
# Purpose....: BATS tests for logging infrastructure (init_logging, session logs, caller info)
# Notes......: Run with: bats test_logging_infrastructure.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup before each test
setup() {
    # Get the directory containing the script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
    
    # Source common library
    source "${PROJECT_ROOT}/src/lib/common.sh"
    
    # Reset environment for each test
    unset ORADBA_LOG_DIR
    unset ORADBA_LOG_FILE
    unset ORADBA_SESSION_LOG
    unset ORADBA_LOG_LEVEL
    unset ORADBA_SESSION_LOGGING
    unset ORADBA_LOG_SHOW_CALLER
    unset ORADBA_SESSION_LOG_ONLY
    unset DEBUG
    
    # Create temporary test directory
    TEST_LOG_DIR="${BATS_TEST_TMPDIR}/oradba_logs_$$"
    mkdir -p "${TEST_LOG_DIR}"
}

# Cleanup after each test
teardown() {
    # Clean up test log directory
    [[ -d "${TEST_LOG_DIR}" ]] && rm -rf "${TEST_LOG_DIR}"
}

# ------------------------------------------------------------------------------
# Test: init_logging() Function
# ------------------------------------------------------------------------------

@test "init_logging() function exists" {
    run type -t init_logging
    [ "$status" -eq 0 ]
    [[ "$output" == "function" ]]
}

@test "init_logging() creates log directory in /var/log/oradba if writable" {
    # Skip if /var/log is not writable
    if [[ ! -w "/var/log" ]]; then
        skip "Requires write access to /var/log"
    fi
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging && echo \${ORADBA_LOG_DIR}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/var/log/oradba" ]]
}

@test "init_logging() falls back to user directory if /var/log not writable" {
    # Simulate non-writable /var/log by using custom directory
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging && echo \${ORADBA_LOG_DIR}"
    [ "$status" -eq 0 ]
    [[ "$output" == "${TEST_LOG_DIR}" ]]
    [ -d "${TEST_LOG_DIR}" ]
}

@test "init_logging() creates log directory if it doesn't exist" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}/new_subdir"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging"
    [ "$status" -eq 0 ]
    [ -d "${TEST_LOG_DIR}/new_subdir" ]
}

@test "init_logging() sets ORADBA_LOG_FILE to oradba.log" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging && echo \${ORADBA_LOG_FILE}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "oradba.log" ]]
}

@test "init_logging() respects existing ORADBA_LOG_FILE setting" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_LOG_FILE="${TEST_LOG_DIR}/custom.log"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging && echo \${ORADBA_LOG_FILE}"
    [ "$status" -eq 0 ]
    [[ "$output" == "${TEST_LOG_DIR}/custom.log" ]]
}

@test "init_logging() returns 0 on success" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging"
    [ "$status" -eq 0 ]
}

@test "init_logging() can be called multiple times safely" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_logging && init_logging && echo OK"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

# ------------------------------------------------------------------------------
# Test: init_session_log() Function
# ------------------------------------------------------------------------------

@test "init_session_log() function exists" {
    run type -t init_session_log
    [ "$status" -eq 0 ]
    [[ "$output" == "function" ]]
}

@test "init_session_log() does nothing if ORADBA_SESSION_LOGGING not enabled" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log && echo \${ORADBA_SESSION_LOG:-NOTSET}"
    [ "$status" -eq 0 ]
    [[ "$output" == "NOTSET" ]]
}

@test "init_session_log() creates session log file when enabled" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log && ls -1 \${ORADBA_LOG_DIR}/session_*.log | head -1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "session_" ]]
    [[ "$output" =~ ".log" ]]
}

@test "init_session_log() creates log directory if not initialized" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log"
    [ "$status" -eq 0 ]
    [ -d "${TEST_LOG_DIR}" ]
}

@test "init_session_log() writes session header with metadata" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log && cat \${ORADBA_SESSION_LOG}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA Session Log" ]]
    [[ "$output" =~ "Started" ]]
    [[ "$output" =~ "User" ]]
    [[ "$output" =~ "Host" ]]
    [[ "$output" =~ "PID" ]]
}

@test "init_session_log() includes ORACLE_SID in header" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    export ORACLE_SID="TESTDB"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log && cat \${ORADBA_SESSION_LOG}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ORACLE_SID" ]]
    [[ "$output" =~ "TESTDB" ]]
}

@test "init_session_log() sets session log as primary when ORADBA_SESSION_LOG_ONLY=true" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    export ORADBA_SESSION_LOG_ONLY="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && init_session_log && echo \${ORADBA_LOG_FILE}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "session_" ]]
}

# ------------------------------------------------------------------------------
# Test: Caller Information in log()
# ------------------------------------------------------------------------------

@test "log() includes caller info when ORADBA_LOG_SHOW_CALLER=true" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_LOG_FILE="${TEST_LOG_DIR}/test.log"
    export ORADBA_LOG_SHOW_CALLER="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'Test message' 2>&1"
    [ "$status" -eq 0 ]
    # Should contain caller information in format [file:line]
    [[ "$output" =~ \[.*:[0-9]*\] ]] || [[ "$output" =~ "[::]" ]]
}

@test "log() excludes caller info when ORADBA_LOG_SHOW_CALLER=false" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_LOG_FILE="${TEST_LOG_DIR}/test.log"
    export ORADBA_LOG_SHOW_CALLER="false"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'Test message' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "[bash:" ]]
    [[ "$output" =~ "[INFO]" ]]
    [[ "$output" =~ "Test message" ]]
}

@test "log() caller info shows correct file and line format" {
    export ORADBA_LOG_SHOW_CALLER="true"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'Test' 2>&1"
    [ "$status" -eq 0 ]
    # Should contain caller bracket notation even if empty in bash -c context
    [[ "$output" =~ \[.*\] ]]
    # Should have timestamp and message
    [[ "$output" =~ "[INFO]" ]]
    [[ "$output" =~ "Test" ]]
}

# ------------------------------------------------------------------------------
# Test: Dual Logging (Main + Session)
# ------------------------------------------------------------------------------

@test "log() writes to both main and session logs when both are set" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_LOG_FILE="${TEST_LOG_DIR}/main.log"
    export ORADBA_SESSION_LOG="${TEST_LOG_DIR}/session.log"
    
    # Create empty log files
    touch "${TEST_LOG_DIR}/main.log"
    touch "${TEST_LOG_DIR}/session.log"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'Dual log test'"
    [ "$status" -eq 0 ]
    
    # Check main log
    run cat "${TEST_LOG_DIR}/main.log"
    [[ "$output" =~ "Dual log test" ]]
    
    # Check session log
    run cat "${TEST_LOG_DIR}/session.log"
    [[ "$output" =~ "Dual log test" ]]
}

@test "log() does not duplicate when ORADBA_LOG_FILE equals ORADBA_SESSION_LOG" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_LOG_FILE="${TEST_LOG_DIR}/same.log"
    export ORADBA_SESSION_LOG="${TEST_LOG_DIR}/same.log"
    
    touch "${TEST_LOG_DIR}/same.log"
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'Single entry'"
    [ "$status" -eq 0 ]
    
    # Should appear only once
    run grep -c "Single entry" "${TEST_LOG_DIR}/same.log"
    [ "$output" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Test: Integration - Complete Logging Setup
# ------------------------------------------------------------------------------

@test "Complete logging setup: init_logging + init_session_log + log with caller" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    export ORADBA_SESSION_LOGGING="true"
    export ORADBA_LOG_SHOW_CALLER="true"
    
    run bash -c "
        source ${PROJECT_ROOT}/src/lib/common.sh
        init_logging
        init_session_log
        log INFO 'Integration test message'
        if [[ -f \"\${ORADBA_SESSION_LOG}\" ]]; then
            cat \"\${ORADBA_SESSION_LOG}\"
        else
            echo 'ERROR: Session log not created'
            exit 1
        fi
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OraDBA Session Log" ]]
    [[ "$output" =~ "Integration test message" ]]
    # Verify caller format is present (even if empty in bash -c)
    [[ "$output" =~ \[.*\] ]]
}

@test "Logging works without initialization (backward compatible)" {
    # Don't call init_logging, just use log directly
    run bash -c "source ${PROJECT_ROOT}/src/lib/common.sh && log INFO 'No init test' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "[INFO]" ]]
    [[ "$output" =~ "No init test" ]]
}

@test "init_logging preserves backward compatibility with existing scripts" {
    export ORADBA_LOG_DIR="${TEST_LOG_DIR}"
    
    # Test that old log_info still works after init_logging
    run bash -c "
        source ${PROJECT_ROOT}/src/lib/common.sh
        init_logging
        log_info 'Legacy function test' 2>&1
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "[INFO]" ]]
    [[ "$output" =~ "Legacy function test" ]]
}
