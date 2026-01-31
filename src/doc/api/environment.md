# Environment Management

Environment management libraries for building, parsing, validating, and tracking Oracle environments.

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_dedupe_path`

---

### ``

Remove duplicate entries from PATH-like variables

---

### ``

**Arguments:**

- $1 - Path string (colon-separated)

---

### ``

**Returns:** Deduplicated path string

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_clean_path`

---

### ``

Remove Oracle-related directories from PATH

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Cleaned PATH exported

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_add_oracle_path`

---

### ``

Add Oracle binaries to PATH using plugin system

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

!!! info "Notes"
    Uses plugin_build_bin_path() from product-specific plugins

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_set_lib_path`

---

### ``

Detect Read-Only Oracle Home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

---

### ``

**Returns:** 0 if ROOH, 1 if not ROOH or cannot determine

---

### ``

**Output:** Sets ORACLE_BASE, ORADBA_ROOH, ORADBA_DBS

---

### ``

!!! info "Notes"
    Uses plugin_build_lib_path() from product-specific plugins

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_detect_rooh`

---

### ``

Detect Read-Only Oracle Home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 if ROOH, 1 if not ROOH or cannot determine

---

### ``

**Output:** Sets ORACLE_BASE, ORADBA_ROOH, ORADBA_DBS

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_is_asm_instance`

---

### ``

Check if SID is an ASM instance

---

### ``

**Arguments:**

- $1 - SID

---

### ``

**Returns:** 0 if ASM, 1 if not

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_set_oracle_vars`

---

### ``

Set core Oracle environment variables

---

### ``

**Arguments:**

- $1 - ORACLE_SID

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_set_asm_environment`

---

### ``

Set ASM-specific environment variables

---

### ``

**Arguments:**

- None (uses ORACLE_SID, ORACLE_HOME)

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_set_product_environment`

---

### ``

Set product-specific environment variables

---

### ``

**Arguments:**

- $1 - Product type

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_product_needs_client`

---

### ``

Determine if a product type needs external client tools

---

### ``

**Arguments:**

- $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)

---

### ``

**Returns:** 0 if product needs client, 1 if it has its own client

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_resolve_client_home`

---

### ``

Resolve client home path from ORADBA_CLIENT_PATH_FOR_NON_CLIENT setting

---

### ``

**Arguments:**

- None (reads ORADBA_CLIENT_PATH_FOR_NON_CLIENT env var)

---

### ``

**Returns:** 0 on success, 1 if no client found

---

### ``

**Output:** Prints resolved client home path

---

### ``

!!! info "Notes"
    Accepts DATABASE, CLIENT, or ICLIENT product types

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_add_client_path`

---

### ``

Add client tools to PATH for non-client products

---

### ``

**Arguments:**

- $1 - Current product type (uppercase)

---

### ``

**Returns:** 0 on success or not needed, 1 on error

---

### ``

---

### ``

!!! info "Notes"
    Appends client bin directory to PATH after existing entries

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_product_needs_java`

---

### ``

Determine if a product type needs Java (JAVA_HOME)

---

### ``

**Arguments:**

- $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)

---

### ``

**Returns:** 0 if product needs Java, 1 if it has its own or doesn't need Java

---

### ``

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_resolve_java_home`

---

### ``

Resolve Java home path from ORADBA_JAVA_PATH_FOR_NON_JAVA setting

---

### ``

**Arguments:**

- $1 - Current ORACLE_HOME (optional, for auto-detection of $ORACLE_HOME/java)

---

### ``

**Returns:** 0 on success, 1 if no Java found

---

### ``

**Output:** Prints resolved Java home path

---

### ``

!!! info "Notes"
    Supports "auto", "none", or named Java from oradba_homes.conf

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_add_java_path`

---

### ``

Add Java to JAVA_HOME and PATH for products that need it

---

### ``

**Arguments:**

- $1 - Current product type (uppercase)

---

### ``

**Returns:** 0 on success or not needed, 1 on error

---

### ``

---

### ``

!!! info "Notes"
    Prepends Java bin directory to PATH (takes precedence)

---

### ``

**Source:** `oradba_env_builder.sh`

---

### ``

---

### `oradba_build_environment`

---

### ``

Main function to build complete environment

---

### ``

**Arguments:**

- $1 - SID or ORACLE_HOME

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_get_file_signature`

---

### ``

Get file signature (timestamp:size)

---

### ``

**Arguments:**

- $1 - File path

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

**Output:** File signature string

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_store_file_signature`

---

### ``

Store file signature for future comparison

---

### ``

**Arguments:**

- $1 - File path to monitor

---

### ``

**Returns:** 0 on success, 1 on failure

---

### ``

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_check_file_changed`

---

### ``

Check if file has changed since last signature

---

### ``

**Arguments:**

- $1 - File path to check

---

### ``

**Returns:** 0 if changed, 1 if not changed or error

---

### ``

**Output:** Change message (if changed)

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_check_config_changes`

---

### ``

Check if any configuration files have changed

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if changes detected, 1 if no changes

---

### ``

**Output:** List of changed files

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_init_change_tracking`

---

### ``

Initialize change tracking for all config files

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Initialization message

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_clear_change_tracking`

---

### ``

Clear all change tracking data

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

**Source:** `oradba_env_changes.sh`

---

### ``

---

### `oradba_auto_reload_on_change`

---

### ``

Check for changes and reload environment if needed

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 if environment reloaded, 1 if no changes

---

### ``

**Output:** Reload message if environment was reloaded

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_apply_config_section`

---

### ``

Apply configuration from a specific section in config file

---

### ``

**Arguments:**

- $1 - Config file path

---

### ``

**Returns:** 0 on success, 1 if file not found

---

### ``

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_load_generic_configs`

---

### ``

Load all generic configuration files in order

---

### ``

**Arguments:**

- $1 - Section name to apply (optional, defaults to DEFAULT)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Exports variables from configuration files

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_load_sid_config`

---

### ``

Load SID-specific configuration file

---

### ``

**Arguments:**

- $1 - SID or instance name

---

### ``

**Returns:** 0 on success, 1 if config not found

---

### ``

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_apply_product_config`

---

### ``

Apply configuration for specific product type using plugin system

---

### ``

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS or lowercase)

---

### ``

**Returns:** 0 on success

---

### ``

---

### ``

!!! info "Notes"
    Uses plugin_get_config_section() from product-specific plugins

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_expand_variables`

---

### ``

Expand variables in a string (simple implementation)

---

### ``

**Arguments:**

- $1 - String with variables

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Expanded string

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_list_config_sections`

---

### ``

List all sections defined in a config file

---

### ``

**Arguments:**

- $1 - Config file path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Section names, one per line

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_validate_config_file`

---

### ``

Validate configuration file syntax

---

### ``

**Arguments:**

- $1 - Config file path

---

### ``

**Returns:** 0 if valid, 1 if errors found

---

### ``

**Output:** Error messages for invalid syntax

---

### ``

**Source:** `oradba_env_config.sh`

---

### ``

---

### `oradba_get_config_value`

---

### ``

Get a specific variable value from config section

---

### ``

**Arguments:**

- $1 - Config file path

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Variable value

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_parse_oratab`

---

### ``

Parse /etc/oratab file and find SID entry

---

### ``

**Arguments:**

- $1 - SID to find (optional, if empty returns all)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Format: SID|ORACLE_HOME|FLAG

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_parse_homes`

---

### ``

Parse oradba_homes.conf file

---

### ``

**Arguments:**

- $1 - oradba_homes.conf file path (optional, defaults to ${ORADBA_BASE}/etc/oradba_homes.conf)

---

### ``

**Returns:** 0 on success, 1 on error

---

### ``

**Output:** Format: NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION

---

### ``

!!! info "Notes"
    Format matches actual file: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_find_sid`

---

### ``

Find SID in oratab and return entry

---

### ``

**Arguments:**

- $1 - SID to find

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** SID|ORACLE_HOME|FLAG

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_find_home`

---

### ``

Find Oracle Home by NAME, ALIAS, or PATH in oradba_homes.conf

---

### ``

**Arguments:**

- $1 - NAME, ALIAS, or PATH to find

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_get_home_metadata`

---

### ``

Get Oracle Home metadata from oradba_homes.conf

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success, 1 if not found

---

### ``

**Output:** Field value

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_list_all_sids`

---

### ``

List all available SIDs from oratab

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** One SID per line

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_list_all_homes`

---

### ``

List all Oracle Homes from oradba_homes.conf, sorted by order

---

### ``

**Arguments:**

- $1 - oradba_homes.conf file path (optional)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Format: NAME|PATH|TYPE|ORDER|ALIAS (sorted by order)

---

### ``

**Source:** `oradba_env_parser.sh`

---

### ``

---

### `oradba_get_product_type`

---

### ``

Determine product type for an Oracle Home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success, 1 if cannot determine

---

### ``

**Output:** Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_db_status`

---

### ``

Check if Oracle database instance is running

---

### ``

**Arguments:**

- $1 - ORACLE_SID

---

### ``

**Returns:** 0 if running, 1 if not running or cannot determine

---

### ``

**Output:** Status string (OPEN|MOUNTED|NOMOUNT|SHUTDOWN|UNKNOWN)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_asm_status`

---

### ``

Check if ASM instance is running

---

### ``

**Arguments:**

- $1 - ASM instance name (e.g., +ASM, +ASM1)

---

### ``

**Returns:** 0 if running, 1 if not running

---

### ``

**Output:** Status string (STARTED|MOUNTED|SHUTDOWN)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_listener_status`

---

### ``

Check if Oracle listener is running

---

### ``

**Arguments:**

- $1 - Listener name (optional, defaults to LISTENER)

---

### ``

**Returns:** 0 if running, 1 if not running

---

### ``

**Output:** Status string (RUNNING|STOPPED)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_process_running`

---

### ``

Check if a process is running (generic check)

---

### ``

**Arguments:**

- $1 - Process pattern to search for

---

### ``

**Returns:** 0 if running, 1 if not

---

### ``

**Output:** Number of matching processes

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_oud_status`

---

### ``

Check if Oracle Unified Directory instance is running

---

### ``

**Arguments:**

- $1 - OUD instance name/path

---

### ``

**Returns:** 0 if running, 1 if not running

---

### ``

**Output:** Status string (RUNNING|STOPPED|UNKNOWN)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_check_wls_status`

---

### ``

Check if WebLogic Server is running

---

### ``

**Arguments:**

- $1 - Domain home path

---

### ``

**Returns:** 0 if running, 1 if not running

---

### ``

**Output:** Status string (RUNNING|STOPPED|UNKNOWN)

---

### ``

**Source:** `oradba_env_status.sh`

---

### ``

---

### `oradba_get_product_status`

---

### ``

Get status for any product type using plugin system

---

### ``

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS or lowercase)

---

### ``

**Returns:** 0 if can determine status, 1 otherwise

---

### ``

**Output:** Status information

---

### ``

!!! info "Notes"
    Uses plugin_check_status() from product-specific plugins

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_validate_oracle_home`

---

### ``

Check if ORACLE_HOME exists and is valid

---

### ``

**Arguments:**

- $1 - ORACLE_HOME (optional, uses $ORACLE_HOME if not provided)

---

### ``

**Returns:** 0 if valid, 1 if not

---

### ``

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_validate_sid`

---

### ``

Check if SID is valid format

---

### ``

**Arguments:**

- $1 - SID

---

### ``

**Returns:** 0 if valid, 1 if not

---

### ``

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_check_oracle_binaries`

---

### ``

Verify critical Oracle binaries exist using plugin system

---

### ``

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD or lowercase)

---

### ``

**Returns:** 0 if all found, 1 if any missing

---

### ``

**Output:** Error messages for missing binaries

---

### ``

!!! info "Notes"
    Uses plugin_get_required_binaries() from product-specific plugins

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_check_db_running`

---

### ``

Check if database is running

---

### ``

**Arguments:**

- $1 - SID (optional, uses $ORACLE_SID if not provided)

---

### ``

**Returns:** 0 if running, 1 if not

---

### ``

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_get_db_version`

---

### ``

Detect Oracle version from sqlplus

---

### ``

**Arguments:**

- None (uses current environment)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Version string (e.g., "19.0.0.0.0")

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_get_db_status`

---

### ``

Get database open mode

---

### ``

**Arguments:**

- None (uses current environment)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Status (OPEN|MOUNTED|NOMOUNT|DOWN)

---

### ``

**Source:** `oradba_env_validator.sh`

---

### ``

---

### `oradba_validate_environment`

---

### ``

Comprehensive environment validation

---

### ``

**Arguments:**

- $1 - Validation level (basic|standard|full) default: standard

---

### ``

**Returns:** 0 if valid, 1 if issues found

---

### ``

**Output:** Validation messages

---

