# BasEnv Coexistence Guide

This guide explains how to run OraDBA alongside TVD BasEnv / DB*Star without conflicts.

## Overview

TVD BasEnv (a.k.a. DB*Star) is a widely used Oracle DBA environment manager by Trivadis/Accenture.
It owns Oracle environment variables (`ORACLE_SID`, `ORACLE_HOME`, `ORACLE_BASE`, etc.) and manages
the shell prompt and PATH for Oracle DBAs.

OraDBA detects BasEnv automatically and switches to a non-invasive **coexistence mode** where it
loads its libraries and `ORADBA_*` configuration variables only, leaving Oracle variable management
to BasEnv. A maximal opt-in variant additionally provides safe, non-conflicting shell aliases.

## Detection

OraDBA calls `detect_basenv()` (in `src/lib/oradba_common.sh`) on startup. BasEnv is considered
present when **any** of the following markers is found:

| Marker | Type | Description |
| --- | --- | --- |
| `BE_HOME` | Environment variable | Set by BasEnv before sourcing user scripts |
| `~/.BE_HOME` | File | Created by BasEnv installer |
| `~/.TVDPERL_HOME` | File | Created by TVDPERL component of BasEnv |

Detection result is cached in `ORADBA_COEXIST_MODE`. If the variable is already set before
`oraenv.sh` runs, detection is skipped and the existing value is honoured.

## Coexistence Modes

<!-- markdownlint-disable MD013 -->
| Mode | Trigger | OraDBA behaviour |
| --- | --- | --- |
| `standalone` | Default; no BasEnv detected | Full control: loads all libraries, sets Oracle vars, manages PATH/SQLPATH |
| `basenv` | Auto-detected | Minimal: loads libraries and `ORADBA_*` vars only; BasEnv owns Oracle vars |
| `basenv-maximal` | Opt-in via `oradba_local.conf` | Minimal + safe, non-conflicting aliases via `safe_alias()` |
<!-- markdownlint-enable MD013 -->

Set the mode explicitly in `${ETC_BASE}/oradba_local.conf` to override auto-detection:

```bash
export ORADBA_COEXIST_MODE="basenv-maximal"
```

## Integration Steps

The standard co-installation layout places OraDBA as a peer of BasEnv under `TVD_BASE`:

```text
/opt/oracle/local/
├── dba/          # BE_HOME (BasEnv)
└── oradba/       # OraDBA installation prefix
```

### Step 1 - Install OraDBA

```bash
./oradba_install.sh --prefix /opt/oracle/local/oradba
```

### Step 2 - Add OraDBA to .bash_profile

`${ETC_BASE}/basenv.conf` and `${ETC_BASE}/sid.<SID>.conf` use BasEnv's own custom
parser and do **not** support bash syntax. Adding a bash `if` block there causes:

```text
ERROR : 2001002 => BELIB.pm : BEbliDoConfig : Parse error at line :
 if [[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]]; then
```

The correct integration point is `~/.bash_profile`, after the existing BasEnv
initialization line:

```bash
# Existing BasEnv init (already in .bash_profile)
. /opt/oracle/local/dba/bin/basenv.sh

# Add OraDBA after - BE_HOME is now set, detection works correctly
if [[ -f "${TVD_BASE}/oradba/bin/oraenv.sh" ]]; then
    source "${TVD_BASE}/oradba/bin/oraenv.sh"
fi
```

`BE_HOME` is already exported by BasEnv at this point, so `detect_basenv()`
finds the marker and activates `basenv` mode automatically.

The file `src/etc/oradba_basenv.conf.example` is a reference showing the bash
block to add - it cannot be copied directly into `${ETC_BASE}/`.

### Step 3 - Optional: enable maximal mode

To add non-conflicting aliases, create or extend `${ETC_BASE}/oradba_local.conf`:

```bash
export ORADBA_COEXIST_MODE="basenv-maximal"
```

Reload the environment (via BasEnv's `db` command or a new login shell) to activate the change.

## Protected Variables and Aliases

In `basenv` and `basenv-maximal` mode, OraDBA does **not** modify the following:

| Item | Owned by BasEnv |
| --- | --- |
| `ORACLE_SID` | Set per-instance by BasEnv `db` command |
| `ORACLE_HOME` | Resolved by BasEnv per SID |
| `ORACLE_BASE` | Set from BasEnv configuration |
| `TNS_ADMIN` | Managed by BasEnv |
| `NLS_LANG` | Managed by BasEnv |
| `SQLPATH` (order) | BasEnv entries remain first |
| `PATH` (order) | Oracle bin directories remain under BasEnv control |
| `PS1` | BasEnv prompt customization is not overwritten |
| `BE_*` variables | All BasEnv internal variables untouched |

The `safe_alias()` function (used in `basenv-maximal` mode) skips any alias that already exists,
so BasEnv-defined aliases always take precedence.

## Verification

After setup, verify the active mode:

```bash
# Check detected coexistence mode
echo "ORADBA_COEXIST_MODE=${ORADBA_COEXIST_MODE}"

# Full installation info (shows coexist mode in output)
oradba_version.sh -i

# Confirm OraDBA libraries are loaded
type detect_basenv 2>/dev/null && echo "oradba_common.sh loaded"
```

Expected output in coexistence mode:

```text
ORADBA_COEXIST_MODE=basenv
```

## Troubleshooting

### Mode not detected (stays `standalone` despite BasEnv being present)

Check which markers are present:

```bash
echo "BE_HOME=${BE_HOME:-<not set>}"
ls -la ~/.BE_HOME ~/.TVDPERL_HOME 2>/dev/null || echo "no marker files found"
```

If BasEnv has not exported `BE_HOME` before OraDBA is sourced, create the marker file:

```bash
touch ~/.BE_HOME
```

Alternatively, set the mode explicitly before sourcing OraDBA:

```bash
export ORADBA_COEXIST_MODE="basenv"
```

### Alias conflicts: OraDBA aliases override BasEnv aliases

In `basenv` mode, OraDBA does **not** load aliases at all - this should not occur.

In `basenv-maximal` mode, `safe_alias()` skips existing aliases. If a conflict still appears,
check whether `ORADBA_COEXIST_MODE` is set correctly after sourcing:

```bash
source ${TVD_BASE}/oradba/bin/oraenv.sh
echo "mode=${ORADBA_COEXIST_MODE}"
alias sq 2>/dev/null   # Should still point to BasEnv's version
```

If `ORADBA_COEXIST_MODE` shows `standalone`, OraDBA did not detect BasEnv. See the detection
troubleshooting steps above.

### SQLPATH entries from OraDBA appear before BasEnv entries

In coexistence mode, OraDBA sets the `ORADBA_CONFIGURE_SQLPATH` guard to avoid prepending its
SQL directory. If BasEnv entries appear after OraDBA entries, verify the variable:

```bash
echo "ORADBA_CONFIGURE_SQLPATH=${ORADBA_CONFIGURE_SQLPATH:-<not set>}"
echo "SQLPATH=${SQLPATH}"
```

Set `ORADBA_CONFIGURE_SQLPATH=false` in `oradba_local.conf` to disable SQLPATH modification
entirely when BasEnv already manages it.

## See Also

- `src/etc/oradba_basenv.conf.example` - Integration snippet with inline comments
- `src/lib/oradba_common.sh` - `detect_basenv()` and `safe_alias()` implementations
- `tests/test_basenv_coexist.bats` - Bats test suite for coexistence scenarios
- [configuration.md](configuration.md) - Full OraDBA configuration reference
