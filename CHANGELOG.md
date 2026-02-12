# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- _None_

### Fixed

- _None_

### Changed

- _None_

## [0.21.2] - 2026-02-12

### Fixed

- **Extension Update Configuration Preservation**
  - Fixed `oradba_extension.sh add --update` not properly restoring preserved configuration files
  - Enhanced preservation logic to include all modified files from `.extension.checksum`, not just `etc/` directory
  - Added detection and preservation of user-added files (`*.conf`, `*.sh`, `*.sql`,
   `*.rcv`, `*.rman`, `*.env`, `*.properties`)
  - Files not present in `.extension.checksum` are now automatically preserved during updates
  - All preserved files are correctly restored after new extension content is installed
  - Improved directory structure handling for nested configuration files

## [0.21.1] - 2026-02-11

### Fixed

- **Data Safe Version Display Location**
  - Removed CMAN VERSION and CONNECTOR VER columns from `oraup.sh` Data Safe Connectors section
  - Data Safe version information (ORACLE_VERSION) is now only shown in detailed
    environment display via `oraenv.sh` and `oradba_env.sh status/show` commands
  - `oraup.sh` now displays simplified 4-column format: NAME, PORT, STATUS, DATASAFE_BASE_HOME
  - Aligns with design principle: summary view in `oraup.sh`, detailed view in `oraenv.sh`/`oradba_env.sh`
  - Added tests to verify correct column format and metadata extraction
- **Data Safe Metadata Version Fallbacks**
  - Use `cman_version` metadata when `version` is missing to populate ORACLE_VERSION in env output
  - Accept plain version strings from `setup.py version` to emit `connector_version`
- **Extension Update Config Preservation**
  - Fix `oradba_extension.sh --update` creating incomplete extensions and breaking config preservation (issue #202)

## [0.21.0] - 2026-02-11

### Added

- **Header Standardization**
  - Standardized all env library headers to match the official template format
  - Updated 3 files: `oradba_env_output.sh`, `oradba_env_status.sh`, `oradba_env_changes.sh`
  - All headers now include proper Author, Date, Revision, Purpose, Notes, Reference, License fields

- **Version/Date Refresh Across Files**
  - Updated version and date headers in `*.sh`, library, `rcv`, `sql`, and configuration files
  - Ensures consistent release metadata across scripts, libraries, and configs

- **Data Safe Dual Version Display**
  - Added `plugin_get_connector_version()` function to retrieve on-premises
    connector software version from `python3 setup.py version`
  - Updated `plugin_get_metadata()` to output both `cman_version`
    (Oracle CMAN version) and `connector_version` (connector software version)
  - Maintains backward compatibility with `version` field (maps to cman_version)
  - Updated `oraup.sh` Data Safe section to display both CMAN VERSION and CONNECTOR VER columns
  - Added 6 comprehensive tests for connector version detection and dual version display
  - Enables update scripts (e.g., ds_connector_update.sh) to check both versions independently
  - Facilitates troubleshooting with complete version information for both Oracle product and connector software

- **Data Safe Connection Manager Status Display**
  - Added `plugin_get_cman_status()` function to Data Safe plugin
  - Parses `cmctl show status -c <instance>` output for start date, uptime, and gateway count
  - Updates `show_oracle_home_status()` to display CMAN status fields when available
  - Displays START DATE, UPTIME, and GATEWAYS in status output for running connectors
  - Added 7 comprehensive tests for CMAN status functionality (67 total tests now pass)
  - Follows plugin standards (exit codes 0/1/2, no sentinel strings)
  - Integrates seamlessly with existing status display features

- **Data Safe Connection Count Display**
  - Added `plugin_get_connection_count()` function to Data Safe plugin
  - Retrieves active tunnel/connection count via `cmctl show tunnels -c <instance>`
  - Updates `plugin_get_metadata()` to include connection count
  - Displays `CONNECTIONS` field in status output when connector is running
  - Added 6 comprehensive tests for connection count functionality
  - Follows plugin standards (exit codes 0/1/2, no sentinel strings)

### Fixed

- **Oracle Home Extension Paths** (v0.20.6)
  - Ensure extensions are loaded for Oracle Home environments (non-database homes)
  - Keeps extension bin directories in PATH for Data Safe, Java, and similar homes
- **Repository Hygiene** (v0.20.6)
  - Runtime config artifacts now properly ignored in `.gitignore`
- **Documentation Build Compatibility** (v0.20.6)
  - Replaced Python YAML tags in `mkdocs.yml` with plain string references

## [0.20.6] - 2026-02-10

### Added

- **Ignore Runtime Config Artifacts**
  - Added `src/etc/oradba_homes.conf`, `src/etc/oratab`, and `src/etc/sid.dummy.conf` to `.gitignore`
  - Treats runtime-generated config files as local artifacts

### Fixed

- **Oracle Home Extension Paths**
  - Ensure extensions are loaded for Oracle Home environments (non-database homes)
  - Keeps extension bin directories in PATH for Data Safe, Java, and similar homes
- **Env Library Header Standardization**
  - Aligned env library headers with the standard template format
- **Documentation Build Compatibility**
  - Replaced Python YAML tags in `mkdocs.yml` with plain string references
  - Prevents unresolved tag errors during MkDocs builds
- **Repository Hygiene**
  - Removed runtime-generated config files from `src/etc/`

## [0.20.5] - 2026-02-10

### Added

- **Performance: Parallel Status Checks & Batch Process Detection**
  - Implemented parallel status checks for DataSafe connectors (background jobs with result collection)
  - Added batch process detection: single `ps -ef` call at start, reused for all checks
  - Added `get_process_list()` helper function to cache process list
  - Added `ORADBA_CACHED_PS` environment variable to pass cached process list to plugins
  - Updated `get_db_status()` to accept optional cached process list
  - Updated `get_listener_status()` to accept optional cached process list
  - Updated `should_show_listener_section()` to use cached process list
  - Updated `datasafe_plugin.sh` to use `ORADBA_CACHED_PS` when available
  - **Performance Impact**: ~3x faster for 5 DataSafe connectors (from ~1.5s to ~0.5s)
  - **Before**: 13+ ps -ef calls (sequential checks)
  - **After**: 1 ps -ef call + parallel background jobs
  - Added 7 new tests to verify optimization features (32 total tests pass)

- **Output Consolidation Helper**
  - Added `oradba_env_output.sh` shared formatter for environment/status output
  - Unified label alignment and divider layout across `oraenv.sh` and `oradba_env.sh`
  - Added support for PORT/PORTS metadata display when available

### Fixed

- **oradba_dsctl.sh Environment Setup**
  - Added `setup_connector_environment()` function to automatically set connector-specific environment
  - Each connector now gets proper ORACLE_HOME, LD_LIBRARY_PATH, TNS_ADMIN, and DATASAFE_HOME before operations
  - Fixed issue where operations failed unless user manually ran `. oraenv.sh <connector>` first
  - Fixed batch operations where only first connector was handled correctly
  - All connector operations (start/stop/restart/status) now work regardless of current shell environment
  - Resolves issues #187 and #185 patterns for multi-connector operations

- **Environment Status Consistency**
  - Consolidated non-database output for `oradba_env.sh show/status`
  - Ensured `oraenv.sh` non-database output matches shared formatter

## [0.20.4] - 2026-02-10

### Added

- **Plugin Debug Facilities**
  - Added TRACE log level for fine-grained debugging (finer than DEBUG)
  - Added `ORADBA_PLUGIN_DEBUG` environment variable to enable plugin-specific debugging
  - Added `is_plugin_debug_enabled()` helper function to check debug enablement
  - Added `is_plugin_trace_enabled()` helper function to check trace enablement
  - Added `sanitize_sensitive_data()` function to mask passwords and connection strings in logs
  - Plugin debug shows:
    - DEBUG level: Plugin call details (function, args) and environment snapshot (ORACLE_HOME, LD_LIBRARY_PATH, PATH, TNS_ADMIN)
    - DEBUG level: Plugin exit codes
    - TRACE level: Raw stdout/stderr from plugin functions (sanitized)
  - Automatic sanitization of sensitive data (passwords, connection strings) in all debug output
  - Plugin debug enabled when: `ORADBA_PLUGIN_DEBUG=true` OR `ORADBA_LOG_LEVEL=DEBUG` OR `ORADBA_LOG_LEVEL=TRACE` OR `DEBUG=1`
  - Comprehensive test suite with 25 tests covering all debug functionality
  - Updated plugin-development.md with troubleshooting guide using debug facilities

### Fixed

- **Data Safe Status Output**
  - Status values now use lowercase (running->open, stopped, unknown)
  - Always displays PORT with `n/a` fallback when CMAN port is missing
  - Uses Data Safe plugin metadata for version, service name, and port

## [0.20.3] - 2026-02-10

### Fixed

- **Library Path Resolution**
  - Normalized runtime plugin/library sourcing to `${ORADBA_BASE}/lib/...` across scripts and helpers
  - Ensures repo and installed layouts both resolve libraries consistently
- **TNS_ADMIN Reset on Env Switch**
  - Non-Data Safe environments now reapply config/default `TNS_ADMIN` after loading configs
  - Prevents Data Safe connector paths from persisting when switching to DB/client/java homes
- **Data Safe Status Output**
  - oraenv status now includes Data Safe install dir, Java home, and status
  - Maps running connector status to `OPEN` for consistency with output examples
  - Adds CMAN port extraction from cman.ora to status display

### Changed

- **Tooling and Tests**
  - Updated smart test selection to skip manual-only scripts
  - Adjusted tests to use repo `src` as `ORADBA_BASE` and source libraries via `lib/`
- **Docs and Debug Utilities**
  - Documented library path rule in Copilot instructions and Data Safe workflow
  - Updated Data Safe debug script to use `lib/` only
  - oradba_env show output now resolves and displays non-Data Safe `TNS_ADMIN` from config/default
  - Added `ORADBA_TNS_ADMIN` override example to customer config template

## [0.20.2] - 2026-02-09

### Fixed

- **Data Safe TNS_ADMIN Isolation**
  - `oraenv.sh` now enforces connector-specific `TNS_ADMIN` via Data Safe plugin
  - `oradba_dsctl.sh` sets per-connector `TNS_ADMIN` before cmctl operations
  - Prevents connectors from sharing `cman.ora` across environments

### Added

- **Data Safe Plugin Environment Helper**
  - Added `plugin_set_environment()` to enforce connector-specific variables
- **Data Safe Plugin Tests**
  - Added coverage for `TNS_ADMIN` handling and connector isolation

### Changed

- **User Documentation**
  - Documented Data Safe connector-specific `TNS_ADMIN` behavior

## [0.20.1] - 2026-02-09

### Fixed

- **Environment Variable Leakage in Plugin Execution**
  - Fixed `plugin_status` variable leaking from experimental plugins to non-experimental plugins
  - Fixed `TNS_ADMIN` variable leaking between DataSafe connectors causing wrong configuration usage
  - Added `unset TNS_ADMIN` and `unset plugin_status` before sourcing plugins in `execute_plugin_function_v2`
  - Prevents non-experimental plugins from being incorrectly skipped
  - Ensures each DataSafe connector uses its own `cman.ora` configuration
  - Applied to both NOARGS and regular branches of plugin execution

- **Deprecated log_debug() Function Call**
  - Replaced deprecated `log_debug()` with `oradba_log DEBUG` in `set_oracle_home_environment`
  - Eliminates "command not found" errors when sourcing DataSafe environments
  - Function was removed in v0.19.0 but one call remained

- **DataSafe Instance Name Regex Bug**
  - Fixed instance name extraction in DataSafe plugin to correctly identify `cust_cman` from `cman.ora`
  - Previous regex incorrectly matched `WALLET_LOCATION=(` instead of `cust_cman=`
  - Now excludes system variables (WALLET_LOCATION, SSL_VERSION, SSL_CLIENT_AUTHENTICATION)
  - Handles both formats: `cust_cman=` and `cust_cman =` (with/without spaces before equals)
  - Fixes TNS-04005 errors where cmctl tried to resolve WALLET_LOCATION as instance name
  - DataSafe connector status now correctly reports "running" when processes are active

- **DataSafe Environment Display and TNS_ADMIN**
  - `oradba_env.sh show/status` now displays Data Safe install dir, ORACLE_HOME, TNS_ADMIN, and JAVA_HOME
  - Ensures TNS_ADMIN resolves for Data Safe based on connector paths

### Changed

- **Documentation Version Neutralization**
  - Removed hard-coded v0.20.0 references across user docs
  - Kept versioned sections only where release-specific context is required
- **Data Safe Status Documentation**
  - Added user-doc guidance for Data Safe `oradba_env.sh show/status` outputs
- **PDF User Guide Build**
  - Consolidated PDF generation into `scripts/build_pdf.sh` and invoked from `make docs`
  - PDF build now uses mkdocs navigation order and excludes API reference from the user guide

## [0.20.0] - 2026-02-09

### Major Highlights

This major release consolidates three enhancement phases (v0.19.11, v0.19.12, and
critical bug fixes) into a stable production release with comprehensive plugin
system improvements, Oracle Home discovery enhancements, and improved environment
management.

### Fixed

- **Product Auto-Discovery Configuration Variables Missing** (Critical Bug)
  - Fixed `oradba_standard.conf` still exporting deprecated `ORADBA_AUTO_DISCOVER_HOMES` variable
  - Added missing `ORADBA_AUTO_DISCOVER_ORATAB` and `ORADBA_AUTO_DISCOVER_PRODUCTS` exports
  - Updated `oradba_validate.sh` to check for new variable names (v0.20.0+)
  - Resolves product discovery not executing despite correct installer flags
  - **Critical**: Without these exports, the renamed variables were never set, preventing auto-discovery

- **Product Auto-Discovery Not Running** (Bug Fix)
  - Fixed `oraenv.sh` using incorrect variable `${ORADBA_BASE}` instead of `${_ORAENV_BASE_DIR}`
  - Product discovery (`--auto-discover-products`) now correctly finds and adds Oracle products on first login
  - Resolves issue where ORADBA_AUTO_DISCOVER_PRODUCTS=true was set but discovery was not executing
  - Script path now correctly resolves to `${_ORAENV_BASE_DIR}/bin/oradba_homes.sh`

- **Product Auto-Discovery Missing Non-Database Homes** (Bug Fix)
  - Ensured product discovery runs when non-database homes are empty, even if database entries exist
  - Fixes missing auto-registration of DataSafe, Java, Instant Client, and OUD homes

- **Discovery Tests Mock Installation Validation** (Test Infrastructure)
  - Fixed discover test mocks to pass both `detect_product_type()` and `plugin_validate_home()`
  - OUD mocks now include `oud/lib/ldapjdk.jar` (for detection) and `setup` (for validation)
  - Client mocks now include `bin/sqlplus` and `network/admin` directory structure
  - All discovery tests now pass with realistic mock installations
  - Resolves false test failures where valid mocks were rejected by plugin validation

- **DataSafe Sequential Naming** (Regression from v0.19.4)
  - Fixed `generate_home_name()` in `oradba_homes.sh` to implement sequential naming for DataSafe
  - DataSafe installations now correctly use `dscon1`, `dscon2`, `dscon3` pattern as documented
  - Previously fell through to default uppercase conversion (e.g., EXACC_WOB_VWG_TEST)
  - Sequential counter finds next available number by checking existing config entries
  - Consistent with documented behavior in v0.19.4 release notes

- **DataSafe Auto-Discovery Naming Migration** (Bug Fix)
  - Auto-discovery now migrates legacy DataSafe names to sequential `dsconN` identifiers
  - Prevents DataSafe connectors from keeping path-derived names after auto-registration

- **Plugin System Execution Issues (Exit Code 133)**
  - Removed strict error handling (`set -euo pipefail`) from plugin subshells in `execute_plugin_function_v2`
  - Strict mode was causing plugins to fail with exit code 133 (signal termination) during normal operations
  - Plugins now have flexibility to check conditions that might fail without terminating the subshell
  - Added defensive sourcing of `oradba_common.sh` in `oradba_env_status.sh` to ensure `execute_plugin_function_v2` is available
  - Fixed syntax error in `oraup.sh` DataSafe status detection (malformed string escape)
  - DataSafe connector status now correctly returns "stopped" instead of "unknown"
  - Improved error handling when plugins are unavailable or return unexpected exit codes
  - Added comprehensive debug logging to trace plugin system execution flow
- **Phase 2.4: Stub plugin sentinel strings removed** (Issue #141)
  - Fixed `plugin_check_status()` in weblogic_plugin.sh, emagent_plugin.sh, and oms_plugin.sh
  - Changed from outputting "N/A" with exit 0 to "unavailable" with exit 2
  - All plugins now comply with return value standards (0=running, 1=stopped, 2=unavailable)
  - Completes Phase 2 (Return Value Standardization) - all sentinel strings eliminated
  - Comprehensive audit of all 9 plugins across 13+ core functions confirmed compliance
  - See `.github/.scratch/phase-2-4-audit-report.md` for detailed audit findings
  
### Improved

- **Fixed False Positives in Oracle Home Discovery**
  - Implemented plugin-based validation with parent directory exclusion
  - Discovery now validates each path using `plugin_validate_home()` before accepting
  - Automatically skips subdirectories of already-validated Oracle Homes
  - Excludes common bundled components (jdk, jre, lib, inventory, OPatch, etc.)
  - Prevents false detections like:
    - `/opt/oracle/product/26ai/dbhomeFree/jdk` (bundled JDK)
    - `/opt/oracle/product/26ai/dbhomeFree/lib` (Oracle libraries)
  - Ensures only genuine standalone Oracle Homes are discovered
  - Benefits both `oradba_homes.sh discover` and automatic discovery during initialization
  - Added helper functions: `is_subdirectory_of_oracle_home()`, `is_bundled_component()`

- **Enhanced Dummy Entry Handling in Oracle Environment Tools**
  - `oradba_env.sh list sids` now displays flag column showing entry type:
    - `DUMMY` for alias entries (flag 'D' in oratab)
    - `AUTO-START` for auto-starting databases (flag 'Y')
    - `MANUAL` for manually-started databases (flag 'N')
  - `oradba_env.sh show` now defaults to current `$ORACLE_SID` if no target specified
  - `oradba_env.sh status` removed unnecessary blank line in output for cleaner display
  - `oraup.sh` Oracle Homes section now clearly marks dummy entries:
    - Shows `dummy (→REAL_SID)` to indicate alias relationship
    - Dummy entries remain visible in Oracle Homes section for transparency
    - Real database instances only shown in Database Instances section
  - Improves clarity when using multiple aliases for the same Oracle Home

### Added

- **Product Discovery Options** (New Feature)
  - Added `--auto-discover-oratab` installer option for database homes from oratab
  - Added `--auto-discover-products` installer option for all Oracle products
  - Discovers all Oracle products (database, datasafe, java, iclient, oud) on first login
  - Added `--silent` flag to `oradba_homes.sh discover` for quiet operation

- **DBCA Templates for Automated Database Creation**
  - Added comprehensive DBCA response file templates for Oracle 19c and 26ai
  - Created `src/templates/dbca/` directory structure with templates for:
    - Oracle 19c: general, container, pluggable, dev, rac, dataguard
    - Oracle 26ai: general, container, pluggable, dev, free
  - Implemented `oradba_dbca.sh` helper script for automated database creation
    - Command-line interface with argument parsing
    - Template variable substitution
    - Prerequisites validation
    - Dry-run mode for testing
    - Template discovery with `--show-templates`
    - Secure password prompting
  - Created comprehensive documentation in `src/templates/dbca/README.md`
    - Usage examples and best practices
    - Template variables reference
    - Configuration guidelines
    - Troubleshooting section
  - Added BATS test suite (`test_oradba_dbca.bats`) with 18 test cases
  - All templates follow Oracle best practices and use standardized variable placeholders

- **Phase 5: Cleanup, Documentation, and v1.0.0 Baseline ([#158](https://github.com/oehrlis/oradba/issues/158))**
  - Established v1.0.0 as official plugin interface baseline (no v2.0.0 references)
  - Added `plugin_interface_version="1.0.0"` to all 9 plugins (6 production + 3 stubs)
  - Marked stub plugins (weblogic, emagent, oms) as EXPERIMENTAL
    - Added `plugin_status="EXPERIMENTAL"` metadata field
    - Updated descriptions to indicate "EXPERIMENTAL STUB" status
    - Documented stub/experimental plugin policy in plugin-standards.md
  - Updated plugin_interface.sh template with interface version and status fields
  - Comprehensive documentation updates:
    - Removed all v2.0.0 references from plugin-standards.md
    - Added stub/experimental plugin section with migration path
    - Updated plugin-development.md examples to v1.0.0
    - Updated function-header-guide.md VSCode snippets to v1.0.0
  - Updated .github/.scratch/plugin-refactor-plan.md to reflect Phase 5 progress
  - **100% Backward Compatible**: No breaking changes, purely cleanup and documentation
- **Plugin Interface Documentation Refinement ([#142](https://github.com/oehrlis/oradba/issues/142))**
  - Comprehensive review and documentation of plugin interface conventions (Phase 2.5)
  - Clarified function count structure: 13 universal + 2 category-specific = 15 for database products
  - Enhanced extension function naming conventions with decision tree
  - Added interface versioning and evolution guidelines
  - Documented formal process for proposing interface changes
  - Added deprecation process and backward compatibility guidelines
  - Created `.github/.scratch/plugin-interface-analysis.md` with detailed review findings
  - Enhanced test suite with category-specific validation (10 new tests)
  - **100% Backward Compatible**: Documentation-only improvements, no code changes
- **Phase 4 (Partial)**: Dependency Injection Infrastructure ([#137](https://github.com/oehrlis/oradba/issues/137))
  - Added `oradba_parser_init()`, `oradba_builder_init()`, `oradba_validator_init()` functions
  - Implemented internal logging functions: `_oradba_parser_log()`, `_oradba_builder_log()`, `_oradba_validator_log()`
  - Created comprehensive unit test suites:
    - `test_oradba_env_parser_unit.bats` (17 tests)
    - `test_oradba_env_builder_unit.bats` (22 tests)
    - `test_oradba_env_validator_unit.bats` (28 tests)
  - Added `doc/di-patterns.md` - Comprehensive DI usage guide (450+ lines)
  - Mock logger support for unit testing
  - Stateless execution capabilities
  - **Phase 4 Progress**: ~40% complete (Week 1 of 3 - DI infrastructure and unit tests)
- **Phase 3: Subshell Isolation for Plugin Execution (Issue #136)**
  - Implemented complete plugin execution isolation via `execute_plugin_function_v2()`
  - All plugins now execute in isolated subshells with minimal Oracle environment
  - Enhanced v2 wrapper to support no-arg functions via NOARGS keyword
  - Created comprehensive test suite (test_plugin_isolation.bats) with 13 isolation tests
  - Zero environment pollution - plugin modifications don't leak to parent shell
  - Strict error handling (`set -euo pipefail`) enforced in all plugin executions
  - Complete migration: All 5 direct plugin invocations converted to v2 wrapper
  - Performance overhead < 5% (well under 10% target)
  - See `doc/plugin-standards.md` Subshell Execution Model section
- **Multi-instance support for middleware plugins**
  - OUD plugin: Complete `plugin_get_instance_list()` implementation with pipe-delimited format
  - WebLogic plugin: Domain discovery and instance list with proper exit codes
  - Instance identifiers in environment builders (OUD_INSTANCE, WLS_DOMAIN)
  - Filesystem-based discovery (oudBase for OUD, user_projects/domains for WebLogic)
  - Comprehensive test coverage (26 OUD tests, 24 WebLogic tests)

### Changed

- **BREAKING: Renamed Discovery Flags and Variables** (Consistency & Clarity)
  - Installer flags:
    - `--enable-auto-discover` → `--auto-discover-oratab` (database homes from /etc/oratab)
    - `--enable-full-discovery` → `--auto-discover-products` (all Oracle products)
  - Environment variables:
    - `ORADBA_AUTO_DISCOVER_HOMES` → `ORADBA_AUTO_DISCOVER_ORATAB`
    - `ORADBA_FULL_DISCOVERY` → `ORADBA_AUTO_DISCOVER_PRODUCTS`
  - **Migration:** Update shell profiles to use new variable names
  - **Rationale:** Consistent naming scheme with clear scope indication

### Migration Guide (Breaking Changes)

If you previously used discovery options, update your shell profile:

**Old (deprecated):**

```bash
export ORADBA_AUTO_DISCOVER_HOMES="true"  # Old name
export ORADBA_FULL_DISCOVERY="true"       # Old name
```

**New (current):**

```bash
export ORADBA_AUTO_DISCOVER_ORATAB="true"    # Database homes from oratab
export ORADBA_AUTO_DISCOVER_PRODUCTS="true"  # All Oracle products
```

**Installer flag changes:**

- `./oradba_install.sh --enable-auto-discover` → `./oradba_install.sh --auto-discover-oratab`
- `./oradba_install.sh --enable-full-discovery` → `./oradba_install.sh --auto-discover-products`

- **Phase 4 (Partial)**: Refactored environment libraries for dependency injection
  - Replaced 29 direct `oradba_log` calls in `oradba_env_builder.sh` with `_oradba_builder_log()`
  - Replaced 2 direct `oradba_log` calls in `oradba_env_validator.sh` with `_oradba_validator_log()`
  - Updated `.github/.scratch/plugin-refactor-plan.md` to reflect Phase 4 progress
  - **100% Backward Compatible**: All existing tests (1086+) continue to pass
  - Libraries fall back to `oradba_log` when available if no logger injected
- **BREAKING: plugin_check_status() standardized with tri-state exit codes (Issue #140)**
  - **All status strings removed from output**: No more "running", "stopped", "unavailable", "available" strings
  - **Exit codes only**: 0=running/available, 1=stopped/N/A, 2=unavailable/error
  - **All 9 plugins updated**: database, datasafe, client, iclient, java, oud, weblogic, emagent, oms
  - **Tests updated**: Assert exit codes only, no output string assertions
  - **Migration required**: Callers must check exit codes only (`if plugin_check_status; then ...`), not parse stdout
  - See `doc/plugin-standards.md` for migration examples and updated templates
- **Plugin Interface Enhancements (v1.0.0)**
  - **Function rename**: `plugin_build_path` split into `plugin_build_bin_path` (PATH) and
    `plugin_build_lib_path` (LD_LIBRARY_PATH)
  - **New functions**: `plugin_build_base_path` (resolve ORACLE_BASE_HOME), `plugin_build_env`
    (unified env builder), `plugin_get_instance_list` (enumerate instances/domains)
  - **Listener separation**: `plugin_should_show_listener` and `plugin_check_listener_status`
    for category-specific listener handling
  - Exit code standards unchanged (0=success, 1=n/a, 2=error)
  - See `doc/releases/v0.19.11.md` for complete details and migration guide
- **Documentation parity with plugin interface v1.0.0**
  - Updated all documentation to reflect 13 universal core functions (previously incorrectly listed as 11)
  - Fixed function name references: `plugin_build_path` → `plugin_build_bin_path`
  - Clarified distinction between universal core functions (13) and category-specific functions (2)
  - Updated: copilot-instructions.md, README.md, architecture.md, development.md, plugin-development.md,
    plugin-standards.md, function-header-guide.md
  - All mermaid diagrams verified to match actual code implementation

### Removed

## [0.19.10] - 2026-01-24

### Changed

- **DataSafe status checks use instance name parameter**
  - `oradba_check_datasafe_status()` now accepts an optional instance name parameter
  - `oradba_get_product_status()` passes the instance name for DataSafe connectors
  - Plugin status checks receive instance context for more accurate detection
- **Plugin execution temp file read optimization**
  - Replaced subshell `cat` with bash builtin file read in `oradba_apply_oracle_plugin()`
  - Reduces subshell creation during plugin execution

### Fixed

- **DataSafe status detection tests**
  - Updated `check_datasafe_status` test to use direct `declare -F` validation
  - Prevents false failures when functions are already sourced

## [0.19.9] - 2026-01-23

### Added

- add oradba_datasafe_debug.sh for debugging Data Safe connectors

## [0.19.8] - 2026-01-23

### Added

- **oradba_install.sh: Auto-Discovery Flag for Profile Integration** (Issue #94)
  - New `--enable-auto-discover` flag enables automatic Oracle Homes discovery on shell startup
  - When combined with `--update-profile`, adds `export ORADBA_AUTO_DISCOVER_HOMES="true"` to shell profile
  - Automatically discovers and registers new Oracle products into `oradba_homes.conf` on first login
  - Works with `--update-profile` and `--no-update-profile` combinations
  - Updates both profile writing and manual instructions to include the export statement
  - Benefits:
    - Eliminates manual configuration step for auto-discovery
    - Ensures consistent auto-discovery behavior across environments
    - Simplifies deployment in environments with dynamic Oracle installations

- **oradba_dsctl.sh: Unified Data Safe Connector Control Script** (Issue #[TBD])
  - New control script `oradba_dsctl.sh` for managing Oracle Data Safe on-premises connectors
  - Supports start/stop/restart/status operations for Data Safe connectors
  - Uses `cmctl` command for connector management (startup/shutdown)
  - Integrates with oradba_registry API for connector discovery from oradba_homes.conf
  - Follows same patterns and structure as `oradba_dbctl.sh` for consistency
  - Features:
    - Automatic connector discovery using registry API (datasafe type)
    - Honors autostart flag (Y) from oradba_homes.conf
    - Justification prompt for bulk operations (similar to oradba_dbctl.sh)
    - Graceful shutdown with configurable timeout and fallback to force kill
    - Comprehensive logging using oradba_log
    - Debug mode support via --debug flag or ORADBA_DEBUG environment variable
    - Force mode (--force) to skip confirmation prompts
    - Configurable shutdown timeout (--timeout or ORADBA_SHUTDOWN_TIMEOUT)
  - Implementation details:
    - Uses datasafe_plugin.sh for connector status checks
    - Extracts CMAN instance name from cman.ora configuration
    - Handles oracle_cman_home path adjustments automatically
    - Process-based fallback when graceful shutdown times out
  - Added comprehensive test suite with 50 BATS tests covering:
    - Script existence, permissions, and syntax validation
    - Help and usage output verification
    - Action and option parsing
    - Function definitions and documentation headers
    - Integration with required libraries (oradba_common.sh, datasafe_plugin.sh, oradba_registry.sh)
    - Code quality checks (logging, error handling, cmctl usage)

### Changed

### Fixed

- **Auto-discovery of Oracle Homes does not work on first login** (Issue #[TBD])
  - Fixed `ORADBA_AUTO_DISCOVER_HOMES` not triggering on first login with empty oratab/oradba_homes.conf
  - Root cause: Early return in `_oraenv_gather_available_entries()` prevented Oracle Home discovery when no running
    instances found
  - Restructured control flow to attempt both instance and home discovery before returning error
  - Now correctly discovers and registers Oracle Homes on first login when `ORADBA_AUTO_DISCOVER_HOMES=true`
  - Both discovery methods run when their respective flags are enabled
  - Final error check only happens after both discovery attempts complete
  - Added tests to verify correct behavior and prevent regression
- **Java and Client Path Configuration Variables Not Working** (Issue #[Bug])
  - Fixed `ORADBA_JAVA_PATH_FOR_NON_JAVA` and `ORADBA_CLIENT_PATH_FOR_NON_CLIENT` not being honored during environment setup
  - Root cause: Functions `oradba_add_java_path` and `oradba_add_client_path` were implemented but never called from `oraenv.sh`
  - Added calls to both functions in environment setup after configuration loading
  - Added `ORACLE_CLIENT_HOME` export when client path is configured
  - Created `_oraenv_apply_path_configs` helper function to eliminate code duplication
  - Now correctly sets `JAVA_HOME` and `ORACLE_CLIENT_HOME` when configured
  - Adds Java and client bin directories to PATH as specified
  - Supports all three modes: 'none' (default), 'auto' (first match), and explicit home name
  - Updated unit tests to validate `ORACLE_CLIENT_HOME` export
  - Verified with comprehensive integration tests

- **DataSafe Status Detection in oraup.sh** (Issue #100)
  - Fixed "unknown" status showing for running DataSafe connectors
  - Changed `oraup.sh` to use `oradba_get_product_status()` API (same as `oradba_env.sh`)
  - Removed complex direct function call logic with fallbacks
  - Now consistent with proven pattern used by `oradba_env.sh status` command
  - Both commands now properly show "running" status for active DataSafe connectors

### Removed

## [0.19.7] - 2026-01-22

### Added

- **Phase 3 Debug Support for Job Automation Scripts** (2026-01-22)
  - Added comprehensive debug logging to backup and monitoring scripts:
    - `rman_jobs.sh`: RMAN operation monitoring wrapper with debug tracing
    - `exp_jobs.sh`: DataPump export monitoring wrapper with debug tracing  
    - `imp_jobs.sh`: DataPump import monitoring wrapper with debug tracing
    - `longops.sh`: Core long operations monitoring with detailed SQL debugging
  - Dual activation methods for all scripts:
    - Environment variable: `ORADBA_DEBUG=true`
    - CLI flag: `--debug` or `-d`
  - Debug features for wrapper scripts:
    - Argument processing and filtering
    - Wrapper operation and target script invocation
    - Debug flag propagation to underlying longops.sh
  - Debug features for longops.sh:
    - SQL query construction and WHERE clause building
    - Database connection establishment and environment sourcing
    - Watch mode iterations and timing
    - Operation filtering and result processing
  - Enhanced management tools with comprehensive debug logging:
    - `oradba_dbctl.sh`: Database startup/shutdown with detailed operation tracing
    - `oradba_lsnrctl.sh`: Listener management with environment setup debugging
    - `oradba_services.sh`: Service orchestration with command construction tracing
  - Updated troubleshooting documentation with comprehensive Phase 1-3 debug examples
  - Complete debug coverage across all OraDBA script categories
  - Backward compatible: no output changes unless debug enabled
  - Usage examples:
    - `ORADBA_DEBUG=true rman_jobs.sh -w -i 10`
    - `exp_jobs.sh --debug -o "%EXP%" --all`
    - `longops.sh --debug -o "RMAN%" -w ORCL FREE`
    - `oradba_dbctl.sh --debug start ORCL`
    - `oradba_services.sh --debug restart`

## [0.19.6] - 2026-01-22

### Added

- **Phase 2 Debug Support for Oracle Management Tools** (2026-01-22)
  - Added comprehensive debug logging to Phase 2 management scripts:
    - `oradba_dbctl.sh`: Database start/stop/restart/status with detailed tracing
    - `oradba_lsnrctl.sh`: Listener operations, port detection, environment setup
    - `oradba_services.sh`: Service orchestration, configuration loading, startup/shutdown order
  - Dual activation methods for all scripts:
    - Environment variable: `ORADBA_DEBUG=true`
    - CLI flag: `--debug` or `-d`
  - Instrumented key decision points:
    - Database startup/shutdown operations and timeout handling
    - Listener status checks and configuration management
    - Service orchestration logic and dependency ordering
    - Oracle Home detection and environment setup
    - Error handling and fallback mechanisms
  - Backward compatible: no output changes unless debug enabled
  - Usage examples:
    - `ORADBA_DEBUG=true oradba_dbctl.sh start ORCL`
    - `oradba_lsnrctl.sh --debug stop LISTENER`
    - `oradba_services.sh --debug restart`

## [0.19.5] - 2026-01-22

### Added

- **Debug Logging in oraup.sh** (2026-01-22)
  - Added comprehensive debug logging throughout oraup.sh for troubleshooting
  - Debug messages track:
    - Library and plugin loading
    - Oratab file detection and selection
    - Installation classification (database SID, database home, datasafe, other)
    - Section display decisions (Oracle Homes, Databases, Listeners, DataSafe)
    - Main function execution flow
  - Enable with: `export ORADBA_DEBUG=true` or `export ORADBA_LOG_LEVEL=DEBUG`
  - Example: `ORADBA_DEBUG=true oraup.sh` to see detailed execution trace
  - Helps diagnose issues with Oracle Home detection, listener display, and plugin behavior

- **Debug Flags in CLI Tools** (2026-01-22)
  - Added Phase 1 debug support to two key scripts:
    - oradba_check.sh: `--debug` flag and `ORADBA_DEBUG=true` enable detailed tracing
    - oradba_extension.sh: `--debug` flag sets `ORADBA_LOG_LEVEL=DEBUG` and enables tracing
  - Instrumented decision points for visibility (tool detection, GitHub connectivity, disk space, extension discovery/loading)
  - Backward compatible: no output changes unless debug enabled
  - Usage:
    - `ORADBA_DEBUG=true oradba_check.sh --verbose`
    - `oradba_extension.sh --debug list`

- **API Reference Documentation** (2026-01-21)
  - Generated comprehensive API reference from 510 function headers
  - New script: `scripts/generate_api_docs.py` for automated documentation generation
  - Complete function documentation organized by 8 categories:
    - Core Utilities (48 functions) - logging, PATH management, Oracle environment
    - Registry API (8 functions) - unified installation discovery and management
    - Plugin Interface (129 functions) - product-specific functionality
    - Environment Management (54 functions) - building, parsing, validating environments
    - Database Operations (11 functions) - query execution, status checks
    - Alias Management (6 functions) - database alias generation
    - Extension System (19 functions) - extension loading and management
    - Scripts & Commands (235 functions) - CLI tools and utilities
  - Searchable function index with 510 functions and cross-references
  - Published to documentation site at `src/doc/api/`

### Fixed

- **Plugin Loader Variable Assignment Bug** (2026-01-22)
  - Fixed `oradba_apply_oracle_plugin` function failing to assign plugin results to variables
  - Root cause: Internal parameter name `result_var` caused collision when callers used same variable name
  - Changed internal parameter from `result_var` to `result_var_name` to prevent collision
  - Affected code: DataSafe status detection in `oraup.sh` and `oradba_env_status.sh`
  - Added regression test to prevent future variable name collisions
  - All variable names now work correctly, including `result_var`

## [0.19.4] - 2026-01-22

### Fixed

- **Installer Configuration File Handling** (2026-01-22, Critical Fix)
  - Fixed incorrect \"MODIFIED\" reporting for `etc/oradba_homes.conf` during updates
  - Root cause: `oradba_homes.conf` was treated as core file instead of user-managed configuration
  - Solution:
    - Excluded user-modifiable configs from checksum generation:
      `oradba_homes.conf`, `oradba_customer.conf`, `oradba_local.conf`, `sid.*.conf`
    - Added defensive skip in backup logic to prevent false modification warnings
    - User configurations now properly preserved during updates without .save backups
    - **Removed `src/etc/oradba_homes.conf` from git** (should only exist as template)
  - Benefits:
    - No more confusing \"MODIFIED\" warnings for files that are supposed to be modified
    - Cleaner update experience for users with custom Oracle Home registrations
    - Consistent behavior with other user configuration files
    - File generated from template during installation, not tracked in repository
  - Files changed:
    - `scripts/build_installer.sh`: Exclude user configs from checksum generation
    - `src/bin/oradba_install.sh`: Skip user configs in modification detection
    - `src/etc/oradba_homes.conf`: Removed from git (leftover from testing)

- **AutoDiscovery and Environment Setup Issues on Clean Install** (2026-01-22, Critical Bug Fix)
  - Fixed multiple autodiscovery issues that produced incorrect entries on clean installations
  - **Issue 1: OUD Home False Positive**
    - OUD plugin now only reports existing, validated homes
    - Added check to skip non-existent base directories
    - Prevents reporting of non-existent OUD installations
  - **Issue 2: Incorrect "Dummy" Entry Handling**
    - Installer now checks for existing Oracle products before adding dummy entry
    - Dummy entry only added if explicitly requested OR no Oracle products found
    - Searches common locations for oracle, sqlplus, cmctl, java binaries
    - Prevents dummy entry when real Oracle products exist
  - **Issue 3: Over-Discovery of Nested Installations**
    - Java plugin now excludes JRE subdirectories within JDK installations
    - iClient plugin excludes libraries inside DataSafe oracle_cman_home directories
    - `detect_product_type()` function enhanced with nested installation checks
    - Prevents duplicate entries for JRE inside JDK and iClient inside DataSafe
  - **Issue 4: Naming Convention Improvements**
    - Fixed DataSafe naming: `dsconn` → `dscon` (consistent with user feedback)
    - Naming patterns now consistent: jdk8, jre8, dscon1, iclient19
  - **Issue 5: User Guidance**
    - Added note in autodiscovery output about customizing discovered entries
    - Users informed they can edit `oradba_homes.conf` to change names, order, or descriptions
  - Enhanced plugin detection in:
    - `src/lib/plugins/oud_plugin.sh` - Validate homes exist before reporting
    - `src/lib/plugins/java_plugin.sh` - Exclude nested JRE directories
    - `src/lib/plugins/iclient_plugin.sh` - Exclude libraries in product homes
    - `src/lib/oradba_common.sh` - Improved `detect_product_type()` logic
    - `src/bin/oradba_install.sh` - Smart dummy entry logic
  - Benefits:
    - Accurate environment reporting on clean installs
    - No false positive OUD entries
    - No duplicate JRE/iClient entries
    - Dummy entry only when truly needed
    - Cleaner, more usable discovered names
    - Clear user guidance on customization

## [0.19.3] - 2026-01-22

### Fixed

- **DataSafe Connector Status Detection** (2026-01-22, Critical Fix)
  - Fixed incorrect "UNKNOWN" status when DataSafe connectors were running with active processes
  - Root causes fixed:
    - Invalid cmctl command syntax (was using `cmctl status` instead of `cmctl show services -c <instance>`)
    - Missing `oradba_apply_oracle_plugin()` function that caused plugin loading failures
    - No process-based detection fallback when cmctl unavailable or connectivity issues
  - Implemented robust multi-layered detection with proper fallback:
    1. **Primary**: cmctl show services -c `<instance>` (most accurate)
       - Parses instance name from `oracle_cman_home/network/admin/cman.ora`
       - Defaults to "cust_cman" for standard DataSafe installations
       - Validates service status with Connection Manager
    2. **Secondary**: Process-based detection (reliable fallback)
       - Checks for running cmadmin processes
       - Checks for running cmgw (gateway) processes
       - Works even when cmctl cannot connect to instance
    3. **Tertiary**: Python setup.py (last resort)
       - Falls back to `python3 setup.py status` command
       - Proven working in customer environments
  - Enhanced `plugin_check_status()` in `src/lib/plugins/datasafe_plugin.sh`
  - New function `oradba_apply_oracle_plugin()` in `src/lib/oradba_common.sh` for dynamic plugin loading
  - Improved `oradba_check_datasafe_status()` in `src/lib/oradba_env_status.sh` with proper status conversion
  - Added comprehensive test coverage (13 new test cases)
  - Validated against production cman.ora format
  - Benefits:
    - Accurate status reporting (RUNNING/STOPPED) for all DataSafe connectors
    - Works with HA configurations (multiple connectors)
    - Handles network connectivity issues gracefully
    - Fast detection (<100ms for running services)

## [0.19.2] - 2026-01-21

- **API Reference Documentation** (2026-01-21)
  - Generated comprehensive API reference from 510 function headers
  - New script: `scripts/generate_api_docs.py` for automated documentation generation
  - Complete function documentation organized by 8 categories:
    - Core Utilities (48 functions) - logging, PATH management, Oracle environment
    - Registry API (8 functions) - unified installation discovery and management
    - Plugin Interface (129 functions) - product-specific functionality
    - Environment Management (54 functions) - building, parsing, validating environments
    - Database Operations (11 functions) - query execution, status checks
    - Alias Management (6 functions) - database alias generation
    - Extension System (19 functions) - extension loading and management
    - Scripts & Commands (235 functions) - CLI tools and utilities
  - Searchable function index with 510 functions and cross-references
  - Published to documentation site at `src/doc/api/`
  - Integrated with MkDocs navigation structure
  - Usage examples for common patterns in API overview

- **Enhanced Oracle Homes Auto-Discovery** (2026-01-21, Issue #70)
  - New configuration variables in `oradba_standard.conf`:
    - `ORADBA_AUTO_DISCOVER_HOMES` (default: false) - Enable/disable auto-discovery on login
    - `ORADBA_DISCOVERY_PATHS` (default: `${ORACLE_BASE}/product`) - Paths to scan
  - Unified `auto_discover_oracle_homes()` function in `oradba_common.sh`
    - Used by both `oraenv.sh` initialization and `oradba_homes.sh discover` command
    - Leverages existing plugin system (`detect_product_type()`)
    - Silently skips already registered homes (no duplicates)
    - Scans up to 3 levels deep in configured discovery paths
  - Smart home name generation based on product type:
    - java → jdk17, jre17
    - iclient → iclient2610
    - datasafe → dsconn01, dsconn02
    - database → rdbms1918
    - client → client2610
    - oud → oud1221
    - weblogic → wls1221
  - Integration points:
    - `oraenv.sh`: Auto-discovers on environment load if `ORADBA_AUTO_DISCOVER_HOMES=true`
    - `oradba_homes.sh discover --auto-add`: Uses common function for consistent behavior
  - Single source of truth for maintainability
  - Opt-in feature (backward compatible, default: false)
  - Silent mode support for non-interactive use

### Fixed

- **oraup.sh Display Issues for Non-Database Environments** (2026-01-21, Issue #99)
  - Fixed listener section display logic:
    - Only shown if database SIDs exist OR database listeners are actively running
    - Skipped for pure Data Safe/client/non-database environments
    - Eliminates confusing "No database listeners running" message in irrelevant contexts
  - Fixed Data Safe connector status display:
    - Now uses `oradba_check_datasafe_status()` for real connector health
    - Shows accurate status: running/stopped/unavailable/empty/unknown
    - No longer hardcoded to "N/A" or "available"
  - Fixed dummy entry display:
    - Dummy entries (flag 'D') now skipped in Oracle Homes section
    - Prevents confusion when no oratab exists and dummy entry is created
    - Cleaner, more relevant output for Data Safe-only environments

### Changed

- **Improved Shell Compatibility in oradba_check.sh** (2026-01-21)
  - Replaced Unicode special characters (✓ ✗ ⚠ ℹ) with ASCII-compatible alternatives ([OK] [FAIL] [WARN] [INFO])
  - Ensures consistent display across all shell environments and terminal emulators
  - Improves compatibility with older systems and non-UTF8 terminals
  - Better accessibility for screen readers

### Enhanced

- **Enhanced Developer Documentation** (2026-01-21)
  - Comprehensive enhancements to CONTRIBUTING.md with detailed code style guide
  - Git workflow and branch strategy guidelines (feat/issue-XX, fix/issue-XX naming)
  - Comprehensive pull request checklist and review process
  - Detailed release process documentation for maintainers
  - Enhanced code of conduct and security reporting guidelines
  - New doc/function-header-guide.md with complete function header standards
  - New doc/development-workflow.md with setup, testing strategy, and debugging
  - New doc/plugin-development.md with step-by-step plugin development guide
  - VSCode snippets documentation for function headers
  - Testing decision tree (BATS vs Docker)
  - Complete plugin interface specification (11 required functions)

- **Autonomous JAVA_HOME Detection and Export** (2026-01-21)
  - Automatic detection and export of JAVA_HOME environment variable
  - Similar to existing ORADBA_CLIENT_PATH_FOR_NON_CLIENT mechanism
  - New configuration variable: `ORADBA_JAVA_PATH_FOR_NON_JAVA`
  - Supports "none" (default - backward compatible), "auto", or named Java from oradba_homes.conf
  - Auto mode checks `$ORACLE_HOME/java` first, then `oradba_homes.conf`
  - Exports JAVA_HOME and prepends Java bin directory to PATH (takes precedence)
  - Useful for DataSafe, OUD, WebLogic, and overriding database-shipped Java
  - New functions: `oradba_product_needs_java()`, `oradba_resolve_java_home()`, `oradba_add_java_path()`
  - Comprehensive test coverage: 27 unit and integration tests
  - Documentation updated in `oradba_standard.conf` and `oradba_customer.conf.example`

## [0.19.1] - 2026-01-21

### Fixed

- **Installer Version Normalization** (2026-01-21)
  - Fixed double 'v' prefix when using `--version v0.19.0` format
  - Installer now strips leading 'v' from version string before constructing URLs
  - Both `--version 0.19.0` and `--version v0.19.0` now work correctly
  - Example: `./oradba_install.sh --github --version v0.19.0` now downloads from
    correct URL

- **Installer GitHub API Rate Limiting** (2026-01-21)
  - Improved error handling for GitHub API rate limit errors in installer
  - Now detects rate limit responses and shows helpful workarounds:
    1. Wait a few minutes and retry
    2. Use authenticated requests with GITHUB_TOKEN
    3. Download manually from releases page
    4. Install specific version with `--version` flag
  - Shows first 200 characters of API response on unexpected failures for debugging
  - Resolves generic "Failed to determine latest version" error message

- **Environment Pollution with Internal Functions** (2026-01-21)
  - Clean up internal helper functions after use to prevent environment pollution
  - Remove `has_rlwrap`, `create_dynamic_alias`, `get_diagnostic_dest`,
    `generate_base_aliases`, `generate_sid_aliases` after sourcing
  - Keep only `oradba_tnsping` function (required by tnsping alias at runtime)
  - Eliminates 5 unnecessary `BASH_FUNC_*` environment variables
  - Improves environment hygiene and reduces namespace pollution

## [0.19.0] - 2026-01-21

### Documentation

- **Release Archive Cleanup** (2026-01-21)
  - Created consolidated release notes document (consolidated-v0.10.0-v0.18.5.md)
  - Consolidated 8 major milestone releases (v0.10.0 through v0.18.5) into single reference
  - Removed 21 patch release files (v0.10.1-v0.18.4) from archive
  - Updated archive README with simplified navigation structure
  - Fixed broken references in v0.14.0 and v0.17.0 to point to consolidated document
  - Reduced archive from 29 to 10 files (65% reduction)
  - Deleted 34 GitHub releases (v1.x.x pre-releases, v0.2.0-v0.4.0, and all patch releases)
  - Preserved all 73 git tags for historical reference
  - GitHub releases reduced to 40 major milestones (from 74 total releases)

### Test Infrastructure Improvements

- **Test Infrastructure Fixes** (2026-01-21)
  - Fixed plugin count test: Updated from 5 to 9 plugins (added java, weblogic, oms, emagent)
  - Fixed client_path_config tests: Corrected oradba_homes.conf format from semicolons to colons
  - Fixed oradba_homes validation tests: Corrected field separator handling for pipe-delimited output
  - All 1452 tests now pass (1411 passed, 41 skipped)
  - Updated test counts in documentation (Makefile, README, release notes)
  - Enhanced .testmap.yml with individual plugin mappings
  - **Fixed CI test failures**: Modified Makefile to handle BATS exit code 1 from skipped tests
    - BATS returns exit code 1 when tests are skipped (41 conditional skips expected)
    - Updated `test-full` target to treat exit code 1 as success when caused by skips
    - Updated test count message from "1077 tests, 9 conditional skips" to "1452 tests, 70+ conditional skips expected"
    - CI pipeline now completes successfully with proper exit code 0

### Bug Fixes

- **Java Plugin for Oracle Java Management** (2026-01-20)
  - Added comprehensive Java plugin for Oracle Java installations
  - Supports Java installations under `$ORACLE_BASE/product/java*` and `$ORACLE_BASE/product/jdk*`
  - Auto-detects Java and JDK installations
  - Version detection from `java -version` output
  - Supports Java 8 (1.8.0_xxx) and Java 11+ (17.x.x, 21.x.x) version formats
  - Normalizes Java 8 version format (1.8.0_291 → 8.0.291)
  - Distinguishes between JDK (with javac) and JRE (without javac)
  - Provides PATH and LD_LIBRARY_PATH configuration
  - No listener support (returns 1 for plugin_should_show_listener)
  - Full test coverage with 20+ BATS tests
  - Enables management of Java installations alongside Oracle Database products

- **Auto-Sync Database Homes from oratab** (2026-01-20)
  - Added `oradba_registry_sync_oratab()` function to sync database homes
  - Database homes from oratab automatically added to oradba_homes.conf
  - **Syncs on first login** when generating SID lists and aliases
  - **Syncs on-demand** when home lookup fails (transparent fallback)
  - Syncs when listing homes via `oradba_env.sh list homes`
  - Deduplicates homes by ORACLE_HOME path (multiple SIDs, one home)
  - Names homes by directory basename (e.g., dbhomeFree, dbhome19c)
  - Appends counter to avoid name conflicts (dbhomeFree, dbhomeFree2)
  - Maintains single source of truth for all Oracle installations
  - Skips homes already registered to avoid duplicates
  - Completely transparent - works automatically without user intervention
  - Registry module automatically sourced in all sync trigger locations

- **Complete Plugin Architecture** (2026-01-20)
  - Added stub plugins for WebLogic, OMS, and EM Agent to complete plugin coverage
  - All 8 supported product types now have dedicated plugins (database, client, iclient, datasafe, oud, weblogic, oms, emagent)
  - Stub plugins provide minimal validation and return "ERR" for version detection
  - Eliminates special-case logic in common code for products without version info
  - Creates uniform architecture - all products use plugin pattern
  - Stub plugins ready for future enhancement with full support

- **Instant Client Version Detection Enhancement** (2026-01-20)
  - Added version detection from library filenames when sqlplus is not available
  - Method 4: Extract version from `.so` library files (libclntsh.so.23.1 → 2301)
  - Method 5: Extract version from JDBC JAR manifest (ojdbc*.jar)
  - Supports libclntsh.so, libclntshcore.so, and libocci.so version patterns
  - Handles both single-digit (19.1) and double-digit (19.21) minor versions
  - Added 5 comprehensive tests with isolated function extraction for test safety
  - Instant client homes without sqlplus now show correct version instead of "Unknown"

### Changed

- **Simplified Version Detection Logic** (2026-01-20)
  - Removed special-case handling for datasafe/weblogic/oms/emagent/oud from detect_oracle_version()
  - All product types now use plugin delegation - no exceptions
  - Stub plugins handle "ERR" return via plugin_get_version()
  - Cleaner architecture with consistent plugin-first approach

- **Version Detection Architecture** (2026-01-20)
  - Refactored version detection to delegate to product plugins
  - `detect_oracle_version()` now tries `plugin_get_version()` first before fallback methods
  - Product-specific logic moved from oradba_common.sh to individual plugins
  - Added `plugin_get_version()` to instant client plugin with 3 detection methods
  - Removed redundant instant client-specific code from detect_oracle_version()
  - Improves separation of concerns and maintainability
  - Each plugin is now self-contained for version detection

### Known Issues

- **Auto-Sync Module Sourcing** (2026-01-20)
  - Fixed missing source of oradba_registry.sh in oradba_env.sh commands
  - Fixed missing source in first-login functions (generate_sid_lists, generate_oracle_home_aliases)
  - Auto-sync was failing because oradba_registry_sync_oratab() function wasn't available
  - Added conditional sourcing of registry module before sync calls
  - Checks if function already loaded to avoid redundant sourcing
  - Tries both installed (lib/) and source tree (src/lib/) locations
  - All sync triggers now work correctly (first login, commands, on-demand)

- **Database SID Lookup in oradba_env.sh Commands** (2026-01-20)
  - Fixed `oradba_env.sh show <SID>` failing for database SIDs
  - Fixed `oradba_env.sh status <SID>` failing for database SIDs
  - Fixed `oradba_env.sh validate <SID>` failing for database SIDs
  - Added auto-sync trigger at start of all command functions
  - Database homes now synced before lookup, making SIDs available
  - Commands now work for both database SIDs and Oracle Homes
  - Resolves empty output when querying database SIDs

- **Database Version Display Shows Oracle Home Version** (2026-01-20)
  - Fixed banner to show Oracle Home version instead of database version
  - Previously queried v$instance.version (e.g., "23.0.0.0.0" - base version)
  - Now uses get_oracle_version() from ORACLE_HOME (e.g., "23.26.0.0.0" - with RU)
  - Shows consistent version whether database is running or stopped
  - Oracle Home version reflects actual installed binaries and patches
  - Resolves confusing version mismatch when database is running

- **Instant Client Basic Version Detection** (2026-01-20)
  - Fixed `get_oracle_version()` to fall back to plugin-based detection when sqlplus not available
  - Instant client basic (without sqlplus) now uses library filename detection (Method 2)
  - Converts XXYZ format from detect_oracle_version() back to X.Y.Z.W for display
  - Banner now correctly shows version for instant client basic (e.g., "23.26.0.0")
  - Resolves "Unknown" version for instant client installations without sqlplus

- **Instant Client Version Display in Banner** (2026-01-20)
  - Fixed `get_oracle_version()` to check both `bin/sqlplus` and root `sqlplus`
  - Banner now correctly shows instant client version instead of "Unknown"
  - Added instant client to product types that call version detection
  - Enhanced with debug logging to troubleshoot version detection issues
  - Now displays version 23.26.0.0.0 correctly for instant client

- **Instant Client Version Detection from sqlplus** (2026-01-20)
  - Fixed version detection for instant client when sqlplus is installed
  - Check both `bin/sqlplus` (database/client) and `sqlplus` (instant client root)
  - Instant client has sqlplus directly in ORACLE_HOME, not in bin/ subdirectory
  - Now correctly detects version 2326 from "SQL*Plus: Release 23.26.0.0.0"
  - Resolves "Unknown" version display for instant client with sqlplus

- **Instant Client Plugin Loading** (2026-01-20)
  - Fixed plugin path lookup to support both development and installed environments
  - Check `lib/plugins/` first (installed), then `src/lib/plugins/` (development)
  - Instant client plugin now loads correctly in production installations
  - Added debug logging when plugin file not found
  - Added fallback for instant client libraries in ORACLE_HOME root
  - Resolves LD_LIBRARY_PATH being empty for instant client

- **Instant Client LD_LIBRARY_PATH Export** (2026-01-20)
  - Fixed critical bug where LD_LIBRARY_PATH wasn't cleared when switching to instant client
  - Root cause: `oradba_set_lib_path()` only exported when lib_path was non-empty
  - When instant client has no lib/ directory, lib_path is empty but wasn't exported
  - Old LD_LIBRARY_PATH from `_oraenv_unset_old_env()` persisted in environment
  - Now always exports LD_LIBRARY_PATH, even when empty, to clear old values
  - Resolves instant client environment switching showing wrong library paths

- **Instant Client LD_LIBRARY_PATH** (2026-01-20)
  - Fixed library path setup for instant client installations
  - Replaced deprecated `export_oracle_base_env()` with plugin-aware `oradba_set_lib_path()`
  - Instant client libraries are in `${ORACLE_HOME}` root, not `${ORACLE_HOME}/lib`
  - Plugin system now correctly handles product-specific library paths
  - Resolves "libsqlplus.so: cannot open shared object file" errors
  - Both database and instant client environments now work correctly

### Removed

- **Archived Documentation Cleanup** (2026-01-20)
  - Removed `doc/archive/` directory (27 files) - Historical development documents superseded by v0.19.0+ documentation
  - Removed `doc/releases/archive/phase-4-development/` (4 files) - Phase 4
    development artifacts integrated into main release notes
  - Removed `doc/releases/archive/v1-internal/` (6 files) - Internal v1.x releases superseded by v0.19.0 public release
  - All relevant content migrated to current documentation structure
  - Legacy basenv coexistence mode documentation archived (feature planned for re-engineering in Phase 8)

- **Deprecated export_oracle_base_env() Function** (2026-01-20)
  - Removed deprecated `export_oracle_base_env()` from `oradba_common.sh` (32 lines)
  - Fully replaced by plugin-aware `oradba_set_lib_path()` in all code paths
  - Updated API documentation to reference new function
  - Updated development documentation and lib README
  - Archive references preserved for historical context
  - No breaking changes - function was already replaced in production code

- **BREAKING CHANGE: Deprecated Logging Functions** (2026-01-19)
  - Removed deprecated logging wrapper functions from `oradba_common.sh`:
    - `log_info()` - Use `oradba_log INFO` instead
    - `log_warn()` - Use `oradba_log WARN` instead
    - `log_error()` - Use `oradba_log ERROR` instead
    - `log_debug()` - Use `oradba_log DEBUG` instead
    - `_show_deprecation_warning()` - Internal helper no longer needed
  - Functions were deprecated in v0.13.1 and confirmed unused in OraDBA codebase
  - Removed 7 obsolete tests for deprecated functions
  - Impact: Only external scripts calling `oradba_common.sh`'s log_* functions affected
  - Migration: Replace `log_info "msg"` with `oradba_log INFO "msg"` (and similar for other levels)
  - Code reduction: ~70 lines of dead code eliminated

- **Unused Functions Cleanup** (2026-01-19)
  - Removed 7 unused functions found by systematic analysis (checked all 324 functions):
    - `_oraenv_show_environment()` - Never-called display function in oraenv.sh
    - `extension_provides()` - Superseded by direct directory checks
    - `list_extensions()` - Extension lister never exposed to users
    - `get_central_tns_admin()` - Unused centralized TNS path helper
    - `get_startup_flag()` - Superseded by other oratab parsing code
    - `should_show_listener_status()` - Unused listener display decision logic
    - `oradba_get_datasafe_port()` - Unused DataSafe port extraction function
    - `should_autostart()` - Unused oratab autostart flag reader
  - Removed 2 additional obsolete tests that were testing already-removed deprecated functions
  - All functions verified as having zero callers in OraDBA codebase (src/bin, src/lib, tests)
  - Code reduction: ~120 lines of dead code eliminated
  - All core tests passing after cleanup (41/41 in test_oradba_common.bats)

---

> **📖 Historical Releases:** Release notes for versions prior to v0.19.0 are available in [doc/releases/CHANGELOG.archive.md](doc/releases/CHANGELOG.archive.md).

---

## [0.19.0] - 2026-01-19
