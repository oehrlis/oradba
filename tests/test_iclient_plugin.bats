#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_iclient_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for iclient_plugin.sh (Oracle Instant Client)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_iclient_$$"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/lib/plugins"
    mkdir -p "${TEST_DIR}/test_homes"
    
    # Set ORADBA_BASE for plugins
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/.."
    
    # Create minimal oradba_common.sh stub for logging
    cat > "${TEST_DIR}/lib/oradba_common.sh" <<'EOF'
oradba_log() {
    local level="$1"
    shift
    # Suppress debug logs in tests
    [[ "${level}" == "DEBUG" ]] && return 0
    echo "[${level}] $*" >&2
}
EOF
    
    # Source common functions
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    # Copy plugin to test directory
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/iclient_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# Instant Client Plugin Tests
# ==============================================================================

@test "iclient plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "iclient plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    [[ "${plugin_name}" == "iclient" ]]
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "iclient plugin validates instant client home" {
    # Create mock instant client home
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${ic_home}"
    [ "$status" -eq 0 ]
}

@test "iclient plugin validates versioned instant client" {
    # Create mock instant client with versioned library
    local ic_home="${TEST_DIR}/test_homes/instantclient_21_3"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so.21.1"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${ic_home}"
    [ "$status" -eq 0 ]
}

@test "iclient plugin rejects home without libclntsh" {
    # Create mock home without instant client library
    local fake_home="${TEST_DIR}/test_homes/fake_ic"
    mkdir -p "${fake_home}"
    touch "${fake_home}/some_other_lib.so"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "iclient plugin rejects full client" {
    # Create mock full client (has bin/ subdirectory)
    local client_home="${TEST_DIR}/test_homes/client_19c_ic"
    mkdir -p "${client_home}/bin"
    touch "${client_home}/libclntsh.so"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${client_home}"
    [ "$status" -ne 0 ]
}

@test "iclient plugin rejects database home" {
    # Create mock database home with rdbms (should be rejected)
    local db_home="${TEST_DIR}/test_homes/db_19c_ic"
    mkdir -p "${db_home}/rdbms/admin"
    touch "${db_home}/libclntsh.so.19.8"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${db_home}"
    [ "$status" -ne 0 ]
}

@test "iclient plugin returns available status for readable library" {
    # Create mock instant client home
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so"
    chmod 644 "${ic_home}/libclntsh.so"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_check_status "${ic_home}" ""
    [ "$status" -eq 0 ]
    [ "$output" = "available" ]
}

@test "iclient plugin returns unavailable for missing library" {
    # Create mock instant client home without library
    local ic_home="${TEST_DIR}/test_homes/instantclient_empty"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_check_status "${ic_home}" ""
    [ "$status" -ne 0 ]
    [ "$output" = "unavailable" ]
}

@test "iclient plugin does not show listener" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "iclient plugin discovers no instances" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_discover_instances "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "iclient plugin does not support aliases" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -ne 0 ]
}

@test "iclient plugin gets metadata with version" {
    # Create mock instant client with versioned library
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so.19.8"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_get_metadata "${ic_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"type=instant_client"* ]]
}

@test "iclient plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "iclient plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    local required_functions=(
        "plugin_detect_installation"
        "plugin_validate_home"
        "plugin_adjust_environment"
        "plugin_check_status"
        "plugin_get_metadata"
        "plugin_should_show_listener"
        "plugin_discover_instances"
        "plugin_supports_aliases"
    )
    
    for func in "${required_functions[@]}"; do
        run type "${func}"
        [ "$status" -eq 0 ]
    done
}
