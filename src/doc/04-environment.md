# Environment Management

**Purpose:** Comprehensive guide to `oraenv.sh` - OraDBA's core component for managing Oracle database environments,
setting variables, and switching between databases.

**Audience:** All users - essential for daily OraDBA use.

## Introduction

This chapter covers the `oraenv.sh` script in detail - OraDBA's core component
for managing Oracle database environments. Learn how to use it effectively in
interactive shells, scripts, and automation.

## oraenv.sh Overview

The `oraenv.sh` script sets up your Oracle environment based on the oratab file.
It configures all necessary environment variables, loads OraDBA configurations,
and can display database status.

**Key features:**

- Intelligent environment setup from oratab
- Interactive SID selection with numbered list
- Silent mode for scripting
- Automatic database status display
- Hierarchical configuration loading
- PDB alias generation for multitenant databases
- Profile integration support

## Basic Usage

### Setting Environment for Specific SID

```bash
# Set environment for FREE database (always use oraenv.sh to avoid conflict with Oracle's oraenv)
source oraenv.sh FREE

# Using full path
source /opt/oradba/bin/oraenv.sh FREE

# For convenience, add an alias to your profile
alias oraenv='source /opt/oradba/bin/oraenv.sh'
```

### Interactive SID Selection

When called without a SID, `oraenv.sh` displays available databases:

```bash
$ source oraenv.sh

Available Oracle SIDs from /etc/oratab:
1) FREE      (/u01/app/oracle/product/19.0.0/dbhome_1)
2) TESTDB    (/u01/app/oracle/product/19.0.0/dbhome_2)
3) PRODDB    (/u01/app/oracle/product/21.0.0/dbhome_1)

Select database (1-3): 1

Setting environment for ORACLE_SID: FREE
[Database status information displayed]
```

**Interactive mode features:**

- Automatically detects TTY for interactive use
- Shows ORACLE_HOME for each SID
- Numbered selection for easy choice
- Validates selection
- Displays status after environment is set

### Silent Mode

For scripts and automation, use silent mode to suppress all output:

```bash
#!/usr/bin/env bash

# Set environment silently (no output)
source oraenv.sh FREE --silent

# Verify environment
if [[ "$ORACLE_SID" != "FREE" ]]; then
    echo "Failed to set environment" >&2
    exit 1
fi

# Continue with database operations
sqlplus / as sysdba <<EOF
    SELECT name FROM v\$database;
    EXIT;
EOF
```

**Silent mode characteristics:**

- No output to stdout or stderr (except errors)
- Skips status display
- Ideal for cron jobs and scripts
- Still sets all environment variables
- Returns appropriate exit codes

### Status Display Only

Display database status without changing environment:

```bash
# Show status for current ORACLE_SID
source oraenv.sh $ORACLE_SID --status

# Show status for different SID (changes environment but focuses on status)
source oraenv.sh FREE --status
```

## Command-Line Options

```bash
source oraenv.sh [ORACLE_SID] [OPTIONS]

Arguments:
  ORACLE_SID       Oracle System Identifier from oratab
                   If omitted, shows interactive selection menu

Options:
  --silent         Silent mode - no output (for scripts)
  --status         Display database status after setting environment
  --force          Force environment setup even if already set
  --help, -h       Display help message
```

## Environment Variables Set

After running `oraenv.sh`, these variables are configured:

### Core Oracle Variables

```bash
ORACLE_SID       # Oracle System Identifier (e.g., FREE)
ORACLE_HOME      # Oracle installation directory
ORACLE_BASE      # Oracle base directory (usually /u01/app/oracle)
ORACLE_UNQNAME   # Unique database name (often same as ORACLE_SID)
```

### Path Variables

```bash
PATH             # Updated with $ORACLE_HOME/bin
LD_LIBRARY_PATH  # Oracle libraries (Linux/Unix)
DYLD_LIBRARY_PATH # Oracle libraries (macOS)
```

### TNS and SQL Variables

```bash
TNS_ADMIN        # TNS configuration directory
                 # Default: $ORACLE_HOME/network/admin
SQLPATH          # SQL*Plus script directory
                 # Default: $ORADBA_PREFIX/sql
ORACLE_PATH      # Alternative to SQLPATH
NLS_LANG         # Language and character set
                 # Default: AMERICAN_AMERICA.AL32UTF8
NLS_DATE_FORMAT  # Date format for SQL*Plus
                 # Default: YYYY-MM-DD HH24:MI:SS
```

### OraDBA Variables

```bash
ORADBA_PREFIX           # OraDBA installation directory
ORADBA_VERSION          # OraDBA version number
ORADBA_CONFIG_DIR       # Configuration directory
ORADBA_ETC              # etc/ directory
ORADBA_LOG              # log/ directory
ORADBA_TEMP             # Temporary directory
ORATAB_FILE             # oratab file location

# SID-specific variables (set after SID config loads)
ORADBA_ORA_ADMIN_SID    # $ORACLE_BASE/admin/$ORACLE_SID
ORADBA_ORA_DIAG_SID     # Diagnostic directory
ORADBA_SID_ALERTLOG     # Alert log file path
ORADBA_DIAGNOSTIC_DEST  # Custom diagnostic destination (if configured)

# Lists (generated from oratab and database)
ORADBA_SIDLIST          # All SIDs from oratab
ORADBA_REALSIDLIST      # Real SIDs (excludes DGMGRL dummy entries)
ORADBA_PDBLIST          # PDBs in current CDB (if applicable)
```

### Verification Commands

```bash
# Check all Oracle environment variables
env | grep ORACLE

# Check OraDBA variables
env | grep ORADBA

# Display current environment summary
oraup.sh
```

## Configuration Loading Sequence

When you source `oraenv.sh`, OraDBA loads configuration files in a hierarchical order:

1. Core configuration (system defaults)
2. Standard configuration (aliases and environment)
3. Customer configuration (your global customizations)
4. Default SID configuration (database defaults)
5. SID-specific configuration (per-database settings)

This allows default settings to work everywhere while enabling customization at multiple levels.

For complete details on the configuration hierarchy, files, and variables, see [Configuration System](05-configuration.md).

## Scripting with oraenv.sh

### Basic Script Template

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Example: Database backup script using OraDBA
# ------------------------------------------------------------------------------

# Exit on error
set -e

# OraDBA configuration
ORADBA_PREFIX="${ORADBA_PREFIX:-/opt/oradba}"
ORACLE_SID="${1:-FREE}"

# Set environment silently
source "${ORADBA_PREFIX}/bin/oraenv.sh" "${ORACLE_SID}" --silent

# Verify environment
if [[ -z "${ORACLE_HOME}" ]]; then
    echo "Error: Failed to set Oracle environment" >&2
    exit 1
fi

# Perform database operations
echo "Backing up database: ${ORACLE_SID}"
rman target / <<RMAN
BACKUP DATABASE;
RMAN

echo "Backup completed successfully"
```

### Error Handling

```bash
#!/usr/bin/env bash

# Function to set environment with error handling
set_oracle_env() {
    local sid="$1"
    local oradba_prefix="${ORADBA_PREFIX:-/opt/oradba}"
    
    # Check if oraenv.sh exists
    if [[ ! -f "${oradba_prefix}/bin/oraenv.sh" ]]; then
        echo "Error: oraenv.sh not found at ${oradba_prefix}/bin/" >&2
        return 1
    fi
    
    # Source oraenv.sh
    # shellcheck source=/dev/null
    source "${oradba_prefix}/bin/oraenv.sh" "${sid}" --silent
    
    # Verify environment was set
    if [[ "${ORACLE_SID}" != "${sid}" ]]; then
        echo "Error: Failed to set environment for ${sid}" >&2
        return 1
    fi
    
    return 0
}

# Usage
if set_oracle_env "FREE"; then
    echo "Environment set successfully for FREE"
    sqlplus / as sysdba <<< "SELECT name FROM v\$database;"
else
    echo "Failed to set environment" >&2
    exit 1
fi
```

### Loop Through Multiple Databases

```bash
#!/usr/bin/env bash

# Load OraDBA
ORADBA_PREFIX="/opt/oradba"
source "${ORADBA_PREFIX}/lib/common.sh"

# Generate SID list
generate_sid_lists "/etc/oratab"

# Loop through all databases
for sid in ${ORADBA_REALSIDLIST}; do
    echo "Processing database: ${sid}"
    
    # Set environment
    source "${ORADBA_PREFIX}/bin/oraenv.sh" "${sid}" --silent
    
    # Run SQL query
    sqlplus -S / as sysdba <<EOF
SET HEADING OFF FEEDBACK OFF
SELECT '${sid}: ' || name FROM v\$database;
EXIT;
EOF
done
```

## Integration Scenarios

### Bash Profile Integration

The installer can add OraDBA to your shell profile automatically. Manual setup:

```bash
# ~/.bash_profile or ~/.bashrc

# OraDBA configuration
export ORADBA_PREFIX="/opt/oradba"

# OraDBA environment integration (recommended)
if [ -f "${ORADBA_PREFIX}/bin/oraenv.sh" ]; then
    # Load first Oracle SID from oratab (silent mode)
    source "${ORADBA_PREFIX}/bin/oraenv.sh" --silent
    
    # Show environment status on interactive shells
    if [[ $- == *i* ]] && command -v oraup.sh >/dev/null 2>&1; then
        oraup.sh
    fi
fi
```

### Cron Jobs

```bash
# Example: Daily backup at 2 AM
# m h  dom mon dow   command
0 2 * * * . /opt/oradba/bin/oraenv.sh FREE --silent && /backup/scripts/daily_backup.sh 2>&1 | tee -a /backup/logs/backup.log
```

**Cron job best practices:**

- Always source oraenv.sh with --silent
- Use full paths to scripts
- Redirect output to log files
- Set explicit ORADBA_PREFIX if needed
- Test scripts manually first

### Systemd Service

```ini
[Unit]
Description=Oracle Database %I Service
After=network.target

[Service]
Type=forking
User=oracle
Group=oinstall
Environment="ORADBA_PREFIX=/opt/oradba"
ExecStart=/bin/bash -c 'source /opt/oradba/bin/oraenv.sh %i --silent && ${ORACLE_HOME}/bin/dbstart ${ORACLE_HOME}'
ExecStop=/bin/bash -c 'source /opt/oradba/bin/oraenv.sh %i --silent && ${ORACLE_HOME}/bin/dbshut ${ORACLE_HOME}'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Usage:

```bash
# Start database FREE
sudo systemctl start oracle@FREE

# Enable auto-start
sudo systemctl enable oracle@FREE
```

### SSH Remote Execution

```bash
# Execute SQL on remote host
ssh oracle@dbserver 'source /opt/oradba/bin/oraenv.sh FREE --silent && sqlplus -S / as sysdba <<< "SELECT name FROM v\$database;"'
```

## Advanced Usage

### Custom oratab Location

```bash
# Set custom oratab file
export ORATAB_FILE="/custom/path/oratab"
source oraenv.sh FREE
```

### Debug Mode

Enable detailed debugging output:

```bash
# Set DEBUG variable before sourcing
export DEBUG=1
source oraenv.sh FREE

# Or set in configuration file
echo "DEBUG=1" >> ~/.oradba_config
```

### Force Environment Reload

```bash
# Force reload even if ORACLE_SID is already set
source oraenv.sh FREE --force
```

## Environment Verification

After setting your environment, verify it's correct:

```bash
# Quick check
echo "ORACLE_SID: $ORACLE_SID"
echo "ORACLE_HOME: $ORACLE_HOME"

# Comprehensive check using oraup.sh
oraup.sh

# Detailed status
dbstatus.sh

# Test SQL*Plus connection
sqlplus -V
sqlplus / as sysdba <<< "SELECT name, open_mode FROM v\$database;"
```

## Common Environment Variables Reference

### Standard Oracle Variables

| Variable         | Description                | Example Value                             |
|------------------|----------------------------|-------------------------------------------|
| `ORACLE_SID`     | System Identifier          | `FREE`                                    |
| `ORACLE_HOME`    | Installation directory     | `/u01/app/oracle/product/19.0.0/dbhome_1` |
| `ORACLE_BASE`    | Base directory             | `/u01/app/oracle`                         |
| `ORACLE_UNQNAME` | Unique database name       | `FREE` (or `FREE_STBY` for standby)       |
| `TNS_ADMIN`      | TNS configuration location | `$ORACLE_HOME/network/admin`              |

### NLS Variables

| Variable               | Description                | Default Value               |
|------------------------|----------------------------|-----------------------------|
| `NLS_LANG`             | Language and character set | `AMERICAN_AMERICA.AL32UTF8` |
| `NLS_DATE_FORMAT`      | Date display format        | `YYYY-MM-DD HH24:MI:SS`     |
| `NLS_TIMESTAMP_FORMAT` | Timestamp format           | `YYYY-MM-DD HH24:MI:SS.FF`  |

### OraDBA Variables

| Variable         | Description             | Example Value        |
|------------------|-------------------------|----------------------|
| `ORADBA_PREFIX`  | Installation directory  | `/opt/oradba`        |
| `ORADBA_VERSION` | Version number          | `0.7.4`              |
| `ORADBA_ETC`     | Configuration directory | `$ORADBA_PREFIX/etc` |
| `ORADBA_LOG`     | Log directory           | `$ORADBA_PREFIX/log` |
| `ORADBA_SIDLIST` | All SIDs from oratab    | `FREE TESTDB PRODDB` |

## Troubleshooting

### oraenv.sh not found

```bash
# Check installation
ls -l /opt/oradba/bin/oraenv.sh

# Use full path
source /opt/oradba/bin/oraenv.sh FREE

# Add to PATH
export PATH="/opt/oradba/bin:$PATH"
```

### ORACLE_SID not in oratab

```bash
# Check oratab file
cat /etc/oratab | grep FREE

# Verify oratab location
echo $ORATAB_FILE

# Check for typos in SID name
```

### Environment not persisting

```bash
# Remember: Use 'source' not 'sh' or 'bash'
# WRONG:
sh oraenv.sh FREE          # Creates subshell, environment lost
./oraenv.sh FREE           # Same problem

# CORRECT:
source oraenv.sh FREE      # Runs in current shell
. oraenv.sh FREE           # Same (POSIX syntax)
```

### PDB aliases not created

```bash
# Check if database is CDB
sqlplus / as sysdba <<< "SELECT CDB FROM v\$database;"

# Check if ORADBA_NO_PDB_ALIASES is set
echo $ORADBA_NO_PDB_ALIASES

# Manually regenerate PDB aliases
source $ORADBA_PREFIX/lib/common.sh
generate_pdb_aliases
```

See the [Troubleshooting Guide](12-troubleshooting.md) for more solutions.

## Best Practices

1. **Always use 'source'** - Never run oraenv.sh as a script (./oraenv.sh)
2. **Use --silent in scripts** - Prevents output interference
3. **Verify after setting** - Check $ORACLE_SID matches expectation
4. **Use full paths in cron** - Don't rely on $PATH in cron jobs
5. **Test interactively first** - Before adding to scripts or cron
6. **Keep oratab updated** - Ensure all databases are listed
7. **Use consistent naming** - SID names should be meaningful
8. **Document custom configs** - Comment SID-specific settings

## See Also

- [Configuration](05-configuration.md) - Customize OraDBA settings
- [Aliases](06-aliases.md) - 50+ convenient aliases
- [PDB Aliases](07-pdb-aliases.md) - Pluggable database shortcuts
- [Troubleshooting](12-troubleshooting.md) - Solve common issues
- [Usage Examples](16-usage.md) - Practical scenarios

## Navigation

**Previous:** [Quick Start](03-quickstart.md)  
**Next:** [Configuration System](05-configuration.md)
