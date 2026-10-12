#!/usr/bin/env bats
# shellcheck disable=SC1090,SC2016
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_errexit_rc_capture.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.10.12
# Purpose....: Regression tests for exit code capture under set -euo pipefail
#              and for indirect expansion under set -u
# Notes......: Under set -e, "cmd" on one line and "local rc=$?" on the next
#              exits before rc is assigned - unless the function is called
#              inside an if. All current callers are, so the error handling
#              worked by accident. These tests call the real functions outside
#              a conditional with set -e active.
# Usage......: bats test_errexit_rc_capture.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    BIN_DIR="${PROJECT_ROOT}/src/bin"
}

# ------------------------------------------------------------------------------
# Function: function_body
# Purpose.: Print a function definition from a script
# Args....: $1 - script path, $2 - function name
# Output..: The function from its header line to the closing brace
# ------------------------------------------------------------------------------
function_body() {
    sed -n "/^${2}() {/,/^}/p" "$1"
}

@test "no 'local rc=\$?' after a command in the control scripts" {
    run grep -n 'local rc=\$?' \
        "${BIN_DIR}/oradba_services_root.sh" "${BIN_DIR}/oradba_dbctl.sh" \
        "${BIN_DIR}/oradba_dsctl.sh" "${BIN_DIR}/oradba_services.sh"
    [ "$status" -eq 1 ]
}

@test "run_as_oracle reaches its error handling outside a conditional under set -e" {
    # With the old "cmd; local rc=\$?" shape set -e ended the script at the su
    # line: same exit code, but the ERROR line was never logged.
    local script="${BATS_TEST_TMPDIR}/run_as_oracle.sh"
    {
        echo 'set -euo pipefail'
        echo 'ORACLE_USER=oracle SERVICES_SCRIPT=/bin/true'
        echo 'oradba_log() { echo "$1 $2"; }'
        echo 'su() { return 3; }'
        function_body "${BIN_DIR}/oradba_services_root.sh" run_as_oracle
        echo 'run_as_oracle start'
    } > "$script"
    run bash "$script"
    [ "$status" -eq 3 ]
    [[ "$output" == *"ERROR Command failed with exit code 3"* ]]
}

@test "_oradba_path_contains handles an unset variable under set -u" {
    local script="${BATS_TEST_TMPDIR}/path_contains.sh"
    {
        echo 'set -euo pipefail'
        echo 'unset SQLPATH'
        function_body "${BIN_DIR}/oraenv.sh" _oradba_path_contains
        echo 'if _oradba_path_contains /opt/x SQLPATH; then echo found; else echo absent; fi'
        echo 'SQLPATH=/a:/opt/x:/b'
        echo 'if _oradba_path_contains /opt/x SQLPATH; then echo found; else echo absent; fi'
    } > "$script"
    run bash "$script"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "absent" ]
    [ "${lines[1]}" = "found" ]
}
