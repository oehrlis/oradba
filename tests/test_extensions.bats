#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_extensions.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.02
# Revision...: 0.12.0
# Purpose....: BATS tests for extension system (lib/extensions.sh)
# Notes......: Tests extension discovery, loading, metadata parsing, and priority
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

setup() {
    # Load test helpers
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source common library
    source "${PROJECT_ROOT}/src/lib/common.sh"
    
    # Source extensions library
    source "${PROJECT_ROOT}/src/lib/extensions.sh"
    
    # Create temporary test directory
    TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/oradba_ext_test"
    mkdir -p "${TEST_TEMP_DIR}"
    
    # Set up test environment
    export ORADBA_LOCAL_BASE="${TEST_TEMP_DIR}"
    export ORADBA_AUTO_DISCOVER_EXTENSIONS="true"
    export ORADBA_EXTENSION_PATHS=""
    export DEBUG=0
}

teardown() {
    # Clean up temporary directory
    rm -rf "${TEST_TEMP_DIR}"
    
    # Unset test variables
    unset ORADBA_LOCAL_BASE
    unset ORADBA_AUTO_DISCOVER_EXTENSIONS
    unset ORADBA_EXTENSION_PATHS
}

# ==============================================================================
# Extension Discovery Tests
# ==============================================================================

@test "discover_extensions finds extension with .extension file" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/test_ext1"
    echo "name: test_ext1" > "${TEST_TEMP_DIR}/test_ext1/.extension"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find the extension
    [[ "${result}" == *"test_ext1"* ]]
}

@test "discover_extensions finds extension with bin directory" {
    # Create extension without metadata but with bin/
    mkdir -p "${TEST_TEMP_DIR}/test_ext2/bin"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find the extension
    [[ "${result}" == *"test_ext2"* ]]
}

@test "discover_extensions skips oradba directory" {
    # Create oradba directory (should be skipped)
    mkdir -p "${TEST_TEMP_DIR}/oradba/bin"
    echo "name: oradba" > "${TEST_TEMP_DIR}/oradba/.extension"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should NOT find oradba
    [[ "${result}" != *"oradba"* ]]
}

@test "discover_extensions returns empty when only oradba directory exists (bug #53)" {
    # Create only oradba directory (should be skipped)
    mkdir -p "${TEST_TEMP_DIR}/oradba"
    
    # Discover - should return empty string
    local result
    result=$(discover_extensions)
    
    # Result should be completely empty
    [[ -z "${result}" ]]
    
    # When converted to array, should have zero elements (not one empty element)
    local extensions
    mapfile -t extensions < <(discover_extensions)
    [[ ${#extensions[@]} -eq 0 ]]
}

@test "get_all_extensions returns empty when no extensions exist (bug #53)" {
    # Create only oradba directory
    mkdir -p "${TEST_TEMP_DIR}/oradba"
    
    # Get all extensions - should return empty
    local result
    result=$(get_all_extensions)
    
    # Result should be completely empty
    [[ -z "${result}" ]]
    
    # When converted to array, should have zero elements
    local extensions
    mapfile -t extensions < <(get_all_extensions)
    [[ ${#extensions[@]} -eq 0 ]]
}

@test "discover_extensions finds multiple extensions" {
    # Create multiple extensions
    mkdir -p "${TEST_TEMP_DIR}/ext1/bin"
    mkdir -p "${TEST_TEMP_DIR}/ext2/sql"
    mkdir -p "${TEST_TEMP_DIR}/ext3/rcv"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find all three
    [[ "${result}" == *"ext1"* ]]
    [[ "${result}" == *"ext2"* ]]
    [[ "${result}" == *"ext3"* ]]
}

@test "get_all_extensions combines discovered and manual paths" {
    # Create discovered extension
    mkdir -p "${TEST_TEMP_DIR}/auto_ext/bin"
    
    # Create manual extension
    mkdir -p "${TEST_TEMP_DIR}/manual_ext/bin"
    export ORADBA_EXTENSION_PATHS="${TEST_TEMP_DIR}/manual_ext"
    
    # Get all
    local result
    result=$(get_all_extensions)
    
    # Should find both
    [[ "${result}" == *"auto_ext"* ]]
    [[ "${result}" == *"manual_ext"* ]]
}

@test "get_all_extensions respects ORADBA_AUTO_DISCOVER_EXTENSIONS=false" {
    # Create discovered extension
    mkdir -p "${TEST_TEMP_DIR}/auto_ext/bin"
    
    # Disable auto-discovery
    export ORADBA_AUTO_DISCOVER_EXTENSIONS="false"
    
    # Get all
    local result
    result=$(get_all_extensions)
    
    # Should NOT find auto extension
    [[ "${result}" != *"auto_ext"* ]]
}

# ==============================================================================
# Metadata Parsing Tests
# ==============================================================================

@test "parse_extension_metadata reads name field" {
    # Create metadata file
    local meta_file="${TEST_TEMP_DIR}/test.extension"
    cat > "${meta_file}" << 'EOF'
name: test_extension
version: 1.0.0
EOF
    
    # Parse
    local result
    result=$(parse_extension_metadata "${meta_file}" "name")
    
    [[ "${result}" == "test_extension" ]]
}

@test "parse_extension_metadata reads version field" {
    # Create metadata file
    local meta_file="${TEST_TEMP_DIR}/test.extension"
    cat > "${meta_file}" << 'EOF'
name: test_extension
version: 2.5.1
EOF
    
    # Parse
    local result
    result=$(parse_extension_metadata "${meta_file}" "version")
    
    [[ "${result}" == "2.5.1" ]]
}

@test "parse_extension_metadata handles spaces in values" {
    # Create metadata file
    local meta_file="${TEST_TEMP_DIR}/test.extension"
    cat > "${meta_file}" << 'EOF'
description: This is a test description
EOF
    
    # Parse
    local result
    result=$(parse_extension_metadata "${meta_file}" "description")
    
    [[ "${result}" == "This is a test description" ]]
}

@test "get_extension_name returns name from metadata" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
name: custom_name
EOF
    
    # Get name
    local result
    result=$(get_extension_name "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "custom_name" ]]
}

@test "get_extension_name falls back to directory name" {
    # Create extension without metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Get name (should use directory name)
    local result
    result=$(get_extension_name "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "myext" ]]
}

@test "get_extension_version returns version from metadata" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
version: 3.2.1
EOF
    
    # Get version
    local result
    result=$(get_extension_version "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "3.2.1" ]]
}

@test "get_extension_version returns unknown if no metadata" {
    # Create extension without metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Get version
    local result
    result=$(get_extension_version "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "unknown" ]]
}

# ==============================================================================
# Priority and Enable/Disable Tests
# ==============================================================================

@test "get_extension_priority returns default 50" {
    # Create extension without priority
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Get priority
    local result
    result=$(get_extension_priority "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "50" ]]
}

@test "get_extension_priority reads from metadata" {
    # Create extension with priority
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
priority: 10
EOF
    
    # Get priority
    local result
    result=$(get_extension_priority "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "10" ]]
}

@test "get_extension_priority respects config override" {
    # Create extension with priority in metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
priority: 10
EOF
    
    # Override via config
    export ORADBA_EXT_MYEXT_PRIORITY="5"
    
    # Get priority (should use config)
    local result
    result=$(get_extension_priority "${TEST_TEMP_DIR}/myext")
    
    [[ "${result}" == "5" ]]
    
    unset ORADBA_EXT_MYEXT_PRIORITY
}

@test "is_extension_enabled returns true by default" {
    # Create extension
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Check enabled
    is_extension_enabled "myext" "${TEST_TEMP_DIR}/myext"
}

@test "is_extension_enabled reads from metadata" {
    # Create extension with enabled: false
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
enabled: false
EOF
    
    # Check enabled (should be false)
    run is_extension_enabled "myext" "${TEST_TEMP_DIR}/myext"
    [[ "$status" -ne 0 ]]
}

@test "is_extension_enabled respects config override" {
    # Create extension with enabled: true in metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
enabled: true
EOF
    
    # Override via config
    export ORADBA_EXT_MYEXT_ENABLED="false"
    
    # Check enabled (should use config)
    run is_extension_enabled "myext" "${TEST_TEMP_DIR}/myext"
    [[ "$status" -ne 0 ]]
    
    unset ORADBA_EXT_MYEXT_ENABLED
}

# ==============================================================================
# get_extension_property() Tests (v0.13.3)
# ==============================================================================

@test "get_extension_property function exists" {
    run type -t get_extension_property
    [ "$status" -eq 0 ]
    [ "$output" = "function" ]
}

@test "get_extension_property reads metadata property" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
name: test_extension
version: 1.2.3
custom_field: custom_value
EOF
    
    # Test reading various properties
    name=$(get_extension_property "${TEST_TEMP_DIR}/myext" "name")
    version=$(get_extension_property "${TEST_TEMP_DIR}/myext" "version")
    custom=$(get_extension_property "${TEST_TEMP_DIR}/myext" "custom_field")
    
    [[ "${name}" == "test_extension" ]]
    [[ "${version}" == "1.2.3" ]]
    [[ "${custom}" == "custom_value" ]]
}

@test "get_extension_property returns fallback for missing property" {
    # Create extension without metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Get property with fallback
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "nonexistent" "default_value")
    
    [[ "${result}" == "default_value" ]]
}

@test "get_extension_property returns empty for missing property without fallback" {
    # Create extension without metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    
    # Get property without fallback
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "nonexistent")
    
    [[ -z "${result}" ]]
}

@test "get_extension_property checks config override when requested" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
priority: 50
EOF
    
    # Set config override
    export ORADBA_EXT_MYEXT_PRIORITY="10"
    
    # Get priority with config check
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "priority" "50" "true")
    
    [[ "${result}" == "10" ]]
    
    unset ORADBA_EXT_MYEXT_PRIORITY
}

@test "get_extension_property ignores config override when not requested" {
    # Create extension with metadata
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
priority: 50
EOF
    
    # Set config override
    export ORADBA_EXT_MYEXT_PRIORITY="10"
    
    # Get priority without config check (should use metadata)
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "priority" "50" "false")
    
    [[ "${result}" == "50" ]]
    
    unset ORADBA_EXT_MYEXT_PRIORITY
}

@test "get_extension_property config override takes precedence over metadata" {
    # Create extension
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
custom: metadata_value
EOF
    
    # Set config
    export ORADBA_EXT_MYEXT_CUSTOM="config_value"
    
    # Should prefer config
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "custom" "" "true")
    
    [[ "${result}" == "config_value" ]]
    
    unset ORADBA_EXT_MYEXT_CUSTOM
}

@test "get_extension_property fallback works after config and metadata" {
    # Create extension without the property
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
name: test
EOF
    
    # Get missing property with fallback and config check
    result=$(get_extension_property "${TEST_TEMP_DIR}/myext" "missing" "fallback_value" "true")
    
    [[ "${result}" == "fallback_value" ]]
}

@test "migrated functions use get_extension_property internally" {
    # Verify by checking the functions call get_extension_property
    run grep -A 5 "^get_extension_name()" "${PROJECT_ROOT}/src/lib/extensions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "get_extension_property" ]]
    
    run grep -A 5 "^get_extension_version()" "${PROJECT_ROOT}/src/lib/extensions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "get_extension_property" ]]
    
    run grep -A 5 "^get_extension_priority()" "${PROJECT_ROOT}/src/lib/extensions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "get_extension_property" ]]
}

# ==============================================================================
# Priority Sorting Tests
# ==============================================================================

@test "sort_extensions_by_priority sorts correctly" {
    # Create extensions with different priorities
    mkdir -p "${TEST_TEMP_DIR}/ext_high"
    cat > "${TEST_TEMP_DIR}/ext_high/.extension" << 'EOF'
priority: 10
EOF
    
    mkdir -p "${TEST_TEMP_DIR}/ext_low"
    cat > "${TEST_TEMP_DIR}/ext_low/.extension" << 'EOF'
priority: 50
EOF
    
    mkdir -p "${TEST_TEMP_DIR}/ext_mid"
    cat > "${TEST_TEMP_DIR}/ext_mid/.extension" << 'EOF'
priority: 30
EOF
    
    # Sort
    local result
    result=$(sort_extensions_by_priority "${TEST_TEMP_DIR}/ext_low" "${TEST_TEMP_DIR}/ext_high" "${TEST_TEMP_DIR}/ext_mid")
    
    # Should be in reverse priority order: low (50), mid (30), high (10)
    # because extensions are prepended to PATH (last loaded = first in PATH)
    local first
    local last
    first=$(echo "${result}" | head -1)
    last=$(echo "${result}" | tail -1)
    
    [[ "${first}" == *"ext_low"* ]]
    [[ "${last}" == *"ext_high"* ]]
}

@test "sort_extensions_by_priority uses alphabetical for same priority" {
    # Create extensions with same priority
    mkdir -p "${TEST_TEMP_DIR}/zebra"
    mkdir -p "${TEST_TEMP_DIR}/alpha"
    
    # Sort
    local result
    result=$(sort_extensions_by_priority "${TEST_TEMP_DIR}/zebra" "${TEST_TEMP_DIR}/alpha")
    
    # Should be alphabetical: alpha, zebra
    local first
    local last
    first=$(echo "${result}" | head -1)
    last=$(echo "${result}" | tail -1)
    
    [[ "${first}" == *"alpha"* ]]
    [[ "${last}" == *"zebra"* ]]
}

# ==============================================================================
# Extension Loading Tests
# ==============================================================================

@test "load_extension adds bin to PATH" {
    # Create extension with bin/
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    echo "#!/bin/bash" > "${TEST_TEMP_DIR}/myext/bin/test_tool.sh"
    chmod +x "${TEST_TEMP_DIR}/myext/bin/test_tool.sh"
    
    # Save original PATH
    local orig_path="${PATH}"
    
    # Load extension
    load_extension "${TEST_TEMP_DIR}/myext"
    
    # PATH should include extension bin
    [[ "${PATH}" == *"myext/bin"* ]]
    
    # Restore PATH
    export PATH="${orig_path}"
}

@test "load_extension exports extension path variable" {
    # Create extension
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    
    # Load extension
    load_extension "${TEST_TEMP_DIR}/myext"
    
    # Should export ORADBA_EXT_MYEXT_PATH
    [[ -n "${ORADBA_EXT_MYEXT_PATH}" ]]
    [[ "${ORADBA_EXT_MYEXT_PATH}" == *"myext"* ]]
    
    unset ORADBA_EXT_MYEXT_PATH
}

@test "load_extension skips disabled extension" {
    # Create extension with enabled: false
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
enabled: false
EOF
    
    # Load extension
    load_extension "${TEST_TEMP_DIR}/myext"
    
    # Should NOT export path variable
    [[ -z "${ORADBA_EXT_MYEXT_PATH}" ]]
}

@test "load_extension handles non-existent directory" {
    # Try to load non-existent extension
    run load_extension "${TEST_TEMP_DIR}/nonexistent"
    
    # Should return error
    [[ "$status" -eq 1 ]]
}

# ==============================================================================
# Configuration Override Tests
# ==============================================================================

@test "configuration override disables extension" {
    # Create extension
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    
    # Disable via config
    export ORADBA_EXT_MYEXT_ENABLED="false"
    
    # Load extension
    load_extension "${TEST_TEMP_DIR}/myext"
    
    # Should NOT be loaded
    [[ -z "${ORADBA_EXT_MYEXT_PATH}" ]]
    
    unset ORADBA_EXT_MYEXT_ENABLED
}

@test "configuration override changes priority" {
    # Create extensions
    mkdir -p "${TEST_TEMP_DIR}/ext1"
    cat > "${TEST_TEMP_DIR}/ext1/.extension" << 'EOF'
priority: 50
EOF
    
    mkdir -p "${TEST_TEMP_DIR}/ext2"
    cat > "${TEST_TEMP_DIR}/ext2/.extension" << 'EOF'
priority: 10
EOF
    
    # Override ext1 priority to be higher (lower number)
    export ORADBA_EXT_EXT1_PRIORITY="5"
    
    # Sort
    local result
    result=$(sort_extensions_by_priority "${TEST_TEMP_DIR}/ext1" "${TEST_TEMP_DIR}/ext2")
    
    # ext1 should be last (priority 5 loads last, appears first in PATH)
    local last
    last=$(echo "${result}" | tail -1)
    [[ "${last}" == *"ext1"* ]]
    
    unset ORADBA_EXT_EXT1_PRIORITY
}

# ==============================================================================
# Validation Tests
# ==============================================================================

@test "validate_extension passes for valid extension with metadata" {
    # Create valid extension
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
name: myext
version: 1.0.0
description: Test extension
EOF
    
    # Validate
    run validate_extension "${TEST_TEMP_DIR}/myext"
    
    [[ "$status" -eq 0 ]]
}

@test "validate_extension warns about missing metadata" {
    # Create extension without metadata
    mkdir -p "${TEST_TEMP_DIR}/myext/bin"
    
    # Validate
    run validate_extension "${TEST_TEMP_DIR}/myext"
    
    [[ "$output" == *"Warning"* ]]
    [[ "$output" == *".extension"* ]]
}

@test "validate_extension warns about empty extension" {
    # Create extension with no content directories
    mkdir -p "${TEST_TEMP_DIR}/myext"
    cat > "${TEST_TEMP_DIR}/myext/.extension" << 'EOF'
name: myext
EOF
    
    # Validate
    run validate_extension "${TEST_TEMP_DIR}/myext"
    
    [[ "$output" == *"Warning"* ]]
    [[ "$output" == *"no content"* ]]
}

# ==============================================================================
# Integration Tests
# ==============================================================================

@test "full workflow: discover, sort, and load extensions" {
    # Create multiple extensions with different priorities
    mkdir -p "${TEST_TEMP_DIR}/ext_low/bin"
    cat > "${TEST_TEMP_DIR}/ext_low/.extension" << 'EOF'
priority: 50
EOF
    
    mkdir -p "${TEST_TEMP_DIR}/ext_high/bin"
    cat > "${TEST_TEMP_DIR}/ext_high/.extension" << 'EOF'
priority: 10
EOF
    
    # Save original PATH
    local orig_path="${PATH}"
    
    # Load all extensions
    load_extensions
    
    # PATH should include both extensions
    [[ "${PATH}" == *"ext_high"* ]]
    [[ "${PATH}" == *"ext_low"* ]]
    
    # Check that high priority (10) is before low priority (50) in PATH
    # Find positions using pattern matching
    local before_high="${PATH%%ext_high*}"
    local before_low="${PATH%%ext_low*}"
    
    # If ext_high is first, the string before it should be shorter
    [[ ${#before_high} -lt ${#before_low} ]]
    
    # Restore PATH
    export PATH="${orig_path}"
}

# EOF
