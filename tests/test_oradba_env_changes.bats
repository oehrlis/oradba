#!/usr/bin/env bats
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# ---------------------------------------------------------------------------
# Unit tests for oradba_env_changes.sh
# Tests the configuration change detection functionality
# ---------------------------------------------------------------------------

# Setup and teardown
setup() {
    # Source the changes library
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    source "${ORADBA_BASE}/lib/oradba_env_changes.sh"
    
    # Create temporary test directory
    TEST_DIR="${BATS_TMPDIR}/test_changes_$$"
    mkdir -p "${TEST_DIR}"
    
    # Override cache directory for testing
    export ORADBA_CACHE_DIR="${TEST_DIR}/cache"
    mkdir -p "${ORADBA_CACHE_DIR}"
}

teardown() {
    # Cleanup test directory
    rm -rf "${TEST_DIR}"
}

# Test oradba_get_file_signature
@test "get_file_signature: should return signature for existing file" {
    echo "test content" > "${TEST_DIR}/test.txt"
    
    run oradba_get_file_signature "${TEST_DIR}/test.txt"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+:[0-9]+$ ]]
}

@test "get_file_signature: should fail for non-existent file" {
    run oradba_get_file_signature "${TEST_DIR}/nonexistent.txt"
    [ "$status" -eq 1 ]
}

@test "get_file_signature: signatures differ for different files" {
    echo "content1" > "${TEST_DIR}/file1.txt"
    sleep 1  # Ensure different timestamps
    echo "content2" > "${TEST_DIR}/file2.txt"
    
    local sig1 sig2
    sig1=$(oradba_get_file_signature "${TEST_DIR}/file1.txt")
    sig2=$(oradba_get_file_signature "${TEST_DIR}/file2.txt")
    
    [ "$sig1" != "$sig2" ]
}

# Test oradba_store_file_signature
@test "store_file_signature: should store signature" {
    echo "test content" > "${TEST_DIR}/test.txt"
    
    run oradba_store_file_signature "${TEST_DIR}/test.txt"
    [ "$status" -eq 0 ]
    
    # Check signature file was created
    [ -f "${ORADBA_CACHE_DIR}/test.txt.sig" ]
}

@test "store_file_signature: should fail for non-existent file" {
    run oradba_store_file_signature "${TEST_DIR}/nonexistent.txt"
    [ "$status" -eq 1 ]
}

@test "store_file_signature: should use custom signature file path" {
    echo "test content" > "${TEST_DIR}/test.txt"
    local custom_sig="${TEST_DIR}/custom.sig"
    
    oradba_store_file_signature "${TEST_DIR}/test.txt" "$custom_sig"
    
    [ -f "$custom_sig" ]
}

# Test oradba_check_file_changed
@test "check_file_changed: should detect new file" {
    echo "test content" > "${TEST_DIR}/test.txt"
    
    run oradba_check_file_changed "${TEST_DIR}/test.txt"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "New file detected" ]]
}

@test "check_file_changed: should not detect change if file unchanged" {
    echo "test content" > "${TEST_DIR}/test.txt"
    
    # First check stores signature
    oradba_check_file_changed "${TEST_DIR}/test.txt" >/dev/null || true
    
    # Second check should show no change
    run oradba_check_file_changed "${TEST_DIR}/test.txt"
    [ "$status" -eq 1 ]
}

@test "check_file_changed: should detect change when file modified" {
    echo "original content" > "${TEST_DIR}/test.txt"
    
    # Store initial signature
    oradba_check_file_changed "${TEST_DIR}/test.txt" >/dev/null || true
    
    # Modify file
    sleep 1  # Ensure timestamp changes
    echo "modified content" > "${TEST_DIR}/test.txt"
    
    # Should detect change
    run oradba_check_file_changed "${TEST_DIR}/test.txt"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "File changed" ]]
}

@test "check_file_changed: should fail for non-existent file" {
    run oradba_check_file_changed "${TEST_DIR}/nonexistent.txt"
    [ "$status" -eq 1 ]
}

# Test oradba_init_change_tracking
@test "init_change_tracking: should initialize tracking" {
    # Create some test config files
    mkdir -p "${ORADBA_BASE}/etc"
    echo "test" > "${ORADBA_BASE}/etc/oradba_homes.conf"
    echo "test" > "${ORADBA_BASE}/etc/oradba_core.conf"
    
    run oradba_init_change_tracking
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Initialized change tracking" ]]
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_homes.conf"
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
}

# Test oradba_clear_change_tracking
@test "clear_change_tracking: should clear tracking data" {
    # Create some signature files
    echo "sig1" > "${ORADBA_CACHE_DIR}/test1.sig"
    echo "sig2" > "${ORADBA_CACHE_DIR}/test2.sig"
    
    run oradba_clear_change_tracking
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Cleared change tracking" ]]
    
    # Verify signature files are gone
    [ ! -f "${ORADBA_CACHE_DIR}/test1.sig" ]
    [ ! -f "${ORADBA_CACHE_DIR}/test2.sig" ]
}

# Test oradba_check_config_changes
@test "check_config_changes: should detect no changes for non-existent files" {
    run oradba_check_config_changes
    [ "$status" -eq 1 ]
}

@test "check_config_changes: should detect changes in config files" {
    # Create config files
    mkdir -p "${ORADBA_BASE}/etc"
    echo "test" > "${ORADBA_BASE}/etc/oradba_core.conf"
    
    # First check stores signatures
    oradba_check_config_changes >/dev/null || true
    
    # Modify file
    sleep 1
    echo "modified" > "${ORADBA_BASE}/etc/oradba_core.conf"
    
    # Should detect change
    run oradba_check_config_changes
    [ "$status" -eq 0 ]
    [[ "$output" =~ oradba_core.conf ]]
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
}

# Integration tests
@test "integration: all change detection functions are exported" {
    # Verify functions are exported
    declare -F oradba_get_file_signature | grep -q "oradba_get_file_signature"
    declare -F oradba_store_file_signature | grep -q "oradba_store_file_signature"
    declare -F oradba_check_file_changed | grep -q "oradba_check_file_changed"
    declare -F oradba_check_config_changes | grep -q "oradba_check_config_changes"
    declare -F oradba_init_change_tracking | grep -q "oradba_init_change_tracking"
    declare -F oradba_clear_change_tracking | grep -q "oradba_clear_change_tracking"
}

# Test complete workflow
@test "integration: complete change detection workflow" {
    # Create test file
    echo "v1" > "${TEST_DIR}/config.txt"
    
    # Initialize tracking
    oradba_store_file_signature "${TEST_DIR}/config.txt"
    
    # No change yet
    run oradba_check_file_changed "${TEST_DIR}/config.txt"
    [ "$status" -eq 1 ]
    
    # Modify file
    sleep 1
    echo "v2" > "${TEST_DIR}/config.txt"
    
    # Should detect change
    run oradba_check_file_changed "${TEST_DIR}/config.txt"
    [ "$status" -eq 0 ]
    
    # After detection, signature is updated
    run oradba_check_file_changed "${TEST_DIR}/config.txt"
    [ "$status" -eq 1 ]
}
