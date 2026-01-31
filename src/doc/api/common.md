# Core Utilities

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_script_dir`

---

### ``

Get the absolute path of the script directory

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Absolute directory path

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `init_logging`

---

### ``

Initialize logging infrastructure and create log directories

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates ORADBA_LOG_DIR, sets ORADBA_LOG_FILE, ORADBA_ERROR_LOG

---

### ``

!!! info "Notes"
    Falls back to ${HOME}/.oradba/logs if /var/log not writable

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `init_session_log`

---

### ``

Initialize session-specific log file for current execution

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Sets ORADBA_SESSION_LOG environment variable

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `oradba_log`

---

### ``

Modern unified logging function with level filtering and color support

---

### ``

**Arguments:**

- $1 - Log level (DEBUG|INFO|WARN|ERROR|SUCCESS|FAILURE|SECTION)

---

### ``

**Returns:** 0 - Always successful

---

### ``

**Output:** Formatted log message to stderr (and optional log files)

---

### ``

!!! info "Notes"
    Respects ORADBA_LOG_LEVEL for filtering (default: INFO)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `execute_db_query`

---

### ``

Execute SQL*Plus query with standardized configuration and formatting

---

### ``

---

### ``

**Returns:** Query results in specified format

---

### ``

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oratab_path`

---

### ``

Determine the correct oratab file path using priority order

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if oratab found, 1 if not found

---

### ``

**Output:** Prints path to oratab file (even if doesn't exist)

---

### ``

!!! info "Notes"
    Priority: ORADBA_ORATAB > /etc/oratab > /var/opt/oracle/oratab >

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `is_dummy_sid`

---

### ``

Check if current Oracle SID is marked as dummy/template in oratab

---

### ``

**Arguments:**

- None (uses ORACLE_SID environment variable)

---

### ``

**Returns:** 0 if SID is dummy (:D flag in oratab), 1 otherwise

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Dummy entries are marked with ':D' flag in oratab file

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `command_exists`

---

### ``

Check if a command is available in PATH

---

### ``

**Arguments:**

- $1 - Command name to check

---

### ``

**Returns:** 0 if command exists, 1 otherwise

---

### ``

**Output:** None

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `alias_exists`

---

### ``

Check if an alias or command already exists

---

### ``

**Arguments:**

- $1 - Alias or command name to check

---

### ``

**Returns:** 0 if exists (as alias or command), 1 if not

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Checks both shell aliases and commands in PATH

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `safe_alias`

---

### ``

Create alias respecting coexistence mode with other Oracle environments

---

### ``

**Arguments:**

- $1 - Alias name

---

### ``

**Returns:** 0 - Alias created successfully

---

### ``

**Output:** Debug message if alias skipped

---

### ``

!!! info "Notes"
    Respects ORADBA_COEXIST_MODE and ORADBA_FORCE settings.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `verify_oracle_env`

---

### ``

Verify required Oracle environment variables are set

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if all required vars set, 1 if any missing

---

### ``

**Output:** Error message listing missing variables

---

### ``

!!! info "Notes"
    Checks ORACLE_SID and ORACLE_HOME

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oracle_version`

---

### ``

Retrieve Oracle database version from sqlplus

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Oracle version string (e.g., 19.0.0.0 or 23.26.0.0)

---

### ``

!!! info "Notes"
    Uses sqlplus if available, otherwise delegates to detect_oracle_version()

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `parse_oratab`

---

### ``

Parse oratab file to get Oracle home path for a SID

---

### ``

**Arguments:**

- $1 - Oracle SID to look up

---

### ``

**Returns:** 0 if SID found, 1 if not found or error

---

### ``

**Output:** Oracle home path for the specified SID

---

### ``

!!! info "Notes"
    Skips comment lines and dummy entries (:D flag)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `generate_sid_lists`

---

### ``

Generate SID lists and aliases from oratab and Oracle Homes config

---

### ``

**Arguments:**

- $1 - (Optional) Path to oratab file (defaults to get_oratab_path)

---

### ``

**Returns:** 0 on success, 1 if oratab not found

---

### ``

**Output:** Sets ORADBA_SIDLIST and ORADBA_REALSIDLIST environment variables

---

### ``

!!! info "Notes"
    SIDLIST includes all SIDs and aliases, REALSIDLIST excludes dummies

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `generate_oracle_home_aliases`

---

### ``

Create shell aliases for all registered Oracle Homes

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates shell aliases for Oracle Home switching

---

### ``

!!! info "Notes"
    Creates aliases for both NAME and ALIAS_NAME entries

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `generate_pdb_aliases`

---

### ``

Generate aliases for PDBs in the current CDB

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Creates shell aliases for each PDB and exports ORADBA_PDBLIST

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `load_rman_catalog_connection`

---

### ``

Load and validate RMAN catalog connection string

---

### ``

---

### ``

**Returns:** 0 on success, 1 if no catalog configured

---

### ``

---

### ``

!!! info "Notes"
    Updates ORADBA_RMAN_CATALOG_CONNECTION for use in aliases

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `discover_running_oracle_instances`

---

### ``

Auto-discover running Oracle instances when oratab is empty

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if instances discovered, 1 if none found

---

### ``

**Output:** Prints discovered instances in oratab format (SID:ORACLE_HOME:N)

---

### ``

!!! info "Notes"
    - Only checks processes owned by current user

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `persist_discovered_instances`

---

### ``

Validate directory exists and optionally create it

---

### ``

**Arguments:**

- $1 - Discovered oratab entries (multi-line string)

---

### ``

---

### ``

**Returns:** 0 - Directory exists or was created successfully

---

### ``

**Output:** Error messages to stderr if directory validation/creation fails

---

### ``

!!! info "Notes"
    Example: validate_directory "/u01/app/oracle" "create"

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `validate_directory`

---

### ``

Validate directory exists and optionally create it

---

### ``

**Arguments:**

- $1 - Directory path to validate

---

### ``

**Returns:** 0 - Directory exists or was created successfully

---

### ``

**Output:** Error messages to stderr if directory validation/creation fails

---

### ``

!!! info "Notes"
    Example: validate_directory "/u01/app/oracle" "create"

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oracle_homes_path`

---

### ``

Get path to oradba_homes.conf configuration file

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if file exists, 1 if not found

---

### ``

**Output:** Prints path to oradba_homes.conf

---

### ``

!!! info "Notes"
    Looks for ${ORADBA_BASE}/etc/oradba_homes.conf

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `resolve_oracle_home_name`

---

### ``

Resolve Oracle Home alias to actual NAME from oradba_homes.conf

---

### ``

**Arguments:**

- $1 - Name or alias to resolve

---

### ``

**Returns:** 0 on success, 1 if not found or error

---

### ``

**Output:** Actual Oracle Home NAME (or original if not found)

---

### ``

!!! info "Notes"
    Checks both NAME and ALIAS_NAME columns in oradba_homes.conf

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `parse_oracle_home`

---

### ``

Parse Oracle Home configuration entry from oradba_homes.conf

---

### ``

**Arguments:**

- $1 - Oracle Home name or alias to parse

---

### ``

**Returns:** 0 - Successfully parsed

---

### ``

**Output:** Space-separated values: name alias type path version

---

### ``

!!! info "Notes"
    Example: read -r oh_name oh_alias oh_type oh_path oh_version < <(parse_oracle_home "ora19")

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `list_oracle_homes`

---

### ``

List all Oracle Homes from oradba_homes.conf

---

### ``

**Arguments:**

- $1 - (Optional) Filter by product type

---

### ``

**Returns:** 0 on success, 1 if config file not found

---

### ``

**Output:** One line per home: NAME PATH TYPE ORDER ALIAS DESCRIPTION VERSION

---

### ``

!!! info "Notes"
    Output sorted by ORDER (column 4), ascending

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oracle_home_path`

---

### ``

Get ORACLE_HOME path for a registered Oracle Home

---

### ``

**Arguments:**

- $1 - Oracle Home name

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** ORACLE_HOME path

---

### ``

!!! info "Notes"
    Reads from oradba_homes.conf, column 2 (PATH)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oracle_home_alias`

---

### ``

Get alias name for a registered Oracle Home

---

### ``

**Arguments:**

- $1 - Oracle Home name

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Alias name (or home name if no alias defined)

---

### ``

!!! info "Notes"
    Reads from oradba_homes.conf, column 5 (ALIAS_NAME)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oracle_home_type`

---

### ``

Get product type for a registered Oracle Home

---

### ``

**Arguments:**

- $1 - Oracle Home name

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Product type (database, client, oud, weblogic, oms, emagent, etc.)

---

### ``

!!! info "Notes"
    Reads from oradba_homes.conf, column 3 (TYPE)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `detect_product_type`

---

### ``

Detect Oracle product type from ORACLE_HOME path

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success, 1 if unable to detect

---

### ``

**Output:** Product type: database, client, iclient, java, oud, weblogic, oms,

---

### ``

!!! info "Notes"
    Checks for specific files/directories to identify product type

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `detect_oracle_version`

---

### ``

Detect Oracle version from ORACLE_HOME path

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Oracle version in format XXYZ (e.g., 1920 for 19.2.0, 2301 for 23.1)

---

### ``

!!! info "Notes"
    Delegates to product plugin if available, otherwise uses fallback methods

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `derive_oracle_base`

---

### ``

Derive ORACLE_BASE from ORACLE_HOME by searching upward

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success, 1 if unable to derive

---

### ``

**Output:** Derived ORACLE_BASE path

---

### ``

!!! info "Notes"
    Searches upward for directory containing "product", "oradata",

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `set_oracle_home_environment`

---

### ``

Set environment variables for a specific Oracle Home

---

### ``

**Arguments:**

- $1 - Oracle Home name or alias

---

### ``

**Returns:** 0 - Environment set successfully

---

### ``

**Output:** Debug/error messages via oradba_log

---

### ``

!!! info "Notes"
    Sets ORACLE_HOME, ORACLE_BASE, PATH, LD_LIBRARY_PATH, etc.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `is_oracle_home`

---

### ``

Check if given name refers to an Oracle Home (vs database SID)

---

### ``

**Arguments:**

- $1 - Name to check (Oracle Home name/alias or SID)

---

### ``

**Returns:** 0 - Name is an Oracle Home

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Example: if is_oracle_home "ora19"; then echo "Oracle Home"; fi

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `cleanup_previous_sid_config`

---

### ``

Unset variables from previous SID-specific configuration

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 - Always successful

---

### ``

**Output:** Debug messages about cleanup

---

### ``

!!! info "Notes"
    Uses ORADBA_PREV_SID_VARS to track and unset variables set by

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `capture_sid_config_vars`

---

### ``

Capture variables set by SID-specific configuration

---

### ``

**Arguments:**

- $1 - SID configuration file path

---

### ``

**Returns:** 0 - Successfully captured variables

---

### ``

**Output:** None (sets ORADBA_PREV_SID_VARS)

---

### ``

!!! info "Notes"
    Compares environment before and after loading SID config to track

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `load_config_file`

---

### ``

Load single configuration file with error handling

---

### ``

**Arguments:**

- $1 - Configuration file path

---

### ``

**Returns:** 0 - File loaded successfully (or optional and not found)

---

### ``

**Output:** Debug messages about file loading

---

### ``

!!! info "Notes"
    Automatically logs debug messages and handles shellcheck source disable.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `load_config_file`

---

### ``

Load single configuration file with error handling

---

### ``

**Arguments:**

- $1 - Configuration file path

---

### ``

**Returns:** 0 - File loaded successfully (or optional and not found)

---

### ``

**Output:** Debug messages about file loading

---

### ``

!!! info "Notes"
    Automatically logs debug messages and handles shellcheck source disable.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `create_sid_config`

---

### ``

Create SID-specific configuration file from template

---

### ``

**Arguments:**

- $1 - ORACLE_SID for which to create configuration

---

### ``

**Returns:** 0 - Configuration file created successfully

---

### ``

**Output:** Info messages about file creation

---

### ``

!!! info "Notes"
    Creates ${ORADBA_BASE}/etc/sid.ORCL.conf from template.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_oradba_version`

---

### ``

Get OraDBA version from VERSION file

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 - Version retrieved successfully

---

### ``

**Output:** Version string (e.g., "1.0.0-dev") or "unknown"

---

### ``

!!! info "Notes"
    Example: version=$(get_oradba_version)

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `version_compare`

---

### ``

Compare two semantic version strings

---

### ``

**Arguments:**

- $1 - First version string (e.g., "1.2.3")

---

### ``

**Returns:** 0 - Versions are equal

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Example: version_compare "1.2.3" "1.2.0"; result=$?  # Returns 1

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `version_meets_requirement`

---

### ``

Check if current version meets minimum requirement

---

### ``

**Arguments:**

- $1 - Current version string

---

### ``

**Returns:** 0 - Current version meets requirement (>=)

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Example: if version_meets_requirement "1.2.3" "1.2.0"; then echo "OK"; fi

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `get_install_info`

---

### ``

Get installation metadata value by key

---

### ``

**Arguments:**

- $1 - Metadata key to retrieve

---

### ``

**Returns:** 0 - Key found and value retrieved

---

### ``

**Output:** Value for the specified key

---

### ``

!!! info "Notes"
    Supports both old format (install_version) and new format (version).

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `set_install_info`

---

### ``

Set installation metadata key-value pair

---

### ``

**Arguments:**

- $1 - Metadata key

---

### ``

**Returns:** 0 - Key-value set successfully

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Uses lowercase keys without quotes for consistency with installer.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `init_install_info`

---

### ``

Initialize installation info file with metadata

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 - Installation info initialized successfully

---

### ``

**Output:** Info message about initialization

---

### ``

!!! info "Notes"
    Uses lowercase keys without quotes to match installer format.

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `configure_sqlpath`

---

### ``

Configure SQLPATH for SQL*Plus script discovery with priority order

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 - SQLPATH configured successfully

---

### ``

**Output:** None (exports SQLPATH variable)

---

### ``

!!! info "Notes"
    Priority: 1. Current dir, 2. OraDBA SQL, 3. SID-specific SQL,

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `show_sqlpath`

---

### ``

Display current SQLPATH directories with existence check

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if SQLPATH not set

---

### ``

**Output:** Numbered list of SQLPATH directories with status indicators

---

### ``

!!! info "Notes"
    Shows [✓] for existing directories, [✗ not found] for missing ones

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `show_path`

---

### ``

Display current PATH directories with existence check

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success, 1 if PATH not set

---

### ``

**Output:** Numbered list of PATH directories with status indicators

---

### ``

!!! info "Notes"
    Shows [✓] for existing directories, [✗ not found] for missing ones

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `show_config`

---

### ``

Display OraDBA configuration hierarchy and load order

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Formatted display of configuration files with status

---

### ``

!!! info "Notes"
    Shows Phase 1-4 config hierarchy: core → standard → customer →

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `add_to_sqlpath`

---

### ``

Add directory to SQLPATH if not already present

---

### ``

**Arguments:**

- $1 - Directory path to add to SQLPATH

---

### ``

**Returns:** 0 - Directory added or already in SQLPATH

---

### ``

**Output:** Debug message if directory added

---

### ``

!!! info "Notes"
    Example: add_to_sqlpath "/u01/app/oracle/dba/sql"

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `auto_discover_oracle_homes`

---

### ``

Auto-discover Oracle Homes and add to oradba_homes.conf

---

### ``

**Arguments:**

- $1 - Discovery paths (optional, defaults to ORADBA_DISCOVERY_PATHS)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Discovery summary (unless silent)

---

### ``

!!! info "Notes"
    Issue #70 - Unified auto-discovery function

---

### ``

**Source:** `oradba_common.sh`

---

### ``

---

### `oradba_apply_oracle_plugin`

---

### ``

Load and execute a plugin function dynamically

---

### ``

**Arguments:**

- $1 - Function name (without "plugin_" prefix)

---

### ``

**Returns:** Plugin function exit code, 1 if plugin not found

---

### ``

**Output:** Plugin function output (or stored in result variable)

---

### ``

!!! info "Notes"
    Dynamically loads plugins if not already loaded

---

