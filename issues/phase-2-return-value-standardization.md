### Phase 2: Return Value Standardization (PARTIAL)

**Status:** ~50% Complete  
**Parent Issue:** #135  

**Remaining:**

1. Standardize `plugin_check_status()` (HIGH PRIORITY) (#140)
   - Implement tri-state exit codes:
     - `0 = running`, `1 = stopped`, `2 = unavailable/cannot determine`
   - Remove all status strings from output
   - Update all 9 plugins
   - Update tests

2. Update All Plugin Callers (HIGH PRIORITY) (#142)
   - Remove sentinel string parsing:
     - No more `if [[ "$output" != "ERR" ]]` patterns
   - Use exit codes only:
     - `if plugin_func; then ... fi`
   - Update error handling and logging
     - **Files affected:**
       - `oradba_common.sh` (`detect_oracle_version`, `get_oracle_version`)
       - `oradba_env_builder.sh` (all plugin invocations)
       - `oradba_env_validator.sh` (validation logic)
       - Any other scripts calling plugins

3. Comprehensive Function Audit (MEDIUM PRIORITY) (#141)
   - Audit ALL plugin functions (beyond `get_version/check_status`)
   - Check for remaining sentinel strings
   - Verify exit code consistency
   - Document all function contracts
   - Fix critical issues found

4. Function Naming Review (LOW PRIORITY) (#134)
   - Validate naming conventions consistent across plugins
   - Document extension/optional function patterns
   - May be largely complete after Phase 1 interface work

**Timeline:**
- Week 1: #140 (check_status standardization)
- Week 2: #142 (caller updates)
- Week 3: #141 (comprehensive audit), #134 (naming review).