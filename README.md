# oradba - Oracle Database Administration Toolset

[![CI](https://github.com/oehrlis/oradba/actions/workflows/ci.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/ci.yml)
[![Release](https://github.com/oehrlis/oradba/actions/workflows/release.yml/badge.svg)](https://github.com/oehrlis/oradba/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/oehrlis/oradba)](https://github.com/oehrlis/oradba/releases)

A comprehensive toolset for Oracle Database administration and operations,
designed for lab and engineering environments such as Oracle AI Database Free
Docker containers, Oracle databases in VM environments, and OCI-based lab infrastructures.

## Features

### v0.19.0+ Registry API and Plugin System

- **Registry API** (v0.19.0+): Unified interface for Oracle installation metadata
  - Single API for oratab and oradba_homes.conf access
  - Consistent pipe-delimited format: `type|name|home|version|flags|order|alias|desc`
  - Efficient querying by name, type, or all entries
  - Eliminates duplicate parsing logic across 20+ files
- **Plugin System** (v0.19.0+): Product-specific behavior encapsulation
  - 9 plugins: database, datasafe, client, iclient, oud, java, weblogic, emagent, oms
  - 11-function interface: validate, adjust, status, metadata, discover, etc.
  - Comprehensive plugin tests (100% pass rate)
  - Consolidates product-specific logic into dedicated plugins
  - Extensible architecture for new product types

### v0.19.0+ Architecture

- **Modular Library System** (v0.19.0+): Clean separation of concerns with 6 specialized libraries
  - Environment Parser - Extract and parse Oracle environment metadata
  - Environment Builder - Construct complete Oracle environment variables
  - Environment Validator - Multi-level validation (basic/standard/full)
  - Configuration Manager - Section-based hierarchical configuration
  - Status Checker - Real-time service and database status monitoring
  - Change Detector - Configuration change tracking and auto-reload
- **Hierarchical Configuration** (v0.19.0+): 6-level INI-style configuration system
  - Product sections: [RDBMS], [CLIENT], [ICLIENT], [GRID], [ASM], [DATASAFE], [OUD], [WLS]
  - Variable expansion: ${ORACLE_HOME}, ${ORACLE_SID}, ${ORACLE_BASE}
  - Override hierarchy: core → standard → local → customer → services → SID
- **Oracle Homes Management** (v0.19.0+): Unified support for all Oracle products
  - Database, Client, Instant Client (ICLIENT), Grid Infrastructure, ASM
  - Oracle Unified Directory (OUD), WebLogic Server (WLS), Data Safe On-Premises Connectors (DATASAFE)
  - Enterprise Manager (OMS, EM Agent), Java/JDK
  - Auto-discovery, export/import, version tracking
  - User-friendly aliases and integrated environment setup
- **Auto-Discovery of Running Instances** (v0.19.0+): Zero-config instant startup
  - Automatically detects running Oracle instances when oratab is empty
  - Persists discovered instances to oratab (or local oratab if permission denied)
  - Supports database instances (db_smon_*, ora_pmon_*) and ASM (+ASM)
  - Discovers Oracle Homes for all product types via `ORADBA_AUTO_DISCOVER_PRODUCTS`
  - Current user filtering for security
  - Duplicate prevention for idempotent operations
  - Configurable via `ORADBA_AUTO_DISCOVER_INSTANCES` and `ORADBA_AUTO_DISCOVER_PRODUCTS`

### Core Capabilities

- **Intelligent Environment Setup**: Automatic configuration with product type detection
  (RDBMS, CLIENT, ICLIENT, GRID, ASM, DATASAFE, OUD, WLS)
- **Autonomous Path Management**: Automatic Java and client tools detection and setup
  - Java path auto-detection for DataSafe, OUD, WebLogic (checks `$ORACLE_HOME/java` first)
  - Client path configuration for products without Oracle client tools
  - Configurable via `ORADBA_JAVA_PATH_FOR_NON_JAVA` and `ORADBA_CLIENT_PATH_FOR_NON_CLIENT`
- **Status & Monitoring**: Real-time service status for databases, listeners, and Data Safe
  connectors with change detection and auto-reload
- **Extension System**: Modular plugin architecture for custom scripts and tools
- **Service Management**: Enterprise-grade database and listener lifecycle control
- **50+ Shell Aliases**: SQL*Plus, RMAN, navigation, diagnostics, and service management
- **RMAN Wrapper**: Automated backup execution with parallel processing and notifications
- **Long Operations Monitoring**: Real-time tracking of RMAN, DataPump, and other operations
- **Database Status Display**: Comprehensive information for all states (OPEN/MOUNT/NOMOUNT)
- **SQL & RMAN Scripts**: Ready-to-use administration scripts with central logging
- **Self-Contained Installer**: Single executable, no external dependencies
- **Comprehensive Testing**: BATS test suite with 1086+ tests, 100% pass rate, CI/CD integration

## Quick Start

### Installation

#### Prerequisites Check (Optional)

Before installing, you can verify your system meets all prerequisites:

```bash
# Download and run the standalone check script
curl -sL https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh | bash

# Or download and run with verbose output
curl -L -o oradba_check.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh
chmod +x oradba_check.sh
./oradba_check.sh --verbose
```

The check script validates:

- Required system tools (bash, tar, awk, sed, grep, find, sort)
- Checksum utilities (sha256sum or shasum)
- Base64 encoder (for installer with embedded payload)
- Optional tools (rlwrap for command history, curl/wget for updates)
- Disk space availability (100MB minimum)
- Oracle environment configuration (if exists)
- Oracle binaries and tools (if installed)

#### Install OraDBA

Use the self-contained installer (see [Installation Guide](https://code.oradba.ch/oradba/02-installation/)
for alternative methods):

```bash
# Install latest version (auto-detects ORACLE_BASE)
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh

# Or specify custom installation directory
./oradba_install.sh --prefix /opt/oradba

# Pre-Oracle installation (v0.17.0+) - install before Oracle Database
./oradba_install.sh --user-level          # Install to ~/oradba
./oradba_install.sh --base /opt           # Install to /opt/local/oradba

# After Oracle is installed, link to system oratab
oradba_setup.sh link-oratab
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

# Setup Oracle Homes (v0.19.0+)
source oraenv.sh OUD12     # Oracle Unified Directory
source oraenv.sh WLS14     # WebLogic Server

# Interactive selection (displays both Oracle Homes and database SIDs)
source oraenv.sh

# Check environment status and changes (v0.19.0+)
oradba_env.sh status FREE  # Check database/service status
oradba_env.sh changes      # Detect configuration changes
oradba_env.sh validate     # Validate current environment
```

Manage Oracle Homes (v0.19.0+):

```bash
# List registered Oracle Homes
oradba_homes.sh list

# Auto-discover Oracle products
oradba_homes.sh discover --auto-add

# Add Oracle Home manually
oradba_homes.sh add --name OUD12 \
  --path /u01/app/oracle/product/12.2.1.4/oud --type oud

# Export/import Oracle Homes configuration (v0.19.0+)
oradba_homes.sh export > homes_backup.conf
oradba_homes.sh import homes_backup.conf

# Show environment status (includes Oracle Homes)
oraup.sh

# Query installations via Registry API (v0.19.0+)
oradba_registry_get_all                    # All installations
oradba_registry_get_by_name "ORCLCDB"     # Specific database/home
oradba_registry_get_by_type "database"    # All databases
oradba_registry_get_field "FREE" "home"   # Get ORACLE_HOME for SID
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
# Create new extension (easiest method)
oradba_extension.sh create mycompany

# Follow the displayed next steps to customize
cd /opt/oracle/local/mycompany
vi .extension              # Update metadata
vi bin/my_script.sh        # Add your scripts
chmod +x bin/my_script.sh

# Reload environment - extension is auto-loaded
source oraenv.sh FREE
my_script.sh      # Now available in PATH

# Manage extensions
oradba_extension.sh list              # Show all extensions
oradba_extension.sh info mycompany    # Detailed info
```

See [Extension System Guide](doc/extension-system.md) for complete documentation.

## Troubleshooting

If you experience issues with installation or environment setup:

```bash
# Run the diagnostic script (available after installation)
oradba_check.sh --verbose

# Or download the standalone version
curl -sL https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh | bash -s -- --verbose
```

The check script validates:

- System prerequisites and tools availability
- Disk space for installation
- Oracle environment configuration
- Oracle binaries and database connectivity
- OraDBA installation integrity

Common issues:

- **Missing tools**: Install required packages (tar, awk, sed, grep, find, base64)
- **Insufficient disk space**: Ensure at least 100MB free in installation directory
- **Oracle environment**: Set ORACLE_HOME, ORACLE_BASE, or configure oratab
- **Permissions**: Ensure write access to installation directory

For detailed troubleshooting, see the [User Guide](https://code.oradba.ch/oradba/12-troubleshooting/).

## Documentation

### 📘 User Documentation

Complete user guides available in multiple formats:

- **[User Guide (PDF)](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** -
  Download complete guide
- **[Online Documentation](https://code.oradba.ch/oradba)** - Browse chapters individually

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
- **[Extension System](doc/extension-system.md)** - Extension development guide
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
**[online documentation](https://code.oradba.ch/oradba)** for complete features and usage.

### Quick Development Commands

```bash
make help         # Show all available targets
make test         # Run test suite
make build        # Build installer
make check        # Run all quality checks
```

See [doc/development.md](doc/development.md) for complete development guide.

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

Copyright © 2026 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Links

- **Repository**: <https://github.com/oehrlis/oradba>
- **Issues**: <https://github.com/oehrlis/oradba/issues>
- **Releases**: <https://github.com/oehrlis/oradba/releases>
- **Discussions**: <https://github.com/oehrlis/oradba/discussions>
