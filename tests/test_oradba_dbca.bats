#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_dbca.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 1.0.0
# Purpose....: BATS tests for oradba_dbca.sh script
# Notes......: Tests argument parsing, template discovery, and variable substitution.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Get the directory containing the test script
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORADBA_SRC_BASE="${PROJECT_ROOT}/src"
    
    # Source the common library
    source "${ORADBA_SRC_BASE}/lib/oradba_common.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="$(mktemp -d)"
    
    # Set test variables
    export ORADBA_BASE="${ORADBA_SRC_BASE}"
    export ORACLE_HOME="${TEST_TEMP_DIR}/oracle_home"
    export ORACLE_BASE="${TEST_TEMP_DIR}/oracle_base"
    
    # Create mock Oracle directories
    mkdir -p "${ORACLE_HOME}/bin"
    mkdir -p "${ORACLE_BASE}/oradata"
    
    # Script path
    DBCA_SCRIPT="${ORADBA_SRC_BASE}/bin/oradba_dbca.sh"
}

# Cleanup test environment
teardown() {
    # Remove temporary test directory
    if [[ -d "${TEST_TEMP_DIR}" ]]; then
        rm -rf "${TEST_TEMP_DIR}"
    fi
}

# ------------------------------------------------------------------------------
# Test: Script exists and is executable
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh exists and is executable" {
    [[ -f "${DBCA_SCRIPT}" ]]
    [[ -x "${DBCA_SCRIPT}" ]]
}

# ------------------------------------------------------------------------------
# Test: Display help message
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh displays help message" {
    run "${DBCA_SCRIPT}" --help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" =~ "Usage:" ]]
    [[ "${output}" =~ "Create Oracle database using DBCA response file templates" ]]
}

# ------------------------------------------------------------------------------
# Test: Show templates lists available templates
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh --show-templates lists templates" {
    run "${DBCA_SCRIPT}" --show-templates
    [[ "${status}" -eq 0 ]]
    [[ "${output}" =~ "Available DBCA Templates:" ]]
    [[ "${output}" =~ "Oracle 19c:" ]]
    [[ "${output}" =~ "Oracle 26ai:" ]]
    [[ "${output}" =~ "general" ]]
    [[ "${output}" =~ "container" ]]
    [[ "${output}" =~ "dev" ]]
}

# ------------------------------------------------------------------------------
# Test: Templates directory exists
# ------------------------------------------------------------------------------
@test "DBCA templates directory exists" {
    [[ -d "${PROJECT_ROOT}/src/templates/dbca" ]]
    [[ -d "${PROJECT_ROOT}/src/templates/dbca/19c" ]]
    [[ -d "${PROJECT_ROOT}/src/templates/dbca/26ai" ]]
    [[ -d "${PROJECT_ROOT}/src/templates/dbca/common" ]]
    [[ -d "${PROJECT_ROOT}/src/templates/dbca/custom" ]]
}

# ------------------------------------------------------------------------------
# Test: 19c templates exist
# ------------------------------------------------------------------------------
@test "All 19c templates exist" {
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_general.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_container.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_pluggable.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_dev.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_rac.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_dataguard.rsp" ]]
}

# ------------------------------------------------------------------------------
# Test: 26ai templates exist
# ------------------------------------------------------------------------------
@test "All 26ai templates exist" {
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/26ai/dbca_26ai_general.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/26ai/dbca_26ai_container.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/26ai/dbca_26ai_pluggable.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/26ai/dbca_26ai_dev.rsp" ]]
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/26ai/dbca_26ai_free.rsp" ]]
}

# ------------------------------------------------------------------------------
# Test: Templates contain required variables
# ------------------------------------------------------------------------------
@test "Templates contain required variable placeholders" {
    local template="${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_general.rsp"
    
    grep -q "{{ORACLE_SID}}" "${template}"
    grep -q "{{ORACLE_HOME}}" "${template}"
    grep -q "{{ORACLE_BASE}}" "${template}"
    grep -q "{{DATA_DIR}}" "${template}"
    grep -q "{{FRA_DIR}}" "${template}"
    grep -q "{{SYS_PASSWORD}}" "${template}"
    grep -q "{{SYSTEM_PASSWORD}}" "${template}"
}

# ------------------------------------------------------------------------------
# Test: Templates are valid response files
# ------------------------------------------------------------------------------
@test "Templates have valid DBCA response file format" {
    local template="${PROJECT_ROOT}/src/templates/dbca/19c/dbca_19c_general.rsp"
    
    # Check for required sections
    grep -q "\[GENERAL\]" "${template}"
    grep -q "\[CREATEDATABASE\]" "${template}"
    grep -q "RESPONSEFILE_VERSION" "${template}"
    grep -q "OPERATION_TYPE" "${template}"
}

# ------------------------------------------------------------------------------
# Test: README documentation exists
# ------------------------------------------------------------------------------
@test "DBCA README documentation exists" {
    local readme="${PROJECT_ROOT}/src/templates/dbca/README.md"
    [[ -f "${readme}" ]]
    
    # Check for key sections
    grep -q "# DBCA Templates" "${readme}"
    grep -q "## Available Templates" "${readme}"
    grep -q "## Usage" "${readme}"
    grep -q "## Template Variables" "${readme}"
}

# ------------------------------------------------------------------------------
# Test: Common reference file exists
# ------------------------------------------------------------------------------
@test "Common DBCA reference file exists" {
    [[ -f "${PROJECT_ROOT}/src/templates/dbca/common/dbca_common.rsp" ]]
    
    # Check for content
    grep -q "Common Variables for Substitution" "${PROJECT_ROOT}/src/templates/dbca/common/dbca_common.rsp"
}

# ------------------------------------------------------------------------------
# Test: Error handling - missing SID
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh fails when SID is missing" {
    run "${DBCA_SCRIPT}" --version 19c --sys-password test --system-password test
    [[ "${status}" -ne 0 ]]
    [[ "${output}" =~ "Database SID is required" ]]
}

# ------------------------------------------------------------------------------
# Test: Error handling - missing version
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh fails when version is missing" {
    run "${DBCA_SCRIPT}" --sid ORCL --sys-password test --system-password test
    [[ "${status}" -ne 0 ]]
    [[ "${output}" =~ "Oracle version is required" ]]
}

# ------------------------------------------------------------------------------
# Test: Error handling - invalid version
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh fails with invalid version" {
    run "${DBCA_SCRIPT}" --sid ORCL --version 21c --sys-password test --system-password test
    [[ "${status}" -ne 0 ]]
    [[ "${output}" =~ "Invalid version" ]]
}

# ------------------------------------------------------------------------------
# Test: Error handling - invalid template for version
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh fails with free template for 19c" {
    run "${DBCA_SCRIPT}" --sid ORCL --version 19c --template free --sys-password test --system-password test
    [[ "${status}" -ne 0 ]]
    [[ "${output}" =~ "Template 'free' is not available for 19c" ]]
}

# ------------------------------------------------------------------------------
# Test: Error handling - dataguard not available for 26ai
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh fails with dataguard template for 26ai" {
    run "${DBCA_SCRIPT}" --sid ORCL --version 26ai --template dataguard --sys-password test --system-password test
    [[ "${status}" -ne 0 ]]
    [[ "${output}" =~ "Template 'dataguard' is not available for 26ai" ]]
}

# ------------------------------------------------------------------------------
# Test: Script passes shellcheck
# ------------------------------------------------------------------------------
@test "oradba_dbca.sh passes shellcheck" {
    if command -v shellcheck &> /dev/null; then
        run shellcheck "${DBCA_SCRIPT}"
        [[ "${status}" -eq 0 ]]
    else
        skip "shellcheck not available"
    fi
}

# ------------------------------------------------------------------------------
# CF-002 regression: response file must not use a predictable /tmp path
# ------------------------------------------------------------------------------

@test "dbca_response_file_not_in_predictable_tmp_path" {
    # Provide a dummy dbca executable so validate_prerequisites passes
    cat > "${ORACLE_HOME}/bin/dbca" << 'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "${ORACLE_HOME}/bin/dbca"

    # Ensure no stale predictable file is present before the run
    rm -f /tmp/dbca_*.rsp 2> /dev/null || true

    run "${DBCA_SCRIPT}" --sid DRYSID --version 19c --template general \
        --sys-password testpw --system-password testpw --dry-run

    # Dry run must succeed
    [[ "${status}" -eq 0 ]]
    # The reported response file must live under a per-run mktemp directory
    [[ "${output}" =~ oradba_dbca\. ]]
    [[ ! "${output}" =~ /tmp/dbca_DRYSID_ ]]

    # No predictable /tmp/dbca_<SID>_<PID>.rsp file may be left behind
    run bash -c 'ls /tmp/dbca_*_*.rsp 2>/dev/null'
    [[ "${status}" -ne 0 ]]
}

@test "oradba_dbca.sh source creates response file via mktemp" {
    run bash -c "grep -q 'mktemp -d' '${DBCA_SCRIPT}'"
    [[ "${status}" -eq 0 ]]
    run bash -c "grep -q '/tmp/dbca_' '${DBCA_SCRIPT}'"
    [[ "${status}" -ne 0 ]]
}

# ------------------------------------------------------------------------------
# CF-009 First-Iteration Regression
# The validation path increments an 'errors' counter starting from 0. Running
# the help/dispatch path must complete cleanly; a reverted from-zero arithmetic
# fix (CF-001/M1) would abort the script under set -e on the first increment.
# ------------------------------------------------------------------------------

@test "oradba_dbca_first_iteration_does_not_abort" {
    run bash "${DBCA_SCRIPT}" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ oradba_dbca ]]
}
