# OraDBA API Documentation

Complete function reference for OraDBA v0.19.0+ libraries.

**Last Updated:** 2026-01-20

## Table of Contents

- [Library Organization](#library-organization)
- [Registry API](#registry-api)
- [Plugin Interface](#plugin-interface)
- [Environment Management Libraries](#environment-management-libraries)
- [Core Utilities](#core-utilities)
- [Database Operations](#database-operations)
- [Alias Management](#alias-management)

---

## Library Organization

OraDBA v0.19.0+ uses a modular architecture with clearly separated concerns:

### 1. Registry API (`oradba_registry.sh`)

Unified interface for Oracle installation discovery and management. Single source of truth combining `oratab` and `oradba_homes.conf`.

**Key Functions:**

- `oradba_registry_get_all` - Get all installations
- `oradba_registry_get_by_name` - Get by NAME (SID/home name)
- `oradba_registry_get_by_type` - Get by product type
- `oradba_registry_get_by_home` - Get by ORACLE_HOME path
- `oradba_registry_get_status` - Check service status
- `oradba_registry_validate_entry` - Validate entry

### 2. Plugin System (6 product-specific plugins)

**Plugins:**

- `database_plugin.sh` - Oracle Database (RDBMS)
- `datasafe_plugin.sh` - Data Safe On-Premises Connector
- `client_plugin.sh` - Oracle Full Client
- `iclient_plugin.sh` - Oracle Instant Client
- `oud_plugin.sh` - Oracle Unified Directory
- `java_plugin.sh` - Java JDK/JRE

**Standard Interface (8 functions per plugin):**

- `plugin_detect_installation` - Auto-discover installations
- `plugin_validate_home` - Validate ORACLE_HOME
- `plugin_adjust_environment` - Adjust PATH/environment
- `plugin_check_status` - Check service status
- `plugin_get_metadata` - Extract version/edition
- `plugin_should_show_listener` - Show listener?
- `plugin_discover_instances` - Find instances
- `plugin_supports_aliases` - Support aliases?

### 3. Environment Management Libraries (6 libraries)

**Parser** (`oradba_env_parser.sh`) - Parse and merge 6 configuration levels  
**Builder** (`oradba_env_builder.sh`) - Build Oracle environment variables  
**Validator** (`oradba_env_validator.sh`) - Validate Oracle installations  
**Config** (`oradba_env_config.sh`) - Configuration management  
**Status** (`oradba_env_status.sh`) - Status display and formatting  
**Changes** (`oradba_env_changes.sh`) - Change detection and tracking

### 4. Core Utilities

**Common** (`oradba_common.sh`) - Logging, utilities, PATH management  
**Database** (`oradba_db_functions.sh`) - Database operations and queries  
**Aliases** (`oradba_aliases.sh`) - Alias generation and management

---

## Registry API

The Registry API (`oradba_registry.sh`) provides unified access to Oracle
installations from both `oratab` and `oradba_homes.conf`.

### Output Format

All Registry API functions return colon-delimited entries:

```text
NAME:ORACLE_HOME:PRODUCT_TYPE:VERSION:AUTO_START:DESCRIPTION
```

**Fields:**

- `NAME` - Entry name (SID for databases, home name for others)
- `ORACLE_HOME` - Installation path
- `PRODUCT_TYPE` - One of: `database`, `client`, `iclient`, `datasafe`, `oud`, `java`
- `VERSION` - Oracle/product version or "N/A"
- `AUTO_START` - Auto-start flag (Y/N) or "N/A"
- `DESCRIPTION` - Optional description

**Example entries:**

```bash
# Database (from oratab)
FREE:/opt/oracle/product/23ai/dbhomeFree:database:23.6.0.0.0:Y:Oracle 23ai Free

# Instant Client (from oradba_homes.conf)
iclient21:/opt/oracle/product/instantclient_21_15:iclient:21.15.0.0.0:N/A:Oracle Instant Client 21.15

# Java (from oradba_homes.conf)
jdk17:/opt/oracle/product/jdk-17:java:17.0.12:N/A:Oracle JDK 17

# Data Safe Connector (from oradba_homes.conf)
datasafe-conn:/u01/app/oracle/ds-conn:datasafe:N/A:N/A:Data Safe Connector
```

### Core Functions

#### oradba_registry_get_all

Get all Oracle installations from both `oratab` and `oradba_homes.conf`.

**Syntax:**

```bash
oradba_registry_get_all
```

**Arguments:** None

**Returns:**  

- Colon-delimited entries (one per line) for all installations
- Exit code 0 on success

**Output:** Multiple lines in format `NAME:ORACLE_HOME:PRODUCT_TYPE:VERSION:AUTO_START:DESCRIPTION`

**Example:**

```bash
# List all Oracle installations
oradba_registry_get_all

# Output:
# FREE:/opt/oracle/product/23ai/dbhomeFree:database:23.6.0.0.0:Y:Oracle 23ai Free
# iclient21:/opt/oracle/instantclient_21_15:iclient:21.15.0.0.0:N/A:Instant Client
# jdk17:/opt/oracle/jdk-17:java:17.0.12:N/A:Oracle JDK 17
# datasafe-conn:/u01/app/oracle/ds-conn:datasafe:N/A:N/A:Data Safe Connector

# Parse and process all entries
while IFS=: read -r name home type version auto_start desc; do
    echo "Found $type: $name at $home"
done < <(oradba_registry_get_all)
```

#### oradba_registry_get_by_name

Get entry by NAME (SID or home name).

**Syntax:**

```bash
oradba_registry_get_by_name <name>
```

**Arguments:**

- `$1` - NAME to search for (case-sensitive)

**Returns:**

- Colon-delimited entry if found
- Exit code 0 if found, 1 if not found

**Example:**

```bash
# Get specific database
entry=$(oradba_registry_get_by_name "FREE")
echo "$entry"
# Output: FREE:/opt/oracle/product/23ai/dbhomeFree:database:23.6.0.0.0:Y:Oracle 23ai Free

# Parse fields
IFS=: read -r name home type version auto_start desc <<< "$entry"
echo "Oracle Home: $home"
echo "Product Type: $type"
echo "Version: $version"

# Check if entry exists
if oradba_registry_get_by_name "NONEXISTENT" >/dev/null 2>&1; then
    echo "Entry found"
else
    echo "Entry not found"
fi
```

#### oradba_registry_get_by_type

Get all entries of a specific product type.

**Syntax:**

```bash
oradba_registry_get_by_type <product_type>
```

**Arguments:**

- `$1` - Product type: `database`, `client`, `iclient`, `datasafe`, `oud`, or `java`

**Returns:**

- Colon-delimited entries (one per line) for matching type
- Exit code 0 on success (even if no matches)

**Example:**

```bash
# Get all Java installations
oradba_registry_get_by_type "java"
# Output:
# jdk17:/opt/oracle/jdk-17:java:17.0.12:N/A:Oracle JDK 17
# jdk11:/opt/oracle/jdk-11:java:11.0.21:N/A:Oracle JDK 11

# Get all databases
oradba_registry_get_by_type "database" | while IFS=: read -r name home type version auto_start desc; do
    echo "Database: $name (version $version)"
done

# Count installations by type
count=$(oradba_registry_get_by_type "database" | wc -l)
echo "Found $count database(s)"
```

#### oradba_registry_get_by_home

Get entry by ORACLE_HOME path.

**Syntax:**

```bash
oradba_registry_get_by_home <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path to search for (must match exactly)

**Returns:**

- Colon-delimited entry if found
- Exit code 0 if found, 1 if not found

**Example:**

```bash
# Find entry by path
entry=$(oradba_registry_get_by_home "/opt/oracle/product/23ai/dbhomeFree")
IFS=: read -r name home type version auto_start desc <<< "$entry"
echo "Entry name: $name"
echo "Type: $type"

# Reverse lookup - find name from current ORACLE_HOME
if [[ -n "${ORACLE_HOME}" ]]; then
    entry=$(oradba_registry_get_by_home "${ORACLE_HOME}")
    IFS=: read -r name _ _ _ _ _ <<< "$entry"
    echo "Current environment is for: $name"
fi
```

#### oradba_registry_get_status

Get service status for an entry (delegates to appropriate plugin).

**Syntax:**

```bash
oradba_registry_get_status <name>
```

**Arguments:**

- `$1` - NAME to check status for

**Returns:**

- Status string from plugin's check_status function
- Possible values: `RUNNING`, `STOPPED`, `UNKNOWN`, `N/A`
- Exit code 0 on success

**Example:**

```bash
# Check database status
status=$(oradba_registry_get_status "FREE")
echo "Database FREE is: $status"
# Output: Database FREE is: RUNNING

# Check DataSafe connector status
status=$(oradba_registry_get_status "datasafe-conn")
echo "Connector status: $status"

# Check all databases
oradba_registry_get_by_type "database" | while IFS=: read -r name home _; do
    status=$(oradba_registry_get_status "$name")
    echo "$name: $status"
done
```

#### oradba_registry_validate_entry

Validate an entry using appropriate plugin.

**Syntax:**

```bash
oradba_registry_validate_entry <name>
```

**Arguments:**

- `$1` - NAME to validate

**Returns:**

- Exit code 0 if valid, 1 if invalid
- Validation messages on stderr

**Example:**

```bash
# Validate database home
if oradba_registry_validate_entry "FREE"; then
    echo "FREE is valid"
else
    echo "FREE validation failed"
fi

# Validate all entries
oradba_registry_get_all | while IFS=: read -r name home type _; do
    if oradba_registry_validate_entry "$name" 2>/dev/null; then
        echo "✓ $name ($type)"
    else
        echo "✗ $name ($type) - INVALID"
    fi
done
```

---

## Plugin Interface

Each of the 6 product plugins implements this standard 8-function interface.
All plugin functions must be prefixed with `plugin_` when called.

### Loading Plugins

Plugins are automatically loaded by the Registry API, but can also be loaded manually:

```bash
# Load specific plugin
source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"

# All plugins are in
ls "${ORADBA_BASE}/lib/plugins/"
# database_plugin.sh  datasafe_plugin.sh  client_plugin.sh
# iclient_plugin.sh   oud_plugin.sh       java_plugin.sh
```

### Required Functions

#### plugin_detect_installation

Auto-discover installations of this product type on the system.

**Syntax:**

```bash
plugin_detect_installation
```

**Arguments:** None

**Returns:**

- Prints detected installations (one per line)  
  Format: `ORACLE_HOME|NAME|VERSION|DESCRIPTION`
- Exit code 0 on success

**Example:**

```bash
# Detect all Java installations
source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"
plugin_detect_installation

# Output:
# /opt/oracle/jdk-17|jdk17|17.0.12|Oracle JDK 17
# /usr/lib/jvm/java-11|jdk11|11.0.21|OpenJDK 11

# Process detected installations
plugin_detect_installation | while IFS='|' read -r home name version desc; do
    echo "Found: $name at $home (version $version)"
done
```

#### plugin_validate_home

Validate that ORACLE_HOME is a valid installation of this product type.

**Syntax:**

```bash
plugin_validate_home <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path to validate

**Returns:**

- Exit code 0 if valid
- Exit code 1 if invalid (with error message on stderr)

**Example:**

```bash
# Validate Java home
if plugin_validate_home "/opt/oracle/jdk-17"; then
    echo "Valid Java installation"
else
    echo "Invalid Java installation"
fi

# Validate before setting environment
oracle_home="/opt/oracle/product/23ai/dbhomeFree"
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
if plugin_validate_home "$oracle_home"; then
    export ORACLE_HOME="$oracle_home"
fi
```

#### plugin_adjust_environment

Adjust PATH and other environment variables for this product type (optional).

**Syntax:**

```bash
plugin_adjust_environment <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- Prints export statements to eval (or nothing if no adjustments needed)
- Exit code 0

**Example:**

```bash
# Get environment adjustments for Java
eval "$(plugin_adjust_environment "/opt/oracle/jdk-17")"
# May output: export PATH="/opt/oracle/jdk-17/bin:$PATH"
# May output: export JAVA_HOME="/opt/oracle/jdk-17"

# Instant Client adjustments (no bin subdirectory)
source "${ORADBA_BASE}/lib/plugins/iclient_plugin.sh"
eval "$(plugin_adjust_environment "/opt/oracle/instantclient_21_15")"
# Adds /opt/oracle/instantclient_21_15 directly to PATH
```

#### plugin_check_status

Check if service/instance is running.

**Syntax:**

```bash
plugin_check_status <oracle_home> <name>
```

**Arguments:**

- `$1` - ORACLE_HOME path
- `$2` - Instance/service name

**Returns:**

- Status string: `RUNNING`, `STOPPED`, `UNKNOWN`, or `N/A`
- Exit code 0

**Example:**

```bash
# Check database status
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
status=$(plugin_check_status "/opt/oracle/product/23ai/dbhomeFree" "FREE")
echo "$status"  # Output: RUNNING or STOPPED

# Check Data Safe connector
source "${ORADBA_BASE}/lib/plugins/datasafe_plugin.sh"
status=$(plugin_check_status "/u01/app/oracle/ds-conn" "datasafe-conn")
echo "Connector: $status"
```

#### plugin_get_metadata

Extract version, edition, and other metadata from the installation.

**Syntax:**

```bash
plugin_get_metadata <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- Pipe-delimited metadata: `VERSION|EDITION|PATCH_LEVEL`
- Exit code 0

**Example:**

```bash
# Get Java version
source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"
metadata=$(plugin_get_metadata "/opt/oracle/jdk-17")
IFS='|' read -r version edition patch <<< "$metadata"
echo "Version: $version"  # Output: 17.0.12

# Get database metadata
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
metadata=$(plugin_get_metadata "/opt/oracle/product/23ai/dbhomeFree")
IFS='|' read -r version edition patch <<< "$metadata"
echo "Version: $version, Edition: $edition"
```

#### plugin_should_show_listener

Indicate if listener status should be shown for this product type.

**Syntax:**

```bash
plugin_should_show_listener <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- Exit code 0 if listener should be shown
- Exit code 1 if listener should not be shown

**Example:**

```bash
# Check if listener applies to this product type
if plugin_should_show_listener "$ORACLE_HOME"; then
    lsnrctl status
fi

# Database and client show listener, others don't
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
plugin_should_show_listener "/opt/oracle/product/23ai/dbhomeFree"  # Returns 0

source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"
plugin_should_show_listener "/opt/oracle/jdk-17"  # Returns 1
```

#### plugin_discover_instances

Discover all instances/services for this ORACLE_HOME.

**Syntax:**

```bash
plugin_discover_instances <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- List of instance/service names (one per line)
- Exit code 0

**Example:**

```bash
# Find all databases for a home
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
instances=$(plugin_discover_instances "/opt/oracle/product/23ai/dbhomeFree")
echo "$instances"
# Output:
# FREE
# TEST

# Process each instance
plugin_discover_instances "$ORACLE_HOME" | while read -r sid; do
    echo "Found instance: $sid"
    status=$(plugin_check_status "$ORACLE_HOME" "$sid")
    echo "  Status: $status"
done
```

#### plugin_supports_aliases

Indicate if this product type supports SID-based aliases.

**Syntax:**

```bash
plugin_supports_aliases <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- Exit code 0 if aliases supported
- Exit code 1 if aliases not supported

**Example:**

```bash
# Check if aliases should be generated
if plugin_supports_aliases "$ORACLE_HOME"; then
    # Generate aliases for this SID
    generate_aliases_for_sid "$SID"
fi

# Database supports aliases, Java doesn't
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"
plugin_supports_aliases "/opt/oracle/product/23ai/dbhomeFree"  # Returns 0

source "${ORADBA_BASE}/lib/plugins/java_plugin.sh"
plugin_supports_aliases "/opt/oracle/jdk-17"  # Returns 1
```

---

## Environment Management Libraries

These libraries handle environment building, parsing, validation, and configuration management.

### oradba_env_parser.sh

Parse and merge configuration from 6 hierarchical levels.

#### parse_configuration

Parse configuration hierarchy and merge settings.

**Syntax:**

```bash
parse_configuration <sid_or_name> <product_type>
```

**Arguments:**

- `$1` - SID or Oracle Home name
- `$2` - Product type (database, client, etc.)

**Returns:**

- Sets environment variables from merged configuration
- Exit code 0 on success

**Configuration Hierarchy (lowest to highest priority):**

1. Core (`oradba_core.conf`)
2. Standard (`oradba_standard.conf`)
3. Local (`oradba_local.conf`) - optional
4. Customer (`oradba_customer.conf`) - optional
5. SID-specific (`sid.<SID>.conf`) - optional
6. Environment variables

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"

# Parse configuration for database SID
parse_configuration "FREE" "database"

# Parse for Java home
parse_configuration "jdk17" "java"
```

### oradba_env_builder.sh

Build Oracle environment variables.

#### build_oracle_environment

Build complete Oracle environment for a SID or home.

**Syntax:**

```bash
build_oracle_environment <sid_or_name> <oracle_home> <product_type>
```

**Arguments:**

- `$1` - SID or Oracle Home name
- `$2` - ORACLE_HOME path
- `$3` - Product type

**Returns:**

- Sets ORACLE_HOME, ORACLE_SID, PATH, LD_LIBRARY_PATH, etc.
- Exit code 0 on success

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"

# Build environment for database
build_oracle_environment "FREE" "/opt/oracle/product/23ai/dbhomeFree" "database"

# Verify
echo "ORACLE_HOME: $ORACLE_HOME"
echo "ORACLE_SID: $ORACLE_SID"
echo "PATH: $PATH"
```

#### set_oracle_environment_paths

Set PATH and LD_LIBRARY_PATH based on product type.

**Syntax:**

```bash
set_oracle_environment_paths <product_type> <oracle_home>
```

**Arguments:**

- `$1` - Product type
- `$2` - ORACLE_HOME path

**Returns:**

- Modifies PATH and LD_LIBRARY_PATH
- Exit code 0

**Example:**

```bash
# Set paths for database
set_oracle_environment_paths "database" "/opt/oracle/product/23ai/dbhomeFree"
# Adds $ORACLE_HOME/bin to PATH
# Adds $ORACLE_HOME/lib to LD_LIBRARY_PATH

# Set paths for Instant Client (no bin subdirectory)
set_oracle_environment_paths "iclient" "/opt/oracle/instantclient_21_15"
# Adds /opt/oracle/instantclient_21_15 directly to PATH
```

### oradba_env_validator.sh

Validate Oracle installations and environments.

#### validate_oracle_environment

Validate complete Oracle environment.

**Syntax:**

```bash
validate_oracle_environment <sid_or_name> <product_type>
```

**Arguments:**

- `$1` - SID or Oracle Home name
- `$2` - Product type

**Returns:**

- Exit code 0 if valid
- Exit code 1 if invalid (with errors on stderr)

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_validator.sh"

# Validate database environment
if validate_oracle_environment "FREE" "database"; then
    echo "Environment is valid"
else
    echo "Environment validation failed"
fi

# Validate Java environment (minimal checks)
validate_oracle_environment "jdk17" "java"
```

#### validate_oracle_home

Validate ORACLE_HOME path and structure.

**Syntax:**

```bash
validate_oracle_home <oracle_home> <product_type>
```

**Arguments:**

- `$1` - ORACLE_HOME path
- `$2` - Product type

**Returns:**

- Exit code 0 if valid
- Exit code 1 if invalid

**Example:**

```bash
# Validate database home
if validate_oracle_home "/opt/oracle/product/23ai/dbhomeFree" "database"; then
    echo "Valid database home"
fi

# Uses plugin validation internally
```

### oradba_env_config.sh

Configuration management functions.

#### load_config_file

Load and parse a configuration file.

**Syntax:**

```bash
load_config_file <config_file>
```

**Arguments:**

- `$1` - Path to configuration file

**Returns:**

- Sources configuration file
- Exit code 0 on success, 1 if file not found

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_config.sh"

# Load customer configuration
if load_config_file "${ORADBA_PREFIX}/etc/oradba_customer.conf"; then
    echo "Customer config loaded"
fi

# Load SID-specific config
load_config_file "${ORADBA_PREFIX}/etc/sid.FREE.conf"
```

### oradba_env_status.sh

Status display and formatting functions.

#### show_oracle_environment

Display current Oracle environment settings.

**Syntax:**

```bash
show_oracle_environment [--format <format>]
```

**Arguments:**

- `--format` - Output format: `simple`, `detailed`, `json` (default: `simple`)

**Returns:**

- Prints environment information
- Exit code 0

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_status.sh"

# Show simple format
show_oracle_environment

# Show detailed format
show_oracle_environment --format detailed

# Get JSON output
show_oracle_environment --format json
```

### oradba_env_changes.sh

Change detection and tracking.

#### detect_environment_changes

Detect what changed between old and new environment.

**Syntax:**

```bash
detect_environment_changes
```

**Arguments:** None (uses global variables)

**Returns:**

- Prints changed variables
- Exit code 0

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_env_changes.sh"

# Detect changes after environment switch
detect_environment_changes
```

---

## Core Utilities

### oradba_common.sh

Core utility functions used throughout OraDBA.

#### oradba_log

Unified logging function with configurable log levels.

**Syntax:**

```bash
oradba_log <level> <message>
```

**Arguments:**

- `$1` - Log level: `DEBUG`, `INFO`, `WARN`, `ERROR`
- `$2` - Log message

**Environment:**

- `ORADBA_LOG_LEVEL` - Minimum level to display (default: `INFO`)

**Returns:**

- Prints log message to stderr
- Exit code 0

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_common.sh"

# Log messages
oradba_log INFO "Database started successfully"
oradba_log WARN "Archive log directory is 90% full"
oradba_log ERROR "Connection to database failed"
oradba_log DEBUG "SQL query: ${sql_query}"

# Configure log level
export ORADBA_LOG_LEVEL=DEBUG  # Show all messages
export ORADBA_LOG_LEVEL=WARN   # Show only WARN and ERROR
```

#### oradba_dedupe_path

Deduplicate PATH variable by removing duplicate entries.

**Syntax:**

```bash
oradba_dedupe_path
```

**Arguments:** None

**Returns:**

- Modifies global PATH variable
- Exit code 0

**Example:**

```bash
# Before
echo "$PATH"
# /bin:/usr/bin:/bin:/opt/oracle/bin:/usr/bin

oradba_dedupe_path

# After
echo "$PATH"
# /bin:/usr/bin:/opt/oracle/bin
```

#### detect_product_type

Detect Oracle product type from ORACLE_HOME filesystem.

**Syntax:**

```bash
detect_product_type <oracle_home>
```

**Arguments:**

- `$1` - ORACLE_HOME path

**Returns:**

- Prints product type: `database`, `client`, `iclient`, `datasafe`, `oud`, `java`, or `unknown`
- Exit code 0

**Example:**

```bash
# Detect product type
product_type=$(detect_product_type "/opt/oracle/product/23ai/dbhomeFree")
echo "$product_type"  # Output: database

product_type=$(detect_product_type "/opt/oracle/jdk-17")
echo "$product_type"  # Output: java
```

#### parse_oratab

Parse oratab file and extract entries.

**Syntax:**

```bash
parse_oratab [<sid>]
```

**Arguments:**

- `$1` - Optional SID to search for (if omitted, returns all entries)

**Returns:**

- Prints oratab entries (one per line)
- Format: `SID:ORACLE_HOME:AUTO_START`
- Exit code 0

**Example:**

```bash
# Get all oratab entries
parse_oratab
# Output:
# FREE:/opt/oracle/product/23ai/dbhomeFree:Y
# TEST:/opt/oracle/product/19c/dbhome_1:N

# Get specific SID
entry=$(parse_oratab "FREE")
IFS=: read -r sid oracle_home auto_start <<< "$entry"
echo "ORACLE_HOME: $oracle_home"
```

#### verify_oracle_env

Verify Oracle environment variables are set correctly.

**Syntax:**

```bash
verify_oracle_env
```

**Arguments:** None

**Returns:**

- Exit code 0 if environment is valid
- Exit code 1 if invalid (with error on stderr)

**Example:**

```bash
# Verify before running database commands
if verify_oracle_env; then
    sqlplus / as sysdba
else
    echo "Oracle environment not set correctly"
    exit 1
fi
```

---

## Database Operations

### oradba_db_functions.sh

Database-specific operations and queries.

#### execute_db_query

Execute SQL query with simplified interface.

**Syntax:**

```bash
execute_db_query <query> [<format>]
```

**Arguments:**

- `$1` - SQL query (escape dollar signs: `v\$database`)
- `$2` - Output format: `raw` (default) or `delimited` (pipe-separated, first line only)

**Returns:**

- Query results to stdout
- Exit code 0 on success, 1 on error

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

# Simple query (raw format)
query="SELECT name FROM v\$database;"
db_name=$(execute_db_query "$query" "raw")
echo "Database: $db_name"

# Pipe-delimited output
query="SELECT name || '|' || db_unique_name FROM v\$database;"
result=$(execute_db_query "$query" "delimited")
IFS='|' read -r db_name db_unique_name <<< "$result"

# With error handling
if ! result=$(execute_db_query "$query" "raw"); then
    oradba_log ERROR "Failed to query database"
    exit 1
fi
```

#### check_database_status

Check if database instance is running.

**Syntax:**

```bash
check_database_status <sid>
```

**Arguments:**

- `$1` - Database SID

**Returns:**

- Prints status: `RUNNING`, `STOPPED`, or `UNKNOWN`
- Exit code 0

**Example:**

```bash
# Check database status
status=$(check_database_status "FREE")
if [[ "$status" == "RUNNING" ]]; then
    echo "Database is up"
else
    echo "Database is down"
fi
```

#### check_listener_status

Check if listener is running.

**Syntax:**

```bash
check_listener_status [<listener_name>]
```

**Arguments:**

- `$1` - Optional listener name (default: LISTENER)

**Returns:**

- Prints status: `RUNNING`, `STOPPED`, or `UNKNOWN`
- Exit code 0

**Example:**

```bash
# Check default listener
status=$(check_listener_status)
echo "Listener status: $status"

# Check specific listener
status=$(check_listener_status "LISTENER_FREE")
```

#### get_database_version

Get Oracle database version.

**Syntax:**

```bash
get_database_version
```

**Arguments:** None (uses current ORACLE_HOME)

**Returns:**

- Prints version string (e.g., "23.6.0.0.0")
- Exit code 0 on success

**Example:**

```bash
version=$(get_database_version)
echo "Oracle Database version: $version"

# Version comparison
if [[ "${version%%.*}" -ge 23 ]]; then
    echo "Oracle 23ai or later"
fi
```

---

## Alias Management

### oradba_aliases.sh

Alias generation and management for database environments.

#### generate_aliases_for_sid

Generate database-related aliases for a SID.

**Syntax:**

```bash
generate_aliases_for_sid <sid>
```

**Arguments:**

- `$1` - Database SID

**Returns:**

- Creates aliases in current shell
- Exit code 0

**Generated Aliases:**

- `sql` - Connect as SYSDBA
- `sqlu` - Connect as user
- `rman` - Start RMAN
- `dgmgrl` - Start Data Guard Manager
- `adrci` - Start ADR Command Interpreter

**Example:**

```bash
source "${ORADBA_BASE}/lib/oradba_aliases.sh"

# Generate aliases for database
generate_aliases_for_sid "FREE"

# Now can use:
# sql       -> sqlplus / as sysdba
# sqlu      -> sqlplus user/pass
# rman      -> rman target /
```

#### clear_aliases

Clear all OraDBA-generated aliases.

**Syntax:**

```bash
clear_aliases
```

**Arguments:** None

**Returns:**

- Removes all OraDBA aliases
- Exit code 0

**Example:**

```bash
# Clear old aliases before switching SID
clear_aliases
generate_aliases_for_sid "NEWDB"
```

---

## Best Practices

### Error Handling

Always check return codes for critical operations:

```bash
# Check if entry exists before using
if ! entry=$(oradba_registry_get_by_name "FREE" 2>/dev/null); then
    oradba_log ERROR "Database FREE not found in registry"
    exit 1
fi

# Validate before setting environment
if ! validate_oracle_home "$oracle_home" "$product_type"; then
    oradba_log ERROR "Invalid Oracle Home: $oracle_home"
    exit 1
fi
```

### Using Plugins

Load plugins explicitly when needed:

```bash
# Load plugin
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"

# Use plugin functions
if plugin_validate_home "$ORACLE_HOME"; then
    metadata=$(plugin_get_metadata "$ORACLE_HOME")
    oradba_log INFO "Metadata: $metadata"
fi
```

### Configuration Management

Use the hierarchical configuration system:

```bash
# Create customer configuration
cat > "${ORADBA_PREFIX}/etc/oradba_customer.conf" <<EOF
# Custom settings
export ORADBA_LOG_LEVEL=DEBUG
export PATH_DEDUPE_ENABLED=true
EOF

# Create SID-specific configuration
cat > "${ORADBA_PREFIX}/etc/sid.FREE.conf" <<EOF
# FREE database specific settings
export TNS_ADMIN=/opt/oracle/network/admin/FREE
EOF
```

### Logging

Use consistent logging levels:

```bash
# Informational messages
oradba_log INFO "Starting database environment setup"

# Warnings for non-critical issues
oradba_log WARN "Archive log directory approaching capacity"

# Errors for failures
oradba_log ERROR "Failed to connect to database"

# Debug for troubleshooting
oradba_log DEBUG "Configuration file: $config_file"
```

---

## See Also

- [Architecture Documentation](architecture.md) - System design and components
- [Development Guide](development.md) - Development workflow and standards
- [Extension System](extension-system.md) - Creating OraDBA extensions
- [User Documentation](../src/doc/index.md) - End-user guides and reference

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20  
**OraDBA Version:** v0.19.0+
