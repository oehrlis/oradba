<!-- markdownlint-disable MD013 -->
# Database Functions Library (db_functions.sh)

**Purpose:** Reference for reusable shell functions that query Oracle database information from v$ views.

**Audience:** Script developers and advanced users.

**Prerequisites:**

- ORACLE_HOME and ORACLE_SID environment variables set
- Oracle SQL*Plus available
- `common.sh` library sourced

## Overview

The `db_functions.sh` library provides reusable functions to query Oracle database information from v$ views. Functions are designed to work gracefully with databases in different states: NOMOUNT, MOUNT, and OPEN.

## Location

```bash
${ORADBA_BASE}/lib/db_functions.sh
```

## Dependencies

- `common.sh` - Must be sourced before db_functions.sh
- Oracle SQL*Plus
- ORACLE_HOME and ORACLE_SID environment variables

## Usage

```bash
# Source common library first
source "${ORADBA_BASE}/lib/common.sh"

# Source database functions
source "${ORADBA_BASE}/lib/db_functions.sh"

# Use functions
if check_database_connection; then
    show_database_status
fi
```

## Functions Reference

### Connection and Status

#### check_database_connection()

Check if database is accessible.

**Returns:** 0 if connected, 1 if not

```bash
if check_database_connection; then
    echo "Database is accessible"
fi
```

#### get_database_open_mode()

Get current database open mode.

**Returns:** "NOMOUNT", "MOUNT", "OPEN", or "UNKNOWN"

```bash
mode=$(get_database_open_mode)
echo "Database is in $mode mode"
```

### Instance Information (NOMOUNT+)

#### query_instance_info()

Query v$instance for basic instance information.

**Available at:** NOMOUNT, MOUNT, OPEN states

**Returns:** Multi-line output with:

- INSTANCE_NAME
- HOST_NAME
- VERSION
- STARTUP_TIME
- STATUS
- INSTANCE_ROLE

```bash
instance_info=$(query_instance_info)
echo "$instance_info"
```

#### format_uptime()

Format database uptime in human-readable format.

**Parameters:** `startup_time` - Startup time in format "YYYY-MM-DD HH:MI:SS"

**Returns:** Formatted uptime string (e.g., "2d 5h 23m")

```bash
startup_time="2025-12-14 10:30:00"
uptime=$(format_uptime "$startup_time")
echo "Uptime: $uptime"
```

### Database Information (MOUNT+)

#### query_database_info()

Query v$database for database-level information.

**Available at:** MOUNT, OPEN states

**Returns:** Multi-line output with:

- DATABASE_NAME
- DB_UNIQUE_NAME
- DBID
- LOG_MODE
- OPEN_MODE
- CREATED

```bash
if [[ "$mode" != "NOMOUNT" ]]; then
    db_info=$(query_database_info)
    echo "$db_info"
fi
```

#### query_datafile_size()

Query total size of all datafiles.

**Available at:** MOUNT, OPEN states

**Returns:** Total size in MB

```bash
if [[ "$mode" != "NOMOUNT" ]]; then
    size=$(query_datafile_size)
    echo "Total datafile size: ${size} MB"
fi
```

### Performance Information (OPEN only)

#### query_memory_usage()

Query SGA and PGA memory usage.

**Available at:** OPEN state only

**Returns:** Multi-line output with:

- SGA_SIZE (MB)
- PGA_SIZE (MB)

```bash
if [[ "$mode" == "OPEN" ]]; then
    memory=$(query_memory_usage)
    echo "$memory"
fi
```

#### query_sessions_info()

Query session statistics.

**Available at:** OPEN state only

**Returns:** Multi-line output with:

- TOTAL_SESSIONS
- ACTIVE_SESSIONS
- USER_SESSIONS

```bash
if [[ "$mode" == "OPEN" ]]; then
    sessions=$(query_sessions_info)
    echo "$sessions"
fi
```

#### query_pdb_info()

Query pluggable database information.

**Available at:** OPEN state only

**Returns:** Multi-line output with PDB details or empty if not a CDB

```bash
if [[ "$mode" == "OPEN" ]]; then
    pdb_info=$(query_pdb_info)
    [[ -n "$pdb_info" ]] && echo "$pdb_info"
fi
```

### Display Functions

#### show_database_status()

Display comprehensive database status information. Automatically adjusts output based on database state and handles dummy/non-running databases gracefully.

**Available at:** All states (NOMOUNT, MOUNT, OPEN) plus dummy/not-started detection

**Output includes:**

- **Environment (all states):**
  - ORACLE_BASE, ORACLE_HOME, TNS_ADMIN
  - Oracle version
- **Instance information (NOMOUNT+):**
  - Instance name and startup time
  - Uptime calculation
  - Status (STARTED/MOUNTED/OPEN)
- **Database information (MOUNT+):**
  - Database name, unique name, DBID
  - Database role (PRIMARY/STANDBY)
  - Datafile size (total GB)
  - Log mode (ARCHIVELOG/NOARCHIVELOG)
  - Character set
  - Session information (user counts)
  - PDB information if CDB
- **Memory information:**
  - SGA/PGA targets (all states)
  - Current SGA/PGA usage (OPEN only)
  - FRA size
- **Special handling:**
  - Dummy databases (oratab :D flag): Shows environment only
  - NOT STARTED: Shows environment with clear status
  - No error messages displayed for non-running databases

```bash
show_database_status
```

## State-Dependent Behavior

The library automatically handles different database states:

| Function                  | NOMOUNT | MOUNT | OPEN |
|---------------------------|---------|-------|------|
| check_database_connection | [OK]       | [OK]     | [OK]    |
| get_database_open_mode    | [OK]       | [OK]     | [OK]    |
| query_instance_info       | [OK]       | [OK]     | [OK]    |
| format_uptime             | [OK]       | [OK]     | [OK]    |
| query_database_info       | [X]       | [OK]     | [OK]    |
| query_datafile_size       | [X]       | [OK]     | [OK]    |
| query_memory_usage        | [X]       | [X]     | [OK]    |
| query_sessions_info       | [X]       | [OK]     | [OK]    |
| query_pdb_info            | [X]       | [OK]     | [OK]    |
| show_database_status      | [OK]       | [OK]     | [OK]    |

## Error Handling

All functions include error handling:

- Return appropriate exit codes
- Log errors using `log_error()` from common.sh
- Gracefully handle missing or inaccessible views
- Validate environment (ORACLE_HOME, ORACLE_SID)

## Examples

### Basic Status Check

```bash
#!/usr/bin/env bash
source /opt/oradba/lib/common.sh
source /opt/oradba/lib/db_functions.sh

if check_database_connection; then
    show_database_status
else
    log_error "Cannot connect to database"
    exit 1
fi
```

### State-Specific Queries

```bash
#!/usr/bin/env bash
source /opt/oradba/lib/common.sh
source /opt/oradba/lib/db_functions.sh

mode=$(get_database_open_mode)

case "$mode" in
    NOMOUNT)
        echo "Database is in NOMOUNT state"
        query_instance_info
        ;;
    MOUNT)
        echo "Database is mounted"
        query_instance_info
        query_database_info
        ;;
    OPEN)
        echo "Database is open"
        show_database_status  # Shows everything
        ;;
    *)
        log_error "Unknown database state: $mode"
        exit 1
        ;;
esac
```

### Custom Status Display

```bash
#!/usr/bin/env bash
source /opt/oradba/lib/common.sh
source /opt/oradba/lib/db_functions.sh

# Get mode first
mode=$(get_database_open_mode)
echo "Database Mode: $mode"

# Get instance info (works at any state)
instance_info=$(query_instance_info)
instance_name=$(echo "$instance_info" | grep INSTANCE_NAME | cut -d: -f2 | xargs)
startup_time=$(echo "$instance_info" | grep STARTUP_TIME | cut -d: -f2- | xargs)
uptime=$(format_uptime "$startup_time")

echo "Instance: $instance_name"
echo "Uptime: $uptime"

# Get database info if mounted
if [[ "$mode" != "NOMOUNT" ]]; then
    db_info=$(query_database_info)
    db_name=$(echo "$db_info" | grep "^DATABASE_NAME" | cut -d: -f2 | xargs)
    log_mode=$(echo "$db_info" | grep LOG_MODE | cut -d: -f2 | xargs)
    echo "Database: $db_name"
    echo "Archive Mode: $log_mode"
fi

# Get performance metrics if open
if [[ "$mode" == "OPEN" ]]; then
    memory=$(query_memory_usage)
    sga=$(echo "$memory" | grep SGA_SIZE | cut -d: -f2 | xargs)
    echo "SGA: ${sga} MB"
    
    sessions=$(query_sessions_info)
    total=$(echo "$sessions" | grep TOTAL_SESSIONS | cut -d: -f2 | xargs)
    echo "Sessions: $total"
fi
```

## Testing

The library includes comprehensive test coverage in `tests/test_db_functions.bats`:

```bash
# Run all database function tests
bats tests/test_db_functions.bats

# Run specific test
bats tests/test_db_functions.bats -f "check_database_connection"
```

## Utility Scripts

### Long Operations Monitoring

Monitor long-running database operations from v$session_longops:

**longops.sh** - Generic monitoring with watch mode:

```bash
# Monitor all operations
longops.sh

# Filter by operation pattern
longops.sh -o "RMAN%"          # RMAN operations only
longops.sh -o "%EXP%"          # DataPump exports
longops.sh -o "%IMP%"          # DataPump imports

# Watch mode (continuous monitoring)
longops.sh -w                  # Default 5-second refresh
longops.sh -w -i 10            # 10-second refresh interval
```

**Convenience wrappers:**

```bash
rman_jobs.sh                   # Monitor RMAN operations
rman_jobs.sh -w                # Continuous RMAN monitoring
exp_jobs.sh                    # Monitor DataPump exports
imp_jobs.sh -w                 # Monitor DataPump imports
```

### Wallet Password Utility

Extract passwords from Oracle Wallet using mkstore:

**get_seps_pwd.sh** - Wallet password extraction:

```bash
# Extract specific entry
get_seps_pwd.sh -w /path/to/wallet -e entry_name

# List all entries (debug mode)
get_seps_pwd.sh -w /path/to/wallet -d

# Use encoded password file
get_seps_pwd.sh -w /path/to/wallet -e entry -f pwd.enc
```

### Peer Synchronization

Distribute files across database peer hosts using rsync:

**sync_to_peers.sh** - Distribute from local to peers:

```bash
# Sync file to all peers
sync_to_peers.sh /opt/oracle/wallet/cwallet.sso

# Sync directory (with trailing slash)
sync_to_peers.sh /opt/oracle/network/admin/

# Dry run with verbose output
sync_to_peers.sh -n -v /etc/oracle/tnsnames.ora

# Delete remote files not present locally
sync_to_peers.sh -D /opt/oracle/wallet/
```

**sync_from_peers.sh** - Pull from peer and distribute:

```bash
# Sync from specific peer to all others
sync_from_peers.sh -p db01 /opt/oracle/wallet

# Specify remote base path
sync_from_peers.sh -p db01 -r /tmp/backup /opt/oracle/admin

# Dry run verbose mode
sync_from_peers.sh -p db01 -n -v /etc/oracle/oratab
```

**Configuration:**

Both sync scripts support configuration via:

- Environment variables: `PEER_HOSTS`, `SSH_USER`, `SSH_PORT`
- Config files: `${ORADBA_ETC}/sync_*.conf`
- Command line: `-H "host1 host2"`, `-c config.conf`

## See Also

- [Usage Guide](16-usage.md) - Including dbstatus.sh usage
- [Environment Management](04-environment.md) - Environment setup with status
- [Configuration](05-configuration.md) - Function behavior settings

## Navigation

**Previous:** [RMAN Script Templates](09-rman-scripts.md)  
**Next:** [rlwrap Filter Configuration](11-rlwrap.md)
