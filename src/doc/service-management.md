# Oracle Service Management

OraDBA provides comprehensive service management tools for Oracle databases and listeners, suitable for interactive
use, automation, and integration with systemd or init.d.

## Overview

The service management toolkit consists of three main scripts and supporting templates:

- **oradba_dbctl.sh**: Database instance control (start/stop/restart/status)
- **oradba_lsnrctl.sh**: Listener control (start/stop/restart/status)
- **oradba_services.sh**: Orchestrates both databases and listeners
- **oradba_services_root.sh**: Root wrapper for systemd/init.d integration

## Quick Start

### Basic Usage

```bash
# Start all databases marked with :Y in oratab
dbstart

# Start specific database
oradba_dbctl.sh start ORCL

# Stop all databases (asks for justification)
oradba_dbctl.sh stop

# Stop with force flag (no confirmation)
oradba_dbctl.sh stop --force

# Start all services (listeners + databases)
orastart

# Check status
oradba_services.sh status
```

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

## Database Control (oradba_dbctl.sh)

Controls Oracle database instances with environment-aware execution.

### Features

- Honors `:Y` flag in oratab for auto-start databases
- Explicit SID override supported (ignores `:N` flag when SID specified)
- Configurable shutdown timeout (default: 180s)
- Escalates from `shutdown immediate` to `shutdown abort` on timeout
- Requires justification when stopping ALL databases
- Optional explicit PDB opening
- Continues on errors (logs failures, processes remaining)
- Integrates with oraenv.sh for per-database environment

### Usage

```bash
oradba_dbctl.sh {start|stop|restart|status} [OPTIONS] [SID1 SID2 ...]
```

### Options

- `-f, --force`: Skip confirmation prompts
- `-t, --timeout SECONDS`: Shutdown timeout (default: 180)
- `-p, --open-pdbs`: Explicitly open all PDBs after startup
- `-h, --help`: Show help message

### Examples

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

When stopping ALL databases (no SIDs specified), the script:

1. Shows warning with count of affected databases
2. Asks for justification (logged to file and console)
3. Requires "yes" confirmation to proceed
4. Can be bypassed with `--force` flag

### Environment Variables

- `ORADBA_SHUTDOWN_TIMEOUT`: Default shutdown timeout in seconds
- `ORADBA_LOG`: Log directory (default: /var/log/oracle)
- `ORATAB`: Path to oratab file (default: /etc/oratab)

### Exit Codes

- `0`: Success (all databases processed successfully)
- `1`: Failure (one or more databases failed)

## Listener Control (oradba_lsnrctl.sh)

Manages Oracle listeners across different Oracle homes.

### Features

- Supports multiple listeners
- Defaults to LISTENER from first Oracle home in oratab
- Explicit listener name specification
- Discovers running listeners for status command
- Cross-home listener management

### Usage

```bash
oradba_lsnrctl.sh {start|stop|restart|status} [OPTIONS] [LISTENER1 ...]
```

### Options

- `-f, --force`: Skip confirmation prompts
- `-h, --help`: Show help message

### Examples

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

- `ORADBA_LOG`: Log directory (default: /var/log/oracle)
- `ORATAB`: Path to oratab file (default: /etc/oratab)
- `TNS_ADMIN`: TNS configuration directory

## Combined Services (oradba_services.sh)

Orchestrates startup/shutdown of databases and listeners in configured order.

### Features

- Configurable startup/shutdown order
- Default: start listeners first, stop databases first
- Uses oradba_dbctl.sh and oradba_lsnrctl.sh
- Configuration via oradba_services.conf
- Pass-through options to underlying scripts
- Unified status reporting

### Usage

```bash
oradba_services.sh {start|stop|restart|status} [OPTIONS]
```

### Options

- `-f, --force`: Skip confirmation prompts
- `-c, --config FILE`: Use alternate configuration file
- `-h, --help`: Show help message

### Examples

```bash
# Start all services with default config
oradba_services.sh start

# Stop all services without confirmation
oradba_services.sh stop --force

# Restart with custom config
oradba_services.sh restart --config /etc/oradba_prod.conf

# Show comprehensive status
oradba_services.sh status
```

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

#### Example 3: Custom order with multiple DBs

```bash
STARTUP_ORDER="listener,database"
SHUTDOWN_ORDER="database,listener"
SPECIFIC_DBS="ORCL CDB1 TESTDB"
SPECIFIC_LISTENERS="LISTENER"
DB_OPTIONS="--timeout 240"
```

## System Integration

### systemd Service

Copy the systemd unit file:

```bash
sudo cp src/templates/systemd/oradba.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable oradba.service
sudo systemctl start oradba.service
```

Manage the service:

```bash
# Start
sudo systemctl start oradba.service

# Stop
sudo systemctl stop oradba.service

# Restart
sudo systemctl restart oradba.service

# Status
sudo systemctl status oradba.service

# View logs
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

## Logging

All service management operations are logged to:

- **Console**: Colored output (INFO=green, WARN=yellow, ERROR=red)
- **Log files**:
  - `${ORADBA_LOG}/oradba_dbctl.log`: Database operations
  - `${ORADBA_LOG}/oradba_lsnrctl.log`: Listener operations
  - `${ORADBA_LOG}/oradba_services.log`: Combined orchestration
  - `${ORADBA_LOG}/oradba_services_root.log`: Root wrapper operations

### Log Format

```text
[2026-01-01 14:30:45] [INFO] Starting database ORCL...
[2026-01-01 14:30:50] [INFO] Database ORCL started successfully
```

### Viewing Logs

```bash
# Tail all logs
tail -f /var/log/oracle/*.log

# Specific script logs
tail -f /var/log/oracle/oradba_dbctl.log

# Search for errors
grep ERROR /var/log/oracle/oradba_services.log
```

## Error Handling

The service management scripts implement robust error handling:

### Continue on Error

- Scripts continue processing remaining databases/listeners on failure
- Each failure is logged with details
- Summary reports success/failure counts
- Non-zero exit code if any operation failed

### Timeout Escalation

Database shutdown follows this sequence:

1. `SHUTDOWN IMMEDIATE;` (wait up to timeout)
2. If timeout: `SHUTDOWN ABORT;` (immediate)
3. Log escalation for review

### Failure Scenarios

**Database won't start:**

- Error logged to console and file
- Remaining databases still processed
- Check logs: `grep ERROR /var/log/oracle/oradba_dbctl.log`

**Listener already running:**

- Logged as INFO (not an error)
- Script continues normally

**Missing oratab entry:**

- Error if explicit SID provided
- Warning if auto-detecting from :Y flag

## Security Considerations

### Permissions

- **Interactive use**: Run as `oracle` user
- **System service**: Root wrapper calls scripts as `oracle`
- **Log directory**: Must be writable by `oracle` user

### Justification Requirement

When operating on ALL databases:

- Justification prompt cannot be bypassed interactively
- Use `--force` flag only in automation
- All justifications logged with timestamp and user

### Best Practices

1. **Test first**: Test scripts with status command before start/stop
2. **Use specific SIDs**: Prefer explicit SID specification for safety
3. **Review logs**: Check logs after bulk operations
4. **Configuration**: Use oradba_services.conf for production settings
5. **Timeouts**: Adjust shutdown timeout based on database size
6. **PDBs**: Enable `--open-pdbs` if application requires it

## Troubleshooting

### Database won't start

```bash
# Check environment
oraenv.sh ORCL
env | grep ORA

# Check if already running
ps -ef | grep pmon

# Manual startup
sqlplus / as sysdba
SQL> STARTUP;

# Review logs
tail -50 /var/log/oracle/oradba_dbctl.log
```

### Listener won't start

```bash
# Check TNS configuration
ls -la $TNS_ADMIN

# Check if already running
ps -ef | grep tnslsnr

# Manual start
lsnrctl start LISTENER

# Review logs
tail -50 /var/log/oracle/oradba_lsnrctl.log
```

### Timeout too short

```bash
# Increase timeout temporarily
oradba_dbctl.sh stop --timeout 600 ORCL

# Set permanently
export ORADBA_SHUTDOWN_TIMEOUT=600

# Or edit config
vi ${ORADBA_BASE}/etc/oradba_services.conf
# Add: DB_OPTIONS="--timeout 600"
```

### Service fails to start at boot

**systemd:**

```bash
# Check service status
sudo systemctl status oradba.service

# View detailed logs
sudo journalctl -xe -u oradba.service

# Check dependencies
systemctl list-dependencies oradba.service
```

**init.d:**

```bash
# Check runlevels
chkconfig --list oradba

# Manual test
sudo /etc/init.d/oradba start

# Check logs
tail -50 /var/log/oracle/oradba_services_root.log
```

## Advanced Usage

### Multiple Configurations

```bash
# Production config
oradba_services.sh start --config /etc/oradba_prod.conf

# Development config
oradba_services.sh start --config /etc/oradba_dev.conf
```

### Conditional Restart

```bash
# Only restart if already running
if pgrep -f "ora_pmon_ORCL" > /dev/null; then
    oradba_dbctl.sh restart ORCL
fi
```

### Pre/Post Hooks

Add custom logic around service operations:

```bash
#!/bin/bash
# custom_startup.sh

# Pre-startup tasks
echo "Checking filesystems..."
df -h /u01 /u02

# Start services
oradba_services.sh start

# Post-startup tasks
echo "Notifying monitoring..."
curl -X POST http://monitoring/oracle/started
```

## See Also {.unlisted .unnumbered}

- [Installation Guide](02-installation.md)
- [Configuration](05-configuration.md)
- [Environment Management](04-environment.md)
- [Reference](13-reference.md)
