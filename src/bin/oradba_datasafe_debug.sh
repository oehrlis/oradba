#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_datasafe_debug.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2026.02.11
# Version....: 0.21.0
# Purpose....: Debug script for DataSafe status reporting issues
# Notes......: Generates comprehensive debug information for troubleshooting
# Usage......: ./oradba_datasafe_debug.sh [datasafe_base_path] [instance_name]
# Example....: ./oradba_datasafe_debug.sh /appl/oracle/product/exacc-wob-vwg-ha1 dscon1
# ------------------------------------------------------------------------------

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo "  $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine ORADBA_BASE
if [[ -n "${ORADBA_BASE}" ]]; then
    print_success "ORADBA_BASE is set: ${ORADBA_BASE}"
else
    # Try to derive from script location
    ORADBA_BASE="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    print_warning "ORADBA_BASE not set, using derived: ${ORADBA_BASE}"
fi

# Parse arguments
DATASAFE_BASE="${1:-}"
INSTANCE_NAME="${2:-}"

print_header "DataSafe Status Debugging Report"
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"

# ------------------------------------------------------------------------------
# SECTION 1: Environment Variables
# ------------------------------------------------------------------------------
print_header "1. Environment Variables"

print_info "ORADBA_BASE: ${ORADBA_BASE:-<not set>}"
print_info "ORACLE_BASE: ${ORACLE_BASE:-<not set>}"
print_info "ORACLE_HOME: ${ORACLE_HOME:-<not set>}"
print_info "PATH: ${PATH}"
print_info "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-<not set>}"

# ------------------------------------------------------------------------------
# SECTION 2: Plugin System Status
# ------------------------------------------------------------------------------
print_header "2. Plugin System Status"

# Check for datasafe plugin
echo "Checking datasafe plugin location:"

PLUGIN_FILE="${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
if [[ -f "${PLUGIN_FILE}" ]]; then
    print_success "Found: ${PLUGIN_FILE}"
    print_info "  Size: $(stat -f%z "${PLUGIN_FILE}" 2>/dev/null || stat -c%s "${PLUGIN_FILE}" 2>/dev/null) bytes"
    print_info "  Modified: $(stat -f%Sm "${PLUGIN_FILE}" 2>/dev/null || stat -c%y "${PLUGIN_FILE}" 2>/dev/null)"
else
    print_error "Not found: ${PLUGIN_FILE}"
    PLUGIN_FILE=""
fi

# Check if plugin can be sourced
if [[ -n "${PLUGIN_FILE}" ]]; then
    echo ""
    echo "Testing plugin loading:"
    if bash -c "source '${PLUGIN_FILE}' 2>/dev/null && declare -F plugin_check_status >/dev/null" ; then
        print_success "Plugin loads successfully"
    else
        print_error "Plugin failed to load or missing functions"
    fi
fi

# ------------------------------------------------------------------------------
# SECTION 3: Library Loading
# ------------------------------------------------------------------------------
print_header "3. OraDBA Libraries Status"

# Check for libraries
echo "Checking for OraDBA libraries:"

# Check oradba_common.sh
COMMON_LIB="${ORADBA_BASE}/lib/oradba_common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
    print_success "Found: oradba_common.sh"
    if bash -c "source '${COMMON_LIB}' 2>/dev/null"; then
        print_info "  Can be sourced successfully"
    else
        print_error "  Failed to source"
    fi
else
    print_error "Not found: ${COMMON_LIB}"
fi

# Check oradba_env_status.sh
STATUS_LIB="${ORADBA_BASE}/lib/oradba_env_status.sh"
if [[ -f "${STATUS_LIB}" ]]; then
    print_success "Found: oradba_env_status.sh"
    if bash -c "source '${STATUS_LIB}' 2>/dev/null"; then
        print_info "  Can be sourced successfully"
    else
        print_error "  Failed to source"
    fi
else
    print_error "Not found: ${STATUS_LIB}"
fi

# ------------------------------------------------------------------------------
# SECTION 4: DataSafe Installations Discovery
# ------------------------------------------------------------------------------
print_header "4. DataSafe Installations Discovery"

# Check oradba_homes.conf - try installed path first, then dev path
HOMES_CONF_PATHS=(
    "${ORADBA_BASE}/etc/oradba_homes.conf"
    "${ORADBA_BASE}/src/etc/oradba_homes.conf"
)

HOMES_CONF=""
for conf_path in "${HOMES_CONF_PATHS[@]}"; do
    if [[ -f "${conf_path}" ]]; then
        HOMES_CONF="${conf_path}"
        break
    fi
done

if [[ -n "${HOMES_CONF}" ]]; then
    print_success "Found oradba_homes.conf: ${HOMES_CONF}"
    echo ""
    echo "DataSafe entries in oradba_homes.conf:"
    if grep -E "^[^#]*:datasafe:" "${HOMES_CONF}" 2>/dev/null; then
        print_success "DataSafe entries found"
    else
        print_warning "No DataSafe entries found in oradba_homes.conf"
    fi
else
    print_error "oradba_homes.conf not found in any expected location"
fi

# Check for running cmctl processes
echo ""
echo "Running cmctl processes:"
# shellcheck disable=SC2009
if ps -ef | grep "[c]mctl" 2>/dev/null; then
    print_success "Found cmctl processes"
else
    print_warning "No cmctl processes found"
fi

# Check for cmadmin/cmgw processes
echo ""
echo "Running cmadmin/cmgw processes:"
# shellcheck disable=SC2009
if ps -ef | grep -E "[c]madmin|[c]mgw" 2>/dev/null; then
    print_success "Found DataSafe processes"
else
    print_warning "No cmadmin/cmgw processes found"
fi

# ------------------------------------------------------------------------------
# SECTION 5: Specific DataSafe Instance Testing
# ------------------------------------------------------------------------------
if [[ -n "${DATASAFE_BASE}" ]]; then
    print_header "5. Testing Specific DataSafe Instance"
    
    print_info "DataSafe Base Path: ${DATASAFE_BASE}"
    print_info "Instance Name: ${INSTANCE_NAME:-<not provided>}"
    
    # Check if base path exists
    if [[ -d "${DATASAFE_BASE}" ]]; then
        print_success "Base path exists"
    else
        print_error "Base path does not exist"
        exit 1
    fi
    
    # Check for oracle_cman_home
    CMAN_HOME="${DATASAFE_BASE}/oracle_cman_home"
    if [[ -d "${CMAN_HOME}" ]]; then
        print_success "oracle_cman_home exists: ${CMAN_HOME}"
    else
        print_error "oracle_cman_home not found"
        CMAN_HOME="${DATASAFE_BASE}"
        print_warning "Using base path as cman_home: ${CMAN_HOME}"
    fi
    
    # Check for cmctl
    CMCTL="${CMAN_HOME}/bin/cmctl"
    if [[ -x "${CMCTL}" ]]; then
        print_success "cmctl is executable: ${CMCTL}"
    else
        print_error "cmctl not found or not executable: ${CMCTL}"
    fi
    
    # Check for required directories
    echo ""
    echo "Required directories:"
    for dir in "bin" "lib" "network/admin"; do
        if [[ -d "${CMAN_HOME}/${dir}" ]]; then
            print_success "${dir}/ exists"
        else
            print_error "${dir}/ not found"
        fi
    done
    
    # Check for cman.ora
    CMAN_CONF="${CMAN_HOME}/network/admin/cman.ora"
    echo ""
    if [[ -f "${CMAN_CONF}" ]]; then
        print_success "cman.ora exists: ${CMAN_CONF}"
        echo ""
        echo "cman.ora content:"
        cat "${CMAN_CONF}"
        
        # Try to extract instance name
        echo ""
        echo "Extracting instance name from cman.ora:"
        EXTRACTED_INSTANCE=$(grep -E '^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=[[:space:]]*\(' "${CMAN_CONF}" 2>/dev/null | head -1 | cut -d'=' -f1 | tr -d ' ' || echo "")
        if [[ -n "${EXTRACTED_INSTANCE}" ]]; then
            print_success "Extracted instance name: ${EXTRACTED_INSTANCE}"
            if [[ -z "${INSTANCE_NAME}" ]]; then
                INSTANCE_NAME="${EXTRACTED_INSTANCE}"
                print_info "Using extracted instance name for testing"
            fi
        else
            print_warning "Could not extract instance name, using default: cust_cman"
            INSTANCE_NAME="${INSTANCE_NAME:-cust_cman}"
        fi
    else
        print_error "cman.ora not found: ${CMAN_CONF}"
    fi
    
    # Test cmctl commands
    if [[ -x "${CMCTL}" ]]; then
        echo ""
        print_header "6. Testing cmctl Commands"
        
        # Set environment for cmctl
        export ORACLE_HOME="${CMAN_HOME}"
        export LD_LIBRARY_PATH="${CMAN_HOME}/lib:${LD_LIBRARY_PATH:-}"
        
        # Test: cmctl show version
        echo ""
        echo "Command: cmctl show version -c ${INSTANCE_NAME}"
        if output=$("${CMCTL}" show version -c "${INSTANCE_NAME}" 2>&1); then
            print_success "cmctl show version succeeded"
            echo "${output}"
        else
            print_error "cmctl show version failed"
            echo "${output}"
        fi
        
        # Test: cmctl show services
        echo ""
        echo "Command: cmctl show services -c ${INSTANCE_NAME}"
        if output=$("${CMCTL}" show services -c "${INSTANCE_NAME}" 2>&1); then
            print_success "cmctl show services succeeded"
            echo "${output}"
            
            # Check for READY status
            if echo "${output}" | grep -qiE "READY|running|started"; then
                print_success "Service appears to be RUNNING (found READY/running/started)"
            elif echo "${output}" | grep -qiE "not running|stopped|TNS-"; then
                print_warning "Service appears to be STOPPED"
            else
                print_warning "Status is unclear from output"
            fi
        else
            print_error "cmctl show services failed"
            echo "${output}"
        fi
    fi
    
    # Test plugin functions directly
    print_header "7. Testing Plugin Functions Directly"
    
    # Detect plugin file location
    PLUGIN_FILE="${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
    if [[ ! -f "${PLUGIN_FILE}" ]]; then
        PLUGIN_FILE=""
    fi
    
    if [[ -n "${PLUGIN_FILE}" ]]; then
        # Create minimal oradba_log stub
        oradba_log() {
            local level="$1"
            shift
            echo "[${level}] $*" >&2
        }
        
        echo "Sourcing plugin: ${PLUGIN_FILE}"
        # shellcheck disable=SC1090
        if source "${PLUGIN_FILE}" 2>/dev/null; then
            print_success "Plugin sourced successfully"
            
            # Test plugin_check_status
            echo ""
            echo "Testing: plugin_check_status '${DATASAFE_BASE}' '${INSTANCE_NAME}'"
            plugin_check_status "${DATASAFE_BASE}" "${INSTANCE_NAME}" >/dev/null 2>&1
            exit_code=$?
            case ${exit_code} in
                0)
                    print_success "plugin_check_status returned: 0 (running/available)"
                    ;;
                1)
                    print_success "plugin_check_status returned: 1 (stopped/N/A)"
                    ;;
                2)
                    print_error "plugin_check_status returned: 2 (unavailable/error)"
                    ;;
                *)
                    print_error "plugin_check_status returned unexpected code: ${exit_code}"
                    ;;
            esac
            echo "Note: plugin_check_status communicates status via exit code only (no output)"
            
            # Test plugin_validate_home
            echo ""
            echo "Testing: plugin_validate_home '${DATASAFE_BASE}'"
            if plugin_validate_home "${DATASAFE_BASE}"; then
                print_success "plugin_validate_home succeeded"
            else
                print_error "plugin_validate_home failed"
            fi
            
            # Test plugin_adjust_environment
            echo ""
            echo "Testing: plugin_adjust_environment '${DATASAFE_BASE}'"
            adjusted=$(plugin_adjust_environment "${DATASAFE_BASE}")
            print_info "Adjusted ORACLE_HOME: ${adjusted}"
            
        else
            print_error "Failed to source plugin"
        fi
    fi
    
    # Test OraDBA functions
    print_header "8. Testing OraDBA Functions"
    
    # Source required libraries - try installed path first, then dev path
    if [[ -f "${ORADBA_BASE}/lib/oradba_common.sh" ]]; then
        # shellcheck disable=SC1091
        source "${ORADBA_BASE}/lib/oradba_common.sh" 2>/dev/null || true
    fi
    
    if [[ -f "${ORADBA_BASE}/lib/oradba_env_status.sh" ]]; then
        # shellcheck disable=SC1091
        source "${ORADBA_BASE}/lib/oradba_env_status.sh" 2>/dev/null || true
    fi
    
    # Test oradba_check_datasafe_status
    if declare -F oradba_check_datasafe_status >/dev/null 2>&1; then
        echo ""
        echo "Testing: oradba_check_datasafe_status '${DATASAFE_BASE}' '${INSTANCE_NAME}'"
        if status_output=$(oradba_check_datasafe_status "${DATASAFE_BASE}" "${INSTANCE_NAME}" 2>&1); then
            print_success "oradba_check_datasafe_status returned: ${status_output}"
        else
            print_error "oradba_check_datasafe_status failed"
            echo "Output: ${status_output}"
        fi
    else
        print_warning "oradba_check_datasafe_status function not available"
    fi
    
    # Test oradba_get_product_status
    if declare -F oradba_get_product_status >/dev/null 2>&1; then
        echo ""
        echo "Testing: oradba_get_product_status 'datasafe' '${INSTANCE_NAME}' '${DATASAFE_BASE}'"
        if status_output=$(oradba_get_product_status "datasafe" "${INSTANCE_NAME}" "${DATASAFE_BASE}" 2>&1); then
            print_success "oradba_get_product_status returned: ${status_output}"
        else
            print_error "oradba_get_product_status failed"
            echo "Output: ${status_output}"
        fi
    else
        print_warning "oradba_get_product_status function not available"
    fi
fi

# ------------------------------------------------------------------------------
# SECTION 9: Summary and Recommendations
# ------------------------------------------------------------------------------
print_header "9. Summary and Recommendations"

echo "Debug report complete. Review the sections above for any errors or warnings."
echo ""
echo "Common issues and solutions:"
echo "  1. Plugin not found:"
echo "     - Ensure ORADBA_BASE is set correctly"
echo "     - Check that datasafe_plugin.sh exists in lib/plugins/"
echo ""
echo "  2. cmctl commands fail:"
echo "     - Verify ORACLE_HOME points to oracle_cman_home"
echo "     - Check LD_LIBRARY_PATH includes oracle_cman_home/lib"
echo "     - Ensure instance name in cman.ora is correct"
echo ""
echo "  3. Status detection issues:"
echo "     - plugin_check_status returns exit codes: 0=running, 1=stopped, 2=unavailable"
echo "     - Check that instance_name parameter is being passed"
echo "     - Verify cmctl can connect to the service"
echo "     - Check for TNS errors in cmctl output"
echo ""
echo "  4. Plugin functions fail:"
echo "     - Review plugin_check_status exit code handling"
echo "     - Ensure regex patterns match actual cmctl output"
echo "     - Check process-based detection fallback"
echo ""

print_header "End of Debug Report"
