# Quick Start Guide

## Installation

### Quick Install (Default)

```bash
curl -o oradba_install.sh https://raw.githubusercontent.com/oehrlis/oradba/main/oradba_install.sh
chmod +x oradba_install.sh
sudo ./oradba_install.sh
```

### Custom Installation

```bash
# Install to custom location
sudo ./oradba_install.sh --prefix /usr/local/oradba

# Install as specific user
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle
```

## First Steps

### 1. Set up your oratab file

Create or edit `/etc/oratab`:

```bash
# Format: SID:ORACLE_HOME:STARTUP_FLAG
FREE:/u01/app/oracle/product/19.0.0/dbhome_1:N
TESTDB:/u01/app/oracle/product/19.0.0/dbhome_2:Y
```

### 2. Set Oracle environment

```bash
# Using oraenv
source oraenv.sh FREE

# Or if symbolic link was created
source oraenv FREE
```

### 3. Verify environment

```bash
echo $ORACLE_SID
echo $ORACLE_HOME
sqlplus -V
```

## Common Tasks

### Switch Between Databases

```bash
# Switch to FREE
source oraenv.sh FREE

# Switch to TESTDB
source oraenv.sh TESTDB
```

### Interactive SID Selection

```bash
# Run without arguments to see available databases
source oraenv.sh
```

### Run SQL Scripts

```bash
# Database info
sqlplus / as sysdba @$ORADBA_PREFIX/src/sql/db_info.sql

# Or set SQLPATH
export SQLPATH=$ORADBA_PREFIX/src/sql
sqlplus / as sysdba @db_info.sql
```

### RMAN Backups

```bash
# Full backup
rman target / @$ORADBA_PREFIX/src/rcv/backup_full.rman
```

## Configuration

### Global Configuration

Edit `/opt/oradba/src/etc/oradba.conf`:

```bash
# Set debug mode
DEBUG=1

# Custom oratab location
ORATAB_FILE="/var/opt/oracle/oratab"

# Custom backup directory
BACKUP_DIR="/backup/oracle"
```

### User Configuration

Create `~/.oradba_config`:

```bash
# Copy example
cp /opt/oradba/src/etc/oradba_config.example ~/.oradba_config

# Edit
vim ~/.oradba_config
```

## Troubleshooting

### oraenv not found

```bash
# Add to PATH
export PATH="/opt/oradba/src/bin:$PATH"

# Or use full path
source /opt/oradba/src/bin/oraenv.sh FREE
```

### ORACLE_SID not found in oratab

```bash
# Check oratab file
cat /etc/oratab

# Set custom oratab location
export ORATAB_FILE=/path/to/custom/oratab
source oraenv.sh FREE
```

### Permission issues

```bash
# Check installation directory permissions
ls -la /opt/oradba

# Fix if needed
sudo chown -R oracle:oinstall /opt/oradba
```

### Debug mode

```bash
# Enable debug output
export DEBUG=1
source oraenv.sh FREE
```

## Examples

### Basic Usage

```bash
# Set environment for FREE
$ source oraenv.sh FREE

Oracle Environment:
==================
ORACLE_SID       : FREE
ORACLE_HOME      : /u01/app/oracle/product/19.0.0/dbhome_1
ORACLE_BASE      : /u01/app/oracle
TNS_ADMIN        : /u01/app/oracle/product/19.0.0/dbhome_1/network/admin
NLS_LANG         : AMERICAN_AMERICA.AL32UTF8

# Connect to database
$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production
Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
```

### Create Custom Script

```bash
# Copy template
cp /opt/oradba/src/templates/script_template.sh ~/my_script.sh

# Edit
vim ~/my_script.sh

# Make executable
chmod +x ~/my_script.sh

# Run
./my_script.sh
```

### Add to Profile

Add to `~/.bash_profile` or `~/.bashrc`:

```bash
# oradba setup
export ORADBA_PREFIX="/opt/oradba"
export PATH="$ORADBA_PREFIX/src/bin:$PATH"
export SQLPATH="$ORADBA_PREFIX/src/sql"

# Default Oracle SID (optional)
export ORACLE_SID=FREE
source oraenv.sh $ORACLE_SID
```

## Next Steps

- Read the [full documentation](README.md)
- Check [development guide](docs/DEVELOPMENT.md) for contributing
- Review [example scripts](src/sql/) and [templates](src/templates/)
- Join the community and contribute!

## Getting Help

- Check the [README.md](README.md)
- Review [CONTRIBUTING.md](CONTRIBUTING.md)
- Open an issue on GitHub
- Check existing issues for solutions
