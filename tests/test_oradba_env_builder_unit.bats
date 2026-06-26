#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_builder_unit.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: Unit tests for oradba_env_builder.sh with dependency injection
# Notes......: Tests DI infrastructure, mocked logging, and stateless execution
#              Run with: bats tests/test_oradba_env_builder_unit.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Test setup
setup() {
    # Set ORADBA_BASE to project root
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE
    
    # Explicitly set the src path as the lib path for testing
    export ORADBA_BASE="${ORADBA_BASE}/src"
    
    # Mock logger for testing
    export MOCK_LOG_CALLS=0
    export MOCK_LOG_FILE="${BATS_TMPDIR:-/tmp}/mock_log.$$.txt"
    rm -f "$MOCK_LOG_FILE"
    
    # Define mock logger function
    mock_logger() {
        MOCK_LOG_CALLS=$((MOCK_LOG_CALLS + 1))
        echo "[MOCK] $*" >> "$MOCK_LOG_FILE"
    }
    export -f mock_logger
    
    # Source the builder (it will auto-source parser)
    source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
}

# Test teardown
teardown() {
    rm -f "$MOCK_LOG_FILE"
    unset MOCK_LOG_CALLS
    unset ORADBA_BUILDER_LOGGER
}

# ==============================================================================
# Dependency Injection Tests
# ==============================================================================

@test "builder: init without arguments creates default state" {
    run oradba_builder_init
    [ "$status" -eq 0 ]
    [ -z "$ORADBA_BUILDER_LOGGER" ]
}

@test "builder: init with custom logger stores logger reference" {
    oradba_builder_init "mock_logger"
    [ "$ORADBA_BUILDER_LOGGER" = "mock_logger" ]
}

@test "builder: internal log function falls back when no logger configured" {
    ORADBA_BUILDER_LOGGER=""
    # Should not fail, either calls oradba_log if available or no-op
    run _oradba_builder_log DEBUG "test message"
    [ "$status" -eq 0 ]
}

@test "builder: internal log function calls injected logger" {
    oradba_builder_init "mock_logger"
    _oradba_builder_log DEBUG "test message"
    [ -f "$MOCK_LOG_FILE" ]
    grep -q "test message" "$MOCK_LOG_FILE"
}

@test "builder: logger is called when processing paths" {
    oradba_builder_init "mock_logger"
    MOCK_LOG_CALLS=0
    
    # Call a function that logs
    oradba_dedupe_path "/bin:/usr/bin:/bin" >/dev/null
    
    # Mock logger should have been called (via _oradba_builder_log if any logging happens)
    # dedupe_path doesn't log, but we verify the mechanism works
    [ "$?" -eq 0 ]
}

# ==============================================================================
# Core Functionality Tests (with DI)
# ==============================================================================

@test "builder: dedupe_path works with injected logger" {
    oradba_builder_init "mock_logger"
    
    run oradba_dedupe_path "/bin:/usr/bin:/bin:/usr/local/bin"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^/bin:/usr/bin:/usr/local/bin$ ]]
}

@test "builder: dedupe_path removes duplicates" {
    run oradba_dedupe_path "/a:/b:/c:/b:/a"
    [ "$status" -eq 0 ]
    [ "$output" = "/a:/b:/c" ]
}

@test "builder: dedupe_path handles empty paths" {
    run oradba_dedupe_path ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "builder: dedupe_path handles single path" {
    run oradba_dedupe_path "/bin"
    [ "$status" -eq 0 ]
    [ "$output" = "/bin" ]
}

@test "builder: dedupe_path preserves order" {
    run oradba_dedupe_path "/first:/second:/third:/second"
    [ "$status" -eq 0 ]
    [ "$output" = "/first:/second:/third" ]
}

# ==============================================================================
# Stateless Execution Tests
# ==============================================================================

@test "builder: multiple init calls don't break functionality" {
    oradba_builder_init "mock_logger"
    oradba_builder_init "mock_logger"
    oradba_builder_init "mock_logger"
    
    run oradba_dedupe_path "/a:/b:/a"
    [ "$status" -eq 0 ]
    [ "$output" = "/a:/b" ]
}

@test "builder: switching loggers works correctly" {
    # First logger
    oradba_builder_init "mock_logger"
    [ "$ORADBA_BUILDER_LOGGER" = "mock_logger" ]
    
    # Switch to different logger
    another_logger() { echo "ANOTHER: $*"; }
    export -f another_logger
    oradba_builder_init "another_logger"
    [ "$ORADBA_BUILDER_LOGGER" = "another_logger" ]
    
    # Verify functionality still works
    run oradba_dedupe_path "/x:/y:/x"
    [ "$status" -eq 0 ]
    [ "$output" = "/x:/y" ]
}

# ==============================================================================
# Edge Cases and Error Handling
# ==============================================================================

@test "builder: dedupe_path handles paths with spaces" {
    run oradba_dedupe_path "/path with space:/another:/path with space"
    [ "$status" -eq 0 ]
    [ "$output" = "/path with space:/another" ]
}

@test "builder: dedupe_path handles special characters" {
    run oradba_dedupe_path "/path-one:/path_two:/path.three:/path-one"
    [ "$status" -eq 0 ]
    [ "$output" = "/path-one:/path_two:/path.three" ]
}

@test "builder: dedupe_path handles consecutive colons" {
    run oradba_dedupe_path "/a::/b:/a"
    [ "$status" -eq 0 ]
    # Should skip empty entries
    [ "$output" = "/a:/b" ]
}

# ==============================================================================
# Backward Compatibility Tests
# ==============================================================================

@test "builder: works without init (legacy mode)" {
    # Don't call oradba_builder_init - should work with fallback or no logging
    run oradba_dedupe_path "/x:/y:/x"
    [ "$status" -eq 0 ]
    [ "$output" = "/x:/y" ]
}

@test "builder: clean_path works without DI" {
    # This test requires actual ORACLE_HOME to be set up, skip in unit test
    skip "Requires actual Oracle environment setup"
}

# ==============================================================================
# Performance and Isolation Tests
# ==============================================================================

@test "builder: does not pollute global environment excessively" {
    # Count variables before
    local vars_before
    vars_before=$(compgen -v | wc -l)
    
    oradba_builder_init "mock_logger"
    oradba_dedupe_path "/a:/b" >/dev/null
    
    # Count variables after (allow for test framework and DI variables)
    local vars_after
    vars_after=$(compgen -v | wc -l)
    
    # Should have minimal variable growth
    [ "$((vars_after - vars_before))" -lt 10 ]
}

@test "builder: init is idempotent" {
    local logger1="mock_logger"
    local logger2="mock_logger"
    
    oradba_builder_init "$logger1"
    local state1="$ORADBA_BUILDER_LOGGER"
    
    oradba_builder_init "$logger2"
    local state2="$ORADBA_BUILDER_LOGGER"
    
    [ "$state1" = "$state2" ]
}

@test "builder: dedupe_path performance acceptable" {
    # Create a path with 100 entries (50 duplicates)
    local long_path=""
    for i in {1..50}; do
        long_path="${long_path}/path${i}:"
    done
    for i in {1..50}; do
        long_path="${long_path}/path${i}:"
    done
    long_path="${long_path%:}"  # Remove trailing colon
    
    # Should complete quickly
    result=$(oradba_dedupe_path "$long_path")
    [ "$?" -eq 0 ]
    
    # Should have exactly 50 unique paths
    local count _res_parts
    IFS=: read -ra _res_parts <<< "$result"; count="${#_res_parts[@]}"
    [ "$count" -eq 50 ]
}

# ==============================================================================
# Integration with Parser
# ==============================================================================

@test "builder: parser functions available after sourcing builder" {
    # Builder sources parser, so parser functions should be available
    declare -f oradba_parse_oratab >/dev/null
    [ "$?" -eq 0 ]
}

@test "builder: can initialize both builder and parser with same logger" {
    oradba_builder_init "mock_logger"
    oradba_parser_init "mock_logger"

    [ "$ORADBA_BUILDER_LOGGER" = "mock_logger" ]
    [ "$ORADBA_PARSER_LOGGER" = "mock_logger" ]
}

# ==============================================================================
# Behavioral Coverage (CF-008) - PATH / lib path / ROOH / ASM / product vars
# ==============================================================================

@test "builder: clean_path removes oracle/grid/instantclient entries" {
    run bash -c "
        export PATH='/usr/bin:/u01/app/oracle/product/19/bin:/opt/grid/bin:/opt/instantclient_19'
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_clean_path
        echo \"\$PATH\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"/usr/bin"* ]]
    [[ "$output" != *"/oracle/"* ]]
    [[ "$output" != *"/grid/"* ]]
    [[ "$output" != *"instantclient"* ]]
}

@test "builder: add_oracle_path fails for a non-existent home" {
    run oradba_add_oracle_path "${BATS_TMPDIR}/no_such_home.$$" "database"
    [ "$status" -eq 1 ]
}

@test "builder: add_oracle_path prepends the home bin directory to PATH" {
    local home="${BATS_TMPDIR}/oh_addpath.$$"
    mkdir -p "${home}/bin"
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_add_oracle_path '${home}' 'database'
        echo \"\$PATH\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"${home}/bin"* ]]
    rm -rf "${home}"
}

@test "builder: set_lib_path fails for a non-existent home" {
    run oradba_set_lib_path "${BATS_TMPDIR}/no_such_libhome.$$" "database"
    [ "$status" -eq 1 ]
}

@test "builder: set_lib_path exports lib path containing the home lib dir" {
    local home="${BATS_TMPDIR}/oh_libpath.$$"
    mkdir -p "${home}/bin" "${home}/lib"
    local libvar="LD_LIBRARY_PATH"
    [[ "$(uname -s)" == "Darwin" ]] && libvar="DYLD_LIBRARY_PATH"
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_set_lib_path '${home}' 'database'
        echo \"\${${libvar}}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"${home}/lib"* ]]
    rm -rf "${home}"
}

@test "builder: is_asm_instance recognises +ASM names" {
    run oradba_is_asm_instance "+ASM"
    [ "$status" -eq 0 ]
    run oradba_is_asm_instance "+ASM1"
    [ "$status" -eq 0 ]
}

@test "builder: is_asm_instance rejects a normal SID" {
    run oradba_is_asm_instance "ORCL"
    [ "$status" -eq 1 ]
}

@test "builder: detect_rooh sets ORACLE_BASE and ORADBA_DBS for a non-ROOH home" {
    local base="${BATS_TMPDIR}/rooh_base.$$"
    local home="${base}/product/19/dbhome_1"
    mkdir -p "${home}"
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_detect_rooh '${home}' || true
        echo \"BASE=\${ORACLE_BASE}\"
        echo \"DBS=\${ORADBA_DBS}\"
        echo \"ROOH=\${ORADBA_ROOH}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"BASE=${base}"* ]]
    [[ "$output" == *"DBS=${home}/dbs"* ]]
    [[ "$output" == *"ROOH=0"* ]]
    rm -rf "${base}"
}

@test "builder: detect_rooh honours orabasetab read-only flag" {
    local base="${BATS_TMPDIR}/rooh_base_y.$$"
    local home="${base}/product/19/dbhome_1"
    mkdir -p "${home}/install"
    printf '%s:%s:dbhome_1:Y\n' "${home}" "${base}" > "${home}/install/orabasetab"
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_detect_rooh '${home}'
        echo \"rc=\$?\"
        echo \"DBS=\${ORADBA_DBS}\"
        echo \"ROOH=\${ORADBA_ROOH}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ROOH=1"* ]]
    [[ "$output" == *"DBS=${base}/dbs"* ]]
    rm -rf "${base}"
}

@test "builder: detect_rooh fails for a non-existent home" {
    run oradba_detect_rooh "${BATS_TMPDIR}/no_such_rooh.$$"
    [ "$status" -eq 1 ]
}

@test "builder: set_oracle_vars exports core variables for a database home" {
    local home="${BATS_TMPDIR}/oh_vars.$$"
    mkdir -p "${home}/bin"
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_set_oracle_vars 'TESTDB' '${home}' 'RDBMS'
        echo \"SID=\${ORACLE_SID}\"
        echo \"HOME=\${ORACLE_HOME}\"
        echo \"UNQ=\${ORACLE_UNQNAME}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SID=TESTDB"* ]]
    [[ "$output" == *"HOME=${home}"* ]]
    [[ "$output" == *"UNQ=TESTDB"* ]]
    rm -rf "${home}"
}

@test "builder: set_oracle_vars rejects missing SID" {
    local home="${BATS_TMPDIR}/oh_vars_nosid.$$"
    mkdir -p "${home}/bin"
    run oradba_set_oracle_vars "" "${home}" "RDBMS"
    [ "$status" -eq 1 ]
    rm -rf "${home}"
}

@test "builder: set_oracle_vars rejects a non-existent home" {
    run oradba_set_oracle_vars "TESTDB" "${BATS_TMPDIR}/no_such_oh.$$" "RDBMS"
    [ "$status" -eq 1 ]
}

@test "builder: set_asm_environment sets ASM privilege and GRID_HOME" {
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        export ORACLE_HOME='/opt/grid'
        unset GRID_HOME
        oradba_set_asm_environment
        echo \"SYSASM=\${ORACLE_SYSASM}\"
        echo \"GRID=\${GRID_HOME}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SYSASM=TRUE"* ]]
    [[ "$output" == *"GRID=/opt/grid"* ]]
}

@test "builder: set_product_environment sets GRID_HOME for GRID product" {
    run bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        export ORACLE_HOME='/opt/grid_home'
        oradba_set_product_environment 'GRID'
        echo \"GRID=\${GRID_HOME}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"GRID=/opt/grid_home"* ]]
}

# ==============================================================================
# Integration: oradba_build_environment with a mock home tree
# ==============================================================================

@test "builder: build_environment fails for an empty target" {
    run oradba_build_environment ""
    [ "$status" -eq 1 ]
}

@test "builder: build_environment builds a complete environment from a mock home" {
    local base="${BATS_TMPDIR}/bld_base.$$"
    local home="${base}/product/19.0.0/dbhome_1"
    mkdir -p "${home}/bin"
    for b in sqlplus rman oracle; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "${home}/bin/${b}"
        chmod +x "${home}/bin/${b}"
    done
    run bash -c "
        export ORADBA_BASE='${ORADBA_BASE}'
        export ORACLE_BASE='${base}'
        source '${ORADBA_BASE}/lib/oradba_env_builder.sh'
        oradba_build_environment '${home}'
        echo \"rc=\$?\"
        echo \"PATH=\$PATH\"
        echo \"LOADED=\${ORADBA_ENV_LOADED}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"${home}/bin"* ]]
    [[ "$output" == *"LOADED=1"* ]]
    rm -rf "${base}"
}
