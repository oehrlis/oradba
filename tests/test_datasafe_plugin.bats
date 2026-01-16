#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_datasafe_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for datasafe_plugin.sh (Data Safe Connector)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_datasafe_$$"
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
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/datasafe_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# DataSafe Plugin Tests
# ==============================================================================

@test "datasafe plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "datasafe plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "datasafe" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "datasafe plugin validates datasafe home with oracle_cman_home" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${ds_home}"
    [ "$status" -eq 0 ]
}

@test "datasafe plugin rejects home without oracle_cman_home" {
    # Create mock home without oracle_cman_home
    local fake_home="${TEST_DIR}/test_homes/fake_ds"
    mkdir -p "${fake_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin rejects home without cmctl" {
    # Create mock home with oracle_cman_home but no cmctl
    local incomplete_home="${TEST_DIR}/test_homes/incomplete_ds"
    mkdir -p "${incomplete_home}/oracle_cman_home/bin"
    mkdir -p "${incomplete_home}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${incomplete_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin rejects home without lib directory" {
    # Create mock home without lib
    local incomplete_home="${TEST_DIR}/test_homes/nolib_ds"
    mkdir -p "${incomplete_home}/oracle_cman_home/bin"
    touch "${incomplete_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${incomplete_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${incomplete_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin adjusts environment to oracle_cman_home" {
    # Create mock DataSafe home
    local ds_base="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_base}/oracle_cman_home/bin"
    mkdir -p "${ds_base}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_adjust_environment "${ds_base}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ds_base}/oracle_cman_home" ]
}

@test "datasafe plugin adjust_environment handles already adjusted path" {
    # If path already points to oracle_cman_home
    local cman_home="${TEST_DIR}/test_homes/datasafe_conn1/oracle_cman_home"
    mkdir -p "${cman_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_adjust_environment "${cman_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${cman_home}" ]
}

@test "datasafe plugin check_status returns unavailable without cmctl" {
    local ds_home="${TEST_DIR}/test_homes/datasafe_nocmctl"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 2 ]
    [ "$output" = "unavailable" ]
}

@test "datasafe plugin does not show listener" {
    # DataSafe connectors don't show listener status
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "datasafe plugin discovers connector instance" {
    # DataSafe connectors return connector name as instance
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_discover_instances "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"datasafe_conn1"* ]]
}

@test "datasafe plugin does not support aliases" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -ne 0 ]
}

@test "datasafe plugin gets metadata" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_metadata "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"type=datasafe"* ]]
}

@test "datasafe plugin has adjusted paths helper" {
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_adjusted_paths "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PATH="* ]]
    [[ "$output" == *"LD_LIBRARY_PATH="* ]]
}

@test "datasafe plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
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

@test "datasafe plugin has datasafe-specific functions" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # DataSafe-specific helper function
    run type plugin_get_adjusted_paths
    [ "$status" -eq 0 ]
}
