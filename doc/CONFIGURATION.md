# OraDBA Configuration System

OraDBA uses a hierarchical configuration system that allows flexible customization at multiple levels. Configuration files are loaded in a specific order, with later files overriding earlier settings.

## Configuration Hierarchy

### Loading Order

1. **oradba_core.conf** - Core system settings (required)
2. **oradba_standard.conf** - Standard environment and aliases (required)
3. **oradba_customer.conf** - Customer-specific overrides (optional)
4. **sid._DEFAULT_.conf** - Default SID settings (optional)
5. **sid.<ORACLE_SID>.conf** - SID-specific configuration (optional, auto-created)

Later configurations override earlier ones, allowing you to customize settings at each level without modifying the base configuration.

## Configuration Files

### 1. oradba_core.conf

**Purpose:** Core system settings that control OraDBA behavior

**Location:** `${ORADBA_PREFIX}/etc/oradba_core.conf`

**Key Settings:**

```bash
# Installation prefix
ORADBA_PREFIX="/opt/oradba"

# Configuration directory
ORADBA_CONFIG_DIR="${ORADBA_PREFIX}/etc"

# Oratab location
ORATAB_FILE="/etc/oratab"

# Behavior settings
DEBUG="0"
ORADBA_LOAD_ALIASES="true"
ORADBA_SHOW_DB_STATUS="true"
ORADBA_AUTO_CREATE_SID_CONFIG="true"

# Logging
LOG_DIR="${ORADBA_PREFIX}/logs"
LOG_LEVEL="INFO"

# Directories
BACKUP_DIR="/backup"
RECOVERY_DIR="${ORADBA_PREFIX}/rcv"
```

**When to Edit:** Rarely. Only modify if you need to change installation paths, logging behavior, or core features.

### 2. oradba_standard.conf

**Purpose:** Standard Oracle environment variables and simple aliases

**Location:** `${ORADBA_PREFIX}/etc/oradba_standard.conf`

**Key Settings:**

```bash
# Oracle directories
ORACLE_BASE="/u01/app/oracle"
TNS_ADMIN=""  # Defaults to $ORACLE_HOME/network/admin

# NLS settings
NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
NLS_TIMESTAMP_FORMAT="YYYY-MM-DD HH24:MI:SS.FF"

# SQL*Plus paths
SQLPATH="${ORADBA_PREFIX}/sql"
ORACLE_PATH="${ORADBA_PREFIX}/sql"

# rlwrap configuration
RLWRAP_COMMAND="rlwrap"
RLWRAP_OPTS="-i -c -f $ORACLE_HOME/bin/sqlplus"

# Simple aliases (defined in this file)
alias sq='sqlplus / as sysdba'
alias cdoh='cd ${ORACLE_HOME}'
# ... etc
```

**When to Edit:** Generally not recommended. Override settings in `oradba_customer.conf` instead.

### 3. oradba_customer.conf

**Purpose:** Customer-specific configuration overrides

**Location:** `${ORADBA_PREFIX}/etc/oradba_customer.conf`

**Template:** `${ORADBA_PREFIX}/etc/oradba_customer.conf.example`

**Example Configuration:**

```bash
# Override default Oracle base
ORACLE_BASE="/u02/app/oracle"

# Use German locale
NLS_LANG="GERMAN_GERMANY.AL32UTF8"
NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"

# Custom backup location
BACKUP_DIR="/backup/oracle"

# Disable automatic database status display
ORADBA_SHOW_DB_STATUS="false"

# Custom aliases
alias sqdev='sqlplus user/pass@dev'
alias cdarch='cd /backup/oracle/archive'
```

**When to Edit:** This is the recommended file for customization. Copy from the .example template and modify as needed.

### 4. sid._DEFAULT_.conf

**Purpose:** Default settings for all SIDs (unless overridden by SID-specific config)

**Location:** `${ORADBA_PREFIX}/etc/sid._DEFAULT_.conf`

**Example Configuration:**

```bash
# Default database settings
ORADBA_DB_NAME="${ORACLE_SID}"
ORADBA_DB_UNIQUE_NAME="${ORACLE_SID}"
ORADBA_DBID=""
ORADBA_DB_ROLE="PRIMARY"

# Default connection settings
ORADBA_CONNECT_TYPE="LOCAL"

# Default backup settings
ORADBA_DB_BACKUP_DIR="${BACKUP_DIR}/${ORACLE_SID}"
ORADBA_BACKUP_RETENTION=7
```

**When to Edit:** Modify to set defaults that apply to all databases in your environment.

### 5. sid.<ORACLE_SID>.conf

**Purpose:** SID-specific configuration with database metadata

**Location:** `${ORADBA_PREFIX}/etc/sid.<ORACLE_SID>.conf`

**Auto-Creation:** Automatically created on first environment switch if `ORADBA_AUTO_CREATE_SID_CONFIG=true`

**Example (sid.ORCL.conf):**

```bash
# Database Identity (populated from v$database)
ORADBA_DB_NAME="ORCL"
ORADBA_DB_UNIQUE_NAME="ORCL"
ORADBA_DBID="1234567890"
ORADBA_DB_ROLE="PRIMARY"
ORADBA_DB_VERSION="19.0.0.0.0"
ORADBA_DB_OPEN_MODE="READ WRITE"

# NLS Settings (override defaults)
NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"

# Connection Settings
ORADBA_TNS_ALIAS="ORCL"
ORADBA_CONNECT_TYPE="LOCAL"

# Database-Specific Paths (from v$parameter)
ORADBA_DIAGNOSTIC_DEST="/u01/app/oracle/diag/rdbms/orcl/ORCL"
ORADBA_ARCHIVE_DEST="/u01/app/oracle/archive/ORCL"
ORADBA_DB_BACKUP_DIR="/backup/ORCL"

# Backup Settings
ORADBA_BACKUP_RETENTION=7
ORADBA_BACKUP_TYPE="INCREMENTAL"
ORADBA_BACKUP_COMPRESSION="MEDIUM"
```

**When to Edit:** Customize settings for specific databases. Auto-created configs include database metadata queried from v$database and v$parameter.

## Configuration Loading Process

### When Configuration is Loaded

Configuration files are loaded when you set your Oracle environment:

```bash
source oraenv.sh ORCL
```

### Loading Sequence

1. **Initial Load:** `oradba_core.conf` is loaded when oraenv.sh is sourced
2. **After ORACLE_SID Set:** Full hierarchical configuration is loaded via `load_config()`
3. **Order:** core → standard → customer → default → sid-specific
4. **Override Behavior:** Later values replace earlier ones

### Debug Mode

Enable debug mode to see configuration loading details:

```bash
DEBUG=1 source oraenv.sh ORCL
```

Output includes:
```
[DEBUG] Loading OraDBA configuration for SID: ORCL
[DEBUG] Loading core config: /opt/oradba/etc/oradba_core.conf
[DEBUG] Loading standard config: /opt/oradba/etc/oradba_standard.conf
[DEBUG] Loading customer config: /opt/oradba/etc/oradba_customer.conf
[DEBUG] Loading default SID config: /opt/oradba/etc/sid._DEFAULT_.conf
[DEBUG] Loading SID config: /opt/oradba/etc/sid.ORCL.conf
[DEBUG] Configuration loading complete
```

## Dynamic Alias Generation

### aliases.sh

**Location:** `${ORADBA_PREFIX}/lib/aliases.sh`

**Purpose:** Functions for generating SID-specific dynamic aliases

**Sourced From:** `oradba_standard.conf` (if `ORADBA_LOAD_ALIASES=true`)

**Key Functions:**

- `get_diagnostic_dest()` - Query database for diagnostic_dest or use fallback
- `has_rlwrap()` - Check if rlwrap is available
- `generate_sid_aliases()` - Generate SID-specific aliases (taa, vaa, cdda, cdta, cdaa)

**Auto-Execution:** `generate_sid_aliases()` is called automatically if ORACLE_SID is set

## Customization Examples

### Example 1: Disable Aliases Globally

Edit `oradba_core.conf`:

```bash
ORADBA_LOAD_ALIASES="false"
```

### Example 2: Custom NLS Settings Per SID

Create `oradba_customer.conf`:

```bash
# Default to US settings
NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
```

Create `sid.DEVDB.conf`:

```bash
# German settings for DEVDB
NLS_LANG="GERMAN_GERMANY.WE8ISO8859P15"
NLS_DATE_FORMAT="DD.MM.YYYY"
```

### Example 3: Custom Backup Paths

Edit `sid._DEFAULT_.conf`:

```bash
# All databases backup to SAN
ORADBA_DB_BACKUP_DIR="/san/backup/${ORACLE_SID}"
ORADBA_BACKUP_RETENTION=14
```

Override for specific SID in `sid.PRODDB.conf`:

```bash
# Production has 30-day retention
ORADBA_BACKUP_RETENTION=30
ORADBA_BACKUP_COMPRESSION="HIGH"
```

### Example 4: Site-Specific Oratab Location

Edit `oradba_core.conf`:

```bash
ORATAB_FILE="/u01/app/oracle/oratab"

ORATAB_ALTERNATIVES=(
    "/u01/app/oracle/oratab"
    "/etc/oratab"
    "${HOME}/.oratab"
)
```

## Auto-Created SID Configurations

### When Auto-Creation Occurs

If `ORADBA_AUTO_CREATE_SID_CONFIG=true` (default), OraDBA automatically creates a SID-specific configuration file on first environment switch for a new ORACLE_SID.

### Database Metadata Queried

The `create_sid_config()` function queries the database for:

From **v$database:**
- `name` → ORADBA_DB_NAME
- `db_unique_name` → ORADBA_DB_UNIQUE_NAME
- `dbid` → ORADBA_DBID
- `database_role` → ORADBA_DB_ROLE
- `open_mode` → ORADBA_DB_OPEN_MODE

From **v$parameter:**
- `diagnostic_dest` → ORADBA_DIAGNOSTIC_DEST

### Fallback Behavior

If database is not accessible during auto-creation:
- Metadata fields are populated with defaults
- `ORADBA_DIAGNOSTIC_DEST` uses convention: `${ORACLE_BASE}/diag/rdbms/${sid,,}/${sid}`
- Configuration file is still created for future customization

### Manual Creation

You can manually create SID configurations using the template:

```bash
cp ${ORADBA_PREFIX}/etc/sid.ORCL.conf.example ${ORADBA_PREFIX}/etc/sid.MYDB.conf
# Edit sid.MYDB.conf as needed
```

## Configuration Variables Reference

### Core System Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ORADBA_PREFIX | /opt/oradba | Installation base directory |
| ORADBA_CONFIG_DIR | ${ORADBA_PREFIX}/etc | Configuration directory |
| ORATAB_FILE | /etc/oratab | Oratab file location |
| DEBUG | 0 | Debug mode (0=off, 1=on) |
| LOG_DIR | ${ORADBA_PREFIX}/logs | Log directory |
| LOG_LEVEL | INFO | Log level (DEBUG, INFO, WARN, ERROR) |
| BACKUP_DIR | /backup | Default backup directory |
| RECOVERY_DIR | ${ORADBA_PREFIX}/rcv | Recovery scripts directory |

### Behavior Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ORADBA_LOAD_ALIASES | true | Load aliases and functions |
| ORADBA_SHOW_DB_STATUS | true | Show database status on environment switch |
| ORADBA_AUTO_CREATE_SID_CONFIG | true | Auto-create SID configurations |

### Oracle Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ORACLE_BASE | /u01/app/oracle | Oracle base directory |
| TNS_ADMIN | ${ORACLE_HOME}/network/admin | TNS configuration directory |
| NLS_LANG | AMERICAN_AMERICA.AL32UTF8 | NLS language and character set |
| NLS_DATE_FORMAT | YYYY-MM-DD HH24:MI:SS | Date format |
| NLS_TIMESTAMP_FORMAT | YYYY-MM-DD HH24:MI:SS.FF | Timestamp format |
| SQLPATH | ${ORADBA_PREFIX}/sql | SQL*Plus script path |
| ORACLE_PATH | ${ORADBA_PREFIX}/sql | Oracle script search path |

### Database Metadata Variables (SID-specific)

| Variable | Source | Description |
|----------|--------|-------------|
| ORADBA_DB_NAME | v$database.name | Database name |
| ORADBA_DB_UNIQUE_NAME | v$database.db_unique_name | Database unique name (Data Guard) |
| ORADBA_DBID | v$database.dbid | Database ID |
| ORADBA_DB_ROLE | v$database.database_role | Database role (PRIMARY, STANDBY, etc.) |
| ORADBA_DB_VERSION | v$instance.version | Database version |
| ORADBA_DB_OPEN_MODE | v$database.open_mode | Database open mode |
| ORADBA_DIAGNOSTIC_DEST | v$parameter (diagnostic_dest) | Diagnostic destination directory |

### Connection Variables (SID-specific)

| Variable | Default | Description |
|----------|---------|-------------|
| ORADBA_TNS_ALIAS | ${ORACLE_SID} | TNS alias for connection |
| ORADBA_CONNECT_TYPE | LOCAL | Connection type (LOCAL, TNS, EZCONNECT) |

### Backup Variables (SID-specific)

| Variable | Default | Description |
|----------|---------|-------------|
| ORADBA_DB_BACKUP_DIR | ${BACKUP_DIR}/${ORACLE_SID} | Database backup directory |
| ORADBA_BACKUP_RETENTION | 7 | Backup retention (days) |
| ORADBA_BACKUP_TYPE | INCREMENTAL | Backup type (FULL, INCREMENTAL) |
| ORADBA_BACKUP_COMPRESSION | MEDIUM | Compression level (BASIC, LOW, MEDIUM, HIGH) |

### rlwrap Variables

| Variable | Default | Description |
|----------|---------|-------------|
| RLWRAP_COMMAND | rlwrap | rlwrap executable |
| RLWRAP_OPTS | -i -c -f $ORACLE_HOME/bin/sqlplus | rlwrap options |

## Troubleshooting

### Configuration Not Loading

1. **Check file permissions:**
   ```bash
   ls -l ${ORADBA_PREFIX}/etc/oradba_*.conf
   ```

2. **Enable debug mode:**
   ```bash
   DEBUG=1 source oraenv.sh ORCL
   ```

3. **Verify ORADBA_PREFIX:**
   ```bash
   echo $ORADBA_PREFIX
   ```

### SID Configuration Not Auto-Created

1. **Check auto-creation setting:**
   ```bash
   grep ORADBA_AUTO_CREATE_SID_CONFIG ${ORADBA_PREFIX}/etc/oradba_core.conf
   ```

2. **Check database connectivity:**
   ```bash
   sqlplus -S / as sysdba <<< "SELECT 1 FROM dual;"
   ```

3. **Manually create if needed:**
   ```bash
   cp ${ORADBA_PREFIX}/etc/sid.ORCL.conf.example ${ORADBA_PREFIX}/etc/sid.MYDB.conf
   ```

### Override Not Taking Effect

Check the loading order. Remember that later configs override earlier ones:

```bash
# This will NOT work (core loads before customer)
# In oradba_core.conf:
BACKUP_DIR="/backup"

# In oradba_customer.conf:
BACKUP_DIR="/custom/backup"  # This WILL take effect
```

### Variables Not Persisting

Configuration files are sourced (not exported) during environment setup. Some variables may need explicit export:

```bash
# In oradba_customer.conf:
export MY_CUSTOM_VAR="value"
```

## See Also

- [Aliases Guide](ALIASES.md) - Shell aliases documentation
- [Usage Guide](USAGE.md) - Complete OraDBA usage documentation
- [Development Guide](DEVELOPMENT.md) - Configuration testing
- [Quick Start](../doc/QUICKSTART.md) - Getting started with OraDBA
