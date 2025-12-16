# OraDBA Shell Aliases

OraDBA provides a comprehensive set of shell aliases to streamline Oracle
database administration tasks. Aliases are automatically loaded when you set your
Oracle environment using `oraenv.sh`.

## Quick Reference

### SQL*Plus Aliases

| Alias        | Description                                    | Command                       |
|--------------|------------------------------------------------|-------------------------------|
| `sq`         | SQL*Plus as SYSDBA (basic)                     | `sqlplus / as sysdba`         |
| `sqh`        | SQL*Plus as SYSDBA (with rlwrap if available)  | `rlwrap sqlplus / as sysdba`  |
| `sqlplush`   | SQL*Plus as SYSDBA (with rlwrap if available)  | `rlwrap sqlplus / as sysdba`  |
| `sqoh`       | SQL*Plus as SYSOPER (with rlwrap if available) | `rlwrap sqlplus / as sysoper` |
| `sessionsql` | SQL*Plus with dynamic terminal width detection | `sessionsql.sh`               |

**Note:** When `ORADBA_RLWRAP_FILTER=true`, aliases with rlwrap (sqh, sqlplush, sqoh)
use password filtering to hide passwords from command history. See [RLWRAP_FILTER.md](RLWRAP_FILTER.md)
for details.

**sessionsql** automatically detects your terminal width using `tput` and configures SQL*Plus
LINESIZE and PAGESIZE accordingly. This ensures optimal output formatting for your current terminal size.

### RMAN Aliases

| Alias    | Description                                 | Command                        |
|----------|---------------------------------------------|--------------------------------|
| `rman`   | RMAN with target connection                 | `rman target /`                |
| `rmanc`  | RMAN with target and catalog                | `rman target / catalog`        |
| `rmanh`  | RMAN with target (with rlwrap if available) | `rlwrap rman target /`         |
| `rmanch` | RMAN with target and catalog (with rlwrap)  | `rlwrap rman target / catalog` |

**Note:** When `ORADBA_RLWRAP_FILTER=true`, aliases with rlwrap (rmanh, rmanch) use password
filtering. See [RLWRAP_FILTER.md](RLWRAP_FILTER.md) for details.

### Directory Navigation Aliases

#### Oracle Directories

| Alias  | Description                         | Target Directory                             |
|--------|-------------------------------------|----------------------------------------------|
| `cdob` | Change to ORACLE_BASE               | `$ORACLE_BASE`                               |
| `cdh`  | Change to ORACLE_HOME               | `$ORACLE_HOME`                               |
| `cdbn` | Change to ORACLE_HOME/bin           | `$ORACLE_HOME/bin`                           |
| `cdn`  | Change to TNS_ADMIN parent          | `$TNS_ADMIN/..` or `$ORACLE_HOME/network`    |
| `cdt`  | Change to TNS_ADMIN                 | `$TNS_ADMIN` or `$ORACLE_HOME/network/admin` |

#### OraDBA Directories

| Alias   | Description                    | Target Directory       |
|---------|--------------------------------|------------------------|
| `cdb`   | Change to OraDBA base          | `$ORADBA_PREFIX`       |
| `cde`   | Change to OraDBA etc           | `$ORADBA_ETC`          |
| `etc`   | Change to OraDBA etc           | `$ORADBA_ETC`          |
| `cdr`   | Change to OraDBA rcv           | `$ORADBA_RCV`          |
| `cdlog` | Change to OraDBA log           | `$ORADBA_LOG`          |
| `log`   | Change to OraDBA log           | `$ORADBA_LOG`          |
| `cdtmp` | Change to OraDBA tmp           | `$ORADBA_TMP`          |
| `cdl`   | Change to ORACLE_BASE/local    | `$ORACLE_BASE/local`   |

### Database Operations Aliases

| Alias    | Description                     | Command                       |
|----------|---------------------------------|-------------------------------|
| `lstat`  | Listener status                 | `lsnrctl status`              |
| `lstart` | Start listener                  | `lsnrctl start`               |
| `lstop`  | Stop listener                   | `lsnrctl stop`                |
| `pmon`   | Show running database processes | `ps -ef \| grep pmon`         |
| `oratab` | Display oratab file             | `cat /etc/oratab`             |
| `tns`    | Display tnsnames.ora            | `cat $TNS_ADMIN/tnsnames.ora` |

### VI Editor Aliases

| Alias    | Description                 | Command                               |
|----------|-----------------------------|---------------------------------------|
| `vio`    | Edit oratab file            | `vi /etc/oratab`                      |
| `vit`    | Edit tnsnames.ora           | `vi $TNS_ADMIN/tnsnames.ora`          |
| `vil`    | Edit listener.ora           | `vi $TNS_ADMIN/listener.ora`          |
| `visql`  | Edit sqlnet.ora             | `vi $TNS_ADMIN/sqlnet.ora`            |
| `vildap` | Edit ldap.ora               | `vi $TNS_ADMIN/ldap.ora`              |
| `vis`    | Edit OraDBA standard config | `vi $ORADBA_ETC/oradba_standard.conf` |
| `vic`    | Edit OraDBA customer config | `vi $ORADBA_ETC/oradba_customer.conf` |
| `vii`    | Edit OraDBA SID config      | `vi $ORADBA_ETC/sid.$ORACLE_SID.conf` |
| `via`    | Edit alert log              | `vi` alert log (dynamic)              |

### Convenience Variables

These short variables can be used with `cd` or other commands:

| Variable | Description               | Value                        |
|----------|---------------------------|------------------------------|
| `$cdh`   | ORACLE_HOME path          | `$ORACLE_HOME`               |
| `$cda`   | Admin directory path      | `$ORADBA_ORA_ADMIN_SID`      |
| `$cdob`  | ORACLE_BASE path          | `$ORACLE_BASE`               |
| `$cdl`   | Local directory path      | `$ORACLE_BASE/local`         |
| `$cdd`   | Diagnostic dest path      | `$ORADBA_ORA_DIAG_SID`       |
| `$etc`   | OraDBA etc path           | `$ORADBA_ETC`                |
| `$log`   | OraDBA log path           | `$ORADBA_LOG`                |
| `$cdn`   | Network admin parent path | `$TNS_ADMIN/..`              |

**Example usage:**

```bash
cd $cdh/bin       # Navigate to ORACLE_HOME/bin
ls -l $cda        # List admin directory
vi $etc/oradba_customer.conf  # Edit customer config
```

### SID-Specific Dynamic Aliases

These aliases are generated dynamically based on the current `ORACLE_SID` and diagnostic_dest location:

| Alias  | Description               | Dynamic Path Example                                               |
|--------|---------------------------|--------------------------------------------------------------------|
| `cda`  | Change to admin directory | `$ORADBA_ORA_ADMIN_SID` (e.g., `$ORACLE_BASE/admin/ORCL`)          |
| `cdc`  | Change to control files   | `$ORADBA_ORA_CONTROL` (e.g., `$ORACLE_BASE/oradata/ORCL`)          |
| `cdd`  | Change to diagnostic dest | `$ORADBA_ORA_DIAG_SID` (e.g., `$ORACLE_BASE/diag/rdbms/orcl/ORCL`) |
| `cddt` | Change to trace directory | `diagnostic_dest/trace`                                            |
| `cdda` | Change to alert directory | `diagnostic_dest/alert`                                            |
| `taa`  | Tail alert log            | `tail -f` alert log (log.xml or alert_SID.log)                     |
| `vaa`  | View alert log with less  | `less` alert log (log.xml or alert_SID.log)                        |
| `via`  | Edit alert log with vi    | `vi` alert log (log.xml or alert_SID.log)                          |

### PDB Aliases (Multitenant)

For Container Databases (CDB), OraDBA automatically generates aliases for each Pluggable Database:

| Alias Type | Example   | Description                                    |
|------------|-----------|------------------------------------------------|
| Simple     | `pdb1`    | Connect to PDB1, set ORADBA_PDB, alter session |
| Prefixed   | `pdbpdb1` | Same as simple, with 'pdb' prefix for clarity  |

**Generated for each PDB:**

```bash
# For PDB named "PDB1"
alias pdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
alias pdbpdb1="export ORADBA_PDB='PDB1'; sqlplus / as sysdba <<< 'ALTER SESSION SET CONTAINER=PDB1;'"
```

**Usage:**

```bash
# List available PDBs
echo $ORADBA_PDBLIST

# Connect to a PDB
pdb1

# Prompt shows: [CDB1.PDB1]
```

**Configuration:**

```bash
# Disable PDB aliases (in oradba_customer.conf or sid.*.conf)
export ORADBA_NO_PDB_ALIASES="true"
```

See [PDB_ALIASES.md](PDB_ALIASES.md) for complete documentation.

### Help and Information

| Alias     | Description              | Command                                           |
|-----------|--------------------------|---------------------------------------------------|
| `alih`    | Display alias help       | `cat $ORADBA_PREFIX/doc/ALIAS_HELP.txt`           |
| `alig`    | List all current aliases | `alias \| grep -E '^(cd\|sq\|rm\|via\|taa\|vaa)'` |
| `version` | Show OraDBA version      | `oradba_version.sh`                               |

## Configuration

### Enabling/Disabling Aliases

Aliases are loaded by default. To disable them, set the following in [oradba_core.conf](../etc/oradba_core.conf):

```bash
ORADBA_LOAD_ALIASES="false"
```

### Custom Aliases

You can add custom aliases in [oradba_customer.conf](../etc/oradba_customer.conf.example):

```bash
# Custom SQL*Plus alias with connection string
alias sqdev='sqlplus user/pass@dev'

# Custom directory alias
alias cdarch='cd /backup/oracle/archive'

# Custom backup alias
alias fullbackup='rman target / cmdfile=${ORADBA_PREFIX}/rcv/backup_full.rman'
```

## rlwrap Integration

OraDBA automatically uses [rlwrap](https://github.com/hanslub42/rlwrap) with SQL*Plus if it's available, providing:

- Command history (up/down arrows)
- Tab completion
- Editing capabilities

If rlwrap is not installed, the aliases fall back to standard SQL*Plus without these features.

### Installing rlwrap

**macOS:**

```bash
brew install rlwrap
```

**Linux (RHEL/OL/CentOS):**

```bash
sudo yum install rlwrap
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt-get install rlwrap
```

## Dynamic Alias Generation

### How It Works

When you set your Oracle environment using `oraenv.sh`, the `generate_sid_aliases()`
function in [aliases.sh](../lib/aliases.sh) automatically:

1. Queries the database for `diagnostic_dest` parameter (or uses convention-based path as fallback)
2. Generates SID-specific aliases for trace and alert log access
3. Creates directory navigation aliases based on the actual paths

### Example

```bash
$ source oraenv.sh ORCL
Setting Oracle environment for ORCL...
Oracle environment set successfully.

$ type taa
taa is aliased to `tail -f /u01/app/oracle/diag/rdbms/orcl/ORCL/alert/log.xml'

$ cddt  # Change to trace directory
$ pwd
/u01/app/oracle/diag/rdbms/orcl/ORCL/trace

$ cd $cdh/bin  # Using convenience variable
$ pwd
/u01/app/oracle/product/19.0.0/dbhome_1/bin
```

## Alias Categories

### 1. Simple Aliases

Defined in [oradba_standard.conf](../etc/oradba_standard.conf), these are static aliases that don't change based on context:

- SQL*Plus and RMAN connection shortcuts
- Basic directory navigation (ORACLE_HOME, ORACLE_BASE, etc.)
- Listener commands
- Configuration file viewing

### 2. Dynamic Aliases

Generated by functions in [aliases.sh](../lib/aliases.sh), these adapt to the current ORACLE_SID:

- Trace and alert log access (paths vary by SID)
- Diagnostic directory navigation (based on diagnostic_dest)
- rlwrap integration (conditional on availability)

## Troubleshooting

### Aliases Not Loading

1. Check if aliases are enabled:

   ```bash
   echo $ORADBA_LOAD_ALIASES
   ```

2. Verify aliases.sh exists:

   ```bash
   ls -l ${ORADBA_PREFIX}/lib/aliases.sh
   ```

3. Check debug output:

   ```bash
   DEBUG=1 source oraenv.sh ORCL
   ```

### Dynamic Aliases Not Generated

1. Verify ORACLE_SID is set:

   ```bash
   echo $ORACLE_SID
   ```

2. Check if database is accessible:

   ```bash
   sqlplus -S / as sysdba <<< "SELECT instance_name FROM v\$instance;"
   ```

3. Check diagnostic_dest parameter:

   ```bash
   sqlplus -S / as sysdba <<< "SHOW PARAMETER diagnostic_dest"
   ```

### rlwrap Not Working

1. Check if rlwrap is installed:

   ```bash
   which rlwrap
   ```

2. Verify rlwrap configuration:

   ```bash
   echo $RLWRAP_COMMAND
   echo $RLWRAP_OPTS
   ```

3. Test rlwrap directly:

   ```bash
   rlwrap -i -c -f $ORACLE_HOME/bin/sqlplus sqlplus / as sysdba
   ```

## rlwrap and Password Security

### Password Filtering

OraDBA supports optional password filtering for rlwrap-enabled aliases. When enabled,
passwords are hidden from command history files.

**Enable password filtering:**

```bash
# In oradba_customer.conf or sid.*.conf
export ORADBA_RLWRAP_FILTER="true"
```

**Requirements:**

- rlwrap installed
- Perl with RlwrapFilter module (`cpan RlwrapFilter`)

**What gets filtered:**

- Password prompts (SQL*Plus, RMAN)
- CONNECT commands with embedded passwords
- CREATE/ALTER USER IDENTIFIED BY statements

**Example:**

```sql
-- Input:
CONNECT user/password@database

-- Saved in history as:
CONNECT user/@database
```

For complete documentation, see [RLWRAP_FILTER.md](RLWRAP_FILTER.md)

### Installing rlwrap

**RHEL/Oracle Linux:**

```bash
sudo yum install rlwrap
```

**Ubuntu/Debian:**

```bash
sudo apt-get install rlwrap
```

**macOS:**

```bash
brew install rlwrap
```

## See Also

- [Configuration Guide](CONFIGURATION.md) - Hierarchical configuration system
- [Usage Guide](USAGE.md) - Complete OraDBA usage documentation
- [Quick Start](../doc/QUICKSTART.md) - Getting started with OraDBA
