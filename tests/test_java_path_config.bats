#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_java_path_config.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.21
# Purpose..: Unit tests for Java path configuration feature
# Reference: Feature - Add autonomous JAVA_HOME detection and export
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_java_path_$$"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/etc"
    mkdir -p "${TEST_DIR}/test_homes"
    
    # Set ORADBA_BASE and ORADBA_PREFIX
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    export ORADBA_PREFIX="${ORADBA_BASE}"
    
    # Source required libraries
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
    
    # Create mock homes
    setup_mock_homes
    
    # Create mock oracle homes config
    create_mock_homes_config
}

teardown() {
    /bin/rm -rf "${TEST_DIR}"
    unset ORADBA_JAVA_PATH_FOR_NON_JAVA
    unset JAVA_HOME
}

# Helper: Setup mock Oracle and Java homes
setup_mock_homes() {
    # Mock Java home (standalone)
    local java_home="${TEST_DIR}/test_homes/jdk-17"
    mkdir -p "${java_home}/bin"
    mkdir -p "${java_home}/lib"
    touch "${java_home}/bin/java"
    touch "${java_home}/bin/javac"
    chmod +x "${java_home}/bin/java"
    chmod +x "${java_home}/bin/javac"
    
    # Mock another Java home
    local java11_home="${TEST_DIR}/test_homes/jdk-11"
    mkdir -p "${java11_home}/bin"
    mkdir -p "${java11_home}/lib"
    touch "${java11_home}/bin/java"
    touch "${java11_home}/bin/javac"
    chmod +x "${java11_home}/bin/java"
    chmod +x "${java11_home}/bin/javac"
    
    # Mock Oracle Home with embedded Java
    local db_home="${TEST_DIR}/test_homes/db_19c"
    mkdir -p "${db_home}/bin"
    mkdir -p "${db_home}/java/bin"
    touch "${db_home}/bin/sqlplus"
    touch "${db_home}/java/bin/java"
    chmod +x "${db_home}/bin/sqlplus"
    chmod +x "${db_home}/java/bin/java"
    
    # Mock DataSafe home (no Java)
    local ds_home="${TEST_DIR}/test_homes/datasafe"
    mkdir -p "${ds_home}/bin"
    touch "${ds_home}/bin/cmctl"
    chmod +x "${ds_home}/bin/cmctl"
    
    # Mock OUD home (no Java)
    local oud_home="${TEST_DIR}/test_homes/oud12c"
    mkdir -p "${oud_home}/oud/bin"
    touch "${oud_home}/setup"
    chmod +x "${oud_home}/setup"
}

# Helper: Create mock oradba_homes.conf
create_mock_homes_config() {
    # Use absolute paths that actually exist
    local java_home="${TEST_DIR}/test_homes/jdk-17"
    local java11_home="${TEST_DIR}/test_homes/jdk-11"
    local db_home="${TEST_DIR}/test_homes/db_19c"
    local ds_home="${TEST_DIR}/test_homes/datasafe"
    local oud_home="${TEST_DIR}/test_homes/oud12c"
    
    # Format: NAME:PATH:TYPE:ORDER:ALIAS:DESC:VERSION
    cat > "${TEST_DIR}/etc/oradba_homes.conf" <<EOF
# Mock oracle homes configuration
JAVA17:${java_home}:JAVA:10:JDK17:Java Development Kit 17:17.0.1
JAVA11:${java11_home}:JAVA:20:JDK11:Java Development Kit 11:11.0.12
DB19:${db_home}:DATABASE:30:DB19:Oracle Database 19c:19.0.0.0.0
DS:${ds_home}:DATASAFE:50:DS:Oracle Data Safe Connector:1.0.0.0.0
OUD12:${oud_home}:OUD:60:OUD12:Oracle Unified Directory 12c:12.2.1.4.0
EOF
    
    # Override get_oracle_homes_path to return our mock config
    get_oracle_homes_path() {
        echo "${TEST_DIR}/etc/oradba_homes.conf"
        return 0
    }
}

# ==============================================================================
# Tests for oradba_product_needs_java
# ==============================================================================

@test "product_needs_java: DATASAFE needs Java" {
    run oradba_product_needs_java "DATASAFE"
    [ "$status" -eq 0 ]
}

@test "product_needs_java: OUD needs Java" {
    run oradba_product_needs_java "OUD"
    [ "$status" -eq 0 ]
}

@test "product_needs_java: WLS needs Java" {
    run oradba_product_needs_java "WLS"
    [ "$status" -eq 0 ]
}

@test "product_needs_java: WEBLOGIC needs Java" {
    run oradba_product_needs_java "WEBLOGIC"
    [ "$status" -eq 0 ]
}

@test "product_needs_java: DATABASE doesn't need external Java (has built-in)" {
    run oradba_product_needs_java "DATABASE"
    [ "$status" -ne 0 ]
}

@test "product_needs_java: CLIENT doesn't need external Java" {
    run oradba_product_needs_java "CLIENT"
    [ "$status" -ne 0 ]
}

@test "product_needs_java: JAVA product doesn't need external Java" {
    run oradba_product_needs_java "JAVA"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Tests for oradba_resolve_java_home
# ==============================================================================

@test "resolve_java_home: returns error when set to 'none'" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="none"
    run oradba_resolve_java_home
    [ "$status" -ne 0 ]
}

@test "resolve_java_home: finds Java in ORACLE_HOME/java with 'auto'" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    local db_home="${TEST_DIR}/test_homes/db_19c"
    
    run oradba_resolve_java_home "${db_home}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ db_19c/java ]]
}

@test "resolve_java_home: finds first Java in oradba_homes.conf with 'auto' when no ORACLE_HOME/java" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    
    run oradba_resolve_java_home ""
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/jdk- ]]
}

@test "resolve_java_home: resolves specific Java by short name" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA17"
    run oradba_resolve_java_home
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/jdk-17 ]]
}

@test "resolve_java_home: resolves specific Java by alias" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JDK11"
    run oradba_resolve_java_home
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_homes/jdk-11 ]]
}

@test "resolve_java_home: returns error for non-existent Java" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="NONEXISTENT"
    run oradba_resolve_java_home
    [ "$status" -ne 0 ]
}

@test "resolve_java_home: returns error for non-Java product" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="DS"
    run oradba_resolve_java_home
    [ "$status" -ne 0 ]
}

@test "resolve_java_home: prefers ORACLE_HOME/java over oradba_homes.conf with 'auto'" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    local db_home="${TEST_DIR}/test_homes/db_19c"
    
    run oradba_resolve_java_home "${db_home}"
    [ "$status" -eq 0 ]
    # Should get db_19c/java not standalone jdk
    [[ "$output" =~ db_19c/java ]]
    [[ ! "$output" =~ jdk-17 ]]
}

# ==============================================================================
# Tests for oradba_add_java_path
# ==============================================================================

@test "add_java_path: does not add path when set to 'none'" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="none"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    run oradba_add_java_path "DATASAFE"
    [ "$status" -eq 0 ]
    [[ "$PATH" == "/usr/bin:/bin" ]]
    [[ -z "${JAVA_HOME}" ]]
}

@test "add_java_path: adds Java bin to PATH and exports JAVA_HOME for DATASAFE" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA17"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "DATASAFE"
    [[ "$PATH" =~ test_homes/jdk-17/bin ]]
    [[ "$JAVA_HOME" =~ test_homes/jdk-17 ]]
}

@test "add_java_path: prepends Java path to front of PATH" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA17"
    export PATH="/datasafe/bin:/usr/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "DATASAFE"
    
    # Java path should be at the beginning
    [[ "$PATH" =~ ^${TEST_DIR}/test_homes/jdk-17/bin: ]]
}

@test "add_java_path: does not add duplicate paths" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA17"
    local java_bin="${TEST_DIR}/test_homes/jdk-17/bin"
    export PATH="${java_bin}:/usr/bin:/bin"
    export JAVA_HOME="${TEST_DIR}/test_homes/jdk-17"
    
    oradba_add_java_path "DATASAFE"
    
    # Count occurrences of Java path
    local count
    count=$(echo "$PATH" | grep -o "${java_bin}" | wc -l)
    [ "$count" -eq 1 ]
}

@test "add_java_path: does not add path for DATABASE product when set to 'none'" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="none"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "DATABASE"
    [[ ! "$PATH" =~ test_homes/jdk-17/bin ]]
    [[ -z "${JAVA_HOME}" ]]
}

@test "add_java_path: allows override for DATABASE product when explicitly set" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA17"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "DATABASE"
    [[ "$PATH" =~ test_homes/jdk-17/bin ]]
    [[ "$JAVA_HOME" =~ test_homes/jdk-17 ]]
}

@test "add_java_path: works with auto setting" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "OUD"
    
    # Should have added some Java path
    [[ "$PATH" =~ test_homes/(jdk-|db_19c/java) ]]
    [[ -n "${JAVA_HOME}" ]]
}

@test "add_java_path: auto uses ORACLE_HOME/java when available" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    local db_home="${TEST_DIR}/test_homes/db_19c"
    
    oradba_add_java_path "DATASAFE" "${db_home}"
    
    # Should use db_19c/java not standalone jdk
    [[ "$JAVA_HOME" =~ db_19c/java ]]
    [[ "$PATH" =~ db_19c/java/bin ]]
}

# ==============================================================================
# Integration tests
# ==============================================================================

@test "integration: DataSafe setup with auto Java detection" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    export PATH="/datasafe/bin:/usr/bin"
    unset JAVA_HOME
    
    # Simulate DataSafe setup
    local ds_home="${TEST_DIR}/test_homes/datasafe"
    
    # Add Java path
    oradba_add_java_path "DATASAFE" ""
    
    # Verify Java is set
    [[ -n "${JAVA_HOME}" ]]
    [[ "$PATH" =~ test_homes/(jdk-|db_19c/java) ]]
    
    # Java should come before DataSafe
    local java_pos ds_pos
    java_pos=$(echo "$PATH" | grep -ob "jdk-" | head -1 | cut -d: -f1)
    ds_pos=$(echo "$PATH" | grep -ob "datasafe" | head -1 | cut -d: -f1)
    [ "$java_pos" -lt "$ds_pos" ]
}

@test "integration: OUD setup with named Java" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="JAVA11"
    export PATH="/oud/bin:/usr/bin"
    unset JAVA_HOME
    
    # Add Java path
    oradba_add_java_path "OUD"
    
    # Verify correct Java is set
    [[ "$JAVA_HOME" =~ test_homes/jdk-11 ]]
    [[ "$PATH" =~ test_homes/jdk-11/bin ]]
}

@test "integration: backward compatibility - defaults to 'none'" {
    # Don't set ORADBA_JAVA_PATH_FOR_NON_JAVA - should default to "none"
    unset ORADBA_JAVA_PATH_FOR_NON_JAVA
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    
    oradba_add_java_path "DATASAFE"
    
    # Should not have added Java
    [[ ! "$PATH" =~ jdk- ]]
    [[ -z "${JAVA_HOME}" ]]
}

@test "integration: product with built-in Java uses ORACLE_HOME/java with auto" {
    export ORADBA_JAVA_PATH_FOR_NON_JAVA="auto"
    export PATH="/usr/bin:/bin"
    unset JAVA_HOME
    local db_home="${TEST_DIR}/test_homes/db_19c"
    
    # Even though DATABASE doesn't "need" Java, explicit setting should work
    oradba_add_java_path "DATABASE" "${db_home}"
    
    # Should have used embedded Java
    [[ "$JAVA_HOME" =~ db_19c/java ]]
}
