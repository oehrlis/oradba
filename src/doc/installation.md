# Installation

**Purpose:** Complete installation guide for OraDBA, covering prerequisites,
installation methods, and post-installation verification.

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

OraDBA offers multiple installation methods to support different environments and use cases.

```mermaid
graph TB
    Start[Choose Installation Method]
    Quick[Quick Install<br/>Embedded Payload]
    AirGap[Air-Gapped Install<br/>Embedded Payload]
    Separate[Air-Gapped Install<br/>Separate Tarball]
    GitHub[GitHub Repository<br/>Latest Development]
    
    Download[Download Installer]
    Transfer[Transfer to Target]
    Extract[Extract & Install]
    Verify[Verify Installation]
    Profile[Update Shell Profile]
    Registry[Initialize Registry]
    Done[Installation Complete]
    
    Start --> Quick
    Start --> AirGap
    Start --> Separate
    Start --> GitHub
    
    Quick --> Download
    AirGap --> Download
    Separate --> Download
    GitHub --> Download
    
    Download --> Transfer
    Transfer --> Extract
    Extract --> Verify
    Verify --> Profile
    Profile --> Registry
    Registry --> Done
    
    style Start fill:#E6E6FA
    style Quick fill:#87CEEB
    style AirGap fill:#87CEEB
    style Separate fill:#87CEEB
    style GitHub fill:#87CEEB
    style Done fill:#98FB98
```

**Installation process:**  
All methods follow the same core flow - download installer, transfer if needed, extract files, verify integrity with
SHA256 checksums, update shell profile, and initialize Registry API for managing installations.

### Method 1: Quick Install with Embedded Payload (Recommended)

**Best for:** Standard installations with internet access

The `oradba_install.sh` installer includes an embedded tarball payload, making it a single-file
installation solution. Download and run - no separate package required.

```bash
# Download installer (contains embedded payload)
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh

# Run installer (auto-detects ORACLE_BASE for prefix)
./oradba_install.sh

# Or specify custom installation directory
./oradba_install.sh --prefix /usr/local/oradba

# Install specific version
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/download/v0.14.0/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh --prefix /opt/oradba
```

**Key Features:**

- **Single file download** - Installer includes complete OraDBA package as base64-encoded payload
- **Auto-detection** - Detects ORACLE_BASE and uses `$ORACLE_BASE/local/oradba` as default prefix
- **Fallback prefix** - Uses `$HOME/local/oradba` if ORACLE_BASE not set
- **Integrity verification** - SHA256 checksums validate all extracted files
- **Version flexibility** - Download any released version from GitHub
- **Smart updates** - Detects existing installations and preserves configurations

### Method 2: Air-Gapped Install with Embedded Payload

**Best for:** Air-gapped, DMZ, or restricted network environments

Use the same self-contained installer in environments without internet access.

```bash
# On internet-connected system: Download installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh

# Transfer oradba_install.sh to target system via approved method
# (USB drive, secure file transfer, etc.)

# On air-gapped system: Install
chmod +x oradba_install.sh
./oradba_install.sh --prefix /opt/oradba

# Or with sudo for system-wide installation
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle
```

**Key Features:**

- **No network required** - Complete package embedded in installer
- **Transfer-friendly** - Single file simplifies approval and transfer processes
- **Same installer** - Identical file used for online and offline installations
- **Validation included** - Full integrity checking without external dependencies

### Method 3: Air-Gapped Install with Separate Tarball

**Best for:** Environments requiring separate payload verification or custom packages

Download installer and tarball separately for maximum flexibility.

```bash
# Step 1: On internet-connected system, download both files
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
curl -L -o oradba-0.14.0.tar.gz \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba-0.14.0.tar.gz

# Step 2: Verify checksums (optional but recommended)
sha256sum oradba-0.14.0.tar.gz

# Step 3: Transfer both files to target system

# Step 4: Install from local tarball
chmod +x oradba_install.sh
./oradba_install.sh --local oradba-0.14.0.tar.gz --prefix /opt/oradba
```

**Key Features:**

- **Separate verification** - Independently validate tarball before installation
- **Custom packages** - Build and deploy your own tarball with extensions
- **Policy compliance** - Supports environments requiring separate approval of payload
- **Explicit versioning** - Tarball filename clearly indicates version

### Method 4: Direct from GitHub Repository

**Best for:** Development environments, testing unreleased features, contributors

Install directly from GitHub repository for latest development code.

```bash
# Install latest development version from main branch
./oradba_install.sh --github

# Install specific version/tag
./oradba_install.sh --github --version v0.14.0

# Install from specific branch (development/testing)
./oradba_install.sh --github --version dev-branch-name
```

**Requirements:** `git` and `curl` or `wget`

**Key Features:**

- **Latest code** - Access unreleased features and bug fixes
- **Branch flexibility** - Install from any branch or tag
- **Development workflow** - Perfect for testing and contribution
- **Auto-build** - Clones repository and builds package on-the-fly

**Warning:** Development branches may contain unstable code. Use stable releases for production.

### Method 5: Ansible Automated Deployment

**Best for:** Managing multiple Oracle servers, standardized deployments, infrastructure as code

Automate OraDBA installation across your Oracle infrastructure using Ansible.

```yaml
# playbook: deploy-oradba.yml
---
- name: Deploy OraDBA to Oracle Database Servers
  hosts: oracle_servers
  become: yes
  become_user: oracle
  gather_facts: yes

  vars:
    # Default to the latest release unless explicitly pinned (e.g. "0.14.0")
    oradba_version: "latest"

    # Prefix is derived from ORACLE_BASE on the target host:
    #   $ORACLE_BASE/local/oradba
    oradba_prefix: "{{ ansible_env.ORACLE_BASE }}/local/oradba"

  tasks:
    - name: Ensure ORACLE_BASE is set on the target host
      assert:
        that:
          - ansible_env.ORACLE_BASE is defined
          - (ansible_env.ORACLE_BASE | length) > 0
        fail_msg: "ORACLE_BASE is not set for user 'oracle' on the target host."

    - name: Compute OraDBA download URL (latest or pinned)
      set_fact:
        oradba_download_url: >-
          {{
            (oradba_version == 'latest')
            | ternary(
                'https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh',
                'https://github.com/oehrlis/oradba/releases/download/v' ~ oradba_version ~ '/oradba_install.sh'
              )
          }}

    - name: Create temporary download directory
      file:
        path: /tmp/oradba-install
        state: directory
        mode: "0755"

    - name: Download OraDBA installer
      get_url:
        url: "{{ oradba_download_url }}"
        dest: /tmp/oradba-install/oradba_install.sh
        mode: "0755"
      when: ansible_connection != "local"  # Skip in air-gapped

    - name: Copy installer (air-gapped alternative)
      copy:
        src: files/oradba_install.sh
        dest: /tmp/oradba-install/oradba_install.sh
        mode: "0755"
      when: ansible_connection == "local"

    - name: Run OraDBA installer
      command: >
        /tmp/oradba-install/oradba_install.sh
        --prefix {{ oradba_prefix }}
        --update-profile
        --quiet
      args:
        creates: "{{ oradba_prefix }}/bin/oraenv.sh"
      register: install_result

    - name: Verify installation
      command: "{{ oradba_prefix }}/bin/oradba_version.sh --verify"
      register: verify_result
      changed_when: false

    - name: Display installation summary
      debug:
        msg: "OraDBA installed successfully at {{ oradba_prefix }} (requested version: {{ oradba_version }})"
      when: verify_result.rc == 0

    - name: Clean up temporary files
      file:
        path: /tmp/oradba-install
        state: absent
```

**Usage:**

```bash
# Deploy to all Oracle servers
ansible-playbook -i inventory.ini deploy-oradba.yml

# Deploy to specific group
ansible-playbook -i inventory.ini deploy-oradba.yml --limit production

# Check mode (dry-run)
ansible-playbook -i inventory.ini deploy-oradba.yml --check

# Update existing installations
ansible-playbook -i inventory.ini deploy-oradba.yml -e "oradba_force_update=yes"
```

**Key Features:**

- **Idempotent** - Safely re-run without reinstalling
- **Scalable** - Deploy to hundreds of servers simultaneously
- **Consistent** - Ensures identical configuration across all environments
- **Versioned** - Pin to specific OraDBA versions for stability
- **Air-gap ready** - Use local files when internet unavailable
- **Integration** - Combine with Oracle installation playbooks

**Air-Gapped Ansible Deployment:**

```yaml
# For air-gapped: Pre-download installer and place in playbook files/
# playbook/
#   ├── deploy-oradba.yml
#   └── files/
#       └── oradba_install.sh  # Pre-downloaded from GitHub releases
```

## Installation Scenarios

### Pre-Oracle Installation

**Available from:** v0.17.0

OraDBA can now be installed **before Oracle Database is installed**, enabling
preparatory system setup, CI/CD pipeline bootstrapping, or Docker image layering.

#### Why Install Before Oracle?

- **CI/CD Pipelines:** Prepare database tools before Oracle installation in automation workflows
- **Docker/Container Images:** Layer OraDBA in base images before Oracle binaries
- **System Preparation:** Set up administrative tooling on new servers
- **Development Environments:** Configure tooling before full Oracle setup
- **Gradual Deployment:** Install tools first, Oracle later

#### Pre-Oracle Installation Methods

**User-Level Installation (Recommended for Pre-Oracle):**

```bash
# Install to ~/oradba with no Oracle requirement
./oradba_install.sh --user-level

# Or explicitly specify home directory
./oradba_install.sh --prefix $HOME/oradba
```

Creates structure:

```text
$HOME/
  oradba/               # OraDBA installation
  .oratab               # Temporary oratab (symlink ready)
  .bashrc               # Updated with OraDBA (if --update-profile)
```

**Base Directory Installation:**

```bash
# Install to /opt/local/oradba with temp oratab
./oradba_install.sh --base /opt

# Or specify path explicitly
./oradba_install.sh --prefix /opt/local/oradba
```

Creates structure:

```text
/opt/
  local/oradba/         # OraDBA installation
    etc/oratab          # Temporary oratab (ready for symlink)
```

**Silent Installation (Non-Interactive):**

```bash
# Suppress Oracle Base prompt
./oradba_install.sh --user-level --silent

# For automation/scripts
./oradba_install.sh --prefix /opt/local/oradba --silent --update-profile
```

#### Understanding Temporary oratab

In pre-Oracle mode, OraDBA creates a **temporary oratab** at `${ORADBA_BASE}/etc/oratab`:

```bash
# Example temporary oratab content
#
# OraDBA Temporary oratab
# This file was created during pre-Oracle installation.
# Replace with symlink to system oratab after Oracle installation:
#   oradba_setup.sh link-oratab
#
```

**Characteristics:**

- ✓ Allows OraDBA to function without Oracle
- ✓ Tools work with graceful degradation  
- ✓ Ready to be replaced with symlink post-Oracle
- ✓ No interference with system oratab

#### Post-Oracle Configuration

After Oracle Database is installed, link OraDBA to the system oratab:

```bash
# Link to system oratab (requires appropriate permissions)
oradba_setup.sh link-oratab

# Verify configuration
oradba_setup.sh check

# Display current settings
oradba_setup.sh show-config
```

**What `link-oratab` does:**

1. Detects system oratab location (`/etc/oratab` or `/var/opt/oracle/oratab`)
2. Backs up temporary oratab (`${ORADBA_BASE}/etc/oratab.backup.TIMESTAMP`)
3. Creates symlink: `${ORADBA_BASE}/etc/oratab -> /etc/oratab`
4. Validates symlink functionality

#### Graceful Degradation (No-Oracle Mode)

When Oracle is not detected, OraDBA operates in **No-Oracle Mode**:

```bash
# Tools work with minimal environment
source oraenv.sh     # Sets ORADBA_NO_ORACLE_MODE=true
oraup.sh            # Shows helpful pre-Oracle guidance

# Validation is context-aware
oradba_validate.sh  # Reports "Pre-Oracle" mode, skips Oracle checks
```

**What works without Oracle:**

- ✓ Base directory structure
- ✓ Configuration management
- ✓ Extension system
- ✓ Documentation and help
- ✓ Setup helper commands

**What requires Oracle:**

- ✗ Database environment switching (`oraenv.sh <SID>`)
- ✗ Database listing (`oraup.sh`)
- ✗ Oracle-specific tools (RMAN, SQL wrappers)

#### Example: Docker Multi-Stage Build

```dockerfile
# Stage 1: OraDBA preparation
FROM oraclelinux:8-slim AS oradba-prep
RUN useradd -m -u 54321 oracle
USER oracle
WORKDIR /home/oracle

# Install OraDBA before Oracle
RUN curl -L https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh | \
    bash -s -- --user-level --silent --update-profile

# Stage 2: Oracle Database (separate layer)
FROM oradba-prep AS oracle-db
USER root
# ... install Oracle Database ...
USER oracle

# Link OraDBA to system oratab
RUN /home/oracle/oradba/bin/oradba_setup.sh link-oratab

CMD ["/home/oracle/oradba/bin/oraenv.sh"]
```

#### Example: CI/CD Pipeline

```yaml
# .github/workflows/oracle-setup.yml
name: Oracle Database Setup
jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - name: Install OraDBA (Pre-Oracle)
        run: |
          curl -L -o install.sh \
            https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
          bash install.sh --user-level --silent
          
      - name: Verify OraDBA
        run: ~/oradba/bin/oradba_validate.sh
        
      - name: Install Oracle Database
        run: |
          # ... Oracle installation steps ...
          
      - name: Link OraDBA to Oracle
        run: ~/oradba/bin/oradba_setup.sh link-oratab
```

#### Troubleshooting Pre-Oracle Issues

**Issue**: "Oracle Base directory not found"

```bash
# Use explicit prefix or user-level
./oradba_install.sh --user-level
# Or
./oradba_install.sh --prefix /opt/local/oradba
```

**Issue**: "Permission denied" during installation

```bash
# Install to user directory
./oradba_install.sh --user-level

# Or fix permissions
sudo chown -R oracle:oinstall /opt/local
./oradba_install.sh --base /opt
```

**Issue**: Tools not finding databases

```bash
# This is expected before Oracle installation
# Verify pre-Oracle mode:
oradba_validate.sh  # Should show "Pre-Oracle" mode

# After Oracle is installed:
oradba_setup.sh link-oratab
```

**Issue**: Want to test pre-Oracle without Oracle

```bash
# Use dummy home for testing
./oradba_install.sh --dummy-home /tmp/fake-oracle --prefix /tmp/oradba
```

### New Installation

First-time installation with default settings:

```bash
# Auto-detect ORACLE_BASE
./oradba_install.sh

# Custom prefix
./oradba_install.sh --prefix /opt/oradba

# With profile integration
./oradba_install.sh --update-profile
```

### Update Existing Installation

Upgrade OraDBA while preserving configurations:

```bash
# Update to latest version
./oradba_install.sh --update

# Update to specific version
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/download/v0.14.0/oradba_install.sh
chmod +x oradba_install.sh
./oradba_install.sh --update --prefix /opt/oradba

# Force reinstall same version (repair)
./oradba_install.sh --force --prefix /opt/oradba
```

**Update behavior:**

- **Automatic backup** - Creates `${PREFIX}.backup.TIMESTAMP`
- **Config preservation** - Detects modified files, saves as `.save` extension
- **Rollback support** - Previous version available if issues occur
- **Selective replacement** - Only updates core files, keeps customizations

### Version Management

Install multiple versions side-by-side:

```bash
# Production version
./oradba_install.sh --prefix /opt/oradba-0.14.0

# Testing version  
./oradba_install.sh --prefix /opt/oradba-0.15.0

# Switch versions via symlink or profile
ln -sf /opt/oradba-0.14.0 /opt/oradba
```

### Custom Installation Prefix

Install to non-standard location:

```bash
# User home directory
./oradba_install.sh --prefix $HOME/tools/oradba

# Shared tools directory
./oradba_install.sh --prefix /usr/local/oradba

# Project-specific location
./oradba_install.sh --prefix /projects/oracle/oradba
```

### User and Permissions

Control installation ownership:

```bash
# Install as oracle user (requires sudo)
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle

# Install with specific group
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle --group dba

# User installation (no sudo needed)
./oradba_install.sh --prefix $HOME/local/oradba
```

**The installer will:**

- Create directories with specified ownership
- Set appropriate permissions (755 for directories, 644/755 for files)
- Preserve execute permissions for scripts
- Create installation metadata

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

After installation (excerpt):

```text
${PREFIX}/
├── bin/        # Core utilities: oraenv.sh, oradba_version.sh, oradba_validate.sh,
│               # oradba_check.sh, oradba_install.sh, oradba_rman.sh, oradba_dbctl.sh and others
├── lib/        # Shared libraries
├── etc/        # Configuration and examples (includes rlwrap completions)
├── sql/        # README plus a few starter SQL scripts
├── rcv/        # RMAN scripts
├── doc/        # Documentation index and key chapters
├── templates/  # Script/config templates
├── log/        # Log directory
└── .install_info  # Installation metadata
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

## See Also {.unlisted .unnumbered}

- [Quick Start](quickstart.md) - Getting started with OraDBA
- [Configuration](configuration.md) - Customizing your installation
- [Troubleshooting](troubleshooting.md) - Solving installation issues

## Navigation {.unlisted .unnumbered}

**Previous:** [Introduction](introduction.md)  
**Next:** [Quick Start](quickstart.md)
