# Architecture Review Findings - OraDBA v0.24.11

**Generated:** 2026-06-26 **Reviewer:** automated agent (claude-opus-4-8) **Scope:** module
boundaries, coupling, plugin system, Registry API, env subsystem, entry-point layering **Target:**
v1.0.0 stable architecture

----------------------------------------------------------------------------------------------------

## Critical Findings

### ARCH-001 - Duplicate `plugin_check_listener_status` definition in plugin_interface.sh

**Severity:** Critical **File:** `src/lib/plugins/plugin_interface.sh:298` and `:337`

Both lines define `plugin_check_listener_status()`. The first returns `2`/"unavailable" silently as
a category default; the second logs an ERROR and returns `2`. In bash the second definition wins, so
the documented "category default" behaviour at line 298 is dead code. The canonical interface
contract - the single most load-bearing file for the plugin system - is internally contradictory.

**Impact:** Any plugin author or test reading the template gets ambiguous guidance. The
silent-default behaviour cannot be relied on.

**Recommendation (analysis only):** Keep exactly one definition. Decide whether a non-listener
product should silently return unavailable or emit a "not implemented" ERROR, then delete the other.
Add a guard test asserting each interface function name is defined exactly once in the template.

----------------------------------------------------------------------------------------------------

### ARCH-002 - Two competing plugin-loading mechanisms; the safe one is bypassed by 9 direct-source sites

**Severity:** Critical **Files:**

- `src/lib/oradba_common.sh:1541`
- `src/bin/oraup.sh:399`
- `src/bin/oradba_homes.sh:838`
- `src/bin/oradba_dsctl.sh:41`
- `src/bin/oradba_env.sh:138`
- `src/bin/oradba_datasafe_debug.sh:328`
- `src/bin/oraenv.sh:754,920,1028`

`execute_plugin_function_v2()` runs each plugin in a subshell, unsets `TNS_ADMIN`/`plugin_status`,
enforces interface-version and EXPERIMENTAL checks. In parallel, 9 sites source plugins directly
into the caller's shell, bypassing all those guarantees. Plugins loaded via direct `source` leak
their functions and variables (e.g. `plugin_status`, `plugin_name`) into the calling environment.

**Impact:** Cross-plugin contamination is exactly the class of bug `execute_plugin_function_v2` was
built to prevent. Interface-version/EXPERIMENTAL gating is enforced inconsistently.

**Recommendation (analysis only):** Make `execute_plugin_function_v2` (or a thin wrapper) the only
sanctioned entry to plugin behaviour. Where direct-source is required for performance, wrap in an
explicit subshell and document the exception. Before v1.0.0, audit every direct-source site against
the isolation contract.

----------------------------------------------------------------------------------------------------

## High Findings

### ARCH-003 - `ORADBA_BASE` vs `ORADBA_PREFIX` used interchangeably but bootstrapped inconsistently

**Severity:** High **Files:**

- `src/bin/oraup.sh:394`
- `src/bin/oradba_env.sh:136`
- `src/bin/oradba_dsctl.sh:39`
- `src/bin/oradba_homes.sh:832`
- `src/lib/oradba_common.sh:403`
- `src/lib/oradba_registry.sh:77,219`
- `src/lib/oradba_database_discovery.sh:359,390`

Plugin path uses `ORADBA_BASE` in `oraup.sh:394`, `oradba_env.sh:136`, `oradba_dsctl.sh:39`, but
`ORADBA_PREFIX` in `oradba_homes.sh:832`. `get_oratab_path` priority 4 reads
`${ORADBA_BASE}/etc/oratab` while the registry and discovery fallbacks read
`${ORADBA_PREFIX}/etc/oratab`. Bootstrap is ad hoc: `oraenv.sh:31,80` sets both equal;
`oradba_homes.sh:19,22` sets PREFIX then `BASE:-PREFIX`; `oradba_setup.sh:22`, `oraup.sh:20` set
only `BASE`; `oradba_dsctl.sh:26`, `oradba_rman.sh:26` derive `BASE` from `ORADBA_BIN`.

**Impact:** Root-cause class for Data Safe installer path defects. In any installation where the two
variables diverge, plugin discovery, oratab resolution, and config loading silently look in
different trees.

**Recommendation (analysis only):** Define one canonical install-root variable (`ORADBA_BASE`) and
treat `ORADBA_PREFIX` as a deprecated alias. Replace all `${ORADBA_PREFIX}/...` library references
with the canonical one. Introduce a shared bootstrap snippet that resolves the root from
`BASH_SOURCE` and exports both for one release as a compatibility shim.

----------------------------------------------------------------------------------------------------

### ARCH-004 - The env_builder/parser/validator subsystem is not on the primary `oraenv.sh` code path

**Severity:** High **Files:** `src/bin/oraenv.sh:719`, `src/lib/oradba_common.sh:695`,
`src/lib/oradba_env_builder.sh:889`

`oraenv.sh` builds the environment by calling `set_oracle_home_environment` and setting vars inline
(`:985-986,1022`). The dedicated orchestrator `oradba_build_environment`
(`oradba_env_builder.sh:889`) is referenced only by `oradba_env_changes.sh` and the README - no
`src/bin` script calls it (verified: `grep -rln oradba_build_environment src/bin` returns nothing).
Test-coverage scan confirms `oradba_build_environment` and most sub-functions have 0 test
references.

**Impact:** Two parallel environment-building implementations exist. The structured one was intended
to replace the inline logic but the migration stalled. Maintenance happens in one path while the
other rots untested. The 16-library count is inflated by a subsystem the main flow does not use.

**Recommendation (analysis only):** Decide the direction before v1.0.0. Either (a) complete the
migration so `oraenv.sh` delegates to `oradba_build_environment` and retire the inline logic, or (b)
explicitly demote env_builder/validator to "alternate API" status. Do not ship v1.0.0 with both
presented as equal public surface.

----------------------------------------------------------------------------------------------------

### ARCH-005 - Database-status querying implemented three times with three different sqlplus queries

**Severity:** High **Files:** `src/lib/oradba_env_status.sh:42`,
`src/lib/oradba_env_validator.sh:194,238`, `src/lib/oradba_db_functions.sh:60,83`

`oradba_check_db_status` queries `v$instance WHERE instance_name=...`;
`oradba_get_db_status`/`oradba_check_db_running` query `v$instance` via `/ as sysdba` with different
normalisation and status vocabulary (adds NOMOUNT/STARTED);
`get_database_open_mode`/`check_database_connection` form a third variant. Each rolls its own pmon
check and output normalisation.

**Impact:** Three subtly different definitions of "is the database up and in what mode" produce
inconsistent results. Status vocabulary differs (SHUTDOWN vs DOWN vs unavailable), so callers cannot
rely on a stable contract.

**Recommendation (analysis only):** Define one canonical db open-mode function with a fixed output
vocabulary and documented exit-code contract in the status module. Have the validator and
db_functions call it. Remove the redundant sqlplus heredocs.

----------------------------------------------------------------------------------------------------

## Medium Findings

### ARCH-006 - Two independent oratab parsers with overlapping responsibility

**Severity:** Medium **Files:** `src/lib/oradba_database_discovery.sh:32`,
`src/lib/oradba_env_parser.sh:73`, `src/lib/oradba_registry.sh:56-72`

`parse_oratab()` and `oradba_parse_oratab()` both parse oratab; the registry adds a third inline
parse loop. The registry was introduced as the abstraction layer over oratab yet still inlines its
own parse.

**Recommendation (analysis only):** Make the registry the sole oratab reader and have
parser/discovery consume `oradba_registry_get_*`. At minimum, collapse the two library parsers into
one.

----------------------------------------------------------------------------------------------------

### ARCH-007 - Public function naming split between prefixed and unprefixed conventions

**Severity:** Medium **Files:**

- `src/lib/oradba_common.sh`
- `src/lib/oradba_database_discovery.sh`
- `src/lib/oradba_home_discovery.sh`
- `src/lib/oradba_db_functions.sh`

Newer modules use `oradba_` prefix; older core/discovery libs export unprefixed names into the
global shell namespace (`parse_oratab`, `get_oracle_homes_path`, `detect_product_type`,
`set_oracle_home_environment`, `generate_sid_lists`, `check_database_connection`). For a sourced
framework, every unprefixed function is a global-namespace landmine in the user's interactive shell.

**Recommendation (analysis only):** All sourced-into-shell functions should carry `oradba_` (public)
or `_oradba_` (internal) prefix. For v1.0.0, prefix remaining unprefixed public functions and
provide thin deprecated aliases for one release to protect downstream consumers.

----------------------------------------------------------------------------------------------------

### ARCH-008 - `oradba_log` redefined locally, shadowing the real logger

**Severity:** Medium **Files:** `src/bin/oradba_datasafe_debug.sh:320`, `src/bin/oradba_rman.sh`,
`src/templates/script_template.sh`

`oradba_datasafe_debug.sh:320` defines a stub `oradba_log()` inside `main` even though it sources
the real `oradba_common.sh` at `:378`. Once `main` runs it permanently overrides the unified logger
for the rest of the process, losing file logging, levels, and `sanitize_sensitive_data`.

**Recommendation (analysis only):** Only define a fallback `oradba_log` when the real one is absent:
`command -v oradba_log >/dev/null || oradba_log() { ... }`. Never redefine after sourcing common.

----------------------------------------------------------------------------------------------------

### ARCH-009 - Entry-point bootstrap boilerplate duplicated across ~27 scripts with no shared loader

**Severity:** Medium **Files:** 27 `src/bin/*.sh` scripts, each independently computing `SCRIPT_DIR`
and deriving `ORADBA_BASE`/`ORADBA_PREFIX`.

27 scripts independently compute `SCRIPT_DIR` and re-derive `ORADBA_BASE`/`ORADBA_PREFIX` with
slightly different expressions. There is no `load_all_plugins.sh` or shared `bootstrap.sh`. Library
load order is implicit: `oradba_common.sh:1713-1717` unconditionally sources three sub-libs while
`oraenv.sh:35-94` sources six in a hand-ordered sequence.

**Recommendation (analysis only):** Introduce one sourced `lib/oradba_bootstrap.sh` that resolves
the install root from `BASH_SOURCE`, exports the canonical root variable, and sources required
libraries in a single defined order. Every `bin` script sources that one file.

----------------------------------------------------------------------------------------------------

### ARCH-010 - Registry abstraction is incomplete - auto-discovery is a stub and callers still bypass it

**Severity:** Medium **Files:** `src/lib/oradba_registry.sh:320-331`, `:56-96`, `:99-107`

`oradba_registry_discover_all()` logs "Auto-discovery not yet implemented" and returns 0, yet
`oradba_registry_get_all` advertises auto-discovery fallback. The registry inlines its own oratab
and homes.conf parsing rather than delegating to the parser libs.

**Recommendation (analysis only):** Either implement `oradba_registry_discover_all` or remove the
advertised fallback and document discovery as out of scope for v1.0.0. Route the parser/discovery
libs through the registry so it is the single source of truth.

----------------------------------------------------------------------------------------------------

## Low Findings

### ARCH-011 - Dead no-op branch in plugin path resolution

**Severity:** Low **File:** `src/lib/oradba_common.sh:1559-1563`

If plugin file is missing, the fallback rebuilds `plugin_file` with an identical expression before
failing - the branch can never recover. Suggests an intended alternate-location lookup that was
never wired.

**Recommendation (analysis only):** Either remove the redundant rebuild or implement the intended
secondary lookup location (e.g., a user/extension plugin dir).

----------------------------------------------------------------------------------------------------

### ARCH-012 - `set -euo pipefail` gaps on two non-sourced entry points

**Severity:** Low **Files:** `src/bin/oradba_homes.sh` (no `set` statement),
`src/bin/oradba_extension.sh` (only `set -o pipefail`)

Both are executed, not sourced. Violates the project mandatory error-handling convention and risks
the same silent-failure class as the recent `((idx++))`-under-`set -e` fix (commit 4db7ccf).

**Recommendation (analysis only):** Add full `set -euo pipefail` to both, then audit
arithmetic/`grep` exit-code patterns.

----------------------------------------------------------------------------------------------------

### ARCH-013 - `$(echo "$var" | awk/sed)` subshell chains inside hot loops

**Severity:** Low **Files:** `src/bin/oraup.sh:382,386,427`, `src/lib/oradba_common.sh:1025`

`echo | awk`/`sed` inside the per-listener `while read` loop; PATH deduplication via
`echo | awk | sed` in oradba_common.

**Recommendation (analysis only):** Replace with bash built-ins per the bash-performance rule.
`oradba_dedupe_path` already exists and should be preferred.

----------------------------------------------------------------------------------------------------

## Clarifications

- The `--prepare` -\> `--install` contract described in test-coverage.md does not exist in
  `src/bin/oradba_install.sh` (which uses `INSTALL_MODE` = embedded/local/github). The only
  `--prepare`/`--install` references are in `doc/releases/v0.24.11.md:72-74` describing the
  downstream `odb_datasafe` connector lifecycle, not oradba's installer. Recommend confirming
  whether oradba is expected to provide a generic prepare/install contract for extensions.

----------------------------------------------------------------------------------------------------

## Summary Table

| ID       | Severity | Title                                                                      |
|----------|----------|----------------------------------------------------------------------------|
| ARCH-001 | Critical | Duplicate `plugin_check_listener_status` definition in plugin_interface.sh |
| ARCH-002 | Critical | Two competing plugin loaders; safe one bypassed by 9 direct-source sites   |
| ARCH-003 | High     | `ORADBA_BASE` vs `ORADBA_PREFIX` bootstrapped inconsistently               |
| ARCH-004 | High     | env_builder/parser/validator subsystem not on primary oraenv.sh code path  |
| ARCH-005 | High     | DB status querying implemented three times with divergent SQL/vocabulary   |
| ARCH-006 | Medium   | Two independent oratab parsers with overlapping responsibility             |
| ARCH-007 | Medium   | Public function naming split between prefixed and unprefixed conventions   |
| ARCH-008 | Medium   | `oradba_log` redefined locally, shadowing the real logger                  |
| ARCH-009 | Medium   | Bootstrap boilerplate duplicated across 27 scripts; no shared loader       |
| ARCH-010 | Medium   | Registry auto-discovery is a stub; callers bypass the abstraction          |
| ARCH-011 | Low      | Dead no-op branch in plugin path resolution                                |
| ARCH-012 | Low      | `set -euo pipefail` gaps on oradba_homes.sh and oradba_extension.sh        |
| ARCH-013 | Low      | \`echo                                                                     |
