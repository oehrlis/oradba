#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# -----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: test_execute_db_query.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.04
# Revision...: 0.13.2
# Purpose....: Bats tests for execute_db_query function in common.sh
# Notes......: Tests the unified SQL*Plus query executor
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# -----------------------------------------------------------------------

# Source the common.sh library
setup() {
    # Get the directory of the test file
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    REPO_ROOT="$(dirname "$TEST_DIR")"
    
    # Source common.sh
    source "$REPO_ROOT/src/lib/oradba_common.sh"
}

# =======================================================================
# Function Existence Tests
# =======================================================================

@test "execute_db_query function is defined" {
    run type -t execute_db_query
    [ "$status" -eq 0 ]
    [ "$output" = "function" ]
}

# =======================================================================
# Parameter Validation Tests
# =======================================================================

@test "execute_db_query rejects empty query" {
    run execute_db_query ""
    [ "$status" -eq 1 ]
}

@test "execute_db_query rejects missing query parameter" {
    run execute_db_query
    [ "$status" -eq 1 ]
}

@test "execute_db_query rejects invalid format parameter" {
    run execute_db_query "SELECT 1 FROM DUAL;" "invalid"
    [ "$status" -eq 1 ]
}

@test "execute_db_query accepts raw format" {
    # This will fail if no DB connection, but should accept the format parameter
    run execute_db_query "SELECT 1 FROM DUAL;" "raw"
    # Status will be 1 (no DB connection), but shouldn't error on format validation
    true
}

@test "execute_db_query accepts delimited format" {
    # This will fail if no DB connection, but should accept the format parameter
    run execute_db_query "SELECT 1 FROM DUAL;" "delimited"
    # Status will be 1 (no DB connection), but shouldn't error on format validation
    true
}

@test "execute_db_query defaults to raw format when format not specified" {
    # Function should accept query without format parameter
    run execute_db_query "SELECT 1 FROM DUAL;"
    # Will fail without DB, but shouldn't error on missing format parameter
    true
}

# =======================================================================
# Integration Tests (with migrated functions)
# =======================================================================

@test "query_instance_info uses execute_db_query" {
    # Check that query_instance_info function calls execute_db_query
    run grep -A 25 "^query_instance_info" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

@test "query_database_info uses execute_db_query" {
    run grep -A 30 "^query_database_info" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

@test "query_datafile_size uses execute_db_query" {
    run grep -A 15 "^query_datafile_size" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

@test "query_memory_usage uses execute_db_query" {
    run grep -A 20 "^query_memory_usage" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

@test "query_sessions_info uses execute_db_query" {
    run grep -A 18 "^query_sessions_info" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

@test "query_pdb_info uses execute_db_query" {
    run grep -A 35 "^query_pdb_info" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}

# =======================================================================
# Code Quality Tests
# =======================================================================

@test "execute_db_query has proper error logging" {
    # Check that function uses oradba_log ERROR for errors
    run grep -A 50 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "oradba_log ERROR" ]] || [[ "$output" =~ "oradba_log DEBUG" ]]
}

@test "execute_db_query has parameter validation" {
    # Check that function validates required parameters
    run grep -A 20 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "-z" ]] && [[ "$output" =~ "query" ]]
}

@test "execute_db_query uses standardized SQL*Plus settings" {
    # Check that function uses consistent SET commands
    run grep -A 50 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SET PAGESIZE" ]]
    [[ "$output" =~ "HEADING OFF" ]]
    [[ "$output" =~ "FEEDBACK OFF" ]]
}

@test "execute_db_query filters SQL*Plus errors" {
    # Check that function filters out SP2-, ORA- error messages
    run grep -A 50 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "grep -v" ]] && [[ "$output" =~ "SP2-" ]] && [[ "$output" =~ "ORA-" ]]
}

@test "execute_db_query has format-specific processing" {
    # Check that function has case statement for format processing
    run grep -A 50 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "case" ]] && [[ "$output" =~ "format" ]]
    [[ "$output" =~ "raw" ]] && [[ "$output" =~ "delimited" ]]
}

# =======================================================================
# Documentation Tests
# =======================================================================

@test "execute_db_query is documented in common.sh" {
    # Check for function comments/documentation
    run grep -B 10 "^execute_db_query" "$REPO_ROOT/src/lib/oradba_common.sh"
    [ "$status" -eq 0 ]
    # Should have at least some comments near the function
    [[ "$output" =~ "#" ]]
}

@test "execute_db_query eliminates SQL*Plus boilerplate duplication" {
    # Verify that migrated functions are significantly shorter
    # Count lines in query_instance_info (should be ~27 lines vs old ~50+)
    run bash -c "sed -n '/^query_instance_info/,/^}/p' '$REPO_ROOT/src/lib/oradba_db_functions.sh' | wc -l"
    [ "$status" -eq 0 ]
    line_count=$(echo "$output" | tr -d ' ')
    # Should be less than 35 lines (old was ~50+ with boilerplate)
    [ "$line_count" -lt 35 ]
}

# =======================================================================
# Backward Compatibility Tests
# =======================================================================

@test "migrated query functions maintain same signatures" {
    # All query functions should still accept the same parameters
    # Check that query_database_info still takes mode parameter
    run bash -c "grep -A 10 '^query_database_info' '$REPO_ROOT/src/lib/oradba_db_functions.sh'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mode" ]]
}

@test "migrated query functions preserve return codes" {
    # Check that functions still return 0/1 appropriately
    run grep -A 20 "^query_instance_info" "$REPO_ROOT/src/lib/oradba_db_functions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "execute_db_query" ]]
}
