#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_database_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for database_plugin.sh (Oracle Database RDBMS)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_database_$$"
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
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/database_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# Database Plugin Tests
# ==============================================================================

@test "database plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "database plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "database" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "database plugin validates database home" {
    # Create mock database home
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/rdbms/admin"
    touch "${db_home}/bin/sqlplus"
    touch "${db_home}/bin/oracle"
    chmod +x "${db_home}/bin/sqlplus"
    chmod +x "${db_home}/bin/oracle"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "${db_home}"
    [ "$status" -eq 0 ]
}

@test "database plugin validates home with oracle binary only" {
    # Create mock database home (only oracle, no sqlplus)
    local db_home="${TEST_DIR}/test_homes/db_minimal"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/rdbms/admin"
    touch "${db_home}/bin/oracle"
    chmod +x "${db_home}/bin/oracle"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "${db_home}"
    [ "$status" -eq 0 ]
}

@test "database plugin rejects home without rdbms directory" {
    # Create mock home without rdbms (like client)
    local client_home="${TEST_DIR}/test_homes/client"
    mkdir -p "${client_home}/bin"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "${client_home}"
    [ "$status" -ne 0 ]
}

@test "database plugin rejects home without bin directory" {
    # Create mock home without bin
    local fake_home="${TEST_DIR}/test_homes/fake_db"
    mkdir -p "${fake_home}/rdbms/admin"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "database plugin rejects home without oracle or sqlplus" {
    # Create mock home with rdbms but no executables
    local fake_home="${TEST_DIR}/test_homes/incomplete_db"
    mkdir -p "${fake_home}/bin"
    mkdir -p "${fake_home}/rdbms/admin"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "database plugin adjust_environment returns unchanged path" {
    # Database homes don't need adjustment
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_adjust_environment "${db_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${db_home}" ]
}

@test "database plugin should show listener" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -eq 0 ]
}

@test "database plugin supports aliases" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -eq 0 ]
}

@test "database plugin gets metadata" {
    # Create mock database home with oracle binary
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/rdbms/admin"
    touch "${db_home}/bin/oracle"
    chmod +x "${db_home}/bin/oracle"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_get_metadata "${db_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"version="* ]]
}

@test "database plugin discovers no instances when none running" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_discover_instances "${db_home}"
    [ "$status" -eq 0 ]
    # Output might be empty if no pmon processes
}

@test "database plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "database plugin check_status returns stopped when no SID provided" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "${db_home}" ""
    [ "$status" -ne 0 ]
    [ "$output" = "stopped" ]
}

@test "database plugin check_status returns stopped for non-running SID" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "${db_home}" "NONEXIST"
    [ "$status" -ne 0 ]
    [ "$output" = "stopped" ]
}

@test "database plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
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
