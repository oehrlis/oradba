# Oracle Service and Log Operations

**Purpose:** Guide to managing Oracle database services, listeners, and log files with OraDBA.

**Audience:** DBAs and system administrators managing Oracle services and log files.

## Service Management Overview

OraDBA provides comprehensive service management tools for Oracle databases and listeners, suitable
for interactive use, automation, and integration with systemd or init.d. The Plugin System enables
product-specific service management for databases, Data Safe connectors, and other Oracle products.

The service management toolkit consists of three main scripts and a root wrapper:

- **oradba_dbctl.sh**: Database instance control (start/stop/restart/status)
- **oradba_lsnrctl.sh**: Listener control (start/stop/restart/status)
- **oradba_services.sh**: Orchestrates both databases and listeners
- **oradba_services_root.sh**: Root wrapper for systemd/init.d integration

### Convenient Aliases

OraDBA provides short aliases for daily use:

```bash
# Database control
dbctl           # Alias for oradba_dbctl.sh
dbstart         # Start databases
dbstop          # Stop databases
dbrestart       # Restart databases

# Listener control
listener        # Alias for oradba_lsnrctl.sh
lsnrstart       # Start listeners (oradba_lsnrctl.sh wrapper)
lsnrstop        # Stop listeners (oradba_lsnrctl.sh wrapper)
lsnrstatus      # Listener status (oradba_lsnrctl.sh wrapper)

# Combined services
orastart        # Start all Oracle services
orastop         # Stop all Oracle services
orarestart      # Restart all Oracle services
orastatus       # Show all service status
```

## Database Control

`oradba_dbctl.sh` controls Oracle database instances with environment-aware execution.

### Features

- Honors `:Y` flag in oratab for auto-start databases
- Explicit SID override supported (ignores `:N` flag when SID specified)
- Configurable shutdown timeout (default: 180s)
- Escalates from `SHUTDOWN IMMEDIATE` to `SHUTDOWN ABORT` on timeout
- Requires justification when stopping ALL databases
- Optional explicit PDB opening
- Continues on errors (logs failures, processes remaining)
- Integrates with oraenv.sh for per-database environment

### Usage and Options

```bash
oradba_dbctl.sh {start|stop|restart|status} [OPTIONS] [SID1 SID2 ...]
```

| Option | Long Form           | Description                            |
|--------|---------------------|----------------------------------------|
| `-f`   | `--force`           | Skip confirmation prompts              |
| `-t`   | `--timeout SECONDS` | Shutdown timeout (default: 180)        |
| `-p`   | `--open-pdbs`       | Explicitly open all PDBs after startup |
| `-h`   | `--help`            | Show help message                      |

### Key Examples

```bash
# Start all databases with :Y flag in oratab
oradba_dbctl.sh start

# Start specific databases (overrides :N flag)
oradba_dbctl.sh start ORCL CDB1

# Stop all with 300s timeout
oradba_dbctl.sh stop --timeout 300

# Start and open all PDBs
oradba_dbctl.sh start ORCL --open-pdbs

# Force stop without confirmation
oradba_dbctl.sh stop --force

# Check status
oradba_dbctl.sh status
```

### Behavior

**Startup:**

1. Checks oratab for databases with `:Y` flag (unless explicit SIDs provided)
2. For each database:
   - Sources environment via oraenv.sh
   - Checks if already running
   - Executes `STARTUP;`
   - Optionally opens PDBs with `ALTER PLUGGABLE DATABASE ALL OPEN;`

**Shutdown:**

1. For each database:
   - Sources environment via oraenv.sh
   - Checks if running
   - Attempts `SHUTDOWN IMMEDIATE;` with timeout
   - Escalates to `SHUTDOWN ABORT;` if timeout exceeded
   - Logs all operations

**Justification:**

When stopping ALL databases (no SIDs specified), the script shows a warning with the count of
affected databases, asks for a justification (logged to file and console), and requires "yes"
confirmation to proceed. Use `--force` to bypass in automation.

### Environment Variables

| Variable                  | Default           | Description                         |
|---------------------------|-------------------|-------------------------------------|
| `ORADBA_SHUTDOWN_TIMEOUT` | 180               | Default shutdown timeout in seconds |
| `ORADBA_LOG`              | `/var/log/oracle` | Log directory                       |
| `ORATAB`                  | `/etc/oratab`     | Path to oratab file                 |

## Listener Control

`oradba_lsnrctl.sh` manages Oracle listeners across different Oracle homes.

### Features

- Supports multiple listeners across homes
- Defaults to LISTENER from first Oracle home in oratab
- Explicit listener name specification
- Discovers running listeners for status command
- Cross-home listener management

### Usage and Options

```bash
oradba_lsnrctl.sh {start|stop|restart|status} [OPTIONS] [LISTENER1 ...]
```

| Option | Long Form | Description               |
|--------|-----------|---------------------------|
| `-f`   | `--force` | Skip confirmation prompts |
| `-h`   | `--help`  | Show help message         |

### Key Examples

```bash
# Start default LISTENER
oradba_lsnrctl.sh start

# Start specific listeners
oradba_lsnrctl.sh start LISTENER LISTENER_ORCL

# Stop all listeners with force
oradba_lsnrctl.sh stop --force

# Show status of all running listeners
oradba_lsnrctl.sh status
```

### Environment Variables

| Variable     | Default           | Description                 |
|--------------|-------------------|-----------------------------|
| `ORADBA_LOG` | `/var/log/oracle` | Log directory               |
| `ORATAB`     | `/etc/oratab`     | Path to oratab file         |
| `TNS_ADMIN`  | —                 | TNS configuration directory |

## Service Orchestration

`oradba_services.sh` orchestrates startup and shutdown of databases and listeners in configured
order.

### Features

- Configurable startup/shutdown order
- Default: start listeners first, stop databases first
- Delegates to oradba_dbctl.sh and oradba_lsnrctl.sh
- Configuration via `oradba_services.conf`
- Pass-through options to underlying scripts
- Unified status reporting

### Usage and Options

```bash
oradba_services.sh {start|stop|restart|status} [OPTIONS]
```

| Option | Long Form       | Description                      |
|--------|-----------------|----------------------------------|
| `-f`   | `--force`       | Skip confirmation prompts        |
| `-c`   | `--config FILE` | Use alternate configuration file |
| `-h`   | `--help`        | Show help message                |

### Configuration File

Located at `${ORADBA_BASE}/etc/oradba_services.conf`:

```bash
# Startup order (default: listener,database)
STARTUP_ORDER="listener,database"

# Shutdown order (default: database,listener)
SHUTDOWN_ORDER="database,listener"

# Specific databases (empty = all with :Y flag)
SPECIFIC_DBS=""

# Specific listeners (empty = default LISTENER)
SPECIFIC_LISTENERS=""

# Database options
DB_OPTIONS=""

# Listener options
LSNR_OPTIONS=""
```

### Configuration Examples

#### Example 1: Production with PDBs

```bash
STARTUP_ORDER="listener,database"
SHUTDOWN_ORDER="database,listener"
SPECIFIC_DBS="PRODDB"
SPECIFIC_LISTENERS="LISTENER_PROD"
DB_OPTIONS="--open-pdbs --timeout 300"
```

#### Example 2: Development (all databases)

```bash
STARTUP_ORDER="listener,database"
SHUTDOWN_ORDER="database,listener"
SPECIFIC_DBS=""
SPECIFIC_LISTENERS=""
DB_OPTIONS="--open-pdbs"
```

#### Example 3: Multiple databases with custom timeout

```bash
STARTUP_ORDER="listener,database"
SHUTDOWN_ORDER="database,listener"
SPECIFIC_DBS="ORCL CDB1 TESTDB"
SPECIFIC_LISTENERS="LISTENER"
DB_OPTIONS="--timeout 240"
```

## Log Management

OraDBA provides automated log rotation through logrotate integration. Proper log management
addresses disk space growth, system performance, compliance retention requirements (PCI-DSS, HIPAA,
SOX, GDPR), security audit trails, and historical troubleshooting data.

**Prerequisites:** logrotate installed (standard on most Linux distributions), root access for
system-wide configuration.

### Quick Start

```bash
# Install all logrotate templates (requires root)
sudo oradba_logrotate.sh --install

# Test configuration without rotating logs
oradba_logrotate.sh --test

# Force rotation for testing (requires root)
sudo oradba_logrotate.sh --force

# User-mode setup (no root required)
oradba_logrotate.sh --install-user
oradba_logrotate.sh --run-user
```

### Log Templates

Five logrotate templates are provided in `src/templates/logrotate/`:

| Template                  | Purpose             | Default Rotation | Retention         |
|---------------------------|---------------------|------------------|-------------------|
| oradba.logrotate          | OraDBA system logs  | Monthly/Weekly   | 12 months/8 weeks |
| oracle-alert.logrotate    | Database alert logs | Daily            | 30 days           |
| oracle-trace.logrotate    | Trace files cleanup | Weekly (maxage)  | 30 days           |
| oracle-audit.logrotate    | Audit logs          | Weekly           | 90 days           |
| oracle-listener.logrotate | Listener logs       | Daily            | 30 days           |

Each template includes OraDBA headers, inline documentation, safe defaults, gzip compression,
`missingok`/`notifempty` error handling, and appropriate `create` modes or `copytruncate` for
active logs.

### User-Mode vs System-Wide

For environments where root access is restricted, OraDBA supports non-root logrotate operation:

| Aspect           | User-Mode                    | System-Wide           |
|------------------|------------------------------|-----------------------|
| **Privileges**   | No root required             | Requires root         |
| **Installation** | `~/.oradba/logrotate/`       | `/etc/logrotate.d/`   |
| **State files**  | `~/.oradba/logrotate/state/` | `/var/lib/logrotate/` |
| **Execution**    | Manual or user crontab       | System cron           |
| **Scope**        | User's Oracle logs           | All system logs       |
| **Management**   | Self-service                 | System admin          |

User-mode setup:

```bash
# Initialize configuration
oradba_logrotate.sh --install-user

# Review and test
oradba_logrotate.sh --test

# Automate with cron
oradba_logrotate.sh --cron
# Then: crontab -e → paste generated entry
```

### Compliance Requirements

The oracle-audit.logrotate template manages audit trails. Default retention is 90 days; adjust
`rotate` values to meet regulatory requirements:

| Standard | Retention Period | Notes             |
|----------|------------------|-------------------|
| PCI-DSS  | 1 year minimum   | Card payment data |
| HIPAA    | 6 years minimum  | Healthcare data   |
| SOX      | 7 years minimum  | Financial records |
| GDPR     | Varies by data   | EU privacy law    |

Example PCI-DSS configuration:

```bash
# Edit /etc/logrotate.d/oracle-audit
rotate 365  # Daily rotation = 365 days
```

Example HIPAA configuration:

```bash
weekly
rotate 312  # 6 years * 52 weeks
```

## System Integration

### systemd Service

Copy and enable the systemd unit file:

```bash
sudo cp src/templates/systemd/oradba.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable oradba.service
sudo systemctl start oradba.service
```

Manage the service:

```bash
sudo systemctl start oradba.service
sudo systemctl stop oradba.service
sudo systemctl restart oradba.service
sudo systemctl status oradba.service
sudo journalctl -u oradba.service -f
```

### init.d/chkconfig Service

Copy the init.d script:

```bash
sudo cp src/templates/init.d/oradba /etc/init.d/
sudo chmod +x /etc/init.d/oradba
```

**Red Hat/CentOS:**

```bash
sudo chkconfig --add oradba
sudo chkconfig oradba on
sudo service oradba start
```

**Debian/Ubuntu:**

```bash
sudo update-rc.d oradba defaults
sudo update-rc.d oradba enable
sudo service oradba start
```

### Service Log Locations and Format

All service management operations are logged to:

| Log File                                 | Contents                |
|------------------------------------------|-------------------------|
| `${ORADBA_LOG}/oradba_dbctl.log`         | Database operations     |
| `${ORADBA_LOG}/oradba_lsnrctl.log`       | Listener operations     |
| `${ORADBA_LOG}/oradba_services.log`      | Combined orchestration  |
| `${ORADBA_LOG}/oradba_services_root.log` | Root wrapper operations |

Log format:

```text
[2026-01-01 14:30:45] [INFO] Starting database ORCL...
[2026-01-01 14:30:50] [INFO] Database ORCL started successfully
```

Output to console uses color: INFO=green, WARN=yellow, ERROR=red.

### Monitoring Integration

Monitor logrotate execution and log growth:

```bash
# Check logrotate status
ls -lrt /var/lib/logrotate/status
grep logrotate /var/log/messages

# Monitor log directory sizes
ORACLE_BASE=${ORACLE_BASE:-/opt/oracle}
THRESHOLD_MB=5000
for logdir in "$ORACLE_BASE"/diag/rdbms/*/*/trace; do
    [ -d "$logdir" ] || continue
    SIZE_MB=$(du -sm "$logdir" | awk '{print $1}')
    [ "$SIZE_MB" -gt "$THRESHOLD_MB" ] && echo "WARNING: $logdir is ${SIZE_MB}MB"
done
```

Alert if logrotate has not run recently:

```bash
LAST_RUN=$(stat -c %Y /var/lib/logrotate/status 2>/dev/null || echo 0)
AGE=$(( $(date +%s) - LAST_RUN ))
[ "$AGE" -gt 129600 ] && echo "WARNING: Logrotate hasn't run in $((AGE / 3600)) hours"
```

## Troubleshooting

### Database Won't Start

```bash
# Check environment
oraenv.sh ORCL
env | grep ORA

# Check if already running
ps -ef | grep pmon

# Manual startup to see error output
sqlplus / as sysdba <<EOF
STARTUP;
EXIT;
EOF

# Review script logs
tail -50 /var/log/oracle/oradba_dbctl.log
grep ERROR /var/log/oracle/oradba_dbctl.log
```

### Listener Won't Start

```bash
# Check TNS configuration
ls -la $TNS_ADMIN

# Check if already running
ps -ef | grep tnslsnr

# Manual start
lsnrctl start LISTENER

# Review script logs
tail -50 /var/log/oracle/oradba_lsnrctl.log
```

### Timeout Too Short

```bash
# Increase timeout for a single operation
oradba_dbctl.sh stop --timeout 600 ORCL

# Set permanently via environment
export ORADBA_SHUTDOWN_TIMEOUT=600

# Or set in services config
# Add to ${ORADBA_BASE}/etc/oradba_services.conf:
# DB_OPTIONS="--timeout 600"
```

### Service Fails to Start at Boot

**systemd:**

```bash
sudo systemctl status oradba.service
sudo journalctl -xe -u oradba.service
systemctl list-dependencies oradba.service
```

**init.d:**

```bash
chkconfig --list oradba
sudo /etc/init.d/oradba start
tail -50 /var/log/oracle/oradba_services_root.log
```

### Log Rotation Not Working

**Symptom:** Logs continue growing despite logrotate configuration.

```bash
# Test configuration
oradba_logrotate.sh --test --template oracle-alert

# Check for syntax errors
sudo logrotate -d /etc/logrotate.d/oracle-alert

# Debug in verbose mode
sudo logrotate -d -v /etc/logrotate.d/oracle-alert
```

Common causes: incorrect file paths or wildcards, permission issues, SELinux denials, syntax errors
in configuration.

### Permission Errors in Log Rotation

**Symptom:** `permission denied` errors in logrotate output.

```bash
# Verify file ownership
ls -la $ORACLE_BASE/diag/rdbms/*/*/trace/

# Logrotate configs must be root-owned
sudo chown root:root /etc/logrotate.d/oracle-*
sudo chmod 644 /etc/logrotate.d/oracle-*

# Log directories must be oracle-owned
chown -R oracle:oinstall $ORACLE_BASE/diag/
```

For SELinux environments:

```bash
sudo ausearch -m avc -ts recent | grep logrotate
sudo audit2allow -a -M logrotate_oracle
sudo semodule -i logrotate_oracle.pp
```

### Database Can't Write to Alert Log After Rotation

**Cause:** Using `create` instead of `copytruncate` for active (open) log files.

**Solution:** Always use `copytruncate` for logs held open by the database process:

```bash
/path/to/alert_*.log {
    copytruncate  # REQUIRED for active logs
    daily
    rotate 30
    compress
    missingok
}
```

### Missing oratab Entry

- Error is raised if an explicit SID is provided but not found in oratab
- Warning is issued (not an error) when auto-detecting from the `:Y` flag
- Listener already running is logged as INFO and is not treated as a failure

<!-- Web-only sections below: kept for MkDocs navigation, stripped during PDF build (build_pdf.sh). -->
## See Also {.unlisted .unnumbered}

- [Configuration](configuration.md)
- [Environment Management](environment.md)
- [Troubleshooting](troubleshooting.md)

## Navigation {.unlisted .unnumbered}

**Previous:** [SQL*Net Configuration](sqlnet-config.md)
**Next:** [Troubleshooting](troubleshooting.md)
