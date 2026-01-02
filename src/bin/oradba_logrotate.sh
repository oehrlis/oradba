#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oradba_logrotate.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.22
# Version....: v0.9.0
# Purpose....: Manage logrotate configurations for OraDBA and Oracle Database
# Notes......: Installs, tests, and manages logrotate templates
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Set script defaults
set -o pipefail
set -o nounset

# Script information
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
readonly SCRIPT_NAME
readonly SCRIPT_VERSION="v0.9.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Default directories
readonly TEMPLATE_DIR="${SCRIPT_DIR}/../templates/logrotate"
readonly TARGET_DIR="/etc/logrotate.d"
readonly CUSTOM_DIR="${HOME}/.oradba/logrotate"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Usage information
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Manage logrotate configurations for OraDBA and Oracle Database logs.
Supports both system-wide (root) and user-mode (non-root) operation.

Options:
  ${BOLD}System-wide (requires root):${NC}
  -i, --install         Install logrotate configurations to ${TARGET_DIR}
  -u, --uninstall       Uninstall system-wide configurations
  -f, --force           Force rotation for testing

  ${BOLD}User-mode (non-root):${NC}
  --install-user        Set up user-specific logrotate configurations
  --run-user            Run logrotate with user-specific configurations
  --cron                Generate crontab entry for automated rotation

  ${BOLD}General:${NC}
  -l, --list            List installed configurations
  -t, --test            Test logrotate configurations (dry-run)
  -c, --customize       Generate customized configurations
  -v, --version         Show script version
  -h, --help            Show this help message

Examples:
  ${BOLD}System-wide installation (requires root):${NC}
  sudo ${SCRIPT_NAME} --install
  sudo ${SCRIPT_NAME} --force

  ${BOLD}User-mode operation (as oracle user):${NC}
  # Initial setup
  ${SCRIPT_NAME} --install-user

  # Run manually
  ${SCRIPT_NAME} --run-user

  # Add to crontab
  ${SCRIPT_NAME} --cron
  crontab -e  # Then paste the generated entry

  ${BOLD}Testing and customization:${NC}
  ${SCRIPT_NAME} --test
  ${SCRIPT_NAME} --list
  ${SCRIPT_NAME} --customize

EOF
}

# Print colored message
print_message() {
    local color="${1}"
    local message="${2}"
    echo -e "${color}${message}${NC}"
}

# Check if running as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        print_message "${RED}" "ERROR: Must run as root for this operation"
        print_message "${YELLOW}" "Try: sudo ${SCRIPT_NAME} ${1}"
        return 1
    fi
    return 0
}

# Install logrotate configurations
install_logrotate() {
    check_root "--install" || return 1
    
    if [[ ! -d "${TEMPLATE_DIR}" ]]; then
        print_message "${RED}" "ERROR: Template directory not found: ${TEMPLATE_DIR}"
        return 1
    fi
    
    if [[ ! -d "${TARGET_DIR}" ]]; then
        print_message "${RED}" "ERROR: Target directory not found: ${TARGET_DIR}"
        print_message "${YELLOW}" "Is logrotate installed?"
        return 1
    fi
    
    print_message "${GREEN}" "Installing logrotate configurations..."
    echo ""
    
    local installed=0
    local failed=0
    
    for template in "${TEMPLATE_DIR}"/*.logrotate; do
        if [[ ! -f "${template}" ]]; then
            continue
        fi
        
        local basename
        basename=$(basename "${template}" .logrotate)
        local target="${TARGET_DIR}/${basename}"
        
        # Backup existing config
        if [[ -f "${target}" ]]; then
            cp "${target}" "${target}.backup.$(date +%Y%m%d_%H%M%S)"
            print_message "${YELLOW}" "  ⚠ Backed up existing ${basename}"
        fi
        
        # Copy template
        if cp "${template}" "${target}"; then
            chmod 644 "${target}"
            chown root:root "${target}"
            print_message "${GREEN}" "  ✓ Installed ${basename}"
            ((installed++))
        else
            print_message "${RED}" "  ✗ Failed to install ${basename}"
            ((failed++))
        fi
    done
    
    echo ""
    print_message "${GREEN}" "Installation Summary:"
    echo "  Installed: ${installed}"
    if [[ ${failed} -gt 0 ]]; then
        echo "  Failed: ${failed}"
    fi
    
    echo ""
    print_message "${YELLOW}" "Next steps:"
    echo "  1. Review configurations: ls -l ${TARGET_DIR}/oracle*"
    echo "  2. Customize paths if needed"
    echo "  3. Test configurations: ${SCRIPT_NAME} --test"
    
    return 0
}

# Uninstall logrotate configurations
uninstall_logrotate() {
    check_root "--uninstall" || return 1
    
    print_message "${YELLOW}" "Uninstalling logrotate configurations..."
    echo ""
    
    local removed=0
    
    for config in "${TARGET_DIR}"/oradba* "${TARGET_DIR}"/oracle-*; do
        if [[ -f "${config}" ]]; then
            local basename
            basename=$(basename "${config}")
            if rm -f "${config}"; then
                print_message "${GREEN}" "  ✓ Removed ${basename}"
                ((removed++))
            else
                print_message "${RED}" "  ✗ Failed to remove ${basename}"
            fi
        fi
    done
    
    echo ""
    if [[ ${removed} -eq 0 ]]; then
        print_message "${YELLOW}" "No configurations found to remove"
    else
        print_message "${GREEN}" "Removed ${removed} configuration(s)"
    fi
    
    return 0
}

# List installed configurations
list_logrotate() {
    echo "Installed logrotate configurations:"
    echo ""
    
    local found=0
    
    for config in "${TARGET_DIR}"/oradba* "${TARGET_DIR}"/oracle-*; do
        if [[ -f "${config}" ]]; then
            ls -lh "${config}"
            ((found++))
        fi
    done
    
    echo ""
    if [[ ${found} -eq 0 ]]; then
        print_message "${YELLOW}" "No OraDBA logrotate configurations found"
        echo ""
        print_message "${YELLOW}" "Install configurations with: sudo ${SCRIPT_NAME} --install"
    else
        print_message "${GREEN}" "Found ${found} configuration(s)"
    fi
    
    return 0
}

# Test logrotate configurations
test_logrotate() {
    print_message "${GREEN}" "Testing logrotate configurations (dry-run)..."
    echo ""
    
    local found=0
    
    for config in "${TARGET_DIR}"/oradba* "${TARGET_DIR}"/oracle-*; do
        if [[ -f "${config}" ]]; then
            local basename
            basename=$(basename "${config}")
            print_message "${YELLOW}" "=== Testing ${basename} ==="
            logrotate -d "${config}" 2>&1 | tail -30
            echo ""
            ((found++))
        fi
    done
    
    if [[ ${found} -eq 0 ]]; then
        print_message "${YELLOW}" "No configurations found to test"
        print_message "${YELLOW}" "Install configurations with: sudo ${SCRIPT_NAME} --install"
        return 1
    fi
    
    return 0
}

# Force rotation for testing
force_logrotate() {
    check_root "--force" || return 1
    
    print_message "${YELLOW}" "WARNING: Forcing log rotation for testing"
    print_message "${YELLOW}" "This will rotate logs immediately!"
    echo ""
    read -p "Continue? (yes/no): " -r
    if [[ ! "${REPLY}" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted"
        return 1
    fi
    
    echo ""
    print_message "${GREEN}" "Forcing log rotation..."
    echo ""
    
    for config in "${TARGET_DIR}"/oradba* "${TARGET_DIR}"/oracle-*; do
        if [[ -f "${config}" ]]; then
            local basename
            basename=$(basename "${config}")
            print_message "${YELLOW}" "=== Rotating ${basename} ==="
            logrotate -f -v "${config}"
            echo ""
        fi
    done
    
    print_message "${GREEN}" "Forced rotation complete"
    return 0
}

# Generate customized configurations
customize_logrotate() {
    mkdir -p "${CUSTOM_DIR}"
    
    print_message "${GREEN}" "Generating customized logrotate configurations..."
    echo ""
    
    # Check if oratab exists
    local oratab="/etc/oratab"
    if [[ ! -f "${oratab}" ]]; then
        print_message "${YELLOW}" "WARNING: ${oratab} not found"
        print_message "${YELLOW}" "Cannot auto-detect databases"
        echo ""
    fi
    
    # Detect Oracle environment
    local oracle_base="${ORACLE_BASE:-/u01/app/oracle}"
    local oracle_home="${ORACLE_HOME:-}"
    
    print_message "${GREEN}" "Detected environment:"
    echo "  ORACLE_BASE: ${oracle_base}"
    echo "  ORACLE_HOME: ${oracle_home:-<not set>}"
    echo ""
    
    # Parse oratab if available
    if [[ -f "${oratab}" ]]; then
        print_message "${GREEN}" "Databases found in ${oratab}:"
        grep -v "^#" "${oratab}" | grep -v "^$" | cut -d: -f1 | while read -r sid; do
            echo "  - ${sid}"
        done
        echo ""
    fi
    
    # Generate customized alert log config
    local custom_alert="${CUSTOM_DIR}/oracle-alert-custom.logrotate"
    cat > "${custom_alert}" <<EOF
# Auto-generated Oracle Alert Log Configuration
# Generated: $(date)
# Environment: ${oracle_base}

# Oracle Database Alert Logs
# Customize paths based on your actual diagnostic_dest
${oracle_base}/diag/rdbms/*/*/trace/alert_*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    nocreate
    copytruncate
    size 100M
}
EOF
    
    print_message "${GREEN}" "✓ Created ${custom_alert}"
    
    # Generate customized trace config
    local custom_trace="${CUSTOM_DIR}/oracle-trace-custom.logrotate"
    cat > "${custom_trace}" <<EOF
# Auto-generated Oracle Trace Files Configuration
# Generated: $(date)
# Environment: ${oracle_base}

# Background process trace files
${oracle_base}/diag/rdbms/*/*/trace/*_ora_*.trc {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    nocreate
    maxage 30
    size 10M
}

# Trace metadata files
${oracle_base}/diag/rdbms/*/*/trace/*_ora_*.trm {
    weekly
    rotate 2
    compress
    missingok
    notifempty
    nocreate
    maxage 14
}
EOF
    
    print_message "${GREEN}" "✓ Created ${custom_trace}"
    
    echo ""
    print_message "${GREEN}" "Customized configurations created in:"
    echo "  ${CUSTOM_DIR}"
    echo ""
    print_message "${YELLOW}" "Next steps:"
    echo "  1. Review: ls -l ${CUSTOM_DIR}"
    echo "  2. Edit paths if needed: vi ${CUSTOM_DIR}/*.logrotate"
    echo "  3. Test: logrotate -d ${CUSTOM_DIR}/oracle-alert-custom.logrotate"
    echo "  4. Install: sudo cp ${CUSTOM_DIR}/*.logrotate ${TARGET_DIR}/"
    
    return 0
}

# Install user-mode configurations
install_user() {
    local user_state_dir="${CUSTOM_DIR}/state"
    
    mkdir -p "${CUSTOM_DIR}"
    mkdir -p "${user_state_dir}"
    
    print_message "${GREEN}" "Setting up user-mode logrotate..."
    echo ""
    
    # Check if logrotate is available
    if ! command -v logrotate &>/dev/null; then
        print_message "${RED}" "ERROR: logrotate command not found"
        print_message "${YELLOW}" "Please install logrotate package"
        return 1
    fi
    
    # Generate customized configurations for user
    print_message "${GREEN}" "Generating user-specific configurations..."
    echo ""
    
    # Detect Oracle environment
    local oracle_base="${ORACLE_BASE:-/u01/app/oracle}"
    local oracle_home="${ORACLE_HOME:-}"
    
    # Generate user-specific alert log config
    local user_alert="${CUSTOM_DIR}/oracle-alert.logrotate"
    cat > "${user_alert}" <<EOF
# User-specific Oracle Alert Log Configuration
# Generated: $(date)
# User: ${USER}
# Environment: ${oracle_base}

${oracle_base}/diag/rdbms/*/*/trace/alert_*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    nocreate
    copytruncate
    size 100M
}
EOF
    
    print_message "${GREEN}" "✓ Created ${user_alert}"
    
    # Generate user-specific trace config
    local user_trace="${CUSTOM_DIR}/oracle-trace.logrotate"
    cat > "${user_trace}" <<EOF
# User-specific Oracle Trace Files Configuration
# Generated: $(date)
# User: ${USER}
# Environment: ${oracle_base}

${oracle_base}/diag/rdbms/*/*/trace/*_ora_*.trc {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    nocreate
    maxage 30
    size 10M
}

${oracle_base}/diag/rdbms/*/*/trace/*_ora_*.trm {
    weekly
    rotate 2
    compress
    missingok
    notifempty
    nocreate
    maxage 14
}
EOF
    
    print_message "${GREEN}" "✓ Created ${user_trace}"
    
    # Generate user-specific listener log config
    local user_listener="${CUSTOM_DIR}/oracle-listener.logrotate"
    cat > "${user_listener}" <<EOF
# User-specific Oracle Listener Log Configuration
# Generated: $(date)
# User: ${USER}
# Environment: ${oracle_base}

${oracle_base}/diag/tnslsnr/*/listener/trace/listener.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    nocreate
    copytruncate
    size 100M
}

${oracle_base}/diag/tnslsnr/*/listener/alert/log.xml {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    nocreate
    copytruncate
    size 50M
}
EOF
    
    print_message "${GREEN}" "✓ Created ${user_listener}"
    
    echo ""
    print_message "${GREEN}" "User-mode setup complete!"
    echo ""
    echo "Configuration directory: ${CUSTOM_DIR}"
    echo "State directory:         ${user_state_dir}"
    echo ""
    print_message "${YELLOW}" "Next steps:"
    echo "  1. Review: ls -l ${CUSTOM_DIR}"
    echo "  2. Edit paths if needed: vi ${CUSTOM_DIR}/*.logrotate"
    echo "  3. Test: ${SCRIPT_NAME} --test"
    echo "  4. Run: ${SCRIPT_NAME} --run-user"
    echo "  5. Automate: ${SCRIPT_NAME} --cron"
    
    return 0
}

# Run user-mode logrotate
run_user() {
    local user_state_dir="${CUSTOM_DIR}/state"
    local state_file="${user_state_dir}/logrotate.status"
    
    # Check if user-mode is set up
    if [[ ! -d "${CUSTOM_DIR}" ]]; then
        print_message "${RED}" "ERROR: User-mode not initialized"
        print_message "${YELLOW}" "Run: ${SCRIPT_NAME} --install-user"
        return 1
    fi
    
    # Check if any config files exist
    local config_count=0
    for config in "${CUSTOM_DIR}"/oracle-*.logrotate; do
        [[ -f "${config}" ]] && ((config_count++))
    done
    
    if [[ ${config_count} -eq 0 ]]; then
        print_message "${RED}" "ERROR: No logrotate configurations found"
        print_message "${YELLOW}" "Run: ${SCRIPT_NAME} --install-user"
        return 1
    fi
    
    # Check if logrotate is available
    if ! command -v logrotate &>/dev/null; then
        print_message "${RED}" "ERROR: logrotate command not found"
        return 1
    fi
    
    # Ensure state directory exists
    mkdir -p "${user_state_dir}"
    
    print_message "${GREEN}" "Running logrotate as user: ${USER}"
    echo ""
    
    # Run logrotate for each configuration
    for config in "${CUSTOM_DIR}"/oracle-*.logrotate; do
        if [[ -f "${config}" ]]; then
            local basename
            basename=$(basename "${config}")
            print_message "${YELLOW}" "=== Processing ${basename} ==="
            
            # Run logrotate with user-specific state file
            if logrotate -v --state="${state_file}" "${config}"; then
                print_message "${GREEN}" "✓ ${basename} processed successfully"
            else
                print_message "${RED}" "✗ ${basename} failed"
            fi
            echo ""
        fi
    done
    
    print_message "${GREEN}" "User-mode rotation complete"
    echo "State file: ${state_file}"
    
    return 0
}

# Generate crontab entry
generate_cron() {
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    print_message "${GREEN}" "Crontab entry for automated log rotation:"
    echo ""
    echo "# OraDBA log rotation (runs daily at 2 AM)"
    echo "0 2 * * * ${script_path} --run-user >/dev/null 2>&1"
    echo ""
    print_message "${YELLOW}" "To add this to your crontab:"
    echo "  1. Run: crontab -e"
    echo "  2. Paste the line above"
    echo "  3. Save and exit"
    echo ""
    print_message "${YELLOW}" "To verify:"
    echo "  crontab -l | grep oradba_logrotate"
    
    return 0
}

# Show version
show_version() {
    echo "${SCRIPT_NAME} ${SCRIPT_VERSION}"
    echo "Part of OraDBA - Oracle Database Infrastructure and Security"
    return 0
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        usage
        return 1
    fi
    
    case "${1}" in
        -i|--install)
            install_logrotate
            ;;
        -u|--uninstall)
            uninstall_logrotate
            ;;
        -l|--list)
            list_logrotate
            ;;
        -t|--test)
            test_logrotate
            ;;
        -f|--force)
            force_logrotate
            ;;
        -c|--customize)
            customize_logrotate
            ;;
        --install-user)
            install_user
            ;;
        --run-user)
            run_user
            ;;
        --cron)
            generate_cron
            ;;
        -v|--version)
            show_version
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_message "${RED}" "ERROR: Unknown option: ${1}"
            echo ""
            usage
            return 1
            ;;
    esac
}

# Execute main function
main "$@"

# --- EOF ----------------------------------------------------------------------
