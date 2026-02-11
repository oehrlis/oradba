#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_plugin_debug.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: BATS tests for plugin debug facilities
# Notes......: Tests TRACE log level, ORADBA_PLUGIN_DEBUG, sanitization
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup before each test
setup() {
    # Get the directory containing the script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    
    # Source common library
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    
    # Reset environment for each test
    unset ORADBA_LOG_LEVEL
    unset ORADBA_PLUGIN_DEBUG
    unset DEBUG
    
    # Create temporary test directory
    TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/oradba_plugin_debug_$$"
    mkdir -p "${TEST_TEMP_DIR}"
}

# Cleanup after each test
teardown() {
    # Clean up test directory
    [[ -d "${TEST_TEMP_DIR}" ]] && rm -rf "${TEST_TEMP_DIR}"
}

# ------------------------------------------------------------------------------
# Test: TRACE Log Level
# ------------------------------------------------------------------------------

@test "TRACE log level is supported by oradba_log" {
    run bash -c "export ORADBA_LOG_LEVEL=TRACE && source ${ORADBA_BASE}/lib/oradba_common.sh && oradba_log TRACE 'Trace message' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[TRACE\] ]]
    [[ "$output" =~ "Trace message" ]]
}

@test "TRACE is finer than DEBUG" {
    # TRACE should show when log level is TRACE
    run bash -c "export ORADBA_LOG_LEVEL=TRACE && source ${ORADBA_BASE}/lib/oradba_common.sh && oradba_log TRACE 'Should appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Should appear" ]]
    
    # TRACE should NOT show when log level is DEBUG
    run bash -c "export ORADBA_LOG_LEVEL=DEBUG && source ${ORADBA_BASE}/lib/oradba_common.sh && oradba_log TRACE 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
}

@test "DEBUG shows when TRACE level is set" {
    run bash -c "export ORADBA_LOG_LEVEL=TRACE && source ${ORADBA_BASE}/lib/oradba_common.sh && oradba_log DEBUG 'Debug at TRACE level' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Debug at TRACE level" ]]
}

@test "TRACE is filtered by default" {
    run bash -c "source ${ORADBA_BASE}/lib/oradba_common.sh && oradba_log TRACE 'Should not appear' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Should not appear" ]]
}

# ------------------------------------------------------------------------------
# Test: Helper Functions
# ------------------------------------------------------------------------------

@test "is_plugin_debug_enabled returns 0 when ORADBA_PLUGIN_DEBUG=true" {
    export ORADBA_PLUGIN_DEBUG=true
    run is_plugin_debug_enabled
    [ "$status" -eq 0 ]
}

@test "is_plugin_debug_enabled returns 0 when ORADBA_LOG_LEVEL=DEBUG" {
    export ORADBA_LOG_LEVEL=DEBUG
    run is_plugin_debug_enabled
    [ "$status" -eq 0 ]
}

@test "is_plugin_debug_enabled returns 0 when ORADBA_LOG_LEVEL=TRACE" {
    export ORADBA_LOG_LEVEL=TRACE
    run is_plugin_debug_enabled
    [ "$status" -eq 0 ]
}

@test "is_plugin_debug_enabled returns 0 when DEBUG=1" {
    export DEBUG=1
    run is_plugin_debug_enabled
    [ "$status" -eq 0 ]
}

@test "is_plugin_debug_enabled returns 1 when debug not enabled" {
    run is_plugin_debug_enabled
    [ "$status" -eq 1 ]
}

@test "is_plugin_trace_enabled returns 0 when ORADBA_LOG_LEVEL=TRACE" {
    export ORADBA_LOG_LEVEL=TRACE
    run is_plugin_trace_enabled
    [ "$status" -eq 0 ]
}

@test "is_plugin_trace_enabled returns 1 when log level is DEBUG" {
    export ORADBA_LOG_LEVEL=DEBUG
    run is_plugin_trace_enabled
    [ "$status" -eq 1 ]
}

@test "is_plugin_trace_enabled returns 1 by default" {
    run is_plugin_trace_enabled
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Test: Sanitization Function
# ------------------------------------------------------------------------------

@test "sanitize_sensitive_data masks sqlplus passwords" {
    run sanitize_sensitive_data "sqlplus user/password@db"
    [ "$status" -eq 0 ]
    [[ "$output" =~ sqlplus\ user/\*\*\*@db ]]
    [[ ! "$output" =~ "password" ]]
}

@test "sanitize_sensitive_data masks rman passwords" {
    run sanitize_sensitive_data "rman target user/password"
    [ "$status" -eq 0 ]
    [[ "$output" =~ rman\ target\ user/\*\*\* ]]
    [[ ! "$output" =~ "password" ]]
}

@test "sanitize_sensitive_data masks password= patterns" {
    run sanitize_sensitive_data "connect password=secret123"
    [ "$status" -eq 0 ]
    [[ "$output" =~ password=\*\*\* ]]
    [[ ! "$output" =~ "secret123" ]]
}

@test "sanitize_sensitive_data masks pwd= patterns" {
    run sanitize_sensitive_data "auth pwd=mypass"
    [ "$status" -eq 0 ]
    [[ "$output" =~ pwd=\*\*\* ]]
    [[ ! "$output" =~ "mypass" ]]
}

@test "sanitize_sensitive_data masks PASSWORD environment variables" {
    run sanitize_sensitive_data 'export PASSWORD="secret"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ PASSWORD=\"\*\*\*\" ]]
    [[ ! "$output" =~ "secret" ]]
}

@test "sanitize_sensitive_data preserves non-sensitive text" {
    run sanitize_sensitive_data "echo 'Hello World'"
    [ "$status" -eq 0 ]
    [[ "$output" == "echo 'Hello World'" ]]
}

# ------------------------------------------------------------------------------
# Test: Plugin Debug Output (Integration)
# ------------------------------------------------------------------------------

@test "plugin debug shows call details when ORADBA_PLUGIN_DEBUG=true" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_get_config_section() {
    echo "test_section"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_PLUGIN_DEBUG=true
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'get_config_section' 'NOARGS' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin call:" ]]
    [[ "$output" =~ "plugin=testdebug" ]]
    [[ "$output" =~ "function=get_config_section" ]]
}

@test "plugin debug shows environment snapshot when ORADBA_LOG_LEVEL=DEBUG" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_check_status() {
    echo "running"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_LOG_LEVEL=DEBUG
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'check_status' '/fake/oracle/home' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin env:" ]]
    [[ "$output" =~ "ORACLE_HOME=/fake/oracle/home" ]]
}

@test "plugin debug shows exit code when enabled" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_check_status() {
    echo "running"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_LOG_LEVEL=DEBUG
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'check_status' '/fake/oracle/home' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin exit:" ]]
    [[ "$output" =~ "code=0" ]]
}

@test "plugin trace shows stdout when ORADBA_LOG_LEVEL=TRACE" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_get_metadata() {
    echo "version=19.0.0"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_LOG_LEVEL=TRACE
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'get_metadata' '/fake/oracle/home' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin stdout:" ]]
    [[ "$output" =~ version=19.0.0 ]]
}

@test "plugin debug does not show when disabled" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_get_config_section() {
    echo "test_section"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    # No debug flags set
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'get_config_section' 'NOARGS' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Plugin call:" ]]
    [[ ! "$output" =~ "Plugin env:" ]]
    [[ ! "$output" =~ "Plugin exit:" ]]
}

# ------------------------------------------------------------------------------
# Test: Sanitization in Plugin Debug
# ------------------------------------------------------------------------------

@test "plugin debug sanitizes sensitive data in extra_arg" {
    # Create a simple test plugin
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_check_status() {
    local oracle_home="$1"
    local instance="$2"
    echo "running"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_PLUGIN_DEBUG=true
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'check_status' '/fake/oracle/home' 'result' 'sys/password@db' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ extra_arg=sys/\*\*\*@db ]]
    [[ ! "$output" =~ "password" ]]
}

@test "plugin trace sanitizes stdout output" {
    # Create a simple test plugin that outputs sensitive data
    local plugin_dir="${TEST_TEMP_DIR}/lib/plugins"
    mkdir -p "${plugin_dir}"
    cat > "${plugin_dir}/testdebug_plugin.sh" <<'EOF'
plugin_get_metadata() {
    echo "connection=user/secret@db"
    return 0
}
EOF
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORADBA_LOG_LEVEL=TRACE
    
    run bash -c "source ${PROJECT_ROOT}/src/lib/oradba_common.sh && execute_plugin_function_v2 'testdebug' 'get_metadata' '/fake/oracle/home' 'result' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plugin stdout:" ]]
    [[ "$output" =~ connection=user/\*\*\*@db ]]
    [[ ! "$output" =~ "secret" ]]
}
