# Clarifications - OraDBA Roadmap to v1.0.0

**Generated:** 2026-06-26 **Updated:** 2026-06-26 (all DR and B items resolved by maintainer)
**Basis:** roadmap.md, consolidated-findings.md, technical-debt-register.md, risk-register.md, and
the domain findings (testing.md, release.md) **Purpose:** capture only genuine human-input items -
assumptions, blockers, dependencies, and DECISION-REQUIRED items. Everything resolvable by
repository analysis has been resolved in the roadmap and is not listed here.

----------------------------------------------------------------------------------------------------

## Roadmap supersession note

`doc/review/roadmap.md` REPLACES `.claude/review-plan.md`. The old plan (dated 2026-03-10, status
"Complete 2026-03-25") is now historical context only. Its deferred items (lazy-loading,
error-message standardisation, install/extension shared helper, the five untested bin scripts, the
auto-generated extensions catalog) are folded into the milestones and traced to CF IDs. The roadmap
is the single source of truth for the path from v0.24.11 to v1.0.0.

----------------------------------------------------------------------------------------------------

## Decisions already made (recorded, not re-opened)

- **DECISION 1 (CF-017):** Option A - complete the migration so `oraenv.sh` delegates to
  `oradba_build_environment` and retire the inline environment-building logic in `oradba_common.sh`.
  L-effort; scheduled as M6 with comprehensive testing (M3) as a hard prerequisite. The earlier
  "DECISION-REQUIRED" framing in consolidated-findings.md item 1 is resolved by this decision.
- **DECISION 2 (CF-004 vs CF-016/P-06):** Option B - tiered plugin isolation.
  `execute_plugin_function_v2` is mandatory for state-changing/risky plugin calls
  (`plugin_detect_installation`, `plugin_check_status`, `plugin_check_listener_status`). Direct
  in-parent calls are allowed only for audited, side-effect-free path-builders (`build_bin_path`,
  `build_lib_path`). The audited exception list must be documented in M4. The earlier
  "DECISION-REQUIRED" framing in consolidated-findings.md item 2 is resolved by this decision.

----------------------------------------------------------------------------------------------------

## DECISION-REQUIRED (all resolved 2026-06-26)

### DR-1 - Audited pure path-builder exception list completeness (RESOLVED)

**Resolution:** Exception list is exactly `build_bin_path` and `build_lib_path` only. `odb_datasafe`
does not need classification - it does not call oradba plugin libs directly; it uses `oraenv.sh` for
environment setup and calls oradba scripts like `oradba_dsctl.sh`. No downstream consumer functions
need direct-call classification. The M4 implementer must not extend this list without a new human
decision.

### DR-2 - Registry auto-discovery: implement or document out of scope (RESOLVED)

**Resolution:** Implement `oradba_registry_discover_all`. It is in scope for v1.0.0. Scheduled as
task 3 of M5. The roadmap has been updated accordingly.

### DR-3 - Deprecation of plaintext dbca password flags (RESOLVED)

**Resolution:** Do NOT deprecate `--sys-password`/`--system-password`. DBCA actively uses these
flags and they cannot be removed at v1.0.0. M2 task 4 secures their credential handling (response
file via exclusive mktemp, chmod 600, EXIT-trap shred, no logging) without any API change. No
`--sys-password-stdin` alternative is added. The API freeze in M9 retains both flags as-is.

----------------------------------------------------------------------------------------------------

## Assumptions (resolved by analysis; flagged for confirmation)

### A-1 - The `--prepare` to `--install` contract (carried from architecture review)

The test-coverage scan (F-010) assumes oradba's installer has a `--prepare` -\> `--install`
two-phase contract. Repository analysis shows `oradba_install.sh` actually uses `INSTALL_MODE` =
embedded/local/github; the only `--prepare`/ `--install` references are in
`doc/releases/v0.24.11.md:72-74` describing the downstream `odb_datasafe` connector lifecycle, not
oradba itself. **Assumption used in the roadmap:** oradba does NOT provide a generic prepare/install
two-phase contract, so the F-010 cross-validation test target does not exist and is dropped from M3.
The bbf2540 regression is instead covered by the single-phase
`installer_silent_succeeds_without_oracle_base_exported` and
`prompt_oracle_base_returns_0_when_oracle_base_unset` tests. Confirm this is correct before writing
M3 tests, otherwise the prepare/install contract must be specified first.

### A-2 - Security severity assumptions (carried from security review)

The roadmap treats these as stated; confirm or downgrade:

- CF-006 (SEC-03/04) severity assumes releases are not yet signed and the `.sha256` is not verified
  in the documented flow. If a verification step exists outside the reviewed files, downgrade CF-006
  and relax the M2 fail-closed requirement.
- CF-022 (SEC-06) exploitability assumes `/etc/oratab` and `oradba_homes.conf` can be group-writable
  in some supported configs. If both are strictly root/oracle-owned and never group-writable in
  supported deployments, practical severity is lower (M2 still applies the allowlist as
  defence-in-depth).
- CF-002 (SEC-01) severity assumes a common 022/027 umask. The finding stands regardless because the
  script sets no explicit restrictive permission; M2 fixes it unconditionally.

### A-3 - Coverage-target percentages are policy, not measured (M3)

The M3 targets (validator \>= 80%, env-builder \>= 80%, home-discovery \>= 70%, version-metadata \>=
80%, error-path ratio \>= 15%) are adopted from the testing review's recommendations as policy
thresholds. Confirm these specific numbers are acceptable as v1.0.0 gates; they are the bar the
readiness checklist enforces.

### A-4 - One minor release per milestone and the v0.25.0..v0.32.0 numbering

The roadmap assigns one minor version per milestone (v0.25.0 through v0.32.0, then v1.0.0-rc.1 and
v1.0.0). This is a deliberate replacement of the prior same-day patch cadence (RF-01). Confirm the
team wants discrete tagged minors per milestone rather than batching several milestones into one
release.

----------------------------------------------------------------------------------------------------

## Blockers and external dependencies (all resolved 2026-06-26)

### B-1 - Oracle AI Database 26ai Docker image availability (RESOLVED)

**Resolution:** Use `container-registry.oracle.com/database/free:latest`. This is the canonical
image reference. M8 CF-025 task updates `tests/run_docker_tests.sh` and all test documentation to
reference this tag. M9 final integration run uses this image. Digest pinning (CF-028/RISK-18) is
addressed in M8 task 5 for supply-chain hardening; `free:latest` is the confirmed tag reference for
test documentation.

### B-2 - Schedule placeholders (RESOLVED)

**Resolution:** No fixed target date. Milestones are driven by a /loop (automated
milestone-by-milestone execution), starting with M1 as soon as possible. Duration placeholders
(TBD-1..TBD-9) remain in the roadmap as estimates once each milestone's scope is implemented. The
30-day RC soak remains fixed by policy.

### B-3 - Downstream consumer coordination (RESOLVED)

**Resolution:** One release of deprecation aliases is sufficient. Both `odb_datasafe` and
`exatoolbox` consumers are covered by the single-release alias window introduced in M5. No extended
deprecation window is required.

----------------------------------------------------------------------------------------------------

## New questions surfaced during milestone planning

### Q-1 - Implementer/verifier agents do not yet exist

The roadmap's automation design references `implement-milestone` (opus) and `verify-milestone`
(sonnet) agents. The current `.claude/agents/` set is review-only (scan-*, review-*, consolidate,
roadmap). Milestones will be driven via /loop using the existing Claude Code session. Agent
authoring is a follow-up action post-REVIEW.md.

### Q-2 - `make validate-docs-counts` and the testmap-count CI check are new targets (ASSUMED YES)

M8 introduces `make validate-docs-counts` and a CI step matching the testmap annotation to
`find tests -name '*.bats' | wc -l`. These do not exist yet. Roadmap assumes they are added in M8 as
the automated control keeping CF-025 clean.

### Q-3 - `--offline` build mode and extension-template pinning approach (M8) (ASSUMED: .version file)

RF-10/CF-028: roadmap assumes the pinned `templates/oradba_extension/.version` file approach plus an
`--offline` flag on `build_installer.sh`. To be confirmed when M8 begins if a different mechanism is
preferred.

### Q-4 - DB open-mode canonical vocabulary (RESOLVED)

**Resolution:** Confirmed. Canonical vocabulary is {OPEN, MOUNTED, NOMOUNT, STARTED, SHUTDOWN}. All
three existing implementations will converge to this set in M6. Callers (validator, db_functions,
env_status) and any downstream consumer are frozen against this vocabulary at v1.0.0.
