#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_version.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: Test script for version management functions
# Notes......: Tests get_oradba_version and related functions
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Source the common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORADBA_BASE="${SCRIPT_DIR}"

# shellcheck source=../src/lib/common.sh
source "${SCRIPT_DIR}/src/lib/common.sh"

echo "Testing OraDBA Version Management Functions"
echo "=============================================="
echo ""

# Test 1: Get version
echo "Test 1: Get OraDBA version"
VERSION=$(get_oradba_version)
echo "  Current version: ${VERSION}"
[[ "${VERSION}" == "0.14.0" ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 2: Version comparison - equal
echo "Test 2: Version comparison (equal)"
version_compare "0.14.0" "0.14.0"
result=$?
echo "  0.14.0 vs 0.14.0: ${result}"
[[ ${result} -eq 0 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 3: Version comparison - greater
echo "Test 3: Version comparison (greater)"
version_compare "0.15.0" "0.14.0"
result=$?
echo "  0.15.0 vs 0.14.0: ${result}"
[[ ${result} -eq 1 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 4: Version comparison - less
echo "Test 4: Version comparison (less)"
version_compare "0.13.0" "0.14.0"
result=$?
echo "  0.13.0 vs 0.14.0: ${result}"
[[ ${result} -eq 2 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 5: Version with v prefix
echo "Test 5: Version with v prefix"
version_compare "v0.15.0" "v0.14.0"
result=$?
echo "  v0.15.0 vs v0.14.0: ${result}"
[[ ${result} -eq 1 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 6: Major version difference
echo "Test 6: Major version difference"
version_compare "1.0.0" "0.9.9"
result=$?
echo "  1.0.0 vs 0.9.9: ${result}"
[[ ${result} -eq 1 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 7: Version meets requirement (yes)
echo "Test 7: Version meets requirement (yes)"
version_meets_requirement "0.14.0" "0.13.0"
result=$?
echo "  0.14.0 meets 0.13.0: ${result}"
[[ ${result} -eq 0 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 8: Version meets requirement (no)
echo "Test 8: Version meets requirement (no)"
version_meets_requirement "0.12.0" "0.13.0"
result=$?
echo "  0.12.0 meets 0.13.0: ${result}"
[[ ${result} -eq 1 ]] && echo "  ✗ PASS (expected failure)" || echo "  ✗ FAIL"
echo ""

# Test 9: Version meets requirement (equal)
echo "Test 9: Version meets requirement (equal)"
version_meets_requirement "0.14.0" "0.14.0"
result=$?
echo "  0.14.0 meets 0.14.0: ${result}"
[[ ${result} -eq 0 ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
echo ""

# Test 10: Initialize and read install info
echo "Test 10: Install info functions"
TEMP_DIR=$(mktemp -d)
ORADBA_BASE="${TEMP_DIR}"
init_install_info "0.14.0"
STORED_VERSION=$(get_install_info "install_version")
echo "  Stored version: ${STORED_VERSION}"
[[ "${STORED_VERSION}" == "0.14.0" ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
rm -rf "${TEMP_DIR}"
echo ""

# Test 11: Set and get install info
echo "Test 11: Set/Get install info"
TEMP_DIR=$(mktemp -d)
export ORADBA_BASE="${TEMP_DIR}"
init_install_info "0.14.0"
set_install_info "test_key" "test_value"
TEST_VALUE=$(get_install_info "test_key")
echo "  Stored value: ${TEST_VALUE}"
[[ "${TEST_VALUE}" == "test_value" ]] && echo "  ✓ PASS" || echo "  ✗ FAIL"
rm -rf "${TEMP_DIR}"
echo ""

echo "=============================================="
echo "Testing completed"
