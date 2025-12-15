#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: run_tests.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Revision...: 0.1.0
# Purpose....: Execute all BATS test suites and report results
# Notes......: Runs all .bats files in the tests directory.
#              Requires BATS testing framework to be installed.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Running oradba Test Suite"
echo "========================================="
echo ""

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}ERROR:${NC} BATS is not installed"
    echo ""
    echo "Install BATS using:"
    echo "  macOS:   brew install bats-core"
    echo "  Ubuntu:  sudo apt-get install bats"
    echo "  GitHub:  https://github.com/bats-core/bats-core"
    exit 1
fi

# Find all test files
TEST_FILES=$(find "$SCRIPT_DIR" -name "*.bats" -type f | sort)

if [[ -z "$TEST_FILES" ]]; then
    echo -e "${YELLOW}WARNING:${NC} No test files found"
    exit 0
fi

echo "Found test files:"
echo "$TEST_FILES" | sed 's/^/  /'
echo ""

# Run tests
FAILED=0
PASSED=0

for test_file in $TEST_FILES; do
    test_name=$(basename "$test_file")
    echo -e "${YELLOW}Running:${NC} $test_name"
    
    if bats "$test_file"; then
        PASSED=$((PASSED + 1))
        echo -e "${GREEN}✓${NC} $test_name passed"
    else
        FAILED=$((FAILED + 1))
        echo -e "${RED}✗${NC} $test_name failed"
    fi
    echo ""
done

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
