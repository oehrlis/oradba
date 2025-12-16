# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
