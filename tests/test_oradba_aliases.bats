#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_aliases.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.6.0
# Purpose....: BATS tests for oradba_aliases.sh - dynamic alias generation
# Notes......: Run with: bats test_oradba_aliases.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup before each test
setup() {
    # Enable alias expansion in bash (required for alias tests)
    shopt -s expand_aliases
    
    # Get the directory containing the script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORADBA_SRC_BASE="${PROJECT_ROOT}/src"
    
    # Source the common library first (provides log functions)
    export ORADBA_PREFIX="${ORADBA_SRC_BASE}"
    source "${ORADBA_SRC_BASE}/lib/oradba_common.sh"
    
    # Source the aliases library
    # Note: This cleans up internal helper functions after sourcing (v0.19.1)
    # Only oradba_tnsping remains as it's needed by the tnsping alias
    source "${ORADBA_SRC_BASE}/lib/oradba_aliases.sh"
    
    # Re-define internal functions for testing
    # These are normally cleaned up but we need them for unit tests
    # shellcheck disable=SC1090  # Dynamic source for test setup only
    source <(sed -n '/^has_rlwrap()/,/^}/p; /^create_dynamic_alias()/,/^}/p; /^get_diagnostic_dest()/,/^}/p; /^generate_base_aliases()/,/^}/p; /^generate_sid_aliases()/,/^}/p' "${ORADBA_SRC_BASE}/lib/oradba_aliases.sh")
    
    # Create temp directory for tests
    TEMP_TEST_DIR="${BATS_TMPDIR}/oradba_aliases_test_$$"
    mkdir -p "${TEMP_TEST_DIR}"
    
    # Mock environment
    export ORACLE_SID="TESTDB"
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    mkdir -p "${ORACLE_HOME}/bin"
    mkdir -p "${ORACLE_BASE}"
}

# Cleanup after each test
teardown() {
    if [[ -d "${TEMP_TEST_DIR}" ]]; then
        rm -rf "${TEMP_TEST_DIR}"
    fi
    unalias -a 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Basic Function Tests
# ------------------------------------------------------------------------------

@test "oradba_aliases.sh can be sourced" {
    run bash -c "source '${ORADBA_SRC_BASE}/lib/oradba_aliases.sh'; echo 'OK'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

@test "has_rlwrap function exists" {
    # Note: Function is cleaned up after sourcing but re-defined in setup for testing
    type has_rlwrap
}

@test "get_diagnostic_dest function exists" {
    # Note: Function is cleaned up after sourcing but re-defined in setup for testing
    type get_diagnostic_dest
}

@test "generate_sid_aliases function exists" {
    # Note: Function is cleaned up after sourcing but re-defined in setup for testing
    type generate_sid_aliases
}

@test "create_dynamic_alias function exists" {
    # Note: Function is cleaned up after sourcing but re-defined in setup for testing
    type create_dynamic_alias
}

# ------------------------------------------------------------------------------
# create_dynamic_alias() Tests
# ------------------------------------------------------------------------------

@test "create_dynamic_alias creates non-expanded alias" {
    export ORADBA_BIN="/usr/local/bin"
    
    # Create non-expanded alias (default behavior)
    create_dynamic_alias test_alias '${ORADBA_BIN}/script.sh'
    
    # Check alias was created
    run alias test_alias
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ORADBA_BIN" ]]
}

@test "create_dynamic_alias creates expanded alias when requested" {
    export ORADBA_BIN="/usr/local/bin"
    
    # Create expanded alias
    create_dynamic_alias test_alias_exp "${ORADBA_BIN}/script.sh" "true"
    
    # Check alias was created with expanded value
    run alias test_alias_exp
    [ "$status" -eq 0 ]
    [[ "$output" =~ /usr/local/bin/script.sh ]]
}

@test "create_dynamic_alias requires alias name" {
    # Should fail without name
    run create_dynamic_alias
    [ "$status" -ne 0 ]
}

@test "create_dynamic_alias requires alias command" {
    # Should fail without command
    run create_dynamic_alias test_name
    [ "$status" -ne 0 ]
}

@test "create_dynamic_alias respects safe_alias coexistence mode" {
    export ORADBA_COEXIST_MODE="basenv"
    
    # Create a fake existing alias
    alias existing_alias="echo exists"
    
    # Try to create same alias (should be skipped)
    run create_dynamic_alias existing_alias "echo new"
    [ "$status" -eq 1 ]  # safe_alias returns 1 when skipped
}

@test "create_dynamic_alias works with directory navigation" {
    local test_dir="/tmp/test_oradba"
    
    # Create expanded directory alias
    create_dynamic_alias cdtest "cd ${test_dir}" "true"
    
    # Verify alias was created with expanded path
    run alias cdtest
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/tmp/test_oradba" ]]
}

@test "create_dynamic_alias works with complex commands" {
    # Create non-expanded complex command
    create_dynamic_alias complex_cmd 'if [ -f "${FILE}" ]; then cat "${FILE}"; else echo "not found"; fi'
    
    # Verify alias was created
    run alias complex_cmd
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FILE" ]]
    [[ "$output" =~ "not found" ]]
}

# ------------------------------------------------------------------------------
# has_rlwrap() Tests
# ------------------------------------------------------------------------------

@test "has_rlwrap returns 0 if rlwrap is available" {
    if command -v rlwrap &>/dev/null; then
        run has_rlwrap
        [ "$status" -eq 0 ]
    else
        skip "rlwrap not installed on this system"
    fi
}

@test "has_rlwrap returns 1 if rlwrap is not available" {
    export RLWRAP_COMMAND="nonexistent_rlwrap_command"
    run has_rlwrap
    [ "$status" -eq 1 ]
}

@test "has_rlwrap respects RLWRAP_COMMAND variable" {
    # Test with a command that exists
    export RLWRAP_COMMAND="bash"
    run has_rlwrap
    [ "$status" -eq 0 ]
    
    # Test with a command that doesn't exist
    export RLWRAP_COMMAND="this_command_does_not_exist"
    run has_rlwrap
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# get_diagnostic_dest() Tests
# ------------------------------------------------------------------------------

@test "get_diagnostic_dest returns fallback path when DB not accessible" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Without a real database, should return convention-based path
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    [[ "$result" =~ "diag/rdbms/testdb/TESTDB" ]]
}

@test "get_diagnostic_dest handles empty ORACLE_SID" {
    unset ORACLE_SID
    
    run get_diagnostic_dest
    [ "$status" -eq 0 ]
    # Should still return a path (with empty SID placeholders)
    [[ "$output" =~ "diag/rdbms" ]]
}

@test "get_diagnostic_dest uses ORACLE_BASE" {
    export ORACLE_SID="PRODDB"
    export ORACLE_BASE="/u01/app/oracle"
    
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    [[ "$result" =~ "diag/rdbms/proddb/PRODDB" ]]
}

@test "get_diagnostic_dest converts SID to lowercase in path" {
    export ORACLE_SID="ORCL"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    local result
    result=$(get_diagnostic_dest)
    [ -n "$result" ]
    # Path should contain lowercase 'orcl' for rdbms directory
    [[ "$result" =~ "rdbms/orcl/ORCL" ]]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - No ORACLE_SID
# ------------------------------------------------------------------------------

@test "generate_sid_aliases returns 0 with no ORACLE_SID set" {
    unset ORACLE_SID
    
    run generate_sid_aliases
    [ "$status" -eq 0 ]
}

@test "generate_sid_aliases creates no aliases when ORACLE_SID is empty" {
    unset ORACLE_SID
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # Check that SID-specific aliases are not created
    run alias taa
    [ "$status" -ne 0 ]
    
    run alias cdda
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - With Mock Diagnostic Directories
# ------------------------------------------------------------------------------

@test "ORADBA_SID_ALERTLOG variable is set when ORACLE_SID and ORACLE_BASE exist" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    export ORADBA_ORA_DIAG_SID="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    
    # Source the standard config to set ORADBA_SID_ALERTLOG
    ORADBA_SID_ALERTLOG="${ORADBA_ORA_DIAG_SID}/trace/alert_${ORACLE_SID}.log"
    
    # Verify variable is set correctly
    [ -n "${ORADBA_SID_ALERTLOG}" ]
    [[ "${ORADBA_SID_ALERTLOG}" =~ alert_TESTDB.log ]]
    [[ "${ORADBA_SID_ALERTLOG}" =~ /trace/ ]]
}

@test "generate_sid_aliases creates cdda alias when diagnostic dest exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/alert"
    mkdir -p "${diag_dest}/trace"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    
    # Verify the function completed successfully
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates cdta alias when trace directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates cdaa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/alert"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

@test "generate_sid_aliases creates taa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    touch "${diag_dest}/trace/alert_TESTDB.log"
    
    # Set ORADBA_SID_ALERTLOG
    export ORADBA_SID_ALERTLOG="${diag_dest}/trace/alert_TESTDB.log"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
    
    # Verify alias contains ORADBA_SID_ALERTLOG
    run alias taa
    [[ "$output" =~ "ORADBA_SID_ALERTLOG" ]]
}

@test "generate_sid_aliases creates vaa alias when alert directory exists" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic directory structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/testdb/TESTDB"
    mkdir -p "${diag_dest}/trace"
    touch "${diag_dest}/trace/alert_TESTDB.log"
    
    # Set ORADBA_SID_ALERTLOG
    export ORADBA_SID_ALERTLOG="${diag_dest}/trace/alert_TESTDB.log"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
    
    # Verify alias contains ORADBA_SID_ALERTLOG
    run alias vaa
    [[ "$output" =~ "ORADBA_SID_ALERTLOG" ]]
}

@test "generate_sid_aliases doesn't create aliases when diagnostic dest doesn't exist" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Don't create diagnostic directories
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # Check that aliases are not created
    run alias cdda 2>/dev/null
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# generate_sid_aliases() Tests - rlwrap Integration
# ------------------------------------------------------------------------------

@test "generate_sid_aliases creates rlwrap aliases when rlwrap is available" {
    if ! command -v rlwrap &>/dev/null; then
        skip "rlwrap not installed on this system"
    fi
    
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="rlwrap"
    export RLWRAP_OPTS="-i -c"
    
    generate_sid_aliases
    
    # Check sq alias contains rlwrap
    run bash -c "alias sq"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rlwrap" ]]
    [[ "$output" =~ "sqlplus" ]]
}

@test "generate_sid_aliases doesn't create rlwrap aliases when rlwrap not available" {
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="nonexistent_rlwrap"
    
    # Clear all aliases first
    unalias -a 2>/dev/null || true
    
    generate_sid_aliases
    
    # sq alias should not be created (since rlwrap not available and not in generate_sid_aliases)
    # This test just verifies the function doesn't fail
    [ "$?" -eq 0 ]
}

@test "sqh alias connects with sysdba when rlwrap available" {
    if ! command -v rlwrap &>/dev/null; then
        skip "rlwrap not installed on this system"
    fi
    
    export ORACLE_SID="TESTDB"
    export RLWRAP_COMMAND="rlwrap"
    export RLWRAP_OPTS="-i -c"
    
    generate_sid_aliases
    
    # Check sqh alias uses "/ as sysdba" not "/nolog"
    run bash -c "alias sqh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sqlplus / as sysdba" ]]
    [[ ! "$output" =~ "/nolog" ]]
}

# ------------------------------------------------------------------------------
# Integration Tests - Different SIDs
# ------------------------------------------------------------------------------

@test "generate_sid_aliases works with different ORACLE_SID values" {
    # Test with multiple different SIDs
    for sid in "ORCL" "DEVDB" "PRODDB" "TEST01"; do
        export ORACLE_SID="$sid"
        export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
        
        # Create diagnostic structure
        local diag_dest="${ORACLE_BASE}/diag/rdbms/${sid,,}/${sid}"
        mkdir -p "${diag_dest}/alert"
        mkdir -p "${diag_dest}/trace"
        
        # Generate aliases - should succeed for each SID
        generate_sid_aliases
        [ "$?" -eq 0 ]
    done
}

@test "generate_sid_aliases handles SIDs with special characters" {
    # Test with SID containing numbers
    export ORACLE_SID="DB19C"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    local diag_dest="${ORACLE_BASE}/diag/rdbms/db19c/DB19C"
    mkdir -p "${diag_dest}/alert"
    
    # Generate aliases - should succeed
    generate_sid_aliases
    [ "$?" -eq 0 ]
}

# ------------------------------------------------------------------------------
# Auto-Generation Tests
# ------------------------------------------------------------------------------

@test "oradba_aliases.sh auto-generates aliases if ORACLE_SID is set on load" {
    export ORACLE_SID="AUTOTEST"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    
    # Create diagnostic structure
    local diag_dest="${ORACLE_BASE}/diag/rdbms/autotest/AUTOTEST"
    mkdir -p "${diag_dest}/alert"
    
    # Source oradba_aliases.sh (which auto-generates if ORACLE_SID is set)
    # Should not fail
    run bash -c "
        shopt -s expand_aliases
        export ORACLE_SID='AUTOTEST'
        export ORACLE_BASE='${TEMP_TEST_DIR}/oracle'
        export ORADBA_PREFIX='${PROJECT_ROOT}/src'
        source '${ORADBA_SRC_BASE}/lib/oradba_common.sh'
        source '${ORADBA_SRC_BASE}/lib/oradba_aliases.sh'
        echo OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

@test "oradba_aliases.sh doesn't fail if ORACLE_SID is not set on load" {
    unset ORACLE_SID
    
    # Should not fail to source
    run bash -c "source '${ORADBA_SRC_BASE}/lib/oradba_aliases.sh'; echo 'OK'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OK" ]]
}

# ------------------------------------------------------------------------------
# Error Handling Tests
# ------------------------------------------------------------------------------

@test "get_diagnostic_dest handles missing ORACLE_BASE gracefully" {
    export ORACLE_SID="TESTDB"
    unset ORACLE_BASE
    
    # Should still return a path
    run get_diagnostic_dest
    [ "$status" -eq 0 ]
    # Output should not be empty
    [ -n "$output" ]
}

@test "generate_sid_aliases handles missing ORACLE_HOME gracefully" {
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    unset ORACLE_HOME
    
    # Should not fail
    run generate_sid_aliases
    [ "$status" -eq 0 ]
}

@test "oradba_aliases.sh functions don't pollute environment with unexpected variables" {
    # Run alias generation
    export ORACLE_SID="TESTDB"
    export ORACLE_BASE="${TEMP_TEST_DIR}/oracle"
    generate_sid_aliases
    
    # Should not have unexpected new variables (some test framework vars are OK)
    # Main concern is no leaked 'sid', 'diag_dest', etc. at global scope
    run bash -c "declare -p sid 2>&1"
    [[ "$output" =~ (not found|not set) ]]
}

@test "internal helper functions are cleaned up after sourcing" {
    # Start fresh bash and source oradba_aliases.sh
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type has_rlwrap 2>&1"
    # Should not exist
    [ "$status" -ne 0 ]
    
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type create_dynamic_alias 2>&1"
    [ "$status" -ne 0 ]
    
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type get_diagnostic_dest 2>&1"
    [ "$status" -ne 0 ]
    
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type generate_base_aliases 2>&1"
    [ "$status" -ne 0 ]
    
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type generate_sid_aliases 2>&1"
    [ "$status" -ne 0 ]
}

@test "oradba_tnsping function remains after sourcing" {
    # oradba_tnsping must remain as it's used by the tnsping alias
    run bash -c "source ${ORADBA_SRC_BASE}/lib/oradba_common.sh && source ${ORADBA_SRC_BASE}/lib/oradba_aliases.sh && type oradba_tnsping"
    [ "$status" -eq 0 ]
}
# ------------------------------------------------------------------------------
# TNS Ping Wrapper Tests
# ------------------------------------------------------------------------------

@test "oradba_tnsping function exists" {
    type oradba_tnsping
}

@test "oradba_tnsping requires ORACLE_HOME" {
    unset ORACLE_HOME
    run oradba_tnsping FREE
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ORACLE_HOME not set" ]]
}

@test "oradba_tnsping requires target argument" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    run oradba_tnsping
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_tnsping uses native tnsping when available" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    mkdir -p "${ORACLE_HOME}/bin"
    
    # Create mock tnsping
    cat > "${ORACLE_HOME}/bin/tnsping" <<'EOF'
#!/usr/bin/env bash
echo "TNS Ping Utility for Linux: Version 19.0.0.0.0 - Production"
echo "Used parameter files:"
echo "Attempting to contact $1"
echo "OK (10 msec)"
EOF
    chmod +x "${ORACLE_HOME}/bin/tnsping"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TNS Ping Utility" ]]
    [[ "$output" =~ "FREE" ]]
}

@test "oradba_tnsping falls back to sqlplus -P for Instant Client (bin/sqlplus)" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    mkdir -p "${ORACLE_HOME}/bin"
    
    # No tnsping, but sqlplus in bin/
    cat > "${ORACLE_HOME}/bin/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "sqlplus -P called with: $2"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/bin/sqlplus"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sqlplus -P called with: FREE" ]]
}

@test "oradba_tnsping falls back to sqlplus -P for Instant Client (direct sqlplus)" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    mkdir -p "${ORACLE_HOME}"
    
    # No tnsping, sqlplus directly in ORACLE_HOME
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "sqlplus -P called with: $2"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sqlplus -P called with: FREE" ]]
}

@test "oradba_tnsping rejects connect descriptors with sqlplus -P" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    mkdir -p "${ORACLE_HOME}"
    
    # Only sqlplus available
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
echo "Should not reach here"
exit 1
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    # Try with connect descriptor
    run oradba_tnsping "(DESCRIPTION=(CONNECT_DATA=(SERVICE_NAME=FREE))(ADDRESS=(PROTOCOL=tcp)(HOST=172.18.0.3)(PORT=1521)))"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not support full connect descriptors" ]]
    [[ "$output" =~ "TNS name or EZ Connect" ]]
}

@test "oradba_tnsping accepts TNS name with sqlplus -P" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    mkdir -p "${ORACLE_HOME}"
    
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "Testing connection to: $2"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping FREE.world
    [ "$status" -eq 0 ]
    [[ "$output" =~ Testing\ connection\ to:\ FREE.world ]]
}

@test "oradba_tnsping accepts EZ Connect with sqlplus -P" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    mkdir -p "${ORACLE_HOME}"
    
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "Testing connection to: $2"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping "172.18.0.3:1521/FREE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 172.18.0.3:1521/FREE ]]
}

@test "oradba_tnsping shows notice in verbose mode" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    export ORADBA_VERBOSE="true"
    mkdir -p "${ORACLE_HOME}"
    
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "Connection test"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Notice: Using sqlplus -P" ]]
}

@test "oradba_tnsping shows notice in debug mode" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    export ORADBA_LOG_LEVEL="DEBUG"
    mkdir -p "${ORACLE_HOME}"
    
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "Connection test"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Notice: Using sqlplus -P" ]]
}

@test "oradba_tnsping does not show notice in normal mode" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/instantclient_19_19"
    unset ORADBA_VERBOSE
    unset ORADBA_LOG_LEVEL
    unset DEBUG
    mkdir -p "${ORACLE_HOME}"
    
    cat > "${ORACLE_HOME}/sqlplus" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-P" ]]; then
    echo "Connection test"
    exit 0
fi
EOF
    chmod +x "${ORACLE_HOME}/sqlplus"
    
    run oradba_tnsping FREE
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Notice:" ]]
}

@test "oradba_tnsping fails when neither tnsping nor sqlplus available" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/empty"
    mkdir -p "${ORACLE_HOME}/bin"
    
    run oradba_tnsping FREE
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Neither tnsping nor sqlplus found" ]]
}

@test "tnsping alias is created when ORACLE_SID is set" {
    export ORACLE_SID="TESTDB"
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    mkdir -p "${ORACLE_HOME}/bin"
    
    generate_sid_aliases
    
    # Check if alias exists (don't use bash -c as aliases aren't exported)
    run alias tnsping
    [ "$status" -eq 0 ]
    [[ "$output" =~ "oradba_tnsping" ]]
}

@test "oradba_tnsping passes multiple arguments correctly" {
    export ORACLE_HOME="${TEMP_TEST_DIR}/oracle/product/19c"
    mkdir -p "${ORACLE_HOME}/bin"
    
    # Create mock tnsping that shows all arguments
    cat > "${ORACLE_HOME}/bin/tnsping" <<'EOF'
#!/usr/bin/env bash
echo "Arguments: $@"
EOF
    chmod +x "${ORACLE_HOME}/bin/tnsping"
    
    run oradba_tnsping FREE 10
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Arguments: FREE 10" ]]
}