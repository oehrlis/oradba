# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

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
    ```
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
