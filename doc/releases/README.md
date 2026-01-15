
This directory contains release notes for OraDBA versions.

## Current Release

### v1.0.0 - First Stable Release (2026-01-15)

- [v1.0.0](v1.0.0.md) - **Latest**: First production-ready release with comprehensive
  testing infrastructure, auto-discovery, enhanced service management, and complete documentation

## Archived Releases

Older releases (v0.9.4 through v0.18.5) are available in the [archive/](archive/) directory.

For a complete list of all releases, see [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Release Retention Policy

We maintain release notes for:

- **Current major/minor version**: Latest stable release (v1.0.0)
- **Older versions**: Pre-1.0 releases (v0.9.4 through v0.18.5) archived in `archive/` directory

## Usage

### View Release Notes

```bash
# Current release
cat doc/releases/v0.18.1.md
1.0.0.md

# Archived release
cat doc/releases/archive/v0.18.5.md
```

### Update GitHub Release

```bash
gh release edit v1.0.0 --notes-file doc/releases/v1.0.0

## File Naming Convention

Files follow the pattern: `v<MAJOR>.<MINOR>.<PATCH>.md`

Examples: `v1.0.0.md`, `v0.18.5.md`, `v0.18.4.md`
