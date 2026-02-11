#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oud_plugin.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.01.16
# Purpose....: Unit tests for oud_plugin.sh (Oracle Unified Directory)
# Reference..: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_oud_$$"
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
    cp "${ORADBA_BASE}/lib/plugins/oud_plugin.sh" "${TEST_DIR}/lib/plugins/"
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
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "oud" ]]
    # shellcheck disable=SC2154
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
        "plugin_build_base_path"
        "plugin_build_env"
        "plugin_build_bin_path"
        "plugin_build_lib_path"
        "plugin_get_instance_list"
        "plugin_get_config_section"
    )
    
    for func in "${required_functions[@]}"; do
        run type "${func}"
        [ "$status" -eq 0 ]
    done
}

# ==============================================================================
# Multi-Instance Support Tests (plugin_get_instance_list)
# ==============================================================================

@test "oud plugin_get_instance_list returns pipe-delimited format" {
    # Create mock OUD home with instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase/instance1"
    mkdir -p "${oud_home}/oudBase/instance2"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_instance_list "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Verify pipe-delimited format: instance_name|status|metadata
    [[ "$output" == *"|"* ]]
    [[ "$output" == *"instance1|"* ]]
    [[ "$output" == *"instance2|"* ]]
}

@test "oud plugin_get_instance_list includes status field" {
    # Create mock OUD home with instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase/test_instance"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_instance_list "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Should include status (running or stopped)
    [[ "$output" == *"test_instance|stopped|"* ]] || [[ "$output" == *"test_instance|running|"* ]]
}

@test "oud plugin_get_instance_list includes metadata" {
    # Create mock OUD home with instances
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase/test_instance"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_instance_list "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Should include metadata field (path=...)
    [[ "$output" == *"path="* ]]
}

@test "oud plugin_get_instance_list returns empty for no instances" {
    # Create mock OUD home without oudBase
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_get_instance_list "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ==============================================================================
# Environment Builder Tests
# ==============================================================================

@test "oud plugin_build_env includes OUD_INSTANCE when instance provided" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/bin"
    mkdir -p "${oud_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_env "${oud_home}" "instance1"
    [ "$status" -eq 0 ]
    
    # Should include OUD_INSTANCE variable
    [[ "$output" == *"OUD_INSTANCE=instance1"* ]]
}

@test "oud plugin_build_env includes ORACLE_HOME" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_env "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Should include ORACLE_HOME
    [[ "$output" == *"ORACLE_HOME=${oud_home}"* ]]
}

@test "oud plugin_build_env includes PATH" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_env "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Should include PATH
    [[ "$output" == *"PATH="* ]]
}

@test "oud plugin_build_env includes LD_LIBRARY_PATH" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_env "${oud_home}"
    [ "$status" -eq 0 ]
    
    # Should include LD_LIBRARY_PATH
    [[ "$output" == *"LD_LIBRARY_PATH="* ]]
}

# ==============================================================================
# Builder Function Tests
# ==============================================================================

@test "oud plugin_build_bin_path returns bin directory" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_bin_path "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/bin"* ]]
}

@test "oud plugin_build_lib_path returns lib directory" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_lib_path "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/lib"* ]]
}

@test "oud plugin_build_base_path returns home unchanged" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_build_base_path "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${oud_home}" ]
}

# ==============================================================================
# Instance Base Directory Priority Tests
# ==============================================================================

@test "oud get_oud_instance_base uses OUD_INSTANCE_BASE when set" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    local custom_base="${TEST_DIR}/custom_instances"
    mkdir -p "${custom_base}"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Set OUD_INSTANCE_BASE
    export OUD_INSTANCE_BASE="${custom_base}"
    run get_oud_instance_base "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${custom_base}" ]
    
    unset OUD_INSTANCE_BASE
}

@test "oud get_oud_instance_base uses OUD_DATA/instances when OUD_INSTANCE_BASE not set" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    local oud_data="${TEST_DIR}/oud_data"
    mkdir -p "${oud_data}/instances"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Set OUD_DATA
    export OUD_DATA="${oud_data}"
    run get_oud_instance_base "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${oud_data}/instances" ]
    
    unset OUD_DATA
}

@test "oud get_oud_instance_base uses ORACLE_DATA/instances when higher priority not set" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    local oracle_data="${TEST_DIR}/oracle_data"
    mkdir -p "${oracle_data}/instances"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Set ORACLE_DATA
    export ORACLE_DATA="${oracle_data}"
    run get_oud_instance_base "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${oracle_data}/instances" ]
    
    unset ORACLE_DATA
}

@test "oud get_oud_instance_base uses ORACLE_BASE/instances when higher priority not set" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    local oracle_base="${TEST_DIR}/oracle_base"
    mkdir -p "${oracle_base}/instances"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Set ORACLE_BASE
    export ORACLE_BASE="${oracle_base}"
    run get_oud_instance_base "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${oracle_base}/instances" ]
    
    unset ORACLE_BASE
}

@test "oud get_oud_instance_base falls back to ORACLE_HOME/oudBase" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    mkdir -p "${oud_home}/oudBase"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Ensure no environment variables are set
    unset OUD_INSTANCE_BASE OUD_DATA ORACLE_DATA ORACLE_BASE
    
    run get_oud_instance_base "${oud_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${oud_home}/oudBase" ]
}

@test "oud plugin_get_instance_list uses OUD_INSTANCE_BASE for discovery" {
    local oud_home="${TEST_DIR}/test_homes/oud_12c"
    local custom_base="${TEST_DIR}/custom_instances"
    mkdir -p "${custom_base}/instance1"
    mkdir -p "${custom_base}/instance2"
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    
    # Set OUD_INSTANCE_BASE
    export OUD_INSTANCE_BASE="${custom_base}"
    run plugin_get_instance_list "${oud_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"instance1"* ]]
    [[ "$output" == *"instance2"* ]]
    [[ "$output" == *"${custom_base}"* ]]
    
    unset OUD_INSTANCE_BASE
}
