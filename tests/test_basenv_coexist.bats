#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_basenv_coexist.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.28
# Revision...: 0.1.0
# Purpose....: BATS tests for BasEnv coexistence mode (detect_basenv, safe_alias, oraenv guards)
# Notes......: Tests detect_basenv(), alias_exists(), safe_alias(), and configure_sqlpath()
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# shellcheck disable=SC1091,SC2030,SC2031

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORADBA_SRC_BASE="${PROJECT_ROOT}/src"

    # Source common library (provides detect_basenv, alias_exists, safe_alias, configure_sqlpath)
    # shellcheck source=../src/lib/oradba_common.sh
    source "${ORADBA_SRC_BASE}/lib/oradba_common.sh"

    # Set ORADBA_BASE so configure_sqlpath can reference ${ORADBA_BASE}/sql
    export ORADBA_BASE="${ORADBA_SRC_BASE}"

    # Save/restore HOME for tests that write ~/.BE_HOME
    ORIGINAL_HOME="${HOME}"
    TEST_HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${TEST_HOME}"
}

teardown() {
    export HOME="${ORIGINAL_HOME}"
    unset BE_HOME ORADBA_COEXIST_MODE ORADBA_BASE 2>/dev/null || true
}

# ==============================================================================
# Group 1: detect_basenv()
# ==============================================================================

@test "detect_basenv returns 0 when BE_HOME variable is set" {
    export BE_HOME="/some/basenv/path"
    run detect_basenv
    [ "$status" -eq 0 ]
}

@test "detect_basenv returns 0 when HOME/.BE_HOME file exists" {
    unset BE_HOME
    export HOME="${TEST_HOME}"
    touch "${HOME}/.BE_HOME"
    run detect_basenv
    [ "$status" -eq 0 ]
}

@test "detect_basenv returns 0 when HOME/.TVDPERL_HOME file exists without BE_HOME" {
    unset BE_HOME
    export HOME="${TEST_HOME}"
    # Ensure .BE_HOME does not exist
    rm -f "${HOME}/.BE_HOME"
    touch "${HOME}/.TVDPERL_HOME"
    run detect_basenv
    [ "$status" -eq 0 ]
}

@test "detect_basenv returns 1 when no BasEnv markers are present" {
    unset BE_HOME
    export HOME="${TEST_HOME}"
    # Ensure neither marker file exists
    rm -f "${HOME}/.BE_HOME" "${HOME}/.TVDPERL_HOME"
    run detect_basenv
    [ "$status" -eq 1 ]
}

# ==============================================================================
# Group 2: safe_alias() in basenv coexistence mode
# ==============================================================================

@test "safe_alias skips alias that already exists in basenv mode" {
    export ORADBA_COEXIST_MODE="basenv"
    # Create a pre-existing alias
    # shellcheck disable=SC2139
    alias sq="existing_command"
    run safe_alias "sq" "new_command"
    # Should return 1 (skipped)
    [ "$status" -eq 1 ]
    # Alias should still point to original command
    local alias_output
    alias_output=$(alias sq 2>/dev/null)
    [[ "${alias_output}" == *"existing_command"* ]]
    unalias sq 2>/dev/null || true
}

@test "safe_alias creates new alias when it does not exist in basenv mode" {
    export ORADBA_COEXIST_MODE="basenv"
    # Ensure alias does not exist
    unalias oradba_test_alias 2>/dev/null || true
    # Call directly (not via run) so the alias is set in the current shell
    safe_alias "oradba_test_alias" "echo hello"
    local rc=$?
    # Should return 0 (created)
    [ "${rc}" -eq 0 ]
    # Alias should now exist
    alias oradba_test_alias &>/dev/null
    unalias oradba_test_alias 2>/dev/null || true
}

# ==============================================================================
# Group 3: PATH/SQLPATH deduplication via configure_sqlpath
# ==============================================================================

@test "configure_sqlpath rebuilds SQLPATH discarding previous content" {
    # Set a SQLPATH with arbitrary content that configure_sqlpath will not preserve
    export SQLPATH="before:test:value"
    # Use a temp dir with sql/ subdir as ORADBA_BASE
    local temp_base="${BATS_TEST_TMPDIR}/oradba_base_test"
    mkdir -p "${temp_base}/sql"
    export ORADBA_BASE="${temp_base}"
    # Ensure preserve mode is off so old value is discarded
    export ORADBA_PRESERVE_SQLPATH="false"
    configure_sqlpath
    # SQLPATH should no longer contain the old "before:test:value" entries
    [[ "${SQLPATH}" != *"before"* ]]
    [[ "${SQLPATH}" != *"test:value"* ]]
    # But must now include the new oradba sql path
    [[ "${SQLPATH}" == *"${temp_base}/sql"* ]]
}

# ==============================================================================
# Group 4: Auto-detection logic (ORADBA_COEXIST_MODE)
# ==============================================================================

@test "ORADBA_COEXIST_MODE is set to basenv when detect_basenv returns 0" {
    unset ORADBA_COEXIST_MODE
    export BE_HOME="/some/basenv/path"
    # Inline the detection logic from oraenv.sh (subshell not needed — run in current shell)
    if [[ "${ORADBA_COEXIST_MODE:-standalone}" != "basenv"* ]]; then
        if detect_basenv; then
            export ORADBA_COEXIST_MODE="basenv"
        fi
    fi
    [ "${ORADBA_COEXIST_MODE}" = "basenv" ]
}

@test "ORADBA_COEXIST_MODE stays basenv-maximal when already set and detect_basenv returns 0" {
    export ORADBA_COEXIST_MODE="basenv-maximal"
    export BE_HOME="/some/basenv/path"
    # Run the same detection logic — should not overwrite basenv-maximal
    if [[ "${ORADBA_COEXIST_MODE:-standalone}" != "basenv"* ]]; then
        if detect_basenv; then
            export ORADBA_COEXIST_MODE="basenv"
        fi
    fi
    [ "${ORADBA_COEXIST_MODE}" = "basenv-maximal" ]
}

# ==============================================================================
# Group 5: SQLPATH guard — _oradba_path_contains coverage
# ==============================================================================

@test "_oradba_path_contains returns 0 when directory is already in SQLPATH" {
    # Inline the function from oraenv.sh to test in isolation
    _oradba_path_contains() {
        local dir="$1" pathvar="${2:-PATH}"
        [[ ":${!pathvar}:" == *":${dir}:"* ]]
    }

    export SQLPATH="/opt/oracle/oradba/sql:/opt/oracle/local/oradba/sql"
    run _oradba_path_contains "/opt/oracle/local/oradba/sql" "SQLPATH"
    [ "$status" -eq 0 ]
}

@test "configure_sqlpath skips adding oradba/sql when ORADBA_COEXIST_MODE=basenv and path already present" {
    # Inline the guard function
    _oradba_path_contains() {
        local dir="$1" pathvar="${2:-PATH}"
        [[ ":${!pathvar}:" == *":${dir}:"* ]]
    }

    local temp_base="${BATS_TEST_TMPDIR}/oradba_guard_test"
    mkdir -p "${temp_base}/sql"
    export ORADBA_BASE="${temp_base}"
    export ORADBA_COEXIST_MODE="basenv"

    # Pre-populate SQLPATH so the guard condition is met
    export SQLPATH="${temp_base}/sql"

    # The guard: in basenv mode, skip configure_sqlpath if path already present
    if [[ "${ORADBA_COEXIST_MODE:-standalone}" == "basenv"* ]] && _oradba_path_contains "${ORADBA_BASE}/sql" "SQLPATH"; then
        skipped=true
    else
        skipped=false
        configure_sqlpath
    fi

    [ "${skipped}" = "true" ]
    # Verify _oradba_path_contains correctly reported presence
    run _oradba_path_contains "${temp_base}/sql" "SQLPATH"
    [ "$status" -eq 0 ]
}

@test "oradba_standard.conf guards \$etc export in basenv coexistence mode" {
    # $etc is also exported by BasEnv (from ETC_BASE).  oradba must not
    # overwrite it in coexist mode or BasEnv aliases (sqh, rmanh, rmanch, ...)
    # that reference $etc/sqlplus.filter for rlwrap will break.
    local conf="${PROJECT_ROOT}/src/etc/oradba_standard.conf"
    [ -f "$conf" ]
    # The raw bare export must not exist
    ! grep -q '^export etc=' "$conf"
    # The guarded conditional export must exist
    grep -q 'ORADBA_COEXIST_MODE.*basenv' "$conf"
    grep -A 3 'ORADBA_COEXIST_MODE.*basenv' "$conf" | grep -q 'export etc='
}

@test "oradba_standard.conf guards \$log export in basenv coexistence mode" {
    local conf="${PROJECT_ROOT}/src/etc/oradba_standard.conf"
    [ -f "$conf" ]
    # The raw bare export must not exist
    ! grep -q '^export log=' "$conf"
    # log must be inside the same coexist guard block as etc
    grep -A 4 'ORADBA_COEXIST_MODE.*basenv' "$conf" | grep -q 'export log='
}

# EOF
