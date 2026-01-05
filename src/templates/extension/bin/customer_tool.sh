#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name.......: customer_tool.sh
# Purpose....: Example customer tool script
# Notes......: This script is automatically added to PATH when extension loads
# ------------------------------------------------------------------------------

echo "==================================="
echo "Customer Tool - Example Extension"
echo "==================================="
echo ""
echo "Extension: customer"
echo "Path:      ${ORADBA_EXT_CUSTOMER_PATH:-unknown}"
echo "Version:   1.0.0"
echo ""

# Example: Show Oracle environment
if [[ -n "${ORACLE_SID}" ]]; then
    echo "Current Oracle Environment:"
    echo "  ORACLE_SID:  ${ORACLE_SID}"
    echo "  ORACLE_HOME: ${ORACLE_HOME}"
    echo "  ORACLE_BASE: ${ORACLE_BASE}"
else
    echo "No Oracle environment set"
    echo "Run: source oraenv.sh <SID>"
fi

echo ""
echo "This is an example script demonstrating the extension system."
echo "Replace this with your own customer-specific tools."
