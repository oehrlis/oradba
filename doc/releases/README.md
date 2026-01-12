
This directory contains release notes for OraDBA versions.

## Current Releases

### v0.18.x Series (Current)

- [v0.18.1](v0.18.1.md) - Latest: ALIAS_NAME support for Oracle Homes
- [v0.18.0](v0.18.0.md) - Enhanced testing framework

### v0.17.x Series (Previous)

- [v0.17.0](v0.17.0.md) - Previous minor release

## Archived Releases

Older releases (v0.9.4 through v0.16.0) are available in the [archive/](archive/) directory.

For a complete list of all releases, see [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Release Retention Policy

We maintain release notes for:

- **Current minor version**: All patch releases (0.18.x)
- **Previous minor version**: All patch releases (0.17.x)
- **Older versions**: Archived in `archive/` directory

## Usage

### View Release Notes

```bash
# Current release
cat doc/releases/v0.18.1.md

# Archived release
cat doc/releases/archive/v0.16.0.md
```

### Update GitHub Release

```bash
gh release edit v0.18.1 --notes-file doc/releases/v0.18.1.md
```

## File Naming Convention

Files follow the pattern: `v<MAJOR>.<MINOR>.<PATCH>.md`

Examples: `v0.18.1.md`, `v0.18.0.md`, `v0.17.0.md`
