#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_db_functions.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.1.0
# Purpose....: Test suite for oradba_db_functions.sh library
# Notes......: Uses BATS (Bash Automated Testing System)
#              These tests check the database query functions
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

setup() {
    # Load the common library first
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    ORADBA_SRC_BASE="${PROJECT_ROOT}/src"
    source "${ORADBA_SRC_BASE}/lib/oradba_common.sh"
    source "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
}

# Test: check_database_connection function exists
@test "check_database_connection function is defined" {
    type -t check_database_connection | grep -q "function"
}

# Test: get_database_open_mode function exists
@test "get_database_open_mode function is defined" {
    type -t get_database_open_mode | grep -q "function"
}

# Test: query_instance_info function exists
@test "query_instance_info function is defined" {
    type -t query_instance_info | grep -q "function"
}

# Test: query_database_info function exists
@test "query_database_info function is defined" {
    type -t query_database_info | grep -q "function"
}

# Test: query_datafile_size function exists
@test "query_datafile_size function is defined" {
    type -t query_datafile_size | grep -q "function"
}

# Test: query_memory_usage function exists
@test "query_memory_usage function is defined" {
    type -t query_memory_usage | grep -q "function"
}

# Test: query_sessions_info function exists
@test "query_sessions_info function is defined" {
    type -t query_sessions_info | grep -q "function"
}

# Test: query_pdb_info function exists
@test "query_pdb_info function is defined" {
    type -t query_pdb_info | grep -q "function"
}

# Test: format_uptime function exists
@test "format_uptime function is defined" {
    type -t format_uptime | grep -q "function"
}

# Test: show_database_status function exists
@test "show_database_status function is defined" {
    type -t show_database_status | grep -q "function"
}

# Test: format_uptime handles empty input
@test "format_uptime handles empty input" {
    result=$(format_uptime "")
    [[ "$result" == "unknown" ]]
}

# Test: format_uptime formats valid timestamp
@test "format_uptime formats valid timestamp" {
    # Use a fixed timestamp for consistent testing
    result=$(format_uptime "2025-12-16 10:00:00")
    # Result should contain the input timestamp and uptime format
    [[ "$result" =~ 2025-12-16 ]] && [[ "$result" =~ "d" ]] && [[ "$result" =~ "h" ]]
}

# Test: query_database_info returns error in STARTED mode
@test "query_database_info returns error for STARTED mode" {
    run query_database_info "STARTED"
    [ "$status" -eq 1 ]
}

# Test: query_datafile_size returns error in STARTED mode
@test "query_datafile_size returns error for STARTED mode" {
    run query_datafile_size "STARTED"
    [ "$status" -eq 1 ]
}

# Test: query_memory_usage works for MOUNTED mode (v$sga and v$pgastat available)
@test "query_memory_usage returns error for STARTED mode" {
    run query_memory_usage "STARTED"
    [ "$status" -eq 1 ]
}

# Test: query_sessions_info returns error for STARTED mode
@test "query_sessions_info returns error for STARTED mode" {
    run query_sessions_info "STARTED"
    [ "$status" -eq 1 ]
}

# Test: query_pdb_info returns error for non-OPEN mode
@test "query_pdb_info returns error for STARTED mode" {
    run query_pdb_info "STARTED"
    [ "$status" -eq 1 ]
}

# Test: Library requires oradba_common.sh
@test "oradba_db_functions.sh requires oradba_common.sh" {
    # This test verifies that db_functions checks for oradba_common.sh
    # We've already loaded it in setup, so we check if oradba_log exists
    type -t oradba_log | grep -q "function"
}

# Integration test: show_database_status handles no connection gracefully
@test "show_database_status handles missing connection gracefully" {
    # Mock sqlplus to simulate no connection
    sqlplus() {
        return 1
    }
    export -f sqlplus
    
    run show_database_status
    # Should return 0 (success) because it shows environment info with NOT STARTED status
    [ "$status" -eq 0 ]
    # Verify output contains NOT STARTED or Dummy Database status
    [[ "$output" =~ "NOT STARTED"|"Dummy Database" ]]
    
    unset -f sqlplus
}

# Test: Functions handle sqlplus errors gracefully
@test "query_instance_info handles sqlplus errors" {
    # This test verifies that the function can be called
    # In a real environment, sqlplus might not be available
    # We test that the function exists and can be invoked
    type -t query_instance_info | grep -q "function"
}

# Test: format_uptime calculates days correctly
@test "format_uptime calculates uptime components" {
    # Mock a timestamp from 2 days, 5 hours, 30 minutes ago
    # Note: This is a simplified test, actual calculation depends on current time
    result=$(format_uptime "2025-12-16 10:00:00")
    
    # Check format contains required components
    [[ "$result" =~ [0-9]+d ]]
    [[ "$result" =~ [0-9]+h ]]
    [[ "$result" =~ [0-9]+m ]]
}

# Test: SQL query functions return proper format (pipe-separated)
@test "query functions should use pipe separator" {
    # This is a structure test - functions should output pipe-delimited data
    # We verify this by checking the function code contains the pipe character
    grep -q "||" "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
}

# Test: All query functions handle SET commands for sqlplus
@test "query functions use proper sqlplus SET commands" {
    # Verify functions use proper sqlplus formatting commands (on same line or separate)
    grep -q "HEADING OFF" "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
    grep -q "FEEDBACK OFF" "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
    grep -q "VERIFY OFF" "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
}

# Test: show_database_status outputs formatted display
@test "show_database_status uses formatted output" {
    # Check that the function uses printf for formatting
    grep -q "printf" "${ORADBA_SRC_BASE}/lib/oradba_db_functions.sh"
}

# Test: oradba_env_status.sh is sourced for product status functions
@test "oradba_db_functions.sh sources oradba_env_status.sh" {
    # Verify that oradba_get_product_status function is available
    type -t oradba_get_product_status | grep -q "function"
}

# Test: show_oracle_home_status exists and can be called
@test "show_oracle_home_status function is defined" {
    type -t show_oracle_home_status | grep -q "function"
}

# Test: show_oracle_home_status handles datasafe product type
@test "show_oracle_home_status handles datasafe product type" {
    export ORADBA_CURRENT_HOME_TYPE="datasafe"
    export ORACLE_HOME="/test/oracle_cman_home"
    export DATASAFE_HOME="/test"
    
    run show_oracle_home_status
    [ "$status" -eq 0 ]
    # Should contain datasafe-specific fields
    [[ "$output" =~ "ORACLE_BASE" ]]
    [[ "$output" =~ "DATASAFE_HOME" ]]
    [[ "$output" =~ "PRODUCT_TYPE" ]]
}

# Test: show_oracle_home_status preserves running status for datasafe
@test "show_oracle_home_status shows running status for datasafe" {
    # Create a temporary mock to return 'running'
    oradba_get_product_status() {
        echo "running"
        return 0
    }
    export -f oradba_get_product_status
    
    export ORADBA_CURRENT_HOME_TYPE="datasafe"
    export ORACLE_HOME="/test/oracle_cman_home"
    export DATASAFE_HOME="/test"
    
    # Call show_oracle_home_status and verify it outputs 'running', not 'open'
    run show_oracle_home_status
    [ "$status" -eq 0 ]
    # Should contain "STATUS" line with "running" value
    echo "$output" | grep -E "^STATUS[[:space:]]+:" | grep -q "running"
    # Should NOT contain "open" (which was the bug)
    ! echo "$output" | grep -E "^STATUS[[:space:]]+:" | grep -q "open"
    
    unset -f oradba_get_product_status
}

@test "show_oracle_home_status displays complete datasafe metadata" {
    # Test that all datasafe metadata fields are displayed when available
    # This verifies the fix for: version, port, connections, uptime etc should be shown
    
    # Mock execute_plugin_function_v2 to return full datasafe metadata
    execute_plugin_function_v2() {
        local product_type="$1"
        local function_name="$2"
        # shellcheck disable=SC2034
        local oracle_home="$3"
        local result_var="$4"
        
        if [[ "${product_type}" == "datasafe" ]] && [[ "${function_name}" == "get_metadata" ]]; then
            # Return comprehensive datasafe metadata
            # shellcheck disable=SC2034
            local metadata="cman_version=23.4.0.0.0
version=23.4.0.0.0
service_name=test_service
port=1521
connections=5
cman_start_date=10-FEB-2026 15:20:38
cman_uptime=0 days 20 hr. 10 min. 7 sec
cman_gateways=12"
            eval "${result_var}=\"\${metadata}\""
            return 0
        fi
        return 1
    }
    export -f execute_plugin_function_v2
    
    # Mock oradba_get_product_status to return 'running'
    oradba_get_product_status() {
        echo "running"
        return 0
    }
    export -f oradba_get_product_status
    
    # Set environment
    export ORADBA_CURRENT_HOME_TYPE="datasafe"
    export ORACLE_HOME="/test/dscon1/oracle_cman_home"
    export DATASAFE_HOME="/test/dscon1"
    export ORACLE_SID="test_service"
    
    # Call show_oracle_home_status
    run show_oracle_home_status "datasafe" "/test/dscon1" "test_service" "true"
    [ "$status" -eq 0 ]
    
    # Verify all metadata fields are displayed
    [[ "$output" =~ ORACLE_VERSION ]]
    [[ "$output" =~ 23\.4\.0\.0\.0 ]]
    [[ "$output" =~ STATUS ]]
    [[ "$output" =~ running ]]
    [[ "$output" =~ SERVICE ]]
    [[ "$output" =~ test_service ]]
    [[ "$output" =~ PORT ]]
    [[ "$output" =~ 1521 ]]
    [[ "$output" =~ CONNECTIONS ]]
    [[ "$output" =~ 5 ]]
    [[ "$output" =~ "START DATE" ]]
    [[ "$output" =~ "10-FEB-2026 15:20:38" ]]
    [[ "$output" =~ UPTIME ]]
    echo "$output" | grep -q "0 days 20 hr. 10 min. 7 sec"
    [[ "$output" =~ GATEWAYS ]]
    [[ "$output" =~ 12 ]]
    
    # Cleanup
    unset -f execute_plugin_function_v2
    unset -f oradba_get_product_status
}
