# Extension System

**Purpose:** Guide to OraDBA extension system for adding custom scripts and tools.

**Audience:** DBAs and developers extending OraDBA functionality.

The OraDBA extension system allows you to add custom scripts and tools without modifying the core OraDBA
installation. Extensions are automatically discovered and integrated into your environment, working seamlessly with the
Registry API and Plugin System.

## What Are Extensions

Extensions are directories parallel to your OraDBA installation that contain custom:

- **Scripts** (`bin/`) - Added to PATH automatically
- **SQL Scripts** (`sql/`) - Added to SQLPATH for SQL*Plus
- **RMAN Scripts** (`rcv/`) - Available for RMAN operations
- **Configuration** (`etc/`) - Example configurations
- **Libraries** (`lib/`) - Shared bash libraries

OraDBA automatically discovers extensions in `${ORADBA_LOCAL_BASE}` (typically
`/opt/oracle/local`). Extensions are identified by:

1. **Metadata file**: Directories with `.extension` file
2. **Content directories**: Directories with `bin/`, `sql/`, or `rcv/` subdirectories

The core OraDBA installation (`/opt/oradba`) is excluded from discovery.

### Navigation Aliases {.unlisted .unnumbered}

OraDBA creates navigation aliases for each extension:

```bash
# If extension name is "customer"
cdecustomer              # cd to extension directory

# If extension name is "monitoring"
cdemonitoring           # cd to monitoring extension
```

Each loaded extension also exports a `<NAME>_BASE` variable pointing to its directory:

```bash
echo $CUSTOMER_BASE    # /opt/oracle/local/customer
echo $USZ_BASE         # /opt/oracle/local/usz
```

## Quick Start

### Creating an Extension

#### Method 1: Using the create command (Recommended)

```bash
# Create new extension from default template
oradba_extension.sh create mycompany

# Follow the displayed next steps:
# 1. Review and customize files
# 2. Edit .extension metadata
# 3. Add your scripts to bin/, sql/, rcv/
# 4. Reload environment
source oraenv.sh FREE

# Verify extension is loaded
oradba_extension.sh list
```

#### Method 2: Manual creation

1. **Create extension directory**:

   ```bash
   mkdir -p /opt/oracle/local/customer/bin
   mkdir -p /opt/oracle/local/customer/sql
   ```

2. **Add your scripts**:

   ```bash
   # Add a custom database script
   cat > /opt/oracle/local/customer/bin/check_db.sh << 'EOF'
   #!/usr/bin/env bash
   echo "Custom database check for ${ORACLE_SID}"
   sqlplus -s / as sysdba << SQL
   SELECT name, open_mode FROM v\$database;
   SQL
   EOF

   chmod +x /opt/oracle/local/customer/bin/check_db.sh
   ```

3. **Source OraDBA environment**:

   ```bash
   source oraenv.sh FREE
   # Extension is auto-discovered and loaded

   check_db.sh  # Your script is now in PATH
   ```

### Optional: Add Metadata

Create a `.extension` file for better tracking:

```bash
cat > /opt/oracle/local/customer/.extension << 'EOF'
name: customer
version: 1.0.0
priority: 10
author: DBA Team
description: Customer-specific Oracle tools and scripts
EOF
```

### Database Monitoring Extension Example

```bash
mkdir -p /opt/oracle/local/monitoring/{bin,sql}

# Add monitoring script
cat > /opt/oracle/local/monitoring/bin/check_tablespaces.sh << 'EOF'
#!/usr/bin/env bash
sqlplus -s / as sysdba @${ORADBA_LOCAL_BASE}/monitoring/sql/tablespaces.sql
EOF

# Add SQL query
cat > /opt/oracle/local/monitoring/sql/tablespaces.sql << 'EOF'
SET PAGESIZE 100 LINESIZE 200
SELECT tablespace_name,
       ROUND(used_space*8192/1024/1024,2) used_mb,
       ROUND(tablespace_size*8192/1024/1024,2) size_mb,
       ROUND(used_percent,2) pct_used
FROM dba_tablespace_usage_metrics
ORDER BY pct_used DESC;
EOF

chmod +x /opt/oracle/local/monitoring/bin/check_tablespaces.sh
```

### Backup Extension Example

```bash
mkdir -p /opt/oracle/local/backup/{bin,rcv}

# Add backup script
cat > /opt/oracle/local/backup/bin/backup_db.sh << 'EOF'
#!/usr/bin/env bash
rman target / @${ORADBA_LOCAL_BASE}/backup/rcv/level0.rman
EOF

# Add RMAN script
cat > /opt/oracle/local/backup/rcv/level0.rman << 'EOF'
RUN {
  BACKUP DATABASE PLUS ARCHIVELOG;
  DELETE NOPROMPT OBSOLETE;
}
EOF

chmod +x /opt/oracle/local/backup/bin/backup_db.sh
```

## Managing Extensions

Use the `oradba_extension.sh` command-line tool to create, install, inspect, and validate extensions.

### Create

```bash
# Create from default template
oradba_extension.sh create mycompany

# Create from GitHub release
oradba_extension.sh create mycompany --from-github

# Create with custom template
oradba_extension.sh create mycompany --template /path/to/template.tar.gz

# Create in custom location
oradba_extension.sh create mycompany --path /opt/oracle/custom
```

The create command validates the extension name, extracts the template to the target location,
updates metadata with the new name, and displays next steps for customization.

### Add / Install

Install existing extensions from GitHub or local tarballs:

```bash
# Install from GitHub (latest release)
oradba_extension.sh add oehrlis/odb_autoupgrade

# Install specific version
oradba_extension.sh add oehrlis/odb_autoupgrade@v1.2.0

# Install from local tarball
oradba_extension.sh add /path/to/extension.tar.gz

# Update existing extension (preserves modified configs)
oradba_extension.sh add oehrlis/odb_autoupgrade --update

# Install with custom name
oradba_extension.sh add oehrlis/odb_xyz --name custom_name
```

The add command downloads and extracts the extension, validates its structure, and enables it by default.
When updating with `--update`, it:

- Creates a timestamped backup (e.g., `extension_backup_20260211_193500/`)
- Preserves modified files detected via `.extension.checksum`
- Preserves user-added files: `*.conf`, `*.sh`, `*.sql`, `*.rcv`, `*.rman`, `*.env`, `*.properties`
- Installs new extension content
- Restores all preserved files to their original locations

This means customized configuration files (e.g., `etc/datasafe.conf`) and custom scripts you have added
to `bin/`, `sql/`, or `rcv/` are automatically preserved and restored during the update.

### List

```bash
# Show all extensions
oradba_extension.sh list

# NAME                 VERSION      PRIORITY   STATUS
# ----                 -------      --------   ------
# customer             1.0.0        10         Enabled
# monitoring           2.1.0        20         Enabled

# Show detailed information
oradba_extension.sh list --verbose

# List only enabled or disabled extensions
oradba_extension.sh enabled
oradba_extension.sh disabled
```

### Info

```bash
oradba_extension.sh info customer

# Extension Information
# =====================
# Name:        customer
# Version:     1.0.0
# Enabled:     yes
# Priority:    10
# Path:        /opt/oracle/local/customer
# ...
```

### Validate

```bash
# Validate specific extension
oradba_extension.sh validate customer

# Validate all extensions
oradba_extension.sh validate-all
```

### Discover

```bash
# Show auto-discovered extensions
oradba_extension.sh discover

# Display search paths
oradba_extension.sh paths
```

## Configuration

### Priority and Load Order

Extensions support priority-based loading (lower number = higher priority):

```bash
# In .extension file
priority: 10
```

Extensions are loaded in PATH as:

1. Core OraDBA (`${ORADBA_BIN}`)
2. Extensions (by priority: 10, 20, 30, ...)
3. Oracle Home (`${ORACLE_HOME}/bin`)
4. System PATH

This ensures OraDBA core commands are always available, high-priority extensions can override Oracle tools,
and low-priority extensions do not interfere with core functionality.

### Enable/Disable Extensions

In `oradba_customer.conf`:

```bash
# Disable specific extension
export ORADBA_EXT_CUSTOMER_ENABLED="false"

# Enable extension (default)
export ORADBA_EXT_CUSTOMER_ENABLED="true"
```

### Override Priority

```bash
# Change priority (lower = higher priority)
export ORADBA_EXT_CUSTOMER_PRIORITY="5"
```

### Manual Extension Paths

```bash
# Add extensions not in ORADBA_LOCAL_BASE
export ORADBA_EXTENSION_PATHS="/data/ext1:/opt/custom/ext2"
```

### Disable Auto-Discovery

```bash
# Disable auto-discovery (use only manual paths)
export ORADBA_AUTO_DISCOVER_EXTENSIONS="false"
```

### Extension Structure

**Minimal extension** — a single content directory is sufficient:

```text
/opt/oracle/local/customer/
└── bin/
    └── my_script.sh
```

**Complete extension** with all optional components:

```text
/opt/oracle/local/customer/
├── .extension              # Metadata (optional)
├── .extension.checksum     # SHA256 checksums for integrity (optional)
├── README.md              # Documentation (recommended)
├── bin/                   # Executable scripts (added to PATH)
│   ├── tool1.sh
│   └── tool2.sh
├── sql/                   # SQL scripts (added to SQLPATH)
│   ├── query1.sql
│   └── query2.sql
├── rcv/                   # RMAN scripts (ORADBA_RCV_PATHS)
│   └── backup.rman
├── etc/                   # Configuration examples
│   └── config.example
└── lib/                   # Shared libraries
    └── functions.sh
```

**Best practices:**

1. Always create `.extension` for version tracking
2. Include `README.md` with usage instructions
3. Keep extensions in version control (git)
4. Run `oradba_extension.sh validate` before deployment
5. Avoid overriding core OraDBA commands
6. Choose distinctive script names to avoid conflicts
7. Use `${ORADBA_LOG}` for logging (shared by default)
8. Use `etc/` for configuration templates

## Available Extensions

Extensions are separate packages that integrate with OraDBA to provide additional functionality. Each
extension has its own repository and version numbers, follows the standard OraDBA directory structure
(`bin/`, `sql/`, `rcv/`, `lib/`, etc.), is automatically discovered when placed parallel to the OraDBA
installation, and can be installed using the OraDBA extension management tools.

<!-- This section is automatically updated by the documentation build workflow -->
<!-- EXTENSIONS_LIST_START -->
### OraDBA Extension Template

**Repository:** [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)
**Category:** Development
**Status:** Active
**Version:** v0.4.0

Template for creating OraDBA extensions with priority-based loading, provides metadata, and comprehensive documentation

**Features:**

- Priority-based loading (default: 50, range: 10-90)
- Selective directory inclusion via provides metadata
- OraDBA library dependency tracking
- Environment variables and navigation aliases
- Example scripts (bin/, sql/, rcv/)

[View Documentation](https://github.com/oehrlis/oradba_extension#readme){ .md-button }

### OraDBA Data Safe Extension

**Repository:** [oehrlis/odb_datasafe](https://github.com/oehrlis/odb_datasafe)
**Category:** Operations
**Status:** Active

Tools for managing Oracle Data Safe targets in OCI with simplified CLI and comprehensive logging

[View Documentation](https://github.com/oehrlis/odb_datasafe#readme){ .md-button }

### OraDBA AutoUpgrade Extension

**Repository:** [oehrlis/odb_autoupgrade](https://github.com/oehrlis/odb_autoupgrade)
**Category:** Operations
**Status:** Active

Oracle AutoUpgrade wrapper scripts with ready-to-use configs for database upgrades

[View Documentation](https://github.com/oehrlis/odb_autoupgrade#readme){ .md-button }

### OraDBA Extras Extension

**Repository:** [oehrlis/odb_extras](https://github.com/oehrlis/odb_extras)
**Category:** Utilities
**Status:** Active
**Version:** v0.1.0

User-specific tools and wrappers for GNU utilities, OCI CLI, jq, and other commonly used tools

**Features:**

- GNU tar wrapper (gnu-tar) for consistent behavior on Solaris/Linux
- OCI CLI enhancements (oci-wrapper)
- JSON processing helpers (jq wrappers)
- Additional command-line utilities
- No database dependencies (works with any Oracle product)

[View Documentation](https://github.com/oehrlis/odb_extras#readme){ .md-button }

<!-- EXTENSIONS_LIST_END -->

### Contributing Extensions

To have your extension listed here:

1. **Follow the structure** - Use the standard OraDBA extension layout
2. **Add documentation** - Include markdown docs in your repository's README
3. **Submit a request** - Open an issue or PR to add your extension to this catalog
4. **Review process** - Extensions are reviewed for quality and compatibility

Each extension maintains its own documentation in its GitHub repository. At minimum, the README should include
an overview and features, installation instructions, configuration options, usage examples and command reference,
and a changelog with version history. See the
[Extension Template](https://github.com/oehrlis/oradba_extension) for a complete example with comprehensive
documentation structure.

## Troubleshooting

### Extension Not Found

**Problem**: Extension doesn't appear in `oradba_extension.sh list`

**Solutions**:

1. Check directory location:

   ```bash
   ls -la ${ORADBA_LOCAL_BASE}
   ```

2. Verify content directories exist:

   ```bash
   ls -la /opt/oracle/local/customer/bin
   ```

3. Check discovery setting:

   ```bash
   echo ${ORADBA_AUTO_DISCOVER_EXTENSIONS}
   ```

### Scripts Not in PATH

**Problem**: Extension scripts not available after sourcing oraenv

**Solutions**:

1. Verify files are executable:

   ```bash
   chmod +x /opt/oracle/local/customer/bin/*.sh
   ```

2. Check PATH includes extension:

   ```bash
   echo ${PATH} | tr ':' '\n' | grep customer
   ```

3. Source oraenv again:

   ```bash
   source oraenv.sh ${ORACLE_SID}
   ```

### Integrity Check Failures

**Problem**: Extension shows failed checksum verification

**Symptoms**:

```text
Extension Integrity Checks:
  Managed directories: bin, sql, rcv, etc, lib
  (Other directories like doc/ and templates/ are not verified)
  ✗ Extension 'customer': FAILED
```

**Note**: Only files in managed directories (`bin`, `sql`, `rcv`, `etc`, `lib`) are
verified. Files in other directories like `doc/`, `templates/`, or `log/` are
intentionally excluded from integrity checks.

**Solutions**:

1. Verify extension is enabled:

   ```bash
   oradba_extension.sh list
   # Disabled extensions are not checked
   ```

2. Check what files changed:

   ```bash
   # Use verbose mode to see details
   oradba_version.sh --info --verbose

   # Or check manually
   cd /opt/oracle/local/customer
   sha256sum -c .extension.checksum
   ```

3. Update checksums after intentional changes:

   ```bash
   cd /opt/oracle/local/customer
   # Regenerate checksums for all files
   find bin sql rcv etc lib -type f 2>/dev/null | sort | \
     xargs sha256sum > .extension.checksum
   ```

4. Exclude files from integrity checks by creating or editing `.checksumignore`:

   ```bash
   # Add patterns to .checksumignore
   cat >> .checksumignore << 'EOF'
   # Temporary files
   tmp/
   *.tmp

   # Credentials (if stored in extension)
   keystore/
   secrets/
   EOF
   ```

**Checksum Exclusions (.checksumignore)**:

The `.checksumignore` file lets you exclude specific files or patterns from integrity checks.

Default exclusions (always applied): `.extension` (metadata file), `.checksumignore` (this file itself),
and `log/` (log directory).

Pattern syntax:

- One pattern per line, `#` for comments
- `*` matches any characters: `*.log`, `data/*.cache`
- `?` matches one character: `file?.txt`
- Patterns ending with `/` match directories: `tmp/`, `keystore/`

Common patterns:

```text
# Runtime files
cache/
tmp/
*.tmp
*.cache

# Credentials
keystore/
secrets/
*.key
*.pem

# User configs
etc/*.local
```

Use `oradba_version.sh --verify --verbose` to see detailed output showing exactly which files
are modified, missing, or untracked.

### Priority Issues

**Problem**: Wrong extension loads first

**Solution**: Set priority explicitly in `oradba_customer.conf`:

```bash
export ORADBA_EXT_IMPORTANT_PRIORITY="5"   # Loads last (appears first in PATH)
export ORADBA_EXT_OTHER_PRIORITY="50"      # Loads first (appears later in PATH)
```

## See Also {.unlisted .unnumbered}

- **[Configuration Guide](configuration.md)** - Configuration hierarchy and environment variables
- **[Troubleshooting](troubleshooting.md)** - General troubleshooting reference

---

**Next Chapter**: [Troubleshooting](troubleshooting.md) | **Previous Chapter**: [Functions Library](functions.md)
