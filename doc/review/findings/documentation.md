# Documentation Review Findings - OraDBA v0.24.11
<!-- markdownlint-disable MD013 -->
**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-opus-4-8) **Scope:** README.md,
CONTRIBUTING.md, doc/, src/doc/, src/lib/README.md, src/bin/README.md, CHANGELOG.md, function
headers **Target:** v1.0.0

----------------------------------------------------------------------------------------------------

## Critical Findings

### DOC-001 - Registry API output format documented as colon-delimited; actual implementation is pipe-delimited

**Severity:** Critical **Files:** `doc/api.md:82`, `doc/architecture.md:154`, `doc/README.md:99`,
`src/lib/oradba_registry.sh:31-32`

`doc/api.md:82` states "All Registry API functions return colon-delimited entries" with format
`NAME:ORACLE_HOME:PRODUCT_TYPE:VERSION:AUTO_START:DESCRIPTION` (6 fields). `doc/architecture.md:154`
likewise says "colon-delimited format". Actual code: `readonly REGISTRY_FIELD_SEP="|"` (pipe).
Actual format: `type|name|home|version|flags|order|alias|desc` (8 fields, pipe-separated, different
field order and names). The only correct statement is `README.md:20`: "Consistent pipe-delimited
format: `type|name|home|version|flags|order|alias|desc`".

**Recommendation (analysis only):** Update `doc/api.md:82-95` and `doc/architecture.md:154` to
reflect the actual pipe-delimited format with the correct 8-field schema. Remove the conflicting
`NAME:ORACLE_HOME:...` format example from `api.md`.

----------------------------------------------------------------------------------------------------

### DOC-002 - api.md documents three registry functions that do not exist; four real functions are absent

**Severity:** Critical **Files:** `doc/api.md`, `src/lib/oradba_registry.sh`

`doc/api.md` documents `oradba_registry_get_by_home`, `oradba_registry_get_status`, and
`oradba_registry_validate_entry` with full syntax, argument, return value, and example sections.
None of these exist in `src/lib/oradba_registry.sh`. Also `doc/README.md:119-124` repeats the same
phantom function names. Four functions that DO exist in the implementation are entirely absent from
`api.md`: `oradba_registry_get_databases`, `oradba_registry_get_field`,
`oradba_registry_sync_oratab`, `oradba_registry_discover_all`.

**Recommendation (analysis only):** Audit the full function list in `oradba_registry.sh` against
`doc/api.md`. Remove documentation for the 3 phantom functions. Add documentation for the 4
undocumented real functions.

----------------------------------------------------------------------------------------------------

## High Findings

### DOC-003 - api.md "Last Updated" date and version pin are 5+ months stale

**Severity:** High **Files:** `doc/api.md:1,5,1423-1424`

`doc/api.md:1` reads "Complete function reference for OraDBA v0.19.0+ libraries." `doc/api.md:5`
reads "Last Updated: 2026-01-20". 22 releases have shipped since that date. `api.md` also describes
"6 product plugins" (line 349) and "standard 11-function interface" while actual counts are 9
plugins and 13 interface functions.

**Recommendation (analysis only):** Update the version pin and "Last Updated" marker to v0.24.x.
Correct plugin count from 6 to 9 and interface function count from 11 to 13 throughout the document.

----------------------------------------------------------------------------------------------------

### DOC-004 - Per-script version headers show v0.21.0 while repository is at v0.24.11

**Severity:** High **Files:** `src/bin/oraenv.sh:9` (Revision: 0.21.0),
`src/lib/oradba_registry.sh:9` (Version: 0.21.0), `src/lib/extensions.sh:9` (Revision: 0.21.0)

Both files have `Date.......: 2026.02.11`, indicating they have not been updated since v0.21.0.
`VERSION` file correctly reads `0.24.11`. This affects multiple scripts and library files across
`src/bin/` and `src/lib/`.

**Recommendation (analysis only):** Establish a Makefile target that updates the
`Version`/`Revision` field in OraDBA script headers as part of the release process, or adopt the
`INSTALLER_VERSION="__VERSION__"` placeholder pattern (used in `oradba_install.sh`) consistently
across all script headers so the build injects the correct version.

----------------------------------------------------------------------------------------------------

### DOC-005 - README.md test count ("1086+") is stale; three conflicting counts exist across docs

**Severity:** High **Files:** `README.md:76`, `CONTRIBUTING.md:272`, `doc/README.md:230`

`README.md:76`: "BATS test suite with 1086+ tests". `CONTRIBUTING.md:272`: "All 1516 tests (~10
min)". `doc/README.md:230`: "1086 BATS tests across 65 test files". Actual: 1,557 tests across 48
bats files.

**Recommendation (analysis only):** Run `bats --count tests/*.bats` as part of the release process
and update all four locations. Add a `make validate-docs-counts` target that fails if documented
counts diverge from actual.

----------------------------------------------------------------------------------------------------

### DOC-006 - README.md and doc/README.md claim "6 specialized libraries"; actual library count is 15

**Severity:** High **Files:** `README.md:32`, `doc/README.md:241`, `src/lib/README.md:49`

`README.md:32`: "Modular Library System: Clean separation of concerns with 6 specialized libraries".
`doc/README.md:241`: "Environment Management Libraries (oradba_env\_*): 6 libraries, 47 functions".
`src/lib/README.md:49`: "133 functions across 10 libraries". Actual: 15 library files in `src/lib/`
(the 6 `oradba_env_*` libs plus 9 others). The "6 specialized libraries" conflates the oradba_env\_*
subsystem with the entire library layer. Actual function count: inventory shows 151+ core functions,
not 133.

**Recommendation (analysis only):** Distinguish between the "6 environment management libraries"
(oradba_env\_\*) and the full library layer (15 libraries total). Update `src/lib/README.md` to list
all 15 and correct the total function count.

----------------------------------------------------------------------------------------------------

### DOC-007 - src/bin/README.md documents only 16 of 30 scripts; oraup.sh description is factually wrong

**Severity:** High **Files:** `src/bin/README.md`, `src/bin/oraup.sh:10`

`src/bin/README.md` states "Total Scripts: 16". Actual: 30 scripts. 14 undocumented scripts include
the most user-facing commands: `oradba_env.sh`, `oradba_homes.sh`, `oradba_dsctl.sh`,
`oradba_extension.sh`, `oradba_dbctl.sh`, `oradba_lsnrctl.sh`, `oradba_services.sh`,
`oradba_dbca.sh`, `oradba_logrotate.sh`, `oradba_help.sh`, `oradba_datasafe_debug.sh`,
`oradba_setup.sh`, `oradba_services_root.sh`, `oradba_sqlnet.sh`. Additionally, `oraup.sh` is
described as "Update OraDBA from GitHub" while its actual purpose (`oraup.sh:10`) is "Display
comprehensive Oracle environment status overview".

**Recommendation (analysis only):** Expand `src/bin/README.md` to cover all 30 scripts. Correct the
oraup.sh description. Prioritize documenting the 5 primary entry points.

----------------------------------------------------------------------------------------------------

### DOC-008 - src/lib/README.md omits 5 libraries and understates per-library function counts

**Severity:** High **Files:** `src/lib/README.md`

Five libraries absent from `src/lib/README.md`: `oradba_registry.sh` (8 functions),
`oradba_home_discovery.sh` (15 functions), `oradba_database_discovery.sh` (5 functions),
`oradba_version_metadata.sh` (6 functions), `oradba_env_output.sh` (5 functions). Per-library counts
are wrong for documented libraries: `oradba_env_builder.sh` (README says 9, actual 18),
`oradba_env_parser.sh` (README says 8, actual 10), `oradba_env_validator.sh` (README says 7, actual
9).

**Recommendation (analysis only):** Add the 5 missing libraries to the table with descriptions and
accurate function counts. Recount and correct all per-library function totals. The Registry API
library is especially important to document here since it is the primary public interface.

----------------------------------------------------------------------------------------------------

### DOC-009 - doc/README.md "Last Stable Release: v0.18.5" and "v1.0.0-dev (Phase 6 of 9)" are inaccurate

**Severity:** High **Files:** `doc/README.md:225-226,363`

`doc/README.md:226`: "Last Stable Release: v0.18.5" (actual: v0.24.11). `doc/README.md:225`:
"Version: v1.0.0-dev (Phase 6 of 9 - README & Main Docs in progress)". The "Phase 6 of 9"
development process scaffolding was never removed from the user-visible developer hub.

**Recommendation (analysis only):** Update `doc/README.md` to reflect the actual current version
(v0.24.11). Remove the "Phase X of 9" language. If v1.0.0 is still a target milestone, express it as
a roadmap goal rather than as the current version state.

----------------------------------------------------------------------------------------------------

### DOC-010 - doc/development.md version pin reads "v0.21.0 contributors"; internal plugin count contradiction

**Severity:** High **Files:** `doc/development.md:4,17,28,31`

`doc/development.md:4`: "development information for OraDBA v0.21.0 contributors."
`doc/development.md:28`: "OraDBA v0.21.0 uses a modular, library-based architecture". Additionally:
line 17 says "6 product plugins" but line 31 says "9 product plugins" - an internal contradiction in
the same document.

**Recommendation (analysis only):** Update the version pin from "v0.21.0" to "v0.24.x". Resolve the
6-vs-9 plugin contradiction by settling on the accurate count (9: 6 production + 3 stubs).

----------------------------------------------------------------------------------------------------

### DOC-011 - README.md references `doc/markdown-linting.md` which does not exist

**Severity:** High **File:** `README.md:321`

`README.md:321`: "Markdown Linting (doc/markdown-linting.md) - Documentation standards". The file
`/doc/markdown-linting.md` does not exist. Actual markdownlint config exists as `.markdownlint.json`
in the project root.

**Recommendation (analysis only):** Either create `doc/markdown-linting.md` with content covering
the markdownlint configuration, or update `README.md:321` to point to the correct location.

----------------------------------------------------------------------------------------------------

## Medium Findings

### DOC-012 - CHANGELOG lacks version comparison diff links required by Keep a Changelog format

**Severity:** Medium **File:** `CHANGELOG.md:1-5`

`CHANGELOG.md` claims to follow Keep a Changelog format but has zero comparison diff links at the
bottom (pattern: `[0.24.11]: https://github.com/oehrlis/oradba/compare/v0.24.10...v0.24.11`).
Verified by `grep -c "compare.*github" CHANGELOG.md` returning 0.

**Recommendation (analysis only):** Add the standard comparison link block at the bottom of
`CHANGELOG.md` for all tracked versions, enabling hyperlinks on GitHub.

----------------------------------------------------------------------------------------------------

### DOC-013 - doc/releases/ directory is missing v0.24.5 release notes file

**Severity:** Medium **Files:** `doc/releases/` (missing `v0.24.5.md`), `CHANGELOG.md:113`

`CHANGELOG.md:113` has a substantial `## [0.24.5] - 2026-05-03` entry covering Bash 3.2
compatibility fixes. The corresponding `doc/releases/v0.24.5.md` is absent. The release pipeline
uses this file as the GitHub release body.

**Recommendation (analysis only):** Create `doc/releases/v0.24.5.md` by extracting the existing
CHANGELOG entry for v0.24.5.

----------------------------------------------------------------------------------------------------

### DOC-014 - Orphaned `extension_provides` header comment block in extensions.sh

**Severity:** Medium **File:** `src/lib/extensions.sh:271-274`

A `# Function: extension_provides` header block exists with no following function declaration or
body. CHANGELOG v0.19.0 records the function as intentionally removed ("Superseded by direct
directory checks"). The orphaned header will confuse readers and automated header extractors.

**Recommendation (analysis only):** Remove the orphaned `# Function: extension_provides` comment
block at lines 271-274.

----------------------------------------------------------------------------------------------------

### DOC-015 - CONTRIBUTING.md describes `set -euo pipefail` as optional; project standard mandates it

**Severity:** Medium **Files:** `CONTRIBUTING.md:146-152`, `CLAUDE.md` (shell.md rule)

`CONTRIBUTING.md:146-152`: "Strict mode: Consider enabling for critical scripts" - optional
examples. Project rules (`CLAUDE.md` via `.claude/rules/shell.md`): "`set -euo pipefail` mandatory
(first line after shebang)". 25 of 31 scripts already use it. The CONTRIBUTING guidance will mislead
contributors.

**Recommendation (analysis only):** Update `CONTRIBUTING.md` to state that `set -euo pipefail` is
mandatory for all non-sourced scripts, with a note that sourced scripts (oraenv.sh, oradba_env.sh)
are exempt by design.

----------------------------------------------------------------------------------------------------

### DOC-016 - function-header-guide.md claims "437+ functions"; verifiable count is approximately 327

**Severity:** Medium **File:** `doc/function-header-guide.md:3`

"All 437+ functions in the codebase follow these standards". Inventory count: 151 core library
functions + 18 extensions + 158 plugin functions = ~327 total exported functions. The number 437
appears to conflate all script internal functions (not just public API functions) with the library
function count.

**Recommendation (analysis only):** Replace "437+" with an accurate count or use "all public library
functions" to avoid the unverifiable specific number.

----------------------------------------------------------------------------------------------------

### DOC-017 - CONTRIBUTING.md "Development Setup" uses `./tests/run_tests.sh`; project standard is `make test`

**Severity:** Medium **File:** `CONTRIBUTING.md:129-130`

The "Setting Up Development Environment" code block shows `./tests/run_tests.sh`. Later in the same
file (lines 94, 263-272), the correct commands are `make test` and `make test-full`. This
inconsistency within a single file will confuse new contributors.

**Recommendation (analysis only):** Update the "Setting Up Development Environment" section in
`CONTRIBUTING.md` to use `make test` as the primary example.

----------------------------------------------------------------------------------------------------

### DOC-018 - Docker test infrastructure references pre-rebrand image tag `23.6.0.0` inconsistent with "Oracle AI Database 26ai" product name

**Severity:** Medium **Files:** `tests/run_docker_tests.sh:27`, `doc/README.md:172`,
`doc/automated_testing.md:11,17,57`, `doc/development.md:1071`

Oracle rebranded the product to "Oracle AI Database 26ai" in late 2025. Documentation references to
"Oracle 26ai Free" use the correct current product name. However, `tests/run_docker_tests.sh:27`
hardcodes `container-registry.oracle.com/database/free:23.6.0.0`, a pre-rebrand image version tag.
The `database/free:latest` alias may still resolve correctly, but pinning to `23.6.0.0` creates an
inconsistency and will use an older image when a 26ai-tagged version is available.

**Recommendation (analysis only):** Update `tests/run_docker_tests.sh:27` to reference the Oracle AI
Database 26ai image tag (e.g., `database/free:26ai` or `database/free:latest`) once the 26ai-branded
image is published to the Oracle Container Registry. Update `CONTRIBUTING.md` and all test
documentation to consistently use "Oracle AI Database 26ai" as the product name.

----------------------------------------------------------------------------------------------------

### DOC-019 - src/lib/README.md lists stale builder function names not in actual source

**Severity:** Medium **Files:** `src/lib/README.md:139-152`, `src/lib/oradba_env_builder.sh`

README lists: `oradba_derive_oracle_base`, `oradba_construct_path`,
`oradba_construct_ld_library_path`, `oradba_set_oracle_sid`, `oradba_set_tns_admin`,
`oradba_set_nls_settings`, `oradba_export_environment`, `oradba_clean_environment`. None of these 9
names exist in the actual source file. Actual functions include: `oradba_builder_init`,
`oradba_dedupe_path`, `oradba_clean_path`, `oradba_add_oracle_path`, `oradba_set_lib_path`,
`oradba_detect_rooh`, `oradba_set_oracle_vars`, `oradba_build_environment`, etc.

**Recommendation (analysis only):** Replace the function listings under `oradba_env_builder.sh` in
`src/lib/README.md` with the actual function names extracted from the source file.

----------------------------------------------------------------------------------------------------

### DOC-020 - No public documentation of language conventions, 1Password secrets, or repo topology

**Severity:** Medium **Files:** `CONTRIBUTING.md`

`CONTRIBUTING.md` has no mention of: (1) language policy (code/CLI in English), (2) 1Password
`op read` pattern for secret handling (mandated in `CLAUDE.md` but not surfaced to external
contributors), (3) Forgejo (private) / GitHub (public) repository split. A new contributor reading
only public docs has no guidance on these project-specific conventions.

**Recommendation (analysis only):** Add a "Project Conventions" section to `CONTRIBUTING.md`
covering language policy, secret handling (use `op read "op://vault/item/field"`, never hardcode),
and repository topology.

----------------------------------------------------------------------------------------------------

## Low Findings

### DOC-021 - README.md presents shell library functions as if they are executable CLI commands

**Severity:** Low **File:** `README.md:179-183`

The "Query installations via Registry API" code block presents `oradba_registry_get_all`,
`oradba_registry_get_by_name "ORCLCDB"` etc. as commands without noting they are shell functions
available only after sourcing the environment. There is no `oradba_registry` CLI wrapper script in
`src/bin/`.

**Recommendation (analysis only):** Add a comment to the README code block explaining these are
shell functions available after `source oraenv.sh FREE`, not standalone CLI commands.

----------------------------------------------------------------------------------------------------

### DOC-022 - doc/README.md Quick Reference lists Makefile targets not confirmed to exist

**Severity:** Low **File:** `doc/README.md:258-283`

Quick Reference lists `make test-fast`, `make test-unit`, `make test-integration`, `make dist`,
`make version-bump-patch`, `make version-bump-minor`, `make version-bump-major`, `make tag`,
`make release`. These were not verified against the actual Makefile.

**Recommendation (analysis only):** Verify all Makefile target names in `doc/README.md:258-283`
against the actual Makefile. Remove or annotate any targets that do not exist.

----------------------------------------------------------------------------------------------------

## Summary Table

| ID      | Severity | Type       | Title (short)                                                                                 |
|---------|----------|------------|-----------------------------------------------------------------------------------------------|
| DOC-001 | Critical | Inaccurate | Registry output format wrong in api.md and architecture.md                                    |
| DOC-002 | Critical | Inaccurate | Three phantom registry functions documented; four real ones absent                            |
| DOC-003 | High     | Inaccurate | api.md "Last Updated" and version pin 5+ months stale                                         |
| DOC-004 | High     | Inaccurate | Per-script version headers show v0.21.0 vs actual v0.24.11                                    |
| DOC-005 | High     | Inaccurate | README test count "1086+" vs actual 1557; four conflicting numbers                            |
| DOC-006 | High     | Inaccurate | "6 specialized libraries" vs actual 15 libraries                                              |
| DOC-007 | High     | Inaccurate | src/bin/README.md covers 16 of 30 scripts; oraup.sh description wrong                         |
| DOC-008 | High     | Absent     | src/lib/README.md omits 5 libraries; per-library function counts wrong                        |
| DOC-009 | High     | Inaccurate | doc/README.md "Last Stable Release: v0.18.5" and "v1.0.0-dev" are wrong                       |
| DOC-010 | High     | Inaccurate | doc/development.md version pin "v0.21.0"; internal 6-vs-9 plugin contradiction                |
| DOC-011 | High     | Inaccurate | README.md links to doc/markdown-linting.md which does not exist                               |
| DOC-012 | Medium   | Absent     | CHANGELOG missing Keep-a-Changelog comparison diff links                                      |
| DOC-013 | Medium   | Absent     | doc/releases/v0.24.5.md absent despite CHANGELOG entry existing                               |
| DOC-014 | Medium   | Inaccurate | Orphaned extension_provides header comment block in extensions.sh                             |
| DOC-015 | Medium   | Inaccurate | CONTRIBUTING.md says set -euo pipefail is optional; project mandates it                       |
| DOC-016 | Medium   | Inaccurate | function-header-guide.md claims "437+ functions"; verifiable count is ~327                    |
| DOC-017 | Medium   | Inaccurate | CONTRIBUTING.md setup example uses ./tests/run_tests.sh, not make test                        |
| DOC-018 | Medium   | Inaccurate | Test infra pins pre-rebrand `23.6.0.0` image; correct product name is Oracle AI Database 26ai |
| DOC-019 | Medium   | Inaccurate | src/lib/README.md lists stale builder function names not in actual source                     |
| DOC-020 | Medium   | Absent     | No public docs for language split, 1Password secrets, or repo topology                        |
| DOC-021 | Low      | Misleading | README presents shell library functions as if they are CLI commands                           |
| DOC-022 | Low      | Unverified | doc/README.md Quick Reference lists Makefile targets not confirmed to exist                   |
