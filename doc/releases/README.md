
This directory contains release notes for OraDBA versions.

## Current Release

### v0.19.0 - Plugin Architecture Release (2026-01-19)

- [v0.19.0](v0.19.0.md) - **Latest**: Plugin architecture adoption with v1.0.0 plugins,
  complete function documentation (437 functions), comprehensive testing (1082 tests across 65 test files),
  and code cleanup

## Archived Releases

- **Older releases** (v0.9.4 through v0.18.5): Available in [archive/](archive/) directory
- **Internal v1.x releases** (v1.0.0 through v1.2.2): Removed in v0.19.0+ cleanup
  - These were internal development versions superseded by v0.19.0
  - Available in git history if needed for reference
- **Phase 4 development docs**: Removed in v0.19.0+ cleanup
  - Architectural decisions integrated into main documentation
  - Available in git history if needed for reference

For a complete list of all releases, see [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Release Retention Policy

We maintain release notes for:

- **Current version**: Latest stable release (v0.19.0)
- **Older versions**: Pre-v0.19.0 releases (v0.9.4 through v0.18.5) in `archive/` directory
- **Historical releases**: Internal v1.x and Phase 4 development docs removed (available in git history)

## Usage

### View Release Notes

```bash
# Current release
cat doc/releases/v0.19.0.md

# Archived release
cat doc/releases/archive/v0.18.5.md
```

### Update GitHub Release

```bash
gh release edit v0.19.0 --notes-file doc/releases/v0.19.0.md
```

## File Naming Convention

Files follow the pattern: `vMAJOR.MINOR.PATCH.md`

Examples: `v0.19.0.md`, `v0.18.5.md`, `v0.18.4.md`
