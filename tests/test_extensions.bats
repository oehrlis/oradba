#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_extensions.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.02.11
# Revision...: 0.21.0
# Purpose....: BATS tests for extension system (lib/extensions.sh)
# Notes......: Tests extension discovery, loading, metadata parsing, and priority
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315

setup() {
    # Load test helpers
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    ORADBA_SRC_BASE="${PROJECT_ROOT}/src"
    
    # Save original PATH and SQLPATH to restore in teardown
    ORIGINAL_TEST_PATH="${PATH}"
    ORIGINAL_TEST_SQLPATH="${SQLPATH:-}"
    
    # Source common library
    # shellcheck source=../src/lib/oradba_common.sh
    source "${ORADBA_SRC_BASE}/lib/oradba_common.sh"
    
    # Source extensions library
    # shellcheck source=../src/lib/extensions.sh
    source "${ORADBA_SRC_BASE}/lib/extensions.sh"
    
    # Source helper functions from oradba_extension.sh for validation tests
    # Extract only the validate_extension_structure function
    # shellcheck disable=SC1090
    source <(sed -n '/^validate_extension_structure()/,/^}/p' "${ORADBA_SRC_BASE}/bin/oradba_extension.sh")
    
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
    # Restore original PATH and SQLPATH before cleanup
    export PATH="${ORIGINAL_TEST_PATH}"
    export SQLPATH="${ORIGINAL_TEST_SQLPATH}"
    
    # Clean up temporary directory
    rm -rf "${TEST_TEMP_DIR}"
    
    # Unset test variables
    unset ORADBA_LOCAL_BASE
    unset ORADBA_AUTO_DISCOVER_EXTENSIONS
    unset ORADBA_EXTENSION_PATHS
    unset ORIGINAL_TEST_PATH
    unset ORIGINAL_TEST_SQLPATH
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

@test "discover_extensions finds extension with content directories (no .extension marker)" {
    # Create directory without .extension marker but with bin/
    mkdir -p "${TEST_TEMP_DIR}/test_ext2/bin"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find the extension (with bin/ directory)
    [[ "${result}" == *"test_ext2"* ]]
}

@test "discover_extensions finds extension with sql directory only" {
    # Create directory with only sql/ directory (no .extension)
    mkdir -p "${TEST_TEMP_DIR}/test_sql_ext/sql"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find the extension with sql/ directory
    [[ "${result}" == *"test_sql_ext"* ]]
}

@test "discover_extensions finds extension with rcv directory only" {
    # Create directory with only rcv/ directory (no .extension)
    mkdir -p "${TEST_TEMP_DIR}/test_rcv_ext/rcv"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find the extension with rcv/ directory
    [[ "${result}" == *"test_rcv_ext"* ]]
}

@test "discover_extensions skips directory with no .extension and no content dirs" {
    # Create directory without .extension and without content directories
    mkdir -p "${TEST_TEMP_DIR}/test_empty_ext/doc"
    mkdir -p "${TEST_TEMP_DIR}/test_empty_ext/templates"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should NOT find this extension (no .extension, no bin/sql/rcv)
    [[ "${result}" != *"test_empty_ext"* ]]
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
    # Create multiple extensions with .extension marker files
    mkdir -p "${TEST_TEMP_DIR}/ext1/bin"
    touch "${TEST_TEMP_DIR}/ext1/.extension"
    mkdir -p "${TEST_TEMP_DIR}/ext2/sql"
    touch "${TEST_TEMP_DIR}/ext2/.extension"
    mkdir -p "${TEST_TEMP_DIR}/ext3/rcv"
    touch "${TEST_TEMP_DIR}/ext3/.extension"
    
    # Discover
    local result
    result=$(discover_extensions)
    
    # Should find all three
    [[ "${result}" == *"ext1"* ]]
    [[ "${result}" == *"ext2"* ]]
    [[ "${result}" == *"ext3"* ]]
}

@test "get_all_extensions combines discovered and manual paths" {
    # Create discovered extension with .extension marker
    mkdir -p "${TEST_TEMP_DIR}/auto_ext/bin"
    touch "${TEST_TEMP_DIR}/auto_ext/.extension"
    
    # Create manual extension (manual extensions in ORADBA_EXTENSION_PATHS don't require .extension marker)
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
    run grep -A 5 "^get_extension_name()" "${ORADBA_SRC_BASE}/lib/extensions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "get_extension_property" ]]
    
    run grep -A 5 "^get_extension_version()" "${ORADBA_SRC_BASE}/lib/extensions.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "get_extension_property" ]]
    
    run grep -A 5 "^get_extension_priority()" "${ORADBA_SRC_BASE}/lib/extensions.sh"
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

# ==============================================================================
# oradba_extension.sh Command Tests
# ==============================================================================

@test "oradba_extension.sh create requires extension name" {
    # Run without name
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Extension name is required"* ]]
}

@test "oradba_extension.sh create validates extension name format" {
    # Invalid: starts with number
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create 123invalid --path "${TEST_TEMP_DIR}"
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"must start with a letter"* ]]
    
    # Invalid: contains spaces
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create "bad name" --path "${TEST_TEMP_DIR}"
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"can only contain"* ]]
    
    # Invalid: special characters
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create "bad@name" --path "${TEST_TEMP_DIR}"
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"can only contain"* ]]
}

@test "oradba_extension.sh create accepts valid extension names" {
    # Valid names (will fail due to missing template, but name validation passes)
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create myext --path "${TEST_TEMP_DIR}"
    [[ "$output" != *"can only contain"* ]]
    [[ "$output" != *"must start with a letter"* ]]
    
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create my_ext --path "${TEST_TEMP_DIR}"
    [[ "$output" != *"can only contain"* ]]
    [[ "$output" != *"must start with a letter"* ]]
    
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create my-ext-123 --path "${TEST_TEMP_DIR}"
    [[ "$output" != *"can only contain"* ]]
    [[ "$output" != *"must start with a letter"* ]]
}

@test "oradba_extension.sh create fails if extension already exists" {
    # Create existing extension
    mkdir -p "${TEST_TEMP_DIR}/existing"
    
    # Try to create again
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create existing --path "${TEST_TEMP_DIR}"
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"already exists"* ]]
}

@test "oradba_extension.sh create fails if target directory does not exist" {
    # Try to create in non-existent directory
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create myext --path "/nonexistent/path"
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "oradba_extension.sh create requires ORADBA_LOCAL_BASE if --path not specified" {
    # Unset ORADBA_LOCAL_BASE
    local orig_base="${ORADBA_LOCAL_BASE}"
    export ORADBA_LOCAL_BASE=""
    
    # Try to create without --path
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create myext
    
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"not set"* ]]
    
    # Restore
    export ORADBA_LOCAL_BASE="${orig_base}"
}

@test "validate_extension_name function accepts valid names" {
    # Source the script functions
    source "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    
    # Valid names
    run validate_extension_name "myext"
    [[ "$status" -eq 0 ]]
    
    run validate_extension_name "my_ext"
    [[ "$status" -eq 0 ]]
    
    run validate_extension_name "my-ext-123"
    [[ "$status" -eq 0 ]]
    
    run validate_extension_name "MyExt123"
    [[ "$status" -eq 0 ]]
}

@test "validate_extension_name function rejects invalid names" {
    # Source the script functions
    source "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    
    # Empty name
    run validate_extension_name ""
    [[ "$status" -eq 1 ]]
    
    # Starts with number
    run validate_extension_name "123ext"
    [[ "$status" -eq 1 ]]
    
    # Contains spaces
    run validate_extension_name "my ext"
    [[ "$status" -eq 1 ]]
    
    # Contains special characters
    run validate_extension_name "my@ext"
    [[ "$status" -eq 1 ]]
    
    # Starts with dash
    run validate_extension_name "-myext"
    [[ "$status" -eq 1 ]]
}

# ==============================================================================
# Integration test for create command (with mock template)
# ==============================================================================

@test "oradba_extension.sh create with custom template creates extension" {
    # Create a mock template tarball
    local template_dir="${TEST_TEMP_DIR}/template"
    mkdir -p "${template_dir}/customer/bin"
    mkdir -p "${template_dir}/customer/sql"
    cat > "${template_dir}/customer/.extension" << 'EOF'
name=customer
version=1.0.0
description=Template extension
EOF
    
    # Create tarball
    local template_file="${TEST_TEMP_DIR}/template.tar.gz"
    (cd "${template_dir}" && tar czf "${template_file}" customer)
    
    # Create extension
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create newext \
        --path "${TEST_TEMP_DIR}" \
        --template "${template_file}"
    
    echo "$output"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"created successfully"* ]]
    
    # Verify extension was created
    [[ -d "${TEST_TEMP_DIR}/newext" ]]
    [[ -d "${TEST_TEMP_DIR}/newext/bin" ]]
    [[ -d "${TEST_TEMP_DIR}/newext/sql" ]]
    [[ -f "${TEST_TEMP_DIR}/newext/.extension" ]]
    
    # Verify name was updated in metadata
    local metadata_content
    metadata_content=$(cat "${TEST_TEMP_DIR}/newext/.extension")
    [[ "${metadata_content}" == *"name: newext"* ]]
}

@test "oradba_extension.sh create shows next steps after creation" {
    # Create a mock template tarball
    local template_dir="${TEST_TEMP_DIR}/template"
    mkdir -p "${template_dir}/customer"
    cat > "${template_dir}/customer/.extension" << 'EOF'
name=customer
EOF
    
    local template_file="${TEST_TEMP_DIR}/template.tar.gz"
    (cd "${template_dir}" && tar czf "${template_file}" customer)
    
    # Create extension
    run "${PROJECT_ROOT}/src/bin/oradba_extension.sh" create myext \
        --path "${TEST_TEMP_DIR}" \
        --template "${template_file}"
    
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Next Steps"* ]]
    [[ "$output" == *"cd ${TEST_TEMP_DIR}/myext"* ]]
    [[ "$output" == *"source"* ]]
    [[ "$output" == *"oradba_extension.sh list"* ]]
}

# ==============================================================================
# PATH/SQLPATH Deduplication Tests
# ==============================================================================

@test "remove_extension_paths removes extension bin paths" {
    # Setup test extensions
    mkdir -p "${TEST_TEMP_DIR}/ext1/bin"
    mkdir -p "${TEST_TEMP_DIR}/ext2/bin"
    
    # Set PATH with extension paths
    export PATH="${TEST_TEMP_DIR}/ext1/bin:${TEST_TEMP_DIR}/ext2/bin:/usr/bin:/bin"
    
    # Remove extension paths
    remove_extension_paths
    
    # Extension paths should be removed
    [[ "${PATH}" != *"${TEST_TEMP_DIR}/ext1/bin"* ]]
    [[ "${PATH}" != *"${TEST_TEMP_DIR}/ext2/bin"* ]]
    # System paths should remain
    [[ "${PATH}" == *"/usr/bin"* ]]
    [[ "${PATH}" == *"/bin"* ]]
}

@test "remove_extension_paths removes extension sql paths from SQLPATH" {
    # Setup test extensions
    mkdir -p "${TEST_TEMP_DIR}/ext1/sql"
    mkdir -p "${TEST_TEMP_DIR}/ext2/sql"
    
    # Set SQLPATH with extension paths
    export SQLPATH="${TEST_TEMP_DIR}/ext1/sql:${TEST_TEMP_DIR}/ext2/sql:/opt/oracle/sql"
    
    # Remove extension paths
    remove_extension_paths
    
    # Extension paths should be removed
    [[ "${SQLPATH}" != *"${TEST_TEMP_DIR}/ext1/sql"* ]]
    [[ "${SQLPATH}" != *"${TEST_TEMP_DIR}/ext2/sql"* ]]
    # Other paths should remain
    [[ "${SQLPATH}" == *"/opt/oracle/sql"* ]]
}

@test "deduplicate_path removes duplicate PATH entries" {
    # Set PATH with duplicates
    export PATH="/usr/bin:/opt/bin:/usr/bin:/bin:/opt/bin"
    
    # Deduplicate
    deduplicate_path
    
    # Count occurrences of /usr/bin
    local count
    count=$(echo "${PATH}" | grep -o "/usr/bin" | wc -l | tr -d ' ')
    [[ "${count}" -eq 1 ]]
    
    # Count occurrences of /opt/bin
    count=$(echo "${PATH}" | grep -o "/opt/bin" | wc -l | tr -d ' ')
    [[ "${count}" -eq 1 ]]
}

@test "deduplicate_path keeps first occurrence" {
    # Set PATH with duplicates
    export PATH="/first:/second:/first:/third"
    
    # Deduplicate
    deduplicate_path
    
    # Should keep first occurrence
    [[ "${PATH}" == "/first:/second:/third" ]]
}

@test "deduplicate_sqlpath removes duplicate SQLPATH entries" {
    # Set SQLPATH with duplicates
    export SQLPATH="/opt/sql1:/opt/sql2:/opt/sql1:/opt/sql3"
    
    # Deduplicate
    deduplicate_sqlpath
    
    # Count occurrences of /opt/sql1
    local count
    count=$(echo "${SQLPATH}" | grep -o "/opt/sql1" | wc -l | tr -d ' ')
    [[ "${count}" -eq 1 ]]
}

@test "load_extensions saves original PATH on first run" {
    # Clear any existing saved PATH
    unset ORADBA_ORIGINAL_PATH
    
    # Set initial PATH
    export PATH="/usr/bin:/bin"
    
    # Load extensions (none exist, but should still save PATH)
    load_extensions
    
    # Original PATH should be saved
    [[ -n "${ORADBA_ORIGINAL_PATH}" ]]
    [[ "${ORADBA_ORIGINAL_PATH}" == "/usr/bin:/bin" ]]
}

@test "load_extensions prevents duplicate paths when called multiple times" {
    # Create extension
    mkdir -p "${TEST_TEMP_DIR}/test_dup/bin"
    echo "name: test_dup" > "${TEST_TEMP_DIR}/test_dup/.extension"
    echo "enabled: true" >> "${TEST_TEMP_DIR}/test_dup/.extension"
    
    # Set initial PATH
    export PATH="/usr/bin:/bin"
    
    # Load extensions multiple times
    load_extensions
    load_extensions
    load_extensions
    
    # Count occurrences of test_dup/bin
    local count
    count=$(echo "${PATH}" | grep -o "test_dup/bin" | wc -l | tr -d ' ')
    
    # Should only appear once
    [[ "${count}" -eq 1 ]]
}

@test "load_extensions excludes disabled extensions" {
    # Create enabled extension
    mkdir -p "${TEST_TEMP_DIR}/ext_enabled/bin"
    echo "name: ext_enabled" > "${TEST_TEMP_DIR}/ext_enabled/.extension"
    echo "enabled: true" >> "${TEST_TEMP_DIR}/ext_enabled/.extension"
    
    # Create disabled extension
    mkdir -p "${TEST_TEMP_DIR}/ext_disabled/bin"
    echo "name: ext_disabled" > "${TEST_TEMP_DIR}/ext_disabled/.extension"
    echo "enabled: false" >> "${TEST_TEMP_DIR}/ext_disabled/.extension"
    
    # Set initial PATH
    export PATH="/usr/bin:/bin"
    
    # Load extensions
    load_extensions
    
    # Enabled should be in PATH
    [[ "${PATH}" == *"ext_enabled/bin"* ]]
    
    # Disabled should NOT be in PATH
    [[ "${PATH}" != *"ext_disabled/bin"* ]]
}

@test "load_extensions removes disabled extension paths when re-sourced" {
    # Create extension initially enabled
    mkdir -p "${TEST_TEMP_DIR}/ext_toggle/bin"
    echo "name: ext_toggle" > "${TEST_TEMP_DIR}/ext_toggle/.extension"
    echo "enabled: true" >> "${TEST_TEMP_DIR}/ext_toggle/.extension"
    
    # Set initial PATH
    export PATH="/usr/bin:/bin"
    
    # Load extensions - should add ext_toggle
    load_extensions
    [[ "${PATH}" == *"ext_toggle/bin"* ]]
    
    # Disable the extension
    echo "enabled: false" > "${TEST_TEMP_DIR}/ext_toggle/.extension"
    
    # Load extensions again - should remove ext_toggle
    load_extensions
    [[ "${PATH}" != *"ext_toggle/bin"* ]]
}

# ==============================================================================
# Extension Add Command Tests (Validation)
# ==============================================================================

@test "validate_extension_structure accepts extension with .extension file" {
    mkdir -p "${TEST_TEMP_DIR}/valid_ext"
    echo "name: valid_ext" > "${TEST_TEMP_DIR}/valid_ext/.extension"
    
    run validate_extension_structure "${TEST_TEMP_DIR}/valid_ext"
    [[ "$status" -eq 0 ]]
}

@test "validate_extension_structure accepts extension with bin directory" {
    mkdir -p "${TEST_TEMP_DIR}/valid_ext2/bin"
    
    run validate_extension_structure "${TEST_TEMP_DIR}/valid_ext2"
    [[ "$status" -eq 0 ]]
}

@test "validate_extension_structure accepts extension with sql directory" {
    mkdir -p "${TEST_TEMP_DIR}/valid_ext3/sql"
    
    run validate_extension_structure "${TEST_TEMP_DIR}/valid_ext3"
    [[ "$status" -eq 0 ]]
}

@test "validate_extension_structure rejects empty directory" {
    mkdir -p "${TEST_TEMP_DIR}/invalid_ext"
    
    run validate_extension_structure "${TEST_TEMP_DIR}/invalid_ext"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Invalid extension structure"* ]]
}

# ==============================================================================
# Hyphenated Extension Names Tests (Issue #1)
# ==============================================================================

@test "load_extension handles extension names with hyphens" {
    # Create extension with hyphenated name
    mkdir -p "${TEST_TEMP_DIR}/oci-cli/bin"
    cat > "${TEST_TEMP_DIR}/oci-cli/.extension" << 'EOF'
name: oci-cli
version: 1.0.0
priority: 50
enabled: true
EOF
    
    # Load extension
    load_extension "${TEST_TEMP_DIR}/oci-cli"
    
    # Should export sanitized variable names (hyphens replaced with underscores)
    [[ -n "${ORADBA_EXT_OCI_CLI_PATH}" ]]
    [[ "${ORADBA_EXT_OCI_CLI_PATH}" == *"oci-cli"* ]]
    
    # Should also export BASE variable with sanitized name
    [[ -n "${OCI_CLI_BASE}" ]]
    [[ "${OCI_CLI_BASE}" == *"oci-cli"* ]]
    
    # Clean up
    unset ORADBA_EXT_OCI_CLI_PATH
    unset OCI_CLI_BASE
}

@test "get_extension_property handles hyphenated names with config override" {
    # Create extension with hyphenated name
    mkdir -p "${TEST_TEMP_DIR}/my-ext/bin"
    cat > "${TEST_TEMP_DIR}/my-ext/.extension" << 'EOF'
name: my-ext
priority: 50
EOF
    
    # Set config override using sanitized name (hyphen -> underscore)
    export ORADBA_EXT_MY_EXT_PRIORITY="10"
    
    # Get priority with config check
    result=$(get_extension_priority "${TEST_TEMP_DIR}/my-ext")
    
    # Should use config override value
    [[ "${result}" == "10" ]]
    
    unset ORADBA_EXT_MY_EXT_PRIORITY
}

@test "is_extension_enabled handles hyphenated names with config override" {
    # Create extension with hyphenated name
    mkdir -p "${TEST_TEMP_DIR}/my-ext-test/bin"
    cat > "${TEST_TEMP_DIR}/my-ext-test/.extension" << 'EOF'
name: my-ext-test
enabled: true
EOF
    
    # Override via config using sanitized name
    export ORADBA_EXT_MY_EXT_TEST_ENABLED="false"
    
    # Check enabled (should use config)
    run is_extension_enabled "my-ext-test" "${TEST_TEMP_DIR}/my-ext-test"
    [[ "$status" -ne 0 ]]
    
    unset ORADBA_EXT_MY_EXT_TEST_ENABLED
}

@test "load_extensions works with multiple hyphenated extensions" {
    # Create multiple extensions with hyphens
    mkdir -p "${TEST_TEMP_DIR}/ext-one/bin"
    cat > "${TEST_TEMP_DIR}/ext-one/.extension" << 'EOF'
name: ext-one
priority: 10
EOF
    
    mkdir -p "${TEST_TEMP_DIR}/ext-two/bin"
    cat > "${TEST_TEMP_DIR}/ext-two/.extension" << 'EOF'
name: ext-two
priority: 50
EOF
    
    # Save original PATH
    local orig_path="${PATH}"
    
    # Load all extensions
    load_extensions
    
    # PATH should include both extensions
    [[ "${PATH}" == *"ext-one/bin"* ]]
    [[ "${PATH}" == *"ext-two/bin"* ]]
    
    # Should export sanitized variable names
    [[ -n "${ORADBA_EXT_EXT_ONE_PATH}" ]]
    [[ -n "${ORADBA_EXT_EXT_TWO_PATH}" ]]
    [[ -n "${EXT_ONE_BASE}" ]]
    [[ -n "${EXT_TWO_BASE}" ]]
    
    # Restore PATH
    export PATH="${orig_path}"
    unset ORADBA_EXT_EXT_ONE_PATH
    unset ORADBA_EXT_EXT_TWO_PATH
    unset EXT_ONE_BASE
    unset EXT_TWO_BASE
}

# ==============================================================================
# Enable/Disable Command Tests
# ==============================================================================

@test "cmd_enable enables a disabled extension" {
    # Source helper functions and cmd_enable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create disabled extension
    mkdir -p "${TEST_TEMP_DIR}/test_enable/bin"
    cat > "${TEST_TEMP_DIR}/test_enable/.extension" << 'EOF'
name: test_enable
enabled: false
EOF
    
    # Enable it
    run cmd_enable "test_enable"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"enabled successfully"* ]]
    
    # Verify enabled in metadata
    grep -q "^enabled: true" "${TEST_TEMP_DIR}/test_enable/.extension"
}

@test "cmd_enable reports if already enabled" {
    # Source helper functions and cmd_enable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create enabled extension
    mkdir -p "${TEST_TEMP_DIR}/test_already_enabled/bin"
    cat > "${TEST_TEMP_DIR}/test_already_enabled/.extension" << 'EOF'
name: test_already_enabled
enabled: true
EOF
    
    # Try to enable again
    run cmd_enable "test_already_enabled"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"already enabled"* ]]
}

@test "cmd_enable creates .extension file if missing" {
    # Source helper functions and cmd_enable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create extension without .extension file
    mkdir -p "${TEST_TEMP_DIR}/test_no_metadata/bin"
    
    # Enable it
    run cmd_enable "test_no_metadata"
    [[ "$status" -eq 0 ]]
    
    # Verify .extension file created with enabled: true
    [[ -f "${TEST_TEMP_DIR}/test_no_metadata/.extension" ]]
    grep -q "^enabled: true" "${TEST_TEMP_DIR}/test_no_metadata/.extension"
}

@test "cmd_disable disables an enabled extension" {
    # Source helper functions and cmd_disable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_disable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create enabled extension
    mkdir -p "${TEST_TEMP_DIR}/test_disable/bin"
    cat > "${TEST_TEMP_DIR}/test_disable/.extension" << 'EOF'
name: test_disable
enabled: true
EOF
    
    # Disable it
    run cmd_disable "test_disable"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"disabled successfully"* ]]
    
    # Verify disabled in metadata
    grep -q "^enabled: false" "${TEST_TEMP_DIR}/test_disable/.extension"
}

@test "cmd_disable reports if already disabled" {
    # Source helper functions and cmd_disable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_disable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create disabled extension
    mkdir -p "${TEST_TEMP_DIR}/test_already_disabled/bin"
    cat > "${TEST_TEMP_DIR}/test_already_disabled/.extension" << 'EOF'
name: test_already_disabled
enabled: false
EOF
    
    # Try to disable again
    run cmd_disable "test_already_disabled"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"already disabled"* ]]
}

@test "cmd_enable fails with no extension name" {
    # Source helper functions and cmd_enable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Try to enable without name
    run cmd_enable
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Extension name required"* ]]
}

@test "cmd_disable fails with no extension name" {
    # Source helper functions and cmd_disable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_disable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Try to disable without name
    run cmd_disable
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Extension name required"* ]]
}

@test "cmd_enable fails with non-existent extension" {
    # Source helper functions and cmd_enable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Try to enable non-existent extension
    run cmd_enable "nonexistent_ext"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"not found"* ]]
}

@test "cmd_disable fails with non-existent extension" {
    # Source helper functions and cmd_disable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_disable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Try to disable non-existent extension
    run cmd_disable "nonexistent_ext"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"not found"* ]]
}

@test "enable/disable integration: extension loads after enable" {
    # Source helper functions and cmd_enable/cmd_disable
    # shellcheck disable=SC1090
    source <(cat << 'EOFUNC'
log_debug() { :; }  # Stub
GREEN='\033[0;32m'
NC='\033[0m'
EOFUNC
    sed -n '/^cmd_enable()/,/^}/p; /^cmd_disable()/,/^}/p' "${PROJECT_ROOT}/src/bin/oradba_extension.sh"
    )
    
    # Create disabled extension
    mkdir -p "${TEST_TEMP_DIR}/test_integration/bin"
    cat > "${TEST_TEMP_DIR}/test_integration/.extension" << 'EOF'
name: test_integration
enabled: false
EOF
    
    # Initial state: should not load
    local orig_path="${PATH}"
    load_extensions
    [[ "${PATH}" != *"test_integration/bin"* ]]
    
    # Enable extension
    cmd_enable "test_integration" > /dev/null
    
    # Reload extensions - should now load
    export PATH="${orig_path}"
    load_extensions
    [[ "${PATH}" == *"test_integration/bin"* ]]
    
    # Verify environment variables are set
    [[ -n "${ORADBA_EXT_TEST_INTEGRATION_PATH}" ]]
    [[ -n "${TEST_INTEGRATION_BASE}" ]]
    
    # Cleanup
    export PATH="${orig_path}"
    unset ORADBA_EXT_TEST_INTEGRATION_PATH
    unset TEST_INTEGRATION_BASE
}

# ==============================================================================
# Extension Diagnostic Logging Tests (#194)
# ==============================================================================

@test "discover_extensions logs when ORADBA_LOCAL_BASE is empty" {
    # Set DEBUG logging
    export ORADBA_LOG_LEVEL="DEBUG"
    
    # Unset ORADBA_LOCAL_BASE
    unset ORADBA_LOCAL_BASE
    
    # Run discover_extensions and capture output
    local result
    result=$(discover_extensions 2>&1)
    
    # Should log that base directory is not configured
    [[ "${result}" == *"Extension base directory not configured"* ]] || \
    [[ "${result}" == *"ORADBA_LOCAL_BASE is empty"* ]]
}

@test "discover_extensions logs when ORADBA_LOCAL_BASE does not exist" {
    # Set DEBUG logging
    export ORADBA_LOG_LEVEL="DEBUG"
    
    # Set ORADBA_LOCAL_BASE to non-existent directory
    export ORADBA_LOCAL_BASE="/nonexistent/directory/path"
    
    # Run discover_extensions and capture output
    local result
    result=$(discover_extensions 2>&1)
    
    # Should log that base directory was not found
    [[ "${result}" == *"Extension base directory not found"* ]] || \
    [[ "${result}" == *"/nonexistent/directory/path"* ]]
}

@test "discover_extensions logs scanning message when directory exists" {
    # Set DEBUG logging
    export ORADBA_LOG_LEVEL="DEBUG"
    
    # ORADBA_LOCAL_BASE is already set to TEST_TEMP_DIR in setup()
    
    # Run discover_extensions and capture output
    local result
    result=$(discover_extensions 2>&1)
    
    # Should log that it's scanning for extensions
    [[ "${result}" == *"Scanning for extensions"* ]] || \
    [[ "${result}" == *"${TEST_TEMP_DIR}"* ]]
}

@test "load_extensions logs when no extensions found" {
    # Set DEBUG logging
    export ORADBA_LOG_LEVEL="DEBUG"
    
    # Empty directory (no extensions)
    # TEST_TEMP_DIR is already empty from setup()
    
    # Run load_extensions and capture output
    local result
    result=$(load_extensions 2>&1)
    
    # Should log that no extensions were found
    [[ "${result}" == *"No extensions found"* ]]
}

@test "load_extensions logs when extensions are found" {
    # Set DEBUG logging
    export ORADBA_LOG_LEVEL="DEBUG"
    
    # Create test extension
    mkdir -p "${TEST_TEMP_DIR}/test_ext/bin"
    echo "name: test_ext" > "${TEST_TEMP_DIR}/test_ext/.extension"
    
    # Run load_extensions and capture output
    local result
    result=$(load_extensions 2>&1)
    
    # Should log discovery and loading
    [[ "${result}" == *"Starting extension discovery and loading"* ]] && \
    [[ "${result}" == *"Found 1 extension"* ]] && \
    [[ "${result}" == *"Loading extension: test_ext"* ]]
}

# EOF
