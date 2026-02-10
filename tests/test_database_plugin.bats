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
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    
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
    cp "${ORADBA_BASE}/lib/plugins/database_plugin.sh" "${TEST_DIR}/lib/plugins/"
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
    # Version may be omitted if not available (no sentinel strings)
    # Just verify metadata returns successfully with edition info
    [[ "$output" == *"edition="* ]]
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
    mkdir -p "${db_home}/bin"
    touch "${db_home}/bin/oracle"
    chmod +x "${db_home}/bin/oracle"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "${db_home}" ""
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "database plugin check_status returns stopped for non-running SID" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    touch "${db_home}/bin/oracle"
    chmod +x "${db_home}/bin/oracle"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "${db_home}" "NONEXIST"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
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
        "plugin_check_listener_status"
        "plugin_discover_instances"
        "plugin_get_instance_list"
        "plugin_supports_aliases"
        "plugin_build_base_path"
        "plugin_build_env"
        "plugin_build_bin_path"
        "plugin_build_lib_path"
        "plugin_get_config_section"
    )
    
    for func in "${required_functions[@]}"; do
        run type "${func}"
        [ "$status" -eq 0 ]
    done
}

@test "database plugin check_status returns unavailable for missing home" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "/nonexistent/path" ""
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "database plugin check_status returns unavailable for home without oracle binary" {
    local db_home="${TEST_DIR}/test_homes/incomplete"
    mkdir -p "${db_home}/bin"
    # Create home without oracle binary
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_status "${db_home}" ""
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "database plugin check_listener_status returns unavailable when lsnrctl missing" {
    local db_home="${TEST_DIR}/test_homes/no_lsnrctl"
    mkdir -p "${db_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_listener_status "${db_home}"
    [ "$status" -eq 2 ]
    [ "$output" = "unavailable" ]
}

@test "database plugin check_listener_status returns stopped when listener not running" {
    # Create mock database home with lsnrctl that returns error
    local db_home="${TEST_DIR}/test_homes/db_listener_test"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/lib"
    
    # Create mock lsnrctl that returns non-zero (listener stopped)
    cat > "${db_home}/bin/lsnrctl" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "${db_home}/bin/lsnrctl"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    run plugin_check_listener_status "${db_home}"
    [ "$status" -eq 1 ]
    [ "$output" = "stopped" ]
}

@test "database plugin get_instance_list handles dummy flag" {
    # Create mock oratab with dummy entry
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    local test_oratab="${TEST_DIR}/test_oratab"
    cat > "${test_oratab}" <<EOF
# Test oratab
PROD:${db_home}:Y
TEST:${db_home}:N
DUMMY:${db_home}:D
EOF
    
    export ORATAB_FILE="${test_oratab}"
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_get_instance_list "${db_home}"
    [ "$status" -eq 0 ]
    
    # Check that dummy entry is marked as stopped with dummy flag
    echo "$output" | grep -q "DUMMY|stopped|.*dummy=true"
}

@test "database plugin get_instance_list shows status for non-dummy instances" {
    # Create mock oratab
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    local test_oratab="${TEST_DIR}/test_oratab"
    cat > "${test_oratab}" <<EOF
# Test oratab
PROD:${db_home}:Y
EOF
    
    export ORATAB_FILE="${test_oratab}"
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_get_instance_list "${db_home}"
    [ "$status" -eq 0 ]
    
    # Should have status field (running or stopped)
    [[ "$output" =~ PROD\|(running|stopped)\|autostart=Y ]]
}

@test "database plugin build_base_path returns ORACLE_BASE_HOME when set" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    export ORACLE_BASE_HOME="${TEST_DIR}/base"
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_build_base_path "${db_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${TEST_DIR}/base" ]
    
    unset ORACLE_BASE_HOME
}

@test "database plugin build_base_path returns home_path when ORACLE_BASE_HOME not set" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}"
    
    unset ORACLE_BASE_HOME
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_build_base_path "${db_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${db_home}" ]
}

@test "database plugin build_env returns all required env vars" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_build_env "${db_home}" "TESTDB"
    [ "$status" -eq 0 ]
    
    # Should contain ORACLE_HOME, ORACLE_SID, PATH, LD_LIBRARY_PATH
    echo "$output" | grep -q "ORACLE_HOME=${db_home}"
    echo "$output" | grep -q "ORACLE_SID=TESTDB"
    echo "$output" | grep -q "PATH="
    echo "$output" | grep -q "LD_LIBRARY_PATH="
}

@test "database plugin build_bin_path returns bin and OPatch" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/OPatch"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_build_bin_path "${db_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"${db_home}/bin"* ]]
    [[ "$output" == *"${db_home}/OPatch"* ]]
}

@test "database plugin build_lib_path prefers lib64 over lib" {
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/lib64"
    mkdir -p "${db_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_build_lib_path "${db_home}"
    [ "$status" -eq 0 ]
    # lib64 should appear before lib
    [[ "$output" == "${db_home}/lib64:"* ]]
}

@test "database plugin get_config_section returns RDBMS" {
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ "$output" = "RDBMS" ]
}
