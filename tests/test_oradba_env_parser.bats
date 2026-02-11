#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_parser.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Unit tests for oradba_env_parser.sh
# Notes......: Run with: bats tests/test_oradba_env_parser.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Test setup
setup() {
    # Set ORADBA_BASE to repo src directory
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export ORADBA_BASE
    
    # Create temporary test files
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp}"
    export TEST_ORATAB="${BATS_TMPDIR}/oratab.$$"
    export TEST_HOMES_CONF="${BATS_TMPDIR}/oradba_homes.conf.$$"
    export ORATAB_FILE="$TEST_ORATAB"
    
    # Source the parser
    source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
    
    # Create test oratab
    cat > "$TEST_ORATAB" <<EOF
# Test oratab file
ORCL:/u01/app/oracle/product/19.0.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/21.0.0.0/dbhome_1:Y
+ASM:/u01/app/19.0.0.0/grid:N
EOF

    # Create test oradba_homes.conf
    cat > "$TEST_HOMES_CONF" <<EOF
# Test oradba_homes.conf (Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION)
DB19:/u01/app/oracle/product/19.0.0.0/dbhome_1:RDBMS:10:db19:Oracle 19c EE:19.0.0.0.0
CL19:/opt/oracle/product/19c/client:CLIENT:30:cl19:Oracle Client 19c:19.0.0.0.0
IC19:/opt/oracle/instantclient_19_19:ICLIENT:40:ic19:Instant Client 19.19:19.19.0.0.0
GRID19:/u01/app/19.0.0.0/grid:GRID:15:grid19:Grid Infrastructure 19c:19.0.0.0.0
EOF
}

# Test teardown
teardown() {
    rm -f "$TEST_ORATAB" "$TEST_HOMES_CONF"
}

# Test: oradba_parse_oratab - basic functionality
@test "oradba_parse_oratab parses oratab correctly" {
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ ORCL\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|N ]]
    [[ "${lines[1]}" =~ TESTDB\|/u01/app/oracle/product/21.0.0.0/dbhome_1\|Y ]]
    [[ "${lines[2]}" =~ \+ASM\|/u01/app/19.0.0.0/grid\|N ]]
}

# Test: oradba_parse_oratab - ignores comments and empty lines
@test "oradba_parse_oratab ignores comments" {
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]  # Only 3 entries, no comment lines
}

# Test: oradba_parse_homes - basic functionality
@test "oradba_parse_homes parses oradba_homes.conf correctly" {
    run oradba_parse_homes "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ DB19\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|RDBMS\|10\|db19\|Oracle\ 19c\ EE\|19.0.0.0.0 ]]
}

# Test: oradba_find_sid - find existing SID
@test "oradba_find_sid finds existing SID" {
    run oradba_find_sid "ORCL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ORCL\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|N ]]
}

# Test: oradba_find_sid - non-existent SID
@test "oradba_find_sid returns error for non-existent SID" {
    run oradba_find_sid "NONEXIST"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

# Test: oradba_find_sid - ASM instance
@test "oradba_find_sid finds ASM instance" {
    run oradba_find_sid "+ASM"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \+ASM\|/u01/app/19.0.0.0/grid\|N ]]
}

# Test: oradba_find_home - find existing home
@test "oradba_find_home finds existing home" {
    run oradba_find_home "DB19" "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "RDBMS" ]]
}

# Test: oradba_find_home - non-existent home
@test "oradba_find_home returns error for non-existent home" {
    run oradba_find_home "/nonexistent/path" "$TEST_HOMES_CONF"
    [ "$status" -eq 1 ]
}

# Test: oradba_get_home_metadata - extract Type field (backward compat: Product→Type)
@test "oradba_get_home_metadata extracts Product field" {
    run oradba_get_home_metadata "DB19" "Type" "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [ "$output" = "RDBMS" ]
}

# Test: oradba_get_home_metadata - extract Version field
@test "oradba_get_home_metadata extracts Version field" {
    run oradba_get_home_metadata "CL19" "Version" "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [ "$output" = "19.0.0.0.0" ]
}

# Test: oradba_get_home_metadata - extract Name field (backward compat: Short_Name→Name)
@test "oradba_get_home_metadata extracts Short_Name field" {
    run oradba_get_home_metadata "IC19" "Name" "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [ "$output" = "IC19" ]
}

# Test: oradba_get_home_metadata - invalid field returns N/A
@test "oradba_get_home_metadata returns N/A for invalid field" {
    run oradba_get_home_metadata "DB19" "InvalidField" "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [ "$output" = "N/A" ]
}

# Test: oradba_list_all_sids - list all SIDs
@test "oradba_list_all_sids lists all SIDs from oratab" {
    run oradba_list_all_sids
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [[ "$output" =~ ORCL ]]
    [[ "$output" =~ TESTDB ]]
    [[ "$output" =~ \+ASM ]]
}

# Test: oradba_list_all_homes - list sorted by position
@test "oradba_list_all_homes lists homes sorted by position" {
    run oradba_list_all_homes "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    # First should be Order 10 (DB19), last should be Order 40 (IC19)
    [[ "${lines[0]}" =~ ^DB19\| ]]
    [[ "${lines[-1]}" =~ ^IC19\| ]]
}

# Test: oradba_get_product_type - detect RDBMS
@test "oradba_get_product_type detects RDBMS from sqlplus" {
    # Create mock ORACLE_HOME structure
    local test_home="${BATS_TMPDIR}/oracle_home_$$"
    mkdir -p "${test_home}/bin"
    mkdir -p "${test_home}/rdbms/lib"
    touch "${test_home}/bin/sqlplus"
    
    run oradba_get_product_type "$test_home"
    [ "$status" -eq 0 ]
    [ "$output" = "RDBMS" ]
    
    rm -rf "$test_home"
}

# Test: oradba_get_product_type - detect CLIENT
@test "oradba_get_product_type detects CLIENT from sqlplus without rdbms" {
    # Create mock CLIENT structure
    local test_home="${BATS_TMPDIR}/client_home_$$"
    mkdir -p "${test_home}/bin"
    touch "${test_home}/bin/sqlplus"
    
    run oradba_get_product_type "$test_home"
    [ "$status" -eq 0 ]
    [ "$output" = "CLIENT" ]
    
    rm -rf "$test_home"
}

# Test: oradba_get_product_type - detect ICLIENT
@test "oradba_get_product_type detects ICLIENT from libclntsh" {
    # Create mock Instant Client structure
    local test_home="${BATS_TMPDIR}/instantclient_$$"
    mkdir -p "${test_home}"
    touch "${test_home}/libclntsh.so"
    
    run oradba_get_product_type "$test_home"
    [ "$status" -eq 0 ]
    [ "$output" = "ICLIENT" ]
    
    rm -rf "$test_home"
}

# Test: oradba_get_product_type - detect GRID
@test "oradba_get_product_type detects GRID from crsctl" {
    # Create mock Grid structure
    local test_home="${BATS_TMPDIR}/grid_home_$$"
    mkdir -p "${test_home}/bin"
    touch "${test_home}/bin/crsctl"
    
    run oradba_get_product_type "$test_home"
    [ "$status" -eq 0 ]
    [ "$output" = "GRID" ]
    
    rm -rf "$test_home"
}

# Test: oradba_parse_homes - handles whitespace
@test "oradba_parse_homes trims whitespace correctly" {
    # Create test file with extra whitespace
    local test_file="${BATS_TMPDIR}/whitespace_test.$$"
    cat > "$test_file" <<EOF
  SHORT  :  /path/to/home  :  RDBMS  :  10  :  short  :  Description  :  19.0.0.0.0  
EOF
    
    run oradba_parse_homes "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ SHORT\|/path/to/home\|RDBMS\|10\|short\|Description\|19.0.0.0.0 ]]
    
    rm -f "$test_file"
}

# Test: oradba_parse_homes - handles default values
@test "oradba_parse_homes applies default values for empty fields" {
    # Create test file with missing fields (NAME:PATH:TYPE:ORDER:ALIAS:DESC:VERSION)
    local test_file="${BATS_TMPDIR}/defaults_test.$$"
    cat > "$test_file" <<EOF
TEST:/path/to/home::::
EOF
    
    run oradba_parse_homes "$test_file"
    [ "$status" -eq 0 ]
    # Should have default order=50, alias=TEST (same as name), version=AUTO
    [[ "$output" =~ TEST\|/path/to/home\|\|50\|TEST\|\|AUTO ]]
    
    rm -f "$test_file"
}

# Test: Empty oratab file
@test "oradba_parse_oratab handles empty file" {
    echo "" > "$TEST_ORATAB"
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# Test: Malformed oratab entry
@test "oradba_parse_oratab skips malformed entries" {
    echo "BADENTRY" > "$TEST_ORATAB"
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
