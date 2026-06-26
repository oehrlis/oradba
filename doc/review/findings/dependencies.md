# Dependency Review - OraDBA v0.24.11

**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-sonnet-4-6) **Scope:** runtime and
build dependencies, validation completeness, portability, supply-chain

----------------------------------------------------------------------------------------------------

## 1. Dependency Table

<!-- markdownlint-disable MD013 -->

| Name                                               | Where Used                                                                                                                                               | Required-Version Assumption                            | Validated (y/n)                                                                                | Risk   |
|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------|------------------------------------------------------------------------------------------------|--------|
| bash                                               | all scripts, shebang                                                                                                                                     | 4.0+ (CONTRIBUTING.md:117; mapfile/declare -A/,, used) | n - no runtime check in any script                                                             | High   |
| tar                                                | oradba_check.sh, oradba_install.sh                                                                                                                       | POSIX-compatible                                       | y - check_system_tools()                                                                       | Low    |
| awk                                                | oradba_check.sh, oradba_install.sh, oradba_homes.sh, build_installer.sh, oradba_version.sh                                                               | POSIX awk                                              | y - check_system_tools()                                                                       | Low    |
| sed                                                | oradba_check.sh, oradba_install.sh, oradba_homes.sh, oradba_sqlnet.sh, oradba_extension.sh, build_installer.sh, build_pdf.sh, oradba_version_metadata.sh | GNU sed assumed in oradba_dbca.sh (df -BG)             | y - check_system_tools()                                                                       | Medium |
| grep                                               | oradba_check.sh, oradba_install.sh, oradba_version.sh, oradba_dbctl.sh, oradba_dsctl.sh                                                                  | POSIX + -E flag                                        | y - check_system_tools()                                                                       | Low    |
| find                                               | oradba_check.sh, build_installer.sh                                                                                                                      | POSIX find                                             | y - check_system_tools()                                                                       | Low    |
| sort                                               | oradba_check.sh, build_installer.sh                                                                                                                      | POSIX sort                                             | y - check_system_tools()                                                                       | Low    |
| sha256sum                                          | build_installer.sh (line 287), oradba_version.sh (lines 164/414/535), oradba_extension.sh (line 619)                                                     | GNU coreutils sha256sum                                | y in oradba_check.sh and oradba_install.sh; **n in oradba_version.sh and oradba_extension.sh** | High   |
| shasum                                             | oradba_check.sh, oradba_install.sh, oradba_validate.sh                                                                                                   | BSD shasum -a 256                                      | y as fallback in check/install/validate; absent in version/extension                           | High   |
| base64                                             | oradba_install.sh (line 1571, --decode flag), get_seps_pwd.sh (line 186, -d flag), build_installer.sh (line 262, openssl base64)                         | --decode flag (GNU/macOS compatible); -d same          | y in oradba_check.sh (as optional warning)                                                     | Medium |
| openssl                                            | build_installer.sh (line 262, base64 encoding payload)                                                                                                   | openssl base64 subcommand                              | n - not checked before use                                                                     | Medium |
| df                                                 | oradba_check.sh (line 535, -Pm), oradba_install.sh (line 687, -Pm), oradba_dbca.sh (line 245, -BG)                                                       | -Pm POSIX; **-BG GNU-only**                            | y in check/install; n in oradba_dbca.sh                                                        | Medium |
| curl                                               | oradba_check.sh, oradba_install.sh (github mode), oradba_version.sh (line 570), oradba_extension.sh, build_installer.sh                                  | \-                                                     | y - checked before use with curl/wget fallback                                                 | Low    |
| wget                                               | oradba_check.sh, oradba_install.sh (github fallback), oradba_extension.sh                                                                                | \-                                                     | y - checked as curl fallback                                                                   | Low    |
| pgrep                                              | oradba_check.sh (line 698-699)                                                                                                                           | POSIX pgrep                                            | n - not checked before use                                                                     | Low    |
| timeout                                            | oradba_check.sh (line 704), oradba_dbctl.sh (line 345)                                                                                                   | GNU coreutils timeout                                  | n - not checked before use                                                                     | Medium |
| rsync                                              | sync_to_peers.sh (line 266), sync_from_peers.sh                                                                                                          | \-                                                     | n - never validated before use                                                                 | Medium |
| realpath                                           | sync_to_peers.sh (line 239)                                                                                                                              | GNU coreutils realpath                                 | n - not on macOS without coreutils; sync_from_peers.sh has fallback, sync_to_peers.sh does not | Medium |
| parallel                                           | oradba_rman.sh (line 231, optional)                                                                                                                      | GNU parallel                                           | y - checked with fallback to background jobs                                                   | Low    |
| mail / sendmail                                    | oradba_rman.sh (lines 908/911)                                                                                                                           | \-                                                     | y - checked with fallback                                                                      | Low    |
| rlwrap                                             | oradba_check.sh                                                                                                                                          | \-                                                     | y - optional warning only                                                                      | Low    |
| less                                               | oradba_check.sh                                                                                                                                          | \-                                                     | y - optional warning only                                                                      | Low    |
| sqlplus                                            | oradba_dbctl.sh (line 221+), oradba_check.sh (line 704), oradba_rman.sh                                                                                  | Oracle Database Client                                 | **n in oradba_dbctl.sh** - no command -v check before invocation                               | High   |
| rman                                               | oradba_rman.sh (line 721)                                                                                                                                | Oracle Database                                        | n - path constructed from ORACLE_HOME/bin/rman; binary existence not validated                 | High   |
| lsnrctl                                            | oradba_lsnrctl.sh (line 296/308)                                                                                                                         | Oracle Listener                                        | n - no command -v or -x check before invocation                                                | High   |
| dbca                                               | oradba_dbca.sh (line 223)                                                                                                                                | Oracle Database                                        | y - existence check at line 223 (-x flag)                                                      | Low    |
| cmctl                                              | datasafe_plugin.sh (lines 158/219), oradba_datasafe_debug.sh (line 223)                                                                                  | Oracle Data Safe / CMAN                                | y - -x check in plugin; y in debug script                                                      | Low    |
| mkstore                                            | get_seps_pwd.sh (lines 116/210)                                                                                                                          | Oracle Client                                          | y - command -v check at line 169                                                               | Low    |
| tnsping                                            | oradba_check.sh (optional check)                                                                                                                         | Oracle Client                                          | y - informational only, warns if missing                                                       | Low    |
| rsync                                              | sync_to_peers.sh, sync_from_peers.sh                                                                                                                     | \-                                                     | n                                                                                              | Medium |
| docker                                             | build_pdf.sh (line 194), CI workflows                                                                                                                    | Docker Engine                                          | y in build_pdf.sh check_dependencies()                                                         | Low    |
| git                                                | scripts/select_tests.sh, validate_test_environment.sh, sync_extension_docs.py                                                                            | git                                                    | y - checked before use in select_tests.sh                                                      | Low    |
| python3                                            | .github/scripts/sync_extension_docs.py                                                                                                                   | Python 3.x                                             | n - not checked                                                                                | Low    |
| pip packages                                       | docs.yml (mkdocs-material, pymdown-extensions, pyyaml)                                                                                                   | latest (unpinned)                                      | n - no version pins                                                                            | Medium |
| oehrlis/pandoc:latest-full                         | ci.yml (line 251), release.yml (line 69)                                                                                                                 | latest-full tag mutable                                | n - mutable tag                                                                                | Medium |
| container-registry.oracle.com/database/free:latest | docker-tests.yml (line 36)                                                                                                                               | latest mutable                                         | n - mutable tag                                                                                | Medium |
| shellcheck                                         | CI ci.yml (line 81)                                                                                                                                      | pinned to 0.10.0 via env var                           | y - version pinned in env                                                                      | Low    |
| bats                                               | CI ci.yml (line 106), release.yml (line 51)                                                                                                              | distro-provided version                                | n - no version pin                                                                             | Low    |
| markdownlint-cli                                   | CI release.yml (line 52), ci.yml (line 232)                                                                                                              | npm latest                                             | n - no version pin                                                                             | Low    |
| softprops/action-gh-release                        | release.yml (line 152)                                                                                                                                   | @v1 mutable tag                                        | n - not SHA-pinned                                                                             | Medium |
| dorny/paths-filter                                 | ci.yml (line 31)                                                                                                                                         | @v3 mutable tag                                        | n - not SHA-pinned                                                                             | Medium |

<!-- markdownlint-enable -->

----------------------------------------------------------------------------------------------------

## 2. Findings

<!-- markdownlint-disable MD013 -->

### DEP-001 - No Runtime Bash Version Check Before Using Bash 4+ Features

**Severity:** High

**Evidence:**

- `src/bin/oradba_validate.sh:355` - `declare -A checked_files`
- `src/bin/oradba_dbctl.sh:515` - `mapfile -t db_list`
- `src/bin/oradba_version.sh:183` - `declare -A reported_files`
- `src/bin/oradba_version.sh:499/510` - `mapfile -t extensions`
- `src/bin/oraup.sh:661` - `mapfile -t all_installations`
- `src/bin/oradba_lsnrctl.sh:435` - `mapfile -t running`
- `src/bin/oradba_dsctl.sh:610/620/650` - `mapfile -t conn_list`, `declare -A CONNECTOR_HOMES`
- `src/bin/oradba_extension.sh:1325/1344/1421+` - `mapfile -t extensions` (9 occurrences)
- `src/bin/oradba_homes.sh:419/500/505` - `${name,,}` (bash 4+ lowercase, no fallback)
- `src/bin/get_seps_pwd.sh:206/225` - `${CONNECT_STRING,,}`, `${alias,,}` (bash 4+ lowercase, no
  fallback)
- `src/bin/oradba_setup.sh:337` - `${safe_ext_name^^}` (bash 4+ uppercase, no fallback)
- `src/bin/oradba_version.sh:432/461` - `${ext_name^^}` (bash 4+ uppercase, no fallback)
- `src/bin/oraup.sh:437/484` - `${protocol^^}` (bash 4+ uppercase, no fallback)
- `CONTRIBUTING.md:117` - documents "Bash 4.0+" requirement

macOS ships bash 3.2.57 as the system bash at `/bin/bash`. Any user running `#!/usr/bin/env bash`
with the Homebrew or system path will silently hit bash 3.2 on macOS unless they installed bash 4/5
separately. `oradba_check.sh` does not check the bash version;
`scripts/validate_test_environment.sh` does check but only warns. No production script performs a
version guard at startup.

**Recommendation:** Add a version guard at the top of every script that uses bash 4+ features:

``` bash
if (( BASH_VERSINFO[0] < 4 )); then
    echo "ERROR: bash 4.0 or later required (found ${BASH_VERSION})" >&2
    exit 1
fi
```

Add this to `oradba_check.sh` as a critical check. Add to `CONTRIBUTING.md` that macOS users must
install bash 4+ from Homebrew and set it as the default. Note: `oraup.sh:176/189` already shows the
right pattern (try `,,` with fallback to `tr`) - apply the same to the remaining files.

----------------------------------------------------------------------------------------------------

### DEP-002 - sha256sum Used Without shasum Fallback in oradba_version.sh

**Severity:** High

**Evidence:**

- `src/bin/oradba_version.sh:164` - `sha256sum -c -` (no shasum fallback)
- `src/bin/oradba_version.sh:414` - `sha256sum -c -` (no shasum fallback)
- `src/bin/oradba_version.sh:535` - `sha256sum -c -` (no shasum fallback)
- `src/bin/oradba_extension.sh:619` - `sha256sum "${filename}"` (no shasum fallback)

`sha256sum` is a GNU coreutils command and is absent on stock macOS. macOS provides `shasum`
instead. `oradba_check.sh`, `oradba_install.sh`, and `oradba_validate.sh` correctly handle the
sha256sum/shasum duality. `oradba_version.sh` (integrity verification, a user-facing feature) and
`oradba_extension.sh` use sha256sum directly. On macOS this silently fails with a confusing "command
not found" error, making integrity checks non-functional.

**Recommendation:** Apply the same pattern already used in `oradba_validate.sh:374-377`:

``` bash
if command -v sha256sum > /dev/null 2>&1; then
    sha256sum -c - < "${checksum_file}"
elif command -v shasum > /dev/null 2>&1; then
    shasum -a 256 -c - < "${checksum_file}"
else
    echo "ERROR: sha256sum or shasum required" >&2; return 1
fi
```

----------------------------------------------------------------------------------------------------

### DEP-003 - Oracle CLI Tools (sqlplus, rman, lsnrctl) Not Validated Before Use

**Severity:** High

**Evidence:**

- `src/bin/oradba_dbctl.sh:221` - calls `sqlplus -s / as sysdba` with no prior `command -v sqlplus`
  check
- `src/bin/oradba_dbctl.sh:238/279/286/326/345/363/415` - multiple additional sqlplus invocations
- `src/bin/oradba_rman.sh:721/748` - builds `rman_cmd="${ORACLE_HOME}/bin/rman"` and executes it
  with no `-x` or `command -v` check
- `src/bin/oradba_lsnrctl.sh:296/308` - calls `lsnrctl status` and `lsnrctl stop` with no prior
  existence check

`oradba_check.sh` checks these as informational/warning, not as blocking checks in the scripts
themselves. `oradba_dbca.sh:223` shows the correct pattern (`[[ ! -x "${ORACLE_HOME}/bin/dbca" ]]`)
that the others should follow.

Under `set -euo pipefail` a missing binary causes immediate script termination with an unhelpful
"command not found" error rather than a clear diagnostic message.

**Recommendation:** Add a pre-flight check to each script's initialisation:

- `oradba_dbctl.sh`: check `command -v sqlplus` in the `start_database()`/`stop_database()`
  functions or in the main guard.
- `oradba_rman.sh`: add
  `[[ -x "${rman_cmd}" ]] || { oradba_log ERROR "rman not found at ${rman_cmd}"; return 1; }` before
  execution.
- `oradba_lsnrctl.sh`: add
  `command -v lsnrctl > /dev/null 2>&1 || { oradba_log ERROR "lsnrctl not found"; exit 1; }` near
  top.

----------------------------------------------------------------------------------------------------

### DEP-004 - df -BG Used in oradba_dbca.sh (GNU-Only Flag Breaks macOS/Solaris)

**Severity:** Medium

**Evidence:**

- `src/bin/oradba_dbca.sh:245` -
  `df -BG "${data_dir_parent}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//'`

`-B` (block size) is a GNU coreutils extension. BSD df (macOS, OmniOS) does not support it. The call
is inside a `2>/dev/null` so it silently returns empty output. The variable `avail_gb` will be empty
and the disk-space check will silently not fire, not block a DBCA run with insufficient space.

`oradba_check.sh` and `oradba_install.sh` correctly use `df -Pm` (POSIX `-P` + `-m` for megabytes)
which works on both GNU and BSD df.

**Recommendation:** Replace:

``` bash
avail_gb=$(df -BG "${data_dir_parent}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
```

with the portable pattern already used in `oradba_check.sh:535`:

``` bash
avail_mb=$(df -Pm "${data_dir_parent}" 2>/dev/null | awk 'NR==2 {print $4}')
avail_gb=$(( avail_mb / 1024 ))
```

----------------------------------------------------------------------------------------------------

### DEP-005 - realpath Not Available on macOS Without GNU Coreutils (sync_to_peers.sh)

**Severity:** Medium

**Evidence:**

- `src/bin/sync_to_peers.sh:239` - `abs_source=$(realpath "${SOURCE}")` - no fallback
- `src/bin/sync_from_peers.sh:244` -
  `abs_source=$(realpath "${SOURCE}" 2>/dev/null || echo "${SOURCE}")` - has fallback

`sync_from_peers.sh` already applies the correct pattern. `sync_to_peers.sh` does not. `realpath` is
not part of POSIX and is absent on macOS without Homebrew `coreutils`. The script will abort with
"command not found" under `set -euo pipefail`.

**Recommendation:** Align `sync_to_peers.sh:239` with the fallback already used in
`sync_from_peers.sh:244`:

``` bash
abs_source=$(realpath "${SOURCE}" 2>/dev/null || echo "${SOURCE}")
```

----------------------------------------------------------------------------------------------------

### DEP-006 - rsync Not Validated Before Use in sync_to_peers.sh / sync_from_peers.sh

**Severity:** Medium

**Evidence:**

- `src/bin/sync_to_peers.sh:266` - invokes `rsync` with no prior `command -v rsync` guard
- `src/bin/sync_from_peers.sh` - same pattern

The usage comment at line 146 states "Requires ssh and rsync on all hosts" but there is no runtime
check. `oradba_check.sh` does not list rsync as a tool to verify. Under `set -euo pipefail` a
missing rsync terminates the loop immediately with `SYNC_FAILURE` unpopulated.

**Recommendation:** Add to `perform_sync()`:

``` bash
command -v rsync > /dev/null 2>&1 || { oradba_log ERROR "rsync is required but not found"; return 1; }
```

----------------------------------------------------------------------------------------------------

### DEP-007 - openssl Used in build_installer.sh Without Validation

**Severity:** Medium

**Evidence:**

- `scripts/build_installer.sh:262` - `openssl base64 < "$DIST_TARBALL" >> "$INSTALLER_OUTPUT"`

`openssl` is present on all modern Linux and macOS but is not listed in the build dependencies and
not checked by `check_dependencies()` inside `build_installer.sh`. The script uses `set -e` (line
19) but not `-u`, so if `openssl` is absent the base64 section of the installer is silently missing,
producing a corrupt installer that only fails at extraction time on the end-user machine.

**Recommendation:** Add
`command -v openssl > /dev/null 2>&1 || { echo "ERROR: openssl is required for build"; exit 1; }`
near the top of `build_installer.sh`. Add `openssl` to the required-tools list in `oradba_check.sh`
help text and `CONTRIBUTING.md`.

----------------------------------------------------------------------------------------------------

### DEP-008 - build_installer.sh Fetches External Content at Build Time Without Integrity Check

**Severity:** Medium

**Evidence:**

- `scripts/build_installer.sh:80-155` - fetches
  `https://api.github.com/repos/oehrlis/oradba_extension/releases/latest` then downloads
  `extension-template-*.tar.gz` directly from GitHub
- No checksum verification of the downloaded tarball before embedding it in the installer
- Cached version (`templates/oradba_extension/extension-template.tar.gz`) is used without
  re-verification on subsequent runs

The downloaded archive is embedded verbatim into the distributed installer. A compromised GitHub
release asset or a MITM on the download would silently embed malicious content in the installer.

**Recommendation:** After downloading, verify the tarball SHA-256 against a published checksum. If
the upstream release does not publish a checksum, compute it once and pin it in the build script as
a sanity check. At minimum, verify the TLS certificate chain (curl already does this by default with
`-fsSL`). Consider publishing the expected SHA-256 of embedded extension templates in the release
notes.

----------------------------------------------------------------------------------------------------

### DEP-009 - Mutable Docker Image Tags in CI and build Scripts

**Severity:** Medium

**Evidence:**

- `scripts/build_pdf.sh:29` - `PANDOC_IMAGE="${PANDOC_IMAGE:-oehrlis/pandoc:latest-full}"` (runtime
  default)
- `.github/workflows/ci.yml:251` - `docker pull oehrlis/pandoc:latest-full`
- `.github/workflows/release.yml:69` - `docker pull oehrlis/pandoc:latest-full`
- `.github/workflows/docker-tests.yml:36` -
  `docker pull container-registry.oracle.com/database/free:latest`

`latest-full` and `latest` tags are mutable. A Docker Hub or Oracle Container Registry push can
silently change the image used in builds and release-artifact generation. This affects the
reproducibility of release PDFs and the integrity of integration tests.

**Recommendation:** Pin Docker images by digest in the CI workflows, e.g.
`oehrlis/pandoc@sha256:<digest>` and `container-registry.oracle.com/database/free@sha256:<digest>`.
Update `build_pdf.sh` to default to a digest-pinned image or require explicit override.

----------------------------------------------------------------------------------------------------

### DEP-010 - Third-Party GitHub Action Not SHA-Pinned (softprops/action-gh-release)

**Severity:** Medium

**Evidence:**

- `.github/workflows/release.yml:152` - `uses: softprops/action-gh-release@v1`

All first-party actions (`actions/checkout@v4`, `actions/setup-node@v4`, etc.) are pinned to a major
version tag, not a commit SHA. `softprops/action-gh-release@v1` is a third-party action. A malicious
tag update to `v1` could execute arbitrary code in the release pipeline with `contents: write`
permission. GitHub recommends pinning third-party actions to a full commit SHA.

`dorny/paths-filter@v3` in `ci.yml:31` has lower privilege but is also unpinned.

**Recommendation:** Pin both to full commit SHAs with a comment indicating the semantic version:

``` yaml
# softprops/action-gh-release v1 (pinned)
uses: softprops/action-gh-release@de2c0eb89ae2a093876385947365aca7b0e5f844
```

Consider using Dependabot to auto-update these pins.

----------------------------------------------------------------------------------------------------

### DEP-011 - pip and npm Packages Installed Without Version Pins in CI

**Severity:** Medium

**Evidence:**

- `.github/workflows/docs.yml:48-52` -
  `pip install mkdocs-material mkdocs-git-revision-date-localized-plugin pymdown-extensions pyyaml`
  (all unpinned)
- `.github/workflows/ci.yml:232` - `npm install -g markdownlint-cli` (unpinned)
- `.github/workflows/release.yml:52` - `npm install -g markdownlint-cli` (unpinned)
- `.github/workflows/release.yml:51` - `sudo apt-get install -y bats shellcheck` (distro version,
  not pinned)

Unpinned packages fetch latest-available versions on each run. A breaking change or a compromised
package update (supply-chain attack) would silently affect CI without a version change in the
repository.

**Recommendation:** Pin Python packages in a `requirements-docs.txt` and reference it with
`pip install -r requirements-docs.txt`. Pin npm packages (`markdownlint-cli@0.x.y`). For bats,
either pin via npm/brew or accept the distro version explicitly by documenting the dependency.

----------------------------------------------------------------------------------------------------

### DEP-012 - shellcheck Downloaded Over curl Without Checksum Verification

**Severity:** Low

**Evidence:**

- `.github/workflows/ci.yml:81-83` - shellcheck tarball downloaded via `curl -fsSL ... | tar -xJ`
  and installed directly

The version is pinned (`SHELLCHECK_VERSION: "0.10.0"`) which is good. However the downloaded tarball
is not checksum-verified before extracting and installing to `/usr/local/bin`. A compromised GitHub
release asset would install a malicious shellcheck binary that then runs on all source files.

**Recommendation:** Add a SHA-256 verification step after download:

``` bash
echo "<expected_sha256>  shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" | sha256sum -c -
```

Alternatively, install shellcheck from the Ubuntu package manager where the package is signed.

----------------------------------------------------------------------------------------------------

### DEP-013 - Undocumented Dependency on timeout Utility

**Severity:** Low

**Evidence:**

- `src/bin/oradba_check.sh:704` - `timeout 5 sqlplus -S / as sysdba`
- `src/bin/oradba_dbctl.sh:345` - `timeout "${SHUTDOWN_TIMEOUT}" sqlplus -s / as sysdba`

`timeout` is part of GNU coreutils. macOS provides it as `gtimeout` via Homebrew coreutils; the
stock macOS does not have `/usr/bin/timeout`. Neither `oradba_check.sh` nor `oradba_dbctl.sh` check
for `timeout` before using it.

**Recommendation:** Add `timeout` to the optional tools check in `oradba_check.sh`. In
`oradba_dbctl.sh` add a guard:

``` bash
TIMEOUT_CMD=$(command -v timeout || command -v gtimeout || echo "")
if [[ -n "$TIMEOUT_CMD" ]]; then
    $TIMEOUT_CMD "${SHUTDOWN_TIMEOUT}" sqlplus ...
else
    sqlplus ...  # proceed without timeout wrapper
fi
```

----------------------------------------------------------------------------------------------------

### DEP-014 - Runtime Fetch from External GitHub Repos in docs.yml (sync_extension_docs.py)

**Severity:** Low

**Evidence:**

- `.github/workflows/docs.yml:54-57` - runs `python .github/scripts/sync_extension_docs.py`
- `.github/scripts/sync_extension_docs.py:26/36-48` - clones `https://github.com/${repo}.git` for
  each entry in `.github/extensions.yml`
- `.github/extensions.yml` lists `oehrlis/oradba_extension`, `oehrlis/odb_datasafe`,
  `oehrlis/odb_autoupgrade` (and potentially others)

Documentation is built by cloning external repositories at build time. While these are same-owner
repos, the mechanism introduces a dependency on external repo availability and the current HEAD of
each repo's default branch. There is no version pinning; a breaking change in an extension repo's
documentation would break the OraDBA docs build.

**Recommendation:** Add a `ref:` field to each entry in `extensions.yml` to pin the commit or tag to
pull from. Validate in `sync_extension_docs.py` that `ref` is set before cloning.

----------------------------------------------------------------------------------------------------

### DEP-015 - base64 -d Flag Portability Note (Low Severity)

**Severity:** Low

**Evidence:**

- `src/bin/get_seps_pwd.sh:186` - `base64 -d "${WALLET_DIR}/.wallet_pwd"`
- `src/bin/oradba_install.sh:1571` - `base64 --decode` (uses long form)

`-d` is accepted by both GNU base64 and macOS base64 (macOS accepts `-d` as a synonym for
`--decode`). This is currently not a functional bug on macOS 10.14+. The build-time use in
`build_installer.sh:262` uses `openssl base64` (without `-d`) for encoding, which is also portable.
No change required at this time, documented for completeness.

**Recommendation:** Prefer `--decode` (long form) consistently for clarity. The
`oradba_install.sh:1571` already does this correctly.

<!-- markdownlint-enable -->

----------------------------------------------------------------------------------------------------

## 3. Summary

| ID      | Title                                                                  | Severity |
|---------|------------------------------------------------------------------------|----------|
| DEP-001 | No runtime bash version check before using bash 4+ features            | High     |
| DEP-002 | sha256sum used without shasum fallback in oradba_version.sh            | High     |
| DEP-003 | Oracle CLI tools (sqlplus, rman, lsnrctl) not validated before use     | High     |
| DEP-004 | df -BG used in oradba_dbca.sh (GNU-only flag)                          | Medium   |
| DEP-005 | realpath not available on macOS in sync_to_peers.sh                    | Medium   |
| DEP-006 | rsync not validated before use in sync scripts                         | Medium   |
| DEP-007 | openssl used in build_installer.sh without validation                  | Medium   |
| DEP-008 | build_installer.sh fetches external content without integrity check    | Medium   |
| DEP-009 | Mutable Docker image tags in CI and build scripts                      | Medium   |
| DEP-010 | Third-party GitHub Action not SHA-pinned (softprops/action-gh-release) | Medium   |
| DEP-011 | pip and npm packages installed without version pins in CI              | Medium   |
| DEP-012 | shellcheck downloaded without checksum verification                    | Low      |
| DEP-013 | Undocumented dependency on timeout utility                             | Low      |
| DEP-014 | Runtime fetch from external GitHub repos in docs.yml                   | Low      |
| DEP-015 | base64 -d flag portability note                                        | Low      |
