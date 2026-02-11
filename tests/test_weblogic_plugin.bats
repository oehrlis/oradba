#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_weblogic_plugin.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.02.11
# Purpose....: Unit tests for weblogic_plugin.sh (Oracle WebLogic Server)
# Notes......: Stub implementation tests
#            EXPERIMENTAL: Set ORADBA_TEST_EXPERIMENTAL=true to run these tests
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Skip experimental plugin tests unless explicitly enabled
    if [[ "${ORADBA_TEST_EXPERIMENTAL:-false}" != "true" ]]; then
        skip "Experimental plugin tests disabled (set ORADBA_TEST_EXPERIMENTAL=true to enable)"
    fi
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_weblogic_$$"
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
    cp "${ORADBA_BASE}/lib/plugins/weblogic_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# WebLogic Plugin Basic Tests
# ==============================================================================

@test "weblogic plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "weblogic plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "weblogic" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "weblogic plugin validates WebLogic home with weblogic.jar" {
    # Create mock WebLogic home
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/wlserver/server/lib"
    touch "${wls_home}/wlserver/server/lib/weblogic.jar"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_validate_home "${wls_home}"
    [ "$status" -eq 0 ]
}

@test "weblogic plugin rejects home without WebLogic markers" {
    # Create mock home without WebLogic-specific files
    local fake_home="${TEST_DIR}/test_homes/fake_wls"
    mkdir -p "${fake_home}"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "weblogic plugin does not show listener" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "weblogic plugin does not support aliases" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -ne 0 ]
}

@test "weblogic plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Multi-Instance Support Tests (plugin_get_instance_list)
# ==============================================================================

@test "weblogic plugin_get_instance_list returns pipe-delimited format" {
    # Create mock WebLogic home with domains
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/domain1/config"
    mkdir -p "${wls_home}/../user_projects/domains/domain2/config"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_instance_list "${wls_home}"
    [ "$status" -eq 0 ]
    
    # Verify pipe-delimited format: domain_name|status|metadata
    [[ "$output" == *"|"* ]]
    [[ "$output" == *"domain1|"* ]]
    [[ "$output" == *"domain2|"* ]]
}

@test "weblogic plugin_get_instance_list includes status field" {
    # Create mock WebLogic home with domain
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/test_domain/config"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_instance_list "${wls_home}"
    [ "$status" -eq 0 ]
    
    # Should include status (stub returns "stopped")
    [[ "$output" == *"test_domain|stopped|"* ]]
}

@test "weblogic plugin_get_instance_list includes metadata" {
    # Create mock WebLogic home with domain
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/test_domain/config"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_instance_list "${wls_home}"
    [ "$status" -eq 0 ]
    
    # Should include metadata field (path=...)
    [[ "$output" == *"path="* ]]
}

@test "weblogic plugin_get_instance_list returns empty for no domains" {
    # Create mock WebLogic home without user_projects
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_instance_list "${wls_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "weblogic plugin_get_instance_list ignores directories without config" {
    # Create mock WebLogic home with invalid domain
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/invalid_domain"
    mkdir -p "${wls_home}/../user_projects/domains/valid_domain/config"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_instance_list "${wls_home}"
    [ "$status" -eq 0 ]
    
    # Should only list valid_domain
    [[ "$output" == *"valid_domain"* ]]
    [[ "$output" != *"invalid_domain"* ]]
}

# ==============================================================================
# Instance Discovery Tests
# ==============================================================================

@test "weblogic plugin_discover_instances finds domains" {
    # Create mock WebLogic home with domains
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/domain1/config"
    mkdir -p "${wls_home}/../user_projects/domains/domain2/config"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_discover_instances "${wls_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"domain1"* ]]
    [[ "$output" == *"domain2"* ]]
}

@test "weblogic plugin_discover_instances returns empty for no domains" {
    # Create mock WebLogic home without domains
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_discover_instances "${wls_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ==============================================================================
# Environment Builder Tests
# ==============================================================================

@test "weblogic plugin_build_env includes WLS_DOMAIN when domain provided" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_env "${wls_home}" "domain1"
    [ "$status" -eq 0 ]
    
    # Should include WLS_DOMAIN variable
    [[ "$output" == *"WLS_DOMAIN=domain1"* ]]
}

@test "weblogic plugin_build_env includes ORACLE_HOME" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_env "${wls_home}"
    [ "$status" -eq 0 ]
    
    # Should include ORACLE_HOME
    [[ "$output" == *"ORACLE_HOME=${wls_home}"* ]]
}

@test "weblogic plugin_build_env includes DOMAIN_HOME when domain exists" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    mkdir -p "${wls_home}/../user_projects/domains/domain1"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_env "${wls_home}" "domain1"
    [ "$status" -eq 0 ]
    
    # Should include DOMAIN_HOME
    [[ "$output" == *"DOMAIN_HOME="* ]]
}

# ==============================================================================
# Builder Function Tests
# ==============================================================================

@test "weblogic plugin_build_bin_path returns empty (stub)" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_bin_path "${wls_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "weblogic plugin_build_lib_path returns empty (stub)" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_lib_path "${wls_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "weblogic plugin_build_base_path returns home unchanged" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_build_base_path "${wls_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${wls_home}" ]
}

@test "weblogic plugin_get_config_section returns WEBLOGIC" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ "$output" = "WEBLOGIC" ]
}

# ==============================================================================
# Interface Compliance Tests
# ==============================================================================

@test "weblogic plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    
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
        "plugin_get_version"
    )
    
    for func in "${required_functions[@]}"; do
        run type "${func}"
        [ "$status" -eq 0 ]
    done
}

@test "weblogic plugin_get_version returns exit 1 when not implemented" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_get_version "${wls_home}"
    
    # Stub should return 1 (N/A) per plugin standards
    [ "$status" -eq 1 ]
    # No output per standards
    [ "$output" = "" ]
}

@test "weblogic plugin_check_status returns proper format" {
    local wls_home="${TEST_DIR}/test_homes/wls_12c"
    
    source "${TEST_DIR}/lib/plugins/weblogic_plugin.sh"
    run plugin_check_status "${wls_home}"
    
    # Stub returns exit 1 (N/A) with no output
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}
