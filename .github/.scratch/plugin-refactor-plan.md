# Plugin System Refactoring - Master Plan

**Parent Issue**: #128  
**Status**: Planning  
**Last Updated**: 2026-01-29

---

## Overview

This document outlines the comprehensive refactoring plan for the OraDBA plugin
system and environment management libraries. The refactoring addresses
architectural issues identified in #114 and the architecture review (#127).

### Goals

1. **Plugin Isolation**: Run all plugins in subshells to prevent state pollution
2. **Return Value Standards**: Enforce exit codes for status, stdout for data only
3. **Interface Versioning**: Establish v1.0.0 baseline and prevent breaking changes
4. **Stub Plugin Management**: Mark experimental plugins and exclude from production
5. **Library Testability**: Enable unit testing through dependency injection

---

## Architecture Decisions

| Decision Area            | Decision             | Rationale                                                                  |
|--------------------------|----------------------|----------------------------------------------------------------------------|
| **Plugin Execution**     | Subshell (isolation) | Plugins are information providers only; no environment modification needed |
| **Error Codes**          | Extended (0, 1, 2+)  | Semantic meaning improves error handling without string parsing            |
| **Versioning**           | v1.0.0 baseline      | Current drift was accidental; establish baseline before v2.0.0             |
| **Stub Plugins**         | Mark experimental    | Exclude from production and default tests until complete                   |
| **Library Independence** | Testability priority | Enable unit tests through dependency injection                             |

---

## Implementation Phases

### Phase 1: Foundation - Documentation and Standards

**Duration**: 1 week  
**Dependencies**: None

#### Issues

- #129: Create plugin standards documentation (PLUGIN_STANDARDS.md)
- #130: Add return value and error code test suite

**Deliverables**:

- [ ] `src/lib/plugins/PLUGIN_STANDARDS.md` - Formal specification (core + category-specific functions)
- [ ] `tests/test_plugin_return_values.bats` - Test framework
- [ ] Updated `doc/plugin-development.md` and diagrams to match core/path/env/listener changes

---

### Phase 2: Plugin Return Value and Interface Standardization

**Duration**: 2 weeks  
**Dependencies**: Phase 1 complete

#### Issues

- #131: Standardize plugin_get_version() across all plugins
- #132: Standardize plugin_check_status() across all plugins
- #133: Update plugin callers to use exit codes
- #144: Introduce `plugin_build_base_path`, `plugin_build_env`,
  `plugin_build_bin_path`, `plugin_get_instance_list`, and listener functions
  where applicable

**Deliverables**:

- [ ] All 9 production plugins updated (no sentinel strings, new core functions wired)
- [ ] All callers in `oradba_common.sh` updated (new function names, exit codes)
- [ ] All callers in `oradba_env_*` libraries updated (new env builder/path/lib builder)
- [ ] Tests passing for return value conventions

**Affected Files**:

```text
src/lib/plugins/database_plugin.sh
src/lib/plugins/datasafe_plugin.sh
src/lib/plugins/client_plugin.sh
src/lib/plugins/iclient_plugin.sh
src/lib/plugins/java_plugin.sh
src/lib/plugins/oud_plugin.sh
src/lib/oradba_common.sh (detect_oracle_version, get_oracle_version)
src/lib/oradba_env_builder.sh
src/lib/oradba_env_validator.sh
```

---

### Phase 3: Subshell Isolation Implementation

**Duration**: 2 weeks  
**Dependencies**: Phase 2 complete

#### Issues

- #134: Implement execute_plugin_function_v2() with subshell isolation
- #135: Migrate all plugin invocations to v2 wrapper
- #136: Add plugin isolation tests

**Deliverables**:

- [ ] `execute_plugin_function_v2()` in `oradba_common.sh`
- [ ] All plugin calls migrated to v2
- [ ] Remove old `execute_plugin_function()` or deprecate
- [ ] Isolation tests verify no state leakage

**Technical Details**:

```bash
# New pattern
execute_plugin_function_v2() {
    local plugin_type="$1"
    local function_name="$2"
    shift 2
    
    # Run in subshell for isolation
    (
        source_plugin_and_call "${plugin_type}" "${function_name}" "$@"
    )
}
```

---

### Phase 4: Library Independence and Testability

**Duration**: 3 weeks  
**Dependencies**: Phase 3 complete

#### Issues

- #137: Refactor oradba_env_parser.sh for dependency injection
- #138: Refactor oradba_env_builder.sh for dependency injection
- #139: Refactor oradba_env_validator.sh for dependency injection
- #140: Add unit tests for environment management libraries

**Deliverables**:

- [ ] All 6 `oradba_env_*` libraries support DI
- [ ] Unit tests added for parser (currently 0)
- [ ] Unit tests added for builder (currently 0)
- [ ] Unit tests added for validator (currently 0)
- [ ] Libraries testable without `oradba_common.sh`

**Pattern**:

```bash
# Each library gets init function
oradba_parser_init() {
    local logger="${1:-oradba_log}"
    ORADBA_PARSER_CONFIG[logger]="${logger}"
}
```

---

### Phase 5: Cleanup and Versioning

**Duration**: 1 week  
**Dependencies**: Phases 1-4 complete

#### Issues

- #141: Revert all v2.0.0 references to v1.0.0
- #142: Mark stub plugins as experimental
- #143: Update all documentation for new architecture

**Deliverables**:

- [ ] All plugins show v1.0.0
- [ ] Stub plugins (weblogic, oms, emagent) marked experimental
- [ ] Test suite skips stubs by default
- [ ] Documentation updated across all files (including diagrams and Copilot instructions)

**Files to Update**:

```text
src/lib/plugins/weblogic_plugin.sh
src/lib/plugins/oms_plugin.sh
src/lib/plugins/emagent_plugin.sh
tests/test_plugin_interface.bats (add skip logic)
doc/plugin-development.md
src/doc/api/plugins.md
```

---

## Testing Strategy

### Unit Tests (New)

- Each `oradba_env_*` library testable in isolation
- Mock logger and dependencies
- Target: 80%+ code coverage for core functions

### Integration Tests (Enhanced)

- Plugin execution through full stack
- Return value propagation
- Error handling across layers

### Regression Tests (New)

- Verify bug #114 class of issues prevented
- Version detection scenarios
- Status check scenarios

### Test Files

```
tests/test_plugin_return_values.bats (new)
tests/test_plugin_isolation.bats (new)
tests/test_oradba_env_parser_unit.bats (new)
tests/test_oradba_env_builder_unit.bats (new)
tests/test_oradba_env_validator_unit.bats (new)
tests/test_integration_plugin_execution.bats (enhanced)
```

---

## Risk Assessment

| Risk                        | Likelihood | Impact | Mitigation                                                |
|-----------------------------|------------|--------|-----------------------------------------------------------|
| Breaking existing workflows | Medium     | High   | Parallel implementation (v2 functions), extensive testing |
| Performance degradation     | Low        | Medium | Subshell overhead minimal; benchmark before/after         |
| Incomplete migration        | Medium     | High   | Automated checks for old patterns; deprecation warnings   |
| Test coverage gaps          | Medium     | Medium | Require tests for each PR; track coverage metrics         |

---

## Migration Strategy

### Backward Compatibility

- Keep old `execute_plugin_function()` during transition
- Add deprecation warnings but don't break
- Allow 2-3 release cycles for full migration

### Rollout Plan

1. **Phase 1-2**: Non-breaking (documentation + plugin internals)
2. **Phase 3**: Parallel implementation (v2 alongside v1)
3. **Phase 4**: Library changes isolated to tests initially
4. **Phase 5**: Final cleanup after validation

### Validation Gates

- [ ] All existing tests pass
- [ ] New tests added and passing
- [ ] No regressions in manual testing
- [ ] Performance benchmarks acceptable
- [ ] Documentation complete

---

## Success Metrics

### Correctness

- [ ] Zero recurrences of bug #114 pattern
- [ ] All plugin functions return clean data or exit codes
- [ ] No sentinel strings in plugin output

### Testability

- [ ] 100% of environment libraries have unit tests
- [ ] 80%+ code coverage for critical paths
- [ ] Tests run in <5 minutes

### Maintainability

- [ ] Plugin interface formally documented
- [ ] Clear examples for new plugin development
- [ ] Contributor onboarding time reduced

### Architecture

- [ ] All plugins run in subshells
- [ ] Libraries decoupled from global state
- [ ] Clean separation of concerns verified

---

## Issue Tracking

### Phase 1: Foundation

- [ ] #129 - Plugin standards documentation
- [ ] #130 - Return value test suite

### Phase 2: Return Values

- [ ] #131 - Standardize plugin_get_version()
- [ ] #132 - Standardize plugin_check_status()
- [ ] #133 - Update plugin callers

### Phase 3: Isolation

- [ ] #134 - Implement execute_plugin_function_v2()
- [ ] #135 - Migrate plugin invocations
- [ ] #136 - Plugin isolation tests

### Phase 4: Library Independence

- [ ] #137 - Refactor parser for DI
- [ ] #138 - Refactor builder for DI
- [ ] #139 - Refactor validator for DI
- [ ] #140 - Add library unit tests

### Phase 5: Cleanup

- [ ] #141 - Revert to v1.0.0
- [ ] #142 - Mark stub plugins experimental
- [ ] #143 - Update documentation

---

## Timeline

```text
Week 1:     Phase 1 (Documentation)
Week 2-3:   Phase 2 (Return Values)
Week 4-5:   Phase 3 (Isolation)
Week 6-8:   Phase 4 (Library Independence)
Week 9:     Phase 5 (Cleanup)
Week 10:    Buffer for issues/validation
```

**Total Duration**: 10 weeks (7-8 weeks of active development)

---

## Related Issues

- **#114**: Data Safe version not displayed (original bug)
- **#127**: Architecture review (PR with findings)
- **#128**: Parent feature request (this plan implements it)

---

**Maintained by**: @oehrlis  
**Questions/Issues**: Comment on #128
