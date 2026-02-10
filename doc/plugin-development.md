# Plugin Development Guide

This guide provides comprehensive instructions for developing plugins for the
OraDBA plugin system (v1.0.0+).

> **📖 Related Documentation:**
>
> - [Plugin Standards](plugin-standards.md) - **Start here** for interface
>   specification and return value conventions
> - [Plugin Interface](../src/lib/plugins/plugin_interface.sh) - Template implementation
> - [Architecture](architecture.md) - System architecture

## Overview

OraDBA's plugin system enables product-specific behavior for different Oracle
products. Each plugin implements a standardized interface that allows OraDBA to:

- Auto-detect installations
- Validate Oracle Homes
- Build environment variables (PATH, LD_LIBRARY_PATH, CLASSPATH as needed)
- Check service status (including listener when applicable)
- Discover and enumerate instances/domains
- Get product metadata

**Before developing a plugin, read [plugin-standards.md](plugin-standards.md)**
which formalizes:

- Universal core functions and category-specific requirements
- Return value standards (exit codes + stdout)
- Optional function patterns
- Testing requirements
- Best practices and anti-patterns

## Plugin Architecture

### Design Principles

1. **Separation of Concerns**: Each product type has its own plugin
2. **Standardized Interface**: All plugins implement the universal core functions,
   plus category-specific functions where applicable
3. **Extensibility**: Easy to add support for new Oracle products
4. **Isolation**: Plugins don't interfere with each other
5. **Backward Compatibility**: Plugin interface versioning ensures compatibility

### Plugin System Components

```text
OraDBA Core
    ↓
Plugin Loader (oradba_env_builder.sh)
    ↓
Plugin Interface (plugin_interface.sh)
    ↓
Product Plugins
    ├─ database_plugin.sh       (Oracle Database)
    ├─ datasafe_plugin.sh       (Data Safe Connectors)
    ├─ client_plugin.sh         (Full Oracle Client)
    ├─ iclient_plugin.sh        (Instant Client)
    ├─ oud_plugin.sh            (Oracle Unified Directory)
    └─ java_plugin.sh           (Oracle Java/JDK)
```

## Plugin Interface v1.0.0

Each plugin must implement the **13 universal core functions** and
**3 metadata variables**. Plugins for specific product categories must also implement
**category-specific mandatory functions** (e.g., 2 listener functions for database products).

> **📖 Complete Specification:** See [plugin-standards.md](plugin-standards.md) for:
>
> - Detailed function descriptions
> - Exit code standards (0=success, 1=expected failure, 2=unavailable)
> - Return value conventions (no sentinel strings!)
> - Function templates for all core and category-specific functions
> - Extension patterns for optional functions

### Function Count Structure

The plugin interface uses a tiered structure:

- **13 Universal Core Functions** - Required for ALL plugins
- **2 Category-Specific Functions** - Required for database/listener-based products
- **N Optional Functions** - Added as needed (common optional + product-specific extensions)

**Total mandatory functions:**

- Non-database products (client, iclient, java, oud): **13 functions**
- Database/listener products (database, datasafe): **15 functions** (13 + 2)

### Required Metadata

```bash
# Plugin metadata (REQUIRED)
export plugin_name="myproduct"              # Product type identifier
export plugin_version="1.0.0"               # Plugin version (semantic versioning)
export plugin_interface_version="1.0.0"     # Interface version (optional but recommended)
export plugin_description="My Oracle Product plugin"  # Human-readable description
```

### Universal Core Functions (13 Required for ALL Plugins)

These functions MUST be implemented by every plugin:

| #  | Function                     | Purpose                                                   | Exit Codes                          |
|----|------------------------------|-----------------------------------------------------------|-------------------------------------|
| 1  | `plugin_detect_installation` | Auto-discover installations                               | 0=success                           |
| 2  | `plugin_validate_home`       | Validate installation path (ORACLE_HOME/ORACLE_BASE_HOME) | 0=valid, 1=invalid                  |
| 3  | `plugin_adjust_environment`  | Adjust ORACLE_HOME if needed                              | 0=success                           |
| 4  | `plugin_build_base_path`     | Resolve ORACLE_BASE_HOME vs ORACLE_HOME                   | 0=success                           |
| 5  | `plugin_build_env`           | Build environment variables (product/instance)            | 0=success, 1=n/a, 2=unavailable     |
| 6  | `plugin_check_status`        | Check service/instance status                             | 0=running, 1=stopped, 2=unavailable |
| 7  | `plugin_get_metadata`        | Get installation metadata                                 | 0=success                           |
| 8  | `plugin_discover_instances`  | Discover instances/domains for this home                  | 0=success                           |
| 9  | `plugin_get_instance_list`   | Enumerate instances/domains (multi-instance only)         | 0=success                           |
| 10 | `plugin_supports_aliases`    | Supports SID-like aliases?                                | 0=yes, 1=no                         |
| 11 | `plugin_build_bin_path`      | Get PATH components                                       | 0=success                           |
| 12 | `plugin_build_lib_path`      | Get LD_LIBRARY_PATH components                            | 0=success                           |
| 13 | `plugin_get_config_section`  | Get config section name                                   | 0=success                           |

### Category-Specific Mandatory Functions (2 for Database/Listener Products)

These functions MUST be implemented by database and listener-based products:

| Function                       | Applies To           | Purpose                                   | Exit Codes                          |
|--------------------------------|----------------------|-------------------------------------------|-------------------------------------|
| `plugin_should_show_listener`  | database, datasafe   | Whether to render listener entries        | 0=yes, 1=no                         |
| `plugin_check_listener_status` | database, datasafe   | Listener status per Oracle Home           | 0=running, 1=stopped, 2=unavailable |

**Notes:**

- These are **mandatory** for database and datasafe plugins
- Other plugins should implement them but return appropriate defaults (see templates below)

> **📖 Detailed Documentation:** See [plugin-standards.md](plugin-standards.md) for:
>
> - Complete function specifications
> - Function templates (copy-paste ready)
> - Return value standards
> - Usage examples

#### 1. plugin_detect_installation

Auto-detect installations of this product type.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect installations of this product type
# Args....: None
# Returns.: 0 on success
# Output..: List of installation paths (one per line)
# Notes...: Used for auto-discovery when no registry files exist
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    # Implementation: scan common locations for product
    # Example: find /opt/oracle -name "product_binary"
}
```

**Examples**:

- Database: Scan for running `pmon` processes
- DataSafe: Check for `cmctl` binary in typical locations
- Client: Look for `sqlplus` without `rdbms` directory

#### 2. plugin_validate_home

Validate that a path is a valid ORACLE_HOME for this product.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_validate_home
# Purpose.: Validate that path is a valid ORACLE_HOME for this product
# Args....: $1 - Path to validate
# Returns.: 0 if valid, 1 if invalid
# Output..: None
# Notes...: Checks for product-specific files/directories
# ------------------------------------------------------------------------------
plugin_validate_home() {
    local home_path="$1"
    
    # Check for product-specific markers
    # Example: [[ -x "${home_path}/bin/sqlplus" ]]
}
```

**Validation Strategies**:

- Check for specific binaries (e.g., `sqlplus`, `cmctl`)
- Verify directory structure (e.g., `rdbms/`, `network/`)
- Check for configuration files

#### 3. plugin_adjust_environment

Adjust ORACLE_HOME path for product-specific requirements.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for product-specific requirements
# Args....: $1 - Original ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME path
# Notes...: Example: DataSafe appends /oracle_cman_home
#           Most products return the path unchanged
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    
    # Most products return unchanged
    echo "${home_path}"
    
    # DataSafe example:
    # echo "${home_path}/oracle_cman_home"
}
```

#### 4. plugin_build_base_path

Resolve the actual installation base (ORACLE_BASE_HOME-aware).

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_base_path
# Purpose.: Resolve the actual installation base (ORACLE_BASE_HOME-aware)
# Args....: $1 - Input ORACLE_HOME or ORACLE_BASE_HOME
# Returns.: 0 on success
# Output..: Normalized base path
# Notes...: Use when ORACLE_HOME differs from installation base
# ------------------------------------------------------------------------------
plugin_build_base_path() {
    local home_path="$1"
    # If ORACLE_BASE_HOME is provided via env, prefer it
    if [[ -n "${ORACLE_BASE_HOME:-}" ]]; then
        echo "${ORACLE_BASE_HOME}"
    else
        echo "${home_path}"
    fi
    return 0
}
```

#### 5. plugin_build_env

Build all environment variables required for the product type (and instance, if applicable).

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for the product/instance
# Args....: $1 - ORACLE_HOME
#           $2 - Instance/domain identifier (if applicable)
# Returns.: 0 on success, 1 if not applicable, 2 if unavailable
# Output..: Key=value pairs (one per line)
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    local instance="${2:-}"

    local base_path
    base_path=$(plugin_build_base_path "${home_path}")

    local bin_path
    bin_path=$(plugin_build_bin_path "${home_path}")

    local lib_path
    lib_path=$(plugin_build_lib_path "${home_path}")

    echo "ORACLE_BASE_HOME=${base_path}"
    echo "ORACLE_HOME=${home_path}"
    [[ -n "${instance}" ]] && echo "ORACLE_SID=${instance}"
    [[ -n "${bin_path}" ]] && echo "PATH=${bin_path}:${PATH:-}"
    [[ -n "${lib_path}" ]] && echo "LD_LIBRARY_PATH=${lib_path}:${LD_LIBRARY_PATH:-}"
    return 0
}
```

#### 6. plugin_check_status

Check if product instance is running.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if product instance is running
# Args....: $1 - Installation path
#           $2 - Instance name (optional)
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Uses explicit environment (not current shell environment)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    
    # Check if service/process is running
    # Return appropriate status
}
```

#### 7. plugin_get_metadata

Get product metadata (version, edition, etc.).

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get product metadata (version, features, etc.)
# Args....: $1 - Installation path
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Example output:
#           version=19.21.0.0.0
#           edition=Enterprise
#           patchlevel=221018
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Extract version
    local version
    version=$(get_version_from_product "${home_path}")
    
    # Output key=value pairs
    echo "version=${version}"
    echo "edition=Enterprise"
}
```

#### 8. plugin_discover_instances

Discover all instances for this Oracle Home.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover all instances for this Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: List of instances (one per line)
# Format..: instance_name|status|additional_metadata
# Notes...: Handles 1:many relationships (RAC, WebLogic, OUD)
#           Example: PROD1|running|node1
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    
    # Scan for instances
    # Example: check running processes, config files
    # Output instance info
}
```

#### 9. plugin_get_instance_list

Enumerate all instances/domains within the specified ORACLE_HOME.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate all instances/domains for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: Mandatory for multi-instance products (database, middleware, etc.)
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"
    # Implement per product: read oratab, domain listings, etc.
}
```

#### 10. plugin_supports_aliases

Indicate whether this product supports SID-like aliases.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Whether this product supports SID-like aliases
# Args....: None
# Returns.: 0 if supports aliases, 1 if not
# Output..: None
# Notes...: Database products: return 0, most others return 1
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    return 1
}
```

#### 11. plugin_build_bin_path

Get PATH components for this product.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns the directories to add to PATH for this product
#           Example (RDBMS): /u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch
#           Example (ICLIENT): /u01/app/oracle/instantclient_19_21
#           Example (DATASAFE): /u01/app/oracle/ds-name/oracle_cman_home/bin
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local home_path="$1"
    
    # Build PATH for product
    echo "${home_path}/bin:${home_path}/OPatch"
}
```

#### 12. plugin_build_lib_path

Get LD_LIBRARY_PATH components for this product.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Returns directories containing shared libraries
#           Example (RDBMS): /u01/app/oracle/product/19/lib
#           Example (ICLIENT): /u01/app/oracle/instantclient_19_21
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    
    # Build library path for product
    echo "${home_path}/lib"
}
```

#### 10. plugin_get_config_section

Get configuration section name for this product.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for this product
# Args....: None
# Returns.: 0 on success
# Output..: Configuration section name (uppercase)
# Notes...: Used by oradba_apply_product_config() to load product-specific settings
#           Example: "RDBMS", "DATASAFE", "CLIENT", "ICLIENT", "OUD", "WLS"
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "MYPRODUCT"
    return 0
}
```

#### 11. plugin_get_required_binaries

Get list of required binaries for this product.

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for this product
# Args....: None
# Returns.: 0 on success
# Output..: Space-separated list of required binary names
# Notes...: Used by oradba_check_oracle_binaries() to validate installation
#           Example (RDBMS): "sqlplus tnsping lsnrctl"
#           Example (DATASAFE): "cmctl"
#           Example (CLIENT): "sqlplus tnsping"
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "myproduct_binary myctl"
    return 0
}
```

### Optional Functions

Beyond the 13 universal core functions (and 2 category-specific for database products),
plugins may implement optional functions for product-specific features.

#### Common Optional Functions

Functions that multiple plugins may implement, with standardized naming:

```bash
# Get product version (has default implementation in plugin_interface.sh)
plugin_get_version() {
    local home_path="$1"
    # Extract version from installation
    echo "19.21.0.0.0"
    return 0
}

# Get required binaries for validation
plugin_get_required_binaries() {
    echo "myproduct_binary myctl"
    return 0
}

# Custom display name for instance (defaults to installation name)
plugin_get_display_name() {
    local name="$1"
    echo "${name}"
    return 0
}
```

#### Product-Specific Extensions

For features unique to a product, use descriptive function names:

```bash
# DataSafe example - get adjusted paths for oracle_cman_home
plugin_get_adjusted_paths() {
    local home_path="$1"
    echo "${home_path}/oracle_cman_home"
    return 0
}

# Database example - PDB status checking (illustrative)
plugin_database_get_pdb_status() {
    local home_path="$1"
    local pdb_name="$2"
    # Check PDB status
    echo "OPEN"
    return 0
}
```

**Naming Guidelines:**

- Use `plugin_<descriptive_name>` for generic extensions
- Use `plugin_<product>_<action>` when product-specific scope needs clarity
- Follow return value standards (exit codes + stdout conventions)
- Document thoroughly in plugin source file

> **📖 Extension Patterns:** See
> [plugin-standards.md - Optional Functions](plugin-standards.md#optional-functions-and-extension-patterns)
> for:
>
> - Common optional functions (plugin_get_version, plugin_get_required_binaries)
> - Product-specific extension patterns
> - When to use simple vs. complex extension patterns
> - Extension module structure (separate files for complex features)

## Step-by-Step Plugin Development

### Step 1: Create Plugin File

Create a new file in `src/lib/plugins/`:

```bash
cd /path/to/oradba
cat > src/lib/plugins/myproduct_plugin.sh << 'EOF'
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: myproduct_plugin.sh
# Author...: Your Name (email)
# Date.....: $(date +%Y.%m.%d)
# Version..: 1.0.0
# Purpose..: Plugin for My Oracle Product
# Notes....: Implements plugin interface v1.0.0
# ------------------------------------------------------------------------------

# Plugin Metadata (REQUIRED)
export plugin_name="myproduct"
export plugin_version="1.0.0"
export plugin_description="My Oracle Product plugin"

# Implement all 13 universal core functions here...
# (see examples below)

EOF
```

### Step 2: Implement Required Functions

Use the database plugin as a reference:

```bash
# View database plugin for reference
cat src/lib/plugins/database_plugin.sh

# Copy and adapt the structure
```

### Step 3: Add Product Type Detection

Update `src/lib/oradba_common.sh` to recognize your product:

```bash
detect_product_type() {
    local oracle_home="$1"
    
    # Add your product detection
    if [[ -x "${oracle_home}/bin/myproduct" ]]; then
        echo "myproduct"
        return 0
    fi
    
    # ... existing detections ...
}
```

### Step 4: Update Registry Validation

Add your product type to valid types in `src/lib/oradba_registry.sh`:

```bash
# Valid product types
local valid_types="database|client|iclient|datasafe|oud|java|myproduct"
```

### Step 5: Create Tests

Create comprehensive tests in `tests/`:

```bash
cat > tests/test_myproduct_plugin.bats << 'EOF'
#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# Tests for myproduct_plugin.sh
# ------------------------------------------------------------------------------

load test_helper

setup() {
    # Source the plugin
    source src/lib/plugins/myproduct_plugin.sh
}

@test "plugin metadata is set correctly" {
    [ -n "${plugin_name}" ]
    [ "${plugin_name}" = "myproduct" ]
    [ -n "${plugin_version}" ]
    [ -n "${plugin_description}" ]
}

@test "plugin_validate_home detects valid home" {
    # Create mock directory structure
    local test_home="${BATS_TEST_TMPDIR}/myproduct_home"
    mkdir -p "${test_home}/bin"
    touch "${test_home}/bin/myproduct"
    chmod +x "${test_home}/bin/myproduct"
    
    # Test validation
    run plugin_validate_home "${test_home}"
    [ "$status" -eq 0 ]
}

@test "plugin_validate_home rejects invalid home" {
    local test_home="${BATS_TEST_TMPDIR}/invalid_home"
    mkdir -p "${test_home}"
    
    run plugin_validate_home "${test_home}"
    [ "$status" -eq 1 ]
}

@test "plugin_build_bin_path returns correct path" {
    local test_home="/opt/oracle/myproduct"
    
    run plugin_build_bin_path "${test_home}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "${test_home}" ]]
}

@test "plugin_get_config_section returns correct section" {
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ "$output" = "MYPRODUCT" ]
}

# Add tests for all 13 universal core functions
EOF

# Run tests
bats tests/test_myproduct_plugin.bats
```

### Step 6: Add Integration Tests

Test integration with OraDBA core:

```bash
# Add to tests/test_integration.bats
@test "myproduct plugin integrates with oradba_add_oracle_path" {
    source src/lib/oradba_env_builder.sh
    source src/lib/plugins/myproduct_plugin.sh
    
    local test_home="/opt/oracle/myproduct"
    
    run oradba_add_oracle_path "${test_home}" "myproduct"
    [ "$status" -eq 0 ]
    
    # Verify PATH was modified
    [[ "${PATH}" =~ "${test_home}" ]]
}
```

### Step 7: Update Documentation

1. Add to README.md supported products list
2. Update doc/architecture.md plugin list
3. Add plugin-specific documentation if needed

### Step 8: Test Thoroughly

```bash
# Run all plugin tests
bats tests/test_myproduct_plugin.bats

# Run integration tests
bats tests/test_integration.bats

# Run full test suite
make test-full

# Check code quality
make lint
```

## Complete Example: Simple Plugin

Here's a complete, minimal plugin:

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Simple Example Plugin for OraDBA
# ------------------------------------------------------------------------------

# Plugin Metadata
export plugin_name="example"
export plugin_version="1.0.0"
export plugin_description="Example Oracle Product plugin"

# 1. Auto-detect installations
plugin_detect_installation() {
    # Scan for installations
    find /opt/oracle -maxdepth 2 -name "example_binary" -type f 2>/dev/null | \
 xargs -r dirname | sort -u 
}

# 2. Validate home
plugin_validate_home() {
    local home_path="$1"
    [[ -d "${home_path}" ]] && [[ -x "${home_path}/bin/example_binary" ]]
}

# 3. Adjust environment (most products don't need this)
plugin_adjust_environment() {
    local home_path="$1"
    echo "${home_path}"
}

# 4. Check status
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    
    if pgrep -f "example_process" > /dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

# 5. Get metadata
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    version=$("${home_path}/bin/example_binary" --version 2>&1 | head -1 | awk '{print $NF}')
    
    echo "version=${version}"
    echo "edition=Standard"
    return 0
}

# 6. Check status
plugin_check_status() {
    echo "running"
    return 0
}

# 7. Get metadata
plugin_get_metadata() {
    echo "version=1.0.0"
    return 0
}

# Category-specific: Show listener?
plugin_should_show_listener() {
    return 1  # No listener for this product
}

# 8. Discover instances
plugin_discover_instances() {
    local home_path="$1"
    # Single instance per home
    echo "example|running|default"
}

# 9. Build PATH
plugin_build_bin_path() {
    local home_path="$1"
    echo "${home_path}/bin"
}

# 10. Build library path
plugin_build_lib_path() {
    local home_path="$1"
    echo "${home_path}/lib"
}

# 11. Get config section
plugin_get_config_section() {
    echo "EXAMPLE"
}

# Optional: Check listener status (category-specific)
plugin_check_listener_status() {
    echo "unavailable"
    return 2
}

# Optional: Get required binaries
plugin_get_required_binaries() {
    echo "example_binary"
}

# Optional: Supports aliases?
plugin_supports_aliases() {
    return 1  # No SID-like aliases
}
```

## Integration Points

### Loading Plugins

Plugins are loaded automatically by `oradba_env_builder.sh`:

```bash
# Load plugin for product type
load_plugin() {
    local product_type="$1"
    local plugin_file="${ORADBA_BASE}/lib/plugins/${product_type}_plugin.sh"
    
    if [[ -f "${plugin_file}" ]]; then
        source "${plugin_file}"
        return 0
    else
        return 1
    fi
}
```

### Using Plugins

OraDBA core uses plugins through standardized calls:

```bash
# Validate Oracle Home using plugin
if load_plugin "${product_type}"; then
    if plugin_validate_home "${oracle_home}"; then
        echo "Valid home for ${product_type}"
    fi
fi

# Build PATH using plugin
if load_plugin "${product_type}"; then
    path_components=$(plugin_build_bin_path "${oracle_home}")
    export PATH="${path_components}:${PATH}"
fi
```

### Product Configuration

Add product-specific configuration to `oradba_standard.conf`:

```ini
# ------------------------------------------------------------------------------
# My Product Configuration
# ------------------------------------------------------------------------------
[MYPRODUCT]
# Product-specific environment variables
MYPRODUCT_SETTING1=value1
MYPRODUCT_SETTING2=value2
```

## Testing Strategy

### Unit Tests

Test each function independently:

```bash
@test "plugin_validate_home with valid home" { }
@test "plugin_validate_home with invalid home" { }
@test "plugin_validate_home with missing directory" { }
```

Add the return-value contract suite (`tests/test_plugin_return_values.bats`) to
enforce exit codes and stdout hygiene for core and category-specific functions.

### Integration Tests

Test plugin interaction with OraDBA core:

```bash
@test "plugin integrates with environment builder" { }
@test "plugin metadata accessible after load" { }
@test "plugin PATH added correctly" { }
```

### Manual Testing

1. Install plugin
2. Add entry to oradba_homes.conf
3. Source oraenv
4. Verify environment variables
5. Test status checks
6. Verify aliases (if applicable)

## Common Patterns

### DataSafe Pattern (Subdirectory)

```bash
plugin_adjust_environment() {
    local home_path="$1"
    # DataSafe uses subdirectory
    echo "${home_path}/oracle_cman_home"
}
```

### Instant Client Pattern (No bin directory)

```bash
plugin_build_bin_path() {
    local home_path="$1"
    # Instant Client: add home directly, not bin subdirectory
    echo "${home_path}"
}
```

### Multi-Instance Pattern (RAC, WebLogic)

```bash
plugin_discover_instances() {
    local home_path="$1"
    
    # Discover multiple instances
    for instance in $(find_instances); do
        status=$(check_instance_status "${instance}")
        echo "${instance}|${status}|node1"
    done
}
```

## Troubleshooting

### Plugin Debug Facilities (v0.19.0+)

OraDBA provides comprehensive debug facilities for troubleshooting plugin execution issues.

#### Enabling Plugin Debug Mode

Plugin debug is automatically enabled when **any** of these conditions are met:

- `export ORADBA_PLUGIN_DEBUG=true` - Dedicated plugin debug flag
- `export ORADBA_LOG_LEVEL=DEBUG` - General debug level
- `export ORADBA_LOG_LEVEL=TRACE` - Detailed trace level (includes raw output)
- `export DEBUG=1` - Legacy debug flag (backward compatible)

```bash
# Method 1: Use dedicated plugin debug flag
export ORADBA_PLUGIN_DEBUG=true
source oraenv

# Method 2: Use general debug level
export ORADBA_LOG_LEVEL=DEBUG
source oraenv

# Method 3: Use trace level for maximum verbosity
export ORADBA_LOG_LEVEL=TRACE
source oraenv
```

#### Debug Output Levels

**DEBUG Level** - Shows plugin call details and environment snapshot:

```text
[DEBUG] Plugin call: plugin=database, function=check_status, oracle_home=/u01/app/oracle/product/19c
[DEBUG] Plugin env: ORACLE_HOME=/u01/app/oracle/product/19c, LD_LIBRARY_PATH=/u01/app/oracle/product/19c/lib, TNS_ADMIN=<unset>, PATH=...
[DEBUG] Plugin exit: code=0, plugin=database, function=check_status
```

**TRACE Level** - Includes raw stdout/stderr from plugin functions:

```text
[DEBUG] Plugin call: plugin=datasafe, function=check_status, oracle_home=/u01/app/oracle/cman01
[DEBUG] Plugin env: ORACLE_HOME=/u01/app/oracle/cman01, LD_LIBRARY_PATH=/u01/app/oracle/cman01/lib, TNS_ADMIN=<unset>, PATH=...
[TRACE] Plugin stdout: cmctl status
[TRACE] Plugin stderr: <any error messages>
[DEBUG] Plugin exit: code=0, plugin=datasafe, function=check_status
```

#### Security: Automatic Sanitization

All debug output automatically masks sensitive data:

- **Passwords**: `user/password@db` → `user/***@db`
- **Connection strings**: `sqlplus sys/pass@db` → `sqlplus sys/***@db`
- **Environment variables**: `PASSWORD="secret"` → `PASSWORD="***"`
- **Parameter patterns**: `password=secret` → `password=***`

```bash
# Example: Sensitive data is automatically masked
export ORADBA_LOG_LEVEL=DEBUG
execute_plugin_function_v2 "database" "check_status" "/u01/app/oracle/product/19c" "result" "sys/password@db"
# Output: [DEBUG] Plugin call: plugin=database, function=check_status, oracle_home=/u01/app/oracle/product/19c, extra_arg=sys/***@db
```

#### Troubleshooting Common Issues

**Issue**: Plugin function returns error but no details visible

```bash
# Enable debug to see environment and call details
export ORADBA_LOG_LEVEL=DEBUG
source oraenv
```

**Issue**: Command-line tool (sqlplus/cmctl/lsnrctl) failing inside plugin

```bash
# Enable trace to see raw stdout/stderr
export ORADBA_LOG_LEVEL=TRACE
source oraenv
```

**Issue**: Environment variables not set correctly

```bash
# Debug shows exact environment passed to plugin
export ORADBA_PLUGIN_DEBUG=true
source oraenv
# Look for "Plugin env:" lines showing ORACLE_HOME, LD_LIBRARY_PATH, PATH
```

**Issue**: Need to debug plugin without affecting all logging

```bash
# Use dedicated plugin debug flag (doesn't enable DEBUG for everything else)
export ORADBA_PLUGIN_DEBUG=true
source oraenv
```

#### Best Practices for Plugin Debugging

✅ **Start with DEBUG level**: Shows most relevant information  
✅ **Use TRACE only when needed**: Generates verbose output  
✅ **Check sanitization**: Verify no credentials in logs before sharing  
✅ **Disable after debugging**: Reset `ORADBA_LOG_LEVEL` to INFO or unset  

❌ **Don't leave TRACE enabled**: Performance impact and log bloat  
❌ **Don't share unsanitized logs**: Even with sanitization, review before sharing  

### Plugin Not Loading

```bash
# Check if plugin file exists
ls -la src/lib/plugins/myproduct_plugin.sh

# Check for syntax errors
bash -n src/lib/plugins/myproduct_plugin.sh

# Enable debug logging
export ORADBA_LOG_LEVEL=DEBUG
source oraenv
```

### Function Not Found

```bash
# Verify all 13 universal core functions are implemented
grep "^plugin_" src/lib/plugins/myproduct_plugin.sh | wc -l
# Should show at least 13

# Check function names match exactly
grep "^plugin_" src/lib/plugins/myproduct_plugin.sh
```

### Tests Failing

```bash
# Run specific test with output
bats tests/test_myproduct_plugin.bats -f "test_name" --tap

# Check test environment
ls -la "${BATS_TEST_TMPDIR}"

# Add debug output to test
@test "my test" {
    echo "Debug info" >&3
    run my_function
    echo "Output: $output" >&3
}
```

## Best Practices

### DO

✅ **Implement all 13 universal core functions**: Even if they return defaults
✅ **Follow naming conventions**: Use `plugin_*` prefix
✅ **Add comprehensive tests**: Cover edge cases
✅ **Document behavior**: Use function headers
✅ **Handle errors gracefully**: Return appropriate error codes
✅ **Use plugin_get_version**: For consistency across plugins

### DON'T

❌ **Don't modify global state**: Except PATH/LD_LIBRARY_PATH as designed
❌ **Don't hardcode paths**: Use variables and configuration
❌ **Don't skip error handling**: Check return codes
❌ **Don't assume dependencies**: Verify binaries exist before calling
❌ **Don't break interface**: Maintain function signatures

## Checklist

Before submitting plugin:

**Mandatory Requirements:**

- [ ] All 13 universal core functions implemented
- [ ] Category-specific functions added if applicable:
  - [ ] `plugin_should_show_listener` (database/listener products)
  - [ ] `plugin_check_listener_status` (database/listener products)
- [ ] Plugin metadata set (name, version, interface_version, description)
- [ ] Tests created and passing (see plugin-standards.md for test requirements)
- [ ] All tests pass: `bats tests/test_myproduct_plugin.bats`
- [ ] Return value contract followed (exit codes 0/1/2, no sentinel strings)

**Integration and Validation:**

- [ ] Integration tested with OraDBA core
- [ ] Product type added to `detect_product_type()` in oradba_common.sh
- [ ] Product type added to registry validation in oradba_registry.sh
- [ ] Configuration section added (if needed) in oradba_standard.conf
- [ ] Code passes shellcheck: `shellcheck src/lib/plugins/myproduct_plugin.sh`

**Documentation:**

- [ ] All function headers complete (Purpose, Args, Returns, Output)
- [ ] Plugin metadata documented in source file header
- [ ] Optional/extension functions documented (if added)
- [ ] Product-specific notes added to plugin-standards.md (if new category)
- [ ] README updated with new product type
- [ ] CHANGELOG.md updated

**Recommended:**

- [ ] Plugin interface version declared: `export plugin_interface_version="1.0.0"`
- [ ] Follow naming conventions for extension functions
- [ ] Add examples to plugin source documentation
- [ ] Test edge cases and error conditions

## References

- **[Plugin Standards](plugin-standards.md)** - **Official specification** for plugin interface
- [Plugin Interface](../src/lib/plugins/plugin_interface.sh) - Interface template implementation
- [Database Plugin](../src/lib/plugins/database_plugin.sh) - Reference implementation
- [Architecture](architecture.md) - System architecture
- [Development Workflow](development-workflow.md) - Development process
- [Extension System](extension-system.md) - Extension development

## Support

- Open an issue for plugin development questions
- Review existing plugins for examples
- Check plugin tests for usage patterns
- See architecture documentation for system design
