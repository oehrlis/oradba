# Release Notes Archive

This directory stores release notes for OraDBA versions, used to update GitHub release information.

## Purpose

- Archive historical release notes
- Enable updating GitHub releases via CLI
- Provide reference for release content

## Usage

Update an existing GitHub release:

```bash
gh release edit v0.10.2 --notes-file doc/releases/v0.10.2.md
```

View a specific release notes:

```bash
cat doc/releases/v0.10.1.md
```

## File Naming Convention

Files follow the pattern: `v<MAJOR>.<MINOR>.<PATCH>.md`

Examples:

- `v0.10.2.md`
- `v0.10.1.md`
- `v0.10.0.md`

## Location

Release notes are created during the release process and saved to
`/tmp/release_notes_<version>.md`, then copied here for archival.
