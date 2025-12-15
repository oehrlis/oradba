<!-- markdownlint-disable MD013 -->
# oradba Usage Guide

## Introduction

oradba is a comprehensive Oracle Database Administration Toolset designed to simplify database operations in lab and engineering environments.

## Basic Usage

### Setting Oracle Environment

The primary function of oradba is to set up your Oracle environment based on the oratab file.

```bash
# Set environment for specific SID
source oraenv.sh ORCL

# Interactive selection
source oraenv.sh

# Using symbolic link (if created during installation)
source oraenv ORCL
```

### Environment Variables

After setting the environment, the following variables are available:

- `ORACLE_SID` - Oracle System Identifier
- `ORACLE_HOME` - Oracle installation directory
- `ORACLE_BASE` - Oracle base directory
- `PATH` - Includes Oracle binaries
- `LD_LIBRARY_PATH` - Includes Oracle libraries
- `TNS_ADMIN` - TNS configuration directory
- `NLS_LANG` - Language settings

## Common Tasks

### Connecting to Database

```bash
# Set environment
source oraenv.sh ORCL

# Connect as sysdba
sqlplus / as sysdba

# Connect as specific user
sqlplus username/password
```

### Running SQL Scripts

```bash
# Set SQLPATH
export SQLPATH=$ORADBA_PREFIX/srv/sql

# Run script
sqlplus / as sysdba @db_info.sql

# Run with parameters
sqlplus / as sysdba @script.sql param1 param2
```

### RMAN Operations

```bash
# Set environment
source oraenv.sh ORCL

# Run RMAN script
rman target / @$ORADBA_PREFIX/srv/rcv/backup_full.rman

# Interactive RMAN
rman target /
```

### Switching Between Databases

```bash
# Switch to ORCL
source oraenv.sh ORCL

# Verify
echo $ORACLE_SID  # Should show: ORCL

# Switch to TESTDB
source oraenv.sh TESTDB

# Verify
echo $ORACLE_SID  # Should show: TESTDB
```

## Configuration

### Global Configuration

Edit the global configuration file:

```bash
vim $ORADBA_PREFIX/srv/etc/oradba.conf
```

Key settings:

```bash
# oratab file location
ORATAB_FILE="/etc/oratab"

# Debug mode
DEBUG=0

# Default directories
ORACLE_BASE="/u01/app/oracle"
BACKUP_DIR="/backup"
LOG_DIR="$ORADBA_PREFIX/logs"
```

### User Configuration

Create personal configuration file:

```bash
# Copy example
cp $ORADBA_PREFIX/srv/etc/oradba_config.example ~/.oradba_config

# Edit
vim ~/.oradba_config
```

Example user configuration:

```bash
# Custom oratab location
ORATAB_FILE="$HOME/.oratab"

# Enable debug mode
DEBUG=1

# Custom SQL path
SQLPATH="$HOME/sql:$ORADBA_PREFIX/srv/sql"
```

## Advanced Usage

### Debug Mode

Enable detailed output:

```bash
export DEBUG=1
source oraenv.sh ORCL
```

### Custom oratab Location

```bash
export ORATAB_FILE="/custom/path/oratab"
source oraenv.sh ORCL
```

### Scripting with oraenv

```bash
#!/usr/bin/env bash
# Example script

# Source oraenv
ORADBA_PREFIX="/opt/oradba"
source "$ORADBA_PREFIX/srv/bin/oraenv.sh" ORCL

# Verify environment
if [[ "$ORACLE_SID" != "ORCL" ]]; then
    echo "Failed to set environment"
    exit 1
fi

# Perform database operations
sqlplus / as sysdba <<EOF
SELECT name, open_mode FROM v\$database;
EXIT;
EOF
```

## Integration

### Shell Profile

Add to `~/.bash_profile` or `~/.bashrc`:

```bash
# oradba configuration
export ORADBA_PREFIX="/opt/oradba"
export PATH="$ORADBA_PREFIX/srv/bin:$PATH"
export SQLPATH="$ORADBA_PREFIX/srv/sql"

# Set default environment (optional)
# source oraenv.sh ORCL
```

### Cron Jobs

```bash
# Example cron entry
0 2 * * * . /opt/oradba/srv/bin/oraenv.sh ORCL && /backup/scripts/backup.sh
```

### Systemd Service

```ini
[Unit]
Description=Oracle Database Service
After=network.target

[Service]
Type=forking
User=oracle
Environment="ORADBA_PREFIX=/opt/oradba"
ExecStart=/bin/bash -c 'source /opt/oradba/srv/bin/oraenv.sh ORCL && $ORACLE_HOME/bin/dbstart $ORACLE_HOME'
ExecStop=/bin/bash -c 'source /opt/oradba/srv/bin/oraenv.sh ORCL && $ORACLE_HOME/bin/dbshut $ORACLE_HOME'

[Install]
WantedBy=multi-user.target
```

## SQL*Plus Configuration

The oradba installation includes a login.sql script that configures SQL*Plus:

```bash
# Set SQLPATH to use login.sql automatically
export SQLPATH=$ORADBA_PREFIX/srv/sql

# Now SQL*Plus will use the configuration
sqlplus / as sysdba
```

## Best Practices

1. **Always source oraenv before database operations**
2. **Use full paths in scripts**
3. **Verify environment with echo commands**
4. **Use logging functions for scripts**
5. **Test in non-production first**

## Command Reference

### oraenv.sh Options

```bash
source oraenv.sh [ORACLE_SID] [OPTIONS]

Options:
  -f, --force    Force environment setup
  -h, --help     Display help message
```

### Environment Verification

```bash
# Check Oracle environment
verify_oracle_env

# Get Oracle version
get_oracle_version

# Parse oratab
parse_oratab "ORCL"
```

## See Also

- [SCRIPTS.md](SCRIPTS.md) - Script reference
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solving
- [EXAMPLES.md](EXAMPLES.md) - More examples
