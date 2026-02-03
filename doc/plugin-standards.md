# OraDBA Plugin Standards

**Version:** 1.0.0  
**Last Updated:** January 2026  
**Status:** Active

## Recent Changes

### January 2026 - Phase 2.5 Interface Documentation Refinement (Issue #142)

Comprehensive review and documentation refinement of plugin interface conventions:

- ✅ Clarified function count structure: 13 universal + 2 category-specific = 15 mandatory for database products
- ✅ Enhanced extension function naming conventions and patterns
- ✅ Updated category-specific function documentation for clarity
- ✅ Added interface versioning and evolution guidelines
- ✅ Improved test coverage for category-specific requirements
- ✅ 100% backward compatible - no breaking changes

See `.github/.scratch/plugin-interface-analysis.md` for detailed review findings.

### January 2026 - Phase 2.5 Complete Sentinel String Removal (Issue #142)

All plugins updated to fully remove sentinel strings from ALL output functions:

- ✅ All sentinel strings ("ERR", "unknown", "N/A") removed from plugin_get_metadata output
- ✅ When version is unavailable, the version key-value pair is omitted entirely
- ✅ Exit codes remain the definitive status indicator (0=success, 1=N/A, 2=error)
- ✅ All 9 plugins (6 production + 3 stubs) updated to new standard
- ✅ Experimental plugin exclusion: plugins with `plugin_status="EXPERIMENTAL"` are automatically skipped
- ✅ Test infrastructure updated: experimental tests skipped by default, run with `ORADBA_TEST_EXPERIMENTAL=true`

### January 2026 - Phase 2.4 Completion (Issue #141)

All 9 plugins have been audited for comprehensive return value standardization:

- ✅ All sentinel strings removed from all plugin functions
- ✅ Stub plugins (weblogic, emagent, oms) fixed: `plugin_check_status()` now outputs "unavailable" with exit 2
- ✅ All 9 plugins across 13+ core functions confirmed compliant with return value standards
- ✅ Phase 2 (Return Value Standardization) complete and validated
- ✅ No critical issues remain; codebase ready for Phase 3 (Subshell Isolation)

See `.github/.scratch/phase-2-4-audit-report.md` for detailed audit findings.

### January 2026 - Phase 2.1 Refactoring (Issue #135)

All plugins have been standardized to conform to the exit code contract for `plugin_get_version()`:

- ✅ All sentinel strings ("ERR", "unknown", "N/A") removed from plugin_get_version output
- ✅ Exit codes standardized: 0=success with clean version, 1=N/A, 2=error
- ✅ All 9 plugins (6 production + 3 stubs) updated to new contract
- ✅ Tests updated to validate exit codes instead of sentinel strings

See [Migration from Non-Compliant Code](#migration-from-non-compliant-code) for before/after examples.

## Table of Contents

- [Introduction](#introduction)
- [Core Plugin Functions](#core-plugin-functions)
- [Return Value Standards](#return-value-standards)
- [Subshell Execution Model](#subshell-execution-model)
- [Optional Functions and Extension Patterns](#optional-functions-and-extension-patterns)
- [Function Templates](#function-templates)
- [Interface Versioning](#interface-versioning)
- [Testing Requirements](#testing-requirements)
- [Best Practices](#best-practices)
- [Migration from Non-Compliant Code](#migration-from-non-compliant-code)

## Introduction

### Purpose

This document formalizes the OraDBA plugin interface specification. It defines:

- **Required plugin functions**: The universal core functions every plugin MUST
  implement, plus category-specific functions where applicable
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

### Experimental Plugins

Plugins marked with `plugin_status="EXPERIMENTAL"` are excluded from production use:

- **Automatic Exclusion**: Plugin loader functions (`execute_plugin_function_v2` and 
  `oradba_apply_oracle_plugin`) automatically skip experimental plugins with a warning
- **Testing**: Experimental plugin tests are skipped by default; enable with 
  `ORADBA_TEST_EXPERIMENTAL=true` environment variable
- **Use Cases**: Stub implementations, beta features, or incomplete plugins under development
- **Current Experimental Plugins**: `weblogic`, `emagent`, `oms`
- **Production Plugins**: `database`, `datasafe`, `client`, `iclient`, `oud`, `java`

**When developing experimental plugins:**
1. Set `export plugin_status="EXPERIMENTAL"` in plugin metadata
2. Mark purpose as stub/beta in description: `"Product Name (EXPERIMENTAL STUB)"`
3. Tests will be skipped in CI/CD unless explicitly enabled
4. Plugin functions will not execute in production environments

## Product Types and Categories

Oracle products share common concepts (installations with an `ORACLE_HOME`) but
have category-specific needs. Plugins must respect these differences so that
discovery, environment building, and status logic remain accurate.

### Cross-Cutting Expectations

- Always treat each installation (`ORACLE_HOME`) independently; multiple installations can coexist on a host.
- Support multiple instances/domains per installation where applicable; handle each instance separately.
- If `ORACLE_HOME` differs from the actual installation path, use `ORACLE_BASE_HOME`
  to point to the real base and adjust `ORACLE_HOME` accordingly.
- Environment variables such as `PATH`, `LD_LIBRARY_PATH`, `CLASSPATH`, and product
  identifiers (`ORACLE_SID` for databases or equivalent IDs for other products) must
  be set per product type and per instance.
- When invoking commands as another user (e.g., `oracle`), construct the environment
  explicitly for the target user before running commands.
- Provide clear error messages when required environment variables or configuration
  files are missing or misconfigured.

### Database (RDBMS, etc.)

- Focused on Oracle Database (not MySQL/NoSQL).
- Instances are defined in `oratab` with format `<ORACLE_SID>:<ORACLE_HOME>:<Y|N|D>` where `D` marks dummy installs.
- One installation can host multiple database instances in various states (started, stopped, mounted, nomount, etc.).
- Listener management is tied to an Oracle Home, not a single database; listener status is required.

### Middleware (WebLogic, Unified Directory, etc.)

- Multiple domains/instances can run under one installation.
- Unified Directory can run standalone or with WebLogic/ODSM.
- Clarify per-product how to enumerate domains/instances because `oratab` is database-only.
- Environment variables and domain layout are product-specific.

### Special Cases (Data Safe On-Premises Connector)

- Single service per installation (1:1 relationship between software and connector service).
- Requires registration with OCI Data Safe; treat as its own category with middleware-like layout but dedicated status handling.

### Pure Client / Software-Only (Oracle Client, Instant Client, JDK, etc.)

- Software-only; no server component.
- Provide version/environment/path details; no listener/instance management.
- Often dependencies for other categories (e.g., Java runtime for middleware).

### Not Yet Defined / Other Product Types

- Examples: Grid Infrastructure, Oracle Enterprise Manager Agent/Cloud Control, future products.
- Document open questions for category-specific environment variables and aliases before adding plugins.

### Stub/Experimental Plugins

**Status Classification:**

Plugins can be in different stages of maturity:

1. **Production Plugins** - Fully implemented and tested
   - Examples: database, datasafe, client, iclient, oud, java
   - Complete implementation of all mandatory functions
   - Comprehensive test coverage
   - Production-ready status checks and operations

2. **Experimental/Stub Plugins** - Limited or placeholder implementation
   - Examples: weblogic, emagent, oms
   - Minimal viable implementation
   - Basic validation and structure only
   - Not recommended for production use
   - Marked with `plugin_status="EXPERIMENTAL"`

**Experimental Plugin Requirements:**

All experimental/stub plugins MUST:

- Include `plugin_status="EXPERIMENTAL"` in metadata
- Clearly indicate experimental status in plugin_description
- Implement all 13 universal core functions (even if minimal/stub)
- Return appropriate exit codes (typically 1 for N/A features)
- Document limitations in plugin header comments

**Testing Experimental Plugins:**

Test files for experimental plugins should use skip patterns to avoid false failures:

```bash
@test "experimental plugin - basic loading" {
    # Test basic functionality that works
    source "${plugin_file}"
    [ "$status" -eq 0 ]
}

@test "experimental plugin - advanced feature" {
    skip "EXPERIMENTAL: Feature not yet implemented"
    # Test code here
}
```

**Migration Path:**

When an experimental plugin is fully implemented:

1. Remove `plugin_status="EXPERIMENTAL"` from metadata
2. Update plugin_description to remove "EXPERIMENTAL STUB" text
3. Implement all required functionality
4. Add comprehensive test coverage
5. Update documentation to reflect production status
6. Remove test skip patterns

## Core Plugin Functions

Every plugin MUST implement the **13 universal core functions**. Plugins for specific
product categories MUST also implement **category-specific mandatory functions**.
All functions must follow the return value standards defined in this document.

### Function Count Summary

The plugin interface uses a tiered structure:

- **13 Universal Core Functions** - Required for ALL plugins (database, client, datasafe, oud, java, etc.)
- **2 Category-Specific Mandatory Functions** - Required for database/listener-based products
- **N Optional/Extension Functions** - Added as needed for product-specific features

**Total mandatory functions per plugin:**

- Non-database products (client, iclient, java, oud): **13 functions**
- Database/listener products (database, datasafe): **15 functions** (13 + 2 category-specific)
- Plus any optional/extension functions as needed

### Universal Core Functions (13 Required for ALL Plugins)

These functions MUST be implemented by every plugin, regardless of product type:

| #  | Function Name                | Purpose                                              | Exit Codes                          | Required |
|----|------------------------------|------------------------------------------------------|-------------------------------------|----------|
| 1  | `plugin_detect_installation` | Auto-discover installations                          | 0=success                           | ✅       |
| 2  | `plugin_validate_home`       | Validate installation path                           | 0=valid, 1=invalid                  | ✅       |
| 3  | `plugin_adjust_environment`  | Adjust ORACLE_HOME if needed                         | 0=success                           | ✅       |
| 4  | `plugin_build_base_path`     | Resolve actual installation/ORACLE_BASE_HOME         | 0=success                           | ✅       |
| 5  | `plugin_build_env`           | Build environment variables for the product/instance | 0=success, 1=n/a, 2=unavailable     | ✅       |
| 6  | `plugin_check_status`        | Check service/instance status                        | 0=running, 1=stopped, 2=unavailable | ✅       |
| 7  | `plugin_get_metadata`        | Get installation metadata                            | 0=success                           | ✅       |
| 8  | `plugin_discover_instances`  | Discover instances/domains for this home             | 0=success                           | ✅       |
| 9  | `plugin_get_instance_list`   | Enumerate instances/domains (multi-instance only)    | 0=success                           | ✅       |
| 10 | `plugin_supports_aliases`    | Supports SID-like aliases?                           | 0=yes, 1=no                         | ✅       |
| 11 | `plugin_build_bin_path`      | Get PATH components                                  | 0=success                           | ✅       |
| 12 | `plugin_build_lib_path`      | Get LD_LIBRARY_PATH components                       | 0=success                           | ✅       |
| 13 | `plugin_get_config_section`  | Get config file section name                         | 0=success                           | ✅       |

**Notes:**

- `plugin_get_instance_list` is universal but only returns data for multi-instance products (database, RAC, WebLogic, OUD)
- Single-instance products (client, iclient, java) should implement it but return empty output

### Category-Specific Mandatory Functions (2 for Database/Listener Products)

These functions MUST be implemented by plugins that manage listener components:

| Function Name                  | Applies To                                      | Purpose                                   | Exit Codes                          |
|--------------------------------|-------------------------------------------------|-------------------------------------------|-------------------------------------|
| `plugin_should_show_listener`  | Database, DataSafe, and listener-based products | Decide whether to render listener entries | 0=yes, 1=no                         |
| `plugin_check_listener_status` | Database, DataSafe, and listener-based products | Report listener status per Oracle Home    | 0=running, 1=stopped, 2=unavailable |

**Category-Specific Requirements by Product Type:**

| Product Type | Universal Core | Category-Specific | Total Mandatory |
|--------------|----------------|-------------------|-----------------|
| database     | 13             | 2 (listener)      | 15              |
| datasafe     | 13             | 2 (listener)      | 15              |
| client       | 13             | 0                 | 13              |
| iclient      | 13             | 0                 | 13              |
| oud          | 13             | 0                 | 13              |
| java         | 13             | 0                 | 13              |
| weblogic     | 13             | TBD               | 13+             |
| emagent      | 13             | TBD               | 13+             |
| oms          | 13             | TBD               | 13+             |

**Notes:**

- Listener functions are **mandatory** for database and datasafe plugins
- Non-listener products should still implement these functions but return appropriate defaults (see templates)
- Future product categories may introduce additional category-specific requirements

### Detailed Function Descriptions

#### plugin_detect_installation

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

#### plugin_validate_home

**Purpose:** Validate that a given path is a valid ORACLE_HOME for this product
type (or a valid ORACLE_BASE_HOME that can be resolved to ORACLE_HOME).

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

#### plugin_adjust_environment

**Purpose:** Adjust ORACLE_HOME path for product-specific requirements and align
it with `ORACLE_BASE_HOME` when they differ.

**Usage:** Called when setting up environment variables.

**Exit Codes:**

- `0` - Success

**Output Format:**

- Single line: adjusted ORACLE_HOME path

**Notes:**

- Most products return path unchanged.
- DataSafe appends `/oracle_cman_home` subdirectory.
- Align ORACLE_HOME to the resolved base returned by `plugin_build_base_path` when the install layout uses ORACLE_BASE_HOME.
- Output must be a valid filesystem path
- Don't validate existence - just transform path

#### plugin_build_base_path

**Purpose:** Return the actual installation base path, accounting for `ORACLE_BASE_HOME` when it differs from `ORACLE_HOME`.

**Usage:** Called before path/env builders to normalize installation roots.

**Exit Codes:**

- `0` - Success

**Output Format:**

- Single line: normalized base path

**Notes:**

- Use when installations are staged in a base directory with multiple Oracle Homes beneath it.
- Do not attempt to auto-correct invalid inputs; return the best-known base or empty with exit 1 if not applicable.

#### plugin_build_env

**Purpose:** Build all environment variables required for the product type (and instance, if applicable).

**Usage:** Called whenever subshells need a complete product/instance environment.

**Exit Codes:**

- `0` - Success
- `1` - Not applicable (e.g., minimal client needing no env tweaks)
- `2` - Unavailable (missing inputs or binaries)

**Output Format:**

- Key=value pairs, one per line. Typical keys: `ORACLE_HOME`, `ORACLE_BASE_HOME`
- (when set), `ORACLE_SID` or equivalent instance/domain identifier, `PATH`,
- `LD_LIBRARY_PATH`, `CLASSPATH`, product-specific variables as required.

**Notes:**

- Must be aware of the target user; if running under `sudo -u oracle`, build the environment for that user explicitly.
- Database products must set `ORACLE_HOME`, `ORACLE_SID`, and paths; middleware products must
  set their domain/instance identifiers; pure clients may only need PATH/LD_LIBRARY_PATH.
- Keep PATH and LD_LIBRARY_PATH scoped to the current product/instance; do not leak unrelated installations.

#### plugin_check_status

**Purpose:** Check if product instance/service is currently running.

**Exit Codes:**

- `0` - Running/active (for services) or Available (for software-only products)
- `1` - Stopped/inactive (for services) or Not Applicable (for stubs)
- `2` - Unavailable (binary missing, command failed, cannot determine status)

**Output Format:**

- **No output to stdout** - Status is communicated via exit code only
- Previous versions used status strings ("running", "stopped", "unavailable") but this has been
  deprecated in favor of exit codes only (Issue #140)

**Notes:**

- Use explicit environment (don't rely on shell environment)
- Check actual service status, not just binary existence
- Timeout commands appropriately (avoid hangs)
- Handle missing binaries gracefully (return 2)
- Database listeners should be covered by a dedicated `plugin_check_listener_status`
  function rather than overloading instance status.
- **Breaking change (v0.20.0):** Callers must check exit codes only; do not parse stdout

#### plugin_get_metadata

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
- **No sentinel strings**: Omit key-value pairs entirely if data unavailable (don't output "version=N/A")
- Clean data only: Output should contain valid data or nothing

#### plugin_discover_instances

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
- Use `plugin_get_instance_list` for per-home enumeration when multiple
  instances/domains exist; `plugin_discover_instances` can orchestrate across homes.

#### plugin_get_instance_list

**Purpose:** Enumerate all instances/domains within the specified ORACLE_HOME.

**Exit Codes:**

- `0` - Success (instances found or none - both valid)

**Output Format:**

- One instance per line: `instance_name|status|additional_metadata`

**Notes:**

- Mandatory for database, middleware, and any product supporting multiple instances/domains per installation.
- Status should map to `plugin_check_status` (database plugins may include
  mounted/nomount/etc. in metadata, not in the status token).
- Support dummy entries (e.g., `D` flag in oratab) by setting status to `stopped` and metadata flagging dummy installs.

#### 10. plugin_supports_aliases

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

#### 11. plugin_build_bin_path

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

#### 12. plugin_build_lib_path

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

#### 13. plugin_get_config_section

**Purpose:** Get the configuration section name for this product.

**Exit Codes:**

- `0` - Success

**Output Format:**

- Single line: uppercase section name
- Example: `RDBMS`, `DATASAFE`, `CLIENT`, `ICLIENT`, `OUD`, `WLS`

**Notes:**

- Used by `oradba_apply_product_config()` to load settings
- Convention: uppercase product identifier
- Must match section names in oradba_standard.conf and reflect the product category
  (e.g., `RDBMS`, `MIDDLEWARE`, `DATASAFE`, `CLIENT`, `ICLIENT`, `JAVA`)

#### plugin_should_show_listener (category-specific)

**Purpose:** Determine if this product's listener should appear in listener sections.

**Exit Codes:**

- `0` - Show listener (database products and any product exposing a listener)
- `1` - Don't show listener (products that reuse tnslsnr but should not be shown)

**Output Format:**

- No output (boolean return code only)

**Notes:**

- Required for products that ship or rely on a listener (databases, Data Safe).
- Database listeners: return 0.
- DataSafe connectors: return 1 (use tnslsnr but aren't DB listeners).
- Most non-database products: return 1.

#### plugin_check_listener_status (category-specific)

**Purpose:** Report listener status for products that expose a listener component tied to an Oracle Home.

**Exit Codes:**

- `0` - Running/active
- `1` - Stopped/inactive
- `2` - Unavailable (binary missing, command failed)

**Output Format:**

- Single word: `running`, `stopped`, or `unavailable`

**Notes:**

- Separate from `plugin_check_status` for database instances; listener lifecycle is managed per Oracle Home.
- Use explicit environment and timeouts; handle missing binaries with exit 2.

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

```bash
# ❌ WRONG: Fragile string checking
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
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

## Subshell Execution Model

### Overview

Starting with Phase 3 (Issue #136), all plugin functions execute in isolated subshells to prevent side effects
and environment pollution. This ensures plugins cannot accidentally modify the caller's environment.

### Minimal Oracle Environment

**Critical Requirement:** The subshell wrapper MUST provide minimal Oracle environment variables to ensure plugins
can execute Oracle commands:

- `ORACLE_HOME` - Oracle installation directory (required)
- `LD_LIBRARY_PATH` - Must include `$ORACLE_HOME/lib` (required)

**Why This is Required:**

- Plugins call Oracle binaries (sqlplus, lsnrctl, cmctl, etc.)
- Oracle binaries require ORACLE_HOME to locate components
- Oracle shared libraries (.so files) require LD_LIBRARY_PATH
- Without these, Oracle commands will fail with "command not found" or library errors

### Wrapper Implementation Pattern

```bash
execute_plugin_in_subshell() {
    local plugin_name="$1"
    local function_name="$2"
    shift 2
    local args=("$@")
    
    # Execute in isolated subshell with minimal Oracle environment
    local output
    local exit_code
    
    output=$(
        # Enable strict error handling
        set -euo pipefail
        
        # ✅ CRITICAL: Pass minimal Oracle environment
        export ORACLE_HOME="${ORACLE_HOME:-}"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
        
        # Source plugin in subshell (isolated from parent)
        source "${ORADBA_PLUGIN_DIR}/${plugin_name}_plugin.sh" || return 2
        
        # Execute plugin function with arguments
        "${function_name}" "${args[@]}"
    )
    exit_code=$?
    
    # Output result to parent (if any)
    [[ -n "${output}" ]] && echo "${output}"
    
    # Propagate exit code to parent
    return ${exit_code}
}
```

### Environment Isolation

**What is Isolated:**

- All environment variables except ORACLE_HOME and LD_LIBRARY_PATH
- Global shell variables
- Function definitions (unless re-sourced)
- File descriptors
- Traps and signal handlers

**What is Inherited:**

- ORACLE_HOME (explicitly passed)
- LD_LIBRARY_PATH (explicitly passed)
- Exit codes (propagated via return)
- Stdout output (captured and returned)

### Plugin Developer Guidelines

When writing plugins, you can **assume** the following environment is available:

```bash
plugin_function() {
    local home_path="$1"
    
    # ✅ ORACLE_HOME is available - use it for Oracle commands
    local version=$("${ORACLE_HOME}/bin/sqlplus" -v 2>/dev/null | head -1)
    
    # ✅ LD_LIBRARY_PATH is available - Oracle libraries will load
    local listener_status=$("${ORACLE_HOME}/bin/lsnrctl" status 2>&1)
    
    # ✅ Exit codes propagate correctly
    return 0  # or 1, or 2
}
```

**Important notes**:

- Exported variables from parent ARE inherited (by design of bash subshells)
- Modifications to inherited variables do NOT leak back to parent
- New variables you create/export do NOT leak back to parent
- Function definitions do NOT persist across plugin calls
- Oracle environment (ORACLE_HOME, LD_LIBRARY_PATH) is guaranteed available

### Consumer Usage Patterns

**Standard plugin function call** (function takes oracle_home argument):

```bash
# Call plugin function and capture result
local version
if execute_plugin_function_v2 "database" "get_version" "/opt/oracle/19c" "version"; then
    echo "Database version: ${version}"
else
    case $? in
        1) echo "Version not applicable" ;;
        2) echo "Version unavailable" ;;
    esac
fi
```

**No-argument plugin function call** (e.g., plugin_get_config_section):

```bash
# Use NOARGS keyword for functions that take no arguments
local config_section
if execute_plugin_function_v2 "database" "get_config_section" "NOARGS" "config_section"; then
    echo "Config section: ${config_section}"
fi
```

**With extra argument**:

```bash
# Pass extra argument for functions that need it
local metadata
execute_plugin_function_v2 "database" "get_metadata" "/opt/oracle/19c" "metadata" "full"
```

**Direct output** (without result variable):

```bash
# Let output go to stdout
if version=$(execute_plugin_function_v2 "database" "get_version" "/opt/oracle/19c"); then
    echo "Version: ${version}"
fi
```

### Testing Subshell Isolation

Plugins should be tested to verify:

1. Oracle commands work (ORACLE_HOME available)
2. Oracle libraries load (LD_LIBRARY_PATH available)
3. No environment pollution (variables don't leak to parent)

Example test:

```bash
@test "plugin can execute Oracle commands in subshell" {
    export ORACLE_HOME="/u01/oracle"
    export LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
    
    # Execute plugin function
    run execute_plugin_in_subshell "database" "plugin_get_version" "${ORACLE_HOME}"
    
    # Should succeed
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "subshell has access to ORACLE_HOME" {
    export ORACLE_HOME="/u01/oracle"
    
    run execute_plugin_in_subshell "test" "plugin_check_oracle_home"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/u01/oracle" ]]
}

@test "environment variables don't leak from subshell" {
    export ORACLE_HOME="/u01/oracle"
    TEST_VAR="original"
    
    # Plugin tries to modify TEST_VAR
    run execute_plugin_in_subshell "test" "plugin_modify_var"
    
    # Variable unchanged in parent
    [ "${TEST_VAR}" = "original" ]
}
```

### Performance Impact

Subshell execution adds minimal overhead:

- Subshell creation: ~5-10ms
- Plugin sourcing: ~5-10ms
- Total overhead: typically < 10%

This is acceptable for interactive and automation use cases.

### References

- Phase 3 Implementation: Issue #136
- Subshell Isolation Tests: `tests/test_plugin_isolation.bats`
- Phase 3 Sub-Issues: `.github/.scratch/phase3-subissues.md`

## Optional Functions and Extension Patterns

Beyond the mandatory functions (13 universal + category-specific), plugins MAY
implement optional functions for product-specific features.

### Types of Optional Functions

#### 1. Common Optional Functions

Functions that multiple plugins may implement, with standardized naming and behavior:

| Function                        | Purpose                           | Usage                       | Exit Codes              | Plugins Using   |
|---------------------------------|-----------------------------------|-----------------------------|-------------------------|-----------------|
| `plugin_get_version`            | Extract product version           | Called by get_metadata      | 0=success, 1=N/A, 2=err | All 9 plugins   |
| `plugin_get_required_binaries`  | List required binaries            | Used by validators          | 0=success               | All 9 plugins   |
| `plugin_get_display_name`       | Custom display name for instance  | Override default naming     | 0=success               | 1 (oud)         |

**Characteristics:**

- Standardized function names (no product prefix)
- May have default implementations in plugin_interface.sh
- Should be documented in this specification
- Testable with generic tests

#### 2. Product-Specific Extension Functions

Functions unique to a single product or product family, with product-prefixed naming:

| Function                         | Plugin   | Purpose                            |
|----------------------------------|----------|------------------------------------|
| `plugin_get_adjusted_paths`      | datasafe | DataSafe-specific path logic       |
| `plugin_oud_get_domain_config`   | oud      | OUD domain configuration (example) |
| `plugin_database_get_pdb_status` | database | PDB status checking (example)      |
| `plugin_weblogic_list_domains`   | weblogic | WebLogic domain discovery (example)|

**Naming Convention:** `plugin_<descriptive_name>` OR `plugin_<product>_<action>` when product-specific scope is clear

**Note:** Current implementations use descriptive names without product prefix (`plugin_get_adjusted_paths`).
For future extensions with ambiguous scope, consider adding product prefix for clarity.

**Characteristics:**

- Product-specific logic not applicable to other plugins
- May not follow standard return value patterns (document deviations)
- Should be documented in plugin source code
- Testable with product-specific tests

### Extension Function Naming Conventions

#### Decision Tree: When to Use What Pattern

```text
Is the function applicable to multiple product types?
├─ YES → Use Common Optional Function
│        - Standardized name: plugin_<action>
│        - Example: plugin_get_version
│        - Document in plugin-standards.md
│        
└─ NO → Use Product-Specific Extension
         - Descriptive name: plugin_<descriptive_name>
         - OR prefixed name: plugin_<product>_<action> (when scope needs clarity)
         - Example: plugin_get_adjusted_paths (datasafe)
         - Example: plugin_database_get_pdb_status
         - Document in plugin source file
```

#### Naming Guidelines

**DO:**

- ✅ Use `plugin_` prefix for all plugin functions
- ✅ Use descriptive names that indicate purpose
- ✅ Document the function's purpose, arguments, returns, and output
- ✅ Follow return value standards (exit codes + stdout)
- ✅ Keep function names concise but clear

**DON'T:**

- ❌ Use generic names that could conflict with core functions
- ❌ Skip the `plugin_` prefix
- ❌ Use abbreviations that aren't obvious
- ❌ Create extensions when a core function could be enhanced instead

### Optional Functions

#### Example plugin_get_version

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_version
# Purpose.: Extract product version from installation
# Args....: $1 - ORACLE_HOME path
# Returns.: 0=success, 1=not applicable, 2=extraction failed
# Output..: Version string (e.g., "19.21.0.0.0")
# ------------------------------------------------------------------------------
plugin_get_version() {
    local home_path="$1"
    local version
    
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

Product-specific extension functions implement features unique to a single product.
These are documented in the plugin source file rather than this specification.

**Current Product-Specific Extensions in Use:**

- **datasafe_plugin.sh**: `plugin_get_adjusted_paths` - Returns adjusted oracle_cman_home paths
- **oud_plugin.sh**: `plugin_get_display_name` - Custom display names for OUD instances (also a common optional function)

**Example Product-Specific Extensions (for future development):**

```bash
# Database plugin - PDB status checking
plugin_database_get_pdb_status() {
    local home_path="$1"
    local pdb_name="$2"
    # Check PDB status
    echo "OPEN"
    return 0
}

# WebLogic plugin - Domain discovery
plugin_weblogic_list_domains() {
    local home_path="$1"
    # Discover WebLogic domains
    echo "/u01/domains/prod_domain"
    echo "/u01/domains/test_domain"
    return 0
}

# DataSafe plugin - Connector configuration
plugin_datasafe_get_connector_config() {
    local home_path="$1"
    # Get connector configuration
    echo "connector_id=DS-CONN-001"
    echo "region=us-ashburn-1"
    return 0
}
```

**Guidelines for Product-Specific Extensions:**

1. **Naming**: Use `plugin_<descriptive_name>` or `plugin_<product>_<action>` for clarity
2. **Documentation**: Add complete function header in plugin source file
3. **Return Values**: Follow standard exit codes (0/1/2) and stdout conventions
4. **Testing**: Add product-specific tests in `tests/test_<product>_plugin.bats`
5. **Backward Compatibility**: Don't break existing behavior when adding extensions

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
# Core Functions (universal)
# ------------------------------------------------------------------------------

plugin_detect_installation() { ... }
plugin_validate_home() { ... }
plugin_adjust_environment() { ... }
plugin_build_base_path() { ... }
plugin_build_env() { ... }
plugin_check_status() { ... }
plugin_get_metadata() { ... }
plugin_discover_instances() { ... }
plugin_get_instance_list() { ... }
plugin_supports_aliases() { ... }
plugin_build_bin_path() { ... }
plugin_build_lib_path() { ... }
plugin_get_config_section() { ... }

# Category-Specific Functions
# ------------------------------------------------------------------------------
plugin_should_show_listener() { ... }
plugin_check_listener_status() { ... }

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
├── product_plugin.sh          # Core functions only (universal + category-specific)
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
# Core Functions (universal)
# ------------------------------------------------------------------------------

plugin_detect_installation() { ... }
plugin_validate_home() { ... }
plugin_adjust_environment() { ... }
plugin_build_base_path() { ... }
plugin_build_env() { ... }
plugin_check_status() { ... }
plugin_get_metadata() { ... }
plugin_discover_instances() { ... }
plugin_get_instance_list() { ... }
plugin_supports_aliases() { ... }
plugin_build_bin_path() { ... }
plugin_build_lib_path() { ... }
plugin_get_config_section() { ... }

# ------------------------------------------------------------------------------
# Category-Specific Functions
# ------------------------------------------------------------------------------
plugin_should_show_listener() { ... }
plugin_check_listener_status() { ... }

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

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
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

plugin_get_version() {
    local home_path="$1"
    # Complex version extraction logic
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

- ✅ Core plugin stays focused (13 universal core functions, ~300-500 lines)
- ✅ Optional features don't bloat core
- ✅ Extensions can evolve independently
- ✅ Clear separation of required vs. optional
- ✅ Easier to maintain and debug
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

```

### Template: plugin_adjust_environment

```bash
# ------------------------------------------------------------------------------
# Function: plugin_adjust_environment
# Purpose.: Adjust ORACLE_HOME for product-specific requirements
# Args....: $1 - Original ORACLE_HOME path
# Returns.: 0 on success
# Output..: Adjusted ORACLE_HOME path
# Notes...: Most products return path unchanged
#           DataSafe example: appends /oracle_cman_home
# ------------------------------------------------------------------------------
plugin_adjust_environment() {
    local home_path="$1"
    
    # Most products: return unchanged
    echo "${home_path}"
    return 0
    
    # DataSafe pattern: append subdirectory
    # if [[ -d "${home_path}/subdirectory" ]]; then
    #     echo "${home_path}/subdirectory"
    # else
    #     echo "${home_path}"
    # fi
# return 0
}

```

### Template: plugin_build_base_path

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
        return 0
    fi

    # Fallback: return given path
    echo "${home_path}"
    return 0
}

```

### Template: plugin_build_env

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_env
# Purpose.: Build environment variables for the product/instance
# Args....: $1 - ORACLE_HOME
#           $2 - Instance/domain identifier (if applicable)
# Returns.: 0 on success, 1 if not applicable, 2 if unavailable
# Output..: Key=value pairs (one per line)
# Notes...: Scope PATH/LD_LIBRARY_PATH to this product/instance only
# ------------------------------------------------------------------------------
plugin_build_env() {
    local home_path="$1"
    local instance="${2:-}"

    [[ -z "${home_path}" ]] && return 2

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

### Template: plugin_check_status

```bash
# ------------------------------------------------------------------------------
# Function: plugin_check_status
# Purpose.: Check if product instance is running
# Args....: $1 - Installation path
#           $2 - Instance name (optional)
# Returns.: 0 if running/available, 1 if stopped/N/A, 2 if unavailable/error
# Output..: None - status communicated via exit code only
# Notes...: Uses explicit environment (not current shell environment)
#           No output strings - breaking change in v0.20.0 (Issue #140)
# ------------------------------------------------------------------------------
plugin_check_status() {
    local home_path="$1"
    local instance_name="${2:-}"
    
    # Adjust environment if needed
    local adjusted_home
    adjusted_home=$(plugin_adjust_environment "${home_path}")
    
    # Check if status binary exists
    local status_binary="${adjusted_home}/bin/product_ctl"
    if [[ ! -x "${status_binary}" ]]; then
        return 2
    fi
    
    # Check status using explicit environment
    local status
    status=$(ORACLE_HOME="${adjusted_home}" \
             LD_LIBRARY_PATH="${adjusted_home}/lib:${LD_LIBRARY_PATH:-}" \
             "${status_binary}" status 2>/dev/null)
    
    # Parse status output and return exit code only
    if echo "${status}" | grep -qiE "running|active|started"; then
        return 0
    elif echo "${status}" | grep -qiE "stopped|inactive|down"; then
        return 1
    else
        return 2
    fi
}

```

### Template: plugin_get_metadata

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_metadata
# Purpose.: Get product metadata (version, features, etc.)
# Args....: $1 - Installation path
# Returns.: 0 on success, 1 if not applicable, 2 if failed
# Output..: Key=value pairs (one per line)
# Notes...: Standard keys: version, edition, patchlevel
# ------------------------------------------------------------------------------
plugin_get_metadata() {
    local home_path="$1"
    
    # Get version (use plugin_get_version if available)
    local version=""
    if type plugin_get_version &>/dev/null; then
        if version=$(plugin_get_version "${home_path}"); then
            : # version set successfully
        fi
    fi
    
    # Get edition (product-specific)
    local edition="Standard"
    if [[ -f "${home_path}/lib/libserver_enterprise.so" ]]; then
        edition="Enterprise"
    fi
    
    # Get patch level (if applicable)
    local patchlevel=""
    if [[ -x "${home_path}/OPatch/opatch" ]]; then
        patchlevel=$("${home_path}/OPatch/opatch" lspatches 2>/dev/null | head -1 | awk '{print $1}')
    fi
    
    # Output metadata
    [[ -n "${version}" ]] && echo "version=${version}"
    [[ -n "${edition}" ]] && echo "edition=${edition}"
    [[ -n "${patchlevel}" ]] && echo "patchlevel=${patchlevel}"
    
    return 0
}

```

### Template: plugin_should_show_listener

```bash
# ------------------------------------------------------------------------------
# Function: plugin_should_show_listener
# Purpose.: Decide whether to render listener entries for this product
# Args....: $1 - Installation path
# Returns.: 0 if should show, 1 if should not show
# Output..: None
# Notes...: Category-specific: required for products exposing a listener
# ------------------------------------------------------------------------------
plugin_should_show_listener() {
    local home_path="$1"
    [[ -z "${home_path}" ]] && return 1

    # Database products: show listener
    return 0

    # DataSafe example: reuse tnslsnr but should not appear as DB listener
    # return 1
}

```

### Template: plugin_check_listener_status

```bash
# ------------------------------------------------------------------------------
# Function: plugin_check_listener_status
# Purpose.: Report listener status for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 if running, 1 if stopped, 2 if unavailable
# Output..: Status string (running|stopped|unavailable)
# Notes...: Listener lifecycle is distinct from database instance lifecycle
# ------------------------------------------------------------------------------
plugin_check_listener_status() {
    local home_path="$1"
    local binary="${home_path}/bin/lsnrctl"

    [[ ! -x "${binary}" ]] && { echo "unavailable"; return 2; }

    local status
    status=$("${binary}" status 2>/dev/null)

    if echo "${status}" | grep -qi "listener is running"; then
        echo "running"
        return 0
    elif echo "${status}" | grep -qi "listener is not running"; then
        echo "stopped"
        return 1
    else
        echo "unavailable"
        return 2
    fi
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

```

### Template: plugin_get_instance_list

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_instance_list
# Purpose.: Enumerate all instances/domains for this ORACLE_HOME
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success
# Output..: instance_name|status|additional_metadata (one per line)
# Notes...: Mandatory for products with multiple instances/domains per home
# ------------------------------------------------------------------------------
plugin_get_instance_list() {
    local home_path="$1"

    # Example: read instances from oratab-like file
    local instance_file="${home_path}/install/oratab"
    [[ ! -f "${instance_file}" ]] && return 0

    while IFS=: read -r sid home flag; do
        [[ -z "${sid}" || -z "${home}" ]] && continue
        local status="stopped"
        if plugin_check_status "${home}" "${sid}" &>/dev/null; then
            status="running"
        fi
        echo "${sid}|${status}|flag=${flag}"
    done < "${instance_file}"

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
    # Database products: return 0
    return 0
    
    # Non-database products: return 1
    # return 1
}

```

### Template: plugin_build_bin_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_bin_path
# Purpose.: Get PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if failed
# Output..: Colon-separated PATH components
# Notes...: Don't validate existence - just build path list
# ------------------------------------------------------------------------------
plugin_build_bin_path() {
    local home_path="$1"
    
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

```

### Template: plugin_build_lib_path

```bash
# ------------------------------------------------------------------------------
# Function: plugin_build_lib_path
# Purpose.: Get LD_LIBRARY_PATH components for this product
# Args....: $1 - ORACLE_HOME path
# Returns.: 0 on success, 1 if failed
# Output..: Colon-separated library path components
# Notes...: Don't validate existence - just build path list
# ------------------------------------------------------------------------------
plugin_build_lib_path() {
    local home_path="$1"
    
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

```

### Template: plugin_get_config_section

```bash
# ------------------------------------------------------------------------------
# Function: plugin_get_config_section
# Purpose.: Get configuration section name for this product
# Args....: None
# Returns.: 0 on success
# Output..: Configuration section name (uppercase)
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

## Interface Versioning

### Current Version: v1.0.0

**Interface established:** January 2026  
**Status:** Production-ready, stable  
**Current plugins:** 9 (6 production + 3 stubs)

**All plugins MUST declare:**

```bash
export plugin_interface_version="1.0.0"
```

**Experimental/Stub Plugins:**

Plugins in development or with limited functionality should also include:

```bash
export plugin_status="EXPERIMENTAL"
```

This clearly marks the plugin as not production-ready and helps users understand its maturity level.

### Version History

| Version | Date     | Changes                                                        | Status      |
|---------|----------|----------------------------------------------------------------|-------------|
| 1.0.0   | Jan 2026 | Initial stable release (13 universal + category-specific)      | **Current** |

### Version Policy

- **Current version:** v1.0.0 (January 2026)
- **Stability:** Interface is stable, no breaking changes planned for v1.x series
- **Backward Compatibility:** All v1.x releases will maintain full backward compatibility
- **Breaking changes require:**
  1. Formal decision and announcement
  2. Migration guide for plugin developers
  3. Compatibility layer during transition period (minimum 2-3 release cycles)
  4. Deprecation warnings with clear timeline
  5. Version bump to next major version (e.g., v2.0.0)

### What Constitutes a Breaking Change

**Breaking changes** that require major version bump (v1.0 → v2.0):

- ❌ Removing a universal core function
- ❌ Removing a category-specific mandatory function
- ❌ Changing function signature (adding/removing required parameters)
- ❌ Changing exit code semantics for existing codes
- ❌ Changing output format for structured data (breaking parsers)
- ❌ Renaming functions without compatibility layer

**Non-breaking changes** (allowed in v1.x):

- ✅ Adding new optional functions (common or product-specific)
- ✅ Adding new category-specific requirements for NEW product categories
- ✅ Adding new optional parameters with defaults (backward compatible)
- ✅ Improving documentation without changing behavior
- ✅ Bug fixes that restore documented behavior
- ✅ Performance improvements that maintain behavior
- ✅ Adding new exit codes (e.g., exit 3 for new state)

### Proposing Interface Changes

#### Minor Enhancements (No Version Bump)

For adding optional functions or documentation improvements:

1. **Open GitHub Issue**
   - Template: Feature Request
   - Label: `enhancement`, `plugin-interface`
   - Describe: Use case, proposed function signature, return values

2. **Discuss Design**
   - Review against existing patterns
   - Ensure no conflicts with core functions
   - Validate return value standards compliance

3. **Implement & Test**
   - Add function to relevant plugin(s)
   - Create tests in plugin-specific test file
   - Update plugin source documentation

4. **Submit Pull Request**
   - Include tests and documentation
   - Pass full test suite
   - Get maintainer review

#### Major Changes (Version Bump Required)

For changes that break compatibility:

1. **Create Proposal Document**
   - File: `.github/.scratch/proposal-<feature>.md`
   - Include:
     - Problem statement
     - Proposed solution
     - Breaking changes analysis
     - Migration path
     - Timeline
     - Backward compatibility strategy

2. **Community Discussion**
   - Open discussion issue
   - Solicit feedback from plugin developers
   - Allow minimum 2-week comment period

3. **Formal Approval**
   - Maintainer sign-off required
   - Document decision and rationale
   - Create migration guide

4. **Implementation Plan**
   - Deprecation warnings in v1.x release
   - Compatibility layer development
   - New version implementation
   - Migration tooling (if needed)

5. **Phased Rollout**
   - v1.x: Add deprecation warnings
   - v1.x+1: Compatibility layer with new interface
   - v2.0: Remove old interface, new interface only

### Adding New Product Categories

When adding support for a new product category (e.g., Grid Infrastructure, Exadata):

1. **Analyze Requirements**
   - Do universal core functions cover the product?
   - Are new category-specific functions needed?
   - Document product-specific considerations

2. **Propose Category-Specific Functions**
   - If new mandatory functions needed, follow Major Changes process
   - Document which product types require these functions
   - Update category requirements table

3. **Implementation**
   - Create new plugin file
   - Implement all 13 universal functions
   - Implement category-specific functions if applicable
   - Add comprehensive tests

4. **Documentation**
   - Update plugin-standards.md category table
   - Add product type to supported types list
   - Document any unique characteristics

### Deprecation Process

When deprecating functions or changing behavior:

1. **Announce Deprecation** (v1.x)
   - Add deprecation notice to function documentation
   - Log warning when function is called
   - Document migration path in release notes

2. **Provide Compatibility** (v1.x+1 to v1.x+n)
   - Maintain old behavior as default
   - Provide new behavior via opt-in flag
   - Continue deprecation warnings
   - Minimum 2-3 release cycles

3. **Remove Old Behavior** (v2.0)
   - Remove deprecated function/behavior
   - Update all documentation
   - Provide migration guide
   - Automated migration tooling if possible

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
export plugin_version="1.0.0"  # Plugin version (semantic versioning)
export plugin_interface_version="1.0.0"  # Interface version (optional but recommended)
export plugin_description="Product plugin"
```

### Interface Evolution Best Practices

**For Plugin Developers:**

- ✅ Always test against latest plugin-standards.md
- ✅ Subscribe to interface change notifications
- ✅ Plan for deprecations during maintenance windows
- ✅ Use interface_version declaration to track compatibility

**For Core Maintainers:**

- ✅ Minimize breaking changes
- ✅ Long deprecation timelines (2-3 releases minimum)
- ✅ Clear migration documentation
- ✅ Maintain backward compatibility in v1.x series
- ✅ Batch breaking changes for major versions

## Testing Requirements

### Mandatory Tests

All plugins MUST have tests covering:

#### Generic Tests (All Plugins)

1. **Plugin metadata**

   - All 3 metadata variables are set
   - `plugin_name` matches product type
   - Versions follow semantic versioning

2. **Core functions exist**

   - All universal core functions are defined
   - Functions are callable
   - No syntax errors

3. **Return value conventions**

   - Exit codes match standards (0/1/2)
   - No sentinel strings on stdout
   - Empty output + exit code correlation
   - Exercised by `tests/test_plugin_return_values.bats`

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

4. **Path and environment building**

   - `plugin_build_base_path` resolves ORACLE_BASE_HOME correctly
   - `plugin_build_env` outputs required variables for the product/instance
   - `plugin_build_bin_path` returns valid format
   - `plugin_build_lib_path` returns valid format
   - Paths are colon-separated

5. **Optional function behavior**

   - `plugin_get_version` returns valid versions
   - Product-specific extensions work correctly

### Test Organization

```text
tests/
├── test_plugin_interface.bats         # Generic: all plugins comply
├── test_plugin_return_values.bats     # Generic: return conventions
├── test_database_plugin.bats          # Specific: database
├── test_datasafe_plugin.bats          # Specific: datasafe
├── test_client_plugin.bats            # Specific: client
├── test_iclient_plugin.bats           # Specific: instant client
├── test_oud_plugin.bats               # Specific: OUD
└── test_java_plugin.bats              # Specific: Java
```

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

@test "plugin_build_bin_path returns valid format" {
    run plugin_build_bin_path "${TEST_HOME}"
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

### Running Tests

```bash
# Run all plugin tests
make test-plugins

# Run specific plugin tests
bats tests/test_product_plugin.bats

# Run specific test
bats tests/test_product_plugin.bats -f "validate_home"

# Run with verbose output
bats tests/test_product_plugin.bats --tap

```

## Best Practices

### DO ✅

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

9. **Assume minimal Oracle environment in subshell**

   - ORACLE_HOME is available - use for Oracle binary paths
   - LD_LIBRARY_PATH is available - Oracle libraries will load
   - Don't assume other environment variables exist
   - Test with subshell isolation enabled

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

9. **Don't assume full parent environment**

   - Only ORACLE_HOME and LD_LIBRARY_PATH are guaranteed
   - Other variables may not exist in subshell
   - Check variable existence before using
   - Don't rely on caller's custom environment variables

### Code Quality

1. **Pass shellcheck**

   - No warnings or errors
   - Use `# shellcheck disable=SCXXXX` sparingly with comments

2. **Use consistent formatting**

   - 4 spaces for indentation
   - Function headers with 78-char width
   - Blank lines between sections

3. **Add comprehensive tests**

   - Test all universal core functions and category-specific functions in scope
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
    
    echo "${version}"
    return 0
}

# Caller must check for sentinels
version=$(plugin_get_version "${home}")
if [[ -n "${version}" && "${version}" != "ERR" && "${version}" != "unknown" ]]; then
    echo "Version: ${version}"
fi

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
if version=$(plugin_get_version "${home}"); then
    echo "Version: ${version}"
else
    case $? in
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

#### Anti-Pattern 3: Status Strings in plugin_check_status

**Before (non-compliant, deprecated in v0.20.0):**

```bash

plugin_check_status() {
    local home_path="$1"
    
    # ❌ WRONG: Outputs status strings
    if pgrep -f "product_process" >/dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

# Caller must parse strings
status=$(plugin_check_status "${home}")
if [[ "${status}" == "running" ]]; then
    echo "Service is running"
fi

```

**After (compliant, v0.20.0+):**

```bash

plugin_check_status() {
    local home_path="$1"
    
    # ✅ CORRECT: Exit code only, no output
    if pgrep -f "product_process" >/dev/null; then
        return 0  # Running
    else
        return 1  # Stopped
    fi
}

# Caller checks exit code only
if plugin_check_status "${home}"; then
    echo "Service is running"
else
    case $? in
        1) echo "Service is stopped" ;;
        2) echo "Service status unavailable" ;;
    esac
fi

```

#### Anti-Pattern 4: Sentinel Values in plugin_get_metadata

**Before (non-compliant, deprecated in v0.20.0):**

```bash
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    # ❌ WRONG: Outputs sentinel string for unavailable data
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    else
        echo "version=N/A"  # Sentinel string
    fi
    
    echo "edition=Enterprise"
    return 0
}

# Caller must check for sentinels
metadata=$(plugin_get_metadata "${home}")
version=$(echo "$metadata" | grep version= | cut -d= -f2)
if [[ "${version}" != "N/A" ]]; then
    echo "Version: ${version}"
fi
```

**After (compliant, v0.20.0+):**

```bash
plugin_get_metadata() {
    local home_path="$1"
    local version
    
    # ✅ CORRECT: Omit key-value pair if data unavailable
    if version=$(plugin_get_version "${home_path}"); then
        echo "version=${version}"
    fi
    # No output if version not available - cleaner than sentinel
    
    echo "edition=Enterprise"
    return 0
}

# Caller handles missing keys gracefully
metadata=$(plugin_get_metadata "${home}")
if version=$(echo "$metadata" | grep "^version=" | cut -d= -f2); then
    echo "Version: ${version}"
else
    echo "Version: Not available"
fi
```

#### Anti-Pattern 5: Assuming Dependencies

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

```

### Migration Checklist

When updating a plugin to comply with standards:

- [ ] Remove all sentinel strings ("ERR", "unknown", "N/A") from ALL functions
- [ ] In `plugin_get_metadata`, omit key-value pairs when data unavailable (don't output "key=N/A")
- [ ] Update exit codes to standard conventions (0/1/2)
- [ ] Separate stdout (data) from stderr (logging)
- [ ] Add function headers for all universal core (and category-specific) functions
- [ ] Validate all input parameters
- [ ] Remove global state modifications
- [ ] Add error handling for missing binaries
- [ ] Update tests to check exit codes, not output strings
- [ ] Run shellcheck and fix warnings
- [ ] For experimental/stub plugins, set `plugin_status="EXPERIMENTAL"`
- [ ] Test with experimental plugin exclusion (should be skipped by default)
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
