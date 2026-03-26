# CLAUDE.md – oradba

## Role in Ecosystem

`oradba` is the **base environment** for Oracle DBA tooling.
`odb_datasafe` is an extension of this library – look here for shared
conventions, library patterns, and common shell infrastructure before
creating anything new.

## Edit Policy

- **Read-only by default** – only modify when explicitly requested
- Changes here may affect multiple downstream consumers (odb_datasafe and others)
- Prefer reading existing functions/patterns over duplicating them elsewhere

## Key Conventions

- `#!/usr/bin/env bash`, `set -euo pipefail` on all scripts
- Script header: use skill `/bash-header` – always include Name, Author,
  Description, Version, Change History
- Config cascade: code defaults → env file → conf file → CLI args
- Library loading via `source` with path resolved from `BASH_SOURCE[0]`
- All output via `LogMessage`-style wrapper, not bare echo/printf
- Flags on all scripts: `--dry-run` | `--delete` | `--yes` | `--help`
- Secrets: always via `op read "op://vault/item/field"` – never hardcoded

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

## Commands

/idea-capture    ← capture a new idea quickly
/update-docs     ← update CLAUDE.md or rules after significant work
/repo-review     ← analyse repo status and recommend next steps
