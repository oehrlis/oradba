### Phase 2: Return Value Standardization

**Status:** ~50% Complete  
**Parent Issue:** #135  

**Remaining Tasks:**  
- Standardize `plugin_check_status()` (HIGH PRIORITY, #140)  
  - Implement tri-state exit codes (`0 = running`, `1 = stopped`, `2 = unavailable/cannot determine`)  
  - Remove all status strings from output  
  - Update all 9 plugins  
  - Update tests  

- Update All Plugin Callers (HIGH PRIORITY, #142)  
  - Remove sentinel string parsing (`if [[ "$output" != "ERR" ]]` patterns)  
  - Use exit codes only (`if plugin_func; then ... fi`)  
  - Update error handling and logging (affects files like `oradba_common.sh`, `oradba_env_builder.sh`, `oradba_env_validator.sh`)  

- Comprehensive Function Audit (MEDIUM PRIORITY, #141)  
  - Audit all plugin functions (beyond `get_version/check_status`), check for remaining sentinel strings, verify exit code consistency, document contracts, and fix issues  

- Function Naming Review (LOW PRIORITY, #134)  
  - Validate naming conventions, document patterns, and ensure consistency  

**Timeline:**  
Week 1: #140 (check_status standardization)  
Week 2: #142 (caller updates)  
Week 3: #141, #134.