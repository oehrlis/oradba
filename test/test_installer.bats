#!/usr/bin/env bats
# -----------------------------------------------------------------------
# oradba - Oracle Database Administration Toolset
# test_installer.bats - Tests for installer script
# -----------------------------------------------------------------------
# Copyright (c) 2025 Stefan Oehrli
# Licensed under the Apache License, Version 2.0
# -----------------------------------------------------------------------

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    BUILD_SCRIPT="${PROJECT_ROOT}/build_installer.sh"
    
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
