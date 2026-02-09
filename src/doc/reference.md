# Quick Reference

**Purpose:** Condensed reference card for essential OraDBA commands and aliases - quick lookup for daily
operations.

**Audience:** All users - especially useful for beginners and quick reference.

## Introduction

Essential commands and aliases for daily Oracle database administration with OraDBA. This reference covers
database operations and can be adapted for other product types (Data Safe, Instant Client, Java, etc.) supported by the
Plugin System.

## OraDBA Quick Reference Card

## Environment Setup

```bash
# Set environment for database
source oraenv.sh FREE          # Set environment for FREE
source oraenv.sh               # Interactive SID selection
oraup.sh                       # Show all database statuses
u                              # Short alias for oraup.sh

# Version and help
oradba help                    # OraDBA help system menu
oradba help aliases            # Show alias help
oradba help scripts            # List available scripts
oradba help variables          # Show environment variables
oradba help config             # Configuration system
oradba help sql                # SQL script help
oradba_version.sh --check      # Check OraDBA version
oradba_version.sh --verify     # Verify installation integrity
oradba_validate.sh             # Validate installation and environment
oradba_setup.sh link-oratab    # Link to system oratab (v0.17.0+)
oradba_setup.sh check          # Check installation health (v0.17.0+)
oradba_setup.sh show-config    # Display configuration (v0.17.0+)
alih                           # Alias help reference
```

## SQL*Plus Connections

```bash
# Basic connections
sq                             # sqlplus / as sysdba
sqh                            # sqlplus / as sysdba (with rlwrap)
sqoh                           # sqlplus / as sysoper (with rlwrap)
sqlplush                       # sqlplus /nolog (with rlwrap)
sessionsql                     # SQL*Plus with terminal width detection
```

## RMAN Connections

```bash
# RMAN connections (note: 'rman' is not aliased)
rman target /                  # Standard Oracle RMAN command
rmanc                          # rman target / [catalog] (fallback)
rmanh                          # rlwrap rman (manual connection)
rmanch                         # rlwrap rman target / [catalog]
```

## Directory Navigation

```bash
# Oracle directories
cdh                            # cd $ORACLE_HOME
cdob                           # cd $ORACLE_BASE
cdbn                           # cd $ORACLE_HOME/bin
cdn                            # cd $TNS_ADMIN/..
cdt                            # cd $TNS_ADMIN
cdl                            # cd $ORACLE_BASE/local

# OraDBA directories
cdb                            # cd $ORADBA_PREFIX
etc / cde                      # cd $ORADBA_ETC
log / cdlog                    # cd $ORADBA_LOG
cdtmp                          # cd $ORADBA_TMP

# SID-specific (dynamic)
cda                            # cd $ORACLE_BASE/admin/$ORACLE_SID
cdc                            # cd $ORACLE_BASE/oradata/$ORACLE_SID
cdd                            # cd diagnostic_dest
cddt                           # cd diagnostic_dest/trace
cdda                           # cd diagnostic_dest/alert
```

## Diagnostic and Logs

```bash
# Alert log
taa                            # tail -f -n 50 alert_$ORACLE_SID.log
vaa                            # less alert_$ORACLE_SID.log
via                            # vi alert_$ORACLE_SID.log

# Listener and diagnostics
lsnr / lsnrh                   # lsnrctl (Oracle native, with rlwrap)
listener                       # Listener control (oradba_lsnrctl.sh wrapper)
lstart / lsnrstart             # Start listener (wrapper)
lstop / lsnrstop               # Stop listener (wrapper)
lsnrrestart                    # Restart listener (wrapper)
lsnrstatus                     # Listener status (wrapper)
lstat                          # lsnrctl status (Oracle native)
adrcih                         # adrci (with rlwrap)
```

## Database Operations

```bash
# Status and monitoring
oraup / u                      # Oracle environment overview
sta                            # dbstatus.sh - current database status
pmon                           # ps -ef | grep pmon
lstat                          # lsnrctl status

# Configuration files
oratab                         # cat /etc/oratab
tns                            # cat $TNS_ADMIN/tnsnames.ora
```

## File Editing

```bash
# Oracle configuration
vio                            # vi /etc/oratab
vit                            # vi $TNS_ADMIN/tnsnames.ora
vil                            # vi $TNS_ADMIN/listener.ora
visql                          # vi $TNS_ADMIN/sqlnet.ora
vildap                         # vi $TNS_ADMIN/ldap.ora

# OraDBA configuration
vis                            # vi $ORADBA_ETC/oradba_standard.conf
vic                            # vi $ORADBA_ETC/oradba_customer.conf
vii                            # vi $ORADBA_ETC/sid.$ORACLE_SID.conf
```

## SQL Scripts

```sql
-- Database information
@db_info                       -- Database name, version, status
@who                           -- Current session and user information

-- Security and users
@users                         -- List all database users [DBA]
@roles                         -- Show role hierarchy [DBA]
@privs                         -- Show privileges for current user
@objgr                         -- Show object grants

-- Audit
@audit                         -- Audit configuration [AUDIT_ADMIN]
@apol                          -- Audit policies [AUDIT_ADMIN]
@logins                        -- Login events [AUDIT_ADMIN]
@afails                        -- Failed login attempts [AUDIT_ADMIN]
@aevt                          -- Recent audit events [AUDIT_ADMIN]

-- Encryption (TDE)
@tde                           -- TDE configuration status [DBA]
@keys                          -- Master encryption keys [SYSDBA]
@wallets                       -- Keystore status [DBA]
@tdeops                        -- TDE operations progress [DBA]

-- Administration
@space                         -- Tablespace usage [DBA]
@temp                          -- Temp tablespace usage [DBA]
@locks                         -- Current locks and blocking
@sess                          -- Active sessions
@jobs                          -- Scheduler jobs [DBA]
@params                        -- Init parameters [DBA]
```

## Monitoring and Operations

```bash
# Long operations monitoring
longops.sh                     # Monitor all long-running operations
longops.sh -o "RMAN%"          # Monitor RMAN operations
longops.sh -o "%EXP%" -w       # Watch DataPump exports
longops.sh -w -i 10            # Watch mode with 10-second interval

# Convenience wrappers
rman_jobs.sh                   # Monitor RMAN jobs
rman_jobs.sh -w                # Continuous RMAN monitoring
exp_jobs.sh                    # Monitor DataPump exports
imp_jobs.sh -w                 # Monitor DataPump imports

# Wallet utilities
get_seps_pwd.sh -w /path/to/wallet -e entry_name
                               # Extract password from wallet
get_seps_pwd.sh -w /path/to/wallet -d
                               # Display all wallet entries

# Peer synchronization
sync_to_peers.sh /path/to/file # Distribute file to peer hosts
sync_to_peers.sh -n -v /path   # Dry-run with verbose output
sync_from_peers.sh -p db01 /path
                               # Sync from peer to all others
```

## PDB Aliases (Multitenant)

```bash
# Auto-generated for each PDB
pdb1                           # Connect to PDB1
pdb2                           # Connect to PDB2
pdbpdb1                        # Connect to PDB1 (prefixed)

# List available PDBs
echo $ORADBA_PDBLIST           # Show all PDBs in current CDB
```

## Extension Management

```bash
# List all extensions
oradba_extension.sh list

# Show extension details
oradba_extension.sh info <name>

# Enable/disable extension
oradba_extension.sh enable <name>
oradba_extension.sh disable <name>

# Validate extension
oradba_extension.sh validate <name>
```

For complete extension system documentation, see [Extension System Guide](extensions.md).

## Utility Aliases

```bash
# General utilities
c                              # clear
m                              # more
l                              # ls -al
ll                             # ls -alb
lr                             # ls -ltr
lsl                            # ls -lrt | tail -n 20
psg                            # ps -ef | grep
alig                           # alias | grep -i
sqa                            # show_sqlpath
pth                            # show_path
cfg                            # show_config
save_cron                      # Backup crontab
```

## Configuration Variables

```bash
# Check important variables
echo $ORACLE_SID               # Current Oracle SID
echo $ORACLE_HOME              # Oracle installation directory
echo $ORACLE_BASE              # Oracle base directory
echo $ORADBA_PREFIX            # OraDBA installation directory
echo $SQLPATH                  # SQL*Plus script path
echo $TNS_ADMIN                # TNS configuration directory
echo $ORADBA_SIDLIST           # All SIDs from oratab
echo $ORADBA_PDBLIST           # All PDBs in current CDB
echo $ORADBA_PDB               # Currently selected PDB
```

## Environment Variables for Scripts

```bash
# Short directory variables
$cdh                           # $ORACLE_HOME
$cda                           # $ORACLE_BASE/admin/$ORACLE_SID
$cdob                          # $ORACLE_BASE
$cdd                           # Diagnostic directory
$etc                           # $ORADBA_ETC
$log                           # $ORADBA_LOG

# Usage in commands
cd $cdh/bin                    # Navigate to ORACLE_HOME/bin
ls -l $etc/*.conf              # List config files
vi $cda/scripts/my_script.sh   # Edit script in admin directory
```

## Common Workflows

### Switch Database

```bash
# Method 1: Direct
source oraenv.sh TESTDB

# Method 2: Using alias (auto-generated per SID)
testdb

# Method 3: Interactive
source oraenv.sh               # Shows numbered list
```

### Quick Health Check

```bash
# Overview
u                              # Show all databases status

# Current database
sta                            # Detailed status
@space                         # Tablespace usage
@temp                          # Temp space
@sess                          # Active sessions
@locks                         # Check for blocking
```

### Monitor Logs

```bash
# Real-time alert log
taa

# Browse alert log
vaa

# Check listener
lstat
```

### Backup and Recovery

```bash
# Full backup
rman target / @$ORADBA_PREFIX/rcv/backup_full.rman

# List backups
rman target /
RMAN> LIST BACKUP SUMMARY;
```

## Tips and Tricks

- **Use Tab Completion**: rlwrap provides tab completion with SQL*Plus and RMAN
- **History Search**: Ctrl+R to search command history (with rlwrap)
- **Custom Aliases**: Add your own in `$ORADBA_ETC/oradba_customer.conf`
- **Silent Mode**: Use `--silent` flag in scripts: `source oraenv.sh FREE --silent`
- **Debug Mode**: Set `DEBUG=1` to see detailed output
- **Check Aliases**: Use `type alias_name` to see alias definition
- **Convenience Variables**: Use `$cdh`, `$cda`, `$etc` in commands and scripts

## Privilege Requirements

- **[User]** - Regular user, minimal privileges
- **[DBA]** - DBA role or SYSTEM user
- **[SYSDBA]** - SYSDBA, SYSKM, SYSBACKUP privileges
- **[AUDIT_ADMIN]** - AUDIT_ADMIN or AUDIT_VIEWER role

## Getting Help

```bash
# OraDBA help
alih                           # This quick reference
oradba_version.sh --info       # Installation information

# Check configuration
cat $ORADBA_ETC/oradba_customer.conf

# List all aliases
alias | grep -E '^(cd|sq|rm|via|taa)'

# Documentation
ls -l /opt/oradba/doc/
```

## See Also {.unlisted .unnumbered}

- [Aliases](aliases.md) - Detailed alias documentation
- [Environment Management](environment.md) - Complete environment guide
- [Configuration](configuration.md) - Detailed configuration options
- [Usage Examples](usage.md) - Practical usage scenarios

## Further Reading

Full documentation chapters:

1. [Introduction](introduction.md) - What is OraDBA
2. [Installation](installation.md) - Installation guide
3. [Quick Start](quickstart.md) - Getting started
4. [Environment Management](environment.md) - Environment setup
5. [Configuration](configuration.md) - Configuration system
6. [Aliases](aliases.md) - Complete alias reference
7. [PDB Aliases](pdb-aliases.md) - PDB-specific aliases
8. [SQL Scripts](sql-scripts.md) - SQL scripts
9. [RMAN Scripts](rman-scripts.md) - RMAN templates
10. [Functions](functions.md) - Database functions
11. [rlwrap](rlwrap.md) - rlwrap configuration
12. [Troubleshooting](troubleshooting.md) - Problem solving
13. [Quick Reference](reference.md) - This reference
14. [SQLNet Config](sqlnet-config.md) - SQLNet configuration
15. [Log Management](log-management.md) - Log handling
16. [Usage Examples](usage.md) - Usage guide

## Navigation {.unlisted .unnumbered}

**Previous:** [Troubleshooting Guide](troubleshooting.md)  
**Next:** [SQLNet Configuration](sqlnet-config.md)

---

**OraDBA** - Oracle Database Administration Toolset  
<https://github.com/oehrlis/oradba>

For issues and contributions: <https://github.com/oehrlis/oradba/issues>
