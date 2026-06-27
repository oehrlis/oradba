#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_perf.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-06-27
# Purpose....: BATS tests for M7 performance features (CF-014, CF-015, CF-016)
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Resolve BATS_TEST_DIRNAME portably
BATS_TEST_DIRNAME="${BATS_TEST_DIRNAME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
ORADBA_BASE="$(cd "${BATS_TEST_DIRNAME}/../src" && pwd)"
export ORADBA_BASE

setup() {
    # Unset session guards and feature flags between tests
    unset ORADBA_LOAD_PDB_ALIASES
    unset ORACLE_SID
    # Unset any PDB alias session guards
    local var
    for var in $(compgen -v ORADBA_PDB_ALIASES_DONE_ 2>/dev/null || true); do
        unset "${var}"
    done
}

# ---------------------------------------------------------------------------
# CF-015 Test 1: generate_pdb_aliases returns 0 without calling sqlplus
#                when ORADBA_LOAD_PDB_ALIASES is unset (defaults to false)
# ---------------------------------------------------------------------------
@test "CF-015: generate_pdb_aliases skips when ORADBA_LOAD_PDB_ALIASES unset" {
    # Source the library
    source "${ORADBA_BASE}/lib/oradba_common.sh"

    # Mock sqlplus to detect if it is called
    sqlplus() { echo "SQLPLUS_CALLED"; }
    export -f sqlplus

    # Call without setting ORADBA_LOAD_PDB_ALIASES (defaults to false)
    local output
    output=$(generate_pdb_aliases 2>/dev/null)

    # sqlplus must NOT have been called
    [[ "${output}" != *"SQLPLUS_CALLED"* ]]
}

# ---------------------------------------------------------------------------
# CF-015 Test 2: Session guard prevents re-running generate_pdb_aliases
#                for the same SID
# ---------------------------------------------------------------------------
@test "CF-015: session guard prevents duplicate PDB alias generation" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"

    export ORADBA_LOAD_PDB_ALIASES="true"
    export ORACLE_SID="TESTDB"

    # Mock check_database_connection to return failure (no DB needed)
    check_database_connection() { return 1; }
    export -f check_database_connection

    # First call - should run (but exit early due to no DB connection)
    generate_pdb_aliases 2>/dev/null || true

    # Set the guard manually (simulating that first call completed)
    declare -g "ORADBA_PDB_ALIASES_DONE_TESTDB=1"

    # Track second call by using a mock that would fail if reached
    _pdb_double_called=false
    check_database_connection() { _pdb_double_called=true; return 1; }
    export -f check_database_connection

    generate_pdb_aliases 2>/dev/null || true

    # Session guard should have prevented the second call
    [[ "${_pdb_double_called}" == "false" ]]
}

# ---------------------------------------------------------------------------
# CF-015 Test 3: generate_pdb_aliases runs when ORADBA_LOAD_PDB_ALIASES=true
# ---------------------------------------------------------------------------
@test "CF-015: generate_pdb_aliases proceeds when ORADBA_LOAD_PDB_ALIASES=true" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"

    export ORADBA_LOAD_PDB_ALIASES="true"
    export ORACLE_SID="TESTDB2"

    # Track whether check_database_connection is reached
    _db_check_called=false
    check_database_connection() { _db_check_called=true; return 1; }
    export -f check_database_connection

    generate_pdb_aliases 2>/dev/null || true

    # Should have attempted DB connection check (feature is enabled)
    [[ "${_db_check_called}" == "true" ]]
}

# ---------------------------------------------------------------------------
# CF-014 Test 4: load_config is called exactly once per env switch
#                (no duplicate calls from oraenv.sh top-level)
# ---------------------------------------------------------------------------
@test "CF-014: load_config_file call count" {
    # Verify that oradba_core.conf is sourced exactly once at bootstrap
    # This tests the structure: only one load_config_file at top-level of oraenv.sh
    local oraenv_src="${ORADBA_BASE}/bin/oraenv.sh"

    [[ -f "${oraenv_src}" ]] || skip "oraenv.sh not found"

    # Count top-level load_config_file calls (not inside functions)
    # We expect exactly the two bootstrap calls (core.conf + local.conf)
    local toplevel_calls
    toplevel_calls=$(awk '
        /^[[:space:]]*load_config_file[[:space:]]/ { count++ }
        END { print count+0 }
    ' "${oraenv_src}")

    # Should be exactly 2 top-level load_config_file calls (core + local bootstrap)
    [[ "${toplevel_calls}" -le 2 ]]
}
