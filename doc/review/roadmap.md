# OraDBA Implementation Roadmap - v0.24.11 to v1.0.0

**Version:** 1.0 (roadmap document) **Date:** 2026-06-26 **Status:** Active - supersedes
`.claude/review-plan.md` **Target:** v1.0.0 stable **Starting point:** v0.24.11

> **This document REPLACES `.claude/review-plan.md`.** The old plan (`.claude/review-plan.md`, dated
> 2026-03-10, status "Complete 2026-03-25") was a topic-by-topic exploratory review. Its 9 topics
> are now closed and several of its "deferred" items (lazy-loading, error-message standardisation,
> install/extension shared helper, the 5 untested bin scripts, the auto-generated extensions
> catalog) are folded into the milestones below and traced to consolidated-finding IDs. Treat
> `.claude/review-plan.md` as historical context only; this roadmap is the single source of truth
> for the path to v1.0.0.

----------------------------------------------------------------------------------------------------

## Executive summary

This roadmap converts the 34 consolidated findings (CF-001 to CF-034), 22 technical-debt items, and
19 risks into nine sequenced, independently verifiable milestones from v0.24.11 to v1.0.0. Ordering
is blocker-first: the recurring shell-defect class (zero-start arithmetic, missing strict mode) and
the recurring regression-protection gap are closed in M1 as an immediate safety net, followed by the
credential and supply-chain security class in M2. Test coverage (M3) is deliberately landed before
the two largest architecture changes - the plugin loader consolidation (M4) and the
environment-build migration (M6) - so that those high-blast-radius refactors land on a tested code
path. Two maintainer decisions are already fixed: DECISION 1 completes the migration of `oraenv.sh`
onto `oradba_build_environment` (M6, L-effort), and DECISION 2 adopts tiered plugin isolation -
mandatory `execute_plugin_function_v2` for state-changing calls, audited direct calls only for pure
path-builders (M4). Every milestone carries the same standardized quality gate (build, framework
validation, ShellCheck, shfmt -d, unit + integration + regression tests, docs, CHANGELOG, release
notes, version bump, one atomic commit) and is designed to be driven by autonomous implementer and
verifier agents, with human approval required only at the predefined decision gates. The release
strategy ends with an RC window (v1.0.0-rc.1) and an explicit v1.0.0 readiness checklist that gates
the final tag.

----------------------------------------------------------------------------------------------------

## Milestone overview

<!-- markdownlint-disable MD013 MD060 -->

| Milestone | Version                 | Focus                                                                                   | Effort | Blocker CFs closed                                       | Duration (placeholder) |
|-----------|-------------------------|-----------------------------------------------------------------------------------------|--------|----------------------------------------------------------|------------------------|
| M1        | v0.25.0                 | Immediate safety net (arithmetic, strict mode, regression tests, release gate)          | M      | CF-001, CF-003, CF-005, CF-009 (partial), CF-010, CF-027 | TBD-1                  |
| M2        | v0.26.0                 | Security hardening (credentials, temp files, eval, checksums)                           | M      | CF-002, CF-006                                           | TBD-2                  |
| M3        | v0.27.0                 | Test coverage of path-critical functions + remaining CF-001 regressions                 | L      | CF-008, CF-009 (complete)                                | TBD-3                  |
| M4        | v0.28.0                 | Plugin system consolidation (DECISION 2, tiered isolation)                              | L      | CF-004                                                   | TBD-4                  |
| M5        | v0.29.0                 | Architecture consolidation (canonical root, single oratab parser, prefixing, bootstrap) | M-L    | none (enabling)                                          | TBD-5                  |
| M6        | v0.30.0                 | Environment-build migration (DECISION 1) + single DB-status function                    | L      | CF-017                                                   | TBD-6                  |
| M7        | v0.31.0                 | Performance (lazy load, PDB alias gate, fork reduction)                                 | M-L    | CF-015                                                   | TBD-7                  |
| M8        | v0.32.0                 | Release engineering and documentation                                                   | M      | CF-019, CF-024                                           | TBD-8                  |
| M9        | v1.0.0-rc.1 then v1.0.0 | Stabilisation, RC window, readiness checklist, API freeze                               | M      | all remaining blockers verified                          | TBD-9 + 30-day soak    |

<!-- markdownlint-enable MD013 MD060 -->

Non-blocker findings are scheduled into the milestone that shares their subsystem:
CF-011/CF-012/CF-013 (dependency guards, portability) into M2/M5, CF-016 into M7, CF-018 into M6,
CF-020/CF-021/CF-022/CF-023 into M2, CF-024/CF-025/CF-026/CF-028 into M8,
CF-029/CF-030/CF-031/CF-032/CF-033 into M5, CF-034 into M8/M9.

----------------------------------------------------------------------------------------------------

## M1 - v0.25.0 - Immediate safety net

**Objective:** Eliminate the recurring shell-defect class and stand up the preventive controls and
regression tests so the same bugs cannot ship again.

**Scope (in):** CF-001 (zero-start `(( counter++ ))` in 9 scripts), CF-003 (duplicate
`plugin_check_listener_status`), CF-005 (strict mode on `oradba_homes.sh` and `oradba_extension.sh`
with simultaneous increment guards), CF-009 partial (regression tests for the six shipped defects
from the testing Required Regression Tests table), CF-010 (release pipeline VERSION-vs-tag
assertion), CF-027 (`make test-full` exit-code handling), and the CI lint guard plus
shellcheck/shfmt wiring that protect this class (TD-13, RF-04, RF-05).

**Scope (out):** Deep test coverage of path-critical functions (M3), any architecture refactor,
performance work.

**Expected outcome:** No standalone from-zero `(( var++ ))` remains; both dual-mode scripts run
under full `set -euo pipefail` with guarded increments; the plugin interface template defines
`plugin_check_listener_status` exactly once; a named regression test exists for each of the six
recent defects; the release pipeline fails on a VERSION/tag mismatch; `make test-full` no longer
masks failures; CI lints for the arithmetic pattern and runs `shfmt -d`.

**Implementation tasks:**

1. CF-001: replace or guard every from-zero increment listed in CF-001
    (`oradba_dsctl.sh:148,672-708`, `oradba_dbctl.sh:556-588`, `oradba_lsnrctl.sh:460-492`,
    `oradba_dbca.sh:455-482`, `oradba_version.sh:334,402`, `oradba_logrotate.sh:184-210`,
    `oradba_sqlnet.sh:655,668`, `oradba_env_changes.sh:200,203`) using the established
    `var=$(( var + 1 ))` form or `|| true` guard.
2. CF-005: add `set -euo pipefail` after the shebang in `oradba_homes.sh` and complete it in
    `oradba_extension.sh:17`; in the same commit guard the 13 `oradba_homes.sh` increments and the
    `oradba_extension.sh:1541-1748` increments; guard `cd "${ext_path}"` against an unset value
    (`oradba_extension.sh:603`); update CONTRIBUTING.md to state strict mode is mandatory (DOC-015).
3. CF-003: remove the dead first definition at `plugin_interface.sh:298`, keep one canonical
    `plugin_check_listener_status`, and add a guard test asserting each interface function name is
    defined exactly once in the template (TD-04).
4. CF-009 (six regression tests): implement the named tests from the testing Required Regression
    Tests table - `log_directory_fallback_uses_tmp_when_var_log_oracle_missing` and
    `log_directory_fallback_when_parent_not_writable` (b76fe9c),
    `datasafe_stopped_connector_shows_stopped_not_blank` and
    `datasafe_status_capture_survives_pipefail` (5e89542),
    `datasafe_section_displayed_with_single_connector` and
    `no_unguarded_post_increment_in_datasafe_loop` (4db7ccf),
    `parse_oracle_home_preserves_description_with_empty_alias` and
    `list_oracle_homes_preserves_description_with_empty_alias` (cbcb942),
    `installer_silent_succeeds_without_oracle_base_exported` and
    `prompt_oracle_base_returns_0_when_oracle_base_unset` (bbf2540),
    `no_post_increment_at_zero_in_test_suite` and `load_config_file_path_dedup_counts_correctly`
    (fa36489).
5. CF-010: replace the informational echo at `release.yml:43-46` with
    `[ "$(cat VERSION)" = "${GITHUB_REF#refs/tags/v}" ] || { echo "VERSION mismatch"; exit 1; }`
    before the build step and mirror it in `make release-check` (RF-02).
6. CF-027: change `Makefile:138-151` to run `bats --report-formatter tap` and parse TAP,
    distinguishing failed from skipped tests; stop treating exit 1 as success (RF-11).
7. TD-13/RF-04/RF-05: add a CI lint step flagging standalone `(( var++ ))`; add a `format-check`
    (`shfmt -d`) step to the CI lint job and to `make lint`; pin shellcheck in `release.yml` to
    match `ci.yml` (`SHELLCHECK_VERSION=0.10.0`).

**Dependencies:** None (foundational). M1 must precede all later milestones so the lint guard
prevents reintroduction.

**Acceptance criteria (measurable):**

- `grep -Ern '^[[:space:]]*\(\([A-Za-z_][A-Za-z0-9_]*\+\+\)\)' src/ tests/` returns zero standalone
  from-zero increments not inside an `if`/`then` body or guarded.
- `grep -c 'plugin_check_listener_status()' src/lib/plugins/plugin_interface.sh` equals 1.
- `head -2 src/bin/oradba_homes.sh` and `src/bin/oradba_extension.sh` both contain
  `set -euo pipefail`.
- All 12 named regression tests exist and pass; each fails when its fix is reverted (verified by the
  implementer reverting the fix in a scratch branch).
- A CI dry-run with `VERSION` deliberately mismatched against a fake tag exits non-zero at the
  assertion step.
- `make test-full` returns non-zero when a single synthetic failing test is added, and zero when
  only skips are present.
- CI lint job invokes both the arithmetic-pattern check and `shfmt -d`.

**Risks:** Adding strict mode to `oradba_homes.sh`/`oradba_extension.sh` can expose previously
masked failures (RISK-01 interaction with CF-005); mitigated by guarding every increment in the same
commit and running the full suite. Low residual risk.

**Quality gate (standard):** build OK (`make build`); framework validation
(`oradba_install.sh --prefix <tmp>` smoke); ShellCheck clean (`-S error`, pinned); `shfmt -d` clean;
unit tests pass; integration tests pass (Ubuntu installer lane); regression tests - all 12 M1
regression tests present and green; docs updated (CONTRIBUTING.md strict-mode statement); CHANGELOG
`[0.25.0]` entry; release notes `doc/releases/v0.25.0.md`; `VERSION` bumped to 0.25.0; one atomic
commit `fix(core): eliminate zero-start arithmetic and add regression+lint guards - v0.25.0`.

**Expected artifacts:** `doc/releases/v0.25.0.md`; new/extended bats files for the 12 regression
tests; modified `Makefile`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`; modified
`src/bin/*` per task list; modified `src/lib/plugins/plugin_interface.sh`; updated `CHANGELOG.md`,
`CONTRIBUTING.md`, `VERSION`.

----------------------------------------------------------------------------------------------------

## M2 - v0.26.0 - Security hardening

**Objective:** Remove credential exposure and supply-chain gaps so no secret reaches disk, process
args, or logs in cleartext and no download runs unverified.

**Scope (in):** CF-002 (DBCA password via stdin, not `/tmp`), CF-006 (installer `.sha256`
verification, fail closed), CF-020 (SEPS wallet - no cleartext log, permission check), CF-021 (RMAN
catalog + `--sys/--system` sanitisation), CF-022 (eval sanitisation in `oraenv.sh`), CF-023
(`mktemp` exclusive create + EXIT-trap cleanup). Add CF-011 (bash 4+ runtime guard) and CF-013
(Oracle CLI existence checks) here since they harden the same scripts.

**Scope (out):** Architecture changes; broad portability (CF-012) deferred to M5 unless co-located
with an edited script.

**Expected outcome:** SYS/SYSTEM passwords never written to a predictable file; installer verifies
the companion `.sha256` and aborts without a verify tool; `.wallet_pwd` is read only when `600` and
owner-owned and the recovered password is never logged; catalog/SYS credentials are kept off the
command line and out of logs; oratab/homes fields are validated before use (no eval breakout); temp
dirs use exclusive create with EXIT-trap cleanup; bash version and Oracle CLI tools are pre-flight
checked.

**Implementation tasks:**

1. CF-002: create the DBCA response file via `mktemp` in a mode-700 per-run dir, `chmod 600` before
    writing, register `trap ... EXIT` that shreds it on all paths including failure (remove the
    failure-preservation at `oradba_dbca.sh:613`), and prefer feeding SYS/SYSTEM via stdin so
    passwords do not hit disk (SEC-01).
2. CF-006: in `oradba_install.sh:2065-2085` download the companion `.sha256` and verify with
    `shasum -a 256 -c` before extraction; fail closed when no verify tool is present (replace the
    warn-and-continue at `:284`); add SHA-256 verification to `build_installer.sh:80-155` and the
    `ci.yml:81-83` shellcheck download; make the verified two-step download the headline documented
    install path in README.md (SEC-03, SEC-04).
3. CF-020: in `get_seps_pwd.sh` add a `stat` permission/owner check before `base64 -d` (refuse
    unless `600` and owner-owned), relabel base64 as obfuscation-only, and never log the recovered
    password at `:243` (SEC-02).
4. CF-021: pass RMAN catalog credentials inside the restricted `.rcv` body or via a SEPS alias and
    redact the catalog string in logs (`oradba_rman.sh:726-748`); pass RMAN catalog credentials via
    SEPS alias and redact catalog strings in debug logs (`oradba_rman.sh:726-748`); the
    `--sys-password`/`--system-password` DBCA flags remain (actively used, no deprecation); secure
    their handling: response file via `mktemp -p mode-700 dir`, `chmod 600`, EXIT-trap shred, never
    log value (SEC-05, SEC-08, SEC-09).
5. CF-022: replace `eval "${var}+=(...)"` in `oraenv.sh:401-443` with bash 4.3 namerefs, plus a
    strict allowlist validation `[[ "${sid}" =~ ^[A-Za-z0-9_.]+$ ]]` for the bash 3.2 path (SEC-06).
6. CF-023: switch `oradba_rman.sh:51,1048` to `mktemp -d ".../oradba_rman.XXXXXX"`,
    `oradba_homes.sh:1177` to `mktemp "${homes_file}.dedup.XXXXXX"`, verify ownership before use,
    and register a single-root `trap 'rm -rf ...' EXIT` in `oradba_extension.sh:784-1104` (SEC-07,
    BASH-016, BASH-018).
7. CF-011: add a startup bash 4+ guard to scripts using bash 4 features and as a critical check in
    `oradba_check.sh` (DEP-001).
8. CF-013: add `command -v`/`-x` pre-flight checks for `sqlplus`, `rman`, `lsnrctl` in
    `oradba_dbctl.sh`, `oradba_rman.sh`, `oradba_lsnrctl.sh` following the `oradba_dbca.sh:223`
    pattern (DEP-003).

**Dependencies:** M1 (strict mode and lint guard in place so new code is checked).

**Acceptance criteria (measurable):**

- A dry-run of `oradba_dbca.sh` shows no SYS/SYSTEM password on disk after exit (including a
  forced-failure path); `grep -n '/tmp/dbca' src/bin/oradba_dbca.sh` no longer matches the
  predictable response-file literal.
- Installer aborts with non-zero status when the `.sha256` does not match and when no checksum tool
  is available (covered by new bats tests).
- `get_seps_pwd.sh` refuses a `.wallet_pwd` that is group/other-readable (test with `chmod 644`);
  recovered password absent from log output.
- `grep -n 'eval' src/bin/oraenv.sh` shows no eval over oratab/homes fields; a fixture oratab entry
  containing `")$(touch /tmp/pwned)#` does not create the file (regression test).
- No `mktemp -u` remains; `grep -rn 'mktemp -u' src/` returns zero; EXIT traps present in the three
  temp-using scripts.
- Each script with bash 4 features exits with a clear message under bash 3.2 simulation; each
  Oracle-CLI script emits a clear diagnostic when the tool is absent.

**Risks:** Switching DBCA to stdin may interact with silent/automation flows (RISK-02, RISK-14);
mitigated by retaining a documented automation path and tests. Allowlist validation could reject
legitimate exotic SIDs (RISK-15); mitigated by matching Oracle SID character rules.

**Quality gate (standard):** as M1, plus security-focused regression tests (eval breakout, checksum
mismatch, wallet permission, temp-dir cleanup). Update SECURITY.md and the install docs; CHANGELOG
`[0.26.0]`; `doc/releases/v0.26.0.md`; `VERSION` 0.26.0; one atomic commit
`fix(security): close credential, eval, temp-file and checksum exposures - v0.26.0`.

**Expected artifacts:** new security regression bats; modified `oradba_dbca.sh`,
`oradba_install.sh`, `build_installer.sh`, `get_seps_pwd.sh`, `oradba_rman.sh`, `oraenv.sh`,
`oradba_homes.sh`, `oradba_extension.sh`, `oradba_check.sh`, `oradba_dbctl.sh`, `oradba_lsnrctl.sh`;
updated `README.md`, `SECURITY.md`, `ci.yml`, `CHANGELOG.md`, `VERSION`, `doc/releases/v0.26.0.md`.

----------------------------------------------------------------------------------------------------

## M3 - v0.27.0 - Test coverage

**Objective:** Bring the path-critical functions and install-state layer to behavioral coverage
targets and complete the CF-001 regression set, before any high-blast-radius refactor.

**Scope (in):** CF-008 (validator 22%-\>80%+, env-builder 45%-\>80%+, home-discovery 13%-\>70%+,
version-metadata 17%-\>80%+, env-output into testmap), the five untested bin scripts (F-014), and
CF-009 completion - dedicated regression tests for the CF-001 defect instances per the testing
Required Regression Tests rows mapping BASH-001 through BASH-006 and BASH-014 (the arithmetic class)
into per-script first-iteration tests.

**Scope (out):** Refactoring the functions under test (M4/M6); performance.

**Expected outcome:** Coverage targets met with mock Oracle-home fixtures; all five untested bin
scripts and `oradba_env_output.sh` have at least smoke tests and testmap entries; first-iteration
tests exist for each script that carried a from-zero increment; the happy-to-error assertion ratio
reaches the 15% floor.

**Implementation tasks:**

1. CF-008 validator: add `test_oradba_env_validator.bats` covering `oradba_validate_environment`,
    `oradba_validate_oracle_home`, `oradba_validate_sid`, `oradba_check_db_running`,
    `oradba_check_oracle_binaries`, `oradba_get_db_status`, `oradba_get_db_version` with mock homes
    (F-007).
2. CF-008 env-builder: extend `test_oradba_env_builder_unit.bats` for `oradba_clean_path`,
    `oradba_add_oracle_path`, `oradba_set_lib_path`, `oradba_detect_rooh`, `oradba_is_asm_instance`,
    `oradba_set_oracle_vars`, `oradba_set_asm_environment`, `oradba_set_product_environment`, and a
    full `oradba_build_environment` integration test with a mock home tree (F-008).
3. CF-008 home-discovery: add tests for `is_oracle_home`, `detect_product_type`,
    `is_subdirectory_of_oracle_home`, `parse_oracle_home`, `list_oracle_homes` with filesystem mocks
    (F-009).
4. CF-008 version-metadata: add unit tests for `get_install_info`, `set_install_info`,
    `init_install_info`, `version_meets_requirement`, `get_oradba_version` with a temp
    `.install_info` fixture (F-011).
5. CF-008 env-output: add `src/lib/oradba_env_output.sh` to `.testmap.yml` and add
    `test_oradba_env_output.bats` (F-012).
6. F-014: add `test_oradba_admin_scripts.bats` smoke tests (shebang, syntax, `--help` exit 0) for
    `oradba_logrotate.sh`, `sessionsql.sh`, `oradba_validate.sh`, `oradba_datasafe_debug.sh`,
    `oradba_setup.sh`, and add all five to `.testmap.yml`; add functional install/verify tests for
    `oradba_logrotate.sh` and `oradba_validate.sh`.
7. CF-009 completion: add first-iteration arithmetic tests per script - for example
    `oradba_version.sh --check-all` with a single valid home, the logrotate install/remove flow with
    exactly one config file, and equivalents for dbctl, lsnrctl, dbca, sqlnet (BASH-001 to BASH-006,
    BASH-014).
8. F-013: add negative tests per library (missing env var under nounset, arithmetic-at-zero,
    pipefail capture, empty config field) until error-path assertions reach \>= 15% of total.

**Dependencies:** M1 (regression scaffolding and lint guard).

**Acceptance criteria (measurable):**

- A coverage re-scan reports validator \>= 80%, env-builder \>= 80%, home-discovery \>= 70%,
  version-metadata \>= 80% function coverage.
- `oradba_env_output.sh` and the five bin scripts appear in `.testmap.yml`;
  `find tests -name '*.bats' | wc -l` matches the updated testmap annotation (F-015 also corrected
  here).
- Error-path assertion count / total assertions \>= 0.15 (measured by the scan).
- Every CF-001 script has at least one first-iteration test that fails when the increment guard is
  reverted.

**Risks:** Mock fixtures may not represent all Oracle-home layouts (RISK-06); mitigated by covering
DB, client, ASM, and RoOH structures. Landing tests before M4/M6 means some tests target
soon-to-change internals; mitigated by asserting on public behavior/output, not internal structure.

**Quality gate (standard):** as M1; docs - update `.testmap.yml` annotation and the test-count
references in README/CONTRIBUTING/doc/README (partial CF-025); CHANGELOG `[0.27.0]`;
`doc/releases/v0.27.0.md`; `VERSION` 0.27.0; one atomic commit
`test(coverage): cover path-critical functions and complete defect regressions - v0.27.0`.

**Expected artifacts:** new bats files (validator, env-output, admin-scripts), extended bats files
(env-builder, home-discovery, version-metadata, common), updated `.testmap.yml`, `CHANGELOG.md`,
`VERSION`, `doc/releases/v0.27.0.md`.

----------------------------------------------------------------------------------------------------

## M4 - v0.28.0 - Plugin system consolidation (DECISION 2)

**Objective:** Make the isolation wrapper the single sanctioned entry for state-changing plugin
calls and restrict direct in-parent calls to an audited list of pure path-builders, per DECISION 2.

**Scope (in):** CF-004 (audit and fix the 9 direct-source sites under the tiered model),
confirmation of the CF-003 single-definition interface fix, removal of the dead fallback branch, and
`.testmap.yml` updates for the plugin paths.

**Scope (out):** The performance fork-reduction work that also touches plugins (CF-016) lands in M7;
M4 establishes the contract M7 optimises within.

**Expected outcome:** `execute_plugin_function_v2` (or a thin documented wrapper) is the only
sanctioned entry for `plugin_detect_installation`, `plugin_check_status`, and
`plugin_check_listener_status`; direct in-parent calls remain only for the audited side-effect-free
path-builders `build_bin_path` and `build_lib_path`, with a documented exception list; the dead
no-op fallback at `oradba_common.sh:1559-1563` is removed; no `plugin_status`/`plugin_name` leakage
into the calling shell from state-changing calls.

**Implementation tasks:**

1. CF-004 audit: enumerate the 9 direct-source sites (`oraup.sh:399`, `oradba_homes.sh:838`,
    `oradba_dsctl.sh:41`, `oradba_env.sh:138`, `oradba_datasafe_debug.sh:328`,
    `oraenv.sh:754,920,1028`) and classify each call as state-changing or pure path-builder.
2. State-changing calls (`plugin_detect_installation`, `plugin_check_status`,
    `plugin_check_listener_status`) must route through `execute_plugin_function_v2`; convert each
    such site.
3. Pure path-builders (`build_bin_path`, `build_lib_path`) may be called directly after a single
    audited source; document the audited exception list in `doc/architecture.md` and in the plugin
    development docs (DECISION 2 record).
4. Remove the dead fallback branch at `oradba_common.sh:1559-1563` (ARCH-011).
5. Confirm the CF-003 single-definition fix and ensure the interface-uniqueness guard test from M1
    still passes.
6. Update `.testmap.yml` for the plugin loader paths; add tests asserting that a state-changing
    call does not leak `plugin_status`/`plugin_name` into the parent shell and that a pure
    path-builder returns identical output via direct call and via the wrapper.

**Dependencies:** M1 (CF-003 single definition), M3 (plugin and dsctl/oraup behavioral coverage so
the conversion is verifiable).

**Acceptance criteria (measurable):**

- For each state-changing function name, every call site in `src/` is routed through
  `execute_plugin_function_v2` (grep audit shows no direct invocation of those three function names
  outside the wrapper and the plugin files themselves).
- The audited exception list (exactly `build_bin_path`, `build_lib_path`) is documented and matched
  by the only remaining direct-call sites.
- After a state-changing plugin call from a parent shell,
  `set | grep -E 'plugin_status|plugin_name'` shows no leakage (test).
- `grep -n '1559' ...` confirms the dead fallback branch is gone (no no-op fallback remains).

**Risks:** Cross-plugin contamination if a state-changing call is missed (RISK-04); mitigated by the
grep audit acceptance criterion and the leakage test. Subshell cost increase is accepted here and
addressed in M7 (DECISION 2 explicitly trades isolation for the M7 pure-builder optimisation).

**Quality gate (standard):** as M1; docs - architecture.md and plugin development docs updated with
the tiered model and exception list; CHANGELOG `[0.28.0]`; `doc/releases/v0.28.0.md`; `VERSION`
0.28.0; one atomic commit `refactor(plugins): enforce tiered isolation per DECISION 2 - v0.28.0`.

**Expected artifacts:** modified plugin call sites in the 9 listed files, modified
`oradba_common.sh`, updated `doc/architecture.md`, plugin dev docs, `.testmap.yml`, new
plugin-isolation tests, `CHANGELOG.md`, `VERSION`, `doc/releases/v0.28.0.md`.

----------------------------------------------------------------------------------------------------

## M5 - v0.29.0 - Architecture consolidation

**Objective:** Establish the canonical install-root variable, a single oratab parser, prefixed
public functions, and a shared bootstrap loader - the foundations the env-build migration (M6)
depends on.

**Scope (in):** CF-007 (canonical `ORADBA_BASE`, deprecate `ORADBA_PREFIX` as an alias with a
runtime warning), CF-029 (single oratab parser via the registry), CF-030 (`oradba_` prefix on public
functions with deprecation aliases; fix the shadowing `oradba_log` stub), CF-032 (shared
`oradba_bootstrap.sh` for bin scripts). Fold in CF-031 (stderr routing) and CF-033 (locale, GNU
date, fragile idioms) and CF-012 (GNU-only tool fallbacks) since they touch the same files.

**Scope (out):** The env-build migration itself (M6).

**Expected outcome:** One canonical root variable resolved consistently; `ORADBA_PREFIX` remains as
a deprecated alias emitting a runtime warning; the registry is the sole oratab reader; public
functions are `oradba_`-prefixed with one-release deprecation aliases; one sourced bootstrap file
resolves the root and sources libraries in a defined order, used by all bin scripts.

**Implementation tasks:**

1. CF-007: define `ORADBA_BASE` as the single install-root variable; replace all
    `${ORADBA_PREFIX}/...` references (`oradba_homes.sh:832`, `oradba_registry.sh:77,219`,
    `oradba_database_discovery.sh:359,390`); keep `ORADBA_PREFIX` as an alias that emits a
    deprecation warning when set (ARCH-003, RISK-05, RF-12 policy).
2. CF-032: create `src/lib/oradba_bootstrap.sh` that resolves the root from `BASH_SOURCE`, exports
    `ORADBA_BASE`, and sources required libraries in one defined order; convert the 27 bin scripts
    to source it (ARCH-009).
3. CF-029: make `oradba_registry` the sole oratab reader; route
    `parse_oratab`/`oradba_parse_oratab` and the registry inline parse through
    `oradba_registry_get_*`; implement `oradba_registry_discover_all` (DR-2 resolved: implement, do
    not document as out of scope) (ARCH-006, ARCH-010).
4. CF-030: prefix unprefixed public functions (`parse_oratab`, `get_oracle_homes_path`,
    `detect_product_type`, `set_oracle_home_environment`, `generate_sid_lists`,
    `check_database_connection`) with `oradba_` and add one-release deprecation aliases; remove the
    shadowing `oradba_log` stub in `oradba_datasafe_debug.sh:320` and guard fallback definitions
    with `command -v oradba_log >/dev/null || ...` (ARCH-007, ARCH-008).
5. CF-031: add `>&2` to the listed stdout error calls (`get_seps_pwd.sh:32`, `oradba_dsctl.sh:34`,
    `oradba_dbctl.sh:34`, `oradba_lsnrctl.sh:33`, `oradba_services_root.sh:36`,
    `oradba_env.sh:554,585,600`).
6. CF-033: rewrite the grep/find boolean idioms as explicit two-step checks, prefix `sort`/`comm`
    with `LC_ALL=C`, and guard the uptime computation against an implausible epoch
    (`oradba_db_functions.sh:269`).
7. CF-012: replace `df -BG`/`df -Pm` with `df -k` + awk, add the `sha256sum || shasum -a 256`
    fallback where missing, align `sync_to_peers.sh` with the `realpath` fallback, and detect
    `timeout`/`gtimeout` before use.

**Dependencies:** M1, M3 (coverage so the prefixing/bootstrap changes are verifiable on the affected
paths).

**Acceptance criteria (measurable):**

- `grep -rn 'ORADBA_PREFIX' src/lib src/bin` shows only the alias-definition and deprecation-warning
  site, not path construction.
- Setting `ORADBA_PREFIX` produces a deprecation warning on stderr (test).
- All 27 bin scripts source `oradba_bootstrap.sh`; no bin script re-derives the root with an ad hoc
  expression.
- Only the registry reads oratab; `grep -rn 'IFS=:' src/lib` shows oratab parsing centralised in
  `oradba_registry.sh`.
- No unprefixed public function is exported; deprecation aliases resolve for one release;
  `oradba_log` is defined once at runtime.
- `df -BG`/`df -Pm` absent; `command -v` guards present for `timeout`.

**Risks:** Bootstrap consolidation and prefixing have wide blast radius across downstream consumers
`odb_datasafe` and `exatoolbox` (RISK-05); mitigated by deprecation aliases for one release and the
M3 coverage. Registry-only parsing could regress standalone-script bootstrapping; mitigated by tests
on each standalone script.

**Quality gate (standard):** as M1; docs - architecture.md, development.md, `src/lib/README.md`,
`src/bin/README.md` updated to the canonical variable, bootstrap, registry parser, and prefixed
names; CHANGELOG `[0.29.0]` with explicit deprecation notes; `doc/releases/v0.29.0.md`; `VERSION`
0.29.0; one atomic commit
`refactor(arch): canonical ORADBA_BASE, shared bootstrap, single oratab parser, prefixed API - v0.29.0`.

**Expected artifacts:** new `src/lib/oradba_bootstrap.sh`; modified 27 bin scripts,
`oradba_registry.sh`, `oradba_database_discovery.sh`, `oradba_common.sh`,
`oradba_datasafe_debug.sh`, the stderr/idiom/portability sites; updated docs, `CHANGELOG.md`,
`VERSION`, `doc/releases/v0.29.0.md`.

----------------------------------------------------------------------------------------------------

## M6 - v0.30.0 - Environment-build migration (DECISION 1)

**Objective:** Complete the migration so `oraenv.sh` delegates to `oradba_build_environment` and
retire the inline environment-building logic, with a single canonical DB-status function.

**Scope (in):** CF-017 (migrate `oraenv.sh` onto `oradba_build_environment`, retire the inline logic
in `oradba_common.sh`), CF-018 (single canonical DB-status function). This is L-effort and requires
M3 coverage as a prerequisite.

**Scope (out):** Performance tuning of the unified path (M7); plugin contract (settled in M4).

**Expected outcome:** `oraenv.sh:719,985-986,1022` no longer build the environment inline; the
single tested orchestrator `oradba_build_environment` (`oradba_env_builder.sh:889`) is the one path;
the inline logic and redundant sub-functions are retired; DB status is queried by one canonical
function with a fixed output vocabulary and documented exit-code contract, called by the validator
and `oradba_db_functions.sh`.

**Implementation tasks:**

1. CF-017: route `oraenv.sh` environment construction through `oradba_build_environment`; remove
    the inline `set_oracle_home_environment` and variable-setting blocks (`:719,985-986,1022`);
    retire now-dead inline logic in `oradba_common.sh` (ARCH-004, P-01, DOC-019).
2. CF-017 docs: update README and `src/lib/README.md` so the env-builder is the documented single
    public path, not an "alternate API".
3. CF-018: define one canonical open-mode function with a fixed vocabulary (one of: OPEN, MOUNTED,
    NOMOUNT, STARTED, SHUTDOWN) and a documented exit-code contract in the status module; have
    `oradba_env_validator.sh:194,238` and `oradba_db_functions.sh:60,83` call it; remove the
    redundant heredocs (ARCH-005).
4. Run the M3 env-builder integration tests against the migrated path; add a parity test that
    asserts the migrated `oraenv.sh` produces the same exported environment (ORACLE_HOME, PATH,
    LD_LIBRARY_PATH, TNS_ADMIN) as the pre-migration behavior for a fixed fixture.

**Dependencies:** M3 (env-builder and validator coverage), M5 (canonical root and bootstrap so the
migrated path resolves consistently).

**Acceptance criteria (measurable):**

- `grep -n 'set_oracle_home_environment' src/bin/oraenv.sh` shows no inline build call; `oraenv.sh`
  invokes `oradba_build_environment`.
- The env-builder integration test and the environment-parity test pass for DB, client, ASM, and
  RoOH fixtures.
- Exactly one DB open-mode function exists; the validator and db_functions call it; status
  vocabulary is consistent across all callers (grep audit).
- The retired inline functions in `oradba_common.sh` are removed or clearly demoted to internal
  helpers with no public callers.

**Risks:** This is the most-used code path; regressions here affect every env switch (RISK-08).
Mitigated by landing on the M3-tested orchestrator, the parity test, and the M9 RC soak. The
migration is L-effort and is the single largest schedule risk in the roadmap.

**Quality gate (standard):** as M1, with the env-parity test required; docs - README and
`src/lib/README.md` reflect the single path; CHANGELOG `[0.30.0]`; `doc/releases/v0.30.0.md`;
`VERSION` 0.30.0; one atomic commit
`refactor(env): migrate oraenv.sh to oradba_build_environment, single DB-status function - v0.30.0`.

**Expected artifacts:** modified `oraenv.sh`, `oradba_common.sh`, `oradba_env_builder.sh`,
`oradba_env_validator.sh`, `oradba_db_functions.sh`, `oradba_env_status.sh`; new parity test;
updated README, `src/lib/README.md`, `CHANGELOG.md`, `VERSION`, `doc/releases/v0.30.0.md`.

----------------------------------------------------------------------------------------------------

## M7 - v0.31.0 - Performance

**Objective:** Cut the per-env-switch fixed cost via lazy library loading, a PDB-alias gate, and
fork-reduction on the hot path, without weakening the M4 isolation contract.

**Scope (in):** CF-014 (lazy/deferred library loading, remove double config load), CF-015 (gate
`generate_pdb_aliases`, default `ORADBA_LOAD_PDB_ALIASES=false`, per-SID session guard, extend
`--fast-silent`), CF-016 (subshell/fork reduction - dedupe, log timestamp, path operations, with
pure path-builders called directly per DECISION 2).

**Scope (out):** Any change to the plugin isolation contract for state-changing calls (fixed in M4).

**Expected outcome:** Path-specific libraries are sourced only when needed; the double config load
is removed; `generate_pdb_aliases` no longer spawns sqlplus on silent/fast paths and is gated and
session-guarded; hot-path subshell/fork patterns are replaced with bash built-ins and caching; pure
plugin path-builders are called directly (DECISION 2) while state-changing calls keep the wrapper.

**Implementation tasks:**

1. CF-014: source `oradba_env_parser.sh`, `oradba_env_builder.sh`, `oradba_env_validator.sh`,
    `oradba_env_config.sh` inside the functions that need them; remove the direct `load_config_file`
    calls at `oraenv.sh:51,56` and defer to the single `load_config()` (P-01, P-02).
2. CF-015: gate `generate_pdb_aliases` (`oradba_database_discovery.sh:164-228`) behind
    `ORADBA_LOAD_PDB_ALIASES` defaulting false; add a per-SID session guard
    `ORADBA_PDB_ALIASES_DONE_${ORACLE_SID}`; extend `--fast-silent` to skip PDB alias generation
    (P-13). This is the v1.0.0-blocking performance item.
3. CF-016: replace the O(N^2) dedupe with `awk '!seen[$0]++'` and dedupe PATH once at end of load;
    move the log timestamp behind the level filter and precompute `ORADBA_MIN_LEVEL_VALUE`; cache
    `(product_type, oracle_home)` results and parse `oradba_homes.conf` once into an associative
    array; replace `echo|sed`/`echo|awk` with parameter expansion; replace the 14 `command -v`
    guards with `declare -f` or flags; call pure plugin path-builders (`build_bin_path`,
    `build_lib_path`) directly per DECISION 2 (P-03 to P-12, ARCH-013).

**Dependencies:** M4 (plugin contract decided so direct pure-builder calls are sanctioned), M6
(single env-build path so optimisation targets one implementation).

**Acceptance criteria (measurable):**

- `oradba_core.conf` and `oradba_local.conf` are each loaded once per source (instrumented test or
  `ORADBA_PROFILE_STARTUP` trace).
- With `ORADBA_LOAD_PDB_ALIASES` unset and `--silent`/`--fast-silent`, no `sqlplus` process is
  spawned during an env switch (process-count test against a mock).
- A repeat env switch for the same SID does not re-run PDB alias generation (session guard test).
- Hot-path fork count for a fixed fixture is measurably lower than the v0.30.0 baseline (captured
  via `ORADBA_PROFILE_STARTUP`); no functional regression in the M3/M6 tests.

**Risks:** Lazy loading can break callers relying on a library being pre-sourced (RISK-16);
mitigated by the M3/M6 functional tests and by sourcing on first use. Caching can serve stale
results if homes change mid-session; mitigated by keying the cache on the homes-file mtime or
invalidating on explicit reload.

**Quality gate (standard):** as M1, plus a profiling artifact showing the before/ after fork count;
docs - configuration.md documents `ORADBA_LOAD_PDB_ALIASES` and the fast-silent behavior; CHANGELOG
`[0.31.0]`; `doc/releases/v0.31.0.md`; `VERSION` 0.31.0; one atomic commit
`perf(env): lazy loading, PDB-alias gate, hot-path fork reduction - v0.31.0`.

**Expected artifacts:** modified `oraenv.sh`, `oradba_common.sh`, `oradba_database_discovery.sh`,
`oradba_env_builder.sh`, `oradba_home_discovery.sh`, `oradba_standard.conf`; new perf/process-count
tests; profiling artifact under `doc/review/`; updated configuration.md, `CHANGELOG.md`, `VERSION`,
`doc/releases/v0.31.0.md`.

----------------------------------------------------------------------------------------------------

## M8 - v0.32.0 - Release engineering and documentation

**Objective:** Close the release-gate and documentation-accuracy gaps and author the v1.0.0
readiness definition, leaving only stabilisation for M9.

**Scope (in):** CF-019 (Docker integration in CI), CF-024 (Registry API docs), CF-025 (version/count
staleness + build-injected headers), CF-026 (release-note/ tag/CHANGELOG drift), CF-028 (pin
images/actions/packages, verify build downloads), RF-04/RF-05 confirmation in release.yml, RF-10
(reproducible build), RF-14 (`doc/v1.0.0-readiness.md`), RF-07 (`build_installer.sh` strict mode),
RF-13 (pre-push hook).

**Scope (out):** Tagging v1.0.0 (M9).

**Expected outcome:** Docker integration runs on a schedule and is a required status check; Registry
API docs match the 8-field pipe schema and real functions; versions/counts are accurate and
build-injected; release notes exist for every tagged version and the pipeline fails when a note is
missing; CI images/actions/ packages are pinned and build downloads verified;
`doc/v1.0.0-readiness.md` exists; `build_installer.sh` runs strict mode; a pre-push hook runs
`make lint`.

**Implementation tasks:**

1. CF-019: add `on: schedule` to `docker-tests.yml` and wire a recent successful run as a required
    status check before release tags; record a documented passing Docker integration run as a
    release-checklist item (RF-03).
2. CF-024: correct `doc/api.md:82` and `doc/architecture.md:154` to the `REGISTRY_FIELD_SEP="|"`
    8-field schema `type|name|home|version|flags|order|alias|desc`; remove the three phantom
    functions and document the four real ones (DOC-001, DOC-002).
3. CF-025: adopt the `__VERSION__` build-injection pattern for script headers (RF-08); add
    `make validate-docs-counts` failing on test/library/plugin/function count divergence; fix the
    broken `doc/markdown-linting.md` link, the `oraup.sh` description, the "Phase X of 9"
    scaffolding, the pre-rebrand Docker image pin (pre-rebrand Docker image pin -\>
    `container-registry.oracle.com/database/free:latest`), and stale function listings; align
    `.testmap.yml:8` and add a CI check matching the annotation to
    `find tests -name '*.bats' | wc -l` (DOC-003 to DOC-019, F-015).
4. CF-026: change the `else` branch at `release.yml:95` to `exit 1` when the notes file is absent;
    add a `release-notes` prerequisite to `release-check`; retroactively create
    `doc/releases/v0.24.5.md`; resolve the v0.24.4 orphan; add CHANGELOG comparison diff links
    (RF-06, RF-09, DOC-012, DOC-013).
5. CF-028: pin Docker images by digest, third-party actions by commit SHA, and pip/npm packages by
    version (a `requirements-docs.txt`); add an `openssl` existence check; checksum-verify the
    extension-template download or pin via a tracked `templates/oradba_extension/.version` and add
    `--offline` to `build_installer.sh` (DEP-007 to DEP-014, RF-10).
6. RF-07: set `build_installer.sh:19` to `set -euo pipefail`.
7. RF-13: add `.githooks/pre-push` running `make lint` and wire
    `git config core.hooksPath .githooks` into `make setup-dev`.
8. RF-14: author `doc/v1.0.0-readiness.md` with the explicit criteria enumerated in the v1.0.0
    readiness checklist below (CF-034).

**Dependencies:** M1 (CI lint, VERSION assertion, shfmt, shellcheck pin already landed and now
extended), M3 (test counts to validate against).

**Acceptance criteria (measurable):**

- `docker-tests.yml` has a `schedule` trigger; the release workflow references a required Docker
  status check.
- `doc/api.md` and `doc/architecture.md` state the pipe delimiter and 8-field schema; the three
  phantom functions are gone; the four real functions documented.
- `make validate-docs-counts` passes (counts match actuals); the CI testmap-count check passes; no
  script header shows a stale hardcoded version.
- `release.yml` exits non-zero when a release-notes file is absent (dry-run test);
  `doc/releases/v0.24.5.md` exists; v0.24.4 orphan resolved; CHANGELOG has comparison links.
- All Docker image tags, third-party actions, and packages are pinned; the extension-template
  download is checksum-verified or pinned; `build_installer.sh` has `set -euo pipefail`.
- `doc/v1.0.0-readiness.md` exists and lists every criterion in the checklist below.

**Risks:** Pinning may break builds when a pinned digest is later removed (RISK-18); mitigated by
tracking pins and a documented update procedure. Build-injected headers must not desync from
`VERSION` (TD-19); mitigated by the `validate-docs-counts` and VERSION-assertion gates.

**Quality gate (standard):** as M1; docs - api.md, architecture.md, README, development.md,
`.testmap.yml`, all stale headers corrected; `doc/v1.0.0-readiness.md` created; CHANGELOG
`[0.32.0]`; `doc/releases/v0.32.0.md`; `VERSION` 0.32.0; one atomic commit
`chore(release): integration gate, doc accuracy, supply-chain pinning, v1.0.0 readiness doc - v0.32.0`.

**Expected artifacts:** `doc/v1.0.0-readiness.md`, `doc/releases/v0.24.5.md`,
`doc/releases/v0.32.0.md`, `.githooks/pre-push`, `requirements-docs.txt`,
`templates/oradba_extension/.version`; modified `docker-tests.yml`, `release.yml`, `ci.yml`,
`docs.yml`, `build_installer.sh`, `Makefile`, `doc/api.md`, `doc/architecture.md`, script headers,
`.testmap.yml`, `CHANGELOG.md`, `VERSION`.

----------------------------------------------------------------------------------------------------

## M9 - v1.0.0-rc.1 then v1.0.0 - Stabilisation

**Objective:** Verify all blocking findings closed, soak through a 30-day RC window, freeze the
public API surface, and tag v1.0.0.

**Scope (in):** RC tag `v1.0.0-rc.1`, 30-day stabilisation window, final Docker integration run on
Oracle AI Database 26ai, verification that every blocking CF is closed, deprecation warnings for
removed variables confirmed, CHANGELOG and release notes complete, public API surface declared
frozen (CF-034, RF-01, RF-12, RF-14).

**Scope (out):** New features; any non-blocking finding deferred to v1.1.0 (CF-016 residual beyond
M7, CF-028 residual, TD-10/TD-20 remainder).

**Expected outcome:** `v1.0.0-rc.1` tagged; no Critical or High finding reopened during the soak; a
documented passing Docker integration run on Oracle AI Database 26ai; the v1.0.0 readiness checklist
fully checked; deprecation warnings present for `ORADBA_PREFIX` and the v0.20.0 renamed variables;
v1.0.0 tagged with a frozen API contract.

**Implementation tasks:**

1. Tag `v1.0.0-rc.1` from the M8 head after the readiness checklist passes; open a 30-day soak
    window (RF-01).
2. Run the full Docker integration suite against Oracle AI Database 26ai and record the result as a
    release-checklist artifact (CF-019, RF-14 item c). If the 26ai image tag is unavailable, fall
    back to the supported Oracle version recorded in clarifications and note the substitution.
3. Verify every blocker CF (CF-001, CF-002, CF-003, CF-004, CF-005, CF-006, CF-007, CF-008, CF-009,
    CF-010, CF-015, CF-017, CF-019, CF-024, CF-034) is closed with evidence; reopen any that
    regressed.
4. Confirm runtime deprecation warnings exist for `ORADBA_PREFIX`, `ORADBA_AUTO_DISCOVER_HOMES`,
    and `ORADBA_FULL_DISCOVERY` (RF-12).
5. Declare the public API surface frozen per the API-freeze scope below; finalize CHANGELOG
    `[1.0.0]`, `doc/releases/v1.0.0.md`, and the migration notes.
6. After the soak with no new Critical/High fix, tag `v1.0.0`.

**Dependencies:** M1 through M8 all complete and merged.

**Acceptance criteria (measurable):** the v1.0.0 readiness checklist below is fully satisfied;
`v1.0.0-rc.1` tagged; \>= 30 days elapsed since the RC with no new Critical/High fix; Docker
integration artifact present; CHANGELOG `[1.0.0]` and `doc/releases/v1.0.0.md` complete.

**Risks:** A blocker regression during soak resets the soak clock (RISK-19); mitigated by the M1
lint guard and the full regression suite. Image availability for 26ai (see clarifications) may force
a documented substitution.

**Quality gate (standard):** as M1, applied to the RC and to the final tag; one atomic commit per
tag (`chore(release): v1.0.0-rc.1` and `chore(release): v1.0.0`); release notes and CHANGELOG
complete; `VERSION` set to `1.0.0-rc.1` then `1.0.0`.

**Expected artifacts:** `doc/releases/v1.0.0-rc.1.md`, `doc/releases/v1.0.0.md`, the Docker
integration artifact, the completed `doc/v1.0.0-readiness.md` checklist, `CHANGELOG.md` `[1.0.0]`,
`VERSION`.

----------------------------------------------------------------------------------------------------

## Standardized quality gate (applies to every milestone)

A milestone is "done" only when all of the following pass:

1. Build OK - `make build` produces the installer without error.
2. Framework validation - `oradba_install.sh --prefix <tmp> --silent --no-update-profile` succeeds;
    smoke of `oraenv.sh`.
3. ShellCheck clean - pinned v0.10.0, `-S error`, zero findings.
4. `shfmt -d` clean - no formatting diff.
5. Unit tests - full bats unit suite green via the fixed `make test-full` (TAP parsing, M1).
6. Integration tests - the Ubuntu installer lane plus, from M8 onward, the Docker integration run.
7. Regression tests - every recent defect has its dedicated regression test (the 12 named tests
    from M1 plus the per-script first-iteration tests from M3), and every defect fixed within the
    milestone gets a new dedicated regression test that fails when the fix is reverted.
8. Docs updated - all affected docs in the milestone scope.
9. CHANGELOG updated - a single `[version]` section, no duplicates.
10. Release notes updated - `doc/releases/v<version>.md` present (pipeline fails if absent from M8
    onward).
11. Version bump - `VERSION` set to the milestone version.
12. One atomic Git commit - Conventional Commits message including the version, no `Co-Authored-By`.

----------------------------------------------------------------------------------------------------

## Automation design

### Executing agents

The existing `.claude/agents/` set is review-only (scan-*, review-*, consolidate, roadmap).
Implementation milestones require implementer and verifier agents. The driver dispatches, per
milestone:

- `implement-milestone` (opus) - applies the milestone tasks, writes tests, updates
  docs/CHANGELOG/release notes, bumps VERSION, and stages one atomic commit. One focused milestone
  per invocation.
- `verify-milestone` (sonnet) - runs the standardized quality gate read-only-ish (build, lint,
  shfmt, tests) and reports pass/fail per gate item without amending the commit.
- `review-bash`, `review-security`, `review-testing`, `review-performance`, `review-architecture`
  (existing) - re-run scoped to the milestone diff as acceptance reviewers for the milestone's
  domain (for example `review-security` gates M2, `review-testing` gates M3, `review-architecture`
  gates M4/M5/M6, `review-performance` gates M7, `review-release` gates M1/M8/M9).

Mapping of executing/gating agents to milestones:

<!-- markdownlint-disable MD013 MD060 -->

| Milestone | Implementer         | Domain acceptance reviewer          | Verifier         |
|-----------|---------------------|-------------------------------------|------------------|
| M1        | implement-milestone | review-bash, review-release         | verify-milestone |
| M2        | implement-milestone | review-security                     | verify-milestone |
| M3        | implement-milestone | review-testing                      | verify-milestone |
| M4        | implement-milestone | review-architecture                 | verify-milestone |
| M5        | implement-milestone | review-architecture                 | verify-milestone |
| M6        | implement-milestone | review-architecture, review-testing | verify-milestone |
| M7        | implement-milestone | review-performance                  | verify-milestone |
| M8        | implement-milestone | review-release, review-docs         | verify-milestone |
| M9        | implement-milestone | review-release                      | verify-milestone |

<!-- markdownlint-enable MD013 MD060 -->

### Driver/loop done-signal

For each milestone the driver loop treats the milestone as complete only when both hold:

1. Artifact existence - every file in the milestone "Expected artifacts" list is present on disk,
    the `VERSION` file equals the milestone version, and `doc/releases/v<version>.md` and the
    CHANGELOG `[version]` section exist.
2. Quality-gate pass - `verify-milestone` reports all 12 standardized gate items green and the
    milestone's domain acceptance reviewer reports no Critical/High finding on the diff.

If either fails, the driver re-dispatches `implement-milestone` with the failing gate items as the
focused task and does not advance to the next milestone.

### Human approval (predefined decision gates only)

Human approval is required at exactly these points and nowhere else:

- DECISION GATE 1 (already passed) - DECISION 1 and DECISION 2 are fixed in this roadmap; no further
  approval needed to start M1.
- DECISION GATE 2 - before M4 begins, a human confirms the audited pure path-builder exception list
  (exactly `build_bin_path`, `build_lib_path`) is complete; the implementer must not add to it
  without approval.
- DECISION GATE 3 - before M6 begins, a human confirms M3 coverage targets are met
  (env-builder/validator) since the L-effort migration depends on them.
- DECISION GATE 4 - before tagging `v1.0.0-rc.1` (M9), a human signs off the readiness checklist and
  the API-freeze scope.
- DECISION GATE 5 - before tagging `v1.0.0` (M9), a human confirms the 30-day soak completed with no
  new Critical/High fix.

All other transitions are autonomous: artifact existence plus quality-gate pass.

----------------------------------------------------------------------------------------------------

## Release strategy

### Version numbers per milestone

M1 v0.25.0, M2 v0.26.0, M3 v0.27.0, M4 v0.28.0, M5 v0.29.0, M6 v0.30.0, M7 v0.31.0, M8 v0.32.0, M9
v1.0.0-rc.1 then v1.0.0. Each milestone is a minor release; the cadence replaces the prior same-day
patch loop (RF-01) with one tagged minor per completed milestone.

### Stabilisation phases

- Per-milestone stabilisation - no milestone tags until its quality gate and domain reviewer pass.
- M9 RC phase - `v1.0.0-rc.1` tagged from the M8 head; a 30-day soak window with no new
  Critical/High fix is required before promotion. A new Critical/High fix during the window ships as
  `v1.0.0-rc.2` and resets the soak clock.

### API-freeze scope (declared at v1.0.0)

Frozen and retained through at least v2.0.0 with deprecation warnings required for any future
removal:

- Environment variables - the canonical `ORADBA_BASE` and the documented `ORADBA_*` configuration
  variables (108 surveyed, zero Oracle collisions per the prior review). `ORADBA_PREFIX`,
  `ORADBA_AUTO_DISCOVER_HOMES`, `ORADBA_FULL_DISCOVERY` remain as deprecated aliases emitting
  runtime warnings.
- CLI flags - `--dry-run`, `--delete`, `--yes`, `--help`, `--silent`, `--fast-silent`, and the
  documented installer flags; `--sys-password`/ `--system-password` DBCA flags are retained (not
  deprecated - actively used in DBCA workflows; credential handling is secured in M2 without API
  change).
- Plugin interface - version `1.0.0`, the 13-function contract, and the tiered isolation model from
  DECISION 2 (mandatory `execute_plugin_function_v2` for state-changing calls; audited direct calls
  for `build_bin_path`/`build_lib_path`).
- Public functions - the `oradba_`-prefixed API after M5; unprefixed aliases remain for one release
  (through v1.0.0) and are removed at the next major.
- Registry API - the 8-field pipe schema `type|name|home|version|flags|order|alias|desc` and the
  documented `oradba_registry_*` functions (corrected in M8).

### Backward-compatibility contract from v0.24.x

- Any environment variable or flag present in v1.0.0 is retained through at least v2.0.0.
- Breaking renames since v0.19.0 (including `ORADBA_PREFIX` deprecation) ship with runtime
  deprecation warnings (RF-12); the warnings remain for one major cycle.
- Downstream consumers `odb_datasafe` and `exatoolbox` are covered by the one-release deprecation
  aliases introduced in M5; the M5 CHANGELOG entry lists every renamed symbol.

----------------------------------------------------------------------------------------------------

## v1.0.0 readiness checklist (all must be true before tagging v1.0.0)

This is the canonical checklist; `doc/v1.0.0-readiness.md` (authored in M8) mirrors it.

- [ ] All blocker findings closed with evidence: CF-001, CF-002, CF-003, CF-004, CF-005, CF-006,
  CF-007, CF-008, CF-009, CF-010, CF-015, CF-017, CF-019, CF-024, CF-034.
- [ ] No standalone from-zero `(( var++ ))` in `src/` or `tests/` (CI lint green).
- [ ] All 12 named regression tests plus the per-script first-iteration tests present and green;
  each fails when its fix is reverted.
- [ ] No secret reaches disk, process args, or logs in cleartext (M2 criteria met).
- [ ] Installer verifies the companion `.sha256` and fails closed without a verify tool.
- [ ] Coverage targets met: validator \>= 80%, env-builder \>= 80%, home-discovery \>= 70%,
  version-metadata \>= 80%; error-path assertion ratio \>= 15%.
- [ ] Plugin tiered isolation enforced (DECISION 2); audited exception list documented; no
  `plugin_status`/`plugin_name` leakage from state-changing calls.
- [ ] Single canonical install-root (`ORADBA_BASE`); shared bootstrap used by all bin scripts;
  single oratab parser via the registry.
- [ ] `oraenv.sh` delegates to `oradba_build_environment`; inline logic retired (DECISION 1); single
  DB-status function.
- [ ] `generate_pdb_aliases` gated (default off) and session-guarded; no sqlplus spawn on
  silent/fast paths.
- [ ] Release pipeline asserts VERSION == git tag; `make test-full` distinguishes failed from
  skipped tests; `shfmt -d` and pinned shellcheck in CI and release.
- [ ] Docker integration runs on a schedule and is a required status check; a documented passing run
  on Oracle AI Database 26ai (or the recorded supported substitute) exists.
- [ ] Registry API docs corrected (8-field pipe schema, real functions only);
  `make validate-docs-counts` passes; no stale per-script header versions.
- [ ] Release notes exist for every tagged version; v0.24.4/v0.24.5 drift resolved; CHANGELOG has
  comparison diff links.
- [ ] CI images/actions/packages pinned; extension-template download verified or pinned;
  `build_installer.sh` runs `set -euo pipefail`.
- [ ] Public API surface declared frozen (scope above); deprecation warnings present for
  `ORADBA_PREFIX`, `ORADBA_AUTO_DISCOVER_HOMES`, `ORADBA_FULL_DISCOVERY`.
- [ ] `v1.0.0-rc.1` tagged and \>= 30 days elapsed with no new Critical/High fix.
- [ ] CHANGELOG `[1.0.0]` and `doc/releases/v1.0.0.md` complete.

----------------------------------------------------------------------------------------------------

## Traceability summary

Every consolidated finding is scheduled:

- M1: CF-001, CF-003, CF-005, CF-009 (six defect tests), CF-010, CF-027 (+ TD-13, RF-04, RF-05)
- M2: CF-002, CF-006, CF-011, CF-013, CF-020, CF-021, CF-022, CF-023
- M3: CF-008, CF-009 (CF-001 instance regressions, F-013, F-014, F-015 partial)
- M4: CF-004 (+ CF-003 confirmation)
- M5: CF-007, CF-012, CF-029, CF-030, CF-031, CF-032, CF-033
- M6: CF-017, CF-018
- M7: CF-014, CF-015, CF-016
- M8: CF-019, CF-024, CF-025, CF-026, CF-028, CF-034 (+ RF-07, RF-10, RF-13, RF-14)
- M9: verification of all blockers, CF-034 RC/freeze/deprecation closure

Deferred to v1.1.0 (explicitly out of v1.0.0 scope): residual hot-path performance debt beyond
CF-015/M7 (TD-10), residual supply-chain reproducibility beyond M8 pinning (TD-20), and the registry
auto-discovery feature if CF-029 chooses to document it out of scope.
