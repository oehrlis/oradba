#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # Modifications in BATS @test functions are isolated by design
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_installer.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.17
# Revision...: 0.7.3
# Purpose....: BATS tests for installer build script and installer functionality
# Notes......: Tests installer creation, VERSION validation, and installation modes.
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    BUILD_SCRIPT="${PROJECT_ROOT}/scripts/build_installer.sh"
    STANDALONE_INSTALLER="${PROJECT_ROOT}/src/bin/oradba_install.sh"
    
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_INSTALL_DIR="${TEST_TEMP_DIR}/oradba"
}

teardown() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Build Script Tests
# ============================================================================

@test "build_installer.sh exists and is executable" {
    [ -f "$BUILD_SCRIPT" ]
    [ -x "$BUILD_SCRIPT" ]
}

@test "VERSION file exists" {
    [ -f "${PROJECT_ROOT}/VERSION" ]
}

@test "VERSION file contains valid semantic version" {
    version=$(cat "${PROJECT_ROOT}/VERSION")
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# ============================================================================
# Standalone Installer Tests
# ============================================================================

@test "standalone installer exists" {
    [ -f "$STANDALONE_INSTALLER" ]
}

@test "standalone installer is executable" {
    [ -x "$STANDALONE_INSTALLER" ]
}

@test "standalone installer contains version placeholder" {
    grep -q "__VERSION__" "$STANDALONE_INSTALLER"
}

@test "standalone installer contains installation modes" {
    grep -q "INSTALL_MODE" "$STANDALONE_INSTALLER"
}

@test "standalone installer has payload marker" {
    grep -q "^__PAYLOAD_BEGINS__" "$STANDALONE_INSTALLER"
}

@test "standalone installer contains auto-detection logic" {
    grep -q "Auto-detect installation mode" "$STANDALONE_INSTALLER" || \
    grep -q 'INSTALL_MODE="auto"' "$STANDALONE_INSTALLER"
}

@test "standalone installer has embedded extraction function" {
    grep -q "extract_embedded_payload()" "$STANDALONE_INSTALLER"
}

@test "standalone installer has local extraction function" {
    grep -q "extract_local_tarball()" "$STANDALONE_INSTALLER"
}

@test "standalone installer has github extraction function" {
    grep -q "extract_github_release()" "$STANDALONE_INSTALLER"
}

@test "standalone installer has pre-flight checks" {
    grep -q "run_preflight_checks()" "$STANDALONE_INSTALLER"
}

@test "standalone installer has integrity verification" {
    grep -q "Verifying installation integrity" "$STANDALONE_INSTALLER"
}

# ============================================================================
# Build Process Tests
# ============================================================================

@test "build creates dist directory" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    [ -d "${PROJECT_ROOT}/dist" ]
}

@test "build creates build directory" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    [ -d "${PROJECT_ROOT}/build" ]
}

@test "build creates installer output" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]
}

@test "build creates tarball payload" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    version=$(cat VERSION)
    [ -f "${PROJECT_ROOT}/dist/oradba-${version}.tar.gz" ]
}

@test "built installer is executable" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    [ -x "${PROJECT_ROOT}/dist/oradba_install.sh" ]
}

@test "built installer contains injected version" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    version=$(cat VERSION)
    grep -q "INSTALLER_VERSION=\"${version}\"" "${PROJECT_ROOT}/dist/oradba_install.sh"
}

@test "built installer contains base64 payload" {
    cd "$PROJECT_ROOT"
    ./scripts/build_installer.sh >/dev/null 2>&1
    # Check for base64 content after payload marker
    awk '/^__PAYLOAD_BEGINS__/{flag=1;next}/^[^A-Za-z0-9+\/=]/{flag=0}flag' \
        "${PROJECT_ROOT}/dist/oradba_install.sh" | head -1 | grep -q "^[A-Za-z0-9+\/=]"
}

# ============================================================================
# Installation Tests (if built installer exists)
# ============================================================================

@test "installer help works" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --help | grep -q "Usage:"
    else
        skip "Built installer not found"
    fi
}

@test "installer version display works" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --show-version | grep -q "oradba installer version"
    else
        skip "Built installer not found"
    fi
}

@test "installer validates --local requires tarball argument" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Check validation exists in code
        grep -q 'log_error "--local requires' "${PROJECT_ROOT}/dist/oradba_install.sh"
    else
        skip "Built installer not found"
    fi
}

@test "installer validates --version requires --github" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        run bash -c "${PROJECT_ROOT}/dist/oradba_install.sh --version 1.0.0 2>&1 || true"
        [[ "$output" =~ "--version can only be used with --github" ]] || [[ "$output" =~ "Usage:" ]]
    else
        skip "Built installer not found"
    fi
}

@test "embedded mode installation works" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        [ -d "$TEST_INSTALL_DIR" ]
        [ -f "$TEST_INSTALL_DIR/bin/oradba_install.sh" ]
        [ -f "$TEST_INSTALL_DIR/.install_info" ]
    else
        skip "Built installer not found"
    fi
}

@test "local mode installation works" {
    cd "$PROJECT_ROOT"
    version=$(cat VERSION)
    tarball="${PROJECT_ROOT}/build/oradba-${version}.tar.gz"
    
    if [ -f "$tarball" ] && [ -f "$STANDALONE_INSTALLER" ]; then
        "$STANDALONE_INSTALLER" --no-update-profile --local "$tarball" --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        [ -d "$TEST_INSTALL_DIR" ]
        [ -f "$TEST_INSTALL_DIR/bin/oraenv.sh" ]
        [ -f "$TEST_INSTALL_DIR/.install_info" ]
    else
        skip "Tarball or standalone installer not found"
    fi
}

@test "installed oradba_install.sh is standalone" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        [ -f "$TEST_INSTALL_DIR/bin/oradba_install.sh" ]
        # Check it doesn't have embedded payload (smaller than built version)
        built_size=$(wc -c < "${PROJECT_ROOT}/dist/oradba_install.sh")
        installed_size=$(wc -c < "$TEST_INSTALL_DIR/bin/oradba_install.sh")
        [ "$installed_size" -lt "$built_size" ]
    else
        skip "Built installer not found"
    fi
}

@test "installation creates .install_info with metadata" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        [ -f "$TEST_INSTALL_DIR/.install_info" ]
        grep -q "install_date=" "$TEST_INSTALL_DIR/.install_info"
        grep -q "install_version=" "$TEST_INSTALL_DIR/.install_info"
        grep -q "install_method=" "$TEST_INSTALL_DIR/.install_info"
    else
        skip "Built installer not found"
    fi
}

@test "installation creates checksum file" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        [ -f "$TEST_INSTALL_DIR/.oradba.checksum" ]
        # Check checksum file has entries
        [ "$(grep -c '^[^#]' "$TEST_INSTALL_DIR/.oradba.checksum" || true)" -gt 0 ]
    else
        skip "Built installer not found"
    fi
}

@test "installation runs integrity verification" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        output=$("${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" 2>&1)
        echo "$output" | grep -q "Verifying installation integrity"
        echo "$output" | grep -q "Installation integrity verified"
    else
        skip "Built installer not found"
    fi
}

# ============================================================================
# Update Mode Tests
# ============================================================================

@test "installer has --update flag" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --help | grep -q "\--update"
    else
        skip "Built installer not found"
    fi
}

@test "installer has --force flag" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        "${PROJECT_ROOT}/dist/oradba_install.sh" --help | grep -q "\--force"
    else
        skip "Built installer not found"
    fi
}

@test "installer has version_compare function" {
    grep -q "version_compare()" "$STANDALONE_INSTALLER"
}

@test "installer has backup_installation function" {
    grep -q "backup_installation()" "$STANDALONE_INSTALLER"
}

@test "installer has restore_from_backup function" {
    grep -q "restore_from_backup()" "$STANDALONE_INSTALLER"
}

@test "installer has preserve_configs function" {
    grep -q "preserve_configs()" "$STANDALONE_INSTALLER"
}

@test "installer has perform_update function" {
    grep -q "perform_update()" "$STANDALONE_INSTALLER"
}

@test "update detects existing installation" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Try update
        output=$("${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --prefix "$TEST_INSTALL_DIR" 2>&1)
        echo "$output" | grep -q "Current version"
    else
        skip "Built installer not found"
    fi
}

@test "update skips when same version without force" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Try update without force
        output=$("${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --prefix "$TEST_INSTALL_DIR" 2>&1)
        echo "$output" | grep -q "Already running latest version"
    else
        skip "Built installer not found"
    fi
}

@test "update proceeds with --force flag" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Update with force
        output=$("${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --force --prefix "$TEST_INSTALL_DIR" 2>&1)
        echo "$output" | grep -q "Force update enabled"
        echo "$output" | grep -q "Creating backup"
    else
        skip "Built installer not found"
    fi
}

@test "update preserves configuration files" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Add custom config
        echo "test_setting=custom" >> "$TEST_INSTALL_DIR/etc/oradba.conf"
        
        # Update
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --force --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Check config preserved
        grep -q "test_setting=custom" "$TEST_INSTALL_DIR/etc/oradba.conf"
    else
        skip "Built installer not found"
    fi
}

@test "update removes backup on success" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        local install_parent
        install_parent="$(dirname "$TEST_INSTALL_DIR")"
        
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Update with force
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --force --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Check no backup directories remain
        [ "$(find "$install_parent" -type d -name "*.backup.*" 2>/dev/null | wc -l)" -eq 0 ]
    else
        skip "Built installer not found"
    fi
}

@test "update updates install_info metadata" {
    cd "$PROJECT_ROOT"
    if [ -f "${PROJECT_ROOT}/dist/oradba_install.sh" ]; then
        # Install first
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Update
        "${PROJECT_ROOT}/dist/oradba_install.sh" --no-update-profile --update --force --prefix "$TEST_INSTALL_DIR" >/dev/null 2>&1
        
        # Check install_method is "update"
        grep -q "install_method=update" "$TEST_INSTALL_DIR/.install_info"
    else
        skip "Built installer not found"
    fi
}

# ============================================================================
# Profile Integration Tests (Issue #24)
# ============================================================================

@test "installer help shows --update-profile flag" {
    [ -f "$STANDALONE_INSTALLER" ]
    bash "$STANDALONE_INSTALLER" --help 2>&1 | grep -q "update-profile"
}

@test "installer help shows --no-update-profile flag" {
    [ -f "$STANDALONE_INSTALLER" ]
    bash "$STANDALONE_INSTALLER" --help 2>&1 | grep -q "no-update-profile"
}

@test "detect_profile_file function exists" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "detect_profile_file()" "$STANDALONE_INSTALLER"
}

@test "profile_has_oradba function exists" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "profile_has_oradba()" "$STANDALONE_INSTALLER"
}

@test "update_profile function exists" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "update_profile()" "$STANDALONE_INSTALLER"
}

@test "profile detection prefers bash_profile" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that bash_profile is first priority in detect_profile_file
    grep -A 5 "detect_profile_file()" "$STANDALONE_INSTALLER" | grep -q "bash_profile"
}

@test "profile integration checks for duplicates" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Verify profile_has_oradba checks for existing integration
    grep -A 10 "profile_has_oradba()" "$STANDALONE_INSTALLER" | grep -q "OraDBA Environment Integration"
}

@test "profile integration sources oraenv.sh in silent mode" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that profile integration uses --silent flag
    grep -A 80 "update_profile()" "$STANDALONE_INSTALLER" | grep -q "oraenv.sh.*--silent"
}

@test "profile integration runs oraup on interactive shells" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that profile integration conditionally runs oraup for interactive shells
    grep -A 80 "update_profile()" "$STANDALONE_INSTALLER" | grep -q "oraup"
}

@test "installer code has --update-profile flag" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "\-\-update-profile" "$STANDALONE_INSTALLER"
}

@test "installer has --no-update-profile flag" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "\-\-no-update-profile" "$STANDALONE_INSTALLER"
}

@test "installer has UPDATE_PROFILE variable" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q 'UPDATE_PROFILE=' "$STANDALONE_INSTALLER"
}

@test "installer has detect_profile_file function" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "detect_profile_file()" "$STANDALONE_INSTALLER"
}

@test "installer has profile_has_oradba function" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "profile_has_oradba()" "$STANDALONE_INSTALLER"
}

@test "installer has update_profile function" {
    [ -f "$STANDALONE_INSTALLER" ]
    grep -q "update_profile()" "$STANDALONE_INSTALLER"
}

@test "profile file detection supports multiple shells" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check for bashrc, profile, and zshrc fallbacks
    grep -A 15 "detect_profile_file()" "$STANDALONE_INSTALLER" | grep -q "bashrc"
    grep -A 15 "detect_profile_file()" "$STANDALONE_INSTALLER" | grep -q "\.profile"
}

@test "profile integration creates backup before modification" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that backup is created
    grep -A 80 "update_profile()" "$STANDALONE_INSTALLER" | grep -q "\.backup\."
}

@test "profile integration uses silent mode for oraenv" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that --silent flag is used
    grep -q "oraenv.sh.*--silent" "$STANDALONE_INSTALLER"
}

@test "profile integration calls oraup for interactive shells" {
    [ -f "$STANDALONE_INSTALLER" ]
    # Check that oraup is called for interactive shells
    grep -q "if.*\$-.*\*i\*.*oraup" "$STANDALONE_INSTALLER"
}
