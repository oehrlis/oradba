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

| Script                             | Description                                     |
|------------------------------------|-------------------------------------------------|
| [backup_full.rcv](backup_full.rcv) | Full database backup template with archive logs |

**Total Scripts:** 1

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

- **Template Processing**: Replace `<ALLOCATE_CHANNELS>`, `<FORMAT>`, `<TAG>`, `<COMPRESSION>` at runtime
- **Parallel Execution**: Run RMAN for multiple SIDs concurrently
- **Dual Logging**: Generic wrapper log + SID-specific RMAN output logs
- **Email Notifications**: Alert on backup success/failure
- **Configuration**: SID-specific defaults via `oradba_rman.conf`
- **Dry Run**: Test template processing without executing RMAN

### Configuration

Create SID-specific configuration:

```bash
# Copy example config
cp ${ORADBA_BASE}/etc/oradba_rman.conf.example \
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

- `<ALLOCATE_CHANNELS>`: Replaced with channel allocation commands
- `<COMPRESSION>`: Replaced with compression clause (NONE|LOW|MEDIUM|HIGH)
- `<FORMAT>`: Replaced with FORMAT clause for backup files
- `<TAG>`: Replaced with TAG clause for backup identification

**Default Configuration:**

- Format: `/backup/%d_%T_%U.bkp`
- Compression: MEDIUM
- Channels: 2
- Tag: AUTO_BACKUP

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
- Compression level (`COMPRESS HIGH`, `COMPRESS LOW`)
- Parallelism (`CHANNELS`)
- Backup type (`INCREMENTAL LEVEL 0/1`)

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
