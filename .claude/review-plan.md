# oradba Major Review Plan

> Created: 2026-03-10
> Status: In Progress
> Model: claude-sonnet-4-6

This plan tracks a systematic review of the oradba repository across all major
dimensions. Each topic has a status, priority, and concrete work items. Work
through topics sequentially or in parallel — check off items as completed.

---

## Status Legend

| Symbol | Meaning     |
|--------|-------------|
| `[ ]`  | Not started |
| `[~]`  | In progress |
| `[x]`  | Done        |

---

## Topic 1 — Repo Structure

**Priority:** Low (structure is already clean)
**Effort:** Small

### Findings

- Clean top-level layout: `src/`, `doc/`, `tests/`, `scripts/`, `dist/`
- One stale `.DS_Store` file in repo root
- `dist/` build artifacts may be partially tracked in git

### Work Items

- [ ] Remove `.DS_Store` from repo and add to `.gitignore` if missing
- [ ] Verify `dist/` is fully `.gitignore`d (no build artifacts committed)
- [ ] Review whether `doc/` (dev docs) vs `src/doc/` (user docs) split is
      always consistently respected — check for misplaced files
- [ ] Confirm `templates/` content is up to date with current script header
      standards (see Topic 7)

---

## Topic 2 — CI/CD Pipeline

**Priority:** Medium
**Effort:** Medium

### Findings

- 5 workflows: `ci.yml`, `docker-tests.yml`, `docs.yml`, `release.yml`,
  `dependency-review.yml`
- Smart test selection via `.testmap.yml` — good
- Docker integration tests are **manual-trigger only** (resource constraints)
- Linting: shellcheck with `-x` and `-S warning`
- PDF generation baked into `docs.yml`

### Work Items

- [ ] Review `.github/workflows/ci.yml` — validate step order, timeout
      settings, and concurrency groups
- [ ] Add `workflow_dispatch` to `docs.yml` for on-demand doc rebuilds if
      missing
- [ ] Review `release.yml` — ensure checksums cover all artifacts and release
      notes are auto-generated from CHANGELOG
- [ ] Consider adding `markdownlint` to the lint step (currently shell-only)
- [ ] Evaluate whether Docker integration tests can be triggered automatically
      on tagged commits (not just manual)
- [ ] Review `.testmap.yml` completeness — are all new scripts/libs mapped?
- [ ] Add `shellcheck` version pinning in CI to avoid silent behavior changes
- [ ] Review `dependency-review.yml` — verify it covers all relevant
      dependency types

---

## Topic 3 — Developer Documentation

**Priority:** Medium
**Effort:** Medium

### Findings

- Excellent coverage: `CONTRIBUTING.md` (452 lines), `doc/development.md`,
  `doc/development-workflow.md`, `doc/function-header-guide.md`
- `doc/automated_testing.md` and `doc/manual_testing.md` present
- `/.claude/CLAUDE.md` covers ecosystem context and edit policy

### Work Items

- [ ] Review `CONTRIBUTING.md` for accuracy against current workflow
      (branch strategy, PR labels, release procedure)
- [ ] Review `doc/development.md` — check for outdated sections (especially
      around plugin system v1.0.0 and Registry API)
- [ ] Add or verify a `SECURITY.md` at repo root (disclosure policy)
- [ ] Ensure architecture diagrams in `doc/images/` are in sync with current
      code (plugin interface, library loading order, registry format)
- [ ] Validate that `doc/function-header-guide.md` reflects actual header
      format used in source (run a diff check)
- [ ] Review `.testmap.yml` documentation — is usage documented in dev guide?
- [ ] Add a "Getting Started for Contributors" quick-start section to
      `CONTRIBUTING.md` if missing

---

## Topic 4 — User Documentation

**Priority:** High (directly visible to users)
**Effort:** Large

### Findings

- 32 markdown chapters in `src/doc/`
- MkDocs Material theme, deployed to `https://code.oradba.ch/oradba`
- PDF user guide generated via Pandoc/Docker
- `mkdocs.yml` navigation is the canonical chapter order

### Work Items

- [ ] Read all 32 chapters; flag any that are outdated (especially install,
      quickstart, configuration)
- [ ] Verify `mkdocs.yml` nav matches actual files in `src/doc/` — no
      broken links or missing entries
- [ ] Review troubleshooting chapter — is it current with common issues?
- [ ] Add version table to docs (what oradba version introduced each feature)
- [ ] Review PDF metadata (`doc/metadata.yml`) after recent font/highlight
      changes — rebuild and visually inspect PDF
- [ ] Check that all Mermaid diagrams render correctly in both MkDocs site
      and generated PDF (post `<br>` fix)
- [ ] Verify API reference sections in mkdocs are auto-generated or
      manually maintained — identify gaps
- [ ] Review cross-references between chapters for broken internal links

---

## Topic 5 — Tool Architecture

**Priority:** High
**Effort:** Large

### Findings

- 30 binary scripts, 22 libraries, 9 plugins
- Registry API (`oradba_registry.sh`) is the central unifying abstraction
- Plugin interface v1.0.0 with 13 universal functions
- Extension system via `oradba_extension.sh` and `extensions.sh`
- Environment management split across 7 `oradba_env_*.sh` libraries
- `oradba_common.sh` is the largest single file (3,317 lines)

### Work Items

- [ ] Map the dependency graph: which scripts source which libraries —
      identify any circular or unexpected deps
- [ ] Review `oradba_common.sh` for cohesion — should any function groups
      be extracted into separate focused libraries?
- [ ] Review the 7 `oradba_env_*.sh` split — is the granularity appropriate
      or should some be merged/split differently?
- [ ] Review plugin interface: are all 13 functions consistently implemented
      in all 6 production plugins (database, datasafe, client, iclient, oud, java)?
- [ ] Review the 3 stub plugins (weblogic, oms, emagent) — document clearly
      or remove if no plan to implement
- [ ] Review `oradba_install.sh` (2,395 lines) and `oradba_extension.sh`
      (2,000 lines) for opportunities to extract helper libraries
- [ ] Review `oradba_aliases.sh` (11,963 lines) — understand generation
      mechanism; check for stale or wrong aliases
- [ ] Verify Registry API pipe-delimited format is used consistently across
      all consumers — no direct oratab parsing outside registry
- [ ] Review extension loading priority and conflict resolution

---

## Topic 6 — Code Best Practices

**Priority:** High
**Effort:** Large

### Findings

- `#!/usr/bin/env bash` 100% compliance
- `set -euo pipefail` intentionally NOT in sourced libraries (documented)
- Unified logging via `oradba_log` with 8 levels
- ShellCheck compliance at `warning` severity
- SC1091, SC2030, SC2031, SC2314, SC2315 disabled
- One deprecated function: `execute_plugin_function_v2()` with doc pointing
  to replacement

### Work Items

- [ ] Run shellcheck across entire `src/` tree; review all remaining
      warnings at `style` level — decide which to suppress vs fix
- [ ] Audit ShellCheck disabled checks — are SC2314/SC2315 still needed
      (BATS version-specific)?
- [ ] Review all `TODO` / `FIXME` / `HACK` comments (none found currently —
      verify with grep)
- [ ] Audit variable naming: spot-check that internal (non-oradba_) variables
      use `local` in functions
- [ ] Review all `|| true` usages — distinguish legitimate error suppression
      from accidental swallowing
- [ ] Audit `2>/dev/null` suppressions — each one should be intentional
- [ ] Check that `oradba_log` is used consistently; no stray bare `echo` or
      `printf` for user-visible output in library files
- [ ] Review the deprecated `execute_plugin_function_v2()` — schedule removal
      in next minor version
- [ ] Verify all scripts handle missing `ORACLE_HOME` or `ORACLE_SID`
      gracefully (no uninitialised variable errors with `set -u`)

---

## Topic 7 — Redundant / Orphan Code

**Priority:** Medium
**Effort:** Medium
**Status:** Analysis complete — 5 actionable items identified

### Findings (2026-03-10)

**Dead functions (zero callers in production, safe to remove):**

- `get_listener_status()` — `src/bin/oraup.sh:204` — marked "legacy,
  backward compat" and has **no callers** anywhere (production or tests)
- `oradba_apply_oracle_plugin()` — `src/lib/oradba_common.sh:2975` —
  marked DEPRECATED, emits runtime WARN, no callers in production or tests

**Correction — NOT dead (keep):**

- `plugin_get_adjusted_paths()` — `src/lib/plugins/datasafe_plugin.sh:590`
  — called directly in `tests/test_datasafe_plugin.bats` (lines 192, 236)
  and acknowledged as a datasafe-specific extra in
  `tests/test_plugin_interface.bats:496`; may also be used by downstream
  `odb_datasafe` extension. The "legacy" note means "prefer interface
  functions for new callers", not "will be removed". **Do not delete.**
  Consider improving the Notes comment to clarify it remains supported.

**Orphaned scripts in `scripts/` (not referenced from Makefile or CI):**

- `scripts/archive_github_releases.sh` — 0 references
- `scripts/fix_doc_links.py` — 0 references
- `scripts/generate_api_docs.py` — 0 references
- `scripts/generate_api_docs.sh` — 0 references

**Stale documentation reference:**

- `src/rcv/README.md` references `.rman` extension as "legacy" format but
  no `.rman` files exist in the repo — stale sentence

**Clean (no action needed):**

- `src/templates/script_template.sh` — current: `oradba_log`, correct
  shebang, proper library loading ✓
- `dist/` — correctly `.gitignore`d at `/dist/`, nothing tracked ✓
- `doc/images/` — all 14 Mermaid diagram files referenced ≥1 time ✓
- `src/sql/` — no deprecated Oracle statistics syntax (`ANALYZE TABLE`
  occurrence in `aud_policies_create_aud.sql` is an audit policy topic
  list, not a deprecated call) ✓
- `src/rcv/` — "obsolete" references are to RMAN's own `DELETE OBSOLETE`
  command (current, valid syntax), not deprecated code ✓

### Work Items

- [x] Grep `deprecated/legacy/TODO/FIXME/HACK` across `src/`
- [x] Check `src/templates/` — current ✓
- [x] Audit `scripts/` for orphaned helpers
- [x] Check `dist/` git tracking — clean ✓
- [x] Audit `src/sql/` for deprecated Oracle features — clean ✓
- [x] Audit `src/rcv/` for outdated RMAN syntax — clean ✓
- [x] Check `doc/images/` Mermaid files are all referenced ✓
- [ ] **Remove** dead function `get_listener_status()` from
      `src/bin/oraup.sh` (function + header comment block)
- [ ] **Remove** deprecated `oradba_apply_oracle_plugin()` from
      `src/lib/oradba_common.sh` — no callers found
- [ ] **Clarify** `plugin_get_adjusted_paths()` Notes comment in
      `datasafe_plugin.sh` — replace misleading "legacy" with "datasafe-specific
      helper, not part of standard interface; remains supported"
- [x] **Orphaned scripts resolved**:
      `fix_doc_links.py` removed (legacy migration); `generate_api_docs.sh`
      removed (superseded by Python version); `generate_api_docs.py` wired
      into Makefile as `make docs-api` (also added to `make docs` and
      `make docs-clean`); `archive_github_releases.sh` rewritten — hardcoded
      list replaced with dynamic GitHub release discovery (`--keep N` /
      `--before VERSION`)
- [ ] **Clean up** stale `.rman` reference in `src/rcv/README.md`

---

## Topic 8 — API and Plugin System

**Priority:** High
**Effort:** Medium

### Findings

- Registry API: single unified interface, pipe-delimited format
- Plugin system: 13-function universal interface v1.0.0
- Extension system: parallel directory structure, auto-discovery
- 4 official extensions: oradba_extension, odb_datasafe, odb_autoupgrade,
  odb_extras

### Work Items

- [ ] Review Registry API function signatures for consistency; generate or
      update API reference doc
- [ ] Verify all 6 production plugins implement the full 13-function interface
      (no missing or no-op stubs)
- [ ] Review plugin version declaration mechanism — how is the interface
      version enforced at load time?
- [ ] Review `extensions.sh` loading logic — edge cases (missing extension
      dir, wrong permissions, conflicting names)
- [ ] Document the extension contract more explicitly: what a compliant
      extension must/may/must-not provide
- [ ] Review `.github/extensions.yml` — is it current? Does it include all
      known extensions?
- [ ] Design or document an upgrade path when the plugin interface version
      changes (v1.0.0 → v2.0.0)
- [ ] Consider adding a `--list-plugins` / `--list-extensions` flag to a
      diagnostic script for users

---

## Topic 9 — General Optimisation and Best Practices

**Priority:** Medium
**Effort:** Medium

### Findings

- Large scripts (`oradba_install.sh`, `oradba_extension.sh`) are well-organized
  but could benefit from helper extraction
- Configuration cascade (6 levels) is powerful but complex
- No documented performance benchmarks

### Work Items

- [ ] Profile startup time of `oraenv.sh` sourcing (library loading) — set
      a target and identify bottlenecks if slow
- [ ] Review configuration cascade: document the resolution order clearly in
      one place (currently spread across multiple files)
- [ ] Review `oradba_install.sh` for opportunities to share code with
      `oradba_extension.sh` (both do download/extract/install flows)
- [ ] Review error messages for user-friendliness — are they actionable?
      Do they include enough context (file, line, suggestion)?
- [ ] Evaluate whether any SQL scripts (`src/sql/`) should be parameterised
      more consistently (avoid hardcoded schema names, tablespace names)
- [ ] Review RMAN scripts (`src/rcv/`) for modern best practices (e.g.
      section size, backup optimization, catalog vs nocatalog)
- [ ] Consider adding a `--version` flag to all binary scripts (currently
      only some implement it)
- [ ] Evaluate `ORADBA_` variable namespace — any collisions with Oracle's
      own environment variables?

---

## Cross-Cutting Items

These apply across multiple topics:

- [ ] **Grep for hardcoded paths** — `/opt/oracle`, `/u01`, etc. — each
      should be a variable referencing the configured install prefix
- [ ] **Review all `exit 1`** — should use a named exit code constant or
      at least a comment explaining the error
- [ ] **Audit test coverage gaps** — identify any `src/bin/` scripts with
      less than ~5 BATS test cases
- [ ] **Review all external tool dependencies** — `yq`, `python3`, `docker`,
      `pandoc` — are optional dependencies handled gracefully?

---

## Execution Order (Suggested)

1. **Topic 7** (Orphan/Redundant) — quick wins, cleanup first
2. **Topic 6** (Code Best Practices) — foundation for everything else
3. **Topic 5** (Tool Architecture) — understand before changing
4. **Topic 8** (API/Plugin) — closely related to architecture
5. **Topic 4** (User Docs) — visible to users, high value
6. **Topic 2** (CI/CD) — infrastructure reliability
7. **Topic 3** (Dev Docs) — keep in sync with changes made above
8. **Topic 9** (Optimisation) — fine-tuning after cleanup
9. **Topic 1** (Repo Structure) — final housekeeping

---

## Notes

- This repo is **read-only by default** per CLAUDE.md — only modify when
  explicitly requested
- Downstream consumers: `odb_datasafe` (extension), `exatoolbox` (wrapper)
  — breaking changes here have wide impact
- Plugin interface v1.0.0 is a stability contract — changes require
  versioned migration path
