# OraDBA Plugin Standards

<<<<<<< HEAD
**Version:** 1.0.0  
**Last Updated:** January 2026  
**Status:** Active

## Table of Contents

- [Introduction](#introduction)
- [Core Plugin Functions](#core-plugin-functions)
- [Return Value Standards](#return-value-standards)
- [Optional Functions and Extension Patterns](#optional-functions-and-extension-patterns)
- [Function Templates](#function-templates)
- [Interface Versioning](#interface-versioning)
- [Testing Requirements](#testing-requirements)
- [Best Practices](#best-practices)
- [Migration from Non-Compliant Code](#migration-from-non-compliant-code)
=======
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
>>>>>>> origin/main

## Introduction

### Purpose

<<<<<<< HEAD
This document formalizes the OraDBA plugin interface specification. It defines:

- **Required plugin functions**: The 11 core functions every plugin MUST implement
- **Return value conventions**: Exit codes and stdout standards
- **Extension patterns**: How to add optional/complex features
- **Testing requirements**: What must be tested
- **Best practices**: How to write maintainable, compliant plugins

### Relationship to Plugin Interface

This document is the **specification** for the plugin interface defined in `plugin_interface.sh`.
The interface file provides the template implementation, while this document explains the "why"
and "how" of each function.

**Key files:**

- `plugin_interface.sh` - Template with function signatures and default implementations
- `plugin-standards.md` - **This document** - Specification and standards
- `plugin-development.md` - Developer guide for creating new plugins

### When to Reference This Document

- **Creating a new plugin**: Start here to understand requirements
- **Modifying existing plugins**: Ensure changes remain compliant
- **Code review**: Verify plugin implementations follow standards
- **Debugging**: Understand expected behavior and return values
- **Proposing interface changes**: Breaking changes require version bump

## Core Plugin Functions

Every plugin MUST implement these 11 required functions. All functions must follow the return
value standards defined in this document.

### Function Summary Table

| # | Function Name | Purpose | Exit Codes | Required |
| --- | --- | --- | --- | --- |
=======
This document formalizes the OraDBA plugin interface specification (v1.0.0) and establishes standards
for plugin development. It serves as:

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
| --- | --------------- | --------- | ------------ | ---------- |
>>>>>>> origin/main
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

<<<<<<< HEAD
### Detailed Function Descriptions

#### 1. plugin_detect_installation

**Purpose:** Auto-discover installations of this product type on the system.

**Usage:** Called during initial setup or when scanning for new installations.

**Exit Codes:**

- `0` - Success, installations found (or none found - both valid)

**Output Format:**

- One installation path per line
- Paths should be absolute
- Empty output with exit 0 is valid (no installations found)

**Notes:**

- Check running processes (e.g., pmon for database, cmctl for DataSafe)
- Scan common installation locations
- Check process environment variables
- Deduplicate results before output

#### 2. plugin_validate_home

**Purpose:** Validate that a given path is a valid ORACLE_HOME for this product type.

**Usage:** Called when adding new Oracle Homes or validating configuration.

**Exit Codes:**

- `0` - Path is valid for this product
- `1` - Path is invalid or not this product type

**Output Format:**

- No output (validation is boolean)

**Notes:**

- Check for product-specific binaries
- Verify required directory structure
- Don't assume path exists - check first
- Be specific: distinguish between similar products (client vs database)

#### 3. plugin_adjust_environment

**Purpose:** Adjust ORACLE_HOME path for product-specific requirements.

**Usage:** Called when setting up environment variables.

**Exit Codes:**

- `0` - Success

**Output Format:**

- Single line: adjusted ORACLE_HOME path

**Notes:**

- Most products return path unchanged
- DataSafe appends `/oracle_cman_home` subdirectory
- Output must be a valid filesystem path
- Don't validate existence - just transform path

#### 4. plugin_check_status

**Purpose:** Check if product instance/service is currently running.

**Exit Codes:**

- `0` - Running/active
- `1` - Stopped/inactive
- `2` - Unavailable (binary missing, command failed)

**Output Format:**

- Single word: `running`, `stopped`, or `unavailable`

**Notes:**

- Use explicit environment (don't rely on shell environment)
- Check actual service status, not just binary existence
- Timeout commands appropriately (avoid hangs)
- Handle missing binaries gracefully (return 2)

#### 5. plugin_get_metadata

**Purpose:** Get product metadata (version, edition, features, etc.).

**Exit Codes:**

- `0` - Success
- `1` - Metadata not applicable
- `2` - Metadata extraction failed

**Output Format:**

- Key=value pairs, one per line
- Standard keys: `version`, `edition`, `patchlevel`
- Custom keys allowed (product-specific)

#### Example

```text

version=19.21.0.0.0
edition=Enterprise
patchlevel=221018

```

**Notes:**

- Call `plugin_get_version()` if available
- Return minimal metadata if full extraction fails
- Don't error on missing optional metadata

#### 6. plugin_should_show_listener

**Purpose:** Determine if this product's TNS listener should appear in listener sections.

**Exit Codes:**

- `0` - Show listener (database products)
- `1` - Don't show listener (other products using tnslsnr)

**Output Format:**

- No output (boolean return code only)

**Notes:**

- Database listeners: return 0
- DataSafe connectors: return 1 (use tnslsnr but aren't DB listeners)
- Most non-database products: return 1

#### 7. plugin_discover_instances

**Purpose:** Discover all instances/services for this Oracle Home.

**Exit Codes:**

- `0` - Success (instances found or none - both valid)

**Output Format:**

- One instance per line
- Format: `instance_name|status|additional_metadata`
- Empty output with exit 0 is valid (no instances)

**Notes:**

- Handles 1:many relationships (RAC, WebLogic domains, OUD instances)
- Single-instance products can return empty or single entry
- Status field should match `plugin_check_status` output

#### 8. plugin_supports_aliases

**Purpose:** Indicate whether this product supports SID-like aliases.

**Exit Codes:**

- `0` - Supports aliases (like database SIDs)
- `1` - Does not support aliases

**Output Format:**

- No output (boolean return code only)

**Notes:**

- Database products: return 0
- Most other products: return 1
- Affects alias generation and environment switching

#### 9. plugin_build_path

**Purpose:** Get PATH components to add for this product.

**Exit Codes:**

- `0` - Success
- `1` - Build failed (fallback to default)

**Output Format:**

- Colon-separated list of directories
- Example: `/u01/app/oracle/product/19/bin:/u01/app/oracle/product/19/OPatch`

**Notes:**

- Don't validate directory existence
- Instant Client: return ORACLE_HOME directly (no bin subdirectory)
- Database: typically `${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch`
- DataSafe: use adjusted path (oracle_cman_home)

#### 10. plugin_build_lib_path

**Purpose:** Get LD_LIBRARY_PATH components to add for this product.

**Exit Codes:**

- `0` - Success
- `1` - Build failed (fallback to default)

**Output Format:**

- Colon-separated list of library directories
- Example: `/u01/app/oracle/product/19/lib`

**Notes:**

- Don't validate directory existence
- Database: typically `${ORACLE_HOME}/lib`
- Instant Client: return ORACLE_HOME directly
- May include multiple directories (lib, lib32, etc.)

#### 11. plugin_get_config_section

**Purpose:** Get the configuration section name for this product.

**Exit Codes:**

- `0` - Success

**Output Format:**

- Single line: uppercase section name
- Example: `RDBMS`, `DATASAFE`, `CLIENT`, `ICLIENT`, `OUD`, `WLS`

**Notes:**

- Used by `oradba_apply_product_config()` to load settings
- Convention: uppercase product identifier
- Must match section names in oradba_standard.conf

## Return Value Standards

### Exit Code Standards

**All plugin functions MUST follow these conventions:**

| Exit Code | Meaning | When to Use |
| ----------- | --------- | ------------- |
| **0** | Success | Function completed successfully, valid data on stdout |
| **1** | Expected failure | Operation not applicable, service stopped, feature not available |
| **2** | Unavailable | Binary missing, command failed, resource not accessible |
| **3+** | Reserved | Reserved for future use (document if used in custom plugins) |

**Critical Rules:**

1. **Exit 0 = Success**: Function worked, data (if any) is valid
2. **Exit 1 = Expected Failure**: Not an error, just not applicable/available
3. **Exit 2 = True Failure**: Something went wrong (missing binary, command error)
4. **Caller checks exit code**: Never check stdout for "ERR" or "unknown"

### Stdout Standards

**Rules:**

1. ❌ **NEVER** echo sentinel strings: `"ERR"`, `"unknown"`, `"N/A"`, `"Not Applicable"`
2. ✅ **Echo clean data only**: Real values, never error indicators
3. ✅ **Empty output + exit 0**: Valid empty result
4. ✅ **Empty output + exit 1**: Expected failure (not applicable)
5. ✅ **Stderr for logging**: Use stderr for debug/log messages (not stdout)

**Why No Sentinel Strings?**

Sentinel strings create fragile code:
=======
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

```text
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

 **Format**: `instance_name | status | additional_metadata`

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
| ----------- | --------- | ------- |
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
>>>>>>> origin/main

```bash
# ❌ WRONG: Fragile string checking
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
<<<<<<< HEAD
    # What if version is "ERR123" or "unknown-version"?
    # Fragile and error-prone!
fi

```

```bash
# ✅ CORRECT: Robust exit code checking
if version=$(plugin_get_version "${home}"); then
    echo "Version: ${version}"
    # ${version} is guaranteed to be valid
else
    case $? in
        1) echo "Version not applicable" ;;
        2) echo "Version detection failed" ;;
    esac
fi

```

### Standard Patterns

#### Pattern 1: Simple Success/Failure

```bash

plugin_function() {
    local arg="$1"
    
    # Validate input
    [[ -z "${arg}" ]] && return 1
    
    # Do work
    local result
    result=$(do_something "${arg}") || return 2
    
    # Return result
    echo "${result}"
    return 0
}

```

#### Pattern 2: Conditional Output

```bash

plugin_function() {
    local arg="$1"
    
    # Check if applicable
    [[ ! -f "${arg}/indicator" ]] && return 1  # Not applicable
    
    # Try to get data
    local data
    data=$(extract_data "${arg}") || return 2  # Extraction failed
    
    # Check if data is valid
    [[ -z "${data}" ]] && return 1  # No data (expected)
    
    # Return valid data
    echo "${data}"
    return 0
}

```

#### Pattern 3: Multiple Exit Points

```bash

plugin_function() {
    local home_path="$1"
    local binary="${home_path}/bin/tool"
    
    # Binary missing - unavailable
    [[ ! -x "${binary}" ]] && return 2
    
    # Try method 1
    local result
    if result=$("${binary}" --version 2>/dev/null); then
        echo "${result}"
        return 0
    fi
    
    # Method 1 failed, try method 2
    if result=$("${binary}" version 2>/dev/null); then
        echo "${result}"
        return 0
    fi
    
    # No method worked - not applicable
    return 1
}

```

### Testing Return Values

Test both exit codes AND output:

```bash
# Test success case
@test "function returns version successfully" {
    run plugin_get_version "${test_home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^[0-9]+\. ]]  # Looks like version
}

# Test not applicable case
@test "function returns 1 when version not available" {
    run plugin_get_version "${empty_home}"
    [ "$status" -eq 1 ]
    [ -z "$output" ]  # No output expected
}

# Test failure case
@test "function returns 2 when binary missing" {
    run plugin_get_version "${invalid_home}"
    [ "$status" -eq 2 ]
    [ -z "$output" ]  # No output expected
}

```

## Optional Functions and Extension Patterns

### Optional Functions

Plugins MAY implement additional functions beyond the 11 core functions for product-specific features.

#### Common Optional Functions

| Function | Purpose | Usage | Exit Codes |
| ---------- | --------- | ------- | ------------ |
| `plugin_get_version` | Extract product version | Called by `plugin_get_metadata` | 0=success, 1=N/A, 2=failed |
| `plugin_get_required_binaries` | List required binaries | Used by validators | 0=success |
| `plugin_get_display_name` | Custom display name | Override default naming | 0=success |

#### Example plugin_get_version

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Extract product version from installation
# Args....: $1 - ORACLE_HOME path
# Returns.: 0=success, 1=not applicable, 2=extraction failed
# Output..: Version string (e.g., "19.21.0.0.0")
# ------------------------------------------------------------------------------
=======
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
>>>>>>> origin/main
plugin_get_version() {
    local home_path="$1"
    local version
    
<<<<<<< HEAD
    # Try version file
    if [[ -f "${home_path}/inventory/ContentsXML/comps.xml" ]]; then
        version=$(grep -oP 'VER="\K[^"]+' "${home_path}/inventory/ContentsXML/comps.xml" 2>/dev/null | head -1)
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # Try binary --version
    if [[ -x "${home_path}/bin/product_binary" ]]; then
        version=$("${home_path}/bin/product_binary" --version 2>/dev/null | head -1)
        if [[ -n "${version}" ]]; then
            echo "${version}"
            return 0
        fi
    fi
    
    # No version available
    return 1
}

```

### Product-Specific Extensions

For features unique to a product, use descriptive function names.

**Naming Convention:** `plugin_<product>_<function_name>`

#### Examples
=======
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
| ---------- | --------- | ------- |
| `plugin_get_version` | Extract product version | Common across most plugins |
| `plugin_get_required_binaries` | List required binaries | Used by validators |
| `plugin_get_display_name` | Custom display name | Override default naming |

### Product-Specific Extensions

**Naming Convention**: `plugin_<product>_<function_name>`

**Examples**:
>>>>>>> origin/main

- `plugin_database_get_pdb_status` - Database-specific: PDB status
- `plugin_database_check_rac` - Database-specific: RAC configuration
- `plugin_datasafe_get_connector_config` - DataSafe-specific: connector config
<<<<<<< HEAD
- `plugin_weblogic_list_domains` - WebLogic-specific: domain discovery

### Extension Implementation Patterns

#### Pattern 1: Simple Extensions (In Plugin File)

For **1-3 optional functions** with **<50 lines total**, add directly to the main plugin file.

**Structure:**

```bash
#!/usr/bin/env bash
# product_plugin.sh

export plugin_name="product"
export plugin_version="1.0.0"
export plugin_description="Product description"

# ------------------------------------------------------------------------------
# Core Functions (11 Required)
# ------------------------------------------------------------------------------
=======

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
>>>>>>> origin/main

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

<<<<<<< HEAD
# ------------------------------------------------------------------------------
# Optional Functions (Simple Extensions)
# ------------------------------------------------------------------------------

plugin_get_version() {
    local home_path="$1"
    # Extract version
    echo "${version}"
    return 0
}

plugin_get_required_binaries() {
    echo "binary1 binary2"
    return 0
}

```

**When to use:**

- Small number of optional functions (1-3)
- Simple logic (<50 lines total for all optional functions)
- No complex interdependencies

#### Pattern 2: Complex Extensions (Separate Module)

For **4+ optional functions** OR **complex logic (>100 lines)**, create a separate extension module.

**File Structure:**

```text
src/lib/plugins/
├── product_plugin.sh          # Core functions only (11 required)
├── product_extensions.sh      # Optional complex features
└── ...
```

**Main Plugin (product_plugin.sh):**

```bash
#!/usr/bin/env bash
# product_plugin.sh - Core plugin implementation

export plugin_name="product"
export plugin_version="1.0.0"
export plugin_description="Product plugin"

# ------------------------------------------------------------------------------
# Core Functions (11 Required)
# ------------------------------------------------------------------------------
=======
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

```text
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
>>>>>>> origin/main

plugin_detect_installation() { ... }
plugin_validate_home() { ... }
# ... other 9 core functions ...

<<<<<<< HEAD
# ------------------------------------------------------------------------------
# Load Optional Extensions
# ------------------------------------------------------------------------------

# Load extension module if available
if [[ -f "${ORADBA_BASE}/lib/plugins/product_extensions.sh" ]]; then
    # shellcheck source=/dev/null
    source "${ORADBA_BASE}/lib/plugins/product_extensions.sh"
fi

```

**Extension Module (product_extensions.sh):**
=======
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
>>>>>>> origin/main

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
<<<<<<< HEAD
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: product_extensions.sh
# Author...: Your Name
# Date.....: YYYY.MM.DD
# Version..: 1.0.0
# Purpose..: Optional extensions for Product plugin
# Notes....: Provides optional product-specific functionality
#            This module is loaded by product_plugin.sh if present
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Optional Common Functions
# ------------------------------------------------------------------------------
=======
# OraDBA - Database Plugin Extensions
# Purpose.: Provides optional database-specific functionality
# Notes...: Loaded by database_plugin.sh if present
# ------------------------------------------------------------------------------

# ============================================================================
# Optional Helper Functions
# ============================================================================
>>>>>>> origin/main

plugin_get_version() {
    local home_path="$1"
    # Complex version extraction logic
<<<<<<< HEAD
    # ... 30+ lines ...
    return 0
}

# ------------------------------------------------------------------------------
# Product-Specific Extensions
# ------------------------------------------------------------------------------

plugin_product_check_advanced_feature() {
    local home_path="$1"
    local feature="$2"
    
    # Complex feature checking
    # ... 50+ lines ...
    return 0
}

plugin_product_get_configuration() {
    local home_path="$1"
    
    # Complex configuration parsing
    # ... 40+ lines ...
    return 0
}

plugin_product_discover_subsystems() {
    local home_path="$1"
    
    # Complex subsystem discovery
    # ... 60+ lines ...
    return 0
}

```

**Benefits of Separation:**

- ✅ Core plugin stays focused (11 functions, ~300-500 lines)
=======
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
>>>>>>> origin/main
- ✅ Optional features don't bloat core
- ✅ Extensions can evolve independently
- ✅ Clear separation of required vs. optional
- ✅ Easier to maintain and debug
<<<<<<< HEAD
- ✅ Optional features can be disabled by not loading extension
- ✅ Simpler testing (test core separately from extensions)

**When to Use:**

| Scenario | Simple (In-Plugin) | Complex (Separate Module) |
| ---------- | ------------------- | --------------------------- |
| Number of optional functions | 1-3 | 4+ |
| Lines of optional code | <50 | >100 |
| Complexity | Simple logic | Complex algorithms |
| Dependencies | Self-contained | Multiple helper functions |
| Maintenance | Rarely changes | Evolves frequently |

#### Example Database Plugin Extensions

If database plugin needed extensive PDB management:

```bash
# database_plugin.sh - Core functions only (~400 lines)
# database_extensions.sh - PDB/RAC features (~300 lines)
#   - plugin_database_get_pdb_status()
#   - plugin_database_list_pdbs()
#   - plugin_database_check_rac()
#   - plugin_database_get_asm_diskgroups()
#   - plugin_database_check_dataguard()

```

## Function Templates

Use these templates when implementing plugin functions. Copy the appropriate template and adapt for your product.

=======

**When to Use Each Pattern**:

- **In-plugin**: 1-3 simple optional functions (<50 lines total)
- **Separate module**: 4+ optional functions OR complex logic (>100 lines)

---

## Function Templates

>>>>>>> origin/main
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
<<<<<<< HEAD
    # shellcheck disable=SC2009
    while read -r process_line; do
        local pid
        pid=$(echo "${process_line}" | awk '{print $2}')
        if [[ -n "${pid}" ]] && [[ -d "/proc/${pid}" ]]; then
            local home
            home=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | \
 grep '^ORACLE_HOME=' | cut -d= -f2-) 
            if [[ -n "${home}" ]] && [[ -d "${home}" ]]; then
                homes+=("${home}")
            fi
        fi
    done < <(ps -ef | grep "[p]roduct_process_pattern")
    
    # Method 2: Scan common installation directories
    for base_dir in /u01/app/oracle /opt/oracle /usr/local/oracle; do
        if [[ -d "${base_dir}" ]]; then
            while IFS= read -r -d '' home; do
                homes+=("$(dirname "${home}")")
            done < <(find "${base_dir}" -maxdepth 3 -name "product_binary" -type f -print0 2>/dev/null)
        fi
    done
    
    # Deduplicate and output
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}

=======
    # Example: ps -ef | grep "[p]mon_" for databases
    
    # Method 2: Scan common directories
    # Example: find /opt/oracle -name "product_binary"
    
    # Method 3: Check environment variables
    # Example: Parse existing ORACLE_HOME settings
    
    # Deduplicate and print
    printf '%s\n' "${homes[@]}" | sort -u
    return 0
}
>>>>>>> origin/main
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
    
<<<<<<< HEAD
    # Basic path validation
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for product-specific directories
    [[ ! -d "${home_path}/bin" ]] && return 1
    [[ ! -d "${home_path}/lib" ]] && return 1
    
    # Check for required binary
    [[ ! -x "${home_path}/bin/product_binary" ]] && return 1
    
    # Check for product-specific marker
    # Example: specific directory, config file, or library
    [[ ! -f "${home_path}/lib/libproduct.so" ]] && return 1
    
    return 0
}

=======
    # Check directory exists
    [[ ! -d "${home_path}" ]] && return 1
    
    # Check for product-specific markers
    # Examples:
    # - [[ -x "${home_path}/bin/product_binary" ]] || return 1
    # - [[ -d "${home_path}/product_dir" ]] || return 1
    # - [[ -f "${home_path}/lib/product.so" ]] || return 1
    
    return 0
}
>>>>>>> origin/main
```

### Template: plugin_adjust_environment

```bash
# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for product-specific requirements
# Args....: $1 - Original ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME path
<<<<<<< HEAD
# Notes...: Most products return path unchanged
#           DataSafe example: appends /oracle_cman_home
=======
# Notes...: Most products return the path unchanged
#           DataSafe appends /oracle_cman_home
>>>>>>> origin/main
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    
    # Most products: return unchanged
    echo "${home_path}"
<<<<<<< HEAD
    return 0
    
    # DataSafe pattern: append subdirectory
    # if [[ -d "${home_path}/subdirectory" ]]; then
    #     echo "${home_path}/subdirectory"
    # else
    #     echo "${home_path}"
    # fi
    # return 0
}

=======
    
    # DataSafe example:
    # if [[ -d "${home_path}/oracle_cman_home" ]]; then
    #     echo "${home_path}/oracle_cman_home"
    # else
    #     echo "${home_path}"
    # fi
    
    return 0
}
>>>>>>> origin/main
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
    
<<<<<<< HEAD
    # Adjust environment if needed
    local adjusted_home
    adjusted_home=$(plugin_adjust_environment "${home_path}")
    
    # Check if status binary exists
    local status_binary="${adjusted_home}/bin/product_ctl"
    if [[ ! -x "${status_binary}" ]]; then
        echo "unavailable"
        return 2
    fi
    
    # Check status using explicit environment
    local status
    status=$(ORACLE_HOME="${adjusted_home}" \
             LD_LIBRARY_PATH="${adjusted_home}/lib:${LD_LIBRARY_PATH:-}" \
             "${status_binary}" status 2>/dev/null)
    
    # Parse status output
    if echo "${status}" | grep -qiE "running|active|started"; then
        echo "running"
        return 0
    elif echo "${status}" | grep -qiE "stopped|inactive|down"; then
        echo "stopped"
        return 1
    else
        echo "unavailable"
        return 2
    fi
}

=======
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
>>>>>>> origin/main
```

### Template: plugin_get_metadata

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get product metadata (version, features, etc.)
# Args....: $1 - Installation path
<<<<<<< HEAD
# Returns.: 0 on success, 1 if not applicable, 2 if failed
# Output..: Key=value pairs (one per line)
# Notes...: Standard keys: version, edition, patchlevel
=======
# Returns.: 0 on success
# Output..: Key=value pairs (one per line)
# Notes...: Version extraction can use plugin_get_version if implemented
>>>>>>> origin/main
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Get version (use plugin_get_version if available)
    local version="unknown"
<<<<<<< HEAD
    if type plugin_get_version &>/dev/null; then
        if version=$(plugin_get_version "${home_path}"); then
            : # version set successfully
        else
            version="N/A"
        fi
    fi
    
    # Get edition (product-specific)
    local edition="Standard"
    if [[ -f "${home_path}/lib/libserver_enterprise.so" ]]; then
        edition="Enterprise"
    fi
    
    # Get patch level (if applicable)
    local patchlevel="N/A"
    if [[ -x "${home_path}/OPatch/opatch" ]]; then
        patchlevel=$("${home_path}/OPatch/opatch" lspatches 2>/dev/null | head -1 | awk '{print $1}')
    fi
    
    # Output metadata
    echo "version=${version}"
    echo "edition=${edition}"
    [[ "${patchlevel}" != "N/A" ]] && echo "patchlevel=${patchlevel}"
    
    return 0
}

=======
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
>>>>>>> origin/main
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
<<<<<<< HEAD
#           DataSafe connectors: return 1 (they use tnslsnr but aren't DB listeners)
=======
#           DataSafe connectors: return 1
>>>>>>> origin/main
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    local home_path="$1"
    
<<<<<<< HEAD
    # Database products: show listener
    return 0
    
    # Non-database products: don't show listener
    # return 1
}

=======
    # Default: don't show listener (override in product plugins)
    return 1
    
    # Database example:
    # return 0  # Show database listeners
}
>>>>>>> origin/main
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
    
<<<<<<< HEAD
    # Single-instance products: return empty or single instance
    # return 0
    
    # Multi-instance pattern: scan for instances
    local -a instances=()
    
    # Example: Check configuration files
    for config_file in "${home_path}"/config/*.conf; do
        [[ ! -f "${config_file}" ]] && continue
        
        local instance_name
        instance_name=$(basename "${config_file}" .conf)
        
        # Get status
        local status
        if plugin_check_status "${home_path}" "${instance_name}" &>/dev/null; then
            status="running"
        else
            status="stopped"
        fi
        
        # Output instance info
        echo "${instance_name}|${status}|"
    done
    
    return 0
}

=======
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
>>>>>>> origin/main
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
<<<<<<< HEAD
    # Database products: return 0
    return 0
    
    # Non-database products: return 1
    # return 1
}

=======
    # Default: no aliases
    return 1
    
    # Database example:
    # return 0  # Databases support aliases
}
>>>>>>> origin/main
```

### Template: plugin_build_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
<<<<<<< HEAD
# Returns.: 0 on success, 1 if failed
# Output..: Colon-separated PATH components
# Notes...: Don't validate existence - just build path list
=======
# Returns.: 0 on success
# Output..: Colon-separated PATH components
# Notes...: Returns directories to add to PATH
>>>>>>> origin/main
# ------------------------------------------------------------------------------
plugin_build_path() {
    local home_path="$1"
    
<<<<<<< HEAD
    # Adjust environment if needed
    local adjusted_home
    adjusted_home=$(plugin_adjust_environment "${home_path}")
    
    # Standard pattern: bin and OPatch
    echo "${adjusted_home}/bin:${adjusted_home}/OPatch"
    return 0
    
    # Instant Client pattern: no subdirectories
    # echo "${adjusted_home}"
    # return 0
    
    # DataSafe pattern: oracle_cman_home/bin
    # echo "${adjusted_home}/oracle_cman_home/bin"
    # return 0
}

=======
    # Standard pattern: bin and OPatch
    echo "${home_path}/bin:${home_path}/OPatch"
    
    # Instant Client pattern (no bin/):
    # echo "${home_path}"
    
    # DataSafe pattern (oracle_cman_home/bin):
    # echo "${home_path}/bin"
    
    return 0
}
>>>>>>> origin/main
```

### Template: plugin_build_lib_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for this product
# Args....: $1 - ORACLE_HOME path
<<<<<<< HEAD
# Returns.: 0 on success, 1 if failed
# Output..: Colon-separated library path components
# Notes...: Don't validate existence - just build path list
=======
# Returns.: 0 on success
# Output..: Colon-separated library path components
# Notes...: Returns directories containing shared libraries
>>>>>>> origin/main
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    
<<<<<<< HEAD
    # Adjust environment if needed
    local adjusted_home
    adjusted_home=$(plugin_adjust_environment "${home_path}")
    
    # Standard pattern: lib directory
    echo "${adjusted_home}/lib"
    return 0
    
    # Multi-arch pattern: lib and lib32
    # echo "${adjusted_home}/lib:${adjusted_home}/lib32"
    # return 0
    
    # Instant Client pattern: home directory directly
    # echo "${adjusted_home}"
    # return 0
}

=======
    # Standard pattern: lib directory
    echo "${home_path}/lib"
    
    # Instant Client pattern (libraries in root):
    # echo "${home_path}"
    
    # Multiple directories:
    # echo "${home_path}/lib:${home_path}/lib64"
    
    return 0
}
>>>>>>> origin/main
```

### Template: plugin_get_config_section

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for this product
# Args....: None
# Returns.: 0 on success
# Output..: Configuration section name (uppercase)
<<<<<<< HEAD
# Notes...: Used by oradba_apply_product_config() to load product-specific settings
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "PRODUCT"
    return 0
}

```

### Template: plugin_get_required_binaries

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_required_binaries
# Purpose.: Get list of required binaries for this product
# Args....: None
# Returns.: 0 on success
# Output..: Space-separated list of required binary names
# Notes...: Used by oradba_check_oracle_binaries() to validate installation
# ------------------------------------------------------------------------------
plugin_get_required_binaries() {
    echo "product_binary product_ctl"
    return 0
}

```
=======
# Notes...: Used to load product-specific settings from config files
# ------------------------------------------------------------------------------
plugin_get_config_section() {
    echo "MYPRODUCT"
    return 0
}
```

---
>>>>>>> origin/main

## Interface Versioning

### Current Version: v1.0.0

<<<<<<< HEAD
**All plugins MUST declare:**

```bash

export plugin_interface_version="1.0.0"

```

**Note:** Some plugin files may reference "v2.0.0" in comments. This was an accidental internal
reference and should be **ignored**. The official interface version is **v1.0.0**
(established January 2026).

### Version Policy

- **Current version:** v1.0.0 (January 2026)
- **Stability:** Interface is stable, no breaking changes planned
- **Breaking changes require:**
  1. Formal decision and announcement
  2. Migration guide for plugin developers
  3. Compatibility layer during transition period
  4. Deprecation warnings (2-3 release cycles minimum)

### What Constitutes a Breaking Change

Breaking changes that require version bump:

- ❌ Removing a core function
- ❌ Changing function signature (adding/removing parameters)
- ❌ Changing exit code semantics
- ❌ Changing output format for structured data
- ❌ Renaming functions

Non-breaking changes (no version bump needed):

- ✅ Adding new optional functions
- ✅ Adding new parameters with defaults
- ✅ Improving documentation
- ✅ Bug fixes that don't change behavior
- ✅ Performance improvements

### Version Declaration

Include in every plugin file:

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security
# Name.....: product_plugin.sh
# Author...: Your Name
# Date.....: YYYY.MM.DD
# Version..: 1.0.0
# Purpose..: Plugin for Product
# Notes....: Implements plugin interface v1.0.0
# ------------------------------------------------------------------------------

# Plugin Metadata
export plugin_name="product"
export plugin_version="1.0.0"  # Plugin version
export plugin_interface_version="1.0.0"  # Interface version (optional but recommended)
export plugin_description="Product plugin"

```

## Testing Requirements

### Mandatory Tests

All plugins MUST have tests covering:

#### Generic Tests (All Plugins)

1. **Plugin metadata**

   - All 3 metadata variables are set
   - `plugin_name` matches product type
   - Versions follow semantic versioning

2. **Core functions exist**

   - All 11 core functions are defined
   - Functions are callable
   - No syntax errors

3. **Return value conventions**

   - Exit codes match standards (0/1/2)
   - No sentinel strings on stdout
   - Empty output + exit code correlation

4. **Function signatures**

   - Correct number of parameters
   - No hard failures on missing parameters

#### Plugin-Specific Tests

1. **Detection accuracy**

   - `plugin_detect_installation` finds real installations
   - No false positives

2. **Validation correctness**

   - `plugin_validate_home` accepts valid homes
   - `plugin_validate_home` rejects invalid homes
   - Edge cases handled (missing directories, symlinks)

3. **Status checking**

   - `plugin_check_status` returns correct codes
   - Running vs stopped detection works
   - Handles missing binaries gracefully

4. **Path building**

   - `plugin_build_path` returns valid format
   - `plugin_build_lib_path` returns valid format
   - Paths are colon-separated

5. **Optional function behavior**

   - `plugin_get_version` returns valid versions
   - Product-specific extensions work correctly
=======
**All plugins MUST declare the interface version**:

```bash
export plugin_name="myproduct"
export plugin_version="1.0.0"
export plugin_description="My Product plugin"
```

**Note**: The `plugin_version` is the plugin's own version, not the interface version. The interface version
is implicitly v1.0.0 for all plugins implementing the 11 core functions.

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
>>>>>>> origin/main

### Test Organization

```text
tests/
<<<<<<< HEAD
├── test_plugin_interface.bats         # Generic: all plugins comply
=======
├── test_plugin_interface.bats         # Generic: all plugins
>>>>>>> origin/main
├── test_plugin_return_values.bats     # Generic: return conventions
├── test_database_plugin.bats          # Specific: database
├── test_datasafe_plugin.bats          # Specific: datasafe
├── test_client_plugin.bats            # Specific: client
├── test_iclient_plugin.bats           # Specific: instant client
├── test_oud_plugin.bats               # Specific: OUD
└── test_java_plugin.bats              # Specific: Java
```

<<<<<<< HEAD
### Test Template

```bash
#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# Tests for product_plugin.sh
# ------------------------------------------------------------------------------

setup() {
    # Source common functions
    source src/lib/oradba_common.sh
    
    # Source the plugin
    source src/lib/plugins/product_plugin.sh
    
    # Create test directory
    export TEST_HOME="${BATS_TEST_TMPDIR}/product_home"
    mkdir -p "${TEST_HOME}"
}

teardown() {
    rm -rf "${TEST_HOME}"
}

# ==============================================================================
# Metadata Tests
# ==============================================================================

@test "plugin metadata is set correctly" {
    [ -n "${plugin_name}" ]
    [ "${plugin_name}" = "product" ]
    [ -n "${plugin_version}" ]
    [ -n "${plugin_description}" ]
}

# ==============================================================================
# Core Function Tests
# ==============================================================================

@test "plugin_validate_home accepts valid home" {
    # Create mock valid home
    mkdir -p "${TEST_HOME}/bin"
    touch "${TEST_HOME}/bin/product_binary"
    chmod +x "${TEST_HOME}/bin/product_binary"
    
    run plugin_validate_home "${TEST_HOME}"
    [ "$status" -eq 0 ]
}

@test "plugin_validate_home rejects invalid home" {
    run plugin_validate_home "${BATS_TEST_TMPDIR}/nonexistent"
    [ "$status" -eq 1 ]
}

@test "plugin_build_path returns valid format" {
    run plugin_build_path "${TEST_HOME}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ : ]] || [[ "$output" =~ ^/ ]]  # Colon-separated or absolute path
}

@test "plugin_get_config_section returns uppercase" {
    run plugin_get_config_section
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^[A-Z]+$ ]]
}

# ==============================================================================
# Return Value Tests
# ==============================================================================

@test "plugin functions don't output sentinel strings" {
    run plugin_get_version "${TEST_HOME}"
    # If function returns 0, output should not be sentinel
    if [ "$status" -eq 0 ]; then
        [[ "$output" != "ERR" ]]
        [[ "$output" != "unknown" ]]
        [[ "$output" != "N/A" ]]
    fi
}

# Add more tests for each function...

```
=======
### Coverage Requirements

- **Core functions**: 100% coverage (all 11 functions tested)
- **Optional functions**: Test if implemented
- **Error paths**: Test invalid inputs, missing binaries, etc.
- **Edge cases**: Empty directories, permission issues, symlinks
>>>>>>> origin/main

### Running Tests

```bash
# Run all plugin tests
make test-plugins

# Run specific plugin tests
<<<<<<< HEAD
bats tests/test_product_plugin.bats

# Run specific test
bats tests/test_product_plugin.bats -f "validate_home"

# Run with verbose output
bats tests/test_product_plugin.bats --tap

```

=======
bats tests/test_database_plugin.bats

# Run interface compliance tests
bats tests/test_plugin_interface.bats

# Run with verbose output
bats tests/test_database_plugin.bats --tap
```

---

>>>>>>> origin/main
## Best Practices

### DO ✅

<<<<<<< HEAD
1. **Use exit codes for control flow**

   - Caller checks exit code, not output strings
   - Always return appropriate exit code (0/1/2)

2. **Validate all input parameters**

   - Check for empty/null parameters
   - Validate paths exist before using
   - Handle edge cases gracefully

3. **Fail fast and clearly**

   - Return early on errors
   - Don't continue with invalid state
   - Use appropriate exit codes

4. **Document all exit codes**

   - Function header lists all possible exit codes
   - Comments explain when each code is used

5. **Use subshell-safe patterns**

   - Don't modify global state (except PATH/LD_LIBRARY_PATH as designed)
   - Don't rely on caller's environment
   - Use explicit environment variables

6. **Add logging to stderr**

   - Use stderr for debug/log messages
   - Never mix data and logging on stdout
   - Respect ORADBA_LOG_LEVEL

7. **Follow naming conventions**

   - Core functions: `plugin_*`
   - Product extensions: `plugin_<product>_*`
   - Internal helpers: no `plugin_` prefix

8. **Handle missing binaries gracefully**

   - Check binary existence before calling
   - Return exit code 2 for unavailable resources
   - Provide helpful error messages (to stderr)

### DON'T ❌

1. **Don't echo sentinel strings**

   - Never output "ERR", "unknown", "N/A"
   - Use exit codes instead
   - Empty output + exit code is sufficient

2. **Don't modify caller's variables**

   - Don't export unexpected variables
   - Don't unset caller's variables
   - Keep side effects minimal

3. **Don't call oradba_log() directly**

   - Use stderr instead: `echo "message" >&2`
   - Caller controls logging, not plugin
   - Exception: internal plugins (database, datasafe) may use oradba_log

4. **Don't mix data and errors on stdout**

   - Stdout is for data only
   - Stderr is for errors/logging
   - Never output both data and errors

5. **Don't assume dependencies are loaded**

   - Check if functions exist before calling
   - Load required libraries explicitly
   - Handle missing dependencies gracefully

6. **Don't break backward compatibility**

   - Maintain function signatures
   - Keep exit code semantics
   - Version bump required for breaking changes

7. **Don't hardcode paths**

   - Use parameters and configuration
   - Support different installation layouts
   - Make paths configurable

8. **Don't leave debug code**

   - Remove echo statements used for debugging
   - Remove test data generation
   - Clean up temporary files

### Code Quality

1. **Pass shellcheck**

   - No warnings or errors
   - Use `# shellcheck disable=SCXXXX` sparingly with comments

2. **Use consistent formatting**

   - 4 spaces for indentation
   - Function headers with 78-char width
   - Blank lines between sections

3. **Add comprehensive tests**

   - Test all 11 core functions
   - Test edge cases
   - Test error conditions

4. **Document complex logic**

   - Add comments for non-obvious code
   - Explain "why", not "what"
   - Reference external documentation

## Migration from Non-Compliant Code

### Common Anti-Patterns

#### Anti-Pattern 1: Sentinel Strings

**Before (non-compliant):**

```bash

plugin_get_version() {
    local home_path="$1"
    
    # ❌ WRONG: Returns sentinel string
    [[ ! -x "${home_path}/bin/product" ]] && { echo "ERR"; return 1; }
    
    local version
    version=$("${home_path}/bin/product" --version)
    if [[ -z "${version}" ]]; then
        echo "unknown"
        return 1
    fi
=======
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
>>>>>>> origin/main
    
    echo "${version}"
    return 0
}

<<<<<<< HEAD
# Caller must check for sentinels
=======
# ❌ Caller must check for sentinel strings
>>>>>>> origin/main
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
    echo "Version: ${version}"
fi
<<<<<<< HEAD

```

**After (compliant):**

```bash

plugin_get_version() {
    local home_path="$1"
    local version
    
    # ✅ CORRECT: Return appropriate exit code
    [[ ! -x "${home_path}/bin/product" ]] && return 2  # Unavailable
    
    version=$("${home_path}/bin/product" --version 2>/dev/null) || return 2
    [[ -z "${version}" ]] && return 1  # Not applicable
    
    echo "${version}"  # Clean data only
    return 0
}

# Caller checks exit code only
=======
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
>>>>>>> origin/main
if version=$(plugin_get_version "${home}"); then
    echo "Version: ${version}"
else
    case $? in
<<<<<<< HEAD
        1) echo "Version not applicable" ;;
        2) echo "Version detection failed" ;;
    esac
fi

```

#### Anti-Pattern 2: Global State Modification

**Before (non-compliant):**

```bash

plugin_setup_environment() {
    # ❌ WRONG: Modifies global state unexpectedly
    export PRODUCT_CONFIG="${ORACLE_HOME}/config"
    export PRODUCT_MODE="production"
    unset OLD_VARIABLE
}

```

**After (compliant):**

```bash

plugin_get_config_path() {
    local home_path="$1"
    
    # ✅ CORRECT: Returns data, doesn't export
    echo "${home_path}/config"
    return 0
}

# Caller decides whether to export
PRODUCT_CONFIG=$(plugin_get_config_path "${ORACLE_HOME}")
export PRODUCT_CONFIG

```

#### Anti-Pattern 3: Mixing Output Types

**Before (non-compliant):**

```bash

plugin_check_status() {
    local home_path="$1"
    
    # ❌ WRONG: Mixes data and log messages on stdout
    echo "Checking status of ${home_path}..."
    
    if pgrep -f "product_process" >/dev/null; then
        echo "Status: running"
        return 0
    else
        echo "Status: stopped"
        return 1
    fi
}

```

**After (compliant):**

```bash

plugin_check_status() {
    local home_path="$1"
    
    # ✅ CORRECT: Logs to stderr, data to stdout
    echo "Checking status of ${home_path}..." >&2
    
    if pgrep -f "product_process" >/dev/null; then
        echo "running"  # Clean data only
=======
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
>>>>>>> origin/main
        return 0
    else
        echo "stopped"
        return 1
    fi
}

<<<<<<< HEAD
```

#### Anti-Pattern 4: Assuming Dependencies

**Before (non-compliant):**

```bash

plugin_get_info() {
    # ❌ WRONG: Assumes helper_function exists
    local info
    info=$(helper_function "${1}")
    echo "${info}"
    return 0
}

```

**After (compliant):**

```bash

plugin_get_info() {
    local home_path="$1"
    local info
    
    # ✅ CORRECT: Checks if function exists
    if type helper_function &>/dev/null; then
        info=$(helper_function "${home_path}")
    else
        # Fallback or direct implementation
        info=$(direct_method "${home_path}")
    fi
    
    echo "${info}"
    return 0
}

=======
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
>>>>>>> origin/main
```

### Migration Checklist

<<<<<<< HEAD
When updating a plugin to comply with standards:

- [ ] Remove all sentinel strings ("ERR", "unknown", "N/A")
- [ ] Update exit codes to standard conventions (0/1/2)
- [ ] Separate stdout (data) from stderr (logging)
- [ ] Add function headers for all 11 core functions
- [ ] Validate all input parameters
- [ ] Remove global state modifications
- [ ] Add error handling for missing binaries
- [ ] Update tests to check exit codes, not output strings
- [ ] Run shellcheck and fix warnings
- [ ] Test with real Oracle installations

### Testing Migration

Update tests to check exit codes:

**Before (non-compliant):**

```bash

@test "plugin_get_version returns version" {
    run plugin_get_version "${home}"
    [[ "$output" != "ERR" ]]
    [[ "$output" != "unknown" ]]
}

```

**After (compliant):**

```bash

@test "plugin_get_version returns version successfully" {
    run plugin_get_version "${home}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "plugin_get_version returns 1 when not applicable" {
    run plugin_get_version "${empty_home}"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "plugin_get_version returns 2 when unavailable" {
    run plugin_get_version "${invalid_home}"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
}

```

---

## Document History

| Version | Date | Changes |
| --------- | ------ | --------- |
| 1.0.0 | January 2026 | Initial release - formalized plugin standards |

## References

- **Plugin Interface**: `src/lib/plugins/plugin_interface.sh` - Template implementation
- **Plugin Development Guide**: `doc/plugin-development.md` - Developer guide
- **Architecture Documentation**: `doc/architecture.md` - System architecture
- **Example Plugins**: `src/lib/plugins/*_plugin.sh` - Reference implementations

## Support

For questions or issues:

1. Review this document and plugin-development.md
2. Check example plugins for patterns
3. Review plugin tests for usage examples
4. Open an issue for clarifications or suggestions
=======
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
- **Plugin Development**: [../../doc/plugin-development.md](../../doc/plugin-development.md) -
  Comprehensive development guide
- **Database Plugin**: [database_plugin.sh](database_plugin.sh) - Reference implementation
- **Testing**: [../../tests/test_plugin_interface.bats](../../tests/test_plugin_interface.bats) - Interface compliance tests
- **Architecture**: [../../doc/architecture.md](../../doc/architecture.md) - System architecture overview

---

## Revision History

| Version | Date | Description |
| --------- | ------ | ------------- |
| v1.0.0 | 2026-01-29 | Initial plugin standards documentation |

---

**For questions or clarifications**, open an issue in the OraDBA repository.
>>>>>>> origin/main
