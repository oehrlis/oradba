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
  - Interactive SID selection
- **Administration Scripts**: Collection of bash, SQL, and RMAN scripts for daily operations
- **Configuration System**: Global and user-specific configuration files
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
source oraenv.sh ORCL

# The script will:
# - Read oratab configuration
# - Set ORACLE_SID, ORACLE_HOME, ORACLE_BASE
# - Update PATH and LD_LIBRARY_PATH
# - Configure TNS_ADMIN and NLS settings
```

### Configuration

**Global Configuration**: `/opt/oradba/src/etc/oradba.conf`

- Installation paths and directories
- oratab file locations
- Debug and logging settings
- Backup directories

**User Configuration**: `~/.oradba_config`

- User-specific overrides
- Custom paths and preferences

**Example oratab**: `/opt/oradba/src/etc/oratab.example`

```text
# ORACLE_SID:ORACLE_HOME:AUTO_START
ORCL:/u01/app/oracle/product/19c/dbhome_1:N
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
