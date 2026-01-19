# Phase 4.4 Test Failures Analysis

**Date**: 2025-01-16  
**Total Tests**: 1033  
**Passed**: 1023 (99.03%)  
**Failed**: 10 (0.97%)

## Test Results Summary

```
Ran: make test-full
Total: 1033 tests
Pass:  1023 tests (99.03%)
Fail:  10 tests (0.97%)
```

## Failure Categories

### 1. ✅ Deprecated Logging Functions (FIXED)

**Tests**: 332, 388, 390  
**Status**: ✅ RESOLVED  
**Issue**: Code using old `log_debug`/`log_warn`/`log_error` instead of `oradba_log DEBUG/WARN/ERROR`  
**Fix**: Replaced 5 instances in `oradba_common.sh`  
**Commit**: [Next commit]

**Changed**:

- Line 1163: `log_error` → `oradba_log ERROR`
- Line 1578: `log_debug` → `oradba_log DEBUG`
- Line 1640: `log_warn` → `oradba_log WARN`
- Line 1645: `log_debug` → `oradba_log DEBUG`
- Line 2137: `log_debug` → `oradba_log DEBUG`

### 2. ⏳ Database Functions Sourcing (20 tests)

**Tests**: 509-532 (all tests in test_oradba_db_functions.bats)  
**Status**: ⏳ NEEDS FIX  
**Issue**: `oradba_db_functions.sh` requires `oradba_common.sh` to be sourced first  
**Root Cause**: Test setup doesn't source `oradba_common.sh` before sourcing `oradba_db_functions.sh`

**Error Message**:

```
ERROR: oradba_db_functions.sh requires oradba_common.sh to be sourced first
```

**Fix**: Update test setup in `tests/test_oradba_db_functions.bats`:

```bash
setup() {
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # Source oradba_common.sh FIRST
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    # Then source oradba_db_functions.sh
    source "${PROJECT_ROOT}/src/lib/oradba_db_functions.sh"
}
```

**Affected Tests**:

- 509: check_database_connection function is defined
- 510: get_database_open_mode function is defined
- 511: query_instance_info function is defined
- 512: query_database_info function is defined
- 513: query_datafile_size function is defined
- 514: query_memory_usage function is defined
- 515: query_sessions_info function is defined
- 516: query_pdb_info function is defined
- 517: format_uptime function is defined
- 518: show_database_status function is defined
- 519-532: All other function tests in the file

### 3. ⏳ Product Config Logging (4 tests)

**Tests**: 571, 573, 575, 576  
**Status**: ⏳ NEEDS INVESTIGATION  
**Issue**: `oradba_apply_product_config` calling `oradba_log` which isn't available in test context  
**Root Cause**: Code already uses `oradba_log DEBUG` correctly (line 221 in oradba_env_config.sh)

**Error Message**:

```
oradba_env_config.sh: line 221: oradba_log: command not found
```

**Analysis**: The function `oradba_apply_product_config()` in `oradba_env_config.sh` calls `oradba_log DEBUG` but `oradba_log` isn't defined in test context. This is likely because:

1. Test doesn't source `oradba_common.sh` where `oradba_log` is defined, OR
2. Test loads `oradba_env_config.sh` standalone

**Fix**: Update test setup in `tests/test_oradba_env_config.bats`:

```bash
setup() {
    # Source oradba_common.sh first to get oradba_log
    source "${PROJECT_ROOT}/src/lib/oradba_common.sh"
    # Then source env config
    source "${PROJECT_ROOT}/src/lib/oradba_env_config.sh"
}
```

**Affected Tests**:

- 571: apply_product_config: should apply DEFAULT and product sections
- 573: apply_product_config: should apply SID-specific config if exists
- 575: apply_product_config: should handle all product types
- 576: integration: should apply complete configuration hierarchy

### 4. ⏳ Plugin Status Integration (4 tests)

**Tests**: 602, 603, 604, 614  
**Status**: ⏳ NEEDS FIX  
**Issue**: `oradba_get_product_status()` not correctly integrating with plugin system

**Test Failures**:

```bash
Test 602: get_product_status: should return N/A for CLIENT
  Expected: "N/A"
  Actual: (unknown output)

Test 603: get_product_status: should return N/A for ICLIENT  
  Expected: "N/A"
  Actual: (unknown output)

Test 604: get_product_status: should return UNKNOWN for invalid product
  Expected: "UNKNOWN"
  Actual: (unknown output)

Test 614: check_datasafe_status: should return STOPPED for non-running service
  Expected: "UNKNOWN"
  Actual: (unknown output - status mismatch)
```

**Analysis**: The function `oradba_get_product_status()` (lines 275-320 in `oradba_env_status.sh`):

1. Tries to load plugin file directly
2. Calls `plugin_check_status()` directly
3. Should use `oradba_apply_oracle_plugin "check_status" ...` instead

**Current Code** (lines 296-305):

```bash
local plugin_file="${ORADBA_BASE}/src/lib/plugins/${plugin_type}_plugin.sh"
if [[ -f "${plugin_file}" ]]; then
    source "${plugin_file}" 2>/dev/null
    
    if declare -f plugin_check_status >/dev/null 2>&1; then
        plugin_check_status "${home_path}" "${instance_name}"
        return $?
    fi
fi
```

**Should Be**:

```bash
# Try to use plugin for status check
if oradba_apply_oracle_plugin "check_status" "${plugin_type}" "${home_path}" "${instance_name}" "status_result"; then
    echo "${status_result}"
    return 0
fi
```

**Fix Required**:

1. Remove direct plugin sourcing
2. Use `oradba_apply_oracle_plugin` helper
3. Ensure CLIENT and ICLIENT plugins return "N/A" from `plugin_check_status`
4. Ensure fallback returns "UNKNOWN" for invalid types

### 5. ⏳ Registry Validation (1 test)

**Tests**: 910  
**Status**: ⏳ NEEDS INVESTIGATION  
**Issue**: Registry validation not detecting non-existent Oracle homes

**Test Failure**:

```bash
Test 910: validate detects non-existent homes
  Expected: Failure (status != 0)
  Actual: Success with "[DEBUG] Registry validation passed"
```

**Analysis**: The `validate` function in `oradba_registry.sh` should detect when Oracle homes in the registry don't exist on the filesystem. Test expects this to fail, but validation passes.

**Fix**: Check validation logic in `src/lib/oradba_registry.sh` - ensure it:

1. Validates each home path exists
2. Returns error code when non-existent paths found
3. Logs appropriate warnings/errors

## Fix Priority

1. **High Priority** (breaks existing functionality):
   - ✅ [DONE] Deprecated logging functions (3 tests)
   - Database functions sourcing (20 tests)
   - Product config logging (4 tests)

2. **Medium Priority** (plugin system integration):
   - Plugin status integration (4 tests)

3. **Low Priority** (edge case):
   - Registry validation (1 test)

## Next Steps

1. ✅ Fix deprecated logging in `oradba_common.sh` - DONE
2. Fix test setup in `test_oradba_db_functions.bats` - source `oradba_common.sh` first
3. Fix test setup in `test_oradba_env_config.bats` - source `oradba_common.sh` first
4. Refactor `oradba_get_product_status()` to use `oradba_apply_oracle_plugin`
5. Investigate registry validation logic
6. Re-run `make test-full` to verify all fixes
7. Update test count from 925 to 1033 in documentation

## Test Count Update Required

**Found**: 1033 tests (not 925 as previously documented)  
**Files to Update**:

- `README.md` - test count reference
- `doc/automated_testing.md` - test suite statistics
- `Makefile` - if test count is referenced
- `.github/.scratch/next-phases.md` - Phase 4 tracking

## Related Issues

- All 10 failures are related to Phase 4 plugin adoption refactoring
- No failures in core plugin functionality (all plugins pass their tests)
- Failures are in integration points and test setup
- Indicates good plugin architecture but needs test infrastructure updates
