# oradba - Oracle Database Administration Toolset

[![CI](https://github.com/oehrlis/oradba/actions/workflows/ci.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/ci.yml)
[![Release](https://github.com/oehrlis/oradba/actions/workflows/release.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/oehrlis/oradba)](https://github.com/oehrlis/oradba/releases)

A comprehensive toolset for Oracle Database administration and operations, designed for lab and engineering environments.

## Features

- **Intelligent Environment Setup**: Automatic Oracle environment configuration based on oratab
- **Hierarchical Configuration**: 5-level configuration system with flexible overrides
- **Extension System**: Modular plugin architecture for custom scripts and tools
- **Service Management**: Enterprise-grade database and listener lifecycle control with systemd/init.d integration
- **50+ Shell Aliases**: SQL*Plus, RMAN, navigation, diagnostics, and service management
- **RMAN Wrapper**: Automated backup execution with parallel processing, template substitution, and notifications
- **Long Operations Monitoring**: Real-time tracking of RMAN, DataPump, and other operations
- **Database Status Display**: Compact, comprehensive database information for all states (OPEN/MOUNT/NOMOUNT)
- **Peer Synchronization**: Distribute files across database peer hosts
- **Wallet Utilities**: Extract passwords from Oracle Wallet
- **Version Management**: Version checking, integrity verification, and update detection
- **SQL & RMAN Scripts**: Ready-to-use administration scripts with central logging
- **Self-Contained Installer**: Single executable, no external dependencies
- **Comprehensive Testing**: BATS test suite with 490+ tests and CI/CD integration

## Quick Start

### Installation

Download and run the self-contained installer:

```bash
# Install latest version (auto-detects ORACLE_BASE)
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh

# Or specify custom installation directory
./oradba_install.sh --prefix /opt/oradba
```

### Basic Usage

Set your Oracle environment for a specific database:

```bash
# Source environment for specific SID (use oraenv.sh to avoid conflict with Oracle's oraenv)
source /opt/oradba/bin/oraenv.sh FREE

# Or create an alias in your profile for easier access
alias oraenv='source /opt/oradba/bin/oraenv.sh'
source oraenv.sh FREE

# Or use auto-generated aliases
free              # Shortcut for: source /opt/oradba/bin/oraenv.sh FREE

# Interactive selection (displays numbered SID list)
source oraenv.sh
```

After sourcing, you have 50+ aliases available:

```bash
sq                # sqlplus / as sysdba
cdh               # cd $ORACLE_HOME
taa               # tail -f alert.log
alih              # Show all aliases with descriptions
orastart          # Start all Oracle services (listeners + databases)
dbstatus.sh       # Comprehensive database information
```

Manage Oracle services:

```bash
# Start/stop individual databases
dbstart           # Start databases (honors :Y flag in oratab)
dbstop            # Stop databases
dbctl status      # Show database status

# Manage listeners
lsnrstart         # Start listener
lsnrstop          # Stop listener

# Combined service management
orastart          # Start all services (listeners then databases)
orastop           # Stop all services (databases then listeners)
orastatus         # Show status of all services
```

View database status and monitor operations:

```bash
dbstatus.sh       # Comprehensive database information
rman_jobs.sh -w   # Monitor RMAN operations in watch mode
exp_jobs.sh       # Monitor DataPump export jobs
```

Execute RMAN backups with the wrapper:

```bash
# Single database backup
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 2

# Custom settings with notification
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --channels 4 --compression HIGH --notify dba@example.com
```

Extend OraDBA with custom scripts:

```bash
# Create extension directory
mkdir -p /opt/oracle/local/customer/bin
cp my_script.sh /opt/oracle/local/customer/bin/
chmod +x /opt/oracle/local/customer/bin/my_script.sh

# Next time you source oraenv, extension is auto-loaded
source oraenv.sh FREE
my_script.sh      # Now available in PATH

# Manage extensions
oradba_extension.sh list      # Show all extensions
oradba_extension.sh info customer  # Detailed info
```

See [Extension System Guide](doc/extension-system.md) for complete documentation.

## Documentation

### 📘 User Documentation

Complete user guides available in multiple formats:

- **[User Guide (PDF)](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** -
  Download complete guide
- **[User Guide (HTML)](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)** -
  Single-page HTML
- **[Online Documentation](src/doc/README.md)** - Browse chapters individually

**User Guide Contents:**

- Introduction and features
- Installation and quickstart
- Environment management
- Configuration system
- Shell aliases reference
- PDB alias management
- SQL and RMAN scripts
- Service management (databases and listeners)
- rlwrap integration
- Troubleshooting guide
- Complete reference

### 🛠️ Developer Documentation

For contributors and developers:

- **[Developer Hub](doc/README.md)** - Developer resources index
- **[Development Guide](doc/development.md)** - Workflow and standards
- **[Architecture](doc/architecture.md)** - System design
- **[API Reference](doc/api.md)** - Function and script APIs
- **[Project Structure](doc/structure.md)** - Directory organization
- **[Version Management](doc/version-management.md)** - Release process
- **[Markdown Linting](doc/markdown-linting.md)** - Documentation standards

### Additional Resources

- **[CHANGELOG.md](CHANGELOG.md)** - Release history and changes
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[LICENSE](LICENSE)** - Apache License 2.0

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick User Guide

```bash
# Install OraDBA (one-liner)
curl -L https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh | bash

# Or download first, then install
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh

# Set Oracle environment for a database
source oraenv.sh FREE           # Source for specific SID
free                            # Or use auto-generated alias

# Common aliases (50+ available)
sq                              # sqlplus / as sysdba
cdh                             # cd $ORACLE_HOME
taa                             # tail -f alert.log
alih                            # Show all aliases

# View database status
dbstatus.sh
```

See the **[User Guide (PDF)](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** or
**[online documentation](src/doc/README.md)** for complete features and usage.

### Quick Development Commands

```bash
make help         # Show all available targets
make test         # Run test suite
make build        # Build installer
make check        # Run all quality checks
```

See [doc/DEVELOPMENT.md](doc/DEVELOPMENT.md) for complete development guide.

## Project Structure

```text
oradba/
├── src/            # Source files (installed to target system)
│   ├── bin/        # Executable scripts
│   ├── lib/        # Library functions
│   ├── etc/        # Configuration files
│   ├── sql/        # SQL scripts
│   ├── rcv/        # RMAN scripts
│   ├── doc/        # User documentation
│   └── templates/  # Script templates
├── doc/            # Developer documentation
├── tests/          # BATS test suite
├── scripts/        # Build and utility scripts
└── .github/        # CI/CD workflows
```

## Versioning

This project follows [Semantic Versioning](https://semver.org/).

## License

Copyright © 2025 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Links

- **Repository**: <https://github.com/oehrlis/oradba>
- **Issues**: <https://github.com/oehrlis/oradba/issues>
- **Releases**: <https://github.com/oehrlis/oradba/releases>
- **Discussions**: <https://github.com/oehrlis/oradba/discussions>
