# Core Utilities

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

---

## Functions

### `add_to_sqlpath` {: #add-to-sqlpath }

Add directory to SQLPATH if not already present

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Directory path to add to SQLPATH

**Returns:** 0 - Directory added or already in SQLPATH

**Output:** Debug message if directory added

!!! info "Notes"
    Example: add_to_sqlpath "/u01/app/oracle/dba/sql"

---

### `alias_exists` {: #alias-exists }

Check if an alias or command already exists

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Alias or command name to check

**Returns:** 0 if exists (as alias or command), 1 if not

**Output:** None

!!! info "Notes"
    Checks both shell aliases and commands in PATH

---

### `capture_sid_config_vars` {: #capture-sid-config-vars }

Capture variables set by SID-specific configuration

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - SID configuration file path

**Returns:** 0 - Successfully captured variables

**Output:** None (sets ORADBA_PREV_SID_VARS)

!!! info "Notes"
    Compares environment before and after loading SID config to track
    which variables were added. Stores list in ORADBA_PREV_SID_VARS for
    cleanup when switching SIDs.

---

### `cleanup_previous_sid_config` {: #cleanup-previous-sid-config }

Unset variables from previous SID-specific configuration

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 - Always successful

**Output:** Debug messages about cleanup

!!! info "Notes"
    Uses ORADBA_PREV_SID_VARS to track and unset variables set by
    previous SID configuration. This ensures clean environment isolation
    when switching between SIDs.

---

### `command_exists` {: #command-exists }

Check if a command is available in PATH

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Command name to check

**Returns:** 0 if command exists, 1 otherwise

**Output:** None

---

### `configure_sqlpath` {: #configure-sqlpath }

Configure SQLPATH for SQL\*Plus script discovery with priority order

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 - SQLPATH configured successfully

**Output:** None (exports SQLPATH variable)

!!! info "Notes"
    Priority: 1. Current dir, 2. OraDBA SQL, 3. SID-specific SQL,
    4. Oracle RDBMS admin, 5. Oracle sqlplus admin, 6. User custom SQL,
    7. Custom SQLPATH from config, 8. Existing SQLPATH (if preserve enabled).
    Example: configure_sqlpath

---

### `create_sid_config` {: #create-sid-config }

Create SID-specific configuration file from template

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - ORACLE_SID for which to create configuration

**Returns:** 0 - Configuration file created successfully

**Output:** Info messages about file creation

!!! info "Notes"
    Creates ${ORADBA_BASE}/etc/sid.ORCL.conf from template.
    Only tracks static metadata (DB_NAME, DBID, etc), not dynamic state.
    Example: create_sid_config "ORCL"

---

### `execute_db_query` {: #execute-db-query }

Execute SQL\*Plus query with standardized configuration and formatting

**Source:** `oradba_common.sh`

**Returns:** Query results in specified format

---

### `execute_plugin_function_v2` {: #execute-plugin-function-v2 }

Execute a plugin function in an isolated subshell with minimal env

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - product type (plugin name, e.g., database, datasafe)
- $2 - function name (without plugin_ prefix)
- $3 - ORACLE_HOME / base path (use "NOARGS" for no-arg functions)
- $4 - result variable name (optional)
- $5 - extra argument (optional)

**Returns:** Exit code from plugin function

**Output:** Stdout from plugin function (or stored in result variable)

!!! info "Notes"
    Adds subshell isolation (Phase 3) and minimal ORACLE_HOME/LD_LIBRARY_PATH
    For no-arg functions (e.g., plugin_get_config_section), pass "NOARGS" as oracle_home

---

### `get_oracle_version` {: #get-oracle-version }

Retrieve Oracle database version from sqlplus

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 on error

**Output:** Oracle version string (e.g., 19.0.0.0 or 23.26.0.0)

!!! info "Notes"
    Uses sqlplus if available, otherwise delegates to detect_oracle_version()
    for plugin-based detection (library filenames, JDBC JAR, etc.)

---

### `get_oratab_path` {: #get-oratab-path }

Determine the correct oratab file path using priority order

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if oratab found, 1 if not found

**Output:** Prints path to oratab file (even if doesn't exist)

!!! info "Notes"
    Priority: ORADBA_ORATAB \> /etc/oratab \> /var/opt/oracle/oratab \>
    ${ORADBA_BASE}/etc/oratab \> ${HOME}/.oratab

---

### `get_script_dir` {: #get-script-dir }

Get the absolute path of the script directory

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Absolute directory path

---

### `init_logging` {: #init-logging }

Initialize logging infrastructure and create log directories

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Creates ORADBA_LOG_DIR, sets ORADBA_LOG_FILE, ORADBA_ERROR_LOG

!!! info "Notes"
    Falls back to ${HOME}/.oradba/logs if /var/log not writable

---

### `init_session_log` {: #init-session-log }

Initialize session-specific log file for current execution

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Sets ORADBA_SESSION_LOG environment variable

---

### `is_dummy_sid` {: #is-dummy-sid }

Check if current Oracle SID is marked as dummy/template in oratab

**Source:** `oradba_common.sh`

**Arguments:**

- None (uses ORACLE_SID environment variable)

**Returns:** 0 if SID is dummy (:D flag in oratab), 1 otherwise

**Output:** None

!!! info "Notes"
    Dummy entries are marked with ':D' flag in oratab file

---

### `is_plugin_debug_enabled` {: #is-plugin-debug-enabled }

Check if plugin debug mode is enabled

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if plugin debug enabled, 1 otherwise

**Output:** None

!!! info "Notes"
    Plugin debug enabled when ORADBA_PLUGIN_DEBUG=true OR ORADBA_LOG_LEVEL=DEBUG/TRACE

---

### `is_plugin_trace_enabled` {: #is-plugin-trace-enabled }

Check if plugin trace mode is enabled (more verbose than debug)

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if plugin trace enabled, 1 otherwise

**Output:** None

!!! info "Notes"
    Plugin trace enabled only when ORADBA_LOG_LEVEL=TRACE

---

### `load_config` {: #load-config }

Load hierarchical configuration files in priority order (6 levels)

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - ORACLE_SID (optional, loads SID-specific config if provided)

**Returns:** 0 - Configuration loaded successfully

**Output:** Debug messages about which files are loaded

!!! info "Notes"
    Loads in order: core → standard → customer → default → sid-specific.
    Later configs override earlier settings.
    Example: load_config "ORCL"  # Loads all configs + ORCL-specific

---

### `load_config_file` {: #load-config-file }

Load single configuration file with error handling

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Configuration file path
- $2 - Required flag (optional): "required" to fail if file missing

**Returns:** 0 - File loaded successfully (or optional and not found)

**Output:** Debug messages about file loading

!!! info "Notes"
    Automatically logs debug messages and handles shellcheck source disable.
    Example: load_config_file "${ORADBA_BASE}/etc/oradba_core.conf" "required"

---

### `load_rman_catalog_connection` {: #load-rman-catalog-connection }

Load and validate RMAN catalog connection string

**Source:** `oradba_common.sh`

**Returns:** 0 on success, 1 if no catalog configured

!!! info "Notes"
    Updates ORADBA_RMAN_CATALOG_CONNECTION for use in aliases
    Catalog format: catalog user/password@tnsalias
    or catalog user@tnsalias (prompts for password)

---

### `oradba_log` {: #oradba-log }

Modern unified logging function with level filtering and color support

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Log level (TRACE|DEBUG|INFO|WARN|ERROR|SUCCESS|FAILURE|SECTION)
- $@ - Log message (remaining arguments)

**Returns:** 0 - Always successful

**Output:** Formatted log message to stderr (and optional log files)

!!! info "Notes"
    Respects ORADBA_LOG_LEVEL for filtering (default: INFO)
    Supports color output (disable with ORADBA_NO_COLOR=1)
    Dual logging to ORADBA_LOG_FILE and ORADBA_SESSION_LOG
    Legacy DEBUG=1 support for backward compatibility
    TRACE level is finer than DEBUG for very detailed diagnostics
    Replaces deprecated log_info/log_warn/log_error/log_debug functions

---

### `safe_alias` {: #safe-alias }

Create alias respecting coexistence mode with other Oracle environments

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Alias name
- $2 - Alias value/command

**Returns:** 0 - Alias created successfully

**Output:** Debug message if alias skipped

!!! info "Notes"
    Respects ORADBA_COEXIST_MODE and ORADBA_FORCE settings.
    Example: safe_alias "ora19" "set_oracle_env 19.0.0"

---

### `sanitize_sensitive_data` {: #sanitize-sensitive-data }

Sanitize sensitive data from log output (passwords, connection strings)

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Text to sanitize

**Returns:** 0 - Always successful

**Output:** Sanitized text to stdout

!!! info "Notes"
    Masks passwords in common formats (sqlplus, rman, connection strings)
    Pattern examples:
    - sqlplus user/pass@db -\> sqlplus user/***@db
    - rman target user/pass -\> rman target user/***
    - PASSWORD=secret -\> PASSWORD=***
    - pwd=secret -\> pwd=***

---

### `set_oracle_home_environment` {: #set-oracle-home-environment }

Set environment variables for a specific Oracle Home

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name or alias
- $2 - Oracle Home path (optional, will lookup if not provided)
- $3 - Defer path config helpers (optional, true/false; default: false)

**Returns:** 0 - Environment set successfully

**Output:** Debug/error messages via oradba_log

!!! info "Notes"
    Sets ORACLE_HOME, ORACLE_BASE, PATH, LD_LIBRARY_PATH, etc.
    Example: set_oracle_home_environment "ora19"

---

### `show_config` {: #show-config }

Display OraDBA configuration hierarchy and load order

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Formatted display of configuration files with status

!!! info "Notes"
    Shows Phase 1-4 config hierarchy: core → standard → customer →
    local → SID-specific, with [✓ loaded] or [✗ MISSING] status

---

### `show_path` {: #show-path }

Display current PATH directories with existence check

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if PATH not set

**Output:** Numbered list of PATH directories with status indicators

!!! info "Notes"
    Shows [✓] for existing directories, [✗ not found] for missing ones

---

### `show_sqlpath` {: #show-sqlpath }

Display current SQLPATH directories with existence check

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success, 1 if SQLPATH not set

**Output:** Numbered list of SQLPATH directories with status indicators

!!! info "Notes"
    Shows [✓] for existing directories, [✗ not found] for missing ones

---

### `validate_directory` {: #validate-directory }

Validate directory exists and optionally create it

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Directory path to validate
- $2 - Create flag (optional): "create" to create if missing

**Returns:** 0 - Directory exists or was created successfully

**Output:** Error messages to stderr if directory validation/creation fails

!!! info "Notes"
    Example: validate_directory "/u01/app/oracle" "create"

---

### `verify_oracle_env` {: #verify-oracle-env }

Verify required Oracle environment variables are set

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if all required vars set, 1 if any missing

**Output:** Error message listing missing variables

!!! info "Notes"
    Checks ORACLE_SID and ORACLE_HOME

---
