# RMAN Script Templates

**Purpose:** RMAN (Recovery Manager) script templates for common backup and recovery operations.

**Audience:** DBAs implementing backup strategies.

## Introduction

OraDBA includes RMAN (Recovery Manager) script templates for common backup and
recovery operations. These templates provide a starting point for database
backup strategies.

## RMAN Wrapper Script

### oradba_rman.sh

OraDBA provides a shell wrapper for executing RMAN scripts with enhanced features:

```bash
# Execute RMAN script for a single database
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Execute for multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 2

# Override default settings
oradba_rman.sh --sid FREE --rcv backup_full.rcv \
    --channels 4 \
    --compression HIGH \
    --format "/backup/%d_%T_%U.bkp" \
    --tag MONTHLY_BACKUP \
    --notify dba@example.com
```

**Features:**

- **Template Processing**: Dynamic substitution of `<ALLOCATE_CHANNELS>`, `<RELEASE_CHANNELS>`, 
  `<FORMAT>`, `<TAG>`, `<COMPRESSION>`, `<BACKUP_PATH>`, `<ORACLE_SID>`, `<START_DATE>` tags
- **Error Detection**: Checks for RMAN-00569 error pattern to catch failures (RMAN returns exit
  code 0 even on errors)
- **Parallel Execution**: Run RMAN for multiple SIDs concurrently (background jobs or GNU parallel)
- **Dual Logging**: Generic logs in `$ORADBA_LOG` + SID-specific logs in `$ORADBA_ORA_ADMIN_SID/log`
- **Script Preservation**: Automatically saves processed .rcv scripts to log directory for troubleshooting
- **Enhanced Dry-Run**: Saves and displays generated scripts, shows exact RMAN command
- **Cleanup Control**: Optional `--no-cleanup` flag preserves temp files for debugging
- **Email Notifications**: Send alerts on success/failure via mail or sendmail
- **Configuration**: SID-specific settings via `$ORADBA_ORA_ADMIN_SID/etc/oradba_rman.conf`

**Usage:**

```bash
oradba_rman.sh --sid <SID> --rcv <script.rcv> [OPTIONS]

Required Arguments:
  --sid SID[,SID,...]   Oracle SID(s), comma-separated for multiple
  --rcv SCRIPT          RMAN script file (.rcv extension)

Optional Arguments:
  --channels N          Number of parallel channels (default: from config)
  --format FORMAT       Backup format string (default: from config)
  --tag TAG             Backup tag (default: from config)
  --compression LEVEL   NONE|LOW|MEDIUM|HIGH (default: from config)
  --backup-path PATH    Backup destination path (default: from config)
  --catalog CONNECT     RMAN catalog connection string
  --notify EMAIL        Send notifications to email address
  --parallel N          Max parallel SID executions (default: 1)
  --dry-run             Show generated script and command without executing
  --no-cleanup          Keep temporary files after execution (for debugging)
  --verbose             Enable verbose output
  --help                Show detailed help
```

**Configuration:**

Create SID-specific configuration in `$ORADBA_ORA_ADMIN_SID/etc/oradba_rman.conf`:

```bash
# Copy example configuration
cp $ORADBA_PREFIX/etc/oradba_rman.conf.example \
   $ORADBA_ORA_ADMIN_SID/etc/oradba_rman.conf

# Edit configuration
export RMAN_CHANNELS=2
export RMAN_BACKUP_PATH="/backup/prod"    # If empty, uses Fast Recovery Area
export RMAN_FORMAT="%d_%T_%U.bkp"         # Filename pattern only (no path)
export RMAN_TAG="AUTO_BACKUP"
export RMAN_COMPRESSION="MEDIUM"
export RMAN_CATALOG=""
export RMAN_NOTIFY_EMAIL="dba@example.com"
export RMAN_NOTIFY_ON_SUCCESS=false
export RMAN_NOTIFY_ON_ERROR=true
```

**Important Configuration Notes:**

- **`RMAN_FORMAT`**: Contains only the filename pattern (e.g., `%d_%T_%U.bkp`)
  - Do NOT include the path in this variable
  - Variables: `%d` (database name), `%T` (timestamp), `%U` (unique identifier)
  
- **`RMAN_BACKUP_PATH`**: Contains only the directory path (e.g., `/backup/prod`)
  - If empty or not set:
    - RMAN backups use the Fast Recovery Area (FRA)
    - SQL-generated files (pfile, controlfile traces) use `${ORADBA_ORA_ADMIN_SID}/backup/`
  - The wrapper automatically combines path + format: `FORMAT '/backup/prod/DB_20260106_ABC.bkp'`
  - Trailing slash is handled automatically
  - Backup directory is created automatically if it doesn't exist

**Template Tags:**

RMAN scripts use template tags that are replaced at runtime:

- `<ALLOCATE_CHANNELS>`: Generates `ALLOCATE CHANNEL` commands based on `--channels`
- `<RELEASE_CHANNELS>`: Generates `RELEASE CHANNEL` commands matching allocated channels
- `<FORMAT>`: Substituted with `FORMAT` clause from `--format`
- `<TAG>`: Substituted with `TAG` clause from `--tag`
- `<COMPRESSION>`: Substituted with compression clause from `--compression`
- `<BACKUP_PATH>`: Substituted with backup path (includes trailing slash for easy path construction)
- `<ORACLE_SID>`: Substituted with current Oracle SID
- `<START_DATE>`: Substituted with timestamp in YYYYMMDD_HHMMSS format

**Examples:**

```bash
# Single database with defaults from config
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 3

# High compression backup with notification
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --compression HIGH \
    --notify dba-team@example.com

# Custom backup destination path
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --backup-path /backup/prod_daily \
    --format "DB_%d_%T_%U.bkp"

# Use Fast Recovery Area (no --backup-path specified)
# RMAN backups → FRA
# SQL files (pfile/traces) → ${ORADBA_ORA_ADMIN_SID}/backup/
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --format "%d_FULL_%T_%U.bkp"

# Dry run to test template processing (saves and displays script)
oradba_rman.sh --sid FREE --rcv backup_full.rcv --dry-run

# Keep temp files for troubleshooting
oradba_rman.sh --sid FREE --rcv backup_full.rcv --no-cleanup

# Custom format and tag
oradba_rman.sh --sid FREE --rcv backup_full.rcv \
    --backup-path /backup/monthly \
    --format "MONTHLY_%d_%T_%U.bkp" \
    --tag MONTHLY_FULL_20260102
```

**Troubleshooting:**

When RMAN execution fails, the wrapper automatically saves the processed script
for analysis:

```bash
# Check RMAN log
cat /u01/admin/FREE/log/backup_full_20260105_143022.log

# Examine processed RMAN script (template tags resolved)
cat /u01/admin/FREE/log/backup_full_20260105_143022.rcv

# Keep temp directory for debugging
oradba_rman.sh --sid FREE --rcv backup_full.rcv --no-cleanup
# Temp files preserved in: /tmp/oradba_rman_20260105_143022/
```

## Location

```bash
# RMAN scripts location
echo $ORADBA_PREFIX/rcv
# Output: /opt/oradba/rcv

# Navigate to RMAN directory
cd $ORADBA_PREFIX/rcv
# Or use alias
cdr
```

## Available Scripts

### backup_full.rcv

Full database backup template with dynamic substitution:

```bash
# Using wrapper script (recommended)
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Direct execution with RMAN (static values)
rman target / @$ORADBA_PREFIX/rcv/backup_full.rcv

# Or using alias
rman
RMAN> @backup_full.rcv
```

**What it does:**

- Connects to target database
- Performs full database backup
- Includes all datafiles
- Includes control file
- Includes SPFILE
- Archives current redo logs

**Template Tags:**

The script uses template tags that are dynamically replaced:

- `<ALLOCATE_CHANNELS>`: Replaced with channel allocation commands
- `<RELEASE_CHANNELS>`: Replaced with channel release commands (matches allocated channels)
- `<FORMAT>`: Replaced with FORMAT clause
- `<TAG>`: Replaced with TAG clause  
- `<COMPRESSION>`: Replaced with compression clause
- `<BACKUP_PATH>`: Replaced with backup path (with trailing slash)
- `<ORACLE_SID>`: Replaced with current Oracle SID
- `<START_DATE>`: Replaced with timestamp (YYYYMMDD_HHMMSS)

**Customization:**

Option 1 - Use wrapper script with command-line arguments:

```bash
oradba_rman.sh --sid FREE --rcv backup_full.rcv \
    --channels 4 --compression HIGH --format "/backup/%d_%T_%U.bkp"
```

Option 2 - Configure defaults in `$ORADBA_ORA_ADMIN_SID/etc/oradba_rman.conf`

Option 3 - Copy and edit the .rcv file directly for static values

### Using Template Tags in SQL Commands

The template tags can be used in SQL commands within RMAN scripts for creating
additional backup files with dynamic naming:

```rman
RUN {
<ALLOCATE_CHANNELS>
    
    # Backup database
    BACKUP <COMPRESSION> DATABASE <FORMAT> <TAG>;
    
    # Create text versions for documentation
    sql "create pfile=''<BACKUP_PATH>init_<ORACLE_SID>_<START_DATE>.ora'' from spfile";
    sql "alter database backup controlfile to ''<BACKUP_PATH>controlfile_<ORACLE_SID>_<START_DATE>.ctl''";
    sql "alter database backup controlfile to trace as ''<BACKUP_PATH>cre_controlfile_<ORACLE_SID>_<START_DATE>.sql''";
    
<RELEASE_CHANNELS>
}
```

**Example processed output** (when `--sid FREE --backup-path /backup/prod` is used):

```sql
sql "create pfile=''/backup/prod/init_FREE_20260106_143022.ora'' from spfile";
sql "alter database backup controlfile to ''/backup/prod/controlfile_FREE_20260106_143022.ctl''";
sql "alter database backup controlfile to trace as ''/backup/prod/cre_controlfile_FREE_20260106_143022.sql''";
```

**Example processed output** (when `--sid FREE` without `--backup-path`):

```sql
sql "create pfile=''/u01/admin/FREE/backup/init_FREE_20260106_143022.ora'' from spfile";
sql "alter database backup controlfile to ''/u01/admin/FREE/backup/controlfile_FREE_20260106_143022.ctl''";
sql "alter database backup controlfile to trace as ''/u01/admin/FREE/backup/cre_controlfile_FREE_20260106_143022.sql''";
```

**Benefits:**
- Automatic timestamp in filenames prevents overwrites
- SID-specific naming for multi-database environments
- Flexible path construction with `<BACKUP_PATH>` (includes trailing slash)
- Consistent naming across all backup artifacts
- When no path specified: RMAN uses FRA, text files go to `${ORADBA_ORA_ADMIN_SID}/backup/`

## Using RMAN with OraDBA

### Basic RMAN Usage

```bash
# Set environment
source oraenv.sh FREE

# Connect to RMAN
rman target /

# Or with command history (rlwrap)
rmanh

# Run script
RMAN> @backup_full.rman
```

### RMAN with Catalog

```bash
# Configure catalog connection in oradba_customer.conf
export ORADBA_RMAN_CATALOG="catalog rman/password@catdb"

# Connect with catalog
rmanc

# Or with rlwrap
rmanch
```

### Run RMAN Script from Shell

```bash
# Using wrapper script (recommended)
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Direct RMAN execution
rman target / @$ORADBA_PREFIX/rcv/backup_full.rcv

# With logging (direct execution)
rman target / @$ORADBA_PREFIX/rcv/backup_full.rcv log=/tmp/backup.log

# Wrapper provides automatic dual logging:
# - $ORADBA_LOG/oradba_rman_TIMESTAMP.log (wrapper log)
# - $ORADBA_ORA_ADMIN_SID/log/backup_full_TIMESTAMP.log (RMAN output)
```

## Creating Custom RMAN Scripts

### Script Template

**Static RMAN Script (.rman):**

```rman
# ------------------------------------------------------------------------------
# Script......: my_backup.rman
# Author......: Your Name
# Date........: YYYY-MM-DD
# Purpose.....: Brief description
# Usage.......: rman target / @my_backup.rman
# ------------------------------------------------------------------------------

CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE RETENTION POLICY TO REDUNDANCY 2;

RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL ch2 DEVICE TYPE DISK;
    BACKUP AS COMPRESSED BACKUPSET 
        DATABASE 
        FORMAT '/backup/%d_%T_%U.bkp'
        TAG 'FULL_BACKUP';
    BACKUP CURRENT CONTROLFILE 
        FORMAT '/backup/ctrl_%d_%T_%U.ctl';
    BACKUP SPFILE 
        FORMAT '/backup/spfile_%d_%T_%U.ora';
    RELEASE CHANNEL ch1;
    RELEASE CHANNEL ch2;
}
```

**Template RMAN Script (.rcv) - Recommended:**

```rman
# ------------------------------------------------------------------------------
# Script......: my_backup.rcv
# Author......: Your Name
# Date........: YYYY-MM-DD
# Purpose.....: Brief description with template support
# Usage.......: oradba_rman.sh --sid DB01 --rcv my_backup.rcv
# ------------------------------------------------------------------------------

SHOW ALL;

RUN {
    # Allocate channels dynamically
<ALLOCATE_CHANNELS>
    
    # Full database backup with dynamic settings
    BACKUP <COMPRESSION>
        DATABASE 
        <FORMAT>
        <TAG>;
    
    # Backup controlfile and SPFILE
    BACKUP CURRENT CONTROLFILE <FORMAT> TAG 'CONTROLFILE';
    BACKUP SPFILE <FORMAT> TAG 'SPFILE';
    
    # Optional: Create text versions for documentation
    sql "create pfile=''<BACKUP_PATH>init_<ORACLE_SID>_<START_DATE>.ora'' from spfile";
    sql "alter database backup controlfile to trace as ''<BACKUP_PATH>cre_controlfile_<ORACLE_SID>_<START_DATE>.sql''";
    
    # Release channels dynamically
<RELEASE_CHANNELS>
}

# Maintenance
DELETE NOPROMPT OBSOLETE;
CROSSCHECK BACKUP;
LIST BACKUP SUMMARY;
```

### Best Practices

1. **Always test in development first**
2. **Use meaningful backup tags**
3. **Include control file and SPFILE**
4. **Configure retention policy**
5. **Enable controlfile autobackup**
6. **Use compression for disk backups**
7. **Verify backups after completion**
8. **Document backup strategy**
9. **Test recovery procedures regularly**
10. **Monitor backup job completion**

## Common RMAN Operations

### Full Database Backup

```rman
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
```

### Incremental Backup

```rman
RMAN> BACKUP INCREMENTAL LEVEL 1 DATABASE;
```

### Backup Specific Tablespace

```rman
RMAN> BACKUP TABLESPACE users, tools;
```

### List Backups

```rman
RMAN> LIST BACKUP SUMMARY;
RMAN> LIST BACKUP OF DATABASE;
```

### Validate Backup

```rman
RMAN> VALIDATE BACKUPSET <backup_set_number>;
RMAN> RESTORE DATABASE VALIDATE;
```

### Delete Obsolete Backups

```rman
RMAN> DELETE OBSOLETE;
RMAN> DELETE NOPROMPT OBSOLETE;
```

## Backup Strategy Examples

### Daily Incremental Strategy

```rman
# Sunday: Level 0 (full)
BACKUP INCREMENTAL LEVEL 0 DATABASE 
    TAG 'WEEKLY_FULL';

# Monday-Saturday: Level 1
BACKUP INCREMENTAL LEVEL 1 DATABASE 
    TAG 'DAILY_INCREMENTAL';
```

### Backup with Validation

```rman
RUN {
    BACKUP DATABASE;
    RESTORE DATABASE VALIDATE;
}
```

### Compressed Backup to Disk

```rman
BACKUP AS COMPRESSED BACKUPSET 
    DATABASE 
    FORMAT '/backup/%d_%T_%U.bkp';
```

## Troubleshooting

### RMAN Script Not Found

```bash
# Check script location
ls -l $ORADBA_PREFIX/rcv/*.rman

# Use full path
rman target / @/opt/oradba/rcv/backup_full.rman
```

### Backup Fails

```rman
# Check RMAN configuration
RMAN> SHOW ALL;

# Check backup destination space
RMAN> SHOW PARAMETER DB_RECOVERY_FILE_DEST;

# Verify controlfile autobackup
RMAN> SHOW CONTROLFILE AUTOBACKUP;
```

### Permission Issues

```bash
# Check backup directory permissions
ls -ld /backup

# Create directory if needed
mkdir -p /backup
chown oracle:oinstall /backup
```

## See Also

- [SQL Scripts](08-sql-scripts.md) - Database administration scripts
- [Functions](10-functions.md) - Database functions reference
- [Configuration](05-configuration.md) - Setting ORADBA_RMAN_CATALOG
- [Troubleshooting](12-troubleshooting.md) - RMAN issues

## Navigation

**Previous:** [SQL Scripts Reference](08-sql-scripts.md)  
**Next:** [Database Functions Library](10-functions.md)
