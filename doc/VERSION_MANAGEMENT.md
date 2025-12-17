# Version Management

OraDBA includes a comprehensive version management system that enables version-aware installations, updates, and compatibility checking.

## Overview

The version management infrastructure provides:

- **Version Information**: Read and display OraDBA version
- **Version Comparison**: Semantic versioning comparison (MAJOR.MINOR.PATCH)
- **Compatibility Checking**: Verify version requirements
- **Installation Metadata**: Track installation details and history
- **Update Support**: Foundation for safe version updates

## VERSION File

The `VERSION` file in the root directory contains the current OraDBA version:

```
0.6.1
```

This file is:
- Read by the build system to create versioned installers
- Used by runtime functions to determine the current version
- Updated during version bumps

## Installation Metadata

The `.install_info` file stores installation metadata:

```bash
# OraDBA Installation Information
VERSION="0.6.1"
INSTALL_DATE="2025-12-17T08:02:47Z"
INSTALL_USER="oracle"
INSTALL_HOST="dbserver01"
INSTALL_METHOD="installer"
INSTALL_SOURCE="local"
ORADBA_BASE="/opt/oradba"
ORACLE_BASE="/u01/app/oracle"
```

### Metadata Fields

| Field | Description | Example |
|-------|-------------|---------|
| `VERSION` | OraDBA version installed | `0.6.1` |
| `BUILD_DATE` | When the installer was built | `2025-12-17T08:02:47Z` |
| `INSTALL_DATE` | When OraDBA was installed | `2025-12-17T10:30:00Z` |
| `INSTALL_USER` | User who performed installation | `oracle` |
| `INSTALL_HOST` | Host where OraDBA is installed | `dbserver01` |
| `INSTALL_METHOD` | How OraDBA was installed | `installer`, `git`, `update` |
| `INSTALL_SOURCE` | Installation source | `local`, `github`, `update` |
| `ORADBA_BASE` | OraDBA installation directory | `/opt/oradba` |
| `ORACLE_BASE` | Oracle base directory | `/u01/app/oracle` |

## Version Management Functions

### get_oradba_version()

Reads the current OraDBA version from the VERSION file.

```bash
version=$(get_oradba_version)
echo "Current version: ${version}"
# Output: Current version: 0.6.1
```

### version_compare()

Compares two semantic versions.

**Returns:**
- `0` - Versions are equal
- `1` - First version is greater
- `2` - First version is less

```bash
version_compare "0.7.0" "0.6.1"
result=$?
if [[ ${result} -eq 1 ]]; then
    echo "0.7.0 is newer than 0.6.1"
fi
```

**Features:**
- Supports semantic versioning (MAJOR.MINOR.PATCH)
- Handles version prefixes (`v0.6.1` → `0.6.1`)
- Handles pre-release versions (`0.7.0-beta`)

### version_meets_requirement()

Checks if a version meets a minimum requirement.

```bash
if version_meets_requirement "0.6.1" "0.6.0"; then
    echo "Version requirement satisfied"
fi
```

### get_install_info()

Retrieves a value from the `.install_info` file.

```bash
install_date=$(get_install_info "INSTALL_DATE")
install_user=$(get_install_info "INSTALL_USER")
echo "Installed on ${install_date} by ${install_user}"
```

### set_install_info()

Sets or updates a value in the `.install_info` file.

```bash
set_install_info "LAST_UPDATE" "2025-12-17T15:30:00Z"
set_install_info "UPDATE_SOURCE" "github"
```

### init_install_info()

Initializes a new `.install_info` file with installation metadata.

```bash
init_install_info "0.6.1"
```

This creates the `.install_info` file with:
- Version information
- Installation timestamp
- User and host information
- Installation paths

### show_version_info()

Displays comprehensive version and installation information.

```bash
show_version_info
```

**Output:**
```
OraDBA Version: 0.6.1

Installation Details:
  Installed: 2025-12-17T10:30:00Z
  Method: installer
  Source: local
  User: oracle
  Base: /opt/oradba
```

## Usage Examples

### Check Version Before Operation

```bash
#!/usr/bin/env bash
# Check if OraDBA version meets requirements

source "${ORADBA_BASE}/lib/common.sh"

REQUIRED_VERSION="0.6.0"
CURRENT_VERSION=$(get_oradba_version)

if ! version_meets_requirement "${CURRENT_VERSION}" "${REQUIRED_VERSION}"; then
    log_error "OraDBA ${REQUIRED_VERSION} or higher required"
    log_error "Current version: ${CURRENT_VERSION}"
    exit 1
fi

log_info "Version check passed: ${CURRENT_VERSION}"
```

### Update Installation Metadata

```bash
#!/usr/bin/env bash
# Update installation info after configuration change

source "${ORADBA_BASE}/lib/common.sh"

set_install_info "LAST_CONFIG_UPDATE" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
set_install_info "CONFIG_VERSION" "2"

log_info "Configuration metadata updated"
```

### Version-Aware Feature Check

```bash
#!/usr/bin/env bash
# Check if a feature is available in current version

source "${ORADBA_BASE}/lib/common.sh"

CURRENT_VERSION=$(get_oradba_version)

if version_meets_requirement "${CURRENT_VERSION}" "0.7.0"; then
    # Use new features available in 0.7.0
    log_info "Using enhanced installation features"
    use_local_installer=true
else
    # Fall back to basic features
    log_info "Using basic installation"
    use_local_installer=false
fi
```

### Display Installation Summary

```bash
#!/usr/bin/env bash
# Show detailed installation information

source "${ORADBA_BASE}/lib/common.sh"

show_version_info

echo ""
echo "Oracle Environment:"
echo "  ORACLE_BASE: $(get_install_info "ORACLE_BASE")"
echo "  ORADBA_BASE: $(get_install_info "ORADBA_BASE")"
```

## Build Process

The build system automatically generates version metadata:

1. **Read VERSION file**: Current version extracted
2. **Generate .install_info**: Build metadata created
3. **Create checksums**: SHA256 hashes for all files including .install_info
4. **Package tarball**: All files bundled together

```bash
./scripts/build_installer.sh
```

**Generated files:**
- `dist/oradba_install.sh` - Self-contained installer
- `build/oradba-0.6.1.tar.gz` - Tarball payload
- Embedded `.install_info` - Installation metadata
- Embedded `.oradba.checksum` - File integrity checksums

## Testing

Comprehensive test suite validates all version functions:

```bash
./tests/test_version.sh
```

**Test coverage:**
- Version reading and parsing
- Version comparison (equal, greater, less)
- Version prefix handling
- Major version differences
- Requirement checking
- Installation metadata read/write
- Metadata persistence

All 11 tests validate the version management system.

## Integration with Other Features

The version management infrastructure enables:

### Update Capability (v0.7.0)
- Check current vs available version
- Download and verify updates
- Preserve configuration during updates
- Rollback on failure

### Local Installation (v0.7.0)
- Verify installer version
- Check compatibility with existing installation
- Track installation source (local vs GitHub)

### Prerequisites Check (v0.7.0)
- Verify minimum OraDBA version
- Check compatibility with Oracle versions
- Validate feature availability

### Bash Profile Integration (v0.7.0)
- Version-aware PATH updates
- Conditional feature loading based on version
- Profile compatibility checking

## Future Enhancements

Planned improvements for v0.8.0+:

- **Automatic Updates**: Check for and download new versions
- **Version Channels**: Stable, beta, development tracks
- **Migration Scripts**: Automated migration between versions
- **Dependency Tracking**: Track dependent package versions
- **Update Notifications**: Alert when new versions available
- **Rollback Support**: Revert to previous versions
- **Version History**: Track all installed versions

## Related Issues

- #6: Installation Enhancements (v0.7.0)
- #19: Parallel Installation Support (v0.8.0)
- #15: Extension System (v0.8.0)

## See Also

- [Installation Guide](QUICKSTART.md)
- [Update Procedure](USAGE.md) (coming in v0.7.0)
- [Architecture](ARCHITECTURE.md)
- [Development Guide](DEVELOPMENT.md)
