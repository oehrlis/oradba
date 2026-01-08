# OraDBA Release 0.16.0

**Release Date:** 2026-01-08

## Overview

This release introduces a major enhancement to the extension system with the new `add` command, comprehensive PATH/SQLPATH management improvements, and critical bug fixes for extension loading.

## What's New

### Extension Add Command

A powerful new command for installing existing extensions from multiple sources:

```bash
# Install from GitHub (short name)
oradba_extension.sh add oehrlis/odb_autoupgrade

# Install specific version
oradba_extension.sh add oehrlis/odb_xyz@v1.0.0

# Install from local tarball
oradba_extension.sh add /path/to/extension.tar.gz

# Update existing extension
oradba_extension.sh add oehrlis/odb_xyz --update
```

**Features:**
- Automatic download from GitHub repositories (releases, tags, or branches)
- Local tarball installation support
- Structure validation before installation
- RPM-style configuration updates (creates `.save` backup files)
- Timestamped backups before updates
- Preserves logs and user data

### PATH/SQLPATH Management Overhaul

Complete rewrite of extension path management to fix duplication and cleanup issues:

**Clean Slate Approach:**
- Saves original PATH/SQLPATH on first load
- Removes all extension paths before each reload
- Only adds paths for enabled extensions
- Automatically deduplicates all paths

**Benefits:**
- No more PATH pollution from multiple `oraenv.sh` sourcing
- Disabled extensions immediately removed from PATH
- First occurrence preserved in deduplication
- Predictable, repeatable behavior

## Critical Fixes

### Extension Loading

**Fixed: Core oradba commands disappeared after login**
- `remove_extension_paths()` was incorrectly removing the main `oradba/bin` directory
- Core commands like `oraup.sh` were no longer in PATH
- Now explicitly preserves `oradba/bin` and `oradba/sql` directories

**Fixed: Verbose output hiding important information**
- Extension loading messages changed from INFO to DEBUG level
- Login shells now show clean output
- Use `DEBUG=1` to see extension loading details when troubleshooting

### Extension Path Management

**Fixed: Disabled extensions not removed until logout**
- Extensions now properly removed from PATH when disabled
- No need to logout/login to see changes

**Fixed: PATH duplication on multiple oraenv.sh sourcing**
- Each `oraenv.sh` source would add duplicate paths
- Now deduplicates automatically

## Installation

### From Distribution

```bash
# Download and extract
tar -xzf oradba-0.16.0.tar.gz
cd oradba-0.16.0

# Run installer
./oradba_install.sh
```

### Upgrade from Previous Version

```bash
# Download new version
curl -LO https://github.com/oehrlis/oradba/releases/download/v0.16.0/oradba_install.sh

# Run installer (will detect and upgrade existing installation)
bash oradba_install.sh
```

## Breaking Changes

None. This release is fully backward compatible with 0.15.0.

## Testing Recommendations

After upgrading, verify:

1. **Extension Loading:**
   ```bash
   # Source oraenv multiple times
   source /opt/oracle/local/oradba/bin/oraenv.sh
   source /opt/oracle/local/oradba/bin/oraenv.sh
   
   # Check for duplicate paths
   echo $PATH | tr ':' '\n' | sort | uniq -d
   ```

2. **Extension Add Command:**
   ```bash
   # Test installation
   oradba_extension.sh add oehrlis/odb_autoupgrade
   
   # Verify extension loaded
   oradba_extension.sh list
   ```

3. **Extension Disable/Enable:**
   ```bash
   # Disable extension
   oradba_extension.sh disable <extension_name>
   
   # Verify removed from PATH
   echo $PATH | grep <extension_name>
   
   # Enable again
   oradba_extension.sh enable <extension_name>
   ```

## Documentation Updates

- [Extension System Guide](../extension-system.md) - Updated with add command examples
- [Quick Start Guide](../src/doc/03-quickstart.md) - Added installation examples
- [Extensions Reference](../src/doc/18-extensions.md) - Complete add command documentation

## Known Issues

None at this time.

## Contributors

- Stefan Oehrli (@oehrlis)

## Full Changelog

See [CHANGELOG.md](../../CHANGELOG.md) for complete list of changes.

## Feedback

Please report issues or suggestions:
- GitHub Issues: https://github.com/oehrlis/oradba/issues
- Email: stefan.oehrli@oradba.ch
