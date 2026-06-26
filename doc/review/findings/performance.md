# Performance Review Findings - OraDBA v0.24.11

<!-- markdownlint-disable MD013 -->

**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-opus-4-8) **Scope:** environment
sourcing latency, plugin/module loading, repeated filesystem work, subshell anti-patterns
**Target:** v1.0.0

**Measurement guidance:** To obtain real wall-clock data run:
`PS4='+ $EPOCHREALTIME ' bash -x -c '. /opt/oradba/bin/oraenv.sh FREE --silent' 2>oraenv_trace.txt`
then sort by cumulative delta. On macOS use `BASH_XTRACEFD=3 bash -x ...` to avoid PS4 polluting
interactive output.

----------------------------------------------------------------------------------------------------

## Critical Findings

### P-01 - Eager sourcing of 12+ library files on every oraenv.sh call

**Severity:** Critical **File:** `src/bin/oraenv.sh:36-93`

`oraenv.sh` unconditionally sources the following in sequence before any argument is parsed:

- `oradba_common.sh` (1718 LOC) + transitive: `oradba_home_discovery.sh` (1008),
  `oradba_database_discovery.sh` (441), `oradba_version_metadata.sh` (192)
- `oradba_registry.sh` (376 LOC)
- `oradba_db_functions.sh` (447 LOC)
- `extensions.sh` (803 LOC) - conditional on `ORADBA_AUTO_DISCOVER_EXTENSIONS=true`
- `oradba_env_parser.sh` (404 LOC)
- `oradba_env_builder.sh` (1014 LOC) + conditional transitive: `oradba_env_parser.sh`,
  `oradba_env_config.sh`, `extensions.sh`
- `oradba_env_validator.sh` (425 LOC)
- `oradba_env_config.sh` (399 LOC)

Minimum 11 library files (12 when extensions is active), totalling approximately 6,500+ LOC, are
parsed and executed before `_oraenv_main` is called. This happens on every `source oraenv.sh`
invocation, including repeated profile-sourcing (login, tmux panes, screen windows). None use
deferred/lazy loading.

**Impact:** Bash must parse and execute ~6,500 LOC of shell library code on each `source oraenv.sh`
call. This is the dominant fixed cost of every env switch.

**Recommendation (analysis only):**

- Libraries needed only for specific code paths (`oradba_env_parser.sh`, `oradba_env_builder.sh`,
  `oradba_env_validator.sh`, `oradba_env_config.sh`) should be sourced inside the functions that
  require them, not at startup top-level.
- `oradba_env_builder.sh:112-137` itself defensively re-sources `oradba_env_parser.sh`,
  `oradba_env_config.sh`, and `extensions.sh` - this is triple-guarded but still runs the guard
  check and file-existence test on every load.

----------------------------------------------------------------------------------------------------

### P-13 - `generate_pdb_aliases` unconditionally attempts two sqlplus connections per env switch

**Severity:** Critical **Files:** `src/etc/oradba_standard.conf:172`,
`src/lib/oradba_database_discovery.sh:164-228`

`generate_pdb_aliases` is called from `oradba_standard.conf` which is sourced by `load_config()` on
every `source oraenv.sh`. The function: (1) calls `check_database_connection`, (2) spawns
`sqlplus -s / as sysdba` to query `SELECT cdb FROM v$database`, (3) if CDB, spawns another
`sqlplus -s / as sysdba` to query `SELECT name FROM v$pdbs`. This runs even in `--silent` mode
whenever `ORACLE_SID` is set and `ORADBA_NO_PDB_ALIASES` is not `true`. The `--fast-silent` flag
sets `ORADBA_LOAD_ALIASES=false` which skips `generate_sid_aliases` but does NOT skip
`generate_pdb_aliases`.

**Impact:** Spawning the Oracle sqlplus binary takes 50-500ms depending on ORACLE_HOME location and
system load. Two invocations = 100ms-1s added to every env switch on a live system.

**Recommendation (analysis only):**

- Gate `generate_pdb_aliases` on `ORADBA_LOAD_ALIASES` (same flag gating `generate_sid_aliases`) or
  introduce `ORADBA_LOAD_PDB_ALIASES` defaulting to `false`.
- Add a session guard `ORADBA_PDB_ALIASES_DONE_${ORACLE_SID}` so PDB aliases are generated at most
  once per SID per session.
- Extend `--fast-silent` to cover PDB alias generation by checking `ORAENV_FAST_SILENT` before the
  `generate_pdb_aliases` call in `oradba_standard.conf`.

----------------------------------------------------------------------------------------------------

## High Findings

### P-02 - `oradba_core.conf` sourced twice per `oraenv.sh` invocation

**Severity:** High **Files:** `src/bin/oraenv.sh:51`, `src/lib/oradba_common.sh:1072`

`load_config_file "${config_dir}/oradba_core.conf"` is called at `oraenv.sh:51` directly during
startup, and again inside `load_config()` at `oradba_common.sh:1072`. The full config hierarchy (5
files) is also loaded by `load_config()` inside `_oraenv_load_configurations`. The extra direct
calls at lines 51 and 56 mean `oradba_core.conf` and `oradba_local.conf` are sourced, PATH
deduplication run, then the same files are re-sourced and PATH-deduplication re-run inside
`load_config()`.

**Impact:** Double load pollutes the environment with intermediate state. Each `load_config_file`
invocation conditionally spawns a subshell for `oradba_dedupe_path` (see P-04).

**Recommendation (analysis only):** Remove the direct `load_config_file` calls at `oraenv.sh:51,56`.
Bootstrap the bare minimum (path to config dir, `ORADBA_PREFIX`) from the filesystem path only, then
defer all config loading to the single `load_config()` call inside `_oraenv_load_configurations`.

----------------------------------------------------------------------------------------------------

### P-03 - `date` subshell spawned on every `oradba_log` call in debug mode

**Severity:** High **File:** `src/lib/oradba_common.sh:264`

`timestamp="$(date '+%Y-%m-%d %H:%M:%S')"` runs unconditionally inside `oradba_log()`. At
`ORADBA_LOG_LEVEL=DEBUG` or `ORADBA_PLUGIN_DEBUG=true`, every single log call spawns a `date`
process. The startup chain has ~215 `oradba_log` calls across all libraries.

**Impact:** At DEBUG level: 215 `date` forks per env setup. At INFO level: the repeated two-pass
`case` normalization (lines 190-219, then 237-245) is unnecessary work on every suppressed call.

**Recommendation (analysis only):**

- Move `timestamp=` to after the level-filter check (after line 248) so it only runs when a message
  is actually emitted.
- Merge the two `case` blocks for `level_upper` and `min_level_upper` normalization - both do the
  same string mapping.
- On bash 5+ (Linux): `printf '%(%Y-%m-%d %H:%M:%S)T' -1` avoids the `date` fork entirely. Add as a
  platform-conditional fast path.

----------------------------------------------------------------------------------------------------

### P-04 - `oradba_dedupe_path` called via subshell at least 5 times per startup with O(N^2) inner loop

**Severity:** High **Files:** `src/lib/oradba_common.sh:1022`,
`src/lib/oradba_env_builder.sh:310,976,981,985,989,993`, `src/bin/oraenv.sh:694`

Each call is a subshell expansion `"$(oradba_dedupe_path "$PATH")"` (process fork). The function
(`src/lib/oradba_env_builder.sh:79-110`) has an O(N^2) inner loop: for each of N path directories it
iterates the `seen_paths` array looking for duplicates. With a typical PATH of 20-30 entries this is
400-900 string comparisons per call, multiplied by 5+ call sites.

**Impact:** Medium-High. 5 subshell forks at 5-10ms each on macOS = 25-50ms fixed cost per env
switch from path deduplication alone.

**Recommendation (analysis only):**

- Replace the O(N^2) bash loop with a single `awk '!seen[$0]++'` via process substitution.
- Consolidate: deduplicate PATH exactly once at the very end of `_oraenv_load_configurations`, not
  after each config file load.
- For the `load_config_file` path: test `[[ ":${PATH}:" != *":${new_entry}:"* ]]` before appending
  to avoid the need to deduplicate at all.

----------------------------------------------------------------------------------------------------

### P-05 - `generate_sid_lists` and `generate_oracle_home_aliases` execute on every config load

**Severity:** High **File:** `src/etc/oradba_standard.conf:95,110`

`oradba_standard.conf` is sourced by `load_config()` on every `source oraenv.sh`. It unconditionally
calls `generate_sid_lists` (reads and parses oratab, reads `oradba_homes.conf`) and
`generate_oracle_home_aliases` (reads `oradba_homes.conf` line-by-line and calls `alias` for each
entry). Both run on every SID switch because `load_config()` always loads `oradba_standard.conf`.
`generate_sid_lists` also conditionally sources `oradba_registry.sh` a second time.

**Recommendation (analysis only):**

- Wrap in a session-level guard `ORADBA_ALIAS_GENERATION_DONE`. Once aliases are generated per
  session they do not need regenerating unless oratab/`oradba_homes.conf` changes.
- Move the SID-list generation out of `oradba_standard.conf` into a dedicated first-login hook that
  checks the session guard.

----------------------------------------------------------------------------------------------------

### P-06 - `execute_plugin_function_v2` forks a full subshell and re-sources the plugin file on every call

**Severity:** High **Files:** `src/lib/oradba_common.sh:1541-1705`,
`src/lib/oradba_env_builder.sh:191,263,403`, `src/lib/oradba_home_discovery.sh:482`

The function spawns a `$()` subshell, sources the plugin `.sh` file from disk inside that subshell,
runs the plugin function, and returns via `eval`. Each call: 1 subshell fork + 1 disk read + 1
`source` parse of a 200-900 LOC plugin file + `mktemp` syscall + `trap` registration. A typical env
switch invokes this 2-3 times minimum. The plugin file is already sourced into the parent shell in
several code paths - the isolation wrapper then re-sources it redundantly.

**Impact:** High. 3 subshell forks with plugin sourcing per env switch. The `mktemp` call at line
1584 is an additional filesystem write on every invocation.

**Recommendation (analysis only):**

- For PATH/library-path construction (`build_bin_path`, `build_lib_path`), isolation is not needed -
  these functions only compute path strings. Call them directly in the parent shell after sourcing
  the plugin once.
- Reserve `execute_plugin_function_v2` for genuinely risky calls (e.g.,
  `plugin_detect_installation`).
- Cache results of `build_bin_path`/`build_lib_path` per `(product_type, oracle_home)` pair for the
  session lifetime.

----------------------------------------------------------------------------------------------------

### P-07 - `get_oracle_home_type` parses `oradba_homes.conf` from disk on every call, then spawns `echo|awk`

**Severity:** High **Files:** `src/lib/oradba_home_discovery.sh:326-332,292-315`,
`src/bin/oraenv.sh:559,748,990-991`, `src/lib/oradba_common.sh:718`

`parse_oracle_home` loops through `oradba_homes.conf` line by line via `while IFS=: read`. The
`echo|awk` then spawns two additional processes just to extract field 3. Three separate functions
(`get_oracle_home_type`, `get_oracle_home_path`, `get_oracle_home_alias`) each independently call
`parse_oracle_home` and spawn `echo|awk`. `get_oracle_home_type` is called 4 times in `oraenv.sh`
per env switch.

**Impact:** Medium-High. 4+ calls x (file read + 2 process forks) per env switch = 8+ process forks
plus 4 disk reads of `oradba_homes.conf`.

**Recommendation (analysis only):**

- Replace `echo "${home_info}" | awk '{print $N}'` with bash parameter expansion:
  `read -r _f1 _f2 type _rest <<< "${home_info}"`.
- Parse `oradba_homes.conf` once per session into an associative array indexed by home name; all
  type/path/alias lookups become O(1) array reads with no disk I/O or forking.
- Merge `get_oracle_home_type`, `get_oracle_home_path`, `get_oracle_home_alias` into a single
  `parse_oracle_home_to_vars` function that sets multiple named variables in one pass.

----------------------------------------------------------------------------------------------------

## Medium Findings

### P-08 - `_oraenv_unset_old_env` strips PATH and LD_LIBRARY_PATH via `echo|sed`

**Severity:** Medium **File:** `src/bin/oraenv.sh:1243-1244`

``` bash
PATH=$(echo "$PATH" | sed -e "s|${ORACLE_HOME}/bin:||g" -e "s|:${ORACLE_HOME}/bin||g")
LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | sed -e ...)
```

4 process forks (echo + sed for each of 2 variables) per env switch. The bash-builtin equivalent
uses `${PATH//${ORACLE_HOME}\/bin:/}` with zero forks.

**Recommendation (analysis only):** Replace with bash parameter expansion patterns for all
positional cases of path removal.

----------------------------------------------------------------------------------------------------

### P-09 - `capture_sid_config_vars` spawns 6 processes per SID config load

**Severity:** Medium **File:** `src/lib/oradba_common.sh:960-989`

``` bash
vars_before=$(compgen -e | sort)
# ... source config ...
vars_after=$(compgen -e | sort)
new_vars=$(comm -13 <(echo "$vars_before") <(echo "$vars_after") | tr '\n' ' ')
```

This spawns: `compgen|sort` (2 subshells) twice + `comm` + `echo` + `echo` + `tr` = 6 process forks
per SID config load (called at `oradba_common.sh:1110` when a `sid.SID.conf` exists).

**Recommendation (analysis only):**

- Replace with a pure-bash associative array diff (snapshot `compgen -e` into a bash array
  before/after sourcing).
- Or require all SID-config variables to carry a `ORADBA_SID_` prefix; cleanup becomes
  `for var in "${!ORADBA_SID_@}"; do unset "$var"; done` with zero process forks.

----------------------------------------------------------------------------------------------------

### P-10 - `oradba_log` level normalization performs four redundant `case` passes per call

**Severity:** Medium **File:** `src/lib/oradba_common.sh:190-245`

Every call performs: 4 `case` evaluations (2 normalization + 2 integer conversion). With 215+ calls
across the startup chain, the minimum-level numeric value is re-computed from `ORADBA_LOG_LEVEL` on
every call even though it is a session constant.

**Recommendation (analysis only):** Compute `ORADBA_MIN_LEVEL_VALUE` once at init time and export it
as a pre-computed integer. Collapse the two `case` blocks for `level_upper` and its integer value
into one combined `case`.

----------------------------------------------------------------------------------------------------

### P-11 - `auto_discover_oracle_homes` runs `find -maxdepth 3` filesystem scan when triggered

**Severity:** Medium (conditional - only when `ORADBA_AUTO_DISCOVER_PRODUCTS=true`) **File:**
`src/lib/oradba_home_discovery.sh:980`

When `ORADBA_AUTO_DISCOVER_PRODUCTS=true`, this scan runs during env setup. `${ORACLE_BASE}/product`
can contain hundreds of directories across 3 levels. Inside the loop, each directory calls
`detect_product_type` (multiple `-d` and `-f` stat checks). No equivalent guard to
`ORADBA_REGISTRY_SYNC_DONE` exists for the full product discovery scan. The
`is_subdirectory_of_oracle_home` helper at line 795 calls `cd && pwd -P` (two subshells) for every
candidate directory.

**Recommendation (analysis only):**

- Add a session-level guard `ORADBA_PRODUCT_DISCOVERY_DONE` mirroring `ORADBA_REGISTRY_SYNC_DONE`.
- Cache discovery results to `oradba_homes.conf` and skip the scan entirely if `oradba_homes.conf`
  is non-empty and newer than `${ORACLE_BASE}/product` (use `-nt` file comparison).

----------------------------------------------------------------------------------------------------

## Low Findings

### P-12 - 14 `command -v` guards for profiling function in oradba_common.sh

**Severity:** Low **Files:** `src/lib/oradba_common.sh` (14 occurrences),
`src/bin/oraenv.sh:118-129,155-168`

`_oraenv_now_ms` spawns `python3` or `perl` to get millisecond timestamps. While
`_oraenv_profile_mark` guards on `_ORAENV_PROFILE_ENABLED`, 14 `command -v _oraenv_profile_mark`
guards in `oradba_common.sh` each spawn a subprocess for the lookup.

**Recommendation (analysis only):** Replace `command -v _oraenv_profile_mark &>/dev/null` with
`declare -f _oraenv_profile_mark >/dev/null 2>&1` (builtin, no fork) or export a simple flag
variable `ORADBA_PROFILE_ACTIVE` and test `[[ "${ORADBA_PROFILE_ACTIVE:-false}" == "true" ]]` to
eliminate all 14 `command -v` guards.

----------------------------------------------------------------------------------------------------

## Summary Table

| ID   | Severity | Title                                                                         |
|------|----------|-------------------------------------------------------------------------------|
| P-01 | Critical | Eager sourcing of 12+ library files on every oraenv.sh call                   |
| P-13 | Critical | `generate_pdb_aliases` spawns 2-3 sqlplus per env switch                      |
| P-02 | High     | `oradba_core.conf` sourced twice per invocation                               |
| P-03 | High     | `date` subshell on every `oradba_log` call at debug level                     |
| P-04 | High     | `oradba_dedupe_path` called 5+ times via subshell with O(N^2) inner loop      |
| P-05 | High     | `generate_sid_lists` and home alias generation on every config reload         |
| P-06 | High     | `execute_plugin_function_v2` re-sources plugin file in subshell per call      |
| P-07 | High     | `get_oracle_home_type` re-parses config file and spawns `echo`+`awk` per call |
| P-08 | Medium   | `_oraenv_unset_old_env` uses `echo`+`sed` for PATH manipulation               |
| P-09 | Medium   | `capture_sid_config_vars` spawns 6 processes per SID config load              |
| P-10 | Medium   | `oradba_log` performs 4 `case` evaluations per call for constant data         |
| P-11 | Medium   | `auto_discover_oracle_homes` runs unbounded `find` scan when enabled          |
| P-12 | Low      | 14 `command -v` guards for profiling function in oradba_common.sh             |
