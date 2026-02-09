#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Administration Toolset (https://www.oradba.ch)
# ------------------------------------------------------------------------------
# Name.......: oradba_validate.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.20
# Revision...: v0.19.x
# Purpose....: Validation script for OraDBA v0.19.x installation
# Notes......: Verifies Registry API, Plugin System, and Environment Libraries setup
# Usage......: oradba_validate.sh [-h|--help] [-v|--verbose]
# ------------------------------------------------------------------------------

# Script directory and setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORADBA_BASE="${ORADBA_PREFIX:-$(dirname "${SCRIPT_DIR}")}"

# Source common library for oratab detection
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    # shellcheck source=../lib/oradba_common.sh
    source "${ORADBA_BASE}/lib/oradba_common.sh"
fi

# Detect pre-Oracle installation mode
PRE_ORACLE_MODE=false
if type get_oratab_path &> /dev/null; then
    ORATAB_PATH=$(get_oratab_path)
    if [[ ! -f "$ORATAB_PATH" ]] || ! grep -q "^[^#]" "$ORATAB_PATH" 2> /dev/null; then
        PRE_ORACLE_MODE=true
    fi
else
    # Fallback detection
    if [[ ! -f "/etc/oratab" ]] && [[ ! -f "/var/opt/oracle/oratab" ]] && [[ ! -f "${ORADBA_BASE}/etc/oratab" ]]; then
        PRE_ORACLE_MODE=true
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
VERBOSE=false

# Test counters
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display usage information for validation script
# Args....: None
# Returns.: 0 (exits after display)
# Output..: Usage help to stdout
# Notes...: Shows options and examples for running validation
# ------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Validate OraDBA installation and configuration.

OPTIONS:
    -h, --help      Display this help message
    -v, --verbose   Verbose output (show all tests)
    --debug         Enable debug logging (ORADBA_DEBUG=true)
    
EXAMPLES:
    ${0##*/}                 # Run validation
    ${0##*/} --verbose       # Run with detailed output
    ${0##*/} --debug         # Run with debug logging

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h | --help)
            usage
            ;;
        -v | --verbose)
            VERBOSE=true
            shift
            ;;
        --debug)
            export ORADBA_DEBUG="true"
            export ORADBA_LOG_LEVEL="DEBUG"
            oradba_log DEBUG "oradba_validate.sh: Debug mode enabled via --debug flag"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

oradba_log DEBUG "oradba_validate.sh: Starting validation with VERBOSE=${VERBOSE}"

# ------------------------------------------------------------------------------
# Function: test_item
# Purpose.: Execute a single validation test and track results
# Args....: $1 - Test name (description)
#           $2 - Test command to execute
#           $3 - Test type (required|optional, default: required)
# Returns.: 0 if test passes, 1 if test fails
# Output..: Test result with checkmark/X/warning (if verbose or failed)
# Notes...: Updates global counters TOTAL, PASSED, FAILED, WARNINGS
#           Optional tests show warning symbol instead of failure
# ------------------------------------------------------------------------------
test_item() {
    local test_name="$1"
    local test_command="$2"
    local test_type="${3:-required}" # required|optional

    oradba_log DEBUG "oradba_validate.sh: Running test '${test_name}' (type=${test_type})"
    oradba_log DEBUG "oradba_validate.sh: Test command: ${test_command}"

    TOTAL=$((TOTAL + 1))

    if eval "${test_command}" > /dev/null 2>&1; then
        if [[ "${VERBOSE}" == "true" ]]; then
            echo -e "${GREEN}✓${NC} ${test_name}"
        fi
        oradba_log DEBUG "oradba_validate.sh: Test PASSED: ${test_name}"
        PASSED=$((PASSED + 1))
        return 0
    else
        if [[ "${test_type}" == "optional" ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo -e "${YELLOW}⚠${NC} ${test_name} (optional)"
            fi
            oradba_log DEBUG "oradba_validate.sh: Test WARNING (optional): ${test_name}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${RED}✗${NC} ${test_name}"
            oradba_log DEBUG "oradba_validate.sh: Test FAILED: ${test_name}"
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

Installation Mode: $([[ "$PRE_ORACLE_MODE" == "true" ]] && echo "Pre-Oracle" || echo "Oracle Installed")
Validation Date:   $(date '+%Y-%m-%d %H:%M:%S')

===============================================================================
                      OraDBA Installation Validation
===============================================================================

Installation Directory: ${ORADBA_BASE}
$(date)

EOF

# Check basic installation
if [[ "${VERBOSE}" == "true" ]]; then
    echo "Checking OraDBA Installation..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking OraDBA Installation..."
fi

test_item "OraDBA base directory exists" "[[ -d '${ORADBA_BASE}' ]]"
test_item "bin directory exists" "[[ -d '${ORADBA_BASE}/bin' ]]"
test_item "etc directory exists" "[[ -d '${ORADBA_BASE}/etc' ]]"
test_item "lib directory exists" "[[ -d '${ORADBA_BASE}/lib' ]]"
test_item "doc directory exists" "[[ -d '${ORADBA_BASE}/doc' ]]"
test_item "sql directory exists" "[[ -d '${ORADBA_BASE}/sql' ]]"

# Check core scripts
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Core Scripts..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Core Scripts..."
fi

test_item "oraenv.sh exists" "[[ -f '${ORADBA_BASE}/bin/oraenv.sh' ]]"
test_item "oradba_env.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_env.sh' ]]"
test_item "oradba_check.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_check.sh' ]]"
test_item "oradba_check.sh is executable" "[[ -x '${ORADBA_BASE}/bin/oradba_check.sh' ]]"
test_item "oradba_version.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_version.sh' ]]"
test_item "oradba_version.sh is executable" "[[ -x '${ORADBA_BASE}/bin/oradba_version.sh' ]]"
test_item "oradba_homes.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_homes.sh' ]]" "optional"
test_item "oradba_help.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_help.sh' ]]" "optional"
test_item "dbstatus.sh exists" "[[ -f '${ORADBA_BASE}/bin/dbstatus.sh' ]]" "optional"
test_item "dbstatus.sh is executable" "[[ -x '${ORADBA_BASE}/bin/dbstatus.sh' ]]" "optional"
test_item "oraup.sh exists" "[[ -f '${ORADBA_BASE}/bin/oraup.sh' ]]" "optional"
test_item "oradba_dbctl.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_dbctl.sh' ]]" "optional"
test_item "oradba_lsnrctl.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_lsnrctl.sh' ]]" "optional"
test_item "oradba_services.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_services.sh' ]]" "optional"
test_item "oradba_rman.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_rman.sh' ]]" "optional"
test_item "oradba_extension.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_extension.sh' ]]" "optional"
test_item "oradba_sqlnet.sh exists" "[[ -f '${ORADBA_BASE}/bin/oradba_sqlnet.sh' ]]" "optional"
test_item "get_seps_pwd.sh exists" "[[ -f '${ORADBA_BASE}/bin/get_seps_pwd.sh' ]]" "optional"
test_item "sync_to_peers.sh exists" "[[ -f '${ORADBA_BASE}/bin/sync_to_peers.sh' ]]" "optional"
test_item "rman_jobs.sh exists" "[[ -f '${ORADBA_BASE}/bin/rman_jobs.sh' ]]" "optional"
test_item "exp_jobs.sh exists" "[[ -f '${ORADBA_BASE}/bin/exp_jobs.sh' ]]" "optional"
test_item "longops.sh exists" "[[ -f '${ORADBA_BASE}/bin/longops.sh' ]]" "optional"

# Check libraries
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Library Files..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Library Files..."
fi

test_item "oradba_common.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_common.sh' ]]"

# Check for auto-discovery function (v0.19.2+)
if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
    test_item "auto_discover_oracle_homes function exists" "grep -q 'auto_discover_oracle_homes()' '${ORADBA_BASE}/lib/oradba_common.sh'"
fi

test_item "oradba_aliases.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_aliases.sh' ]]"
test_item "oradba_db_functions.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_db_functions.sh' ]]" "optional"
test_item "extensions.sh exists" "[[ -f '${ORADBA_BASE}/lib/extensions.sh' ]]" "optional"

# Registry API (v0.19.0+)
test_item "oradba_registry.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_registry.sh' ]]"

# Environment Management Libraries (v0.19.0+)
test_item "oradba_env_parser.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_parser.sh' ]]"
test_item "oradba_env_builder.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_builder.sh' ]]"
test_item "oradba_env_validator.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_validator.sh' ]]" "optional"
test_item "oradba_env_config.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_config.sh' ]]" "optional"
test_item "oradba_env_status.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_status.sh' ]]" "optional"
test_item "oradba_env_changes.sh exists" "[[ -f '${ORADBA_BASE}/lib/oradba_env_changes.sh' ]]" "optional"

# Plugin System (v0.19.0+)
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Plugin System..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Plugin System..."
fi

test_item "Plugin directory exists" "[[ -d '${ORADBA_BASE}/lib/plugins' ]]"
test_item "Plugin interface exists" "[[ -f '${ORADBA_BASE}/lib/plugins/plugin_interface.sh' ]]"
test_item "Database plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/database_plugin.sh' ]]"
test_item "Client plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/client_plugin.sh' ]]"
test_item "Instant Client plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/iclient_plugin.sh' ]]"
test_item "DataSafe plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh' ]]"
test_item "OUD plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/oud_plugin.sh' ]]"
test_item "Java plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/java_plugin.sh' ]]"
test_item "WebLogic plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/weblogic_plugin.sh' ]]" "optional"
test_item "EM Agent plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/emagent_plugin.sh' ]]" "optional"
test_item "OMS plugin exists" "[[ -f '${ORADBA_BASE}/lib/plugins/oms_plugin.sh' ]]" "optional"

# Check configuration files
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Configuration Files (Phase 1-4 System)..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Configuration Files..."
fi

# Core required configs (Phase 1-3)
test_item "oradba_core.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_core.conf' ]]"
test_item "oradba_standard.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_standard.conf' ]]"

# Check for auto-discovery configuration variables (v0.20.0+)
test_item "ORADBA_AUTO_DISCOVER_ORATAB defined in oradba_standard.conf" "grep -q 'ORADBA_AUTO_DISCOVER_ORATAB' '${ORADBA_BASE}/etc/oradba_standard.conf'"
test_item "ORADBA_AUTO_DISCOVER_PRODUCTS defined in oradba_standard.conf" "grep -q 'ORADBA_AUTO_DISCOVER_PRODUCTS' '${ORADBA_BASE}/etc/oradba_standard.conf'"
test_item "ORADBA_DISCOVERY_PATHS defined in oradba_standard.conf" "grep -q 'ORADBA_DISCOVERY_PATHS' '${ORADBA_BASE}/etc/oradba_standard.conf'"

test_item "sid._DEFAULT_.conf exists" "[[ -f '${ORADBA_BASE}/etc/sid._DEFAULT_.conf' ]]"

# Optional user configs (Phase 1-3)
test_item "oradba_local.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_local.conf' ]]" "optional"
test_item "oradba_customer.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_customer.conf' ]]" "optional"

# Templates (should exist for user creation)
test_item "oradba_customer.conf.example exists" "[[ -f '${ORADBA_BASE}/templates/etc/oradba_customer.conf.example' ]]"
test_item "sid.ORACLE_SID.conf.example exists" "[[ -f '${ORADBA_BASE}/templates/etc/sid.ORACLE_SID.conf.example' ]]"
test_item "oradba_homes.conf.template exists" "[[ -f '${ORADBA_BASE}/templates/etc/oradba_homes.conf.template' ]]"
test_item "oradba_services.conf.example exists" "[[ -f '${ORADBA_BASE}/templates/etc/oradba_services.conf.example' ]]" "optional"

# Service configs (optional, may be created by user)
test_item "oradba_services.conf exists" "[[ -f '${ORADBA_BASE}/etc/oradba_services.conf' ]]" "optional"

# Completions (optional)
test_item "rlwrap_sqlplus_completions exists" "[[ -f '${ORADBA_BASE}/etc/rlwrap_sqlplus_completions' ]]" "optional"
test_item "rlwrap_rman_completions exists" "[[ -f '${ORADBA_BASE}/etc/rlwrap_rman_completions' ]]" "optional"
test_item "rlwrap_lsnrctl_completions exists" "[[ -f '${ORADBA_BASE}/etc/rlwrap_lsnrctl_completions' ]]" "optional"
test_item "rlwrap_adrci_completions exists" "[[ -f '${ORADBA_BASE}/etc/rlwrap_adrci_completions' ]]" "optional"

# Check documentation
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Documentation..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Documentation..."
fi

test_item "README.md exists" "[[ -f '${ORADBA_BASE}/../README.md' ]]" "optional"
test_item "CHANGELOG.md exists" "[[ -f '${ORADBA_BASE}/../CHANGELOG.md' ]]" "optional"
test_item "User documentation directory exists" "[[ -d '${ORADBA_BASE}/doc' ]]"
test_item "index.md exists" "[[ -f '${ORADBA_BASE}/doc/index.md' ]]" "optional"
test_item "aliases.md exists" "[[ -f '${ORADBA_BASE}/doc/aliases.md' ]]"
test_item "configuration.md exists" "[[ -f '${ORADBA_BASE}/doc/configuration.md' ]]"
test_item "alias_help.txt exists" "[[ -f '${ORADBA_BASE}/doc/alias_help.txt' ]]"

# Check SQL files
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking SQL Files..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking SQL Files..."
fi

test_item "login.sql exists" "[[ -f '${ORADBA_BASE}/sql/login.sql' ]]"
test_item "db_info.sql exists" "[[ -f '${ORADBA_BASE}/sql/db_info.sql' ]]" "optional"

# Check installation metadata
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Installation Metadata..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Installation Metadata..."
fi

test_item ".install_info exists" "[[ -f '${ORADBA_BASE}/.install_info' ]]" "optional"
test_item ".oradba.checksum exists" "[[ -f '${ORADBA_BASE}/.oradba.checksum' ]]" "optional"

# Check for file modifications if checksum exists
if [[ -f "${ORADBA_BASE}/.oradba.checksum" ]]; then
    MODIFIED_COUNT=0
    MISSING_COUNT=0
    declare -A checked_files # Track files to avoid duplicates

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse checksum line: hash filename
        expected_hash=$(echo "$line" | awk '{print $1}')
        file_path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        full_path="${ORADBA_BASE}/${file_path}"

        # Skip if already checked (handles duplicates in checksum file)
        [[ -n "${checked_files[$file_path]}" ]] && continue
        checked_files[$file_path]=1

        # Skip files that are expected to be modified during normal operations
        [[ "$file_path" == ".install_info" ]] && continue

        if [[ -f "$full_path" ]]; then
            if command -v sha256sum > /dev/null 2>&1; then
                actual_hash=$(sha256sum "$full_path" 2> /dev/null | awk '{print $1}')
            elif command -v shasum > /dev/null 2>&1; then
                actual_hash=$(shasum -a 256 "$full_path" 2> /dev/null | awk '{print $1}')
            else
                continue
            fi

            if [[ "$expected_hash" != "$actual_hash" ]]; then
                MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
                if [[ "${VERBOSE}" == "true" ]]; then
                    echo -e "${YELLOW}⚠${NC} Modified: ${file_path}"
                fi
            fi
        else
            # File is missing
            MISSING_COUNT=$((MISSING_COUNT + 1))
            if [[ "${VERBOSE}" == "true" ]]; then
                echo -e "${RED}✗${NC} Missing: ${file_path}"
            fi
        fi
    done < "${ORADBA_BASE}/.oradba.checksum"

    if [[ $MODIFIED_COUNT -gt 0 || $MISSING_COUNT -gt 0 ]]; then
        if [[ "${VERBOSE}" == "false" ]]; then
            [[ $MODIFIED_COUNT -gt 0 ]] && echo -e "${YELLOW}⚠${NC} $MODIFIED_COUNT file(s) modified since installation"
            [[ $MISSING_COUNT -gt 0 ]] && echo -e "${RED}✗${NC} $MISSING_COUNT file(s) missing"
        fi
        WARNINGS=$((WARNINGS + MODIFIED_COUNT + MISSING_COUNT))
    else
        if [[ "${VERBOSE}" == "true" ]]; then
            echo -e "${GREEN}✓${NC} No files modified or missing"
        fi
    fi
fi

# Check if environment can be sourced
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Environment Setup..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Environment Setup..."
fi

if [[ -f "${ORADBA_BASE}/bin/oraenv.sh" ]]; then
    # Check bash syntax without executing
    if bash -n "${ORADBA_BASE}/bin/oraenv.sh" 2> /dev/null; then
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

# Check Oracle prerequisites (context-aware)
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
    echo "Checking Oracle Environment..."
    echo "-------------------------------------------------------------------------------"
else
    echo "Checking Oracle Environment..."
fi

if [[ "$PRE_ORACLE_MODE" == "true" ]]; then
    # Pre-Oracle mode: show informative message
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}ℹ${NC} Pre-Oracle installation detected"
        echo -e "${BLUE}ℹ${NC} Oracle Database not required for OraDBA functionality"
        echo -e "${BLUE}ℹ${NC} After installing Oracle, run: oradba_setup.sh link-oratab"
    else
        echo -e "${BLUE}ℹ${NC} Pre-Oracle installation mode (Oracle Database not required)"
    fi
else
    # Oracle installed: check environment
    test_item "ORACLE_HOME is set" "[[ -n '${ORACLE_HOME}' ]]" "optional"
    test_item "ORACLE_BASE is set" "[[ -n '${ORACLE_BASE}' ]]" "optional"
    test_item "ORACLE_SID is set" "[[ -n '${ORACLE_SID}' ]]" "optional"
    test_item "oratab file exists" "[[ -f '/etc/oratab' || -f '/var/opt/oracle/oratab' || -f '${ORADBA_BASE}/etc/oratab' ]]" "optional"
    test_item "sqlplus command available" "command -v sqlplus >/dev/null" "optional"
fi

# Print validation summary
if [[ "${VERBOSE}" == "true" ]]; then
    echo ""
fi

echo "==============================================================================="
echo "Validation Summary"
echo "==============================================================================="
echo ""
echo "  Total Tests:     ${TOTAL}"
echo "  Passed:          ${PASSED}"

if [[ ${WARNINGS} -gt 0 ]]; then
    echo "  Warnings:        ${WARNINGS} (optional components)"
fi

if [[ ${FAILED} -gt 0 ]]; then
    echo "  Failed:          ${FAILED}"
fi

# Show modification status
if [[ -f "${ORADBA_BASE}/.oradba.checksum" ]]; then
    if [[ ${MODIFIED_COUNT:-0} -gt 0 ]]; then
        echo "  Modified:        ${MODIFIED_COUNT} file(s)"
    else
        echo "  Modified:        0 files"
    fi
    if [[ ${MISSING_COUNT:-0} -gt 0 ]]; then
        echo "  Missing:         ${MISSING_COUNT} file(s)"
    else
        echo "  Missing:         0 files"
    fi
else
    echo "  Modified:        unknown (no checksum file)"
    echo "  Missing:         unknown (no checksum file)"
fi

echo ""

# Final result
if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}✓ OraDBA installation is valid!${NC}"
    echo ""

    if [[ "$PRE_ORACLE_MODE" == "true" ]]; then
        # Pre-Oracle mode instructions
        echo "Pre-Oracle Installation Detected:"
        echo ""
        echo "OraDBA is installed and ready. After installing Oracle Database:"
        echo ""
        echo "1. Link system oratab:"
        echo "   ${ORADBA_BASE}/bin/oradba_setup.sh link-oratab"
        echo ""
        echo "2. Check installation:"
        echo "   ${ORADBA_BASE}/bin/oradba_setup.sh check"
        echo ""
        echo "3. Source environment:"
        echo "   source ${ORADBA_BASE}/bin/oraenv.sh [ORACLE_SID]"
        echo ""
        echo "Current functionality:"
        echo "  - OraDBA tools and utilities are available"
        echo "  - Oracle-specific features will activate after Oracle installation"
        echo "  - Run 'oraup.sh' to see current status"
    else
        # Normal mode instructions
        echo "To use OraDBA, source the environment script:"
        echo "  source ${ORADBA_BASE}/bin/oraenv.sh [ORACLE_SID]"
        echo ""
        echo "For help:"
        echo "  ${ORADBA_BASE}/bin/oraenv.sh --help"
        echo "  source ${ORADBA_BASE}/bin/oraenv.sh && alih"
        echo ""
        echo "Check configuration:"
        echo "  ${ORADBA_BASE}/bin/oradba_setup.sh show-config"
    fi
    echo ""
    exit 0
else
    echo -e "${RED}✗ OraDBA installation has issues!${NC}"
    echo ""
    echo "Please check the failed items above. You may need to:"
    echo "  1. Reinstall OraDBA"
    echo "  2. Check file permissions"
    echo "  3. Verify installation directory"
    echo ""
    if [[ "$PRE_ORACLE_MODE" == "true" ]]; then
        echo "Note: Pre-Oracle installation mode is normal before Oracle is installed."
        echo "      Oracle-specific issues will be addressed after Oracle installation."
        echo ""
    fi
    echo "For support, see: ${ORADBA_BASE}/README.md"
    exit 1
fi
