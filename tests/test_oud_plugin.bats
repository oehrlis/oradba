#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_oud_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for oud_plugin.sh (Oracle Unified Directory)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_oud_$$"
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
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/oud_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# OUD Plugin Tests
# ==============================================================================

@test "oud plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "oud plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    [[ "${plugin_name}" == "oud" ]]
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "oud plugin validates OUD home with setup" {
    # Create mock OUD home with setup command
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${oud_home}"
    [ "$status" -eq 0 ]
}

@test "oud plugin validates OUD home with oudBase" {
    # Create mock OUD home with oudBase directory
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${oud_home}"
    [ "$status" -eq 0 ]
}

@test "oud plugin validates OUD home with OpenDJ.jar" {
    # Create mock OUD home with OpenDJ library
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/lib"
    touch "${oud_home}/lib/OpenDJ.jar"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${oud_home}"
    [ "$status" -eq 0 ]
}

@test "oud plugin rejects home without OUD markers" {
    # Create mock home without OUD-specific files
    local fake_home="${TEST_DIR}/test_homes/fake_oud"
    mkdir -p "${fake_home}"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "oud plugin does not show listener" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "oud plugin discovers instances from oudBase" {
    # Create mock OUD home with instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase/instance1"
    mkdir -p "${oud_home}/oudBase/instance2"
    mkdir -p "${oud_home}/oudBase/instance3"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_discover_instances "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"instance1"* ]]
    [[ "$output" == *"instance2"* ]]
    [[ "$output" == *"instance3"* ]]
}

@test "oud plugin discovers no instances without oudBase" {
    # Create mock OUD home without instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_discover_instances "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "oud plugin supports aliases" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -eq 0 ]
}

@test "oud plugin gets display name" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_display_name "myoud1"
    [ "$status" -eq 0 ]
    [ "$output" = "OUD:myoud1" ]
}

@test "oud plugin gets metadata with instance count" {
    # Create mock OUD home with instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase/instance1"
    mkdir -p "${oud_home}/oudBase/instance2"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_metadata "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"type=oud"* ]]
    [[ "$output" == *"instances=2"* ]]
}

@test "oud plugin gets metadata without instances" {
    # Create mock OUD home without oudBase
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_metadata "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"type=oud"* ]]
    [[ "$output" == *"instances=0"* ]]
}

@test "oud plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "oud plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
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
