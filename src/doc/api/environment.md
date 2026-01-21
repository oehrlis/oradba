# Environment Management

Environment management libraries for building, parsing, validating, and tracking Oracle environments.

---

### `oradba_add_client_path` {: #oradba_add_client_path }

Add client tools to PATH for non-client products

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Current product type (uppercase)

**Returns:** 0 on success or not needed, 1 on error

!!! info "Notes"
    Appends client bin directory to PATH after existing entries

---
### `oradba_add_java_path` {: #oradba_add_java_path }

Add Java to JAVA_HOME and PATH for products that need it

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Current product type (uppercase)
- $2 - Current ORACLE_HOME (optional, for auto-detection)

**Returns:** 0 on success or not needed, 1 on error

!!! info "Notes"
    Prepends Java bin directory to PATH (takes precedence)
    Exports JAVA_HOME environment variable

---
### `oradba_add_oracle_path` {: #oradba_add_oracle_path }

Add Oracle binaries to PATH using plugin system

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - Product type (optional, lowercase: database, client, iclient, etc.)

**Returns:** 0 on success

!!! info "Notes"
    Uses plugin_build_path() from product-specific plugins
    Falls back to basic bin directory for unknown products

---
### `oradba_apply_config_section` {: #oradba_apply_config_section }

Apply configuration from a specific section in config file

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Config file path
- $2 - Section name (DEFAULT|RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS)

**Returns:** 0 on success, 1 if file not found

---
### `oradba_apply_product_config` {: #oradba_apply_product_config }

Apply configuration for specific product type using plugin system

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS or lowercase)
- $2 - SID (optional, for ASM detection)

**Returns:** 0 on success

!!! info "Notes"
    Uses plugin_get_config_section() from product-specific plugins
    Falls back to uppercase product type for unknown products

---
### `oradba_auto_reload_on_change` {: #oradba_auto_reload_on_change }

Check for changes and reload environment if needed

**Source:** `oradba_env_changes.sh`

**Arguments:**

- None

**Returns:** 0 if environment reloaded, 1 if no changes

**Output:** Reload message if environment was reloaded

---
### `oradba_build_environment` {: #oradba_build_environment }

Main function to build complete environment

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - SID or ORACLE_HOME

**Returns:** 0 on success, 1 on error

---
### `oradba_check_asm_status` {: #oradba_check_asm_status }

Check if ASM instance is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - ASM instance name (e.g., +ASM, +ASM1)
- $2 - ORACLE_HOME (optional, uses current if not specified)

**Returns:** 0 if running, 1 if not running

**Output:** Status string (STARTED|MOUNTED|SHUTDOWN)

---
### `oradba_check_config_changes` {: #oradba_check_config_changes }

Check if any configuration files have changed

**Source:** `oradba_env_changes.sh`

**Arguments:**

- None

**Returns:** 0 if changes detected, 1 if no changes

**Output:** List of changed files

---
### `oradba_check_datasafe_status` {: #oradba_check_datasafe_status }

Check if DataSafe On-Premises Connector is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - ORACLE_HOME (DataSafe connector path)

**Returns:** 0 if running, 1 if not running

**Output:** Status string (RUNNING|STOPPED|UNKNOWN)

!!! info "Notes"
    Uses direct cmctl command (faster than Python setup.py)

---
### `oradba_check_db_running` {: #oradba_check_db_running }

Check if database is running

**Source:** `oradba_env_validator.sh`

**Arguments:**

- $1 - SID (optional, uses $ORACLE_SID if not provided)

**Returns:** 0 if running, 1 if not

---
### `oradba_check_db_status` {: #oradba_check_db_status }

Check if Oracle database instance is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - ORACLE_SID
- $2 - ORACLE_HOME (optional, uses current if not specified)

**Returns:** 0 if running, 1 if not running or cannot determine

**Output:** Status string (OPEN|MOUNTED|NOMOUNT|SHUTDOWN|UNKNOWN)

---
### `oradba_check_file_changed` {: #oradba_check_file_changed }

Check if file has changed since last signature

**Source:** `oradba_env_changes.sh`

**Arguments:**

- $1 - File path to check
- $2 - Signature storage file (optional, auto-generated if not provided)

**Returns:** 0 if changed, 1 if not changed or error

**Output:** Change message (if changed)

---
### `oradba_check_listener_status` {: #oradba_check_listener_status }

Check if Oracle listener is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - Listener name (optional, defaults to LISTENER)
- $2 - ORACLE_HOME (optional, uses current if not specified)

**Returns:** 0 if running, 1 if not running

**Output:** Status string (RUNNING|STOPPED)

---
### `oradba_check_oracle_binaries` {: #oradba_check_oracle_binaries }

Verify critical Oracle binaries exist using plugin system

**Source:** `oradba_env_validator.sh`

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD or lowercase)

**Returns:** 0 if all found, 1 if any missing

**Output:** Error messages for missing binaries

!!! info "Notes"
    Uses plugin_get_required_binaries() from product-specific plugins
    Falls back to basic sqlplus check for unknown products

---
### `oradba_check_oud_status` {: #oradba_check_oud_status }

Check if Oracle Unified Directory instance is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - OUD instance name/path

**Returns:** 0 if running, 1 if not running

**Output:** Status string (RUNNING|STOPPED|UNKNOWN)

---
### `oradba_check_process_running` {: #oradba_check_process_running }

Check if a process is running (generic check)

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - Process pattern to search for

**Returns:** 0 if running, 1 if not

**Output:** Number of matching processes

---
### `oradba_check_wls_status` {: #oradba_check_wls_status }

Check if WebLogic Server is running

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - Domain home path

**Returns:** 0 if running, 1 if not running

**Output:** Status string (RUNNING|STOPPED|UNKNOWN)

---
### `oradba_clean_path` {: #oradba_clean_path }

Remove Oracle-related directories from PATH

**Source:** `oradba_env_builder.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Cleaned PATH exported

---
### `oradba_clear_change_tracking` {: #oradba_clear_change_tracking }

Clear all change tracking data

**Source:** `oradba_env_changes.sh`

**Arguments:**

- None

**Returns:** 0 on success

---
### `oradba_dedupe_path` {: #oradba_dedupe_path }

Remove duplicate entries from PATH-like variables

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Path string (colon-separated)

**Returns:** Deduplicated path string

---
### `oradba_detect_rooh` {: #oradba_detect_rooh }

Detect Read-Only Oracle Home

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - ORACLE_HOME

**Returns:** 0 if ROOH, 1 if not ROOH or cannot determine

**Output:** Sets ORACLE_BASE, ORADBA_ROOH, ORADBA_DBS

---
### `oradba_expand_variables` {: #oradba_expand_variables }

Expand variables in a string (simple implementation)

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - String with variables

**Returns:** 0 on success

**Output:** Expanded string

---
### `oradba_find_home` {: #oradba_find_home }

Find Oracle Home by NAME, ALIAS, or PATH in oradba_homes.conf

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - NAME, ALIAS, or PATH to find
- $2 - oradba_homes.conf file path (optional)

**Returns:** 0 on success, 1 if not found

**Output:** NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION

---
### `oradba_find_sid` {: #oradba_find_sid }

Find SID in oratab and return entry

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - SID to find

**Returns:** 0 on success, 1 if not found

**Output:** SID|ORACLE_HOME|FLAG

---
### `oradba_get_config_value` {: #oradba_get_config_value }

Get a specific variable value from config section

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Config file path
- $2 - Section name
- $3 - Variable name

**Returns:** 0 on success, 1 if not found

**Output:** Variable value

---
### `oradba_get_db_status` {: #oradba_get_db_status }

Get database open mode

**Source:** `oradba_env_validator.sh`

**Arguments:**

- None (uses current environment)

**Returns:** 0 on success

**Output:** Status (OPEN|MOUNTED|NOMOUNT|DOWN)

---
### `oradba_get_db_version` {: #oradba_get_db_version }

Detect Oracle version from sqlplus

**Source:** `oradba_env_validator.sh`

**Arguments:**

- None (uses current environment)

**Returns:** 0 on success

**Output:** Version string (e.g., "19.0.0.0.0")

---
### `oradba_get_file_signature` {: #oradba_get_file_signature }

Get file signature (timestamp:size)

**Source:** `oradba_env_changes.sh`

**Arguments:**

- $1 - File path

**Returns:** 0 on success, 1 on failure

**Output:** File signature string

---
### `oradba_get_home_metadata` {: #oradba_get_home_metadata }

Get Oracle Home metadata from oradba_homes.conf

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - Field name (Product|Version|Edition|DB_Type|Position|Dummy_SID|Short_Name|Description)
- $3 - oradba_homes.conf file path (optional)

**Returns:** 0 on success, 1 if not found

**Output:** Field value

---
### `oradba_get_product_status` {: #oradba_get_product_status }

Get status for any product type using plugin system

**Source:** `oradba_env_status.sh`

**Arguments:**

- $1 - Product type (RDBMS|CLIENT|ICLIENT|GRID|ASM|DATASAFE|OUD|WLS or lowercase)
- $2 - Instance/SID/Domain name
- $3 - ORACLE_HOME or product home (optional)

**Returns:** 0 if can determine status, 1 otherwise

**Output:** Status information

!!! info "Notes"
    Uses plugin_check_status() from product-specific plugins
    Falls back to product-specific functions for unknown products

---
### `oradba_get_product_type` {: #oradba_get_product_type }

Determine product type for an Oracle Home

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success, 1 if cannot determine

**Output:** Product type (RDBMS|CLIENT|ICLIENT|GRID|DATASAFE|OUD|WLS)

---
### `oradba_init_change_tracking` {: #oradba_init_change_tracking }

Initialize change tracking for all config files

**Source:** `oradba_env_changes.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Initialization message

---
### `oradba_is_asm_instance` {: #oradba_is_asm_instance }

Check if SID is an ASM instance

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - SID

**Returns:** 0 if ASM, 1 if not

---
### `oradba_list_all_homes` {: #oradba_list_all_homes }

List all Oracle Homes from oradba_homes.conf, sorted by order

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - oradba_homes.conf file path (optional)

**Returns:** 0 on success

**Output:** Format: NAME|PATH|TYPE|ORDER|ALIAS (sorted by order)

---
### `oradba_list_all_sids` {: #oradba_list_all_sids }

List all available SIDs from oratab

**Source:** `oradba_env_parser.sh`

**Returns:** 0 on success

**Output:** One SID per line

---
### `oradba_list_config_sections` {: #oradba_list_config_sections }

List all sections defined in a config file

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Config file path

**Returns:** 0 on success

**Output:** Section names, one per line

---
### `oradba_load_generic_configs` {: #oradba_load_generic_configs }

Load all generic configuration files in order

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Section name to apply (optional, defaults to DEFAULT)

**Returns:** 0 on success

**Output:** Exports variables from configuration files

---
### `oradba_load_sid_config` {: #oradba_load_sid_config }

Load SID-specific configuration file

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - SID or instance name
- $2 - Section name to load from SID config (optional, defaults to DEFAULT)

**Returns:** 0 on success, 1 if config not found

---
### `oradba_parse_homes` {: #oradba_parse_homes }

Parse oradba_homes.conf file

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - oradba_homes.conf file path (optional, defaults to ${ORADBA_BASE}/etc/oradba_homes.conf)
- $2 - NAME or ALIAS to find (optional, if empty returns all)

**Returns:** 0 on success, 1 on error

**Output:** Format: NAME|PATH|TYPE|ORDER|ALIAS|DESCRIPTION|VERSION

!!! info "Notes"
    Format matches actual file: NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION

---
### `oradba_parse_oratab` {: #oradba_parse_oratab }

Parse /etc/oratab file and find SID entry

**Source:** `oradba_env_parser.sh`

**Arguments:**

- $1 - SID to find (optional, if empty returns all)

**Returns:** 0 on success, 1 on error

**Output:** Format: SID|ORACLE_HOME|FLAG

---
### `oradba_product_needs_client` {: #oradba_product_needs_client }

Determine if a product type needs external client tools

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)

**Returns:** 0 if product needs client, 1 if it has its own client

---
### `oradba_product_needs_java` {: #oradba_product_needs_java }

Determine if a product type needs Java (JAVA_HOME)

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Product type (uppercase: DATASAFE, OUD, WLS, etc.)

**Returns:** 0 if product needs Java, 1 if it has its own or doesn't need Java

---
### `oradba_resolve_client_home` {: #oradba_resolve_client_home }

Resolve client home path from ORADBA_CLIENT_PATH_FOR_NON_CLIENT setting

**Source:** `oradba_env_builder.sh`

**Arguments:**

- None (reads ORADBA_CLIENT_PATH_FOR_NON_CLIENT env var)

**Returns:** 0 on success, 1 if no client found

**Output:** Prints resolved client home path

!!! info "Notes"
    Accepts DATABASE, CLIENT, or ICLIENT product types
    (all have client tools like sqlplus, sqlldr, etc.)

---
### `oradba_resolve_java_home` {: #oradba_resolve_java_home }

Resolve Java home path from ORADBA_JAVA_PATH_FOR_NON_JAVA setting

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Current ORACLE_HOME (optional, for auto-detection of $ORACLE_HOME/java)

**Returns:** 0 on success, 1 if no Java found

**Output:** Prints resolved Java home path

!!! info "Notes"
    Supports "auto", "none", or named Java from oradba_homes.conf

---
### `oradba_set_asm_environment` {: #oradba_set_asm_environment }

Set ASM-specific environment variables

**Source:** `oradba_env_builder.sh`

**Arguments:**

- None (uses ORACLE_SID, ORACLE_HOME)

**Returns:** 0 on success

---
### `oradba_set_lib_path` {: #oradba_set_lib_path }

Set library path using plugin system

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - Product type (optional, lowercase: database, client, iclient, etc.)

**Returns:** 0 on success

!!! info "Notes"
    Uses plugin_build_lib_path() from product-specific plugins
    Falls back to basic lib/lib64 detection for unknown products#           Cleans old Oracle/Grid/InstantClient paths before setting new ones
    Preserves non-Oracle library paths from existing environment# ------------------------------------------------------------------------------

---
### `oradba_set_oracle_vars` {: #oradba_set_oracle_vars }

Set core Oracle environment variables

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - ORACLE_SID
- $2 - ORACLE_HOME
- $3 - Product type

**Returns:** 0 on success

---
### `oradba_set_product_environment` {: #oradba_set_product_environment }

Set product-specific environment variables

**Source:** `oradba_env_builder.sh`

**Arguments:**

- $1 - Product type

**Returns:** 0 on success

---
### `oradba_store_file_signature` {: #oradba_store_file_signature }

Store file signature for future comparison

**Source:** `oradba_env_changes.sh`

**Arguments:**

- $1 - File path to monitor
- $2 - Signature storage file (optional, auto-generated if not provided)

**Returns:** 0 on success, 1 on failure

---
### `oradba_validate_config_file` {: #oradba_validate_config_file }

Validate configuration file syntax

**Source:** `oradba_env_config.sh`

**Arguments:**

- $1 - Config file path

**Returns:** 0 if valid, 1 if errors found

**Output:** Error messages for invalid syntax

---
### `oradba_validate_environment` {: #oradba_validate_environment }

Comprehensive environment validation

**Source:** `oradba_env_validator.sh`

**Arguments:**

- $1 - Validation level (basic|standard|full) default: standard

**Returns:** 0 if valid, 1 if issues found

**Output:** Validation messages

---
### `oradba_validate_oracle_home` {: #oradba_validate_oracle_home }

Check if ORACLE_HOME exists and is valid

**Source:** `oradba_env_validator.sh`

**Arguments:**

- $1 - ORACLE_HOME (optional, uses $ORACLE_HOME if not provided)

**Returns:** 0 if valid, 1 if not

---
### `oradba_validate_sid` {: #oradba_validate_sid }

Check if SID is valid format

**Source:** `oradba_env_validator.sh`

**Arguments:**

- $1 - SID

**Returns:** 0 if valid, 1 if not

---
