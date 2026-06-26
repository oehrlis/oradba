# Bash Robustness Review Findings - OraDBA v0.24.11

**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-opus-4-8) **Scope:** set -euo
pipefail correctness, (( counter++ )) foot-guns, quoting, BSD portability, error routing **Target:**
v1.0.0

Severity scale:

- Critical - script exits or corrupts data silently
- High - operational failure under normal use
- Medium - latent defect triggered by specific inputs
- Low - style/portability concern

----------------------------------------------------------------------------------------------------

## Group A: Remaining `(( counter++ ))` Zero-Start Foot-Gun - Recent Regression Class

Root cause identical to commit `4db7ccf`
(`fix(oraup): remove ((idx++)) that exits script under set -e`). Bash evaluates `(( expr ))` using
the pre-increment value. When a counter starts at 0 and `set -e` is active, `(( 0++ ))` has exit
code 1 (the old value is falsy), triggering immediate script exit. The fix in `4db7ccf` covered
`oraup.sh` but not the scripts below.

### BASH-001 - `(( entry_count++ ))` at zero kills `oradba_dsctl.sh` on first connector found

**Severity:** Critical **Files:** `src/bin/oradba_dsctl.sh:146` (`local entry_count=0`),
`src/bin/oradba_dsctl.sh:148` (`((entry_count++))`)

`get_connectors()` initialises `entry_count=0` then immediately increments with `((entry_count++))`
as the first statement in the while-read loop body. The first iteration evaluates `(( 0++ ))`, exit
code 1 under Bash arithmetic rules, triggering `set -e` exit. Any DataSafe environment with at least
one connector registration silently aborts every `dsctl start/stop/restart/status` invocation.

**Recommendation (analysis only):** Replace bare `((entry_count++))` with
`(( entry_count++ )) || true` or `entry_count=$(( entry_count + 1 ))`. Apply the `|| true` pattern
already used in `oradba_check.sh:79` and `oradba_install.sh:619`.

----------------------------------------------------------------------------------------------------

### BASH-002 - `(( success_count++ ))` and `(( failure_count++ ))` at zero kill oradba_dsctl.sh, oradba_dbctl.sh, oradba_lsnrctl.sh

**Severity:** Critical **Files:**

- `src/bin/oradba_dsctl.sh:672-673` (both init to 0), `:686,689,695,698,705,708`
- `src/bin/oradba_dbctl.sh:556-557` (both init to 0), `:566,569,575,578,585,588`
- `src/bin/oradba_lsnrctl.sh:460-461` (both init to 0), `:470,473,479,482,489,492`

Counters initialised to 0 outside the loop. The first successful operation enters the `then` branch
and executes `((success_count++))` from 0, exit code 1, aborting the script. This means the first
start/stop/restart of any connector, database, or listener always terminates the script silently.

**Recommendation (analysis only):** Add `|| true` to every `(( success_count++ ))`,
`(( failure_count++ ))` statement or switch to `counter=$(( counter + 1 ))`.

----------------------------------------------------------------------------------------------------

### BASH-003 - `(( errors++ ))` at zero aborts `oradba_dbca.sh` on first validation failure

**Severity:** Critical **Files:** `src/bin/oradba_dbca.sh:455` (`local errors=0`),
`src/bin/oradba_dbca.sh:460,465,471,477,482`

`validate_arguments()` sets `errors=0` then increments inside each `if` branch that detects a
missing argument. The first validation failure causes `((errors++))` with `errors=0` to exit the
script before remaining checks run and before any usage message is printed.

**Recommendation (analysis only):** `|| true` guard or `errors=$(( errors + 1 ))`.

----------------------------------------------------------------------------------------------------

### BASH-004 - Bare `(( checked_count++ ))` at zero aborts `oradba_version.sh` on first extension check

**Severity:** Critical **Files:** `src/bin/oradba_version.sh:334` (`local checked_count=0`),
`src/bin/oradba_version.sh:402`

Unlike other instances this increment is a bare statement, not inside an `if/else` branch. It
executes unconditionally at the top of the loop body, guaranteed to fire as `(( 0++ ))` on the first
iteration.

**Recommendation (analysis only):** `(( checked_count++ )) || true` or
`checked_count=$(( checked_count + 1 ))`.

----------------------------------------------------------------------------------------------------

### BASH-005 - `(( installed++ ))` and `(( failed++ ))` at zero abort `oradba_logrotate.sh`

**Severity:** High **Files:** `src/bin/oradba_logrotate.sh:184-185` (both init to 0),
`src/bin/oradba_logrotate.sh:207,210`

The first logrotate template successfully installed triggers `((installed++))` from 0, aborting
before the installation summary is printed or further templates are processed.

**Recommendation (analysis only):** `|| true` guard.

----------------------------------------------------------------------------------------------------

### BASH-006 - `(( errors++ ))` at zero aborts `oradba_sqlnet.sh` on first config validation failure

**Severity:** High **Files:** `src/bin/oradba_sqlnet.sh:655` (`local errors=0`),
`src/bin/oradba_sqlnet.sh:668`

If `sqlnet.ora` is missing or unreadable, the first `((errors++))` fires from zero, aborting the
validation function silently under `set -euo pipefail`.

**Recommendation (analysis only):** `|| true` guard.

----------------------------------------------------------------------------------------------------

### BASH-014 - Library `(( count++ ))` instances starting at 0 are hazardous when sourced into `set -e` callers

**Severity:** Medium **Files:** `src/lib/oradba_env_changes.sh:200` (`count=0`),
`src/lib/oradba_env_changes.sh:203` (`((count++))`)

Library files inherit the caller's `set -e` state. `oradba_env_changes.sh` initialises `count=0` at
line 200 and calls `((count++))` at line 203 inside a for-loop over config files. When sourced by
`oradba_dsctl.sh` or `oraup.sh` (both `set -euo pipefail`), the first config file processed triggers
`(( 0++ ))` and aborts.

**Recommendation (analysis only):** Add `|| true` to `oradba_env_changes.sh:203`. Review all library
files for `count=0` followed by `((count++))` before the v1.0.0 hardening pass. Note:
`oradba_common.sh:1282,1310` (count=1) and `oradba_home_discovery.sh:880` (counter=1),
`oradba_registry.sh:288` (counter=2) are all safe.

----------------------------------------------------------------------------------------------------

## Group B: Missing or Incomplete `set -euo pipefail`

### BASH-007 - `oradba_homes.sh` has no `set -euo pipefail`

**Severity:** High **File:** `src/bin/oradba_homes.sh:1-20` (no `set` statement present)

All 30 bin scripts are required to carry `set -euo pipefail` per project rules. Without it, failed
commands in `remove_home`, `validate_homes`, `import_config`, and `dedupe_homes` are silently
swallowed. The 13 `((counter++))` instances at lines 702, 861, 951, 961, 1082, 1089, 1097, 1108,
1114, 1122, 1216, 1219, 1225 are all from-zero increments - currently harmless only because `set -e`
is absent. This changes the moment `set -euo pipefail` is added without simultaneous `|| true`
guards.

**Recommendation (analysis only):** Add `set -euo pipefail` immediately after the shebang, and add
`|| true` to every `(( ++ ))` at the listed lines in the same commit.

----------------------------------------------------------------------------------------------------

### BASH-008 - `oradba_extension.sh` has only `set -o pipefail`, missing `-e` and `-u`

**Severity:** High **File:** `src/bin/oradba_extension.sh:17` (`set -o pipefail`)

Without `set -e`, any failed command in `cmd_create`, `cmd_add`, `update_extension`, `cmd_enable`,
`cmd_disable` continues silently. Without `set -u`, unset variables expand to empty strings - a
missing `ext_path` in `update_extension` would cause `cd ""` at line 603.

**Recommendation (analysis only):** Change line 17 to `set -euo pipefail`. Then audit all `(( ++ ))`
increments (lines 1541, 1543, 1685, 1699, 1734, 1748) since they would become hazardous.

----------------------------------------------------------------------------------------------------

## Group C: Error Routing to stdout Instead of stderr

### BASH-009 - Several `echo "ERROR:"` calls missing `>&2` redirect

**Severity:** Medium **Files:**

- `src/bin/get_seps_pwd.sh:32`, `src/bin/oradba_dsctl.sh:34`, `src/bin/oradba_dbctl.sh:34`,
  `src/bin/oradba_lsnrctl.sh:33`, `src/bin/oradba_services_root.sh:36` - library-not-found errors
- `src/bin/oradba_env.sh:554,585,600` - sourced script error messages

Callers that capture script output with `$()` will receive the error message in the variable instead
of seeing it on the terminal. For `oradba_env.sh` (which is sourced), ERROR messages on stdout can
corrupt environment-setup pipelines.

**Recommendation (analysis only):** Add `>&2` to all listed `echo "ERROR:"` calls. Project shell
rule already requires `echo "ERROR: ..." >&2`.

----------------------------------------------------------------------------------------------------

### BASH-019 - `oradba_env.sh` error messages at lines 554, 585, 600 write to stdout instead of stderr

**Severity:** Medium **File:** `src/bin/oradba_env.sh:554,585,600`

Inconsistent with lines 298, 416, 490, 497, 524, 735 in the same file which all correctly use `>&2`.

**Recommendation (analysis only):** Add `>&2` to the three `echo "ERROR:"` lines.

----------------------------------------------------------------------------------------------------

## Group D: BSD/macOS Portability Violations

### BASH-010 - `df -BG` is GNU-only; fails silently on BSD/macOS

**Severity:** Medium **File:** `src/bin/oradba_dbca.sh:245`

``` bash
df -BG "${data_dir_parent}" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//'
```

BSD `df` does not accept `-B` (block size) flag. The command fails silently (stderr suppressed),
`avail_gb` is empty, and `(( avail_gb < 10 ))` evaluates to `(( 0 < 10 ))` - always true, triggering
a spurious "low disk space" warning for every run on macOS. The project rules require macOS/BSD as
the default target.

**Recommendation (analysis only):** Replace with `df -k` (POSIX) then convert KB to GB in awk, or
detect platform with `[[ "$(uname)" == "Darwin" ]]` and branch.

----------------------------------------------------------------------------------------------------

### BASH-012 - `sha256sum` used without `shasum` fallback in `oradba_extension.sh`

**Severity:** Medium **File:** `src/bin/oradba_extension.sh:619`

`sha256sum` is a GNU coreutils command not available on macOS (BSD equivalent: `shasum -a 256`). The
`2>/dev/null` suppression means an empty `current_checksum` is returned silently, so every file
appears unmodified during `--update` on macOS. `oradba_install.sh:280-282` already implements the
correct `sha256sum || shasum -a 256` fallback pattern.

**Recommendation (analysis only):** Mirror the `oradba_install.sh` fallback pattern.

----------------------------------------------------------------------------------------------------

### BASH-011 - `df -Pm` is non-POSIX; `-m` flag is GNU extension

**Severity:** Low **Files:** `src/bin/oradba_check.sh:535`, `src/bin/oradba_install.sh:687`

BSD `df` does not accept `-m` (megabytes). The command fails silently with `2>/dev/null`
suppression, making `available_mb` empty. Disk space pre-flight checks silently pass.

**Recommendation (analysis only):** Use `df -k` and divide by 1024 in awk for a portable MB value.

----------------------------------------------------------------------------------------------------

### BASH-013 - `date -d` (GNU) parse failure returns 0, producing absurd uptime

**Severity:** Low **File:** `src/lib/oradba_db_functions.sh:269`

The macOS/GNU branching is correctly implemented with `||`. However the `2>/dev/null` suppression
means a parse failure returns "0", producing an uptime of ~55 years. The issue is correctness not
portability.

**Recommendation (analysis only):** Add a check that `startup_epoch` is non-zero and plausible
before computing uptime.

----------------------------------------------------------------------------------------------------

## Group E: set -e Correctness - Subshell and Local Interactions

### BASH-015 - `grep ... | grep -qv` pipeline in `oraup.sh` is accidentally correct under pipefail

**Severity:** Medium **File:** `src/bin/oraup.sh:215,364`

``` bash
grep "[t]nslsnr" <<< "$process_list" | grep -qv "datasafe\|oracle_cman_home"
```

When no standard listener is running, `grep "[t]nslsnr]"` returns exit code 1. Both call sites are
inside `if` conditionals, so `set -e` does not abort. However if this pattern is ever moved to a
standalone statement, it would abort the script. Intent is fragile.

**Recommendation (analysis only):** Rewrite with an explicit two-step: check for any match first,
then filter.

----------------------------------------------------------------------------------------------------

## Group F: Security-Adjacent Shell Practices

### BASH-017 - `eval` on user-controlled variable names in `oraenv.sh` without sanitisation

**Severity:** Medium **File:** `src/bin/oraenv.sh:401,402,409,419,424,425,436,443`

Pattern: `eval "${sids_var}=()"`, `eval "${homes_var}+=(\\"${sid}\\")"`, where `sids_var` and
`homes_var` are function parameters. If a caller passes a malicious string as `sids_var`, the eval
executes arbitrary code. Current callers are all internal functions in the same file (low immediate
risk) but the pattern violates defensive coding for sourced environment scripts.

**Recommendation (analysis only):** Replace with Bash 4.3 `local -n sids_ref="$2"` nameref syntax.
If Bash 3.2 compatibility is required, add a variable-name sanitisation guard:
`[[ "$sids_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1`.

----------------------------------------------------------------------------------------------------

### BASH-016 - No EXIT trap for temp file cleanup in `oradba_extension.sh`

**Severity:** Low **File:** `src/bin/oradba_extension.sh:784,848,1047,1073,1104` (multiple
`mktemp -d` calls; no `trap ... EXIT` present)

All 38 `rm -rf` cleanup calls are on normal-path code. SIGTERM or unexpected `set -e` exit (from
BASH-008 remediation) would leave `mktemp -d` directories under `/tmp`.

**Recommendation (analysis only):** Add `trap 'rm -rf "${_EXT_TMPDIR:-}"' EXIT` with a single
registered temp root, similar to `oradba_install.sh:225`.

----------------------------------------------------------------------------------------------------

### BASH-018 - `oradba_homes.sh` dedupe temp file uses `$$` PID suffix instead of `mktemp`

**Severity:** Low **File:** `src/bin/oradba_homes.sh:1177`

PID-based temp file names are predictable. Concurrent executions by two users with write access to
the same config file could collide or corrupt each other's work.

**Recommendation (analysis only):** Replace with `temp_file=$(mktemp "${homes_file}.dedup.XXXXXX")`.

----------------------------------------------------------------------------------------------------

### BASH-020 - `find ... | read` as boolean idiom is fragile under pipefail

**Severity:** Low **File:** `src/bin/oradba_extension.sh:680`

`if find "${ext_path}" -name "*.save" -type f | read` - works accidentally under pipefail but is
non-obvious to readers. Also runs a redundant `find` since the loop at line 683 re-runs it.

**Recommendation (analysis only):** Replace with `find ... -print -quit 2>/dev/null | grep -q .` or
eliminate the guard and let the inner loop process zero iterations.

----------------------------------------------------------------------------------------------------

## Group H: Determinism / Locale

### BASH-021 - `sort` and `comm` calls lack `LC_ALL=C`

**Severity:** Low **Files:** `src/lib/oradba_common.sh:967,977`, `src/bin/oradba_sqlnet.sh:641`,
`src/bin/oradba_install.sh:1912,1920,1932`

Without `LC_ALL=C`, the `comm -13` comparison of sorted env-var lists in `oradba_common.sh:980` may
misidentify new variables if locale collation differs between `vars_before` and `vars_after`
captures.

**Recommendation (analysis only):** Prefix sort-then-compare operations with `LC_ALL=C`.

----------------------------------------------------------------------------------------------------

## Regression-Class Cross-Reference

Scripts/counters in the same defect class as commits `4db7ccf` and `fa36489`:

| ID       | Script                | Counter variable | Trigger condition                      |
|----------|-----------------------|------------------|----------------------------------------|
| BASH-001 | oradba_dsctl.sh       | entry_count      | any DataSafe connector in registry     |
| BASH-002 | oradba_dsctl.sh       | success_count    | first start/stop/restart succeeds      |
| BASH-002 | oradba_dbctl.sh       | success_count    | first db start/stop succeeds           |
| BASH-002 | oradba_lsnrctl.sh     | success_count    | first listener operation succeeds      |
| BASH-003 | oradba_dbca.sh        | errors           | any missing required argument          |
| BASH-004 | oradba_version.sh     | checked_count    | any extension with .extension.checksum |
| BASH-005 | oradba_logrotate.sh   | installed        | first template installed successfully  |
| BASH-006 | oradba_sqlnet.sh      | errors           | sqlnet.ora absent or unreadable        |
| BASH-014 | oradba_env_changes.sh | count            | any config file exists at store time   |

----------------------------------------------------------------------------------------------------

## Summary Table

| ID       | Severity | Title                                                                        |
|----------|----------|------------------------------------------------------------------------------|
| BASH-001 | Critical | `(( entry_count++ ))` at zero kills oradba_dsctl.sh on first connector       |
| BASH-002 | Critical | `(( success_count++ ))`/`(( failure_count++ ))` kill dsctl, dbctl, lsnrctl   |
| BASH-003 | Critical | `(( errors++ ))` at zero aborts oradba_dbca.sh on first validation failure   |
| BASH-004 | Critical | Bare `(( checked_count++ ))` at zero aborts oradba_version.sh                |
| BASH-005 | High     | `(( installed++ ))` and `(( failed++ ))` abort oradba_logrotate.sh           |
| BASH-006 | High     | `(( errors++ ))` at zero aborts oradba_sqlnet.sh on first failure            |
| BASH-007 | High     | oradba_homes.sh has no set -euo pipefail                                     |
| BASH-008 | High     | oradba_extension.sh has only set -o pipefail, missing -e -u                  |
| BASH-009 | Medium   | Multiple echo "ERROR:" calls missing \>&2 redirect                           |
| BASH-010 | Medium   | df -BG is GNU-only; fails silently on BSD/macOS                              |
| BASH-012 | Medium   | sha256sum used without shasum fallback in oradba_extension.sh                |
| BASH-014 | Medium   | Library `(( count++ ))` from zero hazardous when sourced into set -e callers |
| BASH-015 | Medium   | grep pipeline in oraup.sh accidentally correct under pipefail                |
| BASH-017 | Medium   | eval on function parameter names in oraenv.sh without sanitisation           |
| BASH-019 | Medium   | oradba_env.sh error messages at lines 554,585,600 go to stdout               |
| BASH-011 | Low      | df -Pm is non-POSIX; -m flag is GNU extension                                |
| BASH-013 | Low      | date -d parse failure returns 0, producing absurd uptime                     |
| BASH-016 | Low      | No EXIT trap for temp file cleanup in oradba_extension.sh                    |
| BASH-018 | Low      | oradba_homes.sh dedupe temp file uses \$\$ PID suffix instead of mktemp      |
| BASH-020 | Low      | find pipe read boolean idiom is fragile under pipefail                       |
| BASH-021 | Low      | sort and comm calls lack LC_ALL=C                                            |
