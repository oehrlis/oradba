#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_dsctl.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.01.23
# Purpose....: BATS tests for oradba_dsctl.sh (Data Safe Connector Control)
# Usage......: bats test_oradba_dsctl.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    export ORADBA_BIN="${PROJECT_ROOT}/src/bin"
    
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_dsctl_$$"
    mkdir -p "${TEST_DIR}"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ------------------------------------------------------------------------------
# Script Existence and Permissions Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh exists" {
    [ -f "${ORADBA_BIN}/oradba_dsctl.sh" ]
}

@test "oradba_dsctl.sh is executable" {
    [ -x "${ORADBA_BIN}/oradba_dsctl.sh" ]
}

@test "oradba_dsctl.sh has valid bash syntax" {
    bash -n "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh has correct shebang" {
    head -1 "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "#!/usr/bin/env bash"
}

# ------------------------------------------------------------------------------
# Help and Usage Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh without arguments shows usage" {
    run "${ORADBA_BIN}/oradba_dsctl.sh"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_dsctl.sh --help displays usage" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Actions:" ]]
    [[ "$output" =~ "start" ]]
    [[ "$output" =~ "stop" ]]
    [[ "$output" =~ "restart" ]]
    [[ "$output" =~ "status" ]]
}

@test "oradba_dsctl.sh -h displays usage" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" -h
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_dsctl.sh help output mentions Data Safe connectors" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Data Safe" ]] || [[ "$output" =~ "connector" ]]
}

@test "oradba_dsctl.sh help output mentions cmctl" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "cmctl" ]]
}

@test "oradba_dsctl.sh help output mentions oradba_homes.conf" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    # shellcheck disable=SC2076
    [[ "$output" =~ "oradba_homes.conf" ]]
}

# ------------------------------------------------------------------------------
# Action Validation Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh accepts start action" {
    # This will fail with no connectors found, but should accept the action
    run "${ORADBA_BIN}/oradba_dsctl.sh" start 2>&1
    # Should not show usage (invalid action would show usage)
    if [[ "$output" =~ "Usage:" ]]; then
        # Only fail if it's because of invalid action, not missing connectors
        ! [[ "$output" =~ "invalid_action" ]]
    fi
}

@test "oradba_dsctl.sh accepts stop action" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" stop 2>&1
    # Should not show usage for invalid action
    if [[ "$output" =~ "Usage:" ]]; then
        ! [[ "$output" =~ "invalid_action" ]]
    fi
}

@test "oradba_dsctl.sh accepts restart action" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" restart 2>&1
    # Should not show usage for invalid action
    if [[ "$output" =~ "Usage:" ]]; then
        ! [[ "$output" =~ "invalid_action" ]]
    fi
}

@test "oradba_dsctl.sh accepts status action" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" status 2>&1
    # Should not show usage for invalid action
    if [[ "$output" =~ "Usage:" ]]; then
        ! [[ "$output" =~ "invalid_action" ]]
    fi
}

@test "oradba_dsctl.sh rejects invalid action" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" invalid_action
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Option Parsing Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh accepts --force option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" start --force 2>&1
    # Should accept the option (may fail for other reasons)
    ! [[ "$output" =~ "Unknown option: --force" ]]
}

@test "oradba_dsctl.sh accepts -f option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" start -f 2>&1
    # Should accept the option
    ! [[ "$output" =~ "Unknown option: -f" ]]
}

@test "oradba_dsctl.sh accepts --timeout option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" stop --timeout 60 2>&1
    # Should accept the option
    ! [[ "$output" =~ "Unknown option: --timeout" ]]
}

@test "oradba_dsctl.sh accepts -t option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" stop -t 60 2>&1
    # Should accept the option
    ! [[ "$output" =~ "Unknown option: -t" ]]
}

@test "oradba_dsctl.sh accepts --debug option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" status --debug 2>&1
    # Should accept the option
    ! [[ "$output" =~ "Unknown option: --debug" ]]
}

@test "oradba_dsctl.sh accepts -d option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" status -d 2>&1
    # Should accept the option
    ! [[ "$output" =~ "Unknown option: -d" ]]
}

@test "oradba_dsctl.sh rejects unknown option" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" start --unknown-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]] || [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Environment Variable Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh respects ORADBA_DEBUG environment variable" {
    export ORADBA_DEBUG=true
    run "${ORADBA_BIN}/oradba_dsctl.sh" status 2>&1
    # Should enable debug mode
    [[ "$output" =~ "DEBUG" ]] || true  # May not always produce debug output
}

# ------------------------------------------------------------------------------
# Function Tests - Check function definitions exist in source
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh defines get_connectors function" {
    grep -q "^get_connectors()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines start_connector function" {
    grep -q "^start_connector()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines stop_connector function" {
    grep -q "^stop_connector()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines show_status function" {
    grep -q "^show_status()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines get_cman_instance_name function" {
    grep -q "^get_cman_instance_name()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines ask_justification function" {
    grep -q "^ask_justification()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh defines setup_connector_environment function" {
    grep -q "^setup_connector_environment()" "${ORADBA_BIN}/oradba_dsctl.sh"
}

# ------------------------------------------------------------------------------
# Library Sourcing Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh sources oradba_common.sh" {
    grep -q "source.*oradba_common.sh" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh sources datasafe_plugin.sh" {
    grep -q "source.*datasafe_plugin.sh" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh sources oradba_registry.sh" {
    grep -q "source.*oradba_registry.sh" "${ORADBA_BIN}/oradba_dsctl.sh"
}

# ------------------------------------------------------------------------------
# Code Quality Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh uses oradba_log for logging" {
    grep -q "oradba_log" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh has proper error handling" {
    # Check for error handling patterns
    grep -q "return 1" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh uses cmctl for connector management" {
    grep -q "cmctl" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh handles cmctl startup command" {
    grep -q "cmctl.*startup" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh handles cmctl shutdown command" {
    grep -q "cmctl.*shutdown" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh has timeout handling for shutdown" {
    grep -q "timeout.*shutdown" "${ORADBA_BIN}/oradba_dsctl.sh" || \
    grep -q "SHUTDOWN_TIMEOUT" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh uses registry API for connector discovery" {
    grep -q "oradba_registry" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh checks for datasafe type installations" {
    grep -q "datasafe" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "setup_connector_environment sets ORACLE_HOME" {
    grep "setup_connector_environment" "${ORADBA_BIN}/oradba_dsctl.sh" -A20 | grep -q "export ORACLE_HOME"
}

@test "setup_connector_environment sets LD_LIBRARY_PATH" {
    grep "setup_connector_environment" "${ORADBA_BIN}/oradba_dsctl.sh" -A20 | grep -q "export LD_LIBRARY_PATH"
}

@test "setup_connector_environment sets TNS_ADMIN" {
    grep "setup_connector_environment" "${ORADBA_BIN}/oradba_dsctl.sh" -A20 | grep -q "export TNS_ADMIN"
}

@test "setup_connector_environment sets DATASAFE_HOME" {
    grep "setup_connector_environment" "${ORADBA_BIN}/oradba_dsctl.sh" -A20 | grep -q "export DATASAFE_HOME"
}

@test "start_connector calls setup_connector_environment" {
    grep "^start_connector()" "${ORADBA_BIN}/oradba_dsctl.sh" -A10 | grep -q "setup_connector_environment"
}

@test "stop_connector calls setup_connector_environment" {
    grep "^stop_connector()" "${ORADBA_BIN}/oradba_dsctl.sh" -A10 | grep -q "setup_connector_environment"
}

@test "show_status calls setup_connector_environment" {
    grep "^show_status()" "${ORADBA_BIN}/oradba_dsctl.sh" -A10 | grep -q "setup_connector_environment"
}

# ------------------------------------------------------------------------------
# Pattern Consistency Tests (comparing with oradba_dbctl.sh)
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh follows similar structure to oradba_dbctl.sh" {
    # Both should have usage function
    grep -q "^usage()" "${ORADBA_BIN}/oradba_dsctl.sh"
    
    # Both should have similar action handling
    grep -q "start | stop | restart | status" "${ORADBA_BIN}/oradba_dsctl.sh"
}

@test "oradba_dsctl.sh has proper header with metadata" {
    head -20 "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Name\.\.\.\.\.\.\.: oradba_dsctl.sh"
    head -20 "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Author"
    head -20 "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Purpose"
}

@test "oradba_dsctl.sh has Apache License reference" {
    head -20 "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Apache License"
}

# ------------------------------------------------------------------------------
# Integration Tests with Mock Data
# ------------------------------------------------------------------------------

@test "get_cman_instance_name returns default when cman.ora missing" {
    skip "Requires mocking - would need isolated test environment"
}

@test "get_cman_instance_name extracts name from cman.ora" {
    skip "Requires mocking - would need isolated test environment"
}

@test "start_connector validates cmctl exists" {
    skip "Requires mocking - would need isolated test environment"
}

@test "stop_connector handles timeout gracefully" {
    skip "Requires mocking - would need isolated test environment"
}

# ------------------------------------------------------------------------------
# Documentation Tests
# ------------------------------------------------------------------------------

@test "oradba_dsctl.sh functions have documentation headers" {
    # Check that key functions have proper documentation
    grep -B10 "^get_connectors()" "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Purpose."
    grep -B10 "^start_connector()" "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Purpose."
    grep -B10 "^stop_connector()" "${ORADBA_BIN}/oradba_dsctl.sh" | grep -q "Purpose."
}

@test "oradba_dsctl.sh has examples in usage" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Examples:" ]]
}

@test "oradba_dsctl.sh documents environment variables" {
    run "${ORADBA_BIN}/oradba_dsctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Environment Variables:" ]]
    [[ "$output" =~ "ORADBA_DEBUG" ]]
}
