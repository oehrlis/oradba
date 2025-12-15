#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_installer.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: BATS tests for installer build script
# Notes......: Tests installer creation and VERSION file validation.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    BUILD_SCRIPT="${PROJECT_ROOT}/scripts/build_installer.sh"
    
    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "build_installer.sh exists and is executable" {
    [ -f "$BUILD_SCRIPT" ]
    [ -x "$BUILD_SCRIPT" ]
}

@test "VERSION file exists" {
    [ -f "${PROJECT_ROOT}/VERSION" ]
}

@test "VERSION file contains valid semantic version" {
    version=$(cat "${PROJECT_ROOT}/VERSION")
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
