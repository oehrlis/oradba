#!/usr/bin/env bats
# ---------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security Automation
# ---------------------------------------------------------------------------
# Unit tests for oradba_env_config.sh
# Tests the configuration processor for section-based config files
# ---------------------------------------------------------------------------

# Setup and teardown
setup() {
    # Source the configuration library
    export ORADBA_BASE="${BATS_TEST_DIRNAME}/../src"
    source "${ORADBA_BASE}/lib/oradba_env_config.sh"
    
    # Create temporary test directory
    TEST_DIR="${BATS_TMPDIR}/test_config_$$"
    mkdir -p "${TEST_DIR}"
    
    # Set Oracle environment for testing
    export ORACLE_BASE="/u01/app/oracle"
    export ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
    export ORACLE_SID="TESTDB"
}

teardown() {
    # Cleanup test directory
    rm -rf "${TEST_DIR}"
    
    # Unset test variables
    unset TEST_VAR TEST_ALIAS
}

# Test oradba_list_config_sections
@test "list_config_sections: should list all sections in config file" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
# Test config file
[DEFAULT]
EDITOR=vi

[RDBMS]
SQLPATH=/opt/oracle/sqlpath

[CLIENT]
NLS_LANG=AMERICAN_AMERICA.AL32UTF8
EOF
    
    run oradba_list_config_sections "${TEST_DIR}/test.conf"
    [ "$status" -eq 0 ]
    [[ "$output" =~ DEFAULT ]]
    [[ "$output" =~ RDBMS ]]
    [[ "$output" =~ CLIENT ]]
}

@test "list_config_sections: should handle file with no sections" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
# Config with no sections
EDITOR=vi
SQLPATH=/opt/oracle/sqlpath
EOF
    
    run oradba_list_config_sections "${TEST_DIR}/test.conf"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "list_config_sections: should handle nonexistent file" {
    run oradba_list_config_sections "${TEST_DIR}/nonexistent.conf"
    [ "$status" -eq 1 ]
}

# Test oradba_apply_config_section
@test "apply_config_section: should export variables from section" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export TEST_VAR=testvalue
export TEST_NUMBER=42
EOF
    
    run oradba_apply_config_section "${TEST_DIR}/test.conf" "DEFAULT"
    [ "$status" -eq 0 ]
    
    # Variables should be exported
    oradba_apply_config_section "${TEST_DIR}/test.conf" "DEFAULT"
    [ "${TEST_VAR}" = "testvalue" ]
    [ "${TEST_NUMBER}" = "42" ]
}

@test "apply_config_section: should create aliases from section" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[RDBMS]
alias test_alias='echo hello'
EOF
    
    oradba_apply_config_section "${TEST_DIR}/test.conf" "RDBMS"
    
    # Check if alias was created using alias command directly
    shopt -s expand_aliases
    alias test_alias 2>&1 | grep -q "echo hello"
}

@test "apply_config_section: should expand variables" {
    cat > "${TEST_DIR}/test.conf" <<EOF
[RDBMS]
export TEST_VAR="\${ORACLE_HOME}/bin"
EOF
    
    oradba_apply_config_section "${TEST_DIR}/test.conf" "RDBMS"
    [[ "${TEST_VAR}" == "${ORACLE_HOME}/bin" ]]
}

@test "apply_config_section: should handle section not found" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export TEST_VAR=testvalue
EOF
    
    run oradba_apply_config_section "${TEST_DIR}/test.conf" "NONEXISTENT"
    [ "$status" -eq 0 ]  # Not an error, just no matches
}

@test "apply_config_section: should skip comments and empty lines" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
# This is a comment
export TEST_VAR=value1

# Another comment
export TEST_VAR2=value2
EOF
    
    oradba_apply_config_section "${TEST_DIR}/test.conf" "DEFAULT"
    [ "${TEST_VAR}" = "value1" ]
    [ "${TEST_VAR2}" = "value2" ]
}

@test "apply_config_section: should stop at next section" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export DEFAULT_VAR=default_value

[RDBMS]
export RDBMS_VAR=rdbms_value
EOF
    
    oradba_apply_config_section "${TEST_DIR}/test.conf" "DEFAULT"
    [ "${DEFAULT_VAR}" = "default_value" ]
    [ -z "${RDBMS_VAR}" ]  # Should not be set
}

# Test oradba_validate_config_file
@test "validate_config_file: should pass valid config" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
alias ll='ls -la'

[RDBMS]
export SQLPATH=/opt/oracle/sqlpath
EOF
    
    run oradba_validate_config_file "${TEST_DIR}/test.conf"
    [ "$status" -eq 0 ]
}

@test "validate_config_file: should detect invalid section syntax" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT
export EDITOR=vi
EOF
    
    run oradba_validate_config_file "${TEST_DIR}/test.conf"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid section" ]]
}

@test "validate_config_file: should detect invalid variable syntax" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
INVALID LINE WITHOUT EXPORT OR ALIAS
EOF
    
    run oradba_validate_config_file "${TEST_DIR}/test.conf"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid syntax" ]]
}

@test "validate_config_file: should allow comments and empty lines" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
# This is a comment
[DEFAULT]

# Another comment
export EDITOR=vi

# End comment
EOF
    
    run oradba_validate_config_file "${TEST_DIR}/test.conf"
    [ "$status" -eq 0 ]
}

@test "validate_config_file: should handle nonexistent file" {
    run oradba_validate_config_file "${TEST_DIR}/nonexistent.conf"
    [ "$status" -eq 1 ]
}

# Test oradba_get_config_value
@test "get_config_value: should retrieve value from section" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
export PAGER=less

[RDBMS]
export SQLPATH=/opt/oracle/sqlpath
EOF
    
    run oradba_get_config_value "${TEST_DIR}/test.conf" "DEFAULT" "EDITOR"
    [ "$status" -eq 0 ]
    [ "$output" = "vi" ]
}

@test "get_config_value: should handle variable not found" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
EOF
    
    run oradba_get_config_value "${TEST_DIR}/test.conf" "DEFAULT" "NONEXISTENT"
    [ "$status" -eq 1 ]
}

@test "get_config_value: should handle section not found" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
EOF
    
    run oradba_get_config_value "${TEST_DIR}/test.conf" "NONEXISTENT" "EDITOR"
    [ "$status" -eq 1 ]
}

@test "get_config_value: should extract value with spaces" {
    cat > "${TEST_DIR}/test.conf" <<'EOF'
[DEFAULT]
export TEST_VAR="value with spaces"
EOF
    
    run oradba_get_config_value "${TEST_DIR}/test.conf" "DEFAULT" "TEST_VAR"
    [ "$status" -eq 0 ]
    [ "$output" = "value with spaces" ]
}

# Test oradba_expand_variables
@test "expand_variables: should expand ORACLE_HOME" {
    run oradba_expand_variables '${ORACLE_HOME}/bin'
    [ "$status" -eq 0 ]
    [[ "$output" =~ /bin ]]
    [[ "$output" =~ ${ORACLE_HOME} ]]
}

@test "expand_variables: should expand ORACLE_SID" {
    run oradba_expand_variables '${ORACLE_SID}_backup'
    [ "$status" -eq 0 ]
    [[ "$output" =~ ${ORACLE_SID}_backup ]]
}

@test "expand_variables: should expand ORACLE_BASE" {
    run oradba_expand_variables '${ORACLE_BASE}/admin'
    [ "$status" -eq 0 ]
    [[ "$output" =~ /admin ]]
    [[ "$output" =~ ${ORACLE_BASE} ]]
}

@test "expand_variables: should handle string without variables" {
    run oradba_expand_variables 'plain_text'
    [ "$status" -eq 0 ]
    [ "$output" = "plain_text" ]
}

# Test oradba_apply_product_config
@test "apply_product_config: should apply DEFAULT and product sections" {
    # Create config files
    mkdir -p "${ORADBA_BASE}/etc"
    cat > "${ORADBA_BASE}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export DEFAULT_VAR=default_value

[RDBMS]
export RDBMS_VAR=rdbms_value
EOF
    
    oradba_apply_product_config "RDBMS" "TESTDB"
    [ "${DEFAULT_VAR}" = "default_value" ]
    [ "${RDBMS_VAR}" = "rdbms_value" ]
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
}

@test "apply_product_config: should handle missing config files gracefully" {
    # Ensure config files don't exist
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
    rm -f "${ORADBA_BASE}/etc/oradba_standard.conf"
    
    run oradba_apply_product_config "RDBMS" "TESTDB"
    [ "$status" -eq 0 ]  # Should not fail
}

@test "apply_product_config: should apply SID-specific config if exists" {
    # Create config files
    mkdir -p "${ORADBA_BASE}/etc/sid"
    cat > "${ORADBA_BASE}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export CORE_VAR=core_value
EOF
    
    cat > "${ORADBA_BASE}/etc/sid/sid.TESTDB.conf" <<'EOF'
[DEFAULT]
export SID_SPECIFIC_VAR=sid_value
EOF
    
    oradba_apply_product_config "RDBMS" "TESTDB"
    [ "${CORE_VAR}" = "core_value" ]
    [ "${SID_SPECIFIC_VAR}" = "sid_value" ]
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
    rm -rf "${ORADBA_BASE}/etc/sid"
}

# Test oradba_load_generic_configs
@test "load_generic_configs: should load configs in correct order" {
    # Create config files with different priorities
    mkdir -p "${ORADBA_BASE}/etc"
    cat > "${ORADBA_BASE}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=core
EOF
    
    cat > "${ORADBA_BASE}/etc/oradba_standard.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=standard
EOF
    
    cat > "${ORADBA_BASE}/etc/oradba_local.conf" <<'EOF'
[DEFAULT]
export TEST_PRIORITY=local
EOF
    
    oradba_load_generic_configs "DEFAULT"
    # Later configs should override earlier ones
    [ "${TEST_PRIORITY}" = "local" ]
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
    rm -f "${ORADBA_BASE}/etc/oradba_standard.conf"
    rm -f "${ORADBA_BASE}/etc/oradba_local.conf"
}

# Test product-specific sections
@test "apply_product_config: should handle all product types" {
    mkdir -p "${ORADBA_BASE}/etc"
    
    for product in RDBMS CLIENT ICLIENT GRID ASM DATASAFE OUD WLS; do
        # Create config file for this product
        cat > "${ORADBA_BASE}/etc/oradba_core.conf" <<EOF
[${product}]
export ${product}_VAR=${product}_value
EOF
        
        # Apply product config
        oradba_apply_product_config "${product}" "TEST"
        
        # Check variable was set
        var_name="${product}_VAR"
        [ "${!var_name}" = "${product}_value" ]
        
        # Unset for next iteration
        unset "${product}_VAR"
    done
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
}

# Integration test: Full configuration flow
@test "integration: should apply complete configuration hierarchy" {
    mkdir -p "${ORADBA_BASE}/etc/sid"
    
    # Core config
    cat > "${ORADBA_BASE}/etc/oradba_core.conf" <<'EOF'
[DEFAULT]
export EDITOR=vi
export CORE_VAR=from_core

[RDBMS]
export SQLPATH=/core/sqlpath
export RDBMS_CORE=core_value
EOF
    
    # Local config (overrides core)
    cat > "${ORADBA_BASE}/etc/oradba_local.conf" <<'EOF'
[DEFAULT]
export EDITOR=vim

[RDBMS]
export SQLPATH=/local/sqlpath
EOF
    
    # SID-specific config (overrides all)
    cat > "${ORADBA_BASE}/etc/sid/sid.TESTDB.conf" <<'EOF'
[RDBMS]
export SQLPATH=/sid/sqlpath
export SID_SPECIFIC=sid_value
EOF
    
    oradba_apply_product_config "RDBMS" "TESTDB"
    
    # Check hierarchy: SID > local > core
    [ "${EDITOR}" = "vim" ]                    # From local (overrides core)
    [ "${SQLPATH}" = "/sid/sqlpath" ]          # From SID config (overrides all)
    [ "${CORE_VAR}" = "from_core" ]            # From core (not overridden)
    [ "${RDBMS_CORE}" = "core_value" ]         # From core RDBMS section
    [ "${SID_SPECIFIC}" = "sid_value" ]        # From SID config
    
    # Cleanup
    rm -f "${ORADBA_BASE}/etc/oradba_core.conf"
    rm -f "${ORADBA_BASE}/etc/oradba_local.conf"
    rm -rf "${ORADBA_BASE}/etc/sid"
}
