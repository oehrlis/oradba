# CLAUDE.md - oradba

## Role in Ecosystem

`oradba` is the **base environment** for Oracle DBA tooling.
`odb_datasafe` is an extension of this library - look here for shared
conventions, library patterns, and common shell infrastructure before
creating anything new.

## Edit Policy

- **Read-only by default** - only modify when explicitly requested
- Changes here may affect multiple downstream consumers (odb_datasafe and others)
- Prefer reading existing functions/patterns over duplicating them elsewhere

## Key Conventions

- `#!/usr/bin/env bash`, `set -euo pipefail` on all scripts
- Script header: use skill `/bash-header` - always include Name, Author,
  Description, Version, Change History
- Config cascade: code defaults → env file → conf file → CLI args
- Library loading via `source` with path resolved from `BASH_SOURCE[0]`
- All output via `LogMessage`-style wrapper, not bare echo/printf
- Flags on all scripts: `--dry-run` | `--delete` | `--yes` | `--help`
- Secrets: always via `op read "op://vault/item/field"` - never hardcoded

## Rules (always active)

@.claude/rules/shell.md
@.claude/rules/markdown-lint.md

## Skills (load on demand)

- Bash scripts & headers    →  /bash-header
- Oracle Audit              →  /oracle-audit
- Oracle TDE                →  /oracle-tde
- Oracle Auth               →  /oracle-auth
- Oracle Data Safe          →  /oracle-datasafe
- Oracle Security           →  /oracle-security

## Testing

- `make test` — fast local BATS unit tests (no Docker, no Oracle)
- `make test-docker` — full Docker integration tests against Oracle 26ai Free
  (~10 min, resource-intensive); run manually or trigger via GitHub Actions on
  release tags — not suitable for every commit
- Test results land in `tests/results/`; failed runs produce a `*_failed_*.log`

## Known Open Issues

- **#180** — Config loader (`oradba_apply_config_section`) requires `[SECTION]`
  headers; shipped config files use plain shell exports. Planned fix: treat
  files without sections as `[DEFAULT]`. Tests use variable-presence checks
  as a workaround until the loader is fixed.

## Commands

/idea-capture       ← capture a new idea quickly
/update-docs        ← update CLAUDE.md or rules after significant work
/repo-review        ← analyse repo status and recommend next steps
/framework-review   ← full architecture & code review toward v1.0.0
