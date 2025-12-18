# Quick Start Guide

## Introduction

This guide helps you get started with OraDBA quickly after installation. You'll
learn how to set up your oratab file, switch between databases, and perform
common tasks.

## Prerequisites

- OraDBA installed (see [Installation Guide](02-installation.md))
- Oracle Database installed
- Shell profile configured (typically done automatically during installation)

## First Steps

### 1. Set Up Your oratab File

The oratab file defines your Oracle databases. Create or edit `/etc/oratab`:

```bash
# Format: SID:ORACLE_HOME:STARTUP_FLAG
# SID            - Oracle System Identifier
# ORACLE_HOME    - Oracle installation directory
# STARTUP_FLAG   - Y (auto-start), N (no auto-start), D (DGMGRL dummy)

# Examples:
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/19.0.0/dbhome_2:Y
PRODDB:/u01/app/oracle/product/21.0.0/dbhome_1:N
```

**Note:** The startup flag (Y/N/D) is mainly for documentation purposes in OraDBA.
It doesn't trigger automatic database startup but helps identify production vs
development databases.

### 2. Set Your Oracle Environment

Use `oraenv.sh` to set up your Oracle environment:

```bash
# Set environment for specific SID (always use oraenv.sh to avoid conflict with Oracle's oraenv)
source oraenv.sh FREE

# Or use the full path
source /opt/oradba/bin/oraenv.sh FREE

# For convenience, add an alias to your profile:
alias oraenv='source /opt/oradba/bin/oraenv.sh'
```

**Interactive Mode** (no SID specified):

```bash
# Run without arguments to see available databases
$ source oraenv.sh

Available Oracle SIDs from oratab:
1) FREE
2) TESTDB  
3) PRODDB
Select database (1-3):
```

### 3. Verify Your Environment

After setting the environment, verify it's configured correctly:

```bash
# Check Oracle environment variables
echo $ORACLE_SID    # Should show: FREE
echo $ORACLE_HOME   # Should show your Oracle installation path
echo $ORACLE_BASE   # Should show your Oracle base path

# Test SQL*Plus connection
sqlplus -V          # Shows SQL*Plus version

# Connect to database
sqlplus / as sysdba
```

You can also use the status display:

```bash
# Show environment status
oraup.sh

# Or use the short alias
u
```

### 4. Verify OraDBA Installation

Check your OraDBA installation integrity:

```bash
# Check version
oradba_version.sh --check

# Verify installation integrity (checksums)
oradba_version.sh --verify

# Show detailed installation information
oradba_version.sh --info

# Check for available updates
oradba_version.sh --update-check
```

## Common Tasks

### Switching Between Databases

One of the most common operations is switching between different database environments:

```bash
# Switch to FREE database
$ source oraenv.sh FREE
Setting environment for ORACLE_SID: FREE

# Verify
$ echo $ORACLE_SID
FREE

# Switch to TESTDB
$ source oraenv.sh TESTDB
Setting environment for ORACLE_SID: TESTDB

# Verify
$ echo $ORACLE_SID
TESTDB
```

**Using Aliases** (created automatically for each SID):

```bash
# Each SID gets an alias for quick switching
$ free          # Same as: source oraenv.sh FREE
$ testdb        # Same as: source oraenv.sh TESTDB
```

### Connecting to Database

```bash
# Set environment first
source oraenv.sh FREE

# Connect as sysdba (using alias)
sq              # Same as: sqlplus / as sysdba

# Or with rlwrap for command history
sqh             # Same as: rlwrap sqlplus / as sysdba

# Connect as sysoper
sqo             # Same as: sqlplus / as sysoper
```

### Running SQL Scripts

```bash
# Set environment
source oraenv.sh FREE

# The SQLPATH is automatically configured
# Run database info script
sqlplus / as sysdba @db_info.sql

# Or use full path
sqlplus / as sysdba @$ORADBA_PREFIX/sql/db_info.sql

# With parameters
sqlplus / as sysdba @script.sql param1 param2
```

**Available SQL scripts:**

- `db_info.sql` - Display database information
- `whoami.sql` - Show current user information
- `ssec_usrinf.sql` - Security user information
- `login.sql` - SQL*Plus formatting (loaded automatically)

### RMAN Operations

```bash
# Set environment
source oraenv.sh FREE

# Run RMAN (using alias)
rman            # Same as: rman target /

# With rlwrap for command history
rmanh           # Same as: rlwrap rman target /

# Run RMAN script
rman target / @$ORADBA_PREFIX/rcv/backup_full.rman
```

### Database Status Information

```bash
# Set environment
source oraenv.sh FREE

# Display comprehensive database status
dbstatus.sh

# Or use the short aliases
sta             # Same as: dbstatus.sh
u               # Same as: oraup.sh (shows all databases)
```

The status display shows:

- Database open mode (NOMOUNT, MOUNT, OPEN)
- Instance status and uptime
- Database name and log mode
- Datafile size and memory usage
- Active sessions
- PDB information (if applicable)

### Navigating Oracle Directories

OraDBA provides convenient aliases for quick directory navigation:

```bash
# Oracle directories
cdh             # cd $ORACLE_HOME
cdob            # cd $ORACLE_BASE
cdb             # cd $ORADBA_PREFIX
cdn             # cd $TNS_ADMIN

# Admin directories
cda             # cd $ORACLE_BASE/admin/$ORACLE_SID
cdc             # cd $ORACLE_BASE/admin/$ORACLE_SID/create

# Diagnostic directories
cdd             # cd diagnostic directory for current SID
cddt            # cd diagnostic/trace directory
cdda            # cd diagnostic/alert directory

# Log directories
cdlog           # cd $ORADBA_PREFIX/log
cdtmp           # cd temporary directory
```

### Viewing Logs

```bash
# Alert log aliases (automatically configured per SID)
taa             # tail -f alert log
vaa             # view alert log (less)
via             # edit alert log (vi)

# Listener status
lstat           # lsnrctl status
```

## Silent Mode (for Scripts)

When using OraDBA in scripts, use silent mode to suppress output:

```bash
#!/usr/bin/env bash

# Set environment silently
source oraenv.sh FREE --silent

# Now run your database operations
sqlplus / as sysdba <<EOF
SELECT name, open_mode FROM v\$database;
EXIT;
EOF
```

## Updating OraDBA

Keep your OraDBA installation up to date:

```bash
# Check for updates
oradba_version.sh --update-check

# Update from GitHub (to latest version)
$ORADBA_PREFIX/bin/oradba_install.sh --update --github

# Update to specific version
$ORADBA_PREFIX/bin/oradba_install.sh --update --github --version 0.7.0

# Update from local tarball
$ORADBA_PREFIX/bin/oradba_install.sh --update --local /path/to/oradba-0.7.0.tar.gz
```

**Update features:**

- Automatic backup before update
- Configuration preservation
- Rollback on failure
- Version detection (skips if already current)
- Force update option (`--force`)

## Next Steps

Now that you're familiar with basic operations, explore these topics:

- **[Environment Management](04-environment.md)** - Detailed oraenv.sh usage and environment variables
- **[Configuration](05-configuration.md)** - Customize OraDBA for your needs
- **[Aliases](06-aliases.md)** - Complete reference of 50+ aliases
- **[SQL Scripts](08-sql-scripts.md)** - Database administration SQL scripts
- **[RMAN Scripts](09-rman-scripts.md)** - Backup and recovery templates

## Tips and Best Practices

1. **Always set environment before database operations** - Use `source oraenv.sh SID` before any database work
2. **Use aliases for speed** - Learn the common aliases (sq, rman, cdh, etc.)
3. **Verify environment** - Check `$ORACLE_SID` when switching between databases
4. **Use status display** - Run `oraup.sh` to see all database statuses at a glance
5. **Keep OraDBA updated** - Check for updates regularly
6. **Use silent mode in scripts** - Add `--silent` flag when using oraenv.sh in automation

## Getting Help

If you encounter issues:

- Check the **[Troubleshooting Guide](12-troubleshooting.md)**
- View alias help: `alih` or `cat $ORADBA_PREFIX/doc/ALIAS_HELP.txt`
- Check version info: `oradba_version.sh --info`
- Review logs in `$ORADBA_PREFIX/log/`
- Open an issue on [GitHub](https://github.com/oehrlis/oradba/issues)

## Quick Reference Card

```bash
# Environment
source oraenv.sh FREE    # Set environment for FREE
source oraenv.sh         # Interactive SID selection
oraup.sh / u             # Show all database statuses

# SQL*Plus
sq / sqh                 # Connect as sysdba (with/without rlwrap)
sqlplus / as sysdba @db_info.sql

# RMAN
rman / rmanh             # RMAN target / (with/without rlwrap)

# Navigation
cdh / cdob / cda / cdd   # Oracle directories
taa / vaa                # View alert log

# Status
dbstatus.sh / sta        # Database status

# Version
oradba_version.sh --check          # Current version
oradba_version.sh --update-check   # Check for updates
```
