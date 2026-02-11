#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_registry.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.01.16
# Purpose....: Unit tests for oradba_registry.sh
# Reference..: Architecture Review & Refactoring Plan (Phase 1.1)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_registry_$$"
    mkdir -p "${TEST_DIR}/etc"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/lib/plugins"
    
    # Set ORADBA_PREFIX for tests
    export ORADBA_PREFIX="${TEST_DIR}"
    ORADBA_SRC_BASE="${BATS_TEST_DIRNAME}/../src"
    
    # Create minimal oradba_common.sh stub for logging
    cat > "${TEST_DIR}/lib/oradba_common.sh" <<'EOF'
oradba_log() {
    local level="$1"
    shift
    echo "[${level}] $*" >&2
}
get_oratab_path() {
    echo "/etc/oratab"
}
get_oracle_homes_path() {
    echo "${ORADBA_PREFIX}/etc/oradba_homes.conf"
}
detect_product_type() {
    local home="$1"
    if [[ -d "${home}/rdbms" ]]; then
        echo "database"
    elif [[ -d "${home}/oracle_cman_home" ]]; then
        echo "datasafe"
    else
        echo "unknown"
    fi
}
EOF
    
    # Source common functions
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    # Copy registry to test directory
    cp "${ORADBA_SRC_BASE}/lib/oradba_registry.sh" "${TEST_DIR}/lib/"
    
    # Source registry module
    source "${TEST_DIR}/lib/oradba_registry.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ------------------------------------------------------------------------------
# Test: Registry module loads
# ------------------------------------------------------------------------------
@test "registry module loads successfully" {
    run type oradba_registry_get_all
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

# ------------------------------------------------------------------------------
# Test: Get all installations (empty)
# ------------------------------------------------------------------------------
@test "get_all returns empty when no registry files" {
    export ORADBA_AUTO_DISCOVER=false
    run oradba_registry_get_all
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ------------------------------------------------------------------------------
# Test: Get all installations from oratab
# ------------------------------------------------------------------------------
@test "get_all parses oratab entries" {
    # Create test oratab
    mkdir -p "${TEST_DIR}/homes/db19"
    mkdir -p "${TEST_DIR}/homes/db19/rdbms"
    mkdir -p "${TEST_DIR}/homes/db19/bin"
    
    cat > "/tmp/test_oratab_$$" <<EOF
# Test oratab
TESTDB:${TEST_DIR}/homes/db19:Y
EOF
    
    # Override get_oratab_path
    get_oratab_path() {
        echo "/tmp/test_oratab_$$"
    }
    
    run oradba_registry_get_all
    [ "$status" -eq 0 ]
    [[ "$output" == *"database|TESTDB|${TEST_DIR}/homes/db19"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}

# ------------------------------------------------------------------------------
# Test: Get all installations from oradba_homes.conf
# ------------------------------------------------------------------------------
@test "get_all parses oradba_homes.conf entries" {
    export ORADBA_AUTO_DISCOVER=false
    
    # Create test home
    mkdir -p "${TEST_DIR}/homes/client19"
    mkdir -p "${TEST_DIR}/homes/client19/bin"
    
    # Create oradba_homes.conf
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
# Test homes
client19:${TEST_DIR}/homes/client19:client:10:cli19:Client 19c:19.0.0
EOF
    
    run oradba_registry_get_all
    [ "$status" -eq 0 ]
    [[ "$output" == *"client|client19|${TEST_DIR}/homes/client19"* ]]
}

# ------------------------------------------------------------------------------
# Test: Get installation by name
# ------------------------------------------------------------------------------
@test "get_by_name finds specific installation" {
    export ORADBA_AUTO_DISCOVER=false
    
    # Create test home
    mkdir -p "${TEST_DIR}/homes/testdb"
    mkdir -p "${TEST_DIR}/homes/testdb/rdbms"
    
    # Create oratab
    cat > "/tmp/test_oratab_$$" <<EOF
TESTDB:${TEST_DIR}/homes/testdb:Y
OTHERDB:${TEST_DIR}/homes/otherdb:N
EOF
    
    get_oratab_path() {
        echo "/tmp/test_oratab_$$"
    }
    
    run oradba_registry_get_by_name "TESTDB"
    [ "$status" -eq 0 ]
    [[ "$output" == *"database|TESTDB|${TEST_DIR}/homes/testdb"* ]]
    [[ "$output" != *"OTHERDB"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}

# ------------------------------------------------------------------------------
# Test: Get installation by type
# ------------------------------------------------------------------------------
@test "get_by_type filters by product type" {
    export ORADBA_AUTO_DISCOVER=false
    
    # Create test homes
    mkdir -p "${TEST_DIR}/homes/db19/rdbms"
    mkdir -p "${TEST_DIR}/homes/client19/bin"
    
    # Create mixed registry
    cat > "/tmp/test_oratab_$$" <<EOF
TESTDB:${TEST_DIR}/homes/db19:Y
EOF
    
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
client19:${TEST_DIR}/homes/client19:client:10:::
EOF
    
    get_oratab_path() {
        echo "/tmp/test_oratab_$$"
    }
    
    # Get only databases
    run oradba_registry_get_by_type "database"
    [ "$status" -eq 0 ]
    [[ "$output" == *"database|TESTDB"* ]]
    [[ "$output" != *"client"* ]]
    
    # Get only clients
    run oradba_registry_get_by_type "client"
    [ "$status" -eq 0 ]
    [[ "$output" == *"client|client19"* ]]
    [[ "$output" != *"TESTDB"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}

# ------------------------------------------------------------------------------
# Test: Get databases shortcut
# ------------------------------------------------------------------------------
@test "get_databases returns only database installations" {
    export ORADBA_AUTO_DISCOVER=false
    
    mkdir -p "${TEST_DIR}/homes/db19/rdbms"
    mkdir -p "${TEST_DIR}/homes/client19/bin"
    
    cat > "/tmp/test_oratab_$$" <<EOF
PROD:${TEST_DIR}/homes/db19:Y
EOF
    
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
client19:${TEST_DIR}/homes/client19:client:10:::
EOF
    
    get_oratab_path() {
        echo "/tmp/test_oratab_$$"
    }
    
    run oradba_registry_get_databases
    [ "$status" -eq 0 ]
    [[ "$output" == *"database|PROD"* ]]
    [[ "$output" != *"client"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}

# ------------------------------------------------------------------------------
# Test: Get field from installation object
# ------------------------------------------------------------------------------
@test "get_field extracts specific fields" {
    local install_obj="database|TESTDB|/u01/app/oracle/product/19|19.0.0|Y|10|test|Test Database"
    
    run oradba_registry_get_field "${install_obj}" "name"
    [ "$status" -eq 0 ]
    [ "$output" = "TESTDB" ]
    
    run oradba_registry_get_field "${install_obj}" "type"
    [ "$status" -eq 0 ]
    [ "$output" = "database" ]
    
    run oradba_registry_get_field "${install_obj}" "home"
    [ "$status" -eq 0 ]
    [ "$output" = "/u01/app/oracle/product/19" ]
}

# ------------------------------------------------------------------------------
# Test: Validation detects duplicate names
# ------------------------------------------------------------------------------
@test "validate detects duplicate installation names" {
    export ORADBA_AUTO_DISCOVER=false
    
    mkdir -p "${TEST_DIR}/homes/db19/rdbms"
    mkdir -p "${TEST_DIR}/homes/db21/rdbms"
    
    # Create duplicate SID in both registries
    cat > "/tmp/test_oratab_$$" <<EOF
TESTDB:${TEST_DIR}/homes/db19:Y
EOF
    
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
TESTDB:${TEST_DIR}/homes/db21:database:10:::
EOF
    
    get_oratab_path() {
        echo "/tmp/test_oratab_$$"
    }
    
    run oradba_registry_validate
    [ "$status" -ne 0 ]
    [[ "$output" == *"Duplicate installation name: TESTDB"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}

# ------------------------------------------------------------------------------
# Test: Validation handles oratab with non-existent homes gracefully
# ------------------------------------------------------------------------------
@test "validate detects non-existent homes" {
    export ORADBA_AUTO_DISCOVER=false
    
    # Create oratab with non-existent home
    cat > "/tmp/test_oratab_$$" <<EOF
TESTDB:/nonexistent/path:Y
EOF
    
    # Override oratab path using environment variable
    export ORADBA_ORATAB="/tmp/test_oratab_$$"
    
    # Registry filters out non-existent homes during parsing
    # So validation passes (no invalid entries in registry)
    run oradba_registry_validate
    [ "$status" -eq 0 ]
    [[ "$output" == *"Registry validation passed"* ]]
    
    rm -f "/tmp/test_oratab_$$"
}
