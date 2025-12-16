# oradba - Oracle Database Administration Toolset

[![CI](https://github.com/oehrlis/oradba/actions/workflows/ci.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/ci.yml)
[![Release](https://github.com/oehrlis/oradba/actions/workflows/release.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/oehrlis/oradba)](https://github.com/oehrlis/oradba/releases)

A comprehensive toolset for Oracle Database administration and operations, designed for lab and engineering environments.

## Features

### Core Capabilities

- **oraenv.sh**: Intelligent Oracle environment setup based on oratab
  - Automatic ORACLE_HOME, ORACLE_SID, and ORACLE_BASE configuration
  - Support for multiple Oracle versions and instances
  - Interactive SID selection with numbered options
  - Case-insensitive SID matching
  - Auto-generated SID aliases (e.g., `free` to source environment)
- **Hierarchical Configuration System** (5 levels with override):
  - `oradba_core.conf`: Core system settings
  - `oradba_standard.conf`: Standard aliases and variables (50+ aliases)
  - `oradba_customer.conf`: Customer overrides (optional)
  - `sid._DEFAULT_.conf`: Default SID template
  - `sid.<SID>.conf`: Auto-created per-SID configs with database metadata
- **Comprehensive Alias System** (~50 aliases):
  - SQL*Plus, RMAN, directory navigation, VI editors, alert log access
  - `sessionsql` - SQL*Plus with automatic terminal width detection
  - `rmanc`, `rmanch` - RMAN with automatic catalog connection
  - SID lists: `ORADBA_SIDLIST`, `ORADBA_REALSIDLIST`
  - PDB aliases: Auto-generated for CDB environments (configurable with ORADBA_NO_PDB_ALIASES)
  - rlwrap integration with graceful fallback
  - Optional password filtering for command history (requires Perl RlwrapFilter)
  - Dynamic aliases based on diagnostic_dest
- **dbstatus.sh**: Compact database status display
  - Instance, database, memory, storage information
  - Works in NOMOUNT, MOUNT, and OPEN states
  - PDB information for multitenant databases
- **oradba_version.sh**: Version management and integrity verification
  - Check installed version and available updates
  - Verify installation integrity with SHA256 checksums
  - Detect modified or corrupted files
  - Query GitHub releases for updates
- **oradba_validate.sh**: Post-installation validation
  - Checks directory structure, scripts, configs, documentation
  - Optional Oracle environment validation
  - Color-coded output with pass/fail/warning counts
- **Administration Scripts**: Collection of bash, SQL, and RMAN scripts for daily operations
- **SQL Scripts**: Ready-to-use SQL scripts for database information and management
- **RMAN Templates**: Backup and recovery script templates

### Development & Quality

- **Self-Contained Installer**: Single executable with base64-encoded payload, no external dependencies
- **Comprehensive Testing**: BATS-based test suite with unit and integration tests
- **CI/CD Pipeline**: GitHub Actions workflows with automated testing and releases
- **Code Quality**: Shellcheck linting, shfmt formatting, markdownlint validation
- **Development Tools**: Makefile with 50+ targets for streamlined development

## Project Structure

```text
oradba/
├── src/
│   ├── bin/         # Executable scripts
│   ├── lib/         # Library files and functions
│   ├── etc/         # Configuration files
│   ├── sql/         # SQL scripts
│   ├── rcv/         # RMAN recovery scripts
│   └── templates/   # Template files
├── tests/           # BATS test files
├── scripts/         # Build and utility scripts
├── doc/             # Developer documentation
└── .github/         # GitHub workflows
```

## Installation

Download and run the installer:

```bash
curl -o oradba_install.sh https://raw.githubusercontent.com/oehrlis/oradba/main/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh
```

Or with options:

```bash
./oradba_install.sh --prefix /opt/oradba --version 0.1.0
```

## Usage

### Setting Oracle Environment

```bash
# Set Oracle environment for specific SID
source oraenv.sh FREE

# Use SID aliases (auto-generated from oratab)
free       # Short for: source oraenv.sh FREE
cdb1       # Short for: source oraenv.sh CDB1

# Interactive selection
source oraenv.sh

# The script will:
# - Load hierarchical configuration (5 levels)
# - Set ORACLE_SID, ORACLE_HOME, ORACLE_BASE
# - Update PATH and LD_LIBRARY_PATH
# - Configure TNS_ADMIN and NLS settings
# - Generate 50+ aliases for administration
# - Create SID-specific convenience variables
```

### Using Aliases

```bash
# After sourcing oraenv.sh, you have 50+ aliases:

# SQL*Plus
sq         # sqlplus / as sysdba
sqh        # sqlplus with rlwrap (history/editing)
sqoh       # sqlplus / as sysoper with rlwrap

# Directory navigation
cdh        # cd $ORACLE_HOME
cda        # cd $ORACLE_BASE/admin/$ORACLE_SID
cdd        # cd diagnostic_dest
etc        # cd OraDBA etc directory
log        # cd OraDBA log directory

# Alert log
taa        # tail -f alert log
vaa        # view alert log with less
via        # edit alert log with vi

# Quick help
alih       # Show all aliases with descriptions
alig       # List current aliases
```

### Database Status

```bash
# Show comprehensive database status
dbstatus.sh

# Example output:
# -------------------------------------------------------------------------------
# ORACLE_BASE    : /opt/oracle
# ORACLE_HOME    : /opt/oracle/product/26ai/dbhomeFree
# -------------------------------------------------------------------------------
# DATABASE       : FREE (Instance: FREE, DBID: 1489657696)
# STATUS         : OPEN / OPEN
# MEMORY_SIZE    : 1.49G SGA / .36G PGA
# ...
```

### Version Management and Integrity

```bash
# Check installed version
oradba_version.sh --check

# Verify installation integrity
oradba_version.sh --verify

# Check for updates
oradba_version.sh --update-check

# Show detailed information
oradba_version.sh --info
```

### Post-Installation Validation

```bash
# Validate installation
oradba_validate.sh

# Verbose output
oradba_validate.sh --verbose
```

### Configuration

**Hierarchical Configuration** (5 levels, later overrides earlier):

1. `oradba_core.conf`: Core system settings (paths, installation)
2. `oradba_standard.conf`: Standard aliases and variables
3. `oradba_customer.conf`: Customer-specific overrides (optional)
4. `sid._DEFAULT_.conf`: Default SID template
5. `sid.<SID>.conf`: Auto-created per-SID configs with database metadata

**Key Variables**:

- `ORADBA_SIDLIST`: All SIDs from oratab
- `ORADBA_REALSIDLIST`: Real SIDs (excludes DGMGRL dummy entries)
- `ORADBA_ORA_ADMIN_SID`: Admin directory for current SID
- `ORADBA_ORA_DIAG_SID`: Diagnostic destination for current SID

**User Configuration**: `~/.oradba_config`

- User-specific overrides
- Custom paths and preferences

**Example oratab**: `/opt/oradba/src/etc/oratab.example`

```text
# ORACLE_SID:ORACLE_HOME:AUTO_START
FREE:/u01/app/oracle/product/19c/dbhome_1:N
TEST:/u01/app/oracle/product/21c/dbhome_1:Y
```

## Development

### Prerequisites

- Bash 4.0+
- BATS for testing
- Oracle Database (for testing database-specific scripts)
- Development tools: shellcheck, shfmt (optional, for linting/formatting)

### Development Workflow

The project includes a comprehensive `Makefile` for development tasks:

```bash
# Show all available targets
make help

# Run all tests
make test

# Lint shell scripts
make lint

# Format shell scripts
make format

# Run all checks (test + lint)
make check

# Build installer
make build

# Clean build artifacts
make clean
```

**Quick shortcuts:**

- `make t` - Run tests
- `make l` - Lint code
- `make f` - Format code
- `make b` - Build installer
- `make c` - Run all checks

### Version Management

```bash
# Bump patch version (0.2.0 -> 0.2.1)
make version-bump-patch

# Bump minor version (0.2.0 -> 0.3.0)
make version-bump-minor

# Bump major version (0.2.0 -> 1.0.0)
make version-bump-major

# Create git tag
make tag
```

### Running Tests

```bash
# Using Makefile (recommended)
make test

# Or directly
./tests/run_tests.sh
```

### Building the Installer

```bash
# Using Makefile (recommended)
make build

# Or directly
./scripts/build_installer.sh
```

## Versioning

This project uses [Semantic Versioning](https://semver.org/).

Current version: **0.2.3**

## License

Copyright (c) 2025 Stefan Oehrli

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
