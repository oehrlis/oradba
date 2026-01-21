# Core Utilities

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

---

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

Configure SQLPATH for SQL*Plus script discovery with priority order

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
### `derive_oracle_base` {: #derive-oracle-base }

Derive ORACLE_BASE from ORACLE_HOME by searching upward

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success, 1 if unable to derive

**Output:** Derived ORACLE_BASE path

!!! info "Notes"
    Searches upward for directory containing "product", "oradata",
    "oraInventory", or "admin" (max 5 levels)

---
### `detect_oracle_version` {: #detect-oracle-version }

Detect Oracle version from ORACLE_HOME path

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - Product type (optional, will detect if not provided)

**Returns:** 0 on success, 1 on error

**Output:** Oracle version in format XXYZ (e.g., 1920 for 19.2.0, 2301 for 23.1)

!!! info "Notes"
    Delegates to product plugin if available, otherwise uses fallback methods
    Plugin detection via plugin_get_version() (returns X.Y.Z.W format)
    Fallback methods: sqlplus, OPatch, inventory XML, path parsing

---
### `detect_product_type` {: #detect-product-type }

Detect Oracle product type from ORACLE_HOME path

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success, 1 if unable to detect

**Output:** Product type: database, client, iclient, java, oud, weblogic, oms,

!!! info "Notes"
    Checks for specific files/directories to identify product type

---
### `discover_running_oracle_instances` {: #discover-running-oracle-instances }

Auto-discover running Oracle instances when oratab is empty

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if instances discovered, 1 if none found

**Output:** Prints discovered instances in oratab format (SID:ORACLE_HOME:N)

!!! info "Notes"
    - Only checks processes owned by current user
    - Detects db_smon_*, ora_pmon_*, asm_smon_* processes
    - Extracts ORACLE_HOME from /proc/<pid>/exe
    - Adds temporary entries with startup flag 'N'
    - Shows warning if Oracle processes run as different user

---
### `execute_db_query` {: #execute-db-query }

Execute SQL*Plus query with standardized configuration and formatting

**Source:** `oradba_common.sh`

**Returns:** Query results in specified format

---
### `generate_oracle_home_aliases` {: #generate-oracle-home-aliases }

Create shell aliases for all registered Oracle Homes

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Creates shell aliases for Oracle Home switching

!!! info "Notes"
    Creates aliases for both NAME and ALIAS_NAME entries
    Example: DBHOMEFREE and rdbms26 both point to same home

---
### `generate_pdb_aliases` {: #generate-pdb-aliases }

Generate aliases for PDBs in the current CDB

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Creates shell aliases for each PDB and exports ORADBA_PDBLIST

---
### `generate_sid_lists` {: #generate-sid-lists }

Generate SID lists and aliases from oratab and Oracle Homes config

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - (Optional) Path to oratab file (defaults to get_oratab_path)

**Returns:** 0 on success, 1 if oratab not found

**Output:** Sets ORADBA_SIDLIST and ORADBA_REALSIDLIST environment variables

!!! info "Notes"
    SIDLIST includes all SIDs and aliases, REALSIDLIST excludes dummies

---
### `get_install_info` {: #get-install-info }

Get installation metadata value by key

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Metadata key to retrieve

**Returns:** 0 - Key found and value retrieved

**Output:** Value for the specified key

!!! info "Notes"
    Supports both old format (install_version) and new format (version).
    Example: install_date=$(get_install_info "install_date")

---
### `get_oracle_home_alias` {: #get-oracle-home-alias }

Get alias name for a registered Oracle Home

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name

**Returns:** 0 on success, 1 if not found

**Output:** Alias name (or home name if no alias defined)

!!! info "Notes"
    Reads from oradba_homes.conf, column 5 (ALIAS_NAME)

---
### `get_oracle_home_path` {: #get-oracle-home-path }

Get ORACLE_HOME path for a registered Oracle Home

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name

**Returns:** 0 on success, 1 if not found

**Output:** ORACLE_HOME path

!!! info "Notes"
    Reads from oradba_homes.conf, column 2 (PATH)

---
### `get_oracle_home_type` {: #get-oracle-home-type }

Get product type for a registered Oracle Home

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name

**Returns:** 0 on success, 1 if not found

**Output:** Product type (database, client, oud, weblogic, oms, emagent, etc.)

!!! info "Notes"
    Reads from oradba_homes.conf, column 3 (TYPE)

---
### `get_oracle_homes_path` {: #get-oracle-homes-path }

Get path to oradba_homes.conf configuration file

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if file exists, 1 if not found

**Output:** Prints path to oradba_homes.conf

!!! info "Notes"
    Looks for ${ORADBA_BASE}/etc/oradba_homes.conf

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
### `get_oradba_version` {: #get-oradba-version }

Get OraDBA version from VERSION file

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 - Version retrieved successfully

**Output:** Version string (e.g., "1.0.0-dev") or "unknown"

!!! info "Notes"
    Example: version=$(get_oradba_version)

---
### `get_oratab_path` {: #get-oratab-path }

Determine the correct oratab file path using priority order

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 if oratab found, 1 if not found

**Output:** Prints path to oratab file (even if doesn't exist)

!!! info "Notes"
    Priority: ORADBA_ORATAB > /etc/oratab > /var/opt/oracle/oratab >
    ${ORADBA_BASE}/etc/oratab > ${HOME}/.oratab

---
### `get_script_dir` {: #get-script-dir }

Get the absolute path of the script directory

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Absolute directory path

---
### `init_install_info` {: #init-install-info }

Initialize installation info file with metadata

**Source:** `oradba_common.sh`

**Arguments:**

- None

**Returns:** 0 - Installation info initialized successfully

**Output:** Info message about initialization

!!! info "Notes"
    Uses lowercase keys without quotes to match installer format.
    Creates ${ORADBA_BASE}/.install_info with install metadata.
    Example: init_install_info

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
### `is_oracle_home` {: #is-oracle-home }

Check if given name refers to an Oracle Home (vs database SID)

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Name to check (Oracle Home name/alias or SID)

**Returns:** 0 - Name is an Oracle Home

**Output:** None

!!! info "Notes"
    Example: if is_oracle_home "ora19"; then echo "Oracle Home"; fi

---
### `list_oracle_homes` {: #list-oracle-homes }

List all Oracle Homes from oradba_homes.conf

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - (Optional) Filter by product type

**Returns:** 0 on success, 1 if config file not found

**Output:** One line per home: NAME PATH TYPE ORDER ALIAS DESCRIPTION VERSION

!!! info "Notes"
    Output sorted by ORDER (column 4), ascending

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

- $1 - Log level (DEBUG|INFO|WARN|ERROR|SUCCESS|FAILURE|SECTION)
- $@ - Log message (remaining arguments)

**Returns:** 0 - Always successful

**Output:** Formatted log message to stderr (and optional log files)

!!! info "Notes"
    Respects ORADBA_LOG_LEVEL for filtering (default: INFO)
    Supports color output (disable with ORADBA_NO_COLOR=1)
    Dual logging to ORADBA_LOG_FILE and ORADBA_SESSION_LOG
    Legacy DEBUG=1 support for backward compatibility
    Replaces deprecated log_info/log_warn/log_error/log_debug functions

---
### `parse_oracle_home` {: #parse-oracle-home }

Parse Oracle Home configuration entry from oradba_homes.conf

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name or alias to parse

**Returns:** 0 - Successfully parsed

**Output:** Space-separated values: name alias type path version

!!! info "Notes"
    Example: read -r oh_name oh_alias oh_type oh_path oh_version < <(parse_oracle_home "ora19")
    Returns: "ora19 19c database /u01/app/oracle/product/19.3.0/dbhome_1 19.3.0"

---
### `parse_oratab` {: #parse-oratab }

Parse oratab file to get Oracle home path for a SID

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle SID to look up
- $2 - (Optional) Path to oratab file (defaults to get_oratab_path)

**Returns:** 0 if SID found, 1 if not found or error

**Output:** Oracle home path for the specified SID

!!! info "Notes"
    Skips comment lines and dummy entries (:D flag)

---
### `persist_discovered_instances` {: #persist-discovered-instances }

Write auto-discovered instances to oratab file with fallback

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Discovered oratab entries (multi-line string)
- $2 - Target oratab file (optional, defaults to ORATAB_FILE)

**Returns:** 0 - Successfully persisted

**Output:** Appends entries to oratab, logs warnings/info

!!! info "Notes"
    - Tries system oratab first (e.g., /etc/oratab)
    - Falls back to local oratab if permission denied
    - Checks for duplicates before adding
    - Updates ORATAB_FILE if fallback used
    Example: persist_discovered_instances "$discovered_data"

---
### `resolve_oracle_home_name` {: #resolve-oracle-home-name }

Resolve Oracle Home alias to actual NAME from oradba_homes.conf

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Name or alias to resolve

**Returns:** 0 on success, 1 if not found or error

**Output:** Actual Oracle Home NAME (or original if not found)

!!! info "Notes"
    Checks both NAME and ALIAS_NAME columns in oradba_homes.conf

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
### `set_install_info` {: #set-install-info }

Set installation metadata key-value pair

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Metadata key
- $2 - Metadata value

**Returns:** 0 - Key-value set successfully

**Output:** None

!!! info "Notes"
    Uses lowercase keys without quotes for consistency with installer.
    Example: set_install_info "install_date" "2026-01-14"

---
### `set_oracle_home_environment` {: #set-oracle-home-environment }

Set environment variables for a specific Oracle Home

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Oracle Home name or alias
- $2 - Oracle Home path (optional, will lookup if not provided)

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
### `version_compare` {: #version-compare }

Compare two semantic version strings

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - First version string (e.g., "1.2.3")
- $2 - Second version string (e.g., "1.2.0")

**Returns:** 0 - Versions are equal

**Output:** None

!!! info "Notes"
    Example: version_compare "1.2.3" "1.2.0"; result=$?  # Returns 1

---
### `version_meets_requirement` {: #version-meets-requirement }

Check if current version meets minimum requirement

**Source:** `oradba_common.sh`

**Arguments:**

- $1 - Current version string
- $2 - Required version string

**Returns:** 0 - Current version meets requirement (>=)

**Output:** None

!!! info "Notes"
    Example: if version_meets_requirement "1.2.3" "1.2.0"; then echo "OK"; fi

---
