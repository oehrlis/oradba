# oradba API Documentation

## Common Library Functions

This document describes the public API of the oradba common library (`srv/lib/common.sh`).

## Logging Functions

### log_info

Output informational message with timestamp.

**Syntax**: `log_info <message>`

**Parameters**:

- `message` - Message to log

**Example**:

```bash
log_info "Starting database backup"
```

**Output**:

```text
[INFO] 2025-12-15 10:30:45 - Starting database backup
```

### log_warn

Output warning message to stderr with timestamp.

**Syntax**: `log_warn <message>`

**Parameters**:

- `message` - Warning message

**Example**:

```bash
log_warn "Database not in archivelog mode"
```

### log_error

Output error message to stderr with timestamp.

**Syntax**: `log_error <message>`

**Parameters**:

- `message` - Error message

**Example**:

```bash
log_error "ORACLE_HOME not found"
```

### log_debug

Output debug message when DEBUG=1.

**Syntax**: `log_debug <message>`

**Parameters**:

- `message` - Debug message

**Environment**:

- `DEBUG` - Must be set to 1 to output debug messages

**Example**:

```bash
export DEBUG=1
log_debug "Checking oratab entry"
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
entry=$(parse_oratab "ORCL" "/etc/oratab")
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

## Configuration Functions

### Configuration Hierarchy

1. System configuration: `$ORADBA_PREFIX/srv/etc/oradba.conf`
2. User configuration: `~/.oradba_config`
3. Environment variables
4. Command-line arguments (highest priority)

### Reading Configuration

Configuration files are automatically sourced by scripts.
Variables can be overridden by environment variables.

**Example**:

```bash
# In script
source "${ORADBA_PREFIX}/srv/etc/oradba.conf"

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
source oraenv.sh ORCL

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

Use the script template from `srv/templates/script_template.sh` for new scripts.

### Template Structure

```bash
#!/usr/bin/env bash
# Header (use doc/templates/header.sh)

# Source common library
source "${ORADBA_BASE}/srv/lib/common.sh"

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
   source "${ORADBA_BASE}/srv/lib/common.sh"
   ```

## See Also

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [README.md](../README.md) - Main documentation
