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

## Installation Methods

OraDBA offers multiple installation methods to support different environments and use cases.
All methods follow the same core flow: download installer, transfer if needed, extract files,
verify integrity with SHA256 checksums, update shell profile, and initialize the Registry API.

Before installing, optionally run the prerequisites check:

```bash
curl -L -o oradba_check.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh
chmod +x oradba_check.sh
./oradba_check.sh          # basic check
./oradba_check.sh --verbose  # show all checks
./oradba_check.sh --dir /opt/oradba  # check specific target directory
```

### Method 1: Quick Install with Embedded Payload (Recommended)

**Best for:** Standard installations with internet access.

The `oradba_install.sh` installer includes an embedded tarball payload — a single-file
installation solution. Download and run; no separate package required.

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

Key features: single file download with complete embedded package, auto-detection of
`ORACLE_BASE` (fallback to `$HOME/local/oradba`), SHA256 integrity verification, and
smart update detection that preserves existing configurations.

### Method 2: Air-Gapped Install with Embedded Payload

**Best for:** Air-gapped, DMZ, or restricted network environments.

Use the same self-contained installer in environments without internet access.

```bash
# On internet-connected system: download installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh

# Transfer oradba_install.sh to target system via approved method
# (USB drive, secure file transfer, etc.)

# On air-gapped system: install
chmod +x oradba_install.sh
./oradba_install.sh --prefix /opt/oradba

# Or with sudo for system-wide installation
sudo ./oradba_install.sh --prefix /opt/oradba --user oracle
```

### Method 3: Air-Gapped Install with Separate Tarball

**Best for:** Environments requiring separate payload verification or custom packages.

```bash
# Step 1: On internet-connected system, download both files
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
curl -L -o oradba-0.14.0.tar.gz \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba-0.14.0.tar.gz

# Step 2: Verify checksum (optional but recommended)
sha256sum oradba-0.14.0.tar.gz

# Step 3: Transfer both files to target system

# Step 4: Install from local tarball
chmod +x oradba_install.sh
./oradba_install.sh --local oradba-0.14.0.tar.gz --prefix /opt/oradba
```

### Method 4: Direct from GitHub Repository

**Best for:** Development environments, testing unreleased features, contributors.

```bash
# Install latest development version from main branch
./oradba_install.sh --github

# Install specific version/tag
./oradba_install.sh --github --version v0.14.0

# Install from specific branch (development/testing)
./oradba_install.sh --github --version dev-branch-name
```

**Requirements:** `git` and `curl` or `wget`.

**Warning:** Development branches may contain unstable code. Use stable releases for production.

### Method 5: Ansible Automated Deployment

**Best for:** Managing multiple Oracle servers, standardized deployments, infrastructure as code.

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

Deploy the playbook:

```bash
ansible-playbook -i inventory.ini deploy-oradba.yml           # all Oracle servers
ansible-playbook -i inventory.ini deploy-oradba.yml --limit production
ansible-playbook -i inventory.ini deploy-oradba.yml --check   # dry-run
ansible-playbook -i inventory.ini deploy-oradba.yml -e "oradba_force_update=yes"
```

For air-gapped Ansible deployments, pre-download the installer and place it in
`playbook/files/oradba_install.sh`; the playbook's `copy` task handles the rest.

## Pre-Oracle Installation

**Available from:** v0.17.0

OraDBA can be installed **before Oracle Database is installed**, enabling
preparatory system setup, CI/CD pipeline bootstrapping, or Docker image layering.

### Installation Options

**User-level installation (recommended for pre-Oracle):**

```bash
# Install to ~/oradba with no Oracle requirement
./oradba_install.sh --user-level

# Or explicitly specify home directory
./oradba_install.sh --prefix $HOME/oradba
```

**Base directory installation:**

```bash
# Install to /opt/local/oradba
./oradba_install.sh --base /opt

# Or specify path explicitly
./oradba_install.sh --prefix /opt/local/oradba
```

**Silent installation (non-interactive / automation):**

```bash
./oradba_install.sh --user-level --silent
./oradba_install.sh --prefix /opt/local/oradba --silent --update-profile
```

### Temporary oratab

In pre-Oracle mode, OraDBA creates a **temporary oratab** at `${ORADBA_BASE}/etc/oratab`.
This allows OraDBA to function without Oracle, is ready to be replaced with a symlink
post-Oracle, and does not interfere with any system oratab.

After Oracle Database is installed, link OraDBA to the system oratab:

```bash
oradba_setup.sh link-oratab   # detects /etc/oratab or /var/opt/oracle/oratab,
                               # backs up temp oratab, creates symlink
oradba_setup.sh check
oradba_setup.sh show-config
```

### Graceful Degradation (No-Oracle Mode)

When Oracle is not detected, OraDBA operates in **No-Oracle Mode**
(`ORADBA_NO_ORACLE_MODE=true`). The following work without Oracle:

- Base directory structure, configuration management, extension system, documentation

The following require Oracle:

- Database environment switching (`oraenv.sh <SID>`), database listing (`oraup.sh`),
  Oracle-specific tools (RMAN, SQL wrappers)

### Example: Docker Multi-Stage Build

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

### Example: CI/CD Pipeline

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

### Test Environment Setup

```bash
# Set environment for first database
source /opt/oradba/bin/oraenv.sh FREE

# Verify environment variables
echo $ORACLE_SID    # FREE
echo $ORACLE_HOME   # /u01/app/oracle/product/19c/dbhome_1
echo $ORACLE_BASE   # /u01/app/oracle

# Test SQL*Plus connection
sqlplus -V

# Test database status
/opt/oradba/bin/dbstatus.sh
```

### Add to PATH

```bash
# Add to ~/.bash_profile or ~/.bashrc
export ORADBA_PREFIX="/opt/oradba"
export PATH="$ORADBA_PREFIX/bin:$PATH"
export SQLPATH="$ORADBA_PREFIX/sql"
export ORACLE_PATH="$ORADBA_PREFIX/sql"
```

### Shell Profile Integration

```bash
# Enable automatic environment loading on shell startup
./oradba_install.sh --update-profile

# Disable profile integration (manual sourcing required)
./oradba_install.sh --no-update-profile
```

Profile integration adds OraDBA sourcing to `~/.bash_profile`, `~/.profile`,
or `~/.zshrc`, auto-loads the first Oracle SID from oratab on login, and creates
a backup before modification. Example entry added:

```bash
# OraDBA Environment Integration
if [ -f "/opt/oracle/local/oradba/bin/oraenv.sh" ]; then
    source "/opt/oracle/local/oradba/bin/oraenv.sh" --silent
    if [[ $- == *i* ]] && command -v oraup.sh >/dev/null 2>&1; then
        oraup.sh
    fi
fi
```

### Directory Structure

After installation:

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

Default prefix detection order:

1. `${ORACLE_BASE}/local/oradba` — if ORACLE_BASE is set
2. `/opt/oracle/local/oradba` — if `/opt/oracle` exists
3. `/u01/app/oracle/local/oradba` — if `/u01/app/oracle` exists
4. `${HOME}/local/oradba` — fallback to user's home directory

## Docker Installation

**Purpose:** Install OraDBA inside a running Oracle Database container (e.g. Oracle Free 26ai)
using the published installer.

### Prerequisites

- A running Oracle Database container (example: Oracle Free 26ai image)
- Docker CLI access on the host
- Network egress from the container to GitHub, or a pre-downloaded installer
- Container user `oracle` exists (typical for Oracle images)

### Helpful Variables

Set these on the host to simplify commands:

```bash
CTR=free26ai            # container name or ID
INSTALLER_URL="https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh"
PREFIX="/opt/oradba"    # install target inside container
```

### Step 1: Ensure Required Tools Inside the Container

If the container is missing curl/wget/tar, install them as root:

```bash
docker exec -it -u root "$CTR" microdnf install -y curl tar gzip shadow-utils findutils
```

(Use `dnf`/`yum`/`apt` if microdnf is unavailable.)

### Step 2: Download and Run the Installer

Run as the `oracle` user inside the container:

```bash
docker exec -it "$CTR" bash -lc "
  curl -L -o /tmp/oradba_install.sh \"$INSTALLER_URL\" &&
  chmod +x /tmp/oradba_install.sh &&
  /tmp/oradba_install.sh --prefix \"$PREFIX\"
"
```

### Step 3: Verify Installation

```bash
docker exec -it "$CTR" bash -lc "
  test -x \"$PREFIX/bin/oraenv.sh\" &&
  echo \"OraDBA installed at $PREFIX\"
"
```

Optional — run the prerequisites checker inside the container:

```bash
docker exec -it "$CTR" bash -lc "
  curl -L -o /tmp/oradba_check.sh https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh &&
  chmod +x /tmp/oradba_check.sh &&
  /tmp/oradba_check.sh --dir \"$PREFIX\"
"
```

### Step 4: Use OraDBA Inside the Container

```bash
docker exec -it "$CTR" bash -lc "
  source \"$PREFIX/bin/oraenv.sh\" FREE &&
  oradba_extension.sh list
"
```

Replace `FREE` with your SID if different.

### Notes and Tips

- **Persisting install:** Mount a host volume to `$PREFIX`
  (e.g., `-v /opt/oradba:/opt/oradba`) so the install survives container rebuilds.
- **Air-gapped:** Download `oradba_install.sh` on the host, copy it into the container
  (`docker cp oradba_install.sh $CTR:/tmp/`), then run it as above.
- **Missing root access:** If you cannot use root in the container, ensure required tools
  are already present or bake them into a custom image.

## Updating OraDBA

### Update from GitHub

```bash
# Update to latest version
$PREFIX/bin/oradba_install.sh --update --github

# Update to specific version
$PREFIX/bin/oradba_install.sh --update --github --version 0.7.4
```

### Update from Local Installer

```bash
# Download latest installer
curl -L -o oradba_install.sh \
  https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh
chmod +x oradba_install.sh

# Update existing installation
./oradba_install.sh --update

# Force reinstall (repair)
./oradba_install.sh --force --prefix /opt/oradba
```

### Check for Updates

```bash
# Check if updates are available
$PREFIX/bin/oradba_version.sh --update-check

# Show detailed version information
$PREFIX/bin/oradba_version.sh --info
```

### Update Behavior

- **Automatic backup** — Creates `${PREFIX}.backup.TIMESTAMP` before update
- **Configuration preservation** — Detects modified files, saves as `.save` extension
- **Sensitive file preservation** — Keeps `etc/*.b64`, `*.pem`, `*.key`, `*.crt` and
  equivalent files in bundled extension `etc/` directories
- **Rollback on failure** — Restores previous version if update fails
- **Version detection** — Skips update if already running latest version
- **Selective replacement** — Only replaces core files, preserves customizations

### Uninstalling OraDBA

```bash
# Remove installation directory
rm -rf /opt/oradba

# Remove profile integration (if added)
# Edit ~/.bash_profile and remove the OraDBA section

# Remove user config (optional)
rm -f ~/.oradba_config

# Remove SID-specific configs
rm -f /opt/oradba/etc/sid.*.conf
```

**Note:** Always back up custom configurations before uninstalling.

## Troubleshooting

### Installer Not Found or Not Executable

```bash
# Check download
ls -l oradba_install.sh

# Make executable
chmod +x oradba_install.sh

# Check file type
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

# Inspect file
file oradba_install.sh
head -5 oradba_install.sh

# If still failing, report an issue on GitHub
```

### Disk Space Insufficient

```bash
# Check available space
df -h /opt

# Clean up temporary files
find /tmp -name "oradba*" -mtime +7 -delete

# Install to a location with more space
./oradba_install.sh --prefix /u01/app/oracle/local/oradba
```

### Missing Required Tools

```bash
# Check which tools are missing
./oradba_check.sh

# Install missing tools (RHEL/Oracle Linux)
sudo yum install bash tar gawk sed grep coreutils findutils

# For rlwrap (optional)
sudo yum install rlwrap
```

### Pre-Oracle Mode Issues

**"Oracle Base directory not found"** — use explicit prefix or user-level install:

```bash
./oradba_install.sh --user-level
# or
./oradba_install.sh --prefix /opt/local/oradba
```

**Tools not finding databases** — this is expected before Oracle installation.
Verify pre-Oracle mode with `oradba_validate.sh` (should report "Pre-Oracle" mode),
then after Oracle is installed run `oradba_setup.sh link-oratab`.

<!-- Web-only sections below: kept for MkDocs navigation, stripped during PDF build (build_pdf.sh). -->
## See Also {.unlisted .unnumbered}

- [Quick Start](quickstart.md) - Getting started with OraDBA
- [Configuration](configuration.md) - Customizing your installation
- [Troubleshooting](troubleshooting.md) - Solving installation issues

## Navigation {.unlisted .unnumbered}

**Previous:** [Introduction](introduction.md)
**Next:** [Quick Start](quickstart.md)
