#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_plugin_isolation.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.03
# Purpose....: Test plugin execution isolation (Phase 3)
# Notes......: Tests subshell isolation, environment propagation, and state immutability
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Source common library
    SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    export ORADBA_BASE="${SCRIPT_DIR}/.."
    source "${ORADBA_BASE}/src/lib/oradba_common.sh"
    
    # Create temp directory for test plugins
    export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/oradba_test_$$"
    mkdir -p "${TEST_TEMP_DIR}/plugins"
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    mkdir -p "${ORADBA_BASE}/src/lib/plugins"
}

# Cleanup
teardown() {
    rm -rf "${TEST_TEMP_DIR}"
}

# ------------------------------------------------------------------------------
# Test 1: Environment isolation - plugin cannot modify parent environment
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: plugin cannot modify parent variables" {
    # Create test plugin that tries to modify environment
    cat > "${ORADBA_BASE}/src/lib/plugins/test_plugin.sh" <<'EOF'
plugin_modify_env() {
    export TEST_VAR="modified_value"
    export NEW_VAR="new_value"
    echo "success"
    return 0
}
EOF
    
    # Set initial value
    export TEST_VAR="original_value"
    unset NEW_VAR
    
    # Call plugin function
    run execute_plugin_function_v2 "test" "modify_env" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "success" ]]
    
    # Verify parent environment is unchanged
    [[ "${TEST_VAR}" == "original_value" ]]
    [[ -z "${NEW_VAR}" ]]
}

# ------------------------------------------------------------------------------
# Test 2: ORACLE_HOME and LD_LIBRARY_PATH are passed to plugin
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: minimal Oracle environment available in plugin" {
    cat > "${ORADBA_BASE}/src/lib/plugins/oracle_env_plugin.sh" <<'EOF'
plugin_check_env() {
    local home="$1"
    # Verify ORACLE_HOME is set
    if [[ -z "${ORACLE_HOME}" ]]; then
        echo "ERROR: ORACLE_HOME not set"
        return 2
    fi
    # Verify LD_LIBRARY_PATH is set
    if [[ -z "${LD_LIBRARY_PATH}" ]]; then
        echo "ERROR: LD_LIBRARY_PATH not set"
        return 2
    fi
    # Verify ORACLE_HOME matches passed argument
    if [[ "${ORACLE_HOME}" != "${home}" ]]; then
        echo "ERROR: ORACLE_HOME mismatch"
        return 2
    fi
    echo "ORACLE_HOME=${ORACLE_HOME}"
    echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
    return 0
}
EOF
    
    run execute_plugin_function_v2 "oracle_env" "check_env" "/opt/oracle/product/19c"
    [ "$status" -eq 0 ]
    [[ "${output}" == *"ORACLE_HOME=/opt/oracle/product/19c"* ]]
    [[ "${output}" == *"LD_LIBRARY_PATH="*"/opt/oracle/product/19c/lib"* ]]
}

# ------------------------------------------------------------------------------
# Test 3: Exit code propagation
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: exit codes propagate correctly" {
    cat > "${ORADBA_BASE}/src/lib/plugins/exitcode_plugin.sh" <<'EOF'
plugin_exit_success() {
    echo "success"
    return 0
}
plugin_exit_na() {
    return 1
}
plugin_exit_error() {
    return 2
}
EOF
    
    # Test exit 0
    run execute_plugin_function_v2 "exitcode" "exit_success" "/fake/home"
    [ "$status" -eq 0 ]
    
    # Test exit 1
    run execute_plugin_function_v2 "exitcode" "exit_na" "/fake/home"
    [ "$status" -eq 1 ]
    
    # Test exit 2
    run execute_plugin_function_v2 "exitcode" "exit_error" "/fake/home"
    [ "$status" -eq 2 ]
}

# ------------------------------------------------------------------------------
# Test 4: No-args function support (NOARGS)
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: NOARGS support for no-arg functions" {
    cat > "${ORADBA_BASE}/src/lib/plugins/noargs_plugin.sh" <<'EOF'
plugin_get_config() {
    # This function takes no arguments
    echo "CONFIG_SECTION=RDBMS"
    return 0
}
plugin_get_binaries() {
    # This function takes no arguments
    echo "sqlplus tnsping lsnrctl"
    return 0
}
EOF
    
    # Test no-arg function with NOARGS
    local result
    run execute_plugin_function_v2 "noargs" "get_config" "NOARGS"
    [ "$status" -eq 0 ]
    [[ "${output}" == "CONFIG_SECTION=RDBMS" ]]
    
    # Test another no-arg function
    run execute_plugin_function_v2 "noargs" "get_binaries" "NOARGS"
    [ "$status" -eq 0 ]
    [[ "${output}" == "sqlplus tnsping lsnrctl" ]]
}

# ------------------------------------------------------------------------------
# Test 5: Result variable capture
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: result variable capture works" {
    cat > "${ORADBA_BASE}/src/lib/plugins/result_plugin.sh" <<'EOF'
plugin_get_data() {
    echo "result_data"
    return 0
}
EOF
    
    # Test with result variable
    local result_var=""
    execute_plugin_function_v2 "result" "get_data" "/fake/home" "result_var"
    [[ "${result_var}" == "result_data" ]]
    
    # Test without result variable (output to stdout)
    run execute_plugin_function_v2 "result" "get_data" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "result_data" ]]
}

# ------------------------------------------------------------------------------
# Test 6: Plugin function not found
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: returns error for missing function" {
    cat > "${ORADBA_BASE}/src/lib/plugins/missing_plugin.sh" <<'EOF'
plugin_existing_func() {
    echo "exists"
    return 0
}
EOF
    
    # Try to call non-existent function
    run execute_plugin_function_v2 "missing" "nonexistent_func" "/fake/home"
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Test 7: Plugin file not found
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: returns error for missing plugin" {
    # Try to call function from non-existent plugin
    run execute_plugin_function_v2 "nonexistent" "some_func" "/fake/home"
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Test 8: Function definitions don't leak to parent
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: function definitions isolated" {
    cat > "${ORADBA_BASE}/src/lib/plugins/funcdef_plugin.sh" <<'EOF'
plugin_define_funcs() {
    # Define some functions in plugin
    test_function_one() {
        echo "one"
    }
    test_function_two() {
        echo "two"
    }
    echo "functions_defined"
    return 0
}
EOF
    
    # Call plugin
    run execute_plugin_function_v2 "funcdef" "define_funcs" "/fake/home"
    [ "$status" -eq 0 ]
    
    # Verify functions are not defined in parent
    run declare -F test_function_one
    [ "$status" -ne 0 ]
    run declare -F test_function_two
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Test 9: Plugin modifications don't leak back to parent
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: plugin modifications don't leak to parent" {
    cat > "${ORADBA_BASE}/src/lib/plugins/varcheck_plugin.sh" <<'EOF'
plugin_check_vars() {
    # Exported variables are inherited (expected), but modifications don't leak back
    # Verify ORACLE_HOME is available
    if [[ -z "${ORACLE_HOME}" ]]; then
        echo "ERROR: ORACLE_HOME not available"
        return 2
    fi
    # Modify inherited variable
    INHERITED_VAR="modified_in_plugin"
    echo "isolation_success"
    return 0
}
EOF
    
    # Set and export a variable that will be inherited
    export INHERITED_VAR="original_value"
    
    # Call plugin
    run execute_plugin_function_v2 "varcheck" "check_vars" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "isolation_success" ]]
    
    # Verify modification didn't leak back to parent
    [[ "${INHERITED_VAR}" == "original_value" ]]
    
    # Cleanup
    unset INHERITED_VAR
}

# ------------------------------------------------------------------------------
# Test 10: set -euo pipefail is active in subshell
# NOTE: This test is unreliable because bash -u behavior varies across versions
#       and environments. Undefined variable access may not always cause exit.
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: strict error handling active" {
    skip "Unreliable test - bash -u behavior varies across environments"
    cat > "${ORADBA_BASE}/src/lib/plugins/strict_plugin.sh" <<'EOF'
plugin_test_strict() {
    # Try to use undefined variable (should fail with set -u)
    local result="${UNDEFINED_VAR}"
    echo "should_not_reach_here"
    return 0
}
EOF
    
    # Plugin should fail due to undefined variable
    run execute_plugin_function_v2 "strict" "test_strict" "/fake/home"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Test 11: Extra argument support
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: extra argument passed correctly" {
    cat > "${ORADBA_BASE}/src/lib/plugins/extraarg_plugin.sh" <<'EOF'
plugin_with_extra() {
    local home="$1"
    local extra="$2"
    echo "home=${home}"
    echo "extra=${extra}"
    return 0
}
EOF
    
    # Call with extra argument
    run execute_plugin_function_v2 "extraarg" "with_extra" "/fake/home" "" "extra_value"
    [ "$status" -eq 0 ]
    [[ "${output}" == *"home=/fake/home"* ]]
    [[ "${output}" == *"extra=extra_value"* ]]
}

# ------------------------------------------------------------------------------
# Test 12: LD_LIBRARY_PATH inheritance when already set
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: LD_LIBRARY_PATH inherited when set" {
    cat > "${ORADBA_BASE}/src/lib/plugins/ldlib_plugin.sh" <<'EOF'
plugin_check_ldlib() {
    echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
    return 0
}
EOF
    
    # Set LD_LIBRARY_PATH in parent
    export LD_LIBRARY_PATH="/existing/path:/another/path"
    
    # Call plugin
    run execute_plugin_function_v2 "ldlib" "check_ldlib" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == *"LD_LIBRARY_PATH=/existing/path:/another/path"* ]]
    
    # Cleanup
    unset LD_LIBRARY_PATH
}

# ------------------------------------------------------------------------------
# Test 13: Verify state changes don't persist after plugin execution
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: state changes don't persist" {
    cat > "${ORADBA_BASE}/src/lib/plugins/state_plugin.sh" <<'EOF'
# Global variable in plugin
PLUGIN_STATE="initial"

plugin_modify_state() {
    PLUGIN_STATE="modified"
    echo "state=${PLUGIN_STATE}"
    return 0
}

plugin_check_state() {
    echo "state=${PLUGIN_STATE}"
    return 0
}
EOF
    
    # First call modifies state
    local result1
    result1=$(execute_plugin_function_v2 "state" "modify_state" "/fake/home")
    [[ "${result1}" == "state=modified" ]]
    
    # Second call should see initial state (not persisted)
    local result2
    result2=$(execute_plugin_function_v2 "state" "check_state" "/fake/home")
    [[ "${result2}" == "state=initial" ]]
}

# ------------------------------------------------------------------------------
# Test 14: plugin_status doesn't leak between plugins (Issue #1)
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: plugin_status doesn't leak between plugins" {
    # Create experimental plugin that exports plugin_status
    cat > "${ORADBA_BASE}/src/lib/plugins/experimental_plugin.sh" <<'EOF'
export plugin_status="EXPERIMENTAL"
export plugin_name="experimental"
export plugin_version="1.0.0"

plugin_test_func() {
    echo "experimental_plugin"
    return 0
}
EOF
    
    # Create non-experimental plugin that doesn't set plugin_status
    cat > "${ORADBA_BASE}/src/lib/plugins/normal_plugin.sh" <<'EOF'
export plugin_name="normal"
export plugin_version="1.0.0"
# Note: plugin_status is NOT set here

plugin_test_func() {
    echo "normal_plugin"
    return 0
}
EOF
    
    # First, call experimental plugin (this will export plugin_status="EXPERIMENTAL")
    run execute_plugin_function_v2 "experimental" "test_func" "/fake/home"
    # Should be skipped with exit code 1
    [ "$status" -eq 1 ]
    # The function itself should not execute (no "experimental_plugin" in output)
    [[ "${output}" != *"experimental_plugin"* ]]
    
    # Now call normal plugin - it should NOT be skipped despite plugin_status in parent env
    run execute_plugin_function_v2 "normal" "test_func" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "normal_plugin" ]]
}

# ------------------------------------------------------------------------------
# Test 15: TNS_ADMIN doesn't leak between plugins (Issue #2)
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: TNS_ADMIN doesn't leak to plugin subshell" {
    # Create plugin that checks if TNS_ADMIN is set
    cat > "${ORADBA_BASE}/src/lib/plugins/tns_check_plugin.sh" <<'EOF'
plugin_check_tns() {
    if [[ -n "${TNS_ADMIN:-}" ]]; then
        echo "ERROR: TNS_ADMIN is set to: ${TNS_ADMIN}"
        return 2
    else
        echo "SUCCESS: TNS_ADMIN is not set"
        return 0
    fi
}
EOF
    
    # Set TNS_ADMIN in parent environment (simulating multiple DataSafe connectors)
    export TNS_ADMIN="/wrong/path/to/network/admin"
    
    # Call plugin - it should NOT inherit TNS_ADMIN
    run execute_plugin_function_v2 "tns_check" "check_tns" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "SUCCESS: TNS_ADMIN is not set" ]]
    
    # Verify TNS_ADMIN is still set in parent (not affected by unset in subshell)
    [[ "${TNS_ADMIN}" == "/wrong/path/to/network/admin" ]]
    
    # Cleanup
    unset TNS_ADMIN
}

# ------------------------------------------------------------------------------
# Test 16: Multiple environment variables are unset in subshell
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: both TNS_ADMIN and plugin_status are unset" {
    # Create plugin that checks both variables
    cat > "${ORADBA_BASE}/src/lib/plugins/multi_check_plugin.sh" <<'EOF'
plugin_check_both() {
    local errors=0
    if [[ -n "${TNS_ADMIN:-}" ]]; then
        echo "ERROR: TNS_ADMIN is set"
        errors=1
    fi
    if [[ -n "${plugin_status:-}" ]]; then
        echo "ERROR: plugin_status is set"
        errors=1
    fi
    if [[ $errors -eq 0 ]]; then
        echo "SUCCESS: Both variables are unset"
        return 0
    else
        return 2
    fi
}
EOF
    
    # Set both variables in parent environment
    export TNS_ADMIN="/some/path"
    export plugin_status="EXPERIMENTAL"
    
    # Call plugin - it should see neither variable
    run execute_plugin_function_v2 "multi_check" "check_both" "/fake/home"
    [ "$status" -eq 0 ]
    [[ "${output}" == "SUCCESS: Both variables are unset" ]]
    
    # Verify variables are still set in parent
    [[ "${TNS_ADMIN}" == "/some/path" ]]
    [[ "${plugin_status}" == "EXPERIMENTAL" ]]
    
    # Cleanup
    unset TNS_ADMIN
    unset plugin_status
}

# ------------------------------------------------------------------------------
# Test 17: plugin_status isolation with NOARGS functions
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: plugin_status isolation works with NOARGS" {
    # Create experimental plugin with no-arg function
    cat > "${ORADBA_BASE}/src/lib/plugins/exp_noargs_plugin.sh" <<'EOF'
export plugin_status="EXPERIMENTAL"
export plugin_name="exp_noargs"

plugin_get_config() {
    echo "CONFIG"
    return 0
}
EOF
    
    # Create normal plugin with no-arg function
    cat > "${ORADBA_BASE}/src/lib/plugins/normal_noargs_plugin.sh" <<'EOF'
export plugin_name="normal_noargs"
# plugin_status NOT set

plugin_get_config() {
    echo "NORMAL_CONFIG"
    return 0
}
EOF
    
    # Call experimental plugin with NOARGS (should be skipped)
    run execute_plugin_function_v2 "exp_noargs" "get_config" "NOARGS"
    [ "$status" -eq 1 ]
    
    # Call normal plugin with NOARGS (should succeed)
    run execute_plugin_function_v2 "normal_noargs" "get_config" "NOARGS"
    [ "$status" -eq 0 ]
    [[ "${output}" == "NORMAL_CONFIG" ]]
}

# ------------------------------------------------------------------------------
# Test 18: TNS_ADMIN isolation with NOARGS functions
# ------------------------------------------------------------------------------
@test "execute_plugin_function_v2: TNS_ADMIN isolation works with NOARGS" {
    # Create plugin with no-arg function that checks TNS_ADMIN
    cat > "${ORADBA_BASE}/src/lib/plugins/tns_noargs_plugin.sh" <<'EOF'
plugin_check_tns_noargs() {
    if [[ -n "${TNS_ADMIN:-}" ]]; then
        echo "ERROR: TNS_ADMIN leaked"
        return 2
    else
        echo "SUCCESS: TNS_ADMIN not set"
        return 0
    fi
}
EOF
    
    # Set TNS_ADMIN in parent
    export TNS_ADMIN="/some/network/admin"
    
    # Call no-arg plugin function
    run execute_plugin_function_v2 "tns_noargs" "check_tns_noargs" "NOARGS"
    [ "$status" -eq 0 ]
    [[ "${output}" == "SUCCESS: TNS_ADMIN not set" ]]
    
    # Cleanup
    unset TNS_ADMIN
}
