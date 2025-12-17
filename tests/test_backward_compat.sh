#!/usr/bin/env bash
# Test backward compatibility with existing .install_info format

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR=$(mktemp -d)

# Create an existing-style .install_info
cat > "${TEMP_DIR}/.install_info" <<'EOF'
install_date=2025-12-17T00:15:58Z
install_version=0.6.0
install_method=installer
install_user=oracle
install_prefix=/opt/oracle/local/oradba
EOF

echo "Testing Backward Compatibility"
echo "==============================="
echo ""
echo "Existing .install_info file:"
cat "${TEMP_DIR}/.install_info"
echo ""

# Source common.sh with temp directory
ORADBA_BASE="${TEMP_DIR}"
# shellcheck source=../src/lib/common.sh
source "${SCRIPT_DIR}/src/lib/common.sh"

echo "Reading with get_install_info():"
echo "  install_version: $(get_install_info "install_version")"
echo "  install_date: $(get_install_info "install_date")"
echo "  install_user: $(get_install_info "install_user")"
echo "  install_method: $(get_install_info "install_method")"
echo "  install_prefix: $(get_install_info "install_prefix")"
echo ""

# Test updating
echo "Testing update with set_install_info():"
set_install_info "last_update" "2025-12-17T09:00:00Z"
echo ""

echo "Updated .install_info file:"
cat "${TEMP_DIR}/.install_info"
echo ""

# Verify the update
LAST_UPDATE=$(get_install_info "last_update")
echo "Retrieved last_update: ${LAST_UPDATE}"

# Cleanup
rm -rf "${TEMP_DIR}"

if [[ "${LAST_UPDATE}" == "2025-12-17T09:00:00Z" ]]; then
    echo ""
    echo "✓ Backward compatibility test PASSED"
    exit 0
else
    echo ""
    echo "✗ Backward compatibility test FAILED"
    exit 1
fi
