#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_env_validator.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.26
# Revision...: 0.27.0
# Purpose....: Behavioral tests for oradba_env_validator.sh (CF-008)
# Notes......: Covers oracle-home/SID validation, binary checks, DB status and
#              version detection, and full environment validation. Uses a mock
#              ORACLE_HOME in BATS_TEST_TMPDIR; no real Oracle install required.
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

    # Source the validator under test
    source "${ORADBA_BASE}/lib/oradba_env_validator.sh"
}

teardown() {
    unset ORACLE_HOME ORACLE_SID ORADBA_VALIDATOR_LOGGER ORADBA_PRODUCT_TYPE
}

# ------------------------------------------------------------------------------
# oradba_validate_oracle_home
# ------------------------------------------------------------------------------

@test "validate_oracle_home accepts a valid existing home" {
    run oradba_validate_oracle_home "${MOCK_ORACLE_HOME}"
    [ "$status" -eq 0 ]
}

@test "validate_oracle_home uses ORACLE_HOME env var when no arg given" {
    run oradba_validate_oracle_home
    [ "$status" -eq 0 ]
}

@test "validate_oracle_home rejects a non-existent path" {
    run oradba_validate_oracle_home "${BATS_TEST_TMPDIR}/does_not_exist"
    [ "$status" -eq 1 ]
}

@test "validate_oracle_home rejects empty path" {
    run oradba_validate_oracle_home ""
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# oradba_validate_sid
# ------------------------------------------------------------------------------

@test "validate_sid accepts a normal SID" {
    run oradba_validate_sid "ORCL"
    [ "$status" -eq 0 ]
}

@test "validate_sid accepts an ASM instance name" {
    run oradba_validate_sid "+ASM1"
    [ "$status" -eq 0 ]
}

@test "validate_sid rejects an empty SID" {
    run oradba_validate_sid ""
    [ "$status" -eq 1 ]
}

@test "validate_sid rejects a SID starting with a digit" {
    run oradba_validate_sid "9DB"
    [ "$status" -eq 1 ]
}

@test "validate_sid rejects a SID with an embedded space" {
    run oradba_validate_sid "MY DB"
    [ "$status" -eq 1 ]
}

@test "validate_sid rejects a SID with invalid characters" {
    run oradba_validate_sid "DB@HOST"
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# oradba_check_oracle_binaries
# ------------------------------------------------------------------------------

@test "check_oracle_binaries succeeds when required binary is on PATH" {
    # Provide a fake sqlplus on PATH so the RDBMS fallback check passes
    local fakebin="${BATS_TEST_TMPDIR}/fakebin"
    mkdir -p "${fakebin}"
    for b in sqlplus tnsping lsnrctl; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "${fakebin}/${b}"
        chmod +x "${fakebin}/${b}"
    done
    PATH="${fakebin}:${PATH}" run oradba_check_oracle_binaries "RDBMS"
    [ "$status" -eq 0 ]
}

@test "check_oracle_binaries fails when required binaries are missing from PATH" {
    # Restrict PATH so no oracle binaries are found; bash/coreutils still needed
    run env PATH="/usr/bin:/bin" bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_validator.sh'
        oradba_check_oracle_binaries 'GRID'
    "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

# ------------------------------------------------------------------------------
# oradba_check_db_running
# ------------------------------------------------------------------------------

@test "check_db_running returns non-zero for a non-running SID" {
    run oradba_check_db_running "NONEXISTENTSID12345"
    [ "$status" -eq 1 ]
}

@test "check_db_running fails when no SID is provided or set" {
    run env -u ORACLE_SID bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_validator.sh'
        oradba_check_db_running
    "
    [ "$status" -eq 1 ]
}

# ------------------------------------------------------------------------------
# oradba_get_db_status
# ------------------------------------------------------------------------------

@test "get_db_status reports DOWN when SID is unset" {
    run env -u ORACLE_SID bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_validator.sh'
        oradba_get_db_status
    "
    [ "$status" -eq 1 ]
    [[ "$output" == "SHUTDOWN" ]]
}

@test "get_db_status reports DOWN when database process is not running" {
    export ORACLE_SID="NONEXISTENTSID12345"
    run oradba_get_db_status
    [ "$status" -eq 1 ]
    [[ "$output" =~ DOWN ]]
}

# ------------------------------------------------------------------------------
# oradba_get_db_version
# ------------------------------------------------------------------------------

@test "get_db_version fails when sqlplus is not on PATH" {
    run env PATH="/usr/bin:/bin" bash -c "
        source '${ORADBA_BASE}/lib/oradba_env_validator.sh'
        oradba_get_db_version
    "
    [ "$status" -eq 1 ]
}

@test "get_db_version parses the version reported by a fake sqlplus" {
    local fakebin="${BATS_TEST_TMPDIR}/fakebin_ver"
    mkdir -p "${fakebin}"
    cat > "${fakebin}/sqlplus" <<'EOF'
#!/usr/bin/env bash
echo "SQL*Plus: Release 19.21.0.0.0 - Production"
EOF
    chmod +x "${fakebin}/sqlplus"
    PATH="${fakebin}:${PATH}" run oradba_get_db_version
    [ "$status" -eq 0 ]
    [[ "$output" == "19.21.0.0.0" ]]
}

# ------------------------------------------------------------------------------
# oradba_validate_environment
# ------------------------------------------------------------------------------

@test "validate_environment fails when ORACLE_HOME is invalid" {
    export ORACLE_HOME="${BATS_TEST_TMPDIR}/missing_home"
    export ORADBA_PRODUCT_TYPE="RDBMS"
    run oradba_validate_environment "basic"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ORACLE_HOME is not valid" ]]
}

@test "validate_environment basic level reports valid ORACLE_HOME" {
    export ORADBA_PRODUCT_TYPE="RDBMS"
    run oradba_validate_environment "basic"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ORACLE_HOME is valid" ]]
}

@test "validate_environment does minimal validation for non-database product" {
    export ORADBA_PRODUCT_TYPE="JAVA"
    run oradba_validate_environment "basic"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Basic Validation" ]]
}
