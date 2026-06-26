#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_output.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.26
# Revision...: 0.27.0
# Purpose....: Smoke tests for oradba_env_output.sh (CF-008)
# Notes......: Verifies clean sourcing, presence of public formatting helpers,
#              and basic output behaviour of the divider / key-value / section
#              functions.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    OUTPUT_LIB="${ORADBA_BASE}/lib/oradba_env_output.sh"
    source "${OUTPUT_LIB}"
}

# ------------------------------------------------------------------------------
# Sourcing and function presence
# ------------------------------------------------------------------------------

@test "env_output: library sources without error" {
    run bash -c "source '${OUTPUT_LIB}'"
    [ "$status" -eq 0 ]
}

@test "env_output: oradba_env_output_divider is defined" {
    declare -f oradba_env_output_divider >/dev/null
}

@test "env_output: oradba_env_output_kv is defined" {
    declare -f oradba_env_output_kv >/dev/null
}

@test "env_output: oradba_env_output_resolve_oracle_base is defined" {
    declare -f oradba_env_output_resolve_oracle_base >/dev/null
}

@test "env_output: oradba_env_output_print_home_section is defined" {
    declare -f oradba_env_output_print_home_section >/dev/null
}

@test "env_output: show_oracle_home_status is defined" {
    declare -f show_oracle_home_status >/dev/null
}

# ------------------------------------------------------------------------------
# Behavioural smoke tests
# ------------------------------------------------------------------------------

@test "env_output: divider prints a non-empty line" {
    run oradba_env_output_divider
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^-+$ ]]
}

@test "env_output: kv prints label and value" {
    run oradba_env_output_kv "ORACLE_HOME" "/u01/app/oracle"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ORACLE_HOME ]]
    [[ "$output" =~ /u01/app/oracle ]]
}

@test "env_output: kv suppresses empty value by default" {
    run oradba_env_output_kv "TNS_ADMIN" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "env_output: kv forces output of empty value when requested" {
    run oradba_env_output_kv "TNS_ADMIN" "" "true"
    [ "$status" -eq 0 ]
    [[ "$output" =~ TNS_ADMIN ]]
}

@test "env_output: resolve_oracle_base falls back to 'not set' when nothing known" {
    run env -u ORACLE_BASE bash -c "
        source '${OUTPUT_LIB}'
        oradba_env_output_resolve_oracle_base ''
    "
    [ "$status" -eq 0 ]
    [ "$output" = "not set" ]
}

@test "env_output: resolve_oracle_base echoes ORACLE_BASE when set" {
    export ORACLE_BASE="/u01/app/oracle"
    run oradba_env_output_resolve_oracle_base "/u01/app/oracle/product/19/dbhome_1"
    [ "$status" -eq 0 ]
    [ "$output" = "/u01/app/oracle" ]
}

@test "env_output: print_home_section emits the ORACLE_BASE label" {
    run oradba_env_output_print_home_section "/u01/app/oracle" "/u01/app/oracle/product/19" "" "" "" "19.0.0" "database"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ORACLE_BASE ]]
    [[ "$output" =~ PRODUCT_TYPE ]]
}
