# CLAUDE.md — oradba

## Role in Ecosystem

`oradba` is the **base environment** for Oracle DBA tooling.
`odb_datasafe` is an extension of this library — look here for shared conventions,
library patterns, and common shell infrastructure before creating anything new.

## Edit Policy

- **Read-only by default** — only modify when explicitly requested by the user
- Changes here may affect multiple downstream consumers (odb_datasafe and others)
- Prefer reading existing functions/patterns here over duplicating them elsewhere

## Key Conventions (shared with odb_datasafe)

- `#!/usr/bin/env bash`, `set -euo pipefail` on all scripts
- Standardized script header: Name, Author, Description, Version, Change History
- Config cascade: code defaults → env file → conf file → CLI args
- Library loading via `source` with path resolved from `BASH_SOURCE[0]`
- All output via a `LogMessage`-style wrapper, not bare echo/printf
