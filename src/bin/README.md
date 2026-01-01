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
| [longops.sh](longops.sh)                 | Monitor long-running operations in v$session_longops              |
| [rman_jobs.sh](rman_jobs.sh)             | Monitor RMAN backup and restore operations                        |
| [exp_jobs.sh](exp_jobs.sh)               | Monitor DataPump export jobs                                      |
| [imp_jobs.sh](imp_jobs.sh)               | Monitor DataPump import jobs                                      |
| [get_seps_pwd.sh](get_seps_pwd.sh)       | Extract passwords from Oracle Wallet                              |
| [sync_from_peers.sh](sync_from_peers.sh) | Sync files from remote peer to local and other peers              |
| [sync_to_peers.sh](sync_to_peers.sh)     | Distribute files from local host to peer hosts                    |

**Total Scripts:** 15

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

### Long Operations Monitoring (longops.sh)

Monitor long-running database operations:

```bash
# Monitor all long operations
longops.sh

# Monitor RMAN operations
longops.sh -o "RMAN%"

# Watch mode with 10-second interval
longops.sh -o "%EXP%" -w -i 10

# Use convenience wrappers
rman_jobs.sh -w    # Monitor RMAN jobs continuously
exp_jobs.sh        # Monitor DataPump exports
imp_jobs.sh -w     # Monitor DataPump imports
```

**Features:**

- Real-time monitoring of v$session_longops
- Operation pattern filtering (RMAN%, %EXP%, %IMP%)
- Watch mode with configurable refresh intervals
- Progress percentage and time remaining display
- Convenience wrappers for common operations

### Wallet Password Utility (get_seps_pwd.sh)

Extract passwords from Oracle Wallet:

```bash
# Extract password for entry
get_seps_pwd.sh -w /path/to/wallet -e entry_name

# Search wallet for matching entries
get_seps_pwd.sh -w /path/to/wallet -d

# With encoded password file
get_seps_pwd.sh -w /path/to/wallet -e entry -f pwd.enc
```

### Peer Synchronization (sync_*.sh)

Synchronize files across peer hosts:

```bash
# Sync from peer to all others
sync_from_peers.sh -p db01 -v /opt/oracle/wallet

# Distribute file to all peers
sync_to_peers.sh -v /etc/oracle/tnsnames.ora

# Dry run with delete option
sync_to_peers.sh -n -D /opt/oracle/network/admin/
```

### Database Status (dbstatus.sh)

Display comprehensive database status information:

```bash
# Show database status
dbstatus.sh

# Or use alias
sta
```

**Output Information:**

- **Environment**: ORACLE_BASE, ORACLE_HOME, TNS_ADMIN, version
- **Database State**:
  - STARTED (NOMOUNT): Single status field
  - MOUNTED: Single status field with database details
  - OPEN: Status with database role (e.g., "OPEN / PRIMARY")
- **Instance Details**: Name, uptime, memory usage (SGA/PGA)
- **Database Info**: Name, DBID, datafile size, log mode, character set
- **Sessions**: User and Oracle session counts (when OPEN)
- **PDBs**: Pluggable database list (when OPEN)
- **Not Started**: Shows environment with "NOT STARTED" status
- **Dummy Databases**: Identified as "Dummy Database (environment only)"

**Database States Supported:**

- Database not started (shows environment only)
- NOMOUNT/STARTED (instance only)
- MOUNT (instance + database info, no PDBs)
- OPEN (full information including PDBs)

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
