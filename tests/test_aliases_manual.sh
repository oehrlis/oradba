#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: test_aliases_manual.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.16
# Revision...: 0.5.0
# Purpose....: Manual test script for OraDBA aliases and variables
# Notes......: Run this after sourcing oraenv.sh to verify aliases work
# Usage......: source oraenv.sh <SID> && bash tests/test_aliases_manual.sh
# ------------------------------------------------------------------------------

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL=0
PASSED=0
FAILED=0

# Test function
test_variable() {
    local var_name="$1"
    local var_value="${!var_name}"
    TOTAL=$((TOTAL + 1))
    
    if [[ -n "${var_value}" ]]; then
        echo -e "${GREEN}✓${NC} ${var_name}=${var_value}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} ${var_name} is empty or not set"
        FAILED=$((FAILED + 1))
    fi
}

test_alias() {
    local alias_name="$1"
    TOTAL=$((TOTAL + 1))
    
    if alias "${alias_name}" >/dev/null 2>&1; then
        local alias_def=$(alias "${alias_name}" 2>/dev/null | sed "s/^alias ${alias_name}=//")
        echo -e "${GREEN}✓${NC} ${alias_name} → ${alias_def}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} ${alias_name} not defined"
        FAILED=$((FAILED + 1))
    fi
}

test_function() {
    local func_name="$1"
    TOTAL=$((TOTAL + 1))
    
    if declare -F "${func_name}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} ${func_name}() is defined"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} ${func_name}() not defined"
        FAILED=$((FAILED + 1))
    fi
}

echo "==============================================================================="
echo "OraDBA Alias and Variable Test"
echo "==============================================================================="
echo ""

# Check if oraenv.sh has been sourced
if [[ -z "${ORADBA_PREFIX}" ]]; then
    echo -e "${RED}ERROR: ORADBA_PREFIX not set. Please source oraenv.sh first.${NC}"
    echo "Usage: source oraenv.sh <SID> && bash $0"
    exit 1
fi

echo "Environment Check:"
echo "  ORACLE_SID: ${ORACLE_SID:-<not set>}"
echo "  ORACLE_HOME: ${ORACLE_HOME:-<not set>}"
echo "  ORACLE_BASE: ${ORACLE_BASE:-<not set>}"
echo "  ORADBA_PREFIX: ${ORADBA_PREFIX}"
echo ""

# Test Core Variables
echo "Testing Core Variables:"
echo "-------------------------------------------------------------------------------"
test_variable "ORADBA_PREFIX"
test_variable "ORADBA_CONFIG_DIR"
test_variable "ORADBA_ETC"
test_variable "ORADBA_LOG"
test_variable "ORADBA_TEMP"
test_variable "ORACLE_HOME"
test_variable "ORACLE_BASE"
test_variable "ORACLE_SID"
test_variable "TNS_ADMIN"
echo ""

# Test Short Directory Variables
echo "Testing Short Directory Variables:"
echo "-------------------------------------------------------------------------------"
test_variable "cdh"
test_variable "cdob"
test_variable "cdl"
test_variable "etc"
test_variable "log"
test_variable "cdn"
echo ""

# Test SID-Specific Variables (may be empty if DB not accessible)
echo "Testing SID-Specific Variables (may be empty if DB not accessible):"
echo "-------------------------------------------------------------------------------"
test_variable "ORADBA_ORA_ADMIN_SID"
test_variable "ORADBA_ORA_DIAG_SID"
test_variable "cda"
test_variable "cdd"
echo ""

# Test SQL*Plus Aliases
echo "Testing SQL*Plus Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "sq"
test_alias "sqh"
test_alias "sqlplush"
test_alias "sqoh"
echo ""

# Test RMAN Aliases
echo "Testing RMAN Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "rman"
test_alias "rmanc"
test_alias "rmanh"
test_alias "rmanch"
test_alias "lsnr"
test_alias "adrcih"
echo ""

# Test sessionsql
echo "Testing sessionsql:"
echo "-------------------------------------------------------------------------------"
test_alias "sessionsql"
echo ""

# Test Directory Aliases - Oracle
echo "Testing Directory Aliases (Oracle):"
echo "-------------------------------------------------------------------------------"
test_alias "cdh"
test_alias "cdob"
test_alias "cdbn"
test_alias "cdn"
test_alias "cdt"
echo ""

# Test Directory Aliases - OraDBA
echo "Testing Directory Aliases (OraDBA):"
echo "-------------------------------------------------------------------------------"
test_alias "cdb"
test_alias "cde"
test_alias "cdr"
test_alias "cdlog"
test_alias "cdtmp"
test_alias "cdl"
test_alias "etc"
test_alias "log"
echo ""

# Test SID-Specific Aliases
echo "Testing SID-Specific Aliases (may not exist if DB not accessible):"
echo "-------------------------------------------------------------------------------"
test_alias "cda"
test_alias "cdc"
test_alias "cdd"
test_alias "vii"
echo ""

# Test Dynamic Aliases (generated by aliases.sh)
echo "Testing Dynamic Aliases (require ORACLE_SID and accessible DB):"
echo "-------------------------------------------------------------------------------"
test_alias "taa"
test_alias "vaa"
test_alias "via"
test_alias "cdda"
test_alias "cddt"
echo ""

# Test Utility Aliases
echo "Testing Utility Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "c"
test_alias "m"
test_alias "l"
test_alias "ll"
test_alias "lr"
test_alias "lsl"
test_alias "psg"
test_alias "alig"
echo ""

# Test Database Operations
echo "Testing Database Operation Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "sta"
test_alias "lstat"
test_alias "lstart"
test_alias "lstop"
test_alias "pmon"
test_alias "oratab"
test_alias "tns"
echo ""

# Test Editor Aliases
echo "Testing Editor Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "vio"
test_alias "vit"
test_alias "vil"
test_alias "visql"
test_alias "vildap"
test_alias "vis"
test_alias "vic"
echo ""

# Test Help and Version
echo "Testing Help and Version Aliases:"
echo "-------------------------------------------------------------------------------"
test_alias "version"
test_alias "alih"
test_alias "save_cron"
echo ""

# Test Functions (if aliases.sh loaded)
if [[ "${ORADBA_LOAD_ALIASES}" == "true" ]]; then
    echo "Testing OraDBA Functions:"
    echo "-------------------------------------------------------------------------------"
    test_function "get_diagnostic_dest"
    test_function "has_rlwrap"
    test_function "generate_sid_aliases"
    echo ""
fi

# Summary
echo "==============================================================================="
echo "Test Summary:"
echo "  Total:  ${TOTAL}"
echo -e "  ${GREEN}Passed: ${PASSED}${NC}"
if [[ ${FAILED} -gt 0 ]]; then
    echo -e "  ${RED}Failed: ${FAILED}${NC}"
else
    echo "  Failed: 0"
fi
echo "==============================================================================="

if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. This may be normal if:${NC}"
    echo "  - Database is not accessible (dynamic aliases won't be generated)"
    echo "  - ORACLE_SID is not set (SID-specific aliases won't exist)"
    echo "  - Some directories don't exist yet"
    exit 1
fi
