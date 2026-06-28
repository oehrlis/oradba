# BasEnv Coexistence

**Purpose:** Guide for running OraDBA alongside TVD BasEnv / DB\*Star without conflicts.

**Audience:** DBAs who use TVD BasEnv (DB\*Star) as their primary Oracle environment manager
and want to add OraDBA tooling on the same host.

## Overview

TVD BasEnv (a.k.a. DB\*Star) manages Oracle environment variables (`ORACLE_SID`, `ORACLE_HOME`,
`ORACLE_BASE`, etc.), the shell prompt, and PATH for Oracle DBAs. OraDBA detects BasEnv
automatically and switches to a non-invasive **coexistence mode** where it loads its own libraries
and `ORADBA_*` configuration variables only, leaving Oracle variable management to BasEnv.

Three coexistence modes are available:

<!-- markdownlint-disable MD013 -->
| Mode             | How it is activated                   | OraDBA behaviour                                                           |
|------------------|---------------------------------------|----------------------------------------------------------------------------|
| `standalone`     | Default; no BasEnv detected           | Full control: sets Oracle vars, PATH, SQLPATH, aliases                     |
| `basenv`         | Auto-detected at install and runtime  | Minimal: loads libraries and `ORADBA_*` vars only; BasEnv owns Oracle vars |
| `basenv-maximal` | Opt-in by editing `oradba_local.conf` | Minimal + safe, non-conflicting aliases via `safe_alias()`                 |
<!-- markdownlint-enable MD013 -->

## Installation

### Standard Installation (Automatic Detection)

Run the installer normally. It checks for BasEnv markers and sets the coexistence mode
in `oradba_local.conf` automatically:

```bash
./oradba_install.sh --prefix /opt/oracle/local/oradba
```

When BasEnv is detected (see [Detection](#detection) below), the installer writes:

```bash
export ORADBA_COEXIST_MODE="basenv"
```

When BasEnv is not detected, it writes:

```bash
export ORADBA_COEXIST_MODE="standalone"
```

There is **no installer flag** to select `basenv-maximal` directly. The installer
sets `basenv` (minimal) when BasEnv is present. Maximal mode requires a manual
step after installation (see [Enabling Maximal Mode](#enabling-maximal-mode)).

### Shell Profile Integration

OraDBA must be sourced **after** BasEnv has initialized, so that `BE_HOME` is
already exported when `detect_basenv()` runs.

**Important:** `${ETC_BASE}/basenv.conf` and `${ETC_BASE}/sid.<SID>.conf` use
BasEnv's own custom parser - they do **not** support bash syntax. Adding a bash
`if` block there causes a parse error:

```text
ERROR : 2001002 => BELIB.pm : BEbliDoConfig : Parse error at line :
 if [[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]]; then
```

The correct integration point is `.bash_profile`, **after** the BasEnv
initialization line:

```bash
# Existing BasEnv initialization (already in .bash_profile)
. /opt/oracle/local/dba/bin/basenv.sh

# Add OraDBA after - BE_HOME is now set, detection works correctly
if [[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]]; then
    source "${TVD_BASE}/oradba/bin/oraenv.sh"
fi
```

The correct load order is:

```text
.bash_profile
    ├── . basenv.sh          ← BasEnv sets BE_HOME, ORACLE_SID, ORACLE_HOME, ...
    └── source oraenv.sh     ← OraDBA detects BE_HOME, activates basenv mode
```

Do **not** use `--update-profile` when installing alongside BasEnv - that flag
adds OraDBA at the top of `.bash_profile` before BasEnv initializes, which
causes OraDBA to start in `standalone` mode and override Oracle variables that
BasEnv owns.

**Note on `${ETC_BASE}` config files:**

| File | Format | Bash syntax |
| --- | --- | --- |
| `basenv.conf` | BasEnv custom parser | not supported |
| `sid.<SID>.conf` | INI-style `[SID]` sections | not supported |
| `sid._DEFAULT_.conf` | INI-style `[DEFAULT]` sections | not supported |

None of these files can host the OraDBA integration block.
The `oradba_basenv.conf.example` shipped with OraDBA is provided as a
reference for the bash code to add to `.bash_profile` - it cannot be copied
directly into `${ETC_BASE}/`.

### Typical Directory Layout

```text
/opt/oracle/local/
├── dba/          # BE_HOME (BasEnv / DB*Star)
└── oradba/       # OraDBA installation prefix
```

## Enabling Maximal Mode

Maximal mode (`basenv-maximal`) adds non-conflicting OraDBA shell aliases on top of the
minimal coexistence baseline. Aliases that already exist in BasEnv are skipped automatically
via `safe_alias()`.

### Step 1 - Edit oradba_local.conf

Open `${INSTALL_PREFIX}/etc/oradba_local.conf` and change the coexistence mode line:

```bash
# Before (set by installer):
export ORADBA_COEXIST_MODE="basenv"

# After (maximal mode):
export ORADBA_COEXIST_MODE="basenv-maximal"
```

The installer leaves a commented-out example in the file:

```bash
# To enable maximal mode (non-conflicting oradba aliases in BasEnv sessions):
# export ORADBA_COEXIST_MODE="basenv-maximal"
```

Uncomment that line and remove or comment out the `basenv` line above it.

### Step 2 - Reload the Environment

Activate the change by switching databases in BasEnv (which re-sources OraDBA) or
by starting a new login shell:

```bash
# Via BasEnv database switch
db PROD

# Or open a new shell
bash -l
```

### Step 3 - Verify

```bash
echo "ORADBA_COEXIST_MODE=${ORADBA_COEXIST_MODE}"
# Expected: ORADBA_COEXIST_MODE=basenv-maximal
```

## Switching Between Modes

All mode changes go through `oradba_local.conf`. Edit the file and reload.

| Target mode               | `ORADBA_COEXIST_MODE` value |
|---------------------------|-----------------------------|
| Minimal (BasEnv detected) | `basenv`                    |
| Maximal                   | `basenv-maximal`            |
| Full (no BasEnv)          | `standalone`                |

```bash
# Edit the config file
vi /opt/oracle/local/oradba/etc/oradba_local.conf

# Set exactly one of:
export ORADBA_COEXIST_MODE="basenv"
export ORADBA_COEXIST_MODE="basenv-maximal"
export ORADBA_COEXIST_MODE="standalone"
```

After saving, reload with `db <SID>` or a new login shell. The change takes
effect immediately because `oradba_local.conf` is sourced on every BasEnv
database switch.

## Detection

OraDBA checks for BasEnv at install time and again at runtime (via `detect_basenv()`
in `oradba_common.sh`). BasEnv is considered present when **any** of the following
markers is found:

| Marker            | Type                 | Created by                          |
|-------------------|----------------------|-------------------------------------|
| `BE_HOME`         | Environment variable | BasEnv before sourcing user scripts |
| `~/.BE_HOME`      | File                 | BasEnv installer                    |
| `~/.TVDPERL_HOME` | File                 | TVDPERL component of BasEnv         |

If `ORADBA_COEXIST_MODE` is already set when `oraenv.sh` runs, detection is skipped
and the existing value is honoured. The auto-detection never upgrades `basenv` to
`basenv-maximal`; maximal mode always requires explicit opt-in.

## Protected Variables

In `basenv` and `basenv-maximal` mode, OraDBA does **not** modify:

| Variable / item      | Owned by                                    |
|----------------------|---------------------------------------------|
| `ORACLE_SID`         | BasEnv `db` command                         |
| `ORACLE_HOME`        | BasEnv per-SID resolution                   |
| `ORACLE_BASE`        | BasEnv configuration                        |
| `TNS_ADMIN`          | BasEnv                                      |
| `NLS_LANG`           | BasEnv                                      |
| `LD_LIBRARY_PATH`    | BasEnv                                      |
| `SQLPATH` (ordering) | BasEnv entries remain first                 |
| `PATH` (ordering)    | Oracle bin directories under BasEnv control |
| `PS1`                | BasEnv prompt customization                 |
| `BE_*` variables     | All BasEnv internal variables               |

## Verification

```bash
# Check active coexistence mode
echo "ORADBA_COEXIST_MODE=${ORADBA_COEXIST_MODE}"

# Full installation info (includes coexist_mode field)
oradba_version.sh -i

# Confirm OraDBA common library is loaded
type detect_basenv 2>/dev/null && echo "oradba_common.sh loaded"

# Check BasEnv markers on the current host
echo "BE_HOME=${BE_HOME:-<not set>}"
ls -la ~/.BE_HOME ~/.TVDPERL_HOME 2>/dev/null || echo "no BasEnv marker files found"
```

## Troubleshooting

### Mode stays `standalone` despite BasEnv being present

The installer runs before BasEnv exports `BE_HOME`, or no marker file exists yet.

```bash
# Check which markers are present
echo "BE_HOME=${BE_HOME:-<not set>}"
ls -la ~/.BE_HOME ~/.TVDPERL_HOME 2>/dev/null || echo "no marker files"
```

Create the marker file if missing, or set the mode explicitly in `oradba_local.conf`:

```bash
# Option A: create marker file
touch ~/.BE_HOME

# Option B: force mode in config
echo 'export ORADBA_COEXIST_MODE="basenv"' >> /opt/oracle/local/oradba/etc/oradba_local.conf
```

### Alias conflicts in `basenv-maximal` mode

`safe_alias()` skips any alias that already exists when OraDBA loads. If OraDBA
aliases appear where BasEnv aliases are expected, check the load order:

```bash
# Source BasEnv first, then OraDBA (the integration snippet handles this)
echo "mode=${ORADBA_COEXIST_MODE}"
alias sq 2>/dev/null   # Should point to BasEnv version if BasEnv defined it first
```

If `ORADBA_COEXIST_MODE` shows `standalone`, OraDBA did not detect BasEnv.
See the detection steps above.

### SQLPATH entries from OraDBA appear before BasEnv entries

In coexistence mode, OraDBA skips SQLPATH modification when the `ORADBA_BASE/sql`
directory is already present. If BasEnv entries appear after OraDBA entries,
disable SQLPATH handling entirely in `oradba_local.conf`:

```bash
export ORADBA_CONFIGURE_SQLPATH=false
```

<!-- Web-only sections below: kept for MkDocs navigation, stripped during PDF build. -->
## See Also {.unlisted .unnumbered}

- [Installation](installation.md) - Full installation guide
- [Configuration System](configuration.md) - OraDBA configuration reference
- [Aliases Reference](aliases.md) - Available aliases (affected by coexistence mode)
- `src/etc/oradba_basenv.conf.example` - Integration snippet with inline comments

## Navigation {.unlisted .unnumbered}

**Previous:** [Advanced Configuration](advanced-configuration.md)
**Next:** [Extension System](extensions.md)
