#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_home_discovery.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.26
# Revision...: 0.27.0
# Purpose....: Behavioral tests for oradba_home_discovery.sh (CF-008)
# Notes......: Covers product-type detection, Oracle-home recognition, path
#              containment, registry parsing and listing. Uses filesystem mocks
#              in BATS_TEST_TMPDIR and a temporary oradba_homes.conf.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Use an isolated ORADBA_BASE so our temp etc/oradba_homes.conf is picked up
    export ORADBA_BASE="${BATS_TEST_TMPDIR}/oradba"
    mkdir -p "${ORADBA_BASE}/lib" "${ORADBA_BASE}/etc"

    # Source common (provides oradba_log etc.) and the discovery module from src
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    source "${PROJECT_ROOT}/src/lib/oradba_home_discovery.sh"

    HOMES_CONF="${ORADBA_BASE}/etc/oradba_homes.conf"
}

teardown() {
    unset ORADBA_BASE
}

# ------------------------------------------------------------------------------
# detect_product_type
# ------------------------------------------------------------------------------

@test "detect_product_type recognises a database home" {
    local home="${BATS_TEST_TMPDIR}/db_home"
    mkdir -p "${home}/bin"
    touch "${home}/bin/sqlplus" "${home}/bin/oracle"
    run detect_product_type "${home}"
    [ "$status" -eq 0 ]
    [ "$output" = "database" ]
}

@test "detect_product_type recognises a client home (sqlplus, no oracle)" {
    local home="${BATS_TEST_TMPDIR}/client_home"
    mkdir -p "${home}/bin"
    touch "${home}/bin/sqlplus"
    run detect_product_type "${home}"
    [ "$status" -eq 0 ]
    [ "$output" = "client" ]
}

@test "detect_product_type returns unknown for an empty directory" {
    local home="${BATS_TEST_TMPDIR}/empty_home"
    mkdir -p "${home}"
    run detect_product_type "${home}"
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

@test "detect_product_type returns unknown for a non-existent path" {
    run detect_product_type "${BATS_TEST_TMPDIR}/missing_home"
    [ "$status" -eq 1 ]
    [ "$output" = "unknown" ]
}

# ------------------------------------------------------------------------------
# is_oracle_home (registry-backed)
# ------------------------------------------------------------------------------

@test "is_oracle_home returns true for a registered home name" {
    printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:50:db19:DB 19c:19.0.0\n' > "${HOMES_CONF}"
    run is_oracle_home "rdbms1900"
    [ "$status" -eq 0 ]
}

@test "is_oracle_home returns false for an unregistered name" {
    printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:50:db19:DB 19c:19.0.0\n' > "${HOMES_CONF}"
    run is_oracle_home "NOTAHOME"
    [ "$status" -eq 1 ]
}

@test "is_oracle_home rejects an empty argument" {
    run is_oracle_home ""
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# parse_oracle_home / list_oracle_homes
# ------------------------------------------------------------------------------

@test "parse_oracle_home returns fields for a registered home" {
    printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:50:db19:DB 19c:19.0.0\n' > "${HOMES_CONF}"
    run parse_oracle_home "rdbms1900"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rdbms1900"* ]]
    [[ "$output" == *"/u01/app/oracle/product/19/dbhome_1"* ]]
    [[ "$output" == *"database"* ]]
}

@test "parse_oracle_home resolves an alias to the canonical name" {
    printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:50:db19:DB 19c:19.0.0\n' > "${HOMES_CONF}"
    run parse_oracle_home "db19"
    [ "$status" -eq 0 ]
    [[ "$output" == rdbms1900* ]]
}

@test "parse_oracle_home fails for an unknown home" {
    printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:50:db19:DB 19c:19.0.0\n' > "${HOMES_CONF}"
    run parse_oracle_home "UNKNOWNHOME"
    [ "$status" -eq 1 ]
}

@test "parse_oracle_home fails when no name is given" {
    run parse_oracle_home ""
    [ "$status" -eq 1 ]
}

@test "list_oracle_homes lists all registered homes sorted by order" {
    {
        printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:60:db19:DB 19c:19.0.0\n'
        printf 'client2300:/u01/app/oracle/product/23/client_1:client:50:cl23:Client 23:23.0.0\n'
    } > "${HOMES_CONF}"
    run list_oracle_homes
    [ "$status" -eq 0 ]
    [[ "$output" == *"rdbms1900"* ]]
    [[ "$output" == *"client2300"* ]]
    # client2300 (order 50) must appear before rdbms1900 (order 60)
    [[ "${lines[0]}" == client2300* ]]
}

@test "list_oracle_homes filters by product type" {
    {
        printf 'rdbms1900:/u01/app/oracle/product/19/dbhome_1:database:60:db19:DB 19c:19.0.0\n'
        printf 'client2300:/u01/app/oracle/product/23/client_1:client:50:cl23:Client 23:23.0.0\n'
    } > "${HOMES_CONF}"
    run list_oracle_homes "client"
    [ "$status" -eq 0 ]
    [[ "$output" == *"client2300"* ]]
    [[ "$output" != *"rdbms1900"* ]]
}

@test "list_oracle_homes fails when the config file is absent" {
    rm -f "${HOMES_CONF}"
    run list_oracle_homes
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# is_subdirectory_of_oracle_home
# ------------------------------------------------------------------------------

@test "is_subdirectory_of_oracle_home detects a nested directory" {
    local home="${BATS_TEST_TMPDIR}/oh_parent"
    mkdir -p "${home}/jdk"
    run is_subdirectory_of_oracle_home "${home}/jdk" "${home}"
    [ "$status" -eq 0 ]
}

@test "is_subdirectory_of_oracle_home rejects an unrelated directory" {
    local home="${BATS_TEST_TMPDIR}/oh_parent2"
    local other="${BATS_TEST_TMPDIR}/somewhere_else"
    mkdir -p "${home}" "${other}"
    run is_subdirectory_of_oracle_home "${other}" "${home}"
    [ "$status" -eq 1 ]
}
