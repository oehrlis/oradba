# OraDBA Plugin Standards

**Version**: v1.0.0  
**Last Updated**: 2026-01-29  
**Status**: Official Standard

## Table of Contents

1. [Introduction](#introduction)
2. [Core Plugin Functions](#core-plugin-functions)
3. [Return Value Standards](#return-value-standards)
4. [Optional Functions and Extension Patterns](#optional-functions-and-extension-patterns)
5. [Function Templates](#function-templates)
6. [Interface Versioning](#interface-versioning)
7. [Testing Requirements](#testing-requirements)
8. [Best Practices](#best-practices)
9. [Migration from Non-Compliant Code](#migration-from-non-compliant-code)

---

## Introduction

### Purpose

This document formalizes the OraDBA plugin interface specification (v1.0.0) and establishes standards for plugin development. It serves as:

- **Reference guide** for implementing new product plugins
- **Contract specification** between OraDBA core and product plugins
- **Quality standard** for return values, exit codes, and error handling
- **Extension guide** for adding optional product-specific features

### Relationship to v1.0.0 Interface

The plugin interface was established at version **v1.0.0** in January 2026. This document codifies:

- 11 core required functions that all plugins MUST implement
- Return value conventions (exit codes + stdout patterns)
- Extension patterns for optional/product-specific features
- Backward compatibility guarantees

**Note**: Previous references to "v2.0.0" were accidental and should be ignored. The canonical interface version is **v1.0.0**.

### When to Reference This Document

- **Plugin developers**: When creating a new product plugin
- **Maintainers**: When reviewing plugin PRs or updating interface
- **Testers**: When writing plugin compliance tests
- **Troubleshooters**: When debugging plugin integration issues

---

## Core Plugin Functions

All plugins MUST implement these **11 required functions** and declare **3 metadata variables**.

### Required Metadata

```bash
export plugin_name="myproduct"              # Product type identifier
export plugin_version="1.0.0"               # Plugin version (semantic versioning)
export plugin_description="My Product"      # Human-readable description
```

### Required Functions Table

| # | Function Name | Purpose | Exit Codes | Required |
|---|---------------|---------|------------|----------|
| 1 | `plugin_detect_installation` | Auto-discover installations | 0=success | ✅ |
| 2 | `plugin_validate_home` | Validate installation path | 0=valid, 1=invalid | ✅ |
| 3 | `plugin_adjust_environment` | Adjust ORACLE_HOME if needed | 0=success | ✅ |
| 4 | `plugin_check_status` | Check service/instance status | 0=running, 1=stopped, 2=unavailable | ✅ |
| 5 | `plugin_get_metadata` | Get installation metadata | 0=success | ✅ |
| 6 | `plugin_should_show_listener` | Show in listener list? | 0=yes, 1=no | ✅ |
| 7 | `plugin_discover_instances` | Discover running instances | 0=success | ✅ |
| 8 | `plugin_supports_aliases` | Supports SID aliases? | 0=yes, 1=no | ✅ |
| 9 | `plugin_build_path` | Get PATH components | 0=success | ✅ |
| 10 | `plugin_build_lib_path` | Get LD_LIBRARY_PATH components | 0=success | ✅ |
| 11 | `plugin_get_config_section` | Get config file section name | 0=success | ✅ |

### Function Details

#### 1. plugin_detect_installation

**Purpose**: Auto-discover installations of this product type on the system.

**Signature**: `plugin_detect_installation()`

**Returns**: Exit 0 on success

**Output**: List of installation paths (one per line), sorted and deduplicated

**Notes**:
- Scans common locations (e.g., `/opt/oracle`, `/u01/app/oracle`)
- May check running processes (e.g., `pmon`, `cmctl`)
- Excludes installations inside other product homes
- Used for auto-discovery when registry files are missing

#### 2. plugin_validate_home

**Purpose**: Validate that a path is a valid ORACLE_HOME for this product.

**Signature**: `plugin_validate_home <path>`

**Args**: `$1` - Path to validate

**Returns**: Exit 0 if valid, 1 if invalid

**Output**: None (status via exit code only)

**Notes**:
- Checks for product-specific files/directories
- Examples: `bin/sqlplus` (database), `bin/cmctl` (datasafe), `libclntsh.so` (iclient)
- Should NOT echo anything (exit code is the contract)

#### 3. plugin_adjust_environment

**Purpose**: Adjust ORACLE_HOME path for product-specific requirements.

**Signature**: `plugin_adjust_environment <path>`

**Args**: `$1` - Original ORACLE_HOME path

**Returns**: Exit 0 on success

**Output**: Adjusted ORACLE_HOME path (may be same as input)

**Notes**:
- Most products return path unchanged
- DataSafe appends `/oracle_cman_home`
- Used to handle products with non-standard directory structures

#### 4. plugin_check_status

**Purpose**: Check if product instance/service is running.

**Signature**: `plugin_check_status <home_path> [instance_name]`

**Args**:
- `$1` - Installation path (ORACLE_HOME)
- `$2` - Instance name (optional)

**Returns**:
- Exit 0 if running
- Exit 1 if stopped
- Exit 2 if unavailable (binary missing, command failed)

**Output**: Status string (`running`, `stopped`, or `unavailable`)

**Notes**:
- Uses explicit environment (not current shell environment)
- For databases: checks `pmon` processes or connects with sqlplus
- For datasafe: checks `cmctl status`
- For iclient: checks if libraries are readable

#### 5. plugin_get_metadata

**Purpose**: Get product metadata (version, edition, features).

**Signature**: `plugin_get_metadata <home_path>`

**Args**: `$1` - Installation path (ORACLE_HOME)

**Returns**: Exit 0 on success

**Output**: Key=value pairs (one per line)

**Format**:
```
version=19.21.0.0.0
edition=Enterprise
patchlevel=221018
```

**Notes**:
- Version detection varies by product (see optional `plugin_get_version`)
- May include product-specific metadata
- All values should be clean data (no "unknown" or "ERR" sentinels)

#### 6. plugin_should_show_listener

**Purpose**: Determine if this product's listener should appear in listener section.

**Signature**: `plugin_should_show_listener <home_path>`

**Args**: `$1` - Installation path (ORACLE_HOME)

**Returns**: Exit 0 if should show, 1 if should not show

**Output**: None (status via exit code only)

**Notes**:
- Database listeners: return 0 (show in listener list)
- DataSafe connectors: return 1 (use `tnslsnr` but aren't DB listeners)
- Most products: return 1 (no listener)

#### 7. plugin_discover_instances

**Purpose**: Discover all instances for this Oracle Home.

**Signature**: `plugin_discover_instances <home_path>`

**Args**: `$1` - ORACLE_HOME path

**Returns**: Exit 0 on success

**Output**: List of instances (one per line), pipe-delimited

**Format**: `instance_name|status|additional_metadata`

**Notes**:
- Handles 1:many relationships (RAC, WebLogic, OUD)
- Most products have single instance per home
- May return empty output if no instances found

#### 8. plugin_supports_aliases

**Purpose**: Indicate whether this product supports SID-like aliases.

**Signature**: `plugin_supports_aliases()`

**Returns**: Exit 0 if supports aliases, 1 if not

**Output**: None (status via exit code only)

**Notes**:
- Databases support aliases (exit 0)
- Most other products don't (exit 1)

#### 9. plugin_build_path

**Purpose**: Get PATH components for this product.

**Signature**: `plugin_build_path <home_path>`

**Args**: `$1` - ORACLE_HOME path

**Returns**: Exit 0 on success

**Output**: Colon-separated PATH components

**Examples**:
- RDBMS: `/u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch`
- Instant Client: `/u01/app/oracle/instantclient_19_21` (no `bin/`)
- DataSafe: `/u01/app/oracle/ds-name/oracle_cman_home/bin`

**Notes**:
- Returns directories to prepend to PATH
- May return multiple directories (colon-separated)
- Caller handles deduplication

#### 10. plugin_build_lib_path

**Purpose**: Get LD_LIBRARY_PATH components for this product.

**Signature**: `plugin_build_lib_path <home_path>`

**Args**: `$1` - ORACLE_HOME path

**Returns**: Exit 0 on success

**Output**: Colon-separated library path components

**Examples**:
- RDBMS: `/u01/app/oracle/product/19/lib`
- Instant Client: `/u01/app/oracle/instantclient_19_21` (libraries in root)
- DataSafe: `/u01/app/oracle/ds-name/oracle_cman_home/lib`

**Notes**:
- Returns directories containing shared libraries
- May return multiple directories (colon-separated)
- Caller handles deduplication

#### 11. plugin_get_config_section

**Purpose**: Get configuration section name for this product.

**Signature**: `plugin_get_config_section()`

**Returns**: Exit 0 on success

**Output**: Configuration section name (UPPERCASE)

**Examples**: `RDBMS`, `DATASAFE`, `CLIENT`, `ICLIENT`, `OUD`, `WLS`

**Notes**:
- Used by `oradba_apply_product_config()` to load product-specific settings
- Section names should be uppercase
- Must match section headers in config files

---

## Return Value Standards

### Standard Exit Codes

**All plugin functions MUST follow these conventions:**

| Exit Code | Meaning | Usage |
|-----------|---------|-------|
| **0** | Success | Operation completed successfully, valid data on stdout |
| **1** | Expected failure | Operation not applicable, service stopped, version N/A |
| **2** | Unavailable | Binary missing, command failed, resource not accessible |
| **3+** | Reserved | Reserved for future use (must be documented if used) |

### Stdout Standards

**Critical Rules**:

1. ❌ **NEVER** echo sentinel strings: `"ERR"`, `"unknown"`, `"N/A"`, `"Not Applicable"`
2. ✅ **Echo clean data only** - Callers should never parse output strings for error detection
3. ✅ **Empty output + exit 0** = valid empty result (e.g., no instances found)
4. ✅ **Empty output + exit 1** = expected failure (e.g., version not applicable)
5. ✅ **Stderr may contain debug info** - Caller controls logging level

### Why Avoid Sentinel Strings?

**Problem with sentinels**:
```bash
# ❌ WRONG: Fragile string checking
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
    # What if someone adds "N/A" later? Code breaks!
    echo "Version: ${version}"
fi
```

**Solution with exit codes**:
```bash
# ✅ CORRECT: Clean contract
if version=$(plugin_get_version "${home}"); then
    # Success - use ${version} safely
    echo "Version: ${version}"
else
    case $? in
        1) oradba_log DEBUG "Version not applicable" ;;
        2) oradba_log WARN "Version detection failed" ;;
    esac
fi
```

### Pattern Examples

#### ✅ Correct Pattern

```bash
plugin_get_version() {
    local home_path="$1"
    local version
    
    # Check if binary exists
    [[ ! -x "${home_path}/bin/oracle" ]] && return 2  # Unavailable
    
    # Try to extract version
    version=$(extract_version "${home_path}") || return 2  # Command failed
    
    # Check if version found
    [[ -z "${version}" ]] && return 1  # Not applicable
    
    # Output clean data
    echo "${version}"
    return 0
}

# Caller
if version=$(plugin_get_version "${home}"); then
    echo "Found version: ${version}"
else
    exit_code=$?
    [[ ${exit_code} -eq 2 ]] && oradba_log ERROR "Version check failed"
fi
```

#### ❌ Incorrect Patterns

```bash
# ❌ WRONG: Sentinel string
plugin_get_version() {
    [[ ! -x "${binary}" ]] && { echo "ERR"; return 1; }
    echo "unknown"  # Never do this!
}

# ❌ WRONG: Checking stdout instead of exit code
version=$(plugin_get_version "${home}")
if [[ "${version}" != "ERR" ]]; then
    # Fragile and error-prone!
fi

# ❌ WRONG: Mixed data and error messages
plugin_get_metadata() {
    echo "version=19.21.0.0.0"
    echo "ERROR: Could not determine edition" >&1  # Wrong stream!
}
```

---

## Optional Functions and Extension Patterns

Plugins MAY implement additional functions beyond the 11 core functions for product-specific features.

### Common Optional Functions

| Function | Purpose | Usage |
|----------|---------|-------|
| `plugin_get_version` | Extract product version | Common across most plugins |
| `plugin_get_required_binaries` | List required binaries | Used by validators |
| `plugin_get_display_name` | Custom display name | Override default naming |

### Product-Specific Extensions

**Naming Convention**: `plugin_<product>_<function_name>`

**Examples**:
- `plugin_database_get_pdb_status` - Database-specific: PDB status
- `plugin_database_check_rac` - Database-specific: RAC configuration
- `plugin_datasafe_get_connector_config` - DataSafe-specific: connector config

### Implementation Patterns

#### Pattern 1: Simple Extensions (In Plugin File)

For **1-3 optional functions** (< 50 lines total), add directly to the main plugin file:

```bash
#!/usr/bin/env bash
# database_plugin.sh

export plugin_name="database"
export plugin_version="1.0.0"
export plugin_description="Oracle Database plugin"

# ============================================================================
# Core Functions (11 required)
# ============================================================================

plugin_detect_installation() { ... }
plugin_validate_home() { ... }
plugin_adjust_environment() { ... }
plugin_check_status() { ... }
plugin_get_metadata() { ... }
plugin_should_show_listener() { ... }
plugin_discover_instances() { ... }
plugin_supports_aliases() { ... }
plugin_build_path() { ... }
plugin_build_lib_path() { ... }
plugin_get_config_section() { ... }

# ============================================================================
# Optional Functions (simple extensions)
# ============================================================================

plugin_get_version() {
    local home_path="$1"
    # Extract database version
    # ... implementation ...
}

plugin_get_required_binaries() {
    echo "sqlplus lsnrctl"
}
```

#### Pattern 2: Complex Extensions (Separate Module)

For **4+ optional functions** or **complex logic (>100 lines)**, create a separate extension module:

**File Structure**:
```
src/lib/plugins/
├── database_plugin.sh          # Core functions only (11 required)
├── database_extensions.sh      # Optional complex features
├── datasafe_plugin.sh          # Core functions only
└── datasafe_extensions.sh      # Optional complex features (if needed)
```

**Main Plugin** (`database_plugin.sh`):
```bash
#!/usr/bin/env bash
# database_plugin.sh

export plugin_name="database"
export plugin_version="1.0.0"
export plugin_description="Oracle Database plugin"

# ============================================================================
# Core Functions (11 required)
# ============================================================================

plugin_detect_installation() { ... }
plugin_validate_home() { ... }
# ... other 9 core functions ...

# ============================================================================
# Load Extensions
# ============================================================================

# Load optional extensions if available
if [[ -f "${ORADBA_BASE}/lib/plugins/database_extensions.sh" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_BASE}/lib/plugins/database_extensions.sh"
fi
```

**Extension Module** (`database_extensions.sh`):
```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Database Plugin Extensions
# Purpose.: Provides optional database-specific functionality
# Notes...: Loaded by database_plugin.sh if present
# ------------------------------------------------------------------------------

# ============================================================================
# Optional Helper Functions
# ============================================================================

plugin_get_version() {
    local home_path="$1"
    # Complex version extraction logic
    # ... implementation ...
}

# ============================================================================
# Database-Specific Extensions
# ============================================================================

plugin_database_get_pdb_status() {
    local oracle_home="$1"
    local pdb_name="${2:-}"
    
    # Complex PDB status checking
    # ... implementation ...
}

plugin_database_check_rac() {
    local oracle_home="$1"
    
    # RAC configuration detection
    # ... implementation ...
}

plugin_database_get_asm_diskgroups() {
    local oracle_home="$1"
    
    # ASM diskgroup enumeration
    # ... implementation ...
}
```

**Benefits of Separation**:
- ✅ Core plugin stays focused and testable
- ✅ Optional features don't bloat core
- ✅ Extensions can evolve independently
- ✅ Clear separation of required vs. optional
- ✅ Easier to maintain and debug

**When to Use Each Pattern**:
- **In-plugin**: 1-3 simple optional functions (<50 lines total)
- **Separate module**: 4+ optional functions OR complex logic (>100 lines)

---

## Function Templates

### Template: plugin_detect_installation

```bash
# ------------------------------------------------------------------------------
# Function: plugin_detect_installation
# Purpose.: Auto-detect product installations on the system
# Args....: None
# Returns.: 0 on success
# Output..: List of installation paths (one per line)
# Notes...: Scans common locations, checks processes, searches filesystems
# ------------------------------------------------------------------------------
plugin_detect_installation() {
    local -a homes=()
    
    # Method 1: Check running processes
    # Example: ps -ef | grep "[p]mon_" for databases
    
    # Method 2: Scan common directories
    # Example: find /opt/oracle -name "product_binary"
    
    # Method 3: Check environment variables
    # Example: Parse existing ORACLE_HOME settings
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}
```

### Template: plugin_validate_home

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
    
    # Check directory exists
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for product-specific markers
    # Examples:
    # - [[ -x "${home_path}/bin/product_binary" ]] || return 1
    # - [[ -d "${home_path}/product_dir" ]] || return 1
    # - [[ -f "${home_path}/lib/product.so" ]] || return 1
    
    return 0
}
```

### Template: plugin_adjust_environment

```bash
# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for product-specific requirements
# Args....: $1 - Original ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME path
# Notes...: Most products return the path unchanged
#           DataSafe appends /oracle_cman_home
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    
    # Most products: return unchanged
    echo "${home_path}"
    
    # DataSafe example:
    # if [[ -d "${home_path}/oracle_cman_home" ]]; then
    #     echo "${home_path}/oracle_cman_home"
    # else
    #     echo "${home_path}"
    # fi
    
    return 0
}
```

### Template: plugin_check_status

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
    
    # Check if binary exists
    [[ ! -x "${home_path}/bin/product_binary" ]] && {
        echo "unavailable"
        return 2
    }
    
    # Check if service/process is running
    if pgrep -f "product_process" > /dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}
```

### Template: plugin_get_metadata

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get product metadata (version, features, etc.)
# Args....: $1 - Installation path
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Version extraction can use plugin_get_version if implemented
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Get version (use plugin_get_version if available)
    local version="unknown"
    if declare -f plugin_get_version >/dev/null 2>&1; then
        if version=$(plugin_get_version "${home_path}"); then
            :  # Version retrieved successfully
        fi
    fi
    
    # Output metadata
    echo "version=${version}"
    echo "edition=Standard"
    # Add product-specific metadata
    
    return 0
}
```

### Template: plugin_should_show_listener

```bash
# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Determine if this product's tnslsnr should appear in listener section
# Args....: $1 - Installation path
# Returns.: 0 if should show, 1 if should not show
# Output..: None
# Notes...: Database listeners: return 0
#           DataSafe connectors: return 1
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    local home_path="$1"
    
    # Default: don't show listener (override in product plugins)
    return 1
    
    # Database example:
    # return 0  # Show database listeners
}
```

### Template: plugin_discover_instances

```bash
# ------------------------------------------------------------------------------
# Function: plugin_discover_instances
# Purpose.: Discover all instances for this Oracle Home
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: List of instances (one per line)
# Format..: instance_name|status|additional_metadata
# Notes...: Handles 1:many relationships (RAC, WebLogic, OUD)
# ------------------------------------------------------------------------------
plugin_discover_instances() {
    local home_path="$1"
    
    # Default: single instance (most products)
    # Override for RAC, WebLogic, OUD, etc.
    
    # Example for single instance:
    # echo "instance1|running|default"
    
    # Example for multiple instances:
    # for instance in $(find_instances); do
    #     status=$(check_instance_status "${instance}")
    #     echo "${instance}|${status}|node1"
    # done
    
    return 0
}
```

### Template: plugin_supports_aliases

```bash
# ------------------------------------------------------------------------------
# Function: plugin_supports_aliases
# Purpose.: Whether this product supports SID-like aliases
# Args....: None
# Returns.: 0 if supports aliases, 1 if not
# Output..: None
# Notes...: Databases support aliases, most other products don't
# ------------------------------------------------------------------------------
plugin_supports_aliases() {
    # Default: no aliases
    return 1
    
    # Database example:
    # return 0  # Databases support aliases
}
```

### Template: plugin_build_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns directories to add to PATH
# ------------------------------------------------------------------------------
plugin_build_path() {
    local home_path="$1"
    
    # Standard pattern: bin and OPatch
    echo "${home_path}/bin:${home_path}/OPatch"
    
    # Instant Client pattern (no bin/):
    # echo "${home_path}"
    
    # DataSafe pattern (oracle_cman_home/bin):
    # echo "${home_path}/bin"
    
    return 0
}
```

### Template: plugin_build_lib_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Returns directories containing shared libraries
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    
    # Standard pattern: lib directory
    echo "${home_path}/lib"
    
    # Instant Client pattern (libraries in root):
    # echo "${home_path}"
    
    # Multiple directories:
    # echo "${home_path}/lib:${home_path}/lib64"
    
    return 0
}
```

### Template: plugin_get_config_section

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for this product
# Args....: None
# Returns.: 0 on success
# Output..: Configuration section name (uppercase)
# Notes...: Used to load product-specific settings from config files
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "MYPRODUCT"
    return 0
}
```

---

## Interface Versioning

### Current Version: v1.0.0

**All plugins MUST declare the interface version**:

```bash
export plugin_name="myproduct"
export plugin_version="1.0.0"
export plugin_description="My Product plugin"
```

**Note**: The `plugin_version` is the plugin's own version, not the interface version. The interface version is implicitly v1.0.0 for all plugins implementing the 11 core functions.

### Version Policy

- **Current Interface**: v1.0.0 (established January 2026)
- **Previous "v2.0.0" references**: Were accidental and should be ignored
- **Future versions**: Breaking changes require explicit version bump

### What Constitutes a Breaking Change

Breaking changes require a formal decision, announcement, and migration plan:

1. **Removing a core function** - All 11 functions are required
2. **Changing function signature** - Adding/removing parameters
3. **Changing exit code semantics** - Exit code meanings are part of the contract
4. **Changing output format** - For structured data (pipe-delimited, key=value)

### Non-Breaking Changes

These can be done without version bump:

- Adding new optional functions
- Adding new metadata fields to `plugin_get_metadata`
- Improving error messages on stderr
- Performance improvements
- Documentation updates

### Migration Process for Breaking Changes

If a breaking change is necessary:

1. **Formal decision**: Document rationale and necessity
2. **Announcement**: Notify plugin developers (2-3 release cycles in advance)
3. **Migration guide**: Provide clear upgrade instructions
4. **Compatibility layer**: Support old interface during transition
5. **Deprecation warnings**: Log warnings when old patterns detected
6. **Version bump**: Increment interface version (e.g., v1.0.0 → v2.0.0)

---

## Testing Requirements

All plugins MUST have comprehensive tests covering both generic interface compliance and product-specific behavior.

### Generic Tests (All Plugins)

Every plugin must pass these interface compliance tests:

```bash
# Test file: tests/test_plugin_interface.bats

@test "plugin has required metadata" {
    source plugin_file.sh
    [[ -n "${plugin_name}" ]]
    [[ -n "${plugin_version}" ]]
    [[ -n "${plugin_description}" ]]
}

@test "plugin implements all 11 core functions" {
    source plugin_file.sh
    declare -f plugin_detect_installation
    declare -f plugin_validate_home
    declare -f plugin_adjust_environment
    declare -f plugin_check_status
    declare -f plugin_get_metadata
    declare -f plugin_should_show_listener
    declare -f plugin_discover_instances
    declare -f plugin_supports_aliases
    declare -f plugin_build_path
    declare -f plugin_build_lib_path
    declare -f plugin_get_config_section
}

@test "plugin functions follow return value conventions" {
    # Test exit codes
    # Test stdout is clean (no sentinel strings)
}

@test "plugin functions never echo sentinel strings" {
    # Verify no "ERR", "unknown", "N/A" in stdout
}
```

### Plugin-Specific Tests

Each plugin should have dedicated tests for its specific behavior:

```bash
# Test file: tests/test_database_plugin.bats

@test "plugin_detect_installation finds database homes" {
    # Test detection logic
}

@test "plugin_validate_home accepts valid database home" {
    # Test validation with mock directory
}

@test "plugin_check_status reports correct database status" {
    # Test status checking
}

@test "plugin_build_path includes bin and OPatch" {
    # Test PATH building
}

@test "plugin_database_get_pdb_status works correctly" {
    # Test product-specific extension
}
```

### Test Organization

```
tests/
├── test_plugin_interface.bats         # Generic: all plugins
├── test_plugin_return_values.bats     # Generic: return conventions
├── test_database_plugin.bats          # Specific: database
├── test_datasafe_plugin.bats          # Specific: datasafe
├── test_client_plugin.bats            # Specific: client
├── test_iclient_plugin.bats           # Specific: instant client
├── test_oud_plugin.bats               # Specific: OUD
└── test_java_plugin.bats              # Specific: Java
```

### Coverage Requirements

- **Core functions**: 100% coverage (all 11 functions tested)
- **Optional functions**: Test if implemented
- **Error paths**: Test invalid inputs, missing binaries, etc.
- **Edge cases**: Empty directories, permission issues, symlinks

### Running Tests

```bash
# Run all plugin tests
make test-plugins

# Run specific plugin tests
bats tests/test_database_plugin.bats

# Run interface compliance tests
bats tests/test_plugin_interface.bats

# Run with verbose output
bats tests/test_database_plugin.bats --tap
```

---

## Best Practices

### DO ✅

- **Use exit codes for control flow, stdout for data**
  ```bash
  if version=$(plugin_get_version "${home}"); then
      echo "Version: ${version}"
  fi
  ```

- **Validate all input parameters**
  ```bash
  plugin_build_path() {
      local home_path="$1"
      [[ -z "${home_path}" ]] && return 1
      [[ ! -d "${home_path}" ]] && return 1
      # ... implementation ...
  }
  ```

- **Fail fast and clearly**
  ```bash
  [[ ! -x "${binary}" ]] && return 2  # Unavailable
  [[ -z "${result}" ]] && return 1    # Not applicable
  ```

- **Document all exit codes in function header**
  ```bash
  # Returns.: 0 if running, 1 if stopped, 2 if unavailable
  ```

- **Use subshell-safe patterns**
  ```bash
  # Avoid global state modification
  # Return data via stdout, not global variables
  ```

- **Add logging to stderr (not stdout)**
  ```bash
  oradba_log DEBUG "Checking status for ${home}" >&2
  echo "running"  # Clean stdout
  ```

- **Follow naming conventions for extensions**
  ```bash
  plugin_database_get_pdb_status  # Product-specific
  plugin_get_version               # Common optional
  ```

### DON'T ❌

- **Don't echo "ERR", "unknown", or other sentinels**
  ```bash
  # ❌ WRONG
  echo "ERR"
  echo "unknown"
  echo "N/A"
  
  # ✅ CORRECT
  return 1  # Use exit code
  ```

- **Don't modify caller's variables or environment**
  ```bash
  # ❌ WRONG
  export MODIFIED_VAR="value"
  
  # ✅ CORRECT
  echo "value"  # Return via stdout
  ```

- **Don't call `oradba_log()` directly to stdout**
  ```bash
  # ❌ WRONG
  oradba_log INFO "Processing..." >&1
  
  # ✅ CORRECT
  oradba_log DEBUG "Processing..." >&2  # stderr is fine
  ```

- **Don't mix data and error messages on stdout**
  ```bash
  # ❌ WRONG
  echo "version=19.21.0.0.0"
  echo "ERROR: Edition not found"
  
  # ✅ CORRECT
  echo "version=19.21.0.0.0"
  oradba_log WARN "Edition not found" >&2
  ```

- **Don't assume dependencies are loaded**
  ```bash
  # ✅ CORRECT: Check before use
  if declare -f oradba_log >/dev/null 2>&1; then
      oradba_log DEBUG "Message"
  fi
  ```

- **Don't break backward compatibility without version bump**
  ```bash
  # ❌ WRONG: Changing function signature
  plugin_check_status() {
      local home="$1"
      local instance="$2"
      local timeout="$3"  # NEW PARAMETER - BREAKING!
  }
  ```

---

## Migration from Non-Compliant Code

### Example: Version Detection

#### Before (Non-Compliant)

```bash
plugin_get_version() {
    local home_path="$1"
    local binary="${home_path}/bin/oracle"
    
    # ❌ Sentinel string on error
    [[ ! -x "${binary}" ]] && { echo "ERR"; return 1; }
    
    # ❌ Sentinel string for unknown
    version=$(extract_version "${binary}") || { echo "unknown"; return 1; }
    
    echo "${version}"
    return 0
}

# ❌ Caller must check for sentinel strings
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
    echo "Version: ${version}"
fi
```

#### After (Compliant)

```bash
plugin_get_version() {
    local home_path="$1"
    local binary="${home_path}/bin/oracle"
    local version
    
    # ✅ Exit code for unavailable
    [[ ! -x "${binary}" ]] && return 2
    
    # ✅ Exit code for command failure
    version=$(extract_version "${binary}") || return 2
    
    # ✅ Exit code for not applicable
    [[ -z "${version}" ]] && return 1
    
    # ✅ Clean data on success
    echo "${version}"
    return 0
}

# ✅ Caller uses exit code
if version=$(plugin_get_version "${home}"); then
    echo "Version: ${version}"
else
    case $? in
        1) oradba_log DEBUG "Version not applicable" ;;
        2) oradba_log WARN "Version detection failed" ;;
    esac
fi
```

### Example: Status Checking

#### Before (Non-Compliant)

```bash
plugin_check_status() {
    local home="$1"
    
    # ❌ Returns "unknown" sentinel
    if ! pgrep -f "process_name" >/dev/null; then
        echo "unknown"
        return 1
    fi
    
    echo "running"
    return 0
}

# ❌ Caller checks string
status=$(plugin_check_status "${home}")
if [[ "${status}" == "unknown" ]]; then
    echo "Status unknown"
fi
```

#### After (Compliant)

```bash
plugin_check_status() {
    local home="$1"
    
    # ✅ Check if binary exists first
    [[ ! -x "${home}/bin/process" ]] && {
        echo "unavailable"
        return 2
    }
    
    # ✅ Clean status strings + appropriate exit codes
    if pgrep -f "process_name" >/dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

# ✅ Caller uses exit code
if ! status=$(plugin_check_status "${home}"); then
    exit_code=$?
    if [[ ${exit_code} -eq 2 ]]; then
        oradba_log WARN "Service unavailable"
    else
        oradba_log DEBUG "Service stopped"
    fi
fi
```

### Example: Metadata Extraction

#### Before (Non-Compliant)

```bash
plugin_get_metadata() {
    local home="$1"
    
    # ❌ Mixing data and errors on stdout
    echo "version=$(get_version || echo 'ERR')"
    echo "edition=$(get_edition || echo 'N/A')"
    echo "ERROR: Could not determine patch level"
    
    return 0
}
```

#### After (Compliant)

```bash
plugin_get_metadata() {
    local home="$1"
    local version edition
    
    # ✅ Handle errors via exit code
    if ! version=$(get_version "${home}"); then
        oradba_log DEBUG "Version detection failed" >&2
        version="unknown"
    fi
    
    if ! edition=$(get_edition "${home}"); then
        oradba_log DEBUG "Edition detection failed" >&2
        edition="unknown"
    fi
    
    # ✅ Clean data only on stdout
    echo "version=${version}"
    echo "edition=${edition}"
    
    # ✅ Optional fields can be omitted (not "N/A")
    # echo "patchlevel=N/A"  # DON'T DO THIS
    
    return 0
}
```

### Migration Checklist

When updating existing plugins:

- [ ] Replace sentinel strings with exit codes
- [ ] Move error messages from stdout to stderr
- [ ] Update callers to check exit codes instead of output strings
- [ ] Add proper exit code handling (0/1/2)
- [ ] Document exit codes in function headers
- [ ] Update tests to verify exit codes
- [ ] Remove string comparisons for error detection
- [ ] Ensure empty output is valid (when appropriate)

---

## References

- **Plugin Interface**: [plugin_interface.sh](plugin_interface.sh) - Interface specification and template
- **Plugin Development**: [../../doc/plugin-development.md](../../doc/plugin-development.md) - Comprehensive development guide
- **Database Plugin**: [database_plugin.sh](database_plugin.sh) - Reference implementation
- **Testing**: [../../tests/test_plugin_interface.bats](../../tests/test_plugin_interface.bats) - Interface compliance tests
- **Architecture**: [../../doc/architecture.md](../../doc/architecture.md) - System architecture overview

---

## Revision History

| Version | Date | Description |
|---------|------|-------------|
| v1.0.0 | 2026-01-29 | Initial plugin standards documentation |

---

**For questions or clarifications**, open an issue in the OraDBA repository.
