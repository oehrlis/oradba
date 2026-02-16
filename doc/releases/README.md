
This directory contains release notes for OraDBA versions.

## Current Release

Release notes are stored one file per release using semantic version filenames:
`vMAJOR.MINOR.PATCH.md`.

- To see the latest release notes, open the highest versioned file in this directory
  or check [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Archived Releases

- **Older releases** (v0.9.4 through v0.18.5): Available in [archive/](archive/) directory
- **Internal v1.x releases** (v1.0.0 through v1.2.2): Removed during cleanup
  - These were internal development versions superseded by stable semver releases
  - Available in git history if needed for reference
- **Phase 4 development docs**: Removed during cleanup
  - Architectural decisions integrated into main documentation
  - Available in git history if needed for reference

For a complete list of all releases, see [GitHub Releases](https://github.com/oehrlis/oradba/releases).

## Release Retention Policy

We maintain release notes for:

- **Current versions**: Recent stable releases in this directory
- **Older versions**: Pre-v0.19.0 releases (v0.9.4 through v0.18.5) in `archive/` directory
- **Historical releases**: Internal v1.x and Phase 4 development docs removed (available in git history)

## Usage

### View Release Notes

```bash
# Latest release in this directory
ls -1 doc/releases/v*.md | sort -V | tail -1

# Archived release
cat doc/releases/archive/v0.18.5.md
```

### Update GitHub Release

```bash
LATEST_TAG="$(git describe --tags --abbrev=0)"
gh release edit "${LATEST_TAG}" --notes-file "doc/releases/${LATEST_TAG}.md"
```

## File Naming Convention

Files follow the pattern: `vMAJOR.MINOR.PATCH.md`

Examples: `v0.21.3.md`, `v0.20.6.md`, `v0.19.10.md`
