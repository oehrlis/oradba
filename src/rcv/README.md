# RMAN Scripts

Recovery Manager (RMAN) scripts for Oracle Database backup and recovery operations.

## Overview

This directory contains RMAN script templates for database backup, recovery, and
maintenance tasks. Scripts use RMAN command language with template tags for
dynamic substitution.

**Wrapper Script**: OraDBA provides `oradba_rman.sh` for executing RMAN scripts
with enhanced features like parallel execution, template processing, dual logging,
and email notifications.

**File Extensions**:

- `.rcv` - RMAN scripts with template tags (e.g., `<ALLOCATE_CHANNELS>`)
- `.rman` - Static RMAN scripts (legacy)

## Available Scripts

### Backup Scripts

| Script                                                     | Description                                          |
|------------------------------------------------------------|------------------------------------------------------|
| [backup_full.rcv](backup_full.rcv)                         | Full database backup with archive logs, maintenance  |
| [bck_arc.rcv](bck_arc.rcv)                                 | Archive logs backup only (without logswitch)         |
| [bck_ctl.rcv](bck_ctl.rcv)                                 | Controlfile backup only                              |
| [bck_db_keep.rcv](bck_db_keep.rcv)                         | Full database backup with retention guarantee        |
| [bck_db_validate.rcv](bck_db_validate.rcv)                 | Full database validation (backup validate)           |
| [bck_inc0.rcv](bck_inc0.rcv)                               | Incremental level 0 backup with archive logs         |
| [bck_inc0_noarc.rcv](bck_inc0_noarc.rcv)                   | Incremental level 0 backup without archive logs      |
| [bck_inc0_cold.rcv](bck_inc0_cold.rcv)                     | Offline (cold) incremental level 0 backup            |
| [bck_inc0_df.rcv](bck_inc0_df.rcv)                         | Incremental level 0 backup for specific datafiles    |
| [bck_inc0_pdb.rcv](bck_inc0_pdb.rcv)                       | Incremental level 0 backup for pluggable databases   |
| [bck_inc0_rec_area.rcv](bck_inc0_rec_area.rcv)             | Incremental level 0 backup to recovery area          |
| [bck_inc0_ts.rcv](bck_inc0_ts.rcv)                         | Incremental level 0 backup for specific tablespaces  |
| [bck_inc1c.rcv](bck_inc1c.rcv)                             | Incremental level 1 cumulative backup with archives  |
| [bck_inc1c_noarc.rcv](bck_inc1c_noarc.rcv)                 | Incremental level 1 cumulative without archives      |
| [bck_inc1d.rcv](bck_inc1d.rcv)                             | Incremental level 1 differential backup with archives|
| [bck_inc1d_noarc.rcv](bck_inc1d_noarc.rcv)                 | Incremental level 1 differential without archives    |
| [bck_recovery_area.rcv](bck_recovery_area.rcv)             | Fast recovery area backup (requires SBT channels)    |
| [bck_standby_inc0.rcv](bck_standby_inc0.rcv)               | Incremental level 0 for standby database setup       |

### Maintenance Scripts

| Script                                                     | Description                                          |
|------------------------------------------------------------|------------------------------------------------------|
| [mnt_chk.rcv](mnt_chk.rcv)                                 | Crosscheck backups/copies and delete expired         |
| [mnt_chk_arc.rcv](mnt_chk_arc.rcv)                         | Crosscheck archive logs                              |
| [mnt_del_arc.rcv](mnt_del_arc.rcv)                         | Delete archive logs (commented for safety)           |
| [mnt_del_obs.rcv](mnt_del_obs.rcv)                         | Delete obsolete backups (commented for safety)       |
| [mnt_del_obs_nomaint.rcv](mnt_del_obs_nomaint.rcv)         | Delete obsolete without maintenance window           |
| [mnt_reg.rcv](mnt_reg.rcv)                                 | Register database and set snapshot controlfile       |
| [mnt_sync.rcv](mnt_sync.rcv)                               | Resync RMAN catalog                                  |

### Reporting Scripts

| Script                                                     | Description                                          |
|------------------------------------------------------------|------------------------------------------------------|
| [rpt_bck.rcv](rpt_bck.rcv)                                 | Report backup status and requirements                |

### Recovery Scripts

| Script                                                     | Description                                          |
|------------------------------------------------------------|------------------------------------------------------|
| [rcv_arc.rcv](rcv_arc.rcv)                                 | Restore archivelogs by sequence number range         |
| [rcv_ctl.rcv](rcv_ctl.rcv)                                 | Restore controlfile from backup                      |
| [rcv_db.rcv](rcv_db.rcv)                                   | Complete database recovery (controlfiles in place)   |
| [rcv_db_pitr.rcv](rcv_db_pitr.rcv)                         | Database point-in-time recovery (PITR)               |
| [rcv_df.rcv](rcv_df.rcv)                                   | Datafile recovery                                    |
| [rcv_standby_db.rcv](rcv_standby_db.rcv)                   | Create standby database from primary backup          |
| [rcv_ts.rcv](rcv_ts.rcv)                                   | Tablespace recovery                                  |
| [rcv_ts_pitr.rcv](rcv_ts_pitr.rcv)                         | Tablespace point-in-time recovery (TSPITR)           |

### Configuration Examples

| Script                                                     | Description                                          |
|------------------------------------------------------------|------------------------------------------------------|
| [rman_set_commands.example](rman_set_commands.example)     | Example external SET commands file (optional)        |

**Total Scripts:** 34 scripts (18 backup + 7 maintenance + 1 reporting + 8 recovery) + 1 example file

## RMAN Wrapper Script

### Quick Start

```bash
# Execute backup for single database
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Execute for multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 2

# Custom settings with notification
oradba_rman.sh --sid PROD --rcv backup_full.rcv \
    --channels 4 \
    --compression HIGH \
    --format "/backup/%d_%T_%U.bkp" \
    --tag MONTHLY_BACKUP \
    --notify dba@example.com
```

### Features

- **Template Processing**: Replace `<ALLOCATE_CHANNELS>`, `<RELEASE_CHANNELS>`, `<FORMAT>`,
  `<TAG>`, `<COMPRESSION>`, `<BACKUP_PATH>`, `<ORACLE_SID>`, `<START_DATE>` at runtime
- **Parallel Execution**: Run RMAN for multiple SIDs concurrently
- **Dual Logging**: Generic wrapper log + SID-specific RMAN output logs
- **Email Notifications**: Alert on backup success/failure
- **Configuration**: SID-specific defaults via `oradba_rman.conf`
- **Dry Run**: Test template processing without executing RMAN

### Configuration

Create SID-specific configuration:

```bash
# Copy example config
cp ${ORADBA_BASE}/templates/etc/oradba_rman.conf.example \
   ${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf

# Edit configuration
vi ${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf
```

Example configuration:

```bash
export RMAN_CHANNELS=2
export RMAN_FORMAT="/backup/%d_%T_%U.bkp"
export RMAN_TAG="AUTO_BACKUP"
export RMAN_COMPRESSION="MEDIUM"
export RMAN_CATALOG=""
export RMAN_NOTIFY_EMAIL="dba@example.com"
export RMAN_NOTIFY_ON_SUCCESS=false
export RMAN_NOTIFY_ON_ERROR=true
```

### Usage Options

```bash
oradba_rman.sh --sid <SID> --rcv <script.rcv> [OPTIONS]

Required:
  --sid SID[,SID,...]   Oracle SID(s), comma-separated for multiple
  --rcv SCRIPT          RMAN script file (.rcv extension)

Optional:
  --channels N          Number of parallel channels
  --format FORMAT       Backup format string
  --tag TAG            Backup tag
  --compression LEVEL   NONE|LOW|MEDIUM|HIGH
  --catalog CONNECT    RMAN catalog connection
  --notify EMAIL       Email address for notifications
  --parallel N         Max parallel SID executions (default: 1)
  --dry-run           Test template processing only
  --verbose           Enable verbose output
```

## Usage

### Execute RMAN Script

**Using Wrapper (Recommended):**

```bash
# Single database
oradba_rman.sh --sid FREE --rcv backup_full.rcv

# Multiple databases in parallel
oradba_rman.sh --sid "CDB1,CDB2" --rcv backup_full.rcv --parallel 2

# With custom settings
oradba_rman.sh --sid FREE --rcv backup_full.rcv \
    --channels 4 --compression HIGH
```

**Direct RMAN Execution:**

```bash
# Run RMAN script directly (uses static values)
rman target / @${ORADBA_BASE}/rcv/backup_full.rcv

# With log file
rman target / log=/tmp/backup_full.log @${ORADBA_BASE}/rcv/backup_full.rcv

# Using catalog
rman target / catalog rman/password@catdb @${ORADBA_BASE}/rcv/backup_full.rcv
```

**Note:** Direct execution uses static values from the script. Wrapper execution
enables template substitution and enhanced features.

### Via OraDBA Alias

```bash
# Use rman alias with configured environment
rman target / @$ORADBA_BASE/rcv/backup_full.rman
```

## Script Templates

### Full Backup (backup_full.rcv)

Performs complete database backup including:

- Database datafiles
- Control files
- Archive logs
- SPFILE
- Automatic backup validation

**Template Tags:**

**Basic Tags:**

- `<ALLOCATE_CHANNELS>`: Replaced with channel allocation commands
- `<RELEASE_CHANNELS>`: Replaced with channel release commands
- `<COMPRESSION>`: Replaced with compression clause (NONE|LOW|BASIC|MEDIUM|HIGH)
- `<FORMAT>`: Replaced with FORMAT clause for backup files
- `<TAG>`: Replaced with TAG clause for backup identification
- `<BACKUP_PATH>`: Replaced with backup path (with trailing slash)
- `<ORACLE_SID>`: Replaced with current Oracle SID
- `<START_DATE>`: Replaced with timestamp (YYYYMMDD_HHMMSS)

**Advanced Tags (v0.14.0+):**

- `<SET_COMMANDS>`: Custom RMAN SET commands (inline or external file)
- `<TABLESPACES>`: Specific tablespaces for selective backup
- `<DATAFILES>`: Specific datafiles for selective backup
- `<PLUGGABLE_DATABASE>`: Specific PDBs for container database backups
- `<SECTION_SIZE>`: Enables multisection backup for large datafiles
- `<ARCHIVE_RANGE>`: Archive log range (ALL, FROM TIME, FROM SCN)
- `<ARCHIVE_PATTERN>`: LIKE clause for archive log filtering
- `<RESYNC_CATALOG>`: RMAN catalog resync command (when catalog configured)
- `<CUSTOM_PARAM_1>`, `<CUSTOM_PARAM_2>`, `<CUSTOM_PARAM_3>`: User-defined parameters

**Default Configuration:**

- Format: `/backup/%d_%T_%U.bkp`
- Compression: BASIC (no license required)
- Channels: 2
- Tag: AUTO_BACKUP

**Note on Compression Levels:**

- `BASIC`: Default, no additional Oracle license required
- `LOW`: No license required, less compression than BASIC
- `MEDIUM`, `HIGH`: Require Oracle Advanced Compression option license
- `NONE`: No compression

### Customization

#### Option 1: Command-Line Arguments (Recommended)

```bash
oradba_rman.sh --sid FREE --rcv backup_full.rcv \
    --format "/backup/monthly/%d_%T_%U.bkp" \
    --compression HIGH \
    --channels 4 \
    --tag MONTHLY_FULL_20260102
```

#### Option 2: Configuration File

```bash
# Edit SID-specific config
vi ${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf
```

#### Option 3: Copy and Modify Script

Copy scripts to a local directory and modify:

```bash
# Copy template
cp $ORADBA_BASE/rcv/backup_full.rcv /backup/scripts/my_backup.rcv

# Replace template tags with static values
vi /backup/scripts/my_backup.rcv

# Execute directly
rman target / @/backup/scripts/my_backup.rcv
```

**Common Customizations:**

- Backup destination (`FORMAT`)
- Retention policy (`RETENTION POLICY`)
- Compression level (`NONE|LOW|BASIC|MEDIUM|HIGH`)
  - Note: BASIC/LOW do not require Oracle Advanced Compression license
  - MEDIUM/HIGH require Oracle Advanced Compression option
- Parallelism (`CHANNELS`)
- Backup type (`INCREMENTAL LEVEL 0/1`)

### Archived Redo Log Backup (bck_arc.rcv)

Performs backup of archived redo logs with automatic deletion after successful backup:

- Archived redo logs (with DELETE INPUT)
- Current controlfile
- SPFILE (optional via CUSTOM_PARAM_1)
- Control file to trace
- PFILE for recovery reference

**Key Features:**

- **DELETE INPUT**: Removes archived logs after successful backup
- **No Automatic Log Switch**: Allows backup even if archiver is stuck
- **Flexible Filtering**: Use ARCHIVE_RANGE and ARCHIVE_PATTERN for selective backup
- **Optional SPFILE**: Control SPFILE backup via CUSTOM_PARAM_1

**Example Usage:**

```bash
# Backup all archived logs
oradba_rman.sh --sid PROD --rcv bck_arc.rcv

# Backup last 24 hours of archived logs
export RMAN_ARCHIVE_RANGE="FROM TIME 'SYSDATE-1'"
oradba_rman.sh --sid PROD --rcv bck_arc.rcv

# Include SPFILE backup (conditional via CUSTOM_PARAM_1)
export RMAN_CUSTOM_PARAM_1="backup spfile TAG 'SPFILE_BACKUP' format '<BACKUP_PATH>spfile_<ORACLE_SID>_<START_DATE>';"
oradba_rman.sh --sid PROD --rcv bck_arc.rcv

# Backup with pattern filtering
export RMAN_ARCHIVE_PATTERN="LIKE '/arch/prod_%'"
oradba_rman.sh --sid PROD --rcv bck_arc.rcv --compression HIGH
```

**Configuration Example:**

```bash
# In ${ORADBA_ORA_ADMIN_SID}/etc/oradba_rman.conf

# Archive log backup every 4 hours
export RMAN_ARCHIVE_RANGE="ALL"
export RMAN_COMPRESSION="BASIC"
export RMAN_TAG="ARCHIVELOG_BACKUP"

# Optional: Include SPFILE backup
export RMAN_CUSTOM_PARAM_1="backup spfile TAG 'SPFILE_BACKUP' format '<BACKUP_PATH>spfile_<ORACLE_SID>_<START_DATE>';"
```

**Important Notes:**

1. **DELETE INPUT** removes archived logs after backup - ensure backups are successful
2. No automatic log switch is performed - manually uncomment if needed
3. Use with appropriate retention policy to prevent running out of archived log space
4. Recommended for scheduled archivelog-only backups (e.g., every 4 hours)

### Incremental Level 0 Backup (bck_inc0.rcv)

Performs incremental level 0 backup (base backup for incremental backup strategy):

- Complete database backup at block level
- Archived redo logs (with DELETE INPUT)
- Current controlfile
- Control file to trace
- PFILE for recovery reference

**Key Features:**

- **Base for Incrementals**: Level 0 is the starting point for incremental strategy
- **Block-Level Backup**: Similar to full but creates incremental base
- **Multisection Support**: Use SECTION_SIZE for large datafile parallelization
- **Archive Log Cleanup**: DELETE INPUT removes archived logs after backup

**Example Usage:**

```bash
# Weekly level 0 backup (base for incremental strategy)
oradba_rman.sh --sid PROD --rcv bck_inc0.rcv --tag WEEKLY_L0

# With multisection for large database
export RMAN_SECTION_SIZE="10G"
oradba_rman.sh --sid BIGDB --rcv bck_inc0.rcv --channels 4

# Selective tablespace level 0
export RMAN_TABLESPACES="USERS,TOOLS"
oradba_rman.sh --sid PROD --rcv bck_inc0.rcv
```

### Incremental Level 1 Differential Backup (bck_inc1d.rcv)

Performs differential incremental level 1 backup:

- Backs up all blocks changed since most recent level 0 **or** level 1
- Smaller backup size compared to cumulative
- Faster backup but slower recovery (more backups to apply)

**Example Usage:**

```bash
# Daily differential level 1 (backs up changes since last level 0 or level 1)
oradba_rman.sh --sid PROD --rcv bck_inc1d.rcv --tag DAILY_L1D

# Schedule: Level 0 on Sunday, Level 1 differential Mon-Sat
# Mon: changes since Sun
# Tue: changes since Mon
# Wed: changes since Tue
# etc.
```

### Incremental Level 1 Cumulative Backup (bck_inc1c.rcv)

Performs cumulative incremental level 1 backup:

- Backs up all blocks changed since most recent level 0 **only**
- Larger backup size compared to differential
- Slower backup but faster recovery (fewer backups to apply)

**Example Usage:**

```bash
# Daily cumulative level 1 (backs up all changes since level 0)
oradba_rman.sh --sid PROD --rcv bck_inc1c.rcv --tag DAILY_L1C

# Schedule: Level 0 on Sunday, Level 1 cumulative Mon-Sat
# Mon: all changes since Sun
# Tue: all changes since Sun
# Wed: all changes since Sun
# etc.
```

**Incremental Backup Strategy Comparison:**

| Aspect           | Differential (bck_inc1d.rcv)      | Cumulative (bck_inc1c.rcv)        |
|------------------|-----------------------------------|-----------------------------------|
| Backup Size      | Smaller (only since last backup)  | Larger (all since level 0)        |
| Backup Time      | Faster                            | Slower                            |
| Recovery Time    | Slower (more backups to apply)    | Faster (fewer backups to apply)   |
| Storage Required | Less                              | More                              |
| Use Case         | Daily backups, space-constrained  | Weekly backups, fast recovery     |

## Best Practices

1. **Test Restores** - Regularly test backup restores
2. **Monitor Logs** - Review RMAN logs for errors
3. **Retention Policy** - Align with business requirements
4. **Backup Validation** - Use `BACKUP VALIDATE` periodically
5. **Archive Log Management** - Delete obsolete archive logs
6. **Catalog Usage** - Use RMAN catalog for enterprise environments
7. **Compression** - Balance compression vs. performance needs

## Integration

### RMAN Configuration

OraDBA doesn't modify RMAN configuration but works with existing setups:

```sql
-- Check current RMAN configuration
RMAN> SHOW ALL;

-- Common configurations
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE COMPRESSION ALGORITHM 'HIGH';
CONFIGURE DEVICE TYPE DISK PARALLELISM 2;
```

### Cron Jobs

Schedule RMAN backups via cron:

```bash
# Using wrapper script (recommended)
# Full backup daily at 2 AM with notification
0 2 * * * . $HOME/.bash_profile && oradba_rman.sh --sid FREE --rcv backup_full.rcv --notify dba@example.com

# Multiple databases in parallel
0 2 * * * . $HOME/.bash_profile && oradba_rman.sh --sid "CDB1,CDB2,CDB3" --rcv backup_full.rcv --parallel 2

# Direct RMAN execution (legacy)
0 2 * * * . $HOME/.bash_profile && rman target / @$ORADBA_BASE/rcv/backup_full.rcv >> /var/log/oracle/rman_full.log 2>&1
```

## Documentation

- **[RMAN Scripts](../doc/09-rman-scripts.md)** - Detailed RMAN script documentation
- **[Configuration](../doc/05-configuration.md)** - OraDBA environment setup
- **[Aliases](../doc/06-aliases.md)** - Shell aliases for RMAN

## Development

### Adding New Scripts

1. Create script with `.rcv` extension
2. Include header comment with purpose and parameters
3. Use template tags for dynamic substitution:
   - `<ALLOCATE_CHANNELS>` for channel allocation
   - `<FORMAT>` for backup format
   - `<TAG>` for backup tags
   - `<COMPRESSION>` for compression settings
4. Test with wrapper script and different backup scenarios
5. Document customization points

### Script Template

```rman
# ------------------------------------------------------------------------------
# Script......: my_backup.rcv
# Author......: Your Name
# Date........: YYYY-MM-DD
# Purpose.....: Custom backup script
# Usage.......: oradba_rman.sh --sid <SID> --rcv my_backup.rcv
# Version.....: 1.0.0
# ------------------------------------------------------------------------------

RUN {
    <ALLOCATE_CHANNELS>
    BACKUP <COMPRESSION> DATABASE PLUS ARCHIVELOG <FORMAT> <TAG>;
    BACKUP CURRENT CONTROLFILE <FORMAT> TAG 'CONTROLFILE_BACKUP';
}
```

See [development.md](../../doc/development.md) for coding standards.
