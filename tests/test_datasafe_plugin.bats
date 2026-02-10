#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_datasafe_plugin.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Unit tests for datasafe_plugin.sh (Data Safe Connector)
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_datasafe_$$"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/lib/plugins"
    mkdir -p "${TEST_DIR}/test_homes"
    
    # Set ORADBA_BASE for plugins
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    
    # Create minimal oradba_common.sh stub for logging
    cat > "${TEST_DIR}/lib/oradba_common.sh" <<'EOF'
oradba_log() {
    local level="$1"
    shift
    # Suppress debug logs in tests
    [[ "${level}" == "DEBUG" ]] && return 0
    echo "[${level}] $*" >&2
}
EOF
    
    # Source common functions
    source "${TEST_DIR}/lib/oradba_common.sh"
    
    # Copy plugin to test directory
    cp "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh" "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# DataSafe Plugin Tests
# ==============================================================================

@test "datasafe plugin loads successfully" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run type plugin_validate_home
    [ "$status" -eq 0 ]
    [[ "$output" == *"function"* ]]
}

@test "datasafe plugin has correct metadata" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    # shellcheck disable=SC2154
    [[ "${plugin_name}" == "datasafe" ]]
    # shellcheck disable=SC2154
    [[ "${plugin_version}" == "1.0.0" ]]
    [[ -n "${plugin_description}" ]]
}

@test "datasafe plugin validates datasafe home with oracle_cman_home" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${ds_home}"
    [ "$status" -eq 0 ]
}

@test "datasafe plugin rejects home without oracle_cman_home" {
    # Create mock home without oracle_cman_home
    local fake_home="${TEST_DIR}/test_homes/fake_ds"
    mkdir -p "${fake_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${fake_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin rejects home without cmctl" {
    # Create mock home with oracle_cman_home but no cmctl
    local incomplete_home="${TEST_DIR}/test_homes/incomplete_ds"
    mkdir -p "${incomplete_home}/oracle_cman_home/bin"
    mkdir -p "${incomplete_home}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${incomplete_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin rejects home without lib directory" {
    # Create mock home without lib
    local incomplete_home="${TEST_DIR}/test_homes/nolib_ds"
    mkdir -p "${incomplete_home}/oracle_cman_home/bin"
    touch "${incomplete_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${incomplete_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "${incomplete_home}"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin adjusts environment to oracle_cman_home" {
    # Create mock DataSafe home
    local ds_base="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_base}/oracle_cman_home/bin"
    mkdir -p "${ds_base}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_adjust_environment "${ds_base}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ds_base}/oracle_cman_home" ]
}

@test "datasafe plugin adjust_environment handles already adjusted path" {
    # If path already points to oracle_cman_home
    local cman_home="${TEST_DIR}/test_homes/datasafe_conn1/oracle_cman_home"
    mkdir -p "${cman_home}/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_adjust_environment "${cman_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "${cman_home}" ]
}

@test "datasafe plugin check_status returns unavailable without cmctl" {
    local ds_home="${TEST_DIR}/test_homes/datasafe_nocmctl"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "datasafe plugin does not show listener" {
    # DataSafe connectors don't show listener status
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -ne 0 ]
}

@test "datasafe plugin discovers connector instance" {
    # DataSafe connectors return connector name as instance
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_discover_instances "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"datasafe_conn1"* ]]
}

@test "datasafe plugin does not support aliases" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_supports_aliases
    [ "$status" -ne 0 ]
}

@test "datasafe plugin gets metadata" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    touch "${ds_home}/oracle_cman_home/bin/cmctl"
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_metadata "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"type=datasafe_connector"* ]]
}

@test "datasafe plugin has adjusted paths helper" {
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_adjusted_paths "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PATH="* ]]
    [[ "$output" == *"LD_LIBRARY_PATH="* ]]
}

@test "datasafe plugin handles non-existent directory" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_validate_home "/nonexistent/path"
    [ "$status" -ne 0 ]
}

@test "datasafe plugin has all required interface functions" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    local required_functions=(
        "plugin_detect_installation"
        "plugin_validate_home"
        "plugin_adjust_environment"
        "plugin_build_base_path"
        "plugin_build_env"
        "plugin_build_bin_path"
        "plugin_build_lib_path"
        "plugin_check_status"
        "plugin_get_metadata"
        "plugin_get_version"
        "plugin_get_instance_list"
        "plugin_supports_aliases"
        "plugin_get_config_section"
        "plugin_should_show_listener"
        "plugin_check_listener_status"
        "plugin_discover_instances"
    )
    
    for func in "${required_functions[@]}"; do
        run type "${func}"
        [ "$status" -eq 0 ]
    done
}

@test "datasafe plugin has datasafe-specific functions" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # DataSafe-specific helper function
    run type plugin_get_adjusted_paths
    [ "$status" -eq 0 ]
}

@test "datasafe plugin detects running connector via cmadmin process" {
    # Create mock DataSafe home WITHOUT cmctl (so it falls back to process detection)
    local ds_home="${TEST_DIR}/test_homes/datasafe_proc_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create a non-executable cmctl or don't create it at all - ensures fallback to process check
    # We'll just not create cmctl, so it's not executable
    
    # Mock ps command to simulate running cmadmin process
    # Use absolute path that matches the base_path pattern
    cat > "${TEST_DIR}/ps" <<MOCK_PS_SCRIPT
#!/usr/bin/env bash
# Check if we're looking for -ef
if [[ "\$1" == "-ef" ]]; then
    echo "oracle 12345 ${ds_home}/oracle_cman_home/bin/cmadmin cust_cman"
fi
MOCK_PS_SCRIPT
    chmod +x "${TEST_DIR}/ps"
    
    # Temporarily override PATH to use our mock ps
    local OLD_PATH="${PATH}"
    export PATH="${TEST_DIR}:${PATH}"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    
    # Restore PATH
    export PATH="${OLD_PATH}"
    rm -f "${TEST_DIR}/ps"
    
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin detects running connector via cmgw process" {
    # Create mock DataSafe home WITHOUT cmctl (so it falls back to process detection)
    local ds_home="${TEST_DIR}/test_homes/datasafe_cmgw_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Don't create cmctl - ensures fallback to process check
    
    # Mock ps command to simulate running cmgw process
    cat > "${TEST_DIR}/ps" <<MOCK_PS_SCRIPT
#!/usr/bin/env bash
# Check if we're looking for -ef
if [[ "\$1" == "-ef" ]]; then
    echo "oracle 12346 ${ds_home}/oracle_cman_home/bin/cmgw cmgw0"
fi
MOCK_PS_SCRIPT
    chmod +x "${TEST_DIR}/ps"
    
    # Temporarily override PATH to use our mock ps
    local OLD_PATH="${PATH}"
    export PATH="${TEST_DIR}:${PATH}"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    
    # Cleanup
    export PATH="${OLD_PATH}"
    rm -f "${TEST_DIR}/ps"
    
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin uses setup.py when processes not found" {
    # Create mock DataSafe home with setup.py
    local ds_home="${TEST_DIR}/test_homes/datasafe_setup_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    # Create mock setup.py that returns "already started"
    cat > "${ds_home}/setup.py" <<'SETUP_PY'
#!/usr/bin/env python3
import sys
if "status" in sys.argv:
    print("Connector is already started")
    sys.exit(0)
SETUP_PY
    chmod +x "${ds_home}/setup.py"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin detects stopped connector via setup.py" {
    # Create mock DataSafe home with setup.py
    local ds_home="${TEST_DIR}/test_homes/datasafe_stopped_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    # Create mock setup.py that returns "not running"
    cat > "${ds_home}/setup.py" <<'SETUP_PY'
#!/usr/bin/env python3
import sys
if "status" in sys.argv:
    print("Connector is not running")
    sys.exit(0)
SETUP_PY
    chmod +x "${ds_home}/setup.py"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "datasafe plugin uses correct cmctl show services command" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_cmctl_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create mock cman.ora with instance name
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
cust_cman = (configuration=(address=(protocol=tcp)(host=localhost)(port=1521)))
CMAN_ORA
    
    # Create mock cmctl that verifies correct command
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
# Verify we receive "show services -c <instance>" not "show status"
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]] && [[ "$3" == "-c" ]] && [[ -n "$4" ]]; then
    echo "Services Summary..."
    echo "Instance: $4"
    echo "READY"
    exit 0
elif [[ "$1" == "show" ]] && [[ "$2" == "status" ]]; then
    echo "NL-00853: undefined command - use 'show services -c <instance>'"
    exit 1
else
    exit 1
fi
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin parses instance name from cman.ora" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_cman_ora_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with custom instance name
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
# Comment line
  my_custom_instance = (configuration=(address=(protocol=tcp)))
CMAN_ORA
    
    # Create mock cmctl that echoes the instance name it receives
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]] && [[ "$3" == "-c" ]]; then
    echo "Instance: $4"
    echo "Services Summary..."
    exit 0
fi
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin uses default instance name when cman.ora missing" {
    # Create mock DataSafe home without cman.ora
    local ds_home="${TEST_DIR}/test_homes/datasafe_no_cman_ora"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create mock cmctl that verifies default instance name "cust_cman"
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]] && [[ "$3" == "-c" ]] && [[ "$4" == "cust_cman" ]]; then
    echo "Services Summary for cust_cman"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_status "${ds_home}" ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin gets version from cmctl" {
    # Create mock DataSafe home with version detection
    local ds_home="${TEST_DIR}/test_homes/datasafe_version_test"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with instance name
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
cust_cman = (configuration=(address=(protocol=tcp)(host=localhost)(port=1521)))
CMAN_ORA
    
    # Create mock cmctl that returns version information
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "version" ]] && [[ "$3" == "-c" ]]; then
    echo "Oracle Connection Manager Version 23.4.0.0.0"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_version "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "23.4.0.0.0" ]
}

@test "datasafe plugin returns exit 2 when cmctl missing (no output)" {
    # Create mock DataSafe home without cmctl
    local ds_home="${TEST_DIR}/test_homes/datasafe_no_cmctl"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_version "${ds_home}"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

@test "datasafe plugin parses version from cmctl output" {
    # Create mock DataSafe home with different version format
    local ds_home="${TEST_DIR}/test_homes/datasafe_version_alt"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create mock cmctl with version in output
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "version" ]]; then
    echo "Connection Manager"
    echo "Version 19.21.0.0.0"
    echo "Additional info"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_version "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "19.21.0.0.0" ]
}

@test "datasafe plugin metadata includes version" {
    # Create mock DataSafe home with version
    local ds_home="${TEST_DIR}/test_homes/datasafe_metadata_version"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create mock cmctl
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "version" ]]; then
    echo "Oracle Connection Manager Version 21.9.0.0.0"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_metadata "${ds_home}"
    [ "$status" -eq 0 ]
    [[ "$output" == *"version=21.9.0.0.0"* ]]
    [[ "$output" == *"type=datasafe_connector"* ]]
}

@test "datasafe plugin handles version fallback without instance" {
    # Test fallback to 'cmctl version' without instance parameter
    local ds_home="${TEST_DIR}/test_homes/datasafe_version_fallback"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    
    # Create mock cmctl that doesn't support 'show version -c' but supports 'version'
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "version" ]]; then
    # Simulate no output for 'show version -c'
    exit 1
elif [[ "$1" == "version" ]]; then
    echo "Oracle Connection Manager Version 19.3.0.0.0"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_get_version "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "19.3.0.0.0" ]
}

@test "datasafe plugin accepts instance name parameter in check_status" {
    # Create mock DataSafe home with cmctl
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with instance name
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
test_instance = (configuration = (address = (protocol=tcp)(host=localhost)(port=1521)))
CMAN_ORA
    
    # Create mock cmctl that responds to show services
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]] && [[ "$3" == "-c" ]]; then
    echo "Services Summary..."
    echo "Instance test_instance: Status READY"
    exit 0
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Test with instance name
    run plugin_check_status "${ds_home}" "test_instance"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin extracts instance name from cman.ora" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn1"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with specific instance name
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
my_custom_cman = (
  configuration = (
    address = (protocol=tcp)(host=localhost)(port=1521)
  )
)
CMAN_ORA
    
    # Create mock cmctl
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]]; then
    if [[ "$4" == "my_custom_cman" ]]; then
        echo "Instance my_custom_cman: Status READY"
        exit 0
    else
        echo "TNS-12541: TNS:no listener"
        exit 1
    fi
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Plugin should extract instance name from cman.ora
    run plugin_check_status "${ds_home}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin correctly extracts instance name and ignores system variables like WALLET_LOCATION" {
    # Create mock DataSafe home
    local ds_home="${TEST_DIR}/test_homes/datasafe_conn_wallet"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    mkdir -p "${ds_home}/oracle_cman_home/lib"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with WALLET_LOCATION and other system variables before the instance name
    # This tests that the regex correctly identifies cust_cman and ignores system variables
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'CMAN_ORA'
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/path/to/wallet)))
SSL_VERSION = 0
SSL_CLIENT_AUTHENTICATION = TRUE
cust_cman=
    (configuration=
        (address=(protocol=tcp)(host=localhost)(port=1521))
    )
CMAN_ORA
    
    # Create mock cmctl that only responds to correct instance name
    cat > "${ds_home}/oracle_cman_home/bin/cmctl" <<'CMCTL_MOCK'
#!/usr/bin/env bash
if [[ "$1" == "show" ]] && [[ "$2" == "services" ]] && [[ "$3" == "-c" ]]; then
    if [[ "$4" == "cust_cman" ]]; then
        echo "Instance cust_cman: Status READY"
        echo "Services Summary..."
        exit 0
    elif [[ "$4" == "WALLET_LOCATION" ]]; then
        # Simulate error if WALLET_LOCATION is used as instance name
        echo "TNS-04005: Unable to resolve address for WALLET_LOCATION."
        exit 1
    else
        echo "TNS-12541: TNS:no listener"
        exit 1
    fi
fi
exit 1
CMCTL_MOCK
    chmod +x "${ds_home}/oracle_cman_home/bin/cmctl"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Plugin should extract "cust_cman" correctly, not "WALLET_LOCATION"
    run plugin_check_status "${ds_home}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ==============================================================================
# Builder Functions Tests (Plugin Interface v1.0.0)
# ==============================================================================

@test "datasafe plugin_build_base_path returns base path when given oracle_cman_home" {
    local cman_home="/opt/oracle/datasafe/oracle_cman_home"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_base_path "${cman_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/oracle/datasafe" ]
}

@test "datasafe plugin_build_base_path returns path unchanged when not oracle_cman_home" {
    local base_path="/opt/oracle/datasafe"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_base_path "${base_path}"
    [ "$status" -eq 0 ]
    [ "$output" = "${base_path}" ]
}

@test "datasafe plugin_build_bin_path returns oracle_cman_home/bin" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_build_path"
    mkdir -p "${ds_base}/oracle_cman_home/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_bin_path "${ds_base}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ds_base}/oracle_cman_home/bin" ]
}

@test "datasafe plugin_build_bin_path returns empty when bin directory missing" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_no_bin"
    mkdir -p "${ds_base}/oracle_cman_home"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_bin_path "${ds_base}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin_build_lib_path returns oracle_cman_home/lib" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_build_lib"
    mkdir -p "${ds_base}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_lib_path "${ds_base}"
    [ "$status" -eq 0 ]
    [ "$output" = "${ds_base}/oracle_cman_home/lib" ]
}

@test "datasafe plugin_build_lib_path returns empty when lib directory missing" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_no_lib"
    mkdir -p "${ds_base}/oracle_cman_home"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_lib_path "${ds_base}"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "datasafe plugin_build_env outputs complete environment" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_build_env"
    mkdir -p "${ds_base}/oracle_cman_home/bin"
    mkdir -p "${ds_base}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_env "${ds_base}"
    [ "$status" -eq 0 ]
    
    # Check required key=value pairs
    echo "$output" | grep -q "ORACLE_BASE_HOME=${ds_base}"
    echo "$output" | grep -q "ORACLE_HOME=${ds_base}/oracle_cman_home"
    echo "$output" | grep -q "PATH=${ds_base}/oracle_cman_home/bin"
    echo "$output" | grep -q "LD_LIBRARY_PATH=${ds_base}/oracle_cman_home/lib"
}

@test "datasafe plugin_build_env handles missing directories gracefully" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_incomplete_env"
    mkdir -p "${ds_base}/oracle_cman_home"
    # Don't create bin or lib directories
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_build_env "${ds_base}"
    [ "$status" -eq 0 ]
    
    # Should still output ORACLE_BASE_HOME and ORACLE_HOME
    echo "$output" | grep -q "ORACLE_BASE_HOME=${ds_base}"
    echo "$output" | grep -q "ORACLE_HOME=${ds_base}/oracle_cman_home"
    
    # PATH and LD_LIBRARY_PATH should not be present if dirs don't exist
    ! echo "$output" | grep -q "^PATH="
    ! echo "$output" | grep -q "^LD_LIBRARY_PATH="
}

@test "datasafe plugin_build_env with instance parameter (not used for DataSafe)" {
    local ds_base="${TEST_DIR}/test_homes/datasafe_env_instance"
    mkdir -p "${ds_base}/oracle_cman_home/bin"
    mkdir -p "${ds_base}/oracle_cman_home/lib"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    # DataSafe doesn't use instance parameter like databases do
    run plugin_build_env "${ds_base}" "ignored_instance"
    [ "$status" -eq 0 ]
    
    # Should not set ORACLE_SID
    ! echo "$output" | grep -q "ORACLE_SID="
}

# ==============================================================================
# Listener Visibility Tests (Category-Specific Functions)
# ==============================================================================

@test "datasafe plugin_should_show_listener returns 1 (don't show)" {
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_should_show_listener
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "datasafe plugin_check_listener_status returns 1 with no output" {
    local ds_home="${TEST_DIR}/test_homes/datasafe_listener"
    mkdir -p "${ds_home}/oracle_cman_home/bin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_listener_status "${ds_home}"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "datasafe plugin_check_listener_status never outputs sentinel strings" {
    # Per plugin-standards.md: No "ERR", "unknown", "N/A" on stdout
    local ds_home="${TEST_DIR}/test_homes/datasafe_listener_check"
    mkdir -p "${ds_home}/oracle_cman_home"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    run plugin_check_listener_status "${ds_home}"
    
    # Should return 1 (not applicable)
    [ "$status" -eq 1 ]
    
    # Should have no output (especially no sentinel strings)
    [ -z "$output" ]
    ! echo "$output" | grep -qiE "ERR|unknown|N/A"
}

# ==============================================================================
# plugin_set_environment Tests
# ==============================================================================

@test "datasafe plugin_set_environment sets TNS_ADMIN correctly" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_tns1"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Call plugin_set_environment (not via run, since we need exports)
    plugin_set_environment "${ds_home}"
    local exit_code=$?
    
    # Verify exit code
    [ "$exit_code" -eq 0 ]
    
    # Verify TNS_ADMIN is set to connector-specific path
    [ "${TNS_ADMIN}" = "${ds_home}/oracle_cman_home/network/admin" ]
}

@test "datasafe plugin_set_environment overrides inherited TNS_ADMIN" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_tns2"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Set TNS_ADMIN to a different value (simulating inheritance)
    export TNS_ADMIN="/some/other/path"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Call plugin_set_environment - should override (not via run)
    plugin_set_environment "${ds_home}"
    local exit_code=$?
    
    # Verify exit code
    [ "$exit_code" -eq 0 ]
    
    # Verify TNS_ADMIN was overridden
    [ "${TNS_ADMIN}" = "${ds_home}/oracle_cman_home/network/admin" ]
    [ "${TNS_ADMIN}" != "/some/other/path" ]
}

@test "datasafe plugin_set_environment sets DATASAFE_HOME" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_tns3"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Call plugin_set_environment (not via run)
    plugin_set_environment "${ds_home}"
    local exit_code=$?
    
    # Verify exit code
    [ "$exit_code" -eq 0 ]
    
    # Verify DATASAFE_HOME is set to base path
    [ "${DATASAFE_HOME}" = "${ds_home}" ]
}

@test "datasafe plugin_set_environment handles oracle_cman_home path correctly" {
    # Create mock DataSafe connector home
    local ds_home="${TEST_DIR}/test_homes/datasafe_tns4"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Call with oracle_cman_home path (should still work)
    plugin_set_environment "${ds_home}/oracle_cman_home"
    local exit_code=$?
    
    # Verify exit code
    [ "$exit_code" -eq 0 ]
    
    # TNS_ADMIN should point to network/admin under oracle_cman_home
    [[ "${TNS_ADMIN}" == *"/oracle_cman_home/network/admin" ]]
}

# ==============================================================================
# plugin_get_port Tests
# ==============================================================================

@test "datasafe plugin_get_port extracts port from cman.ora" {
    # Create mock DataSafe connector home with cman.ora
    local ds_home="${TEST_DIR}/test_homes/datasafe_port1"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with port configuration
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'EOF'
cust_cman =
  (configuration=
    (address=(protocol=TCPS)(host=localhost)(port=1561))
    (parameter_list=
      (max_freelist_buffers=256)
    )
  )
EOF
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    run plugin_get_port "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "1561" ]
}

@test "datasafe plugin_get_port extracts different port number" {
    # Create mock DataSafe connector home with cman.ora
    local ds_home="${TEST_DIR}/test_homes/datasafe_port2"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with different port
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'EOF'
cust_cman =
  (configuration=
    (address=(protocol=TCPS)(host=localhost)(port=1562))
  )
EOF
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    run plugin_get_port "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "1562" ]
}

@test "datasafe plugin_get_port returns 1 when cman.ora missing" {
    # Create mock DataSafe connector home WITHOUT cman.ora
    local ds_home="${TEST_DIR}/test_homes/datasafe_port_missing"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    run plugin_get_port "${ds_home}"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "datasafe plugin_get_port returns 1 when port not in cman.ora" {
    # Create mock DataSafe connector home with cman.ora without port
    local ds_home="${TEST_DIR}/test_homes/datasafe_port_noport"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora without port
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'EOF'
cust_cman =
  (configuration=
    (address=(protocol=TCPS)(host=localhost))
  )
EOF
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    run plugin_get_port "${ds_home}"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "datasafe plugin_get_port extracts first port when multiple addresses" {
    # Create mock DataSafe connector home with multiple addresses
    local ds_home="${TEST_DIR}/test_homes/datasafe_port_multi"
    mkdir -p "${ds_home}/oracle_cman_home/network/admin"
    
    # Create cman.ora with multiple addresses
    cat > "${ds_home}/oracle_cman_home/network/admin/cman.ora" <<'EOF'
cust_cman =
  (configuration=
    (address=(protocol=TCPS)(host=localhost)(port=1561))
    (address=(protocol=TCP)(host=localhost)(port=1562))
  )
EOF
    
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    run plugin_get_port "${ds_home}"
    [ "$status" -eq 0 ]
    [ "$output" = "1561" ]
}
