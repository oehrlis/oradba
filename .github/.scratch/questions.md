# Questions

Questions regarding the refactoring plan and architecture review.

## Client Plugin

**Question:** Do we implement a dedicated client plugin or is this part of the core functionality or the database plugin?

**Answer:** **Yes, implement a dedicated `client_plugin.sh`**

**Rationale:**

1. **Separation of Concerns**: Oracle Client has distinct characteristics:
   - No pmon process to check
   - No database instances to manage
   - Different validation (no `rdbms/` directory)
   - Different PATH/LD_LIBRARY_PATH handling
   - No listener status to show

2. **Product-Specific Behavior**:
   - **Full Client** (`/bin/sqlplus` exists, has `network/admin`)
   - **Instant Client** (`libclntsh.so`, no `bin/` subdirectory)
   - Status: Always "available" (not "running" like databases)
   - Should NOT appear in listener section

3. **Clean Architecture**:
   ```
   database_plugin.sh  → Handles RDBMS homes (has rdbms/, pmon)
   client_plugin.sh    → Handles full client (has bin/sqlplus)
   iclient_plugin.sh   → Handles instant client (libclntsh.so)
   ```

4. **Implementation Example**:
   ```bash
   # client_plugin.sh
   plugin_validate_home() {
       [[ -f "$1/bin/sqlplus" ]] || [[ -f "$1/bin/sqlplus.exe" ]]
   }
   
   plugin_check_status() {
       echo "available"  # Clients don't "run"
   }
   
   plugin_should_show_listener() {
       return 1  # Never show listener for client-only
   }
   ```

5. **Current OraDBA Support**: Already distinguishes client from database:
   - `detect_product_type()` returns "client" or "iclient"
   - `oradba_homes.conf` has client entries
   - Different environment setup in `oradba_env_builder.sh`

**Decision:** Create separate plugins for client and iclient in Phase 2 for clean separation.

## Plugin Detection Architecture

**Question:** Some plugins use hardcoded paths in `plugin_detect_installation()` to auto-detect installations (e.g., `/u01/app/oracle`, `/opt/oracle`). Should we:
1. Keep hardcoded paths (simple, works for most cases)?
2. Extend the interface to pass additional information like:
   - oratab entries (for context-aware discovery)
   - Configuration values from oradba_core.conf (e.g., `ORADBA_ORACLE_BASE`)
   - Environment variables (e.g., `ORACLE_BASE`, `ORACLE_HOME`)
3. Or use a hybrid approach?

**Answer:** **Use hybrid approach with optional context**

**Rationale:**

1. **Current Design is Good for Phase 2**:
   - Hardcoded paths work for 90% of installations
   - Plugins are self-contained and simple
   - No dependencies on external state
   - Easy to test in isolation

2. **Future Enhancement (Phase 3)**:
   - Add optional context parameter to `plugin_detect_installation()`
   - Keep backward compatibility (context optional)
   - Example: `plugin_detect_installation "${ORACLE_BASE:-}"`
   - Plugins can fall back to defaults if context empty

3. **Why Not Now**:
   - Phase 2 focus: Get basic plugins working
   - Avoid premature optimization
   - Can refactor in Phase 3 if needed
   - Current approach is testable and maintainable

4. **Alternative Solutions**:
   - Environment variables already available in plugin scope
   - Plugins can access `${ORACLE_BASE}` if set
   - Can source oradba_common.sh for utility functions

**Decision:** Keep current hardcoded paths for Phase 2. Consider optional context parameter in Phase 3 if real-world usage shows need for it.

##