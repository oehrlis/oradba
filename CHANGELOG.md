# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

### Fixed

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

## [0.19.0] - 2026-01-19

**Note**: This release consolidates all changes since the last official release (0.18.x).
Previous version numbers 1.x.x and 2.x.x were development-only and are being reset to
maintain semantic versioning continuity.

### Added

- **Complete Function Documentation** (2026-01-19)
  - Achieved 100% function documentation coverage: **437/437 functions documented**
  - Documented all functions in `src/bin/` (235 functions) and `src/lib/` (147 functions)
  - Added comprehensive headers to all functions with:
    - Purpose: Clear description of function responsibility
    - Args: Detailed parameter documentation with types and defaults
    - Returns: Exit codes and success/failure conditions
    - Output: Description of stdout/stderr behavior
    - Notes: Dependencies, special cases, implementation details
  - Documentation progression:
    - Starting point: 306/437 (70%)
    - Phase 1 (70%→80%): Large files (sqlnet, check, version) → 350/437
    - Phase 2 (80%→90%): Medium files (logrotate, services, lsnrctl, help, dbctl) → 396/437
    - Phase 3 (90%→100%): Small files (seps_pwd, sync scripts, longops, setup, services_root) → 437/437 ✅
  - Key files completed in final push:
    - `oradba_lsnrctl.sh` (8/8): Listener control operations
    - `oradba_help.sh` (8/8): Help system and documentation
    - `oradba_dbctl.sh` (8/8): Database start/stop control
    - `get_seps_pwd.sh` (8/8): Wallet password retrieval
    - `sync_to_peers.sh` (7/7): Peer synchronization outbound
    - `sync_from_peers.sh` (7/7): Peer synchronization inbound
    - `longops.sh` (6/6): Long operations monitoring
    - `oradba_setup.sh` (5/5): Post-installation setup
    - `oradba_services_root.sh` (5/5): Root-level service management
    - `oradba_services.sh` (9/9): Service orchestration (completed)
  - Benefits:
    - Complete API documentation for all functions
    - Improved code maintainability and understanding
    - Better onboarding for new contributors
    - Foundation for automated API reference generation
    - Clear function contracts and interfaces
  - All 180 tests passing with no regressions

### Changed

- **Logging System Migration** (2025-01-21)
  - Migrated 95 legacy logging calls to modern `oradba_log` function
  - Affected files: `oradba_homes.sh` (50 calls), `oraenv.sh` (40 calls), `dbstatus.sh` (5 calls)
  - Benefits:
    - Unified logging format across all OraDBA scripts
    - Better log level control via `ORADBA_LOG_LEVEL`
    - Consistent output formatting
    - Preparation for future syslog integration
  - Legacy functions (`log_error`, `log_warn`, `log_info`, `log_debug`) remain as deprecated wrappers
  - Modern usage: 512 calls to `oradba_log` (84% adoption in core scripts)
  - All 180 tests passing with no regressions

### Refactored

- **Critical Function Refactoring in oraenv.sh** (2025-01-21)
  - Refactored `_oraenv_set_environment`: 210 → 65 lines (69% reduction)
    - Extracted 6 helper functions for Oracle Home setup, registry lookup, auto-discovery,
      product adjustments, environment variables, and configuration loading
    - Each helper function has single responsibility and clear boundaries
  - Refactored `_oraenv_prompt_sid`: 128 → 37 lines (71% reduction)
    - Extracted 3 helper functions for data gathering, UI display, and input parsing
    - Improved testability and user interaction handling
  - Total: 9 new helper functions with maximum size of 65 lines
  - Benefits:
    - Reduced complexity from 210-line monolithic functions to focused helpers
    - Improved maintainability with clear separation of concerns
    - Better testability: each function independently testable
    - Easier debugging with focused function boundaries
  - All 180 tests passing with no functional changes

### Documentation

- **Function Documentation in oraenv.sh** (2025-01-21)
  - Added comprehensive function headers to all 17 functions in oraenv.sh (100% coverage)
  - Documented functions include:
    - Core: `_oraenv_parse_args`, `_oraenv_usage`, `_oraenv_find_oratab`, `_oraenv_main`
    - User interaction: `_oraenv_gather_available_entries`, `_oraenv_display_selection_menu`, `_oraenv_parse_user_selection`
    - Environment setup: `_oraenv_handle_oracle_home`, `_oraenv_lookup_oratab_entry`,
      `_oraenv_auto_discover_instances`, `_oraenv_apply_product_adjustments`,
      `_oraenv_setup_environment_variables`, `_oraenv_load_configurations`
    - Utilities: `_oraenv_prompt_sid`, `_oraenv_set_environment`, `_oraenv_unset_old_env`, `_oraenv_show_environment`
  - Each header includes: Purpose, Args (with types), Returns, Output, Notes (dependencies/special cases)
  - Benefits:
    - Improved code understanding for maintainers
    - Better onboarding for new contributors
    - Clear function interfaces and contracts
    - Documentation for all helper functions created during refactoring
  - Codebase progress: 188/374 functions documented (50%)

- **Function Documentation in oradba_homes.sh** (2025-01-21)
  - Completed documentation for all 11 functions in oradba_homes.sh (100% coverage)
  - Added comprehensive header to `main()` function
  - Documented functions include:
    - `show_usage`: Display usage information
    - `list_homes`: List all registered Oracle Homes
    - `show_home`: Show details of specific Oracle Home
    - `add_home`: Add new Oracle Home to configuration
    - `remove_home`: Remove Oracle Home from configuration
    - `discover_homes`: Auto-discover Oracle installations
    - `validate_homes`: Validate registered Oracle Homes
    - `export_config`: Export configuration to file
    - `import_config`: Import configuration from file
    - `dedupe_homes`: Remove duplicate entries
    - `main`: Main entry point dispatcher
  - Benefits:
    - Complete API documentation for Oracle Homes management
    - Clear command-line interface documentation
    - Better understanding of configuration file operations
  - Combined progress: 28 functions across 2 critical files (oraenv.sh + oradba_homes.sh)
  - Updated codebase progress: 241/437 functions documented (55%)
  - Benefits:
    - Improved code understanding for developers and contributors
    - Clear API contracts for each function
    - Better onboarding documentation
    - Foundation for API documentation generation
  - Documentation coverage progress: 188/374 functions (50% codebase-wide)

- **Oracle Home Management Support** (2026-01-16)
  - `oradba_env.sh` now fully supports Oracle Homes from oradba_homes.conf
  - All commands (list, show, status, validate) work with Oracle Home names/aliases
  - Added lookup by name or alias for DataSafe, Instant Client, OUD, WebLogic, etc.
  - Automatic fallback to oratab for database SIDs

- **GitHub Copilot Instructions** (2026-01-16)
  - Added comprehensive AI coding guidelines for OraDBA project
  - Added extension-specific instructions for all extension templates
  - Documented database query patterns, logging conventions, test workflows
  - Created `.github/.scratch/` for temporary AI-generated working files

- **DataSafe On-Premises Connector Support** (2026-01-15)
  - Added DataSafe product type detection for oracle_cman_home structure
  - Implemented direct cmctl status checking (50-100ms faster than Python)
  - Added proper PATH setup for DataSafe: `$ORACLE_HOME/oracle_cman_home/bin`
  - Added proper LD_LIBRARY_PATH setup: `$ORACLE_HOME/oracle_cman_home/lib`
  - Validation no longer requires sqlplus for DataSafe homes
  - Status checks support Data Safe connectors showing RUNNING/STOPPED/UNKNOWN
  - `oraup.sh` now displays DataSafe connectors with live status

- **Instant Client (ICLIENT) Product Type** (2026-01-15)
  - Added ICLIENT as distinct product type (separate from CLIENT)
  - Auto-detection based on libclntsh.so presence and missing bin directory
  - Proper PATH setup: ORACLE_HOME directly (not bin subdirectory)
  - Proper LD_LIBRARY_PATH setup: ORACLE_HOME directly
  - Validation adjusted for client-only features

- **PATH Deduplication** (2026-01-15)
  - Added `oradba_dedupe_path()` function to remove duplicate PATH entries
  - Automatically deduplicates PATH after environment setup
  - Automatically deduplicates LD_LIBRARY_PATH and platform equivalents
  - Prevents repeated JDK paths and other duplicates from accumulating
  - Final deduplication after custom config loading ensures all paths cleaned
  - Consolidated all deduplication functions to use single source of truth
  
- **Dummy Entry Configuration** (2026-01-15)
  - Added `ORADBA_SHOW_DUMMY_ENTRIES` configuration variable (default: true)
  - Set to false in oradba_customer.conf to hide dummy entries
  - Useful for environments that will never have Oracle installations
  - Enhanced installer comments with instructions to hide dummy entries
  
- **Directory Existence Validation** (2026-01-15)
  - PATH directories now validated for existence before addition
  - Non-existent directories no longer added to PATH
  - Prevents warning messages about missing directories
  
- **Client Display Improvements** (2026-01-15)
  - `oraup.sh` now hides dummy entries for client-only installations
  - Cleaner output when no databases are installed

### Fixed

- **oradba_env.sh Delimiter Parsing** (2026-01-16)
  - Fixed `cmd_show`, `cmd_validate`, and `cmd_status` to use correct colon `:` delimiter
  - Updated grep patterns to match actual oradba_homes.conf format
  - Resolves issue where entire config line was displayed as name field
  - User-reported: `oradba_env.sh show dscontest` now correctly splits and displays fields

- **oradba_env.sh Validate Command for Oracle Homes** (2026-01-16)
  - Apply DataSafe ORACLE_HOME adjustment (oracle_cman_home subdirectory)
  - Display product type from config file instead of auto-detecting
  - Show target name when validating specific target
  - Clear ORACLE_SID when validating Oracle Home (not a database SID)
  - Temporary ORACLE_HOME override during validation to test specific homes

- **oradba_env.sh Delimiter Parsing (Enhanced)** (2026-01-16)
  - Fixed `cmd_show`, `cmd_validate`, and `cmd_status` to use correct colon `:` delimiter
  - Updated grep patterns to match actual oradba_homes.conf format
  - Resolves issue where entire config line was displayed as name field
  - User-reported: `oradba_env.sh show dscontest` now correctly splits and displays fields

- **oradba_env.sh Validate Command for Oracle Homes (Enhanced)** (2026-01-16)
  - Apply DataSafe ORACLE_HOME adjustment (oracle_cman_home subdirectory)
  - Display product type from config file instead of auto-detecting
  - Show target name when validating specific target
  - Clear ORACLE_SID when validating Oracle Home (not a database SID)
  - Restore environment variables after validation completes
  - Resolves confusion where current environment's values were mixed with target validation

- **PATH Deduplication** (2026-01-16)
  - Fixed PATH accumulation when sourcing environment repeatedly
  - Added deduplication in `load_config_file()` after sourcing configuration files
  - Uses `oradba_dedupe_path` if available, falls back to awk implementation
  - Resolves issue where JDK and other paths accumulated on each environment switch
  - User-reported: Paths went from 1→2→3→4 copies on repeated sourcing

- **DataSafe ORACLE_HOME Adjustment** (2026-01-16)
  - Fixed ORACLE_HOME to point to `oracle_cman_home` subdirectory for DataSafe installations
  - Implemented in three code paths:
    - `oraenv.sh` for oratab entries (lines 470-479)
    - `set_oracle_home_environment()` for Oracle Homes (lines 1640-1668)
    - `oradba_env_builder.sh` for Phase 2 architecture (lines 343-365)
  - Sets additional DataSafe variables: `DATASAFE_HOME`, `DATASAFE_INSTALL_DIR`, `DATASAFE_CONFIG`
  - Adjusts PATH to use `oracle_cman_home/bin` instead of parent directory
  - User-reported: DataSafe commands now work correctly with proper paths

- **Status Display Concatenation Bug** (2026-01-16)
  - Fixed "unknownavailable" concatenation in oraup.sh Oracle Homes section
  - Fixed same issue in Data Safe Status section
  - Removed problematic `|| echo` fallbacks that caused status string concatenation
  - Status now correctly shows: unavailable, unknown, running, or stopped

- **Status Logic for Missing Installations** (2026-01-16)
  - Added directory existence checks before checking connector status
  - "unavailable": directory doesn't exist
  - "unknown": directory exists but cmctl not found/executable  
  - "stopped": installation exists but connector not running
  - "running": connector is actively running (with port number)

- **Display Alignment Issues** (2026-01-16)
  - Changed "Connection Manager" to "Connector" in Data Safe Status section
  - Fixed column alignment across all status sections
  - Consistent 17-character width for type column

- **Oracle Homes List Format** (2026-01-16)
  - Fixed parsing of oradba_list_all_homes output (NAME|PATH|TYPE|ORDER|ALIAS)
  - Display format now: NAME TYPE PATH (consistent with SID listing)
  - Shows alias if different from name, otherwise shows name

## [0.18.x] - Previous Official Release

- Added "Instant Client" product type display name

- **Archived Version Warning** (2026-01-15)
  - Added notification in `oradba_install.sh` for archived pre-1.0 releases
  - Displays informative message when installing versions 0.9.4 through 0.18.5
  - Warns users that archived versions are for historical reference only
  - Recommends upgrading to v1.0.0 or later for production use

- **TNS Ping Wrapper for Instant Client** (2026-01-15)
  - Added `oradba_tnsping()` function with transparent fallback to sqlplus -P
  - Automatically uses native tnsping when available (database/client installations)
  - Falls back to sqlplus -P for Instant Client environments (no tnsping)
  - Supports TNS names (FREE, FREE.world) and EZ Connect format (host:port/service)
  - Rejects connect descriptors with helpful error message (sqlplus -P limitation)
  - Shows informational notice in verbose/debug mode when using fallback
  - Created tnsping alias automatically via generate_sid_aliases()
  - Includes link to specific release notes on GitHub

### Fixed

- **DataSafe Environment Issues** (2026-01-15)
  - Fixed "Unknown product type" error for DataSafe homes
  - Fixed "sqlplus not found" error (sqlplus not required for DataSafe)
  - Fixed incorrect PATH (was adding non-existent bin directory)
  - Fixed incorrect LD_LIBRARY_PATH (was not using oracle_cman_home/lib)
  - Fixed oradba_homes.conf parsing delimiter (semicolon → colon)
  - Optimized status checking to use direct cmctl (no Python overhead)
  - `set_oracle_home_environment()` now reads product type from config first
  - Falls back to filesystem detection only if not in oradba_homes.conf
  - `show_oracle_home_status()` skips sqlplus version check for non-DB products
  - Version shown as 'N/A' for products without sqlplus

- **PATH Duplication Issues** (2026-01-15)
  - Fixed custom variables (JAVA_HOME, etc.) being added multiple times
  - Final PATH deduplication now runs after all config files loaded
  - Consolidated deduplication functions to use single implementation
  - `deduplicate_path()` and `deduplicate_sqlpath()` now use `oradba_dedupe_path()`
  - Includes fallback for standalone use

- **Oracle Homes Duplicate Prevention** (2026-01-15)
  - Added duplicate detection before adding entries to oradba_homes.conf
  - Checks both NAME and PATH fields for existing entries
  - Shows clear error with existing entry name if duplicate found
  - New `dedupe` command to clean existing duplicates
  - Prevents DataSafe and other homes from appearing twice

- **Client Environment Issues** (2026-01-15)
  - ICLIENT product type now properly detected and handled
  - Instant Client PATH now includes ORACLE_HOME directly (not bin subdir)
  - Instant Client LD_LIBRARY_PATH now includes ORACLE_HOME directly
  - Client validations skip checks for database-specific features
  - Added 'iclient' to valid product types in oradba_homes.sh

- **Display Issues** (2026-01-15)
  - Fixed DataSafe status line break in oraup.sh display
  - Status field now strips newlines and extra spaces
  - Ensures single-line display for all Oracle Home status

- **Version Detection** (2026-01-15)
  - Fixed oradba_check.sh version display (was showing 0.14.1)
  - Checks installed location first (bin/../VERSION)
  - Falls back to repo location (src/bin/../../VERSION)
  - Final fallback to hardcoded version (1.1.0)

- **Parser Format Alignment** (2026-01-15)
  - Complete refactor of `oradba_env_parser.sh` to match actual file format
  - Fixed field order mismatch: now uses NAME:PATH:TYPE:ORDER:ALIAS:DESCRIPTION:VERSION
  - Updated all dependent functions (oradba_find_home, oradba_get_home_metadata, oradba_list_all_homes)
  - Added support for searching by NAME, ALIAS, or PATH
  - Backward compatibility with old field names (Product → Type, etc.)

- **Code Quality Issues** (2026-01-15)
  - Fixed duplicate lines in `oradba_env_parser.sh` causing parse errors
  - Fixed SC2155 shellcheck warning (declare and assign separately)
  - Fixed markdown line length issues (MD013)

### Changed

- **Display Improvements** (2026-01-15)
  - oraup.sh now hides client/iclient homes from Oracle Homes section
  - Data Safe connectors now show proper status (running/stopped) with connector name
  - Dummy entries for client-only installations are no longer displayed
  - Grid Infrastructure product type now shows as "Grid Infrastructure" instead of "grid"
  - Product type display uses proper capitalization

- **Environment Management Cleanup** (2026-01-15)
  - Removed unnecessary function exports from all 6 environment management libraries
  - Eliminated 47 `export -f` statements that were polluting bash environment
  - Functions remain available when libraries are sourced (no functionality change)
  - Cleaned up `BASH_FUNC_*` entries visible in environment output
  - Affected files: `oradba_env_config.sh`, `oradba_env_builder.sh`,
    `oradba_env_parser.sh`, `oradba_env_validator.sh`, `oradba_env_changes.sh`,
    `oradba_env_status.sh`

### Documentation

- **User Documentation Updates** (2026-01-15)
  - Updated README.md with DataSafe and Instant Client support details
  - Added ICLIENT to Hierarchical Configuration product sections
  - Expanded Oracle Homes Management with all product types
  - Updated Intelligent Environment Setup to list all supported types
  - Enhanced Status & Monitoring description for Data Safe connectors

- **Developer Documentation Updates** (2026-01-15)
  - Updated doc/architecture.md with comprehensive product type list
  - Added descriptions for RDBMS, CLIENT, ICLIENT, GRID, ASM, DATASAFE, OUD, WLS, OMS
  - Enhanced Validator section with product detection logic details
  - Added oradba_check_datasafe_status to Status section

- **Release Notes** (2026-01-15)
  - Created comprehensive v1.1.0 release notes
  - Documented all new features, fixes, and improvements
  - Added migration guide and known issues

- **Documentation Cleanup** (2026-01-15)
  - Archived `v1.0.0-release-plan.md` to `doc/archive/` (release complete)
  - Archived `release-testing-checklist.md` to `doc/archive/` (superseded by automated_testing.md and manual_testing.md)
  - Updated `doc/README.md` to reflect current documentation structure
  - Added clarification note to `doc/oradba-env-design.md` (design reference document)
  - Kept design document for historical design rationale
  - Commit: 58703eb

- **README Updates for v1.0.0** (2026-01-15)
  - Updated test count from 892 to 910 tests in `tests/README.md`
  - Fixed environment library count (6 libraries, not 4) in test documentation
  - Updated version to 1.0.0 in validation scripts: `validate_project.sh`, `validate_test_environment.sh`
  - Updated `script_template.sh` to v1.0.0
  - Expanded `src/log/README.md` with comprehensive logging documentation
  - Added log location priority, naming conventions, rotation guidance
  - Updated all README files to reference v1.0.0 as current release
  - Fixed markdown linting errors (trailing spaces, line length, table alignment)
  - Verified documentation accuracy across all project README files
  - Commit: 3afacc1

- **Validation Script Updates** (2026-01-15)
  - Updated `scripts/validate_project.sh` to reflect v1.0.0 structure
  - Removed checks for archived files: `structure.md`, `version-management.md`, `markdown-linting.md`
  - Content now covered in `development.md` and `architecture.md`
  - Fixed `oradba_homes.conf.template` path check (moved to `src/templates/etc/`)
  - Added checks for all 6 environment management libraries (parser, builder, validator, config, status, changes)
  - Added file counting for SQL scripts (126) and RMAN scripts (34)
  - Added checks for all 28 BATS test files (was checking only 15)
  - Reorganized sections: core libraries, environment libraries, configuration files, template examples
  - All validation checks now pass successfully

## [1.0.0] - 2026-01-15

### Added

- **Comprehensive Automated Testing Infrastructure** (2026-01-15)
  - Docker-based automated testing using Oracle 26ai Free container
  - 68 comprehensive integration tests covering all OraDBA functionality
  - 98% pass rate (67/68 tests passing, 2 skipped for environment limitations)
  - Tests complete in ~3 minutes vs hours of manual testing
  - Test suites covering:
    - Installation & updates (8 tests)
    - Environment loading & configuration (6 tests)
    - Auto-discovery functionality (3 tests)
    - Oracle Homes management (7 tests)
    - Extensions creation & management (3 tests)
    - Service control: listener & database (12 tests)
    - Database status reporting (3 tests)
    - Validation & checking tools (8 tests)
    - Utility scripts (6 tests including version, help, dbstatus, longops)
    - Output format variations (12 tests)
    - Aliases & functions (8 tests)
  - Test results persist to `tests/results/` on host (not lost with container removal)
  - Using `docker cp` for reliable test result extraction
  - Test logs cleaned with `make clean-all`
  - Fixed database readiness detection: grep pattern `^\s+1$` handles SQL*Plus whitespace
  - CI/CD ready automated testing infrastructure
  - Partially addresses issue #20 - Complex integration tests requiring real database
  - Commits: 0393790, c8f4d92, 868ab68, 65e80cb, 2562ca9, 86a7888, c8204d2

- **Auto-Discovery of Running Oracle Instances** (2026-01-15)
  - Automatically detects running Oracle instances when oratab is empty
  - New function: `discover_running_oracle_instances()` in oradba_common.sh
  - Detects db_smon_*, ora_pmon_*, and asm_smon_* processes for current user only
  - Extracts ORACLE_HOME from `/proc/{pid}/exe` with fallback to `/proc/{pid}/environ`
  - Persists discovered instances to oratab automatically
  - Fallback to local oratab ($ORADBA_PREFIX/etc/oratab) if permission denied
  - New function: `persist_discovered_instances()` for automatic oratab updates
  - Duplicate prevention: won't add instances already in oratab
  - Configurable via `ORADBA_AUTO_DISCOVER_INSTANCES` (default: true)
  - Integrated into both oraenv.sh and oraup.sh
  - Added comprehensive manual testing documentation with 6 test cases
  - Commits: b503b0b, bbdfc80, c30e697, a9e2e6a, 8685403, bc5780f, 6070197

### Fixed

- **Auto-Discovery Bugs** (2026-01-15)
  - Fixed undefined function error: `display_database_entry: command not found`
  - Fixed syntax error: `[[: 0\n0:` caused by grep -cv exit code issue
  - Fixed SID matching in discovery using case-insensitive awk instead of grep
  - Fixed empty line filtering in discovered instance parsing
  - Root cause: `grep -cv` returns exit code 1 when count is 0, causing `|| echo "0"`
    to execute and output second zero
  - Solution: Changed to `entry_count=$(grep -cv ...) || entry_count=0`
  - All discovery errors resolved and tested
  - Commits: bbdfc80, bc5780f, a9e2e6a, 8685403

- **SID Configuration Variable Isolation** (2026-01-14)
  - Fixed environment pollution where SID-specific variables persisted across environment switches
  - Added `cleanup_previous_sid_config()` to unset previous SID variables
  - Added `capture_sid_config_vars()` to track new SID variables
  - Variables from `sid.<SID>.conf` now properly cleaned up on SID switch
  - Shared configs (core, standard, customer, sid.*DEFAULT*) remain global as intended
  - Test: `tests/manual/test_sid_variable_isolation.sh` (7 tests passing)

- **oradba_homes.sh Critical Fixes** (2026-01-14)
  - Fixed syntax error at line 966: missing closing parenthesis `((errors++)` → `((errors++))`
  - Fixed show command to accept both paths and names/aliases
  - Fixed description truncation in list output (now shows full text or truncates at 39 chars
    with ellipsis)
  - Added alias conflict detection with existing SID aliases
  - Improved import validation to reject invalid format, paths, and product types
  - Fixed shellcheck warnings: unused variables (home, flag) → (underscore_home, underscore_flag)
  - Improved grep usage: `grep | wc -l` → `grep -c` for better performance

### Changed

- **Environment Isolation** (2026-01-14)
  - Enhanced `load_config()` to cleanup previous SID variables before loading new SID
  - SID-specific variables now properly isolated between environments
  - Critical Oracle/OraDBA variables (ORACLE_*, ORADBA_*, PATH, etc.) protected from cleanup

- **Listener Status Display Logic** (2026-01-15)
  - Changed from AND logic to OR logic: show if ANY condition met
  - Condition 1: tnslsnr process running (any user)
  - Condition 2: Oracle database binary installed (oratab or oradba_homes.conf)
  - Exception: Client-only + listener.ora (no tnslsnr, no database) = hidden
  - Commits: 978d1fa, 050bb9b, 62625b1, 018f809, 9354660

### Documentation

- **Manual Testing Updates** (2026-01-15)
  - Updated auto-discovery test cases to reflect persistence behavior
  - Added Test Case 1b: Permission denied fallback scenario
  - Updated pass criteria to include persistence verification
  - Added duplicate prevention testing
  - Added listener status display testing (6 test cases)
  - Section numbers removed from manual_testing.md for better readability

- **SID Variable Isolation Test** (2026-01-14)
  - New test: `tests/manual/test_sid_variable_isolation.sh`
  - 7 automated unit tests for cleanup/capture functions
  - Manual test instructions for real Oracle environments
  - Color-coded output and comprehensive test reporting

## [1.0.0] - 2026-01-XX

### Breaking Changes

**Architecture Rewrite**: OraDBA v1.0.0 represents a complete architecture redesign with breaking changes from v0.18.5

- **New Library-Based System**: Replaced monolithic scripts with modular library architecture
  - Environment Parser (oradba_env_parser.sh) - 13 functions
  - Environment Builder (oradba_env_builder.sh) - 12 functions  
  - Environment Validator (oradba_env_validator.sh) - 11 functions
  - Configuration Management (oradba_env_config.sh) - 8 functions
  - Status Checking (oradba_env_status.sh) - 8 functions
  - Change Detection (oradba_env_changes.sh) - 7 functions

- **Configuration System Overhaul**: New section-based hierarchical configuration
  - 6-level configuration hierarchy (core → standard → local → customer → services → SID)
  - INI-style section format: [DEFAULT], [RDBMS], [CLIENT], [ASM], etc.
  - Variable expansion: ${ORACLE_HOME}, ${ORACLE_SID}, ${ORACLE_BASE}
  - Product-specific sections for 9 product types
  - Backward compatibility: Old configs still work but new format recommended

- **Oracle Homes Framework**: New system for managing non-database Oracle products
  - oradba_homes.conf registry for Oracle Homes
  - Support for CLIENT, ICLIENT, GRID, RDBMS, ASM products
  - Alias support for user-friendly names
  - Export/import functionality

- **Removed Legacy Code**: Cleaned up deprecated functions and old architecture
  - Removed 15+ orphaned functions from Phase 0-2
  - Removed legacy dummy entry handling
  - Removed outdated configuration approaches
  
**Migration Required**: Users on v0.18.x or earlier MUST review configuration changes

### Added

#### Core Environment Management (v0.19.0)

- **Environment Parser Library** (oradba_env_parser.sh):
  - parse_oracle_home() - Extract ORACLE_HOME from oratab/homes
  - parse_oracle_base() - Determine ORACLE_BASE from inventory
  - parse_oracle_sid() - Extract SID information
  - parse_product_type() - Detect product type (RDBMS/CLIENT/GRID/ASM)
  - parse_is_rac_enabled() - Detect RAC configuration
  - parse_is_rooh() - Detect Read-Only Oracle Home
  - And 7 more parsing functions

- **Environment Builder Library** (oradba_env_builder.sh):
  - oradba_build_environment() - Main environment construction
  - set_oracle_home_environment() - Set ORACLE_HOME variables
  - set_oracle_sid_environment() - Set ORACLE_SID variables
  - set_oracle_base_environment() - Set ORACLE_BASE path
  - set_product_specific_environment() - Product-specific setup
  - And 7 more builder functions

- **Environment Validator Library** (oradba_env_validator.sh):
  - oradba_validate_environment() - Complete validation
  - validate_oracle_home() - ORACLE_HOME checks
  - validate_oracle_sid() - ORACLE_SID validation
  - validate_product_type() - Product type verification
  - validate_required_paths() - Path existence checks
  - And 6 more validation functions

#### Configuration Management (v0.20.0)

- **Configuration Library** (oradba_env_config.sh):
  - Section-based config processing: oradba_apply_config_section()
  - Hierarchical loading: oradba_load_generic_configs()
  - SID-specific overrides: oradba_load_sid_config()
  - Variable expansion: oradba_expand_variables()
  - Config validation: oradba_validate_config_file()

- **Configuration Files**:
  - oradba_core.conf - System-wide defaults (267 lines)
  - oradba_standard.conf - Standard organizational settings (380 lines)
  - oradba_services.conf - Service management configuration
  - oradba_environment.conf.template - Complete examples for all products

- **Product Sections**: 9 product-specific configuration sections
  - [DEFAULT], [RDBMS], [CLIENT], [ICLIENT], [GRID], [ASM], [DATASAFE], [OUD], [WLS]

#### Advanced Features (v0.21.0)

- **Status Checking Library** (oradba_env_status.sh):
  - Database status: oradba_check_db_status() (OPEN/MOUNTED/SHUTDOWN)
  - ASM status: oradba_check_asm_status()
  - Listener status: oradba_check_listener_status()
  - Process detection: oradba_check_process_running()
  - Product-specific checks for DataSafe, OUD, WLS

- **Change Detection Library** (oradba_env_changes.sh):
  - File signatures: oradba_get_file_signature()
  - Change tracking: oradba_check_file_changed()
  - Config monitoring: oradba_check_config_changes()
  - Auto-reload: oradba_auto_reload_on_change()

- **Enhanced oradba_env.sh Command**:
  - New `status [SID]` subcommand - Check service status
  - New `changes` subcommand - Detect config changes

#### Management Tools (v0.22.0)

- **Oracle Homes Export/Import**:
  - `oradba_homes.sh export` - Export configuration to stdout
  - `oradba_homes.sh import` - Import from file or stdin
  - Automatic backup with timestamp
  - Format validation and round-trip capability

### Enhanced

- **Oracle Home Support**: Extended for non-database products
  - ALIAS_NAME field for user-friendly aliases
  - VERSION field tracking
  - ORDER field for display sorting
  - Support for CLIENT, ICLIENT, GRID products

- **Environment Loading**: Faster and more reliable
  - Library-based sourcing pattern
  - Conditional library loading
  - Graceful degradation if libraries missing
  - Better error messages

- **Multi-Platform Support**:
  - macOS stat format (stat -f)
  - Linux stat format (stat -c)
  - Automatic platform detection
  - pgrep vs ps+grep fallback

- **ROOH (Read-Only Oracle Home)**: Full support
  - Automatic detection via inventory.xml
  - Read-only base handling
  - Configuration placement in writable locations

- **ASM Handling**: Enhanced ASM instance support
  - ASM as standalone product type
  - +ASM SID prefix detection
  - ASM-specific variables (ORACLE_SYSASM)
  - Integration with RDBMS and GRID configs

### Fixed

- **Configuration File Persistence** (Phase 3 Testing):
  - Fixed tests deleting core configuration files
  - Implemented backup/restore pattern in 12 tests
  - Files now persist correctly through test runs
  - Resolves critical blocker for v1.0.0 release

- **VERSION Format Validation** (Phase 3 Testing):
  - Updated regex to support pre-release versions
  - Pattern: `^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?$`
  - Allows 1.0.0-dev, 1.0.0-alpha, 1.0.0-rc.1, etc.

- **Oracle Home Alias Resolution** (v0.18.5):
  - parse_oracle_home() resolves aliases to NAME
  - resolve_oracle_home_name() checks NAME and ALIAS_NAME
  - Prevents circular alias references
  - Fixed phantom entries in display

- **PS1 Prompt Enhancement** (v0.18.5):
  - Shows Oracle Home alias in prompt
  - Format: `SID[.PDB]` or `[home_alias]`
  - Uses ORADBA_CURRENT_HOME_ALIAS variable

- **Installer Race Condition** (v0.18.5):
  - Added sync + sleep after tar extraction
  - Prevents "syntax error" on slow filesystems
  - Fixed intermittent installation failures

### Testing

- **Comprehensive Test Suite**: 533+ tests across 28 BATS files
  - Phase 1 (Parser/Builder/Validator): 64 unit tests
  - Phase 2 (Configuration): 28 unit tests
  - Phase 3 (Status/Changes): 37 unit tests
  - Phase 4 (Oracle Homes): 53 unit tests
  - Integration tests: 15 (skipped in CI, require Oracle)
  - **100% pass rate**: 528 passed, 0 failed, 15 skipped

- **Smart Test Selection**: .testmap.yml for optimized CI
  - Maps source files to relevant test files
  - Reduces unnecessary test runs by 30-40%
  - Faster feedback on changes

- **Test Infrastructure Improvements**:
  - Backup/restore pattern for config file tests
  - Skip markers for integration tests
  - Better error messages
  - Comprehensive coverage of all libraries

### Documentation

- **Architecture Documentation** (Phase 1-2 Complete):
  - Complete rewrite of doc/architecture.md
  - New configuration hierarchy documentation
  - Environment loading flow diagrams
  - Library interaction patterns

- **User Documentation** (Phase 2 Complete):
  - Updated Getting Started guide
  - Enhanced Configuration guide
  - Environment Variables reference
  - Installation instructions

- **Developer Documentation** (Phase 1 Complete):
  - API documentation for all 59 library functions
  - Development workflow guide
  - Testing strategy documentation
  - Extension system documentation

- **Code Quality Report** (Phase 4):
  - Shellcheck compliance: 0 errors, 0 warnings
  - 100% header standards compliance (37 scripts)
  - Comprehensive function documentation
  - Security and error handling review

- **Release Documentation**:
  - Archive policy for old releases (v0.9.4-v0.16.0)
  - Release notes for all versions
  - Migration guide from v0.18.x

### Code Quality

- **Shellcheck Compliance**: 100% clean
  - 0 errors across 37 shell scripts
  - 0 warnings
  - 39 minor style suggestions (intentional design choices)
  - Average 1.05 issues per script

- **Naming Conventions**: Consistent standards
  - 48 public functions with oradba_ prefix
  - 85 private helper functions
  - UPPER_CASE exported variables
  - lower_case local variables

- **Error Handling**: Robust patterns
  - 32 error logging calls
  - 10 explicit return code checks
  - Proper trap handlers
  - Cleanup in error paths

- **Security Practices**: Verified secure
  - 8 mktemp calls (secure temp files)
  - 13 eval statements (minimal, necessary)
  - Oracle Wallet for password handling
  - No command injection vulnerabilities

### Performance

- **Faster Environment Loading**:
  - Library-based loading vs monolithic sourcing
  - Conditional library loading
  - Reduced duplicate code execution

- **Optimized Config Processing**:
  - Section-based parsing (only load needed sections)
  - Cached file signatures for change detection
  - Lazy loading of optional features

### Compatibility

- **Backward Compatibility**: Preserved where possible
  - Old configuration files still work
  - Existing aliases continue to function
  - Oratab format unchanged
  - Migration path provided

- **Forward Compatibility**: Designed for extensibility
  - Library system allows new features without core changes
  - Extension system for third-party additions
  - Versioned configuration format

### Internal Changes

- **Version Numbering**: Updated to 1.0.0-dev for testing
  - Internal versions v0.19.0-v0.22.0 for Phase 1-4
  - v1.0.0 represents architecture stability
  - Semantic versioning compliance

- **Removed Deprecated Code**:
  - 15+ orphaned functions from legacy architecture
  - Old dummy entry system
  - Unused configuration approaches
  - Temporary development files

### Migration Notes

**From v0.18.5 to v1.0.0**:

1. **Review Configuration Files**:
   - New format uses [SECTION] headers
   - Variable expansion uses ${VAR} syntax
   - Old configs work but update recommended

2. **Oracle Homes**:
   - New oradba_homes.conf file for non-DB Oracle products
   - Use `oradba_homes.sh add` to register existing homes
   - Aliases now lowercase by default

3. **Environment Loading**:
   - Same sourcing pattern: `. oraenv.sh SID`
   - Libraries loaded automatically
   - New commands: `oradba_env status`, `oradba_env changes`

4. **Testing**:
   - Run full test suite to verify local setup
   - Integration tests require ORACLE_HOME
   - 100% pass rate expected

### Contributors

- Stefan Oehrli (@oehrlis)

### Statistics

- **Code Changes**: 40+ commits since v0.18.5
- **Files Changed**: 100+ files modified
- **Lines Added**: ~5,000 lines of new code
- **Lines Removed**: ~2,000 lines of deprecated code
- **Documentation**: 3,000+ lines updated
- **Tests**: 150+ new tests added
- **Libraries**: 6 new library files
- **Functions**: 59 new functions added

---

## Development Versions (Archive)

The following versions (v0.19.0 through v0.22.0) were internal development releases
implementing the Phase 1-4 architecture for v1.0.0. They are retained for reference
but superseded by the consolidated v1.0.0 release above.

## [0.22.0] - 2026-01-14

### Added

- **Phase 4: Management Tools Enhancement** - Export/import functionality for Oracle Homes management
  - **New `export` command** in `oradba_homes.sh`:
    - Export Oracle Homes configuration to stdout
    - Include metadata (export timestamp, OraDBA version)
    - Format documentation in export header
    - Support for backup and migration workflows
  
  - **New `import` command** in `oradba_homes.sh`:
    - Import Oracle Homes configuration from file or stdin
    - Automatic backup of existing configuration (default)
    - `--no-backup` option to skip backup creation
    - `--force` option for non-interactive import (reserved for future use)
    - Input validation before import
    - Configuration format verification
    - Summary output showing number of imported homes
  
  - **Configuration management features**:
    - Round-trip export/import capability
    - Backup file creation with timestamp
    - Format validation on import
    - Field count verification
    - Support for stdin and file input
    - Comprehensive error handling

### Enhanced

- **Updated `oradba_homes.sh` usage documentation**:
  - Added export and import command documentation
  - Include import options (--force, --no-backup)
  - Added examples for export/import workflows
  - Enhanced global options section

### Fixed

- Fixed argument parsing in import_config function to properly handle --no-backup option
- Fixed shellcheck SC2034 warning (unused force variable, prefixed with underscore)
- Fixed shellcheck SC2155 warning (declare and assign separately for backup_file)

### Testing

- **11 new BATS tests** for export/import functionality:

  - `export: works with no config` - Handles empty configuration gracefully
  - `export: exports existing config` - Successfully exports homes configuration
  - `export: includes export metadata` - Verifies metadata in export output
  - `import: requires valid input` - Validates import format
  - `import: imports from stdin` - Supports stdin input
  - `import: imports from file` - Supports file input
  - `import: creates backup by default` - Creates timestamped backup
  - `import: --no-backup skips backup` - Respects --no-backup flag
  - `import: validates field count` - Checks minimum field requirements
  - `export+import: round-trip test` - Full workflow verification
  - `import: shows summary` - Displays import statistics

- **Total test suite**: 53 passing tests for oradba_homes.sh (42 existing + 11 new)

### Documentation

- Updated Phase 4 status in design document
- Enhanced command-line help with export/import examples
- Documented import validation process
- Added backup strategy documentation

## [0.21.0] - 2026-01-14

### Added

- **Phase 3: Advanced Features** - Service status checking and change detection
  - New `oradba_env_status.sh` library (8 functions) for service status checking:
    - `oradba_check_db_status` - Check Oracle database instance status (OPEN/MOUNTED/NOMOUNT/SHUTDOWN)
    - `oradba_check_asm_status` - Check ASM instance status (STARTED/MOUNTED/SHUTDOWN)
    - `oradba_check_listener_status` - Check Oracle listener status (RUNNING/STOPPED)
    - `oradba_check_process_running` - Generic process detection
    - `oradba_check_datasafe_status` - Check Oracle Data Safe service status
    - `oradba_check_oud_status` - Check Oracle Unified Directory instance status
    - `oradba_check_wls_status` - Check WebLogic Server status
    - `oradba_get_product_status` - Unified status check for any product type
  
  - New `oradba_env_changes.sh` library (7 functions) for configuration change detection:
    - `oradba_get_file_signature` - Get file signature (timestamp:size)
    - `oradba_store_file_signature` - Store signature for future comparison
    - `oradba_check_file_changed` - Detect if file has changed
    - `oradba_check_config_changes` - Check all config files for changes
    - `oradba_init_change_tracking` - Initialize tracking for all config files
    - `oradba_clear_change_tracking` - Clear all tracking data
    - `oradba_auto_reload_on_change` - Auto-reload environment on config changes
  
  - **Enhanced `oradba_env.sh` command** with new subcommands:
    - `status [SID]` - Check status of Oracle instances and services
    - `changes` - Detect configuration file changes
  
  - **Status checking capabilities**:
    - Database instance status (OPEN, MOUNTED, NOMOUNT, SHUTDOWN)
    - ASM instance status (STARTED, MOUNTED, SHUTDOWN)
    - Oracle listener status (RUNNING, STOPPED)
    - Product-specific service checks (DataSafe, OUD, WLS)
    - Process-based status detection with pgrep fallback
  
  - **Change detection features**:
    - File signature tracking (timestamp + size)
    - Automatic signature storage and comparison
    - Multi-file change monitoring
    - Config hierarchy change detection (core/standard/local/customer/SID)
    - Cache directory for signature storage
    - Manual and automatic change checking

### Changed

- **oradba_env.sh** - Updated to version 0.21.0
  - Added Phase 3 library loading (status and changes)
  - Enhanced usage information with new commands
  - Integrated status checking for all product types
  - Added change detection command

- **oradba_env_status.sh** - Enhanced process checking
  - Uses `pgrep` when available for better performance
  - Falls back to `ps | grep` if pgrep not available
  - Disabled SC2009 shellcheck warning for ps/grep fallback

### Testing

- **21 Unit Tests** for service status checking (test_oradba_env_status.bats):
  - Process running detection tests
  - Product status tests (CLIENT, ICLIENT, RDBMS, ASM, DataSafe, OUD, WLS)
  - Database status checking tests
  - ASM status checking tests
  - Listener status checking tests
  - Empty/invalid parameter handling tests
  - Function export verification

- **16 Unit Tests** for change detection (test_oradba_env_changes.bats):
  - File signature generation tests
  - Signature storage tests
  - File change detection tests
  - Config change monitoring tests
  - Change tracking initialization/cleanup tests
  - Complete workflow integration tests

- **All Previous Tests Still Passing**:
  - Phase 1: 22 unit tests ✅
  - Phase 2: 28 unit tests ✅
  - **Total: 87 unit tests** across all phases

### Enhanced

- **Multi-platform support** for change detection:
  - macOS support (stat -f format)
  - Linux support (stat -c format)
  - Automatic platform detection

- **ROOH Support** - Read-Only Oracle Home detection (from Phase 1, now documented)
- **ASM Handling** - Full ASM instance support (from Phase 1, now documented)

### Documentation

- Updated `doc/oradba-env-design.md`:
  - Marked Phase 2 as complete (v0.20.0)
  - Updated Phase 3 status (IN PROGRESS)
  - Documented completed Phase 3 items (ROOH, ASM)
  
### Compatibility

- All Phase 1 functionality preserved (parser, builder, validator)
- All Phase 2 functionality preserved (configuration system)
- Backward compatible with existing environments
- New features are optional (graceful degradation if libraries not found)

### Deliverables

Phase 3 delivers advanced monitoring and automation:

- 2 new libraries (oradba_env_status.sh - 306 lines, oradba_env_changes.sh - 229 lines)
- Enhanced oradba_env.sh command (2 new subcommands)
- 37 new unit tests (all passing)
- Service status checking for all product types
- Configuration change detection and tracking
- Cross-platform file monitoring

## [0.20.0] - 2026-01-14

### Added

- **Phase 2: Configuration Management System** - Section-based hierarchical configuration for environment customization
  - New `oradba_env_config.sh` library (8 functions) for configuration processing:
    - `oradba_apply_config_section` - Parse and apply specific section from config file
    - `oradba_load_generic_configs` - Load all configs in hierarchy order
    - `oradba_load_sid_config` - Load SID-specific configuration overrides
    - `oradba_apply_product_config` - Main entry point for product config application
    - `oradba_expand_variables` - Expand ${ORACLE_HOME}, ${ORACLE_SID}, ${ORACLE_BASE} variables
    - `oradba_list_config_sections` - List all sections in config file
    - `oradba_validate_config_file` - Syntax validation for config files
    - `oradba_get_config_value` - Extract specific values from config sections
  
  - **Section-based configuration format** with INI-like syntax:
    - `[DEFAULT]` - Variables applied to all product types
    - `[RDBMS]` - Oracle Database specific settings
    - `[CLIENT]` - Full Client specific settings
    - `[ICLIENT]` - Instant Client specific settings
    - `[GRID]` - Grid Infrastructure specific settings
    - `[ASM]` - ASM instance specific settings
    - `[DATASAFE]` - Oracle Data Safe specific settings
    - `[OUD]` - Oracle Unified Directory specific settings
    - `[WLS]` - WebLogic Server specific settings
  
  - **Hierarchical configuration loading** (later configs override earlier):
    1. `oradba_core.conf` - System-wide core configuration
    2. `oradba_standard.conf` - Standard organizational settings
    3. `oradba_local.conf` - Local site-specific settings
    4. `oradba_customer.conf` - Customer-specific overrides
    5. `etc/sid/sid.<SID>.conf` - Instance-specific configurations
  
  - **New configuration template**: `oradba_environment.conf.template`
    - Complete examples for all 9 product sections
    - Variable expansion examples (${ORACLE_HOME}, ${ORACLE_SID})
    - Product-specific aliases (70+ examples):
      - RDBMS: sqlplus, sqldba, rman, dbs, admin, trace, alert
      - GRID: crsctl, asmcmd, srvctl, crs, admin, log
      - CLIENT: sqlplus, tnsping, tns
      - And more for all products
    - Navigation shortcuts per product type
    - ASM special handling within RDBMS and GRID sections
  
  - **Variable expansion support** in config files:
    - `${ORACLE_HOME}` - Expands to current Oracle Home path
    - `${ORACLE_SID}` - Expands to current SID
    - `${ORACLE_BASE}` - Expands to Oracle Base directory
    - `${ORADBA_BASE}` - Expands to OraDBA installation directory
    - Eval-based expansion within controlled config context
  
  - **Configuration validation framework**:
    - Section header syntax checking
    - Variable assignment validation
    - Alias syntax verification
    - Detects malformed sections and invalid syntax
    - Provides clear error messages with line numbers

### Changed

- **oradba_env_builder.sh** - Enhanced to apply configuration after environment setup
  - Added sourcing of `oradba_env_config.sh` library
  - Integrated `oradba_apply_product_config` call in `oradba_build_environment`
  - Configuration applied after product-specific environment, before ASM handling
  - Graceful handling of missing config files

- **oraenv.sh Integration** - Updated to source configuration management library
  - Added conditional loading of `oradba_env_config.sh` (Phase 2)
  - Configuration functions available when environment is loaded
  - Maintains backward compatibility with Phase 1 functionality

### Enhanced

- **ASM Product Support** - ASM now recognized as standalone product type
  - Added ASM case in `oradba_apply_product_config`
  - ASM configs can be applied directly or as part of RDBMS/GRID
  - Special handling for +ASM prefixed SIDs
  - ASM-specific variables (ORACLE_SYSASM) supported

### Testing

- **28 Unit Tests** for configuration processor (test_oradba_env_config.bats):
  - Section listing and parsing tests
  - Config section application tests (export, alias, variable expansion)
  - Validation tests (valid/invalid syntax detection)
  - Config value extraction tests
  - Variable expansion tests (ORACLE_HOME, ORACLE_SID, ORACLE_BASE)
  - Product config application tests (all 9 products)
  - Config hierarchy tests (core → standard → local override)
  - SID-specific config tests
  - Integration test with complete hierarchy
  - Config value extraction

### Fixed

- Configuration loading with missing files now handled gracefully (returns 0, no error)
- SID config loading failure doesn't break product config application
- Validation properly detects malformed section headers
- ASM product type now fully supported as standalone configuration

### Documentation

- Phase 2 implementation documented in `doc/oradba-env-design.md`
- Configuration template with comprehensive examples
- All Phase 2 functions documented with purpose, arguments, returns, output

### Compatibility

- Phase 1 functionality fully preserved (parser, builder, validator)
- All 22 Phase 1 unit tests still passing
- Phase 1 functional tests still passing
- Backward compatible with existing environment setup

### Deliverables

Phase 2 completes the configuration management system with:

- 1 new library (oradba_env_config.sh, 349 lines, 8 functions)
- 1 new template (oradba_environment.conf.template, 175 lines)
- 28 unit tests (all passing)
- 23 functional tests (all passing)
- Updated integration in builder and oraenv.sh
- Complete variable expansion support
- Validation framework
- 9 product sections supported
- Hierarchical config loading (5 levels)
- SID-specific override capability

## [0.19.0] - 2026-01-14

### Added

- **Phase 1: Core Environment Management System** - Complete redesign of Oracle environment management
  - New modular library architecture in `src/lib/`:
    - `oradba_env_parser.sh` - Core parsing with 8 functions for oratab and oradba_homes.conf
    - `oradba_env_builder.sh` - Environment builder with 10 functions for PATH/LD_LIBRARY_PATH management
    - `oradba_env_validator.sh` - Validation system with 7 functions and 3 validation levels
  - New `oradba_env.sh` command utility with subcommands:
    - `list [sids|homes|all]` - List available Oracle SIDs and Oracle Homes
    - `show <SID|HOME>` - Display detailed information about SID or Oracle Home
    - `validate [basic|standard|full]` - Validate current Oracle environment
  - Enhanced `oradba_homes.conf` format (9 fields):
    - New fields: Version, Edition, DB_Type (database type: SI/RAC/DG/RAC-DG)
    - Format: `ORACLE_HOME;Product;Version;Edition;DB_Type;Position;Dummy_SID;Short_Name;Description`
  - Support for all Priority 1 products: RDBMS, CLIENT, ICLIENT (Instant Client), GRID
  - Automatic product type detection with fallback logic
  - Read-Only Oracle Home (ROOH) detection and handling
  - ASM instance detection and special handling (+ASM prefix)
  - Platform-aware library path management (LD_LIBRARY_PATH, SHLIB_PATH, LIBPATH, DYLD_LIBRARY_PATH)
  - Intelligent PATH construction with Oracle path cleanup
  - Multi-level environment validation (basic/standard/full)

### Changed

- **oraenv.sh Integration** - Updated to source new environment management libraries
  - Automatically loads parser, builder, and validator on sourcing
  - Sets ORADBA_BASE for library discovery
  - Maintains backward compatibility with existing functionality

- **oradba_homes.conf.template** - Completely redesigned for new 9-field format
  - Comprehensive examples for all Priority 1 products
  - Detailed field documentation and usage guidelines
  - Clarified coexistence model with /etc/oratab

### Enhanced

- **Product Type Detection** - Intelligent auto-detection for Oracle products
  - RDBMS: Detects from sqlplus + rdbms directory
  - CLIENT: Detects from sqlplus without rdbms
  - ICLIENT: Detects from libclntsh library files (versioned and unversioned)
  - GRID: Detects from crsctl/asmcmd binaries
  - Supports Priority 2 (DATASAFE) and Priority 3 (OUD, WLS) products

- **Environment Building** - Comprehensive environment variable management
  - Smart PATH cleanup (removes old Oracle paths)
  - Product-specific PATH additions (bin, OPatch, Grid)
  - Platform-specific library path handling (Linux, HP-UX, AIX, Darwin)
  - ORACLE_BASE detection from orabasetab or intelligent derivation
  - TNS_ADMIN configuration for all product types
  - NLS variable defaults (NLS_LANG, NLS_DATE_FORMAT, ORA_NLS10)
  - ASM-specific environment (ORACLE_SYSASM, GRID_HOME)
  - Product-specific variables (DATASAFE_HOME, OUD_INSTANCE_HOME, WLS_HOME, etc.)

- **Environment Validation** - Multi-level validation system
  - Basic: ORACLE_HOME existence, SID format validation, PATH checks
  - Standard: Binary availability checks (sqlplus, tnsping, lsnrctl, crsctl, asmcmd)
  - Full: Database connectivity, status checks, version detection
  - Product-specific validation for each supported product type
  - Grid Infrastructure status checking (crsctl check crs)

### Fixed

- **Shellcheck Compliance** - All lint warnings resolved
  - SC2034: Fixed unused variable warnings (prefixed with underscore)
  - SC2076: Fixed regex pattern quoting in BATS tests
  - SC2144: Fixed glob pattern in -f test (changed to ls with redirect)
  - SC2155: Fixed declare-and-assign pattern in readonly variables

### Testing

- **Unit Tests** - Comprehensive BATS test suite (22 tests, all passing)
  - Parser function tests for oratab and oradba_homes.conf
  - Metadata extraction tests (Product, Version, Edition, etc.)
  - SID and Home lookup tests
  - Product type auto-detection tests
  - Whitespace trimming and default value tests
  - Edge case handling (empty files, malformed entries, missing fields)

- **Functional Tests** - Complete integration testing
  - All libraries load without errors
  - Parser functions work with test data
  - Product type detection works for all Priority 1 products
  - ASM instance detection working
  - Validation functions operational

### Documentation

- **Design Specification** - Complete design document (1441 lines)
  - Architecture overview and component structure
  - File format specifications (9-field oradba_homes.conf)
  - Implementation details for all components
  - Product priority system (P1: RDBMS/CLIENT/ICLIENT/GRID, P2: DATASAFE, P3: OUD/WLS)
  - Phase-based implementation roadmap (Phases 1-4)
  - Validation logic and testing requirements

## [0.18.5] - 2026-01-13

### Added

- **Oracle Version Detection**: Added VERSION field to `oradba_homes.conf` for tracking Oracle Home versions
  - Format: `NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:ALIAS_NAME:DESCRIPTION:VERSION`
  - Supports `AUTO` (dynamic detection), `XXYZ` (specific version like 1920), or `ERR` (no version)
  - New `detect_oracle_version()` function with 4 detection methods (sqlplus, OPatch, inventory XML, path parsing)
  - New `get_oracle_home_version()` helper function
  - Version displayed in `oradba_homes.sh show` command
  - `--version` parameter added to `oradba_homes.sh add` command

### Changed

- **Template Organization**: Moved `oradba_homes.conf.template` from `src/etc/` to `src/templates/etc/`
  - Consistent with other configuration templates
  - Improved discoverability

### Enhanced

- **ORACLE_BASE Derivation**: Improved intelligence for deriving ORACLE_BASE from ORACLE_HOME
  - New `derive_oracle_base()` function searches upward for Oracle base indicators
  - Correctly handles paths like `/appl/oracle/product/26.0.0/client` → `/appl/oracle`
  - Looks for directories containing `product`, `oradata`, `oraInventory`, or `admin`
  - Falls back to traditional two-levels-up method if needed
  
- **Non-Root ORATAB Access**: Fixed `vio` alias for systems without root access
  - ORATAB_FILE now dynamically determined via `get_oratab_path()` function
  - Removed hardcoded `/etc/oratab` default from `oradba_core.conf`
  - Properly uses priority system for oratab file location
  
- **Oracle Home Parsing**: All Oracle Home functions updated to handle VERSION field
  - `parse_oracle_home()` - Returns 7 fields instead of 6
  - `list_oracle_homes()` - Parses and outputs VERSION
  - `resolve_oracle_home_name()` - Handles VERSION in parsing
  - `generate_sid_lists()` - Handles VERSION in parsing
  - `generate_oracle_home_aliases()` - Handles VERSION in parsing
  - `show_home()` - Displays configured and detected versions
  - `list_homes()` - Handles VERSION field
  - `validate_homes()` - Handles VERSION field

### Fixed

- **Shellcheck Warning**: Fixed SC2155 in `oraenv.sh` (declare and assign separately)

## [0.18.4] - 2026-01-13

### Fixed

- **Extension Installation**: Fixed hidden files not being copied during extension installation from tarball
  - Changed from `cp -R` with glob pattern to `rsync` or `tar` for reliable file copying
  - Now properly installs `.extension`, `.checksumignore`, `.extension.checksum`, and other hidden files
  - Fixes issue where extensions were installed without metadata files
  - Falls back to tar if rsync is not available

### Added

- **Release Notes Update**: Added `release-notes` target to Makefile for GitHub release management
  - Automatically updates GitHub release with release notes from `doc/releases/v<VERSION>.md`
  - Validates release notes file existence and `gh` CLI availability
  - Usage: `make release-notes` (uses current VERSION file)
  - Example: For v0.18.3, runs `gh release edit v0.18.3 --notes-file doc/releases/v0.18.3.md`

## [0.18.3] - 2026-01-13

### Changed

- **File Headers Standardization**: Updated all source file headers to version 0.18.3 and date 2026.01.13
  - Updated 22 shell scripts in `src/bin/` with standardized headers
  - Updated 10 configuration files in `src/etc/` with standardized headers
  - Updated 126 SQL scripts in `src/sql/` with standardized headers
  - Updated 5 scripts in `scripts/` with standardized headers
  - Consistent formatting across all file types (shell, SQL, config, RMAN)

### Enhanced

- **Project Validation**: Improved `scripts/validate_project.sh` to match current repository structure
  - Added validation for all new core scripts (oradba_validate.sh, oradba_setup.sh, oradba_homes.sh, etc.)
  - Added validation for new configuration files (oradba_services.conf, oradba_homes.conf.template, sid.\*DEFAULT\*.conf)
  - Added validation for template files (oradba_customer.conf.example, sid.ORACLE_SID.conf.example, oradba_rman.conf.example)
  - Added validation for new test files (test_oradba_homes.bats, test_extensions.bats, etc.)
  - Added validation for additional scripts (select_tests.sh, build_pdf.sh, archive_github_releases.sh)
  - Updated documentation file checks to new naming convention (removed numbered prefixes)
  - Added check for docs.yml workflow
  - Enhanced permission checks to loop through all scripts
  - Removed obsolete file references (backup_full.rman, old doc naming)

- **Oracle Home Status Display**: Improved status display for non-database Oracle Homes
  - Created `show_oracle_home_status()` function for client, OUD, WebLogic, OMS, etc.
  - Shows `PRODUCT_TYPE` instead of inappropriate `STATUS: NOT STARTED` for client homes
  - `show_database_status()` now detects non-database Oracle Homes and delegates appropriately
  - Export `ORADBA_CURRENT_HOME_TYPE` environment variable in `set_oracle_home_environment()`
  - Better distinction between database and non-database Oracle Home types

- **Configuration Templates Organization**: Moved example configuration files to `src/templates/etc/`
  - Moved `oradba_config.example`, `oradba_customer.conf.example`, `oradba_rman.conf.example`, `oratab.example`,
    and `sid.ORACLE_SID.conf.example` from `src/etc/` to `src/templates/etc/`
  - Updated all documentation, scripts, and tests to reference new location
  - Consolidated all configuration templates in one location for easier discovery
  - Updated `src/etc/README.md` and `src/templates/etc/README.md` with new structure

## [0.18.2] - 2026-01-12

### Fixed

- **Oracle Home Alias Resolution**: Fixed critical bugs preventing Oracle Home aliases from working
  - `parse_oracle_home()` now resolves alias names to actual NAME before lookup
  - Added `resolve_oracle_home_name()` function to check both NAME and ALIAS_NAME fields
  - `set_oracle_home_environment()` resolves aliases to prevent circular references
  - Fixed alias creation to use actual NAME, not alias itself (e.g., `alias rdbms26='. oraenv.sh DBHOMEFREE'`)
  
- **Oracle Home Configuration Path**: Fixed incorrect config file path in generate functions
  - `generate_sid_lists()` now uses `get_oracle_homes_path()` instead of hardcoded path
  - `generate_oracle_home_aliases()` now uses `get_oracle_homes_path()` instead of hardcoded path
  - Corrected filename from `oracle_homes.conf` to `oradba_homes.conf`
  - Both functions now consistent with all other Oracle Homes functions

- **Empty Dummy Array Display**: Fixed phantom "Dummy rdbms" line appearing when no dummy entries exist
  - Added conditional sorting to prevent mapfile from creating empty array elements
  - Only sort arrays if they contain elements (`${#array[@]} -gt 0`)
  - Prevents bash quirk where `printf '%s\n' ""` creates one empty element

- **PS1 Prompt Enhancement**: Fixed empty PS1 prompt when using Oracle Homes
  - Enhanced PS1 logic to show `ORADBA_CURRENT_HOME_ALIAS` for Oracle Homes
  - Shows database format `SID[.PDB]` or Oracle Home alias `[rdbms26]`
  - Removed invalid `local` keyword in oradba_standard.conf (outside function)

- **Installer Race Condition**: Fixed intermittent "syntax error near unexpected token" during installation
  - Added `sync` command after tar extraction to ensure filesystem writes complete
  - Added 0.5s sleep to allow buffered operations to finish
  - Prevents failures on slow/busy systems or network filesystems

### Changed

- **Oracle Home Alias Convention**: Made Oracle Home aliases lowercase by default
  - Consistent with database SID alias convention (e.g., `FREE` → `free`)
  - Default alias is now lowercase version of NAME (e.g., `DBHOMEFREE` → `dbhomefree`)
  - Custom aliases still supported via `--alias` option
  - `generate_oracle_home_aliases()` creates lowercase alias for NAME automatically
  - Example: `DBHOMEFREE` creates both `dbhomefree` and custom `rdbms26` aliases

- **ORADBA_SIDLIST Enhancement**: Extended to include Oracle Home names and aliases
  - `ORADBA_REALSIDLIST`: Real database SIDs only (Y/N/S flags from oratab)
  - `ORADBA_SIDLIST`: All sourceable names (database SIDs + dummy entries + Oracle Home names/aliases)
  - `generate_sid_lists()` now appends Oracle Home entries from oradba_homes.conf
  - Both NAME and ALIAS_NAME added to SIDLIST for completeness

- **Dynamic Alias Generation**: Aliases regenerated after add/remove operations
  - `oradba_homes.sh add` now calls `generate_sid_lists()` and `generate_oracle_home_aliases()`
  - `oradba_homes.sh remove` regenerates aliases after removal
  - New Oracle Homes immediately available in current shell (after first source)
  - Note: Parent shell requires sourcing once due to subshell limitation

- **Oracle Home Display**: Show alias name in `oraup.sh` instead of full NAME
  - Displays user-friendly alias (e.g., `rdbms26`) instead of technical name (e.g., `DBHOMEFREE`)
  - Falls back to NAME if no alias defined or alias same as NAME
  - More intuitive display matching what users actually type

### Documentation

- **Release Notes Archive**: Implemented retention policy for release documentation
  - Moved old releases (v0.9.4-v0.16.0) to `doc/releases/archive/` directory
  - Created `archive_github_releases.sh` script to add archive notices to GitHub releases
  - Archive notice includes link to `/releases/latest` (permanent URL)
  - Applied to 21 GitHub releases (v0.9.5-v0.16.0)

## [0.18.1] - 2026-01-12

### Added

- **Oracle Homes ALIAS_NAME Support**: Optional user-friendly alias names for Oracle Homes
  - Extended configuration format: `NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER[:ALIAS_NAME][:DESCRIPTION]`
  - ALIAS_NAME defaults to NAME if not specified (backward compatible)
  - Useful for distinguishing between auto-discovered NAME and user-preferred alias
  - Added `--alias` option to `oradba_homes.sh add` command
  - New function `get_oracle_home_alias()` in oradba_common.sh
  - List display shows alias when different from home name
  - Updated documentation and tests

### Changed

- **Extension Registry**: Added odb_datasafe and odb_autoupgrade extensions
  - odb_datasafe: Oracle Data Safe tools for OCI management
  - odb_autoupgrade: AutoUpgrade wrapper scripts and configurations
  - Updated sync script to filter problematic files and auto-convert README to index

### Fixed

- **Documentation Build**: Fixed mkdocs strict mode failures
  - Exclude release_notes_*.md files with broken source links
  - Automatically rename README.md to index.md in synced extension docs
  - Pattern-based file filtering during extension documentation sync

- **CI/CD Workflows**: Standardized workflow linting
  - Updated ci.yml to use `make lint-shell` and `make lint-markdown`
  - Fixed SC2155 shellcheck warnings in build_pdf.sh
  - Consistent use of Makefile targets across all workflows

## [0.18.0] - 2026-01-11

### Added

- **Oracle Homes Support (Phase 1)**: Core infrastructure for managing non-database Oracle products
  - New configuration file: `oradba_homes.conf` for registering Oracle Homes
  - Configuration format: `NAME:ORACLE_HOME:PRODUCT_TYPE:ORDER:DESCRIPTION`
  - Core functions in oradba_common.sh:
    - `get_oracle_homes_path()`: Get path to oradba_homes.conf
    - `parse_oracle_home()`: Parse home entry by name
    - `list_oracle_homes()`: List all homes sorted by order with optional filtering
    - `get_oracle_home_path()`: Get ORACLE_HOME path for a named home
    - `get_oracle_home_type()`: Get product type for a home
    - `detect_product_type()`: Auto-detect product type from ORACLE_HOME filesystem
    - `set_oracle_home_environment()`: Set environment variables by product type
    - `is_oracle_home()`: Check if name refers to Oracle Home vs database SID
  - Supported product types:
    - `database`: Oracle Database (existing functionality)
    - `oud`: Oracle Unified Directory
    - `client`: Oracle Client
    - `weblogic`: WebLogic Server
    - `oms`: Enterprise Manager OMS
    - `emagent`: Enterprise Manager Agent
    - `datasafe`: Oracle Data Safe
  - Comprehensive unit test suite with 28 tests (100% coverage)

- **Oracle Homes Support (Phase 2)**: Integration with oraenv.sh and oraup.sh
  - Enhanced `oraenv.sh` to support Oracle Homes:
    - Checks `is_oracle_home()` before oratab lookup
    - Calls `set_oracle_home_environment()` for Oracle Homes
    - Interactive menu displays both Oracle Homes and database SIDs
    - Shows product type indicators for Oracle Homes
    - Clears `ORACLE_SID` for non-database homes
    - Updated help text to mention both SIDs and Oracle Homes
  - Enhanced `oraup.sh` to display Oracle Homes:
    - New "Oracle Homes" section before database instances
    - Shows product type (OUD, WebLogic, Client, OMS, etc.)
    - Displays home status (available/missing)
    - Maintains sorted display (homes by order, databases by SID)
  - Integration test coverage:
    - 3 new Oracle Homes integration tests in test_oraenv.bats
    - All 28 oraenv tests passing
    - Validates Oracle Home detection, environment setup, and priority handling

- **Oracle Homes Support (Phase 3)**: Management CLI tool
  - New `oradba_homes.sh` command-line management tool with 6 commands:
    - `list`: Display registered Oracle Homes with filtering (--type, --verbose)
    - `show <name>`: Show detailed information about specific Oracle Home
    - `add`: Add new Oracle Home (interactive or CLI parameters)
      - Parameters: --name, --path, --type, --order, --desc
      - Auto-detection of product type from filesystem
      - Input validation for name format, product type, duplicates
      - Interactive prompts with TTY detection for non-interactive environments
    - `remove <name>`: Remove Oracle Home with confirmation and backup
      - Automatic backup creation before removal
      - Confirmation prompt (skipped in non-interactive mode)
    - `discover`: Auto-discover Oracle Homes under $ORACLE_BASE/product
      - Options: --base, --auto-add, --dry-run
      - Scans product directory recursively
      - Auto-detects product types
      - Skips already registered homes
    - `validate [name]`: Validate configuration and detect issues
      - Checks directory existence
      - Verifies product type matches detected type
      - Can validate all homes or specific home
      - Returns exit codes for CI/CD integration
  - Features:
    - TTY detection prevents hanging in non-interactive environments (CI/CD, tests)
    - Graceful fallback with clear error messages when inputs missing
    - Configuration file auto-creation with documentation
    - Sorted display by order value
    - Color-coded output for status indicators
  - Comprehensive test suite:
    - 39 tests covering all commands and scenarios
    - Basic tests (5): existence, syntax, help, usage
    - List tests (5): empty config, display, filtering, verbose mode
    - Show tests (3): validation, details, error handling
    - Add tests (9): validation, creation, auto-detection, duplicates, ordering
    - Remove tests (5): validation, confirmation, backup creation, non-interactive
    - Discover tests (6): ORACLE_BASE handling, finding homes, dry-run, auto-add
    - Validate tests (5): directory checks, type mismatch detection, specific home
    - Integration tests (2): full workflow, oraenv integration
    - All tests pass reliably without timeouts

### Fixed

- **Code Quality**: Fixed all shellcheck and markdownlint warnings
  - `src/bin/oraup.sh`: SC2034 - Prefixed unused variables with underscore
  - `src/lib/oradba_common.sh`: SC2155 - Separated ORACLE_HOSTNAME declaration and assignment
  - `tests/test_oraenv.bats`: SC2076 - Removed quotes from regex patterns (3 locations)
  - `doc/releases/v0.18.0.md`: MD013 - Split long overview line
  - `doc/releases/v0.18.0.md`: MD040 - Added language specifiers to code blocks (2 locations)

### Removed

- **Documentation Cleanup**: Removed interim development documentation
  - `doc/v0.17.0-phase1-summary.md` (255 lines) - Phase 1 implementation notes
  - `doc/v0.17.0-complete-summary.md` (994 lines) - Complete implementation summary
  - `doc/v0.18.0-oracle-homes-support.md` (811 lines) - Planning/architecture document
  - These interim documents are superseded by official release documentation

## [0.17.0] - 2026-01-09

### Added

- **Pre-Oracle Installation Support**: OraDBA can now be installed before Oracle Database
  - New CLI parameters for installer:
    - `--user-level`: Install to ~/oradba (no root/Oracle required)
    - `--base PATH`: Specify Oracle Base directory (installs to PATH/local/oradba)
    - `--prefix PATH`: Direct installation path (overrides auto-detection)
    - `--dummy-home PATH`: Custom dummy ORACLE_HOME for pre-Oracle scenarios
  - Enhanced prefix detection with 5-priority system
  - Automatic creation of temporary oratab at `${ORADBA_BASE}/etc/oratab`
  - Interactive Oracle Base prompt for non-silent installations
  - Write permission validation before installation
  - Symlink creation when /etc/oratab exists
  - Dummy database entry support for pre-Oracle testing

- **Centralized oratab Priority System**: New `get_oratab_path()` function in oradba_common.sh
  - Priority 1: `$ORADBA_ORATAB` (explicit override)
  - Priority 2: `/etc/oratab` (system default)
  - Priority 3: `/var/opt/oracle/oratab` (Solaris/AIX)
  - Priority 4: `${ORADBA_BASE}/etc/oratab` (temporary for pre-Oracle)
  - Priority 5: `${HOME}/.oratab` (user fallback)
  - All oratab-related functions now use centralized priority system
  - Updated: `is_dummy_sid()`, `parse_oratab()`, `generate_sid_lists()`
  - Updated: `oraup.sh`, `oraenv.sh` to use priority detection

### Changed

- **Installer Behavior**: Enhanced installation flow for pre-Oracle scenarios
  - Auto-detection returns empty when Oracle not found (instead of failing)
  - Clear error messages when installation location cannot be determined
  - Silent mode prevents interactive prompts
  - Prefix determination follows clear priority: --prefix > --user-level > --base > auto-detect

- **Configuration Documentation**: Updated oradba_core.conf with oratab priority documentation
- **Test Coverage**: Added 9 new tests for oratab priority system

- **Setup Helper Command**: New `oradba_setup.sh` utility for post-installation tasks
  - `link-oratab`: Replace temporary oratab with symlink to system oratab
  - `check`: Validate OraDBA installation health
  - `show-config`: Display current OraDBA configuration
  - Automatic backup before modifying oratab
  - Force mode for overwriting existing configurations

- **Validation Tool Enhancement**: Updated `oradba_validate.sh` for pre-Oracle awareness
  - Detects pre-Oracle installation mode automatically
  - Context-aware Oracle environment checks
  - Tailored guidance for pre-Oracle vs installed Oracle scenarios
  - Shows installation mode in validation header
  - Provides next-steps instructions specific to installation state
  - No longer fails on missing Oracle when in pre-Oracle mode
  - `show-config`: Display current OraDBA configuration
  - Automatic backup before modifying oratab
  - Force mode for overwriting existing configurations

- **No-Oracle Mode**: Graceful degradation when Oracle Database not installed
  - `oraenv.sh` sets minimal environment without failing
  - `oraup.sh` shows helpful messages instead of errors
  - `ORADBA_NO_ORACLE_MODE` flag indicates pre-Oracle state
  - Informative messages guide users on next steps

- **Installer Behavior**: Enhanced installation flow for pre-Oracle scenarios
  - Auto-detection returns empty when Oracle not found (instead of failing)
  - Clear error messages when installation location cannot be determined
  - Silent mode prevents interactive prompts
  - Prefix determination follows clear priority: --prefix > --user-level > --base > auto-detect

- **oraenv.sh Behavior**: Non-fatal handling of missing ORACLE_HOME
  - Warns but continues when ORACLE_HOME directory doesn't exist
  - Allows environment setup for dummy entries
  - Useful for pre-Oracle testing scenarios

- **oraup.sh Output**: Enhanced messaging for empty/missing oratab
  - Clear pre-Oracle installation messages
  - Guidance on using `oradba_setup.sh link-oratab`
  - No longer fails with error when no databases present

- **Configuration Documentation**: Updated oradba_core.conf with:
  - oratab priority documentation
  - ORADBA_NO_ORACLE_MODE flag documentation

- **Test Coverage**: Added 9 new tests for oratab priority system

### Documentation

- **Pre-Oracle Installation Guide**: Comprehensive new section in [02-installation.md](src/doc/02-installation.md)
  - Pre-Oracle installation methods (--user-level, --base, --prefix)
  - Understanding temporary oratab
  - Post-Oracle configuration with oradba_setup.sh
  - Graceful degradation in No-Oracle Mode
  - Docker multi-stage build example
  - CI/CD pipeline integration example
  - Pre-Oracle troubleshooting guide

- **Pre-Oracle Troubleshooting**: New section in [12-troubleshooting.md](src/doc/12-troubleshooting.md)
  - "ORACLE_BASE not found" during installation
  - Temporary oratab behavior
  - "No Oracle installation detected"
  - oraup.sh shows no databases
  - Permission issues during link-oratab
  - oraenv.sh not setting ORACLE_HOME
  - Extensions behavior in pre-Oracle mode
  - Dummy home testing scenarios

- **Pre-Oracle Quick Start**: New section in [03-quickstart.md](src/doc/03-quickstart.md)
  - Verify pre-Oracle installation
  - Understand pre-Oracle behavior
  - Post-Oracle integration steps
  - Complete setup verification

- **README Updates**: Added pre-Oracle support to feature list and installation examples

### Fixed

- **Installer Test Compatibility**: Added --silent flag to all installer tests to prevent hangs

## [0.16.0] - 2026-01-08

### Added

- **Extension Add Command**: New `oradba_extension.sh add` command for installing existing extensions
  - Install from GitHub repositories: short name (`oehrlis/odb_xyz`), versioned (`oehrlis/odb_xyz@v1.0.0`), or full URL
  - Install from local tarball files
  - Automatic structure validation (checks for `.extension` file or standard directories)
  - Update existing extensions with `--update` flag
  - RPM-style configuration handling: creates `.save` backup files for modified configs
  - Preserves logs and user data during updates
  - Timestamped backups of entire extension before update
  - Fallback support for repositories without releases (uses tags or main/master branch)

- **PATH and SQLPATH Deduplication**: Fixed extension path management to prevent duplicates
  - `remove_extension_paths()`: Removes all extension paths before reloading
  - `deduplicate_path()` and `deduplicate_sqlpath()`: Remove duplicate entries
  - Clean slate approach: removes all extension paths, reloads enabled extensions only
  - Preserves original PATH/SQLPATH in `ORADBA_ORIGINAL_PATH` and `ORADBA_ORIGINAL_SQLPATH`
  - Prevents PATH pollution when sourcing `oraenv.sh` multiple times
  - Properly removes disabled extension paths immediately

### Fixed

- **Extension Path Management**: Fixed issues with PATH and SQLPATH handling
  - Disabled extensions are now properly removed from PATH/SQLPATH without logout
  - Multiple sourcing of `oraenv.sh` no longer creates duplicate paths
  - Extension paths are now deduplicated keeping first occurrence

- **Extension Loading Messages**: Suppressed verbose output during interactive shell login
  - Changed extension loading messages from INFO to DEBUG level
  - Changed `add_to_sqlpath` messages from INFO to DEBUG level
  - Prevents extension messages from hiding `oraup.sh` output during login
  - Messages still visible with `DEBUG=1` when troubleshooting

- **Main oradba Directory Removal**: Fixed `remove_extension_paths()` incorrectly removing core oradba bin directory
  - Core `oradba/bin` and `oradba/sql` directories are now preserved
  - Only extension directories are removed during cleanup
  - Fixes issue where `oraup.sh` and other core commands disappeared from PATH after login

### Changed

- **Extension Loading**: Modified `load_extensions()` to use clean slate approach
  - Saves original PATH/SQLPATH on first run
  - Removes all extension paths before reloading
  - Only adds paths for enabled extensions
  - Deduplicates final PATH and SQLPATH

- **GitHub Integration**: Enhanced extension download to support repositories at any stage
  - Tries latest GitHub release first
  - Falls back to latest tag if no releases
  - Falls back to main/master branch if no tags
  - Allows installing extensions from development repositories

## [0.15.0] - 2026-01-07

### Changed

- **Extension Template Repository**: Extension templates moved to dedicated GitHub repository
  - Template content moved to [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)
  - Build process downloads latest template from GitHub releases
  - Cached in `templates/oradba_extension/extension-template.tar.gz`
  - Version tracking in `templates/oradba_extension/.version`
  - Reduces code duplication between repositories
  - `oradba_extension.sh` updated to use new path

### Added

- **Checksum Exclusion Support**: Added `.checksumignore` file for customizable integrity checks
  - Define patterns for files to exclude from checksum verification
  - Supports glob patterns: `*`, `?`, directory matching (`pattern/`)
  - Default exclusions: `.extension`, `.checksumignore`, `log/`
  - Per-extension configuration
  - Common use cases: credentials, caches, temporary files, user-specific configs
  - Template included in oradba_extension repository

- **Build Automation**: Added make targets for extension template management
  - `make download-extensions` - Download latest template from GitHub
  - `make clean-extensions` - Clean downloaded templates
  - Build script checks for newer versions automatically
  - Integrated into `make clean-all`

## [0.14.2] - 2026-01-07

### Changed

- **Extension Checksum Standardization**: Standardized extension checksum filename to `.extension.checksum`
  - Changed from `.${extension_name}.checksum` to fixed `.extension.checksum` naming
  - Simplifies checksum management - no need to rename when distributing
  - Automatically included in GitHub release tarballs without modification
  - Extension name now extracted from directory name instead of checksum filename
  - Backward compatible - old naming scheme still detected if present

- **Extension Verification Improvements**: Enhanced extension integrity checking behavior
  - Disabled extensions are now skipped during checksum verification
  - `.extension` metadata file excluded from verification (modified during installation)
  - `log/` directory excluded from verification (operational data)
  - Only enabled extensions shown in verification output
  - Prevents confusing "FAILED" messages for disabled extensions
  - Uses `awk` to properly parse checksum file format (hash filename pairs)

- **Installer Integrity Checks**: Modified installer to skip extension verification
  - Added `--verify-core` option to verify only core OraDBA files
  - Installer now uses `--verify-core` instead of `--verify`
  - Extension issues no longer cause installation failures
  - Users can still verify extensions manually with `--verify` or `--info`

### Fixed

- **Main OraDBA Directory Exclusion**: Fixed false positive detection of OraDBA as extension
  - `check_extension_checksums()` now correctly excludes `ORADBA_BASE` directory
  - Uses canonical path comparison to handle symlinks properly
  - Prevents "Extension 'oradba': FAILED" error during verification
  - Only processes actual extension directories, not the main installation

- **Color Code Display**: Fixed ANSI escape codes appearing in extension status output
  - Changed from `printf` to `echo -e` for checksum status display
  - Color indicators (✓/✗) now render correctly instead of showing raw escape codes
  - Improved readability of extension integrity status

### Added

- **Verbose Mode for Extension Checks**: Added `--verbose` flag for detailed integrity information
  - Shows modified or missing files with `${EXTENSION_BASE}` prefix
  - Detects additional files not in checksum (e.g., new scripts added)
  - Works with both `--verify` and `--info` commands
  - Usage: `oradba_version.sh --verify --verbose`

- **Extension Base Variables**: Automatic environment variables for each loaded extension
  - Each extension exports `<NAME>_BASE` variable (e.g., `USZ_BASE=/opt/oracle/local/usz`)
  - Simplifies referencing extension paths in scripts and documentation
  - Complements existing `ORADBA_EXT_<NAME>_PATH` variables
  - Automatically set when extension is loaded

- **Documentation Updates**: Enhanced extension documentation with checksum information
  - Added `.extension.checksum` to directory structure examples
  - Documented that `.extension` and `log/` are excluded from verification
  - Added integrity check troubleshooting section in user guide
  - Included checksum update instructions for intentional file changes

## [0.14.1] - 2026-01-06

### Added

- **CLI Parameters for Selective Backups**: Added command-line parameters for tablespaces, datafiles, and PDBs
  - `--tablespaces <names>`: Specify tablespace names (comma-separated, e.g., USERS,TOOLS)
  - `--datafiles <numbers>`: Specify datafile numbers or paths (comma-separated, e.g., 1,2,3)
  - `--pdb <names>`: Specify pluggable database names (comma-separated, e.g., PDB1,PDB2)
  - CLI parameters override config variables `RMAN_TABLESPACES`, `RMAN_DATAFILES`, and `RMAN_PLUGGABLE_DATABASE`
  - Updated `oradba_rman.sh` help and examples
  - Updated `src/doc/09-rman-scripts.md` with usage examples

- **10 Additional RMAN Scripts**: Extended backup and recovery script library
  - **2 Backup Scripts**:
    - `bck_arc.rcv`: Archive logs backup only (without logswitch)
    - `bck_ctl.rcv`: Controlfile backup only
  - **8 Recovery Scripts** converted from TVD Backup to OraDBA format:
    - `rcv_arc.rcv`: Restore archivelogs by sequence number range
    - `rcv_ctl.rcv`: Restore controlfile from backup
    - `rcv_db.rcv`: Complete database recovery (controlfiles in place)
    - `rcv_db_pitr.rcv`: Database point-in-time recovery (PITR)
    - `rcv_df.rcv`: Datafile recovery
    - `rcv_standby_db.rcv`: Create standby database from primary backup
    - `rcv_ts.rcv`: Tablespace recovery
    - `rcv_ts_pitr.rcv`: Tablespace point-in-time recovery (TSPITR)
  - **Total**: 34 RMAN scripts (18 backup + 7 maintenance + 1 reporting + 8 recovery)

- **RMAN Template Tag Support Extended**: Added support for 4 additional template tags
  - `<SPFILE_BACKUP>`: Conditional SPFILE text backup (pfile creation)
  - `<BACKUP_KEEP_TIME>`: Long-term retention with KEEP clause
  - `<RESTORE_POINT>`: Guaranteed restore point creation
  - Configuration parameters: `RMAN_SPFILE_BACKUP`, `RMAN_BACKUP_KEEP_TIME`, `RMAN_RESTORE_POINT`

- **23 RMAN Script Templates Converted from TVD Backup**: Comprehensive backup script library
  - **16 Backup Scripts**: Full, incremental (level 0/1 differential/cumulative), specialized backups
    - `bck_db_keep.rcv`: Full backup with retention guarantee
    - `bck_db_validate.rcv`: Full database validation
    - `bck_inc0.rcv`, `bck_inc0_noarc.rcv`: Incremental level 0 with/without archives
    - `bck_inc0_cold.rcv`: Offline (cold) incremental level 0
    - `bck_inc0_df.rcv`: Incremental level 0 for specific datafiles
    - `bck_inc0_pdb.rcv`: Incremental level 0 for pluggable databases
    - `bck_inc0_rec_area.rcv`: Incremental level 0 to recovery area
    - `bck_inc0_ts.rcv`: Incremental level 0 for specific tablespaces
    - `bck_inc1c.rcv`, `bck_inc1c_noarc.rcv`: Cumulative level 1 with/without archives
    - `bck_inc1d.rcv`, `bck_inc1d_noarc.rcv`: Differential level 1 with/without archives
    - `bck_recovery_area.rcv`: Fast recovery area backup (requires SBT)
    - `bck_standby_inc0.rcv`: Incremental level 0 for standby database setup
  - **7 Maintenance Scripts**: Crosscheck, delete, register, sync operations
    - `mnt_chk.rcv`: Crosscheck backups/copies and delete expired
    - `mnt_chk_arc.rcv`: Crosscheck archive logs
    - `mnt_del_arc.rcv`: Delete archive logs (commented for safety)
    - `mnt_del_obs.rcv`: Delete obsolete backups (commented for safety)
    - `mnt_del_obs_nomaint.rcv`: Delete obsolete without maintenance window
    - `mnt_reg.rcv`: Register database and set snapshot controlfile
    - `mnt_sync.rcv`: Resync RMAN catalog
  - **1 Reporting Script**: Backup status and requirements
    - `rpt_bck.rcv`: Report incarnation, unrecoverable objects, and backup needs
  - **Conversion Details**: Exact 1:1 conversion from TVD Backup templates
    - Template tag updates: `<COMPRESS>` → `<COMPRESSION>`, `<CTLFILE_PATH>` → `<BACKUP_PATH>`
    - Replaced legacy `<BCK_PATH>` with `<BACKUP_PATH>` (12 files, 28 occurrences)
    - Added `SHOW ALL;` and `<SET_COMMANDS>` for OraDBA compatibility
    - Removed `filesperset` directives (handled by wrapper configuration)
    - Preserved all RMAN command structures and logic exactly
    - Maintained separation of concerns: backup scripts vs maintenance scripts

- **RMAN Template Enhancement (#TBD)**: Comprehensive RMAN template system expansion
  - **12 New Template Tags** in `src/bin/oradba_rman.sh`:
    - `<SET_COMMANDS>`: Custom RMAN SET commands (inline or external file)
    - `<TABLESPACES>`: Specific tablespaces for selective backup
    - `<DATAFILES>`: Specific datafiles for selective backup  
    - `<PLUGGABLE_DATABASE>`: Specific PDBs for container database backups
    - `<SECTION_SIZE>`: Enables multisection backup for large datafiles
    - `<ARCHIVE_RANGE>`: Archive log range specification (ALL, FROM TIME, FROM SCN)
    - `<ARCHIVE_PATTERN>`: LIKE clause for archive log filtering
    - `<RESYNC_CATALOG>`: RMAN catalog resync command (when catalog configured)
    - `<CUSTOM_PARAM_1>`, `<CUSTOM_PARAM_2>`, `<CUSTOM_PARAM_3>`: User-defined parameters
  - **15 New Configuration Parameters** in `src/etc/oradba_rman.conf.example`:
    - `RMAN_SET_COMMANDS_INLINE`: Inline SET commands string
    - `RMAN_SET_COMMANDS_FILE`: External SET commands file path (hybrid approach)

### Changed

- **Function Rename (#16)**: Renamed `log()` to `oradba_log()` to avoid conflicts
  - **Root Cause**: `log` alias (`cd ${ORADBA_LOG}`) in `oradba_standard.conf` caused
    bash to expand the alias during function definition, turning `log() {` into
    `cd ${ORADBA_LOG}() {` which is a syntax error
  - **Solution**: Renamed function to `oradba_log()` for cleaner namespace separation
  - **Impact**: All internal calls updated across 9 files
  - **Backward Compatibility**: Deprecated wrapper functions remain (`log_info`, `log_warn`,
    `log_error`, `log_debug`) - all now call `oradba_log()`
  - **Documentation**: Updated all docs and examples to use `oradba_log()`
  - Release workflow now installs `markdownlint-cli` to run Markdown linting instead of skipping with a warning

### Fixed

- **RMAN Maintenance Scripts**: Added missing `RUN { }` blocks for proper RMAN syntax
  - Fixed `mnt_del_obs.rcv`: Added RUN block around channel allocation and delete commands
  - Fixed `mnt_chk.rcv`: Added RUN block around channel allocation and crosscheck operations
  - Fixed `mnt_del_obs_nomaint.rcv`: Removed hardcoded channel, cleaned up RUN block
  - Error prevented: "RMAN-00558: error encountered while parsing input commands"
  - Error prevented: "RMAN-01009: syntax error: found 'identifier': expecting one of: 'for'"

- **rlwrap Filter**: Fixed double-exit issue in RMAN sessions with rlwrap
  - Modified `src/etc/rlwrap_filter_oracle` to return input instead of empty string for password prompts
  - Previously: returning empty string "" caused rlwrap to misinterpret exit commands
  - Now: Uses `send_output_oob("\x00")` to signal history exclusion while returning actual input
  - Single `exit` command now properly terminates RMAN without requiring second exit

- **longops.sh**: Fixed output line wrapping and formatting issues
  - Increased LINESIZE from 120 to 160 for wider display
  - Added SET TRIMOUT ON and SET TRIMSPOOL ON to remove trailing spaces
  - Changed time formatting from `TO_CHAR` with format masks to `LPAD` function
  - Fixed time_remain to display as "000:00:08" instead of " 000:  00:  08" (no extra spaces)
  - Increased message column from A35 to A50 for longer operation descriptions
  - Added WORD_WRAPPED attribute to prevent mid-word line breaks
  - Fixed "Remaining" column displaying on multiple lines

- **RMAN Command Syntax**: Corrected SET vs CONFIGURE usage in scripts and documentation
  - Fixed `mnt_reg.rcv`: Changed `SET SNAPSHOT CONTROLFILE` to `CONFIGURE SNAPSHOT CONTROLFILE`
  - Fixed `src/doc/09-rman-scripts.md`: Updated examples to use `CONFIGURE` for persistent settings
  - Clarified: CONFIGURE for persistent configuration, SET for session-specific settings

- **oradba_check.sh**: Made version detection dynamic instead of hardcoded
  - Now reads version from VERSION file at runtime instead of hardcoded SCRIPT_VERSION
  - Provides fallback version for standalone distribution scenarios
  - Eliminates need to manually update version in script for each release

- **oradba_version.sh**: Fixed duplicate file reporting in integrity checks
  - Added deduplication using associative array to track reported files
  - Prevents same missing/modified file from appearing multiple times
  - Handles cases where files appear multiple times in checksum file

- **oradba_validate.sh**: Added missing file detection and reporting
  - Now tracks and reports missing files separately from modified files
  - Added deduplication to prevent reporting same file multiple times
  - Missing files shown with red ✗ symbol in verbose output
  - Added missing file count to summary section
  - Missing files included in warnings count

## [0.14.0] - 2026-01-05

### 🔴 CRITICAL BUG FIXES

- **RMAN Wrapper False Success Bug** (#56 Phase 6): Fixed critical production bug where
  `oradba_rman.sh` reported success even when RMAN backups failed
  - **Root Cause**: RMAN always returns exit code 0, and piping to `tee` masked the exit code
  - **Solution**: Capture RMAN exit code using `${PIPESTATUS[0]}` before pipe masks it
  - **Error Detection**: Check log file for `RMAN-00569` error pattern (standard RMAN error indicator)
  - **Impact**: Prevents silent backup failures in production environments
  - **Example Failure**:

    ```text
    # Script incorrectly reported:
    [INFO] RMAN execution successful for FREE
    [INFO] Successful: 1, Failed: 0
    
    # But log showed:
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00558: error encountered while parsing input commands
    ```

### Added

- **RMAN Backup Path Configuration**: Add backup destination path support
  - New config variable: `RMAN_BACKUP_PATH` in per-SID config files
  - New CLI parameter: `--backup-path <path>` (overrides config)
  - New template tag: `<BACKUP_PATH>` for RMAN scripts
  - CLI parameter takes precedence over config file
  - **Example**: `oradba_rman.sh --sid PROD --rcv backup_full.rcv --backup-path /backup/prod`

- **Enhanced Dry-Run Mode** (`--dry-run`): Comprehensive preview of RMAN execution
  - Saves processed `.rcv` script to log directory with timestamp
  - Displays complete generated RMAN script content
  - Shows exact RMAN command that would be executed
  - Perfect for debugging template processing issues
  - **Example**: `oradba_rman.sh --sid FREE --rcv backup_full.rcv --dry-run`

- **Automatic Script Preservation**: Always save processed RMAN scripts
  - Every execution saves the processed `.rcv` to log directory
  - Naming pattern: `<script>_YYYYMMDD_HHMMSS.rcv` (matches log files)
  - Enables post-execution troubleshooting and analysis
  - Path displayed in success/error messages
  - **Example locations**:
    - Log: `/u01/admin/FREE/log/backup_full_20260105_143022.log`
    - RCV: `/u01/admin/FREE/log/backup_full_20260105_143022.rcv`

- **Cleanup Control** (`--no-cleanup`): Preserve temp files for debugging
  - New flag preserves temp directory after execution
  - Default behavior unchanged (temp files still removed)
  - Useful for debugging parallel execution and template processing
  - Shows temp directory path when preserved
  - **Example**: `oradba_rman.sh --sid FREE --rcv backup_full.rcv --no-cleanup`

- **Extension Checksum Verification**: Add integrity checking for extensions
  - New function: `check_extension_checksums()` in `oradba_version.sh`
  - Automatically detects and verifies `.{extension}.checksum` files in `extensions/` directory
  - Integrated into `oradba_version.sh --verify` and `--info` commands
  - Reports status for each extension:
    - [OK] Extension verified (n files)
    - [X] Extension FAILED with list of modified/missing files
  - Helps ensure custom extensions haven't been tampered with
  - **Example**: `.customer.checksum` validates all files in customer extension

### Changed

- **Updated `src/bin/oradba_rman.sh`** from v0.13.7 to v0.14.0
  - Added `OPT_BACKUP_PATH` and `OPT_NO_CLEANUP` global variables
  - Enhanced `load_rman_config()` to load `RMAN_BACKUP_PATH` from config
  - Updated `process_template()` to support `<BACKUP_PATH>` tag
  - **Fixed `execute_rman_for_sid()` error detection logic**:
    - Capture RMAN exit code before pipe: `rman_exit_code=${PIPESTATUS[0]}`
    - Check log for RMAN-00569: `grep -q "RMAN-00569" "${sid_log}"`
    - Report failure if either exit code non-zero OR error pattern found
    - Always save processed script to log directory
  - Enhanced dry-run mode with save + display functionality
  - Added conditional cleanup based on `--no-cleanup` flag
  - Updated `usage()` with new parameters and examples
  - **Lines changed**: +76 insertions, -10 deletions

- **Updated `src/bin/oradba_version.sh`** from v0.11.0 to v0.14.0
  - Added `check_extension_checksums()` function for extension integrity verification
  - Integrated extension checks into `check_integrity()` workflow
  - Returns combined status of core + extension integrity checks

- **Updated documentation**:
  - Enhanced RMAN wrapper `usage()` with all new options
  - Added comprehensive examples for each new feature
  - Updated template tags documentation to include `<BACKUP_PATH>`
  - Updated configuration variables list with `RMAN_BACKUP_PATH`

### Documentation

- **API Documentation** ([doc/api.md](doc/api.md)):
  - Comprehensive expansion from 888 to 1,874 lines (+986 lines, +111% growth)
  - Added 39 previously undocumented public functions (35% → 100% coverage)
  - New sections:
    - Information Display Functions (5 functions): `show_config`, `show_path`,
      `show_sqlpath`, `configure_sqlpath`, `add_to_sqlpath`
    - BasEnv Integration Functions (3 functions): `detect_basenv`, `alias_exists`,
      `safe_alias`
    - SID/PDB Management (3 functions): `generate_sid_lists`, `generate_pdb_aliases`,
      `is_dummy_sid`
    - Version Management Functions (4 functions): `get_oradba_version`, `version_compare`,
      `version_meets_requirement`, `show_version_info`
    - Installation Info Functions (3 functions): `get_install_info`, `set_install_info`,
      `init_install_info`
    - Database Functions (10 functions): Complete module documentation
    - Alias Helper Functions (4 functions): `get_diagnostic_dest`, `has_rlwrap`,
      `generate_sid_aliases`, `generate_base_aliases`
    - Extension Management Functions (11 functions): Complete module documentation

- **Installation Guide** ([src/doc/02-installation.md](src/doc/02-installation.md)):
  - Added 6 comprehensive installation methods:
    1. Direct Git Clone (single user)
    2. Git Clone with Shared Installation (multi-user)
    3. Release Archive (offline/restricted environments)
    4. Ansible Deployment (infrastructure automation)
    5. Manual Installation (maximum control)
    6. Container/Docker Installation (development/testing)
  - Complete Ansible deployment playbook with role structure
  - Installation scenarios (new installation, updates, version management)
  - Enhanced BasEnv coexistence documentation
  - Production-ready examples (+600 lines)

- **Test Documentation** ([tests/README.md](tests/README.md)):
  - Updated test suite inventory: 9 → 20 test files
  - Test coverage: 227 → 658 total tests (+189% growth)
  - Added 11 previously undocumented test files:
    - test_oradba_aliases.bats (38 tests)
    - test_execute_db_query.bats (22 tests)
    - test_extensions.bats (42 tests)
    - test_logging.bats (28 tests)
    - test_oradba_check.bats (24 tests)
    - test_oradba_help.bats (12 tests)
    - test_oradba_rman.bats (44 tests, includes 9 new v0.14.0 tests)
    - test_oradba_sqlnet.bats (51 tests)
    - test_oraup.bats (20 tests)
    - test_service_management.bats (51 tests)
    - test_sid_config.bats (17 tests)
  - Updated all test counts to current values
  - Added component mapping and descriptions for all test files

- **Release Notes** ([doc/releases/v0.14.0.md](doc/releases/v0.14.0.md)):
  - Created comprehensive 570-line release documentation
  - Critical bug explanation with root cause analysis
  - Migration guide for new features
  - Testing instructions and verification steps
  - Configuration examples and best practices

- **Mermaid Diagrams** ([doc/images/source/diagrams-mermaid.md](doc/images/source/diagrams-mermaid.md)):
  - Updated **Architecture System** diagram (Diagram 6):
    - Changed "Logging" to "oradba_log" in Core Libraries to reflect function rename
  - Updated **oraenv.sh Execution Flow** diagram (Diagram 7):
    - Added SID config auto-creation logic branch
    - Shows decision flow when `ORADBA_AUTO_CREATE_SID_CONFIG=true`
    - Documents template-based config generation for missing SID configs
  - Updated **Configuration Hierarchy** diagram (Diagram 8):
    - Added note about auto-creation feature in Level 4 (SID Configuration)
  - Updated **Configuration Loading Sequence** diagram (Diagram 9):
    - Changed from simple load to alt/else flow showing:
      - Config file exists → Load
      - Auto-create enabled & SID in oratab → Auto-create from template
      - Auto-create disabled → Skip
  - Added new **SID Config Auto-Creation Flow** diagram (Diagram 12):
    - Complete flowchart of auto-creation logic
    - Shows validation steps: ORATAB_FILE check, regex pattern matching
    - Documents create_sid_config() function flow
    - Illustrates Issue #16 bug fixes (ORATAB_FILE usage, file existence check)
  - **Note**: PNG exports will be generated manually from updated Mermaid definitions

- **Updated RMAN Usage Examples**:

  ```bash
  # With backup path from config
  RMAN_BACKUP_PATH="/backup/prod"
  oradba_rman.sh --sid PROD --rcv backup_full.rcv
  
  # Override backup path via CLI
  oradba_rman.sh --sid PROD --rcv backup_full.rcv --backup-path /backup/prod_daily
  
  # Dry-run to see generated script
  oradba_rman.sh --sid FREE --rcv backup_full.rcv --dry-run
  
  # Keep temp files for troubleshooting
  oradba_rman.sh --sid FREE --rcv backup_full.rcv --no-cleanup
  ```

- **Information Display Aliases** (#56 Phase 6): Consolidated configuration and environment inspection
  - New alias `pth` using `show_path()` to display PATH structure similar to `sqa` (`show_sqlpath()`)
  - New alias `cfg` using `show_config()` to display OraDBA configuration hierarchy and load order
    - Shows 5-level configuration hierarchy: core → standard → customer → default → SID-specific
    - Validates which config files exist and were loaded
    - Status indicators: `[[OK] loaded]`, `[[X] MISSING - REQUIRED]`, `[- not configured]`
    - Helps troubleshoot configuration precedence and missing files
  - Grouped `sqa` (SQLPATH), `pth` (PATH), and `cfg` (config) together in documentation
  - All three use similar output format with validation markers
  - Updated documentation with new "Information Display" section

- **Standalone Prerequisites Check Script** (#56 Phase 6): `oradba_check.sh` now available as release artifact
  - Can be downloaded and run BEFORE installation to validate system prerequisites
  - Available from GitHub releases: `oradba_check.sh`
  - Validates all installer requirements:
    - System tools: bash, tar, awk, sed, grep, find, sort
    - Checksum utilities: sha256sum or shasum
    - Base64 encoder: base64 (required for installer with embedded payload)
    - Optional tools: rlwrap, curl/wget, less
    - Disk space: 100MB minimum for installation
    - Oracle environment (if configured)
    - Oracle binaries and database connectivity (if installed)
  - **Build system updated**:
    - `scripts/build_installer.sh` now creates 3 release artifacts:
      - `oradba-X.Y.Z.tar.gz` (full package)
      - `oradba_install.sh` (installer with embedded payload)
      - `oradba_check.sh` (standalone prerequisites checker)
    - Version automatically injected during build process
  - **Usage modes**:
    - Pre-installation: Download from releases and run to verify prerequisites
    - Post-installation: Available in `bin/` directory for troubleshooting
  - Enhanced usage text with download instructions and comprehensive examples
  - Dynamic banner formatting supports any version length (0.7.0, 0.14.2, 10.15.234, etc.)

### Files Updated

- **Updated `oradba_check.sh`** from v0.7.0 to v0.13.7
  - Added base64 availability check to system tools validation
  - Enhanced script header documentation to clarify dual-use capability
  - Updated usage text with pre-installation example using curl piped to bash
  - Improved checks list with detailed descriptions of each validation

- **Documentation updates**:
  - Added "Prerequisites Check" section to README before installation instructions
  - Added "Troubleshooting" section with common issues and solutions
  - Updated build output to list all 3 release artifacts

### Summary

Release 0.14.0 is a **critical update** addressing a production bug in RMAN wrapper that could
allow backup failures to go undetected. All users running automated backups should upgrade
immediately.

**Key Changes**:

- 🔴 Critical bug fix: RMAN false success reporting
- ✨ 5 new RMAN features: backup path, enhanced dry-run, script preservation, cleanup control, error detection
- ✅ Extension checksum verification
- 📊 Information display aliases (cfg, pth)
- 🔍 Standalone prerequisites checker

**Files Changed**: 4 files

- `src/bin/oradba_rman.sh` (+76/-10 lines)
- `src/bin/oradba_version.sh` (+86 lines)
- `VERSION` (0.13.5 → 0.14.0)
- `CHANGELOG.md` (this file)

**Upgrade Priority**: HIGH (critical bug fix)

## [0.13.5] - 2026-01-05

### Added

- **Unified Configuration File Loader (#56 Phase 5)**: Consolidated configuration loading
  - New function: `load_config_file()` in `src/lib/oradba_common.sh`
    - Signature: `load_config_file <file_path> [required]`
    - Parameters:
      - `file_path` - Full path to configuration file (required)
      - `required` - "true" for required files (fail if missing), "false" for optional (default)
    - **Automatic logging**: Uses `log_debug()` for successful loads, `log_error()` for required file failures
    - **Shellcheck suppression**: Centralized `shellcheck source=/dev/null` directive
    - **Return codes**: 0 for success/skipped, 1 for required file missing
  - **Test Suite**: 10 comprehensive BATS tests in `tests/test_oradba_common.bats` (32 total tests)
    - Function existence and parameter validation
    - Required vs optional config handling
    - Missing file behavior (error vs silent skip)
    - Config file sourcing and variable loading
    - Debug logging validation
    - All 650 tests passing with 0 failures

### Changed

- Updated `src/lib/oradba_common.sh` from v0.13.2 to v0.13.5
  - Added `load_config_file()` function (lines 531-556)
  - **Refactored `load_config()` function**: Reduced from 83 lines to 61 lines (~27% reduction)
    - Eliminated 5 repetitive config loading blocks with duplicated logic
    - Each config load: 8-10 lines → 1 line using `load_config_file()`
    - Maintains all functionality: hierarchy, auto-export, SID-specific configs, auto-create
    - Configuration hierarchy unchanged:
      1. `oradba_core.conf` (required)
      2. `oradba_standard.conf` (required with warning)
      3. `oradba_customer.conf` (optional)
      4. `sid._DEFAULT_.conf` (optional)
      5. `sid.<ORACLE_SID>.conf` (optional with auto-create)
- Updated `src/bin/oraenv.sh` config loading
  - Simplified 14 lines to 4 lines (~71% reduction)
  - Migrated 2 manual config loads to use `load_config_file()`
  - Configs: `oradba_core.conf` (required), `oradba_local.conf` (optional)
- **Total code reduction**: ~67 lines of duplicated configuration loading logic eliminated
- **Centralized error handling**: All config loading now uses consistent logging and return codes

### Documentation

- Updated `doc/api.md` with comprehensive configuration function documentation
  - Added `load_config_file()` section with signature, parameters, examples
  - Enhanced `load_config()` documentation with hierarchy details
  - Added usage examples for required vs optional configs

**Impact**: Phases 3-5 collectively reduce code duplication by ~200 lines, improve
maintainability, and establish consistent patterns for metadata access, alias generation,
and configuration loading.

**Resolves:** #56 Phase 5 - Configuration Loading Refactoring

## [0.13.4] - 2026-01-04

### Added

- **Unified Alias Generation Helper (#56 Phase 4)**: Consolidated dynamic alias creation
  - New function: `create_dynamic_alias()` in `src/lib/oradba_aliases.sh`
    - Signature: `create_dynamic_alias <name> <command> [expand]`
    - Parameters:
      - `name` - Alias name (required)
      - `command` - Alias command/value (required)
      - `expand` - "true" for immediate variable expansion, "false" for runtime expansion (default)
    - **Automatic expansion handling**: Expands variables immediately or at runtime
    - **Shellcheck suppression**: Automatically handles SC2139 for expanded aliases
    - **Coexistence mode support**: Internally calls `safe_alias()` respecting all modes
    - Returns: Exit code from `safe_alias` (0=created, 1=skipped, 2=error)
  - **Test Suite**: 7 comprehensive BATS tests in `tests/test_oradba_aliases.bats` (38 total alias tests)
    - Function existence and parameter validation
    - Expanded vs non-expanded alias creation
    - Required parameter enforcement
    - Coexistence mode integration
    - Directory navigation patterns
    - Complex command handling
    - All 38 tests passing with 0 failures

### Changed

- Updated `src/lib/oradba_aliases.sh` from v0.13.0 to v0.13.4
  - Added `create_dynamic_alias()` function (lines 18-38)
- **Migrated 19 alias creation calls** in `src/lib/oradba_aliases.sh` to use `create_dynamic_alias()`
  - Eliminated repetitive `safe_alias` calls with manual shellcheck disables
  - All aliases maintain 100% backward-compatible behavior
  - Code patterns standardized:
    - **Directory navigation** (6 aliases): `cdd`, `cddt`, `cdda`, `cdbase` - expanded mode
    - **Service management** (13 aliases): `dbctl`, `dbstart`, `lsnrstart`, etc. - non-expanded mode
  - **Total boilerplate eliminated**: 19 shellcheck disable comments + repetitive patterns
  - Code reduction: ~30-40% for alias generation blocks
  - Improved maintainability with centralized expansion logic

### Documentation

- Updated `doc/api.md` with comprehensive `create_dynamic_alias()` documentation
  - Function signature and parameter descriptions
  - Expansion behavior explanation (immediate vs runtime)
  - Use case examples (directory navigation, service management, tool wrappers)
  - Migration examples showing before/after patterns
  - Clear guidance on when to use expanded vs non-expanded modes

**Resolves:** #56 Phase 4 - Alias Generation Refactoring

## [0.13.3] - 2026-01-04

### Added

- **Unified Extension Property Accessor (#56 Phase 3)**: Consolidated extension metadata access
  - New function: `get_extension_property()` in `src/lib/extensions.sh`
    - Signature: `get_extension_property <ext_path> <property> [fallback] [check_config]`
    - Parameters:
      - `ext_path` - Path to extension directory
      - `property` - Property name to retrieve (e.g., "name", "version", "priority", "enabled")
      - `fallback` - Optional fallback value if property not found (default: empty)
      - `check_config` - Optional "true" to check `ORADBA_EXT_<NAME>_<PROPERTY>` environment variable override
    - **Property precedence** applied automatically:
      1. Environment variable override (if `check_config=true`)
      2. Extension `.extension` metadata file
      3. Fallback value
      4. Empty string
    - **Configuration override support**: `ORADBA_EXT_<NAME>_<PROPERTY>` environment variables
    - **Metadata file parsing**: Reads YAML-like key-value pairs from `.extension` file
    - Returns: Property value string to stdout
  - **Test Suite**: 9 comprehensive BATS tests in `tests/test_extensions.bats` (42 total extension tests)
    - Function existence and parameter handling
    - Metadata property reading (name, version, custom fields)
    - Fallback behavior (with and without values)
    - Config override handling (enabled/disabled modes)
    - Precedence verification (config > metadata > fallback)
    - Migration verification (confirms functions use new implementation)
    - All 42 tests passing with 0 failures

### Changed

- Updated `src/lib/extensions.sh` from v0.13.0 to v0.13.3
  - Added `get_extension_property()` function (lines 104-142)
- **Migrated 5 extension metadata functions** in `src/lib/extensions.sh` to use `get_extension_property()`
  - Eliminated **~69 lines** of duplicated metadata access code
  - All functions maintain 100% backward-compatible signatures
  - Code reduction per function:
    - `get_extension_name()`: 18 lines → 5 lines (72% reduction)
    - `get_extension_version()`: 11 lines → 3 lines (73% reduction)
    - `get_extension_description()`: 7 lines → 3 lines (57% reduction)
    - `get_extension_priority()`: 17 lines → 3 lines (82% reduction)
    - `is_extension_enabled()`: 16 lines → 4 lines (75% reduction)
  - **Total boilerplate eliminated**: 69 lines → 18 lines (74% reduction)
  - All functions now leverage unified metadata accessor with config override support

### Documentation

- Updated `doc/api.md` with comprehensive `get_extension_property()` documentation
  - Function signature and parameter descriptions
  - Property precedence explanation
  - Usage examples (basic, with fallback, with config override)
  - Configuration override naming conventions
  - Convenience wrapper function documentation

**Resolves:** #56 Phase 3 - Extension Metadata Standardization

## [0.13.2] - 2026-01-04

### Added

- **Unified SQL Query Executor (#56 Phase 2)**: Consolidated SQL*Plus query execution
  - New function: `execute_db_query()` in `src/lib/oradba_common.sh`
    - Signature: `execute_db_query <query> [format]`
    - Parameters:
      - `query` - SQL query to execute (can be multiline)
      - `format` - Optional output format: `raw` (default) or `delimited`
    - **Standardized SQL*Plus configuration** applied automatically:
      - `SET PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON TRIMOUT ON`
      - `SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF`
      - `SET TIMING OFF TIME OFF SQLPROMPT "" SUFFIX SQL`
      - `SET TAB OFF UNDERLINE OFF WRAP ON COLSEP ""`
      - `SET SERVEROUTPUT OFF TERMOUT ON`
      - `WHENEVER SQLERROR EXIT FAILURE`
      - `WHENEVER OSERROR EXIT FAILURE`
    - **Automatic error filtering**: Removes SP2-, ORA-, ERROR messages, and SQL*Plus banners
    - **Format-specific processing**:
      - `raw`: Direct SQL*Plus output with whitespace trimmed (default)
      - `delimited`: Extract first pipe-delimited line
    - Returns: 0 on success with output to stdout, 1 on failure
  - **Test Suite**: 22 comprehensive BATS tests in `tests/test_execute_db_query.bats`
    - Function existence and parameter validation
    - Format acceptance (raw, delimited, default)
    - Integration verification with all migrated functions
    - Code quality checks (error logging, SQL*Plus settings, error filtering)
    - Documentation presence
    - Boilerplate elimination verification
    - Backward compatibility validation

### Changed

- Updated `src/lib/oradba_common.sh` from v0.13.1 to v0.13.2
  - Added `execute_db_query()` function (lines 130-198)
- **Migrated 6 database query functions** in `src/lib/oradba_db_functions.sh` to use `execute_db_query()`
  - Eliminated **~240 lines** of duplicated SQL*Plus boilerplate code
  - All functions maintain 100% backward-compatible signatures
  - Code reduction per function:
    - `query_instance_info()`: 35 lines → 27 lines (23% reduction)
    - `query_database_info()`: 42 lines → 30 lines (29% reduction)
    - `query_datafile_size()`: 32 lines → 20 lines (38% reduction)
    - `query_memory_usage()`: 38 lines → 27 lines (29% reduction)
    - `query_sessions_info()`: 35 lines → 24 lines (31% reduction)
    - `query_pdb_info()`: 38 lines → 32 lines (16% reduction)
  - **Migrated Functions**:
    - `query_instance_info()` - v$instance + v$parameter queries
    - `query_database_info()` - v$database metadata
    - `query_datafile_size()` - Total datafile size in GB
    - `query_memory_usage()` - SGA/PGA memory usage
    - `query_sessions_info()` - Session count statistics
    - `query_pdb_info()` - Pluggable database information
- Updated documentation for SQL query executor
  - `doc/api.md`: Comprehensive `execute_db_query()` API documentation with examples
  - `doc/development.md`: Added "Database Queries" best practices section
    - Proper dollar sign escaping in SQL (`v\$database` not `v$database`)
    - Quote handling (double quotes for queries with single quotes)
    - Format selection guidance (raw vs delimited)
    - Error handling patterns
    - Migration examples (before/after patterns)
  - `src/lib/README.md`: Updated function listings with version notes

### Technical Notes

**SQL Query Best Practices:**

- **Always escape dollar signs**: Use `v\$database` not `v$database` in queries
- **Use double-quoted strings**: For queries containing single quotes

  ```bash
  local query="SELECT name || '|' || status FROM v\$instance;"
  ```

- **Choose appropriate format**:
  - `raw` - Multi-line output, single values, or no delimiters
  - `delimited` - Pipe-separated values (extracts first line only)
- **Handle failures**: Check return code or verify result is non-empty

**Migration Pattern:**

```bash
# Before (old pattern - 40+ lines of boilerplate)
query_database_info() {
    result=$(sqlplus -s / as sysdba 2>/dev/null << 'EOF'
SET PAGESIZE 0 LINESIZE 500 TRIMSPOOL ON TRIMOUT ON
SET HEADING OFF FEEDBACK OFF VERIFY OFF ECHO OFF
...
SELECT d.name FROM v$database d;
EXIT;
EOF
)
    echo "$result" | grep -v "^SP2-\|^ORA-"
}

# After (new pattern - 10-15 lines)
query_database_info() {
    local query="SELECT name FROM v\$database;"
    execute_db_query "$query" "raw"
}
```

Resolves: #56 (Phase 2 - SQL Query Consolidation)

## [0.13.1] - 2026-01-04

### Added

- **Unified Logging System (#56 Phase 1)**: Consolidated logging with level-based filtering
  - New unified `log()` function with single signature: `log <LEVEL> <message...>`
    - Supported levels: `DEBUG`, `INFO`, `WARN`, `ERROR` (case-insensitive)
    - All messages output to stderr with consistent format: `[LEVEL] YYYY-MM-DD HH:MM:SS - message`
  - **Level-based filtering** via `ORADBA_LOG_LEVEL` environment variable
    - `DEBUG` (0): Show all messages including DEBUG
    - `INFO` (1): Show INFO, WARN, ERROR (default)
    - `WARN` (2): Show only WARN and ERROR
    - `ERROR` (3): Show only ERROR messages
  - **Legacy DEBUG support**: `DEBUG=1` automatically enables DEBUG level for backward compatibility
  - **Backward-compatible deprecation wrappers**:
    - `log_info()`, `log_warn()`, `log_error()`, `log_debug()` still work
    - Opt-in deprecation warnings via `ORADBA_SHOW_DEPRECATION_WARNINGS=true`
    - Warnings shown once per function per session
  - **Test Suite**: 28 comprehensive BATS tests covering:
    - Basic functionality and output redirection
    - Log level filtering (default, explicit, case-insensitive)
    - DEBUG=1 backward compatibility
    - Deprecated function wrappers
    - Deprecation warnings (opt-in, session tracking)
    - Message formatting (multiple arguments, variables, special characters)
    - Integration with existing functions

### Changed

- Updated `src/lib/oradba_common.sh` from v0.11.0 to v0.13.1
  - Replaced individual `log_*` implementations with unified `log()` function
  - Deprecated functions now call `log()` internally for consistency
- Updated documentation for new logging system
  - `doc/api.md`: Comprehensive logging API documentation with migration guide
  - `doc/development.md`: Updated coding standards with best practices
  - `src/lib/README.md`: Updated examples showing new and legacy syntax

### Migration Notes

**New Code** should use the unified `log()` function:

```bash
log INFO "Database started successfully"
log WARN "Archive log directory is 90% full"  
log ERROR "Connection to database failed"
log DEBUG "SQL query: ${sql_query}"
```

**Existing Code** continues to work without changes - legacy functions preserved:

```bash
log_info "Still works"   # Calls log INFO internally
log_warn "Still works"   # Calls log WARN internally
log_error "Still works"  # Calls log ERROR internally
log_debug "Still works"  # Calls log DEBUG internally
```

**Enable deprecation warnings** (optional) to identify legacy usage:

```bash
export ORADBA_SHOW_DEPRECATION_WARNINGS=true
```

## [0.13.0] - 2026-01-02

### Added

- **RMAN Wrapper Script (#52)**: Automated RMAN execution with advanced features
  - New script: `src/bin/oradba_rman.sh` (820+ lines)
  - Template processing for dynamic RMAN scripts (`.rcv` extension)
    - `<ALLOCATE_CHANNELS>`: Automatic channel allocation based on --channels parameter
    - `<FORMAT>`: Dynamic backup format string substitution  
    - `<TAG>`: Dynamic backup tag substitution
    - `<COMPRESSION>`: Compression level (NONE|LOW|MEDIUM|HIGH)
  - Parallel execution support for multiple databases
    - Background jobs method (default)
    - GNU parallel method (auto-detected if available)
    - Configurable via `--parallel` option
  - Dual logging strategy
    - Generic wrapper log: `${ORADBA_LOG}/oradba_rman_TIMESTAMP.log`
    - SID-specific RMAN output: `${ORADBA_ORA_ADMIN_SID}/log/<script>_TIMESTAMP.log`
  - Email notifications (mail/sendmail)
    - Configurable success/error notifications
    - Per-SID notification settings
  - SID-specific configuration: `${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf`
  - Dry-run mode for template testing
  - Comprehensive command-line interface
    - Required: `--sid`, `--rcv`
    - Optional: `--channels`, `--format`, `--tag`, `--compression`, `--notify`, `--parallel`, `--dry-run`, `--verbose`
  - Example configuration: `src/etc/oradba_rman.conf.example`
  - Updated backup script: `src/rcv/backup_full.rcv` (renamed from .rman with template tags)
  - **Test Suite**: 36 comprehensive BATS tests (35 passing, 1 skipped)
    - Full coverage of argument parsing, template processing, configuration, parallel execution
  - **Documentation**: Comprehensive updates
    - Updated `src/doc/09-rman-scripts.md` with wrapper usage
    - Updated `src/rcv/README.md` with template documentation
    - Updated `src/bin/README.md` with oradba_rman.sh reference
    - Updated main `README.md` with RMAN wrapper examples

- **Base Directory Aliases**: Navigation shortcuts for OraDBA directories
  - `cdbase`: Change to `$ORADBA_BASE` directory
  - `<extension>base` aliases for each extension (via existing `cde<name>` pattern)

### Fixed

- **Extension Discovery Bug**: Fixed extension list showing empty/invalid extensions
  - Enhanced oradba directory exclusion in `discover_extensions()`
  - Now properly skips main OraDBA installation directory
  - Compares both directory name and full path to `${ORADBA_BASE}`
  - Prevents false positives when OraDBA is installed in `${ORADBA_LOCAL_BASE}`

### Changed

- **RMAN Script Extension**: Changed from `.rman` to `.rcv` for template-enabled scripts
  - `.rcv`: RMAN scripts with template tags (new standard)
  - `.rman`: Static RMAN scripts (legacy, still supported)
  - Updated all documentation to reflect new convention

## [0.12.1] - 2026-01-02

### Fixed

- **Documentation**: Fixed broken external links in extension guide (18-extensions.md) that caused
  mkdocs build failures. Changed relative paths to GitHub URLs for developer documentation and examples.
- **Extension Script**: Removed ANSI color codes from `oradba_extension.sh` usage output to match
  standard OraDBA script formatting. Colors are still used in command output.

## [0.12.0] - 2026-01-02

### Added

- **Extension System (#15)**: Modular plugin architecture for custom scripts
  - Auto-discovery of extensions in `${ORADBA_LOCAL_BASE}` (e.g., `/opt/oracle/local/customer`)
  - Support for `bin/`, `sql/`, `rcv/`, `etc/`, `lib/` directories in extensions
  - Optional `.extension` metadata file (YAML-like format with name, version, priority)
  - Priority-based loading (lower priority number = higher priority, loaded last to appear first in PATH)
  - Configuration override per extension (enable/disable, change priority)
  - Automatic PATH integration for extension bin/ directories
  - Automatic SQLPATH integration for extension sql/ directories
  - RMAN script path tracking via `ORADBA_RCV_PATHS`
  - Navigation aliases: `cde<name>` for each extension
  - New library: `src/lib/extensions.sh` with discovery, loading, and management functions
  - Comprehensive documentation: `doc/extension-system.md`
  - Example extension: `doc/examples/extensions/customer/`
  - Configuration variables: `ORADBA_AUTO_DISCOVER_EXTENSIONS`, `ORADBA_EXTENSION_PATHS`, `ORADBA_EXTENSIONS_IN_COEXIST`
  - Respects coexistence mode (extensions not loaded with BasEnv unless forced)
  - **Test Suite**: 31 comprehensive BATS tests covering all extension functionality
  - **Management Tool**: `oradba_extension.sh` command-line utility for managing extensions
    - `list` - Show all extensions with status, version, priority
    - `info` - Display detailed information about specific extension
    - `validate` - Validate extension structure and configuration
    - `validate-all` - Validate all discovered extensions
    - `discover` - Show auto-discovered extensions
    - `paths` - Display extension search paths
    - `enabled` - List only enabled extensions
    - `disabled` - List only disabled extensions

### Fixed

- **Extension Priority Sorting**: Fixed sort order to ensure high-priority extensions (lower number) appear first in PATH
  - Extensions are now loaded in reverse priority order (high priority loaded last)
  - Ensures high-priority bins override low-priority bins in PATH resolution

## [0.11.1] - 2026-01-02

### Added

- **Version Info Enhancement**: `oradba_version.sh -i` now displays coexistence mode
  - Shows `coexist_mode` (standalone or basenv)
  - Shows `basenv_detected` (yes or no)
  - Information sourced from `.install_info` file

### Fixed

- **Test Compatibility**: Updated service management tests for safe_alias pattern
  - Fixed 6 tests that were checking for old `alias name=` syntax
  - Now correctly checks for `safe_alias name` pattern
  - All tests passing with coexistence mode implementation

- **Documentation Workflow**: Added version tag trigger to docs workflow
  - Docs now deploy automatically when version tag is pushed
  - Ensures documentation updates on every release
  - No longer relies solely on release published event

## [0.11.0] - 2026-01-02

### Added

- **Coexistence Mode with TVD BasEnv/DB*Star**: Parallel installation support (fixes #19)
  - Auto-detection during installation of BasEnv/DB*Star environments
  - Checks for `.BE_HOME`, `.TVDPERL_HOME` files and `BE_HOME` variable
  - New `oradba_local.conf`: Auto-generated configuration with detected mode
  - Safe alias system: Skips OraDBA aliases when BasEnv versions exist
  - New functions in `oradba_common.sh`: `detect_basenv()`, `alias_exists()`, `safe_alias()`
  - All aliases converted to use `safe_alias()` function
  - Configuration variables: `ORADBA_COEXIST_MODE`, `ORADBA_FORCE`
  - Force mode: Set `ORADBA_FORCE=1` to override BasEnv aliases
  - Respects BasEnv priority: Never modifies PS1, BE_HOME, or BasEnv variables
  - Comprehensive documentation in installation and configuration guides
  - Updated Mermaid diagrams: Architecture, installation flow, alias generation

## [0.10.5] - 2026-01-02

### Added

- **Log Rotation User Mode**: Non-root operation support for oradba_logrotate.sh
  - New `--install-user` option: Sets up user-specific configurations
  - New `--run-user` option: Runs logrotate as non-root user
  - New `--cron` option: Generates crontab entry for automation
  - User configs stored in `~/.oradba/logrotate`
  - State files managed in `~/.oradba/logrotate/state`
  - Supports manual execution and cron-based scheduling
  - Documentation integrated into [15-log-management.md](src/doc/15-log-management.md)

- **Naming Conventions Documentation**: Comprehensive naming conventions (fixes #4)
  - Bash script patterns: `oradba_*`, `*_jobs.sh`, utility scripts
  - Configuration files: `oradba_*.conf`, `sid.*.conf`
  - Library, template, test, and build script conventions
  - References existing SQL script naming documentation

### Changed

- **SQL*Net Authentication**: Changed authentication service from NTS to BEQ
  - BEQ for native OS authentication (Unix/Linux systems)
  - NTS is Windows-specific (Native Network Services)
  - Updated templates: sqlnet.ora.basic, sqlnet.ora.secure
  - Updated documentation and tests

- **Listener Alias Renamed**: Changed `lsnrctl` alias to `listener` to avoid conflict
  - Oracle's native `lsnrctl` command no longer shadowed by alias
  - New alias: `listener` calls `oradba_lsnrctl.sh` wrapper
  - Preserved: `lsnr` and `lsnrh` still call Oracle's native `lsnrctl`
  - Clarified: `lsnrstart`, `lsnrstop`, `lsnrrestart`, `lsnrstatus` use OraDBA wrapper

### Fixed

- **Documentation Workflow**: Now triggers automatically on version tags
  - Added tag trigger for `v*.*.*` pattern
  - No longer reliant on release published event timing

- **Validation Script**: Fixed documentation path checks
  - Now correctly checks `src/doc/index.md` instead of `doc/README.md`
  - All validation tests passing

## [0.10.4] - 2026-01-02

### Fixed

- **Help Command Argument Parsing**: Fixed `oradba help <topic>` command format
  - Now properly handles both `oradba help aliases` and `oradba aliases` formats
  - Detects 'help' keyword and shifts to process actual topic
  - All 12 help system tests passing

## [0.10.3] - 2026-01-02

### Added

- **Command-Line Help System**: Quick access to all help resources (fixes #18)
  - New `oradba help` command as unified help entry point
  - Topic-based help: aliases, scripts, variables, config, sql, online
  - Shows currently set environment variables
  - Lists available scripts with descriptions from headers
  - Configuration file status with visual indicators
  - No redundant content - routes to existing help resources
  - 12 comprehensive BATS tests

- **PDF Documentation in Distribution**: User guide PDF now included in installation
  - Automatically copied to `${ORADBA_PREFIX}/doc/oradba-user-guide.pdf`
  - Offline documentation available after installation
  - Referenced in help system

### Changed

- **Release Workflow**: Reordered build process for documentation inclusion
  - Build → Generate docs → Copy PDF → Rebuild
  - Ensures PDF is included in distribution tarball

### Fixed

- **Shellcheck Lint Issues**: Resolved all shellcheck warnings in oradba_help.sh
  - Fixed SC2155: Separated declare and assign for command substitution
  - Fixed SC2034: Added shellcheck disable for unused metadata variables

## [0.10.2] - 2026-01-02

### Added

- **GitHub Pages Documentation**: Online documentation site at <https://oehrlis.github.io/oradba>
  - MkDocs with Material theme for modern, searchable documentation
  - Automatic deployment on release and documentation changes
  - Mobile-responsive design with default light mode
  - Mermaid diagram support
  - Git revision dates for each page
  - Cross-linked navigation and search
  - Architecture and flow diagrams in user documentation

- **Release Documentation**: Created `doc/releases/` directory for storing release notes
  - Enables updating GitHub releases using `gh release edit` command
  - Historical release notes preserved for v0.9.4, v0.9.5, v0.10.0, v0.10.1

### Changed

- **Validation Script**: Enhanced output format and checks
  - Regular mode: Clean, concise output without separator lines
  - Verbose mode: Detailed test results with all separators
  - Added `.install_info` and `.oradba.checksum` validation
  - File modification detection with summary count
  - Improved validation summary with modification status

- **Documentation**: Added visual diagrams throughout user guides
  - Architecture diagram in Introduction
  - Installation flow diagram
  - Environment management (oraenv.sh) flow diagram
  - Configuration hierarchy and sequence diagrams
  - Alias generation flow diagram

- **Smart Test Selection**: Improved fallback behavior for non-code changes
  - When only images, documentation, or other non-code files change, runs only
    always-run tests (3 tests) instead of full suite (492 tests)
  - More efficient for diagram updates, documentation improvements, and asset changes
  - Reduces unnecessary test execution time for non-functional changes

- **Release Workflow**: Reordered validation steps for faster failure detection
  - Now runs linting before full test suite
  - Fails fast on code quality issues (seconds vs minutes)
  - More efficient use of CI resources

### Fixed

- **Documentation Workflow**: Fixed MkDocs build process
  - Images now copied from `doc/images/` to `src/doc/images/` during build
  - Fixed broken links in documentation (LICENSE, relative paths)
  - Removed pip cache requirement that caused build failures
  - Documentation builds successfully in strict mode

## [0.10.1] - 2026-01-02

### Fixed

- **Validation Script**: Fixed `oradba_validate.sh` to properly validate current installation
  - Fixed oraenv.sh syntax check: Now uses `bash -n` instead of attempting to source with --help
  - Updated config file checks: Changed from `sid.ORACLE_SID.conf.example` to `sid.ORCL.conf.example`
  - Added service management checks: Now validates `oradba_dbctl.sh`, `oradba_lsnrctl.sh`, `oradba_services.sh`
  - Added `oradba_services.conf` configuration file check
  - Made README.md check optional (lives in project root, not src/)
  - Updated revision to 0.10.0

- **Configuration Hierarchy Diagram**: Updated diagram to reflect current configuration system
  - Updated `doc/images/source/config-hierarchy.excalidraw`
  - Updated `doc/images/config-hierarchy.png`

## [0.10.0] - 2026-01-01

### Added

- **Smart Test Selection**: Intelligent test execution based on changed files
  - Runs only tests affected by code changes instead of all 492 tests
  - Configuration-based mapping via `.testmap.yml`
  - Always-run core tests: installer, version, oraenv
  - Pattern matching for flexible test selection
  - Git-based change detection (local: `git diff origin/main`, CI: `dorny/paths-filter`)
  - Fallback to full test suite with warning if changes can't be determined
  - **Performance Improvements**:
    - Single script change: ~10 tests (1 min) vs 492 tests (8 min) - 7 min saved
    - Library change: ~50 tests (2 min) vs 492 tests (8 min) - 6 min saved
    - Documentation only: 3 tests (30 sec) vs 492 tests (8 min) - 7.5 min saved
  - **New Make Targets**:
    - `make test`: Smart selection (default, fast feedback)
    - `make test-full`: All tests (comprehensive validation)
    - `make test DRY_RUN=1`: Preview which tests would run
    - `make pre-commit`: Smart tests + linting
  - **CI/CD Integration**:
    - Regular CI uses smart selection for fast feedback (1-3 minutes)
    - Release workflow uses full test suite for quality assurance (8-10 minutes)
  - **New Files**:
    - `.testmap.yml`: Test mapping configuration
    - `scripts/select_tests.sh`: Smart test selection script
    - `doc/smart-test-selection.md`: Complete documentation

- **Mermaid Diagrams**: Created comprehensive Mermaid diagram definitions
  - `doc/images/source/diagrams-mermaid.md`: 11 Mermaid diagrams for documentation
  - **Updated Diagrams** (PNG and Excalidraw sources):
    - CI/CD Pipeline: Smart test selection vs full test suite workflows
    - Test Strategy: Architecture of smart test selection system
    - Development Workflow: Developer decision tree with test options
    - Architecture System: Complete layered system architecture
    - oraenv.sh Flow: Environment setup process
    - Configuration Hierarchy: 5-level override system
    - Configuration Sequence: Config loading sequence diagram
    - Installation Flow: Self-extracting installer process
    - Alias Generation: Dynamic alias creation with PDB support
    - Performance Comparison: Time savings visualization
    - Test Selection Decision: Simplified test selection logic
  - Text-based diagrams for version control and GitHub rendering
  - Can be imported into Excalidraw for visual editing
  - Reflects smart test selection and service management features

- **Oracle Service Management**: Complete enterprise-grade service management toolkit
  - `oradba_dbctl.sh`: Database lifecycle management (start/stop/restart/status)
    - Honors `:Y` flag in oratab for auto-start configuration
    - Configurable shutdown timeout (default 180s) with abort escalation
    - Optional PDB opening with `--open-pdbs` flag
    - Force mode for non-interactive automation
    - Justification logging for audit trails
    - Continue-on-error to process all databases
  - `oradba_lsnrctl.sh`: Listener management across Oracle homes
    - Automatic discovery of first Oracle home from oratab
    - Support for multiple listeners with explicit names
    - Status reporting for all running listeners
  - `oradba_services.sh`: Orchestrated database and listener management
    - Configurable startup/shutdown order via config file
    - Default order: start listeners→databases, stop databases→listeners
    - Support for specific databases and listeners
    - Pass-through options to underlying scripts
    - Unified status reporting
  - `oradba_services_root.sh`: Root wrapper for system integration
    - Executes services as oracle user from root context
    - Automatic --force flag for unattended operation
    - Used by systemd and init.d service templates
  - **System Integration Templates**:
    - systemd unit file (`oradba.service`) with proper dependencies and timeouts
    - init.d/chkconfig script for Red Hat and Debian systems
    - Complete installation instructions for both service managers
  - **Configuration**: `oradba_services.conf` for service orchestration
    - STARTUP_ORDER and SHUTDOWN_ORDER variables
    - SPECIFIC_DBS and SPECIFIC_LISTENERS for targeted control
    - DB_OPTIONS and LSNR_OPTIONS for pass-through parameters
  - **Convenience Aliases** (11 new aliases):
    - Database: `dbctl`, `dbstart`, `dbstop`, `dbrestart`
    - Listener: `lsnrctl`, `lsnrstart`, `lsnrstop`, `lsnrrestart`, `lsnrstatus`
    - Combined: `orastart`, `orastop`, `orarestart`, `orastatus`
  - **Comprehensive Documentation**: 17-service-management.md (657 lines)
    - Quick start guide with examples
    - Detailed usage for all components
    - systemd and init.d installation procedures
    - Logging, error handling, and security considerations
    - Troubleshooting guide and advanced usage patterns
  - **Complete Test Coverage**: 51 BATS automated tests + interactive test suite
    - Script existence, permissions, and syntax validation
    - Help output and configuration validation
    - Template structure verification
    - Alias and documentation completeness checks
    - Integration point validation

### Changed

- **CI Workflow**: Updated to use smart test selection for faster feedback
  - Fetches full git history for proper diff comparison
  - Groups output for better readability
  - Falls back to full suite if selection fails

- **Release Workflow**: Ensures comprehensive validation
  - Always runs full test suite (492 tests) before release
  - Added explicit test and lint steps
  - Guarantees 100% test coverage for releases

- **Makefile**: Enhanced with smart test selection targets
  - `test` target now uses smart selection by default
  - `test-full` for complete test runs
  - `ci` target uses full tests for comprehensive validation
  - `pre-commit` uses smart tests for quick feedback

- **Development Documentation**: Updated with smart test selection
  - Added "Available Make Targets" section
  - Expanded testing guide with smart selection examples
  - Updated GitHub Actions workflow explanations
  - Added performance comparisons and configuration examples

- **Code Quality**: Fixed all shellcheck warnings for production readiness
  - Separated variable declarations from assignments (SC2155)
  - Changed `"$@"` to `"$*"` for string concatenation (SC2124)
  - Added shellcheck directives for dynamic source and config files
  - Proper variable usage in oradba_db_functions.sh (SC2034)

### Fixed

- **Session Info Query**: Corrected `query_sessions_info()` to work in MOUNT and OPEN states
  - v$session is available in MOUNT mode, not just OPEN
  - Only skips STARTED (NOMOUNT) state as intended
  - Updated test to check for STARTED instead of MOUNTED

- **Memory Usage Query**: Corrected `query_memory_usage()` to work in MOUNT and OPEN states
  - v$sga and v$pgastat are available in MOUNT mode, not just OPEN
  - Only skips STARTED (NOMOUNT) state as intended
  - Updated test to check for STARTED instead of MOUNTED

## [0.9.5] - 2026-01-01

### Added

- **SQL Script Log Management**: Central logging for all SQL scripts with SPOOL ([#33](https://github.com/oehrlis/oradba/issues/33))
  - 53 SQL scripts now support `$ORADBA_LOG` environment variable
  - Log files include database SID and timestamp: `scriptname_sid_timestamp.log`
  - Automatic fallback to current directory if `$ORADBA_LOG` not set
  - Portable across SQL*Plus, SQL Developer, Windows, and Unix/Linux
  - Silent error handling via `WHENEVER OSERROR CONTINUE`
  - Enables centralized log management and cleanup strategies

### Changed

- **RMAN Aliases**: Refactored to avoid conflicts with Oracle's rman binary
  - Removed `rman` alias to prevent overriding Oracle's native command
  - `rmanc`: No rlwrap, uses ORADBA_RMAN_CATALOG_CONNECTION or fallback to `target /`
  - `rmanh`: Just rlwrap wrapper, no automatic connection (user connects manually)
  - `rmanch`: rlwrap with catalog connection, fallback to `target /` if not configured
  - Provides more flexibility for different connection types and workflows
- **Project Validation**: Updated validation script to reflect current project structure
  - Corrected documentation filenames and added new doc files
  - Added checks for important binaries and configuration files
  - Updated test file validation to include all current test suites

## [0.9.4] - 2026-01-01

### Fixed

- **Database Status Display**: Comprehensive improvements to dbstatus.sh for all database states
  - **Dummy Database Detection**: Check oratab `:D` flag before attempting SQL queries
    - Prevents unnecessary connection attempts to dummy SIDs
    - Shows environment info only with clear "Dummy Database" status
    - No SQL errors for intentional dummy entries
  - **NOT STARTED Detection**: Changed connection check from `dual` to `v$instance`
    - `SELECT FROM dual` can succeed even when instance is down
    - Now queries `v$instance` which requires running instance
    - Properly detects and displays "NOT STARTED" status
  - **MOUNT State Display**: Extended to show complete database information
    - Changed from `nls_database_parameters` to `v$nls_parameters` (fixed view)
    - Fixed character set query (ORA-01219: not accessible in MOUNT state)
    - Now displays: DATABASE, DATAFILE_SIZE, LOG_MODE, CHARACTERSET
    - Added USERS/SESSIONS via `v$session` (works in MOUNT)
    - Added PDB info via `v$pdbs` (works in MOUNT)
    - STATUS now shows role: "MOUNTED / PRIMARY" (matching OPEN format)
  - **Display Order**: Reorganized for consistency across all states
    - Environment (BASE, HOME, TNS_ADMIN, VERSION)
    - Database identity (DATABASE/DB_NAME/DB_UNIQUE_NAME with DBID)
    - Memory (MEMORY_SIZE with SGA/PGA)
    - Storage (FRA_SIZE, DATAFILE_SIZE)
    - Runtime (UPTIME, STATUS with role, USERS/SESSIONS)
    - Details (LOG_MODE, CHARACTERSET, PDB)
  - **Error Handling**: Improved SQL error filtering and output parsing
    - Removed `WHENEVER SQLERROR EXIT FAILURE` from query functions
    - Changed from `2>/dev/null` to `2>&1` with explicit grep filtering
    - Filters out SP2-, ORA-, ERROR lines before parsing results
    - Fixed whitespace handling in numeric results
  - MOUNT and OPEN states now have nearly identical information layout
  - NOMOUNT shows environment and instance status only
  - Dummy and NOT STARTED databases show environment with clear status

### Added

- **Common Library**: Added `is_dummy_sid()` function
  - Checks oratab for `:D` flag to identify dummy SIDs
  - Returns 0 if dummy, 1 if real or cannot determine
  - Used by dbstatus.sh to avoid SQL queries on dummy entries

## [0.9.3] - 2026-01-01

### Fixed

- **RMAN Aliases**: Fixed rmanc and rmanch to use fallback when catalog is not configured
  - When `ORADBA_RMAN_CATALOG_CONNECTION` is set: uses catalog connection
  - When not set: falls back to `rman target /` (no catalog keyword)
  - Prevents unwanted prompts for catalog connection info
  - Users can add catalog connection interactively if needed
  - All aliases (rman, rmanc, rmanh, rmanch) are always available
- **Database Functions**: Fixed error handling in database query functions
  - All query functions now properly suppress SQL*Plus errors (redirect stderr to /dev/null)
  - Added `WHENEVER SQLERROR/OSERROR EXIT FAILURE` to SQL blocks
  - Validate output data before returning (check for expected format)
  - Prevents display of error messages like "ORA-01034" in dbstatus.sh output
  - Clean output for databases that are down or in dummy environments
- **Database Status Display**: Improved dbstatus.sh output formatting and information
  - **Not Started/Dummy DBs**: Show environment info with clear status instead of errors
    - Displays ORACLE_BASE, ORACLE_HOME, TNS_ADMIN, ORACLE_VERSION
    - STATUS shows "NOT STARTED" for real databases or "Dummy Database (environment only)" for dummy SIDs
    - No more error messages for non-running databases
  - **Status Field**: Fixed duplicate status display
    - NOMOUNT: Shows "STATUS: STARTED" (single field)
    - MOUNT: Shows "STATUS: MOUNTED" (single field)
    - OPEN: Shows "STATUS: OPEN / READ WRITE" (two fields: open mode and database role)
  - **MOUNT State**: Now displays database information similar to OPEN state
    - Shows database name, DBID, datafile size, LOG_MODE, CHARACTERSET
    - Provides useful information for databases in MOUNT state
    - Skips PDB info (not queryable in MOUNT state)
- **SQL Scripts**: Fixed oh.sql to iterate through SQLPATH directories correctly
  - Previous version tried to cd to colon-separated path string
  - Now splits SQLPATH by colon and processes each directory individually
  - Adds `-u` flag to sort to avoid duplicate entries from multiple paths
  - Properly handles directories that don't exist

### Changed

- **Directory Structure**: Renamed log directory from `logs/` to `log/` for consistency
  - Updated `LOG_DIR` default from `${ORADBA_PREFIX}/logs` to `${ORADBA_PREFIX}/log`
  - Updated all references in installer, configuration, documentation, and logrotate templates
  - Updated `.gitignore` to ignore `log/` instead of `logs/`
  - Maintains consistency with singular naming convention (bin, lib, etc, sql, rcv, doc)
- **Documentation**: Reverted alias_help.txt filename to lowercase for consistency
  - Changed from `ALIAS_HELP.txt` back to `alias_help.txt`
  - All references updated (documentation, validation script, configuration)
  - Maintains consistency with other configuration files

## [0.9.2] - 2026-01-01

### Fixed

- **Installer**: Fix command substitution parsing in download completion message
  - Separated command substitution from log_info string to avoid potential quoting issues
  - Addresses "ath | cut -f1): command not found" error in certain environments
  - Uses intermediate variable for cleaner, more robust code

## [0.9.1] - 2025-12-24

### Fixed

- **Installer**: Improved error handling for missing embedded payload
  - Clear error messages with installation options when payload is absent
  - Prevents running installer from within installation directory
  - Better guidance for using `--local` or `--github` options
- **Tests**: Fixed SQL*Net permissions test for cross-platform compatibility
  - Proper OS detection for stat command (macOS vs Linux)
  - Prevents false failures in CI environment
- **Documentation**: Improved documentation structure and build process
  - Renamed `USAGE.md` to `16-usage.md` for consistency
  - Documentation structure improvements
  - Fixed image copying to exclude source files (.excalidraw)
  - Build now copies only PNG images, not README.md or source subfolder
  - Prevents additional files in installation checksum verification

## [0.9.0] - 2025-12-22

### Added

- **Log Management System**: Automated log rotation for OraDBA and Oracle Database (#9)
  - Five production-ready logrotate templates:
    - `oradba.logrotate`: OraDBA system logs (install, ops, user, backup logs)
    - `oracle-alert.logrotate`: Database alert logs with copytruncate
    - `oracle-trace.logrotate`: Diagnostic trace files cleanup with maxage
    - `oracle-audit.logrotate`: Audit logs with compliance considerations
    - `oracle-listener.logrotate`: Listener logs and traces
  - `oradba_logrotate.sh` v0.9.0: Full-featured management script
    - Install/uninstall logrotate configurations (requires root)
    - Test configurations with dry-run mode (`--test`)
    - Force rotation for testing (`--force`)
    - Generate customized configs (`--customize`) with auto-detection
    - List installed configurations (`--list`)
    - Template-specific operations with `--template` option
  - Compliance support for industry standards:
    - PCI-DSS: 1 year audit retention
    - HIPAA: 6 years healthcare data retention
    - SOX: 7 years financial records
    - GDPR: Configurable data retention
  - Safe defaults:
    - copytruncate for active logs (alert, listener)
    - maxage for trace file cleanup
    - Delayed compression to prevent corruption
    - Permission preservation and error handling
  - Environment-specific customization:
    - Auto-detects ORACLE_BASE from oratab
    - Per-SID configuration generation
    - Replaces wildcards with actual paths
    - Ready-to-deploy configurations

- **Documentation**: Complete log management guide
  - Chapter 15: Log Management and Rotation (src/doc/15-log-management.md)
  - Template reference with features and use cases
  - Compliance requirements matrix
  - Customization guide for different environments
  - Integration with monitoring systems
  - Troubleshooting guide for common issues
  - Security considerations and best practices
  - Template documentation in src/templates/logrotate/README.md

- **SQL*Net Configuration Management**: Comprehensive centralized configuration system (#10)
  - `oradba_sqlnet.sh` v0.2.0: Full-featured SQL*Net management tool
  - Centralized TNS_ADMIN structure under `$ORACLE_BASE/network/{sid}/`
  - Automatic migration from ORACLE_HOME to centralized location
  - Symlink creation for Oracle Home compatibility
  - Read-only Oracle Home support (Oracle 18c+) using `orabasehome` detection
  - Batch processing for all databases in `/etc/oratab`
  - Automatic path updates for log and trace directories
  - New CLI options: `--setup [SID]` and `--setup-all`
  - Configuration templates: basic, secure, tnsnames examples, LDAP/OID
  - Template features: AES256 encryption, TCPS, RAC, PDB, failover, load balancing
  - Backup, validation, and connection testing capabilities

- **Test Coverage**: 51 comprehensive BATS tests for SQL*Net management
  - Template installation and validation
  - Centralized TNS_ADMIN setup (single and batch)
  - File migration and symlink creation
  - Read-only home detection (Oracle 18c+ orabasehome command)
  - Path updates in sqlnet.ora
  - Error handling for missing variables
  - All tests pass, full shellcheck compliance

- **Documentation**: Complete user guide for SQL*Net management
  - Chapter 14: SQL*Net Configuration (src/doc/14-sqlnet-config.md)
  - Quick start guide with common scenarios
  - Detailed explanation of Oracle read-only homes
  - Centralized structure benefits and architecture
  - Template descriptions with security best practices
  - High availability configurations (failover, RAC, load balancing)
  - Troubleshooting guide and compliance standards

### Fixed

- **SQL*Net Script**: Corrected read-only Oracle Home detection logic
  - Changed from physical permission check to logical Oracle method
  - Now uses `orabasehome` command (Oracle 18c+ feature)
  - Properly detects: output ≠ ORACLE_HOME → read-only, output = ORACLE_HOME → read-write
  - Handles older Oracle versions without orabasehome gracefully
  - Fixed function output to use stderr for messages, stdout for return values

- **Test Framework**: Fixed test environment configuration
  - Made oratab path configurable via `ORATAB` environment variable
  - Corrected ORACLE_HOME propagation in test cases
  - Fixed backup file pattern validation
  - All 51 SQL*Net tests now pass consistently

## [0.8.3] - 2025-12-19

### Fixed

- **Release Workflow**: Removed unstable CI status verification that caused release failures
  - Simplified release process to just build and publish when tag is pushed
  - Removed fragile CI status check that relied on commit timing
  - Makes release workflow more stable and predictable
  - Quality control now relies on manual verification or branch protection rules

- **PDF Documentation**: Fixed LaTeX hyperreference warnings during PDF generation
  - Corrected internal cross-reference anchors to match actual heading IDs
  - Links between documentation sections now resolve properly in PDF
  - Eliminates ~30 "Hyper reference not found" warnings during build

### Changed

- **Documentation**: Updated release process documentation
  - Clarified that developers are responsible for verifying CI before tagging
  - Updated workflow steps to reflect simplified release process
  - Added best practices for ensuring quality before releases
  - Updated troubleshooting section to reflect new workflow behavior

## [0.8.2] - 2025-12-19

### Added

- **Long Operations Monitoring**: New comprehensive monitoring tools for database operations
  - `longops.sh`: Generic monitoring script for v$session_longops with watch mode
  - `rman_jobs.sh`: Wrapper for RMAN backup/restore operation monitoring
  - `exp_jobs.sh`: Wrapper for DataPump export job monitoring
  - `imp_jobs.sh`: Wrapper for DataPump import job monitoring
  - Supports continuous watch mode with configurable intervals
  - Operation pattern filtering for targeted monitoring

- **Utility Scripts**: Enhanced system administration tools
  - `get_seps_pwd.sh`: Extract passwords from Oracle Wallet using mkstore
  - `sync_from_peers.sh`: Synchronize files from remote peer to local and other peers
  - `sync_to_peers.sh`: Distribute files from local host to peer hosts
  - Support for dry-run mode, verbose output, and configuration files

- **Test Coverage**: Comprehensive BATS test suites for new scripts
  - `test_longops.bats`: 26 tests for long operations monitoring
  - `test_get_seps_pwd.bats`: 32 tests for wallet password utility
  - `test_sync_scripts.bats`: 56 tests for sync utilities
  - `test_job_wrappers.bats`: 39 tests for job monitoring wrappers
  - Total: 153 new tests (390 total tests project-wide)
  - Tests skip Oracle-dependent features for CI compatibility

### Changed

- **Script Modernization**: Refactored utility scripts to match project standards
  - Updated to modern bash practices (`#!/usr/bin/env bash`, `set -o pipefail`)
  - Converted function names from PascalCase to snake_case
  - Improved modular structure with parse_args(), validate(), and main() functions
  - Enhanced error handling with proper return codes
  - Better variable quoting and validation throughout
  - Scripts: `get_seps_pwd.sh`, `sync_from_peers.sh`, `sync_to_peers.sh`

- **Code Quality**: All new and refactored scripts pass shellcheck linting
  - Added appropriate shellcheck disable directives where needed
  - Fixed SC2034, SC2155, SC2206, and SC1090 warnings
  - Improved SCRIPT_NAME and SCRIPT_DIR declarations

## [0.8.1] - 2025-12-19

### Fixed

- **Installer Configuration Backup**: Fixed backup functionality during updates
  - Corrected checksum file parsing to handle two-space delimiter format
  - Added regex validation for checksum line format (64-char hex hash)
  - Fixed arithmetic expansion compatibility with `set -e` mode
  - Backup now correctly identifies and preserves modified configuration files

- **SQL Script oh.sql**: Fixed multi-line HOST command syntax error
  - Collapsed bash command to single line (SQL*Plus HOST doesn't support backslash continuations)
  - Resolved SP2-0734 and SP2-0042 errors
  - Script now works correctly when filtering help output

- **SQL Script aud_config_show_aud.sql**: Restored proper content and formatting
  - Fixed SET command spacing and SQL formatting
  - Restored column definitions that were previously removed

### Improved

- **SQL Script Headers**: Completed Phase 3 standardization (100 additional files)
  - Updated Date field to 2025.12.19 for all remaining SQL scripts
  - Set Revision to 0.8.0 across all updated files
  - Added Reference field where missing
  - Total: 127 SQL files now have consistent, standardized headers
  - Categories covered: audit (aud_*), TDE (tde_*), security (sec_*), utilities, password verification

- **CI/CD Pipeline**: Enhanced release workflow with comprehensive status checks
  - Added CI status validation before creating releases
  - Improved error messages and run query limits
  - Validates specific commits for tag pushes

## [0.8.0] - 2025-12-19

### Added

- **Configuration Backup on Update**: Installer now backs up modified configuration files
  - Similar to RPM behavior: creates `.save` copies of modified files before overwriting
  - Automatically detects modifications using checksum comparison
  - Only backs up configuration files in `etc/` and files with `.conf` or `.example` extensions
  - Preserves file permissions when creating backups
  - Clear logging shows which files were backed up and where
  - User modifications are never lost during updates

- **SQL Scripts Help** (Issue #1): New consolidated help script
  - Created `oh.sql` (OraDBA Help) - unified help system for SQL scripts
  - Extracts script names and purposes from file headers dynamically
  - Works from any directory using $SQLPATH
  - Supports optional filtering: `@oh`, `@oh aud`, `@oh tde`
  - Replaced old `help.sql` and `help_topics.sql` with better implementation
  - Shows sorted list with actual Purpose field from headers

### Fixed

- **Database Status Display**: Clean output when database is unavailable
  - Shows only environment variables (ORACLE_BASE, ORACLE_HOME, TNS_ADMIN, VERSION)
  - Distinguishes between dummy SIDs and stopped databases
  - Eliminates mangled SQL error messages in status output
  - Proper detection of dummy SIDs using ORADBA_SIDLIST and ORADBA_REALSIDLIST

### Improved

- **Alias Documentation**: Enhanced ALIAS_HELP.txt for better organization
  - Reorganized sections: separated RMAN, database operations, listener operations
  - Added missing aliases: `sessionsql`, `sqa`, `cdc`, `cdr`, `cdtmp`, `vii`, `vildap`
  - Fixed documentation reference from ALIASES.md to 06-aliases.md
  - Clearer section grouping and descriptions

- **Installation Checks**: Added crontab to optional tools verification
  - Warns if crontab is not available (needed for save_cron alias)
  - Non-blocking check, installation continues if missing

- **SQL Scripts Documentation** (Issue #1)
  - Simplified src/sql/README.md to avoid redundancy with 08-sql-scripts.md
  - Removed duplicate tables and lengthy descriptions
  - Added clear references to comprehensive documentation
  - Documented naming convention with examples
  - Kept only essential quick reference information
  - Comprehensive header analysis completed (127 SQL files reviewed)
  - Identified 125 files needing header updates for future cleanup
  - Added notes about legacy scripts migration path

- **SQL Script Headers Standardization** (Issue #1 - Phase 1 & 2)
  - **Phase 1**: Updated 8 critical files with missing/incorrect headers
    - Fixed: help.sql, help_topics.sql (now removed, replaced by oh.sql)
    - Fixed: init.sql (added third-party attribution for Tanel Poder)
    - Fixed: rowid.sql, create_password_hash.sql, verify_password_hash.sql
    - Fixed: aud_config_show_aud.sql (restored proper audit trail content)
  - **Phase 2**: Updated 12 alias files with standardized headers
    - Updated minimal alias files: who.sql, audit.sql, apol.sql, logins.sql, afails.sql, tde.sql, tdeops.sql
    - Updated existing alias files: whoami.sql, hip.sql
    - Updated target files: ssa_hip.sql, sdsec_sysobj.sql, spsec_usrinf.sql
  - All updated files now have Date: 2025.12.19 and Revision: 0.8.0
  - Consistent OraDBA header format across all modified files

## [0.7.16] - 2025-12-19

### Changed

- **Template Renamed**: `sid.ORCL.conf.example` → `sid.ORACLE_SID.conf.example`
  - More generic name that doesn't imply "ORCL" is special
  - Clearer that it's a template for any SID
  - All references updated in code, docs, and tests

- **SID Config Simplification**: Only track static database metadata
  - Removed dynamic fields: `ORADBA_DB_ROLE` and `ORADBA_DB_OPEN_MODE`
  - These should be queried at runtime, not stored in config
  - Keeps config files clean and eliminates stale data
  - Template now documents this design decision

### Fixed

- **Auto-Create Robustness**: Template must exist for auto-creation
  - Added explicit check and error message if template missing
  - Prevents silent failures during SID config creation
  - Clearer error messages to stderr

### Removed

- Removed ~170 lines of dead fallback code for database metadata querying
- Simplified `create_sid_config()` function significantly
- Template-based approach is now the only method

## [0.7.15] - 2025-12-18

### Fixed

- **Auto-Create Debugging**: Enhanced error messaging and debugging output
  - Messages now written to stderr to bypass output redirections
  - Added explicit warnings when config file creation fails
  - Better visibility of ORADBA_AUTO_CREATE_SID_CONFIG setting
  - Helps diagnose why SID configs aren't being created

### Improved

- Error messages more visible even in silent mode
- Better debugging for auto-create troubleshooting

## [0.7.14] - 2025-12-18

### Fixed

- **Auto-Create SID Config**: Fixed SID config auto-creation not working when sourcing database environment
  - Config is now properly sourced after creation in `load_config()`
  - Removed duplicate source calls within `create_sid_config()`
  - Added clear user feedback with [INFO] messages
  - Respects `ORADBA_AUTO_CREATE_SID_CONFIG=false` setting

### Changed

- **Test Cleanup**: Removed test-generated SID config files from repository
  - Deleted `sid.FREE.conf`, `sid.CDB1.conf`, `sid.TESTDB.conf`
  - Added test SID configs to `.gitignore`
  - Prevents test artifacts from being committed or included in releases

### Improved

- Enhanced user messaging when SID config is auto-created
- Shows [OK] checkmark on successful creation
- More consistent log messages and error handling

## [0.7.13] - 2025-12-18

### Fixed

- **Install Version Tracking**: Fixed issue where `.install_info` showed incorrect version after GitHub/local updates
  - Installer now reads VERSION file from extracted tarball and updates `INSTALLER_VERSION` variable
  - Ensures correct version is written to `.install_info` metadata during installation
  - Affects `--github` and `--local` installation modes

### Technical Details

- `src/bin/oradba_install.sh`: Added version detection after tarball extraction
- Reads `VERSION` file from temp directory before copying to installation directory
- Updates internal `INSTALLER_VERSION` variable for accurate metadata recording

## [0.7.12] - 2025-12-18

### Fixed

- **oradba_version.sh**: Additional files now always displayed
  - Previously only shown when integrity check passed
  - Now shown regardless of integrity check result
  - Helps identify custom files even when tracked files are modified

### Changed

- **File naming**: Renamed ALIAS_HELP.txt to alias_help.txt for consistency
  - Updated all references in configs and documentation
  - Updated alih alias definition
  - Updated validation script
  - Follows lowercase convention for consistency

## [0.7.11] - 2025-12-18

### Fixed

- **Auto-create SID Config**: Fixed syntax error in writability check
  - Removed escaped quotes that prevented the check from working
  - Function was failing silently due to bash syntax error
  - Now correctly validates directory permissions before file creation
  - Added visible echo messages when config is created (not just log_info)
  - Users now see "[INFO] Creating SID-specific configuration for \<SID>..." message
  - Shows success message: "[INFO] Created SID configuration from template: \<path>"

## [0.7.10] - 2025-12-18

### Fixed

- **oradba_version.sh**: Fixed file count display in integrity verification
  - Now correctly counts and displays number of verified files
  - Added detection of additional files in managed directories (bin, doc, etc, lib, rcv, sql, templates)
  - Warns users about custom files before updates to help with backups
  - Excludes logs directory from additional file detection

- **Auto-create SID config**: Improved error handling and logging
  - Added check for writable config directory before attempting to create file
  - Enhanced logging to show when auto-creation is attempted
  - Added success/failure messages for better debugging
  - Clearer error messages when permissions are insufficient

## [0.7.9] - 2025-12-18

### Changed

- **Build System**: Unified tarball creation process
  - `build_installer.sh` now creates single distribution tarball in `dist/` directory
  - Same tarball used for both GitHub releases and installer payload
  - Tarball includes `.oradba.checksum` file for integrity verification
  - Eliminates duplicate tarball creation in Makefile
  - Fixes checksum verification during `--update --github` installations

### Fixed

- **Installer**: Installation integrity verification now works correctly
  - Distribution tarball includes `.oradba.checksum` file
  - GitHub release tarball matches installer payload exactly
  - Resolves "Installation integrity verification FAILED" errors

## [0.7.8] - 2025-12-18

### Fixed

- **Build System**: Fixed tarball structure to have flat file layout instead of nested directory
  - Removed `--transform` flag from tar command that was adding directory prefix
  - Tarball now contains `src/`, `scripts/`, etc. at root level as installer expects
  - Fixes extraction issue where files were nested in `oradba-VERSION/` subdirectory
  - Enables `--update --github` to correctly detect and install new version

## [0.7.7] - 2025-12-18

### Fixed

- **CI/CD Workflow**:
  - Fixed release workflow to use `make build` instead of manual tar creation
  - Tarball now correctly named `oradba-VERSION.tar.gz` instead of `oradba-VERSION-src.tar.gz`
  - Ensures uploaded tarball has version substitution in installer
  - `--update --github` now works correctly with CI/CD generated releases

## [0.7.6] - 2025-12-18

### Fixed

- **Build System**:
  - Fixed tarball creation to substitute `__VERSION__` with actual version in `oradba_install.sh`
  - Fixed `build_installer.sh` to substitute version in embedded payload
  - Ensures installed `oradba_install.sh` has correct `INSTALLER_VERSION` instead of placeholder
  
- **Installer**:
  - Fixed version detection during `--update` mode to read VERSION from extracted tarball
  - Fixed final installation message to display actual installed version from VERSION file
  - Proper version comparison now works for `--github` and `--local` updates

## [0.7.5] - 2025-12-18

### Added

- **Linting Improvements** (#29):
  - Enhanced Makefile lint-shell target to cover tests, BATS files, and configuration files
  - Comprehensive shellcheck coverage across the entire codebase

### Fixed

- **Code Quality** (#29):
  - Fixed shellcheck warnings across all shell scripts, tests, and configuration files
  - Added proper shellcheck disable directives with explanations where necessary
  - Fixed quote issues in alias definitions (rmanc, rmanch)
  - Improved regex patterns in BATS tests (removed unnecessary quotes)
  - Fixed variable scoping and command substitution patterns
  - Added shebang lines to example configuration files
  - Corrected PS1BASH variable expansion handling

## [0.7.4] - 2025-12-18

### Fixed (Post-Release)

- **Naming Conflict**: Removed `/usr/local/bin/oraenv` symlink creation to avoid conflict with Oracle's
  own `oraenv` utility. Users should always use `oraenv.sh` explicitly or create their own aliases.
- **GitHub Installer**: Fixed download URL to fetch version-specific tarball (oradba-VERSION.tar.gz)
  instead of non-existent oradba.tar.gz. Installer now queries GitHub API for latest version.
- **Documentation**: Updated all references to emphasize using `oraenv.sh` (not `oraenv`) throughout
  documentation and examples to avoid confusion with Oracle's utility.

## [0.7.4] - 2025-12-18 (Original Release)

### Added

- **Documentation Improvements** (#27):
  - 9 professional diagrams (PNG format) for architecture, workflows, and processes
  - Modern responsive CSS template for HTML documentation
  - Left-floating table of contents (240px width) with fixed positioning
  - Images now included in distribution package (src/doc/images/)
  - Diagram source files (Excalidraw format) for easy maintenance
  - Images: system architecture, config hierarchy, oraenv flow, installation process, config sequence, alias
    generation, CI/CD pipeline, dev workflow, test strategy
  - Images source in doc/images/ with Excalidraw sources in doc/images/source/
  - Images copied to src/doc/images/ during build

### Changed

- **Documentation Build Process** (#27):
  - Implemented temp directory approach for markdown processing
  - Fixed cross-chapter links: converted .md references to # anchors for single-page HTML
  - Images copied from doc/images/ to src/doc/images/ during build for PDF/HTML generation
  - Moved metadata.yml from src/doc/ to doc/ (separate from user documentation)
  - Updated pandoc flags: replaced deprecated --self-contained with --embed-resources
  - Enhanced Makefile with docs-prepare and docs-clean-images targets
  - Updated .gitignore to exclude src/doc/images/ (build-time only)

### Fixed

- **Documentation** (#27):
  - CSS layout: TOC no longer overlaps content
  - Image embedding: diagrams now appear in generated HTML/PDF
  - Internal links: chapter cross-references work in single-page HTML
  - Responsive design: proper layout on mobile, tablet, and desktop screens
  - Makefile lint-markdown: now matches CI workflow pattern

## [0.7.3] - 2025-12-17

### Added

- **Shell Profile Integration** (#24):
  - Automatic Oracle environment loading on shell startup
  - Installer flags: `--update-profile` and `--no-update-profile`
  - Supports bash_profile, profile, and zshrc (login shell profiles only)
  - Silent environment sourcing for non-interactive shells
  - Displays Oracle environment status (oraup.sh) on login for interactive shells
  - Duplicate detection prevents multiple integrations
  - Automatic profile backup before modification
  - 19 new tests for profile integration (63 total installer tests)
  - Uses first SID from oratab automatically
  - Smart TTY detection: prompts in interactive mode, defaults to no in automation

### Fixed

- Profile detection now only uses login shell profiles for compatibility
  - Priority: `.bash_profile` → `.profile` → `.zshrc`
  - Creates `.bash_profile` if none exist
  - `.bashrc` excluded as it's only for non-login shells and should be sourced by `.bash_profile`
  - Ensures environment loads correctly on SSH sessions and terminal login shells
- Profile integration now correctly calls `oraup.sh` instead of `oraup` command

## [0.7.2] - 2025-12-17

### Added

- **SID Config Template Auto-Creation**:
  - Enhanced `create_sid_config()` to use `sid.ORCL.conf.example` as a template for new SID configs
  - Uses `sed` to replace `ORCL`/`orcl` with the actual SID
  - Updates date stamps and auto-created comment in new config
  - Adds comprehensive BATS tests for template-based SID config creation (`test_sid_config.bats`)
  - 16 new tests covering template usage, SID replacements, and edge cases
  - Ensures robust, consistent SID config generation and test coverage

### Fixed

- **Code Quality**:
  - Resolved all shellcheck warnings (SC2155, SC2046, SC2034)
  - Separated variable declarations from assignments to avoid masking return values
  - Fixed markdown linting issues in documentation
  - Total: 108 tests passing across 9 test suites

## [0.7.1] - 2025-12-17

### Added

- **System Prerequisites Check Script** (#22):
  - New `oradba_check.sh` script for validating system readiness
  - Checks required tools (bash, tar, awk, sed, grep, find, sort, sha256sum)
  - Validates optional tools (rlwrap, less, curl, wget)
  - Disk space verification (100MB minimum)
  - Oracle environment detection (ORACLE_HOME, ORACLE_BASE, ORACLE_SID, TNS_ADMIN)
  - Oracle tools validation (sqlplus, rman, lsnrctl, tnsping)
  - Database connectivity testing (when environment is set)
  - OS and Oracle version information display
  - OraDBA installation verification
  - Color-coded output with symbols ([OK] [X] ⚠ ℹ)
  - Options: `--dir`, `--quiet`, `--verbose`, `--help`, `--version`
  - Exit codes: 0 (passed), 1 (failed), 2 (invalid usage)
  - Comprehensive test suite: 24 tests (all passing)
  - Addresses most prerequisites validation requirements from issue #22

### Changed

- **Integrity Check Output Improvement**:
  - Improved `oradba_version.sh --verify` output format for failed integrity checks
  - Clean, one-line-per-file format showing status (MISSING or MODIFIED)
  - Added summary section with counts of modified and missing files
  - Filtered out verbose sha256sum warnings for better readability
  - Example output:

    ```text
    Modified or missing files:
      etc/oratab.example: MISSING
      etc/sid.ORCL.conf.example: MODIFIED
    
    Summary:
      Modified files: 1
      Missing files:  1
      Total issues:   2
    ```

- **Documentation Updates**:
  - Updated QUICKSTART.md with system prerequisites check section
  - Added troubleshooting section using oradba_check.sh
  - Enhanced installation workflow with pre-installation validation

## [0.7.0] - 2025-12-17

### Added

- **Version Management Infrastructure** (#6):
  - Added comprehensive version management functions to `oradba_common.sh`
  - New functions: `get_oradba_version()`, `version_compare()`, `version_meets_requirement()`
  - Installation metadata management: `get_install_info()`, `set_install_info()`, `init_install_info()`
  - Display function: `show_version_info()` for version and installation details
  - Uses existing `.install_info` format: `install_date`, `install_version`, `install_method`, `install_user`, `install_prefix`
  - Build script generates `.install_info` template for installer to populate
  - Comprehensive test suite: `tests/test_version.sh` with 11 test cases
  - Foundation for version-aware installation and update capabilities

- **Installation Enhancements** (#6, partially addresses #22):
  - **Multiple Installation Modes**:
    - Embedded mode (default): Self-contained installer with base64 payload
    - Local mode (`--local`): Install from tarball for air-gapped environments
    - GitHub mode (`--github`): Download and install from GitHub releases
  - **Pre-flight Checks**:
    - Required tools validation (bash, tar, sha256sum, base64, etc.)
    - Optional tools detection with warnings (curl, wget, git)
    - Disk space verification (minimum 100MB required)
    - Installation directory permissions checking
    - Comprehensive pre-installation validation
  - **Post-install Verification**:
    - Automatic SHA256 checksum validation after installation
    - Integrated `oradba_version.sh --verify` into installer
    - Verifies all installed files match expected checksums
    - Excludes `.install_info` from validation (modified during install)
    - Fails installation if integrity check detects corruption
    - Detailed error reporting showing which files failed
  - **Installer Architecture Refactoring**:
    - Extracted installer logic to dedicated `src/bin/oradba_install.sh`
    - Installer now part of distribution (installed to `$PREFIX/bin/`)
    - Simplified build script from 844 to ~130 lines
    - Installed script can be used for --local, --github, --update without payload
    - Enables post-installation operations using same installer
    - Build process: read installer → inject version → append payload
    - Better separation of concerns and maintainability
  - **Update Capabilities** (#6):
    - Added `--update` flag for upgrading existing installations
    - Semantic version comparison (detects upgrades, same version, downgrades)
    - Automatic backup before update with rollback on failure
    - Configuration file preservation (.install_info, oradba.conf, etc.)
    - `--force` flag to reinstall same version or downgrade
    - Update from any source: embedded, --local, or --github
    - Automatic backup cleanup on successful update
    - Rollback capability if integrity verification fails
    - Preserves user customizations during updates

### Fixed

- **Installer code quality**: Resolved shellcheck warnings
  - SC2155: Separated variable declaration from assignment for `parent_dir` and `backup_dir`
  - SC2034: Removed unused `INSTALL_EXAMPLES` variable and `--no-examples` flag
  - Improved shell script best practices and maintainability

## [0.6.1] - 2025-12-17

### Fixed

- **sqh alias**: Fixed to connect as sysdba instead of using /nolog
  - Users were not automatically connected when running sqh
  - Changed from `sqlplus /nolog` to `sqlplus / as sysdba`
  - Now behaves consistently with sq alias

- **oraup.sh**: Improved output sorting and organization
  - Dummy entries now displayed first (alphabetically sorted)
  - DB instances displayed second (alphabetically sorted)
  - Better readability and consistent ordering

- **oraup.sh**: Fixed database status detection for Oracle 23ai new process naming
  - Oracle 23ai uses db_pmon_SID (uppercase) instead of ora_pmon_sid (lowercase)
  - Updated get_db_status to check both naming conventions with grep -E
  - Now supports: db_pmon_FREE (23ai+) and ora_pmon_free (pre-23ai)
  - Fixed duplicate startup flag display (was showing N|N, now shows N)

## [0.6.0] - 2025-12-17

### Fixed

- **oraup.sh**: Improved database status detection
  - Changed query from v$database.open_mode to v$instance.status for better state detection
  - Now correctly shows: open, mounted, started, nomount status
  - Falls back to v$database.open_mode if v$instance query fails
  - Fixed listener detection to only show running listeners (not down listeners)
  - Removed display of non-existent listeners from hostname

- **Alert log aliases**: Point to regular alert log instead of XML format
  - Changed `taa`, `via`, and `vaa` to use `alert_SID.log` instead of `log.xml`
  - Added `ORADBA_SID_ALERTLOG` variable pointing to the standard text alert log
  - Aliases check if file exists before attempting to open it
  - Added `-n 50` to `taa` to show last 50 lines by default
  - Both static (oradba_standard.conf) and dynamic (oradba_aliases.sh) aliases updated
  
- **Alert log aliases**: Added fallback aliases for `taa`, `via`, and `vaa`
  - Fixed issue where aliases were not created if diagnostic directories didn't exist yet
  - Added static aliases based on ORACLE_BASE and ORACLE_SID in oradba_standard.conf
  - Dynamic aliases from oradba_aliases.sh will still override these if diagnostic_dest exists
  - Also includes fallback aliases for `cdd`, `cddt`, `cdda` directory navigation

### Added

- **u alias**: Short alias for oraup.sh for quick Oracle environment overview
- **sessionsql dynamic linesize**: SQL*Plus session configurator with automatic terminal width detection
  - Detects terminal dimensions using `tput cols` and `tput lines`
  - Automatically sets LINESIZE based on terminal width
  - Automatically sets PAGESIZE based on terminal height
  - Wrapper script: `sessionsql.sh` for easy terminal-aware SQL*Plus sessions
  - SQL script: `sessionsql.sql` for manual configuration
  - Alias: `sessionsql` for quick access
  - Falls back to sensible defaults (120 columns, 50 lines) if detection fails

- **RMAN catalog support**: Automatic RMAN recovery catalog connection management
  - New `ORADBA_RMAN_CATALOG` configuration variable
  - `load_rman_catalog_connection()` function validates and loads catalog connection
  - `rmanc` and `rmanch` aliases automatically use configured catalog
  - Supports formats: `user/password@tnsalias` or `user@tnsalias` (prompts for password)
  - Can be configured globally in oradba_core.conf or per-SID in
    sid.SID.conf
  - Falls back to interactive catalog prompt if not configured
  - Added catalog configuration examples to SID templates

- **ADRCI rlwrap wrapper**: Command history support for ADRCI
  - New `adrcih` alias provides rlwrap support for ADRCI
  - Enables command history, line editing, and recall in ADRCI sessions
  - Supports password filtering when `ORADBA_RLWRAP_FILTER=true`
  - Falls back to standard adrci if rlwrap unavailable

- **oraup utility**: Comprehensive Oracle environment overview
  - New `oraup.sh` script and `oraup` alias
  - Shows all Oracle databases from oratab with status and open mode
  - Displays listener status for all Oracle homes
  - Shows startup flags (Y/N/D) and dummy entries
  - Provides system-wide Oracle process overview
  - Formatted table output similar to database status displays

- **rlwrap completion files**: Tab completion support for Oracle tools
  - New completion files: `rlwrap_sqlplus_completions`, `rlwrap_rman_completions`,
    `rlwrap_lsnrctl_completions`, `rlwrap_adrci_completions`
  - 650+ keywords covering commands, parameters, and common patterns
  - Integrated with rlwrap for enhanced command-line experience
  - Automatic tab completion in interactive sessions (sqh, rmanh, lsnrh, adrcih)
  - SQL*Plus: SQL commands, SET/SHOW parameters, system views, privileges
  - RMAN: Backup/restore commands, keywords, connection types
  - lsnrctl: Listener commands, SET/SHOW parameters, trace levels
  - ADRCI: Diagnostic commands, show/set/ips operations, product types

## [0.5.1] - 2025-12-16

### Added

- **PDB alias support** (ORADBA_NO_PDB_ALIASES toggle):
  - Automatic PDB discovery in CDB environments
  - Generates lowercase aliases for each PDB (e.g., `pdb1` for PDB1)
  - Generates prefixed aliases (e.g., `pdbpdb1`)
  - Sets ORADBA_PDB variable for prompt integration
  - Exports ORADBA_PDBLIST with all available PDBs
  - Configurable via ORADBA_NO_PDB_ALIASES=true to disable
  - Documentation in doc/PDB_ALIASES.md
  - Integration with PS1 prompt ([SID.PDB] format)
- **rlwrap password filter support** (ORADBA_RLWRAP_FILTER):
  - Perl-based filter to hide passwords from command history
  - Detects common Oracle password prompts (SQL*Plus, RMAN)
  - Masks CONNECT commands with embedded passwords
  - Masks CREATE/ALTER USER IDENTIFIED BY statements
  - Configurable via ORADBA_RLWRAP_FILTER=true (default: false)
  - Documentation in doc/RLWRAP_FILTER.md
  - Affects: sqh, sqlplush, sqoh, rmanh, rmanch aliases
- **Requirements check in installer**:
  - Validates bash installation before proceeding
  - Checks for rlwrap with installation instructions if missing
  - Verifies basic utilities (tar, base64, awk, sed, grep)
  - Provides OS-specific installation commands

### Fixed

- **Bug #28**: oradba_validate.sh validation issues
  - Fixed color codes not displaying (changed from heredoc to echo -e)
  - Fixed README.md path (now ${ORADBA_BASE}/../README.md)
  - Changed CONFIGURATION.md to optional (doesn't exist yet)
  - Changed ALIAS_HELP.txt to required (used by alih alias)
- **Shellcheck warnings**:
  - Fixed SC2034 in oradba_common.sh: Marked unused oracle_home variable with underscore
  - Fixed SC2139 in oradba_common.sh: Added disable comment for intentional alias expansion
  - Fixed SC2034 in oradba_validate.sh: Removed unused BLUE color variable

## [0.5.0] - 2025-12-16

### Added

- **Issue #5**: Hierarchical configuration system with override capability
  - `oradba_core.conf`: Core system settings (paths, installation, behavior)
  - `oradba_standard.conf`: Standard environment variables and aliases (50+ aliases)
  - `oradba_customer.conf`: Customer-specific configuration overrides (optional)
  - `sid._DEFAULT_.conf`: Default SID-specific settings template
  - `sid.<ORACLE_SID>.conf`: Auto-created SID-specific configurations with database metadata
  - Configuration loading order: core → standard → customer → default → sid-specific
  - Auto-export all variables using `set -a`/`set +a` wrapper (export keyword optional)
  - `load_config()` function in oradba_common.sh for configuration management
  - `create_sid_config()` function for auto-creating SID configs from database metadata
  - Smart config generation: only writes non-default and valid values
  - Example configuration files: `sid.ORCL.conf.example`, `oradba_customer.conf.example`

- **Issue #8**: Comprehensive shell alias system (~50 aliases)
  - **SQL*Plus**: sq, sqh, sqlplush, sqoh (with rlwrap fallback)
  - **RMAN**: rman, rmanc, rmanh, rmanch (with rlwrap support)
  - **Directory navigation**: cdh, cdn, cdob, cdbn, cdt, cdb, cde, cdr, cdlog, cdtmp, cdl, etc, log
  - **SID-specific**: cda, cdc, cdd, cddt, cdda (dynamic based on ORACLE_SID)
  - **VI editors**: vio, vit, vil, visql, vildap, vis, vic, vii, via
  - **Alert log**: taa, vaa, via (tail/view/edit alert log)
  - **Listener**: lstat, lstart, lstop, lsnr
  - **Database ops**: pmon, oratab, tns, sta
  - **Help**: alih, alig, version
  - Dynamic alias generation in `lib/oradba_aliases.sh` based on diagnostic_dest
  - rlwrap integration for SQL*Plus/RMAN with graceful fallback
  - SID aliases: Auto-generate lowercase aliases for all SIDs in oratab (e.g., `alias free='. oraenv.sh FREE'`)

- **SID lists and variables**:
  - `ORADBA_SIDLIST`: Space-separated list of all SIDs from oratab (Y/N/D flags)
  - `ORADBA_REALSIDLIST`: Space-separated list of real SIDs (Y/N only, excludes D for DGMGRL dummy)
  - `generate_sid_lists()`: Parses oratab and creates SID-specific aliases dynamically
  - Auto-aliases regenerated on every environment source

- **Convenience variables** (short paths):
  - `$cdh`: ORACLE_HOME path
  - `$cda`: Admin directory (ORACLE_BASE/admin/SID)
  - `$cdob`: ORACLE_BASE path
  - `$cdl`: ORACLE_BASE/local path
  - `$cdd`: Diagnostic destination path
  - `$etc`: OraDBA etc directory
  - `$log`: OraDBA log directory
  - `$cdn`: TNS_ADMIN parent directory

- **Enhanced error handling**:
  - Comprehensive SET commands in all SQL queries to isolate from user login.sql/glogin.sql
  - Multi-layer error filtering: grep -v for ERROR, ORA-, SP2-, Help:, Usage:, etc.
  - Query validation: checks for pipe separator, minimum length, no error strings
  - Default values used when database not accessible
  - `ORADBA_ORA_ADMIN_SID` and `ORADBA_ORA_DIAG_SID` calculated dynamically from current ORACLE_BASE/ORACLE_SID

- **Validation and help**:
  - `oradba_validate.sh`: Post-installation validation script with color-coded output
    - Checks directory structure, scripts, libraries, configs, docs, SQL files
    - Optional Oracle environment checks (ORACLE_HOME, sqlplus, oratab)
    - Exit codes: 0=success, 1=failures found
  - `ALIAS_HELP.txt`: Quick reference help file with ASCII art banner
  - `alih` alias displays quick help with categorized alias listing

- **Improved dbstatus.sh output**:
  - Compact format: Oracle environment shown first (ORACLE_BASE → ORACLE_HOME → TNS_ADMIN → VERSION)
  - Smart database identity: Single line if DB_NAME == DB_UNIQUE_NAME, two lines for standby/RAC
  - Combined status: "STATUS: OPEN / OPEN" instead of separate lines
  - Supports all database states: STARTED, MOUNTED, OPEN
  - Graceful handling of dummy/unavailable databases: Shows simple environment status only
  
- **PS1/PS1BASH prompt customization**:
  - Automatically includes ORACLE_SID in bash prompt: `user@host:path/ [SID]`
  - PDB support: Shows `[SID.PDB]` when ORADBA_PDB variable is set
  - Two formats: PS1BASH (bash escapes \u, \h, \w) and PS1 (environment variables)
  - Controlled by ORADBA_CUSTOMIZE_PS1 toggle (enabled by default)
  
- **PATH handling documentation**:
  - Documented that PATH modifications in config files are auto-exported via set -a
  - Added examples in oradba_customer.conf.example
  - Referenced Issue #24 for future .bash_profile integration

- Comprehensive documentation:
  - `doc/ALIASES.md`: Complete alias reference (50+ aliases), rlwrap integration, troubleshooting
  - `doc/CONFIGURATION.md`: Hierarchical config system guide, customization examples, variable reference
  - `doc/ALIAS_HELP.txt`: Quick reference with ASCII art banner

### Changed

- Renamed `oradba.conf` to `oradba_core.conf` (focused on core system settings only)
- `oraenv.sh` now uses hierarchical configuration via `load_config()`
- Configuration reloaded on each environment switch (allows SID-specific customization)
- Alias names updated for consistency:
  - `cdoh` → `cdh` (ORACLE_HOME)
  - `cdnw` → `cdn` (TNS_ADMIN parent)
  - `sqlp` → `sqoh` (sysoper with rlwrap)
  - `cdda` → `cdd` (diagnostic_dest)
  - `cdta` → `cddt` (trace directory)
  - `cdaa` → `cdda` (alert directory)
  - Removed: `sqls` (redundant with sq)
- Updated file headers to v0.5.0: oraenv.sh, oradba_common.sh, oradba_core.conf, oradba_standard.conf
- Build process now auto-cleans test SID configs before packaging

### Fixed

- **Critical**: Error messages no longer pollute variables (ORADBA_ORA_DIAG_SID, ORADBA_DIAGNOSTIC_DEST)
  - Added `2>&1` redirection before heredoc in all sqlplus queries
  - Enhanced grep filters to remove all error patterns
  - Changed WHENEVER SQLERROR from EXIT FAILURE to EXIT SQL.SQLCODE
- **Critical**: Variables now exported even without 'export' keyword (set -a/set +a wrapper)
- **Critical**: All database queries isolated from user login.sql/glogin.sql settings
  - 7-line SET command block in every sqlplus invocation
  - SET TIMING OFF, TIME OFF, SQLPROMPT "", etc.
- rlwrap aliases now use hardcoded 'rlwrap' command instead of ${RLWRAP_COMMAND} variable
- login.sql cleaned: removed PROMPT statements, disabled TIMING
- `alih` alias fixed: uses external ALIAS_HELP.txt file instead of heredoc
- ORADBA_ORA_ADMIN_SID and ORADBA_ORA_DIAG_SID now calculated dynamically from current ORACLE_BASE/ORACLE_SID
  - No longer stored in sid.*.conf files (prevents stale paths from test environments)
- SID config generation improved: Only writes non-default and valid values
  - Skips PRIMARY database role (default)
  - Skips READ WRITE open mode (default)
  - Validates all queried values before writing
- Makefile: Added clean-test-configs target, integrated into build process

### Migration Notes

- If upgrading from v0.4.0, rename your customized `oradba.conf` to `oradba_customer.conf`
- Move any SID-specific settings to `sid.<ORACLE_SID>.conf`
- Review new `oradba_core.conf` for system settings
- Update any custom scripts using old alias names (cdoh→cdh, cdnw→cdn, etc.)
- Run `oradba_validate.sh` after installation to verify setup

## [0.4.0] - 2025-12-16

### Added

- **Issue #7**: Checksum verification and version checking utility
  - `oradba_version.sh` utility for version management and integrity verification
  - Automatic checksum generation during build (`.oradba.checksum` with SHA256)
  - `--check` / `-c`: Show current installed version
  - `--verify` / `-v`: Verify installation integrity against checksums
  - `--update-check` / `-u`: Check for available updates from GitHub
  - `--info` / `-i`: Show comprehensive installation information
  - Installation metadata file (`.install_info`) with timestamp and details
  - Checksums for all distributed files (bin, lib, sql, rcv, etc, templates)
- **Issue #3**: README.md files added to all major directories for inline documentation
  - build/ - Build artifacts and output directory
  - doc/templates/ - File header templates
  - scripts/ - Build and validation scripts
  - src/etc/ - Configuration files
  - src/lib/ - Shell libraries
  - src/rcv/ - RMAN scripts
  - src/templates/ - Script templates
  - tests/ - Test suite
- All READMEs reference central documentation to minimize redundancy
- Comprehensive BATS test suite for `oradba_version.sh`

### Changed

- update issue template for tasks
- Build process now generates checksums for all installed files
- Installer creates `.install_info` metadata with installation details

## [0.3.3] - 2025-12-16

### Added

- **Issue #23**: Intelligent installer prefix detection with automatic ORACLE_BASE discovery
  - Priority 1: Uses `${ORACLE_BASE}/local/oradba` if ORACLE_BASE is set
  - Priority 2: Derives from ORACLE_HOME by checking orabasetab and envVars.properties
  - Priority 3: Derives from first SID in oratab using same logic
  - Priority 4: Falls back to `${HOME}/local/oradba`
- Automatic base directory creation when it doesn't exist
- Case-insensitive ORACLE_SID lookup (accepts 'free', 'Free', or 'FREE')

### Changed

- Generated installer now includes standard OraDBA header with version information
- ORACLE_SID now preserves uppercase from oratab regardless of user input case
- Improved installer error messages with helpful suggestions

### Fixed

- Installer no longer requires root privileges in most Oracle environments
- Installation fails gracefully with clear messages when permissions are insufficient

## [0.3.2] - 2025-12-16

### Fixed

- **Bug #25**: Fixed PDB display to show correct open modes (RW, RO, MO, MI) instead of truncated text
- **Bug #25**: Fixed PDB query to include PDB$SEED in output
- **Bug #25**: Fixed memory query SQL echo issue - now displays clean numeric values instead of SQL text
- Fixed subshell variable scope issue causing `--silent` flag to fail completely
- Fixed date command compatibility for uptime calculation (macOS and Linux)
- Fixed default installation prefix to `${ORACLE_BASE}/local/oradba` (no longer requires root)
- Added shellcheck disable comments for intentionally global variables

### Changed

- Removed redundant [INFO] log message on environment setup
- Removed duplicate "Oracle Environment" display section
- Simplified output to show only database status in interactive mode
- Added ORACLE_BASE and TNS_ADMIN to database status output
- Removed verbose PATH display from status output

## [0.3.1] - 2025-12-16

### Fixed

- Fixed argument parsing in oraenv.sh where `--silent` and `--status` flags were not working correctly
- Fixed syntax error in oraenv.sh from incomplete code replacement
- Corrected display modes: `--silent` now produces no output, `--status` shows only database status

### Changed

- Changed all example SIDs from ORCL to FREE throughout documentation and tests
- Examples now align with Oracle Database Free Edition default SID for easier getting started

### Added

- Added bash syntax validation test (`bash -n`) to catch syntax errors early
- Added 8 new integration tests that actually execute oraenv.sh (previously only grep-based tests)
- Integration tests verify ORACLE_SID, ORACLE_HOME, PATH updates, and flag behavior
- Test count increased from 55 to 63 tests

## [0.3.0] - 2025-12-16

### Added

- New `src/lib/oradba_db_functions.sh` library with reusable database query functions
- Enhanced database status display showing detailed information based on database state
- Support for querying database info at NOMOUNT, MOUNT, and OPEN states
- Added `--status` flag to oraenv.sh for detailed database status display
- Added `--silent` flag to oraenv.sh for non-interactive execution
- Interactive SID selection with numbered list when no SID provided to oraenv.sh
- User can select database by number or name from available instances
- Comprehensive test suite for oradba_db_functions.sh library (test_oradba_db_functions.bats)
- Extended test coverage for oraenv.sh with new behavior patterns
- Automatic TTY detection for interactive vs non-interactive mode
- Silent mode auto-selection when running without TTY (e.g., in scripts)
- New `dbstatus.sh` standalone script for displaying database status information
- Comprehensive documentation for oradba_db_functions.sh library (DB_FUNCTIONS.md)
- Updated USAGE.md with documentation for enhanced oraenv.sh features and dbstatus.sh

### Changed

- Renamed `srv/` directory to `src/` throughout the entire project for better clarity
- Updated all documentation, configuration files, and scripts to reference `src/` instead of `srv/`
- Refactored installer build process to package `src/` contents directly without directory wrapper
- Installation now places files directly in `$INSTALL_PREFIX/` (e.g., `bin/`, `lib/`, `etc/`)
- Fixed cross-platform base64 encoding/decoding using `openssl base64` for compatibility
- Updated runtime paths in oraenv.sh to reference installed directory structure
- Updated configuration file paths (SQLPATH, ORACLE_PATH, RECOVERY_DIR) to remove `/src/` wrapper
- Enhanced oraenv.sh prompt to display available databases before asking for selection
- Refactored SQL script naming concept to use SQL-style operation verbs (CREATE, DROP,
  UPDATE, ENABLE, DISABLE, GRANT) instead of Linux-style commands
- Added privilege indicators to script naming and documentation (User, DBA, SYSDBA, AUD)
- Reorganized SQL scripts into clear categories (Security, Audit, Encryption, Admin, Monitor)
- Updated all script tables with privilege requirements for better security awareness
- Enhanced Quick Reference Card with privilege level indicators
- Added comprehensive naming guidelines and best practices for SQL/database operations
- Introduced short aliases (2-7 chars) for commonly used scripts
- Integrated `build_installer.sh` into `make build` target to automatically generate installer
- Self-contained installer script with embedded base64-encoded payload
- Cross-platform installer supporting both macOS and Linux

### Fixed

- Fixed installer script base64 encoding/decoding for macOS and Linux compatibility
- Fixed sed commands for cross-platform compatibility in build script
- Corrected tarball creation to avoid nested directory structure in installation
- Fixed oraenv.sh to correctly locate common library and configuration files at runtime
- Fixed script template to use correct library paths after installation
- Fixed oradba.conf default paths for SQL and recovery directories

## [0.2.3] - 2025-12-15

### Added

- Add SQL scripts to show session information
- Add log folder for future use

### Changed

- Enhanced README.md with comprehensive feature descriptions and configuration details
- Updated README.md version number to 0.2.3

### Removed

- Removed obsolete files: doc/header (empty), scripts/init_git.sh, doc/REORGANIZATION.md
- Removed build artifact: build/oradba-0.1.0.tar.gz

## [0.2.2] - 2025-12-15

### Added

- Markdownlint integration for Markdown file validation (lint-markdown target)
- Organized help output with grouped sections (Development, Build & Distribution,
  Documentation, Version & Git, CI/CD & Release, Tools & Info, Quick Shortcuts)

### Changed

- Updated Makefile help to show targets organized by category
- Removed 2>/dev/null from the lint-markdown command so errors are now visible
- Update Makefile Development Workflow documentation in doc/DEVELOPMENT.md

### Fixed

- Makefile color output and command execution (fixed missing @echo statements)
- Shellcheck SC2155 warnings by separating declaration and assignment (oraenv.sh, oradba_common.sh)
- Shellcheck SC2034 warning for unused force_mode variable (marked for future use)

## [0.2.1] - 2025-12-15

### Added

- Comprehensive Makefile for development workflow automation
  - Testing targets: test, test-unit, test-integration
  - Linting targets: lint, lint-shell, lint-scripts
  - Formatting targets: format, format-check
  - Build targets: build, install, uninstall, clean
  - Version management: version-bump-patch/minor/major, tag
  - CI/CD targets: ci, pre-commit, pre-push
  - Release targets: release-check, release-prepare
  - Quick shortcuts: t (test), l (lint), f (format), b (build), c (check)
  - Color-coded help system with target descriptions

### Changed

- Converted GitHub issue templates from Markdown to YAML forms for better UX

### Fixed

- Release workflow now includes scripts/ directory in source archive

## [0.2.0] - 2025-12-15

### Added

- Comprehensive GitHub issue templates (bug report, feature request, task)
- Developer documentation in `doc/` directory (ARCHITECTURE.md, API.md, STRUCTURE.md)
- User documentation in `src/doc/` directory (USAGE.md, TROUBLESHOOTING.md)
- Markdownlint configuration files (.markdownlint.json, .markdownlint.yaml)
- Markdown linting documentation (MARKDOWN_LINTING.md)
- Project reorganization documentation (REORGANIZATION.md)
- Standardized header templates for all file types (bash, SQL, RMAN, config)
- Markdownlint step in CI/CD pipeline

### Changed

- **BREAKING**: Reorganized project structure with clean root directory
- Moved build scripts to `scripts/` directory
- Moved tests to `tests/` directory (from `test/`)
- Moved documentation to `doc/` directory (from `docs/`)
- Applied standardized OraDBA headers to all scripts and files
- Updated all bash scripts with proper OraDBA header format
- Updated all SQL scripts with proper OraDBA header format
- Updated all RMAN scripts with proper OraDBA header format
- Updated all BATS test files with proper OraDBA header format
- Updated CI/CD workflows to reference new directory structure
- Updated all documentation path references
- Enhanced validate_project.sh to check new structure

### Fixed

- Path references in README.md for new directory structure
- Path references in CONTRIBUTING.md for build and test commands
- CI workflow references to test and build directories
- Release workflow references to build script location
- Markdownlint errors in all *.md files

## [0.1.0] - 2025-12-15

### Added

- Initial release with core oradba functionality
- Core oraenv.sh script for Oracle environment setup based on oratab
- Common library (oradba_common.sh) with logging and utility functions
- Self-contained installer with base64-encoded payload
- Build script for creating installer (build_installer.sh)
- Project validation script (validate_project.sh)
- Git initialization helper (init_git.sh)
- BATS test framework integration with comprehensive test suite
- Test runner script (run_tests.sh)
- Unit tests for common library functions
- Integration tests for oraenv.sh
- Installer validation tests
- GitHub Actions CI/CD workflows for testing, building, and releasing
- Shellcheck linting in CI pipeline
- Semantic versioning support with VERSION file
- SQL scripts for database operations (db_info.sql, login.sql)
- RMAN backup script template (backup_full.rman)
- Script templates for creating new scripts
- Configuration system with system and user-level configs
- Example configuration files (oratab.example, oradba_config.example)
- Comprehensive documentation (README.md, CONTRIBUTING.md, LICENSE)
- Project summary documentation (PROJECT_SUMMARY.md)
- Quick start guide (QUICKSTART.md)
- Developer guide (DEVELOPMENT.md)
- Apache License 2.0
