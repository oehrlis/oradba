
This directory contains release notes for OraDBA versions.

## Current Release

### v0.19.0 - Plugin Architecture Release (2026-01-19)

- [v0.19.0](v0.19.0.md) - **Latest**: Plugin architecture adoption with v1.0.0 plugins,
  complete function documentation (437 functions), comprehensive testing (1033 tests),
  and code cleanup

## Archived Releases

- **Internal v1.x releases** (v1.0.0 through v1.2.2): Archived in [archive/v1-internal/](archive/v1-internal/)
  - These were internal development versions that have been superseded by v0.19.0
- **Older releases** (v0.9.4 through v0.18.5): Available in [archive/](archive/) directory
- **Phase 4 development docs**: Architectural decision records in [archive/phase-4-development/](archive/phase-4-development/)

For a complete list of all releases, see [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Release Retention Policy

We maintain release notes for:

- **Current version**: Latest stable release (v0.19.0)
- **Internal v1.x**: Development versions archived in `archive/v1-internal/`
- **Older versions**: Pre-v0.19.0 releases (v0.9.4 through v0.18.5) in `archive/` directory
- **Development docs**: Phase 4 architectural records in `archive/phase-4-development/`

## Usage

### View Release Notes

```bash9.0.md

# Archived release
cat doc/releases/archive/v0.18.5.md

# Internal v1.x release (archived)
cat doc/releases/archive/v1-internal/v1.2.0.md
```

### Update GitHub Release

```bash
gh release edit v0.19.0 --notes-file doc/releases/v0.19.0.md
```

## File Naming Convention

Files follow the pattern: `vMAJOR.MINOR.PATCH.md`

Examples: `v0.19.0.md`, `v0.18.5.md`, `v0.18.4.md`
