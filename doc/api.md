# oradba API Documentation

## Common Library Functions

This document describes the public API of the oradba common library (`src/lib/common.sh`).

## Logging Functions

### init_logging

**New in v0.14.0**: Initialize logging infrastructure with directory creation.

Creates log directory structure and sets up log file paths. Automatically falls
back to user home directory if system directory is not writable.

**Syntax**: `init_logging`

**Environment (Input)**:

- `ORADBA_LOG_DIR` - Custom log directory (optional)
  - If not set, tries `/var/log/oradba` first, then `~/.oradba/logs`

**Environment (Output)**:

- `ORADBA_LOG_DIR` - Log directory path (created if needed)
- `ORADBA_LOG_FILE` - Main log file path (set to `${ORADBA_LOG_DIR}/oradba.log`)

**Returns**:

- `0` - Success
- `1` - Failed to create log directory

**Examples**:

```bash
# Use default location (/var/log/oradba or ~/.oradba/logs)
init_logging

# Use custom directory
export ORADBA_LOG_DIR="/opt/oracle/logs"
init_logging

# Check result
echo "Logging to: ${ORADBA_LOG_FILE}"
```

**Behavior**:

1. Determines log directory (custom, system, or user)
2. Creates directory if it doesn't exist
3. Falls back to `~/.oradba/logs` if system location fails
4. Sets `ORADBA_LOG_FILE` to `oradba.log` in the directory
5. Can be called multiple times safely (idempotent)

### init_session_log

**New in v0.14.0**: Initialize per-session logging with metadata header.

Creates individual log file for current session with metadata header including
timestamp, user, host, PID, and Oracle environment variables.

**Syntax**: `init_session_log`

**Environment (Input)**:

- `ORADBA_SESSION_LOGGING` - Enable session logging (default: `false`)
- `ORADBA_SESSION_LOG_ONLY` - Use session log as primary log (default: `false`)
- `ORADBA_LOG_DIR` - Log directory (calls `init_logging` if not set)

**Environment (Output)**:

- `ORADBA_SESSION_LOG` - Session log file path
- `ORADBA_LOG_FILE` - Updated to session log if `ORADBA_SESSION_LOG_ONLY=true`

**Returns**:

- `0` - Success or feature disabled

**Examples**:

```bash
# Enable session logging
export ORADBA_SESSION_LOGGING="true"
init_logging
init_session_log

# View session log location
echo "Session log: ${ORADBA_SESSION_LOG}"

# Session log only (no dual logging)
export ORADBA_SESSION_LOGGING="true"
export ORADBA_SESSION_LOG_ONLY="true"
init_session_log
```

**Session Log Header**:

```text
# ------------------------------------------------------------------------------
# OraDBA Session Log
# ------------------------------------------------------------------------------
# Started....: 2026-01-05 16:25:30
# User.......: oracle
# Host.......: dbserver01
# PID........: 12345
# ORACLE_SID.: PRODDB
# ORACLE_HOME: /u01/app/oracle/product/19.0.0/dbhome_1
# ------------------------------------------------------------------------------
```

**Dual Logging**:

- By default, logs are written to both main log and session log
- Set `ORADBA_SESSION_LOG_ONLY=true` to write only to session log
- Session logs named: `session_YYYYMMDD_HHMMSS_PID.log`

### log

**New in v0.13.1**: Unified logging function with configurable levels.
**Enhanced in v0.14.0**: Added caller information and dual logging support.

Output log message with specified level and timestamp. All messages are written
to stderr with automatic filtering based on configured minimum log level.

**Syntax**: `log <LEVEL> <message...>`

**Parameters**:

- `LEVEL` - Log level: `DEBUG`, `INFO`, `WARN`, or `ERROR` (case-insensitive)
- `message` - Message to log (supports multiple arguments)

**Environment**:

- `ORADBA_LOG_LEVEL` - Minimum log level (default: `INFO`)
  - `DEBUG` - Show all messages including DEBUG
  - `INFO` - Show INFO, WARN, ERROR (default)
  - `WARN` - Show only WARN and ERROR
  - `ERROR` - Show only ERROR messages
- `ORADBA_LOG_FILE` - File logging path (optional)
- `ORADBA_SESSION_LOG` - Session log path (optional, for dual logging)
- `ORADBA_LOG_SHOW_CALLER` - Include caller info (default: `false`)
- `ORADBA_NO_COLOR` - Disable color output (default: `0`)
- `DEBUG` - Legacy support: Setting `DEBUG=1` enables DEBUG level

**Examples**:

```bash
# Basic usage
log INFO "Starting database backup"
log WARN "Database not in archivelog mode"
log ERROR "ORACLE_HOME not found"
log DEBUG "Checking oratab entry"

# Enable debug logging
export ORADBA_LOG_LEVEL=DEBUG
log DEBUG "This will now appear"

# Enable caller information
export ORADBA_LOG_SHOW_CALLER="true"
log INFO "Message with caller info"

# Complete logging setup
init_logging
init_session_log
export ORADBA_SESSION_LOGGING="true"
log INFO "Logged to both main and session logs"

# Legacy DEBUG=1 support
export DEBUG=1
log DEBUG "This also appears"

# Filter to only warnings and errors
export ORADBA_LOG_LEVEL=WARN
log INFO "This is filtered out"
log WARN "This appears"
```

**Output Format**:

```text
# Standard format
[LEVEL] YYYY-MM-DD HH:MM:SS - message

# With caller information (ORADBA_LOG_SHOW_CALLER=true)
[LEVEL] YYYY-MM-DD HH:MM:SS [file:line] - message
```

**Example Output**:

```text
[INFO] 2026-01-05 16:30:45 - Starting database backup
[WARN] 2026-01-05 16:30:46 - Database not in archivelog mode
[ERROR] 2026-01-05 16:30:47 - ORACLE_HOME not found
[DEBUG] 2026-01-05 16:30:48 [script.sh:42] - Checking oratab entry
```

### log_info

**Deprecated**: Use `log INFO <message>` instead.

Output informational message with timestamp.

**Syntax**: `log_info <message>`

**Parameters**:

- `message` - Message to log

**Deprecation Note**: This function is maintained for backward compatibility.
New code should use `log INFO <message>` instead. Enable deprecation warnings
by setting `ORADBA_SHOW_DEPRECATION_WARNINGS=true`.

**Example**:

```bash
# Old syntax (deprecated but still works)
log_info "Starting database backup"

# New syntax (recommended)
log INFO "Starting database backup"
```

**Output**:

```text
[INFO] 2025-12-15 10:30:45 - Starting database backup
```

### log_warn

**Deprecated**: Use `log WARN <message>` instead.

Output warning message to stderr with timestamp.

**Syntax**: `log_warn <message>`

**Parameters**:

- `message` - Warning message

**Deprecation Note**: This function is maintained for backward compatibility. New code should use `log WARN <message>` instead.

**Example**:

```bash
# Old syntax (deprecated but still works)
log_warn "Database not in archivelog mode"

# New syntax (recommended)
log WARN "Database not in archivelog mode"
```

### log_error

**Deprecated**: Use `log ERROR <message>` instead.

Output error message to stderr with timestamp.

**Syntax**: `log_error <message>`

**Parameters**:

- `message` - Error message

**Deprecation Note**: This function is maintained for backward compatibility.
New code should use `log ERROR <message>` instead.

**Example**:

```bash
# Old syntax (deprecated but still works)
log_error "ORACLE_HOME not found"

# New syntax (recommended)
log ERROR "ORACLE_HOME not found"
```

### log_debug

**Deprecated**: Use `log DEBUG <message>` instead.

Output debug message when DEBUG=1 or ORADBA_LOG_LEVEL=DEBUG.

**Syntax**: `log_debug <message>`

**Parameters**:

- `message` - Debug message

**Environment**:

- `DEBUG` - Must be set to 1 to output debug messages
- `ORADBA_LOG_LEVEL` - Set to DEBUG to enable debug output

**Deprecation Note**: This function is maintained for backward compatibility.
New code should use `log DEBUG <message>` instead.

**Example**:

```bash
# Old syntax (deprecated but still works)
export DEBUG=1
log_debug "Checking oratab entry"

# New syntax (recommended)
export ORADBA_LOG_LEVEL=DEBUG
log DEBUG "Checking oratab entry"
```

## Utility Functions

### command_exists

Check if a command is available in PATH.

**Syntax**: `command_exists <command>`

**Parameters**:

- `command` - Command name to check

**Returns**:

- `0` - Command exists
- `1` - Command not found

**Example**:

```bash
if command_exists "sqlplus"; then
    echo "SQL*Plus is available"
fi
```

### get_script_dir

Get the absolute directory path of the calling script.

**Syntax**: `get_script_dir`

**Returns**: Absolute directory path

**Example**:

```bash
SCRIPT_DIR=$(get_script_dir)
echo "Script directory: $SCRIPT_DIR"
```

### validate_directory

Validate directory exists, optionally create it.

**Syntax**: `validate_directory <path> [create]`

**Parameters**:

- `path` - Directory path to validate
- `create` - Optional, "true" to create if missing

**Returns**:

- `0` - Directory exists or was created
- `1` - Directory does not exist or creation failed

**Example**:

```bash
# Check only
if validate_directory "/opt/oracle"; then
    echo "Directory exists"
fi

# Create if missing
validate_directory "/var/log/oradba" "true"
```

## Oracle Functions

### verify_oracle_env

Verify required Oracle environment variables are set.

**Syntax**: `verify_oracle_env`

**Checks**:

- `ORACLE_SID` - Oracle System Identifier
- `ORACLE_HOME` - Oracle installation directory

**Returns**:

- `0` - All required variables are set
- `1` - One or more variables missing

**Example**:

```bash
if verify_oracle_env; then
    echo "Oracle environment is valid"
else
    echo "Missing Oracle environment variables"
    exit 1
fi
```

### get_oracle_version

Get Oracle database version from sqlplus.

**Syntax**: `get_oracle_version`

**Returns**: Version string (e.g., "19.20.0.0")

**Example**:

```bash
VERSION=$(get_oracle_version)
echo "Oracle version: $VERSION"
```

### parse_oratab

Parse oratab file for specific SID.

**Syntax**: `parse_oratab <sid> [oratab_file]`

**Parameters**:

- `sid` - Oracle System Identifier to find
- `oratab_file` - Optional oratab file path (default: /etc/oratab)

**Returns**: Oratab entry line or empty string

**Format**: `SID:ORACLE_HOME:STARTUP_FLAG`

**Example**:

```bash
entry=$(parse_oratab "FREE" "/etc/oratab")
echo "Entry: $entry"

# Extract ORACLE_HOME
ORACLE_HOME=$(echo "$entry" | cut -d: -f2)
```

### export_oracle_base_env

Export common Oracle environment variables.

**Syntax**: `export_oracle_base_env`

**Sets**:

- `PATH` - Adds $ORACLE_HOME/bin
- `LD_LIBRARY_PATH` - Adds $ORACLE_HOME/lib
- `TNS_ADMIN` - Sets to network admin directory
- `NLS_LANG` - Sets default language

**Example**:

```bash
export ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
export_oracle_base_env
```

### execute_db_query

**New in v0.13.2**: Unified SQL*Plus query executor with standardized
configuration and formatting.

Execute SQL queries against the local database with consistent SQL*Plus settings
and automatic error filtering. Eliminates SQL*Plus boilerplate duplication across
database query functions.

**Syntax**: `execute_db_query <query> [format]`

**Parameters**:

- `query` - SQL query to execute (can be multiline)
- `format` - Optional output format (default: `raw`)
  - `raw` - Direct SQL*Plus output with whitespace trimmed
  - `delimited` - Extract first pipe-delimited line

**Returns**:

- `0` - Query executed successfully (with output to stdout)
- `1` - Query failed or no results

**Standard SQL*Plus Configuration**:

The function applies these SQL*Plus settings automatically:

```sql
SET PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL
SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""
SET SERVEROUTPUT OFF TERMOUT ON
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE
```

**Error Filtering**:

Automatically filters out SQL*Plus noise:

- `SP2-*` messages
- `ORA-*` errors  
- `ERROR` lines
- `no rows selected`
- `Connected to:` banners

**Examples**:

```bash
# Simple query with raw format (default)
result=$(execute_db_query "SELECT name FROM v\$database;" "raw")
echo "Database name: $result"

# Pipe-delimited output
result=$(execute_db_query "
    SELECT 
        name || '|' || 
        db_unique_name || '|' || 
        dbid 
    FROM v\$database;" "delimited")
echo "DB info: $result"

# Multi-line query
query="
SELECT 
    i.instance_name,
    i.status,
    i.version
FROM v\$instance i;"

if result=$(execute_db_query "$query" "raw"); then
    echo "$result"
else
    log ERROR "Query failed"
fi

# Using in functions
query_database_name() {
    local query="SELECT name FROM v\$database;"
    execute_db_query "$query" "raw"
}
```

**Important Notes**:

- Must escape dollar signs in SQL: Use `v\$database` not `v$database`
- Use double-quoted strings for queries containing single quotes
- Connects as `/ as sysdba` (requires proper OS authentication)
- Query failures return exit code 1 with empty output

**Migration Example**:

```bash
# Before (old pattern with 40+ lines of boilerplate)
query_database_info() {
    result=$(sqlplus -s / as sysdba 2>/dev/null << 'EOF'
SET PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
...
SELECT d.name FROM v$database d;
EXIT;
EOF
)
    echo "$result" | grep -v "^SP2-\|^ORA-"
}

# After (new pattern with ~10 lines)
query_database_info() {
    local query="SELECT name FROM v\$database;"
    execute_db_query "$query" "raw"
}
```

## Alias Generation Functions

### create_dynamic_alias

**New in v0.13.4**: Unified helper for creating dynamic aliases with automatic expansion handling.

Create shell aliases with optional variable expansion at definition time. Internally
calls `safe_alias()` which respects coexistence mode settings. Automatically handles
shellcheck SC2139 suppression for expanded aliases.

**Syntax**: `create_dynamic_alias <name> <command> [expand]`

**Parameters**:

- `name` - Alias name (required)
- `command` - Alias command/value (required)
- `expand` - "true" to expand variables at definition time, "false" for runtime expansion (default: "false")

**Returns**:

Exit code from `safe_alias`:

- `0` - Alias created successfully
- `1` - Alias skipped (coexistence mode and already exists)
- `2` - Error during creation

**Expansion Behavior**:

- **Non-expanded** (`expand=false`, default): Variables expand when alias is executed

  ```bash
  # Variable ${ORADBA_BIN} expands at runtime
  create_dynamic_alias dbctl '${ORADBA_BIN}/oradba_dbctl.sh'
  ```

- **Expanded** (`expand=true`): Variables expand immediately at definition

  ```bash
  # Variable ${diag_dest} expanded now, value frozen
  create_dynamic_alias cdd "cd ${diag_dest}" "true"
  ```

**Examples**:

```bash
# Service management alias (runtime expansion)
export ORADBA_BIN="/opt/oradba/bin"
create_dynamic_alias dbstart '${ORADBA_BIN}/oradba_dbctl.sh start'
# When executed: ${ORADBA_BIN} expands to current value

# Directory navigation (immediate expansion)
local trace_dir="/u01/app/oracle/diag/rdbms/orcl/ORCL/trace"
create_dynamic_alias cddt "cd ${trace_dir}" "true"
# Alias contains: cd /u01/app/oracle/diag/rdbms/orcl/ORCL/trace

# Complex conditional alias (runtime expansion)
create_dynamic_alias taa 'if [ -f "${ORADBA_SID_ALERTLOG}" ]; then tail -f ${ORADBA_SID_ALERTLOG}; fi'

# Database-specific navigation (immediate expansion)
export ORACLE_SID="PRODDB"
local diag_dest="${ORACLE_BASE}/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}"
create_dynamic_alias cdd "cd ${diag_dest}" "true"
```

**Use Cases**:

**Directory Navigation** (use expanded):

```bash
# SID-specific paths that should be frozen at definition time
create_dynamic_alias cdd "cd ${diag_dest}" "true"
create_dynamic_alias cddt "cd ${trace_dir}" "true"
create_dynamic_alias cdda "cd ${alert_dir}" "true"
create_dynamic_alias cdbase "cd ${ORADBA_BASE}" "true"
```

**Service Management** (use non-expanded):

```bash
# Scripts that should resolve at runtime
create_dynamic_alias dbstart '${ORADBA_BIN}/oradba_dbctl.sh start'
create_dynamic_alias lsnrstart '${ORADBA_BIN}/oradba_lsnrctl.sh start'
create_dynamic_alias orastart '${ORADBA_BIN}/oradba_services.sh start'
```

**Tool Wrappers** (use expanded for config):

```bash
# rlwrap with current configuration
create_dynamic_alias sq "${RLWRAP_COMMAND} ${RLWRAP_OPTS} sqlplus / as sysdba" "true"
```

**Advantages**:

- Eliminates repetitive `safe_alias` calls with shellcheck disables
- Centralizes expansion logic in one place
- Respects coexistence mode automatically
- Clear intent via expand parameter
- Reduces code duplication by ~30-40%

**Migration Example**:

```bash
# Before (repetitive pattern):
# shellcheck disable=SC2139  # Intentional: expand at definition
safe_alias cdd "cd ${diag_dest}"
# shellcheck disable=SC2139  # Intentional: expand at definition
safe_alias cddt "cd ${trace_dir}"
safe_alias dbstart '${ORADBA_BIN}/oradba_dbctl.sh start'

# After (unified helper):
create_dynamic_alias cdd "cd ${diag_dest}" "true"
create_dynamic_alias cddt "cd ${trace_dir}" "true"
create_dynamic_alias dbstart '${ORADBA_BIN}/oradba_dbctl.sh start'
```

## Extension Functions

### get_extension_property

**New in v0.13.3**: Unified property accessor for extension metadata.

Retrieve extension metadata properties with support for fallback values and
configuration overrides. Eliminates metadata access duplication across extension
management functions.

**Syntax**: `get_extension_property <ext_path> <property> [fallback] [check_config]`

**Parameters**:

- `ext_path` - Path to extension directory
- `property` - Property name to retrieve (e.g., "name", "version", "priority", "enabled")
- `fallback` - Optional fallback value if property not found (default: empty)
- `check_config` - Optional "true" to check `ORADBA_EXT_<NAME>_<PROPERTY>` environment variable override

**Returns**:

Property value from (in order of precedence):

1. Environment variable override (if `check_config=true`)
2. Extension `.extension` metadata file
3. Fallback value
4. Empty string

**Metadata File Format**:

Extension metadata is stored in `.extension` file (YAML-like key-value):

```yaml
name: my_extension
version: 1.0.0
description: Custom extension for special features
priority: 30
enabled: true
```

**Examples**:

```bash
# Get extension name with directory fallback
ext_name=$(get_extension_property "/opt/extensions/myext" "name" "myext")

# Get version with "unknown" fallback
ext_version=$(get_extension_property "/opt/extensions/myext" "version" "unknown")

# Get priority with config override support
ext_priority=$(get_extension_property "/opt/extensions/myext" "priority" "50" "true")

# Check if extension is enabled (with config override)
enabled=$(get_extension_property "/opt/extensions/myext" "enabled" "true" "true")
[[ "$enabled" == "true" ]] && echo "Extension enabled"

# Get custom property
custom_value=$(get_extension_property "/opt/extensions/myext" "custom_field")
```

**Configuration Overrides**:

Extension properties can be overridden via environment variables:

```bash
# Override priority
export ORADBA_EXT_MYEXTENSION_PRIORITY="10"

# Override enabled status
export ORADBA_EXT_MYEXTENSION_ENABLED="false"

# Get with config check
priority=$(get_extension_property "/path/to/myextension" "priority" "50" "true")
# Returns: "10" (from environment variable)
```

**Convenience Wrappers**:

These functions use `get_extension_property()` internally:

- `get_extension_name <ext_path>` - Get extension name (fallback: directory name)
- `get_extension_version <ext_path>` - Get version (fallback: "unknown")
- `get_extension_description <ext_path>` - Get description
- `get_extension_priority <ext_path>` - Get priority with config check (fallback: 50)
- `is_extension_enabled <ext_name> <ext_path>` - Check if enabled with config check (fallback: true)

**Example Using Wrappers**:

```bash
# Simpler API for common properties
ext_name=$(get_extension_name "/opt/extensions/myext")
ext_version=$(get_extension_version "/opt/extensions/myext")
ext_priority=$(get_extension_priority "/opt/extensions/myext")

if is_extension_enabled "myext" "/opt/extensions/myext"; then
    echo "Extension $ext_name v$ext_version is enabled (priority: $ext_priority)"
fi
```

## Configuration Functions

### load_config_file

Load a single configuration file with automatic logging and error handling.

**Signature**: `load_config_file <file_path> [required]`

**Parameters**:

- `file_path` - Full path to configuration file (required)
- `required` - "true" for required files (return error if missing), "false" for optional (default: "false")

**Returns**:

- `0` - File loaded successfully or skipped (optional file missing)
- `1` - Required file not found

**Example**:

```bash
# Load required config (fail if missing)
load_config_file "${ORADBA_CONFIG_DIR}/oradba_core.conf" "true" || return 1

# Load optional config (continue if missing)
load_config_file "${ORADBA_CONFIG_DIR}/oradba_customer.conf"

# Load optional with explicit false
load_config_file "${ORADBA_CONFIG_DIR}/oradba_local.conf" "false"
```

**Behavior**:

- Automatically logs debug messages via `log_debug()`
- Logs errors for missing required files via `log_error()`
- Includes centralized `shellcheck source=/dev/null` directive
- Used internally by `load_config()` function

### load_config

Load hierarchical configuration files for OraDBA environment.

**Signature**: `load_config [ORACLE_SID]`

**Parameters**:

- `ORACLE_SID` - Optional Oracle SID for SID-specific configuration

**Configuration Hierarchy** (later files override earlier settings):

1. Core configuration: `oradba_core.conf` (required)
2. Standard configuration: `oradba_standard.conf` (required)
3. Customer configuration: `oradba_customer.conf` (optional)
4. Default SID configuration: `sid._DEFAULT_.conf` (optional)
5. SID-specific configuration: `sid.<ORACLE_SID>.conf` (optional, auto-created if enabled)

**Returns**:

- `0` - Configuration loaded successfully
- `1` - Core configuration not found

**Example**:

```bash
# Load configuration for current SID
load_config

# Load configuration for specific SID
load_config "TESTDB"

# Load and handle errors
if ! load_config "${ORACLE_SID}"; then
    echo "ERROR: Failed to load configuration"
    return 1
fi
```

**Auto-export Behavior**:

- Temporarily enables `set -a` during loading
- All variables in config files are automatically exported
- Restores `set +a` after loading completes

### Configuration Hierarchy

1. System configuration: `$ORADBA_PREFIX/src/etc/oradba.conf`
2. User configuration: `~/.oradba_config`
3. Environment variables
4. Command-line arguments (highest priority)

### Reading Configuration

Configuration files are automatically sourced by scripts.
Variables can be overridden by environment variables.

**Example**:

```bash
# In script
source "${ORADBA_PREFIX}/src/etc/oradba.conf"

# Override with environment variable
export ORATAB_FILE="/custom/path/oratab"

# Source user config if exists
[ -f ~/.oradba_config ] && source ~/.oradba_config
```

## oraenv.sh API

### Usage

Must be sourced, not executed directly.

**Syntax**: `source oraenv.sh [ORACLE_SID] [OPTIONS]`

**Parameters**:

- `ORACLE_SID` - Optional, prompts if not provided
- `--force` - Force environment setup
- `--help` - Display help

**Example**:

```bash
# With SID
source oraenv.sh FREE

# Interactive
source oraenv.sh

# With options
source oraenv.sh TESTDB --force
```

### Environment Variables Set

After sourcing oraenv.sh, the following variables are set:

- `ORACLE_SID` - Oracle System Identifier
- `ORACLE_HOME` - Oracle installation directory  
- `ORACLE_BASE` - Oracle base directory
- `PATH` - Updated with Oracle binaries
- `LD_LIBRARY_PATH` - Updated with Oracle libraries
- `TNS_ADMIN` - TNS configuration directory
- `NLS_LANG` - National Language Support settings

## Information Display Functions

**New in v0.14.0**: Functions for displaying configuration and path information.

### show_config

Display OraDBA configuration hierarchy with load status validation.

**Syntax**: `show_config`

**Output**: Shows 5-level configuration hierarchy with status indicators

**Status Indicators**:

- `[✓ loaded]` - File exists and was successfully sourced
- `[✗ MISSING - REQUIRED]` - Required file not found (error condition)
- `[- not configured]` - Optional file not present

**Configuration Levels**:

1. Core Configuration (`oradba_core.conf`) - Required
2. Standard Configuration (`oradba_standard.conf`) - Required
3. Customer Configuration (`oradba_customer.conf`) - Optional
4. Default SID Configuration (`sid._DEFAULT_.conf`) - Optional
5. SID-Specific Configuration (`sid.${ORACLE_SID}.conf`) - Optional

**Example Output**:

```text
OraDBA Configuration Hierarchy:
================================
1. Core Configuration:
   [✓ loaded] /opt/oracle/local/oradba/etc/oradba_core.conf

2. Standard Configuration:
   [✓ loaded] /opt/oracle/local/oradba/etc/oradba_standard.conf

3. Customer Configuration:
   [- not configured] /opt/oracle/local/oradba/etc/oradba_customer.conf

4. Default SID Configuration:
   [✓ loaded] /opt/oracle/local/oradba/etc/sid._DEFAULT_.conf

5. SID-Specific Configuration (FREE):
   [✓ loaded] /opt/oracle/local/oradba/etc/sid.FREE.conf
```

**Alias**: `cfg`

**Example**:

```bash
# Show configuration hierarchy
show_config

# Using alias
cfg
```

### show_path

Display current PATH with numbered entries for easy reference.

**Syntax**: `show_path`

**Output**: Numbered list of directories in PATH

**Example Output**:

```text
Current PATH:
=============
1. /opt/oracle/local/oradba/bin
2. /u01/app/oracle/product/19c/dbhome_1/bin
3. /usr/local/bin
4. /usr/bin
5. /bin
```

**Alias**: `pth`

**Example**:

```bash
# Show PATH structure
show_path

# Using alias
pth
```

### show_sqlpath

Display current SQLPATH and ORACLE_PATH with numbered entries.

**Syntax**: `show_sqlpath`

**Output**: Numbered lists of directories in SQLPATH and ORACLE_PATH

**Example Output**:

```text
Current SQLPATH:
================
1. /opt/oracle/local/oradba/sql
2. /u01/app/oracle/admin/FREE/scripts
3. /home/oracle/sql

Current ORACLE_PATH:
===================
1. /opt/oracle/local/oradba/sql
```

**Alias**: `sqa`

**Example**:

```bash
# Show SQL paths
show_sqlpath

# Using alias
sqa
```

### configure_sqlpath

Configure SQLPATH environment variable with OraDBA and admin directories.

**Syntax**: `configure_sqlpath`

**Sets**:

- `SQLPATH` - SQL*Plus search path
- `ORACLE_PATH` - Oracle search path

**Behavior**:

- Adds `${ORADBA_SQL}` directory
- Adds `${ORADBA_ORA_ADMIN_SID}/scripts` if exists
- Preserves existing SQLPATH entries
- Removes duplicates
- Sets ORACLE_PATH to ORADBA_SQL

**Example**:

```bash
configure_sqlpath
echo $SQLPATH
# Output: /opt/oradba/sql:/u01/app/oracle/admin/FREE/scripts
```

### add_to_sqlpath

Add directory to SQLPATH if not already present.

**Syntax**: `add_to_sqlpath <directory>`

**Parameters**:

- `directory` - Directory path to add

**Returns**:

- `0` - Directory added or already present
- `1` - Directory does not exist

**Example**:

```bash
# Add custom SQL directory
add_to_sqlpath "/home/oracle/custom_sql"

# Verify
echo $SQLPATH
```

## BasEnv Integration Functions

### detect_basenv

Detect if TVD BasEnv / DB*Star is installed and configure coexistence mode.

**Syntax**: `detect_basenv`

**Detection Methods**:

1. `BE_HOME` environment variable
2. `.BE_HOME` file in user's home directory
3. `.TVDPERL_HOME` file in user's home directory

**Sets**:

- `ORADBA_COEXIST_MODE` - "basenv" if detected, "standalone" otherwise
- `ORADBA_BASENV_DETECTED` - "yes" if detected

**Returns**:

- `0` - BasEnv detected
- `1` - BasEnv not detected

**Example**:

```bash
if detect_basenv; then
    log INFO "Running in BasEnv coexistence mode"
else
    log INFO "Running in standalone mode"
fi
```

### alias_exists

Check if a shell alias already exists.

**Syntax**: `alias_exists <name>`

**Parameters**:

- `name` - Alias name to check

**Returns**:

- `0` - Alias exists
- `1` - Alias does not exist

**Example**:

```bash
if alias_exists "sqlplus"; then
    log WARN "sqlplus alias already defined"
fi
```

### safe_alias

Create alias that respects coexistence mode settings.

**Syntax**: `safe_alias <name> <command>`

**Parameters**:

- `name` - Alias name
- `command` - Alias command/value

**Behavior**:

- In **standalone mode**: Always creates alias
- In **coexistence mode** (BasEnv detected):
  - Skips if `ORADBA_FORCE != 1` and alias exists
  - Creates if alias doesn't exist
  - Creates if `ORADBA_FORCE=1` (override mode)

**Returns**:

- `0` - Alias created successfully
- `1` - Alias skipped (coexistence mode, already exists, not forced)

**Example**:

```bash
# Creates alias unless BasEnv already defined it
safe_alias sql 'sqlplus / as sysdba'

# Force mode (overrides existing)
export ORADBA_FORCE=1
safe_alias sql 'sqlplus / as sysdba'  # Always creates
```

## SID and PDB Management Functions

### generate_sid_lists

Generate arrays of Oracle SIDs from oratab with startup flag filtering.

**Syntax**: `generate_sid_lists`

**Globals Set**:

- `ALL_SIDS` - Array of all SIDs from oratab
- `AUTOSTART_SIDS` - Array of SIDs with 'Y' startup flag
- `SID_COUNT` - Total count of non-dummy SIDs

**Filters Out**:

- Dummy entries (ORACLE_HOME = `/no_such_home` or startup flag 'D')
- Comment lines
- Empty lines

**Example**:

```bash
generate_sid_lists

echo "All SIDs: ${ALL_SIDS[@]}"
echo "Autostart: ${AUTOSTART_SIDS[@]}"
echo "Total: $SID_COUNT"
```

### generate_pdb_aliases

Generate aliases for Pluggable Databases (PDBs).

**Syntax**: `generate_pdb_aliases`

**Generated Aliases**:

- `setpdb<PDBNAME>` - Switch to PDB context
- Example: `setpdbPDB1` switches to PDB1

**Requirements**:

- Database must be open
- CDB architecture (12c+)

**Example**:

```bash
# Generate PDB aliases
generate_pdb_aliases

# Use generated alias
setpdbPDB1  # Switches ORACLE_PDB_SID to PDB1
```

### is_dummy_sid

**Internal**: Check if oratab entry is a dummy entry.

**Syntax**: `is_dummy_sid <oracle_home> <startup_flag>`

**Returns**: 0 if dummy, 1 if real

**Example**:

```bash
if is_dummy_sid "$ORACLE_HOME" "D"; then
    log DEBUG "Skipping dummy entry"
fi
```

## Version Management Functions

### get_oradba_version

Get OraDBA version from VERSION file.

**Syntax**: `get_oradba_version`

**Returns**: Version string or "unknown"

**Example**:

```bash
version=$(get_oradba_version)
echo "OraDBA version: $version"
```

### version_compare

Compare two version strings using semantic versioning.

**Syntax**: `version_compare <version1> <version2>`

**Parameters**:

- `version1` - First version (e.g., "0.14.0")
- `version2` - Second version (e.g., "0.13.5")

**Returns**:

- `0` - version1 = version2
- `1` - version1 > version2
- `2` - version1 < version2

**Example**:

```bash
version_compare "0.14.0" "0.13.5"
result=$?
case $result in
    0) echo "Equal" ;;
    1) echo "0.14.0 is greater" ;;
    2) echo "0.14.0 is less" ;;
esac
```

### version_meets_requirement

Check if version meets minimum requirement.

**Syntax**: `version_meets_requirement <current_version> <required_version>`

**Returns**:

- `0` - Requirement met (current >= required)
- `1` - Requirement not met

**Example**:

```bash
if version_meets_requirement "$(get_oradba_version)" "0.13.0"; then
    log INFO "Version requirement met"
else
    log ERROR "OraDBA 0.13.0+ required"
    exit 1
fi
```

### show_version_info

Display comprehensive version information with formatting.

**Syntax**: `show_version_info [format]`

**Parameters**:

- `format` - Output format: "full" (default), "short", "check"

**Example**:

```bash
# Full version info
show_version_info

# Short version
show_version_info short
```

## Installation Info Functions

### get_install_info

Get installation metadata property value.

**Syntax**: `get_install_info <property>`

**Parameters**:

- `property` - Property name (e.g., "version", "date", "method")

**Returns**: Property value or empty string

**Example**:

```bash
install_date=$(get_install_info "install_date")
install_method=$(get_install_info "install_method")
echo "Installed on $install_date via $install_method"
```

### set_install_info

Set installation metadata property value.

**Syntax**: `set_install_info <property> <value>`

**Example**:

```bash
set_install_info "install_date" "$(date '+%Y-%m-%d %H:%M:%S')"
set_install_info "install_method" "github"
```

### init_install_info

Initialize installation metadata file with default values.

**Syntax**: `init_install_info`

**Creates**: `.install_info` file in `${ORADBA_PREFIX}`

**Example**:

```bash
init_install_info
```

## RMAN Catalog Functions

### load_rman_catalog_connection

Load RMAN catalog connection information from configuration.

**Syntax**: `load_rman_catalog_connection`

**Sets**:

- `RMAN_CATALOG_USER` - Catalog username
- `RMAN_CATALOG_PASSWORD` - Catalog password
- `RMAN_CATALOG_TNS` - TNS connection string

**Configuration File**: `${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf`

**Example**:

```bash
load_rman_catalog_connection
if [[ -n "$RMAN_CATALOG_TNS" ]]; then
    log INFO "Using RMAN catalog: $RMAN_CATALOG_TNS"
fi
```

## SID Configuration Functions

### create_sid_config

Create default SID-specific configuration file from template.

**Syntax**: `create_sid_config <sid>`

**Parameters**:

- `sid` - Oracle SID for configuration

**Creates**: `${ORADBA_CONFIG_DIR}/sid.${sid}.conf`

**Example**:

```bash
create_sid_config "PRODDB"
# Creates: /opt/oradba/etc/sid.PRODDB.conf
```

## Database Functions

Complete documentation for `src/lib/db_functions.sh` module.

### check_database_connection

Check if database connection is available.

**Syntax**: `check_database_connection`

**Returns**:

- `0` - Connection successful
- `1` - Connection failed

**Example**:

```bash
if check_database_connection; then
    log INFO "Database is accessible"
else
    log ERROR "Cannot connect to database"
    exit 1
fi
```

### get_database_open_mode

Get database open mode (READ WRITE, READ ONLY, MOUNTED).

**Syntax**: `get_database_open_mode`

**Returns**: Open mode string or empty on error

**Example**:

```bash
open_mode=$(get_database_open_mode)
echo "Database open mode: $open_mode"
```

### query_instance_info

Query instance information (name, status, version, uptime).

**Syntax**: `query_instance_info`

**Returns**: Pipe-delimited string: `instance_name|status|version|startup_time`

**Example**:

```bash
info=$(query_instance_info)
IFS='|' read -r instance status version startup <<< "$info"
echo "Instance: $instance ($status) - Version: $version"
```

### query_database_info

Query database information (name, unique name, DBID, log mode).

**Syntax**: `query_database_info`

**Returns**: Pipe-delimited string: `name|db_unique_name|dbid|log_mode`

**Example**:

```bash
info=$(query_database_info)
IFS='|' read -r name unique_name dbid log_mode <<< "$info"
echo "Database: $name (DBID: $dbid) - Log Mode: $log_mode"
```

### query_datafile_size

Query datafile size information (total size, used size, free size).

**Syntax**: `query_datafile_size`

**Returns**: Pipe-delimited string: `total_gb|used_gb|free_gb`

**Example**:

```bash
info=$(query_datafile_size)
IFS='|' read -r total used free <<< "$info"
echo "Datafiles: ${used}GB used of ${total}GB (${free}GB free)"
```

### query_memory_usage

Query memory usage (SGA, PGA, total).

**Syntax**: `query_memory_usage`

**Returns**: Pipe-delimited string: `sga_mb|pga_mb|total_mb`

**Example**:

```bash
info=$(query_memory_usage)
IFS='|' read -r sga pga total <<< "$info"
echo "Memory: SGA ${sga}MB + PGA ${pga}MB = ${total}MB"
```

### query_sessions_info

Query session information (total sessions, active sessions, max sessions).

**Syntax**: `query_sessions_info`

**Returns**: Pipe-delimited string: `current|active|maximum`

**Example**:

```bash
info=$(query_sessions_info)
IFS='|' read -r current active maximum <<< "$info"
echo "Sessions: $current total ($active active) - Max: $maximum"
```

### query_pdb_info

Query pluggable database information for CDB.

**Syntax**: `query_pdb_info`

**Returns**: Newline-separated PDB entries: `pdb_name|open_mode|restricted`

**Example**:

```bash
pdb_info=$(query_pdb_info)
while IFS='|' read -r pdb_name open_mode restricted; do
    echo "PDB: $pdb_name - $open_mode $([ "$restricted" = "YES" ] && echo "(RESTRICTED)")"
done <<< "$pdb_info"
```

### format_uptime

Format uptime duration into human-readable string.

**Syntax**: `format_uptime <seconds>`

**Parameters**:

- `seconds` - Uptime in seconds

**Returns**: Formatted string (e.g., "5d 3h 42m")

**Example**:

```bash
uptime_str=$(format_uptime 450000)
echo "Uptime: $uptime_str"  # Output: 5d 5h 0m
```

### show_database_status

Display comprehensive database status with formatting.

**Syntax**: `show_database_status`

**Output**: Multi-line formatted status report including:

- Instance information
- Database information
- Storage usage
- Memory usage
- Session count
- PDB status (if CDB)

**Example**:

```bash
show_database_status
```

**Example Output**:

```text
Database Status:
================
Instance: FREE (OPEN) - Version: 19.0.0.0.0
Uptime: 5d 3h 42m

Database: FREE (DBID: 123456789)
Log Mode: ARCHIVELOG

Storage: 15.2GB used of 50.0GB (34.8GB free)
Memory: SGA 2048MB + PGA 512MB = 2560MB
Sessions: 45 total (12 active) - Max: 300

PDBs:
  PDB$SEED - READ ONLY
  PDB1 - READ WRITE
```

## Alias Helper Functions

### get_diagnostic_dest

Get Oracle diagnostic destination directory.

**Syntax**: `get_diagnostic_dest`

**Returns**: Diagnostic destination path or empty string

**Example**:

```bash
diag_dest=$(get_diagnostic_dest)
echo "Diagnostic destination: $diag_dest"
```

### has_rlwrap

Check if rlwrap utility is available.

**Syntax**: `has_rlwrap`

**Returns**:

- `0` - rlwrap available
- `1` - rlwrap not found

**Example**:

```bash
if has_rlwrap; then
    alias sql='rlwrap sqlplus / as sysdba'
else
    alias sql='sqlplus / as sysdba'
fi
```

### generate_sid_aliases

Generate SID-specific aliases for database management.

**Syntax**: `generate_sid_aliases`

**Generated Aliases** (per SID):

- `set<SID>` - Switch to SID environment
- `sql<SID>` - SQL*Plus for SID
- `rman<SID>` - RMAN for SID
- `lsnr<SID>` - Listener control for SID

**Example**:

```bash
generate_sid_aliases
# Creates: setFREE, sqlFREE, rmanFREE, lsnrFREE, etc.
```

### generate_base_aliases

Generate base OraDBA aliases available in all environments.

**Syntax**: `generate_base_aliases`

**Generated Aliases**:

- `sql` - SQL*Plus as sysdba
- `sqlp` - SQL*Plus (no sysdba)
- `adrci` - ADR Command Interpreter
- `cfg` - Show configuration
- `pth` - Show PATH
- `sqa` - Show SQLPATH
- And many more...

**Example**:

```bash
generate_base_aliases
```

## Extension Management Functions

Complete documentation for `src/lib/extensions.sh` module.

### discover_extensions

Discover all available extensions in extensions directory.

**Syntax**: `discover_extensions`

**Returns**: Space-separated list of extension directories

**Example**:

```bash
extensions=$(discover_extensions)
for ext in $extensions; do
    echo "Found extension: $(basename "$ext")"
done
```

### get_all_extensions

Get array of all discovered extensions with metadata.

**Syntax**: `get_all_extensions`

**Returns**: Array of extension paths in global `ORADBA_EXTENSIONS`

**Example**:

```bash
get_all_extensions
echo "Found ${#ORADBA_EXTENSIONS[@]} extensions"
```

### parse_extension_metadata

Parse extension metadata file (.oradba-extension).

**Syntax**: `parse_extension_metadata <extension_dir>`

**Returns**: Metadata in global associative array `ORADBA_EXT_META`

**Example**:

```bash
parse_extension_metadata "/opt/oradba/extensions/myext"
echo "Name: ${ORADBA_EXT_META[name]}"
echo "Version: ${ORADBA_EXT_META[version]}"
```

### sort_extensions_by_priority

Sort extensions by priority (lower number = higher priority).

**Syntax**: `sort_extensions_by_priority <extension_paths...>`

**Returns**: Sorted space-separated list of extension paths

**Example**:

```bash
sorted=$(sort_extensions_by_priority $extensions)
```

### load_extensions

Load all enabled extensions in priority order.

**Syntax**: `load_extensions`

**Behavior**:

- Discovers all extensions
- Sorts by priority
- Loads enabled extensions
- Executes init hooks

**Example**:

```bash
load_extensions
```

### load_extension

Load a single extension.

**Syntax**: `load_extension <extension_dir>`

**Returns**:

- `0` - Extension loaded successfully
- `1` - Extension load failed

**Example**:

```bash
if load_extension "/opt/oradba/extensions/myext"; then
    log INFO "Extension loaded"
fi
```

### create_extension_alias

Create alias for extension functionality.

**Syntax**: `create_extension_alias <name> <command>`

**Uses**: `safe_alias` internally for coexistence mode support

**Example**:

```bash
create_extension_alias myalias 'echo "Extension command"'
```

### list_extensions

List all discovered extensions with status.

**Syntax**: `list_extensions [format]`

**Parameters**:

- `format` - "short" or "full" (default: "short")

**Example**:

```bash
list_extensions
list_extensions full
```

### show_extension_info

Show detailed information about a specific extension.

**Syntax**: `show_extension_info <extension_name>`

**Example**:

```bash
show_extension_info customer
```

### validate_extension

Validate extension structure and metadata.

**Syntax**: `validate_extension <extension_dir>`

**Returns**:

- `0` - Extension valid
- `1` - Extension invalid

**Example**:

```bash
if validate_extension "/opt/oradba/extensions/myext"; then
    log INFO "Extension structure valid"
fi
```

### extension_provides

Check if extension provides a specific feature.

**Syntax**: `extension_provides <extension_dir> <feature>`

**Returns**:

- `0` - Extension provides feature
- `1` - Extension does not provide feature

**Example**:

```bash
if extension_provides "/opt/oradba/extensions/myext" "monitoring"; then
    log INFO "Extension provides monitoring"
fi
```

## Script Template API

Use the script template from `src/templates/script_template.sh` for new scripts.

### Template Structure

```bash
#!/usr/bin/env bash
# Header (use doc/templates/header.sh)

# Source common library
source "${ORADBA_BASE}/src/lib/common.sh"

# Define functions
usage() { ... }
main() { ... }

# Execute
main "$@"
```

## Return Codes

Standard return codes across all scripts:

- `0` - Success
- `1` - General error
- `2` - Invalid arguments
- `3` - Configuration error
- `4` - Environment error
- `5` - Oracle-specific error

## Best Practices

1. **Always check return codes**:

   ```bash
   if ! command_exists "sqlplus"; then
       log_error "SQL*Plus not found"
       return 1
   fi
   ```

2. **Use logging functions**:

   ```bash
   log_info "Starting operation"
   # ... operation ...
   log_info "Operation completed"
   ```

3. **Validate inputs**:

   ```bash
   if [[ -z "$ORACLE_SID" ]]; then
       log_error "ORACLE_SID not provided"
       return 1
   fi
   ```

4. **Source common library**:

   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   ORADBA_BASE="$(dirname "$(dirname "$SCRIPT_DIR")")"
   source "${ORADBA_BASE}/src/lib/common.sh"
   ```

## See Also

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [README.md](../README.md) - Main documentation
