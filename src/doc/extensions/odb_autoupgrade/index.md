# OraDBA Extension Template

A ready-to-use template for creating OraDBA extensions with complete project structure,
build tooling, CI/CD workflows, and integrity verification.

## Overview

This extension template provides everything you need to create professional OraDBA extensions:

- **Complete Structure** - Pre-configured directories for scripts, SQL, RMAN, libraries
- **Build System** - Automated packaging with checksums and integrity verification
- **CI/CD Ready** - GitHub workflows for linting, testing, and releases
- **Rename Helper** - Quick customization script to make the template your own
- **Documentation** - This documentation structure for integration with main OraDBA docs

## Features

### Ready-to-Use Structure

```text
.extension                  # Extension metadata
bin/                        # Scripts added to PATH
sql/                        # SQL scripts added to SQLPATH
rcv/                        # RMAN scripts
etc/                        # Configuration examples
lib/                        # Shared helper libraries
```

### Automated Build System

- Creates versioned tarballs: `<name>-<version>.tar.gz`
- Generates SHA256 checksums automatically
- Includes integrity verification with `.extension.checksum`
- Configurable file exclusions via `.checksumignore`

### CI/CD Workflows

- **Continuous Integration** - Shellcheck, markdownlint, BATS tests
- **Automated Releases** - Tag-based releases with automatic asset publishing
- **Quality Gates** - Ensures code quality before release

### Integrity Verification

Files matching patterns in `.checksumignore` are excluded from integrity checks:

```text
# Exclude log directory
log/

# Credentials and secrets
keystore/
*.key
*.pem

# Cache and temporary files
cache/
*.tmp
```

## Quick Start

### 1. Clone the Template

```bash
git clone https://github.com/oehrlis/oradba_extension.git my-extension
cd my-extension
```

### 2. Rename and Customize

```bash
# Rename the extension
./scripts/rename-extension.sh --name myext --description "My custom OraDBA tools"

# The script updates:
# - .extension metadata file
# - README.md references
# - Configuration file names
# - All template references
```

### 3. Add Your Content

```bash
# Add scripts
vim bin/my-custom-script.sh

# Add SQL scripts
vim sql/my-query.sql

# Add RMAN scripts
vim rcv/my-backup.rcv

# Add configuration examples
vim etc/myext.conf.example

# Add shared libraries
vim lib/myext-common.sh
```

### 4. Build and Test

```bash
# Build the extension package
./scripts/build.sh

# Output:
# dist/myext-1.0.0.tar.gz
# dist/myext-1.0.0.tar.gz.sha256
```

### 5. Release

```bash
# Tag and push to trigger release workflow
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# GitHub Actions will:
# - Run linting and tests
# - Build the tarball
# - Create GitHub release
# - Attach release assets
```

## Installation for Users

Users can install your extension:

```bash
# Extract to OraDBA local directory
cd ${ORADBA_LOCAL_BASE}
tar -xzf myext-1.0.0.tar.gz

# The extension is automatically discovered
# Next time oraenv.sh is sourced, myext is loaded
```

## Documentation

- [Installation](installation.md) - Detailed installation and setup instructions
- [Configuration](configuration.md) - Configuration options and examples
- [Reference](reference.md) - Scripts and tools reference
- [Development](development.md) - Development guide for contributors

## Use Cases

### Custom Database Scripts

Add organization-specific database maintenance scripts:

```bash
bin/my-health-check.sh
sql/company-standards-check.sql
```

### RMAN Backup Solutions

Create standardized backup scripts:

```bash
rcv/backup-full.rcv
rcv/backup-incremental.rcv
```

### Monitoring Integration

Integrate with monitoring systems:

```bash
bin/metrics-collector.sh
sql/performance-metrics.sql
```

### Compliance Tools

Implement compliance and audit tools:

```bash
bin/audit-report.sh
sql/compliance-checks.sql
```

## Support

- **Repository:** [oehrlis/oradba_extension](https://github.com/oehrlis/oradba_extension)
- **Issues:** [GitHub Issues](https://github.com/oehrlis/oradba_extension/issues)
- **Main OraDBA:** [OraDBA Documentation](https://code.oradba.ch/oradba/)

## License

Licensed under the Apache License 2.0. See [LICENSE](https://github.com/oehrlis/oradba_extension/blob/main/LICENSE)
for details.
