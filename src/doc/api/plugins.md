# Plugin Interface

Plugin interface for product-specific functionality (database, client, datasafe, java, etc.).

<!-- markdownlint-disable MD024 -->

---

## Functions

### `get_oud_instance_base` {: #get-oud-instance-base }

Get OUD instance base directory following priority order

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path (optional, for fallback)

**Returns:** 0 on success

**Output:** Instance base directory path

!!! info "Notes"
    Priority order:
    1. $OUD_INSTANCE_BASE (if set and exists)
    2. $OUD_DATA/instances (if OUD_DATA set and directory exists)
    3. $ORACLE_DATA/instances (if ORACLE_DATA set and directory exists)
    4. $ORACLE_BASE/instances (if ORACLE_BASE set and directory exists)
    5. $ORACLE_HOME/oudBase (fallback)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for WebLogic)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for Java (no adjustment needed)

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home

**Returns:** 0 on success

**Output:** Path unchanged

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for OMS)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for database home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (unchanged for database)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust ORACLE_HOME for Data Safe

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (with /oracle_cman_home)

!!! info "Notes"
    THIS IS THE KEY FUNCTION - Consolidates logic from 8+ files

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for OUD

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for OUD)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust ORACLE_HOME for product-specific requirements

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Original ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME path

!!! info "Notes"
    Example: DataSafe appends /oracle_cman_home; align ORACLE_HOME with ORACLE_BASE_HOME if needed

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Adjusted ORACLE_HOME (unchanged for client)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for instant client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for instant client)

!!! info "Notes"
    Instant client uses ORACLE_HOME directly (no bin/ subdirectory)

---

### `plugin_adjust_environment` {: #plugin-adjust-environment }

Adjust environment for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Adjusted path (unchanged for agent)

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Input path

**Returns:** 0 on success

**Output:** Base path

!!! info "Notes"
    Stub implementation

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Input JAVA_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    For Java, base is same as JAVA_HOME

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Input path

**Returns:** 0 on success

**Output:** Base path

!!! info "Notes"
    Stub implementation

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base (ORACLE_BASE_HOME-aware)

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - Input ORACLE_HOME or ORACLE_BASE_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    For database, prefer ORACLE_BASE_HOME if set, otherwise use ORACLE_HOME

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for Data Safe

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Input path (base or oracle_cman_home)

**Returns:** 0 on success

**Output:** Normalized base path (without oracle_cman_home)

!!! info "Notes"
    DataSafe uses subdirectory structure, return base path

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for OUD

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Input ORACLE_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    For OUD, base is same as ORACLE_HOME

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base (ORACLE_BASE_HOME-aware)

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Input ORACLE_HOME or ORACLE_BASE_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    Use when ORACLE_HOME differs from installation base
    See plugin-standards.md for detailed specification

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - Input ORACLE_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    For client, ORACLE_BASE_HOME typically same as ORACLE_HOME

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for instant client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Input ORACLE_HOME

**Returns:** 0 on success

**Output:** Normalized base path

!!! info "Notes"
    For instant client, base is same as ORACLE_HOME

---

### `plugin_build_base_path` {: #plugin-build-base-path }

Resolve actual installation base for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Input path

**Returns:** 0 on success

**Output:** Base path

!!! info "Notes"
    Stub implementation

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME path

**Returns:** 0 on success

**Output:** bin directory path

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

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

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    DataSafe requires oracle_cman_home/bin

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for Oracle Unified Directory

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    OUD has bin directory with management tools

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

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
    See plugin-standards.md for detailed specification

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for Oracle Full Client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Full client has bin + OPatch directories

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for Oracle Instant Client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated PATH components

!!! info "Notes"
    Instant Client has no bin/ subdirectory - binaries in root

---

### `plugin_build_bin_path` {: #plugin-build-bin-path }

Get PATH components for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no binaries added to PATH)

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Installation path (ORACLE_HOME)
- $2 - Domain name (optional)

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Stub implementation - sets ORACLE_HOME and WLS_DOMAIN
    Full implementation would include CLASSPATH, JAVA_HOME, etc.

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME
- $2 - Not used for Java

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds environment for Java

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Installation path
- $2 - Instance (optional)

**Returns:** 0 on success

**Output:** Key=value pairs

!!! info "Notes"
    Stub implementation

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for database instance

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - ORACLE_SID (optional)

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds complete environment for database instance

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path
- $2 - Instance identifier (optional, not used for DataSafe)

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds environment for Data Safe connector

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for Oracle Unified Directory

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - OUD instance name (optional)

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds environment for OUD instance

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for the product/instance

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - Instance/domain identifier (optional)

**Returns:** 0 on success, 1 if not applicable, 2 if unavailable

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds complete environment: ORACLE_HOME, PATH, LD_LIBRARY_PATH, etc.
    See plugin-standards.md for detailed specification

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for Oracle Full Client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - Not used for client

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds environment for client tools

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for Oracle Instant Client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME
- $2 - Not used for instant client

**Returns:** 0 on success

**Output:** Key=value pairs (one per line)

!!! info "Notes"
    Builds environment for instant client

---

### `plugin_build_env` {: #plugin-build-env }

Build environment variables for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Installation path
- $2 - Instance (optional)

**Returns:** 0 on success

**Output:** Key=value pairs

!!! info "Notes"
    Stub implementation

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for WebLogic

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for Java

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME path

**Returns:** 0 on success

**Output:** Library path components

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for OMS

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

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

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    DataSafe requires oracle_cman_home/lib

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for Oracle Unified Directory

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    OUD has lib directory

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Returns the directories to add to LD_LIBRARY_PATH (or equivalent)

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for Oracle Full Client

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Prefers lib64 on 64-bit systems, falls back to lib

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for Oracle Instant Client

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Colon-separated library path components

!!! info "Notes"
    Instant Client libraries are in root, lib64, or lib subdirectory

---

### `plugin_build_lib_path` {: #plugin-build-lib-path }

Get LD_LIBRARY_PATH components for EM Agent

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (no libraries added)

---

### `plugin_check_listener_status` {: #plugin-check-listener-status }

Check listener status for database Oracle Home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string (running|stopped|unavailable)

!!! info "Notes"
    Listener lifecycle is separate from instance lifecycle
    Uses lsnrctl status to check listener state

---

### `plugin_check_listener_status` {: #plugin-check-listener-status }

Check listener status for Data Safe (not applicable)

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (unused for DataSafe)

**Returns:** 1 (not applicable - DataSafe uses cman, not DB listener)

**Output:** None (empty stdout per plugin standards)

!!! info "Notes"
    DataSafe has Connection Manager (cman) but it's not a database
    listener. Listener checks are not applicable for this product.
    Per plugin-standards.md: Return 1 for N/A, no sentinel strings.

---

### `plugin_check_listener_status` {: #plugin-check-listener-status }

Check listener status for products with listener components

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string (running|stopped|unavailable)

!!! info "Notes"
    Category-specific: mandatory for database and listener-based products
    Separate from plugin_check_status (instance status)
    Listener lifecycle is managed per Oracle Home, not per instance
    See plugin-standards.md for detailed specification

---

### `plugin_check_listener_status` {: #plugin-check-listener-status }

Report listener status for this ORACLE_HOME

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string (running|stopped|unavailable)

!!! info "Notes"
    Listener lifecycle is distinct from instance lifecycle; category-specific

---

### `plugin_check_status` {: #plugin-check-status }

Check WebLogic status

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home
- $2 - Domain name (optional)

**Returns:** 0 if running, 1 if stopped/N/A, 2 if unavailable/error

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Stub implementation - returns 2 (unavailable)

---

### `plugin_check_status` {: #plugin-check-status }

Check Java installation status

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home
- $2 - Ignored

**Returns:** 0 if available (java executable exists and is executable)

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Java is software-only, no running service

---

### `plugin_check_status` {: #plugin-check-status }

Check OMS status

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home
- $2 - Ignored

**Returns:** 0 if running, 1 if stopped/N/A, 2 if unavailable/error

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Stub implementation - returns 2 (unavailable)

---

### `plugin_check_status` {: #plugin-check-status }

Check if database instance is running

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - SID (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable/error

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Returns 2 if oracle binary is missing
    Can return metadata for mounted/nomount states in future enhancement

---

### `plugin_check_status` {: #plugin-check-status }

Check Data Safe connector status

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path or oracle_cman_home path
- $2 - Connector name (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable/error

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Multi-layered detection with fallback:
    1. cmctl show services -c \<instance\> (most accurate)
    2. Process-based detection (reliable fallback)
    3. Python setup.py (last resort)
    Supports ORADBA_CACHED_PS environment variable for batch detection

---

### `plugin_check_status` {: #plugin-check-status }

Check OUD instance status

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home
- $2 - Instance name (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable/error

**Output:** None - status communicated via exit code only

---

### `plugin_check_status` {: #plugin-check-status }

Check if product instance is running

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path
- $2 - Instance name (optional)

**Returns:** 0 if running, 1 if stopped, 2 if unavailable

**Output:** Status string (running|stopped|unavailable)

!!! info "Notes"
    Uses explicit environment (not current shell environment)
    See plugin-standards.md for exit code standards (0=running, 1=stopped, 2=unavailable)

---

### `plugin_check_status` {: #plugin-check-status }

Check client availability

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path
- $2 - Ignored (clients don't have instances)

**Returns:** 0 if available (software exists and functional)

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Clients are software-only installations without running services

---

### `plugin_check_status` {: #plugin-check-status }

Check instant client availability

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client
- $2 - Ignored (instant clients don't have instances)

**Returns:** 0 if available (library exists and readable)

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Instant client is software-only, no running service

---

### `plugin_check_status` {: #plugin-check-status }

Check EM Agent status

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home
- $2 - Ignored

**Returns:** 0 if running, 1 if stopped/N/A, 2 if unavailable/error

**Output:** None - status communicated via exit code only

!!! info "Notes"
    Stub implementation - returns 2 (unavailable)

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect WebLogic installations

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** List of WebLogic paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect Java installations under $ORACLE_BASE/product

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** List of Java installation paths

!!! info "Notes"
    Excludes JRE subdirectories within JDK installations

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect OMS installations

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** List of OMS paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect database installations

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** List of ORACLE_HOME paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect Data Safe connector installations

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** List of connector base paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect OUD installations

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** List of OUD home paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect installations of this product type

**Source:** `plugin_interface.sh`

**Arguments:**

- None

**Returns:** 0 on success

**Output:** List of installation paths (one per line)

!!! info "Notes"
    Used for auto-discovery when no registry files exist
    See doc/plugin-standards.md for return value conventions

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect Oracle Full Client installations

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** List of client home paths

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect Oracle Instant Client installations

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** List of instant client paths

!!! info "Notes"
    Excludes libraries found inside other Oracle product homes
    (e.g., DataSafe oracle_cman_home/lib, Database homes)

---

### `plugin_detect_installation` {: #plugin-detect-installation }

Auto-detect EM Agent installations

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** List of agent paths

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover WebLogic domains for this installation

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** List of domain names (one per line)

!!! info "Notes"
    Stub implementation - searches common domain locations
    Full implementation would parse domain config files

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Java doesn't have instances

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** Empty

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover instances

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Empty (stub)

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover database instances for this home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** List of instances with status

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover Data Safe connector instances

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** List of connector instances

!!! info "Notes"
    Usually 1:1 relationship (one connector per base)

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover OUD instances

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** List of instance names

!!! info "Notes"
    Uses get_oud_instance_base() to determine instance location

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover all instances for this Oracle Home

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** List of instances (one per line)

!!! info "Notes"
    Handles 1:many relationships (RAC, WebLogic, OUD)

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover instances for client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (clients don't have instances)

!!! info "Notes"
    Clients have no instances to discover

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover instances

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Empty (instant clients don't have instances)

---

### `plugin_discover_instances` {: #plugin-discover-instances }

Discover instances

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Empty (stub)

---

### `plugin_get_cman_status` {: #plugin-get-cman-status }

Get detailed Connection Manager status information

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success with status details

**Output:** Key=value pairs (start_date, uptime, gateways)

!!! info "Notes"
    Uses cmctl show status -c \<instance\> command
    Expected output format:
    Start date                10-FEB-2026 15:20:38
    Uptime                    0 days 20 hr. 7 min. 6 sec
    Num of gateways started   12
    Per plugin standards: no sentinel strings (ERR, unknown, N/A)

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for WebLogic

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** "WEBLOGIC"

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for Java

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** "JAVA"

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for OMS

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** "OMS"

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for database

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** "RDBMS"

!!! info "Notes"
    Used by oradba_apply_product_config() to load database settings

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for Data Safe

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** "DATASAFE"

!!! info "Notes"
    Used by oradba_apply_product_config() to load Data Safe settings

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for OUD

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** "OUD"

!!! info "Notes"
    Used by oradba_apply_product_config() to load OUD settings

---

### `plugin_get_config_section` {: #plugin-get-config-section }

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

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for Full Client

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** "CLIENT"

!!! info "Notes"
    Used by oradba_apply_product_config() to load client settings

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for Instant Client

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** "ICLIENT"

!!! info "Notes"
    Used by oradba_apply_product_config() to load instant client settings

---

### `plugin_get_config_section` {: #plugin-get-config-section }

Get configuration section name for EM Agent

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** "EMAGENT"

---

### `plugin_get_connection_count` {: #plugin-get-connection-count }

Get the number of active connections/tunnels

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success with connection count

**Output:** Connection count (e.g., "12")

!!! info "Notes"
    Uses cmctl show tunnels command
    Format: "Number of connections: 12."
    Per plugin standards: no sentinel strings (ERR, unknown, N/A)

---

### `plugin_get_connector_version` {: #plugin-get-connector-version }

Get Data Safe on-premises connector software version

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success with clean version string to stdout

**Output:** Version string (e.g., "220517.00")

!!! info "Notes"
    Uses python3 setup.py version command
    Expected output: "On-premises connector software version : 220517.00"
    No sentinel strings (ERR, unknown, N/A) in output
    Returns 2 when setup.py missing or python3 unavailable

---

### `plugin_get_display_name` {: #plugin-get-display-name }

Get display name for OUD instance

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Instance name

**Returns:** 0 on success

**Output:** Display name

---

### `plugin_get_display_name` {: #plugin-get-display-name }

Get custom display name for instance

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation name

**Returns:** 0 on success

**Output:** Display name

!!! info "Notes"
    Optional - defaults to installation name

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate WebLogic domains for this installation

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** domain_name|status|additional_metadata (one per line)

!!! info "Notes"
    Stub implementation - searches common domain locations
    Status is always "stopped" as we don't check actual process status yet
    Full implementation would check AdminServer and managed servers

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate Java instances

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - JAVA_HOME path

**Returns:** 0 on success

**Output:** Empty (Java doesn't have instances)

!!! info "Notes"
    Java installations don't have instances

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate OMS instances

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success

**Output:** Empty (stub)

!!! info "Notes"
    Stub implementation - will be implemented in Phase 3

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate all database instances for this ORACLE_HOME

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** instance_name|status|additional_metadata (one per line)

!!! info "Notes"
    Reads oratab for instances using this ORACLE_HOME
    Handles D (dummy) flag - sets status=stopped and metadata=dummy

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate Data Safe connector instances

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** instance_name|status|additional_metadata (one per line)

!!! info "Notes"
    DataSafe typically has one instance per installation

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate all OUD instances for this installation

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** instance_name|status|additional_metadata (one per line)

!!! info "Notes"
    OUD can have multiple instances per installation
    Instances discovered using get_oud_instance_base() priority order:
    1. $OUD_INSTANCE_BASE
    2. $OUD_DATA/instances
    3. $ORACLE_DATA/instances
    4. $ORACLE_BASE/instances
    5. $ORACLE_HOME/oudBase (fallback)
    Status is determined by checking for running OUD processes

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate all instances/domains for this ORACLE_HOME

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** instance_name|status|additional_metadata (one per line)

!!! info "Notes"
    Mandatory for multi-instance products (database, middleware, etc.)
    See plugin-standards.md for detailed specification

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate client instances

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (clients don't have instances)

!!! info "Notes"
    Clients have no instances to enumerate

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate instant client instances

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Empty (instant clients don't have instances)

!!! info "Notes"
    Instant clients have no instances

---

### `plugin_get_instance_list` {: #plugin-get-instance-list }

Enumerate EM Agent instances

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success

**Output:** Empty (stub)

!!! info "Notes"
    Stub implementation - will be implemented in Phase 3

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get WebLogic metadata

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to WebLogic home

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get Java installation metadata

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to Java home

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get OMS metadata

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to OMS home

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get database metadata

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get Data Safe connector metadata

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get OUD metadata

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to OUD home

**Returns:** 0 on success

**Output:** Key=value pairs

!!! info "Notes"
    Uses get_oud_instance_base() to count instances

---

### `plugin_get_metadata` {: #plugin-get-metadata }

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

### `plugin_get_metadata` {: #plugin-get-metadata }

Get Oracle Client metadata

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - ORACLE_HOME path

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get instant client metadata

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to instant client

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_metadata` {: #plugin-get-metadata }

Get EM Agent metadata

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to agent home

**Returns:** 0 on success

**Output:** Key=value pairs

---

### `plugin_get_port` {: #plugin-get-port }

Extract port number from cman.ora configuration

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success with port number, 1 if not found/applicable

**Output:** Port number (e.g., "1561") or nothing

!!! info "Notes"
    Extracts port from cman.ora address configuration
    Format: (address=(protocol=TCPS)(host=localhost)(port=1562))

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for WebLogic

**Source:** `weblogic_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for Java

**Source:** `java_plugin.sh`

**Returns:** 0 on success

**Output:** List of required binaries

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for OMS

**Source:** `oms_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for database

**Source:** `database_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Core database tools that should be available

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for Data Safe connector

**Source:** `datasafe_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Data Safe uses Connection Manager (cmctl)

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for OUD

**Source:** `oud_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    OUD has oud-setup and other management tools

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

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
    Example (CLIENT): "sqlplus tnsping"

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for Full Client

**Source:** `client_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Full client has sqlplus and tnsping

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for Instant Client

**Source:** `iclient_plugin.sh`

**Returns:** 0 on success

**Output:** Space-separated list of required binaries

!!! info "Notes"
    Instant Client has sqlplus if SQL\*Plus package installed

---

### `plugin_get_required_binaries` {: #plugin-get-required-binaries }

Get list of required binaries for EM Agent

**Source:** `emagent_plugin.sh`

**Returns:** 0 on success

**Output:** Empty (stub)

---

### `plugin_get_service_name` {: #plugin-get-service-name }

Extract CMAN service name from cman.ora configuration

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success

**Output:** Service name (defaults to "cust_cman")

!!! info "Notes"
    Excludes system variables (WALLET_LOCATION, SSL_VERSION, etc.)

---

### `plugin_get_version` {: #plugin-get-version }

Get WebLogic version

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable for stub)

**Output:** No output

!!! info "Notes"
    WebLogic version detection not implemented in stub
    Returns exit code 1 (N/A) per plugin standards

---

### `plugin_get_version` {: #plugin-get-version }

Get Java version

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success with clean version string to stdout

**Output:** Java version string (e.g., "17.0.1", "8.0.291", "21.0.2")

!!! info "Notes"
    Parses output from java -version
    No sentinel strings (ERR, unknown, N/A) in output

---

### `plugin_get_version` {: #plugin-get-version }

Get OMS version

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable for stub)

**Output:** No output

!!! info "Notes"
    OMS version detection not implemented in stub
    Returns exit code 1 (N/A) per plugin standards

---

### `plugin_get_version` {: #plugin-get-version }

Get Data Safe connector version

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path

**Returns:** 0 on success with clean version string to stdout

**Output:** Version string (e.g., "23.4.0.0.0")

!!! info "Notes"
    Uses cmctl show version command
    No sentinel strings (ERR, unknown, N/A) in output

---

### `plugin_get_version` {: #plugin-get-version }

Get OUD version

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success with clean version string to stdout

**Output:** Version string (e.g., "12.2.1.4.0")

!!! info "Notes"
    Detection methods (in order):
    1. config/buildinfo file
    2. setup --version command
    No sentinel strings (ERR, unknown, N/A) in output

---

### `plugin_get_version` {: #plugin-get-version }

Get product version from ORACLE_HOME

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 on success with clean version string to stdout

**Output:** Version string on success only (e.g., "19.21.0.0.0")

!!! info "Notes"
    Called by plugin_get_metadata, can be overridden for efficiency
    No sentinel strings (ERR, unknown, N/A) in output
    See plugin-standards.md for exit code contract details

---

### `plugin_get_version` {: #plugin-get-version }

Get Instant Client version

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Installation path (ORACLE_HOME)

**Returns:** 0 on success with clean version string to stdout

**Output:** Version string in X.Y format (e.g., "23.26.0.0.0" or "19.21.0.0.0")

!!! info "Notes"
    Detection methods (in order):
    1. sqlplus -version (if sqlplus available)
    2. Library filenames (libclntsh.so.X.Y, libclntshcore.so.X.Y, libocci.so.X.Y)
    3. JDBC JAR manifest (ojdbc\*.jar)
    No sentinel strings (ERR, unknown, N/A) in output

---

### `plugin_get_version` {: #plugin-get-version }

Get EM Agent version

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 1 (version not applicable for stub)

**Output:** No output

!!! info "Notes"
    EM Agent version detection not implemented in stub
    Returns exit code 1 (N/A) per plugin standards

---

### `plugin_set_environment` {: #plugin-set-environment }

Set DataSafe-specific environment variables (not part of standard interface)

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path (will be adjusted to oracle_cman_home)

**Returns:** 0 on success

**Output:** None (modifies environment directly)

!!! info "Notes"
    DataSafe MUST use its own TNS_ADMIN - cannot share with other connectors
    This function sets connector-specific environment variables that must
    override any inherited values. Always call after setting ORACLE_HOME.

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

WebLogic should NOT show listener status

**Source:** `weblogic_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Java should NOT show listener status

**Source:** `java_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

OMS should NOT show listener status

**Source:** `oms_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Database homes should show listener status

**Source:** `database_plugin.sh`

**Returns:** 0 (always show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Data Safe connectors should NOT show in listener section

**Source:** `datasafe_plugin.sh`

**Returns:** 1 (never show)

!!! info "Notes"
    Fixes Bug #84 - DataSafe uses tnslsnr but it's not a DB listener

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

OUD should NOT show database listener status

**Source:** `oud_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Determine if this product's tnslsnr should appear in listener section

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Installation path

**Returns:** 0 if should show, 1 if should not show

!!! info "Notes"
    Database listeners: return 0
    DataSafe connectors: return 1 (they use tnslsnr but aren't DB listeners)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Clients should NOT show listener status

**Source:** `client_plugin.sh`

**Returns:** 1 (never show)

!!! info "Notes"
    Client homes don't have their own listeners

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

Instant clients should NOT show listener status

**Source:** `iclient_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_should_show_listener` {: #plugin-should-show-listener }

EM Agent should NOT show listener status

**Source:** `emagent_plugin.sh`

**Returns:** 1 (never show)

---

### `plugin_stop` {: #plugin-stop }

Stop DataSafe connector instance

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Base path
- $2 - Connector name (optional)
- $3 - Timeout in seconds (optional, default: 180)

**Returns:** 0 on success, 1 on error

**Output:** None (logs to oradba_log)

!!! info "Notes"
    Uses cmctl shutdown with -c instance_name parameter
    Falls back to pkill if cmctl fails or processes remain
    Verifies processes are actually stopped

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

WebLogic doesn't support aliases

**Source:** `weblogic_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Java doesn't support instance aliases

**Source:** `java_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

OMS doesn't support aliases

**Source:** `oms_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Databases support SID aliases

**Source:** `database_plugin.sh`

**Returns:** 0 (supports aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Data Safe connectors don't support aliases

**Source:** `datasafe_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

OUD instances can have aliases

**Source:** `oud_plugin.sh`

**Returns:** 0 (supports aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Whether this product supports SID-like aliases

**Source:** `plugin_interface.sh`

**Returns:** 0 if supports aliases, 1 if not

!!! info "Notes"
    Databases support aliases, most other products don't

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Clients don't support SID aliases

**Source:** `client_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

Instant clients don't support aliases

**Source:** `iclient_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_supports_aliases` {: #plugin-supports-aliases }

EM Agent doesn't support aliases

**Source:** `emagent_plugin.sh`

**Returns:** 1 (no aliases)

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is a WebLogic installation

**Source:** `weblogic_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is a Java installation

**Source:** `java_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is an OMS installation

**Source:** `oms_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is a database home

**Source:** `database_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is a Data Safe connector home

**Source:** `datasafe_plugin.sh`

**Arguments:**

- $1 - Path to validate (base path, not oracle_cman_home)

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is an OUD installation

**Source:** `oud_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is a valid ORACLE_HOME for this product

**Source:** `plugin_interface.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

**Output:** None

!!! info "Notes"
    Checks for product-specific files/directories
    See plugin-standards.md for validation strategies

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is an Oracle Full Client home

**Source:** `client_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is an Instant Client installation

**Source:** `iclient_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---

### `plugin_validate_home` {: #plugin-validate-home }

Validate that path is an EM Agent installation

**Source:** `emagent_plugin.sh`

**Arguments:**

- $1 - Path to validate

**Returns:** 0 if valid, 1 if invalid

---
