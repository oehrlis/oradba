#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_java_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor...: Stefan Oehrli
# Date.....: 2026.01.20
# Purpose..: BATS tests for Java plugin
# Notes....: Tests Java plugin functionality
# ------------------------------------------------------------------------------

# Setup and teardown
setup() {
    # Source the Java plugin
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    export ORADBA_LOG_LEVEL="ERROR"
    
    # Source common library for oradba_log
    if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
        # shellcheck source=../src/lib/oradba_common.sh
        source "${ORADBA_BASE}/lib/oradba_common.sh"
    fi
    
    # Source the plugin
    if [[ -f "${ORADBA_BASE}/lib/plugins/java_plugin.sh" ]]; then
        # shellcheck source=../src/lib/plugins/java_plugin.sh
        source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"
    fi
    
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/java_test_$$"
    mkdir -p "${TEST_DIR}"
}

teardown() {
    # Clean up test directory
    rm -rf "${TEST_DIR}"
}

# Test plugin metadata
@test "Java plugin has correct metadata" {
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "java" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

# Test plugin_validate_home with valid Java home
@test "plugin_validate_home accepts valid Java installation" {
    # Create mock Java installation
    mkdir -p "${TEST_DIR}/java17/bin"
    touch "${TEST_DIR}/java17/bin/java"
    chmod +x "${TEST_DIR}/java17/bin/java"
    
    run plugin_validate_home "${TEST_DIR}/java17"
    [[ $status -eq 0 ]]
}

# Test plugin_validate_home with invalid path
@test "plugin_validate_home rejects non-existent path" {
    run plugin_validate_home "${TEST_DIR}/nonexistent"
    [[ $status -eq 1 ]]
}

# Test plugin_validate_home without java executable
@test "plugin_validate_home rejects directory without java" {
    mkdir -p "${TEST_DIR}/notjava/bin"
    
    run plugin_validate_home "${TEST_DIR}/notjava"
    [[ $status -eq 1 ]]
}

# Test plugin_adjust_environment
@test "plugin_adjust_environment returns path unchanged" {
    run plugin_adjust_environment "${TEST_DIR}/java17"
    [[ "$output" == "${TEST_DIR}/java17" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_check_status with available Java
@test "plugin_check_status returns available for valid Java" {
    mkdir -p "${TEST_DIR}/java17/bin"
    touch "${TEST_DIR}/java17/bin/java"
    chmod +x "${TEST_DIR}/java17/bin/java"
    
    run plugin_check_status "${TEST_DIR}/java17"
    [[ "$output" == "available" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_check_status with missing Java
@test "plugin_check_status returns unavailable for missing java" {
    mkdir -p "${TEST_DIR}/java17/bin"
    
    run plugin_check_status "${TEST_DIR}/java17"
    [[ "$output" == "unavailable" ]]
    [[ $status -eq 1 ]]
}

# Test plugin_should_show_listener
@test "plugin_should_show_listener returns 1 (no listener)" {
    run plugin_should_show_listener
    [[ $status -eq 1 ]]
}

# Test plugin_discover_instances
@test "plugin_discover_instances succeeds with no output" {
    run plugin_discover_instances
    [[ -z "$output" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_supports_aliases
@test "plugin_supports_aliases returns 1 (no aliases)" {
    run plugin_supports_aliases
    [[ $status -eq 1 ]]
}

# Test plugin_build_path
@test "plugin_build_path returns bin directory" {
    mkdir -p "${TEST_DIR}/java17/bin"
    
    run plugin_build_path "${TEST_DIR}/java17"
    [[ "$output" == "${TEST_DIR}/java17/bin" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_build_path with no bin directory
@test "plugin_build_path returns empty for missing bin" {
    mkdir -p "${TEST_DIR}/java17"
    
    run plugin_build_path "${TEST_DIR}/java17"
    [[ -z "$output" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_build_lib_path
@test "plugin_build_lib_path returns lib paths if they exist" {
    mkdir -p "${TEST_DIR}/java17/lib/server"
    mkdir -p "${TEST_DIR}/java17/lib"
    
    run plugin_build_lib_path "${TEST_DIR}/java17"
    [[ "$output" == *"lib/server"* ]]
    [[ "$output" == *"/lib"* ]]
    [[ $status -eq 0 ]]
}

# Test plugin_get_config_section
@test "plugin_get_config_section returns JAVA" {
    run plugin_get_config_section
    [[ "$output" == "JAVA" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_get_required_binaries
@test "plugin_get_required_binaries returns java" {
    run plugin_get_required_binaries
    [[ "$output" == "java" ]]
    [[ $status -eq 0 ]]
}

# Test plugin_get_version with missing java
@test "plugin_get_version returns ERR for missing java" {
    mkdir -p "${TEST_DIR}/java17/bin"
    
    run plugin_get_version "${TEST_DIR}/java17"
    [[ "$output" == "ERR" ]]
    [[ $status -eq 1 ]]
}

# Test plugin_get_version with mock java (Java 8 format)
@test "plugin_get_version parses Java 8 version correctly" {
    skip "Requires mock java executable"
}

# Test plugin_get_version with mock java (Java 11+ format)
@test "plugin_get_version parses Java 11+ version correctly" {
    skip "Requires mock java executable"
}

# Test plugin_get_metadata
@test "plugin_get_metadata returns product=java" {
    mkdir -p "${TEST_DIR}/java17/bin"
    touch "${TEST_DIR}/java17/bin/java"
    chmod +x "${TEST_DIR}/java17/bin/java"
    
    run plugin_get_metadata "${TEST_DIR}/java17"
    [[ "$output" == *"product=java"* ]]
    [[ $status -eq 0 ]]
}

# Test plugin_get_metadata detects JDK
@test "plugin_get_metadata detects JDK when javac present" {
    mkdir -p "${TEST_DIR}/jdk17/bin"
    touch "${TEST_DIR}/jdk17/bin/java"
    touch "${TEST_DIR}/jdk17/bin/javac"
    chmod +x "${TEST_DIR}/jdk17/bin/java"
    chmod +x "${TEST_DIR}/jdk17/bin/javac"
    
    run plugin_get_metadata "${TEST_DIR}/jdk17"
    [[ "$output" == *"type=JDK"* ]]
    [[ $status -eq 0 ]]
}

# Test plugin_get_metadata detects JRE
@test "plugin_get_metadata detects JRE when javac absent" {
    mkdir -p "${TEST_DIR}/jre17/bin"
    touch "${TEST_DIR}/jre17/bin/java"
    chmod +x "${TEST_DIR}/jre17/bin/java"
    
    run plugin_get_metadata "${TEST_DIR}/jre17"
    [[ "$output" == *"type=JRE"* ]]
    [[ $status -eq 0 ]]
}

# Test plugin_detect_installation
@test "plugin_detect_installation finds Java installations" {
    export ORACLE_BASE="${TEST_DIR}"
    mkdir -p "${TEST_DIR}/product/java17/bin"
    mkdir -p "${TEST_DIR}/product/jdk21/bin"
    touch "${TEST_DIR}/product/java17/bin/java"
    touch "${TEST_DIR}/product/jdk21/bin/java"
    chmod +x "${TEST_DIR}/product/java17/bin/java"
    chmod +x "${TEST_DIR}/product/jdk21/bin/java"
    
    run plugin_detect_installation
    [[ "$output" == *"java17"* ]]
    [[ "$output" == *"jdk21"* ]]
    [[ $status -eq 0 ]]
}
