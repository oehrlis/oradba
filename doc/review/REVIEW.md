# OraDBA Framework Review - v0.24.11 toward v1.0.0

**Review date:** 2026-06-26 **Reviewed version:** 0.24.11 (commit b76fe9c) **Target version:**
v1.0.0 **Review scope:** Full architecture, security, robustness, performance, testing,
documentation, dependencies, and release engineering **Status:** Complete - all decisions and
clarifications resolved; roadmap approved

----------------------------------------------------------------------------------------------------

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Repository Architecture Review](#2-repository-architecture-review)
3. [Framework Health](#3-framework-health)
4. [Security Review](#4-security-review)
5. [Robustness Review](#5-robustness-review)
6. [Performance Review](#6-performance-review)
7. [Test Coverage](#7-test-coverage)
8. [Documentation Review](#8-documentation-review)
9. [Maintainability Review](#9-maintainability-review)
10. [Dependency Review](#10-dependency-review)
11. [Technical Debt Register](#11-technical-debt-register)
12. [Risk Register](#12-risk-register)
13. [Consolidated Findings](#13-consolidated-findings)
14. [Prioritized Recommendations](#14-prioritized-recommendations)
15. [Open Questions](#15-open-questions)
16. [Required Design Decisions](#16-required-design-decisions)
17. [Blockers](#17-blockers)
18. [Revised Review Plan](#18-revised-review-plan)
19. [Roadmap Summary](#19-roadmap-summary)

----------------------------------------------------------------------------------------------------

## 1. Executive Summary

OraDBA is a mature, production-deployed Oracle DBA toolset. The framework is feature-complete and
operationally stable, but the path to v1.0.0 requires resolving a concentrated set of structural
issues before the version carries the stability guarantee the number implies.

**Repository at a glance:** 30 bin scripts, 15 core libraries (9,471 LOC), 9 product plugins + 1
interface template (4,005 LOC), 155 SQL scripts, 48 Bats test files (1,557 tests). The framework is
in active development (10 releases in the last 12 months).

**Review outcome - 34 consolidated findings** across 8 domains:

- **4 Critical:** zero-start `(( counter++ ))` aborts under `set -e` (9 scripts), DBCA SYS/SYSTEM
  password written to predictable world-readable `/tmp` file, two competing plugin loaders with 9
  direct-source sites bypassing isolation, path-critical functions (validator, env-builder,
  home-discovery) largely untested. Two additional Critical items span testing and release
  engineering.
- **15 High:** incomplete strict mode, missing version-tag assertion in release pipeline, GNU-only
  tools without BSD fallback, eager sourcing of ~6,500 LOC per env switch, duplicate parallel
  environment-build paths, Registry API docs documenting wrong delimiter and phantom functions, and
  others.
- **11 Medium / 4 Low:** mostly maintainability, namespace hygiene, documentation staleness, and
  process items.

**All decisions and clarifications resolved** - the review produced a complete, approved 9-milestone
implementation roadmap.

**Verdict:** v1.0.0 is achievable in 9 milestones. The roadmap is ordered blocker-first: safety net
(M1) -\> security hardening (M2) -\> test coverage (M3) -\> architecture consolidation (M4-M6) -\>
performance (M7) -\> release engineering (M8) -\> stabilisation and RC window (M9). Estimated effort
is dominated by M3 (L), M4 (L), and M6 (L). Non-blocker performance debt is mostly deferrable to
v1.1.0.

Full detail in [Consolidated Findings](consolidated-findings.md) and [Roadmap](roadmap.md).

----------------------------------------------------------------------------------------------------

## 2. Repository Architecture Review

**Source:** [findings/architecture.md](findings/architecture.md)

### Module boundaries and layering

The framework has a clear three-tier structure: bin scripts (user-facing CLI), lib libraries (shared
logic), plugins (product-specific adapters). However, the lines between tiers are blurred by two
structural issues.

**Plugin system:** `execute_plugin_function_v2()` in `oradba_common.sh:1541` provides isolation-safe
plugin dispatch (subshell, unset state, interface-version check). Nine direct-source sites bypass it
entirely (`oraenv.sh:754,920,1028`, `oradba_homes.sh:838`, `oradba_dsctl.sh:41`,
`oradba_env.sh:138`, `oradba_datasafe_debug.sh:328`, `oraup.sh:399`). **Decision resolved:** tiered
isolation is adopted - `execute_plugin_function_v2` mandatory for state-changing calls
(`plugin_detect_installation`, `plugin_check_status`, `plugin_check_listener_status`); direct
in-parent calls permitted only for the audited, side-effect-free path-builders (`build_bin_path`,
`build_lib_path`). See CF-004 / [findings/architecture.md](findings/architecture.md).

**Environment build:** Two parallel paths exist. `oraenv.sh:719` builds the environment inline.
`oradba_build_environment` in `oradba_env_builder.sh:889` is the structured replacement - but no
`src/bin` script calls it; it is referenced only from `oradba_env_changes.sh` and the README. The
migration stalled; the alternate path has 0 test references. **Decision resolved:** complete the
migration so `oraenv.sh` delegates to `oradba_build_environment` and retire the inline logic
(DECISION 1, M6). See CF-017.

**Install-root variable inconsistency:** `ORADBA_BASE` and `ORADBA_PREFIX` refer to the same thing
but are used interchangeably across 27 scripts, causing plugin discovery, oratab resolution, and
config loading to look in different trees. This is the root cause class for the Data Safe installer
path defects. Canonicalize on `ORADBA_BASE`, deprecate `ORADBA_PREFIX` as a one-release alias. See
CF-007.

**Other architectural findings:** duplicate `plugin_check_listener_status` in `plugin_interface.sh`
(CF-003), duplicate oratab parsers across three files (CF-029), DB-status querying duplicated three
times with divergent SQL and status vocabulary (CF-018), unprefixed public functions polluting the
user shell and `oradba_log` redefined in 6 files including a shadowing stub that drops sanitisation
(CF-030), bootstrap boilerplate duplicated across 27 bin scripts (CF-032).

----------------------------------------------------------------------------------------------------

## 3. Framework Health

**Sources:** [\_scans/inventory.md](_scans/inventory.md),
[\_scans/static-findings.md](_scans/static-findings.md)

### Compliance

| Check                       | Status                                                                          |
|-----------------------------|---------------------------------------------------------------------------------|
| `set -euo pipefail` present | 28/30 bin scripts (`oradba_homes.sh`, `oradba_extension.sh` missing/incomplete) |
| Standardized script header  | Present on all scripts reviewed                                                 |
| ShellCheck SC2016           | 2 instances (false-positive risk)                                               |
| ShellCheck SC2181           | 8 instances (checking `$?` after commands)                                      |
| shfmt conformance           | 7 files diverge (4-space indent vs tab norm)                                    |
| `eval` usage                | 7 sites (5 benign parameter-expansion idioms; 2 in `oraenv.sh` injection-risky) |
| `/tmp` literals             | 9 sites (several without exclusive create)                                      |
| `rm -rf` with variables     | 9 sites (all in cleanup traps or well-guarded)                                  |
| `sudo`/`su` usage           | 10 sites (expected for Oracle installer privilege escalation)                   |

### Version markers

`VERSION` file: `0.24.11`. Script/library headers frozen at `0.21.0`. Per-script headers are not
build-injected. The `__VERSION__` placeholder pattern used in installer is not applied to script
headers.

### Git activity

10 patch-level releases in the review cycle; five on a single day (2026-06-25). Same-day patch
cadence indicates insufficient preventive controls - addressed by the M1 lint guard and the M8/M9
release process improvements.

----------------------------------------------------------------------------------------------------

## 4. Security Review

**Source:** [findings/security.md](findings/security.md)

### Critical and High findings

**CF-002 (Critical) - DBCA passwords in predictable world-readable `/tmp`:** `oradba_dbca.sh:584`
creates `response_file="/tmp/dbca_${DB_SID}_$$.rsp"` with default umask; SYS/SYSTEM passwords
written verbatim (`:182-183`), no `chmod 600`, no `mktemp`. On DBCA failure the file is deliberately
preserved (`:613`). Full DBA compromise on shared hosts. Fix: `mktemp -d` in a mode-700 directory,
`chmod 600` before writing, `trap EXIT` shred. Prefer stdin to DBCA so passwords never hit disk.

**CF-006 (High) - No installer integrity verification:** `oradba_install.sh:2065-2085` fetches the
GitHub release tarball with no verification against the shipped `.sha256`. The only `--verify-core`
check (`:2328-2338`) is self-referential (compares files against a checksum inside the same
tarball - useless against a tampered download). README install one-liners pipe remote scripts
straight into `bash`. Fix: download companion `.sha256`, verify with `shasum -a 256 -c`, fail closed
if no verify tool.

**CF-020 (High) - SEPS wallet password reversible and logged:** `get_seps_pwd.sh:84,185-188`
documents/reads a `.wallet_pwd` base64 file without permission check; `:243` logs the recovered DB
password in cleartext in non-quiet mode. Fix: refuse to read unless `600` and owner-owned; never log
the recovered password.

**Medium findings:** `eval` on oratab fields without sanitisation (CF-022), predictable PID-based
temp paths without exclusive create (CF-023), RMAN catalog credential on process args and in DEBUG
logs (CF-021 - flags retained per DR-3).

----------------------------------------------------------------------------------------------------

## 5. Robustness Review

**Sources:** [findings/bash.md](findings/bash.md), [findings/testing.md](findings/testing.md)

### Zero-start arithmetic - CF-001 (Critical)

Under `set -e`, `(( var++ ))` returns exit code 1 when `var=0`. Identical root cause to shipped fix
`4db7ccf`. Remains unfixed in 9 scripts:

- `oradba_dsctl.sh:148,672-708`
- `oradba_dbctl.sh:556-588`
- `oradba_lsnrctl.sh:460-492`
- `oradba_dbca.sh:455-482`
- `oradba_version.sh:334,402`
- `oradba_logrotate.sh:184-210`
- `oradba_sqlnet.sh:655,668`
- `oradba_env_changes.sh:200,203` (library; inherits caller's `set -e`)

Every first start/stop/restart of a connector, database, or listener silently aborts. Fix:
`var=$(( var + 1 ))` or `(( var++ )) || true` at every from-zero increment. Add CI lint rule (see
CF-009).

### Missing strict mode - CF-005 (High)

`oradba_homes.sh`: no `set` statement; carries 13 from-zero increments (currently harmless only
because `set -e` is absent). `oradba_extension.sh:17`: only `set -o pipefail` (missing `-e -u`).
Both have active increment sites. Adding strict mode without simultaneously guarding the increments
would convert latent bugs to live aborts - tasks 1 and 2 of M1 must land in the same commit.

### Other robustness findings

Error messages written to stdout instead of stderr (CF-031, 6 sites), fragile `grep`/`find` boolean
idioms, missing `LC_ALL=C` on sort/comm, GNU `date -d` parse failure returns 0 producing ~55-year
uptimes (CF-033).

----------------------------------------------------------------------------------------------------

## 6. Performance Review

**Source:** [findings/performance.md](findings/performance.md)

### Env-switch hot path

**CF-015 (Critical) - sqlplus spawns on every env switch:** `generate_pdb_aliases`
(`oradba_database_discovery.sh:164-228`) runs on every `source oraenv.sh` via
`oradba_standard.conf:172`; spawns `check_database_connection` then 1-2 sqlplus calls per CDB check.
Even `--silent` does not suppress it (`--fast-silent` skips `generate_sid_aliases` but not
`generate_pdb_aliases`). Each sqlplus spawn adds 50-500ms per switch. Fix: gate on
`ORADBA_LOAD_PDB_ALIASES` defaulting false, add per-SID session guard, extend `--fast-silent`.

**CF-014 (High) - Eager sourcing and double config load:** `oraenv.sh:36-93` unconditionally sources
11-12 library files (~6,500 LOC) before any argument is parsed, on every invocation including
repeated profile-sourcing. `oradba_core.conf` loaded twice (`:51` and inside `load_config()`);
`oradba_local.conf` same (`:56`). Fix: source path-specific libraries inside the functions that need
them; remove the direct `load_config_file` calls.

**CF-016 (High) - Hot-path subshell/fork anti-patterns:** `oradba_dedupe_path` called 5+ times via
subshell with O(N^2) inner loop; `date` fork on every `oradba_log` call at debug (~215 calls per
switch); `execute_plugin_function_v2` re-sources the plugin file in a subshell per call with
`mktemp`; `get_oracle_home_type` re-parses `oradba_homes.conf` and spawns `echo|awk` 4+ times per
call. Cumulative tens-to-hundreds of process forks per env switch. Fix: move timestamp computation
behind the log level filter; dedupe PATH once with `awk '!seen[$0]++'`; cache product-type lookups
in an associative array. Most of CF-016 is deferrable to M7; CF-015 is a v1.0.0 blocker.

----------------------------------------------------------------------------------------------------

## 7. Test Coverage

**Sources:** [\_scans/test-coverage.md](_scans/test-coverage.md),
[findings/testing.md](findings/testing.md)

### Coverage summary

48 Bats test files, 1,557 tests across 30+ scripts and 15 libraries. Smart test selection via
`.testmap.yml` (actual: 48 files / 1,557 tests; annotation claims 65 files / 1,516 - stale).

| Area             | Functions | Covered | Partial | Uncovered |
|------------------|-----------|---------|---------|-----------|
| env-validator    | 9         | 2       | 1       | 6         |
| env-builder      | 20        | 9       | 2       | 9         |
| home-discovery   | 16        | 2       | 3       | 11        |
| version-metadata | 6         | 1       | 0       | 5         |
| env-output       | 5         | 1       | 0       | 4         |

### Key gaps - CF-008 (Critical)

Functions on every `oraenv.sh` code path - `oradba_validate_environment`,
`oradba_build_environment`, `oradba_parse_oracle_home` - have no behavioral test coverage. The
`cbcb942` defect (description clobber) lived in `parse_oracle_home` / `list_oracle_homes`, exactly
this gap.

Five bin scripts have no test file and no `.testmap.yml` entry: `oradba_logrotate.sh`,
`sessionsql.sh`, `oradba_validate.sh`, `oradba_datasafe_debug.sh`, `oradba_setup.sh`. Files absent
from `.testmap.yml` do not trigger CI smart-selection on change.

### Regression gap - CF-009 (Critical)

None of the six recent shipped defects (b76fe9c, 5e89542, 4db7ccf, cbcb942, bbf2540, fa36489) has a
named regression test. Happy-to-error ratio: 13:1 (934 vs 72 assertions). The suite structurally
misses failure-mode and edge-case bugs - the exact class that shipped this cycle.

### `make test-full` masks failures - CF-027

`Makefile:138-151` treats bats exit code 1 as success ("conditional skips"), but bats uses exit 1
for both skipped tests and actual failures. Real test failures are silently swallowed by the primary
release-gate target. Fix: run `bats --report-formatter tap` and parse TAP to distinguish failed from
skipped.

----------------------------------------------------------------------------------------------------

## 8. Documentation Review

**Source:** [findings/documentation.md](findings/documentation.md)

### Registry API docs wrong - CF-024 (High)

`doc/api.md:82` and `doc/architecture.md:154` state the Registry API returns colon-delimited 6-field
entries. Actual code (`oradba_registry.sh:31-32`): `readonly REGISTRY_FIELD_SEP="|"`, 8-field schema
`type|name|home|version|flags|order|alias|desc`. The same docs describe three phantom functions
(`_get_by_home`, `_get_status`, `_validate_entry`) that do not exist and omit four real ones
(`_get_databases`, `_get_field`, `_sync_oratab`, `_discover_all`). Consumers integrating against the
Registry API will fail.

### Pervasive staleness - CF-025 (High)

A representative set of documentation accuracy issues:

- Script/library headers show v0.21.0; `VERSION` is 0.24.11
- `api.md:5` "Last Updated: 2026-01-20" pinned at v0.19.0
- Test counts: README claims "1086+", CONTRIBUTING "1516", actual 1,557
- Library count: stated as 6, actual 15
- Plugin count: 6 vs 9 contradiction inside `development.md`
- `src/bin/README.md` covers 16 of 30 scripts
- `doc/README.md:` "Last Stable Release: v0.18.5"
- Test infrastructure pins pre-rebrand `free:23.6.0.0` image; correct product name is Oracle AI
  Database 26ai (`container-registry.oracle.com/database/free:latest`)
- `README.md:321` links to non-existent `doc/markdown-linting.md`

Documentation is broadly untrustworthy for a v1.0.0 release.

----------------------------------------------------------------------------------------------------

## 9. Maintainability Review

**Source:** [findings/architecture.md](findings/architecture.md),
[\_scans/static-findings.md](_scans/static-findings.md)

### Function naming and namespace

~15 legacy public functions exported without the `oradba_` prefix (`parse_oratab`,
`get_oracle_homes_path`, `detect_product_type`, `set_oracle_home_environment`, `generate_sid_lists`,
`check_database_connection` and others). In a sourced framework, every unprefixed function is a
collision hazard in the user's interactive shell.

`oradba_log()` is defined in 6 files. `oradba_datasafe_debug.sh:320` defines a stub `oradba_log()`
inside `main` even after sourcing the real logger at `:378`, permanently overriding file logging,
log levels, and `sanitize_sensitive_data` for the entire process lifetime. See CF-030.

### Bootstrap boilerplate

27 of 30 bin scripts independently compute `SCRIPT_DIR` and re-derive `ORADBA_BASE`/`ORADBA_PREFIX`
with slightly different shell expressions. No shared `bootstrap.sh` exists. Each variant is an
opportunity for the CF-007 root-variable divergence to manifest. See CF-032.

### ShellCheck and formatting

8 SC2181 instances (`if [ $? -eq ... ]`); 7 files diverge from tab indentation. These are mechanical
issues with a clear S/M fix path.

----------------------------------------------------------------------------------------------------

## 10. Dependency Review

**Source:** [findings/dependencies.md](findings/dependencies.md)

### No bash version guard - CF-011 (High)

Bash 4+ features (`declare -A`, `mapfile`, `${var,,}`/`${var^^}`) used without a runtime version
check. macOS ships `/bin/bash` at 3.2.57. `oraup.sh:176,189` shows the correct fallback pattern but
it is not applied globally. Fix: add
`(( BASH_VERSINFO[0] < 4 )) && { echo "ERROR: bash 4.0+ required" >&2; exit 1; }` and document
Homebrew bash requirement in CONTRIBUTING.md.

### GNU-only tools without BSD fallback - CF-012 (High)

macOS is the declared default target (`.claude/rules/shell.md`). Several GNU-specific tool flags are
used without fallback:

- `df -BG` (`oradba_dbca.sh:245`) - leaves `avail_gb` empty on BSD; spurious low-disk warning
- `sha256sum` (`oradba_version.sh:164,414,535`, `oradba_extension.sh:619`) without `shasum` fallback
  (correct pattern exists in `oradba_install.sh:280-282`)
- `realpath` (`sync_to_peers.sh:239`) without fallback (exists in `sync_from_peers.sh:244`)
- `timeout` (`oradba_check.sh:704`, `oradba_dbctl.sh:345`) - GNU coreutils only

### Oracle CLI existence checks missing - CF-013 (High)

`sqlplus`, `rman`, `lsnrctl` invoked without `command -v` / `-x` pre-flight checks in their
respective control scripts. Under `set -euo pipefail`, a missing binary gives an unhelpful "command
not found" abort. Pattern exists at `oradba_dbca.sh:223`.

### Supply-chain - CF-028 (Medium)

Mutable Docker image tags (`oehrlis/pandoc:latest-full`, `database/free:latest`), unpinned GitHub
Actions (`softprops/action-gh-release@v1`, `dorny/paths-filter@v3`), unpinned pip/npm packages,
build-time download of extension template without checksum verification. Pipeline holds
`contents: write`. Mostly deferrable to v1.1.0 except the Oracle AI Database 26ai image pin (M8).

----------------------------------------------------------------------------------------------------

## 11. Technical Debt Register

Full register: [technical-debt-register.md](technical-debt-register.md)

22 technical debt items (TD-01 to TD-22). Effort summary:

| Tier          | Count | Key items                                                                   |
|---------------|-------|-----------------------------------------------------------------------------|
| S (\< 1 day)  | 5     | TD-04, TD-06, TD-13, TD-16, TD-19                                           |
| M (1-3 days)  | 11    | TD-01, TD-05, TD-07, TD-08, TD-09, TD-11, TD-12, TD-15, TD-17, TD-18, TD-21 |
| L (3-10 days) | 5     | TD-02, TD-03, TD-10, TD-14, TD-20                                           |
| XL            | 1     | TD-22 (readiness gate - depends on most others being closed)                |

Recommended sequencing (from technical-debt-register.md):

1. **Foundational enablers (S-effort):** TD-13 lint guard, TD-16 test gate, TD-04 single interface
    definition, TD-19 build-injected versions
2. **Blocker defect classes:** TD-05 + TD-06 together, TD-21 credential/temp-file, TD-11
    portability, TD-12 runtime validation
3. **Architecture decisions:** TD-01 shared bootstrap -\> TD-02 env-build direction -\> TD-03
    plugin loader -\> TD-09 namespace prefixing
4. **Coverage and release:** TD-14 + TD-15 tests, TD-17 integrity gates, TD-18 docs, TD-22
    readiness definition
5. **Deferrable to v1.1.0:** TD-10 hot-path performance (except CF-015 sqlplus gating), TD-20
    supply-chain reproducibility

----------------------------------------------------------------------------------------------------

## 12. Risk Register

Full register: [risk-register.md](risk-register.md)

19 risks. Summary:

| Level    | Count | Most critical                                                                                                                                                                                                                                                                                                                                                                  |
|----------|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Critical | 1     | RISK-01: scripts abort silently on first normal use (zero-start arithmetic)                                                                                                                                                                                                                                                                                                    |
| High     | 11    | RISK-02 (DBCA passwords), RISK-04 (plugin contamination), RISK-05 (install-root divergence), RISK-06 (untested path-critical functions), RISK-07 (regression recurrence), RISK-08 (env-build ambiguity), RISK-09 (version mismatch in release), RISK-10 (defective build reaches users), RISK-11 (BSD portability), RISK-13 (CI lint gap), RISK-17 (inaccurate docs at v1.0.0) |
| Medium   | 6     | RISK-03, RISK-12, RISK-14, RISK-15, RISK-16, RISK-19                                                                                                                                                                                                                                                                                                                           |
| Low      | 1     | RISK-18                                                                                                                                                                                                                                                                                                                                                                        |

**Most leveraged single mitigation:** RISK-13 (CI lint/format/pin/hook guards) - the systemic
preventive control that stops RISK-01 and RISK-07 defect classes from recurring after they are
fixed.

**Highest acute exposure:** RISK-01 (Critical, fires on first normal operation) and RISK-02
(credential exposure on shared hosts, High).

----------------------------------------------------------------------------------------------------

## 13. Consolidated Findings

Full register: [consolidated-findings.md](consolidated-findings.md)

34 findings (CF-001 to CF-034) deduplicated from 8 domain reviews and 3 mechanical scans. Coverage
map: every upstream finding ID (ARCH-001 to ARCH-013, BASH-001 to BASH-021, DEP-001 to DEP-015,
DOC-001 to DOC-022, P-01 to P-13, RF-01 to RF-14, SEC-01 to SEC-10, F-001 to F-018) is accounted for
in exactly one consolidated finding. No findings were fabricated.

Findings by severity:

| Severity | Count | IDs                                                                  |
|----------|-------|----------------------------------------------------------------------|
| Critical | 8     | CF-001, CF-002, CF-003, CF-004, CF-008, CF-009, CF-010, CF-015       |
| High     | 14    | CF-005 to CF-007, CF-011 to CF-014, CF-016 to CF-020, CF-024, CF-025 |
| Medium   | 11    | CF-021 to CF-023, CF-026 to CF-032, CF-034                           |
| Low      | 1     | CF-033                                                               |

----------------------------------------------------------------------------------------------------

## 14. Prioritized Recommendations

See [consolidated-findings.md - Prioritized recommendations](consolidated-findings.md) for the full
ranked table (CF-001 to CF-034 with severity, blocker status, and effort).

Top 10 by impact x urgency:

<!-- markdownlint-disable MD013 MD060 -->

| Rank | ID     | Area         | One-line                                                                    | Milestone |
|------|--------|--------------|-----------------------------------------------------------------------------|-----------|
| 1    | CF-001 | Bash         | Fix zero-start `(( counter++ ))` in 9 scripts before first iteration aborts | M1        |
| 2    | CF-002 | Security     | Secure DBCA password handling - no plaintext in predictable /tmp            | M2        |
| 3    | CF-003 | Architecture | Remove duplicate `plugin_check_listener_status` - one canonical definition  | M1        |
| 4    | CF-009 | Testing      | Add named regression tests for the 6 recent shipped defects                 | M1        |
| 5    | CF-010 | Release      | Assert VERSION == git tag in release pipeline before build                  | M1        |
| 6    | CF-027 | Release      | Fix `make test-full` exit-code handling - no longer mask failures           | M1        |
| 7    | CF-005 | Bash         | Add full `set -euo pipefail` to oradba_homes.sh and oradba_extension.sh     | M1        |
| 8    | CF-006 | Security     | Verify installer tarball against .sha256 before extraction                  | M2        |
| 9    | CF-008 | Testing      | Add behavioral tests for validator/env-builder/home-discovery functions     | M3        |
| 10   | CF-004 | Architecture | Enforce tiered plugin isolation per DECISION 2                              | M4        |

<!-- markdownlint-enable MD013 MD060 -->

----------------------------------------------------------------------------------------------------

## 15. Open Questions

All questions have been resolved. Full record: [clarifications.md](clarifications.md).

The following questions were raised during the review and are now closed:

- **A-1** (installer prepare/install contract): oradba does NOT provide a generic two-phase
  prepare/install contract; the F-010 cross-validation test target does not exist and is dropped
  from M3.
- **A-2** (security severity assumptions): CF-006, CF-022, and CF-002 severity assumptions are
  confirmed as stated.
- **A-3** (coverage target percentages): M3 targets (validator \>= 80%, env-builder \>= 80%,
  home-discovery \>= 70%, version-metadata \>= 80%, error-path ratio \>= 15%) approved as v1.0.0
  gates.
- **A-4** (release numbering): one minor version per milestone (v0.25.0 to v0.32.0, then v1.0.0-rc.1
  and v1.0.0) confirmed.
- **Q-4** (DB open-mode canonical vocabulary): confirmed as {OPEN, MOUNTED, NOMOUNT, STARTED,
  SHUTDOWN} for all implementations converging in M6.

----------------------------------------------------------------------------------------------------

## 16. Required Design Decisions

Both architecture decisions are resolved. Full record: [clarifications.md](clarifications.md).

### DECISION 1 - Environment-build path (CF-017) - RESOLVED

**Decision:** Option A - complete the migration. `oraenv.sh` will delegate environment-building to
`oradba_build_environment` and the inline logic in `oradba_common.sh` will be retired.

**Rationale:** One tested, documented code path for a v1.0.0 release. Unblocks landing test
investment (M3) on the path that actually ships. M6; L-effort. Comprehensive test coverage (M3) is a
hard prerequisite.

### DECISION 2 - Plugin isolation vs fork cost (CF-004 / CF-016) - RESOLVED

**Decision:** Option B - tiered plugin isolation.

- `execute_plugin_function_v2` (or equivalent wrapper) is mandatory for all state-changing/risky
  plugin calls: `plugin_detect_installation`, `plugin_check_status`, `plugin_check_listener_status`.
- Direct in-parent calls are allowed only for the audited, side-effect-free path-builders:
  `build_bin_path`, `build_lib_path`. Exception list must be documented in M4. No extension of this
  list without a new human decision.
- `odb_datasafe` does not call oradba plugin libs directly; no downstream consumer functions require
  classification.

**Rationale:** Resolves the correctness/security concern without paying the full per-env-switch fork
cost for pure path-computation functions.

----------------------------------------------------------------------------------------------------

## 17. Blockers

Findings that must be resolved before v1.0.0 can be tagged. Sourced from
[consolidated-findings.md](consolidated-findings.md) blocker column.

<!-- markdownlint-disable MD013 MD060 -->

| ID     | Severity | Blocker issue                                                                     | Target milestone |
|--------|----------|-----------------------------------------------------------------------------------|------------------|
| CF-001 | Critical | Zero-start `(( counter++ ))` aborts normal operations                             | M1               |
| CF-002 | Critical | DBCA SYS/SYSTEM passwords in world-readable /tmp                                  | M2               |
| CF-003 | Critical | Duplicate `plugin_check_listener_status` - self-contradictory interface           | M1               |
| CF-004 | Critical | 9 direct-source sites bypassing plugin isolation wrapper                          | M4               |
| CF-005 | High     | Missing strict mode on 2 scripts (must land with CF-001 guards)                   | M1               |
| CF-006 | High     | Installer runs without checksum/signature verification                            | M2               |
| CF-007 | High     | `ORADBA_BASE` vs `ORADBA_PREFIX` root-cause class for path defects                | M5               |
| CF-008 | Critical | Path-critical functions (validator, env-builder, home-discovery) largely untested | M3               |
| CF-009 | Critical | No regression test for any of the 6 recent shipped defects                        | M1/M3            |
| CF-010 | Critical | Release pipeline does not assert VERSION == git tag                               | M1               |
| CF-011 | High     | No runtime bash 4+ version guard; macOS ships bash 3.2                            | M2/M5            |
| CF-015 | Critical | `generate_pdb_aliases` spawns sqlplus on every env switch even in silent mode     | M7               |
| CF-017 | High     | Parallel env-build paths present ambiguous public API at v1.0.0                   | M6               |
| CF-019 | High     | Docker integration tests manual-only and excluded from release gate               | M8               |
| CF-024 | High     | Registry API docs wrong (delimiter, schema, phantom/missing functions)            | M8               |
| CF-027 | Medium   | `make test-full` treats bats exit 1 as success, masking real failures             | M1               |
| CF-034 | Medium   | No v1.0.0 readiness definition, stabilisation gate, or deprecation policy         | M8/M9            |

<!-- markdownlint-enable MD013 MD060 -->

----------------------------------------------------------------------------------------------------

## 18. Revised Review Plan

The previous review plan (`.claude/review-plan.md`, dated 2026-03-10, status "Complete 2026-03-25")
was a topic-by-topic exploratory review. Its deferred items are now folded into the milestone
roadmap.

**`.claude/review-plan.md` is superseded. It is historical context only.**

The single source of truth for the path from v0.24.11 to v1.0.0 is:

**[doc/review/roadmap.md](roadmap.md)**

The roadmap document contains:

- 9 sequenced milestones (M1 to M9) with full task lists
- Standardized quality gate per milestone (build, ShellCheck, shfmt, unit + integration + regression
  tests, docs, CHANGELOG, release notes, version bump, one atomic commit)
- Release strategy (v0.25.0 to v0.32.0, v1.0.0-rc.1, v1.0.0)
- v1.0.0 readiness checklist
- Mapping of all 34 CFs and 22 TD items to milestones

----------------------------------------------------------------------------------------------------

## 19. Roadmap Summary

Full roadmap: [roadmap.md](roadmap.md) - 9 milestones, all decisions resolved.

### Milestone plan

<!-- markdownlint-disable MD013 MD060 -->

| Milestone | Version                 | Focus                                                                                   | Blockers closed                                          | Effort   |
|-----------|-------------------------|-----------------------------------------------------------------------------------------|----------------------------------------------------------|----------|
| M1        | v0.25.0                 | Immediate safety net - arithmetic, strict mode, regression tests, release gate          | CF-001, CF-003, CF-005, CF-009 (partial), CF-010, CF-027 | M        |
| M2        | v0.26.0                 | Security hardening - credentials, temp files, eval, checksums                           | CF-002, CF-006                                           | M        |
| M3        | v0.27.0                 | Test coverage - path-critical functions, remaining regressions                          | CF-008, CF-009 (complete)                                | L        |
| M4        | v0.28.0                 | Plugin system consolidation - tiered isolation (DECISION 2)                             | CF-004                                                   | L        |
| M5        | v0.29.0                 | Architecture consolidation - canonical root, single oratab parser, prefixing, bootstrap | enabling                                                 | M-L      |
| M6        | v0.30.0                 | Environment-build migration (DECISION 1) + single DB-status function                    | CF-017                                                   | L        |
| M7        | v0.31.0                 | Performance - lazy load, PDB alias gate, fork reduction                                 | CF-015                                                   | M-L      |
| M8        | v0.32.0                 | Release engineering and documentation                                                   | CF-019, CF-024                                           | M        |
| M9        | v1.0.0-rc.1 then v1.0.0 | Stabilisation, 30-day RC soak, readiness checklist, API freeze                          | all remaining blockers verified                          | M + soak |

<!-- markdownlint-enable MD013 MD060 -->

### Release strategy

Each milestone produces one tagged minor release (v0.25.0 through v0.32.0). After M8 passes the
quality gate, `v1.0.0-rc.1` is tagged. A minimum 30-day soak with no critical issues is required
before the final `v1.0.0` tag.

The v1.0.0 readiness checklist (to be authored in M8 as `doc/v1.0.0-readiness.md`):

- All 17 blocker findings resolved and verified
- Docker integration tests pass on `container-registry.oracle.com/database/free:latest`
- ShellCheck clean, shfmt conformant
- API frozen (public function set, Registry API schema, flag vocabulary)
- No breaking changes from v0.24.x without runtime deprecation warnings
- One-release deprecation aliases in place for renamed functions/variables
- All v1.0.0 readiness criteria explicitly signed off

### Execution model

Milestones are driven via `/loop` (milestone-by-milestone autonomous execution) with human approval
required only at the predefined decision gates documented in [clarifications.md](clarifications.md).
All 2 architecture decisions and all 7 clarification items are already resolved; no new human
decision gates are anticipated before M8/M9.

----------------------------------------------------------------------------------------------------

*Review produced by the OraDBA framework-review skill.* *Artifact set: `doc/review/` - 14 files.*
*All findings, decisions, and clarifications are fully resolved and documented.*
