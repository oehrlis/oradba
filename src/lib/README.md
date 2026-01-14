# Shell Libraries

Shared shell libraries providing common functionality for OraDBA scripts and functions.

## Overview

This directory contains reusable shell libraries that provide core functionality for OraDBA. The libraries are
organized into three categories:

1. **Environment Management Libraries** (oradba_env_*): Modern library-based architecture with Parser, Builder,
Validator, Config Manager, Status Display, and Change Tracker
2. **Core Utility Libraries**: Essential libraries (oradba_common.sh, oradba_db_functions.sh, oradba_aliases.sh) providing logging,
database operations, and alias management - actively used across the system
3. **Extension Framework**: Extensibility support for custom functionality

## Available Libraries

### Environment Management Libraries (oradba_env_*)

| Library                                | Description                                  | Functions   |
|----------------------------------------|----------------------------------------------|-------------|
| [oradba_env_parser.sh]                 | Parse oratab and Oracle Homes configuration  | 8 functions |
| [oradba_env_builder.sh]                | Build Oracle environment variables           | 9 functions |
| [oradba_env_validator.sh]              | Validate Oracle installations                | 7 functions |
| [oradba_env_config.sh]                 | Configuration management and retrieval       | 8 functions |
| [oradba_env_status.sh]                 | Display environment and service status       | 8 functions |
| [oradba_env_changes.sh]                | Track configuration changes and auto-reload  | 7 functions |

**Total Environment Libraries Functions:** 47 functions

### Core Utility Libraries

| Library                                | Description                           | Functions     |
|----------------------------------------|---------------------------------------|---------------|
| [oradba_common.sh](oradba_common.sh)                 | Core utilities and logging            | 50 functions  |
| [oradba_db_functions.sh](oradba_db_functions.sh)     | Database queries and status           | 11 functions  |
| [oradba_aliases.sh](oradba_aliases.sh)               | Dynamic alias generation              | 5 functions   |

**Total Core Utility Functions:** 66 functions

### Extension Framework

| Library                            | Description                       | Functions     |
|------------------------------------|-----------------------------------|---------------|
| [extensions.sh](extensions.sh)     | Extension loading and management  | 20 functions  |

**Total Library Functions:** 133 functions across 10 libraries (10,586 lines of code)

## Usage

### Environment Library Usage

The environment management libraries (oradba_env_*) are automatically loaded by `oradba_env.sh`:

```bash
# In oradba_env.sh
source "${ORADBA_BASE}/lib/oradba_env_parser.sh"
source "${ORADBA_BASE}/lib/oradba_env_builder.sh"
source "${ORADBA_BASE}/lib/oradba_env_validator.sh"
source "${ORADBA_BASE}/lib/oradba_env_config.sh"
source "${ORADBA_BASE}/lib/oradba_env_status.sh"
source "${ORADBA_BASE}/lib/oradba_env_changes.sh"

# Parser loads and parses configuration
oradba_parse_oratab
oradba_parse_homes

# Builder constructs environment
oradba_build_environment "$ORACLE_SID"

# Validator verifies installation
oradba_validate_oracle_home "$ORACLE_HOME"

# Config manager provides access
db_name=$(oradba_get_config "database.name")

# Status displays current state
oradba_show_environment

# Change tracker monitors config files
oradba_auto_reload_on_change
```

### Core Utility Library Usage

Source core utility libraries at the beginning of your scripts:

```bash
#!/usr/bin/env bash
# Your script

# Source required libraries
source "${ORADBA_BASE}/lib/oradba_common.sh"
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

# Use library functions (v0.13.1+ unified logging)
oradba_log INFO "Starting script..."
db_status=$(get_db_status)
oradba_log INFO "Database status: ${db_status}"

# Deprecated logging functions still work (backward compatible)
log_info "Starting script..."  # Deprecated v0.13.1 - use oradba_log INFO
log_info "Database status: ${db_status}"
```

### In Configuration Files

Libraries are automatically sourced by OraDBA configuration:

```bash
# In oradba_core.conf
source "${ORADBA_BASE}/lib/oradba_common.sh"
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"
source "${ORADBA_BASE}/lib/oradba_aliases.sh"
```

## Library Functions

### Environment Management Library Functions

#### oradba_env_parser.sh - Configuration Parser

**Oratab Parsing:**

- `oradba_parse_oratab` - Parse /etc/oratab and build SID-to-HOME mappings
- `oradba_find_sid` - Find ORACLE_HOME for given SID
- `oradba_list_all_sids` - List all SIDs from oratab

**Oracle Homes Parsing:**

- `oradba_parse_homes` - Parse oradba_homes.conf for Oracle Home definitions
- `oradba_find_home` - Find Oracle Home by name or alias
- `oradba_get_home_metadata` - Get metadata for Oracle Home
- `oradba_list_all_homes` - List all registered Oracle Homes
- `oradba_get_product_type` - Get product type from Oracle Home

#### oradba_env_builder.sh - Environment Builder

**Environment Construction:**

- `oradba_build_environment` - Main entry point: build complete Oracle environment
- `oradba_derive_oracle_base` - Derive ORACLE_BASE from ORACLE_HOME or conventions
- `oradba_construct_path` - Build PATH with Oracle binaries
- `oradba_construct_ld_library_path` - Build LD_LIBRARY_PATH with Oracle libraries
- `oradba_set_oracle_sid` - Set ORACLE_SID and related variables
- `oradba_set_tns_admin` - Set TNS_ADMIN based on conventions
- `oradba_set_nls_settings` - Set NLS_LANG and locale settings
- `oradba_export_environment` - Export all Oracle environment variables
- `oradba_clean_environment` - Clean up environment before rebuild

#### oradba_env_validator.sh - Environment Validator

**Validation Functions:**

- `oradba_validate_oracle_home` - Validate ORACLE_HOME directory structure
- `oradba_validate_oracle_base` - Validate ORACLE_BASE directory
- `oradba_validate_sid` - Validate SID exists in oratab
- `oradba_check_oracle_executable` - Check Oracle binaries exist and are executable
- `oradba_detect_product_type` - Detect Oracle product type (DB, Grid, Client)
- `oradba_detect_version` - Detect Oracle version from inventory or binaries
- `oradba_verify_complete_environment` - Comprehensive environment verification

#### oradba_env_config.sh - Configuration Manager

**Configuration Access:**

- `oradba_get_config` - Get configuration value by key (supports dot notation)
- `oradba_set_config` - Set configuration value
- `oradba_load_config_file` - Load single configuration file
- `oradba_merge_configs` - Merge multiple configuration sources
- `oradba_resolve_variables` - Resolve variable references in configuration
- `oradba_show_config` - Display current configuration
- `oradba_save_config` - Save configuration to file
- `oradba_reset_config` - Reset configuration to defaults

#### oradba_env_status.sh - Status Display

**Status Functions:**

- `oradba_show_environment` - Display complete Oracle environment
- `oradba_show_config_sources` - Show which config files were loaded
- `oradba_check_db_status` - Check if database is running
- `oradba_check_asm_status` - Check ASM instance status
- `oradba_check_listener_status` - Check listener status
- `oradba_check_process_running` - Check if Oracle process is running
- `oradba_check_datasafe_status` - Check Oracle Data Safe status
- `oradba_check_oud_status` - Check Oracle Unified Directory status

#### oradba_env_changes.sh - Change Tracker

**Change Tracking:**

- `oradba_get_file_signature` - Get file checksum/timestamp
- `oradba_store_file_signature` - Store file signature for comparison
- `oradba_check_file_changed` - Check if file changed since last signature
- `oradba_check_config_changes` - Check if any config files changed
- `oradba_init_change_tracking` - Initialize change tracking system
- `oradba_clear_change_tracking` - Clear stored signatures
- `oradba_auto_reload_on_change` - Auto-reload environment on config change

### Core Utility Library Functions

#### oradba_common.sh - Core Utilities

**Logging Functions (v0.13.1+):**

- `oradba_log` - Unified logging function with level filtering (DEBUG|INFO|WARN|ERROR)
- `init_logging` - Initialize logging system with log file and level
- `init_session_log` - Create session-specific log file
- `log_info` - Information messages (deprecated, use `oradba_log INFO`)
- `log_warn` - Warning messages (deprecated, use `oradba_log WARN`)
- `log_error` - Error messages (deprecated, use `oradba_log ERROR`)
- `log_debug` - Debug messages (deprecated, use `oradba_log DEBUG`)

**oratab Management:**

- `get_oratab_path` - Get path to oratab file (OS-specific)
- `parse_oratab` - Parse oratab file entries
- `is_dummy_sid` - Check if SID is a dummy entry
- `generate_sid_lists` - Generate lists of database and non-database SIDs

**Oracle Homes Management:**

- `get_oracle_homes_path` - Get path to oradba_homes.conf
- `resolve_oracle_home_name` - Resolve Oracle Home name from alias or path
- `parse_oracle_home` - Parse Oracle Home configuration entry
- `list_oracle_homes` - List all registered Oracle Homes
- `get_oracle_home_path` - Get path for Oracle Home by name
- `get_oracle_home_alias` - Get alias for Oracle Home
- `get_oracle_home_type` - Get type (db, grid, client) for Oracle Home
- `detect_product_type` - Auto-detect Oracle product type
- `detect_oracle_version` - Auto-detect Oracle version
- `derive_oracle_base` - Derive ORACLE_BASE from conventions
- `set_oracle_home_environment` - Set environment for Oracle Home
- `is_oracle_home` - Check if name is an Oracle Home (vs SID)

**Environment Functions:**

- `verify_oracle_env` - Verify Oracle environment variables are set
- `get_oracle_version` - Get Oracle version string
- `export_oracle_base_env` - Export common Oracle environment variables
- `validate_directory` - Validate and optionally create directory
- `command_exists` - Check if command is in PATH
- `alias_exists` - Check if alias is defined
- `safe_alias` - Create alias respecting coexistence mode

**Configuration Management:**

- `load_config_file` - Load single configuration file with error handling
- `load_config` - Load hierarchical configuration files (6-level system)
- `create_sid_config` - Create SID-specific configuration file
- `configure_sqlpath` - Configure SQLPATH for SQL*Plus
- `add_to_sqlpath` - Add directory to SQLPATH
- `show_sqlpath` - Display current SQLPATH
- `show_path` - Display current PATH with formatting
- `show_config` - Display current OraDBA configuration

**Versioning and Installation:**

- `get_oradba_version` - Get OraDBA version from VERSION file
- `version_compare` - Compare two semantic versions
- `version_meets_requirement` - Check if version meets minimum
- `get_install_info` - Get installation metadata by key
- `set_install_info` - Set installation metadata
- `init_install_info` - Initialize installation info file

**Alias Generation:**

- `generate_oracle_home_aliases` - Generate Oracle Home navigation aliases
- `generate_pdb_aliases` - Generate PDB-specific aliases
- `load_rman_catalog_connection` - Load RMAN catalog connection string

**Database Query Functions (v0.13.2+):**

- `execute_db_query` - Execute SQL queries with standardized configuration
- `get_script_dir` - Get directory of running script

#### oradba_db_functions.sh - Database Operations

**Database Connection:**

- `check_database_connection` - Check if database is accessible
- `get_database_open_mode` - Get current database open mode

**Query Functions (v0.13.2+):**

- `query_instance_info` - Query v$instance and v$parameter
- `query_database_info` - Query v$database information
- `query_datafile_size` - Query total datafile size in GB
- `query_memory_usage` - Query SGA/PGA memory usage
- `query_sessions_info` - Query session information
- `query_pdb_info` - Query pluggable database information

**Display Functions:**

- `show_oracle_home_status` - Display Oracle Home environment info
- `show_database_status` - Display comprehensive database status
- `format_uptime` - Format uptime from startup timestamp

**Note**: All query functions use `execute_db_query()` from oradba_common.sh (v0.13.2+)

#### oradba_aliases.sh - Alias Generation

**Alias Functions:**

- `create_dynamic_alias` - Create dynamic alias with expansion handling
- `generate_sid_aliases` - Generate SID-specific aliases (taa, vaa, via, cdd, cddt, cdda)
- `generate_base_aliases` - Generate OraDBA base directory alias (cdbase)
- `has_rlwrap` - Check if rlwrap command is available
- `get_diagnostic_dest` - Get diagnostic_dest from database or conventions

### Extension Framework

#### extensions.sh - Extension Management

- 20 functions for loading, validating, and managing OraDBA extensions
- See [Extension System Documentation](../../doc/extension-system.md) for details

## Configuration

Libraries respect these environment variables:

### Core Variables

- `ORADBA_BASE` - Installation directory
- `ORADBA_LOG_LEVEL` - Logging verbosity (INFO, WARN, ERROR, DEBUG)
- `ORADBA_LOG_FILE` - Log file location

### Oracle Variables

- `ORACLE_SID` - Current Oracle SID
- `ORACLE_HOME` - Oracle installation directory
- `ORACLE_BASE` - Oracle base directory
- `TNS_ADMIN` - TNS configuration directory

### Environment Library Variables

- `ORADBA_PARSER_DEBUG` - Enable parser debug output
- `ORADBA_VALIDATOR_STRICT` - Enable strict validation mode
- `ORADBA_CONFIG_RELOAD` - Auto-reload on configuration changes

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
