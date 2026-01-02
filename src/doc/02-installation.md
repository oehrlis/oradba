# Installation

**Purpose:** Complete installation guide for OraDBA, covering prerequisites, installation methods, and
post-installation verification.

**Audience:** System administrators and DBAs setting up OraDBA for the first time.

## System Requirements

### Operating System

- Linux (any distribution with Bash 4.0+)
- macOS (tested on recent versions)

### Required Tools

- `bash` 4.0 or higher
- `tar` - Archive extraction
- `awk`, `sed`, `grep` - Text processing
- `base64` - Installer decoding
- `sha256sum` (or `shasum`) - Checksum verification
- `find`, `sort` - File operations

### Oracle Environment

- Oracle Database 11g or higher (11g, 12c, 18c, 19c, 21c, 23ai)
- Any Oracle edition (Enterprise, Standard, Express, Free)
- Valid `oratab` file (typically `/etc/oratab`)

### Optional Tools

- `rlwrap` - Command history and line editing for SQL*Plus and RMAN
- `crontab` - Cron job management (needed for save_cron alias)
- `pandoc` - Documentation generation (if building from source)
- `curl` or `wget` - Downloading releases

### Disk Space

- Minimum: 100MB
- Recommended: 500MB (includes logs, backups, custom scripts)

## Pre-Installation Check

Before installing, run the system prerequisites check:

```bash
# Download system check script
curl -L -o oradba_check.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh
chmod +x oradba_check.sh

# Run check
./oradba_check.sh

# Verbose output (shows all checks)
./oradba_check.sh --verbose

# Check specific installation directory
./oradba_check.sh --dir /opt/oradba
```

The check validates:

- Required system tools availability
- Disk space sufficiency
- Oracle environment configuration
- Optional tools status
- Installation directory permissions

## Installation Methods

OraDBA offers three installation methods depending on your environment.

![Installation Flow](images/installation-flow.png)

The installation process automatically detects your environment, validates
prerequisites, extracts files, and verifies integrity with SHA256 checksums.

### Method 1: Quick Install from GitHub (Recommended)

Best for: Systems with internet access

```bash
# Download latest release installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh

# Run installer (auto-detects ORACLE_BASE for prefix)
./oradba_install.sh

# Or specify custom installation directory
./oradba_install.sh --prefix /usr/local/oradba
```

The installer automatically:

- Detects ORACLE_BASE and uses `$ORACLE_BASE/local/oradba` as default prefix
- Falls back to `$HOME/local/oradba` if ORACLE_BASE not set
- Creates directory structure
- Extracts files with proper permissions
- Verifies installation integrity with SHA256 checksums
- Creates installation metadata

### Method 2: From Local Tarball (Air-Gapped)

Best for: Air-gapped environments or offline installations

```bash
# Download latest installer (recommended)
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh

# Or download specific version
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/download/v0.8.1/oradba_install.sh
chmod +x oradba_install.sh

# Step 3: Install from local tarball
./oradba_install.sh --local oradba-0.7.4.tar.gz --prefix /opt/oradba
```

This method allows you to:

- Download on a different system
- Transfer files to air-gapped environments
- Install without network access
- Use custom tarballs

### Method 3: Direct from GitHub

Best for: Development environments, testing latest code

```bash
# Install latest version directly from GitHub
./oradba_install.sh --github

# Install specific version
./oradba_install.sh --github --version 0.7.4
```

**Note:** This method requires `git` and `curl` or `wget`.

## Installation Options

### Directory Options

```bash
# Custom installation directory
./oradba_install.sh --prefix /opt/oradba

# The prefix determines installation structure:
# /opt/oradba/
#   ├── bin/        # Executable scripts
#   ├── lib/        # Libraries
#   ├── etc/        # Configuration
#   ├── sql/        # SQL scripts
#   ├── rcv/        # RMAN scripts
#   └── doc/        # Documentation
```

### User and Permissions

```bash
# Install as different user (requires sudo)
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle

# The installer will:
# - Create directories as specified user
# - Set appropriate ownership
# - Preserve execute permissions
```

### Shell Profile Integration

```bash
# Enable automatic environment loading on shell startup
./oradba_install.sh --update-profile

# Disable profile integration (manual sourcing required)
./oradba_install.sh --no-update-profile
```

**What profile integration does:**

- Adds OraDBA sourcing to your shell profile
- Auto-loads first Oracle SID from oratab on login
- Displays environment status for interactive shells
- Supports `~/.bash_profile`, `~/.profile`, `~/.zshrc`
- Creates backup before modification

**Profile Integration Example:**

```bash
# Added to ~/.bash_profile
# OraDBA Environment Integration
if [ -f "/opt/oracle/local/oradba/bin/oraenv.sh" ]; then
    source "/opt/oracle/local/oradba/bin/oraenv.sh" --silent
    if [[ $- == *i* ]] && command -v oraup.sh >/dev/null 2>&1; then
        oraup.sh
    fi
fi
```

### Update and Maintenance

```bash
# Update existing installation
./oradba_install.sh --update --prefix /opt/oradba

# Update from GitHub
./oradba_install.sh --update --github

# Force reinstall (same version)
./oradba_install.sh --force --prefix /opt/oradba
```

### Parallel Installation with TVD BasEnv / DB*Star

OraDBA supports parallel installation alongside TVD BasEnv and DB*Star. The
installer automatically detects existing BasEnv installations and configures
OraDBA to coexist peacefully.

**Auto-Detection:**

The installer checks for BasEnv markers during installation:

- `.BE_HOME` file in user's home directory
- `.TVDPERL_HOME` file in user's home directory  
- `BE_HOME` environment variable

If detected, OraDBA operates in **coexistence mode**:

```bash
# Installation automatically detects BasEnv
./oradba_install.sh --prefix /opt/oracle/local/oradba

# Output shows detection:
# [INFO] TVD BasEnv / DB*Star detected - enabling coexistence mode
# [INFO] OraDBA will not override existing basenv aliases and settings
# [INFO]   BE_HOME: /opt/oracle/local/dba
```

**Coexistence Behavior:**

- **BasEnv has priority** - OraDBA acts as a non-invasive add-on
- **No alias conflicts** - OraDBA skips aliases that exist in BasEnv
- **Preserved settings** - PS1 prompt, BE_HOME, and BasEnv variables unchanged
- **Side-by-side installation** - Both toolsets work independently

**Configuration:**

Coexistence mode is recorded in `etc/oradba_local.conf`:

```bash
# Auto-detected coexistence mode
export ORADBA_COEXIST_MODE="basenv"   # or "standalone"
ORADBA_BASENV_DETECTED="yes"

# Optional: Force OraDBA aliases (overrides BasEnv)
# Uncomment to create all aliases even if they exist in BasEnv
# export ORADBA_FORCE=1
```

**Force Mode:**

If you need OraDBA aliases to take priority:

```bash
# Edit oradba_local.conf
vi /opt/oracle/local/oradba/etc/oradba_local.conf

# Uncomment:
export ORADBA_FORCE=1

# Re-source environment
source /opt/oracle/local/oradba/bin/oraenv.sh
```

**Note:** Force mode may override BasEnv functionality - use with caution.

See [Configuration - Coexistence Mode](05-configuration.md#coexistence-mode) for detailed configuration options.

### Information and Help

```bash
# Show installer version
./oradba_install.sh --show-version

# Display help message
./oradba_install.sh --help

# Quiet mode (minimal output)
./oradba_install.sh --quiet
```

## Installation Process

The installer performs these steps:

1. **Validation**
   - Checks required tools
   - Validates options and arguments
   - Checks disk space
   - Verifies permissions

2. **Backup** (for updates)
   - Creates backup of existing installation
   - Preserves custom configurations
   - Stores in `${PREFIX}.backup.TIMESTAMP`

3. **Configuration Protection** (for updates)
   - Detects modified configuration files using checksums
   - Automatically backs up modified files with `.save` extension
   - Only backs up files in `etc/` and `.conf`/`.example` files
   - Preserves file permissions in backup copies
   - Similar to RPM package management behavior
   - Example: `etc/oradba_standard.conf` → `etc/oradba_standard.conf.save`

4. **Extraction**
   - Creates directory structure
   - Extracts files from embedded payload or tarball
   - Sets ownership and permissions

5. **Verification**
   - Validates SHA256 checksums
   - Confirms all files present
   - Reports any discrepancies

6. **Metadata**
   - Records installation date, version, method
   - Stores in `${PREFIX}/.install_info`
   - Used for update detection and verification

7. **Profile Integration** (if enabled)
   - Detects shell profile file
   - Creates backup
   - Adds OraDBA sourcing
   - Prevents duplicate entries

## Post-Installation

### Verify Installation

```bash
# Check OraDBA version
/opt/oradba/bin/oradba_version.sh --check

# Verify installation integrity
/opt/oradba/bin/oradba_version.sh --verify

# Run validation script
/opt/oradba/bin/oradba_validate.sh
```

### Set Up oratab

Create or edit `/etc/oratab`:

```bash
# Format: SID:ORACLE_HOME:STARTUP_FLAG
# Flags: Y (auto-start), N (no auto-start), D (dummy for DGMGRL)
FREE:/u01/app/oracle/product/19c/dbhome_1:N
TESTDB:/u01/app/oracle/product/21c/dbhome_1:Y
PRODCDB:/u01/app/oracle/product/19c/dbhome_1:N
```

**Startup Flags:**

- `Y` - Database should auto-start
- `N` - Manual startup required
- `D` - Dummy entry (e.g., for Data Guard Broker)

### Test Environment Setup

```bash
# Set environment for first database
source /opt/oradba/bin/oraenv.sh FREE

# Verify environment variables
echo $ORACLE_SID        # Should show: FREE
echo $ORACLE_HOME       # Should show: /u01/app/oracle/product/19c/dbhome_1
echo $ORACLE_BASE       # Should show: /u01/app/oracle

# Test SQL*Plus connection
sqlplus -V              # Should show Oracle SQL*Plus version

# Test database status
/opt/oradba/bin/dbstatus.sh
```

### Add to PATH (Optional)

Add OraDBA to your PATH for easier access:

```bash
# Add to ~/.bash_profile or ~/.bashrc
export ORADBA_PREFIX="/opt/oradba"
export PATH="$ORADBA_PREFIX/bin:$PATH"
export SQLPATH="$ORADBA_PREFIX/sql"
export ORACLE_PATH="$ORADBA_PREFIX/sql"
```

## Installation Locations

### Default Prefix Detection

The installer uses this priority for default prefix:

1. `${ORACLE_BASE}/local/oradba` - If ORACLE_BASE is set
2. `/opt/oracle/local/oradba` - If `/opt/oracle` exists
3. `/u01/app/oracle/local/oradba` - If `/u01/app/oracle` exists
4. `${HOME}/local/oradba` - Fallback to user's home directory

### Directory Structure

After installation:

```text
${PREFIX}/
├── bin/                    # Executable scripts
│   ├── oraenv.sh          # Environment setup
│   ├── dbstatus.sh        # Database status
│   ├── oradba_version.sh  # Version management
│   ├── oradba_validate.sh # Validation
│   ├── oradba_check.sh    # System check
│   └── oradba_install.sh  # Installer (for updates)
├── lib/                    # Library files
│   ├── common.sh          # Common functions
│   └── aliases.sh         # Alias generation
├── etc/                    # Configuration files
│   ├── oradba_core.conf   # Core settings
│   ├── oradba_standard.conf  # Standard config
│   ├── oradba_customer.conf.example  # Customer template
│   ├── sid._DEFAULT_.conf # Default SID template
│   ├── sid.ORCL.conf.example  # SID example
│   └── oratab.example     # oratab format example
├── sql/                    # SQL scripts
│   ├── db_info.sql
│   ├── login.sql
│   ├── sessionsql.sql
│   └── README.md
├── rcv/                    # RMAN scripts
│   ├── backup_full.rman
│   └── README.md
├── doc/                    # User documentation
│   ├── README.md
│   ├── 01-introduction.md
│   └── ...
├── templates/              # Script templates
│   └── script_template.sh
├── log/                    # Log directory
└── .install_info          # Installation metadata
```

## Updating OraDBA

### Update from GitHub

```bash
# Update to latest version
$PREFIX/bin/oradba_install.sh --update --github

# Update to specific version
$PREFIX/bin/oradba_install.sh --update --github --version 0.7.4
```

### Update from Local Tarball

```bash
# Download latest version
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh

# Update installation
chmod +x oradba_install.sh
./oradba_install.sh --update
```

### Update Features

- **Automatic Backup**: Creates timestamped backup before update
- **Configuration Preservation**: Keeps all custom settings
- **Rollback on Failure**: Restores previous version if update fails
- **Version Detection**: Skips update if already running latest version
- **Selective Updates**: Only replaces core files, preserves customizations

### Check for Updates

```bash
# Check if updates available
$PREFIX/bin/oradba_version.sh --update-check

# Show detailed version information
$PREFIX/bin/oradba_version.sh --info
```

## Troubleshooting Installation

### Installer Not Found

```bash
# Check download
ls -l oradba_install.sh

# Make executable
chmod +x oradba_install.sh

# Check if it's a text file or binary
file oradba_install.sh
```

### Permission Denied

```bash
# Check directory permissions
ls -ld /opt/oradba

# Install to user directory instead
./oradba_install.sh --prefix $HOME/local/oradba

# Or use sudo for system directories
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle
```

### Checksum Verification Failed

```bash
# Re-download installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh

# Verify download
file oradba_install.sh
head -5 oradba_install.sh

# If still fails, report issue on GitHub
```

### Disk Space Insufficient

```bash
# Check available space
df -h /opt

# Clean up if needed
find /tmp -name "oradba*" -mtime +7 -delete

# Install to location with more space
./oradba_install.sh --prefix /u01/app/oracle/local/oradba
```

### Missing Required Tools

```bash
# Check which tools are missing
./oradba_check.sh

# Install missing tools (example for RHEL/Oracle Linux)
sudo yum install bash tar gawk sed grep coreutils findutils

# For rlwrap (optional)
sudo yum install rlwrap
```

## Uninstallation

To remove OraDBA:

```bash
# Remove installation directory
rm -rf /opt/oradba

# Remove profile integration (if added)
# Edit ~/.bash_profile and remove OraDBA section

# Remove user config (optional)
rm -f ~/.oradba_config

# Remove SID-specific configs
rm -f /opt/oradba/etc/sid.*.conf
```

**Note:** Always backup custom configurations before uninstalling.

## See Also

- [Quick Start](03-quickstart.md) - Getting started with OraDBA
- [Configuration](05-configuration.md) - Customizing your installation
- [Troubleshooting](12-troubleshooting.md) - Solving installation issues

## Navigation

**Previous:** [Introduction](01-introduction.md)  
**Next:** [Quick Start](03-quickstart.md)
