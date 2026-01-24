#!/usr/bin/env bats
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# ---------------------------------------------------------------------------
# Unit tests for oradba_env_status.sh
# Tests the service status checking functionality
# ---------------------------------------------------------------------------

# Setup and teardown
setup() {
    # Source common library first for plugin support
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
    
    # Set Oracle environment for testing
    export ORACLE_BASE="/u01/app/oracle"
    export ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
    export ORACLE_SID="TESTDB"
}

teardown() {
    # Cleanup test variables
    unset TEST_VAR
}

# Test oradba_check_process_running
@test "check_process_running: should detect running process" {
    # bash should always be running
    run oradba_check_process_running "bash"
    [ "$status" -eq 0 ]
    [[ "$output" -gt 0 ]]
}

@test "check_process_running: should not detect non-existent process" {
    run oradba_check_process_running "definitely_not_running_process_12345"
    [ "$status" -eq 1 ]
    [ "$output" = "0" ]
}

@test "check_process_running: should handle empty pattern" {
    run oradba_check_process_running ""
    [ "$status" -eq 1 ]
}

# Test oradba_get_product_status
@test "get_product_status: should return N/A for CLIENT" {
    run oradba_get_product_status "CLIENT" "dummy" "/path/to/client"
    [ "$status" -eq 0 ]
    [ "$output" = "N/A" ]
}

@test "get_product_status: should return N/A for ICLIENT" {
    run oradba_get_product_status "ICLIENT" "dummy" "/path/to/iclient"
    [ "$status" -eq 0 ]
    [ "$output" = "N/A" ]
}

@test "get_product_status: should return UNKNOWN for invalid product" {
    run oradba_get_product_status "INVALID" "dummy" "/path"
    [ "$status" -eq 1 ]
    [ "$output" = "UNKNOWN" ]
}

# Test oradba_check_db_status
@test "check_db_status: should handle missing sqlplus" {
    run oradba_check_db_status "TESTDB" "/nonexistent/path"
    [ "$status" -eq 1 ]
}

@test "check_db_status: should handle empty SID" {
    run oradba_check_db_status "" "/u01/app/oracle/product/19c"
    [ "$status" -eq 1 ]
}

@test "check_db_status: should handle empty home" {
    run oradba_check_db_status "TESTDB" ""
    [ "$status" -eq 1 ]
}

# Test oradba_check_asm_status
@test "check_asm_status: should handle missing sqlplus" {
    run oradba_check_asm_status "+ASM1" "/nonexistent/path"
    [ "$status" -eq 1 ]
}

@test "check_asm_status: should reject non-ASM SID" {
    run oradba_check_asm_status "REGULARDB" "/u01/app/oracle/product/19c"
    [ "$status" -eq 1 ]
}

@test "check_asm_status: should handle empty SID" {
    run oradba_check_asm_status "" "/u01/app/oracle/product/19c"
    [ "$status" -eq 1 ]
}

# Test oradba_check_listener_status
@test "check_listener_status: should handle missing lsnrctl" {
    run oradba_check_listener_status "LISTENER" "/nonexistent/path"
    [ "$status" -eq 1 ]
}

@test "check_listener_status: should handle empty home" {
    run oradba_check_listener_status "LISTENER" ""
    [ "$status" -eq 1 ]
}

# Test DataSafe status via plugin system
@test "get_product_status: datasafe should use plugin for status" {
    # DataSafe status is now exclusively handled by plugin system
    run oradba_get_product_status "datasafe" "test_instance" "/nonexistent/datasafe/home"
    # Plugin will return lowercase status or unknown
    [ "$status" -eq 1 ]
    [[ "$output" =~ unavailable|unknown ]]
}

@test "get_product_status: datasafe should handle missing home" {
    run oradba_get_product_status "DATASAFE" "test_instance" ""
    # Should fail gracefully
    [ "$status" -eq 1 ]
}

# Test oradba_check_oud_status
@test "check_oud_status: should return UNKNOWN for empty instance" {
    run oradba_check_oud_status ""
    [ "$status" -eq 1 ]
    [ "$output" = "UNKNOWN" ]
}

@test "check_oud_status: should return UNKNOWN for non-existent instance" {
    run oradba_check_oud_status "/nonexistent/oud/instance"
    [ "$status" -eq 1 ]
    [ "$output" = "UNKNOWN" ]
}

# Test oradba_check_wls_status
@test "check_wls_status: should return UNKNOWN for empty domain" {
    run oradba_check_wls_status ""
    [ "$status" -eq 1 ]
    [ "$output" = "UNKNOWN" ]
}

@test "check_wls_status: should return STOPPED for non-running server" {
    run oradba_check_wls_status "/nonexistent/wls/domain"
    [ "$status" -eq 1 ]
    [ "$output" = "STOPPED" ]
}

# Integration tests
@test "integration: all status check functions are exported" {
    # Verify functions are exported
    declare -F oradba_check_db_status | grep -q "oradba_check_db_status"
    declare -F oradba_check_asm_status | grep -q "oradba_check_asm_status"
    declare -F oradba_check_listener_status | grep -q "oradba_check_listener_status"
    declare -F oradba_check_process_running | grep -q "oradba_check_process_running"
    declare -F oradba_check_oud_status | grep -q "oradba_check_oud_status"
    declare -F oradba_check_wls_status | grep -q "oradba_check_wls_status"
    declare -F oradba_get_product_status | grep -q "oradba_get_product_status"
}

@test "get_product_status: should pass instance name to datasafe via plugin" {
    # Test that DATASAFE uses plugin system with instance_name
    # This is validated by checking the function can be called with all parameters
    run oradba_get_product_status "DATASAFE" "test_instance" "/nonexistent/path"
    # Plugin will return lowercase status or fail
    [ "$status" -eq 1 ]
    [[ "$output" =~ unavailable|unknown ]]
}
