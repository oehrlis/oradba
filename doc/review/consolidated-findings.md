# Consolidated Review Findings - OraDBA v0.24.11

<!-- markdownlint-disable MD013 -->

**Generated:** 2026-06-26 **Synthesis basis:** 8 domain reviews (architecture, bash, dependencies,
documentation, performance, release, security, testing) plus 3 scans (inventory, static-findings,
test-coverage) **Target:** v1.0.0 stable **Method:** dedupe by theme, merge cross-domain evidence,
rank by impact x likelihood x blast radius. Security findings and the recent installer/regression
defect classes (zero-start `(( ++ ))`, missing `set -euo pipefail`, hardcoded/predictable paths,
missing runtime/dir validation, test-detection gaps) are weighted as v1.0.0 release blockers.

Severity scale: Critical / High / Medium / Low. Blocker = must be resolved before v1.0.0 tag.

----------------------------------------------------------------------------------------------------

## Prioritized recommendations

<!-- markdownlint-disable MD060 -->

| Rank | ID | Severity | Area | One-line | Blocker | Effort |
|----|----|----|----|----|----|----|
| 1 | CF-001 | Critical | Bash / robustness | Zero-start `(( counter++ ))` aborts dsctl, dbctl, lsnrctl, dbca, version, logrotate, sqlnet, env_changes under `set -e` | Yes | M |
| 2 | CF-002 | Critical | Security | DBCA writes SYS/SYSTEM passwords to predictable world-readable `/tmp` response file | Yes | M |
| 3 | CF-003 | Critical | Architecture | Duplicate `plugin_check_listener_status` makes the canonical plugin interface contract self-contradictory | Yes | S |
| 4 | CF-004 | Critical | Architecture | Two competing plugin loaders; isolation-safe path bypassed by 9 direct-source sites | Yes | L |
| 5 | CF-005 | High | Bash / portability | Missing/incomplete `set -euo pipefail` on oradba_homes.sh and oradba_extension.sh | Yes | S |
| 6 | CF-006 | High | Security / supply chain | GitHub release tarball and curl-pipe-bash installs run without checksum/signature verification | Yes | M |
| 7 | CF-007 | High | Architecture / config | `ORADBA_BASE` vs `ORADBA_PREFIX` resolved inconsistently - root-cause class for installer path defects | Yes | M |
| 8 | CF-008 | Critical | Testing | Path-critical validator, env-builder, home-discovery, version-metadata functions largely untested | Yes | L |
| 9 | CF-009 | Critical | Testing | No regression test for any of the six recent shipped defects | Yes | M |
| 10 | CF-010 | Critical | Release | Release pipeline does not assert VERSION file matches the pushed git tag | Yes | S |
| 11 | CF-011 | High | Dependencies | No runtime bash 4+ version guard despite bash 4+ features and macOS bash 3.2 | Yes | S |
| 12 | CF-012 | High | Dependencies / portability | GNU-only tools (`df -BG`, `sha256sum`, `realpath`, `timeout`) used without BSD fallback | No | M |
| 13 | CF-013 | High | Dependencies | Oracle CLI tools (sqlplus, rman, lsnrctl) invoked without existence check | No | S |
| 14 | CF-014 | High | Performance | Eager sourcing of 12+ libraries and double config load on every `oraenv.sh` call | No | L |
| 15 | CF-015 | Critical | Performance | `generate_pdb_aliases` spawns 2-3 sqlplus per env switch even in silent/fast modes | Yes | M |
| 16 | CF-016 | High | Performance | Repeated subshell/fork anti-patterns in hot path (dedupe, log timestamp, plugin re-source, home parse) | No | M |
| 17 | CF-017 | High | Architecture | Parallel environment-build paths: inline `oraenv.sh` logic vs unused `oradba_build_environment` | Yes | L |
| 18 | CF-018 | High | Architecture | DB-status querying implemented three times with divergent SQL and status vocabulary | No | M |
| 19 | CF-019 | High | Release | Docker integration tests manual-only and excluded from the release gate | Yes | M |
| 20 | CF-020 | High | Security | SEPS wallet password loaded from reversible base64 file and logged in cleartext | No | M |
| 21 | CF-021 | Medium | Security | RMAN catalog credential and `--sys/--system-password` reach process args and logs | No | M |
| 22 | CF-022 | Medium | Security | `eval`-based array build in oraenv consumes oratab/homes fields without sanitisation | No | S |
| 23 | CF-023 | Medium | Security | Predictable PID-based temp dirs/files without exclusive create (RMAN, homes dedupe) | No | S |
| 24 | CF-024 | High | Documentation | Registry API docs wrong: wrong delimiter, phantom functions, missing real functions | Yes | M |
| 25 | CF-025 | High | Documentation | Pervasive version/count staleness across docs and per-script headers | No | M |
| 26 | CF-026 | Medium | Release | Release notes/tag/CHANGELOG drift (v0.24.4 untagged, v0.24.5 notes missing, no diff links) | No | S |
| 27 | CF-027 | Medium | Release | `make test-full` treats bats exit 1 as success, masking real failures | Yes | S |
| 28 | CF-028 | Medium | Dependencies / supply chain | Mutable CI image tags, unpinned actions/packages, unverified build downloads | No | M |
| 29 | CF-029 | Medium | Architecture | Duplicate oratab parsers and incomplete registry abstraction (auto-discovery stub) | No | M |
| 30 | CF-030 | Medium | Architecture / bash | Unprefixed public functions and locally redefined `oradba_log` pollute/shadow shell namespace | No | M |
| 31 | CF-031 | Medium | Bash | Error messages written to stdout instead of stderr | No | S |
| 32 | CF-032 | Medium | Architecture | Bootstrap boilerplate duplicated across 27 bin scripts with no shared loader | No | M |
| 33 | CF-033 | Low | Bash / determinism | Fragile `grep`/`find` boolean idioms, missing `LC_ALL=C`, GNU `date -d` returns 0 on parse failure | No | S |
| 34 | CF-034 | Medium | Release / process | No v1.0.0 readiness definition, no stabilisation gate, no deprecation-warning policy | Yes | M |

<!-- markdownlint-enable MD060 -->

----------------------------------------------------------------------------------------------------

## Findings by theme

### Theme 1: Regression-class shell defects (zero-start arithmetic, set -e gaps)

#### CF-001 - Zero-start `(( counter++ ))` aborts scripts under set -e

**Severity:** Critical **Cross-references:** BASH-001, BASH-002, BASH-003, BASH-004, BASH-005,
BASH-006, BASH-014, ARCH-012 (context), F-006 (testing)

**Problem statement:** Identical root cause to shipped fix `4db7ccf`. Under `set -e`, `(( var++ ))`
returns exit code 1 when `var` is 0 (the pre-increment value is falsy), aborting the script. The
`4db7ccf` fix covered only `oraup.sh`. The same pattern remains across:
`oradba_dsctl.sh:148,672-708`, `oradba_dbctl.sh:556-588`, `oradba_lsnrctl.sh:460-492`,
`oradba_dbca.sh:455-482`, `oradba_version.sh:334,402`, `oradba_logrotate.sh:184-210`,
`oradba_sqlnet.sh:655,668`, and library `oradba_env_changes.sh:200,203` (which inherits the caller's
`set -e`).

**Impact:** Every first start/stop/restart of a connector, database, or listener silently aborts;
first validation failure in dbca aborts before usage is printed; first config file processed by
env_changes aborts when sourced into a `set -e` caller. This is the single highest-likelihood
operational defect class - it fires on the first iteration of normal use.

**Recommendation:** Apply the established `|| true` guard (already used at `oradba_check.sh:79`,
`oradba_install.sh:619`) or switch to `var=$(( var + 1 ))` at every from-zero increment. Add a CI
lint rule flagging standalone `(( var++ ))` (see CF-009/F-006). Coordinate with CF-005: the
homes/extension increments become hazardous the moment `set -euo pipefail` is added there.

#### CF-005 - Missing/incomplete `set -euo pipefail`

**Severity:** High **Cross-references:** ARCH-012, BASH-007, BASH-008, inventory section 8, DOC-015

**Problem statement:** `src/bin/oradba_homes.sh` has no `set` statement;
`src/bin/oradba_extension.sh:17` has only `set -o pipefail` (missing `-e -u`). Both are executed,
not sourced. `oradba_homes.sh` additionally carries 13 from-zero `(( counter++ ))` instances (lines
702, 861, 951, 961, 1082-1225) and `oradba_extension.sh` carries increments at 1541-1748 - all
currently harmless only because `set -e` is absent.

**Impact:** Failed commands in `remove_home`, `validate_homes`, `import_config`, `cmd_create`,
`update_extension` are silently swallowed; an unset `ext_path` would produce `cd ""` at
`oradba_extension.sh:603`. CONTRIBUTING.md compounds this by describing strict mode as optional
(DOC-015) while project rules mandate it.

**Recommendation:** Add full `set -euo pipefail` after the shebang in both scripts and, in the same
commit, add `|| true` to every listed increment (link to CF-001). Update CONTRIBUTING.md to state
strict mode is mandatory for non-sourced scripts.

#### CF-031 - Error messages to stdout instead of stderr

**Severity:** Medium **Cross-references:** BASH-009, BASH-019

**Problem statement:** Several `echo "ERROR:"` calls lack `>&2`: `get_seps_pwd.sh:32`,
`oradba_dsctl.sh:34`, `oradba_dbctl.sh:34`, `oradba_lsnrctl.sh:33`, `oradba_services_root.sh:36`,
and `oradba_env.sh:554,585,600`. The same file (`oradba_env.sh`) routes correctly to stderr at lines
298, 416, 490, 497, 524, 735.

**Impact:** Callers capturing output with `$()` receive error text in the variable. For the sourced
`oradba_env.sh`, ERROR text on stdout can corrupt environment-setup pipelines.

**Recommendation:** Add `>&2` to all listed calls, per the project shell rule.

#### CF-033 - Fragile shell idioms, locale, GNU date

**Severity:** Low **Cross-references:** BASH-013, BASH-015, BASH-020, BASH-021

**Problem statement:** `oraup.sh:215,364` use a `grep | grep -qv` pipeline that is correct only
because it sits inside an `if`; `oradba_extension.sh:680` uses `find ... | read` as a boolean and
re-runs the same find; `oradba_common.sh:967,977,980`, `oradba_sqlnet.sh:641`,
`oradba_install.sh:1912-1932` run `sort`/`comm` without `LC_ALL=C`; `oradba_db_functions.sh:269`
lets a GNU `date -d` parse failure return 0, producing ~55-year uptimes.

**Impact:** Latent defects triggered by refactors, differing locale collation, or unparseable
startup timestamps.

**Recommendation:** Rewrite the grep/find idioms as explicit two-step checks, prefix sort/comm with
`LC_ALL=C`, and guard the uptime computation against a zero/implausible epoch.

----------------------------------------------------------------------------------------------------

### Theme 2: Credential and supply-chain security

#### CF-002 - DBCA passwords in predictable world-readable /tmp file

**Severity:** Critical **Cross-references:** SEC-01, static-findings (password patterns, /tmp
literals)

**Problem statement:** `oradba_dbca.sh:584` builds `response_file="/tmp/dbca_${DB_SID}_$$.rsp"`;
SYS/SYSTEM passwords are substituted verbatim (`:182-183`) and written with default umask, no
`chmod`, no `mktemp` (`:194`). On DBCA failure the file is deliberately preserved (`:613`), leaving
plaintext SYS/SYSTEM passwords on disk. Dry-run prints the first 20 lines (`:598`).

**Impact:** The path is predictable (`${DB_SID}` plus observable `$$`); under common umask the file
is world- or group-readable during the DBCA window, and persists indefinitely on failure. These are
SYS/SYSTEM passwords of a fresh database - full DBA compromise on a shared host.

**Recommendation:** Create the response file via `mktemp -d` in a `mode 700` per-run directory (or
under `$ORACLE_BASE/cfgtoollogs`), `chmod 600` before writing secrets, and register a
`trap ... EXIT` that shreds it on all paths including failure. Prefer feeding SYS/SYSTEM to DBCA via
stdin so passwords never hit disk.

#### CF-006 - Installer runs without integrity verification

**Severity:** High **Cross-references:** SEC-03, SEC-04, DEP-008, DEP-012

**Problem statement:** `oradba_install.sh:2065-2085` fetches and extracts the GitHub release tarball
with no verification against the shipped `dist/*.tar.gz.sha256`; the only check (`--verify-core`,
`:2328-2338`) compares files against a checksum manifest inside the same tarball - useless against a
tampered download. README one-liners (`README.md:88,268,337`) pipe remote scripts straight into
`bash`. The build (`build_installer.sh:80-155`) and CI (`ci.yml:81-83` shellcheck download) fetch
external content without checksum verification.

**Impact:** A MITM, compromised CDN, or compromised release asset can substitute a malicious payload
that executes with root/oracle privilege, since installs are commonly run as root. The
self-referential checksum provides false assurance.

**Recommendation:** Download the companion `.sha256`, verify with `shasum -a 256 -c` before
extraction, and fail closed if no verification tool is present (rather than warning and continuing
at `:284`). Make the verified two-step download the headline documented install path. Add SHA-256
verification to build-time and CI downloads; consider minisign/GPG signing with a pinned key.

#### CF-020 - SEPS wallet password reversible and logged

**Severity:** High **Cross-references:** SEC-02

**Problem statement:** `get_seps_pwd.sh:84,185-188` documents and reads a `.wallet_pwd` base64 file
with no permission/ownership check; `:243` logs the recovered DB password in cleartext in non-quiet
mode. base64 is encoding, not encryption.

**Impact:** Anyone who can read `.wallet_pwd` recovers the wallet password, defeating the auto-login
wallet's purpose. With `ORADBA_LOG_FILE` set (as under the root service wrapper) the recovered DB
password lands in a log file.

**Recommendation:** Drop or explicitly relabel the base64 mechanism as obfuscation-only and refuse
to read it unless `600` and owner-owned (`stat` check before `base64 -d`); prefer `cwallet.sso` or
`op read`. Never log the recovered password; restrict cleartext output to an explicit quiet-mode
stdout channel. Preserve the sound stdin-to-`mkstore` pattern already present.

#### CF-021 - Credentials in process arguments and logs

**Severity:** Medium **Cross-references:** SEC-05, SEC-08, SEC-09, static-findings (password
patterns)

**Problem statement:** `oradba_rman.sh:726-748` places `catalog ${RMAN_CATALOG}` (conventionally
`user/pass@catdb`) on the RMAN command line and logs it at DEBUG (`:727`). `oradba_dbca.sh:410-416`
accepts `--sys-password`/`--system-password` as `$2` on the command line (documented as primary in
`dbca/README.md:121-122`), though a safe interactive `read -rs` fallback exists (`:520-527`).

**Impact:** Catalog and SYS/SYSTEM credentials are visible via `ps -ef`/`/proc/<pid>/cmdline` to any
local user during the process lifetime and captured in shell history and DEBUG logs.

**Recommendation:** Pass catalog credentials inside the restricted-permission `.rcv` script body or
via a SEPS alias; redact the catalog string in logs. Keep interactive prompt as default for dbca;
accept automation passwords via stdin or `op read`, or remove the plaintext flags in favour of
`--sys-password-stdin`.

#### CF-022 - eval-based array build consumes oratab/homes fields

**Severity:** Medium **Cross-references:** SEC-06, BASH-017, static-findings (eval usage)

**Problem statement:** `oraenv.sh:401,402,409,419,424,425,436,443` use `eval "${var}+=(\"${sid}\")"`
where `sid`/`name` are colon-delimited fields parsed from oratab and `oradba_homes.conf`
(`oradba_registry.sh:54-95`). A crafted field such as `x")$(touch /tmp/pwned)#` breaks out of
quoting and executes code in the context of the user sourcing oraenv.

**Impact:** A less-privileged account able to edit a group-writable oratab or homes file gains code
execution as anyone who later sources oraenv (for example the DBA). Medium because exposure depends
on those files' write permissions.

**Recommendation:** Replace `eval` with bash 4.3 namerefs
(`local -n arr="${var}"; arr+=("${sid}")`), or if bash 3.2 support is required, validate
names/fields against a strict allowlist (`[[ "${sid}" =~ ^[A-Za-z0-9_.]+$ ]]`) before use.

#### CF-023 - Predictable temp paths without exclusive create

**Severity:** Medium **Cross-references:** SEC-07, BASH-016, BASH-018, static-findings (/tmp
literals)

**Problem statement:** `oradba_rman.sh:51,1048` uses `TEMP_DIR="${TMPDIR:-/tmp}/oradba_rman_$$"`
with `mkdir -p` (succeeds on a pre-existing path/symlink); generated `.rcv` scripts are written
there (`:713`). `oradba_homes.sh:1177` uses a `$$`-suffixed dedupe temp file.
`oradba_extension.sh:784-1104` has multiple `mktemp -d` calls with no `trap ... EXIT` cleanup.

**Impact:** TOCTOU - a local attacker can pre-create the predictable path/symlink and read or tamper
with generated RMAN scripts before execution against the `target /` sysdba session, or collide
concurrent homes-dedupe runs. Missing EXIT traps leave temp dirs behind on `set -e`/SIGTERM exit.

**Recommendation:** Use `mktemp -d "${TMPDIR:-/tmp}/oradba_rman.XXXXXX"` (fresh 700 dir, fails if
exists) and `mktemp "${homes_file}.dedup.XXXXXX"`; verify ownership before use; register
`trap 'rm -rf "${tmpdir}"' EXIT` with a single temp root in oradba_extension.sh.

----------------------------------------------------------------------------------------------------

### Theme 3: Architecture - plugin system, env build paths, naming

#### CF-003 - Duplicate `plugin_check_listener_status` makes interface contract self-contradictory

**Severity:** Critical **Cross-references:** ARCH-001

**Problem statement:** `plugin_interface.sh:298` and `:337` both define
`plugin_check_listener_status()`. The first returns `2`/unavailable silently as a "category
default"; the second logs an ERROR and returns `2`. In bash the second wins, so the documented
default at `:298` is dead code. This is the single most load-bearing file for the plugin system.

**Impact:** Plugin authors and tests reading the template get ambiguous guidance; the silent-default
behaviour cannot be relied on.

**Recommendation:** Keep exactly one definition after deciding the intended contract; add a guard
test asserting each interface function name is defined exactly once in the template.

#### CF-004 - Two competing plugin loaders; safe one bypassed

**Severity:** Critical **Cross-references:** ARCH-002, ARCH-011, P-06 (performance overlap)

**Problem statement:** `execute_plugin_function_v2()` (`oradba_common.sh:1541`) runs each plugin in
a subshell, unsets `TNS_ADMIN`/`plugin_status`, and enforces interface-version/EXPERIMENTAL checks.
In parallel, 9 sites source plugins directly into the caller's shell (`oraup.sh:399`,
`oradba_homes.sh:838`, `oradba_dsctl.sh:41`, `oradba_env.sh:138`, `oradba_datasafe_debug.sh:328`,
`oraenv.sh:754,920,1028`), bypassing all guarantees and leaking `plugin_status`/`plugin_name` into
the calling environment. A dead no-op fallback branch exists at `oradba_common.sh:1559-1563`.

**Impact:** Cross-plugin contamination - precisely the bug class the isolation wrapper exists to
prevent; interface gating enforced inconsistently. (Note: P-06 documents the inverse performance
cost of the isolation wrapper, so resolution must balance isolation vs fork cost - see
DECISION-REQUIRED below.)

**Recommendation:** Make `execute_plugin_function_v2` (or a thin wrapper) the only sanctioned entry
to plugin behaviour; where direct-source is required, wrap in an explicit documented subshell. Audit
every direct-source site against the isolation contract before v1.0.0; remove the dead fallback
branch.

#### CF-007 - ORADBA_BASE vs ORADBA_PREFIX inconsistency

**Severity:** High **Cross-references:** ARCH-003, ARCH-009 (overlap), SEC path-resolution context

**Problem statement:** Plugin path uses `ORADBA_BASE` in `oraup.sh:394`, `oradba_env.sh:136`,
`oradba_dsctl.sh:39` but `ORADBA_PREFIX` in `oradba_homes.sh:832`. `get_oratab_path` priority 4
reads `${ORADBA_BASE}/etc/oratab` while registry/discovery fallbacks read
`${ORADBA_PREFIX}/etc/oratab` (`oradba_registry.sh:77,219`, `oradba_database_discovery.sh:359,390`).
Bootstrap is ad hoc across `oraenv.sh:31,80`, `oradba_homes.sh:19,22`, `oradba_setup.sh:22`,
`oraup.sh:20`, `oradba_dsctl.sh:26`, `oradba_rman.sh:26`.

**Impact:** Root-cause class for the Data Safe installer path defects. Where the two variables
diverge, plugin discovery, oratab resolution, and config loading silently look in different trees.

**Recommendation:** Define one canonical install-root variable (`ORADBA_BASE`), treat
`ORADBA_PREFIX` as a deprecated alias for one release, replace all `${ORADBA_PREFIX}/...` library
references, and introduce a shared bootstrap snippet (link to CF-032).

#### CF-017 - Parallel environment-build paths

**Severity:** High **Cross-references:** ARCH-004, P-01 (overlap), F-008 (testing), DOC-019

**Problem statement:** `oraenv.sh:719` builds the environment by calling
`set_oracle_home_environment` and setting vars inline (`:985-986,1022`). The dedicated orchestrator
`oradba_build_environment` (`oradba_env_builder.sh:889`) is referenced only by
`oradba_env_changes.sh` and the README - no `src/bin` script calls it, and it plus most
sub-functions have 0 test references (test-coverage.md, F-008).

**Impact:** Two parallel implementations; the structured one was meant to replace inline logic but
the migration stalled and the alternate path rots untested. The library count is inflated by a
subsystem the main flow does not use.

**Recommendation (DECISION-REQUIRED - see clarifications):** Decide direction before v1.0.0 - either
complete the migration so `oraenv.sh` delegates to `oradba_build_environment` and retire inline
logic, or explicitly demote env_builder/validator to "alternate API" status. Do not ship v1.0.0 with
both presented as equal public surface.

#### CF-018 - DB-status querying implemented three times

**Severity:** High **Cross-references:** ARCH-005

**Problem statement:** `oradba_check_db_status` (`oradba_env_status.sh:42`) queries
`v$instance WHERE instance_name=...`; `oradba_get_db_status`/`oradba_check_db_running`
(`oradba_env_validator.sh:194,238`) query via `/ as sysdba` with different normalisation and extra
vocabulary (NOMOUNT/STARTED); `get_database_open_mode`/`check_database_connection`
(`oradba_db_functions.sh:60,83`) form a third variant. Each rolls its own pmon check.

**Impact:** Three definitions of "is the database up and in what mode" with divergent vocabulary
(SHUTDOWN vs DOWN vs unavailable); callers cannot rely on a stable contract.

**Recommendation:** Define one canonical open-mode function with a fixed output vocabulary and
documented exit-code contract in the status module; have validator and db_functions call it; remove
redundant heredocs.

#### CF-029 - Duplicate oratab parsers; incomplete registry abstraction

**Severity:** Medium **Cross-references:** ARCH-006, ARCH-010

**Problem statement:** `parse_oratab()` (`oradba_database_discovery.sh:32`) and
`oradba_parse_oratab()` (`oradba_env_parser.sh:73`) both parse oratab; the registry adds a third
inline parse (`oradba_registry.sh:56-72`). `oradba_registry_discover_all()` (`:320-331`) logs
"Auto-discovery not yet implemented" and returns 0, yet `oradba_registry_get_all` advertises an
auto-discovery fallback.

**Impact:** The registry, introduced as the oratab abstraction layer, still inlines its own parse
and advertises a stub; three parse implementations drift independently.

**Recommendation:** Make the registry the sole oratab reader and route parser/discovery through
`oradba_registry_get_*`; either implement `oradba_registry_discover_all` or remove the advertised
fallback and document discovery as out of scope for v1.0.0.

#### CF-030 - Namespace pollution and shadowed logger

**Severity:** Medium **Cross-references:** ARCH-007, ARCH-008, static-findings (oradba_log
duplication, naming inconsistency)

**Problem statement:** Older core/discovery libs export unprefixed names into the global shell
namespace (`parse_oratab`, `get_oracle_homes_path`, `detect_product_type`,
`set_oracle_home_environment`, `generate_sid_lists`, `check_database_connection`).
`oradba_datasafe_debug.sh:320` defines a stub `oradba_log()` inside `main` even though it sources
the real logger at `:378`, permanently overriding file logging, levels, and
`sanitize_sensitive_data` for the process; `oradba_log` is defined in 6 files (static-findings).

**Impact:** For a sourced framework every unprefixed function is a landmine in the user's
interactive shell; the shadowing stub silently drops sensitive-data sanitisation and file logging.

**Recommendation:** Prefix all sourced public functions `oradba_` / internal `_oradba_`, with
deprecated aliases for one release. Only define a fallback `oradba_log` when the real one is absent
(`command -v oradba_log >/dev/null || oradba_log() { ... }`); never redefine after sourcing common.

#### CF-032 - Duplicated bootstrap boilerplate, no shared loader

**Severity:** Medium **Cross-references:** ARCH-009, P-01 (overlap), CF-007, CF-014

**Problem statement:** 27 `src/bin/*.sh` scripts independently compute `SCRIPT_DIR` and re-derive
`ORADBA_BASE`/`ORADBA_PREFIX` with slightly different expressions. There is no shared `bootstrap.sh`
or `load_all_plugins.sh`. Library load order is implicit and inconsistent
(`oradba_common.sh:1713-1717` sources three sub-libs unconditionally; `oraenv.sh:35-94` hand-orders
six).

**Impact:** Each bootstrap variant is an opportunity for the CF-007 divergence; load-order drift is
a latent defect source; this overlaps the P-01 eager-sourcing cost.

**Recommendation:** Introduce one sourced `lib/oradba_bootstrap.sh` that resolves the install root
from `BASH_SOURCE`, exports the canonical root variable, and sources required libraries in a single
defined order. Every bin script sources that one file. Coordinate with CF-014 lazy-loading.

----------------------------------------------------------------------------------------------------

### Theme 4: Test coverage gaps and regression protection

#### CF-008 - Path-critical functions largely untested

**Severity:** Critical **Cross-references:** F-007, F-008, F-009, F-011, F-016, F-012, F-014,
test-coverage.md sections 3 and 7

**Problem statement:** Validator 2/9 covered (`oradba_validate_environment`, `oradba_validate_sid`,
`oradba_get_db_version` uncovered); env-builder 9/20 (`oradba_build_environment` and core path
functions uncovered); home-discovery 2/16 (`is_oracle_home`, `detect_product_type`,
`parse_oracle_home` largely uncovered); version-metadata 1/6 (`get_install_info`,
`set_install_info`, `init_install_info` uncovered); env-output 4/5 uncovered and absent from
`.testmap.yml`. Five bin scripts (oradba_logrotate.sh, sessionsql.sh, oradba_validate.sh,
oradba_datasafe_debug.sh, oradba_setup.sh) have no test file or testmap entry.

**Impact:** The functions executed on every `oraenv.sh` call and the install-state management layer
have no behavioral coverage; the cbcb942 defect lived in `parse_oracle_home`/`list_oracle_homes`,
exactly this gap. Files absent from `.testmap.yml` will not trigger CI smart-selection on change.

**Recommendation:** Add behavioral tests with mock Oracle-home fixtures for
`oradba_validate_environment`, `oradba_build_environment` and its path sub-functions, the
home-discovery classification functions, and the install-info functions. Add the five untested bin
scripts and `oradba_env_output.sh` to `.testmap.yml` with at least smoke tests.

#### CF-009 - No regression test for the six recent defects

**Severity:** Critical **Cross-references:** F-001, F-002, F-003, F-004, F-005, F-006, F-013, F-017,
testing "Required Regression Tests" table

**Problem statement:** None of the six shipped defects (b76fe9c dsctl log fallback, 5e89542
stopped-connector blank, 4db7ccf `((idx++))`, cbcb942 homes description clobber, bbf2540 ORACLE_BASE
unbound, fa36489 test-suite `(( count++ ))`) has a named regression test. The happy-to-error
assertion ratio is 13:1 (934 vs 72), and every one of these defects was a failure-mode/edge-case bug
structurally missed by happy-path bias. Many dsctl/oraup tests assert via `grep` against source
rather than exercising behaviour (F-017).

**Impact:** All six defect classes can recur silently; the suite's structure does not exercise
unset-variable, arithmetic-exit, pipefail, missing-path, or empty-field conditions.

**Recommendation:** Implement the named regression tests in the testing review's "Required
Regression Tests" table (mapping each commit to target, scenario, and assertion). Define and enforce
a minimum error-path ratio (suggested 15%) for v1.0.0. Add a CI lint step flagging standalone
`(( var++ ))` (shared with CF-001). Replace grep-as-coverage with companion functional tests for
behavioral assertions.

#### CF-027 - make test-full masks failures

**Severity:** Medium **Cross-references:** RF-11

**Problem statement:** `Makefile:138-151` catches bats `test_exit=1` and treats it as success ("exit
code 1 is normal with conditional skips"). bats uses exit 1 for both skipped tests and actual
failures, so a suite with one failing test plus any skip returns 1 and passes.

**Impact:** Real test failures are silently swallowed by the primary release-gate test target -
directly undermines every other test investment.

**Recommendation:** Run `bats --report-formatter tap` and parse TAP to distinguish failed from
skipped; do not suppress exit 1 wholesale.

----------------------------------------------------------------------------------------------------

### Theme 5: Release engineering and process

#### CF-010 - Pipeline does not assert VERSION == git tag

**Severity:** Critical **Cross-references:** RF-02, RF-01 (context), inventory section 7

**Problem statement:** The "Verify VERSION file" step in `release.yml:43-46` is two `echo`
statements with no comparison or `exit 1`. The build derives the embedded version from `VERSION`
(`build_installer.sh:26`), not the git tag. A tag `v0.24.11` pushed while `VERSION` reads `0.24.10`
produces a release whose installer self-reports the wrong version.

**Impact:** Silent version mismatch in shipped artifacts - a release-integrity defect that breaks
`--github --version X` installs and version-based upgrade detection.

**Recommendation:** Replace the echo with
`[ "$(cat VERSION)" = "${GITHUB_REF#refs/tags/v}" ] || { echo "VERSION mismatch"; exit 1; }` before
the build step, and mirror it in `make release-check`.

#### CF-019 - Docker integration tests excluded from release gate

**Severity:** High **Cross-references:** RF-03, RF-01, test-coverage cross-validation gap

**Problem statement:** `docker-tests.yml:6-8` is `workflow_dispatch` only. `release.yml` runs
`make lint` and `make test-full` but never triggers or requires the Docker tests. The CI `validate`
job runs the installer on Ubuntu (not an Oracle container) and does not exercise `oraenv.sh`,
`oradba_homes.sh`, or plugin discovery end-to-end.

**Impact:** No automated end-to-end installer validation against a real Oracle container before
release; the same-day patch cadence (RF-01) ships fixes with no integration gate.

**Recommendation:** Add a scheduled nightly run to `docker-tests.yml` and require a recent
successful run as a status check before release tags. For v1.0.0 require a documented passing Docker
integration run as a release-checklist item.

#### CF-026 - Release notes/tag/CHANGELOG drift

**Severity:** Medium **Cross-references:** RF-06, RF-09, DOC-013, DOC-012

**Problem statement:** `doc/releases/v0.24.5.md` is absent though `CHANGELOG.md:113` has a
substantial v0.24.5 entry; `v0.24.4` appears in CHANGELOG with an orphaned `doc/releases/v0.24.4.md`
but no git tag; the release pipeline silently falls back to generic notes when the file is missing
(`release.yml:91-95`); CHANGELOG has zero Keep-a-Changelog comparison diff links (DOC-012).

**Impact:** `--github --version 0.24.4` fails; release bodies silently degrade; CHANGELOG navigation
is broken.

**Recommendation:** Change the `else` branch at `release.yml:95` to `exit 1` when the notes file is
absent; add a `release-notes` prerequisite to `release-check`; retroactively create `v0.24.5.md` and
resolve the v0.24.4 orphan; add CHANGELOG comparison links.

#### CF-034 - No v1.0.0 readiness definition or stabilisation gate

**Severity:** Medium **Cross-references:** RF-01, RF-12, RF-14, RF-07, RF-04, RF-05, RF-13

**Problem statement:** No document defines v1.0.0 stability (API freeze scope, backward-compat
contract, supported Oracle versions, deprecation policy). The commit-tag-release loop has no
stabilisation window (five same-day fixes on 2026-06-25). v0.20.0 breaking renames
(`ORADBA_AUTO_DISCOVER_HOMES` to `ORADBA_AUTO_DISCOVER_ORATAB`, `ORADBA_FULL_DISCOVERY` to
`ORADBA_AUTO_DISCOVER_PRODUCTS`) shipped with no runtime deprecation warnings.
`build_installer.sh:19` uses `set -e` only (RF-07); `shfmt` format-check is absent from CI (RF-04);
shellcheck is unpinned in `release.yml` (RF-05); no git pre-push quality hook (RF-13).

**Impact:** No objective bar for declaring v1.0.0; consumers get no migration warnings; the build
script and release pipeline lack the hardening the source scripts require.

**Recommendation:** Create `doc/v1.0.0-readiness.md` enumerating explicit criteria (API frozen, no
breaking changes from v0.24.x, Docker integration pass on supported Oracle versions, all blocker
findings resolved, minimum soak period). Add an RC tag and freeze period before v1.0.0. Add runtime
deprecation warnings for breaking renames. Set `build_installer.sh` to `set -euo pipefail`, add
`shfmt` to CI, pin shellcheck in release.yml, wire a `pre-push` hook running `make lint`.

----------------------------------------------------------------------------------------------------

### Theme 6: Dependencies and portability

#### CF-011 - No runtime bash version guard

**Severity:** High **Cross-references:** DEP-001

**Problem statement:** Bash 4+ features are used without a version guard: `declare -A`
(`oradba_validate.sh:355`, `oradba_version.sh:183`, `oradba_dsctl.sh:650`), `mapfile`
(`oradba_dbctl.sh:515`, `oraup.sh:661`, `oradba_lsnrctl.sh:435`, many more), `${var,,}`/`${var^^}`
(`oradba_homes.sh:419-505`, `get_seps_pwd.sh:206-225`, `oradba_setup.sh:337`,
`oradba_version.sh:432-461`). macOS ships bash 3.2.57 at `/bin/bash`. No production script guards
the version; `oradba_check.sh` does not check it.

**Impact:** Silent failures or wrong behaviour on stock macOS bash. `oraup.sh:176,189` already shows
the correct fallback pattern.

**Recommendation:** Add a startup guard
`(( BASH_VERSINFO[0] < 4 )) && { echo "ERROR: bash 4.0+ required (found ${BASH_VERSION})" >&2; exit 1; }`
to scripts using bash 4+ features and as a critical check in `oradba_check.sh`; document the
Homebrew bash requirement in CONTRIBUTING.md.

#### CF-012 - GNU-only tools without BSD fallback

**Severity:** High **Cross-references:** DEP-002, DEP-004, DEP-005, DEP-013, BASH-010, BASH-011,
BASH-012, shell.md platform rule

**Problem statement:** `df -BG` (GNU block-size flag) at `oradba_dbca.sh:245` fails silently on
BSD/macOS, leaving `avail_gb` empty so `(( avail_gb < 10 ))` is always true (spurious low-disk
warning); `df -Pm` at `oradba_check.sh:535`/`oradba_install.sh:687` uses the GNU `-m` extension;
`sha256sum` without `shasum` fallback in `oradba_version.sh:164,414,535` and
`oradba_extension.sh:619` (the correct fallback exists in install/check/validate); `realpath`
without fallback in `sync_to_peers.sh:239` (fallback present in `sync_from_peers.sh:244`); `timeout`
(GNU coreutils) used unguarded in `oradba_check.sh:704`, `oradba_dbctl.sh:345`.

**Impact:** macOS/BSD is the declared default target (shell.md), yet disk-space checks silently
pass, integrity checks silently fail or error, and sync/timeout paths abort under `set -e`.

**Recommendation:** Replace `df -BG`/`df -Pm` with `df -k` and convert in awk; add the
`sha256sum || shasum -a 256` fallback (pattern at `oradba_install.sh:280-282`,
`oradba_validate.sh:374-377`); align `sync_to_peers.sh` with the `realpath` fallback; detect
`timeout`/`gtimeout` and proceed without the wrapper if absent.

#### CF-013 - Oracle CLI tools not validated before use

**Severity:** High **Cross-references:** DEP-003

**Problem statement:** `oradba_dbctl.sh:221+` calls `sqlplus -s / as sysdba` with no
`command -v sqlplus` check; `oradba_rman.sh:721,748` builds and runs `${ORACLE_HOME}/bin/rman` with
no `-x` check; `oradba_lsnrctl.sh:296,308` calls `lsnrctl` unguarded. `oradba_dbca.sh:223` shows the
correct `-x` pattern.

**Impact:** Under `set -euo pipefail` a missing binary terminates the script with an unhelpful
"command not found" rather than a clear diagnostic.

**Recommendation:** Add pre-flight existence checks to each script's init/main guard following the
`oradba_dbca.sh:223` pattern.

#### CF-028 - Mutable CI tags, unpinned actions/packages, unverified build downloads

**Severity:** Medium **Cross-references:** DEP-007, DEP-009, DEP-010, DEP-011, DEP-014, RF-10

**Problem statement:** `oehrlis/pandoc:latest-full` and `database/free:latest` are mutable
(`build_pdf.sh:29`, `ci.yml:251`, `release.yml:69`, `docker-tests.yml:36`);
`softprops/action-gh-release@v1` and `dorny/paths-filter@v3` are not SHA-pinned (`release.yml:152`,
`ci.yml:31`); pip/npm packages are unpinned (`docs.yml:48-52`, `ci.yml:232`, `release.yml:52`);
`openssl` is used unchecked in `build_installer.sh:262`; the build downloads the extension template
from GitHub at build time without checksum verification (`build_installer.sh:80-156`, RF-10); docs
build clones external repos at HEAD (`sync_extension_docs.py`).

**Impact:** Non-reproducible builds and a supply-chain surface where a mutable tag, compromised
action, or package update silently changes release artifacts - the release pipeline holds
`contents: write`.

**Recommendation:** Pin Docker images by digest, third-party actions by commit SHA, and pip/npm
packages by version (a `requirements-docs.txt`); add `openssl` existence check and checksum-verify
the extension-template download (or pin via a tracked `.version` file); pin a `ref:` per entry in
`extensions.yml`.

----------------------------------------------------------------------------------------------------

### Theme 7: Performance (env-switch hot path)

#### CF-014 - Eager sourcing and double config load

**Severity:** High **Cross-references:** P-01, P-02, ARCH-009 (overlap with CF-032), ARCH-004
(overlap with CF-017)

**Problem statement:** `oraenv.sh:36-93` unconditionally sources 11-12 library files (~6,500+ LOC)
before any argument is parsed, on every source including repeated profile-sourcing in tmux/screen
panes; none use lazy loading. `oradba_core.conf` is loaded twice (`oraenv.sh:51` and again inside
`load_config()` at `oradba_common.sh:1072`), as is `oradba_local.conf` (`oraenv.sh:56`), with PATH
deduplication re-run each time.

**Impact:** ~6,500 LOC parsed/executed per env switch is the dominant fixed cost; the double config
load pollutes intermediate state and doubles dedupe work.

**Recommendation:** Source path-specific libraries (`oradba_env_parser.sh`, `oradba_env_builder.sh`,
`oradba_env_validator.sh`, `oradba_env_config.sh`) inside the functions that need them; remove the
direct `load_config_file` calls at `oraenv.sh:51,56` and defer to the single `load_config()`.
Coordinate with the CF-032 shared bootstrap and the CF-017 build-path decision.

#### CF-015 - generate_pdb_aliases spawns sqlplus on every env switch

**Severity:** Critical **Cross-references:** P-13

**Problem statement:** `generate_pdb_aliases` (`oradba_database_discovery.sh:164-228`), called from
`oradba_standard.conf:172` on every `source oraenv.sh`, runs `check_database_connection`, spawns
`sqlplus -s / as sysdba` for `SELECT cdb FROM v$database`, and if CDB spawns another for
`SELECT name FROM v$pdbs`. This runs even in `--silent`; `--fast-silent` skips
`generate_sid_aliases` but not `generate_pdb_aliases`.

**Impact:** Each sqlplus spawn is 50-500ms; two per switch adds 100ms-1s to every env switch on a
live system - the dominant runtime (not parse-time) cost.

**Recommendation:** Gate on `ORADBA_LOAD_ALIASES` (or a new `ORADBA_LOAD_PDB_ALIASES` defaulting
false); add a per-SID session guard `ORADBA_PDB_ALIASES_DONE_${ORACLE_SID}`; extend `--fast-silent`
to cover PDB alias generation.

#### CF-016 - Hot-path subshell/fork anti-patterns

**Severity:** High **Cross-references:** P-03, P-04, P-05, P-06, P-07, P-08, P-09, P-10, P-11, P-12,
ARCH-013

**Problem statement:** Repeated forks per env switch: `oradba_dedupe_path` called 5+ times via
subshell with an O(N^2) inner loop (`oradba_common.sh:1022`, `oradba_env_builder.sh:310,976-993`,
`oraenv.sh:694`); `date` fork on every `oradba_log` at debug across ~215 calls
(`oradba_common.sh:264`) plus four redundant `case` passes per call (`:190-245`);
`generate_sid_lists`/`generate_oracle_home_aliases` on every config load
(`oradba_standard.conf:95,110`); `execute_plugin_function_v2` re-sources the plugin file in a
subshell per call with `mktemp` (`oradba_common.sh:1541-1705`); `get_oracle_home_type` re-parses
`oradba_homes.conf` and spawns `echo|awk` 4+ times (`oradba_home_discovery.sh:326-332`,
`oraup.sh:382-427`); `echo|sed` PATH stripping (`oraenv.sh:1243-1244`); 6-process diff in
`capture_sid_config_vars` (`oradba_common.sh:960-989`); unbounded `find -maxdepth 3` when product
discovery enabled (`oradba_home_discovery.sh:980`); 14 `command -v` profiling guards (`:` various).

**Impact:** Cumulative tens-to-hundreds of process forks per env switch, multiplied by every
login/pane/window.

**Recommendation:** Apply bash built-ins and caching per the bash-performance rule: move the log
timestamp behind the level filter and precompute `ORADBA_MIN_LEVEL_VALUE`; replace dedupe O(N^2)
with `awk '!seen[$0]++'` and dedupe PATH once at end of load; session-guard alias/discovery
generation; cache `(product_type, oracle_home)` path results and parse `oradba_homes.conf` once into
an associative array; replace `echo|sed`/`echo|awk` with parameter expansion; replace the 14
`command -v` guards with `declare -f` or a flag variable.

----------------------------------------------------------------------------------------------------

### Theme 8: Documentation accuracy

#### CF-024 - Registry API documentation is wrong

**Severity:** High **Cross-references:** DOC-001, DOC-002

**Problem statement:** `doc/api.md:82` and `doc/architecture.md:154` state the Registry API returns
colon-delimited 6-field entries; actual code uses `readonly REGISTRY_FIELD_SEP="|"` with an 8-field
pipe schema `type|name|home|version|flags|order|alias|desc` (`oradba_registry.sh:31-32`). `api.md`
documents three phantom functions (`oradba_registry_get_by_home`, `_get_status`, `_validate_entry`)
that do not exist and omits four real ones (`_get_databases`, `_get_field`, `_sync_oratab`,
`_discover_all`).

**Impact:** The primary public interface is documented with the wrong format and non-existent
functions - consumers integrating against the Registry API will fail.

**Recommendation:** Correct the delimiter and 8-field schema in api.md and architecture.md; remove
the three phantom functions and document the four real ones after auditing the full function list.

#### CF-025 - Pervasive version and count staleness

**Severity:** High **Cross-references:** DOC-003, DOC-004, DOC-005, DOC-006, DOC-007, DOC-008,
DOC-009, DOC-010, DOC-011, DOC-016, DOC-018, DOC-019, RF-08, F-015, inventory section 7

**Problem statement:** Per-script/library headers show v0.21.0 (`oraenv.sh:9`,
`oradba_registry.sh:9`, `extensions.sh:9`, `Makefile:9`) while `VERSION` is 0.24.11; `api.md:5`
"Last Updated: 2026-01-20" with v0.19.0 pin; test counts conflict (README "1086+", CONTRIBUTING
"1516", doc/README "1086", actual 1,557; `.testmap.yml:8` claims 65 files/1516 tests vs actual
48/1557, F-015); library count stated as 6 vs actual 15 (DOC-006, DOC-008); `src/bin/README.md`
covers 16 of 30 scripts and mis-describes `oraup.sh` as a GitHub updater (DOC-007); plugin count 6
vs 9 contradiction within `development.md` (DOC-010); `doc/README.md` "Last Stable Release: v0.18.5"
and "v1.0.0-dev (Phase 6 of 9)" (DOC-009); `README.md:321` links to a non-existent
`doc/markdown-linting.md` (DOC-011); "437+ functions" vs ~327 (DOC-016); test infrastructure pins
pre-rebrand image `free:23.6.0.0` inconsistent with the correct "Oracle AI Database 26ai" product
name (DOC-018); stale builder function names in `src/lib/README.md` (DOC-019).

**Impact:** Documentation is broadly untrustworthy for a v1.0.0 release; contributors and users
cannot rely on counts, versions, file references, or function names.

**Recommendation:** Adopt the `__VERSION__` placeholder/build-injection pattern for all script
headers (RF-08); add a `make validate-docs-counts` target that fails when documented
test/library/plugin/function counts diverge from actuals; fix the broken link, the oraup.sh
description, the "Phase X of 9" scaffolding, the pre-rebrand Docker image pin (`23.6.0.0` → Oracle
AI Database 26ai image tag), and the stale function listings; update `.testmap.yml:8` and add a CI
check that the annotation matches `find tests -name '*.bats' | wc -l`.

----------------------------------------------------------------------------------------------------

## Clarifications (DECISION-REQUIRED items needing maintainer input)

These are not buried in the table above; resolve before or as part of v1.0.0 planning.

1. **DECISION-REQUIRED (CF-017): environment-build direction.** Two parallel env-build
    implementations exist (inline `oraenv.sh` vs `oradba_build_environment`). Trade-off: completing
    the migration to the structured orchestrator gives one tested, documented path but is L-effort
    and risks regressions in the most-used code path; demoting env_builder to "alternate API" is
    cheaper but leaves dead/under-tested surface advertised in the README. Recommended direction:
    complete the migration if v1.0.0 timeline allows (it also unblocks CF-008 test investment
    landing on the path that is actually used); otherwise demote explicitly and remove env_builder
    from public docs. Needs a human decision because it shapes the public API surface.

2. **DECISION-REQUIRED (CF-004 vs CF-016/P-06): plugin isolation vs fork cost.** The architecture
    review wants `execute_plugin_function_v2` to be the only sanctioned plugin entry (isolation);
    the performance review wants pure path-computing plugin functions (`build_bin_path`,
    `build_lib_path`) called directly to avoid 3 subshell forks per env switch. These pull in
    opposite directions. Recommended reconciliation: keep the isolation wrapper mandatory for
    state-changing/risky calls (`plugin_detect_installation`, `plugin_check_status`) and allow
    direct in-parent calls only for pure, side-effect-free path builders after sourcing the plugin
    once with a documented, audited exception list. Needs a human decision on which functions are
    classified "pure".

3. **CLARIFICATION (carried from architecture review): the `--prepare` to `--install` contract.**
    The test-coverage scan (F-010, cross-validation gap) assumes oradba's installer has a
    `--prepare`/`--install` two-phase contract. `oradba_install.sh` actually uses `INSTALL_MODE` =
    embedded/local/github; the only `--prepare`/`--install` references are in
    `doc/releases/v0.24.11.md:72-74` describing the downstream `odb_datasafe` connector lifecycle.
    Confirm whether oradba is expected to provide a generic prepare/install contract for extensions
    before writing the F-010 cross-validation tests, otherwise the test target does not exist.

4. **CLARIFICATION (carried from security review): severity assumptions.** CF-006 (SEC-03/04)
    severity assumes releases are not yet signed and the `.sha256` is not verified in the documented
    flow - downgrade if a verification step exists outside the reviewed files. CF-022 (SEC-06)
    exploitability depends on the real-world write permissions of `/etc/oratab` and
    `oradba_homes.conf`; if both are strictly root/oracle-owned and never group-writable in
    supported configs, practical severity is lower. CF-002 (SEC-01) severity assumes a common
    022/027 umask; the finding stands regardless because the script sets no explicit restrictive
    permission.

----------------------------------------------------------------------------------------------------

## Source-finding coverage map

Every upstream finding ID is accounted for in exactly one consolidated finding (no new findings were
invented):

- Architecture: ARCH-001 to ARCH-013 -\> CF-003, CF-004, CF-007, CF-017, CF-018, CF-029, CF-030,
  CF-032, CF-005, CF-016
- Bash: BASH-001 to BASH-021 -\> CF-001, CF-005, CF-031, CF-033, CF-012, CF-022, CF-023, CF-016
- Dependencies: DEP-001 to DEP-015 -\> CF-011, CF-012, CF-013, CF-028, CF-006
- Documentation: DOC-001 to DOC-022 -\> CF-024, CF-025, CF-005 (DOC-015)
- Performance: P-01 to P-13 -\> CF-014, CF-015, CF-016
- Release: RF-01 to RF-14 -\> CF-010, CF-019, CF-026, CF-034, CF-027, CF-025 (RF-08), CF-028 (RF-10)
- Security: SEC-01 to SEC-10 -\> CF-002, CF-006, CF-020, CF-021, CF-022, CF-023
- Testing: F-001 to F-018 -\> CF-008, CF-009, CF-027
