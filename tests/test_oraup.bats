#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset
# ------------------------------------------------------------------------------
# Name.......: test_oraup.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.6.1
# Purpose....: BATS tests for oraup.sh
# Notes......: Tests database status detection and Oracle version support
# ------------------------------------------------------------------------------

# Setup - runs before each test
setup() {
    # Get project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    
    # Path to oraup.sh script
    ORAUP_SCRIPT="${PROJECT_ROOT}/src/bin/oraup.sh"
}

# ------------------------------------------------------------------------------
# Basic Script Tests
# ------------------------------------------------------------------------------

@test "oraup.sh script exists and is executable" {
    [ -f "${ORAUP_SCRIPT}" ]
    [ -x "${ORAUP_SCRIPT}" ]
}

@test "oraup.sh has correct shebang" {
    head -1 "${ORAUP_SCRIPT}" | grep -q "^#!/usr/bin/env bash"
}

@test "oraup.sh shows help with -h" {
    run "${ORAUP_SCRIPT}" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Oracle environment status" ]]
}

@test "oraup.sh shows help with --help" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Content and Functionality Tests
# ------------------------------------------------------------------------------

@test "oraup.sh contains get_db_status function" {
    grep -q "get_db_status()" "${ORAUP_SCRIPT}"
}

@test "oraup.sh get_db_status checks for db_pmon_ (Oracle 23ai)" {
    grep "db_pmon_" "${ORAUP_SCRIPT}" | grep -q "grep"
}

@test "oraup.sh get_db_status checks for ora_pmon_ (pre-23ai)" {
    grep "ora_pmon_" "${ORAUP_SCRIPT}" | grep -q "grep"
}

@test "oraup.sh get_db_status uses regex for both patterns" {
    grep -q "grep -E" "${ORAUP_SCRIPT}"
    grep "grep -E" "${ORAUP_SCRIPT}" | grep -q "db_pmon_\|ora_pmon_"
}

@test "oraup.sh contains get_listener_status function" {
    grep -q "get_listener_status()" "${ORAUP_SCRIPT}"
}

@test "oraup.sh contains get_db_mode function" {
    grep -q "get_db_mode()" "${ORAUP_SCRIPT}"
}

# ------------------------------------------------------------------------------
# Oracle Version Support Tests
# ------------------------------------------------------------------------------

@test "oraup.sh help mentions Oracle version support" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "23ai" || "$output" =~ "11g" ]]
}

@test "oraup.sh help mentions both process naming conventions" {
    run "${ORAUP_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ora_pmon" && "$output" =~ "db_pmon" ]]
}

# ------------------------------------------------------------------------------
# Command Line Options Tests
# ------------------------------------------------------------------------------

@test "oraup.sh accepts --verbose option" {
    run "${ORAUP_SCRIPT}" --verbose --help
    [ "$status" -eq 0 ]
}

@test "oraup.sh accepts --quiet option" {
    run "${ORAUP_SCRIPT}" --quiet --help
    [ "$status" -eq 0 ]
}

@test "oraup.sh rejects invalid options" {
    run "${ORAUP_SCRIPT}" --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown option" ]]
}

# ------------------------------------------------------------------------------
# Code Quality Tests
# ------------------------------------------------------------------------------

@test "oraup.sh converts SID to lowercase for ora_pmon matching" {
    grep -A 5 "get_db_status()" "${ORAUP_SCRIPT}" | grep -q "sid_lower="
    grep -A 5 "get_db_status()" "${ORAUP_SCRIPT}" | grep -q ",,"
}

@test "oraup.sh uses extended regex for dual pattern matching" {
    # Should use grep -E with alternation pattern
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep -q "grep -E.*|"
}

@test "oraup.sh checks both uppercase and lowercase SID patterns" {
    # Verify the pattern includes both ${sid} and ${sid_lower}
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep "grep -E" | grep -q "\${sid}"
    grep "get_db_status" -A 10 "${ORAUP_SCRIPT}" | grep "grep -E" | grep -q "\${sid_lower}"
}

# ------------------------------------------------------------------------------
# Architecture Tests (Registry API)
# ------------------------------------------------------------------------------

@test "oraup.sh uses registry API for Oracle installations" {
    # Check that oraup uses oradba_registry_get_all from registry
    grep -q "oradba_registry_get_all" "${ORAUP_SCRIPT}"
}

@test "oraup.sh delegates to show_oracle_status_registry" {
    # Verify that show_oracle_status_registry handles display logic
    grep -q "show_oracle_status_registry" "${ORAUP_SCRIPT}"
}

# ------------------------------------------------------------------------------
# Display Logic Tests (Issue #99)
# ------------------------------------------------------------------------------

@test "oraup.sh skips dummy entries in Oracle Homes section" {
    # Verify that oraup.sh checks for flag 'D' and marks as dummy
    grep -q 'flags.*==.*"D"' "${ORAUP_SCRIPT}"
}

@test "oraup.sh has listener section visibility logic" {
    # Verify that listener section checks for database SIDs or running listeners
    grep -q "total_databases" "${ORAUP_SCRIPT}" && \
    grep -q "has_database_listeners" "${ORAUP_SCRIPT}"
}

@test "oraup.sh uses oradba_get_product_status for Data Safe" {
    # Verify that Data Safe status uses modern plugin architecture (same as oradba_env.sh)
    grep -q "oradba_get_product_status" "${ORAUP_SCRIPT}"
}

@test "oraup.sh does not hardcode Data Safe status" {
    # Verify that status is retrieved dynamically, not hardcoded to N/A
    ! grep -E 'status=.*"N/A".*datasafe' "${ORAUP_SCRIPT}"
}

@test "oraup.sh listener section checks database existence" {
    # Verify logic: listener section shown only if databases exist or listeners running
    # Check that the code has conditional logic for showing listener section
    grep -q "total_databases\|has_database_listeners\|show.*listener" "${ORAUP_SCRIPT}"
}

# ------------------------------------------------------------------------------
# Optimization Tests (Issue: Parallel status checks & batch process detection)
# ------------------------------------------------------------------------------

@test "oraup.sh has get_process_list function for batch detection" {
    # Verify that batch process detection helper exists
    grep -q "get_process_list()" "${ORAUP_SCRIPT}"
}

@test "oraup.sh get_db_status accepts cached process list" {
    # Verify that get_db_status can use cached process list as second argument
    grep -A 10 "get_db_status()" "${ORAUP_SCRIPT}" | grep -q "process_list"
}

@test "oraup.sh implements parallel DataSafe status checks" {
    # Verify parallel execution for DataSafe connectors (background jobs with &)
    # Check for background job comment
    grep -q "Background job to get status and port" "${ORAUP_SCRIPT}"
    # Check for subshell backgrounding
    sed -n '/SECTION 4: Data Safe Connectors/,/SECTION/p' "${ORAUP_SCRIPT}" | grep -q ") &"
}

@test "oraup.sh collects parallel results with wait" {
    # Verify that parallel jobs are collected with wait
    grep -q "wait.*pid" "${ORAUP_SCRIPT}"
}

@test "oraup.sh uses cached process list for listeners" {
    # Verify that listener checks use cached process list instead of ps -ef
    grep -A 5 "Check if any database listeners" "${ORAUP_SCRIPT}" | grep -q "process_list"
}

@test "datasafe_plugin.sh supports ORADBA_CACHED_PS environment variable" {
    # Verify that DataSafe plugin can use cached process list
    local DATASAFE_PLUGIN="${PROJECT_ROOT}/src/lib/plugins/datasafe_plugin.sh"
    grep -q "ORADBA_CACHED_PS" "${DATASAFE_PLUGIN}"
}

@test "datasafe_plugin.sh falls back to ps -ef when no cache" {
    # Verify that plugin maintains backward compatibility
    local DATASAFE_PLUGIN="${PROJECT_ROOT}/src/lib/plugins/datasafe_plugin.sh"
    grep -A 5 "ORADBA_CACHED_PS" "${DATASAFE_PLUGIN}" | grep -q "ps -ef"
}

@test "oraup.sh Data Safe section displays only 4 columns" {
    # Verify Data Safe Connectors section displays: NAME, PORT, STATUS, DATASAFE_BASE_HOME
    # Not CMAN VERSION or CONNECTOR VER (those should be in oraenv.sh/oradba_env.sh)
    local datasafe_section
    datasafe_section=$(sed -n '/Data Safe Connectors/,/^$/p' "${ORAUP_SCRIPT}")
    
    # Check for correct column headers
    echo "$datasafe_section" | grep -q "NAME.*PORT.*STATUS.*DATASAFE_BASE_HOME"
    
    # Verify version columns are NOT present
    ! echo "$datasafe_section" | grep -q "CMAN VERSION"
    ! echo "$datasafe_section" | grep -q "CONNECTOR VER"
}

@test "oraup.sh Data Safe metadata extraction skips version fields" {
    # Verify that metadata extraction only gets port, not versions
    local metadata_section
    metadata_section=$(sed -n '/Get metadata.*port/,/Write results to temp file/p' "${ORAUP_SCRIPT}")
    
    # Should extract port
    echo "$metadata_section" | grep -q 'port='
    
    # Should NOT extract versions
    ! echo "$metadata_section" | grep -q 'cman_version='
    ! echo "$metadata_section" | grep -q 'connector_version='
}

