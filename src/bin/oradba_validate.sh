#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oradba_validate.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.02
# Revision...: 0.10.0
# Purpose....: Validation script for OraDBA installation
# Notes......: Run this after installation to verify setup
# Usage......: oradba_validate.sh [-h|--help] [-v|--verbose]
# ------------------------------------------------------------------------------

# Script directory and setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="${ORADBA_PREFIX:-$(dirname "${SCRIPT_DIR}")}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Options
VERBOSE=false

# Test counters
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# Usage function
usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Validate OraDBA installation and configuration.

OPTIONS:
    -h, --help      Display this help message
    -v, --verbose   Verbose output (show all tests)
    
EXAMPLES:
    ${0##*/}                 # Run validation
    ${0##*/} --verbose       # Run with detailed output

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Test function
test_item() {
    local test_name="$1"
    local test_command="$2"
    local test_type="${3:-required}"  # required|optional
    
    TOTAL=$((TOTAL + 1))
    
    if eval "${test_command}" >/dev/null 2>&1; then
        if [[ "${VERBOSE}" == "true" ]]; then
            echo -e "${GREEN}✓${NC} ${test_name}"
        fi
        PASSED=$((PASSED + 1))
        return 0
    else
        if [[ "${test_type}" == "optional" ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo -e "${YELLOW}⚠${NC} ${test_name} (optional)"
            fi
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${RED}✗${NC} ${test_name}"
            FAILED=$((FAILED + 1))
        fi
        return 1
    fi
}

# Print header
cat << EOF
===============================================================================
                      OraDBA Installation Validation
===============================================================================

Installation Directory: ${ORADBA_BASE}
$(date)

EOF

# Check basic installation
echo "Checking OraDBA Installation..."
echo "-------------------------------------------------------------------------------"

test_item "OraDBA base directory exists" "[[ -d '${ORADBA_BASE}' ]]"
test_item "bin directory exists" "[[ -d '${ORADBA_BASE}/bin' ]]"
test_item "etc directory exists" "[[ -d '${ORADBA_BASE}/etc' ]]"
test_item "lib directory exists" "[[ -d '${ORADBA_BASE}/lib' ]]"
test_item "doc directory exists" "[[ -d '${ORADBA_BASE}/doc' ]]"
test_item "sql directory exists" "[[ -d '${ORADBA_BASE}/sql' ]]"

echo ""

# Check core scripts
echo "Checking Core Scripts..."
echo "-------------------------------------------------------------------------------"

test_item "oraenv.sh exists" "[[ -f '${ORADBA_BASE}/bin/oraenv.sh' ]]"
test_item "oradba_version.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_version.sh' ]]"
test_item "oradba_version.sh is executable" "[[ -x '${ORADBA_BASE}/bin/oradba_version.sh' ]]"
test_item "dbstatus.sh exists" "[[ -f '${ORADBA_BASE}/bin/dbstatus.sh' ]]" "optional"
test_item "dbstatus.sh is executable" "[[ -x '${ORADBA_BASE}/bin/dbstatus.sh' ]]" "optional"
test_item "oradba_dbctl.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_dbctl.sh' ]]" "optional"
test_item "oradba_lsnrctl.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_lsnrctl.sh' ]]" "optional"
test_item "oradba_services.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_services.sh' ]]" "optional"

echo ""

# Check libraries
echo "Checking Library Files..."
echo "-------------------------------------------------------------------------------"

test_item "common.sh exists" "[[ -f '${ORADBA_BASE}/lib/common.sh' ]]"
test_item "aliases.sh exists" "[[ -f '${ORADBA_BASE}/lib/aliases.sh' ]]"
test_item "db_functions.sh exists" "[[ -f '${ORADBA_BASE}/lib/db_functions.sh' ]]" "optional"

echo ""

# Check configuration files
echo "Checking Configuration Files..."
echo "-------------------------------------------------------------------------------"

test_item "oradba_core.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_core.conf' ]]"
test_item "oradba_standard.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_standard.conf' ]]"
test_item "sid._DEFAULT_.conf exists" "[[ -f '${ORADBA_BASE}/etc/sid._DEFAULT_.conf' ]]"
test_item "oradba_customer.conf.example exists" "[[ -f '${ORADBA_BASE}/etc/oradba_customer.conf.example' ]]"
test_item "sid.ORCL.conf.example exists" "[[ -f '${ORADBA_BASE}/etc/sid.ORCL.conf.example' ]]" "optional"
test_item "oradba_services.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_services.conf' ]]" "optional"

echo ""

# Check documentation
echo "Checking Documentation..."
echo "-------------------------------------------------------------------------------"

test_item "README.md exists" "[[ -f '${ORADBA_BASE}/README.md' ]]" "optional"
test_item "06-aliases.md exists" "[[ -f '${ORADBA_BASE}/doc/06-aliases.md' ]]"
test_item "05-configuration.md exists" "[[ -f '${ORADBA_BASE}/doc/05-configuration.md' ]]" "optional"
test_item "alias_help.txt exists" "[[ -f '${ORADBA_BASE}/doc/alias_help.txt' ]]"

echo ""

# Check SQL files
echo "Checking SQL Files..."
echo "-------------------------------------------------------------------------------"

test_item "login.sql exists" "[[ -f '${ORADBA_BASE}/sql/login.sql' ]]"
test_item "db_info.sql exists" "[[ -f '${ORADBA_BASE}/sql/db_info.sql' ]]" "optional"

echo ""

# Check if environment can be sourced
echo "Checking Environment Setup..."
echo "-------------------------------------------------------------------------------"

if [[ -f "${ORADBA_BASE}/bin/oraenv.sh" ]]; then
    # Check bash syntax without executing
    if bash -n "${ORADBA_BASE}/bin/oraenv.sh" 2>/dev/null; then
        TOTAL=$((TOTAL + 1))
        PASSED=$((PASSED + 1))
        if [[ "${VERBOSE}" == "true" ]]; then
            echo -e "${GREEN}✓${NC} oraenv.sh has valid syntax"
        fi
    else
        TOTAL=$((TOTAL + 1))
        FAILED=$((FAILED + 1))
        echo -e "${RED}✗${NC} oraenv.sh has syntax errors"
    fi
fi

echo ""

# Check Oracle prerequisites (optional)
echo "Checking Oracle Environment (optional)..."
echo "-------------------------------------------------------------------------------"

test_item "ORACLE_HOME is set" "[[ -n '${ORACLE_HOME}' ]]" "optional"
test_item "ORACLE_BASE is set" "[[ -n '${ORACLE_BASE}' ]]" "optional"
test_item "ORACLE_SID is set" "[[ -n '${ORACLE_SID}' ]]" "optional"
test_item "oratab file exists" "[[ -f '/etc/oratab' || -f '/var/opt/oracle/oratab' ]]" "optional"
test_item "sqlplus command available" "command -v sqlplus >/dev/null" "optional"

echo ""

# Summary
echo "==============================================================================="
echo "Validation Summary"
echo "==============================================================================="
echo ""
echo "  Total Tests:     ${TOTAL}"
echo -e "  ${GREEN}Passed:${NC}          ${PASSED}"
if [[ ${WARNINGS} -gt 0 ]]; then
    echo -e "  ${YELLOW}Warnings:${NC}        ${WARNINGS} (optional components)"
fi
if [[ ${FAILED} -gt 0 ]]; then
    echo -e "  ${RED}Failed:${NC}          ${FAILED}"
fi
echo ""

# Final result
if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}✓ OraDBA installation is valid!${NC}"
    echo ""
    echo "To use OraDBA, source the environment script:"
    echo "  source ${ORADBA_BASE}/bin/oraenv.sh [ORACLE_SID]"
    echo ""
    echo "For help:"
    echo "  ${ORADBA_BASE}/bin/oraenv.sh --help"
    echo "  source ${ORADBA_BASE}/bin/oraenv.sh && alih"
    exit 0
else
    echo -e "${RED}✗ OraDBA installation has issues!${NC}"
    echo ""
    echo "Please check the failed items above. You may need to:"
    echo "  1. Reinstall OraDBA"
    echo "  2. Check file permissions"
    echo "  3. Verify installation directory"
    echo ""
    echo "For support, see: ${ORADBA_BASE}/README.md"
    exit 1
fi
