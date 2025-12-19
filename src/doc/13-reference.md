# Quick Reference

## OraDBA Quick Reference Card

Essential commands and aliases for daily Oracle database administration with OraDBA.

## Environment Setup

```bash
# Set environment for database
source oraenv.sh FREE          # Set environment for FREE
source oraenv.sh               # Interactive SID selection
oraup.sh                       # Show all database statuses
u                              # Short alias for oraup.sh

# Version and help
oradba_version.sh --check      # Check OraDBA version
oradba_version.sh --verify     # Verify installation integrity
alih                           # This help / alias reference
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
# RMAN connections
rman                           # rman target /
rmanh                          # rman target / (with rlwrap)
rmanc                          # rman target / catalog (uses ORADBA_RMAN_CATALOG)
rmanch                         # rman target / catalog (with rlwrap)
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
lsnr / lsnrh                   # lsnrctl (with rlwrap)
lstat                          # lsnrctl status
lstart                         # lsnrctl start
lstop                          # lsnrctl stop
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

## Further Reading

Full documentation available in `$ORADBA_PREFIX/doc/`:

1. **README.md** - Project overview
2. **01-introduction.md** - What is OraDBA
3. **02-installation.md** - Installation guide
4. **03-quickstart.md** - Getting started
5. **04-environment.md** - Environment management
6. **05-configuration.md** - Configuration system
7. **06-aliases.md** - Complete alias reference
8. **07-pdb-aliases.md** - PDB alias reference
9. **08-sql-scripts.md** - SQL scripts reference
10. **09-rman-scripts.md** - RMAN scripts
11. **10-functions.md** - Database functions
12. **11-rlwrap.md** - rlwrap configuration
13. **12-troubleshooting.md** - Troubleshooting guide
14. **13-reference.md** - This quick reference

---

**OraDBA** - Oracle Database Administration Toolset
<https://github.com/oehrlis/oradba>

For issues and contributions: <https://github.com/oehrlis/oradba/issues>
