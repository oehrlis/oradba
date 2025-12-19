#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: test_sid_config.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.7.2
# Purpose....: Test SID configuration auto-creation from template
# ------------------------------------------------------------------------------

# Setup function - runs before each test
setup() {
    local temp_dir
    temp_dir=$(mktemp -d)
    export TEST_DIR="${temp_dir}"
    local root_dir
    root_dir="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)"
    export PROJECT_ROOT="${root_dir}"
    
    # Create etc directory structure
    mkdir -p "${TEST_DIR}/etc"
    mkdir -p "${TEST_DIR}/lib"
    
    # Copy necessary files
    cp "${PROJECT_ROOT}/src/etc/sid.ORACLE_SID.conf.example" "${TEST_DIR}/etc/"
    cp "${PROJECT_ROOT}/src/lib/common.sh" "${TEST_DIR}/lib/"
    
    # Set environment for testing
    export ORADBA_PREFIX="${TEST_DIR}"
    export ORADBA_CONFIG_DIR="${TEST_DIR}/etc"
}

# Teardown function - runs after each test
teardown() {
    if [[ -n "${TEST_DIR}" && -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

# Basic template tests
@test "sid.ORACLE_SID.conf.example template file exists" {
    [[ -f "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" ]]
}

@test "Template contains expected variables" {
    grep -q "ORADBA_DB_NAME=\"ORCL\"" "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example"
    grep -q "ORADBA_TNS_ALIAS=\"ORCL\"" "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example"
}

# SID replacement tests
@test "sed correctly replaces ORCL with FREE" {
    local sid="FREE"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    [[ -f "${TEST_DIR}/etc/sid.${sid}.conf" ]]
    grep -q "ORADBA_DB_NAME=\"FREE\"" "${TEST_DIR}/etc/sid.${sid}.conf"
    grep -q "ORADBA_TNS_ALIAS=\"FREE\"" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "sed correctly replaces lowercase orcl with free" {
    local sid="FREE"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    # Check for lowercase replacement in paths
    grep -q "rdbms/free/" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "sed works with different SID names" {
    for sid in "TEST" "PROD" "DEV123"; do
        sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
            "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
        
        [[ -f "${TEST_DIR}/etc/sid.${sid}.conf" ]]
        grep -q "ORADBA_DB_NAME=\"${sid}\"" "${TEST_DIR}/etc/sid.${sid}.conf"
    done
}

@test "Created config file is valid bash syntax" {
    local sid="FREE"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    # Try to source it
    bash -n "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "Created config preserves all settings" {
    local sid="FREE"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    # Check key settings are present
    grep -q "ORADBA_DB_UNIQUE_NAME" "${TEST_DIR}/etc/sid.${sid}.conf"
    grep -q "NLS_LANG" "${TEST_DIR}/etc/sid.${sid}.conf"
    grep -q "ORADBA_BACKUP_RETENTION" "${TEST_DIR}/etc/sid.${sid}.conf"
    grep -q "ORADBA_DIAGNOSTIC_DEST" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "Date stamp is updated in created config" {
    local sid="FREE"
    local today
    today=$(date '+%Y.%m.%d')
    
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g; \
         s/Date.......: .*/Date.......: ${today}/" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    grep -q "Date.......: ${today}" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "Auto-created comment is updated" {
    local sid="FREE"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M')
    
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g; \
         s/Auto-created on first environment switch/Auto-created: ${timestamp}/" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    grep -q "Auto-created:" "${TEST_DIR}/etc/sid.${sid}.conf"
}

# Integration test with create_sid_config function
@test "create_sid_config function exists in common.sh" {
    grep -q "^create_sid_config()" "${TEST_DIR}/lib/common.sh"
}

@test "create_sid_config function checks for template" {
    grep -q "sid.ORACLE_SID.conf.example" "${TEST_DIR}/lib/common.sh"
}

@test "create_sid_config uses sed for replacement" {
    grep -q "sed.*ORCL.*\${sid}" "${TEST_DIR}/lib/common.sh"
}

# Edge cases
@test "Works with single-letter SID" {
    local sid="X"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    [[ -f "${TEST_DIR}/etc/sid.${sid}.conf" ]]
    grep -q "ORADBA_DB_NAME=\"X\"" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "Works with long SID name" {
    local sid="VERYLONGSIDNAME"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    [[ -f "${TEST_DIR}/etc/sid.${sid}.conf" ]]
    grep -q "ORADBA_DB_NAME=\"VERYLONGSIDNAME\"" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "Handles SID with numbers" {
    local sid="DB19C"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    [[ -f "${TEST_DIR}/etc/sid.${sid}.conf" ]]
    grep -q "ORADBA_DB_NAME=\"DB19C\"" "${TEST_DIR}/etc/sid.${sid}.conf"
    grep -q "rdbms/db19c/" "${TEST_DIR}/etc/sid.${sid}.conf"
}

@test "No residual ORCL values in created config" {
    local sid="FREE"
    sed "s/ORCL/${sid}/g; s/orcl/${sid,,}/g" \
        "${TEST_DIR}/etc/sid.ORACLE_SID.conf.example" > "${TEST_DIR}/etc/sid.${sid}.conf"
    
    # Should not find ORCL except in comments/descriptions
    ! grep -E "^[^#]*=\".*ORCL" "${TEST_DIR}/etc/sid.${sid}.conf"
}
# Dummy SID tests
@test "Dummy SID check works with ORADBA_REALSIDLIST" {
    # Simulate having both real and dummy SIDs
    export ORADBA_SIDLIST="FREE rdbms26 CDB1"
    export ORADBA_REALSIDLIST="FREE CDB1"
    
    # Check that FREE is in REALSIDLIST (should auto-create)
    [[ " ${ORADBA_REALSIDLIST} " =~ " FREE " ]]
    
    # Check that rdbms26 is NOT in REALSIDLIST (should skip auto-create)
    ! [[ " ${ORADBA_REALSIDLIST} " =~ " rdbms26 " ]]
}