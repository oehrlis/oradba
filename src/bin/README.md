# OraDBA Executable Scripts

Main executable scripts for OraDBA operations.

## Available Scripts

- **[oraenv.sh](oraenv.sh)** - Set Oracle environment from oratab
  - Interactive SID selection with numbered list
  - Case-insensitive SID matching
  - Database status display
  - Silent mode for scripting
  
- **[oradba_version.sh](oradba_version.sh)** - Version and integrity management
  - Check installed version
  - Verify installation integrity with checksums
  - Check for updates from GitHub
  - Display installation metadata

- **[dbstatus.sh](dbstatus.sh)** - Display database status information
  - Instance and database details
  - PDB information
  - Memory and session statistics

## Usage Examples

```bash
# Set Oracle environment
source oraenv.sh FREE

# Check version
oradba_version.sh --check

# Verify integrity
oradba_version.sh --verify

# Show database status
dbstatus.sh
```

## Documentation

See [USAGE.md](../doc/USAGE.md) for comprehensive usage guide and examples.
