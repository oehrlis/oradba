<!-- markdownlint-disable MD013 -->
# Usage Guide

**Purpose:** Practical usage guide covering common scenarios, best practices, and integration examples.

**Audience:** All users - practical examples and workflows.

**Prerequisites:**

- OraDBA installed and configured
- Basic familiarity with OraDBA concepts

## Introduction

oradba is a comprehensive Oracle Database Administration Toolset designed to simplify database operations in lab and engineering environments.

## Basic Usage

### Setting Oracle Environment

The primary function of oradba is to set up your Oracle environment based on the oratab file.

```bash
# Set environment for specific SID
source oraenv.sh FREE

# Interactive selection with numbered list
source oraenv.sh

# Silent mode (for scripts, no output)
source oraenv.sh FREE --silent

# Display only database status
source oraenv.sh FREE --status

# Note: Always use oraenv.sh (not oraenv) to avoid conflict with Oracle's utility
```

**Interactive Mode Features:**

- Automatically displays available SIDs from oratab as a numbered list
- Shows database status after environment is set (unless --silent is used)
- Detects TTY automatically to enable/disable interactive features

### Environment Variables

After setting the environment, the following variables are available:

- `ORACLE_SID` - Oracle System Identifier
- `ORACLE_HOME` - Oracle installation directory
- `ORACLE_BASE` - Oracle base directory
- `PATH` - Includes Oracle binaries
- `LD_LIBRARY_PATH` - Includes Oracle libraries
- `TNS_ADMIN` - TNS configuration directory
- `NLS_LANG` - Language settings

### Version Management

Check and verify your oradba installation:

```bash
# Check current version
oradba_version.sh --check

# Verify installation integrity (checksums)
oradba_version.sh --verify

# Check for available updates from GitHub
oradba_version.sh --update-check

# Show detailed version and installation information
oradba_version.sh --info
```

**Version Utility Features:**

- **Version Checking**: Display current installed version
- **Integrity Verification**: Verify all files match their SHA256 checksums
- **Update Detection**: Check GitHub for newer releases
- **Installation Metadata**: View installation date, method, and user
- **Security Auditing**: Cryptographic proof of unmodified installation

**Exit Codes:**

- `0` - Success or up-to-date
- `1` - Error or integrity check failed
- `2` - Update available

## Common Tasks

### Connecting to Database

```bash
# Set environment
source oraenv.sh FREE

# Connect as sysdba
sqlplus / as sysdba

# Connect as specific user
sqlplus username/password
```

### Running SQL Scripts

```bash
# Set SQLPATH
export SQLPATH=$ORADBA_PREFIX/src/sql

# Run script
sqlplus / as sysdba @db_info.sql

# Run with parameters
sqlplus / as sysdba @script.sql param1 param2
```

### RMAN Operations

```bash
# Set environment
source oraenv.sh FREE

# Run RMAN script
rman target / @$ORADBA_PREFIX/src/rcv/backup_full.rman

# Interactive RMAN
rman target /
```

### Switching Between Databases

```bash
# Switch to FREE
source oraenv.sh FREE

# Verify
echo $ORACLE_SID  # Should show: FREE

# Switch to TESTDB
source oraenv.sh TESTDB

# Verify
echo $ORACLE_SID  # Should show: TESTDB
```

## Configuration

### Global Configuration

Edit the global configuration file:

```bash
vim $ORADBA_PREFIX/src/etc/oradba.conf
```

Key settings:

```bash
# oratab file location
ORATAB_FILE="/etc/oratab"

# Debug mode
DEBUG=0

# Default directories
ORACLE_BASE="/u01/app/oracle"
BACKUP_DIR="/backup"
LOG_DIR="$ORADBA_PREFIX/log"
```

### User Configuration

Create personal configuration file:

```bash
# Copy example
cp $ORADBA_PREFIX/templates/etc/oradba_config.example ~/.oradba_config

# Edit
vim ~/.oradba_config
```

Example user configuration:

```bash
# Custom oratab location
ORATAB_FILE="$HOME/.oratab"

# Enable debug mode
DEBUG=1

# Custom SQL path
SQLPATH="$HOME/sql:$ORADBA_PREFIX/src/sql"
```

## Advanced Usage

### Debug Mode

Enable detailed output:

```bash
export DEBUG=1
source oraenv.sh FREE
```

### Custom oratab Location

```bash
export ORATAB_FILE="/custom/path/oratab"
source oraenv.sh FREE
```

### Scripting with oraenv.sh

**Note:** Always use `oraenv.sh` (not just `oraenv`) to avoid conflicts with Oracle's
own `/usr/local/bin/oraenv` utility.

```bash
#!/usr/bin/env bash
# Example script

# Source oraenv.sh
ORADBA_PREFIX="/opt/oradba"
source "$ORADBA_PREFIX/src/bin/oraenv.sh" FREE

# Verify environment
if [[ "$ORACLE_SID" != "FREE" ]]; then
    echo "Failed to set environment"
    exit 1
fi

# Perform database operations
sqlplus / as sysdba <<EOF
SELECT name, open_mode FROM v\$database;
EXIT;
EOF
```

## Integration

### Shell Profile

Add to `~/.bash_profile` or `~/.bashrc`:

```bash
# oradba configuration
export ORADBA_PREFIX="/opt/oradba"
export PATH="$ORADBA_PREFIX/src/bin:$PATH"
export SQLPATH="$ORADBA_PREFIX/src/sql"

# Set default environment (optional)
# source oraenv.sh FREE
```

### Cron Jobs

```bash
# Example cron entry
0 2 * * * . /opt/oradba/src/bin/oraenv.sh FREE && /backup/scripts/backup.sh
```

### Systemd Service

```ini
[Unit]
Description=Oracle Database Service
After=network.target

[Service]
Type=forking
User=oracle
Environment="ORADBA_PREFIX=/opt/oradba"
ExecStart=/bin/bash -c 'source /opt/oradba/src/bin/oraenv.sh FREE && $ORACLE_HOME/bin/dbstart $ORACLE_HOME'
ExecStop=/bin/bash -c 'source /opt/oradba/src/bin/oraenv.sh FREE && $ORACLE_HOME/bin/dbshut $ORACLE_HOME'

[Install]
WantedBy=multi-user.target
```

## SQL*Plus Configuration

The oradba installation includes a login.sql script that configures SQL*Plus:

```bash
# Set SQLPATH to use login.sql automatically
export SQLPATH=$ORADBA_PREFIX/src/sql

# Now SQL*Plus will use the configuration
sqlplus / as sysdba
```

## Best Practices

1. **Always source oraenv.sh before database operations**
   - Use `oraenv.sh` (not `oraenv`) to avoid conflict with Oracle's `/usr/local/bin/oraenv`
2. **Use full paths in scripts**
3. **Verify environment with echo commands**
4. **Use logging functions for scripts**
5. **Test in non-production first**

## Command Reference

### oraenv.sh Options

```bash
source oraenv.sh [ORACLE_SID] [OPTIONS]

Options:
  -f, --force      Force environment setup
  -h, --help       Display help message
  --silent         Silent mode (no output, for scripts)
  --status         Display only database status
```

### dbstatus.sh - Database Status Display

Display comprehensive database status information:

```bash
# Show status for current ORACLE_SID
dbstatus.sh

# Show status for specific SID
dbstatus.sh --sid FREE

# Enable debug output
dbstatus.sh --debug

# Options
dbstatus.sh [OPTIONS]

Options:
  -h, --help       Display help message
  -v, --version    Display version information
  -d, --debug      Enable debug mode
  -s, --sid SID    Display status for specific ORACLE_SID
```

**Status Information Displayed:**

- **All States:**
  - Oracle environment (ORACLE_BASE, ORACLE_HOME, TNS_ADMIN, VERSION)
  - Instance status and uptime
- **MOUNT and OPEN:**
  - Database name, unique name, DBID
  - Datafile size (total GB)
  - Memory allocation (SGA/PGA targets)
  - FRA size
  - Status with database role (MOUNTED / PRIMARY, OPEN / PRIMARY)
  - Session information (user/oracle counts)
  - Log mode and character set
  - PDB information if applicable
- **OPEN Only:**
  - Current memory usage (actual SGA/PGA in use)
- **Special Handling:**
  - Dummy databases: Shows environment only
  - NOT STARTED: Shows environment with clear status
  - No error messages for non-running or dummy databases

### Environment Verification

```bash
# Check Oracle environment
verify_oracle_env

# Get Oracle version
get_oracle_version

# Parse oratab
parse_oratab "FREE"
```

## See Also {.unlisted .unnumbered}

- [Environment Management](environment.md) - Detailed oraenv.sh usage
- [Configuration](configuration.md) - Configuration options
- [Quick Reference](reference.md) - Quick command reference
- [Troubleshooting](troubleshooting.md) - Problem solving

## Navigation {.unlisted .unnumbered}

**Previous:** [Log Management](log-management.md)  
**Home:** [Introduction](introduction.md)
