#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_parser_unit.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Unit tests for oradba_env_parser.sh with dependency injection
# Notes......: Tests DI infrastructure, mocked logging, and stateless execution
#              Run with: bats tests/test_oradba_env_parser_unit.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Test setup
setup() {
    # Set ORADBA_BASE to src directory
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export ORADBA_BASE
    
    # Create temporary test files
    export BATS_TMPDIR="${BATS_TMPDIR:-/tmp}"
    export TEST_ORATAB="${BATS_TMPDIR}/oratab.$$"
    export TEST_HOMES_CONF="${BATS_TMPDIR}/oradba_homes.conf.$$"
    export ORATAB_FILE="$TEST_ORATAB"
    
    # Mock logger for testing
    export MOCK_LOG_CALLS=0
    export MOCK_LOG_FILE="${BATS_TMPDIR}/mock_log.$$.txt"
    rm -f "$MOCK_LOG_FILE"
    
    # Define mock logger function
    mock_logger() {
        MOCK_LOG_CALLS=$((MOCK_LOG_CALLS + 1))
        echo "[MOCK] $*" >> "$MOCK_LOG_FILE"
    }
    export -f mock_logger
    
    # Source the parser without oradba_common dependency
    source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
    
    # Create test oratab
    cat > "$TEST_ORATAB" <<'EOF'
# Test oratab file
ORCL:/u01/app/oracle/product/19.0.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/21.0.0.0/dbhome_1:Y
+ASM:/u01/app/19.0.0.0/grid:N
EOF

    # Create test oradba_homes.conf
    cat > "$TEST_HOMES_CONF" <<'EOF'
# Test oradba_homes.conf (Format: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION)
DB19:/u01/app/oracle/product/19.0.0.0/dbhome_1:RDBMS:10:db19:Oracle 19c EE:19.0.0.0.0
CL19:/opt/oracle/product/19c/client:CLIENT:30:cl19:Oracle Client 19c:19.0.0.0.0
IC19:/opt/oracle/instantclient_19_19:ICLIENT:40:ic19:Instant Client 19.19:19.19.0.0.0
GRID19:/u01/app/19.0.0.0/grid:GRID:15:grid19:Grid Infrastructure 19c:19.0.0.0.0
EOF
}

# Test teardown
teardown() {
    rm -f "$TEST_ORATAB" "$TEST_HOMES_CONF" "$MOCK_LOG_FILE"
    unset MOCK_LOG_CALLS
    unset ORADBA_PARSER_LOGGER
}

# ==============================================================================
# Dependency Injection Tests
# ==============================================================================

@test "parser: init without arguments creates default state" {
    run oradba_parser_init
    [ "$status" -eq 0 ]
    [ -z "$ORADBA_PARSER_LOGGER" ]
}

@test "parser: init with custom logger stores logger reference" {
    oradba_parser_init "mock_logger"
    [ "$ORADBA_PARSER_LOGGER" = "mock_logger" ]
}

@test "parser: internal log function is no-op when no logger configured" {
    ORADBA_PARSER_LOGGER=""
    run _oradba_parser_log DEBUG "test message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parser: internal log function calls injected logger" {
    oradba_parser_init "mock_logger"
    _oradba_parser_log DEBUG "test message"
    [ -f "$MOCK_LOG_FILE" ]
    grep -q "test message" "$MOCK_LOG_FILE"
}

# ==============================================================================
# Stateless Execution Tests
# ==============================================================================

@test "parser: works without oradba_common sourced" {
    # Parser should work standalone
    run oradba_parse_oratab "ORCL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ORCL\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|N ]]
}

@test "parser: multiple init calls don't break functionality" {
    oradba_parser_init "mock_logger"
    oradba_parser_init "mock_logger"
    oradba_parser_init "mock_logger"
    
    run oradba_parse_oratab "TESTDB"
    [ "$status" -eq 0 ]
    [[ "$output" =~ TESTDB\|/u01/app/oracle/product/21.0.0.0/dbhome_1\|Y ]]
}

# ==============================================================================
# Core Functionality Tests (with DI)
# ==============================================================================

@test "parser: parse_oratab works with injected logger" {
    oradba_parser_init "mock_logger"
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ ORCL\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|N ]]
}

@test "parser: parse_homes works with injected logger" {
    oradba_parser_init "mock_logger"
    run oradba_parse_homes "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ DB19\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|RDBMS ]]
}

@test "parser: find_sid works in isolation" {
    # No init, no logger - should still work
    run oradba_find_sid "ORCL"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ORCL\|/u01/app/oracle/product/19.0.0.0/dbhome_1\|N ]]
}

# ==============================================================================
# Edge Cases and Error Handling
# ==============================================================================

@test "parser: handles missing oratab file gracefully" {
    ORATAB_FILE="/nonexistent/oratab"
    run oradba_parse_oratab
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "parser: handles missing homes.conf file gracefully" {
    run oradba_parse_homes "/nonexistent/homes.conf"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "parser: handles empty oratab file" {
    echo "" > "$TEST_ORATAB"
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parser: find_sid returns error for non-existent SID" {
    oradba_parser_init "mock_logger"
    run oradba_find_sid "NONEXIST"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

# ==============================================================================
# Backward Compatibility Tests
# ==============================================================================

@test "parser: works without init (legacy mode)" {
    # Don't call oradba_parser_init - should work with no logging
    run oradba_parse_oratab
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "parser: all functions work without DI" {
    # Test all public functions work standalone
    run oradba_parse_oratab "ORCL"
    [ "$status" -eq 0 ]
    
    run oradba_parse_homes "$TEST_HOMES_CONF" "DB19"
    [ "$status" -eq 0 ]
    
    run oradba_list_all_sids
    [ "$status" -eq 0 ]
    
    run oradba_list_all_homes "$TEST_HOMES_CONF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Performance and Isolation Tests
# ==============================================================================

@test "parser: does not pollute global environment" {
    # Count variables before
    local vars_before
    vars_before=$(compgen -v | wc -l)
    
    oradba_parser_init "mock_logger"
    oradba_parse_oratab >/dev/null
    
    # Count variables after (allow for test framework variables)
    local vars_after
    vars_after=$(compgen -v | wc -l)
    
    # Should have minimal variable growth (allow more for test environment)
    [ "$((vars_after - vars_before))" -lt 15 ]
}

@test "parser: init is idempotent" {
    local logger1="mock_logger"
    local logger2="mock_logger"
    
    oradba_parser_init "$logger1"
    local state1="$ORADBA_PARSER_LOGGER"
    
    oradba_parser_init "$logger2"
    local state2="$ORADBA_PARSER_LOGGER"
    
    [ "$state1" = "$state2" ]
}
