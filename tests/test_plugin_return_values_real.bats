#!/usr/bin/env bats
# shellcheck disable=SC1091
# ------------------------------------------------------------------------------
# OraDBA - Real plugin return-value contract tests
# Purpose.: Validate exit-code and stdout hygiene on real plugins using fake homes
# Scope...: Database, DataSafe, Client, Instant Client, Java, OUD
# Ref.....: #132 (return value compliance)
# ------------------------------------------------------------------------------

setup() {
    export TEST_ROOT="${BATS_TEST_TMPDIR}/plugin_rv_real_$$"
    mkdir -p "${TEST_ROOT}"
    export ORADBA_BASE="$(pwd)/src"  # ensure plugins can source helper paths if they need ORADBA_BASE
}

teardown() {
    rm -rf "${TEST_ROOT}"
}

# Helper to assert empty stdout when expected
assert_empty_stdout() {
    [ -z "$output" ]
}

# ------------------------------------------------------------------------------
# Fake homes per product
# ------------------------------------------------------------------------------

make_db_home() {
    local home="${TEST_ROOT}/dbhome"
    mkdir -p "${home}/bin" "${home}/rdbms" "${home}/OPatch" "${home}/lib"
    touch "${home}/bin/oracle"
    chmod +x "${home}/bin/oracle"
    echo "${home}"
}

make_datasafe_home() {
    local base="${TEST_ROOT}/dshome"
    mkdir -p "${base}/oracle_cman_home/bin" "${base}/oracle_cman_home/lib"
    touch "${base}/oracle_cman_home/bin/cmctl"
    chmod +x "${base}/oracle_cman_home/bin/cmctl"
    echo "${base}"
}

make_client_home() {
    local home="${TEST_ROOT}/client"
    mkdir -p "${home}/bin" "${home}/network/admin" "${home}/OPatch" "${home}/lib"
    touch "${home}/bin/sqlplus"
    chmod +x "${home}/bin/sqlplus"
    echo "${home}"
}

make_iclient_home() {
    local home="${TEST_ROOT}/iclient"
    mkdir -p "${home}/lib64"
    touch "${home}/libclntsh.so"
    echo "${home}"
}

make_java_home() {
    local home="${TEST_ROOT}/java"
    mkdir -p "${home}/bin" "${home}/lib/server"
    touch "${home}/bin/java"
    chmod +x "${home}/bin/java"
    echo "${home}"
}

make_oud_home() {
    local home="${TEST_ROOT}/oud"
    mkdir -p "${home}/bin" "${home}/lib"
    touch "${home}/setup"
    chmod +x "${home}/setup"
    # Provide a placeholder bin entry
    touch "${home}/bin/oudadm"
    chmod +x "${home}/bin/oudadm"
    echo "${home}"
}

# ------------------------------------------------------------------------------
# Database plugin
# ------------------------------------------------------------------------------
@test "database plugin: validate home and paths obey contract" {
    local home
    home=$(make_db_home)
    source src/lib/plugins/database_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_should_show_listener "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout
}

# ------------------------------------------------------------------------------
# DataSafe plugin
# ------------------------------------------------------------------------------
@test "datasafe plugin: validate home and paths obey contract" {
    local home
    home=$(make_datasafe_home)
    source src/lib/plugins/datasafe_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_should_show_listener "${home}"
    [ "$status" -eq 1 ]
    assert_empty_stdout
}

# ------------------------------------------------------------------------------
# Client plugin
# ------------------------------------------------------------------------------
@test "client plugin: validate home and paths obey contract" {
    local home
    home=$(make_client_home)
    source src/lib/plugins/client_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# ------------------------------------------------------------------------------
# Instant Client plugin
# ------------------------------------------------------------------------------
@test "iclient plugin: validate home and paths obey contract" {
    local home
    home=$(make_iclient_home)
    source src/lib/plugins/iclient_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${home}" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# ------------------------------------------------------------------------------
# Java plugin
# ------------------------------------------------------------------------------
@test "java plugin: validate home and paths obey contract" {
    local home
    home=$(make_java_home)
    source src/lib/plugins/java_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# ------------------------------------------------------------------------------
# OUD plugin
# ------------------------------------------------------------------------------
@test "oud plugin: validate home and paths obey contract" {
    local home
    home=$(make_oud_home)
    source src/lib/plugins/oud_plugin.sh

    run plugin_validate_home "${home}"
    [ "$status" -eq 0 ]
    assert_empty_stdout

    run plugin_build_bin_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    run plugin_build_lib_path "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
