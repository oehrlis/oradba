# Shell Libraries

Shared shell libraries providing common functionality for OraDBA scripts and functions.

## Overview

This directory contains reusable shell libraries that provide core functionality
for OraDBA. These libraries are sourced by executable scripts and configuration
files to provide logging, database operations, alias generation, and utility functions.

## Available Libraries

| Library                            | Description                 | Functions     |
|------------------------------------|-----------------------------|---------------|
| [common.sh](common.sh)             | Core utilities and logging  | ~30 functions |
| [db_functions.sh](db_functions.sh) | Database queries and status | ~15 functions |
| [aliases.sh](aliases.sh)           | Dynamic alias generation    | ~10 functions |

**Total Libraries:** 3

## Usage

### In Scripts

Source libraries at the beginning of your scripts:

```bash
#!/usr/bin/env bash
# Your script

# Source required libraries
source "${ORADBA_BASE}/lib/common.sh"
source "${ORADBA_BASE}/lib/db_functions.sh"

# Use library functions (v0.13.1+ unified logging)
log INFO "Starting script..."
db_status=$(get_db_status)
log INFO "Database status: ${db_status}"

# Legacy logging functions still work (backward compatible)
log_info "Starting script..."  # Still supported but deprecated
log_info "Database status: ${db_status}"
```

### In Configuration Files

Libraries are automatically sourced by OraDBA configuration:

```bash
# In oradba_core.conf
source "${ORADBA_BASE}/lib/common.sh"
source "${ORADBA_BASE}/lib/db_functions.sh"
source "${ORADBA_BASE}/lib/aliases.sh"
```

## Library Functions

### common.sh - Core Utilities

**Logging Functions:**

**New in v0.13.1**: Unified logging with configurable levels

- `log` - Unified logging function with level filtering (DEBUG|INFO|WARN|ERROR)
- `log_info` - Information messages (deprecated, use `log INFO`)
- `log_warn` - Warning messages (deprecated, use `log WARN`)
- `log_error` - Error messages (deprecated, use `log ERROR`)
- `log_debug` - Debug messages (deprecated, use `log DEBUG`)
- `log_msg` - Generic logging with custom level (deprecated)

**oratab Management:**

- `parse_oratab` - Parse oratab file entries
- `list_oracle_sids` - List all Oracle SIDs from oratab
- `get_oracle_home` - Get ORACLE_HOME for specific SID
- `validate_sid` - Check if SID exists in oratab
- `find_sid_case_insensitive` - Case-insensitive SID matching

**Environment Functions:**

- `validate_oracle_env` - Check Oracle environment variables
- `check_oracle_home` - Verify ORACLE_HOME validity
- `set_oracle_env` - Set Oracle environment for SID
- `cleanup_path` - Remove duplicate PATH entries

**Configuration:**

- `load_config` - Load configuration file
- `get_config_value` - Get configuration parameter value
- `set_sqlpath` - Configure SQL*Plus SQLPATH

**Database Query Functions:**

**New in v0.13.2**: Unified SQL*Plus query executor

- `execute_db_query` - Execute SQL queries with standardized configuration
  - Parameters: `<query>` `[format]` (format: raw|delimited)
  - Returns: Query results or error code
  - Eliminates SQL*Plus boilerplate duplication

**Utility Functions:**

- `is_sourced` - Check if script is being sourced
- `command_exists` - Check if command is available
- `get_timestamp` - Generate timestamp for logging

### db_functions.sh - Database Operations

**Status Functions:**

- `get_db_status` - Get database open mode
- `is_db_running` - Check if database is running
- `get_instance_name` - Get instance name
- `get_db_version` - Get database version
- `get_db_name` - Get database name

**Note**: These functions use `execute_db_query()` as of v0.13.2

- `query_instance_info` - Get instance information (name, status, version, memory)
- `query_database_info` - Get database information (name, DBID, log mode, role)
- `query_datafile_size` - Get total datafile size in GB
- `query_memory_usage` - Get SGA/PGA memory usage
- `query_sessions_info` - Get session count statistics
- `query_pdb_info` - Get PDB information (CDB only)
- `sql_query` - Execute SQL query and return result (deprecated - use execute_db_query)
- `sql_query_silent` - Execute SQL without output (deprecated)
- `is_cdb` - Check if database is a container database
- `get_pdb_list` - List all PDBs in CDB
- `get_pdb_status` - Get PDB open mode
- `validate_pdb` - Check if PDB exists

**Query Functions:**

- `sql_query` - Execute SQL query and return result
- `sql_query_silent` - Execute SQL without output
- `get_db_parameter` - Get database parameter value
- `get_session_count` - Count active sessions

**Monitoring:**

- `get_memory_usage` - Get SGA/PGA usage
- `get_tablespace_usage` - Get tablespace usage
- `check_alert_log` - Check for errors in alert log

### aliases.sh - Alias Generation

**Alias Functions:**

- `generate_standard_aliases` - Create standard OraDBA aliases
- `generate_pdb_aliases` - Create PDB-specific aliases
- `generate_sid_aliases` - Create SID-specific aliases
- `cleanup_aliases` - Remove old dynamic aliases
- `list_oradba_aliases` - Show all OraDBA aliases

**Helper Functions:**

- `create_alias` - Create single alias safely
- `alias_exists` - Check if alias already exists
- `get_alias_definition` - Get current alias definition

## Configuration

Libraries respect these environment variables:

- `ORADBA_BASE` - Installation directory
- `ORADBA_LOG_LEVEL` - Logging verbosity (INFO, WARN, ERROR, DEBUG)
- `ORADBA_LOG_FILE` - Log file location
- `ORACLE_SID` - Current Oracle SID
- `ORACLE_HOME` - Oracle installation directory

## Error Handling

All library functions follow consistent error handling:

```bash
# Return codes
# 0 - Success
# 1 - General error
# 2 - Invalid arguments
# 3 - Database not accessible
# 4 - Configuration error

# Example usage
if get_db_status >/dev/null 2>&1; then
    log_info "Database is accessible"
else
    log_error "Cannot connect to database"
    return 3
fi
```

## Documentation

- **[API Reference](../../doc/api.md)** - Complete function API documentation
- **[Development Guide](../../doc/development.md)** - Coding standards and guidelines
- **[Architecture](../../doc/architecture.md)** - System design and components

## Development

### Adding New Functions

1. **Choose appropriate library** based on function purpose
2. **Follow naming conventions** (verb_noun pattern)
3. **Document thoroughly** with header comments
4. **Include usage examples** in comments
5. **Write tests** in `tests/` directory
6. **Update this README** with function listing

### Function Template

```bash
# Function: get_something
# Purpose: Brief description of what function does
# Arguments:
#   $1 - First argument description
#   $2 - Second argument description (optional)
# Returns:
#   0 - Success
#   1 - Error
# Output:
#   Description of what function outputs
# Example:
#   result=$(get_something "arg1" "arg2")
#   echo "Result: ${result}"
get_something() {
    local arg1="${1}"
    local arg2="${2:-default_value}"
    
    # Function implementation
    log_debug "Processing: ${arg1}"
    
    # Return result
    echo "result"
    return 0
}
```

### Testing

Test library functions using BATS:

```bash
# Run library tests
bats tests/test_common.bats
bats tests/test_db_functions.bats

# Run specific test
bats tests/test_common.bats --filter "log_info"
```

See [development.md](../../doc/development.md) for complete testing guidelines.
