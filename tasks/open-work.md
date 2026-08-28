# Open Work - oradba

> The single checkbox file for this repo. Execution lives here; `~/notes/projects/oradba.md`
> keeps only the coordination view. Status syntax: `[ ]` open, `[-]` in progress, `[x]` done.

Stand: 2026-08-28 (Session "Boot-Pfad-Gates schliessen", v1.0.5)

## Done in this session

- [x] `make test-full` reported green without running a single test on any fresh
      checkout (`tests/results` untracked -> bats aborts -> grep on the missing
      report leaves `$failures` empty -> `[ "" -gt 0 ]` errors -> falls through).
      This is why seven failing tests reached three tags.
- [x] Release workflow: independent post-test gate that re-derives the verdict
      from the written TAP report, so a future Makefile change cannot pass silently
- [x] CI: `tests` and `scripts` path filters widened to cover `src/etc/**`.
      v1.0.4 changed only `src/etc/` and therefore ran neither lint nor tests.
- [x] CI test job runs the full suite instead of smart selection
- [x] `tests/test_boot_path.bats`: 11 tests, models the `su - oracle -c` boot with
      an empty environment. Red against v1.0.0 (6 of 11), green after the fixes.
- [x] Defect 7: `oradba_standard.conf:71` expanded a bare `$ORACLE_HOME` inside a
      default value (`${RLWRAP_OPTS:--i -c -f $ORACLE_HOME/bin/sqlplus}`)
- [x] Defect 8: four guards tested for the *file* `oradba_common.sh` while calling
      functions from `oradba_database_discovery.sh` -> `command -v` instead
- [x] Defect 9: `standard.conf` never sourced its own documented prerequisite, so
      the first of 77 `safe_alias` calls aborted the boot
- [x] Defect 10: `generate_sid_lists` returns 1 when there is no oratab; under
      `set -e` that advisory return aborted the whole config
- [x] Defect 11: the SID-derived admin/diagnostic block expanded `${ORACLE_SID}`
      bare; guarded as a block rather than inventing `${ORACLE_BASE}/admin/`
- [x] M5: non-TTY stdin without `--force` now fails naming the flag, in all three
      scripts that carry the pattern (dbctl, dsctl, lsnrctl)
- [x] M1: `--profile-user` resolves the target home via `getent`, plus
      `set_prefix_ownership` for the sudo/become case (also covers M7's
      root-owned `/var/log/oracle`)
- [x] `--update` silently dropped user `sid.*.conf` files; now preserved, with
      `sid._DEFAULT_.conf` excluded so the payload still wins for the shipped one
- [x] All seven long-standing test failures triaged and resolved

## Open - next session

- [ ] **M6 / asset decision**: is oradba the canonical home for dbca-rsp, sqlnet,
      systemd units, AutoUpgrade cfg and verification SQL? Couples to E2 in
      `~/notes/areas/oci-labs.md`. Deliberately untouched - must not be decided
      alongside bugfixes [P2]
- [ ] **Phase 0 repo boundaries**: which repos stay separate, what gets merged.
      Own decision round [P3]

### Found by the release gate on its first run

- [x] `oradba_help.sh`: five unguarded `${ORADBA_BASE}` references under
      `set -u`. Fixed. The local suite had passed only because the developer
      shell exports 71 `ORADBA_*` variables.
- [x] `oradba_homes.sh`: `add`/`remove` completed successfully and exited 1,
      because `generate_sid_lists` returns non-zero without an oratab. Fixed at
      both call sites. Same defect as in `oradba_standard.conf` - when a
      function's return code is reinterpreted, grep every caller.
- [x] `make format-check` reported failure and success simultaneously and exited
      0. Fixed; it now names the files and fails.
- [x] The release workflow did not install `shfmt`, so `make lint` failed there
      once the formatting gate was part of it. Fixed, and all three workflows
      that call `make lint` were audited rather than just the failing one.
- [x] `make lint` did not run the shfmt check the workflow enforces. The file
      list now lives in the Makefile as `SHFMT_SCOPE`, the workflow calls
      `make format-check-scope`, and `lint` includes it.

### Found during this session, not fixed

- [ ] `ORADBA_CACHED_PS` is dead: `oraup.sh:589` builds and exports a process
      list that **no reader anywhere in `src/` consumes**. `443fc0c` replaced the
      ps-based detection with a port-based check and left the producer behind.
      Removing it touches `oraup.sh` parallel-status logic - do it deliberately,
      with a test, not in a patch release [P3]
- [ ] The test suite is **not safe to run concurrently**. `test_installer.bats`
      calls `scripts/build_installer.sh`, which writes the shared
      `build/tar_staging`; a parallel build or a second suite run corrupts both.
      Two runs were invalidated this way before the cause was found. Either give
      the build a per-run staging dir or serialise it explicitly [P2]
- [ ] Log-directory fallback is inconsistent (M7): `oradba_dsctl.sh` and
      `oradba_rman.sh` fall back to `/tmp` when the log dir is unwritable;
      `oradba_services.sh`, `oradba_lsnrctl.sh` and `oradba_dbctl.sh` do not, and
      `oradba_services_root.sh:30` hardcodes `/var/log/oracle` with no override
      at all. Decide one behaviour and apply it to all six [P2]
- [ ] `oradba_version.sh` pads output with spaces for column alignment
      (`Version:       1.0.4`), which conflicts with the no-alignment-padding
      convention. Cosmetic, but it is generated output [P3]
- [ ] Formatting debt outside the CI scope: `make format-check` (the wide
      variant) names six files that need `shfmt` - `oradba_env_config.sh`,
      `oradba_aliases.sh`, `oradba_registry.sh`, `archive_github_releases.sh`,
      `validate_test_environment.sh`, `validate_project.sh`. Mechanical to fix
      with `make format`, but it touches files the suite covers, so it wants its
      own verified change. Until then `SHFMT_SCOPE` stays narrower than the
      repo [P3]
- [ ] Three tests pass or fail depending on whether the runner is root:
      `persist_discovered_instances handles permission denied gracefully`,
      `log_directory_fallback_uses_tmp_when_var_log_oracle_missing` and
      `oradba_rman.sh accepts --parallel gnu` fail as root (root can write
      anywhere, so the negative case never triggers). They should skip with a
      reason when running as root instead of failing [P3]
- [ ] The local test suite runs against a leaked environment: 71 `ORADBA_*` and
      `ORACLE_*` variables from the developer's own installation, plus a
      populated `/etc/oratab`. That is what hid the two defects above. Consider a
      `make test-clean` that runs the suite under `env -i` with only what a
      clean host provides [P2]
- [ ] `src/etc/sid._DEFAULT_.conf:20,22` expand `${ORACLE_SID}` bare. Only
      sourced once a SID is known, so not a live defect - but the only remaining
      instance of the pattern in `src/etc/` [P3]
- [ ] `oradba_aliases.sh:208,209` give `sq` and `sqh` an identical definition.
      Matches `oradba_standard.conf` convention (both sysdba), so intentional -
      confirm and document, or differentiate [P3]

### Carried over from the PKM

- [ ] Docker multi-platform builds for 19c and 26ai, plus CI [P3]
- [ ] Decide: keep base `oradba` lean, move value-add templates to their own
      extension [P2]
- [ ] Test strategy: unit / integration / E2E boundaries [P3]
- [ ] Documentation standard (README, CHANGELOG, mkdocs) [P3]
- [ ] `oradba_backup_report.sh` - full spec exists in
      `tasks/oradba_backup_report_spec.md`, nothing implemented yet [P3]
