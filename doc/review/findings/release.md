# Release Engineering Review Findings - OraDBA v0.24.11

**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-opus-4-8) **Scope:** versioning
maturity, build reproducibility, CI pipeline, CHANGELOG discipline, v1.0.0 readiness criteria
**Target:** v1.0.0

----------------------------------------------------------------------------------------------------

## Current vs Target Quality-Gate Comparison

| Gate                     | Current State                                                         | v1.0.0 Target                                                 |
|--------------------------|-----------------------------------------------------------------------|---------------------------------------------------------------|
| Versioning               | Single source (VERSION file), no tag/VERSION parity check in pipeline | VERSION == git tag enforced; no `__VERSION__` stubs in source |
| shellcheck               | Pinned v0.10.0 in CI; unpinned `apt` in release.yml                   | Pinned everywhere, `-S error` severity                        |
| shfmt -d                 | Defined in Makefile (`format-check`); absent from CI and release.yml  | Enforced in CI lint job                                       |
| bats (unit)              | 48 test files; smart-select in CI; full suite in release              | Smart select merged with full suite gate before tag           |
| Docker integration tests | Manual-trigger only (`workflow_dispatch`)                             | Automated on every PR or nightly; required for release        |
| CHANGELOG discipline     | Present, well-structured; `[Unreleased]` empty at release             | `[Unreleased]` populated before each release commit           |
| Release notes files      | Inconsistent - v0.24.4 and v0.24.5 missing                            | Required for every release; pipeline fails if absent          |
| VERSION/tag parity check | Informational echo only - no assertion                                | \`\[ "$`(cat VERSION)" = "`$TAG_VERSION" \]                   |
| Pre-release (RC) phase   | None - fix shipped directly as release                                | RC tag + stabilisation window before major versions           |

----------------------------------------------------------------------------------------------------

## Critical Findings

### RF-01 - Rapid same-day patch cadence signals insufficient pre-release validation gate

**Severity:** Critical **Evidence:** `git log` - v0.24.7 through v0.24.11 all tagged 2026-06-25;
v0.24.1 through v0.24.3 all tagged 2026-04-27; v0.24.4 exists in CHANGELOG but has no tag (skipped);
v0.24.5 has a tag but no release notes file (`doc/releases/v0.24.5.md` absent); five consecutive
same-day fixes each required a separate release.

The commit-tag-release loop provides no stabilisation window. Each shipped fix triggers CI but
Docker integration tests are not part of the automated gate.

**Recommendation (analysis only):** Before tagging any release, require a passing full bats run plus
a manual or scheduled Docker integration run. For v1.0.0: introduce a freeze period and RC tag
(e.g., `v1.0.0-rc.1`) with at least one week before promotion to final, enforced by a branch
protection rule that rejects direct tag promotion on `main` without a signed-off RC.

----------------------------------------------------------------------------------------------------

### RF-02 - Release pipeline does not assert VERSION file matches the pushed git tag

**Severity:** Critical **File:** `.github/workflows/release.yml:43-46`

The "Verify VERSION file" step consists of two `echo` statements only; no comparison or `exit 1`. A
tag `v0.24.11` pushed while `VERSION` still contains `0.24.10` would produce a release where the
installer self-reports the wrong version. The build derives its embedded version string from
`VERSION` (`scripts/build_installer.sh:26`), not from the git tag.

**Recommendation (analysis only):** Replace the informational echo with an assertion:

``` bash
[ "$(cat VERSION)" = "${GITHUB_REF#refs/tags/v}" ] || { echo "VERSION file mismatch"; exit 1; }
```

This must run before the build step. Also add the same check to `make release-check`
(`Makefile:609-630`).

----------------------------------------------------------------------------------------------------

## High Findings

### RF-03 - Docker integration tests are manual-only and excluded from the release gate

**Severity:** High **File:** `.github/workflows/docker-tests.yml:6-8`

`on: workflow_dispatch` only. The release workflow (`release.yml`) runs `make lint` and
`make test-full` but does not trigger or reference `docker-tests.yml`. End-to-end installer
validation against a real Oracle container is not part of any automated release gate. The CI
`validate` job (`ci.yml:180-214`) runs `oradba_install.sh --prefix /tmp/oradba-test` on Ubuntu but
this is not an Oracle container and does not exercise `oraenv.sh`, \`oradba_homes.sh , or plugin
discovery.

**Recommendation (analysis only):** Add a scheduled nightly run (`on: schedule`) to
`docker-tests.yml` and wire a successful recent run as a required status check before release tags
are accepted. For v1.0.0 specifically, require a documented passing Docker integration run as a
manual release-checklist item.

----------------------------------------------------------------------------------------------------

### RF-04 - shfmt format check absent from CI and release pipeline

**Severity:** High **Files:** `Makefile:267-277`, `.github/workflows/ci.yml`,
`.github/workflows/release.yml`

`Makefile:267-277` defines `format-check` using `shfmt -d`. `shfmt` is absent from `ci.yml` and
`release.yml`. The `make lint` called from `release.yml:57` only invokes
`lint-shell lint-scripts lint-markdown` (`Makefile:218`), none of which call `format-check`.

**Recommendation (analysis only):** Add a `format-check` step to the `lint` job in `ci.yml` and
include it in the `make lint` aggregate target. Pin the `shfmt` binary (same pattern as shellcheck
in `ci.yml:79-83`).

----------------------------------------------------------------------------------------------------

### RF-05 - shellcheck uses unpinned apt package in release workflow while CI pins v0.10.0

**Severity:** High **Files:** `ci.yml:79-83`, `release.yml:51`

`ci.yml` installs shellcheck v0.10.0 via a pinned GitHub releases download. `release.yml` uses
`sudo apt-get install -y bats shellcheck` with no version pin. A different shellcheck version in the
release job creates inconsistency.

**Recommendation (analysis only):** Duplicate the pinned install pattern from `ci.yml:79-83` into
`release.yml`. Use `SHELLCHECK_VERSION` env var set to `0.10.0` in both jobs.

----------------------------------------------------------------------------------------------------

### RF-06 - Release notes files absent for tagged versions v0.24.4 (no tag) and v0.24.5

**Severity:** High **Evidence:** `doc/releases/v0.24.5.md` does not exist. `v0.24.4` appears in
`CHANGELOG.md` but has no git tag (`git tag | grep v0.24.4` returns empty).
`doc/releases/v0.24.4.md` exists without a tag - an orphaned release note. The release pipeline uses
`doc/releases/v${VERSION}.md` as the GitHub release body but silently falls back to generic notes
when the file is absent (`release.yml:91-95`).

**Recommendation (analysis only):** Change the `else` branch in `release.yml:95` to `exit 1` when
the release notes file is absent. Add a `release-notes` prerequisite to `release-check` in the
Makefile. Retroactively create `doc/releases/v0.24.5.md` and resolve the `v0.24.4` tag/note orphan.

----------------------------------------------------------------------------------------------------

## Medium Findings

### RF-07 - build_installer.sh uses `set -e` only, missing `-u` and `-o pipefail`

**Severity:** Medium **File:** `scripts/build_installer.sh:19`

`set -e` only. Project convention and 25 of 31 src scripts require `set -euo pipefail`. An unbound
variable or failed pipeline step would silently continue, potentially producing a corrupt installer.

**Recommendation (analysis only):** Replace `set -e` with `set -euo pipefail` at line 19.

----------------------------------------------------------------------------------------------------

### RF-08 - Per-script revision headers frozen at v0.21.0 while repo is at v0.24.11

**Severity:** Medium **Files:** `src/bin/oraenv.sh:9` (shows `Revision...: 0.21.0`),
`src/bin/oradba_env.sh:23` (shows `SCRIPT_VERSION="1.0.0"`), `Makefile:9` (shows
`Revision...: 0.21.0`)

Per-file version strings are not updated by the build pipeline. Consumers running
`oradba_version.sh --verify` or reading script headers get misleading metadata.

**Recommendation (analysis only):** Either (a) automate header version injection during build using
the same `sed` pattern used for `__VERSION__` substitution in the installer, or (b) adopt a single
runtime version source (`VERSION` file) and remove per-file revision fields from headers. Option (b)
is consistent with how `oradba_version.sh` already works.

----------------------------------------------------------------------------------------------------

### RF-09 - CHANGELOG v0.24.4 entry exists but v0.24.4 was never tagged

**Severity:** Medium **Evidence:** `CHANGELOG.md` contains `## [0.24.4] - 2026-05-02`.
`git tag | grep v0.24.4` returns empty. `doc/releases/v0.24.4.md` exists. Users who attempt
`oradba_install.sh --github --version 0.24.4` would get a download failure.

**Recommendation (analysis only):** Either publish the tag retroactively or add a note that v0.24.4
was superseded by v0.24.5 before tagging. Add a `release-check` step verifying the CHANGELOG
top-most versioned section matches `VERSION` and no untagged versioned section precedes it.

----------------------------------------------------------------------------------------------------

### RF-10 - Extension template download during build is network-dependent and non-reproducible

**Severity:** Medium **File:** `scripts/build_installer.sh:82-156`

The build unconditionally queries the GitHub API for `oehrlis/oradba_extension` latest release and
downloads the template tarball at build time if the cached version differs. Build reproducibility
depends on network availability, the external repo, and GitHub API rate limits. A failed download
produces a `Warning` and continues, silently omitting the extension template from the installer.

**Recommendation (analysis only):** Commit the extension template checksum (not the binary) and
verify the cached tarball against it. Add `--offline` mode to `build_installer.sh` that skips the
download and uses the local cache unconditionally. For CI, pin the cached template version via a
`templates/oradba_extension/.version` file tracked in git.

----------------------------------------------------------------------------------------------------

### RF-11 - `make test-full` treats exit code 1 (bats skip) as success, masking real failures

**Severity:** Medium **File:** `Makefile:138-151`

`test-full` explicitly catches `test_exit=1` and treats it as success with message "Tests completed
with skipped tests (exit code 1 is normal with conditional skips)". bats uses exit 1 for both
skipped tests AND actual failures. A test suite with one failing test and any skipped tests returns
exit 1 and is incorrectly treated as a pass.

**Recommendation (analysis only):** Run `bats --report-formatter tap` and parse the TAP output to
distinguish failed tests from skipped tests. Do not suppress exit code 1 wholesale.

----------------------------------------------------------------------------------------------------

### RF-12 - v0.20.0 introduced breaking flag renames with no runtime deprecation warnings

**Severity:** Medium **Evidence:** `CHANGELOG.md:1100-1113` (`## [0.20.0]`) documents
`ORADBA_AUTO_DISCOVER_HOMES` renamed to `ORADBA_AUTO_DISCOVER_ORATAB` and `ORADBA_FULL_DISCOVERY`
renamed to `ORADBA_AUTO_DISCOVER_PRODUCTS` as BREAKING changes. No runtime deprecation warning was
added for the old variables.

**Recommendation (analysis only):** Before v1.0.0, audit all breaking changes since v0.19.0 and
ensure each has a corresponding runtime warning when the old variable/flag is used. Define the
v1.0.0 stability contract: any variable or flag present in v1.0.0 must be retained through at least
v2.0.0, with explicit deprecation warnings.

----------------------------------------------------------------------------------------------------

## Low Findings

### RF-13 - No project quality gate in git pre-commit hook

**Severity:** Low **Evidence:** `.git/hooks/pre-commit` is the Accenture `acn-security-tools`
scanner only. `make pre-commit` (`Makefile:598`) and `make pre-push` (`Makefile:602`) exist as
developer shortcuts but are not wired to git hooks.

**Recommendation (analysis only):** Add a thin `pre-push` git hook that runs `make lint` at minimum.
Check it in as `.githooks/pre-push` with a setup step in `make setup-dev` that runs
`git config core.hooksPath .githooks`.

----------------------------------------------------------------------------------------------------

### RF-14 - No v1.0.0 readiness definition document exists

**Severity:** Low **Evidence:** `CHANGELOG.md:1047` references "Phase 5: Cleanup, Documentation, and
v1.0.0 Baseline" and the plugin interface is declared baseline, but no document defines what "v1.0.0
stable" means for the full project (API freeze scope, backward-compatibility contract, supported
Oracle versions, deprecation policy).

**Recommendation (analysis only):** Create `doc/v1.0.0-readiness.md` enumerating explicit v1.0.0
criteria: (a) public API surface frozen, (b) no breaking changes from v0.24.x, (c) Docker
integration tests pass on Oracle 19c and 26ai Free, (d) all RF-01 through RF-06 findings resolved,
(e) minimum soak period since the last Critical or High severity fix.

----------------------------------------------------------------------------------------------------

## Summary Table

| ID    | Severity | Title                                                                    |
|-------|----------|--------------------------------------------------------------------------|
| RF-01 | Critical | Same-day patch cadence - no stabilisation gate                           |
| RF-02 | Critical | Release pipeline does not assert VERSION matches tag                     |
| RF-03 | High     | Docker integration tests excluded from release gate                      |
| RF-04 | High     | shfmt format-check absent from CI and release                            |
| RF-05 | High     | shellcheck unpinned in release.yml vs. pinned in ci.yml                  |
| RF-06 | High     | Release notes absent for v0.24.5; v0.24.4 tag never pushed               |
| RF-07 | Medium   | build_installer.sh missing `-u -o pipefail`                              |
| RF-08 | Medium   | Per-script revision headers frozen at v0.21.0                            |
| RF-09 | Medium   | CHANGELOG v0.24.4 entry has no matching git tag                          |
| RF-10 | Medium   | Extension template download is network-dependent; non-reproducible build |
| RF-11 | Medium   | make test-full silently passes when bats returns exit 1 for failures     |
| RF-12 | Medium   | Breaking renames in v0.20.0 shipped without runtime deprecation warnings |
| RF-13 | Low      | No project quality gate in git pre-commit hook                           |
| RF-14 | Low      | v1.0.0 readiness criteria undefined                                      |
