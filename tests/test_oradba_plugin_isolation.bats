#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_plugin_isolation.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026-06-26
# Purpose....: Verify tiered isolation model (DECISION 2, CF-004) - M4
# Notes......: Tests state leakage, path-builder equivalence, and no direct
#              state-changing calls in src/bin and src/lib outside plugin files.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

# Setup
setup() {
    SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    export ORADBA_SRC="${REPO_ROOT}/src"
    export ORADBA_BASE="${ORADBA_SRC}"

    # Source common library for execute_plugin_function_v2
    source "${ORADBA_SRC}/lib/oradba_common.sh"

    # Create isolated plugin dir under BATS_TEST_TMPDIR
    export TEST_PLUGIN_DIR="${BATS_TEST_TMPDIR}/lib/plugins"
    mkdir -p "${TEST_PLUGIN_DIR}"
    # Point ORADBA_BASE to test tmpdir so wrapper finds test plugins
    export ORADBA_BASE="${BATS_TEST_TMPDIR}"
    mkdir -p "${BATS_TEST_TMPDIR}/lib/plugins"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR:?}/lib"
}

# ------------------------------------------------------------------------------
# Test 1: No state leakage after state-changing call
# Verify that execute_plugin_function_v2 runs in a subshell so that variables
# set inside the plugin (plugin_status, plugin_name) do NOT leak to the parent.
# ------------------------------------------------------------------------------
@test "M4: no state leakage after state-changing call via wrapper" {
    # Create a mock plugin that sets plugin_status and plugin_name
    cat > "${BATS_TEST_TMPDIR}/lib/plugins/mock_plugin.sh" << 'PLUGIN'
plugin_name="mock_plugin_set"
plugin_status="INJECTED"
plugin_check_status() {
    plugin_name="should_not_leak"
    plugin_status="leaked_value"
    export LEAKED_VAR="should_not_be_visible"
    return 0
}
PLUGIN

    # Ensure variables are NOT set before the call
    unset plugin_status
    unset plugin_name
    unset LEAKED_VAR

    # Call via wrapper
    run execute_plugin_function_v2 "mock" "check_status" "/fake/oracle/home"
    [ "$status" -eq 0 ]

    # Verify none of the plugin-set variables leaked into the parent shell
    [[ -z "${plugin_status:-}" ]] || {
        echo "FAIL: plugin_status leaked: '${plugin_status}'" >&2
        return 1
    }
    [[ -z "${plugin_name:-}" ]] || {
        echo "FAIL: plugin_name leaked: '${plugin_name}'" >&2
        return 1
    }
    [[ -z "${LEAKED_VAR:-}" ]] || {
        echo "FAIL: LEAKED_VAR leaked: '${LEAKED_VAR}'" >&2
        return 1
    }
}

# ------------------------------------------------------------------------------
# Test 2: Pure path-builder equivalence
# show that build_bin_path called directly (after sourcing the plugin)
# returns the same result as calling it via execute_plugin_function_v2.
# ------------------------------------------------------------------------------
@test "M4: pure path-builder direct call matches wrapper call" {
    # Create a mock plugin with a simple plugin_build_bin_path
    cat > "${BATS_TEST_TMPDIR}/lib/plugins/pathtest_plugin.sh" << 'PLUGIN'
plugin_status="stable"
plugin_interface_version="1.0.0"
plugin_build_bin_path() {
    local oracle_home="$1"
    echo "${oracle_home}/bin"
}
PLUGIN

    local test_home="/opt/oracle/product/21c/dbhome_1"

    # Direct call after sourcing (audited exception for pure path-builders)
    # shellcheck source=/dev/null
    source "${BATS_TEST_TMPDIR}/lib/plugins/pathtest_plugin.sh"
    local direct_result
    direct_result=$(plugin_build_bin_path "${test_home}")

    # Call via wrapper
    local wrapper_result=""
    execute_plugin_function_v2 "pathtest" "build_bin_path" "${test_home}" "wrapper_result"

    # Both must return the same path
    [ "${direct_result}" = "${wrapper_result}" ] || {
        echo "FAIL: direct='${direct_result}' vs wrapper='${wrapper_result}'" >&2
        return 1
    }
    [ "${direct_result}" = "${test_home}/bin" ] || {
        echo "FAIL: expected '${test_home}/bin', got '${direct_result}'" >&2
        return 1
    }
}

# ------------------------------------------------------------------------------
# Test 3: No direct state-changing calls in src/bin/ and src/lib/ outside plugin
# files and the wrapper function itself.
# This is a static-analysis regression test that enforces DECISION 2.
# ------------------------------------------------------------------------------
@test "M4: no direct state-changing plugin calls outside plugin files and wrapper" {
    local src_bin="${ORADBA_SRC}/bin"
    local src_lib="${ORADBA_SRC}/lib"

    # Grep for direct state-changing function calls
    # Filter out:
    #   - Lines containing 'execute_plugin_function_v2' (wrapper calls are OK)
    #   - Lines in src/lib/plugins/ (function definitions in plugin files are OK)
    #   - Lines containing '#' (comments are OK)
    local violations
    violations=$(
        grep -Ern \
            'plugin_detect_installation|plugin_check_status|plugin_check_listener_status' \
            "${src_bin}" "${src_lib}" 2>/dev/null |
            grep -v 'execute_plugin_function_v2' |
            grep -v '/plugins/' |
            grep -v '#' ||
            true
    )

    [ -z "${violations}" ] || {
        echo "FAIL: Direct state-changing plugin calls found outside allowed locations:" >&2
        echo "${violations}" >&2
        return 1
    }
}
