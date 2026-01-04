# oradba API Documentation

## Common Library Functions

This document describes the public API of the oradba common library (`src/lib/common.sh`).

## Logging Functions

### log

**New in v0.13.1**: Unified logging function with configurable levels.

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
[LEVEL] YYYY-MM-DD HH:MM:SS - message
```

**Example Output**:

```text
[INFO] 2026-01-04 17:30:45 - Starting database backup
[WARN] 2026-01-04 17:30:46 - Database not in archivelog mode
[ERROR] 2026-01-04 17:30:47 - ORACLE_HOME not found
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
