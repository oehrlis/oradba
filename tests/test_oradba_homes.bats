#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_homes.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.09
# Revision...: 0.18.0
# Purpose....: BATS tests for oradba_homes.sh management tool
# Notes......: Tests CLI commands, validation, and discovery
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    HOMES_SCRIPT="${PROJECT_ROOT}/src/bin/oradba_homes.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
    export ORADBA_BASE="${TEST_TEMP_DIR}"
    export ORACLE_BASE="${TEST_TEMP_DIR}/oracle"
    
    # Create test directories
    mkdir -p "${ORADBA_BASE}/etc"
    mkdir -p "${ORACLE_BASE}/product"
    
    # Source common library for tests
    source "${PROJECT_ROOT}/src/lib/common.sh"
}

# Cleanup after tests
teardown() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ------------------------------------------------------------------------------
# Basic Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh exists and is executable" {
    [ -f "$HOMES_SCRIPT" ]
    [ -x "$HOMES_SCRIPT" ]
}

@test "oradba_homes.sh has valid bash syntax" {
    run bash -n "$HOMES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "oradba_homes.sh --help shows usage" {
    run "$HOMES_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "COMMANDS:" ]]
}

@test "oradba_homes.sh with no args shows usage" {
    run "$HOMES_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_homes.sh rejects invalid command" {
    run "$HOMES_SCRIPT" invalid_command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}

# ------------------------------------------------------------------------------
# List Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh list works with no homes" {
    run "$HOMES_SCRIPT" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No Oracle Homes" ]]
}

@test "oradba_homes.sh list displays homes when configured" {
    # Create test config
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
OUD12:/u01/app/oracle/oud12:oud:10:Oracle Unified Directory 12c
CLIENT19:/u01/app/oracle/client19:client:20:Oracle Client 19c
EOF
    
    run "$HOMES_SCRIPT" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OUD12" ]]
    [[ "$output" =~ "CLIENT19" ]]
    [[ "$output" =~ "oud" ]]
    [[ "$output" =~ "client" ]]
}

@test "oradba_homes.sh list --type filters by product type" {
    # Create test config
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
OUD12:/u01/app/oracle/oud12:oud:10:Oracle Unified Directory 12c
CLIENT19:/u01/app/oracle/client19:client:20:Oracle Client 19c
WLS14:/u01/app/oracle/wls14:weblogic:30:WebLogic 14c
EOF
    
    run "$HOMES_SCRIPT" list --type oud
    [ "$status" -eq 0 ]
    [[ "$output" =~ "OUD12" ]]
    [[ ! "$output" =~ "CLIENT19" ]]
    [[ ! "$output" =~ "WLS14" ]]
}

@test "oradba_homes.sh list --verbose shows detailed info" {
    # Create test config
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
OUD12:/u01/app/oracle/oud12:oud:10:Oracle Unified Directory 12c
EOF
    
    run "$HOMES_SCRIPT" list --verbose
    [ "$status" -eq 0 ]
    [[ "$output" =~ "PATH" ]]
    [[ "$output" =~ "ORDER" ]]
}

# ------------------------------------------------------------------------------
# Show Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh show requires name argument" {
    run "$HOMES_SCRIPT" show
    [ "$status" -eq 1 ]
    [[ "$output" =~ "required" ]]
}

@test "oradba_homes.sh show displays details for existing home" {
    # Create test config
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
OUD12:/u01/app/oracle/oud12:oud:10:Oracle Unified Directory 12c
EOF
    
    run "$HOMES_SCRIPT" show OUD12
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Oracle Home Details" ]]
    [[ "$output" =~ "OUD12" ]]
    [[ "$output" =~ "/u01/app/oracle/oud12" ]]
    [[ "$output" =~ "oud" ]]
}

@test "oradba_homes.sh show fails for non-existent home" {
    run "$HOMES_SCRIPT" show NOTEXIST
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

# ------------------------------------------------------------------------------
# Add Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh add requires name and path" {
    # Add without name should fail
    run "$HOMES_SCRIPT" add --path /some/path < /dev/null
    [ "$status" -eq 1 ]
}

@test "oradba_homes.sh add creates config file if not exists" {
    [ ! -f "${ORADBA_BASE}/etc/oradba_homes.conf" ]
    
    # Create mock directory
    mkdir -p "${TEST_TEMP_DIR}/test_home/bin"
    touch "${TEST_TEMP_DIR}/test_home/bin/sqlplus"
    
    run "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/test_home" --type client < /dev/null
    [ "$status" -eq 0 ]
    [ -f "${ORADBA_BASE}/etc/oradba_homes.conf" ]
}

@test "oradba_homes.sh add successfully adds new home" {
    # Create mock directory
    mkdir -p "${TEST_TEMP_DIR}/oud_home/oud/lib"
    touch "${TEST_TEMP_DIR}/oud_home/oud/lib/ldapjdk.jar"
    
    run "$HOMES_SCRIPT" add --name OUD12 --path "${TEST_TEMP_DIR}/oud_home" --type oud --desc "Test OUD" < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "added successfully" ]]
    
    # Verify entry was added
    grep -q "^OUD12:" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

@test "oradba_homes.sh add auto-detects product type" {
    # Create mock WebLogic directory
    mkdir -p "${TEST_TEMP_DIR}/wls_home/wlserver/server/lib"
    touch "${TEST_TEMP_DIR}/wls_home/wlserver/server/lib/weblogic.jar"
    
    run "$HOMES_SCRIPT" add --name WLS14 --path "${TEST_TEMP_DIR}/wls_home" < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "weblogic" ]]
}

@test "oradba_homes.sh add validates name format" {
    run "$HOMES_SCRIPT" add --name "invalid name" --path /some/path --type client < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid name" ]]
}

@test "oradba_homes.sh add prevents duplicate names" {
    # Add first home
    mkdir -p "${TEST_TEMP_DIR}/home1"
    "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/home1" --type client < /dev/null >/dev/null 2>&1
    
    # Try to add duplicate
    run "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/home2" --type client < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "already exists" ]]
}

@test "oradba_homes.sh add validates product type" {
    run "$HOMES_SCRIPT" add --name TEST1 --path /some/path --type invalid_type < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid product type" ]]
}

@test "oradba_homes.sh add sets default order" {
    mkdir -p "${TEST_TEMP_DIR}/test_home"
    "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/test_home" --type client < /dev/null >/dev/null 2>&1
    
    grep -q ":50:" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

@test "oradba_homes.sh add accepts custom order" {
    mkdir -p "${TEST_TEMP_DIR}/test_home"
    "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/test_home" --type client --order 99 < /dev/null >/dev/null 2>&1
    
    grep -q ":99:" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

# ------------------------------------------------------------------------------
# Remove Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh remove requires name argument" {
    run "$HOMES_SCRIPT" remove < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "required" ]]
}

@test "oradba_homes.sh remove fails for non-existent home" {
    run "$HOMES_SCRIPT" remove NOTEXIST < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "oradba_homes.sh remove removes existing home with confirmation" {
    # Add a home first
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:/some/path:client:50:Test Client
EOF
    
    # Remove with 'y' confirmation
    run bash -c "echo 'y' | '${HOMES_SCRIPT}' remove TEST1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "removed successfully" ]]
    
    # Verify it's gone
    ! grep -q "^TEST1:" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

@test "oradba_homes.sh remove in non-interactive mode skips confirmation" {
    # Add a home first
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:/some/path:client:50:Test Client
EOF
    
    # Remove in non-interactive mode (stdin from /dev/null)
    run "$HOMES_SCRIPT" remove TEST1 < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Non-interactive mode" ]]
    
    # Verify it was removed
    ! grep -q "^TEST1:" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

@test "oradba_homes.sh remove creates backup" {
    # Add a home first
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:/some/path:client:50:Test Client
EOF
    
    # Remove with confirmation
    echo 'y' | "${HOMES_SCRIPT}" remove TEST1 >/dev/null 2>&1
    
    # Check backup was created
    [ -f "${ORADBA_BASE}/etc/oradba_homes.conf.bak" ]
}

# ------------------------------------------------------------------------------
# Discover Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh discover requires ORACLE_BASE" {
    unset ORACLE_BASE
    run "$HOMES_SCRIPT" discover < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ORACLE_BASE not set" ]]
}

@test "oradba_homes.sh discover works with --base option" {
    mkdir -p "${TEST_TEMP_DIR}/custom_base/product"
    
    run "$HOMES_SCRIPT" discover --base "${TEST_TEMP_DIR}/custom_base" < /dev/null
    [ "$status" -eq 0 ]
}

@test "oradba_homes.sh discover finds Oracle Homes" {
    # Create mock Oracle installations
    mkdir -p "${ORACLE_BASE}/product/oud12/oud/lib"
    touch "${ORACLE_BASE}/product/oud12/oud/lib/ldapjdk.jar"
    
    mkdir -p "${ORACLE_BASE}/product/client19/bin"
    touch "${ORACLE_BASE}/product/client19/bin/sqlplus"
    
    run "$HOMES_SCRIPT" discover < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FOUND" ]]
    [[ "$output" =~ "oud" ]]
    [[ "$output" =~ "client" ]]
}

@test "oradba_homes.sh discover --dry-run doesn't modify config" {
    # Create mock installation
    mkdir -p "${ORACLE_BASE}/product/oud12/oud/lib"
    touch "${ORACLE_BASE}/product/oud12/oud/lib/ldapjdk.jar"
    
    run "$HOMES_SCRIPT" discover --dry-run < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dry run" ]]
    
    # Config should not be created
    [ ! -f "${ORADBA_BASE}/etc/oradba_homes.conf" ]
}

@test "oradba_homes.sh discover --auto-add adds discovered homes" {
    # Create mock installation
    mkdir -p "${ORACLE_BASE}/product/oud12/oud/lib"
    touch "${ORACLE_BASE}/product/oud12/oud/lib/ldapjdk.jar"
    
    run "$HOMES_SCRIPT" discover --auto-add < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Added" ]]
    
    # Verify config was created
    [ -f "${ORADBA_BASE}/etc/oradba_homes.conf" ]
    grep -q "OUD12" "${ORADBA_BASE}/etc/oradba_homes.conf"
}

@test "oradba_homes.sh discover skips already registered homes" {
    # Pre-register a home
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
OUD12:${ORACLE_BASE}/product/oud12:oud:10:Already registered
EOF
    
    # Create the actual directory
    mkdir -p "${ORACLE_BASE}/product/oud12/oud/lib"
    touch "${ORACLE_BASE}/product/oud12/oud/lib/ldapjdk.jar"
    
    run "$HOMES_SCRIPT" discover < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "EXISTS" ]]
}

# ------------------------------------------------------------------------------
# Validate Command Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh validate works with no homes" {
    run "$HOMES_SCRIPT" validate < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No Oracle Homes" ]]
}

@test "oradba_homes.sh validate checks directory existence" {
    # Create config with non-existent path
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:/path/does/not/exist:client:50:Test
EOF
    
    run "$HOMES_SCRIPT" validate < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR" ]]
    [[ "$output" =~ "does not exist" ]]
}

@test "oradba_homes.sh validate succeeds for valid homes" {
    # Create actual directory
    mkdir -p "${TEST_TEMP_DIR}/test_home/bin"
    touch "${TEST_TEMP_DIR}/test_home/bin/sqlplus"
    
    # Create config
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:${TEST_TEMP_DIR}/test_home:client:50:Test
EOF
    
    run "$HOMES_SCRIPT" validate < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid" ]]
}

@test "oradba_homes.sh validate warns on type mismatch" {
    # Create OUD directory
    mkdir -p "${TEST_TEMP_DIR}/oud_home/oud/lib"
    touch "${TEST_TEMP_DIR}/oud_home/oud/lib/ldapjdk.jar"
    
    # But configure as client
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:${TEST_TEMP_DIR}/oud_home:client:50:Test
EOF
    
    run "$HOMES_SCRIPT" validate < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" =~ "WARNING" ]]
    [[ "$output" =~ "differs" ]]
}

@test "oradba_homes.sh validate can check specific home" {
    # Create config with multiple homes
    mkdir -p "${TEST_TEMP_DIR}/home1/bin"
    touch "${TEST_TEMP_DIR}/home1/bin/sqlplus"  # Make it look like a client
    cat > "${ORADBA_BASE}/etc/oradba_homes.conf" << EOF
TEST1:${TEST_TEMP_DIR}/home1:client:50:Test 1
TEST2:/path/does/not/exist:oud:60:Test 2
EOF
    
    run "$HOMES_SCRIPT" validate TEST1 < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TEST1" ]]
    [[ ! "$output" =~ "TEST2" ]]
}

# ------------------------------------------------------------------------------
# Integration Tests
# ------------------------------------------------------------------------------

@test "oradba_homes.sh full workflow: add, list, show, validate, remove" {
    # Add a home
    mkdir -p "${TEST_TEMP_DIR}/test_home/bin"
    touch "${TEST_TEMP_DIR}/test_home/bin/sqlplus"
    
    "$HOMES_SCRIPT" add --name TEST1 --path "${TEST_TEMP_DIR}/test_home" --type client < /dev/null >/dev/null 2>&1
    
    # List should show it
    run "$HOMES_SCRIPT" list < /dev/null
    [[ "$output" =~ "TEST1" ]]
    
    # Show should display details
    run "$HOMES_SCRIPT" show TEST1 < /dev/null
    [[ "$output" =~ "TEST1" ]]
    
    # Validate should pass
    run "$HOMES_SCRIPT" validate TEST1 < /dev/null
    [ "$status" -eq 0 ]
    
    # Remove it
    "$HOMES_SCRIPT" remove TEST1 < /dev/null >/dev/null 2>&1
    
    # Should be gone
    run "$HOMES_SCRIPT" show TEST1 < /dev/null
    [ "$status" -eq 1 ]
}

@test "oradba_homes.sh integrates with oraenv" {
    # Add an Oracle Home
    mkdir -p "${TEST_TEMP_DIR}/oud_home/oud/lib"
    touch "${TEST_TEMP_DIR}/oud_home/oud/lib/ldapjdk.jar"
    
    "$HOMES_SCRIPT" add --name OUD12 --path "${TEST_TEMP_DIR}/oud_home" --type oud < /dev/null >/dev/null 2>&1
    
    # Verify is_oracle_home recognizes it
    run bash -c "source '${PROJECT_ROOT}/src/lib/common.sh' && is_oracle_home OUD12"
    [ "$status" -eq 0 ]
}
