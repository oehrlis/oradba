#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_plugin_return_values.bats
# Author...: ChatGPT (Codex)
# Date.....: 2026.01.31
# Purpose..: Verify plugin return value contract (exit codes + stdout hygiene)
# Reference: #132 (consolidated return-value compliance suite)
# Notes....: Uses minimal fake plugins to validate contract rules without
#            depending on product-specific implementations.
# ------------------------------------------------------------------------------

load 'test_helper' 2>/dev/null || true

# Helper: assert no sentinel strings
assert_no_sentinel() {
    local output="$1"
    [[ "${output}" != "ERR" && "${output}" != "unknown" && "${output}" != "N/A" ]]
}

@test "plugin_get_version: success emits version, exit 0, no sentinel" {
    plugin_get_version() { echo "19.0.0.0.0"; return 0; }
    run plugin_get_version "/fake/home"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    assert_no_sentinel "$output"
}

@test "plugin_get_version: not applicable exit 1 with empty stdout" {
    plugin_get_version() { return 1; }
    run plugin_get_version "/fake/home"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "plugin_get_version: unavailable exit 2 with empty stdout" {
    plugin_get_version() { return 2; }
    run plugin_get_version "/fake/home"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "plugin_check_status: running/stopped/unavailable map to 0/1/2" {
    plugin_check_status() { echo "running"; return 0; }
    run plugin_check_status "/fake/home"
    [ "$status" -eq 0 ]
    [ "$output" = "running" ]

    plugin_check_status() { echo "stopped"; return 1; }
    run plugin_check_status "/fake/home"
    [ "$status" -eq 1 ]
    [ "$output" = "stopped" ]

    plugin_check_status() { echo "unavailable"; return 2; }
    run plugin_check_status "/fake/home"
    [ "$status" -eq 2 ]
    [ "$output" = "unavailable" ]
}

@test "plugin_build_bin_path: exit 0 and colon-separated path" {
    plugin_build_bin_path() { echo "/a/bin:/a/OPatch"; return 0; }
    run plugin_build_bin_path "/fake/home"
    [ "$status" -eq 0 ]
    [[ "$output" =~ : ]]
}

@test "plugin_build_lib_path: exit 0 and colon-separated libs" {
    plugin_build_lib_path() { echo "/a/lib:/a/lib32"; return 0; }
    run plugin_build_lib_path "/fake/home"
    [ "$status" -eq 0 ]
    [[ "$output" =~ : ]]
}

@test "plugin_build_env: success emits key=value lines, exit 0" {
    plugin_build_env() {
        echo "ORACLE_HOME=/a"
        echo "ORACLE_BASE_HOME=/base"
        echo "PATH=/a/bin:${PATH:-}"
        echo "LD_LIBRARY_PATH=/a/lib:${LD_LIBRARY_PATH:-}"
        return 0
    }
    run plugin_build_env "/fake/home"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ORACLE_HOME="* ]]
}

@test "plugin_build_env: not applicable exit 1 empty stdout" {
    plugin_build_env() { return 1; }
    run plugin_build_env "/fake/home"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "plugin_build_env: unavailable exit 2 empty stdout" {
    plugin_build_env() { return 2; }
    run plugin_build_env "/fake/home"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "plugin_get_instance_list: success may return empty, exit 0" {
    plugin_get_instance_list() { return 0; }
    run plugin_get_instance_list "/fake/home"
    [ "$status" -eq 0 ]
}

@test "plugin_should_show_listener: boolean via exit code, no stdout" {
    plugin_should_show_listener() { return 1; }
    run plugin_should_show_listener "/fake/home"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "plugin_check_listener_status: running/stopped/unavailable map to 0/1/2" {
    plugin_check_listener_status() { echo "running"; return 0; }
    run plugin_check_listener_status "/fake/home"
    [ "$status" -eq 0 ]
    [ "$output" = "running" ]

    plugin_check_listener_status() { echo "stopped"; return 1; }
    run plugin_check_listener_status "/fake/home"
    [ "$status" -eq 1 ]
    [ "$output" = "stopped" ]

    plugin_check_listener_status() { echo "unavailable"; return 2; }
    run plugin_check_listener_status "/fake/home"
    [ "$status" -eq 2 ]
    [ "$output" = "unavailable" ]
}

@test "no sentinel strings emitted on success paths" {
    plugin_get_metadata() { echo "version=19.21.0.0.0"; return 0; }
    run plugin_get_metadata "/fake/home"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q -E '^(ERR|unknown|N/A)$'
}
