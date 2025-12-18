# Executable Scripts

Main executable scripts for OraDBA operations and utilities.

## Overview

This directory contains the core executable scripts that provide OraDBA's primary
functionality. These scripts are typically added to `PATH` during installation
and can be executed directly from the shell.

## Available Scripts

| Script                                   | Description                                                       |
|------------------------------------------|-------------------------------------------------------------------|
| [oraenv.sh](oraenv.sh)                   | Set Oracle environment from oratab with interactive SID selection |
| [oradba_check.sh](oradba_check.sh)       | Check system prerequisites and configuration                      |
| [oradba_install.sh](oradba_install.sh)   | Install OraDBA to target directory                                |
| [oradba_validate.sh](oradba_validate.sh) | Validate installation integrity                                   |
| [oradba_version.sh](oradba_version.sh)   | Version management and update checking                            |
| [oraup.sh](oraup.sh)                     | Update OraDBA from GitHub                                         |
| [dbstatus.sh](dbstatus.sh)               | Display database instance status                                  |
| [sessionsql.sh](sessionsql.sh)           | Launch SQL*Plus with session configuration                        |

**Total Scripts:** 8

## Usage

### Environment Setup (oraenv.sh)

Set Oracle environment variables from oratab:

```bash
# Interactive selection
source oraenv.sh

# Direct SID specification
source oraenv.sh FREE

# Silent mode (for scripts)
source oraenv.sh --silent FREE

# Case-insensitive matching
source oraenv.sh free  # matches FREE, Free, or free
```

**Features:**

- Interactive numbered list for SID selection
- Database status display
- PDB detection and alias generation
- PS1 prompt customization

### Version Management (oradba_version.sh)

Check version and installation integrity:

```bash
# Show current version
oradba_version.sh

# Check for updates
oradba_version.sh --check

# Verify installation integrity
oradba_version.sh --verify

# Show installation metadata
oradba_version.sh --info
```

### Database Status (dbstatus.sh)

Display current database information:

```bash
# Show database status
dbstatus.sh

# Output includes:
# - Instance name and version
# - Database status (OPEN, MOUNTED, etc.)
# - PDB information (if CDB)
# - Memory and session statistics
```

### Installation Scripts

```bash
# Check prerequisites
oradba_check.sh

# Install to custom location
oradba_install.sh /opt/oradba

# Validate installation
oradba_validate.sh

# Update from GitHub
oraup.sh
```

## Script Integration

### PATH Configuration

After installation, scripts are accessible from anywhere:

```bash
# Added by installer to ~/.bash_profile
export PATH=$ORADBA_BASE/bin:$PATH

# Use scripts directly
oradba_version.sh
source oraenv.sh
dbstatus.sh
```

### Sourcing vs Execution

- **Source** (`source` or `.`): Required for `oraenv.sh` to modify current shell environment
- **Execute** (direct call): Used for utilities like `oradba_version.sh`, `dbstatus.sh`

```bash
# Must source to set environment variables
source oraenv.sh FREE

# Can execute directly
oradba_version.sh --check
```

## Configuration

Scripts use configuration from:

1. `${ORADBA_BASE}/etc/oradba_core.conf` - Core settings
2. `${ORADBA_BASE}/etc/oradba_standard.conf` - Standard aliases and functions
3. `${ORADBA_BASE}/etc/oradba_customer.conf` - Custom overrides
4. `${ORADBA_BASE}/etc/sid.<SID>.conf` - SID-specific settings

See [Configuration](../doc/05-configuration.md) for details.

## Documentation

- **[Installation](../doc/02-installation.md)** - Installation guide
- **[Quickstart](../doc/03-quickstart.md)** - Getting started
- **[Environment Management](../doc/04-environment.md)** - Using oraenv.sh
- **[Configuration](../doc/05-configuration.md)** - Configuration hierarchy
- **[Aliases](../doc/06-aliases.md)** - Shell alias reference

## Development

### Script Standards

1. **Header**: Include standard header with purpose, usage, and version
2. **Functions**: Use functions from `lib/common.sh` and `lib/db_functions.sh`
3. **Error Handling**: Check return codes and provide meaningful errors
4. **Documentation**: Include usage examples in header comments
5. **Testing**: Write BATS tests for new functionality

### Debugging

Enable debug output:

```bash
# Set debug level
export ORADBA_LOG_LEVEL=DEBUG

# Run script
source oraenv.sh FREE
```

See [development.md](../../doc/development.md) for coding standards and guidelines.
