# Extension System

The OraDBA extension system allows you to add custom scripts, SQL files, and RMAN
scripts in a modular way without modifying the core OraDBA installation.

> **Note:** This document provides complete extension development guidance for the
> current OraDBA extension framework.
> For historical implementation context, see [archive/](archive/).

## Overview

Extensions are separate directories parallel to `ORADBA_BASE`, typically located in
`${ORADBA_LOCAL_BASE}` (e.g., `/opt/oracle/local/customer`). Each extension can provide:

- **bin/** - Scripts automatically added to PATH
- **sql/** - SQL scripts automatically added to SQLPATH
- **rcv/** - RMAN scripts added to RMAN search paths
- **etc/** - Configuration examples (not auto-loaded)
- **lib/** - Library files (not auto-loaded)

Extensions are discovered automatically and loaded in priority order during environment setup.

## Directory Structure

### OraDBA Installation

```text
/opt/oracle/local/
├── oradba/              # Core OraDBA installation (ORADBA_BASE)
│   ├── bin/
│   ├── sql/
│   ├── rcv/
│   ├── etc/
│   ├── lib/
│   └── log/             # Centralized logs (shared by extensions)
│
├── customer/            # Example extension
│   ├── .extension       # Metadata file (optional)
│   ├── .extension.checksum  # Integrity checksums (optional)
│   ├── README.md
│   ├── bin/
│   │   └── my_tool.sh
│   ├── sql/
│   │   └── custom_query.sql
│   ├── rcv/
│   │   └── custom_backup.rman
│   └── etc/
│       └── customer.conf.example
│
└── acme/                # Another extension
    ├── .extension
    ├── bin/
    └── sql/
```

## Extension Metadata

Extensions can optionally include a `.extension` metadata file in YAML-like format:

```yaml
name: customer
version: 1.0.0
description: Customer-specific Oracle scripts and tools
author: DBA Team
enabled: true
priority: 10
provides:
  bin: true
  sql: true
  rcv: true
  etc: false
load_env: false
load_aliases: false
```

### Metadata Fields

| Field         | Required | Description                                 |
|---------------|----------|---------------------------------------------|
| `name`        | No       | Extension name (defaults to directory name) |
| `version`     | No       | Version string (for tracking)               |
| `description` | No       | Brief description                           |
| `author`      | No       | Author or team name                         |
| `enabled`     | No       | Whether to load (default: true)             |
| `priority`    | No       | Load order (lower = first, default: 50)     |
| `provides`    | No       | Which directories are present               |
| `load_env`    | No       | Source `etc/env.sh` when enabled            |
| `load_aliases`| No       | Source `etc/aliases.sh` when enabled        |

**Note**: Extensions work without a `.extension` file. The file is optional and only
provides additional metadata for tracking and management.

`etc/` hooks are **opt-in** and require both:

- Global flag: `ORADBA_EXTENSIONS_SOURCE_ETC=true`
- Extension metadata flag: `load_env: true` and/or `load_aliases: true`

If either condition is not met, `etc/env.sh` and `etc/aliases.sh` are not sourced.

### Integrity Verification

Extensions can include a `.extension.checksum` file containing SHA256 checksums for
integrity verification. This file:

- Uses the standard `.extension.checksum` filename (always the same, regardless of extension name)
- Contains SHA256 checksums in the format produced by `sha256sum`
- Is automatically verified by `oradba_version.sh --verify` and `--info`
- Supports exclusion patterns via `.checksumignore` file
- Is only checked for enabled extensions

Example `.extension.checksum`:

```text
# Extension checksums
a1b2c3d4e5f6...  bin/my_tool.sh
1a2b3c4d5e6f...  sql/custom_query.sql
```

When creating extensions with `oradba_extension.sh create --from-github`, the checksum
file is automatically included and verified.

**Managed Directories**: Integrity checks only verify files in these directories:

- `bin/` - Executable scripts
- `sql/` - SQL scripts
- `rcv/` - RMAN recovery catalog scripts
- `etc/` - Configuration files
- `lib/` - Library/function files

Other directories (e.g., `doc/`, `templates/`, `log/`) are not subject to integrity
verification, allowing users to freely add documentation or other files without
triggering checksum failures.

#### Checksum Exclusions (.checksumignore)

The `.checksumignore` file specifies patterns for files that should be excluded from
integrity checks. This is useful for:

- **Runtime-generated files**: logs, caches, temporary files
- **Credentials**: keystores, certificates, API keys
- **User-specific configs**: local overrides, customizations

**Default Exclusions** (always applied):

- `.extension` - Metadata file (may be modified)
- `.checksumignore` - This file itself
- `log/` - Log directory

**Syntax**:

- One pattern per line
- Lines starting with `#` are comments
- Empty lines are ignored
- Glob patterns supported:
  - `*` - matches any characters within a filename/directory
  - `?` - matches exactly one character
  - Patterns ending with `/` match directory contents

**Example `.checksumignore`**:

```text
# Default - log directory (already excluded)
log/

# Credentials and secrets
keystore/
secrets/
*.key
*.pem

# Cache and temporary files
cache/
tmp/
*.tmp
*.cache

# User-specific configurations
etc/*.local
```

#### Verbose Mode

Use `--verbose` flag to see detailed information about failed checks:

```bash
oradba_version.sh --verify --verbose

Extension Integrity Checks:
  ✗ Extension 'customer': FAILED
      Modified or missing files:
        ${CUSTOMER_BASE}/bin/tool.sh
      Additional files (not in checksum):
        ${CUSTOMER_BASE}/sql/new_query.sql
```

## Configuration

### Auto-Discovery (Default)

Extensions are automatically discovered in `${ORADBA_LOCAL_BASE}`:

```bash
# In oradba_core.conf (enabled by default)
export ORADBA_AUTO_DISCOVER_EXTENSIONS="true"
```

Any directory in `${ORADBA_LOCAL_BASE}` (except `oradba` itself) that contains:

- A `.extension` file, OR
- A `bin/`, `sql/`, or `rcv/` directory

...will be discovered and loaded automatically.

### Manual Configuration

You can explicitly configure extensions in `oradba_customer.conf`:

```bash
# Add additional extension paths (colon-separated)
export ORADBA_EXTENSION_PATHS="/custom/path/ext1:/another/path/ext2"

# Disable auto-discovery and use only manual paths
export ORADBA_AUTO_DISCOVER_EXTENSIONS="false"
```

### Override Extension Settings

Override extension behavior in `oradba_customer.conf`:

```bash
# Disable specific extension
export ORADBA_EXT_CUSTOMER_ENABLED="false"

# Change load priority (lower = first)
export ORADBA_EXT_ACME_PRIORITY="5"
```

Variable naming: `ORADBA_EXT_<NAME>_<SETTING>` where `<NAME>` is the extension name in uppercase.

## Loading Behavior

### Load Order

1. **Core OraDBA** - Always loaded first
2. **Extensions** - Loaded in priority order, then alphabetically
3. **ORACLE_HOME** - Oracle binaries
4. **System PATH** - System commands

### PATH Construction

```bash
# After loading 2 extensions (customer, acme):
PATH="${ORADBA_BIN}:${CUSTOMER_BIN}:${ACME_BIN}:${ORACLE_HOME}/bin:${SYSTEM_PATH}"
```

### PATH and SQLPATH Management

OraDBA maintains clean, unique PATH and SQLPATH values:

**On First Execution**:

- Saves original PATH to `ORADBA_ORIGINAL_PATH`
- Saves original SQLPATH to `ORADBA_ORIGINAL_SQLPATH`

**Every Time `oraenv.sh` is Sourced**:

1. Removes all extension paths matching `${ORADBA_LOCAL_BASE}/*/bin` and `*/sql`
2. Loads only enabled extensions
3. Deduplicates PATH and SQLPATH (keeps first occurrence)

**Benefits**:

- Sourcing `oraenv.sh` multiple times doesn't create duplicates
- Disabling an extension and re-sourcing removes it from PATH/SQLPATH
- Always produces consistent, clean environment

**Example**:

```bash
# First sourcing
$ source ${ORADBA_BASE}/bin/oraenv.sh ${ORACLE_SID}
$ echo $PATH | tr ':' '\n' | grep local
/opt/oracle/local/usz/bin
/opt/oracle/local/oradba/bin

# Re-sourcing doesn't create duplicates
$ source ${ORADBA_BASE}/bin/oraenv.sh ${ORACLE_SID}
$ echo $PATH | tr ':' '\n' | grep local
/opt/oracle/local/usz/bin          # Still only once!
/opt/oracle/local/oradba/bin       # Still only once!

# Disable extension
$ echo "enabled: false" >> /opt/oracle/local/usz/.extension
$ source ${ORADBA_BASE}/bin/oraenv.sh ${ORACLE_SID}
$ echo $PATH | tr ':' '\n' | grep local
/opt/oracle/local/oradba/bin       # usz is gone!
```

### Priority Sorting

Extensions are sorted by:

1. Priority value (lower number = loaded first)
2. Name (alphabetically if same priority)

**Example**:

```text
customer (priority 10) → loaded first
acme     (priority 50) → loaded second
tools    (priority 50) → loaded third (alphabetical after acme)
```

## Creating an Extension

### Using the create Command (Recommended)

The easiest way to create a new extension is using the `create` command:

```bash
# Create from default template
oradba_extension.sh create mycompany

# Create in custom location
oradba_extension.sh create mycompany --path /opt/oracle/custom

# Create from GitHub release (latest)
oradba_extension.sh create mycompany --from-github

# Create from custom template
oradba_extension.sh create mycompany --template /path/to/template.tar.gz
```

The `create` command will:

1. Validate the extension name (alphanumeric, dashes, underscores only)
2. Check that the extension doesn't already exist
3. Extract the template to the target location
4. Update the `.extension` metadata with the new name
5. Show detailed next steps for customization

**Template Sources**:

- **Default**: `${ORADBA_BASE}/templates/oradba_extension/extension-template.tar.gz`
  (downloaded during build from GitHub releases)
- **GitHub**: Latest release from [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)
- **Custom**: Any `.tar.gz` or `.tgz` file with extension structure

### Installing an Existing Extension

Use the `add` command to install extensions from GitHub or local tarballs:

```bash
# Install from GitHub (latest release)
oradba_extension.sh add oehrlis/odb_autoupgrade

# Install specific version
oradba_extension.sh add oehrlis/odb_autoupgrade@v0.5.0

# Install from full GitHub URL
oradba_extension.sh add https://github.com/oehrlis/odb_autoupgrade

# Install from local tarball
oradba_extension.sh add /path/to/extension.tar.gz

# Install with custom name
oradba_extension.sh add oehrlis/odb_xyz --name custom_name

# Install to custom location
oradba_extension.sh add oehrlis/odb_xyz --path /opt/oracle/custom

# Update existing extension
oradba_extension.sh add oehrlis/odb_xyz --update
```

The `add` command will:

1. Download the extension tarball (for GitHub sources, preferring release assets)
2. Validate the extension structure
3. Extract to target location
4. Enable the extension by default (`enabled: true`)
5. Show next steps for configuration

For GitHub repositories, `add` first uses release asset archives (`.tar.gz`/`.tgz`)
from the release page. It falls back to source tarballs only if no release asset
archive is available. This ensures extension package files such as
`.extension.checksum` are included when provided by the extension release.

**Update Behavior (`--update` flag)**:

- Creates timestamped backup: `<extension>_backup_YYYYMMDD_HHMMSS`
- Compares files against `.extension.checksum`
- Creates `.save` files for modified managed files (RPM-style)
- Preserves user-added files (for common extension file types), including
  `*.b64`, `*.pem`, `*.key`, and `*.crt`
- Preserves `log/` directory
- Installs new version
- Restores `.save` files alongside new configs

**Example Update Flow**:

```bash
# Initial install
$ oradba_extension.sh add oehrlis/odb_xyz

# Modify config
$ vi /opt/oracle/local/odb_xyz/etc/config.conf

# Update to new version
$ oradba_extension.sh add oehrlis/odb_xyz --update
Creating backup: /opt/oracle/local/odb_xyz_backup_20260108_143022
Checking for modified and user-added files...
  Preserving modified file: etc/config.conf
Installing new version...
Restoring modified and user-added files...

# Check for .save files
$ ls /opt/oracle/local/odb_xyz/etc/
config.conf       # New version from update
config.conf.save  # Your modified version preserved
```

### Minimal Extension

Create a directory with at least one content folder:

```bash
# Create extension structure
mkdir -p /opt/oracle/local/myext/{bin,sql,rcv}

# Add a script
cat > /opt/oracle/local/myext/bin/mytool.sh << 'EOF'
#!/bin/bash
echo "My custom tool"
EOF
chmod +x /opt/oracle/local/myext/bin/mytool.sh

# That's it! Extension will be auto-discovered on next login
```

### Extension with Metadata

Recommended for better tracking:

```bash
# Create .extension file
cat > /opt/oracle/local/myext/.extension << 'EOF'
name: myext
version: 1.0.0
description: My custom Oracle extension
author: John Doe
enabled: true
priority: 20
provides:
  bin: true
  sql: true
  rcv: true
EOF
```

### Extension with Configuration

If your extension needs configuration:

```bash
# Create example config
mkdir -p /opt/oracle/local/myext/etc
cat > /opt/oracle/local/myext/etc/myext.conf.example << 'EOF'
# My Extension Configuration
# Copy relevant settings to ${ORADBA_PREFIX}/etc/oradba_customer.conf

# Custom setting
export MYEXT_SETTING="value"

# Custom aliases (add to oradba_customer.conf if needed)
# alias mytool='mytool.sh --verbose'
EOF
```

**Important**: Extension config files in `etc/` are **not automatically loaded**. Users must manually copy settings to `oradba_customer.conf`.

## Navigation

Each loaded extension automatically gets a navigation alias:

```bash
# Navigate to extension
cde<name>

# Examples:
cdecustomer    # cd /opt/oracle/local/customer
cdeacme        # cd /opt/oracle/local/acme
cdemyext       # cd /opt/oracle/local/myext
```

## Managing Extensions

OraDBA provides the `oradba_extension.sh` command-line tool for managing extensions.

### Create Extension

```bash
# Create new extension from default template
oradba_extension.sh create mycompany

# Create from GitHub release
oradba_extension.sh create mycompany --from-github

# Create with custom template
oradba_extension.sh create mycompany --template /path/to/custom.tar.gz

# Create in specific location
oradba_extension.sh create mycompany --path /opt/oracle/custom
```

See [Creating an Extension](#creating-an-extension) for detailed information.

### List Extensions

```bash
# Show all extensions with status and version
oradba_extension.sh list

# Show detailed information for all extensions
oradba_extension.sh list --verbose

# Or use library function directly
source ${ORADBA_PREFIX}/lib/extensions.sh
list_extensions
```

### Show Extension Details

```bash
# Using management tool (recommended)
oradba_extension.sh info customer

# Or use library function
source ${ORADBA_PREFIX}/lib/extensions.sh
show_extension_info customer
```

### Validate Extension

```bash
# Validate a specific extension
oradba_extension.sh validate customer

# Validate all extensions
oradba_extension.sh validate-all

# Or use library function
source ${ORADBA_PREFIX}/lib/extensions.sh
validate_extension /opt/oracle/local/customer
```

### Other Management Commands

```bash
# Show auto-discovered extensions
oradba_extension.sh discover

# Display extension search paths
oradba_extension.sh paths

# List only enabled extensions
oradba_extension.sh enabled

# List only disabled extensions
oradba_extension.sh disabled

# Show help
oradba_extension.sh help
```

### Disable Extension

Add to `oradba_customer.conf`:

```bash
export ORADBA_EXT_CUSTOMER_ENABLED="false"
```

## Best Practices

### 1. Use Metadata Files

Always create `.extension` files for proper tracking:

- Makes extensions discoverable
- Documents version and purpose
- Enables proper load order control

### 2. Version Your Extensions

Include version info and maintain a changelog:

```text
myext/
├── .extension         # version: 1.2.0
├── CHANGELOG.md       # Version history
└── README.md          # Documentation
```

### 3. Provide Documentation

Each extension should have:

- `README.md` - What it does, how to use it
- `etc/*.conf.example` - Configuration examples
- Comments in scripts

### 4. Use Priority Wisely

- **1-10**: Critical extensions that must load first
- **10-30**: High priority extensions
- **30-50**: Normal priority (default: 50)
- **50+**: Lower priority extensions

### 5. Test in Isolation

Before adding to production:

```bash
# Test with only your extension
export ORADBA_AUTO_DISCOVER_EXTENSIONS="false"
export ORADBA_EXTENSION_PATHS="/path/to/myext"
source oraenv.sh
```

### 6. Avoid Core Conflicts

- Don't override core OraDBA commands
- Use unique naming for scripts
- Document any intentional overrides

### 7. Handle Logging

Extensions use centralized `${ORADBA_LOG}` by default. If you need extension-specific logs:

```bash
# In your extension script
LOG_DIR="${ORADBA_EXT_MYEXT_PATH}/log"
mkdir -p "${LOG_DIR}"
```

### 8. Configuration Pattern

Don't auto-load extension configs. Instead:

```bash
# In myext/etc/myext.conf.example:
# ============================================
# My Extension Configuration
# Copy required settings to:
#   ${ORADBA_PREFIX}/etc/oradba_customer.conf
# ============================================

# Custom environment variable
export MYEXT_DATABASE="PROD"

# Custom alias (optional)
# alias mydb='sqlplus myuser@${MYEXT_DATABASE}'
```

Users explicitly copy what they need to `oradba_customer.conf`.

## Troubleshooting

### Extension Not Loading

1. **Check discovery**:

```bash
echo "${ORADBA_LOCAL_BASE}"    # Should show /opt/oracle/local or similar
ls -la "${ORADBA_LOCAL_BASE}"  # Extension visible?
```

1. **Check .extension file** (if present):

```bash
cat /path/to/extension/.extension
# Verify enabled: true
```

1. **Check configuration**:

```bash
echo "${ORADBA_AUTO_DISCOVER_EXTENSIONS}"  # Should be 'true'
env | grep ORADBA_EXT_                     # Check for overrides
```

1. **Enable debug logging**:

```bash
export DEBUG=1
source oraenv.sh
# Look for extension loading messages
```

### Wrong Load Order

Extensions load in priority order (lowest first), then alphabetically. To change:

```bash
# In oradba_customer.conf
export ORADBA_EXT_MYEXT_PRIORITY="5"   # Load earlier
export ORADBA_EXT_OTHER_PRIORITY="99"  # Load later
```

### Command Not Found

If extension script not in PATH:

1. **Check directory**:

```bash
ls -la /opt/oracle/local/myext/bin
# Files should be executable
```

1. **Check PATH**:

```bash
echo "${PATH}"
# Should include /opt/oracle/local/myext/bin
```

1. **Make executable**:

```bash
chmod +x /opt/oracle/local/myext/bin/*.sh
```

### Extension Warnings

Extensions that fail validation are skipped with warnings. Check logs:

```bash
# Look for warnings during login
source oraenv.sh 2>&1 | grep -i extension
```

## Examples

See `doc/examples/extensions/` for complete examples:

- **customer/** - Basic extension with bin/ and sql/
- **acme/** - Extension with priority and metadata
- **tools/** - Extension with RMAN scripts

## Reference

### Environment Variables (Core Config)

| Variable                          | Default | Description                                |
|-----------------------------------|---------|--------------------------------------------|
| `ORADBA_AUTO_DISCOVER_EXTENSIONS` | `true`  | Auto-discover extensions                   |
| `ORADBA_EXTENSION_PATHS`          | `""`    | Additional extension paths (`:` separated) |
| `ORADBA_EXTENSIONS_IN_COEXIST`    | `false` | Load in coexistence mode                   |

### Environment Variables (Per-Extension)

| Variable                     | Example                               | Description                     |
|------------------------------|---------------------------------------|---------------------------------|
| `ORADBA_EXT_<NAME>_ENABLED`  | `ORADBA_EXT_CUSTOMER_ENABLED="false"` | Enable/disable                  |
| `ORADBA_EXT_<NAME>_PRIORITY` | `ORADBA_EXT_CUSTOMER_PRIORITY="10"`   | Load priority                   |
| `ORADBA_EXT_<NAME>_PATH`     | Set automatically                     | Extension path (long format)    |
| `<NAME>_BASE`                | Set automatically                     | Extension path (e.g. USZ_BASE)  |

**Note**: The `<NAME>_BASE` variable is automatically exported when an extension is loaded.
For example, loading the `usz` extension creates `$USZ_BASE=/opt/oracle/local/usz`.

### Functions (lib/extensions.sh)

| Function                             | Description                              |
|--------------------------------------|------------------------------------------|
| `discover_extensions()`              | Find all extensions in ORADBA_LOCAL_BASE |
| `load_extensions()`                  | Load all enabled extensions              |
| `load_extension <path>`              | Load single extension                    |
| `list_extensions [--verbose]`        | List all extensions                      |
| `show_extension_info <name>`         | Show extension details                   |
| `validate_extension <path>`          | Validate extension structure             |
| `get_extension_name <path>`          | Get extension name                       |
| `get_extension_version <path>`       | Get extension version                    |
| `get_extension_priority <path>`      | Get load priority                        |
| `is_extension_enabled <name> <path>` | Check if enabled                         |

## See Also

- [Configuration System](../src/doc/configuration.md)
- [Architecture](architecture.md)
- [Development Guide](development.md)
