# Quick Start Guide

**Purpose:** Get started quickly with OraDBA after installation - learn to set up oratab, switch databases, and perform
common tasks.

**Prerequisites:**

- OraDBA installed (see [Installation](installation.md))
- Oracle Database installed (or see [Pre-Oracle Quick Start](#pre-oracle-quick-start) below)
- Shell profile configured

## Introduction

This guide helps you get started with OraDBA quickly after installation. You'll
learn how to set up your oratab file, switch between databases, and perform
common tasks.

## Pre-Oracle Quick Start

**Available from:** v0.17.0

If you installed OraDBA **before Oracle Database**, follow this streamlined path:

### 1. Verify Pre-Oracle Installation

```bash
# Check installation mode
oradba_validate.sh

# Expected output:
# ═══════════════════════════════════════════════════════════════
# OraDBA Installation Validation
# Installation Mode: Pre-Oracle
# ═══════════════════════════════════════════════════════════════
```

### 2. Understand Pre-Oracle Behavior

In pre-Oracle mode, OraDBA operates with graceful degradation:

```bash
# Environment tools work but don't set Oracle-specific variables
source oraenv.sh
echo $ORADBA_NO_ORACLE_MODE  # Shows: true

# Status tools show helpful guidance
oraup.sh
# Shows: "No Oracle databases found" with setup instructions

# Validation is context-aware
oradba_validate.sh  # Skips Oracle-specific checks
```

### 3. After Installing Oracle

Once Oracle Database is installed, link OraDBA to the system oratab:

```bash
# Link to system oratab (creates symlink)
oradba_setup.sh link-oratab

# Verify configuration
oradba_setup.sh check

# Show current settings
oradba_setup.sh show-config
```

### 4. Verify Full Integration

```bash
# Validate complete setup
oradba_validate.sh
# Now shows: "Installation Mode: Oracle Installed"

# List databases
oraup.sh
# Shows databases from /etc/oratab

# Set environment
source oraenv.sh FREE
echo $ORACLE_HOME  # Now set correctly
```

**What's Next?** Continue with [First Steps](#first-steps) below for full Oracle usage.

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

# Run RMAN with catalog (or fallback to target /)
rmanc

# With rlwrap for command history (manual connection)
rmanh
RMAN> connect target /

# With rlwrap and catalog
rmanch

# Standard Oracle RMAN command (not aliased)
rman target /

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

- **Database State**: STARTED (NOMOUNT), MOUNTED, or OPEN with role
- **Environment**: ORACLE_BASE, ORACLE_HOME, TNS_ADMIN, version
- **Instance Info**: Name, uptime, status
- **Database Info**: Name, DBID, datafile size, log mode, character set
- **Memory Usage**: SGA/PGA allocation
- **Sessions**: Active user and Oracle sessions (when OPEN)
- **PDB Information**: Pluggable databases (when OPEN)
- **Not Started**: Shows environment info with "NOT STARTED" status
- **Dummy Databases**: Identified as "Dummy Database (environment only)"

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

# Listener control
listener        # Listener control (oradba_lsnrctl.sh wrapper)
lstat           # lsnrctl status (Oracle native)
lstart          # lsnrctl start (Oracle native)
lstop           # lsnrctl stop (Oracle native)
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
$ORADBA_PREFIX/bin/oradba_install.sh --update --github --version 0.14.1

# Update from local tarball
$ORADBA_PREFIX/bin/oradba_install.sh --update --local /path/to/oradba-0.14.1.tar.gz
```

**Update features:**

- Automatic backup before update
- Configuration preservation
- Rollback on failure
- Version detection (skips if already current)
- Force update option (`--force`)

## Next Steps

Now that you're familiar with basic operations, explore these topics:

- **[Environment Management](environment.md)** - Detailed oraenv.sh usage and environment variables
- **[Configuration](configuration.md)** - Customize OraDBA for your needs
- **[Aliases](aliases.md)** - Complete reference of 50+ aliases
- **[SQL Scripts](sql-scripts.md)** - Database administration SQL scripts
- **[RMAN Scripts](rman-scripts.md)** - Backup and recovery templates

## Tips and Best Practices

1. **Always set environment before database operations** - Use `source oraenv.sh SID` before any database work
2. **Use aliases for speed** - Learn the common aliases (sq, rman, cdh, etc.)
3. **Verify environment** - Check `$ORACLE_SID` when switching between databases
4. **Use status display** - Run `oraup.sh` to see all database statuses at a glance
5. **Keep OraDBA updated** - Check for updates regularly
6. **Use silent mode in scripts** - Add `--silent` flag when using oraenv.sh in automation

## Getting Help

If you encounter issues:

- Check the **[Troubleshooting Guide](troubleshooting.md)**
- View alias help: `alih` or `cat $ORADBA_PREFIX/doc/alias_help.txt`
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

# Extensions
oradba_extension.sh list              # List all extensions
oradba_extension.sh info customer     # Show extension details
oradba_extension.sh add oehrlis/odb_xyz  # Install extension from GitHub
oradba_extension.sh create myext      # Create new extension from template

# Version
oradba_version.sh --check          # Current version
oradba_version.sh --update-check   # Check for updates
```

## Extending OraDBA

You can add custom scripts without modifying the core installation:

### Option 1: Install from GitHub

```bash
# Install existing extension
oradba_extension.sh add oehrlis/odb_autoupgrade

# Source environment to load it
source oraenv.sh FREE
```

### Option 2: Create from Template

```bash
# Create new extension
oradba_extension.sh create customer

# Add your scripts
vi /opt/oracle/local/customer/bin/my_check.sh

# Reload environment
source oraenv.sh FREE
my_check.sh              # Your script is now in PATH
```

### Option 3: Manual Creation

```bash
# Create extension directory
mkdir -p /opt/oracle/local/customer/bin

# Add your script
cat > /opt/oracle/local/customer/bin/my_check.sh << 'EOF'
#!/usr/bin/env bash
echo "Custom check for ${ORACLE_SID}"
EOF

chmod +x /opt/oracle/local/customer/bin/my_check.sh

# Next time you source oraenv, your script is available
source oraenv.sh FREE
my_check.sh              # Your script is now in PATH
```

See [Extension System](extensions.md) for complete guide.

## See Also {.unlisted .unnumbered}

- [Environment Management](environment.md) - Detailed oraenv.sh usage
- [Aliases](aliases.md) - Complete alias reference
- [Configuration](configuration.md) - Customizing OraDBA
- [Extension System](extensions.md) - Adding custom scripts
- [Usage Examples](usage.md) - More usage scenarios

## Navigation {.unlisted .unnumbered}

**Previous:** [Installation](installation.md)  
**Next:** [Environment Management](environment.md)
