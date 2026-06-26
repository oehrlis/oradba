#!/usr/bin/env bats
# shellcheck disable=SC1090,SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_version_metadata.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.06.26
# Revision...: 0.27.0
# Purpose....: Behavioral tests for oradba_version_metadata.sh (CF-008)
# Notes......: Covers version comparison/requirement checks and the .install_info
#              read/write/init helpers. Uses an isolated ORADBA_BASE under
#              BATS_TEST_TMPDIR; no real installation required.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE="${BATS_TEST_TMPDIR}/oradba"
    mkdir -p "${ORADBA_BASE}/etc"

    # Source common (provides oradba_log) and the module under test
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    source "${PROJECT_ROOT}/src/lib/oradba_version_metadata.sh"

    INSTALL_INFO="${ORADBA_BASE}/.install_info"
}

teardown() {
    unset ORADBA_BASE
}

# ------------------------------------------------------------------------------
# get_oradba_version
# ------------------------------------------------------------------------------

@test "get_oradba_version reads the VERSION file" {
    echo "0.27.0" > "${ORADBA_BASE}/VERSION"
    run get_oradba_version
    [ "$status" -eq 0 ]
    [ "$output" = "0.27.0" ]
}

@test "get_oradba_version returns unknown when VERSION file is absent" {
    rm -f "${ORADBA_BASE}/VERSION"
    run get_oradba_version
    [ "$status" -eq 0 ]
    [ "$output" = "unknown" ]
}

# ------------------------------------------------------------------------------
# version_meets_requirement / version_compare
# ------------------------------------------------------------------------------

@test "version_meets_requirement passes when current equals required" {
    run version_meets_requirement "1.2.3" "1.2.3"
    [ "$status" -eq 0 ]
}

@test "version_meets_requirement passes when current is newer" {
    run version_meets_requirement "2.0.0" "1.9.9"
    [ "$status" -eq 0 ]
}

@test "version_meets_requirement fails when current is too old" {
    run version_meets_requirement "1.0.0" "2.0.0"
    [ "$status" -eq 1 ]
}

@test "version_meets_requirement handles leading v prefix" {
    run version_meets_requirement "v1.5.0" "v1.4.0"
    [ "$status" -eq 0 ]
}

# ------------------------------------------------------------------------------
# set_install_info / get_install_info
# ------------------------------------------------------------------------------

@test "set_install_info then get_install_info round-trips a value" {
    set_install_info "install_version" "0.25.0"
    run get_install_info "install_version"
    [ "$status" -eq 0 ]
    [ "$output" = "0.25.0" ]
}

@test "set_install_info updates an existing key in place" {
    set_install_info "install_version" "0.25.0"
    set_install_info "install_version" "0.26.0"
    run get_install_info "install_version"
    [ "$status" -eq 0 ]
    [ "$output" = "0.26.0" ]
    # Must not duplicate the key
    run grep -c "^install_version=" "${INSTALL_INFO}"
    [ "$output" = "1" ]
}

@test "get_install_info returns empty for a missing key" {
    set_install_info "install_version" "0.25.0"
    run get_install_info "nonexistent_key"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "get_install_info returns empty when .install_info is absent" {
    rm -f "${INSTALL_INFO}"
    run get_install_info "install_version"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ------------------------------------------------------------------------------
# init_install_info
# ------------------------------------------------------------------------------

@test "init_install_info creates a populated metadata file" {
    rm -f "${INSTALL_INFO}"
    run init_install_info "0.27.0"
    [ "$status" -eq 0 ]
    [ -f "${INSTALL_INFO}" ]
    run get_install_info "install_version"
    [ "$output" = "0.27.0" ]
    run get_install_info "install_method"
    [ "$output" = "installer" ]
}
