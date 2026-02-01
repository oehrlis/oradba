#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_client_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for client_plugin.sh (Oracle Full Client)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_client_$$"
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
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/client_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# Client Plugin Tests
# ==============================================================================

@test "client plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "client plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "client" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "client plugin validates full client home" {
    # Create mock full client home
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    mkdir -p "${client_home}/network/admin"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${client_home}"
    [ "$status" -eq 0 ]
}

@test "client plugin rejects home without sqlplus" {
    # Create mock home without sqlplus
    local fake_home="${TEST_DIR}/test_homes/fake_client"
    mkdir -p "${fake_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "client plugin rejects database home" {
    # Create mock database home (has rdbms/)
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/rdbms/admin"
    touch "${db_home}/bin/sqlplus"
    chmod +x "${db_home}/bin/sqlplus"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${db_home}"
    [ "$status" -ne 0 ]
}

@test "client plugin rejects instant client" {
    # Create mock instant client (no bin/ subdirectory)
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${ic_home}"
    [ "$status" -ne 0 ]
}

@test "client plugin returns available status" {
    # Create mock full client home
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_check_status "${client_home}" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "client plugin does not show listener" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "client plugin discovers no instances" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_discover_instances "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "client plugin does not support aliases" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -ne 0 ]
}

@test "client plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "client plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    local required_functions=(
        "plugin_detect_installation"
        "plugin_validate_home"
        "plugin_adjust_environment"
        "plugin_check_status"
        "plugin_get_metadata"
        "plugin_should_show_listener"
        "plugin_discover_instances"
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

# ==============================================================================
# Builder Function Tests
# ==============================================================================

@test "client plugin build_base_path returns ORACLE_BASE_HOME when set" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    export ORACLE_BASE_HOME="${TEST_DIR}/base"
    run plugin_build_base_path "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${TEST_DIR}/base" ]
    
    unset ORACLE_BASE_HOME
}

@test "client plugin build_base_path returns home_path when ORACLE_BASE_HOME not set" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_base_path "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${client_home}" ]
}

@test "client plugin build_env returns all required env vars" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    mkdir -p "${client_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_env "${client_home}"
    [ "$status" -eq 0 ]
    
    # Should contain ORACLE_HOME, PATH, LD_LIBRARY_PATH
    echo "$output" | grep -q "ORACLE_HOME=${client_home}"
    echo "$output" | grep -q "ORACLE_BASE_HOME="
    echo "$output" | grep -q "PATH="
    echo "$output" | grep -q "LD_LIBRARY_PATH="
}

@test "client plugin build_bin_path returns bin and OPatch" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    mkdir -p "${client_home}/OPatch"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_bin_path "${client_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"${client_home}/bin"* ]]
    [[ "$output" == *"${client_home}/OPatch"* ]]
}

@test "client plugin build_bin_path returns bin only when OPatch missing" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_bin_path "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${client_home}/bin" ]
}

@test "client plugin build_lib_path prefers lib64 over lib" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/lib64"
    mkdir -p "${client_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_lib_path "${client_home}"
    [ "$status" -eq 0 ]
    # lib64 should appear before lib
    [[ "$output" == "${client_home}/lib64:"* ]]
}

@test "client plugin build_lib_path returns lib when lib64 missing" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_lib_path "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${client_home}/lib" ]
}

@test "client plugin build_lib_path returns lib64 only when lib missing" {
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/lib64"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_build_lib_path "${client_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${client_home}/lib64" ]
}

@test "client plugin get_config_section returns CLIENT" {
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ "$output" = "CLIENT" ]
}
