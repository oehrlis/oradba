# RMAN Scripts

Recovery Manager (RMAN) scripts for Oracle Database backup and recovery operations.

## Overview

This directory contains RMAN script templates for database backup, recovery, and
maintenance tasks. Scripts use RMAN command language and are executed via the
`rman` utility.

## Available Scripts

| Script                               | Description                                     |
|--------------------------------------|-------------------------------------------------|
| [backup_full.rman](backup_full.rman) | Full database backup template with archive logs |

**Total Scripts:** 1

## Usage

### Execute RMAN Script

```bash
# Run RMAN script directly
rman target / @${ORADBA_BASE}/rcv/backup_full.rman

# With log file
rman target / log=/tmp/backup_full.log @${ORADBA_BASE}/rcv/backup_full.rman

# Using catalog
rman target / catalog rman/password@catdb @${ORADBA_BASE}/rcv/backup_full.rman
```

### Via OraDBA Alias

```bash
# Use rman alias with configured environment
rman target / @$ORADBA_BASE/rcv/backup_full.rman
```

## Script Templates

### Full Backup (backup_full.rman)

Performs complete database backup including:

- Database datafiles
- Control files
- Archive logs
- SPFILE
- Automatic backup validation

**Default Configuration:**

- Format: `%d_full_%T_%U`
- Compression: BASIC
- Retention: 7 days
- Parallelism: 2

### Customization

Copy scripts to a local directory and modify:

```bash
# Copy template
cp $ORADBA_BASE/rcv/backup_full.rman /backup/scripts/my_backup.rman

# Edit parameters
vi /backup/scripts/my_backup.rman
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
# Full backup daily at 2 AM
0 2 * * * . $HOME/.bash_profile && rman target / @$ORADBA_BASE/rcv/backup_full.rman >> /var/log/oracle/rman_full.log 2>&1
```

## Documentation

- **[RMAN Scripts](../doc/09-rman-scripts.md)** - Detailed RMAN script documentation
- **[Configuration](../doc/05-configuration.md)** - OraDBA environment setup
- **[Aliases](../doc/06-aliases.md)** - Shell aliases for RMAN

## Development

### Adding New Scripts

1. Create script with `.rman` extension
2. Include header comment with purpose and parameters
3. Use substitution variables for flexibility
4. Test with different backup scenarios
5. Document customization points

### Script Template

```rman
# Script: my_backup.rman
# Purpose: Custom backup script
# Author: Your Name
# Version: 1.0

RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
    BACKUP DATABASE PLUS ARCHIVELOG;
    RELEASE CHANNEL ch1;
}
```

See [development.md](../../doc/development.md) for coding standards.
