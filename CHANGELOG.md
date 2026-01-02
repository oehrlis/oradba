# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.0] - 2026-01-02

### Added

- **Coexistence Mode with TVD BasEnv/DB*Star**: Parallel installation support (fixes #19)
  - Auto-detection during installation of BasEnv/DB*Star environments
  - Checks for `.BE_HOME`, `.TVDPERL_HOME` files and `BE_HOME` variable
  - New `oradba_local.conf`: Auto-generated configuration with detected mode
  - Safe alias system: Skips OraDBA aliases when BasEnv versions exist
  - New functions in `common.sh`: `detect_basenv()`, `alias_exists()`, `safe_alias()`
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
  - Proper variable usage in db_functions.sh (SC2034)

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
- Shows ✓ checkmark on successful creation
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
  - Color-coded output with symbols (✓ ✗ ⚠ ℹ)
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
  - Added comprehensive version management functions to `common.sh`
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
  - Both static (oradba_standard.conf) and dynamic (aliases.sh) aliases updated
  
- **Alert log aliases**: Added fallback aliases for `taa`, `via`, and `vaa`
  - Fixed issue where aliases were not created if diagnostic directories didn't exist yet
  - Added static aliases based on ORACLE_BASE and ORACLE_SID in oradba_standard.conf
  - Dynamic aliases from aliases.sh will still override these if diagnostic_dest exists
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
  - Fixed SC2034 in common.sh: Marked unused oracle_home variable with underscore
  - Fixed SC2139 in common.sh: Added disable comment for intentional alias expansion
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
  - `load_config()` function in common.sh for configuration management
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
  - Dynamic alias generation in `lib/aliases.sh` based on diagnostic_dest
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
- Updated file headers to v0.5.0: oraenv.sh, common.sh, oradba_core.conf, oradba_standard.conf
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

- New `src/lib/db_functions.sh` library with reusable database query functions
- Enhanced database status display showing detailed information based on database state
- Support for querying database info at NOMOUNT, MOUNT, and OPEN states
- Added `--status` flag to oraenv.sh for detailed database status display
- Added `--silent` flag to oraenv.sh for non-interactive execution
- Interactive SID selection with numbered list when no SID provided to oraenv.sh
- User can select database by number or name from available instances
- Comprehensive test suite for db_functions.sh library (test_db_functions.bats)
- Extended test coverage for oraenv.sh with new behavior patterns
- Automatic TTY detection for interactive vs non-interactive mode
- Silent mode auto-selection when running without TTY (e.g., in scripts)
- New `dbstatus.sh` standalone script for displaying database status information
- Comprehensive documentation for db_functions.sh library (DB_FUNCTIONS.md)
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
- Shellcheck SC2155 warnings by separating declaration and assignment (oraenv.sh, common.sh)
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
- Common library (common.sh) with logging and utility functions
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
