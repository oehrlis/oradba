#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# ------------------------------------------------------------------------------
# Name.......: test_oradba_help.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.02.11
# Purpose....: BATS tests for oradba_help.sh
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Get the absolute path to the src directory
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SRC_BIN_DIR="${SCRIPT_DIR}/src/bin"
    ORADBA_HELP="${SRC_BIN_DIR}/oradba_help.sh"
    
    # Set minimal environment
    export ORADBA_PREFIX="${SCRIPT_DIR}/src"
}

@test "oradba_help.sh exists and is executable" {
    [ -f "$ORADBA_HELP" ]
    [ -x "$ORADBA_HELP" ]
}

@test "oradba help shows main help menu" {
    run "$ORADBA_HELP"
    [ "$status" -eq 0 ]
    [[ "$output" =~ OraDBA\ Help\ System ]]
    [[ "$output" =~ TOPICS ]]
    [[ "$output" =~ aliases ]]
    [[ "$output" =~ scripts ]]
    [[ "$output" =~ variables ]]
}

@test "oradba help aliases shows alias help" {
    run "$ORADBA_HELP" aliases
    [ "$status" -eq 0 ]
    [[ "$output" =~ OraDBA\ Aliases ]]
}

@test "oradba help scripts shows available scripts" {
    run "$ORADBA_HELP" scripts
    [ "$status" -eq 0 ]
    [[ "$output" =~ OraDBA\ Scripts ]]
    [[ "$output" =~ Available\ scripts ]]
}

@test "oradba help variables shows environment variables" {
    export ORADBA_PREFIX="/opt/oradba"
    export ORACLE_SID="FREE"
    
    run "$ORADBA_HELP" variables
    [ "$status" -eq 0 ]
    [[ "$output" =~ Environment\ Variables ]]
    [[ "$output" =~ ORADBA_PREFIX ]]
}

@test "oradba help config shows configuration system" {
    run "$ORADBA_HELP" config
    [ "$status" -eq 0 ]
    [[ "$output" =~ Configuration\ System ]]
    [[ "$output" =~ oradba_core\.conf ]]
}

@test "oradba help sql shows SQL help" {
    run "$ORADBA_HELP" sql
    [ "$status" -eq 0 ]
    [[ "$output" =~ SQL\ Scripts ]]
}

@test "oradba help with --help flag shows main menu" {
    run "$ORADBA_HELP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ OraDBA\ Help\ System ]]
}

@test "oradba help with invalid topic shows error" {
    run "$ORADBA_HELP" invalid_topic
    [ "$status" -eq 1 ]
    [[ "$output" =~ Unknown\ topic ]]
}

@test "oradba help alias (singular) works" {
    run "$ORADBA_HELP" alias
    [ "$status" -eq 0 ]
    [[ "$output" =~ OraDBA\ Aliases ]]
}

@test "oradba help vars (short form) works" {
    run "$ORADBA_HELP" vars
    [ "$status" -eq 0 ]
    [[ "$output" =~ Environment\ Variables ]]
}

@test "oradba help conf (short form) works" {
    run "$ORADBA_HELP" conf
    [ "$status" -eq 0 ]
    [[ "$output" =~ Configuration\ System ]]
}
