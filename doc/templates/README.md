# Header Templates

Standard file header templates for OraDBA scripts and configuration files.

## Overview

This directory contains header templates used by OraDBA scripts and build system. Templates ensure consistent documentation, attribution, and licensing across all project files.

## Available Templates

| Template | File Type | Description |
|----------|-----------|-------------|
| [header.sh](header.sh) | Shell scripts | Bash/shell script header template |
| [header.sql](header.sql) | SQL scripts | SQL*Plus script header template |
| [header.rman](header.rman) | RMAN scripts | RMAN script header template |
| [header.conf](header.conf) | Configuration | Configuration file header template |

**Total Templates:** 4

## Usage

### During Development

Headers are manually added when creating new files:

```bash
# For shell scripts
cat doc/templates/header.sh > new_script.sh
echo "# Your script content" >> new_script.sh

# For SQL scripts
cat doc/templates/header.sql > new_query.sql
echo "-- Your SQL content" >> new_query.sql
```

### During Build

Build system automatically adds/updates headers:

```bash
# Build process adds headers to distribution files
make build

# Validate headers
make lint
```

## Template Structure

### Shell Script Header (header.sh)

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Monitoring and Administration Scripts
# Name.........: script_name.sh
# Description..: Brief description
# Author.......: Your Name (github.com/yourusername)
# Version......: 1.0
# Date.........: YYYY-MM-DD
# ------------------------------------------------------------------------------
# Copyright (c) YYYY OraDBA Contributors. All rights reserved.
# Licensed under the Apache License v2.0
# ------------------------------------------------------------------------------
```

**Includes:**
- Shebang line
- Project name and description
- File metadata (name, description, author, version, date)
- Copyright and license information

### SQL Script Header (header.sql)

```sql
-- ------------------------------------------------------------------------------
-- OraDBA - Oracle Database Monitoring and Administration Scripts
-- Name.........: script_name.sql
-- Description..: Brief description
-- Requirements.: Privilege level required
-- Author.......: Your Name
-- Version......: 1.0
-- Date.........: YYYY-MM-DD
-- ------------------------------------------------------------------------------
-- Copyright (c) YYYY OraDBA Contributors. All rights reserved.
-- Licensed under the Apache License v2.0
-- ------------------------------------------------------------------------------
```

**Includes:**
- Project information
- File metadata
- Requirements/prerequisites
- Copyright and license

### RMAN Script Header (header.rman)

```rman
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Monitoring and Administration Scripts
# Name.........: script_name.rman
# Description..: Brief description
# Usage........: rman target / @script_name.rman
# Author.......: Your Name
# Version......: 1.0
# Date.........: YYYY-MM-DD
# ------------------------------------------------------------------------------
# Copyright (c) YYYY OraDBA Contributors. All rights reserved.
# Licensed under the Apache License v2.0
# ------------------------------------------------------------------------------
```

**Includes:**
- Project information
- File metadata
- Usage example
- Copyright and license

### Configuration Header (header.conf)

```bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Monitoring and Administration Scripts
# Name.........: config_name.conf
# Description..: Brief description
# Author.......: Your Name
# Version......: 1.0
# Date.........: YYYY-MM-DD
# ------------------------------------------------------------------------------
# Copyright (c) YYYY OraDBA Contributors. All rights reserved.
# Licensed under the Apache License v2.0
# ------------------------------------------------------------------------------
```

**Includes:**
- Project information
- File metadata
- Copyright and license

## Header Guidelines

### Required Fields

All headers must include:

1. **Name** - File name
2. **Description** - Brief purpose statement (1-2 lines)
3. **Author** - Creator name and GitHub username
4. **Version** - Semantic version (X.Y)
5. **Date** - Creation or last major update (YYYY-MM-DD)
6. **Copyright** - Copyright statement
7. **License** - License reference (Apache License v2.0)

### Optional Fields

Additional fields as needed:

- **Requirements** - Prerequisites (SQL scripts)
- **Usage** - Usage example (RMAN scripts)
- **Parameters** - Script parameters
- **Notes** - Important notes or warnings
- **Dependencies** - External dependencies

### Format Standards

1. **Width** - 80 characters maximum
2. **Separator** - Consistent dashed line (78 dashes)
3. **Alignment** - Right-align field values after dots
4. **Spacing** - Single blank line after header
5. **Comments** - Use appropriate comment syntax for file type

## Maintenance

### Updating Templates

When modifying templates:

1. Update all template files consistently
2. Maintain backward compatibility
3. Update this documentation
4. Test with build system
5. Update version in affected files

### Adding New Templates

To add a new template type:

1. Create template file with appropriate extension
2. Follow existing structure and format
3. Add to table in this README
4. Update build scripts if needed
5. Document usage and requirements

## Version Tracking

### Semantic Versioning

Version numbers follow semantic versioning:

- **Major.Minor** format (e.g., 1.0, 2.1)
- **Major** - Significant changes, breaking changes
- **Minor** - New features, enhancements
- Increment version when making substantial changes

### Date Format

- Use ISO 8601 format: **YYYY-MM-DD**
- Update date on significant changes
- Keep original creation date in version history

## Integration

### Build System

Templates are integrated with build process:

```bash
# Validate headers
make lint

# Check header compliance
scripts/validate_headers.sh

# Build with headers
make build
```

### Linting

Headers are validated during linting:

- Required fields present
- Format compliance
- License consistency
- Copyright year current

## Documentation

- **[Development Guide](../development.md)** - Coding standards and guidelines
- **[Markdown Linting](../markdown-linting.md)** - Documentation standards
- **[Project Structure](../structure.md)** - File organization

## Development

### Best Practices

1. **Consistency** - Use templates for all new files
2. **Attribution** - Credit contributors appropriately
3. **Completeness** - Fill in all required fields
4. **Accuracy** - Keep metadata current
5. **Licensing** - Include license reference

### Example Usage

Creating a new shell script:

```bash
# 1. Copy template
cat doc/templates/header.sh > src/bin/my_script.sh

# 2. Update metadata
# Edit name, description, author, version, date

# 3. Add script content
cat >> src/bin/my_script.sh << 'EOF'

# Your script code here
echo "Hello OraDBA"
EOF

# 4. Make executable
chmod +x src/bin/my_script.sh

# 5. Validate
make lint
```

See [development.md](../development.md) for complete guidelines.
