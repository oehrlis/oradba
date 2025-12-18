# OraDBA User Documentation

Complete user guides and reference materials for the Oracle Database Administration Toolset.

**Audience:** Database administrators, operators, and users of OraDBA

**For Developers:** See [Developer Documentation](../../doc/README.md) for contribution guides and technical details.

## 📖 Complete User Guide

The complete OraDBA user documentation is available in multiple formats:

- **[PDF User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.pdf)** - Download for offline use
- **[HTML User Guide](https://github.com/oehrlis/oradba/releases/latest/download/oradba-user-guide.html)** - Single-page HTML version
- **Browse Online** - Individual chapters below

## Documentation Overview

This documentation is organized to take you from installation through advanced usage:

### Getting Started

- **[USAGE.md](USAGE.md)** - Complete usage guide
  - Installation and setup
  - Environment configuration with `oraenv.sh`
  - Using shell aliases
  - Database status and version management
  - Common administrative tasks

### Reference Materials

- **[DB_FUNCTIONS.md](DB_FUNCTIONS.md)** - Database function reference
  - Available database functions
  - Usage examples and parameters
  - Return values and error handling

### Troubleshooting

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
  - Installation problems
  - Environment setup issues
  - Configuration troubleshooting
  - Known issues and workarounds

## Quick Start

### Installation

```bash
# Download and run installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh
```

### First Steps

```bash
# Set environment for a specific database
source oraenv.sh FREE

# Or use auto-generated alias
free

# Show database status
dbstatus.sh

# List all available aliases
alih
```

## Key Features

### Intelligent Environment Setup

OraDBA automatically configures your Oracle environment:

- Sets `ORACLE_SID`, `ORACLE_HOME`, `ORACLE_BASE`
- Updates `PATH` and library paths
- Configures `TNS_ADMIN` and NLS settings
- Generates 50+ administrative aliases
- Loads hierarchical configuration (5 levels)

### Shell Aliases

Quick access to common tasks:

```bash
sq          # sqlplus / as sysdba
cdh         # cd $ORACLE_HOME
taa         # tail -f alert.log
alih        # Show all aliases
```

See [USAGE.md](USAGE.md) for complete alias documentation.

### Configuration System

Flexible 5-level configuration hierarchy:

1. `oradba_core.conf` - Core system settings
2. `oradba_standard.conf` - Standard aliases and variables
3. `oradba_customer.conf` - Customer overrides (optional)
4. `sid._DEFAULT_.conf` - Default SID settings
5. `sid.<SID>.conf` - Per-SID configuration (auto-created)

Later levels override earlier settings for complete customization.

### Database Status

```bash
dbstatus.sh
```

Displays comprehensive information:

- Instance and database status
- Memory allocation (SGA/PGA)
- Datafile locations and sizes
- PDB information (for multitenant)
- Archive log mode and status

## Additional Resources

### Scripts and Templates

- **SQL Scripts** - Located in `../sql/` directory
  - Database information queries
  - Session management
  - User information displays
  - See [../sql/README.md](../sql/README.md) for details

- **RMAN Scripts** - Located in `../rcv/` directory
  - Backup templates
  - Recovery procedures
  - See [../rcv/README.md](../rcv/README.md) for details

### Configuration

- **Example Configurations** - Located in `../etc/` directory
  - `oratab.example` - Sample oratab format
  - `oradba_customer.conf.example` - Customer configuration template
  - `sid.ORCL.conf.example` - SID-specific configuration example
  - See [../etc/README.md](../etc/README.md) for details

## Getting Help

### Documentation Hierarchy

1. **Start here** - This README and USAGE.md
2. **Function reference** - DB_FUNCTIONS.md
3. **Problems?** - TROUBLESHOOTING.md
4. **Developer info** - ../../doc/README.md

### Support Channels

- **GitHub Issues:** <https://github.com/oehrlis/oradba/issues>
  - Bug reports
  - Feature requests
  - Installation problems

- **GitHub Discussions:** <https://github.com/oehrlis/oradba/discussions>
  - Usage questions
  - Best practices
  - Community support

- **Project Repository:** <https://github.com/oehrlis/oradba>
  - Source code
  - Latest releases
  - Documentation

## Version Information

Check your installed version:

```bash
oradba_version.sh --check      # Show installed version
oradba_version.sh --verify     # Verify integrity
oradba_version.sh --update-check   # Check for updates
```

## Contributing

Found an issue or want to improve the documentation?

- Report issues: <https://github.com/oehrlis/oradba/issues>
- Submit pull requests: <https://github.com/oehrlis/oradba/pulls>
- See contribution guidelines: [CONTRIBUTING.md](../../CONTRIBUTING.md)

## License

Copyright © 2025 Stefan Oehrli

Licensed under the Apache License, Version 2.0. See [LICENSE](../../LICENSE) for details.
