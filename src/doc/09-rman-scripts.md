# RMAN Script Templates

## Introduction

OraDBA includes RMAN (Recovery Manager) script templates for common backup and
recovery operations. These templates provide a starting point for database
backup strategies.

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

### backup_full.rman

Full database backup template:

```rman
# Usage
rman target / @$ORADBA_PREFIX/rcv/backup_full.rman

# Or using alias
rman
RMAN> @backup_full.rman
```

**What it does:**

- Connects to target database
- Performs full database backup
- Includes all datafiles
- Includes control file
- Includes SPFILE
- Archives current redo logs

**Customization:**
Edit the file to adjust:

- Backup format and location
- Compression level
- Retention policy
- Parallelism
- Backup tags

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
# Run RMAN script non-interactively
rman target / @$ORADBA_PREFIX/rcv/backup_full.rman

# With logging
rman target / @$ORADBA_PREFIX/rcv/backup_full.rman log=/tmp/backup.log
```

## Creating Custom RMAN Scripts

### Script Template

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
    BACKUP AS COMPRESSED BACKUPSET 
        DATABASE 
        FORMAT '/backup/%d_%T_%U.bkp'
        TAG 'FULL_BACKUP';
    BACKUP CURRENT CONTROLFILE 
        FORMAT '/backup/ctrl_%d_%T_%U.ctl';
    BACKUP SPFILE 
        FORMAT '/backup/spfile_%d_%T_%U.ora';
    RELEASE CHANNEL ch1;
}
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

## Next Steps

- **[SQL Scripts](08-sql-scripts.md)** - Database administration scripts
- **[Functions](10-functions.md)** - Database functions reference
- **[Troubleshooting](12-troubleshooting.md)** - Solve common issues
- Oracle RMAN Documentation
