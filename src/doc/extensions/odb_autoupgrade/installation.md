# Installation

This guide covers installing and setting up an OraDBA extension.

## Prerequisites

- OraDBA v0.17.0 or later installed
- Bash shell environment
- Appropriate permissions for installation directory

## Installation Methods

### Method 1: Extract to OraDBA Local Directory (Recommended)

Extract the extension to your OraDBA local directory for automatic discovery:

```bash
# Set OraDBA base directory (if not already set)
export ORADBA_LOCAL_BASE="${ORACLE_BASE}/local"

# Extract extension
cd "${ORADBA_LOCAL_BASE}"
tar -xzf /path/to/extension-1.0.0.tar.gz

# Verify extraction
ls -la extension/
```

**Result:** The extension is automatically discovered when you next source `oraenv.sh`.

### Method 2: Custom Location

Extract to a custom location and OraDBA will discover it:

```bash
# Extract to custom directory
mkdir -p /opt/oracle/extensions
cd /opt/oracle/extensions
tar -xzf /path/to/extension-1.0.0.tar.gz

# OraDBA will find it if it's parallel to OraDBA installation
```

## Verification

### 1. Check Extension is Loaded

```bash
# Source OraDBA environment
source oraenv.sh MYSID

# List loaded extensions
oradba_extension.sh list

# Should show your extension
```

### 2. Verify Scripts are in PATH

```bash
# Check if extension scripts are available
which my-custom-script.sh

# Should return path to the script
```

### 3. Verify SQL Scripts

```bash
# Check SQLPATH includes extension
echo $SQLPATH | tr ':' '\n' | grep extension

# Should show extension sql directory
```

## Configuration

### Using Configuration Examples

Extensions provide example configurations in their `etc/` directory:

```bash
# View example configuration
cat "${ORADBA_LOCAL_BASE}/extension/etc/extension.conf.example"

# Copy settings to main OraDBA config
vim "${ORADBA_PREFIX}/etc/oradba_customer.conf"

# Add needed settings from the example
```

### Configuration Locations

OraDBA checks configurations in this order:

1. `${ORADBA_PREFIX}/etc/oradba.conf` - Main configuration
2. `${ORADBA_PREFIX}/etc/oradba_customer.conf` - Customer overrides
3. Extension configurations (loaded automatically)

## Integrity Verification

Verify extension integrity after installation:

```bash
# OraDBA automatically verifies checksums when loading extensions
# Check logs for verification results
grep -i checksum "${ORADBA_PREFIX}/log/oradba.log"
```

If checksums don't match, you'll see a warning indicating which files changed.

## Updating

To update an extension:

```bash
# Remove old version
rm -rf "${ORADBA_LOCAL_BASE}/extension"

# Extract new version
cd "${ORADBA_LOCAL_BASE}"
tar -xzf /path/to/extension-2.0.0.tar.gz

# Reload environment
source oraenv.sh MYSID
```

## Uninstallation

To remove an extension:

```bash
# Remove extension directory
rm -rf "${ORADBA_LOCAL_BASE}/extension"

# Reload environment
source oraenv.sh MYSID
```

## Troubleshooting

### Extension Not Loaded

**Problem:** Extension doesn't appear in `oradba_extension.sh list`

**Solutions:**

1. Check directory location:

   ```bash
   # Extension must be parallel to OraDBA
   ls -la "${ORADBA_LOCAL_BASE}"/
   ```

2. Verify `.extension` file exists:

   ```bash
   cat "${ORADBA_LOCAL_BASE}/extension/.extension"
   ```

3. Check for errors:

   ```bash
   tail -f "${ORADBA_PREFIX}/log/oradba.log"
   ```

### Scripts Not in PATH

**Problem:** Extension scripts not found

**Solutions:**

1. Reload environment:

   ```bash
   source oraenv.sh MYSID
   ```

2. Check PATH:

   ```bash
   echo $PATH | tr ':' '\n' | grep extension
   ```

### Checksum Warnings

**Problem:** Checksum verification warnings appear

**Solutions:**

1. Re-download extension from official source
2. Verify SHA256 checksum of tarball:

   ```bash
   sha256sum extension-1.0.0.tar.gz
   # Compare with .sha256 file
   ```

3. Check `.checksumignore` if you've added custom files

## Next Steps

- Review [Configuration](configuration.md) options
- Explore [Reference](reference.md) for available scripts and tools
- Check [Development](development.md) if contributing
