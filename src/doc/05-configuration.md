# Configuration System

**Purpose:** Comprehensive guide to OraDBA's hierarchical configuration system - the canonical reference for all
configuration files, variables, and customization options.

**Audience:** Users who need to customize OraDBA behavior, paths, or database-specific settings.

## Introduction

OraDBA uses a hierarchical configuration system that allows flexible
customization at multiple levels. This chapter explains how to configure OraDBA
to match your environment and preferences.

## Configuration Hierarchy

Configuration files are loaded in a specific order, with later files overriding earlier settings:

1. **oradba_core.conf** - Core system settings (required, don't modify)
2. **oradba_standard.conf** - Standard environment and aliases (required, don't modify)  
3. **oradba_customer.conf** - Your global custom settings (optional, **recommended for customization**)
4. **sid._DEFAULT_.conf** - Default settings for all databases (optional)
5. **sid.<ORACLE_SID>.conf** - Database-specific settings (optional, auto-created)

![Configuration Hierarchy](images/config-hierarchy.png)

The diagram illustrates the 5-level configuration hierarchy with override
relationships. Later configurations override earlier settings, allowing flexible
customization without modifying base files.

![Configuration Load Sequence](images/config-sequence.png)

The sequence diagram shows the step-by-step process of loading and applying configurations during environment setup.

This hierarchical approach means:

- Base settings work everywhere
- You can customize globally or per-database
- Your customizations survive updates
- Later configurations override earlier ones

## Configuration Files

### oradba_core.conf - Core System Settings

**Location:** `${ORADBA_PREFIX}/etc/oradba_core.conf`

**Purpose:** Core system settings that control OraDBA behavior

**Key Settings:**

```bash
# Installation paths
ORADBA_PREFIX="/opt/oradba"                    # Installation directory
ORADBA_LOCAL_BASE="/opt"                       # Parent directory (auto-detected)
ORADBA_BASE="${ORADBA_PREFIX}"                 # Alias for TVD BasEnv compatibility
ORADBA_CONFIG_DIR="${ORADBA_PREFIX}/etc"
ORADBA_BIN_DIR="${ORADBA_PREFIX}/bin"
ORATAB_FILE="/etc/oratab"

# Behavior control
DEBUG="0"                                      # Legacy debug mode (use ORADBA_DEBUG instead)
ORADBA_DEBUG="false"                           # Debug mode for detailed output
ORADBA_LOAD_ALIASES="true"
ORADBA_SHOW_DB_STATUS="true"
ORADBA_AUTO_CREATE_SID_CONFIG="true"

# Directories
LOG_DIR="${ORADBA_PREFIX}/log"
BACKUP_DIR="/backup"
RECOVERY_DIR="${ORADBA_PREFIX}/rcv"
```

**Path Variables Explained:**

- **ORADBA_PREFIX**: Main installation directory (e.g., `/opt/oracle/local/oradba`)
- **ORADBA_LOCAL_BASE**: Parent "local" directory, auto-detected from:
  - `${ORACLE_BASE}/local` if ORACLE_BASE is set
  - Parent directory of ORADBA_PREFIX otherwise
  - Used by `cdl` alias to navigate to shared tools directory
- **ORADBA_BASE**: Alias to ORADBA_PREFIX for compatibility when installed alongside TVD BasEnv
- **ORADBA_BIN_DIR**: Binary directory, automatically added to PATH

**When to Edit:** Rarely. Only modify if changing installation paths or core
features. Most settings should be overridden in customer config instead.

### oradba_standard.conf - Standard Settings

**Location:** `${ORADBA_PREFIX}/etc/oradba_standard.conf`

**Purpose:** Standard Oracle environment variables and simple aliases

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
ORADBA_RLWRAP_FILTER="false"  # Enable password filtering

# Simple aliases defined here
alias sq='sqlplus / as sysdba'
alias cdh='cd ${ORACLE_HOME}'
# ... and 50+ more aliases
```

**When to Edit:** Not recommended. Override settings in `oradba_customer.conf`
instead to preserve your changes during updates.

### oradba_customer.conf - Your Customizations ⭐

**Location:** `${ORADBA_PREFIX}/etc/oradba_customer.conf`

**Template:** `${ORADBA_PREFIX}/etc/oradba_customer.conf.example`

**Purpose:** **This is the recommended file for your customizations**

**Example Configuration:**

```bash
# ==============================================================================
# Customer Configuration
# ==============================================================================
# This file is loaded after core and standard configs, allowing you to
# override defaults without modifying base files.

# --- Oracle Environment ---

# Override default Oracle base
ORACLE_BASE="/u02/app/oracle"

# Custom TNS_ADMIN location
TNS_ADMIN="/u01/app/oracle/network/admin"

# --- NLS Settings ---

# Use German locale
NLS_LANG="GERMAN_GERMANY.AL32UTF8"
NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"

# --- Directories ---

# Custom backup location
BACKUP_DIR="/backup/oracle"
LOG_DIR="/var/log/oracle"

# --- Behavior ---

# Disable automatic database status display
ORADBA_SHOW_DB_STATUS="false"

# Enable debug mode (shows detailed configuration loading, SID creation, etc.)
ORADBA_DEBUG="true"

# Legacy debug mode (deprecated, use ORADBA_DEBUG)
# DEBUG="1"

# Disable alias loading
ORADBA_LOAD_ALIASES="false"

# Disable auto-creation of SID configurations
# ORADBA_AUTO_CREATE_SID_CONFIG="false"

# --- rlwrap ---

# Enable password filtering
ORADBA_RLWRAP_FILTER="true"

# --- Custom Aliases ---

# Development environment shortcuts
alias sqdev='sqlplus username/password@devdb'
alias cdarch='cd /backup/oracle/archive'
alias mytail='tail -f /var/log/oracle/myapp.log'

# Custom functions
backup_config() {
    cp ${ORADBA_ETC}/*.conf /backup/config/
}

# --- Custom Variables ---

export CUSTOM_APP_HOME="/u01/app/custom"
export PATH="${CUSTOM_APP_HOME}/bin:${PATH}"
```

**When to Edit:** This is where you should make all your customizations! Copy from the `.example` template:

```bash
cp ${ORADBA_PREFIX}/etc/oradba_customer.conf.example \
   ${ORADBA_PREFIX}/etc/oradba_customer.conf

# Edit with your settings
vi ${ORADBA_PREFIX}/etc/oradba_customer.conf
```

### sid._DEFAULT_.conf - Database Defaults

**Location:** `${ORADBA_PREFIX}/etc/sid._DEFAULT_.conf`

**Purpose:** Default settings that apply to all databases (unless overridden per-SID)

**Example Configuration:**

```bash
# ==============================================================================
# Default Database Configuration
# Applied to all SIDs unless overridden in sid.<ORACLE_SID>.conf
# ==============================================================================

# --- Database Identity ---
ORADBA_DB_NAME="${ORACLE_SID}"
ORADBA_DB_UNIQUE_NAME="${ORACLE_SID}"
ORADBA_DB_ROLE="PRIMARY"
ORADBA_CONNECT_TYPE="LOCAL"

# --- Backup Settings ---
ORADBA_DB_BACKUP_DIR="${BACKUP_DIR}/${ORACLE_SID}"
ORADBA_BACKUP_RETENTION=7
ORADBA_BACKUP_TYPE="INCREMENTAL"
ORADBA_BACKUP_COMPRESSION="MEDIUM"

# --- Diagnostic Settings ---
ORADBA_DIAGNOSTIC_DEST="${ORACLE_BASE}/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}"
ORADBA_ARCHIVE_DEST="/u01/app/oracle/archive/${ORACLE_SID}"
```

**When to Edit:** Modify to set defaults that apply to all your databases.
Individual databases can override in their own sid configs.

### sid.<ORACLE_SID>.conf - Database-Specific Settings

**Location:** `${ORADBA_PREFIX}/etc/sid.<ORACLE_SID>.conf`

**Purpose:** Settings specific to one database, with auto-populated metadata

**Auto-Creation:** Automatically created on first environment switch if `ORADBA_AUTO_CREATE_SID_CONFIG=true`

**Example (sid.FREE.conf):**

```bash
# ==============================================================================
# OraDBA SID Configuration: FREE
# Auto-created: 2025-12-18 10:30:00
# Last updated: 2025-12-18 10:30:00
# ==============================================================================

# --- Database Identity (Auto-populated from v$database) ---
ORADBA_DB_NAME="FREE"
ORADBA_DB_UNIQUE_NAME="FREE"
ORADBA_DBID="3456789012"
ORADBA_DB_ROLE="PRIMARY"
ORADBA_DB_VERSION="19.0.0.0.0"
ORADBA_DB_OPEN_MODE="READ WRITE"

# --- Connection Settings ---
ORADBA_TNS_ALIAS="FREE"
ORADBA_CONNECT_TYPE="LOCAL"

# --- Diagnostic Paths (Auto-populated from v$parameter) ---
ORADBA_DIAGNOSTIC_DEST="/u01/app/oracle/diag/rdbms/free/FREE"
ORADBA_ARCHIVE_DEST="/u01/app/oracle/archive/FREE"

# --- Backup Settings (Can be customized) ---
ORADBA_DB_BACKUP_DIR="/backup/FREE"
ORADBA_BACKUP_RETENTION=7
ORADBA_BACKUP_TYPE="INCREMENTAL"
ORADBA_BACKUP_COMPRESSION="MEDIUM"

# --- Custom Settings ---
# Add your database-specific customizations here

# Example: Special NLS settings for this database
# NLS_LANG="GERMAN_GERMANY.AL32UTF8"

# Example: Custom backup retention for production
# ORADBA_BACKUP_RETENTION=30
```

**When to Edit:** Add database-specific customizations. The auto-populated
metadata helps document your database but can be manually adjusted if needed.

## Configuration Loading Process

### When Configuration is Loaded

Configuration files are loaded when you set your environment:

```bash
$ source oraenv.sh FREE

# Loading sequence:
# 1. oradba_core.conf (core settings)
# 2. oradba_standard.conf (standard environment)
# 3. oradba_customer.conf (your global settings)
# 4. sid._DEFAULT_.conf (database defaults)
# 5. sid.FREE.conf (FREE-specific settings)
```

### Debug Configuration Loading

Enable debug mode to see detailed information about configuration loading and SID creation:

```bash
$ export ORADBA_DEBUG=true
$ source oraenv.sh FREE

[DEBUG] Loading OraDBA configuration for SID: FREE
[DEBUG] Loading core config: /opt/oradba/etc/oradba_core.conf
[DEBUG] Loading standard config: /opt/oradba/etc/oradba_standard.conf
[DEBUG] Loading customer config: /opt/oradba/etc/oradba_customer.conf
[DEBUG] Loading default SID config: /opt/oradba/etc/sid._DEFAULT_.conf
[DEBUG] Auto-create enabled, config_dir=/opt/oradba/etc, template should be at: /opt/oradba/etc/sid.ORACLE_SID.conf.example
[DEBUG] create_sid_config called with SID=FREE
[DEBUG] Will create: /opt/oradba/etc/sid.FREE.conf from template: /opt/oradba/etc/sid.ORACLE_SID.conf.example
[INFO] Auto-creating SID configuration for FREE...
[INFO] ✓ Created SID configuration: /opt/oradba/etc/sid.FREE.conf
[DEBUG] Loading newly created SID config: /opt/oradba/etc/sid.FREE.conf
[DEBUG] Configuration loading complete
```

**Debug Output Includes:**

- Configuration file loading sequence
- Template paths and file creation details
- Dummy SID detection and skipping logic
- Variable resolution and overrides

**Legacy DEBUG Variable:**
The old `DEBUG=1` variable still works but is deprecated. Use `ORADBA_DEBUG=true` for consistent boolean behavior.

## Auto-Created SID Configurations

### How Auto-Creation Works

When you switch to a new ORACLE_SID for the first time, OraDBA automatically
creates a SID-specific configuration file from a template.

**Default Behavior:**

- **Enabled by default** (`ORADBA_AUTO_CREATE_SID_CONFIG=true`)
- **Only for real SIDs** - Skips dummy SIDs (oratab entries with startup flag `D`)
- **Template-based** - Uses `sid.ORACLE_SID.conf.example` as the base
- **No database queries** - Uses placeholders from template, not live data

**Example Output:**

```bash
$ free  # First time switching to FREE instance

[INFO] Auto-creating SID configuration for FREE...
[INFO] ✓ Created SID configuration: /opt/oracle/local/oradba/etc/sid.FREE.conf
```

**What Gets Created:**

The auto-creation process:

1. Checks if SID is in `ORADBA_REALSIDLIST` (not a dummy SID)
2. Copies `sid.ORACLE_SID.conf.example` template
3. Replaces `ORCL` with actual SID name (uppercase and lowercase)
4. Updates date stamp and creation timestamp
5. Creates `sid.${ORACLE_SID}.conf` in the configuration directory

**Dummy SID Support:**

Dummy SIDs (used for environment setup before database creation) are automatically skipped:

```bash
# /etc/oratab
FREE:/opt/oracle/product/19c/dbhome:N      # Real DB - config will be auto-created
rdbms26:/opt/oracle/product/26ai/dbhome:D  # Dummy - skipped (only visible in debug mode)
```

**Template Content:**

The template includes static metadata placeholders:

- `ORADBA_DB_NAME="ORCL"` → Replaced with actual SID
- `ORADBA_DB_UNIQUE_NAME="ORCL"` → Replaced with actual SID
- `ORADBA_DBID=""` → Empty, can be filled manually
- NLS settings and backup configuration defaults

**Disabling Auto-Creation:**

```bash
# In oradba_customer.conf or environment
export ORADBA_AUTO_CREATE_SID_CONFIG=false

# Or temporarily:
ORADBA_AUTO_CREATE_SID_CONFIG=false source oraenv.sh FREE
```

**Manual Creation:**

You can also manually create SID configurations:

```bash
# Copy template
cp ${ORADBA_PREFIX}/etc/sid.ORACLE_SID.conf.example \
   ${ORADBA_PREFIX}/etc/sid.MYDB.conf

# Edit with your settings
vi ${ORADBA_PREFIX}/etc/sid.MYDB.conf

# Update ORCL references to your SID
sed -i 's/ORCL/MYDB/g' ${ORADBA_PREFIX}/etc/sid.MYDB.conf
```

### Static vs Dynamic Metadata

**Important:** The SID configuration file tracks only **static metadata** (values that rarely change):

**Static (stored in SID config):**

- Database name
- DB unique name
- DBID
- Database version
- NLS settings
- Backup/recovery paths

**Dynamic (queried at runtime):**

- Database role (PRIMARY/STANDBY)
- Open mode (READ WRITE/READ ONLY/MOUNTED)
- Instance status
- Session counts
- Memory sizes

This design ensures configurations remain valid even when database state changes (e.g., Data Guard switchover).

- `version` → ORADBA_DB_VERSION

From `v$parameter`:

- `diagnostic_dest` → ORADBA_DIAGNOSTIC_DEST

### Fallback Behavior

If the database is not accessible:

- Configuration file is still created
- Metadata fields use defaults based on ORACLE_SID
- You can manually update the file later

### Manual Creation

Create a SID configuration manually if needed:

```bash
# Copy from example
cp ${ORADBA_PREFIX}/etc/sid.ORCL.conf.example \
   ${ORADBA_PREFIX}/etc/sid.MYDB.conf

# Edit as needed
vi ${ORADBA_PREFIX}/etc/sid.MYDB.conf
```

## Common Configuration Scenarios

### Scenario 1: Custom Oracle Base

**Problem:** Your Oracle base is not `/u01/app/oracle`

**Solution:** Override in `oradba_customer.conf`:

```bash
# oradba_customer.conf
ORACLE_BASE="/u02/app/oracle"
```

### Scenario 2: Different NLS Settings

**Problem:** Need German locale for all databases

**Solution:** Override in `oradba_customer.conf`:

```bash
# oradba_customer.conf
NLS_LANG="GERMAN_GERMANY.AL32UTF8"
NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"
NLS_TIMESTAMP_FORMAT="DD.MM.YYYY HH24:MI:SS.FF"
```

### Scenario 3: Production Backup Retention

**Problem:** Production database needs 30-day backup retention, others need 7 days

**Solution:** Set default in `sid._DEFAULT_.conf`:

```bash
# sid._DEFAULT_.conf
ORADBA_BACKUP_RETENTION=7
```

Override in `sid.PRODDB.conf`:

```bash
# sid.PRODDB.conf
ORADBA_BACKUP_RETENTION=30
ORADBA_BACKUP_COMPRESSION="HIGH"
```

### Scenario 4: Custom oratab Location

**Problem:** oratab is in non-standard location

**Solution:** Override in `oradba_customer.conf`:

```bash
# oradba_customer.conf
ORATAB_FILE="/u01/app/oracle/oratab"
```

### Scenario 5: Disable Status Display

**Problem:** Don't want automatic status display when switching databases

**Solution:** Override in `oradba_customer.conf`:

```bash
# oradba_customer.conf
ORADBA_SHOW_DB_STATUS="false"
```

You can still manually run `oraup.sh` or `dbstatus.sh` when needed.

### Scenario 6: Enable Password Filtering

**Problem:** Want to hide passwords in rlwrap command history

**Solution:** Enable in `oradba_customer.conf`:

```bash
# oradba_customer.conf
ORADBA_RLWRAP_FILTER="true"
```

See [rlwrap Filter Configuration](11-rlwrap.md) for setup details.

## Configuration Variables Reference

### Core System Variables

| Variable            | Default                | Description                               |
|---------------------|------------------------|-------------------------------------------|
| `ORADBA_PREFIX`     | `/opt/oradba`          | Installation base directory               |
| `ORADBA_CONFIG_DIR` | `${ORADBA_PREFIX}/etc` | Configuration directory                   |
| `ORATAB_FILE`       | `/etc/oratab`          | oratab file location                      |
| `DEBUG`             | `0`                    | Debug mode (deprecated, use ORADBA_DEBUG) |
| `ORADBA_DEBUG`      | `false`                | Debug mode for detailed output            |
| `LOG_DIR`           | `${ORADBA_PREFIX}/log` | Log directory                             |
| `BACKUP_DIR`        | `/backup`              | Default backup directory                  |

### Behavior Variables

| Variable                        | Default | Description                                     |
|---------------------------------|---------|-------------------------------------------------|
| `ORADBA_LOAD_ALIASES`           | `true`  | Load aliases and functions                      |
| `ORADBA_SHOW_DB_STATUS`         | `true`  | Show database status on environment switch      |
| `ORADBA_AUTO_CREATE_SID_CONFIG` | `true`  | Auto-create SID configurations (real SIDs only) |
| `ORADBA_RLWRAP_FILTER`          | `false` | Enable password filtering in rlwrap             |

### Oracle Environment Variables

| Variable          | Default                      | Description                    |
|-------------------|------------------------------|--------------------------------|
| `ORACLE_BASE`     | `/u01/app/oracle`            | Oracle base directory          |
| `TNS_ADMIN`       | `$ORACLE_HOME/network/admin` | TNS configuration directory    |
| `NLS_LANG`        | `AMERICAN_AMERICA.AL32UTF8`  | NLS language and character set |
| `NLS_DATE_FORMAT` | `YYYY-MM-DD HH24:MI:SS`      | Date format                    |
| `SQLPATH`         | `${ORADBA_PREFIX}/sql`       | SQL*Plus script path           |

### Database Metadata (SID-specific, auto-populated)

| Variable                 | Source                        | Description                      |
|--------------------------|-------------------------------|----------------------------------|
| `ORADBA_DB_NAME`         | `v$database.name`             | Database name                    |
| `ORADBA_DB_UNIQUE_NAME`  | `v$database.db_unique_name`   | Unique database name             |
| `ORADBA_DBID`            | `v$database.dbid`             | Database ID                      |
| `ORADBA_DB_ROLE`         | `v$database.database_role`    | Database role (PRIMARY, STANDBY) |
| `ORADBA_DB_VERSION`      | `v$instance.version`          | Database version                 |
| `ORADBA_DIAGNOSTIC_DEST` | `v$parameter.diagnostic_dest` | Diagnostic directory             |

### Backup Variables (SID-specific, customizable)

| Variable                    | Default                       | Description               |
|-----------------------------|-------------------------------|---------------------------|
| `ORADBA_DB_BACKUP_DIR`      | `${BACKUP_DIR}/${ORACLE_SID}` | Database backup directory |
| `ORADBA_BACKUP_RETENTION`   | `7`                           | Backup retention (days)   |
| `ORADBA_BACKUP_TYPE`        | `INCREMENTAL`                 | Backup type               |
| `ORADBA_BACKUP_COMPRESSION` | `MEDIUM`                      | Compression level         |

## Troubleshooting

### Configuration File Not Found

```bash
# Check if file exists
ls -l ${ORADBA_PREFIX}/etc/oradba_customer.conf

# Create from example
cp ${ORADBA_PREFIX}/etc/oradba_customer.conf.example \
   ${ORADBA_PREFIX}/etc/oradba_customer.conf
```

### Override Not Taking Effect

**Problem:** Changed a setting but it's not applied

**Solution:** Check the loading order. Later configs override earlier ones:

```bash
# This will NOT work (wrong file):
# Edit oradba_standard.conf - will be overridden by customer config

# This WILL work (correct file):
# Edit oradba_customer.conf - loaded last, overrides standard
```

Enable debug mode to see which file sets the final value:

```bash
DEBUG=1 source oraenv.sh FREE | grep "MY_VARIABLE"
```

### SID Configuration Not Auto-Created

**Check 1:** Is auto-creation enabled?

```bash
grep ORADBA_AUTO_CREATE_SID_CONFIG ${ORADBA_PREFIX}/etc/oradba_core.conf
```

**Check 2:** Is database accessible?

```bash
source oraenv.sh FREE
sqlplus -S / as sysdba <<< "SELECT 1 FROM dual;"
```

**Check 3:** Does file already exist?

```bash
ls -l ${ORADBA_PREFIX}/etc/sid.FREE.conf
```

**Manual Creation:**

```bash
# Create manually
vi ${ORADBA_PREFIX}/etc/sid.FREE.conf

# Or copy from example
cp ${ORADBA_PREFIX}/etc/sid.ORCL.conf.example \
   ${ORADBA_PREFIX}/etc/sid.FREE.conf
```

### Variables Not Persisting

Configuration files are sourced, not exported. For custom variables to persist
across shells:

```bash
# In oradba_customer.conf:
export MY_CUSTOM_VAR="value"  # Use 'export' for environment variables
```

## Coexistence Mode

### Overview

OraDBA can be installed alongside TVD BasEnv and DB*Star toolsets. When both are present, OraDBA automatically operates in **coexistence mode** with BasEnv having priority.

**Detection:** Auto-detected during installation by checking for:
- `.BE_HOME` file in `${HOME}`
- `.TVDPERL_HOME` file in `${HOME}`
- `BE_HOME` environment variable

**Behavior:** OraDBA becomes a non-invasive add-on, skipping aliases that already exist in BasEnv.

### Configuration File

Coexistence settings are stored in `etc/oradba_local.conf` (auto-generated during installation):

```bash
# ------------------------------------------------------------------------------
# OraDBA Local Configuration
# ------------------------------------------------------------------------------
# Auto-generated during installation

# Coexistence mode (auto-detected)
export ORADBA_COEXIST_MODE="basenv"    # or "standalone"

# Installation metadata
ORADBA_INSTALL_DATE="2026-01-02T10:30:00Z"
ORADBA_INSTALL_VERSION="0.10.5"
ORADBA_INSTALL_METHOD="embedded"
ORADBA_BASENV_DETECTED="yes"

# Force mode: Override coexistence restrictions
# Uncomment to create all OraDBA aliases even when they exist in BasEnv
# Warning: May override BasEnv aliases - use with caution
# export ORADBA_FORCE=1
```

### Coexistence Mode Values

**`standalone` (default):**
- No other toolsets detected
- OraDBA has full control
- All aliases and features enabled

**`basenv`:**
- TVD BasEnv / DB*Star detected
- OraDBA skips conflicting aliases
- BasEnv settings preserved (PS1, BE_HOME, etc.)
- Minimal footprint

### Alias Behavior

In coexistence mode, OraDBA uses "safe alias creation":

| Alias | Standalone Mode | Coexistence Mode |
|-------|----------------|------------------|
| `sq` | Created by OraDBA | Skipped (BasEnv has it) |
| `taa` | Created by OraDBA | Skipped (BasEnv has it) |
| `cdd` | Created by OraDBA | Skipped (BasEnv has it) |
| `oradba` | Created by OraDBA | Created (OraDBA-specific) |
| `dbctl` | Created by OraDBA | Created (OraDBA-specific) |
| `listener` | Created by OraDBA | Created (OraDBA-specific) |

**Result:** You get the best of both worlds - BasEnv's comprehensive aliases plus OraDBA's unique features.

### Force Mode

To override coexistence restrictions and create all OraDBA aliases:

**Enable Force Mode:**

```bash
# Edit local configuration
vi ${ORADBA_PREFIX}/etc/oradba_local.conf

# Uncomment or add:
export ORADBA_FORCE=1

# Re-source environment
source ${ORADBA_PREFIX}/bin/oraenv.sh
```

**When to Use:**
- You prefer OraDBA's alias implementations
- Specific OraDBA features needed
- Testing OraDBA functionality

**Warning:** Force mode may shadow BasEnv aliases. BasEnv commands may behave differently.

### Environment Variables

**Protected Variables (never modified):**
- `BE_HOME` - BasEnv home directory
- `TVDPERL_HOME` - BasEnv Perl location
- `PS1` / `PS1BASH` - Shell prompt
- `TVD_BASE` - BasEnv base directory
- All other BasEnv-specific variables

**OraDBA Variables (namespaced):**
- `ORADBA_PREFIX` - OraDBA installation directory
- `ORADBA_BASE` - Alias to ORADBA_PREFIX
- `ORADBA_COEXIST_MODE` - Coexistence mode setting
- `ORADBA_FORCE` - Force override flag
- All other `ORADBA_*` variables

### Installation Layout

Both toolsets can share the same parent directory:

```bash
/opt/oracle/local/
├── dba/                      # TVD BasEnv (BE_HOME)
│   ├── bin/
│   ├── etc/
│   └── lib/
└── oradba/                   # OraDBA (ORADBA_PREFIX)
    ├── bin/
    ├── etc/
    └── lib/
```

**Benefits:**
- Logical grouping of Oracle tools
- Easy navigation with `cdl` alias
- Shared backup/log directories possible
- Independent updates and configurations

### Checking Coexistence Status

**View current mode:**

```bash
# Check configuration
cat ${ORADBA_PREFIX}/etc/oradba_local.conf | grep COEXIST

# Check environment
echo $ORADBA_COEXIST_MODE

# Check during installation
grep "basenv detected" ${ORADBA_PREFIX}/.install_info
```

**Test alias behavior:**

```bash
# Check if alias exists
type sq

# Check alias definition
alias sq

# In coexistence mode with BasEnv:
# sq would be BasEnv's version or not created by OraDBA
```

### Troubleshooting

**Problem:** Aliases not working after installation

```bash
# Verify coexistence mode is correct
cat ${ORADBA_PREFIX}/etc/oradba_local.conf

# Check if force mode is needed
export ORADBA_FORCE=1
source ${ORADBA_PREFIX}/bin/oraenv.sh
```

**Problem:** Want to switch from coexistence to standalone

```bash
# Edit local config
vi ${ORADBA_PREFIX}/etc/oradba_local.conf

# Change:
export ORADBA_COEXIST_MODE="standalone"

# Re-source
source ${ORADBA_PREFIX}/bin/oraenv.sh
```

**Problem:** Need to reinstall with different mode

```bash
# Reinstall will auto-detect current environment
./oradba_install.sh --force --prefix /opt/oracle/local/oradba
```

## Best Practices

1. **Never modify core or standard configs** - Use customer config for overrides
2. **Use oradba_customer.conf for global settings** - All your customizations in one place
3. **Use sid.\<SID>.conf for database-specific settings** - Per-database customization
4. **Comment your customizations** - Explain why you changed defaults
5. **Backup your configs** - Keep copies of customer and SID configs
6. **Test configuration changes** - Use DEBUG=1 to verify loading
7. **Use version control** - Track configuration changes over time
8. **Document non-obvious settings** - Help future you understand decisions
9. **Respect coexistence mode** - Use force mode sparingly to avoid conflicts
10. **Keep oradba_local.conf intact** - Auto-generated, reflects installation state

## See Also

- [Installation](02-installation.md#parallel-installation-with-tvd-basenv--dbstar) - Parallel installation guide
- [Environment Management](04-environment.md) - How oraenv.sh loads configurations
- [Aliases](06-aliases.md) - Configuring and customizing aliases
- [PDB Aliases](07-pdb-aliases.md) - PDB-specific configuration
- [Troubleshooting](12-troubleshooting.md) - Configuration issues

## Navigation

**Previous:** [Environment Management](04-environment.md)  
**Next:** [Alias Reference](06-aliases.md)
