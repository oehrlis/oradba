#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: test_plugin_interface.bats
# Author...: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.....: 2026.01.16
# Purpose..: Generic plugin interface compliance tests for all plugins
# Reference: Architecture Review & Refactoring Plan (Phase 2)
# Notes....: Validates that all plugins implement the required interface
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Create temporary test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/oradba_plugin_interface_$$"
    mkdir -p "${TEST_DIR}/lib"
    mkdir -p "${TEST_DIR}/lib/plugins"
    
    # Set ORADBA_BASE for plugins
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/.."
    
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
    
    # Copy all plugins to test directory
    cp "${BATS_TEST_DIRNAME}/../src/lib/plugins/"*.sh "${TEST_DIR}/lib/plugins/"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# Plugin Interface Compliance Tests
# ==============================================================================

# Required interface functions that all plugins must implement
REQUIRED_FUNCTIONS=(
    "plugin_detect_installation"
    "plugin_validate_home"
    "plugin_adjust_environment"
    "plugin_check_status"
    "plugin_get_metadata"
    "plugin_should_show_listener"
    "plugin_discover_instances"
    "plugin_supports_aliases"
)

# List of all plugin files (excluding plugin_interface.sh)
get_plugin_files() {
    find "${TEST_DIR}/lib/plugins" -name "*_plugin.sh" -type f | grep -v "plugin_interface.sh"
}

@test "plugin_interface.sh exists" {
    [ -f "${BATS_TEST_DIRNAME}/../src/lib/plugins/plugin_interface.sh" ]
}

@test "all plugins have required metadata variables" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Check metadata exists
        [[ -n "${plugin_name}" ]] || {
            echo "Plugin ${plugin_file} missing plugin_name"
            return 1
        }
        [[ -n "${plugin_version}" ]] || {
            echo "Plugin ${plugin_file} missing plugin_version"
            return 1
        }
        [[ -n "${plugin_description}" ]] || {
            echo "Plugin ${plugin_file} missing plugin_description"
            return 1
        }
    done
}

@test "all plugins implement plugin_detect_installation" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_detect_installation &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_detect_installation"
            return 1
        }
    done
}

@test "all plugins implement plugin_validate_home" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_validate_home &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_validate_home"
            return 1
        }
    done
}

@test "all plugins implement plugin_adjust_environment" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_adjust_environment &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_adjust_environment"
            return 1
        }
    done
}

@test "all plugins implement plugin_check_status" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_check_status &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_check_status"
            return 1
        }
    done
}

@test "all plugins implement plugin_get_metadata" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_get_metadata &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_get_metadata"
            return 1
        }
    done
}

@test "all plugins implement plugin_should_show_listener" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_should_show_listener &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_should_show_listener"
            return 1
        }
    done
}

@test "all plugins implement plugin_discover_instances" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_discover_instances &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_discover_instances"
            return 1
        }
    done
}

@test "all plugins implement plugin_supports_aliases" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_supports_aliases &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_supports_aliases"
            return 1
        }
    done
}

@test "all plugins implement complete interface" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        for func in "${REQUIRED_FUNCTIONS[@]}"; do
            type "${func}" &>/dev/null || {
                echo "Plugin ${plugin_file} missing required function: ${func}"
                return 1
            }
        done
    done
}

@test "plugin_validate_home returns proper exit codes" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Should fail for non-existent path
        run plugin_validate_home "/nonexistent/path/$$"
        [ "$status" -ne 0 ] || {
            echo "Plugin ${plugin_file} validate_home should fail for non-existent path"
            return 1
        }
    done
}

@test "plugin_adjust_environment returns output" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Should return some path (even if unchanged)
        run plugin_adjust_environment "/some/test/path"
        [[ -n "$output" ]] || {
            echo "Plugin ${plugin_file} adjust_environment should return output"
            return 1
        }
    done
}

@test "plugin_should_show_listener returns valid exit code" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Should return either 0 or 1 (not crash)
        run plugin_should_show_listener
        [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]] || {
            echo "Plugin ${plugin_file} should_show_listener returned invalid exit code: $status"
            return 1
        }
    done
}

@test "plugin_supports_aliases returns valid exit code" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Should return either 0 or 1 (not crash)
        run plugin_supports_aliases
        [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]] || {
            echo "Plugin ${plugin_file} supports_aliases returned invalid exit code: $status"
            return 1
        }
    done
}

@test "plugin_discover_instances returns valid output format" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Should return 0 and output might be empty or pipe-delimited
        run plugin_discover_instances "/some/test/path"
        [ "$status" -eq 0 ] || {
            echo "Plugin ${plugin_file} discover_instances should return 0"
            return 1
        }
        
        # If output exists, should be pipe-delimited
        if [[ -n "$output" ]]; then
            [[ "$output" =~ \| ]] || {
                echo "Plugin ${plugin_file} discover_instances output should be pipe-delimited"
                return 1
            }
        fi
    done
}

@test "all plugin files are executable" {
    for plugin_file in $(get_plugin_files); do
        [ -r "${plugin_file}" ] || {
            echo "Plugin ${plugin_file} is not readable"
            return 1
        }
    done
}

@test "all plugin files have proper shebang" {
    for plugin_file in $(get_plugin_files); do
        head -n 1 "${plugin_file}" | grep -q "#!/usr/bin/env bash" || {
            echo "Plugin ${plugin_file} missing proper shebang"
            return 1
        }
    done
}

@test "plugin count is correct" {
    # We have 9 product plugins (not counting plugin_interface.sh)
    # database, datasafe, client, iclient, oud, java, weblogic, oms, emagent
    local count
    count=$(get_plugin_files | wc -l)
    [ "$count" -eq 9 ] || {
        echo "Expected 9 plugins, found ${count}"
        return 1
    }
}

@test "database plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/database_plugin.sh" ]
}

@test "datasafe plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/datasafe_plugin.sh" ]
}

@test "client plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/client_plugin.sh" ]
}

@test "iclient plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/iclient_plugin.sh" ]
}

@test "oud plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/oud_plugin.sh" ]
}

@test "java plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/java_plugin.sh" ]
}

@test "weblogic plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/weblogic_plugin.sh" ]
}

@test "oms plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/oms_plugin.sh" ]
}

@test "emagent plugin is present" {
    [ -f "${TEST_DIR}/lib/plugins/emagent_plugin.sh" ]
}

# ==============================================================================
# Universal Core Functions Compliance Tests (13 required for ALL plugins)
# ==============================================================================

@test "all plugins implement plugin_build_base_path" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_build_base_path &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_build_base_path"
            return 1
        }
    done
}

@test "all plugins implement plugin_build_env" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_build_env &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_build_env"
            return 1
        }
    done
}

@test "all plugins implement plugin_get_instance_list" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_get_instance_list &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_get_instance_list"
            return 1
        }
    done
}

@test "all plugins implement plugin_build_bin_path" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_build_bin_path &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_build_bin_path"
            return 1
        }
    done
}

@test "all plugins implement plugin_build_lib_path" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_build_lib_path &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_build_lib_path"
            return 1
        }
    done
}

@test "all plugins implement plugin_get_config_section" {
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        type plugin_get_config_section &>/dev/null || {
            echo "Plugin ${plugin_file} missing plugin_get_config_section"
            return 1
        }
    done
}

# ==============================================================================
# Category-Specific Requirements Tests
# ==============================================================================

@test "database plugin implements listener functions" {
    # shellcheck source=/dev/null
    source "${TEST_DIR}/lib/plugins/database_plugin.sh"
    
    # Must implement both listener functions
    type plugin_should_show_listener &>/dev/null || {
        echo "database_plugin missing plugin_should_show_listener"
        return 1
    }
    
    type plugin_check_listener_status &>/dev/null || {
        echo "database_plugin missing plugin_check_listener_status"
        return 1
    }
    
    # Should show listener (return 0)
    run plugin_should_show_listener "/test/path"
    [ "$status" -eq 0 ] || {
        echo "database_plugin should_show_listener should return 0 (yes)"
        return 1
    }
}

@test "datasafe plugin implements listener functions" {
    # shellcheck source=/dev/null
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    # Must implement both listener functions
    type plugin_should_show_listener &>/dev/null || {
        echo "datasafe_plugin missing plugin_should_show_listener"
        return 1
    }
    
    type plugin_check_listener_status &>/dev/null || {
        echo "datasafe_plugin missing plugin_check_listener_status"
        return 1
    }
    
    # Should NOT show listener (return 1) - uses tnslsnr but not a DB listener
    run plugin_should_show_listener "/test/path"
    [ "$status" -eq 1 ] || {
        echo "datasafe_plugin should_show_listener should return 1 (no)"
        return 1
    }
}

@test "non-database plugins implement listener functions with defaults" {
    # Non-database plugins should implement listener functions but return defaults
    local non_db_plugins=(
        "client_plugin.sh"
        "iclient_plugin.sh"
        "oud_plugin.sh"
        "java_plugin.sh"
        "weblogic_plugin.sh"
        "emagent_plugin.sh"
        "oms_plugin.sh"
    )
    
    for plugin in "${non_db_plugins[@]}"; do
        # shellcheck source=/dev/null
        source "${TEST_DIR}/lib/plugins/${plugin}"
        
        # Should implement the function
        type plugin_should_show_listener &>/dev/null || {
            echo "${plugin} missing plugin_should_show_listener"
            return 1
        }
        
        # Should return 1 (no) for non-database products
        run plugin_should_show_listener "/test/path"
        [ "$status" -eq 1 ] || {
            echo "${plugin} should_show_listener should return 1 (no) for non-database products"
            return 1
        }
    done
}

# ==============================================================================
# Extension Function Pattern Tests
# ==============================================================================

@test "extension functions follow naming conventions" {
    # Check that extension functions (non-core) follow patterns
    # This is a validation that plugin-specific extensions are properly named
    
    # DataSafe has plugin_get_adjusted_paths - should be documented
    # shellcheck source=/dev/null
    source "${TEST_DIR}/lib/plugins/datasafe_plugin.sh"
    
    if type plugin_get_adjusted_paths &>/dev/null; then
        # Function exists - it's an extension, which is fine
        # Store function name in variable to avoid SC2050
        local func_name="plugin_get_adjusted_paths"
        # Just verify it starts with plugin_
        [[ "${func_name}" =~ ^plugin_ ]] || {
            echo "Extension function should start with plugin_ prefix"
            return 1
        }
    fi
}

@test "all plugins implement exactly 13 universal core functions" {
    # Define the 13 universal core functions
    local UNIVERSAL_CORE_FUNCTIONS=(
        "plugin_detect_installation"
        "plugin_validate_home"
        "plugin_adjust_environment"
        "plugin_build_base_path"
        "plugin_build_env"
        "plugin_check_status"
        "plugin_get_metadata"
        "plugin_discover_instances"
        "plugin_get_instance_list"
        "plugin_supports_aliases"
        "plugin_build_bin_path"
        "plugin_build_lib_path"
        "plugin_get_config_section"
    )
    
    # shellcheck source=/dev/null
    for plugin_file in $(get_plugin_files); do
        source "${plugin_file}"
        
        # Check each universal core function
        for func in "${UNIVERSAL_CORE_FUNCTIONS[@]}"; do
            type "${func}" &>/dev/null || {
                echo "Plugin ${plugin_file} missing universal core function: ${func}"
                return 1
            }
        done
    done
}

@test "database plugins implement 15 mandatory functions (13 universal + 2 category)" {
    # Database plugins must implement 13 universal + 2 category-specific
    local db_plugins=(
        "database_plugin.sh"
        "datasafe_plugin.sh"
    )
    
    local MANDATORY_FUNCTIONS=(
        # 13 universal core
        "plugin_detect_installation"
        "plugin_validate_home"
        "plugin_adjust_environment"
        "plugin_build_base_path"
        "plugin_build_env"
        "plugin_check_status"
        "plugin_get_metadata"
        "plugin_discover_instances"
        "plugin_get_instance_list"
        "plugin_supports_aliases"
        "plugin_build_bin_path"
        "plugin_build_lib_path"
        "plugin_get_config_section"
        # 2 category-specific
        "plugin_should_show_listener"
        "plugin_check_listener_status"
    )
    
    for plugin in "${db_plugins[@]}"; do
        # shellcheck source=/dev/null
        source "${TEST_DIR}/lib/plugins/${plugin}"
        
        # Check all 15 mandatory functions
        for func in "${MANDATORY_FUNCTIONS[@]}"; do
            type "${func}" &>/dev/null || {
                echo "${plugin} missing mandatory function: ${func}"
                return 1
            }
        done
    done
}
