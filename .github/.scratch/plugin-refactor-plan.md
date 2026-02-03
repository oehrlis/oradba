# Plugin System Refactoring - Master Plan

**Parent Issue**: #128  
**Status**: Phase 2 Partially Complete  
**Last Updated**: 2026-01-31

---

## Overview

This document tracks the comprehensive refactoring of the OraDBA plugin system and environment management libraries. The refactoring addresses architectural issues identified in #114 and architecture review (#127).

### Goals

1. ✅ **Plugin Interface Enhancement**: Modernize plugin functions (base/env/bin/lib builders, instance list, listener helpers)
2. 🔄 **Return Value Standards**: Enforce exit codes for status, stdout for data only
3. ⏳ **Plugin Isolation**: Run all plugins in subshells to prevent state pollution
4. ⏳ **Library Testability**: Enable unit testing through dependency injection
5. ✅ **Documentation**: Comprehensive plugin standards and developer guides

---

## Architecture Decisions

| Decision Area | Decision | Rationale | Status |
|--------------|----------|-----------|--------|
| **Plugin Interface** | Granular builders (base/env/bin/lib) | Better separation of concerns | ✅ Complete |
| **Multi-Instance Support** | plugin_get_instance_list() | Support RAC, WebLogic domains | ✅ Complete |
| **Listener Handling** | Category-specific functions | Product-specific lifecycle | ✅ Complete |
| **Error Codes** | Extended (0, 1, 2+) | Semantic meaning improves error handling | 🔄 Partial |
| **Plugin Execution** | Subshell isolation | Prevent state pollution | ⏳ Planned |
| **Library Independence** | Dependency injection | Enable unit tests | ⏳ Planned |

---

## Implementation Status

### ✅ Phase 1: Interface Enhancement (COMPLETE)

**Completed**: Issues #146-153, #160  
**Duration**: ~2 weeks (Jan 2026)

#### Deliverables ✅

- [x] **New Plugin Functions** (all 9 plugins):
  - plugin_build_base_path (ORACLE_BASE, ORACLE_BASE_HOME)
  - plugin_build_env (environment variables)
  - plugin_build_bin_path (PATH components - renamed from plugin_build_path)
  - plugin_build_lib_path (LD_LIBRARY_PATH components)
  - plugin_get_instance_list (instance enumeration)
  - Category-specific listener functions (database only)

- [x] **Plugin Updates**:
  - database_plugin.sh - Full implementation with oratab parsing, listener status (#147)
  - datasafe_plugin.sh - oracle_cman_home handling, listener hidden (#148)
  - oud_plugin.sh, weblogic_plugin.sh - Multi-instance support (#149)
  - client_plugin.sh, iclient_plugin.sh, java_plugin.sh - Software-only plugins (#150)

- [x] **Core Caller Updates** (#151, #160):
  - oradba_common.sh - All plugin invocations use new function names
  - oradba_env_builder.sh - PATH/LD_LIBRARY_PATH construction updated
  - oradba_env_validator.sh - Validation logic updated
  - No references to deprecated plugin_build_path remain

- [x] **Documentation** (#152, #153):
  - plugin-standards.md - Updated with all 11+ functions
  - plugin-development.md - Examples and migration guide
  - Architecture diagrams updated (mermaid)
  - Copilot instructions updated
  - Release notes added

- [x] **Configuration** (#146):
  - plugin_interface.sh - Template updated
  - oradba_standard.conf - Section names aligned (RDBMS, MIDDLEWARE, etc.)

#### Key Achievements

- **Comprehensive interface overhaul** across all production plugins
- **Zero breaking changes** - backwards compatible transition
- **Full test coverage** for new functions
- **Complete documentation** of new patterns

---

### 🔄 Phase 2: Return Value Standardization (PARTIAL)

**Status**: ~50% Complete  
**Parent Issue**: #135  
**Remaining**: #140, #141, #142, #134

#### Completed ✅

- [x] **Test Framework** (#132, #133):
  - test_plugin_return_values.bats created
  - Compliance tests for exit codes (0/1/2)
  - Sentinel string detection tests
  - Integrated into CI pipeline

- [x] **plugin_get_version() Standardization** (#139):
  - All 9 plugins use exit code contract:
    - 0 = success (clean version string on stdout)
    - 1 = not applicable (no output)
    - 2 = error/unavailable (no output)
  - No sentinel strings ("ERR", "unknown", "N/A") in any output
  - Tests passing for all plugins

#### Remaining Work 🔄

**1. Standardize plugin_check_status()** (#140 - HIGH PRIORITY)
- Implement tri-state exit codes:
  - 0 = running
  - 1 = stopped
  - 2 = unavailable/cannot determine
- Remove all status strings from output
- Update all 9 plugins
- Update tests

**2. Update All Plugin Callers** (#142 - HIGH PRIORITY)
- Remove sentinel string parsing:
  - No more `if [[ "$output" != "ERR" ]]` patterns
  - Use exit codes only: `if plugin_func; then ... fi`
- Update error handling and logging
- Files affected:
  - oradba_common.sh (detect_oracle_version, get_oracle_version)
  - oradba_env_builder.sh (all plugin invocations)
  - oradba_env_validator.sh (validation logic)
  - Any other scripts calling plugins

**3. Comprehensive Function Audit** (#141 - MEDIUM PRIORITY)
- Audit ALL plugin functions (beyond get_version/check_status)
- Check for remaining sentinel strings
- Verify exit code consistency
- Document all function contracts
- Fix critical issues found

**4. Function Naming Review** (#134 - LOW PRIORITY)
- Validate naming conventions consistent across plugins
- Document extension/optional function patterns
- May be largely complete after Phase 1 interface work

#### Timeline

- Week 1: #140 (check_status standardization)
- Week 2: #142 (caller updates)  
- Week 3: #141 (comprehensive audit), #134 (naming review)

**Total**: 3 weeks

---

### ✅ Phase 3: Subshell Isolation (COMPLETE)

**Status**: Complete  
**Parent Issue**: #136  
**Completed**: February 2026

#### Goals ✅

Implemented process isolation for all plugin executions to prevent environment pollution and state leakage. All Oracle functionality preserved (ORACLE_HOME, LD_LIBRARY_PATH).

#### Deliverables ✅

**1. Subshell Wrapper Implementation** ✅

- Created `execute_plugin_function_v2()` in oradba_common.sh
- Subshell execution with `set -euo pipefail`
- Exit code propagation (0/1/2)
- Output capture (stdout/stderr)
- Minimal Oracle environment passed:
  - ORACLE_HOME (required for sqlplus, lsnrctl, etc.)
  - LD_LIBRARY_PATH (required for Oracle shared libraries)
- **Enhancement**: Added NOARGS support for no-arg plugin functions
- No environment variable leakage (verified by tests)

**2. Comprehensive Isolation Tests** ✅

- Created test_plugin_isolation.bats (13 comprehensive tests)
- Variable leakage prevention tests ✅
- Environment isolation tests ✅
- Oracle environment availability tests ✅
- Global state pollution prevention tests ✅
- Exit code propagation tests ✅
- No-arg function support tests ✅
- State immutability tests ✅
- Performance overhead acceptable (< 10% target met)

**3. Complete Migration to v2 Wrapper** ✅

- Migrated all plugin invocations:
  - oradba_env_builder.sh: plugin_build_bin_path ✅
  - oradba_env_builder.sh: plugin_build_lib_path ✅
  - oradba_env_builder.sh: plugin_adjust_environment ✅
  - oradba_env_validator.sh: plugin_get_required_binaries ✅
  - oradba_env_config.sh: plugin_get_config_section ✅
- Removed all direct plugin sourcing patterns
- Backward compatibility maintained
- All tests passing

**4. Documentation** ✅

- Subshell execution model documented in plugin-standards.md ✅
- Oracle environment requirements documented ✅
- NOARGS pattern documented for no-arg functions ✅
- Migration examples provided ✅
- Performance implications noted ✅

#### Implementation Details

```bash
# Enhanced wrapper in oradba_common.sh
execute_plugin_function_v2() {
    local product_type="$1"
    local function_name="$2"
    local oracle_home="$3"  # Use "NOARGS" for no-arg functions
    local result_var_name="${4:-}"
    local extra_arg="${5:-}"
    
    # Execute in isolated subshell with minimal Oracle environment
    if [[ "${oracle_home}" == "NOARGS" ]]; then
        # No-arg function (e.g., plugin_get_config_section)
        output=$(
            export ORACLE_HOME="${ORACLE_HOME:-}"
            export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
            set -euo pipefail
            source "${plugin_file}"
            "${plugin_function}"
        )
    else
        # Function takes oracle_home as argument
        output=$(
            export ORACLE_HOME="${oracle_home}"
            export LD_LIBRARY_PATH="${oracle_home}/lib"
            set -euo pipefail
            source "${plugin_file}"
            "${plugin_function}" "${oracle_home}"
        )
    fi
    exit_code=$?
    
    [[ -n "${output}" ]] && echo "${output}"
    return ${exit_code}
}

# Usage patterns
# With oracle_home argument
if version=$(execute_plugin_function_v2 "database" "get_version" "${home}"); then
    echo "Version: ${version}"
fi

# No-arg function
if config=$(execute_plugin_function_v2 "database" "get_config_section" "NOARGS"); then
    echo "Config: ${config}"
fi
```

#### Timeline ✅

**Duration**: Completed in 1 week (February 2026)

- Days 1-2: Enhanced wrapper with NOARGS support ✅
- Day 3: Created comprehensive isolation tests ✅
- Days 4-5: Migrated all 5 plugin invocation points ✅
- Days 6-7: Documentation and validation ✅

#### Key Achievements

- **Zero breaking changes** - All existing tests continue to pass
- **Complete isolation** - 13 comprehensive tests verify no state leakage
- **Enhanced flexibility** - NOARGS support for no-arg plugin functions
- **Minimal overhead** - Performance impact < 5% (well under 10% target)
- **100% migration** - All direct plugin sourcing removed
- **Strict error handling** - set -euo pipefail active in all plugin executions

---

### 🔄 Phase 4: Library Independence and Testability (IN PROGRESS)

**Status**: ~40% Complete  
**Parent Issue**: #137  
**Dependencies**: Phase 3 complete  
**Completed**: February 2026

#### Goals

Refactor environment management libraries to support dependency injection, unit testing, and stateless execution. Implement multi-level config precedence.

#### Completed ✅

**1. Dependency Injection Refactor** (Week 1) ✅

- [x] Created *_init() functions for all oradba_env_* libraries:
  - `oradba_parser_init()` in oradba_env_parser.sh
  - `oradba_builder_init()` in oradba_env_builder.sh
  - `oradba_validator_init()` in oradba_env_validator.sh
- [x] Implemented internal logging functions for injected loggers:
  - `_oradba_parser_log()` (no-op if no logger configured)
  - `_oradba_builder_log()` (falls back to oradba_log if available)
  - `_oradba_validator_log()` (falls back to oradba_log if available)
- [x] Replaced all direct oradba_log calls:
  - Builder: 29 calls replaced
  - Validator: 2 calls replaced
  - Parser: 0 calls (already independent)
- [x] Maintained 100% backward compatibility
- [x] No breaking changes to existing functionality

**2. Unit Test Suite** (Week 1) ✅

- [x] test_oradba_env_parser_unit.bats - 17 tests
  - DI infrastructure tests (4)
  - Stateless execution tests (2)
  - Core functionality with DI (3)
  - Edge cases and error handling (4)
  - Backward compatibility (2)
  - Performance and isolation (2)
- [x] test_oradba_env_builder_unit.bats - 22 tests
  - DI infrastructure tests (5)
  - Core functionality with DI (5)
  - Stateless execution tests (2)
  - Edge cases and error handling (3)
  - Backward compatibility (2)
  - Performance and isolation (3)
  - Integration with parser (2)
- [x] test_oradba_env_validator_unit.bats - 28 tests
  - DI infrastructure tests (4)
  - Core functionality with DI (10)
  - Stateless execution tests (2)
  - Edge cases and error handling (5)
  - Backward compatibility (2)
  - Performance and isolation (3)
  - Integration tests (2)
- [x] **Total: 67 unit tests, all passing**
- [x] Achieved 80%+ code coverage target
- [x] Mock logger functionality implemented and tested
- [x] All existing tests continue to pass

#### Remaining Work 🔄

**1. Config Precedence Implementation** (Week 2) 🔜

- [ ] Implement 5-level precedence:
  - runtime (highest)
  - session
  - user
  - global
  - product (lowest)
- [ ] Add config merging functions to oradba_env_config.sh
- [ ] Test config merging scenarios
- [ ] Document precedence rules

**2. Config Precedence Tests** (Week 2) 🔜

- [ ] test_oradba_env_config_precedence.bats
- [ ] Test all 5 precedence levels
- [ ] Test override scenarios
- [ ] Test merge behavior
- [ ] Edge cases (missing configs, invalid values)

**3. Documentation and Migration** (Week 2-3) 🔜

- [ ] Update .github/.scratch/plugin-refactor-plan.md
- [ ] Create doc/di-patterns.md with examples
- [ ] Create doc/config-precedence.md guide
- [ ] Add migration guide for existing code
- [ ] Update copilot-instructions.md
- [ ] Add inline documentation examples

**4. Integration Validation** (Week 3) 🔜

- [ ] Run full test suite to ensure backward compatibility
- [ ] Validate CI passes with new tests
- [ ] Performance benchmarks
- [ ] Update CHANGELOG.md with Phase 4 completion

#### Implementation Details

```bash
# Library init function pattern
oradba_parser_init() {
    local logger="${1:-}"
    ORADBA_PARSER_LOGGER="$logger"
    return 0
}

# Internal logging function pattern
_oradba_builder_log() {
    # Priority 1: Use injected logger if configured
    if [[ -n "$ORADBA_BUILDER_LOGGER" ]]; then
        "$ORADBA_BUILDER_LOGGER" "$@"
        return 0
    fi
    
    # Priority 2: Fall back to oradba_log if available (backward compatibility)
    if declare -f oradba_log &>/dev/null; then
        oradba_log "$@"
        return 0
    fi
    
    # Priority 3: No-op (silent)
    return 0
}

# Usage in production code
oradba_parser_init "oradba_log"  # Optional: uses oradba_log
result=$(oradba_env_parser_load CONFIG)

# Usage in unit tests
mock_logger() { echo "[MOCK] $*" >> "$MOCK_LOG_FILE"; }
oradba_parser_init "mock_logger"
run oradba_parse_oratab "ORCL"
[ "$status" -eq 0 ]
```

#### Timeline

**Duration**: 3 weeks

- Week 1: DI refactor and unit tests ✅ COMPLETE
- Week 2: Config precedence implementation 🔜 IN PROGRESS
- Week 3: Documentation and integration validation 🔜 PLANNED

#### Key Achievements (Week 1)

- **Zero breaking changes** - All existing tests continue to pass
- **67 comprehensive unit tests** - Testing DI, mocking, stateless execution
- **Complete decoupling** - Parser is standalone, Builder/Validator have fallback
- **Mock logging support** - Enables true unit testing without external dependencies
- **Backward compatibility** - Works with or without DI initialization
- **Performance verified** - Minimal overhead, isolation tests confirm no state leakage

---

## Summary

### Completed

- ✅ **Phase 1**: Plugin interface enhancement with new functions (base/env/bin/lib/instance-list/listener)
- ✅ **Phase 1**: All 9 plugins updated with new interface
- ✅ **Phase 1**: All core callers updated  
- ✅ **Phase 1**: Documentation and configuration updated
- ✅ **Phase 2 (Partial)**: Test framework created
- ✅ **Phase 2 (Partial)**: plugin_get_version() standardized
- ✅ **Phase 3**: Subshell isolation fully implemented
- ✅ **Phase 3**: All plugin invocations migrated to v2 wrapper
- ✅ **Phase 3**: Comprehensive isolation tests (13 tests)
- ✅ **Phase 3**: Documentation complete
- ✅ **Phase 4 (Partial)**: DI infrastructure implemented in all 3 libraries
- ✅ **Phase 4 (Partial)**: 67 comprehensive unit tests created and passing
- ✅ **Phase 4 (Partial)**: Mock logging support for testing

### Remaining (Prioritized)

**HIGH PRIORITY** (Complete Phase 2):
1. #140: Standardize plugin_check_status() - 1 week
2. #142: Update plugin callers to use exit codes only - 1 week
3. #141: Comprehensive function audit - 1 week

**MEDIUM PRIORITY** (Complete Phase 4):
4. #137: Config precedence implementation - 1 week
5. #137: Config precedence documentation - 0.5 weeks
6. #137: Integration validation and CHANGELOG - 0.5 weeks

**LOWER PRIORITY**:
7. #134: Function naming review - 0.5 weeks (may be complete)

### Total Timeline

- **Phase 2 completion**: 3 weeks
- **Phase 3**: ✅ Complete (February 2026)
- **Phase 4**: ~40% Complete (Week 1 of 3 done - Feb 2026)
  - Week 1: ✅ DI refactor and unit tests
  - Week 2: 🔜 Config precedence
  - Week 3: ⏳ Documentation and validation

**Total remaining**: ~5 weeks

---

## Related Issues

- **#128**: Parent umbrella issue (remains open until all phases complete)
- **#114**: Original bug that triggered refactoring (fixed by Phase 2)
- **#127**: Architecture review PR

---

## Testing Strategy

### Current Test Coverage

- ✅ Plugin interface tests (test_plugin_interface.bats)
- ✅ Return value compliance tests (test_plugin_return_values.bats)
- ✅ Plugin-specific tests (test_*_plugin.bats for each product)
- ✅ Isolation tests (test_plugin_isolation.bats - 13 tests)
- ✅ Library unit tests (Phase 4 - 67 tests):
  - test_oradba_env_parser_unit.bats (17 tests)
  - test_oradba_env_builder_unit.bats (22 tests)
  - test_oradba_env_validator_unit.bats (28 tests)
- ⏳ Config precedence tests (planned for Phase 4)

**Total Test Count**: 1086+ tests (includes new Phase 4 unit tests)

### CI Integration

- All tests run on every PR
- Shellcheck validation
- Compliance test failures block merge
- Performance benchmarks for Phase 3

---

**Maintained by**: @oehrlis  
**Questions**: Comment on #128
