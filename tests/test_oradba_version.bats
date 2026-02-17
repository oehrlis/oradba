#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oradba_version.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.4.0
# Purpose....: BATS tests for oradba_version.sh utility
# Notes......: Tests version checking, integrity verification, and update checking
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Find project root
    if [[ -f "VERSION" ]]; then
        PROJECT_ROOT="$(pwd)"
    elif [[ -f "../VERSION" ]]; then
        PROJECT_ROOT="$(cd .. && pwd)"
    else
        skip "Cannot find project root"
    fi
    
    ORADBA_VERSION="${PROJECT_ROOT}/src/bin/oradba_version.sh"
    VERSION_FILE="${PROJECT_ROOT}/VERSION"
    
    # Skip if script doesn't exist
    [[ -f "$ORADBA_VERSION" ]] || skip "oradba_version.sh not found"
    
    # Create temporary test installation
    TEST_INSTALL_DIR="$(mktemp -d)"
    export ORADBA_BASE="$TEST_INSTALL_DIR"
}

# Cleanup after tests
teardown() {
    if [[ -n "$TEST_INSTALL_DIR" ]] && [[ -d "$TEST_INSTALL_DIR" ]]; then
        rm -rf "$TEST_INSTALL_DIR"
    fi
}

# ------------------------------------------------------------------------------
# Basic functionality tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh exists and is executable" {
    [[ -x "$ORADBA_VERSION" ]]
}

@test "oradba_version.sh --help shows usage" {
    run "$ORADBA_VERSION" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--check" ]]
    [[ "$output" =~ "--verify" ]]
    [[ "$output" =~ "--update-check" ]]
}

@test "oradba_version.sh with no args shows version info" {
    # Setup minimal test installation
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    
    run "$ORADBA_VERSION"
    [[ "$status" -eq 1 ]] # Expected to fail without checksum file
    [[ "$output" =~ "OraDBA Version Information" ]]
}

# ------------------------------------------------------------------------------
# Version checking tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh --check shows version from VERSION file" {
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    
    run "$ORADBA_VERSION" --check
    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    # Should match version pattern (e.g., 0.3.3, 0.4.0, 1.0.0-dev)
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?$ ]]
}

@test "oradba_version.sh --check fails without VERSION file" {
    run "$ORADBA_VERSION" --check
    [[ "$status" -eq 1 ]]
    [[ "$output" == "unknown" ]]
}

# ------------------------------------------------------------------------------
# Integrity verification tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh --verify fails without checksum file" {
    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "ERROR: Checksum file not found" ]]
}

@test "oradba_version.sh --verify succeeds with valid checksums" {
    # Create minimal test installation with checksums
    mkdir -p "$TEST_INSTALL_DIR/bin"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "test content" > "$TEST_INSTALL_DIR/bin/test.sh"
    
    # Generate checksum
    cd "$TEST_INSTALL_DIR" || return 1
    echo "# Test checksums" > .oradba.checksum
    sha256sum VERSION >> .oradba.checksum
    sha256sum bin/test.sh >> .oradba.checksum
    cd - > /dev/null || return 1
    
    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Installation integrity verified" ]]
}

@test "oradba_version.sh --verify detects modified files" {
    # Create test installation
    mkdir -p "$TEST_INSTALL_DIR/bin"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "original content" > "$TEST_INSTALL_DIR/bin/test.sh"
    
    # Generate checksum
    cd "$TEST_INSTALL_DIR" || return 1
    sha256sum bin/test.sh > .oradba.checksum
    
    # Modify file after checksum generation
    echo "modified content" > bin/test.sh
    cd - > /dev/null || return 1
    
    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "FAILED" ]]
}

@test "oradba_version.sh --verify shows clean output for modified files" {
    # Create test installation
    mkdir -p "$TEST_INSTALL_DIR/bin" "$TEST_INSTALL_DIR/etc"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "original" > "$TEST_INSTALL_DIR/bin/test.sh"
    echo "config" > "$TEST_INSTALL_DIR/etc/config.conf"
    
    # Generate checksums
    cd "$TEST_INSTALL_DIR" || return 1
    sha256sum bin/test.sh etc/config.conf > .oradba.checksum
    
    # Modify one file
    echo "modified" > bin/test.sh
    cd - > /dev/null || return 1
    
    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 1 ]]
    # Check for clean output format
    [[ "$output" =~ bin/test\.sh:\ MODIFIED ]]
    [[ "$output" =~ "Summary:" ]]
    [[ "$output" =~ "Modified files: 1" ]]
}

@test "oradba_version.sh --verify shows missing files correctly" {
    # Create test installation
    mkdir -p "$TEST_INSTALL_DIR/bin"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "content" > "$TEST_INSTALL_DIR/bin/test.sh"
    
    # Generate checksums
    cd "$TEST_INSTALL_DIR" || return 1
    sha256sum bin/test.sh > .oradba.checksum
    # Add a properly formatted checksum for a file that doesn't exist
    echo "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  bin/missing.sh" >> .oradba.checksum
    cd - > /dev/null || return 1
    
    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 1 ]]
    # Check for missing file in clean format
    [[ "$output" =~ bin/missing\.sh:\ MISSING ]]
    [[ "$output" =~ "Summary:" ]]
    [[ "$output" =~ "Missing files:" ]]
}

@test "oradba_version.sh --verify ignores runtime-managed template cache files" {
    # Create test installation with template cache files included in checksum
    mkdir -p "$TEST_INSTALL_DIR/templates/oradba_extension"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "v0.4.0" > "$TEST_INSTALL_DIR/templates/oradba_extension/.version"
    echo "template content" > "$TEST_INSTALL_DIR/templates/oradba_extension/extension-template.tar.gz"

    # Generate checksums then modify runtime-managed files
    cd "$TEST_INSTALL_DIR" || return 1
    sha256sum VERSION templates/oradba_extension/.version templates/oradba_extension/extension-template.tar.gz > .oradba.checksum
    echo "v0.4.1" > templates/oradba_extension/.version
    echo "new template content" > templates/oradba_extension/extension-template.tar.gz
    cd - > /dev/null || return 1

    run "$ORADBA_VERSION" --verify
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Installation integrity verified" ]]
    [[ "$output" != *"templates/oradba_extension/.version: MODIFIED"* ]]
    [[ "$output" != *"templates/oradba_extension/extension-template.tar.gz: MODIFIED"* ]]
}

# ------------------------------------------------------------------------------
# Update checking tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh --update-check queries GitHub" {
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    
    run "$ORADBA_VERSION" --update-check
    # Status can be 0 (up to date), 1 (error), or 2 (update available)
    [[ "$status" -ge 0 ]] && [[ "$status" -le 2 ]]
    
    # Should show version comparison (if network available)
    if [[ "$status" -ne 1 ]]; then
        [[ "$output" =~ "Current version:" ]]
        [[ "$output" =~ "Latest version:" ]]
    fi
}

@test "oradba_version.sh --update-check handles network errors gracefully" {
    skip "Network error test requires mocking - tested manually"
}

# ------------------------------------------------------------------------------
# Info command tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh --info shows comprehensive information" {
    # Create complete test installation
    mkdir -p "$TEST_INSTALL_DIR/bin"
    cp "$VERSION_FILE" "$TEST_INSTALL_DIR/"
    echo "test" > "$TEST_INSTALL_DIR/bin/test.sh"
    
    # Create install info
    cat > "$TEST_INSTALL_DIR/.install_info" <<EOF
install_date=2025-12-16T10:00:00Z
install_version=0.4.0
install_method=installer
install_user=testuser
EOF
    
    # Create checksum
    cd "$TEST_INSTALL_DIR" || return 1
    sha256sum VERSION bin/test.sh > .oradba.checksum
    cd - > /dev/null || return 1
    
    run "$ORADBA_VERSION" --info
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "OraDBA Version Information" ]]
    [[ "$output" =~ "Version:" ]]
    [[ "$output" =~ "Install Path:" ]]
    [[ "$output" =~ "Installation Details:" ]]
    [[ "$output" =~ "Installation integrity verified" ]]
}

# ------------------------------------------------------------------------------
# Error handling tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh rejects invalid options" {
    run "$ORADBA_VERSION" --invalid-option
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Unknown option" ]]
}

@test "oradba_version.sh handles missing ORADBA_BASE gracefully" {
    unset ORADBA_BASE
    
    # Should detect base from script location
    run "$ORADBA_VERSION" --check
    # Will fail due to missing VERSION, but shouldn't crash
    [[ "$status" -eq 1 ]]
}

# ------------------------------------------------------------------------------
# Integration tests
# ------------------------------------------------------------------------------

@test "oradba_version.sh works from symlink" {
    skip "Symlink test requires actual installation"
}

@test "oradba_version.sh verifies actual installation" {
    skip "Requires full installation to test"
}
