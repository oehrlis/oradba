# Phase 3 Sub-Issues: Subshell Isolation and Plugin Execution Model

Parent Issue: #136 - [PHASE 3] Subshell Isolation and Plugin Execution Model

## Phase 3.1: Implement Subshell Isolation for All Plugin Executions

**Title**: [Phase 3.1] Implement robust subshell isolation for all plugin executions

**Tag**: phase3-1-process-isolation  
**Parent**: #136  
**Labels**: enhancement, Phase 3, plugin-refactor  
**Assignees**: oehrlis

### Task Description

Implement robust process isolation for all plugin function calls by introducing execute_plugin_in_subshell() wrapper in oradba_common.sh. All plugins must be called in isolated subshells using set -euo pipefail, with proper propagation of exit codes (0/1/2). Capture and relay all plugin output (stdout, stderr) without leakage or mutation of global state, environment variables, or file descriptors.

**Critical Requirement**: Subshell must provide minimal Oracle environment with ORACLE_HOME and LD_LIBRARY_PATH properly set to ensure plugins can execute Oracle commands.

### Objective

Implement execute_plugin_in_subshell() wrapper for isolated plugin execution. Ensure exit code propagation, output capture, error handling, and minimal Oracle environment. Prevent environment pollution while maintaining Oracle functionality.

### Component

Core libraries (oradba_common.sh)

### Task Type

Feature Implementation

### Priority

High

### Requirements

- [ ] Create execute_plugin_in_subshell() function in oradba_common.sh
- [ ] Implement subshell execution with set -euo pipefail
- [ ] Implement exit code propagation (0, 1, 2)
- [ ] Implement output capture (stdout)
- [ ] Pass minimal Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH) to subshell
- [ ] Add error handling and logging
- [ ] Verify no environment variable leakage (except required Oracle vars)
- [ ] Verify no global state pollution
- [ ] Create unit tests for wrapper
- [ ] Performance testing (overhead < 10%)
- [ ] Update documentation

### Implementation Notes

```bash
# Wrapper function in oradba_common.sh
execute_plugin_in_subshell() {
    local plugin_name="$1"
    local function_name="$2"
    shift 2
    local args=("$@")
    
    # Execute in isolated subshell with minimal Oracle environment
    local output
    local exit_code
    
    output=$(
        # Enable strict error handling
        set -euo pipefail
        
        # Set minimal Oracle environment
        export ORACLE_HOME="${ORACLE_HOME:-}"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
        
        # Source plugin in subshell (isolated from parent)
        source "");;;){"ORADBA_PLUGIN_DIR}/${plugin_name}_plugin.sh" || return 2
        
        # Execute plugin function with arguments
        "${function_name}" "${args[@]}"
    )
    exit_code=$?
    
    # Output result to parent (if any)
    [[ -n "${output}" ]] && echo "${output}"
    
    # Propagate exit code to parent
    return ${exit_code}
}

# Usage pattern
if version=$(execute_plugin_in_subshell "database" "plugin_get_version" "${home}"); then
    echo "Version: ${version}"
else
    case $? in
        1) log_warn "Version not applicable" ;;
        2) log_error "Version unavailable" ;; 
    esac
fi
```

**Key Points**:
- Subshell inherits minimal environment: ORACLE_HOME, LD_LIBRARY_PATH
- All other environment variables isolated
- Exit codes 0/1/2 propagate correctly
- Output captured without global state impact
- Performance overhead should be < 10%

### Testing Criteria

- [ ] Wrapper executes plugins in subshell (process isolation)
- [ ] Exit codes (0, 1, 2) propagate correctly
- [ ] Output captured and returned correctly
- [ ] ORACLE_HOME available in subshell
- [ ] LD_LIBRARY_PATH available in subshell
- [ ] Other environment variables do not leak
- [ ] No global state changes after execution
- [ ] Error handling works correctly
- [ ] Performance overhead < 10%
- [ ] All unit tests pass
- [ ] All integration tests pass

### Acceptance Criteria

- [ ] execute_plugin_in_subshell() function implemented
- [ ] All plugin calls use subshell wrapper
- [ ] Exit codes propagate correctly
- [ ] Minimal Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH) passed to subshell
- [ ] Output capture works correctly
- [ ] No environment leakage (except Oracle vars)
- [ ] No global state pollution
- [ ] Isolation tests pass
- [ ] Performance tests show < 10% overhead
- [ ] Documentation updated
- [ ] Code review approved

### Dependencies

- Phase 2 (#135) - MUST be complete
- #142 (Phase 2.3) - MUST be complete
- Blocks: Phase 3.2, 3.3, 3.4

### Additional Context

**Parent**: #136 (Phase 3 - Subshell Isolation)
**First sub-issue for Phase 3**

This creates the foundational wrapper that all subsequent Phase 3 work depends on. Critical for preventing plugin side effects while maintaining Oracle functionality.

**Timeline**: 3-4 days
- Day 1: Design and implement wrapper with Oracle environment handling
- Day 2: Implement exit code propagation and output capture
- Day 3: Error handling, logging, testing
- Day 4: Performance testing, documentation, review

---

## Phase 3.2: Update Plugin Execution in Core Libraries

**Title**: [Phase 3.2] Refactor all plugin invocations to use subshell wrapper

**Tag**: phase3-2-update-callers  
**Parent**: #136  
**Labels**: enhancement, Phase 3, plugin-refactor  
**Assignees**: oehrlis

### Task Description

Refactor all plugin invocations in oradba_common.sh, oradba_env_builder.sh, and oradba_env_validator.sh to use execute_plugin_in_subshell() wrapper. Remove all direct plugin function calls. Ensure consistent subshell execution across the entire codebase.

### Objective

Update all plugin call sites in core libraries to use subshell execution wrapper. Eliminate direct plugin function invocations. Ensure consistent, isolated execution everywhere.

### Component

Core libraries (oradba_common.sh, oradba_env_builder.sh, oradba_env_validator.sh)

### Task Type

Refactoring

### Priority

High

### Requirements

- [ ] Audit all plugin call sites in oradba_common.sh
- [ ] Audit all plugin call sites in oradba_env_builder.sh
- [ ] Audit all plugin call sites in oradba_env_validator.sh
- [ ] Identify all direct plugin function calls
- [ ] Replace all direct calls with execute_plugin_in_subshell()
- [ ] Update error handling for subshell pattern
- [ ] Update logging to reflect subshell execution
- [ ] Verify no direct plugin calls remain
- [ ] Update integration tests
- [ ] Regression testing

### Implementation Notes

```bash
# OLD: Direct plugin call (WRONG)
version=$(plugin_get_version "${home}")
if [[ $? -eq 0 ]]; then
    echo "Version: ${version}"
fi

# NEW: Subshell wrapper (CORRECT)
if version=$(execute_plugin_in_subshell "database" "plugin_get_version" "${home}"); then
    echo "Version: ${version}"
else
    case $? in
        1) log_warn "Version not applicable" ;;
        2) log_error "Version unavailable" ;; 
    esac
fi
```

**Search Commands**:
```bash
# Find direct plugin calls to replace
grep -rn 'plugin_get_version' lib/oradba_common.sh lib/oradba_env*.sh
grep -rn 'plugin_check_status' lib/oradba_common.sh lib/oradba_env*.sh
grep -rn 'plugin_get_home' lib/oradba_common.sh lib/oradba_env*.sh

# Verify no direct calls remain after refactoring
grep -rn '\$(plugin_' lib/
grep -rn 'plugin_[a-z_]*[[:space:]]*"' lib/
```

**Key Files**:
- lib/oradba_common.sh: ~10-15 call sites
- lib/oradba_env_builder.sh: ~5-10 call sites
- lib/oradba_env_validator.sh: ~5-10 call sites

### Testing Criteria

- [ ] No direct plugin function calls in oradba_common.sh
- [ ] No direct plugin function calls in oradba_env_builder.sh
- [ ] No direct plugin function calls in oradba_env_validator.sh
- [ ] All plugin calls use execute_plugin_in_subshell()
- [ ] Error handling works correctly
- [ ] Logging reflects subshell execution
- [ ] All integration tests pass
- [ ] No functionality regressions
- [ ] Performance acceptable

### Acceptance Criteria

- [ ] All plugin calls in oradba_common.sh updated
- [ ] All plugin calls in oradba_env_builder.sh updated
- [ ] All plugin calls in oradba_env_validator.sh updated
- [ ] Zero direct plugin function calls remain (grep verification)
- [ ] All integration tests pass
- [ ] No functional regressions
- [ ] Error handling correct
- [ ] Logging updated
- [ ] Documentation updated
- [ ] Code review approved

### Dependencies

- #136 Phase 3.1 - MUST be complete
- Phase 2 complete
- Blocks: Phase 3.3, 3.4

### Additional Context

**Parent**: #136 (Phase 3)
**Depends on**: Phase 3.1 (execute_plugin_in_subshell wrapper)

This integrates the subshell wrapper into all calling code, completing the migration to isolated execution.

**Timeline**: 4-5 days
- Day 1: Audit all call sites, plan updates
- Day 2: Update oradba_common.sh
- Day 3: Update oradba_env_builder.sh and oradba_env_validator.sh
- Day 4: Testing and bug fixes
- Day 5: Documentation and review

---

## Phase 3.3: Implement Plugin State Isolation Tests

**Title**: [Phase 3.3] Create comprehensive isolation test suite

**Tag**: phase3-3-isolation-tests  
**Parent**: #136  
**Labels**: enhancement, Phase 3, plugin-refactor, testing  
**Assignees**: oehrlis

### Task Description

Create comprehensive test suite to verify subshell isolation. Test for variable leakage, environment pollution, global state changes, Oracle environment availability, and proper cleanup. Ensure plugins cannot affect calling environment.

### Objective

Create test_plugin_isolation.bats test suite to verify complete subshell isolation. Validate no side effects from plugin execution.

### Component

Test suite (test/test_plugin_isolation.bats)

### Task Type

Testing

### Priority

High

### Requirements

- [ ] Create test/test_plugin_isolation.bats file
- [ ] Test variable leakage prevention
- [ ] Test environment variable isolation
- [ ] Test ORACLE_HOME availability in subshell
- [ ] Test LD_LIBRARY_PATH availability in subshell
- [ ] Test global state isolation
- [ ] Test exit code propagation (0, 1, 2)
- [ ] Test output capture
- [ ] Test error handling
- [ ] Test performance (overhead < 10%)
- [ ] Integration with CI pipeline

### Implementation Notes

```bash
#!/usr/bin/env bats
# test/test_plugin_isolation.bats

@test "subshell does not leak variables to parent" {
    # Set test variable
    TEST_VAR="original"
    
    # Execute plugin that tries to modify TEST_VAR
    run execute_plugin_in_subshell "test" "plugin_modify_var"
    
    # Verify variable unchanged in parent
    [ "${TEST_VAR}" = "original" ]
}

@test "subshell has access to ORACLE_HOME" {
    export ORACLE_HOME="/u01/oracle"
    
    # Execute plugin that checks ORACLE_HOME
    run execute_plugin_in_subshell "test" "plugin_check_oracle_home"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/u01/oracle" ]]
}

@test "subshell has access to LD_LIBRARY_PATH" {
    export LD_LIBRARY_PATH="/u01/oracle/lib"
    
    # Execute plugin that checks LD_LIBRARY_PATH
    run execute_plugin_in_subshell "test" "plugin_check_ld_path"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/u01/oracle/lib" ]]
}

@test "subshell exit code 0 propagates correctly" {
    run execute_plugin_in_subshell "test" "plugin_return_success"
    [ "$status" -eq 0 ]
}

@test "subshell exit code 1 propagates correctly" {
    run execute_plugin_in_subshell "test" "plugin_return_notapplicable"
    [ "$status" -eq 1 ]
}

@test "subshell exit code 2 propagates correctly" {
    run execute_plugin_in_subshell "test" "plugin_return_error"
    [ "$status" -eq 2 ]
}

@test "subshell output captured correctly" {
    run execute_plugin_in_subshell "test" "plugin_echo_version"
    [ "$status" -eq 0 ]
    [ "$output" = "19.3.0.0.0" ]
}

@test "subshell does not pollute global state" {
    # Set global array
    declare -g -a GLOBAL_ARRAY=("item1" "item2")
    
    # Execute plugin that modifies array
    run execute_plugin_in_subshell "test" "plugin_modify_array"
    
    # Verify array unchanged
    [ "
    ${#GLOBAL_ARRAY[@]}" -eq 2 ]
    [ "${GLOBAL_ARRAY[0]}" = "item1" ]
}

@test "subshell performance overhead acceptable" {
    # Benchmark direct call
    start=$(date +%s%N)
    for i in {1..100}; do
        plugin_get_version "/u01/oracle" >/dev/null 2>&1 || true
    done
    direct_time=$(($(date +%s%N) - start))
    
    # Benchmark subshell call
    start=$(date +%s%N)
    for i in {1..100}; do
        execute_plugin_in_subshell "database" "plugin_get_version" "/u01/oracle" >/dev/null 2>&1 || true
    done
    subshell_time=$(($(date +%s%N) - start))
    
    # Calculate overhead percentage
    overhead=$(( (subshell_time - direct_time) * 100 / direct_time ))
    
    # Verify overhead < 10%
    [ "$overhead" -lt 10 ]
}
```

### Testing Criteria

- [ ] Variable leakage tests pass
- [ ] Environment isolation tests pass
- [ ] ORACLE_HOME availability tests pass
- [ ] LD_LIBRARY_PATH availability tests pass
- [ ] Global state tests pass
- [ ] Exit code propagation tests pass (0, 1, 2)
- [ ] Output capture tests pass
- [ ] Performance tests pass
- [ ] All tests integrated into CI

### Acceptance Criteria

- [ ] test_plugin_isolation.bats created
- [ ] Variable leakage prevention verified
- [ ] Environment isolation verified
- [ ] Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH) verified in subshell
- [ ] Global state isolation verified
- [ ] Exit code propagation verified
- [ ] Output capture verified
- [ ] Performance overhead < 10% verified
- [ ] All tests passing
- [ ] Tests integrated into CI pipeline
- [ ] Documentation updated

### Dependencies

- Phase 3.1 - MUST be complete
- Phase 3.2 - SHOULD be complete for integration testing
- Blocks: Phase 3.4

### Additional Context

**Parent**: #136 (Phase 3)
**Depends on**: Phase 3.1 (wrapper), Phase 3.2 (integration)

Critical validation that subshell isolation works correctly and doesn't break Oracle functionality.

**Timeline**: 3 days
- Day 1: Design tests, create test framework
- Day 2: Implement isolation tests
- Day 3: Performance tests, CI integration, documentation

---

## Phase 3.4: Document Subshell Patterns and Migration Guide

**Title**: [Phase 3.4] Document subshell execution patterns and provide migration guide

**Tag**: phase3-4-documentation  
**Parent**: #136  
**Labels**: enhancement, Phase 3, plugin-refactor, documentation  
**Assignees**: oehrlis

### Task Description

Update all documentation to reflect subshell execution model. Provide comprehensive migration guide for custom plugins and scripts. Document Oracle environment requirements, performance implications, and troubleshooting.

### Objective

Complete Phase 3 documentation. Ensure plugin authors understand subshell execution model, Oracle environment handling, and migration requirements.

### Component

Documentation (docs/, plugin-standards.md, CHANGELOG.md)

### Task Type

Documentation

### Priority

High

### Requirements

- [ ] Update plugin-standards.md with subshell requirements
- [ ] Document execute_plugin_in_subshell() usage
- [ ] Document Oracle environment requirements (ORACLE_HOME, LD_LIBRARY_PATH)
- [ ] Create migration guide for plugin authors
- [ ] Document before/after code examples
- [ ] Add troubleshooting section
- [ ] Document performance implications
- [ ] Update CHANGELOG.md
- [ ] Update README.md if needed
- [ ] Create developer guide section

### Implementation Notes

**plugin-standards.md updates**:

```markdown
## Subshell Execution Model

All plugin functions execute in isolated subshells to prevent side effects. The `execute_plugin_in_subshell()` wrapper ensures:

- Process isolation
- Exit code propagation (0/1/2)
- Output capture
- Minimal Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH)
- No environment pollution

### Oracle Environment Requirements

Plugins executing Oracle commands require minimal environment:
- `ORACLE_HOME`: Oracle installation directory
- `LD_LIBRARY_PATH`: Must include `$ORACLE_HOME/lib`

The subshell wrapper automatically passes these variables to plugins.

### Usage Pattern

```bash
# Call plugin function in subshell
if output=$(execute_plugin_in_subshell "database" "plugin_get_version" "${home}"); then
    echo "Version: ${output}"
else
    case $? in
        1) log_warn "Version not applicable" ;;
        2) log_error "Version unavailable" ;; 
    esac
fi
```

### Migration Guide

**Old Pattern (Direct Call)**:
```bash
version=$(plugin_get_version "${home}")
if [[ $? -eq 0 ]]; then
    echo "Version: ${version}"
fi
```

**New Pattern (Subshell)**:
```bash
if version=$(execute_plugin_in_subshell "database" "plugin_get_version" "${home}"); then
    echo "Version: ${version}"
fi
```

### Performance Impact

Subshell execution adds ~5-10ms per call:
- Subshell creation: ~5ms
- Plugin sourcing: ~5ms
- Total overhead: < 10%

Acceptable for interactive and automation use.

### Troubleshooting

**Problem**: Plugin fails with "Oracle command not found"
**Solution**: Verify ORACLE_HOME and LD_LIBRARY_PATH are set in parent shell

**Problem**: Exit codes not propagating
**Solution**: Check error handling in subshell wrapper

**Problem**: Output not captured
**Solution**: Ensure plugin writes to stdout, not stderr
```

### Testing Criteria

- [ ] plugin-standards.md updated
- [ ] Migration guide complete
- [ ] Oracle environment documented
- [ ] Code examples provided
- [ ] Troubleshooting section complete
- [ ] CHANGELOG.md updated
- [ ] All documentation reviewed
- [ ] Links and references valid

### Acceptance Criteria

- [ ] plugin-standards.md reflects subshell model
- [ ] execute_plugin_in_subshell() documented
- [ ] Oracle environment requirements documented
- [ ] Migration guide complete with examples
- [ ] Troubleshooting section added
- [ ] Performance impact documented
- [ ] CHANGELOG.md updated
- [ ] Documentation reviewed and approved
- [ ] All examples tested

### Dependencies

- Phase 3.1 - MUST be complete
- Phase 3.2 - MUST be complete
- Phase 3.3 - SHOULD be complete

### Additional Context

**Parent**: #136 (Phase 3)
**Final sub-issue for Phase 3**

Completes Phase 3 by ensuring all knowledge is documented and accessible to plugin developers.

**Timeline**: 2 days
- Day 1: Update plugin-standards.md, create migration guide
- Day 2: Update CHANGELOG.md, review, finalize

---

## Phase 3 Summary

**Timeline**: 2-3 weeks total
- Phase 3.1: 3-4 days (Implement wrapper)
- Phase 3.2: 4-5 days (Update all calls)
- Phase 3.3: 3 days (Isolation tests)
- Phase 3.4: 2 days (Documentation)

**Total**: 12-14 days (~2-3 weeks)

**Critical Path**: 3.1 → 3.2 → 3.3 → 3.4
