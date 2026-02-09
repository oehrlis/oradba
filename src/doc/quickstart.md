# Quick Start Guide

**Purpose:** Get started with OraDBA v0.19.x in 5 minutes - learn environment setup, Registry API basics, and common tasks.

**Prerequisites:**

- OraDBA v0.19.x installed (see [Installation](installation.md))
- Oracle Database or other Oracle products installed
- Shell profile configured

## First Steps

### Verify Installation

Check that OraDBA is properly installed:

```bash
# Check version
oradba_version.sh

# Verify installation integrity
oradba_validate.sh

# Expected output:
# ═══════════════════════════════════════════════════════════════
# OraDBA Installation Validation - v0.19.x
# ═══════════════════════════════════════════════════════════════
# All checks passed
```

### Understand the Registry

OraDBA v0.19.x uses a **Registry API** that automatically manages all Oracle installations:

- **Databases**: Auto-synced from `/etc/oratab` on first login
- **Non-Database Products**: Registered in `oradba_homes.conf`
- **Unified Access**: Single interface for all Oracle products

```mermaid
graph LR
    Oratab[/etc/oratab<br/>Databases]
    Homes[oradba_homes.conf<br/>Other Products]
    Registry[Registry API]
    Plugins[Plugin System<br/>8 Product Types]
    User[User Commands<br/>oraenv.sh, oraup.sh]
    
    Oratab -->|Auto-Sync| Registry
    Homes --> Registry
    Registry --> Plugins
    Plugins --> User
    
    style Oratab fill:#90EE90
    style Homes fill:#FFE4B5
    style Registry fill:#98FB98
    style Plugins fill:#FFD700
    style User fill:#87CEEB
```

### Set Up Your First Environment

**For Databases** (auto-discovered from oratab):

```bash
# Check what's available (auto-syncs from oratab on first run)
source oraenv.sh

# Output shows:
Available Oracle Installations:
  [1] FREE (database) - /u01/app/oracle/product/23ai/dbhomeFree
  [2] TESTDB (database) - /u01/app/oracle/product/19c/dbhome_1
Select [1-2, or 0 to cancel]:
```

**For Non-Database Products** (register manually):

```bash
# Register Data Safe connector
oradba_homes.sh add --name datasafe-conn1 \
  --path /u01/app/oracle/datasafe-conn1 \
  --type datasafe

# Register Instant Client
oradba_homes.sh add --name ic23c \
  --path /usr/lib/oracle/23/client64 \
  --type iclient

# Register Oracle Java
oradba_homes.sh add --name java21 \
  --path /u01/app/oracle/product/jdk-21 \
  --type java

# List all registrations
oradba_homes.sh list
```

### Set Your Oracle Environment

Use `oraenv.sh` to set environment for any registered Oracle installation:

```bash
# Database
source oraenv.sh FREE

# Data Safe connector
source oraenv.sh datasafe-conn1

# Instant Client
source oraenv.sh ic23c

# Oracle Java
source oraenv.sh java21

# Interactive selection (if no argument)
source oraenv.sh
```

### Verify Environment

After setting the environment:

```bash
# Check environment variables
echo $ORACLE_SID      # Database SID (or installation name)
echo $ORACLE_HOME     # Oracle installation path
echo $ORACLE_BASE     # Oracle base directory

# Check product type and version
oraup.sh

# Or use the short alias
u
```

## Common Tasks

### Switching Between Environments

**Using Direct Names:**

```bash
# Switch to FREE database
source oraenv.sh FREE

# Switch to Data Safe connector
source oraenv.sh datasafe-conn1

# Switch to Instant Client
source oraenv.sh ic23c

# Verify current environment
echo $ORACLE_SID
oraup.sh
```

**Using Auto-Generated Aliases:**

Each registered installation gets an automatic alias:

```bash
# Each installation gets a lowercase alias
free              # Same as: source oraenv.sh FREE
testdb            # Same as: source oraenv.sh TESTDB
datasafe-conn1    # Same as: source oraenv.sh datasafe-conn1
ic23c             # Same as: source oraenv.sh ic23c
```

### Working with Databases

**Connect to Database:**

```bash
# Set environment
source oraenv.sh FREE

# Connect as sysdba (using alias)
sq              # Same as: sqlplus / as sysdba

# With rlwrap for command history
sqh             # Same as: rlwrap sqlplus / as sysdba

# Connect as sysoper
sqo             # Same as: sqlplus / as sysoper
```

**Check Database Status:**

```bash
# Detailed status for current environment
dbstatus.sh     # or alias: sta

# Shows:
# - Database state (NOMOUNT/MOUNT/OPEN)
# - Instance information and uptime
# - Memory allocation (SGA/PGA)
# - Storage information
# - PDB status (if multitenant)
# - Archive log mode

# All registered installations
oraup.sh        # or alias: u
```

**Running SQL Scripts:**

```bash
# SQLPATH is automatically configured
sqlplus / as sysdba @db_info.sql

# Available SQL scripts in $ORADBA_PREFIX/sql/:
# - db_info.sql      - Database information
# - whoami.sql       - Current user info
# - ssec_usrinf.sql  - Security user information
# - tde_*.sql        - TDE encryption status
# - aud_*.sql        - Audit configuration
```

### Working with RMAN

```bash
# Set environment
source oraenv.sh FREE

# Run RMAN (using alias)
rman            # Basic RMAN connection

# With rlwrap for command history
rmanh

# With catalog
rmanc

# Run RMAN script
rman target / @$ORADBA_PREFIX/rcv/backup_full.rcv
```

### Working with Data Safe

```bash
# Set Data Safe connector environment
source oraenv.sh datasafe-conn1

# Check connector status
cmctl status

# Environment variables are set:
echo $ORACLE_HOME     # Data Safe connector home
echo $PATH            # Includes connector bin directory
```

### Working with Instant Client

```bash
# Set Instant Client environment
source oraenv.sh ic23c

# Verify
sqlplus64 -V

# Connect to remote database
sqlplus username/password@hostname:1521/service_name
```

### Navigating Oracle Directories

Convenient aliases for quick navigation:

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
cdd             # cd diagnostic directory
cddt            # cd diagnostic/trace
cdda            # cd diagnostic/alert

# Logs
cdlog           # cd $ORADBA_PREFIX/log
```

### Viewing Logs

```bash
# Alert log (databases only)
taa             # tail -f alert log
vaa             # view alert log (less)
via             # edit alert log (vi)

# Listener control (databases only)
lstat           # lsnrctl status
lstart          # lsnrctl start
lstop           # lsnrctl stop
```

## Registry API Usage

### List All Installations

```bash
# Simple list
oradba_homes.sh list

# Detailed information
oradba_homes.sh list --verbose

# Filter by type
oradba_homes.sh list --type database
oradba_homes.sh list --type datasafe
oradba_homes.sh list --type iclient
```

### View Installation Details

```bash
# Show details for specific installation
oradba_homes.sh show FREE

# Shows:
# - Installation name and type
# - ORACLE_HOME path
# - Product version
# - Plugin information
# - Environment variables
```

### Sync Database Homes from Oratab

Databases are automatically synced on first login, but you can trigger manually:

```bash
# Manual sync from oratab
oradba_homes.sh sync-oratab

# Shows:
# - Scans /etc/oratab for database entries
# - Deduplicates by ORACLE_HOME path
# - Names homes from directory (dbhomeFree, dbhome19c, etc.)
# - Adds only new homes (skips existing)
```

### Add Non-Database Installation

```bash
# Add Data Safe connector
oradba_homes.sh add \
  --name datasafe-conn1 \
  --path /u01/app/oracle/datasafe-conn1 \
  --type datasafe \
  --description "Production Data Safe Connector"

# Add Instant Client
oradba_homes.sh add \
  --name ic23c \
  --path /usr/lib/oracle/23/client64 \
  --type iclient

# Add Oracle Unified Directory
oradba_homes.sh add \
  --name oud1 \
  --path /u01/app/oracle/oud1 \
  --type oud

# Add Oracle Java
oradba_homes.sh add \
  --name java21 \
  --path /u01/app/oracle/product/jdk-21 \
  --type java
```

### Update or Remove Installation

```bash
# Update installation details
oradba_homes.sh update --name FREE --description "Free 23ai Database"

# Remove installation from registry
oradba_homes.sh remove --name old-test-db

# Note: Does not delete files, only removes from registry
```

## Plugin System

OraDBA v0.19.x uses plugins for product-specific operations:

**Supported Product Types:**

- `database` - Oracle Database (primary focus)
- `datasafe` - Oracle Data Safe On-Premises Connector
- `client` - Oracle Full Client
- `iclient` - Oracle Instant Client
- `oud` - Oracle Unified Directory
- `java` - Oracle Java (JDK/JRE)
- `weblogic` - WebLogic Server (basic support)
- `oms` - Enterprise Manager OMS (basic support)
- `emagent` - Enterprise Manager Agent (basic support)

Each plugin handles:

- Product detection and validation
- Version detection
- Environment variable setup (PATH, LD_LIBRARY_PATH, etc.)
- Status display
- Product-specific operations

## Silent Mode (for Scripts)

Use silent mode in automated scripts:

```bash
#!/usr/bin/env bash

# Set environment silently (no output)
source oraenv.sh FREE --silent

# Now run database operations
sqlplus -S / as sysdba <<EOF
SELECT name, open_mode FROM v\$database;
EXIT;
EOF
```

## View Comprehensive Status

The `oraup.sh` command shows complete environment information:

```bash
# Run status display
oraup.sh

# Shows:
# Oracle Environment Status
# ==========================================================================================
#
# Oracle Homes
# ------------------------------------------------------------------------------------------
# NAME                 TYPE             STATUS        ORACLE_HOME
# ------------------------------------------------------------------------------------------
# dbhomeFree           database         available     /u01/app/oracle/product/23ai/dbhomeFree
# rdbms26              database         dummy (→FREE) /u01/app/oracle/product/23ai/dbhomeFree
# datasafe-conn1       datasafe         available     /u01/app/oracle/datasafe-conn1
# ic23c                iclient          available     /usr/lib/oracle/23/client64
#
# Database Instances
# ------------------------------------------------------------------------------------------
# SID                  FLAG             STATUS        ORACLE_HOME
# ------------------------------------------------------------------------------------------
# FREE                 AUTO-START       open          /u01/app/oracle/product/23ai/dbhomeFree
#
# ------------------------------------------------------------------------------------------
# NAME                 PORT (tcp/tcps)  STATUS        ORACLE_HOME
# ------------------------------------------------------------------------------------------
# LISTENER             1521             up            /u01/app/oracle/product/23ai/dbhomeFree
#
# ==========================================================================================
```

## Extension System

Add custom functionality without modifying OraDBA core:

```bash
# List available extensions
ls -1 $ORADBA_LOCAL_BASE/*/

# Example output:
# odb_datasafe/     - Data Safe target management
# odb_autoupgrade/  - Oracle AutoUpgrade wrapper
# custom_scripts/   - Your custom scripts

# Extensions are auto-discovered and loaded
# Scripts in */bin/ are added to PATH
# Scripts in */sql/ are added to SQLPATH
```

See [Extension System](extensions.md) for details.

## Updating OraDBA

Keep OraDBA updated to latest v0.19.x release:

```bash
# Check current version
oradba_version.sh

# Check for updates
oradba_version.sh --update-check

# Update to latest v0.19.x
oraup.sh --update

# Or manually download and install
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh --update
```

## What's Different in v0.19.x

If you're upgrading from older versions:

**Registry API:**

- Databases auto-sync from oratab (no manual registration needed)
- Single `oradba_homes.conf` replaces old configuration approach
- Use `oradba_homes.sh` command for registry management

**Plugin System:**

- All product types use plugins (uniform interface)
- 8 product types supported (was limited in previous versions)
- Product detection is automatic and consistent

**No Basenv Coexistence:**

- Basenv coexistence mode removed in v0.19.x
- Clean architecture without legacy compatibility layer
- May be re-engineered with plugin approach in future releases

**Simplified Configuration:**

- Same 6-level hierarchy
- Core files remain compatible
- Customer customizations preserved during upgrade

## Next Steps

Now that you understand the basics:

- **[Environment Management](environment.md)** - Deep dive into Registry API and Plugin System
- **[Configuration](configuration.md)** - Customize OraDBA for your environment
- **[Aliases](aliases.md)** - Complete reference of 50+ aliases
- **[SQL Scripts](sql-scripts.md)** - Database administration SQL library
- **[RMAN Scripts](rman-scripts.md)** - Backup and recovery templates
- **[Extensions](extensions.md)** - Add custom functionality
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## Quick Reference Card

```bash
# Environment Setup
source oraenv.sh FREE          # Set environment
source oraenv.sh               # Interactive selection
oraup.sh / u                   # Show all installations

# Registry Management
oradba_homes.sh list           # List all installations
oradba_homes.sh add ...        # Register installation
oradba_homes.sh sync-oratab    # Sync from oratab

# Database Operations
sq / sqh                       # SQL*Plus (with/without rlwrap)
rman / rmanh                   # RMAN (with/without rlwrap)
dbstatus.sh / sta              # Database status

# Navigation
cdh / cdob / cda / cdd         # Oracle directories
taa / vaa                      # View alert log

# Product-Specific
cmctl status                   # Data Safe connector status
sqlplus64 -V                   # Instant Client version
java -version                  # Oracle Java version

# Help & Version
alih                           # Alias help
oradba_version.sh              # Version information
oradba_validate.sh             # Validate installation
```

## Getting Help

If you encounter issues:

- **[Troubleshooting Guide](troubleshooting.md)** - Common problems and solutions
- **Alias Help**: Run `alih` for quick alias reference
- **Version Info**: Run `oradba_version.sh --info`
- **Logs**: Check `$ORADBA_PREFIX/log/` for detailed logs
- **GitHub**: [github.com/oehrlis/oradba/issues](https://github.com/oehrlis/oradba/issues)

## Tips and Best Practices

1. **Always set environment first** - Use `source oraenv.sh` before Oracle operations
2. **Use the Registry** - Let OraDBA manage installations via Registry API
3. **Leverage plugins** - Each product type has optimized plugin handling
4. **Learn the aliases** - Memorize common ones (sq, rman, cdh, taa, u)
5. **Verify environment** - Check `$ORACLE_SID` when switching
6. **Use silent mode in scripts** - Add `--silent` for automation
7. **Keep updated** - Stay on latest v0.19.x for bug fixes and features

## Navigation

**Previous:** [Installation](installation.md)  
**Next:** [Environment Management](environment.md)
