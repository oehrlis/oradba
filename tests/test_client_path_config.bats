#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_client_path_config.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.20
# Purpose..: Unit tests for client path configuration feature
# Reference: Issue - Add client path config for non-client homes
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_client_path_$$"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/etc"
    mkdir -p "${TEST_DIR}/test_homes"
    
    # Set ORADBA_BASE and ORADBA_PREFIX
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    export ORADBA_PREFIX="${ORADBA_BASE}"
    
    # Source required libraries
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
    
    # Create mock client homes
    setup_mock_homes
    
    # Create mock oracle homes config
    create_mock_homes_config
}

teardown() {
    rm -rf "${TEST_DIR}"
    unset ORADBA_CLIENT_PATH_FOR_NON_CLIENT
}

# Helper: Setup mock Oracle homes
setup_mock_homes() {
    # Mock full client
    local client_home="${TEST_DIR}/test_homes/client_19c"
    mkdir -p "${client_home}/bin"
    mkdir -p "${client_home}/lib"
    touch "${client_home}/bin/sqlplus"
    chmod +x "${client_home}/bin/sqlplus"
    
    # Mock instant client
    local iclient_home="${TEST_DIR}/test_homes/instantclient_19_19"
    mkdir -p "${iclient_home}"
    touch "${iclient_home}/sqlplus"
    touch "${iclient_home}/libclntsh.so"
    chmod +x "${iclient_home}/sqlplus"
    
    # Mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe"
    mkdir -p "${ds_home}/bin"
    touch "${ds_home}/bin/cmctl"
    chmod +x "${ds_home}/bin/cmctl"
    
    # Mock OUD home
    local oud_home="${TEST_DIR}/test_homes/oud12c"
    mkdir -p "${oud_home}/oud/bin"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
}

# Helper: Create mock oradba_homes.conf
create_mock_homes_config() {
    # Use absolute paths that actually exist
    local client_home="${TEST_DIR}/test_homes/client_19c"
    local iclient_home="${TEST_DIR}/test_homes/instantclient_19_19"
    local ds_home="${TEST_DIR}/test_homes/datasafe"
    local oud_home="${TEST_DIR}/test_homes/oud12c"
    
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
# Mock oracle homes configuration
${client_home};CLIENT;19.0.0.0.0;N/A;N/A;30;dummy;CL19;Oracle Client 19c
${iclient_home};ICLIENT;19.19.0.0.0;N/A;N/A;40;dummy;IC19;Oracle Instant Client 19.19
${ds_home};DATASAFE;1.0.0.0.0;N/A;N/A;50;dummy;DS;Oracle Data Safe Connector
${oud_home};OUD;12.2.1.4.0;N/A;N/A;60;oud1;OUD12;Oracle Unified Directory 12c
EOF
    
    # Override get_oracle_homes_path to return our mock config
    get_oracle_homes_path() {
        echo "${TEST_DIR}/etc/oradba_homes.conf"
        return 0
    }
}

# ==============================================================================
# Tests for oradba_product_needs_client
# ==============================================================================

@test "product_needs_client: DATASAFE needs client" {
    run oradba_product_needs_client "DATASAFE"
    [ "$status" -eq 0 ]
}

@test "product_needs_client: OUD needs client" {
    run oradba_product_needs_client "OUD"
    [ "$status" -eq 0 ]
}

@test "product_needs_client: WLS needs client" {
    run oradba_product_needs_client "WLS"
    [ "$status" -eq 0 ]
}

@test "product_needs_client: DATABASE does not need client" {
    run oradba_product_needs_client "DATABASE"
    [ "$status" -ne 0 ]
}

@test "product_needs_client: CLIENT does not need client" {
    run oradba_product_needs_client "CLIENT"
    [ "$status" -ne 0 ]
}

@test "product_needs_client: ICLIENT does not need client" {
    run oradba_product_needs_client "ICLIENT"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Tests for oradba_resolve_client_home
# ==============================================================================

@test "resolve_client_home: returns error when set to 'none'" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="none"
    run oradba_resolve_client_home
    [ "$status" -ne 0 ]
}

@test "resolve_client_home: finds first client with 'auto'" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="auto"
    run oradba_resolve_client_home
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/(client_19c|instantclient_19_19) ]]
}

@test "resolve_client_home: resolves specific client by short name" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    run oradba_resolve_client_home
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/client_19c ]]
}

@test "resolve_client_home: resolves instant client by short name" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="IC19"
    run oradba_resolve_client_home
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/instantclient_19_19 ]]
}

@test "resolve_client_home: returns error for non-existent client" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="NONEXISTENT"
    run oradba_resolve_client_home
    [ "$status" -ne 0 ]
}

@test "resolve_client_home: returns error for non-client product" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="DS"
    run oradba_resolve_client_home
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Tests for oradba_add_client_path
# ==============================================================================

@test "add_client_path: does not add path when set to 'none'" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="none"
    export PATH="/usr/bin:/bin"
    
    run oradba_add_client_path "DATASAFE"
    [ "$status" -eq 0 ]
    [[ "$PATH" == "/usr/bin:/bin" ]]
}

@test "add_client_path: adds client bin to PATH for DATASAFE" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    export PATH="/usr/bin:/bin"
    
    oradba_add_client_path "DATASAFE"
    [[ "$PATH" =~ test_homes/client_19c/bin ]]
}

@test "add_client_path: adds instant client to PATH (no bin subdirectory)" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="IC19"
    export PATH="/usr/bin:/bin"
    
    oradba_add_client_path "OUD"
    [[ "$PATH" =~ test_homes/instantclient_19_19 ]]
    [[ ! "$PATH" =~ instantclient_19_19/bin ]]
}

@test "add_client_path: appends client path after existing entries" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    export PATH="/datasafe/bin:/usr/bin"
    
    oradba_add_client_path "DATASAFE"
    
    # Client path should be at the end
    [[ "$PATH" =~ /datasafe/bin.*test_homes/client_19c/bin ]]
}

@test "add_client_path: does not add duplicate paths" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    local client_bin="${TEST_DIR}/test_homes/client_19c/bin"
    export PATH="/usr/bin:${client_bin}:/bin"
    
    oradba_add_client_path "DATASAFE"
    
    # Count occurrences of client path
    local count
    count=$(echo "$PATH" | grep -o "${client_bin}" | wc -l)
    [ "$count" -eq 1 ]
}

@test "add_client_path: does not add path for DATABASE product" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    export PATH="/usr/bin:/bin"
    
    oradba_add_client_path "DATABASE"
    [[ ! "$PATH" =~ test_homes/client_19c/bin ]]
}

@test "add_client_path: does not add path for CLIENT product" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    export PATH="/usr/bin:/bin"
    
    oradba_add_client_path "CLIENT"
    [[ ! "$PATH" =~ test_homes/client_19c/bin ]]
}

@test "add_client_path: works with auto setting" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="auto"
    export PATH="/usr/bin:/bin"
    
    oradba_add_client_path "OUD"
    
    # Should have added some client path
    [[ "$PATH" =~ test_homes/(client_19c|instantclient_19_19) ]]
}

# ==============================================================================
# Integration Tests - PATH Ordering
# ==============================================================================

@test "integration: client path comes after product path" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    export PATH="/home/bin:/usr/bin:/bin"
    
    # Simulate DataSafe setup
    local ds_bin="${TEST_DIR}/test_homes/datasafe/bin"
    export PATH="${ds_bin}:${PATH}"
    
    # Add client path
    oradba_add_client_path "DATASAFE"
    
    # DataSafe bin should come before client bin
    local ds_pos
    local client_pos
    ds_pos=$(echo "$PATH" | grep -o "^[^:]*:.*${ds_bin}" | wc -c)
    client_pos=$(echo "$PATH" | grep -o "^[^:]*:.*test_homes/client_19c/bin" | wc -c)
    
    [ "$ds_pos" -lt "$client_pos" ]
}

@test "integration: deduplication preserves order" {
    export ORADBA_CLIENT_PATH_FOR_NON_CLIENT="CL19"
    local client_bin="${TEST_DIR}/test_homes/client_19c/bin"
    
    # Setup PATH with duplicate in the middle
    export PATH="/usr/bin:${client_bin}:/bin"
    
    # Add client path (should detect duplicate)
    oradba_add_client_path "DATASAFE"
    
    # Should only appear once
    local count
    count=$(echo "$PATH" | grep -o "${client_bin}" | wc -l)
    [ "$count" -eq 1 ]
    
    # Should still have all other paths
    [[ "$PATH" =~ /usr/bin ]]
    [[ "$PATH" =~ /bin ]]
}
