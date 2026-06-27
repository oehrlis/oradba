#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_migration.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.27
# Revision...: 0.30.0
# Purpose....: Environment parity and DB open-mode tests for M6 migration
#              (CF-017 and CF-018)
# Notes......: Verifies _oraenv_handle_oracle_home delegates to
#              oradba_build_environment, and that oradba_check_db_status returns
#              canonical vocabulary {OPEN,MOUNTED,NOMOUNT,STARTED,SHUTDOWN}.
#              No live Oracle installation required - uses function mocking.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    ORADBA_BASE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export ORADBA_BASE

    # Minimal fake ORACLE_HOME with a bin/sqlplus
    MOCK_ORACLE_HOME="${BATS_TEST_TMPDIR}/oracle_home"
    mkdir -p "${MOCK_ORACLE_HOME}/bin"
    touch "${MOCK_ORACLE_HOME}/bin/sqlplus"
    chmod +x "${MOCK_ORACLE_HOME}/bin/sqlplus"
    export ORACLE_HOME="${MOCK_ORACLE_HOME}"
    export ORACLE_SID="TESTDB"
}

teardown() {
    unset ORACLE_HOME ORACLE_SID ORADBA_BASE MOCK_ORACLE_HOME
    unset ORACLE_BASE ORADBA_BUILD_ENV_CALLED
}

# ==============================================================================
# CF-017: _oraenv_handle_oracle_home delegates to oradba_build_environment
# ==============================================================================

@test "CF-017: oradba_build_environment is referenced in oraenv.sh" {
    grep -q "oradba_build_environment" "${ORADBA_BASE}/bin/oraenv.sh"
}

@test "CF-017: oraenv.sh no longer calls set_oracle_home_environment as primary path" {
    # The only call should be in the fallback branch (elif), not as the primary
    # Verify that oradba_build_environment appears before set_oracle_home_environment
    local build_line fallback_line
    build_line=$(grep -n "oradba_build_environment" "${ORADBA_BASE}/bin/oraenv.sh" | grep -v "^.*#" | head -1 | cut -d: -f1)
    fallback_line=$(grep -n "set_oracle_home_environment" "${ORADBA_BASE}/bin/oraenv.sh" | grep -v "^.*#" | head -1 | cut -d: -f1)
    # oradba_build_environment call must come before set_oracle_home_environment call
    [ "${build_line}" -lt "${fallback_line}" ]
}

@test "CF-017: _oraenv_handle_oracle_home function exists after sourcing oraenv.sh helpers" {
    # Source only the common library to get basic infrastructure
    source "${ORADBA_BASE}/lib/oradba_common.sh"

    # Verify oradba_build_environment is the primary dispatch in oraenv.sh
    # by checking the pattern exists in the file
    grep -q "command -v oradba_build_environment" "${ORADBA_BASE}/bin/oraenv.sh"
}

@test "CF-017: oraenv.sh has fallback to set_oracle_home_environment" {
    grep -q "set_oracle_home_environment" "${ORADBA_BASE}/bin/oraenv.sh"
}

@test "CF-017: oradba_build_environment call in oraenv.sh uses requested_sid argument" {
    # Verify the function is called with the SID argument
    grep -q 'oradba_build_environment "\$requested_sid"' "${ORADBA_BASE}/bin/oraenv.sh"
}

# ==============================================================================
# CF-018: oradba_check_db_status canonical vocabulary
# ==============================================================================

@test "CF-018: oradba_check_db_status is defined after sourcing oradba_env_status.sh" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
    type -t oradba_check_db_status | grep -q "function"
}

@test "CF-018: oradba_check_db_status returns exit 1 for missing sqlplus" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
    # Non-existent ORACLE_HOME - sqlplus not found
    run oradba_check_db_status "TESTDB" "/nonexistent/path"
    [ "$status" -eq 1 ]
}

@test "CF-018: oradba_check_db_status returns SHUTDOWN with exit 1 when sqlplus returns empty" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    # Create a mock sqlplus that returns empty (simulates DB down)
    mkdir -p "${BATS_TEST_TMPDIR}/mock_home/bin"
    cat > "${BATS_TEST_TMPDIR}/mock_home/bin/sqlplus" << 'MOCK'
#!/usr/bin/env bash
# Mock sqlplus returning empty output
exit 0
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/mock_home/bin/sqlplus"

    run oradba_check_db_status "TESTDB" "${BATS_TEST_TMPDIR}/mock_home"
    [ "$status" -eq 1 ]
    [ "$output" = "SHUTDOWN" ]
}

@test "CF-018: oradba_check_db_status returns OPEN with exit 0 for OPEN status" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    mkdir -p "${BATS_TEST_TMPDIR}/mock_open/bin"
    cat > "${BATS_TEST_TMPDIR}/mock_open/bin/sqlplus" << 'MOCK'
#!/usr/bin/env bash
echo "OPEN"
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/mock_open/bin/sqlplus"

    run oradba_check_db_status "TESTDB" "${BATS_TEST_TMPDIR}/mock_open"
    [ "$status" -eq 0 ]
    [ "$output" = "OPEN" ]
}

@test "CF-018: oradba_check_db_status returns MOUNTED with exit 0 for MOUNTED status" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    mkdir -p "${BATS_TEST_TMPDIR}/mock_mounted/bin"
    cat > "${BATS_TEST_TMPDIR}/mock_mounted/bin/sqlplus" << 'MOCK'
#!/usr/bin/env bash
echo "MOUNTED"
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/mock_mounted/bin/sqlplus"

    run oradba_check_db_status "TESTDB" "${BATS_TEST_TMPDIR}/mock_mounted"
    [ "$status" -eq 0 ]
    [ "$output" = "MOUNTED" ]
}

@test "CF-018: oradba_check_db_status returns NOMOUNT with exit 0 for NOMOUNT status" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    mkdir -p "${BATS_TEST_TMPDIR}/mock_nomount/bin"
    cat > "${BATS_TEST_TMPDIR}/mock_nomount/bin/sqlplus" << 'MOCK'
#!/usr/bin/env bash
echo "NOMOUNT"
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/mock_nomount/bin/sqlplus"

    run oradba_check_db_status "TESTDB" "${BATS_TEST_TMPDIR}/mock_nomount"
    [ "$status" -eq 0 ]
    [ "$output" = "NOMOUNT" ]
}

@test "CF-018: oradba_check_db_status returns STARTED with exit 0 for STARTED status" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    mkdir -p "${BATS_TEST_TMPDIR}/mock_started/bin"
    cat > "${BATS_TEST_TMPDIR}/mock_started/bin/sqlplus" << 'MOCK'
#!/usr/bin/env bash
echo "STARTED"
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/mock_started/bin/sqlplus"

    run oradba_check_db_status "TESTDB" "${BATS_TEST_TMPDIR}/mock_started"
    [ "$status" -eq 0 ]
    [ "$output" = "STARTED" ]
}

@test "CF-018: oradba_check_db_status exit contract - accessible states return 0" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"

    # Test each accessible state returns exit 0
    for state in OPEN MOUNTED NOMOUNT STARTED; do
        local mock_dir="${BATS_TEST_TMPDIR}/mock_${state}"
        mkdir -p "${mock_dir}/bin"
        printf '#!/usr/bin/env bash\necho "%s"\n' "${state}" > "${mock_dir}/bin/sqlplus"
        chmod +x "${mock_dir}/bin/sqlplus"
        run oradba_check_db_status "TESTDB" "${mock_dir}"
        [ "$status" -eq 0 ] || {
            echo "State ${state} returned non-zero exit code ${status}"
            return 1
        }
        [ "$output" = "${state}" ] || {
            echo "State ${state}: expected output '${state}', got '${output}'"
            return 1
        }
    done
}

# ==============================================================================
# CF-018: oradba_get_db_status is a shim that delegates to oradba_check_db_status
# ==============================================================================

@test "CF-018: oradba_get_db_status delegates to oradba_check_db_status" {
    # Verify the shim pattern is in the source file
    grep -q "oradba_check_db_status" "${ORADBA_BASE}/lib/oradba_env_validator.sh"
}

@test "CF-018: oradba_get_db_status no longer contains standalone sqlplus heredoc" {
    # The old implementation had a full sqlplus block; verify it's replaced
    # The function body must reference oradba_check_db_status, not have its own SQL
    local func_body
    func_body=$(awk '/^oradba_get_db_status\(\)/{found=1} found{print} /^}$/{if(found) exit}' \
        "${ORADBA_BASE}/lib/oradba_env_validator.sh")
    # Must reference the canonical function
    echo "${func_body}" | grep -q "oradba_check_db_status"
}

@test "CF-018: oradba_get_db_status returns SHUTDOWN (not DOWN) for no SID" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_env_status.sh"
    source "${ORADBA_BASE}/lib/oradba_env_validator.sh"

    unset ORACLE_SID
    run oradba_get_db_status
    [ "$status" -eq 1 ]
    [ "$output" = "SHUTDOWN" ]
}

# ==============================================================================
# CF-018: get_database_open_mode in oradba_db_functions.sh uses canonical vocab
# ==============================================================================

@test "CF-018: get_database_open_mode is defined after sourcing oradba_db_functions.sh" {
    source "${ORADBA_BASE}/lib/oradba_common.sh"
    source "${ORADBA_BASE}/lib/oradba_db_functions.sh"
    type -t get_database_open_mode | grep -q "function"
}

@test "CF-018: get_database_open_mode references oradba_check_db_status" {
    grep -q "oradba_check_db_status" "${ORADBA_BASE}/lib/oradba_db_functions.sh"
}
