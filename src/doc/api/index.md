# API Reference

Complete function reference for OraDBA libraries and scripts.

## Overview

OraDBA provides a comprehensive set of shell functions organized into logical categories. All functions follow standardized header documentation including purpose, arguments, return codes, and output specifications.

## Categories

### [Core Utilities](common.md)

Core utility functions used throughout OraDBA including logging, PATH management, and Oracle environment utilities.

**Key Functions:**

- `oradba_log` - Unified logging with configurable levels
- `oradba_dedupe_path` - Remove duplicate PATH entries
- `detect_product_type` - Detect Oracle product type from filesystem
- `parse_oratab` - Parse oratab file entries
- `verify_oracle_env` - Verify Oracle environment variables

### [Registry API](registry.md)

Unified interface for Oracle installation discovery and management, combining oratab and oradba_homes.conf.

**Key Functions:**

- `oradba_registry_get_all` - Get all installations
- `oradba_registry_get_by_name` - Get installation by name
- `oradba_registry_get_by_type` - Get installations by type
- `oradba_registry_get_status` - Check service status
- `oradba_registry_validate_entry` - Validate entry

### [Plugin Interface](plugins.md)

Plugin interface for product-specific functionality supporting database, client, datasafe, java, oud, and other Oracle products.

**Required Plugin Functions:**

- `plugin_detect_installation` - Auto-discover installations
- `plugin_validate_home` - Validate ORACLE_HOME
- `plugin_adjust_environment` - Adjust environment variables
- `plugin_check_status` - Check service status
- `plugin_get_metadata` - Extract version and edition
- `plugin_should_show_listener` - Determine if listener applies
- `plugin_discover_instances` - Find instances
- `plugin_get_instance_status` - Get instance status
- `plugin_get_instance_type` - Get instance type
- `plugin_get_pdb_status` - Get PDB status
- `plugin_get_version` - Extract version

### [Environment Management](environment.md)

Environment management libraries for building, parsing, validating, and tracking Oracle environments.

**Includes:**

- `oradba_env_parser.sh` - Configuration parsing and merging
- `oradba_env_builder.sh` - Environment variable building
- `oradba_env_validator.sh` - Environment validation
- `oradba_env_config.sh` - Configuration management
- `oradba_env_status.sh` - Status display
- `oradba_env_changes.sh` - Change detection

### [Database Operations](database.md)

Database-specific operations including query execution, status checks, and database management.

**Key Functions:**

- `execute_db_query` - Execute SQL with simplified interface
- `check_database_status` - Check if database is running
- `check_listener_status` - Check listener status
- `get_database_version` - Get Oracle database version

### [Alias Management](aliases.md)

Alias generation and management for database environments.

**Key Functions:**

- `generate_aliases_for_sid` - Generate database aliases
- `clear_aliases` - Clear OraDBA-generated aliases

### [Extension System](extensions.md)

Extension system for loading and managing OraDBA extensions.

**Key Functions:**

- `load_extension` - Load extension from directory
- `list_extensions` - List available extensions
- `extension_discover` - Discover extension directories

### [Scripts and Commands](scripts.md)

Command-line scripts and tools for OraDBA operations including environment management, service control, and system utilities.

**Includes:**

- `oradba_env.sh` - Environment switching
- `oradba_homes.sh` - Oracle Home management
- `oradba_dbctl.sh` - Database control
- `oradba_services.sh` - Service management
- `oradba_install.sh` - Installation script
- And more...

## Quick Reference

### Common Patterns

#### Check Database Status

```bash
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

status=$(check_database_status "FREE")
if [[ "$status" == "RUNNING" ]]; then
    echo "Database is up"
fi
```

#### List All Installations

```bash
source "${ORADBA_BASE}/lib/oradba_registry.sh"

oradba_registry_get_all | while IFS=: read -r name home type version auto_start desc; do
    echo "Found $type: $name at $home"
done
```

#### Execute Database Query

```bash
source "${ORADBA_BASE}/lib/oradba_db_functions.sh"

query="SELECT name FROM v\$database;"
db_name=$(execute_db_query "$query" "raw")
echo "Database: $db_name"
```

#### Load Plugin and Check Status

```bash
source "${ORADBA_BASE}/lib/plugins/database_plugin.sh"

if plugin_validate_home "$ORACLE_HOME"; then
    status=$(plugin_check_status "$ORACLE_HOME" "$ORACLE_SID")
    echo "Status: $status"
fi
```

## See Also

- [Function Index](function-index.md) - Alphabetical function list
- [Architecture Documentation](../../doc/architecture.md) - System design
- [Development Guide](../../doc/development.md) - Development workflow
- [Function Header Guide](../../doc/function-header-guide.md) - Header standards

---

**API Reference Version:** 1.0  
**Last Generated:** 2026-01-31  
**OraDBA Version:** v0.19.1+
