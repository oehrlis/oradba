# OraDBA RMAN Scripts

RMAN recovery and backup scripts for Oracle Database maintenance.

## Available Scripts

- **[backup_full.rman](backup_full.rman)** - Full database backup template

## Usage

Execute RMAN scripts from the command line:

```bash
rman target / @${ORADBA_BASE}/rcv/backup_full.rman
```

## Customization

Copy scripts to your local directory and modify parameters:

- Backup destination
- Retention policy
- Compression settings
- Parallelism degree

## Documentation

See [USAGE.md](../doc/USAGE.md) for RMAN script examples and best practices.
