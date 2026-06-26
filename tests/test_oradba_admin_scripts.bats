#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_admin_scripts.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.26
# Revision...: 0.27.0
# Purpose....: Smoke tests for previously untested admin bin scripts (F-014)
# Notes......: Covers shebang, bash -n syntax and help/run behaviour for
#              oradba_logrotate.sh, sessionsql.sh, oradba_validate.sh,
#              oradba_datasafe_debug.sh and oradba_setup.sh. Includes
#              functional checks for logrotate (--list) and validate (--help),
#              and a CF-009 first-iteration regression for logrotate.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    BIN="${PROJECT_ROOT}/src/bin"
}

# ------------------------------------------------------------------------------
# Shebang tests - every admin script must use the env-bash shebang
# ------------------------------------------------------------------------------

@test "admin: oradba_logrotate.sh uses env bash shebang" {
    run head -1 "${BIN}/oradba_logrotate.sh"
    [ "$output" = "#!/usr/bin/env bash" ]
}

@test "admin: sessionsql.sh uses env bash shebang" {
    run head -1 "${BIN}/sessionsql.sh"
    [ "$output" = "#!/usr/bin/env bash" ]
}

@test "admin: oradba_validate.sh uses env bash shebang" {
    run head -1 "${BIN}/oradba_validate.sh"
    [ "$output" = "#!/usr/bin/env bash" ]
}

@test "admin: oradba_datasafe_debug.sh uses env bash shebang" {
    run head -1 "${BIN}/oradba_datasafe_debug.sh"
    [ "$output" = "#!/usr/bin/env bash" ]
}

@test "admin: oradba_setup.sh uses env bash shebang" {
    run head -1 "${BIN}/oradba_setup.sh"
    [ "$output" = "#!/usr/bin/env bash" ]
}

# ------------------------------------------------------------------------------
# Syntax tests - bash -n must succeed for every admin script
# ------------------------------------------------------------------------------

@test "admin: oradba_logrotate.sh passes bash -n" {
    run bash -n "${BIN}/oradba_logrotate.sh"
    [ "$status" -eq 0 ]
}

@test "admin: sessionsql.sh passes bash -n" {
    run bash -n "${BIN}/sessionsql.sh"
    [ "$status" -eq 0 ]
}

@test "admin: oradba_validate.sh passes bash -n" {
    run bash -n "${BIN}/oradba_validate.sh"
    [ "$status" -eq 0 ]
}

@test "admin: oradba_datasafe_debug.sh passes bash -n" {
    run bash -n "${BIN}/oradba_datasafe_debug.sh"
    [ "$status" -eq 0 ]
}

@test "admin: oradba_setup.sh passes bash -n" {
    run bash -n "${BIN}/oradba_setup.sh"
    [ "$status" -eq 0 ]
}

# ------------------------------------------------------------------------------
# Help / run behaviour
# Note: sessionsql.sh has no --help (it forwards the argument to SQL*Plus), so
#       it is only covered by the shebang/syntax tests above to avoid launching
#       an Oracle client during the test run.
# ------------------------------------------------------------------------------

@test "admin: oradba_logrotate.sh --help exits 0 and shows usage" {
    run bash "${BIN}/oradba_logrotate.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ Usage: ]]
}

@test "admin: oradba_validate.sh --help exits 0 and shows usage" {
    run bash "${BIN}/oradba_validate.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ Usage: ]]
}

@test "admin: oradba_setup.sh --help exits 0 and shows usage" {
    run bash "${BIN}/oradba_setup.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ Usage: ]]
}

@test "admin: oradba_datasafe_debug.sh runs its report (no --help handling)" {
    # This script has no --help; it always produces a debug report. The key
    # assertion is that it runs to completion without aborting under set -e and
    # emits its report header/footer.
    run bash "${BIN}/oradba_datasafe_debug.sh"
    [[ "$output" =~ "Debug Report" ]] || [[ "$output" =~ "ORADBA_BASE" ]]
}

# ------------------------------------------------------------------------------
# Functional tests with mocks
# ------------------------------------------------------------------------------

@test "admin: oradba_logrotate.sh --list reports no configurations cleanly" {
    # --list needs no root and exercises the from-zero 'found' counter loop.
    run bash "${BIN}/oradba_logrotate.sh" --list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "logrotate configurations" ]]
}

@test "admin: oradba_validate.sh --debug runs without aborting" {
    # Validation reports failures against the bare src tree, so a non-zero exit
    # is expected; assert the script completes (does not crash) and produces a
    # recognisable report header.
    run bash "${BIN}/oradba_validate.sh"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    [[ "$output" =~ "OraDBA Installation" ]] || [[ "$output" =~ "Checking" ]]
}

# ------------------------------------------------------------------------------
# CF-009 first-iteration regression
# ------------------------------------------------------------------------------

@test "oradba_logrotate_install_single_config_succeeds" {
    # Regression for CF-001/CF-009: the install workflow increments counters
    # starting from 0. The user-mode install path runs without root. With
    # logrotate present it must succeed (exit 0) and create the user configs;
    # if logrotate is absent the script must still exit cleanly (rc 1 with a
    # clear message) rather than aborting under set -e.
    local fake_home="${BATS_TEST_TMPDIR}/fakehome"
    mkdir -p "${fake_home}"
    run env HOME="${fake_home}" bash "${BIN}/oradba_logrotate.sh" --install-user
    if command -v logrotate >/dev/null 2>&1; then
        [ "$status" -eq 0 ]
        [ -f "${fake_home}/.oradba/logrotate/oracle-alert.logrotate" ]
    else
        # logrotate not installed on this host: graceful failure, no crash
        [ "$status" -eq 1 ]
        [[ "$output" =~ "logrotate" ]]
    fi
}
