# Alias Reference

**Purpose:** Complete reference for OraDBA shell aliases — SQL*Plus, RMAN, directory navigation,
database operations, PDB management, and rlwrap integration.

**Audience:** All users who want to streamline database administration tasks.

## Introduction {.unlisted}

OraDBA provides 50+ shell aliases to streamline Oracle database administration tasks. Aliases are
automatically loaded when you set your Oracle environment using `oraenv.sh`, giving you convenient
shortcuts for common operations.

The alias system uses the Plugin System to detect product types and generates appropriate aliases.
For Container Databases, it automatically queries `v$pdbs` and generates PDB-specific connection
aliases. rlwrap-enabled aliases (`sqh`, `rmanh`, etc.) provide command history and optional
password filtering when rlwrap is installed.

## SQL*Plus and RMAN Aliases

### SQL*Plus

| Alias        | Description                          | Command                       |
|--------------|--------------------------------------|-------------------------------|
| `sq`         | SQL*Plus as SYSDBA (basic)           | `sqlplus / as sysdba`         |
| `sqh`        | SQL*Plus as SYSDBA (with rlwrap)     | `rlwrap sqlplus / as sysdba`  |
| `sqlplush`   | SQL*Plus /nolog (with rlwrap)        | `rlwrap sqlplus /nolog`       |
| `sqoh`       | SQL*Plus as SYSOPER (with rlwrap)    | `rlwrap sqlplus / as sysoper` |
| `sessionsql` | SQL*Plus with dynamic terminal width | `sessionsql.sh`               |

: SQL*Plus Aliases

**`sessionsql`** automatically detects your terminal width and configures SQL*Plus `LINESIZE` and
`PAGESIZE` for optimal display. rlwrap-enabled aliases (`sqh`, `sqoh`, `sqlplush`) add command
history (up/down arrows), tab completion, and line editing; see [rlwrap Integration](#rlwrap-integration)
for password filtering.

```bash
# Connect as SYSDBA with command history
sqh

# Connect /nolog then authenticate at the prompt
sqlplush
```

### RMAN

| Alias    | Description                       | Command                          |
|----------|-----------------------------------|----------------------------------|
| `rmanc`  | RMAN with catalog/fallback        | `rman target / [catalog ...]`    |
| `rmanh`  | RMAN with rlwrap (manual connect) | `rlwrap rman`                    |
| `rmanch` | RMAN with rlwrap + catalog        | `rlwrap rman target / [catalog]` |

: RMAN Aliases

**Note:** The `rman` command itself is not aliased to avoid conflicts with Oracle's native binary.

Configure the catalog in `oradba_customer.conf` or `sid.<SID>.conf`:

```bash
# Global catalog
ORADBA_RMAN_CATALOG="rman_user/password@catdb"

# Per-database catalog (in sid.PRODDB.conf)
ORADBA_RMAN_CATALOG="rman_user@prodcat"
```

```bash
# RMAN with rlwrap — connect manually at prompt
rmanh
RMAN> connect target /
RMAN> connect catalog rman@catdb
```

## Directory Navigation

Quick navigation to Oracle and OraDBA directories.

### Oracle Directories

| Alias  | Description               | Target Directory     |
|--------|---------------------------|----------------------|
| `cdob` | Change to ORACLE_BASE     | `$ORACLE_BASE`       |
| `cdh`  | Change to ORACLE_HOME     | `$ORACLE_HOME`       |
| `cdbn` | Change to bin directory   | `$ORACLE_HOME/bin`   |
| `cdn`  | Change to network parent  | `$TNS_ADMIN/..`      |
| `cdt`  | Change to TNS_ADMIN       | `$TNS_ADMIN`         |
| `cdl`  | Change to local directory | `$ORADBA_LOCAL_BASE` |

: Oracle Directory Navigation Aliases

### OraDBA Directories

| Alias   | Description              | Target Directory |
|---------|--------------------------|------------------|
| `cdb`   | Change to OraDBA base    | `$ORADBA_PREFIX` |
| `etc`   | Change to OraDBA etc     | `$ORADBA_ETC`    |
| `cde`   | Change to OraDBA etc     | `$ORADBA_ETC`    |
| `log`   | Change to OraDBA log     | `$ORADBA_LOG`    |
| `cdlog` | Change to OraDBA log     | `$ORADBA_LOG`    |
| `cdtmp` | Change to temp directory | `$ORADBA_TMP`    |

### SID-Specific Directories (Dynamic)

Generated dynamically based on the current `ORACLE_SID`:

| Alias  | Description                      | Target Directory                   |
|--------|----------------------------------|------------------------------------|
| `cda`  | Change to admin directory        | `$ORACLE_BASE/admin/$ORACLE_SID`   |
| `cdc`  | Change to control file directory | `$ORACLE_BASE/oradata/$ORACLE_SID` |
| `cdd`  | Change to diagnostic dest        | `$ORADBA_ORA_DIAG_SID`             |
| `cddt` | Change to trace directory        | `diagnostic_dest/trace`            |
| `cdda` | Change to alert directory        | `diagnostic_dest/alert`            |

```bash
# Navigate to trace directory and ORACLE_HOME
cddt && pwd   # /u01/app/oracle/diag/rdbms/free/FREE/trace
cdh  && pwd   # /u01/app/oracle/product/19.0.0/dbhome_1
```

### Convenience Variables {#convenience-variables}

The same names also work as shell variables — useful in one-liners and scripts:

| Variable | Description          | Value                   |
|----------|----------------------|-------------------------|
| `$cdh`   | ORACLE_HOME path     | `$ORACLE_HOME`          |
| `$cdob`  | ORACLE_BASE path     | `$ORACLE_BASE`          |
| `$cda`   | Admin directory path | `$ORADBA_ORA_ADMIN_SID` |
| `$cdd`   | Diagnostic dest path | `$ORADBA_ORA_DIAG_SID`  |
| `$etc`   | OraDBA etc path      | `$ORADBA_ETC`           |
| `$log`   | OraDBA log path      | `$ORADBA_LOG`           |

```bash
ls -l $etc/*.conf
vi $cda/pfile/init${ORACLE_SID}.ora
```

## Database Operations and Diagnostics

### Status and Monitoring

| Alias         | Description                     | Command               |
|---------------|---------------------------------|-----------------------|
| `oraup` / `u` | Oracle environment overview     | `oraup.sh`            |
| `sta`         | Database status                 | `dbstatus.sh`         |
| `pmon`        | Show running database processes | `ps -ef \| grep pmon` |

: Database Status and Monitoring Aliases

**`oraup.sh`** displays all databases from oratab, their status (OPEN/MOUNTED/NOMOUNT/DOWN),
listener status, Oracle Home paths, and startup flags.

### Listener Commands

| Alias    | Description                    | Command          |
|----------|--------------------------------|------------------|
| `lsnr`   | Listener control               | `lsnrctl`        |
| `lsnrh`  | Listener control (with rlwrap) | `rlwrap lsnrctl` |
| `lstat`  | Listener status                | `lsnrctl status` |
| `lstart` | Start listener                 | `lsnrctl start`  |
| `lstop`  | Stop listener                  | `lsnrctl stop`   |

: Listener Control Aliases

### Configuration Viewing

| Alias    | Description          | Command                       |
|----------|----------------------|-------------------------------|
| `oratab` | Display oratab file  | `cat /etc/oratab`             |
| `tns`    | Display tnsnames.ora | `cat $TNS_ADMIN/tnsnames.ora` |

### File Editing

#### Oracle Configuration Files

| Alias    | Description       | Target File               |
|----------|-------------------|---------------------------|
| `vio`    | Edit oratab       | `/etc/oratab`             |
| `vit`    | Edit tnsnames.ora | `$TNS_ADMIN/tnsnames.ora` |
| `vil`    | Edit listener.ora | `$TNS_ADMIN/listener.ora` |
| `visql`  | Edit sqlnet.ora   | `$TNS_ADMIN/sqlnet.ora`   |
| `vildap` | Edit ldap.ora     | `$TNS_ADMIN/ldap.ora`     |

: Oracle Configuration File Editing Aliases

#### OraDBA Configuration Files

| Alias | Description          | Target File                        |
|-------|----------------------|------------------------------------|
| `vis` | Edit standard config | `$ORADBA_ETC/oradba_standard.conf` |
| `vic` | Edit customer config | `$ORADBA_ETC/oradba_customer.conf` |
| `vii` | Edit SID config      | `$ORADBA_ETC/sid.$ORACLE_SID.conf` |

### Alert Log and Diagnostics

| Alias    | Description             | Command                              |
|----------|-------------------------|--------------------------------------|
| `taa`    | Tail alert log (follow) | `tail -f -n 50 $ORADBA_SID_ALERTLOG` |
| `vaa`    | View alert log (less)   | `less $ORADBA_SID_ALERTLOG`          |
| `via`    | Edit alert log (vi)     | `vi $ORADBA_SID_ALERTLOG`            |
| `adrcih` | ADRCI with rlwrap       | `rlwrap adrci`                       |

These aliases point to the standard text alert log (`alert_$ORACLE_SID.log`), not the XML version.

```bash
# Watch alert log in real-time
taa

# Interactive ADRCI with command history
adrcih
ADRCI> show alert -tail 50
```

### Information Display

| Alias | Description                  | Function       |
|-------|------------------------------|----------------|
| `sqa` | Show SQLPATH directories     | `show_sqlpath` |
| `pth` | Show PATH directories        | `show_path`    |
| `cfg` | Show OraDBA config hierarchy | `show_config`  |

`cfg` displays the 5-level configuration hierarchy and load order, with `[[OK] loaded]`,
`[[X] MISSING - REQUIRED]`, and `[- not configured]` indicators. Use these aliases to
troubleshoot missing PATH/SQLPATH directories and configuration precedence issues.

### Help and Utility Aliases

| Alias       | Description              | Command                                  |
|-------------|--------------------------|------------------------------------------|
| `alih`      | Display alias help       | `cat $ORADBA_PREFIX/doc/alias_help.txt`  |
| `alig`      | Search aliases           | `alias \| grep -i`                       |
| `version`   | Show OraDBA version      | `oradba_version.sh -i`                   |
| `c`         | Clear screen             | `clear`                                  |
| `l`         | List all (long format)   | `ls -al`                                 |
| `ll`        | List all (detailed)      | `ls -alb`                                |
| `lr`        | List reverse time order  | `ls -ltr`                                |
| `lsl`       | List recent 20 files     | `ls -lrt \| tail -n 20`                  |
| `psg`       | Search processes         | `ps -ef \| grep`                         |
| `save_cron` | Backup crontab           | `crontab -l > ~/crontab.txt.$(date)`     |

## PDB Aliases

OraDBA automatically generates aliases for Pluggable Databases (PDBs) in Oracle Multitenant
environments, providing quick SYSDBA connections to each PDB without typing long SQL commands.

### How It Works

When you source `oraenv.sh` for a CDB, OraDBA:

1. Checks if the database is a CDB (`v$database.cdb = 'YES'`)
2. Queries `v$pdbs` for all PDBs (excluding `PDB$SEED`)
3. Creates two aliases for each PDB and exports `ORADBA_PDBLIST`

This happens automatically unless `ORADBA_NO_PDB_ALIASES=true`.

### Generated Aliases

For each PDB (e.g., `PDB1`) two aliases are created:

```bash
# Simple alias — lowercase PDB name
alias pdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"

# Prefixed alias — same with 'pdb' prefix for clarity
alias pdbpdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

Aliases are always lowercase regardless of PDB name case.

### Key Variables

| Variable               | Description                              |
|------------------------|------------------------------------------|
| `ORADBA_PDBLIST`       | Space-separated list of PDBs in the CDB  |
| `ORADBA_PDB`           | Currently selected PDB (set by alias)    |
| `ORADBA_NO_PDB_ALIASES`| Set `true` to disable alias generation   |

`ORADBA_PDB` is also used by the PS1 prompt customisation, which shows `[CDB1.PDB1]` after
connecting to a PDB (requires `ORADBA_CUSTOMIZE_PS1=true`, the default).

### Basic Usage

```bash
# Source CDB environment
source oraenv.sh CDB1

# Check available PDBs
echo $ORADBA_PDBLIST    # PDB1 PDB2 TESTPDB

# Connect to PDB1
pdb1
SQL> SHOW CON_NAME      # PDB1

# Switch to PDB2
pdb2
SQL> SHOW CON_NAME      # PDB2
```

### Configuration (Enable / Disable)

PDB aliases are enabled by default. To disable:

```bash
# Globally — in oradba_customer.conf
export ORADBA_NO_PDB_ALIASES="true"

# Per CDB — in sid.CDB1.conf
export ORADBA_NO_PDB_ALIASES="true"
```

Re-enable by removing the setting or setting it to `false`, then re-sourcing `oraenv.sh`.

PDB aliases are generated at environment load time. After creating or dropping PDBs, reload:

```bash
source oraenv.sh CDB1
echo $ORADBA_PDBLIST    # updated list
```

### Limitations

- Requires database access to query `v$pdbs` (must be OPEN READ WRITE)
- Requires SYSDBA privileges
- Static — not updated dynamically; reload after PDB changes
- Alias names conflict with existing aliases: existing alias takes precedence
- Only works for CDB databases; non-CDB databases produce no PDB aliases

**Security note:** PDB aliases use OS authentication (`/ as sysdba`), which has full CDB
privileges. In production environments consider disabling automatic PDB aliases
(`ORADBA_NO_PDB_ALIASES=true`) and using proper connection strings with Oracle Wallet or
dedicated PDB accounts.

## rlwrap Integration

[rlwrap](https://github.com/hanslub42/rlwrap) (readline wrapper) adds command-line history,
tab completion, and line editing to programs that do not natively support them. OraDBA
automatically uses rlwrap with SQL*Plus, RMAN, lsnrctl, and ADRCI when it is installed.

### Completion Files

OraDBA ships completion word lists for tool-specific tab completion:

| File                         | Covers                                               |
|------------------------------|------------------------------------------------------|
| `rlwrap_sqlplus_completions` | SQL commands, SET/SHOW parameters, views, privileges |
| `rlwrap_rman_completions`    | Backup/restore commands and keywords                 |
| `rlwrap_lsnrctl_completions` | Listener commands and parameters                     |
| `rlwrap_adrci_completions`   | Diagnostic commands                                  |

### Installing rlwrap

```bash
# RHEL / Oracle Linux / CentOS
sudo yum install rlwrap

# Ubuntu / Debian
sudo apt-get install rlwrap

# macOS
brew install rlwrap
```

When rlwrap is not installed the `sqh`, `rmanh`, `rmanch`, `lsnrh`, and `adrcih` aliases
fall back gracefully (they simply invoke the underlying tool without rlwrap).

### Password Filtering

Password filtering removes sensitive information from rlwrap history files, so plain-text
passwords do not appear in `~/.sqlplus_history` or `~/.rman_history`.

**Example — what gets saved in history:**

```sql
-- Input:                            -- Saved as:
CONNECT scott/tiger@orcl          →  CONNECT scott/@orcl
CREATE USER u IDENTIFIED BY pass; →  CREATE USER u IDENTIFIED BY ***FILTERED***;
ALTER USER u IDENTIFIED BY pass;  →  ALTER USER u IDENTIFIED BY ***FILTERED***;
```

**RMAN:**

```rman
CONNECT TARGET user/password@db   →  CONNECT TARGET user/@db
CONNECT CATALOG rman/pass@cat     →  CONNECT CATALOG rman/@cat
```

#### Enable Password Filtering

**Requirements:** rlwrap installed + Perl `RlwrapFilter` module.

```bash
# Check Perl module
perl -MRlwrapFilter -e 'print "OK\n"'

# Install Perl module if missing
sudo cpan RlwrapFilter
# or on Debian/Ubuntu:
sudo apt-get install libterm-readline-gnu-perl
```

Enable in `oradba_customer.conf` (global) or `sid.<SID>.conf` (per database):

```bash
export ORADBA_RLWRAP_FILTER="true"
```

Reload the environment and verify:

```bash
source oraenv.sh FREE
type sqh    # should include: -z ".../rlwrap_filter_oracle"
```

**Affected aliases when `ORADBA_RLWRAP_FILTER=true`:** `sqh`, `sqlplush`, `sqoh`, `rmanh`,
`rmanch`, `adrcih`.

To disable filtering, set `ORADBA_RLWRAP_FILTER="false"` or unset the variable and reload.
Aliases continue using rlwrap for history/completion — only the password filter is removed.

**Security note:** The filter catches common patterns but may miss edge cases. It does not
retroactively clean existing history files. For production environments, Oracle Wallet or
OS/Kerberos authentication are preferred over relying solely on password filtering.

## Custom Aliases and Configuration

### Custom Aliases

Add personal aliases and functions in `oradba_customer.conf`:

```bash
# Custom SQL*Plus connections
alias sqdev='sqlplus user/pass@devdb'
alias sqtest='sqlplus user/pass@testdb'

# Custom directory shortcuts
alias cdarch='cd /backup/oracle/archive'
alias cdbkp='cd /backup/oracle'

# Custom RMAN shortcuts
alias fullbackup='rman target / cmdfile=${ORADBA_PREFIX}/rcv/backup_full.rman'

# Custom shell function
backup_config() {
    local backup_dir="/backup/config/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    cp ${ORADBA_ETC}/*.conf "$backup_dir/"
    echo "Configuration backed up to: $backup_dir"
}
```

### Dynamic Alias Generation

When you source `oraenv.sh`, the `generate_sid_aliases()` function:

1. Queries the database for the `diagnostic_dest` parameter
2. Generates SID-specific aliases (`taa`, `vaa`, `via`, `cda`, `cdd`, `cddt`, `cdda`)
3. Falls back to convention-based paths if the database is unavailable

```bash
$ source oraenv.sh FREE
$ echo $ORADBA_SID_ALERTLOG
/u01/app/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log
$ cddt && pwd
/u01/app/oracle/diag/rdbms/free/FREE/trace
```

### Enable / Disable All Aliases

Control alias loading in `oradba_core.conf` (or override in `oradba_customer.conf`):

```bash
# Enable (default)
ORADBA_LOAD_ALIASES="true"

# Disable all aliases
ORADBA_LOAD_ALIASES="false"
```

To disable or redefine a specific alias, add to `oradba_customer.conf`:

```bash
unalias sq
# or redefine:
alias sq='echo "Use sqh instead"'
```

**Best practices:**

- Learn the essentials first: `sq`/`sqh`, `cdh`, `taa`, `oraup`
- Use rlwrap aliases (`sqh`, `rmanh`) for command history in interactive sessions
- Customise in `oradba_customer.conf` — never edit the core alias file directly
- Use `type alias_name` to inspect what an alias expands to
- Comment your custom aliases so future you remembers why they exist

## Troubleshooting

### Aliases Not Loading

```bash
# Check if aliases are enabled
echo $ORADBA_LOAD_ALIASES      # should be: true

# Enable debug mode when sourcing
DEBUG=1 source oraenv.sh FREE

# Verify the alias library exists
ls -l ${ORADBA_PREFIX}/lib/oradba_aliases.sh
```

### Dynamic / SID-Specific Aliases Not Generated

```bash
# Confirm ORACLE_SID is set
echo $ORACLE_SID

# Confirm database is accessible
sqlplus -S / as sysdba <<< "SELECT instance_name FROM v\$instance;"

# Check diagnostic_dest (needed for taa/vaa/cdd/cddt)
sqlplus -S / as sysdba <<< "SHOW PARAMETER diagnostic_dest"
```

### PDB Aliases Missing

```bash
# Check whether generation is disabled
echo $ORADBA_NO_PDB_ALIASES    # must NOT be true

# Confirm CDB
sqlplus -s / as sysdba <<< "SELECT cdb FROM v\$database;"
# CDB must be YES

# Confirm database is open READ WRITE
sqlplus -s / as sysdba <<< "SELECT open_mode FROM v\$database;"

# Check for PDBs (excluding seed)
sqlplus -s / as sysdba <<< "SELECT name FROM v\$pdbs WHERE name != 'PDB\$SEED';"

# Reload environment after creating new PDBs
source oraenv.sh CDB1
echo $ORADBA_PDBLIST
```

### PDB Alias Not Working

```bash
# Verify the alias was created
type pdb1

# Manual test — should succeed if PDB is accessible
sqlplus / as sysdba <<< "ALTER SESSION SET CONTAINER=PDB1;"

# Check PDB open mode
sqlplus -s / as sysdba <<< "SELECT name, open_mode FROM v\$pdbs WHERE name='PDB1';"
```

### rlwrap Not Working

```bash
# Check installation
which rlwrap         # should show /usr/bin/rlwrap or similar

# Check current configuration
echo $RLWRAP_COMMAND
echo $RLWRAP_OPTS

# Test directly
rlwrap -i -c sqlplus / as sysdba
```

### Password Filter Not Working

```bash
# Check filter is enabled
echo $ORADBA_RLWRAP_FILTER     # should be: true

# Verify alias includes filter option
type sqh   # should include: -z ".../rlwrap_filter_oracle"

# Check filter script exists and is executable
ls -l /opt/oradba/etc/rlwrap_filter_oracle

# Check Perl module
perl -MRlwrapFilter -e 'print "OK\n"'
```

**If history still shows passwords:**

1. Ensure `ORADBA_RLWRAP_FILTER=true` and reload the environment
2. Use `sqh`/`rmanh`, not `sq`/`rman` (unfiltered aliases bypass rlwrap entirely)
3. The filter does not retroactively clean existing history — back up and remove old files:

```bash
mv ~/.sqlplus_history ~/.sqlplus_history.bak
mv ~/.rman_history    ~/.rman_history.bak
```

For a quick alias reference card at any time, run `alih`.

<!-- Web-only sections below: kept for MkDocs navigation, stripped during PDF build (build_pdf.sh). -->
## See Also {.unlisted .unnumbered}

- [Configuration](configuration.md) - Customising OraDBA settings
- [Environment Management](environment.md) - How aliases are loaded at environment set
- [SQL Scripts](sql-scripts.md) - SQL scripts available via SQLPATH
- [Quick Start](quickstart.md) - Quick reference card

## Navigation {.unlisted .unnumbered}

**Previous:** [Configuration System](configuration.md)
**Next:** [SQL Scripts](sql-scripts.md)
