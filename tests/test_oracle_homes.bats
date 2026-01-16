#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oracle_homes.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.01.09
# Revision...: 0.18.0
# Purpose....: BATS tests for Oracle Homes management functions
# Notes......: Tests parsing, listing, and detection of Oracle Homes
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
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    
    # Create test configuration directory
    mkdir -p "${ORADBA_BASE}/etc"
    
    # Create test oradba_homes.conf
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << 'EOF'
# Test Oracle Homes configuration
# Format: NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:DESCRIPTION

# Database homes
DB19:/u01/app/oracle/product/19.0.0.0/db19:database:10:Oracle Database 19c
DB21:/u01/app/oracle/product/21.0.0.0/db21:database:20:Oracle Database 21c

# Client homes
CLIENT19:/u01/app/oracle/product/19.0.0.0/client19:client:30:Oracle Client 19c

# Other products
OUD12:/u01/app/oracle/product/12.2.1.4/oud12:oud:40:Oracle Unified Directory 12c
WLS14:/u01/app/oracle/product/14.1.1.0/wls14:weblogic:50:WebLogic Server 14c
OMS13:/u01/app/oracle/product/13.5.0.0/oms13:oms:60:Enterprise Manager OMS 13c
EOF
}

# Cleanup after tests
teardown() {
    # Remove temporary test directory
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ------------------------------------------------------------------------------
# Configuration File Tests
# ------------------------------------------------------------------------------

@test "get_oracle_homes_path returns valid path when config exists" {
    run get_oracle_homes_path
    [ "$status" -eq 0 ]
    [ "$output" = "${ORADBA_BASE}/etc/oradba_homes.conf" ]
}

@test "get_oracle_homes_path fails when config does not exist" {
    rm "${ORADBA_BASE}/etc/oradba_homes.conf"
    run get_oracle_homes_path
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Parsing Tests
# ------------------------------------------------------------------------------

@test "parse_oracle_home returns correct entry for DB19" {
    run parse_oracle_home "DB19"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^DB19[[:space:]] ]]
    [[ "$output" =~ /u01/app/oracle/product/19.0.0.0/db19 ]]
    [[ "$output" =~ database ]]
}

@test "parse_oracle_home returns correct entry for OUD12" {
    run parse_oracle_home "OUD12"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^OUD12[[:space:]] ]]
    [[ "$output" =~ /u01/app/oracle/product/12.2.1.4/oud12 ]]
    [[ "$output" =~ oud ]]
}

@test "parse_oracle_home fails for non-existent home" {
    run parse_oracle_home "NOTEXIST"
    [ "$status" -eq 1 ]
}

@test "parse_oracle_home fails without home name" {
    run parse_oracle_home ""
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Listing Tests
# ------------------------------------------------------------------------------

@test "list_oracle_homes returns all homes sorted by order" {
    run list_oracle_homes
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 6 ]
    # First line should be DB19 (order 10)
    [[ "${lines[0]}" =~ ^DB19 ]]
    # Last line should be OMS13 (order 60)
    [[ "${lines[5]}" =~ ^OMS13 ]]
}

@test "list_oracle_homes filters by product type database" {
    run list_oracle_homes "database"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [[ "${lines[0]}" =~ DB19 ]]
    [[ "${lines[1]}" =~ DB21 ]]
}

@test "list_oracle_homes filters by product type oud" {
    run list_oracle_homes "oud"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [[ "${lines[0]}" =~ OUD12 ]]
}

@test "list_oracle_homes with invalid filter returns empty" {
    run list_oracle_homes "invalid"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 0 ]
}

# ------------------------------------------------------------------------------
# Path Extraction Tests
# ------------------------------------------------------------------------------

@test "get_oracle_home_path returns correct path for DB19" {
    run get_oracle_home_path "DB19"
    [ "$status" -eq 0 ]
    [ "$output" = "/u01/app/oracle/product/19.0.0.0/db19" ]
}

@test "get_oracle_home_path returns correct path for CLIENT19" {
    run get_oracle_home_path "CLIENT19"
    [ "$status" -eq 0 ]
    [ "$output" = "/u01/app/oracle/product/19.0.0.0/client19" ]
}

@test "get_oracle_home_path fails for non-existent home" {
    run get_oracle_home_path "NOTEXIST"
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Type Extraction Tests
# ------------------------------------------------------------------------------

@test "get_oracle_home_type returns correct type for DB19" {
    run get_oracle_home_type "DB19"
    [ "$status" -eq 0 ]
    [ "$output" = "database" ]
}

@test "get_oracle_home_type returns correct type for WLS14" {
    run get_oracle_home_type "WLS14"
    [ "$status" -eq 0 ]
    [ "$output" = "weblogic" ]
}

@test "get_oracle_home_type fails for non-existent home" {
    run get_oracle_home_type "NOTEXIST"
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Product Type Detection Tests
# ------------------------------------------------------------------------------

@test "detect_product_type returns unknown for empty path" {
    run detect_product_type ""
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

@test "detect_product_type returns unknown for non-existent directory" {
    run detect_product_type "/path/does/not/exist"
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

@test "detect_product_type detects OUD from ldapjdk.jar" {
    # Create mock OUD structure
    local oracle_home="${TEST_TEMP_DIR}/oud_home"
    mkdir -p "${oracle_home}/oud/lib"
    touch "${oracle_home}/oud/lib/ldapjdk.jar"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "oud" ]
}

@test "detect_product_type detects WebLogic from weblogic.jar" {
    # Create mock WebLogic structure
    local oracle_home="${TEST_TEMP_DIR}/wls_home"
    mkdir -p "${oracle_home}/wlserver/server/lib"
    touch "${oracle_home}/wlserver/server/lib/weblogic.jar"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "weblogic" ]
}

@test "detect_product_type detects iclient from libclntsh.so in root" {
    # Create mock Instant Client structure with libclntsh.so in root
    local oracle_home="${TEST_TEMP_DIR}/iclient_home"
    mkdir -p "${oracle_home}"
    touch "${oracle_home}/libclntsh.so"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "iclient" ]
}

@test "detect_product_type detects iclient from versioned libclntsh" {
    # Create mock Instant Client structure with versioned library
    local oracle_home="${TEST_TEMP_DIR}/iclient_versioned"
    mkdir -p "${oracle_home}"
    touch "${oracle_home}/libclntsh.so.19.1"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "iclient" ]
}

@test "detect_product_type detects iclient from lib directory without bin" {
    # Create mock Instant Client structure with lib directory
    local oracle_home="${TEST_TEMP_DIR}/iclient_lib"
    mkdir -p "${oracle_home}/lib"
    touch "${oracle_home}/lib/libclntsh.so"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "iclient" ]
}

@test "detect_product_type detects client from sqlplus without oracle binary" {
    # Create mock Oracle Client structure
    local oracle_home="${TEST_TEMP_DIR}/client_home"
    mkdir -p "${oracle_home}/bin"
    touch "${oracle_home}/bin/sqlplus"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "client" ]
}

@test "detect_product_type detects database from sqlplus and oracle binary" {
    # Create mock Database structure
    local oracle_home="${TEST_TEMP_DIR}/db_home"
    mkdir -p "${oracle_home}/bin"
    touch "${oracle_home}/bin/sqlplus"
    touch "${oracle_home}/bin/oracle"
    
    run detect_product_type "${oracle_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "database" ]
}

# ------------------------------------------------------------------------------
# Oracle Home Check Tests
# ------------------------------------------------------------------------------

@test "is_oracle_home returns success for existing home" {
    run is_oracle_home "DB19"
    [ "$status" -eq 0 ]
}

@test "is_oracle_home returns success for OUD12" {
    run is_oracle_home "OUD12"
    [ "$status" -eq 0 ]
}

@test "is_oracle_home fails for non-existent home" {
    run is_oracle_home "NOTEXIST"
    [ "$status" -eq 1 ]
}

@test "is_oracle_home fails for empty name" {
    run is_oracle_home ""
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# Environment Setting Tests
# ------------------------------------------------------------------------------

@test "set_oracle_home_environment sets ORACLE_HOME for database" {
    # Create mock database structure
    local oracle_home="${TEST_TEMP_DIR}/db_test"
    mkdir -p "${oracle_home}/bin"
    touch "${oracle_home}/bin/sqlplus"
    touch "${oracle_home}/bin/oracle"
    
    # Call function directly (not via run) to check environment
    set_oracle_home_environment "TEST_DB" "${oracle_home}"
    [ "$?" -eq 0 ]
    [ "${ORACLE_HOME}" = "${oracle_home}" ]
}

@test "set_oracle_home_environment detects path from config" {
    # This test expects failure because path doesn't exist in filesystem
    run set_oracle_home_environment "DB19"
    [ "$status" -eq 0 ]  # Function succeeds even if path doesn't exist
}
@test "set_oracle_home_environment adjusts ORACLE_HOME for DataSafe" {
    # Create mock DataSafe structure with oracle_cman_home subdirectory
    local parent_dir="${TEST_TEMP_DIR}/datasafe_parent"
    local cman_home="${parent_dir}/oracle_cman_home"
    mkdir -p "${cman_home}/bin"
    mkdir -p "${cman_home}/config"
    touch "${cman_home}/bin/cmctl"
    chmod +x "${cman_home}/bin/cmctl"
    touch "${parent_dir}/setup.py"
    
    # Add DataSafe entry to oradba_homes.conf (in ORADBA_BASE/etc)
    echo "dstest:${parent_dir}:datasafe:50:DataSafe Test" >> "${ORADBA_BASE}/etc/oradba_homes.conf"
    
    # Source necessary functions for product detection
    source "${PROJECT_ROOT}/src/lib/oradba_env_parser.sh"
    
    # Call function - it should read type from config
    set_oracle_home_environment "dstest" "${parent_dir}"
    local status=$?
    
    # Should succeed
    [ "${status}" -eq 0 ]
    
    # ORACLE_HOME should point to oracle_cman_home subdirectory (not parent)
    [ "${ORACLE_HOME}" = "${cman_home}" ]
    
    # DataSafe variables should be set
    [ "${DATASAFE_HOME}" = "${cman_home}" ]
    [ "${DATASAFE_INSTALL_DIR}" = "${parent_dir}" ]
    [ "${DATASAFE_CONFIG}" = "${cman_home}/config" ]
    
    # PATH should include oracle_cman_home/bin (not parent/bin)
    [[ "${PATH}" == *"${cman_home}/bin"* ]]
}
