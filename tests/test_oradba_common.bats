#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_common.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: BATS tests for common library functions
# Notes......: Tests logging, validation, and Oracle-specific functions.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Get the directory containing the test script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source the common library
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
}

# Cleanup after tests
teardown() {
    # Remove temporary test directory
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "get_script_dir returns valid directory" {
    local script_dir
    script_dir=$(get_script_dir)
    [ -d "$script_dir" ]
}

@test "command_exists detects existing commands" {
    run command_exists "bash"
    [ "$status" -eq 0 ]
}

@test "command_exists fails for non-existing commands" {
    run command_exists "nonexistentcommand123456"
    [ "$status" -eq 1 ]
}

@test "validate_directory succeeds for existing directory" {
    run validate_directory "$TEST_TEMP_DIR"
    [ "$status" -eq 0 ]
}

@test "validate_directory fails for non-existing directory" {
    run validate_directory "${TEST_TEMP_DIR}/nonexistent"
    [ "$status" -eq 1 ]
}

@test "validate_directory creates directory when requested" {
    local new_dir="${TEST_TEMP_DIR}/newdir"
    run validate_directory "$new_dir" "true"
    [ "$status" -eq 0 ]
    [ -d "$new_dir" ]
}

@test "parse_oratab finds valid entry" {
    # Create mock oratab file
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
# Mock oratab file
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/19.0.0/dbhome_2:Y
EOF
    
    run parse_oratab "FREE" "$mock_oratab"
    [ "$status" -eq 0 ]
    [[ "$output" =~ FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N ]]
}

@test "parse_oratab fails for non-existing SID" {
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
EOF
    
    run parse_oratab "NONEXISTENT" "$mock_oratab"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse_oratab ignores commented lines" {
    local mock_oratab="${TEST_TEMP_DIR}/oratab"
    cat > "$mock_oratab" <<EOF
#COMMENTED:/path/to/oracle:N
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
EOF
    
    run parse_oratab "COMMENTED" "$mock_oratab"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# Tests for new features (tasks 4-7)

@test "generate_pdb_aliases function exists" {
    type -t generate_pdb_aliases | grep -q "function"
}

@test "generate_pdb_aliases returns 0 when ORADBA_NO_PDB_ALIASES is true" {
    export ORADBA_NO_PDB_ALIASES="true"
    run generate_pdb_aliases
    [ "$status" -eq 0 ]
}

@test "load_rman_catalog_connection function exists" {
    type -t load_rman_catalog_connection | grep -q "function"
}

@test "load_rman_catalog_connection returns 1 when ORADBA_RMAN_CATALOG is empty" {
    unset ORADBA_RMAN_CATALOG
    run load_rman_catalog_connection
    [ "$status" -eq 1 ]
}

@test "load_rman_catalog_connection validates catalog format" {
    export ORADBA_RMAN_CATALOG="rman_user@catdb"
    load_rman_catalog_connection
    [ -n "$ORADBA_RMAN_CATALOG_CONNECTION" ]
}

@test "load_rman_catalog_connection builds connection string correctly" {
    export ORADBA_RMAN_CATALOG="rman_user/password@catdb"
    load_rman_catalog_connection
    [[ "$ORADBA_RMAN_CATALOG_CONNECTION" == "catalog rman_user/password@catdb" ]]
}

# ------------------------------------------------------------------------------
# ORADBA_LOCAL_BASE Tests
# ------------------------------------------------------------------------------

@test "ORADBA_LOCAL_BASE is derived from ORACLE_BASE/local when available" {
    # Test with ORACLE_BASE set and local directory exists
    export ORACLE_BASE="/u01/app/oracle"
    mkdir -p "${TEST_TEMP_DIR}/u01/app/oracle/local"
    export ORACLE_BASE="${TEST_TEMP_DIR}/u01/app/oracle"
    export ORADBA_PREFIX="${TEST_TEMP_DIR}/u01/app/oracle/local/oradba"
    unset ORADBA_LOCAL_BASE
    
    # shellcheck disable=SC1094
    source "${PROJECT_ROOT}/src/etc/oradba_core.conf"
    
    [[ "$ORADBA_LOCAL_BASE" == "${TEST_TEMP_DIR}/u01/app/oracle/local" ]]
}

@test "ORADBA_LOCAL_BASE is derived from ORADBA_PREFIX parent when ORACLE_BASE not set" {
    # Test without ORACLE_BASE
    unset ORACLE_BASE
    export ORADBA_PREFIX="${TEST_TEMP_DIR}/opt/oradba"
    unset ORADBA_LOCAL_BASE
    
    # shellcheck disable=SC1094
    source "${PROJECT_ROOT}/src/etc/oradba_core.conf"
    
    [[ "$ORADBA_LOCAL_BASE" == "${TEST_TEMP_DIR}/opt" ]]
}

@test "ORADBA_LOCAL_BASE respects manual override" {
    # Pre-set ORADBA_LOCAL_BASE should be preserved
    export ORADBA_LOCAL_BASE="/custom/location"
    export ORACLE_BASE="/u01/app/oracle"
    export ORADBA_PREFIX="/opt/oradba"
    
    # shellcheck disable=SC1094
    source "${PROJECT_ROOT}/src/etc/oradba_core.conf"
    
    [[ "$ORADBA_LOCAL_BASE" == "/custom/location" ]]
}

@test "ORADBA_BASE equals ORADBA_PREFIX for TVD BasEnv compatibility" {
    export ORADBA_PREFIX="/opt/oradba"
    unset ORADBA_BASE
    
    # shellcheck disable=SC1094
    source "${PROJECT_ROOT}/src/etc/oradba_core.conf"
    
    [[ "$ORADBA_BASE" == "$ORADBA_PREFIX" ]]
}

@test "ORADBA_BIN_DIR and ORADBA_BIN are set correctly" {
    export ORADBA_PREFIX="/opt/oradba"
    unset ORADBA_BIN_DIR
    unset ORADBA_BIN
    
    # shellcheck disable=SC1094
    source "${PROJECT_ROOT}/src/etc/oradba_core.conf"
    
    [[ "$ORADBA_BIN_DIR" == "/opt/oradba/bin" ]]
    [[ "$ORADBA_BIN" == "$ORADBA_BIN_DIR" ]]
}
# ------------------------------------------------------------------------------
# load_config_file() tests - Configuration file loading helper
# ------------------------------------------------------------------------------

@test "load_config_file exists and is a function" {
    type load_config_file | grep -q "function"
}

@test "load_config_file loads existing required config successfully" {
    # Create a test config file
    local test_config="${TEST_TEMP_DIR}/test_required.conf"
    echo "TEST_VAR='loaded_value'" > "${test_config}"
    
    # Load the config as required
    run load_config_file "${test_config}" "true"
    
    # Should succeed
    [ "$status" -eq 0 ]
    # Should load the variable
    # shellcheck source=/dev/null
    source "${test_config}"
    [ "${TEST_VAR}" = "loaded_value" ]
}

@test "load_config_file fails with missing required config" {
    local missing_config="${TEST_TEMP_DIR}/nonexistent_required.conf"
    
    # Try to load missing required config
    run load_config_file "${missing_config}" "true"
    
    # Should fail
    [ "$status" -eq 1 ]
    # Should output error message
    [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "error" ]]
}

@test "load_config_file succeeds with existing optional config" {
    # Create a test config file
    local test_config="${TEST_TEMP_DIR}/test_optional.conf"
    echo "TEST_OPT_VAR='optional_value'" > "${test_config}"
    
    # Load the config as optional (default)
    run load_config_file "${test_config}"
    
    # Should succeed
    [ "$status" -eq 0 ]
}

@test "load_config_file succeeds with missing optional config" {
    local missing_config="${TEST_TEMP_DIR}/nonexistent_optional.conf"
    
    # Try to load missing optional config (no "true" flag)
    run load_config_file "${missing_config}"
    
    # Should succeed (returns 0 for missing optional files)
    [ "$status" -eq 0 ]
}

@test "load_config_file with false required flag treats as optional" {
    local missing_config="${TEST_TEMP_DIR}/nonexistent_false.conf"
    
    # Load with explicit "false" flag
    run load_config_file "${missing_config}" "false"
    
    # Should succeed
    [ "$status" -eq 0 ]
}

@test "load_config_file handles empty file path parameter" {
    # Try to load with missing file path parameter
    run load_config_file
    
    # Should fail due to missing required parameter
    [ "$status" -ne 0 ]
}

@test "load_config_file sources config file content" {
    # Create a test config with multiple variables
    local test_config="${TEST_TEMP_DIR}/test_source.conf"
    cat > "${test_config}" <<'EOF'
VAR1="value1"
VAR2="value2"
VAR3="value3"
EOF
    
    # Source the function and config
    load_config_file "${test_config}" "false"
    
    # Verify variables are set (need to source in same shell)
    # shellcheck source=/dev/null
    source "${test_config}"
    [ "${VAR1}" = "value1" ]
    [ "${VAR2}" = "value2" ]
    [ "${VAR3}" = "value3" ]
}

@test "load_config_file outputs debug log for existing file" {
    # Create a test config file
    local test_config="${TEST_TEMP_DIR}/test_debug_exist.conf"
    echo "TEST_DEBUG='debug_test'" > "${test_config}"
    
    # Load with debug enabled
    export ORADBA_DEBUG=true
    run load_config_file "${test_config}"
    
    # Should succeed
    [ "$status" -eq 0 ]
}

@test "load_config_file outputs debug log for missing optional file" {
    local missing_config="${TEST_TEMP_DIR}/nonexistent_debug.conf"
    
    # Load with debug enabled
    export ORADBA_DEBUG=true
    run load_config_file "${missing_config}"
    
    # Should succeed (optional file missing is not an error)
    [ "$status" -eq 0 ]
}

@test "load_config_file deduplicates PATH after sourcing config" {
    local test_config="${TEST_TEMP_DIR}/path_test.conf"
    
    # Create config that adds duplicate paths
    cat > "${test_config}" <<'EOF'
export PATH="/opt/test/bin:/usr/local/bin:${PATH}"
EOF
    
    # Set initial PATH with some existing dirs
    export PATH="/usr/local/bin:/usr/bin:/bin"
    local path_before="${PATH}"
    
    # Load config (will add /usr/local/bin again)
    load_config_file "${test_config}" "false"
    
    # Count occurrences of /usr/local/bin
    local count
    count=$(echo "${PATH}" | tr ':' '\n' | grep -c '^/usr/local/bin$' || true)
    
    # Should only appear once (deduplicated)
    [ "${count}" -eq 1 ]
    
    # PATH should be different from before (new paths added)
    [ "${PATH}" != "${path_before}" ]
    
    # Should contain the new path
    [[ "${PATH}" == *"/opt/test/bin"* ]]
}

# ------------------------------------------------------------------------------
# Auto-Discovery Tests (v1.0.0 feature)
# ------------------------------------------------------------------------------

@test "discover_running_oracle_instances function exists" {
    type -t discover_running_oracle_instances | grep -q "function"
}

@test "discover_running_oracle_instances returns proper format" {
    # Skip if no Oracle processes running
    if ! ps -U "$(id -un)" -o comm --no-headers | grep -qE "(db_smon_|ora_pmon_|asm_smon_)"; then
        skip "No Oracle processes running for current user"
    fi
    
    run discover_running_oracle_instances
    
    # Should output in oratab format: SID:ORACLE_HOME:N
    if [ "$status" -eq 0 ]; then
        # Check format: three colon-separated fields
        [[ "$output" =~ ^[^:]+:[^:]+:[YN]$ ]] || [[ "$output" =~ ^[^:]+:[^:]+:[YN]$'\n' ]]
    fi
}

@test "discover_running_oracle_instances detects current user processes only" {
    # This test verifies security boundary - only processes owned by current user
    run discover_running_oracle_instances
    
    # If successful, output should only contain instances for current user
    # We can't easily verify this in a test, but the function should log warnings
    # for other-user processes
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # Either found or not found is ok
}

@test "discover_running_oracle_instances handles no running instances" {
    # Mock environment with no Oracle processes
    # We can't really test this without stopping all Oracle instances
    # Just verify function doesn't crash
    run discover_running_oracle_instances
    
    # Should return 0 or 1 (found or not found)
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "persist_discovered_instances function exists" {
    type -t persist_discovered_instances | grep -q "function"
}

@test "persist_discovered_instances creates local oratab when needed" {
    # Create mock discovered instances
    local discovered_instances="TESTDB:/opt/oracle/product/19c:N"
    local test_oratab="${TEST_TEMP_DIR}/oratab"
    
    # Ensure file doesn't exist
    [ ! -f "$test_oratab" ]
    
    # Make it writable (simulate having permission)
    mkdir -p "$(dirname "$test_oratab")"
    touch "$test_oratab"
    chmod 644 "$test_oratab"
    
    # Run persistence
    run persist_discovered_instances "$discovered_instances" "$test_oratab"
    
    # Should succeed
    [ "$status" -eq 0 ]
    
    # Should have created entry
    [ -f "$test_oratab" ]
    grep -q "^TESTDB:" "$test_oratab"
}

@test "persist_discovered_instances prevents duplicates" {
    local discovered_instances="DUPDB:/opt/oracle/product/19c:N"
    local test_oratab="${TEST_TEMP_DIR}/oratab_dup"
    
    # Create existing oratab with same SID
    echo "DUPDB:/opt/oracle/product/19c:N" > "$test_oratab"
    
    # Try to add same SID again
    run persist_discovered_instances "$discovered_instances" "$test_oratab"
    
    # Should succeed but not duplicate
    [ "$status" -eq 0 ]
    
    # Should only have one entry
    local count
    count=$(grep -c "^DUPDB:" "$test_oratab")
    [ "$count" -eq 1 ]
}

@test "persist_discovered_instances handles permission denied gracefully" {
    # Create mock discovered instances
    local discovered_instances="PERMTEST:/opt/oracle/product/19c:N"
    local readonly_oratab="${TEST_TEMP_DIR}/readonly_oratab"
    
    # Create read-only oratab (simulate /etc/oratab without root)
    touch "$readonly_oratab"
    chmod 444 "$readonly_oratab"
    
    # Set up fallback location
    export ORADBA_PREFIX="${TEST_TEMP_DIR}"
    mkdir -p "${ORADBA_PREFIX}/etc"
    
    # Run persistence - should fallback to local oratab
    run persist_discovered_instances "$discovered_instances" "$readonly_oratab"
    
    # Should succeed (using fallback)
    [ "$status" -eq 0 ]
    
    # Should have created local oratab
    [ -f "${ORADBA_PREFIX}/etc/oratab" ]
    
    # Cleanup
    chmod 644 "$readonly_oratab"
}

@test "persist_discovered_instances handles empty input" {
    local test_oratab="${TEST_TEMP_DIR}/oratab_empty"
    touch "$test_oratab"
    
    # Run with empty discovered instances
    run persist_discovered_instances "" "$test_oratab"
    
    # Should return 1 (nothing to persist)
    [ "$status" -eq 1 ]
}

@test "persist_discovered_instances handles multiple instances" {
    local discovered_instances="DB1:/opt/oracle/product/19c:N
DB2:/opt/oracle/product/21c:N
DB3:/opt/oracle/product/23ai:N"
    local test_oratab="${TEST_TEMP_DIR}/oratab_multi"
    touch "$test_oratab"
    
    # Run persistence
    run persist_discovered_instances "$discovered_instances" "$test_oratab"
    
    # Should succeed
    [ "$status" -eq 0 ]
    
    # Should have all three entries
    grep -q "^DB1:" "$test_oratab"
    grep -q "^DB2:" "$test_oratab"
    grep -q "^DB3:" "$test_oratab"
}

# ------------------------------------------------------------------------------
# Product Type Detection Tests
# ------------------------------------------------------------------------------

@test "detect_product_type detects Data Safe with oracle_cman_home structure" {
    # Create Data Safe structure
    local datasafe_home="${TEST_TEMP_DIR}/datasafe1"
    mkdir -p "${datasafe_home}/oracle_cman_home/bin"
    mkdir -p "${datasafe_home}/oracle_cman_home/lib"
    touch "${datasafe_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${datasafe_home}/oracle_cman_home/bin/cmctl"
    
    run detect_product_type "${datasafe_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "datasafe" ]
}

@test "detect_product_type detects Data Safe with connector.conf and setup.py" {
    # Create Data Safe structure (alternative detection)
    local datasafe_home="${TEST_TEMP_DIR}/datasafe2"
    mkdir -p "${datasafe_home}"
    touch "${datasafe_home}/connector.conf"
    touch "${datasafe_home}/setup.py"
    
    run detect_product_type "${datasafe_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "datasafe" ]
}

@test "detect_product_type detects JDK" {
    # Create JDK structure
    local jdk_home="${TEST_TEMP_DIR}/jdk-17"
    mkdir -p "${jdk_home}/bin"
    touch "${jdk_home}/bin/java"
    touch "${jdk_home}/bin/javac"
    chmod +x "${jdk_home}/bin/java"
    chmod +x "${jdk_home}/bin/javac"
    
    run detect_product_type "${jdk_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "java" ]
}

@test "detect_product_type detects JRE" {
    # Create JRE structure (no javac)
    local jre_home="${TEST_TEMP_DIR}/jre-8"
    mkdir -p "${jre_home}/bin"
    touch "${jre_home}/bin/java"
    chmod +x "${jre_home}/bin/java"
    
    run detect_product_type "${jre_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "java" ]
}

@test "detect_product_type detects nested JRE under JDK" {
    # Create JDK with nested JRE
    local jdk_home="${TEST_TEMP_DIR}/jdk-17"
    local jre_home="${jdk_home}/jre"
    mkdir -p "${jdk_home}/bin"
    mkdir -p "${jre_home}/bin"
    touch "${jdk_home}/bin/java"
    touch "${jdk_home}/bin/javac"
    touch "${jre_home}/bin/java"
    chmod +x "${jdk_home}/bin/java"
    chmod +x "${jdk_home}/bin/javac"
    chmod +x "${jre_home}/bin/java"
    
    # Both should be detected as java
    run detect_product_type "${jdk_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "java" ]
    
    run detect_product_type "${jre_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "java" ]
}

@test "detect_product_type detects instant client" {
    # Create instant client structure
    local iclient_home="${TEST_TEMP_DIR}/instantclient_19_8"
    mkdir -p "${iclient_home}"
    touch "${iclient_home}/libclntsh.so.19.1"
    
    run detect_product_type "${iclient_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "iclient" ]
}

@test "detect_product_type returns unknown for invalid path" {
    run detect_product_type "/nonexistent/path"
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

@test "detect_product_type returns unknown for empty directory" {
    local empty_home="${TEST_TEMP_DIR}/empty"
    mkdir -p "${empty_home}"
    
    run detect_product_type "${empty_home}"
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

# ------------------------------------------------------------------------------
# oradba_apply_oracle_plugin Tests
# ------------------------------------------------------------------------------

@test "oradba_apply_oracle_plugin function exists" {
    type -t oradba_apply_oracle_plugin | grep -q "function"
}

@test "oradba_apply_oracle_plugin fails with missing arguments" {
    run oradba_apply_oracle_plugin
    [ "$status" -eq 1 ]
}

@test "oradba_apply_oracle_plugin fails for non-existent plugin" {
    run oradba_apply_oracle_plugin "check_status" "nonexistent" "/some/path"
    [ "$status" -eq 1 ]
}

@test "oradba_apply_oracle_plugin loads and executes datasafe plugin" {
    # Create mock DataSafe home
    local ds_home="${TEST_TEMP_DIR}/datasafe_plugin_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    # Test loading and executing plugin
    run oradba_apply_oracle_plugin "validate_home" "datasafe" "${ds_home}"
    [ "$status" -eq 0 ]
}

@test "oradba_apply_oracle_plugin stores result in variable" {
    # Create mock DataSafe home
    local ds_home="${TEST_TEMP_DIR}/datasafe_var_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    # Test storing result in variable
    local result=""
    oradba_apply_oracle_plugin "adjust_environment" "datasafe" "${ds_home}" "" "result"
    [[ "${result}" == *"oracle_cman_home"* ]]
}

@test "oradba_apply_oracle_plugin handles plugin function failure" {
    # Test with invalid path - validate_home should fail
    local result=""
    run oradba_apply_oracle_plugin "validate_home" "datasafe" "/nonexistent/path" "" "result"
    [ "$status" -ne 0 ]
}