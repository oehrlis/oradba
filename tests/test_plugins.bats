#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_plugins.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for OraDBA plugins (client, iclient, oud)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_plugins_$$"
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
    
    # Copy plugins to test directory (for isolated testing)
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/client_plugin.sh" "${TEST_DIR}/lib/plugins/"
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/iclient_plugin.sh" "${TEST_DIR}/lib/plugins/"
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/oud_plugin.sh" "${TEST_DIR}/lib/plugins/"
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
    [[ "${plugin_name}" == "client" ]]
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
    [ "$output" = "available" ]
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

# ==============================================================================
# Cross-Plugin Tests
# ==============================================================================

@test "all plugins have required interface functions" {
    local plugins=("client_plugin.sh" "iclient_plugin.sh" "oud_plugin.sh")
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
    
    for plugin in "${plugins[@]}"; do
        # shellcheck source=/dev/null
        source "${TEST_DIR}/lib/plugins/${plugin}"
        for func in "${required_functions[@]}"; do
            run type "${func}"
            [ "$status" -eq 0 ]
        done
    done
}

@test "all plugins export metadata variables" {
    local plugins=("client_plugin.sh" "iclient_plugin.sh" "oud_plugin.sh")
    
    for plugin in "${plugins[@]}"; do
        unset plugin_name plugin_version plugin_description
        # shellcheck source=/dev/null
        source "${TEST_DIR}/lib/plugins/${plugin}"
        [[ -n "${plugin_name}" ]]
        [[ -n "${plugin_version}" ]]
        [[ -n "${plugin_description}" ]]
    done
}

@test "plugins handle non-existent directories gracefully" {
    local fake_home="${TEST_DIR}/test_homes/does_not_exist"
    
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
    
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "plugins return proper exit codes" {
    # Create valid test homes
    local client_home="${TEST_DIR}/test_homes/client_19c_exit"
    mkdir -p "${client_home}/bin"
    mkdir -p "${client_home}/network/admin"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8_exit"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so"
    
    local oud_home="${TEST_DIR}/test_homes/oud_12c_exit"
    mkdir -p "${oud_home}/oudBase"
    
    # Test client plugin
    source "${TEST_DIR}/lib/plugins/client_plugin.sh"
    run plugin_validate_home "${client_home}"
    [ "$status" -eq 0 ]
    run plugin_validate_home "/nonexistent"
    [ "$status" -ne 0 ]
    
    # Test iclient plugin
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_validate_home "${ic_home}"
    [ "$status" -eq 0 ]
    run plugin_validate_home "/nonexistent"
    [ "$status" -ne 0 ]
    
    # Test oud plugin
    source "${TEST_DIR}/lib/plugins/oud_plugin.sh"
    run plugin_validate_home "${oud_home}"
    [ "$status" -eq 0 ]
    run plugin_validate_home "/nonexistent"
    [ "$status" -ne 0 ]
}
