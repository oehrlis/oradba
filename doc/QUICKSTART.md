# Quick Start Guide

## Installation

### System Prerequisites Check

Before installation, verify your system meets the requirements:

```bash
# Download and run system check
curl -L -o oradba_check.sh https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh
chmod +x oradba_check.sh
./oradba_check.sh

# Check with verbose output
./oradba_check.sh --verbose

# Check specific installation directory
./oradba_check.sh --dir /opt/oradba
```

The check validates:

- Required system tools (bash, tar, awk, sed, grep, etc.)
- Disk space availability (minimum 100MB)
- Oracle environment (if configured)
- Optional tools (rlwrap for better CLI experience)

### Quick Install (from GitHub Release)

Download and run the self-extracting installer with embedded payload:

```bash
# Download latest release installer
curl -L -o oradba_install.sh https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh

# Run installer (auto-detects ORACLE_BASE for prefix)
./oradba_install.sh

# Or specify custom prefix
./oradba_install.sh --prefix /usr/local/oradba
```

### Alternative Installation Methods

#### From Local Tarball (Air-gapped)

```bash
# Download tarball separately
curl -L -o oradba-0.6.1.tar.gz \
  https://github.com/oehrlis/oradba/releases/download/v0.6.1/oradba-0.6.1.tar.gz

# Install from local file
./oradba_install.sh --local oradba-0.6.1.tar.gz --prefix /opt/oradba
```

#### Directly from GitHub

```bash
# Install latest version
./oradba_install.sh --github

# Install specific version
./oradba_install.sh --github --version 0.6.1
```

### Installation Options

```bash
# Install with custom user (requires sudo)
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle

# Install without example files
./oradba_install.sh --no-examples

# Show installer version
./oradba_install.sh --show-version

# Display help
./oradba_install.sh --help
```

### Post-Installation Usage

After installation, the installer script is available at
`$PREFIX/bin/oradba_install.sh` and can be used for updates or installing to other
locations:

```bash
# Install to another location using installed script
/opt/oradba/bin/oradba_install.sh --local /path/to/tarball --prefix /another/location

# Update from GitHub using installed script
/opt/oradba/bin/oradba_install.sh --github --prefix /opt/oradba
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

### 3. Verify installation and environment

```bash
# Check oradba version and integrity
oradba_version.sh --verify

# Verify Oracle environment
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

## Updating OraDBA

### Update from GitHub

```bash
# Update to latest version
$PREFIX/bin/oradba_install.sh --update --github

# Update to specific version
$PREFIX/bin/oradba_install.sh --update --github --version 0.7.0
```

### Update from Local Tarball

```bash
# Download new version
curl -L -o oradba-0.7.0.tar.gz \
  https://github.com/oehrlis/oradba/releases/download/v0.7.0/oradba-0.7.0.tar.gz

# Update installation
$PREFIX/bin/oradba_install.sh --update --local oradba-0.7.0.tar.gz
```

### Update Features

- **Automatic Backup**: Creates backup before update
- **Configuration Preservation**: Keeps your custom settings
- **Rollback on Failure**: Restores previous version if update fails
- **Version Detection**: Skips if already running latest version
- **Force Update**: Use `--force` to reinstall same version

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

### System Check

Run the system check script to diagnose issues:

```bash
# Run comprehensive check
$PREFIX/bin/oradba_check.sh

# Quiet mode (errors only)
$PREFIX/bin/oradba_check.sh --quiet

# Check specific directory
$PREFIX/bin/oradba_check.sh --dir /custom/path
```

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
