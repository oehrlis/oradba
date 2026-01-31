# Plugin Interface

Plugin interface for product-specific functionality (database, client, datasafe, java, etc.).

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect Oracle Full Client installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of client home paths

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is an Oracle Full Client home

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for client home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted ORACLE_HOME (unchanged for client)

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check client availability

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 always (clients don't "run")

---

### ``

**Output:** Status string

---

### ``

!!! info "Notes"
    Clients are always "available" (not "running" or "stopped")

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get Oracle Client metadata

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Clients should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

!!! info "Notes"
    Client homes don't have their own listeners

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover instances for client home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (clients don't have instances)

---

### ``

!!! info "Notes"
    Clients have no instances to discover

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for client

---

### ``

**Arguments:**

- $1 - Input ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    For client, ORACLE_BASE_HOME typically same as ORACLE_HOME

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for Oracle Full Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds environment for client tools

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate client instances

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (clients don't have instances)

---

### ``

!!! info "Notes"
    Clients have no instances to enumerate

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Clients don't support SID aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for Oracle Full Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    Full client has bin + OPatch directories

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for Oracle Full Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    Prefers lib64 on 64-bit systems, falls back to lib

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for Full Client

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "CLIENT"

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load client settings

---

### ``

**Source:** `client_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for Full Client

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binaries

---

### ``

!!! info "Notes"
    Full client has sqlplus and tnsping

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect database installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of ORACLE_HOME paths

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is a database home

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for database home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted ORACLE_HOME (unchanged for database)

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check if database instance is running

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Returns unavailable if oracle binary is missing

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get database metadata

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Database homes should show listener status

---

### ``

---

### ``

**Returns:** 0 (always show)

---

### ``

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_check_listener_status`

---

### ``

Check listener status for database Oracle Home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Listener lifecycle is separate from instance lifecycle

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover database instances for this home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of instances with status

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base (ORACLE_BASE_HOME-aware)

---

### ``

**Arguments:**

- $1 - Input ORACLE_HOME or ORACLE_BASE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    For database, prefer ORACLE_BASE_HOME if set, otherwise use ORACLE_HOME

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for database instance

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds complete environment for database instance

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate all database instances for this ORACLE_HOME

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** instance_name|status|additional_metadata (one per line)

---

### ``

!!! info "Notes"
    Reads oratab for instances using this ORACLE_HOME

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Databases support SID aliases

---

### ``

---

### ``

**Returns:** 0 (supports aliases)

---

### ``

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for database installations

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    Returns bin and OPatch directories

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for database installations

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    Prefers lib64 on 64-bit systems, falls back to lib

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for database

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "RDBMS"

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load database settings

---

### ``

**Source:** `database_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for database

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binaries

---

### ``

!!! info "Notes"
    Core database tools that should be available

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect Data Safe connector installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of connector base paths

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is a Data Safe connector home

---

### ``

**Arguments:**

- $1 - Path to validate (base path, not oracle_cman_home)

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust ORACLE_HOME for Data Safe

---

### ``

**Arguments:**

- $1 - Base ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted ORACLE_HOME (with /oracle_cman_home)

---

### ``

!!! info "Notes"
    THIS IS THE KEY FUNCTION - Consolidates logic from 8+ files

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check Data Safe connector status

---

### ``

**Arguments:**

- $1 - Base path or oracle_cman_home path

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Multi-layered detection with fallback

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get Data Safe connector version

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success with clean version string to stdout

---

### ``

**Output:** Version string (e.g., "23.4.0.0.0")

---

### ``

!!! info "Notes"
    Uses cmctl show version command

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get Data Safe connector metadata

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Data Safe connectors should NOT show in listener section

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

!!! info "Notes"
    Fixes Bug #84 - DataSafe uses tnslsnr but it's not a DB listener

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_check_listener_status`

---

### ``

Check listener status for Data Safe (not applicable)

---

### ``

**Arguments:**

- $1 - Base path (unused for DataSafe)

---

### ``

**Returns:** 1 (not applicable - DataSafe uses cman, not DB listener)

---

### ``

**Output:** None (empty stdout per plugin standards)

---

### ``

!!! info "Notes"
    DataSafe has Connection Manager (cman) but it's not a database

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover Data Safe connector instances

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of connector instances

---

### ``

!!! info "Notes"
    Usually 1:1 relationship (one connector per base)

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for Data Safe

---

### ``

**Arguments:**

- $1 - Input path (base or oracle_cman_home)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path (without oracle_cman_home)

---

### ``

!!! info "Notes"
    DataSafe uses subdirectory structure, return base path

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for Data Safe connector

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds environment for Data Safe connector

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate Data Safe connector instances

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** instance_name|status|additional_metadata (one per line)

---

### ``

!!! info "Notes"
    DataSafe typically has one instance per installation

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Data Safe connectors don't support aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for Data Safe connector

---

### ``

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    DataSafe requires oracle_cman_home/bin

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for Data Safe connector

---

### ``

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    DataSafe requires oracle_cman_home/lib

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for Data Safe

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "DATASAFE"

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load Data Safe settings

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for Data Safe connector

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binaries

---

### ``

!!! info "Notes"
    Data Safe uses Connection Manager (cmctl)

---

### ``

**Source:** `datasafe_plugin.sh`

---

### ``

---

### `plugin_get_adjusted_paths`

---

### ``

Get adjusted PATH and LD_LIBRARY_PATH for Data Safe

---

### ``

**Arguments:**

- $1 - Base path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** PATH and LD_LIBRARY_PATH (one per line)

---

### ``

!!! info "Notes"
    Helper function for environment setup (legacy, use plugin_build_bin_path/plugin_build_lib_path)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect EM Agent installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of agent paths

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is an EM Agent installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for EM Agent

---

### ``

**Arguments:**

- $1 - Path to agent home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted path (unchanged for agent)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check EM Agent status

---

### ``

**Arguments:**

- $1 - Path to agent home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Status string

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get EM Agent metadata

---

### ``

**Arguments:**

- $1 - Path to agent home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

EM Agent should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover instances

---

### ``

**Arguments:**

- $1 - Path to agent home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for EM Agent

---

### ``

**Arguments:**

- $1 - Input path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Base path

---

### ``

!!! info "Notes"
    Stub implementation

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for EM Agent

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

!!! info "Notes"
    Stub implementation

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate EM Agent instances

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

!!! info "Notes"
    Stub implementation - will be implemented in Phase 3

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

EM Agent doesn't support aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for EM Agent

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no binaries added to PATH)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for EM Agent

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no libraries added)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for EM Agent

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "EMAGENT"

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for EM Agent

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get EM Agent version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

---

### ``

**Returns:** 1 (version not applicable for stub)

---

### ``

**Output:** No output

---

### ``

!!! info "Notes"
    EM Agent version detection not implemented in stub

---

### ``

**Source:** `emagent_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get EM Agent version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

---

### ``

**Returns:** 1 (version not applicable for stub)

---

### ``

**Output:** No output

---

### ``

!!! info "Notes"
    EM Agent version detection not implemented in stub

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect Oracle Instant Client installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of instant client paths

---

### ``

!!! info "Notes"
    Excludes libraries found inside other Oracle product homes

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is an Instant Client installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for instant client

---

### ``

**Arguments:**

- $1 - Path to instant client

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted path (unchanged for instant client)

---

### ``

!!! info "Notes"
    Instant client uses ORACLE_HOME directly (no bin/ subdirectory)

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check instant client availability

---

### ``

**Arguments:**

- $1 - Path to instant client

---

### ``

**Returns:** 0 if libraries available

---

### ``

**Output:** Status string

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get instant client metadata

---

### ``

**Arguments:**

- $1 - Path to instant client

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Instant clients should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover instances

---

### ``

**Arguments:**

- $1 - Path to instant client

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (instant clients don't have instances)

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for instant client

---

### ``

**Arguments:**

- $1 - Input ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    For instant client, base is same as ORACLE_HOME

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for Oracle Instant Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds environment for instant client

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate instant client instances

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (instant clients don't have instances)

---

### ``

!!! info "Notes"
    Instant clients have no instances

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Instant clients don't support aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for Oracle Instant Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    Instant Client has no bin/ subdirectory - binaries in root

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for Oracle Instant Client

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    Instant Client libraries are in root, lib64, or lib subdirectory

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get Instant Client version

---

### ``

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

---

### ``

**Returns:** 0 on success with clean version string to stdout

---

### ``

**Output:** Version string in X.Y format (e.g., "23.26.0.0.0" or "19.21.0.0.0")

---

### ``

!!! info "Notes"
    Detection methods (in order)

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for Instant Client

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "ICLIENT"

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load instant client settings

---

### ``

**Source:** `iclient_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for Instant Client

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binaries

---

### ``

!!! info "Notes"
    Instant Client has sqlplus if SQL*Plus package installed

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect Java installations under $ORACLE_BASE/product

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of Java installation paths

---

### ``

!!! info "Notes"
    Excludes JRE subdirectories within JDK installations

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is a Java installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for Java (no adjustment needed)

---

### ``

**Arguments:**

- $1 - Path to Java home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Path unchanged

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check Java installation status

---

### ``

**Arguments:**

- $1 - Path to Java home

---

### ``

**Returns:** 0 if available, 1 if not

---

### ``

**Output:** Status string

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get Java installation metadata

---

### ``

**Arguments:**

- $1 - Path to Java home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Java should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Java doesn't have instances

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for Java

---

### ``

**Arguments:**

- $1 - Input JAVA_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    For Java, base is same as JAVA_HOME

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for Java

---

### ``

**Arguments:**

- $1 - JAVA_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds environment for Java

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate Java instances

---

### ``

**Arguments:**

- $1 - JAVA_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (Java doesn't have instances)

---

### ``

!!! info "Notes"
    Java installations don't have instances

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Java doesn't support instance aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for Java

---

### ``

**Arguments:**

- $1 - JAVA_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** bin directory path

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for Java

---

### ``

**Arguments:**

- $1 - JAVA_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Library path components

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for Java

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "JAVA"

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for Java

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of required binaries

---

### ``

**Source:** `java_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get Java version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success with clean version string to stdout

---

### ``

**Output:** Java version string (e.g., "17.0.1", "8.0.291", "21.0.2")

---

### ``

!!! info "Notes"
    Parses output from java -version

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect OMS installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of OMS paths

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is an OMS installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for OMS

---

### ``

**Arguments:**

- $1 - Path to OMS home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted path (unchanged for OMS)

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check OMS status

---

### ``

**Arguments:**

- $1 - Path to OMS home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Status string

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get OMS metadata

---

### ``

**Arguments:**

- $1 - Path to OMS home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

OMS should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover instances

---

### ``

**Arguments:**

- $1 - Path to OMS home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for OMS

---

### ``

**Arguments:**

- $1 - Input path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Base path

---

### ``

!!! info "Notes"
    Stub implementation

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for OMS

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

!!! info "Notes"
    Stub implementation

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate OMS instances

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

!!! info "Notes"
    Stub implementation - will be implemented in Phase 3

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

OMS doesn't support aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for OMS

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no binaries added to PATH)

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for OMS

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no libraries added)

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for OMS

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "OMS"

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for OMS

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

**Source:** `oms_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get OMS version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 1 (version not applicable for stub)

---

### ``

**Output:** No output

---

### ``

!!! info "Notes"
    OMS version detection not implemented in stub

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `get_oud_instance_base`

---

### ``

Get OUD instance base directory following priority order

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path (optional, for fallback)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Instance base directory path

---

### ``

!!! info "Notes"
    Priority order

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect OUD installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of OUD home paths

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is an OUD installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for OUD

---

### ``

**Arguments:**

- $1 - Path to OUD home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted path (unchanged for OUD)

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check OUD instance status

---

### ``

**Arguments:**

- $1 - Path to OUD home

---

### ``

**Returns:** 0 if running

---

### ``

**Output:** Status string

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get OUD version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success with clean version string to stdout

---

### ``

**Output:** Version string (e.g., "12.2.1.4.0")

---

### ``

!!! info "Notes"
    Detection methods (in order)

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get OUD metadata

---

### ``

**Arguments:**

- $1 - Path to OUD home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

!!! info "Notes"
    Uses get_oud_instance_base() to count instances

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

OUD should NOT show database listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover OUD instances

---

### ``

**Arguments:**

- $1 - Path to OUD home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of instance names

---

### ``

!!! info "Notes"
    Uses get_oud_instance_base() to determine instance location

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for OUD

---

### ``

**Arguments:**

- $1 - Input ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    For OUD, base is same as ORACLE_HOME

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for Oracle Unified Directory

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds environment for OUD instance

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate all OUD instances for this installation

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** instance_name|status|additional_metadata (one per line)

---

### ``

!!! info "Notes"
    OUD can have multiple instances per installation

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

OUD instances can have aliases

---

### ``

---

### ``

**Returns:** 0 (supports aliases)

---

### ``

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_display_name`

---

### ``

Get display name for OUD instance

---

### ``

**Arguments:**

- $1 - Instance name

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Display name

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for Oracle Unified Directory

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    OUD has bin directory with management tools

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for Oracle Unified Directory

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    OUD has lib directory

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for OUD

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "OUD"

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load OUD settings

---

### ``

**Source:** `oud_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for OUD

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binaries

---

### ``

!!! info "Notes"
    OUD has oud-setup and other management tools

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect installations of this product type

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of installation paths (one per line)

---

### ``

!!! info "Notes"
    Used for auto-discovery when no registry files exist

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is a valid ORACLE_HOME for this product

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

**Output:** None

---

### ``

!!! info "Notes"
    Checks for product-specific files/directories

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust ORACLE_HOME for product-specific requirements

---

### ``

**Arguments:**

- $1 - Original ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted ORACLE_HOME path

---

### ``

!!! info "Notes"
    Example: DataSafe appends /oracle_cman_home; align ORACLE_HOME with ORACLE_BASE_HOME if needed

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base (ORACLE_BASE_HOME-aware)

---

### ``

**Arguments:**

- $1 - Input ORACLE_HOME or ORACLE_BASE_HOME

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Normalized base path

---

### ``

!!! info "Notes"
    Use when ORACLE_HOME differs from installation base

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for the product/instance

---

### ``

**Arguments:**

- $1 - ORACLE_HOME

---

### ``

**Returns:** 0 on success, 1 if not applicable, 2 if unavailable

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Builds complete environment: ORACLE_HOME, PATH, LD_LIBRARY_PATH, etc.

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check if product instance is running

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Uses explicit environment (not current shell environment)

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get product metadata (version, features, etc.)

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Example output

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover all instances for this Oracle Home

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of instances (one per line)

---

### ``

!!! info "Notes"
    Handles 1:many relationships (RAC, WebLogic, OUD)

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate all instances/domains for this ORACLE_HOME

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** instance_name|status|additional_metadata (one per line)

---

### ``

!!! info "Notes"
    Mandatory for multi-instance products (database, middleware, etc.)

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

Whether this product supports SID-like aliases

---

### ``

---

### ``

**Returns:** 0 if supports aliases, 1 if not

---

### ``

---

### ``

!!! info "Notes"
    Databases support aliases, most other products don't

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for this product

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated PATH components

---

### ``

!!! info "Notes"
    Returns the directories to add to PATH for this product

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for this product

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Colon-separated library path components

---

### ``

!!! info "Notes"
    Returns the directories to add to LD_LIBRARY_PATH (or equivalent)

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for this product

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Configuration section name (uppercase)

---

### ``

!!! info "Notes"
    Used by oradba_apply_product_config() to load product-specific settings

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for this product

---

### ``

**Arguments:**

- None

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Space-separated list of required binary names

---

### ``

!!! info "Notes"
    Used by oradba_check_oracle_binaries() to validate installation

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_check_listener_status`

---

### ``

Check listener status for products with listener components

---

### ``

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Category-specific: mandatory for database and listener-based products

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

Determine if this product's tnslsnr should appear in listener section

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 if should show, 1 if should not show

---

### ``

---

### ``

!!! info "Notes"
    Database listeners: return 0

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_check_listener_status`

---

### ``

Check listener status for products with listener components

---

### ``

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

---

### ``

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

---

### ``

**Output:** Status string (running|stopped|unavailable)

---

### ``

!!! info "Notes"
    Category-specific: mandatory for database and listener-based products

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_display_name`

---

### ``

Get custom display name for instance

---

### ``

**Arguments:**

- $1 - Installation name

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Display name

---

### ``

!!! info "Notes"
    Optional - defaults to installation name

---

### ``

**Source:** `plugin_interface.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get product version from ORACLE_HOME

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 0 on success with clean version string to stdout

---

### ``

**Output:** Version string on success only (e.g., "19.21.0.0.0")

---

### ``

!!! info "Notes"
    Called by plugin_get_metadata, can be overridden for efficiency

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_detect_installation`

---

### ``

Auto-detect WebLogic installations

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of WebLogic paths

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_validate_home`

---

### ``

Validate that path is a WebLogic installation

---

### ``

**Arguments:**

- $1 - Path to validate

---

### ``

**Returns:** 0 if valid, 1 if invalid

---

### ``

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_adjust_environment`

---

### ``

Adjust environment for WebLogic

---

### ``

**Arguments:**

- $1 - Path to WebLogic home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Adjusted path (unchanged for WebLogic)

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_check_status`

---

### ``

Check WebLogic status

---

### ``

**Arguments:**

- $1 - Path to WebLogic home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Status string

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_get_metadata`

---

### ``

Get WebLogic metadata

---

### ``

**Arguments:**

- $1 - Path to WebLogic home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_should_show_listener`

---

### ``

WebLogic should NOT show listener status

---

### ``

---

### ``

**Returns:** 1 (never show)

---

### ``

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_discover_instances`

---

### ``

Discover WebLogic domains for this installation

---

### ``

**Arguments:**

- $1 - Path to WebLogic home

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** List of domain names (one per line)

---

### ``

!!! info "Notes"
    Stub implementation - searches common domain locations

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_build_base_path`

---

### ``

Resolve actual installation base for WebLogic

---

### ``

**Arguments:**

- $1 - Input path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Base path

---

### ``

!!! info "Notes"
    Stub implementation

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_build_env`

---

### ``

Build environment variables for WebLogic

---

### ``

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Key=value pairs (one per line)

---

### ``

!!! info "Notes"
    Stub implementation - sets ORACLE_HOME and WLS_DOMAIN

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_get_instance_list`

---

### ``

Enumerate WebLogic domains for this installation

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** domain_name|status|additional_metadata (one per line)

---

### ``

!!! info "Notes"
    Stub implementation - searches common domain locations

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_supports_aliases`

---

### ``

WebLogic doesn't support aliases

---

### ``

---

### ``

**Returns:** 1 (no aliases)

---

### ``

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_build_bin_path`

---

### ``

Get PATH components for WebLogic

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no binaries added to PATH)

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_build_lib_path`

---

### ``

Get LD_LIBRARY_PATH components for WebLogic

---

### ``

**Arguments:**

- $1 - ORACLE_HOME path

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (no libraries added)

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_get_config_section`

---

### ``

Get configuration section name for WebLogic

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** "WEBLOGIC"

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_get_required_binaries`

---

### ``

Get list of required binaries for WebLogic

---

### ``

---

### ``

**Returns:** 0 on success

---

### ``

**Output:** Empty (stub)

---

### ``

**Source:** `weblogic_plugin.sh`

---

### ``

---

### `plugin_get_version`

---

### ``

Get WebLogic version

---

### ``

**Arguments:**

- $1 - Installation path

---

### ``

**Returns:** 1 (version not applicable for stub)

---

### ``

**Output:** No output

---

### ``

!!! info "Notes"
    WebLogic version detection not implemented in stub

---

