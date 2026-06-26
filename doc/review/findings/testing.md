# Testing Quality Review - OraDBA v0.24.11 (Target v1.0.0)

**Review Date:** 2026-06-26 **Reviewer:** Testing Quality Agent **Source:**
doc/review/\_scans/test-coverage.md + direct suite inspection **Scope:** 48 bats files, 1,557 tests,
17 library files, 332 functions

----------------------------------------------------------------------------------------------------

## Executive Summary

The suite provides adequate structural coverage (86% function reference rate) but has three systemic
weaknesses that together represent a pre-release risk:

1. Seven of nine validator functions, eleven of twenty env-builder functions, and fourteen of
    sixteen home-discovery functions have zero test coverage. These are the path-critical functions
    invoked on every `oraenv.sh` call.
2. None of the six recent defects (b76fe9c, 5e89542, 4db7ccf, cbcb942, bbf2540, fa36489) has a
    named regression test that would have caught the original defect.
3. The happy-to-error path ratio is 13:1. The defects in this release cycle were all failure-mode
    or edge-case bugs; the suite's bias toward success paths structurally misses this class.

----------------------------------------------------------------------------------------------------

## Findings

<!-- markdownlint-disable MD013 -->

### F-001 - No regression test for dsctl log-directory fallback (b76fe9c)

**Severity:** Critical

**Evidence:** `tests/test_oradba_dsctl.bats` - no test for LOGFILE fallback path. The fix (added at
`src/bin/oradba_dsctl.sh:65-67`) guards against `/var/log/oracle` being absent. The 58-test dsctl
file contains zero assertions against the `LOGFILE` variable, log-directory existence, or `/tmp`
fallback. The 4 integration tests at lines 338-353 are all `skip`ped.

**Recommendation:** Add a hermetic test that exports `ORADBA_LOG` to a non-existent path and
executes `oradba_dsctl.sh status`, then asserts `[ "$status" -eq 0 ]` and that output does not
contain `unbound variable` or `No such file or directory`. A second variant should use a read-only
parent directory to verify the `/tmp` fallback activates cleanly.

----------------------------------------------------------------------------------------------------

### F-002 - No regression test for DataSafe stopped-status blank column (5e89542)

**Severity:** Critical

**Evidence:** `tests/test_oraup.bats` - no test exercises `oradba_get_product_status` returning exit
code 1 for a stopped connector inside the background subshell. The fix at `src/bin/oraup.sh:580`
adds `|| true` to the status-capture pipeline. The oraup tests at lines 163-167 verify only that the
function is called (grep), not that a stopped connector produces the string `"stopped"` in the
display output. `tests/test_datasafe_plugin.bats:1234-1352` tests the plugin in isolation but not
the oraup pipeline behaviour under `set -euo pipefail`.

**Recommendation:** Add a test that mocks `oradba_get_product_status` to exit 1 with stdout
`"stopped"`, invokes the DataSafe display loop from `show_oracle_status_registry`, and asserts the
output line contains `"stopped"` rather than being empty or blank. The mock must exercise the
`|| true` guard path.

----------------------------------------------------------------------------------------------------

### F-003 - No regression test for (( idx++ )) under set -e (4db7ccf)

**Severity:** Critical

**Evidence:** `tests/test_oraup.bats` - no test verifies that the DataSafe connector section is
reached when exactly one connector exists. The defect was `((idx++))` at `src/bin/oraup.sh:541`
(removed in fix) with `idx=0` as a standalone statement under `set -euo pipefail`; the arithmetic
expression evaluated to 0 (falsy) and triggered immediate exit before the display loop. The fix
commit note explicitly calls out the same root cause as fa36489. No test in the suite exercises the
DataSafe section with a single-connector fixture that would fail before the loop executes.

**Recommendation:** Add a test with a single mocked DataSafe connector that asserts the connector
name appears in `show_oracle_status_registry` output. This is the minimal scenario that would have
failed before the fix: zero entries displayed when one connector was registered.

----------------------------------------------------------------------------------------------------

### F-004 - No regression test for homes description clobbered by empty alias (cbcb942)

**Severity:** High

**Evidence:** `tests/test_oracle_homes.bats:36-51` - the test fixture `oradba_homes.conf` uses the
5-field format (`NAME:PATH:TYPE:ORDER:DESCRIPTION`) exclusively. The fix in
`src/lib/oradba_home_discovery.sh:219-226` and `:272-279` addresses a 7-field format entry where
field 5 (ALIAS_NAME) is intentionally empty (double-colon `::` in the config). No test entry
exercises this format; therefore the regression that clobbered the description field whenever
`h_alias` was empty would recur silently.

**Recommendation:** Add a fixture entry with the 7-field format and an explicitly empty alias field,
for example `DB23::/u01/app/oracle/product/23.0.0/db23:database:10::Oracle Database 23ai:23.0.0`.
Assert that `parse_oracle_home "DB23"` returns the description `"Oracle Database 23ai"` and that the
alias defaults to the home name `"DB23"`, not to the description value.

----------------------------------------------------------------------------------------------------

### F-005 - No regression test for ORACLE_BASE unbound variable in prompt_oracle_base (bbf2540)

**Severity:** High

**Evidence:** `tests/test_installer.bats` - all installer execution tests (lines 225-495) run in the
inheriting shell environment where `ORACLE_BASE` is already exported from the host. The fix at
`src/bin/oradba_install.sh:1627` guards against `ORACLE_BASE` being unset. No test unsets
`ORACLE_BASE` before invoking the installer, meaning the guard `${ORACLE_BASE:-}` is never exercised
by the suite. The bug manifested specifically in containers with `set -u`.

**Recommendation:** Add a test that invokes the built installer with
`env -u ORACLE_BASE "${PROJECT_ROOT}/dist/oradba_install.sh" --silent --no-update-profile --prefix "$TEST_INSTALL_DIR"`
and asserts `[ "$status" -eq 0 ]`. This is the exact container environment that triggered the crash
in v0.24.0.

----------------------------------------------------------------------------------------------------

### F-006 - Test itself contained (( count++ )) defect; no guard pattern enforced (fa36489)

**Severity:** Medium

**Evidence:** `tests/test_oradba_common.bats:341` - the fix replaced `(( count++ ))` with
`(( ++count ))` to avoid falsy arithmetic exit when `count=0` under bats' implicit `set -e`. The
same unguarded post-increment pattern exists in
`src/bin/oradba_logrotate.sh:207,210,252,286,323,645`,
`src/bin/oradba_dbctl.sh:566,569,575,578,585,588`,
`src/bin/oradba_lsnrctl.sh:470,473,479,482,489,492`, `src/bin/oradba_version.sh:402,423`, and
`src/bin/oradba_setup.sh:312,431`. Most are guarded by being inside `if/then` bodies, but some (e.g.
`oradba_version.sh:402` `((checked_count++))` with `checked_count=0`) are standalone statements that
will exit under `set -e` on the first iteration. No test exercises these code paths in isolation.

**Recommendation:** Add a shellcheck rule or CI linting step to flag standalone `(( var++ ))` where
`var` may be 0 on first execution. Add targeted tests for `oradba_version.sh --check-all` with a
single valid home to catch the `checked_count` case, and for the logrotate install/remove flow with
exactly one config file.

----------------------------------------------------------------------------------------------------

### F-007 - oradba_env_validator.sh: 7 of 9 functions have zero test coverage

**Severity:** Critical

**Evidence:** `doc/review/_scans/test-coverage.md:291-298` - `oradba_validate_environment`,
`oradba_validate_oracle_home`, `oradba_validate_sid`, `oradba_check_db_running`,
`oradba_check_oracle_binaries`, `oradba_get_db_status`, `oradba_get_db_version` are all marked
UNCOVERED. These functions are called at environment initialization. The validator scan coverage is
22% (2/9 functions). `tests/test_oradba_env_validator_unit.bats:89-201` tests only the DI init
functions and `oradba_validate_oracle_home`/`oradba_validate_sid` in isolation; the primary
composition function `oradba_validate_environment` is absent.

**Recommendation:** Add a `test_oradba_env_validator.bats` (distinct from the unit file) that tests
`oradba_validate_environment` with a mock Oracle home fixture, covering: valid home (exit 0),
missing `$ORACLE_HOME` (exit 1), home path exists but binaries absent (exit 1), and
`oradba_get_db_version` parsing from `sqlplus -V` mock output.

----------------------------------------------------------------------------------------------------

### F-008 - oradba_env_builder.sh: core path-construction functions untested (45% coverage)

**Severity:** Critical

**Evidence:** `doc/review/_scans/test-coverage.md:194-209` - `oradba_clean_path`,
`oradba_add_oracle_path`, `oradba_set_lib_path`, `oradba_detect_rooh`, `oradba_is_asm_instance`,
`oradba_set_oracle_vars`, `oradba_set_asm_environment`, `oradba_set_product_environment`,
`oradba_build_environment` are all UNCOVERED. `oradba_build_environment` is the top-level
composition function called for every environment switch. `tests/test_oradba_env_builder_unit.bats`
(22 tests) covers only `oradba_builder_init`, `_oradba_builder_log`, and `oradba_dedupe_path`.

**Recommendation:** Extend `test_oradba_env_builder_unit.bats` with tests for `oradba_clean_path`
(removes invalid path entries), `oradba_add_oracle_path` (deduplication), `oradba_detect_rooh`
(read-only oracle home detection via mock filesystem), `oradba_is_asm_instance` (SID prefix
detection), and a full `oradba_build_environment` integration test with a mock Oracle home tree.

----------------------------------------------------------------------------------------------------

### F-009 - oradba_home_discovery.sh: 14 of 16 functions untested (13% coverage)

**Severity:** High

**Evidence:** `doc/review/_scans/test-coverage.md:305-320` - `derive_oracle_base`,
`detect_oracle_version`, `detect_product_type`, `get_oracle_home_alias`, `get_oracle_home_path`,
`get_oracle_home_type`, `get_oracle_homes_path`, `is_bundled_component`, `is_oracle_home`,
`is_subdirectory_of_oracle_home`, `list_oracle_homes`, `parse_oracle_home`,
`resolve_oracle_home_name` are all UNCOVERED in the scan (note: `test_oracle_homes.bats` does cover
`parse_oracle_home` and `list_oracle_homes` but the scan did not attribute those calls to this
library). The functions `is_oracle_home`, `detect_product_type`, and
`is_subdirectory_of_oracle_home` have no tests at all. The cbcb942 defect lived in
`parse_oracle_home` and `list_oracle_homes`.

**Recommendation:** Add tests for `is_oracle_home` with filesystem mocks (valid DB home, valid
client home, empty directory, non-existent path), `detect_product_type` with each product structure
(already partially done in `test_oradba_common.bats:506-605` but not in the home-discovery context),
and `is_subdirectory_of_oracle_home` with nested path fixtures.

----------------------------------------------------------------------------------------------------

### F-010 - Installer --prepare -\> --install cross-validation absent

**Severity:** High

**Evidence:** `doc/review/_scans/test-coverage.md:449-456` - no test chains `--prepare` flag
processing to `--install` phase state. All installer execution tests run a single-phase invocation.
The bbf2540 defect was in the `prompt_oracle_base` function which is part of the interactive/prepare
phase; the silent-mode path bypasses it, so existing tests never reach it.

**Recommendation:** Add a two-phase test that first runs
`--prepare --prefix $DIR --no-update-profile` (non-interactive, writing state to a temp dir), then
runs `--install --prefix $DIR --no-update-profile` using the prepared state, and asserts that the
install metadata `.install_info` is consistent with the prepare phase output. Also add a test for
the prepare-phase path that exercises `prompt_oracle_base` with `ORACLE_BASE` unset and
`SILENT_MODE=false` in a heredoc-fed non-interactive context.

----------------------------------------------------------------------------------------------------

### F-011 - oradba_version_metadata.sh: 5 of 6 functions untested (17% coverage)

**Severity:** High

**Evidence:** `doc/review/_scans/test-coverage.md:354-361` - `get_oradba_version`,
`version_meets_requirement`, `get_install_info`, `set_install_info`, `init_install_info` are
UNCOVERED. Only `version_compare` is tested (2 assertions in `test_installer.bats`). These functions
are the installation state management layer; untested install-info functions mean that version
upgrade detection and metadata corruption go undetected.

**Recommendation:** Add unit tests for `get_install_info` and `set_install_info` using a temp
`.install_info` file fixture; test `init_install_info` with a clean temp directory; test
`version_meets_requirement` with boundary pairs (equal, greater, lesser, malformed).

----------------------------------------------------------------------------------------------------

### F-012 - oradba_env_output.sh: 4 of 5 functions untested, absent from testmap

**Severity:** Medium

**Evidence:** `doc/review/_scans/test-coverage.md:245-251` - `oradba_env_output_divider`,
`oradba_env_output_kv`, `oradba_env_output_resolve_oracle_base`,
`oradba_env_output_print_home_section` are UNCOVERED. Additionally `src/lib/oradba_env_output.sh`
has no entry in `.testmap.yml` at all, meaning changes to this file will not trigger any tests in
the CI smart-selection path.

**Recommendation:** Add `src/lib/oradba_env_output.sh` to `.testmap.yml` mapping to a new
`test_oradba_env_output.bats`. Tests should cover output format assertions for each function
(expected column widths, key-value alignment, Oracle Base path resolution with mock directories).

----------------------------------------------------------------------------------------------------

### F-013 - Happy-to-error ratio 13:1; systematic gap in failure-path coverage

**Severity:** Medium

**Evidence:** `doc/review/_scans/test-coverage.md:532-537` - 934 happy-path assertions vs 72
error-path assertions. The six defects in this release cycle were all triggered by: unset variables
under `-u`, arithmetic exit under `-e`, pipefail propagation, missing filesystem paths, and empty
config fields. None of these defect classes is directly exercised by happy-path tests.

**Recommendation:** Define a minimum error-path ratio target (suggested 15%) for v1.0.0. Add
negative tests for each library: missing required env var (nounset), arithmetic in loop body with
initial value 0 (exit-on-arithmetic), pipeline with non-zero exit captured via `$()` (pipefail), and
config field empty or missing. These map directly to the defect classes observed in b76fe9c,
5e89542, 4db7ccf, fa36489.

----------------------------------------------------------------------------------------------------

### F-014 - Five bin scripts have no test file and no testmap entry

**Severity:** Medium

**Evidence:** `src/bin/oradba_logrotate.sh`, `src/bin/sessionsql.sh`, `src/bin/oradba_validate.sh`,
`src/bin/oradba_datasafe_debug.sh`, `src/bin/oradba_setup.sh` - none have a corresponding `.bats`
file and none appear in `.testmap.yml`. Confirmed by `find tests/ -name "*.bats" | wc -l = 48` and
grep of testmap entries. `oradba_validate.sh` is the post-install validation script;
`oradba_setup.sh` runs post-install configuration. Both use `set -euo pipefail` and contain
`(( ext_count++ ))` patterns.

**Recommendation:** At minimum add smoke tests (shebang check, syntax check, `--help` exit 0) for
each script in a single `test_oradba_admin_scripts.bats`. Add entries for all five to
`.testmap.yml`. For `oradba_logrotate.sh` and `oradba_validate.sh`, add functional tests covering
the install and verify paths with filesystem mocks.

----------------------------------------------------------------------------------------------------

### F-015 - testmap version comment is stale (claims 65 files, 1516 tests)

**Severity:** Low

**Evidence:** `.testmap.yml:8` reads `# Test Coverage: 1516 tests across 65 test files` but the
repository contains 48 `.bats` files with 1,557 tests per the 2026-06-26 scan. The discrepancy (17
phantom files, 41 test count gap) means the testmap was not updated when the suite was reorganized
or tests were added.

**Recommendation:** Update the comment in `.testmap.yml` line 8 to reflect current counts after each
major test-addition cycle. Add a CI step to `always_run` that validates the count annotation matches
`find tests -name "*.bats" | wc -l`.

----------------------------------------------------------------------------------------------------

### F-016 - oradba_common.sh SQL/path display functions untested (6 functions, 70% coverage)

**Severity:** Medium

**Evidence:** `doc/review/_scans/test-coverage.md:147-151` - `configure_sqlpath`, `show_sqlpath`,
`show_path`, `show_config`, `add_to_sqlpath` are UNCOVERED. Additionally `alias_exists`,
`cleanup_previous_sid_config`, and `capture_sid_config_vars` are UNCOVERED. These are session-state
management functions used at every environment switch.

**Recommendation:** Add tests to `test_oradba_common.bats` for `add_to_sqlpath` (deduplication),
`configure_sqlpath` (empty vs populated SQLPATH), and `cleanup_previous_sid_config` (env var
removal). Use the existing `TEST_TEMP_DIR` pattern with mock `SQLPATH` values.

----------------------------------------------------------------------------------------------------

### F-017 - Plugin integration tests use grep-against-source as coverage proxy

**Severity:** Low

**Evidence:** `tests/test_oradba_dsctl.bats:202-228` - 7 tests assert function existence via
`grep -q "^function_name()"` against the script source rather than invoking the function.
`tests/test_oraup.bats:54-69` similarly uses `grep "db_pmon_" ... | grep -q "grep"` to test
"presence of a grep call" rather than exercising the detection logic. This pattern dominates the
dsctl and oraup test files: 34 of 58 dsctl tests and ~18 of 34 oraup tests are source-grep
assertions.

**Recommendation:** Source-grep tests are acceptable as syntax contracts but must not be the only
coverage for behavioral logic. For each grep-based test that asserts a behavior (e.g. "validates
cmctl exists"), add a companion functional test using a mock fixture that exercises the actual code
path.

----------------------------------------------------------------------------------------------------

### F-018 - test_oraup.bats has no teardown() despite ORADBA_DEBUG export

**Severity:** Low

**Evidence:** `tests/test_oraup.bats:16-22` - `setup()` does not export env vars that persist, but
test at line 191 exports `ORADBA_DEBUG=true` inside an `@test` body using bare `export` without
cleanup. In bats, each `@test` body runs in a subshell so leakage to other tests is prevented, but
the pattern is inconsistent with other test files that use `teardown()` for explicit cleanup.
`test_oradba_dsctl.bats` has a `teardown()` that cleans `TEST_DIR`; `test_oraup.bats` creates no
temp dirs but the inconsistency increases maintenance risk.

**Recommendation:** Add `teardown()` to `test_oraup.bats` that runs
`unset ORADBA_DEBUG ORAUP_SCRIPT` to make intent explicit, consistent with the patterns in other
test files.

----------------------------------------------------------------------------------------------------

## Required Regression Tests

The table below maps each recent defect to one or more named tests that MUST exist. Tests are
defined by: target function or script path, scenario description, and minimum assertion.

<!-- markdownlint-disable MD013 -->

| Defect                      | Commit  | Test Name                                                     | Target                                           | Scenario                                                                                                                   | Assertion                                                                                                 |
|-----------------------------|---------|---------------------------------------------------------------|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| dsctl log fallback          | b76fe9c | `log_directory_fallback_uses_tmp_when_var_log_oracle_missing` | `src/bin/oradba_dsctl.sh:65-67`                  | Export `ORADBA_LOG=/nonexistent/$$` and run `oradba_dsctl.sh status`                                                       | `[ "$status" -eq 0 ]`; output does not contain `No such file or directory`                                |
| dsctl log fallback          | b76fe9c | `log_directory_fallback_when_parent_not_writable`             | `src/bin/oradba_dsctl.sh:65-67`                  | Export `ORADBA_LOG` pointing to a read-only parent; run `status` action                                                    | `[ "$status" -eq 0 ]`; `LOGFILE` resolves to `/tmp/oradba_dsctl.log`                                      |
| stopped connector blank     | 5e89542 | `datasafe_stopped_connector_shows_stopped_not_blank`          | `src/bin/oraup.sh:580`                           | Mock `oradba_get_product_status` to `echo "stopped"; return 1`; invoke DataSafe display section                            | Output line for connector contains `"stopped"`, not empty                                                 |
| stopped connector blank     | 5e89542 | `datasafe_status_capture_survives_pipefail`                   | `src/bin/oraup.sh:580`                           | Same mock inside a `set -euo pipefail` subshell context                                                                    | Subshell exits 0; temp file written with status value                                                     |
| idx++ exits under set -e    | 4db7ccf | `datasafe_section_displayed_with_single_connector`            | `src/bin/oraup.sh` DataSafe loop                 | Single mocked DataSafe connector in registry; run `show_oracle_status_registry`                                            | Connector name appears in output; section is not empty                                                    |
| idx++ exits under set -e    | 4db7ccf | `no_unguarded_post_increment_in_datasafe_loop`                | `src/bin/oraup.sh`                               | Static assertion: `grep -n "^[[:space:]]*((.*++))" src/bin/oraup.sh` finds 0 matches outside if-body                       | `[ "$status" -ne 0 ]` (grep finds nothing)                                                                |
| homes description clobbered | cbcb942 | `parse_oracle_home_preserves_description_with_empty_alias`    | `src/lib/oradba_home_discovery.sh:219-226`       | Config entry `DB23:/path:database:10::Oracle DB 23ai:23.0.0`; run `parse_oracle_home "DB23"`                               | Output contains `"Oracle DB 23ai"`; alias field equals `"DB23"`                                           |
| homes description clobbered | cbcb942 | `list_oracle_homes_preserves_description_with_empty_alias`    | `src/lib/oradba_home_discovery.sh:272-279`       | Same config entry; run `list_oracle_homes`                                                                                 | Output line for `DB23` contains `"Oracle DB 23ai"` and not the version string in the description position |
| ORACLE_BASE unbound         | bbf2540 | `installer_silent_succeeds_without_oracle_base_exported`      | `src/bin/oradba_install.sh:1627`                 | Run built installer via `env -u ORACLE_BASE oradba_install.sh --silent --no-update-profile --prefix $DIR`                  | `[ "$status" -eq 0 ]`; no `unbound variable` in output                                                    |
| ORACLE_BASE unbound         | bbf2540 | `prompt_oracle_base_returns_0_when_oracle_base_unset`         | `src/bin/oradba_install.sh:1627` (function unit) | Source installer, unset `ORACLE_BASE`, call `prompt_oracle_base` with `SILENT_MODE=true`                                   | `[ "$status" -eq 0 ]`; no `nounset` error                                                                 |
| (( count++ )) in tests      | fa36489 | `no_post_increment_at_zero_in_test_suite`                     | `tests/*.bats`                                   | Static lint: `grep -Ern "\(\(.*\+\+.*\)\)" tests/*.bats` - all matches must be inside an if/then body or use pre-increment | Zero standalone `(( var++ ))` with var potentially 0 on first iteration                                   |
| (( count++ )) in tests      | fa36489 | `load_config_file_path_dedup_counts_correctly`                | `tests/test_oradba_common.bats:344`              | Re-run the PATH dedup test with initial `count=0` and pre-increment form                                                   | `[ "${count}" -eq 1 ]` passes regardless of bats subshell context                                         |

<!-- markdownlint-enable MD013 -->

----------------------------------------------------------------------------------------------------

## Coverage Gap Summary

| Library                    | Coverage    | Gap Risk                              | Priority |
|----------------------------|-------------|---------------------------------------|----------|
| oradba_env_validator.sh    | 2/9 (22%)   | Critical - init-path functions        | P1       |
| oradba_env_builder.sh      | 9/20 (45%)  | Critical - build_environment untested | P1       |
| oradba_home_discovery.sh   | 2/16 (13%)  | High - all classification logic       | P1       |
| oradba_version_metadata.sh | 1/6 (17%)   | High - install state management       | P1       |
| oradba_env_output.sh       | 1/5 (20%)   | Medium - display only, not in testmap | P2       |
| oradba_common.sh           | 26/37 (70%) | Medium - SQL path functions           | P2       |
| extensions.sh              | 15/18 (83%) | Low - display/alias creation          | P3       |
| oradba_env_config.sh       | 7/8 (88%)   | Low - SID config loader gap           | P3       |
| oradba_env_changes.sh      | 6/7 (86%)   | Low - auto-reload untested            | P3       |

**Untested bin scripts (no test file, no testmap entry):** oradba_logrotate.sh, sessionsql.sh,
oradba_validate.sh, oradba_datasafe_debug.sh, oradba_setup.sh.

<!-- markdownlint-enable MD013 -->

----------------------------------------------------------------------------------------------------

*Review format: each finding includes ID, Title, Severity, Evidence (file:line or "absent"),
Recommendation. No fabricated specifics; all evidence is directly traceable to source file line
numbers or confirmed absent by grep.*
