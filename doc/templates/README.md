# OraDBA Header Templates

Standard file header templates for OraDBA scripts and documentation.

## Available Templates

- **[header.sh](header.sh)** - Shell script header
- **[header.sql](header.sql)** - SQL script header
- **[header.rman](header.rman)** - RMAN script header
- **[header.conf](header.conf)** - Configuration file header

## Usage

Headers are automatically added by build scripts and should include:

- File description and purpose
- Author and contact information
- Version and date tracking
- License reference
- Usage examples (where applicable)

## Maintenance

When updating templates:

1. Maintain consistent format across all header types
2. Update version tracking format
3. Run validation: `make lint`

## Documentation

See [DEVELOPMENT.md](../DEVELOPMENT.md) for:

- Header format guidelines
- Version tracking conventions
- Documentation standards
