# Plugin Interface

Plugin interface for product-specific functionality (database, client, datasafe, java, etc.).

---

### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for instant client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for instant client)

!!! info "Notes"
    Instant client uses ORACLE_HOME directly (no bin/ subdirectory)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for WebLogic)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust ORACLE_HOME for product-specific requirements

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Original ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME path

!!! info "Notes"
    Example: DataSafe appends /oracle_cman_home
    Most products return the path unchanged

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust ORACLE_HOME for Data Safe

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (with /oracle_cman_home)

!!! info "Notes"
    THIS IS THE KEY FUNCTION - Consolidates logic from 8+ files

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for Java (no adjustment needed)

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home

**Returns:** 0 on success

**Output:** Path unchanged

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for agent)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for OUD

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for OUD)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for OMS)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (unchanged for client)

---
### `plugin_adjust_environment` {: #plugin_adjust_environment }

Adjust environment for database home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (unchanged for database)

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for Oracle Instant Client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Instant Client libraries are in root, lib64, or lib subdirectory

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Returns the directories to add to LD_LIBRARY_PATH (or equivalent)
    Example (RDBMS): /u01/app/oracle/product/19/lib
    Example (ICLIENT): /u01/app/oracle/instantclient_19_21
    Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/lib

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    DataSafe requires oracle_cman_home/lib

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME path

**Returns:** 0 on success

**Output:** Library path components

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for Oracle Unified Directory

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    OUD has lib directory

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for Oracle Full Client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Prefers lib64 on 64-bit systems, falls back to lib

---
### `plugin_build_lib_path` {: #plugin_build_lib_path }

Get LD_LIBRARY_PATH components for database installations

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Prefers lib64 on 64-bit systems, falls back to lib
    If GRID_HOME exists and differs from ORACLE_HOME, includes Grid lib

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for Oracle Instant Client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Instant Client has no bin/ subdirectory - binaries in root

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Returns the directories to add to PATH for this product
    Example (RDBMS): /u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch
    Example (ICLIENT): /u01/app/oracle/instantclient_19_21
    Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/bin

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    DataSafe requires oracle_cman_home/bin

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME path

**Returns:** 0 on success

**Output:** bin directory path

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for Oracle Unified Directory

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    OUD has bin directory with management tools

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for Oracle Full Client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Full client has bin + OPatch directories

---
### `plugin_build_path` {: #plugin_build_path }

Get PATH components for database installations

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Returns bin and OPatch directories
    If GRID_HOME exists and differs from ORACLE_HOME, includes Grid bin

---
### `plugin_check_status` {: #plugin_check_status }

Check instant client availability

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client
- $2 - Ignored (instant clients don't have instances)

**Returns:** 0 if libraries available

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check WebLogic status

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home
- $2 - Ignored

**Returns:** 0 on success

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check if product instance is running

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path
- $2 - Instance name (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string (running|stopped|unavailable)

!!! info "Notes"
    Uses explicit environment (not current shell environment)

---
### `plugin_check_status` {: #plugin_check_status }

Check Data Safe connector status

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path or oracle_cman_home path
- $2 - Connector name (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string

!!! info "Notes"
    Uses EXPLICIT environment (fixes Bug #83)

---
### `plugin_check_status` {: #plugin_check_status }

Check Java installation status

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home
- $2 - Ignored

**Returns:** 0 if available, 1 if not

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check EM Agent status

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home
- $2 - Ignored

**Returns:** 0 on success

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check OUD instance status

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home
- $2 - Instance name (optional)

**Returns:** 0 if running

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check OMS status

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home
- $2 - Ignored

**Returns:** 0 on success

**Output:** Status string

---
### `plugin_check_status` {: #plugin_check_status }

Check client availability

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - Ignored (clients don't have instances)

**Returns:** 0 always (clients don't "run")

**Output:** Status string

!!! info "Notes"
    Clients are always "available" (not "running" or "stopped")

---
### `plugin_check_status` {: #plugin_check_status }

Check if database instance is running

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - SID (optional)

**Returns:** 0 if running, 1 if stopped

**Output:** Status string

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect Oracle Instant Client installations

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** List of instant client paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect WebLogic installations

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** List of WebLogic paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect installations of this product type

**Source:** `plugin_interface.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** List of installation paths (one per line)

!!! info "Notes"
    Used for auto-discovery when no registry files exist

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect Data Safe connector installations

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** List of connector base paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect Java installations under $ORACLE_BASE/product

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** List of Java installation paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect EM Agent installations

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** List of agent paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect OUD installations

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** List of OUD home paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect OMS installations

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** List of OMS paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect Oracle Full Client installations

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** List of client home paths

---
### `plugin_detect_installation` {: #plugin_detect_installation }

Auto-detect database installations

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** List of ORACLE_HOME paths

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover instances

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Empty (instant clients don't have instances)

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover instances

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover all instances for this Oracle Home

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** List of instances (one per line)

!!! info "Notes"
    Handles 1:many relationships (RAC, WebLogic, OUD)
    Example: PROD1|running|node1

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover Data Safe connector instances

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** List of connector instances

!!! info "Notes"
    Usually 1:1 relationship (one connector per base)

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Java doesn't have instances

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** Empty

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover instances

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover OUD instances

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** List of instance names

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover instances

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover instances for client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (clients don't have instances)

!!! info "Notes"
    Clients have no instances to discover

---
### `plugin_discover_instances` {: #plugin_discover_instances }

Discover database instances for this home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** List of instances with status

---
### `plugin_get_adjusted_paths` {: #plugin_get_adjusted_paths }

Get adjusted PATH and LD_LIBRARY_PATH for Data Safe

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** PATH and LD_LIBRARY_PATH (one per line)

!!! info "Notes"
    Helper function for environment setup (legacy, use plugin_build_path/lib_path)

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for Instant Client

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** "ICLIENT"

!!! info "Notes"
    Used by oradba_apply_product_config() to load instant client settings

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for WebLogic

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** "WEBLOGIC"

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Configuration section name (uppercase)

!!! info "Notes"
    Used by oradba_apply_product_config() to load product-specific settings
    Example: "RDBMS", "DATASAFE", "CLIENT", "ICLIENT", "OUD", "WLS"

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for Data Safe

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** "DATASAFE"

!!! info "Notes"
    Used by oradba_apply_product_config() to load Data Safe settings

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for Java

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** "JAVA"

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for EM Agent

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** "EMAGENT"

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for OUD

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** "OUD"

!!! info "Notes"
    Used by oradba_apply_product_config() to load OUD settings

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for OMS

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** "OMS"

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for Full Client

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** "CLIENT"

!!! info "Notes"
    Used by oradba_apply_product_config() to load client settings

---
### `plugin_get_config_section` {: #plugin_get_config_section }

Get configuration section name for database

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** "RDBMS"

!!! info "Notes"
    Used by oradba_apply_product_config() to load database settings

---
### `plugin_get_display_name` {: #plugin_get_display_name }

Get custom display name for instance

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation name

**Returns:** 0 on success

**Output:** Display name

!!! info "Notes"
    Optional - defaults to installation name

---
### `plugin_get_display_name` {: #plugin_get_display_name }

Get display name for OUD instance

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Instance name

**Returns:** 0 on success

**Output:** Display name

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get instant client metadata

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get WebLogic metadata

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get product metadata (version, features, etc.)

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Example output:
    version=19.21.0.0.0
    edition=Enterprise
    patchlevel=221018

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get Data Safe connector metadata

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get Java installation metadata

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get EM Agent metadata

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get OUD metadata

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get OMS metadata

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get Oracle Client metadata

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_metadata` {: #plugin_get_metadata }

Get database metadata

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Key=value pairs

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for Instant Client

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Instant Client has sqlplus if SQL*Plus package installed

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for WebLogic

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** Space-separated list of required binary names

!!! info "Notes"
    Used by oradba_check_oracle_binaries() to validate installation
    Example (RDBMS): "sqlplus tnsping lsnrctl"
    Example (DATASAFE): "cmctl"
    Example (CLIENT): "sqlplus tnsping"2

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Data Safe uses Connection Manager (cmctl)

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for Java

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** List of required binaries

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for EM Agent

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for OUD

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    OUD has oud-setup and other management tools

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for OMS

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for Full Client

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Full client has sqlplus and tnsping

---
### `plugin_get_required_binaries` {: #plugin_get_required_binaries }

Get list of required binaries for database

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Core database tools that should be available

---
### `plugin_get_version` {: #plugin_get_version }

Get Instant Client version

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

**Returns:** 0 on success, 1 if version cannot be determined

**Output:** Version string in X.Y format (e.g., "23.26" or "19.21")

!!! info "Notes"
    Detection methods (in order):
    1. sqlplus -version (if sqlplus available)
    2. Library filenames (libclntsh.so.X.Y, libclntshcore.so.X.Y, libocci.so.X.Y)
    3. JDBC JAR manifest (ojdbc*.jar)

---
### `plugin_get_version` {: #plugin_get_version }

Get WebLogic version

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable)

**Output:** "ERR"

!!! info "Notes"
    WebLogic version detection not implemented in stub

---
### `plugin_get_version` {: #plugin_get_version }

Get product version from ORACLE_HOME

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success

**Output:** Version string (e.g., 19.21.0.0.0)

!!! info "Notes"
    Called by plugin_get_metadata, can be overridden for efficiency

---
### `plugin_get_version` {: #plugin_get_version }

Get Java version

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success, 1 on error

**Output:** Java version string (e.g., "17.0.1", "1.8.0_291", "21.0.2")

!!! info "Notes"
    Parses output from java -version

---
### `plugin_get_version` {: #plugin_get_version }

Get EM Agent version

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable)

**Output:** "ERR"

!!! info "Notes"
    EM Agent version detection not implemented in stub

---
### `plugin_get_version` {: #plugin_get_version }

Get OMS version

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable)

**Output:** "ERR"

!!! info "Notes"
    OMS version detection not implemented in stub

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Instant clients should NOT show listener status

**Source:** `iclient_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

WebLogic should NOT show listener status

**Source:** `weblogic_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Determine if this product's tnslsnr should appear in listener section

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 if should show, 1 if should not show

!!! info "Notes"
    Database listeners: return 0
    DataSafe connectors: return 1 (they use tnslsnr but aren't DB listeners)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Data Safe connectors should NOT show in listener section

**Source:** `datasafe_plugin.sh`

**Returns:** 1 (never show)

!!! info "Notes"
    Fixes Bug #84 - DataSafe uses tnslsnr but it's not a DB listener

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Java should NOT show listener status

**Source:** `java_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

EM Agent should NOT show listener status

**Source:** `emagent_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

OUD should NOT show database listener status

**Source:** `oud_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

OMS should NOT show listener status

**Source:** `oms_plugin.sh`

**Returns:** 1 (never show)

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Clients should NOT show listener status

**Source:** `client_plugin.sh`

**Returns:** 1 (never show)

!!! info "Notes"
    Client homes don't have their own listeners

---
### `plugin_should_show_listener` {: #plugin_should_show_listener }

Database homes should show listener status

**Source:** `database_plugin.sh`

**Returns:** 0 (always show)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Instant clients don't support aliases

**Source:** `iclient_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

WebLogic doesn't support aliases

**Source:** `weblogic_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Whether this product supports SID-like aliases

**Source:** `plugin_interface.sh`

**Returns:** 0 if supports aliases, 1 if not

!!! info "Notes"
    Databases support aliases, most other products don't

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Data Safe connectors don't support aliases

**Source:** `datasafe_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Java doesn't support instance aliases

**Source:** `java_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

EM Agent doesn't support aliases

**Source:** `emagent_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

OUD instances can have aliases

**Source:** `oud_plugin.sh`

**Returns:** 0 (supports aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

OMS doesn't support aliases

**Source:** `oms_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Clients don't support SID aliases

**Source:** `client_plugin.sh`

**Returns:** 1 (no aliases)

---
### `plugin_supports_aliases` {: #plugin_supports_aliases }

Databases support SID aliases

**Source:** `database_plugin.sh`

**Returns:** 0 (supports aliases)

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is an Instant Client installation

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is a WebLogic installation

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is a valid ORACLE_HOME for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

**Output:** None

!!! info "Notes"
    Checks for product-specific files/directories

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is a Data Safe connector home

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Path to validate (base path, not oracle_cman_home)

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is a Java installation

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is an EM Agent installation

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is an OUD installation

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is an OMS installation

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is an Oracle Full Client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
### `plugin_validate_home` {: #plugin_validate_home }

Validate that path is a database home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
