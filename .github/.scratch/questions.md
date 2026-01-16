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

