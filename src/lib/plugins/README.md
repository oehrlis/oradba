# OraDBA Plugin System

This directory contains plugin implementations for different Oracle products.

## Plugin Interface v1.0.0

Each plugin must implement 11 required functions following the plugin standards.

**📖 For Plugin Development, see:**

- **[Plugin Standards](../../../doc/plugin-standards.md)** - Official specification
- **[Plugin Development Guide](../../../doc/plugin-development.md)** - Step-by-step guide
- **[Plugin Interface Template](plugin_interface.sh)** - Base implementation

## Current Plugins

| Plugin | Product | Status |
|--------|---------|--------|
| `database_plugin.sh` | Oracle Database (RDBMS) | ✅ Production |
| `datasafe_plugin.sh` | Data Safe On-Premises Connector | ✅ Production |
| `client_plugin.sh` | Oracle Full Client | ✅ Production |
| `iclient_plugin.sh` | Oracle Instant Client | ✅ Production |
| `oud_plugin.sh` | Oracle Unified Directory | ✅ Production |
| `java_plugin.sh` | Oracle Java (JDK/JRE) | ✅ Production |
| `weblogic_plugin.sh` | WebLogic Server | 🚧 Stub |
| `oms_plugin.sh` | Enterprise Manager OMS | 🚧 Stub |
| `emagent_plugin.sh` | Enterprise Manager Agent | 🚧 Stub |

## Quick Reference

### Required Functions (11)

1. `plugin_detect_installation()` - Auto-discover installations
2. `plugin_validate_home()` - Validate ORACLE_HOME
3. `plugin_adjust_environment()` - Adjust path for product
4. `plugin_check_status()` - Check service status
5. `plugin_get_metadata()` - Get product metadata
6. `plugin_should_show_listener()` - Show listener status?
7. `plugin_discover_instances()` - Find instances
8. `plugin_supports_aliases()` - Support SID aliases?
9. `plugin_build_path()` - Build PATH components
10. `plugin_build_lib_path()` - Build LD_LIBRARY_PATH components
11. `plugin_get_config_section()` - Get config section name

### Exit Code Contract

- **0** = Success (operation completed, data valid)
- **1** = Not Applicable (expected failure, not an error)
- **2** = Unavailable (true error, command failed)

### Key Rules

✅ **DO:**

- Return clean data on stdout (no sentinel strings)
- Use exit codes to signal status
- Assume ORACLE_HOME and LD_LIBRARY_PATH in subshell
- Document all functions with headers

❌ **DON'T:**

- Echo "ERR", "unknown", "N/A" (use exit codes instead)
- Modify global environment (except PATH/LD_LIBRARY_PATH)
- Assume full parent environment (subshell isolation)
- Skip error handling

## Development Workflow

1. Read **[Plugin Standards](../../../doc/plugin-standards.md)** first
2. Copy **[Plugin Interface Template](plugin_interface.sh)**
3. Implement 11 required functions
4. Follow **[Plugin Development Guide](../../../doc/plugin-development.md)**
5. Add tests in `tests/test_<product>_plugin.bats`
6. Update this README with new plugin

## Support

- Issues: <https://github.com/oehrlis/oradba/issues>
- Examples: See existing plugins (database, datasafe, etc.)
- Architecture: `doc/architecture.md`
