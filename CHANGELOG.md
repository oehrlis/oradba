# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Converted GitHub issue templates from Markdown to YAML forms for better UX

### Fixed

- Release workflow now includes scripts/ directory in source archive

## [0.2.0] - 2025-12-15

### Added

- Comprehensive GitHub issue templates (bug report, feature request, task)
- Developer documentation in `doc/` directory (ARCHITECTURE.md, API.md, STRUCTURE.md)
- User documentation in `srv/doc/` directory (USAGE.md, TROUBLESHOOTING.md)
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
