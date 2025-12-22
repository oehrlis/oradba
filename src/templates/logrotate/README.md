# Logrotate Templates for OraDBA and Oracle Database

This directory contains logrotate configuration templates for comprehensive log
management of OraDBA system logs and Oracle Database components.

## Available Templates

| Template                     | Purpose                  | Target Logs                              |
|------------------------------|--------------------------|------------------------------------------|
| `oradba.logrotate`           | OraDBA system logs       | Installation, operational, backup logs   |
| `oracle-alert.logrotate`     | Database alert logs      | alert_SID.log files                      |
| `oracle-trace.logrotate`     | Database trace files     | Background/user trace files              |
| `oracle-audit.logrotate`     | Audit logs               | XML, traditional, FGA, DV audit files    |
| `oracle-listener.logrotate`  | Listener logs            | listener.log, trace files                |

## Quick Start

### Installation

```bash
# Using the management script (recommended)
sudo oradba_logrotate.sh --install

# Manual installation
sudo cp src/templates/logrotate/*.logrotate /etc/logrotate.d/
sudo chmod 644 /etc/logrotate.d/*.logrotate
```

### Testing

```bash
# Test configuration without rotating
sudo logrotate -d /etc/logrotate.d/oradba

# Force rotation (testing)
sudo logrotate -f /etc/logrotate.d/oradba
```

### Customization

```bash
# Generate environment-specific configurations
oradba_logrotate.sh --customize
```

## Template Details

### oradba.logrotate

Manages OraDBA system logs:

- **Installation logs**: `/var/log/oradba/` - Monthly, 12 months retention
- **Operational logs**: `/opt/oradba/logs/*.log` - Weekly, 8 weeks retention
- **User logs**: `$HOME/oradba/logs/*.log` - Weekly, 4 weeks retention
- **Backup logs**: `/opt/oradba/logs/backup/*.log` - Weekly, 12 weeks retention

### oracle-alert.logrotate

Manages Oracle database alert logs:

- **Alert logs**: `alert_<SID>.log` - Daily, 30 days retention
- **Method**: `copytruncate` (safe for open files)
- **Size trigger**: 100MB
- **Compression**: Delayed (keeps last rotation uncompressed)

### oracle-trace.logrotate

Manages Oracle trace files:

- **Background traces**: `*_ora_*.trc` - Weekly, 30 days retention
- **Metadata files**: `*_ora_*.trm` - Weekly, 14 days retention
- **Core dumps**: `core_*` - Daily, 7 days retention (aggressive)
- **RMAN traces**: `*rman*.trc` - Weekly, 30 days retention
- **Data Pump traces**: `*dm*.trc, *dp*.trc` - Weekly, 30 days retention

### oracle-audit.logrotate

Manages Oracle audit logs:

- **XML audit files**: `*.aud` - Weekly, 90 days retention
- **Traditional audit**: `*.txt` - Weekly, 90 days retention
- **Unified Audit spillover**: `UNIFIED_AUDIT_TRAIL*` - Weekly, 90 days
- **FGA logs**: `*FGA*.aud` - Weekly, 180 days retention
- **Database Vault**: `*DV*.aud` - Weekly, 180 days retention

**⚠️ Compliance Warning**: Default retention (90 days) may NOT meet your requirements:

- PCI-DSS: 1 year (365 days)
- HIPAA: 6 years (2190 days)
- SOX: 7 years (2555 days)
- GDPR: Varies (180-730 days)

### oracle-listener.logrotate

Manages Oracle Listener logs:

- **Listener logs**: `listener.log` - Daily, 30 days retention
- **Trace files**: `*.trc` - Weekly, 30 days retention
- **Alert logs**: `log.xml` - Daily, 30 days retention
- **Incidents**: ADR incident files - Weekly, 30 days retention
- **Connection Manager**: `cman.log` - Daily, 30 days retention

## Logrotate Options Explained

| Option                    | Description                                         |
|---------------------------|-----------------------------------------------------|
| `copytruncate`            | Copy and truncate (safe for logs Oracle keeps open) |
| `compress`                | Compress rotated logs with gzip                     |
| `delaycompress`           | Don't compress most recent rotation                 |
| `missingok`               | Don't error if log file doesn't exist               |
| `notifempty`              | Don't rotate empty files                            |
| `create MODE OWNER GROUP` | Create new file with specified permissions          |
| `nocreate`                | Don't create new file (for user directories)        |
| `maxage N`                | Remove rotated logs older than N days               |
| `size SIZE`               | Rotate when file exceeds SIZE (e.g., 100M)          |
| `rotate N`                | Keep N rotated log files                            |
| `sharedscripts`           | Run scripts once for all files                      |

## Customization

### Adjust Paths

Templates use standard Oracle paths. Customize for your environment:

```bash
# Find your actual paths
echo $ORACLE_BASE
echo $ORACLE_HOME
echo $TNS_ADMIN

# Edit templates to match
sudo vi /etc/logrotate.d/oracle-alert
```

### Adjust Retention

Change rotation frequency and retention count:

```conf
# Example: Keep 60 days instead of 30
daily
rotate 60  # Changed from 30
```

### Add Notifications

Uncomment and customize postrotate scripts:

```conf
postrotate
    echo "Logs rotated on $(hostname)" | \
        mail -s "Log Rotation" dba@example.com
endscript
```

### Size-Based Rotation

Add size triggers for busy systems:

```conf
/path/to/alert.log {
    daily
    size 500M     # Rotate when file exceeds 500MB
    rotate 30
    ...
}
```

## Testing Best Practices

### Dry Run (Debug Mode)

```bash
# See what would happen without actually rotating
sudo logrotate -d /etc/logrotate.d/oradba
```

### Verbose Mode

```bash
# See detailed execution
sudo logrotate -v /etc/logrotate.d/oradba
```

### Force Rotation

```bash
# Force rotation for testing
sudo logrotate -f /etc/logrotate.d/oradba
```

### Check Logrotate Status

```bash
# View last rotation times
cat /var/lib/logrotate/status
```

## Troubleshooting

### Permissions Issues

```bash
# Ensure logrotate can read/write
sudo chown root:root /etc/logrotate.d/oradba*
sudo chmod 644 /etc/logrotate.d/oradba*

# Ensure oracle user can write to log directories
sudo chown -R oracle:oinstall /opt/oradba/logs
```

### Logs Not Rotating

Check:

1. File paths match actual locations
2. Files exist and are not empty
3. Logrotate is scheduled (cron.daily)
4. No syntax errors: `logrotate -d /etc/logrotate.d/oradba`

### High Disk Usage

Adjust retention or compression:

```conf
# More aggressive cleanup
rotate 7          # Keep only 1 week
compress          # Compress immediately
maxage 7          # Remove files older than 7 days
```

## Security Considerations

### File Permissions

- System configs: `root:root 0644`
- Created logs: `oracle:oinstall 0640`
- User logs: `nocreate` (respect user permissions)

### Audit Log Protection

- Never use `nocreate` for audit logs
- Ensure proper ownership: `oracle:oinstall`
- Consider archival before deletion for compliance

### Sensitive Data

If logs contain sensitive data:

- Reduce retention period
- Consider encryption for archived logs
- Use secure deletion (`shred` in postrotate)

## Integration

### With Centralized Logging

Archive rotated logs to centralized storage:

```conf
postrotate
    # Upload to S3, rsync to log server, etc.
    aws s3 cp /path/to/log.gz s3://bucket/logs/
endscript
```

### With Monitoring

Alert on rotation failures:

```conf
postrotate
    if [ $? -ne 0 ]; then
        echo "Log rotation failed" | mail -s "ERROR" admin@example.com
    fi
endscript
```

### With OraDBA Scripts

OraDBA scripts automatically create log directories with proper permissions.

## Management Script

Use `oradba_logrotate.sh` for simplified management:

```bash
# Install all templates
sudo oradba_logrotate.sh --install

# List installed configs
oradba_logrotate.sh --list

# Test configurations
oradba_logrotate.sh --test

# Generate customized configs
oradba_logrotate.sh --customize
```

## Compliance Matrix

| Standard  | Requirement | Configuration                     |
|-----------|-------------|-----------------------------------|
| PCI-DSS   | 1 year      | `rotate 52`, `maxage 365`         |
| HIPAA     | 6 years     | `rotate 312`, `maxage 2190`       |
| SOX       | 7 years     | `rotate 364`, `maxage 2555`       |
| GDPR      | Varies      | `rotate 26-104`, `maxage 180-730` |
| ISO 27001 | Risk-based  | Align with risk assessment        |

## References

- [logrotate man page](https://linux.die.net/man/8/logrotate)
- [Oracle Database Administrator's Guide - Managing Log Files](https://docs.oracle.com/en/database/)
- [PCI-DSS Requirements](https://www.pcisecuritystandards.org/)
- OraDBA documentation: [LOG_MANAGEMENT.md](../../doc/LOG_MANAGEMENT.md)

## Support

For issues or questions:

- GitHub Issues: <https://github.com/oehrlis/oradba/issues>
- Email: <stefan.oehrli@oradba.ch>

## License

Apache License Version 2.0 - see [LICENSE](../../../LICENSE)

Part of the OraDBA project - Oracle Database Infrastructure and Security
