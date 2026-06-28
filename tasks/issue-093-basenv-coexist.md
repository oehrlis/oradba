# Plan: BasEnv Coexistence Mode (Issue #93)

**Status:** Implemented - merged to main 2026-06-28 (v1.0.0-rc.2)
**Issue:** [#93](https://github.com/oehrlis/oradba/issues/93)
**Target:** v1.0.0 RC2 - tested and released as part of v1.0.0 final

## Implementation Summary

All 8 plan steps completed and merged:

| Step | What | Commit |
| ---- | ---- | ------ |
| 1 | `detect_basenv()` in `oradba_common.sh` | `8ee6a66` |
| 2+3+4 | Coexistence guards in `oraenv.sh` (detection, SQLPATH, Oracle vars) | `6f67995` |
| 5 | `src/etc/oradba_basenv.conf.example` | `05bad86` |
| 6 | `oradba_local.conf` template extended | `fbbd180` |
| 7 | `tests/test_basenv_coexist.bats` (11 tests, 11/11 passing) | `0f9338f` |
| 8 | `doc/basenv_coexist.md`, `README.md`, `CHANGELOG.md` | `4c10b57` |
| fix | Whole-branch review findings resolved | `7dc7244` |
| merge | `feat(coexist): merge BasEnv coexistence mode implementation (#93)` | `16efea3` |

---

## 1. Current State Assessment

### Already implemented (no rework needed)

| Component                           | Location                             | Status |
|-------------------------------------|--------------------------------------|--------|
| `ORADBA_COEXIST_MODE` variable      | `src/etc/oradba_core.conf:56`        | done   |
| `ORADBA_FORCE` override flag        | `src/etc/oradba_core.conf:59`        | done   |
| `ORADBA_EXTENSIONS_IN_COEXIST` flag | `src/etc/oradba_core.conf:189`       | done   |
| `alias_exists()`                    | `src/lib/oradba_common.sh:500`       | done   |
| `safe_alias()` with basenv guard    | `src/lib/oradba_common.sh:528`       | done   |
| Extension loading skip in coexist   | `src/bin/oraenv.sh:1185`             | done   |
| BasEnv detection in installer       | `src/bin/oradba_install.sh:2273`     | done   |
| `oradba_local.conf` generation      | `src/bin/oradba_install.sh:2316`     | done   |
| `.install_info` with coexist fields | `src/bin/oradba_install.sh:2343`     | done   |
| `oradba_version.sh -i` display      | `src/bin/oradba_version.sh:643`      | done   |
| `get/set/init_install_info()`       | `src/lib/oradba_version_metadata.sh` | done   |

### Not yet implemented (gaps to close)

| Gap                                                   | Impact                                                              |
|-------------------------------------------------------|---------------------------------------------------------------------|
| `detect_basenv()` as reusable library function        | HIGH - detection only exists in installer, not in runtime library   |
| Protected variable/alias list documented and enforced | HIGH - `safe_alias()` exists but no guard for variable assignments  |
| BasEnv-compatible config snippet / template           | MEDIUM - no user guidance on how to hook oradba into basenv.conf    |
| PATH/SQLPATH guard in `oraenv.sh` for coexist mode    | MEDIUM - unknown if oraenv.sh re-adds entries already set by BasEnv |
| Minimal vs. maximal mode distinction                  | LOW - only `basenv` vs `standalone` exists; no sub-modes            |
| Coexistence scenario tests (Bats)                     | MEDIUM - zero test coverage for coexist behaviour                   |

---

## 2. Key Findings from BasEnv Analysis

### 2.1 Detection Strategy

BasEnv leaves three reliable markers, checked in priority order:

```text
1. BE_HOME variable   → set by basenv.sh at login (most reliable at runtime)
2. $HOME/.BE_HOME     → present even before basenv.sh runs (install-time reliable)
3. $HOME/.TVDPERL_HOME → secondary marker, always paired with .BE_HOME
4. TVD_BASE variable  → set by basenv.sh (weaker - could be set manually)
```

The installer already uses markers 1-3 (`src/bin/oradba_install.sh:2279`).
A `detect_basenv()` library function should follow the same logic.

### 2.2 Protected Variables (must not be set/overridden in basenv mode)

From `environment_variable.txt` - variables managed by BasEnv:

**Oracle core (absolute no-touch):**

- `ORACLE_SID`, `ORACLE_HOME`, `ORACLE_BASE`, `ORACLE_DOC`, `ORACLE_TERM`
- `ORACLE_PDB`, `ORACLE_PDB_SID`
- `NLS_LANG`, `TNS_ADMIN`, `ORATAB`
- `LD_LIBRARY_PATH`

**BasEnv own namespace (never touch):**

- All `BE_*` variables (`BE_HOME`, `BE_SIDLIST`, `BE_ORA_*`, `BE_PDB`, etc.)
- `TVD_BASE`, `ETC_BASE`, `LOG_BASE`
- `TVDPERL_HOME`, `TVDPERLBIN`, `TVDSQL_BASE`, `TVDUSR_BASE`, `TVDAS_BASE`
- `DBA_BASE`, `BINARY_BASE`

**Shell/prompt (never touch):**

- `PS1`, `PS1BASH`, `PROMPT_COMMAND`
- `MANPATH`, `CDPATH`

**Must not prepend/append blindly:**

- `PATH` - BasEnv already places `oradba/bin` after BasEnv's own bins
- `SQLPATH` - BasEnv already places `oradba/sql` at position 1

### 2.3 Protected Aliases (must not be overridden in basenv mode)

From `BE_ALIASES` in `environment_variable.txt` - full alias inventory managed by BasEnv:

**Navigation (cd*):** `cda`, `cdb`, `cdc`, `cdd`, `cddbs`, `cde`, `cdh`, `cdl`, `cdn`,
`cdnmh`, `cdo`, `cdob`, `cdr`, `cdt`, `cdw`, `cdwa`, `cdwc`, `cdwd`, `cdwh`, `cdwj`, `cdwm`, `cdws`, `cdwv`

**Vi/View:** `via`, `vib`, `vic`, `vidc`, `vid`, `vii`, `vil`, `vildap`, `vio`,
`viot`, `vir`, `vis`, `vist`, `visql`, `vit`, `viw`

**SQL/RMAN:** `sq`, `sqh`, `sqlplush`, `sm`, `rman`, `rmanc`, `rmanch`, `rmanh`, `rman_catalog_loader`

**DG/ASM:** `dg`, `dgh`, `asmcmdh`, `adrcih`, `dcmh`, `lsnrctlh`

**System:** `l`, `ll`, `lr`, `lsl`, `m`, `psg`, `sta`, `u`, `c`, `pdbs`, `etc`,
`log`, `rcv`, `basenv`, `save_cron`, `checkback`, `alig`, `alih`

**SSH:** `ssho`, `sshg`, `sshr`

**WLS:** `tanm`, `taas`, `tams`, `tacs`, `shl`, `wlsup`, `wlsto`, `wlstc`, `wlsth`,
`wlsts`, `wlsnmd`, `wlsasd`, `wlsmsd`, `wlscsd`, `vidc`, `tib`, `tiba` and `*.log`/`*.out` variants

> `safe_alias()` already skips all these when `ORADBA_COEXIST_MODE=basenv`. No additional code needed for aliases.

### 2.4 Directory Structure

Standard BasEnv + oradba co-installation under `TVD_BASE`:

```text
$TVD_BASE  (= /opt/oracle/local = ORADBA_LOCAL_BASE)
├── binary/
├── dba/          ← BE_HOME (BasEnv itself)
│   ├── bin/
│   ├── etc/      → symlink to /opt/oracle/oradata/dbconfig/basenv/etc
│   ├── log/
│   └── ...
├── documentation/
├── oradba/       ← ORADBA_BASE (peer directory, not a subdirectory)
│   ├── bin/
│   ├── etc/
│   ├── sql/
│   └── ...
├── tvdas/
├── tvdperl-all/
├── tvdsql/
└── tvdusr/
```

`TVD_BASE == ORADBA_LOCAL_BASE` in a standard co-installation.

### 2.5 BasEnv Custom Config Integration

The issue mentions `${ETC_BASE}/customer_conf/oradba.conf` but **this directory does not exist** in BasEnv.
The actual customization point is `${ETC_BASE}/basenv.conf` (user-edited, survives upgrades).

For oradba integration a user adds to `${ETC_BASE}/basenv.conf`:

```bash
# Load oradba environment in coexistence mode
[[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]] && source "${TVD_BASE}/oradba/bin/oraenv.sh"
```

oradba must provide this as a template/example, not inject it automatically (that would modify BasEnv files).

### 2.6 PATH and SQLPATH - Already Handled by BasEnv

In the sample environment BasEnv already manages both:

```text
PATH:    ...tvdperl-all/bin:oracle/bin:dba/bin:tvdusr/bin:tvdas/bin:oradba/bin:...
SQLPATH: oradba/sql:tvdsql/oracle12:...:rdbms/admin:.
```

oradba is already present. In coexist mode, `oraenv.sh` must **not add duplicate entries** to PATH/SQLPATH.

---

## 3. Decisions (Confirmed)

| #  | Question                 | Decision                                                                                                       |
|----|--------------------------|----------------------------------------------------------------------------------------------------------------|
| Q1 | Minimal vs. maximal mode | `minimal` is default; `maximal` is opt-in via `ORADBA_COEXIST_MODE=basenv-maximal`                             |
| Q2 | oraenv.sh SID-switching  | **Option A** - guard Oracle var assignment when `BE_HOME` is detected; SID switching stays with BasEnv aliases |
| Q3 | PATH/SQLPATH guard       | Skip PATH/SQLPATH modifications when entry already present in basenv mode                                      |
| Q4 | Runtime toggle           | Not needed; `oradba_local.conf` + re-source is sufficient. Runtime toggle deferred to v1.2.0+ if ever required |
| Q5 | Re-detection             | Dynamic at each session via `detect_basenv()`; auto-falls back to standalone if BasEnv removed                 |

### Q2 Detail - What Option A means in practice

When `oraenv.sh` is sourced in a BasEnv session (e.g., via `basenv.conf`):

- oradba **loads** its libraries and ORADBA\_\* variables
- oradba **creates** non-conflicting aliases via `safe_alias()`
- oradba **does NOT** set `ORACLE_SID`, `ORACLE_HOME`, `ORACLE_BASE`, `NLS_LANG`, etc.
- SID switching remains BasEnv's responsibility (`FREE` alias, `oraup.ksh`, `u`)

Guard pattern in `oraenv.sh`:

```bash
if [[ "${ORADBA_COEXIST_MODE}" != "basenv"* ]]; then
    export ORACLE_SID="${target_sid}"
    export ORACLE_HOME="${oracle_home}"
    # ... all other Oracle vars
fi
```

---

## 4. Implementation Plan

Assuming the answers to Q1-Q5 follow the recommendations above.

### Step 1 - `detect_basenv()` library function

**File:** `src/lib/oradba_common.sh`  
**After:** the `alias_exists()` function (~line 514)

```bash
detect_basenv() {
    # Priority 1: BE_HOME variable (set by basenv.sh at login)
    [[ -n "${BE_HOME:-}" ]] && return 0
    # Priority 2: .BE_HOME marker file (present at install time)
    [[ -f "${HOME}/.BE_HOME" ]] && return 0
    # Priority 3: .TVDPERL_HOME marker (always paired with .BE_HOME)
    [[ -f "${HOME}/.TVDPERL_HOME" ]] && return 0
    return 1
}
```

This mirrors the existing installer logic and can be called at runtime.

### Step 2 - Dynamic coexist mode detection in oraenv.sh

**File:** `src/bin/oraenv.sh`  
**Location:** early in the environment initialization sequence

If `ORADBA_COEXIST_MODE` is not set to a basenv variant but `detect_basenv()` returns 0,
set it dynamically to `basenv` (minimal, the safe default).
This handles the case where oraenv.sh is sourced in a BasEnv session without `oradba_local.conf` loaded first.

```bash
if [[ "${ORADBA_COEXIST_MODE:-standalone}" != "basenv"* ]]; then
    if detect_basenv; then
        export ORADBA_COEXIST_MODE="basenv"
        oradba_log DEBUG "BasEnv detected at runtime - coexistence mode set to minimal (basenv)"
    fi
fi
```

`basenv-maximal` is never auto-set; the user must explicitly configure it in `oradba_local.conf`.

### Step 3 - PATH/SQLPATH guard in oraenv.sh

**File:** `src/bin/oraenv.sh`  
**At every PATH/SQLPATH modification block**

Before adding to PATH or SQLPATH, check if in basenv mode and entry already present:

```bash
_oradba_path_contains() {
    local dir="$1" pathvar="${2:-PATH}"
    [[ ":${!pathvar}:" == *":${dir}:"* ]]
}

# Guard for coexist mode
if [[ "${ORADBA_COEXIST_MODE}" != "basenv" ]] || ! _oradba_path_contains "${ORADBA_BASE}/bin"; then
    export PATH="${ORADBA_BASE}/bin:${PATH}"
fi
```

### Step 4 - Oracle variable guard in oraenv.sh (Q2 - Option A)

**File:** `src/bin/oraenv.sh`  
**At all blocks that set ORACLE_SID, ORACLE_HOME, ORACLE_BASE, NLS_LANG, TNS_ADMIN, LD_LIBRARY_PATH**

Guard with `basenv*` pattern - covers both `basenv` (minimal) and `basenv-maximal`:

```bash
if [[ "${ORADBA_COEXIST_MODE}" != "basenv"* ]]; then
    export ORACLE_SID="${target_sid}"
    export ORACLE_HOME="${oracle_home}"
    export ORACLE_BASE="${oracle_base}"
    export NLS_LANG="${nls_lang}"
    # ... all Oracle core vars
fi
```

In maximal mode oradba still loads all its own aliases/vars - it just never touches Oracle or BE\_\* vars.

### Step 5 - BasEnv integration template

**File:** `src/etc/oradba_basenv.conf.example` (new file)

Provide a ready-to-copy snippet for users to add to `${ETC_BASE}/basenv.conf`:

```bash
# ---------------------------------------------------------------------------
# OraDBA integration for BasEnv
# Add this block to ${ETC_BASE}/basenv.conf to load OraDBA in coexistence mode.
# OraDBA will not override BasEnv-managed variables, aliases, PATH or SQLPATH.
# ---------------------------------------------------------------------------
if [[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]]; then
    source "${TVD_BASE}/oradba/bin/oraenv.sh"
fi
```

### Step 6 - Update oradba_local.conf template

**File:** `src/bin/oradba_install.sh`  
**At the `cat > oradba_local.conf` block (~line 2316)**

Add documentation of the protected variable list and a comment pointing to `oradba_basenv.conf.example`:

```bash
# BasEnv protected variables - OraDBA will not modify these:
# ORACLE_SID, ORACLE_HOME, ORACLE_BASE, NLS_LANG, TNS_ADMIN, LD_LIBRARY_PATH
# BE_*, TVD_BASE, ETC_BASE, LOG_BASE, PS1, PS1BASH, PATH (already set by BasEnv)
```

### Step 7 - Bats tests for coexistence scenarios

**File:** `tests/test_basenv_coexist.bats` (new file)

Minimum test cases:

```text
- detect_basenv() returns 0 when BE_HOME is set
- detect_basenv() returns 0 when ~/.BE_HOME file exists
- detect_basenv() returns 1 when neither marker is present
- safe_alias() skips when alias already exists in basenv mode
- safe_alias() creates alias when alias does not exist in basenv mode
- ORADBA_COEXIST_MODE auto-set to basenv when detect_basenv() returns 0
- PATH is not duplicated when oradba/bin already in PATH (basenv mode)
- SQLPATH is not duplicated when oradba/sql already in SQLPATH (basenv mode)
```

### Step 8 - Documentation

**Files:**

- `doc/basenv_coexist.md` (new) - user-facing integration guide
- `README.md` - add coexistence mode section
- `CHANGELOG.md` - record feature under `[Unreleased]`

---

## 5. ORADBA_COEXIST_MODE Values (Final)

| Value            | Auto-set? | What oradba does                                                                     |
|------------------|-----------|--------------------------------------------------------------------------------------|
| `standalone`     | yes       | Full behaviour - sets all Oracle vars, PATH, SQLPATH, aliases                        |
| `basenv`         | yes       | Minimal: libraries + ORADBA\_\* vars only; no Oracle vars, no duplicate PATH/SQLPATH |
| `basenv-maximal` | no        | Maximal: like `basenv` plus non-conflicting aliases via `safe_alias()`               |

`basenv-maximal` must be set explicitly in `oradba_local.conf`. It is never auto-detected.
All `basenv*` variants share the same Oracle variable guard (pattern match `"basenv"*`).

---

## 6. Scope and Boundaries

### In scope for v1.0.0 RC2 (Steps 1-8)

- `detect_basenv()` as reusable library function in `oradba_common.sh`
- Dynamic mode auto-set to `basenv` (minimal) at session start
- Oracle variable guard in `oraenv.sh` for all `basenv*` modes
- PATH/SQLPATH deduplication guard in `oraenv.sh`
- BasEnv conf snippet template (`src/etc/oradba_basenv.conf.example`)
- `oradba_local.conf` extended with protected-var comment and mode documentation
- Bats tests for all coexistence scenarios
- User-facing documentation (`doc/basenv_coexist.md`)

### Out of scope / deferred

- Runtime toggle command - v1.2.0+ if ever needed
- Automatic injection into `basenv.conf` at install time - would modify BasEnv files
- Automatic upgrade/rollback coordination with BasEnv updates - no use case defined
- KSH / non-bash shell support (BasEnv supports ksh; oradba targets bash only)
