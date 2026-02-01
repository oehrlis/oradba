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
    
    # For version detection tests, we need the real detect_oracle_version function
    # and its dependencies (execute_plugin_function_v2, detect_product_type, oradba_log)
    # Extract these functions from the real common.sh to avoid side effects
    if ! declare -f detect_oracle_version >/dev/null 2>&1; then
        eval "$(sed -n '/^oradba_log()/,/^}/p' "${ORADBA_BASE}/src/lib/oradba_common.sh")"
        eval "$(sed -n '/^detect_product_type()/,/^}/p' "${ORADBA_BASE}/src/lib/oradba_common.sh")"
        eval "$(sed -n '/^execute_plugin_function_v2()/,/^}/p' "${ORADBA_BASE}/src/lib/oradba_common.sh")"
        eval "$(sed -n '/^detect_oracle_version()/,/^}/p' "${ORADBA_BASE}/src/lib/oradba_common.sh")"
    fi
    
    # Create minimal oradba_common.sh stub for logging (used by plugins)
    cat > "${TEST_DIR}/lib/oradba_common.sh" <<'EOF'
oradba_log() {
    local level="$1"
    shift
    # Suppress debug logs in tests
    [[ "${level}" == "DEBUG" ]] && return 0
    echo "[${level}] $*" >&2
}
EOF
    
    # Source common functions stub
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
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "iclient" ]]
    # shellcheck disable=SC2154
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

@test "iclient plugin returns N/A status" {
    # Create mock instant client home
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so"
    chmod 644 "${ic_home}/libclntsh.so"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_check_status "${ic_home}" ""
    [ "$status" -eq 0 ]
    [ "$output" = "N/A" ]
}

@test "iclient plugin also returns N/A for missing library" {
    # Create mock instant client home without library
    local ic_home="${TEST_DIR}/test_homes/instantclient_empty"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    run plugin_check_status "${ic_home}" ""
    [ "$status" -eq 0 ]
    [ "$output" = "N/A" ]
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

# ------------------------------------------------------------------------------
# Builder Function Tests
# ------------------------------------------------------------------------------

@test "iclient plugin build_base_path returns home_path" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_base_path "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ic_home}" ]
}

@test "iclient plugin build_env returns all required env vars" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_env "${ic_home}"
    [ "$status" -eq 0 ]
    
    # Should contain ORACLE_HOME, PATH, LD_LIBRARY_PATH
    echo "$output" | grep -q "ORACLE_HOME=${ic_home}"
    echo "$output" | grep -q "PATH="
    echo "$output" | grep -q "LD_LIBRARY_PATH="
}

@test "iclient plugin build_bin_path returns home root (no bin subdir)" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_bin_path "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ic_home}" ]
}

@test "iclient plugin build_lib_path prefers lib64" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}/lib64"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_lib_path "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ic_home}/lib64" ]
}

@test "iclient plugin build_lib_path returns lib when no lib64" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}/lib"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_lib_path "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ic_home}/lib" ]
}

@test "iclient plugin build_lib_path returns root when no lib subdirs" {
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_8"
    mkdir -p "${ic_home}"
    
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_build_lib_path "${ic_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ic_home}" ]
}

@test "iclient plugin get_config_section returns ICLIENT" {
    source "${TEST_DIR}/lib/plugins/iclient_plugin.sh"
    
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ "$output" = "ICLIENT" ]
}

# ------------------------------------------------------------------------------
# Version Detection Tests
# ------------------------------------------------------------------------------

@test "detect_oracle_version extracts version from library filename" {
    # Source the common functions
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    # Create mock instant client home with versioned library
    local ic_home="${TEST_DIR}/test_homes/instantclient_23_5"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so.23.5"
    
    # Test version detection
    run detect_oracle_version "${ic_home}" "iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "2305" ]
}

@test "detect_oracle_version handles single-digit minor version" {
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    local ic_home="${TEST_DIR}/test_homes/instantclient_21_1"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so.21.1"
    
    run detect_oracle_version "${ic_home}" "iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "2101" ]
}

@test "detect_oracle_version handles libclntshcore" {
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    local ic_home="${TEST_DIR}/test_homes/instantclient_19_21"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntshcore.so.19.21"
    
    run detect_oracle_version "${ic_home}" "iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "1921" ]
}

@test "detect_oracle_version handles libocci" {
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    local ic_home="${TEST_DIR}/test_homes/instantclient_23_1"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libocci.so.23.1"
    
    run detect_oracle_version "${ic_home}" "iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "2301" ]
}

@test "detect_oracle_version prefers first library found" {
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    local ic_home="${TEST_DIR}/test_homes/instantclient_multi"
    mkdir -p "${ic_home}"
    touch "${ic_home}/libclntsh.so.23.5"
    touch "${ic_home}/libclntshcore.so.19.21"
    
    # Should find libclntsh.so first
    run detect_oracle_version "${ic_home}" "iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "2305" ]
}