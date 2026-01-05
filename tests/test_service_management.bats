#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_service_management.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.01
# Revision...: 0.1.0
# Purpose....: BATS tests for service management scripts
# Notes......: Tests oradba_dbctl, oradba_lsnrctl, oradba_services functionality
# Usage......: bats test_service_management.bats
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup
setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export ORADBA_BASE="${PROJECT_ROOT}/src"
    export ORADBA_BIN="${PROJECT_ROOT}/src/bin"
}

# ------------------------------------------------------------------------------
# Script Existence Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh exists" {
    [ -f "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" ]
}

@test "oradba_lsnrctl.sh exists" {
    [ -f "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" ]
}

@test "oradba_services.sh exists" {
    [ -f "${PROJECT_ROOT}/src/bin/oradba_services.sh" ]
}

@test "oradba_services_root.sh exists" {
    [ -f "${PROJECT_ROOT}/src/bin/oradba_services_root.sh" ]
}

# ------------------------------------------------------------------------------
# Script Permissions Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh is executable" {
    [ -x "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" ]
}

@test "oradba_lsnrctl.sh is executable" {
    [ -x "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" ]
}

@test "oradba_services.sh is executable" {
    [ -x "${PROJECT_ROOT}/src/bin/oradba_services.sh" ]
}

@test "oradba_services_root.sh is executable" {
    [ -x "${PROJECT_ROOT}/src/bin/oradba_services_root.sh" ]
}

# ------------------------------------------------------------------------------
# Syntax Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh has valid bash syntax" {
    bash -n "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh"
}

@test "oradba_lsnrctl.sh has valid bash syntax" {
    bash -n "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh"
}

@test "oradba_services.sh has valid bash syntax" {
    bash -n "${PROJECT_ROOT}/src/bin/oradba_services.sh"
}

@test "oradba_services_root.sh has valid bash syntax" {
    bash -n "${PROJECT_ROOT}/src/bin/oradba_services_root.sh"
}

# ------------------------------------------------------------------------------
# Help Output Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh --help displays usage" {
    run "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_lsnrctl.sh --help displays usage" {
    run "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_services.sh --help displays usage" {
    run "${PROJECT_ROOT}/src/bin/oradba_services.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_services_root.sh --help displays usage" {
    run "${PROJECT_ROOT}/src/bin/oradba_services_root.sh" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Invalid Action Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh rejects invalid action" {
    run "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" invalid_action
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_lsnrctl.sh rejects invalid action" {
    run "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" invalid_action
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "oradba_services.sh rejects invalid action" {
    run "${PROJECT_ROOT}/src/bin/oradba_services.sh" invalid_action
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

# ------------------------------------------------------------------------------
# Configuration File Tests
# ------------------------------------------------------------------------------

@test "oradba_services.conf exists" {
    [ -f "${PROJECT_ROOT}/src/etc/oradba_services.conf" ]
}

@test "oradba_services.conf has valid syntax" {
    bash -n "${PROJECT_ROOT}/src/etc/oradba_services.conf"
}

@test "oradba_services.conf contains STARTUP_ORDER" {
    grep -q "STARTUP_ORDER=" "${PROJECT_ROOT}/src/etc/oradba_services.conf"
}

@test "oradba_services.conf contains SHUTDOWN_ORDER" {
    grep -q "SHUTDOWN_ORDER=" "${PROJECT_ROOT}/src/etc/oradba_services.conf"
}

# ------------------------------------------------------------------------------
# Template Tests
# ------------------------------------------------------------------------------

@test "systemd template exists" {
    [ -f "${PROJECT_ROOT}/src/templates/systemd/oradba.service" ]
}

@test "systemd template contains Unit section" {
    grep -q "\[Unit\]" "${PROJECT_ROOT}/src/templates/systemd/oradba.service"
}

@test "systemd template contains Service section" {
    grep -q "\[Service\]" "${PROJECT_ROOT}/src/templates/systemd/oradba.service"
}

@test "systemd template contains Install section" {
    grep -q "\[Install\]" "${PROJECT_ROOT}/src/templates/systemd/oradba.service"
}

@test "init.d template exists" {
    [ -f "${PROJECT_ROOT}/src/templates/init.d/oradba" ]
}

@test "init.d template is executable" {
    [ -x "${PROJECT_ROOT}/src/templates/init.d/oradba" ]
}

@test "init.d template has valid bash syntax" {
    bash -n "${PROJECT_ROOT}/src/templates/init.d/oradba"
}

@test "init.d template contains chkconfig comment" {
    grep -q "# chkconfig:" "${PROJECT_ROOT}/src/templates/init.d/oradba"
}

# ------------------------------------------------------------------------------
# Alias Tests
# ------------------------------------------------------------------------------

@test "aliases.sh contains dbctl alias" {
    grep -q "create_dynamic_alias dbctl" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

@test "aliases.sh contains dbstart alias" {
    grep -q "create_dynamic_alias dbstart" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

@test "aliases.sh contains dbstop alias" {
    grep -q "create_dynamic_alias dbstop" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

@test "aliases.sh contains lsnrctl alias" {
    grep -q "create_dynamic_alias listener" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

@test "aliases.sh contains orastart alias" {
    grep -q "create_dynamic_alias orastart" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

@test "aliases.sh contains orastop alias" {
    grep -q "create_dynamic_alias orastop" "${PROJECT_ROOT}/src/lib/aliases.sh"
}

# ------------------------------------------------------------------------------
# Documentation Tests
# ------------------------------------------------------------------------------

@test "service management documentation exists" {
    [ -f "${PROJECT_ROOT}/src/doc/17-service-management.md" ]
}

@test "documentation contains Overview section" {
    grep -q "## Overview" "${PROJECT_ROOT}/src/doc/17-service-management.md"
}

@test "documentation contains Database Control section" {
    grep -q "## Database Control" "${PROJECT_ROOT}/src/doc/17-service-management.md"
}

@test "documentation contains Listener Control section" {
    grep -q "## Listener Control" "${PROJECT_ROOT}/src/doc/17-service-management.md"
}

@test "documentation contains System Integration section" {
    grep -q "## System Integration" "${PROJECT_ROOT}/src/doc/17-service-management.md"
}

@test "documentation contains examples" {
    grep -q "### Examples" "${PROJECT_ROOT}/src/doc/17-service-management.md"
}

# ------------------------------------------------------------------------------
# Script Header Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh has standard header" {
    head -5 "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh" | grep -q "OraDBA"
}

@test "oradba_lsnrctl.sh has standard header" {
    head -5 "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh" | grep -q "OraDBA"
}

@test "oradba_services.sh has standard header" {
    head -5 "${PROJECT_ROOT}/src/bin/oradba_services.sh" | grep -q "OraDBA"
}

@test "scripts have revision numbers" {
    grep -q "Revision" "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh"
    grep -q "Revision" "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh"
    grep -q "Revision" "${PROJECT_ROOT}/src/bin/oradba_services.sh"
}

# ------------------------------------------------------------------------------
# Integration Tests
# ------------------------------------------------------------------------------

@test "oradba_dbctl.sh can source common.sh" {
    grep -q "source.*common.sh" "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh"
}

@test "oradba_lsnrctl.sh can source common.sh" {
    grep -q "source.*common.sh" "${PROJECT_ROOT}/src/bin/oradba_lsnrctl.sh"
}

@test "oradba_services.sh can source common.sh" {
    grep -q "source.*common.sh" "${PROJECT_ROOT}/src/bin/oradba_services.sh"
}

@test "scripts reference oraenv.sh for environment" {
    grep -q "oraenv.sh" "${PROJECT_ROOT}/src/bin/oradba_dbctl.sh"
}

# EOF -------------------------------------------------------------------------
