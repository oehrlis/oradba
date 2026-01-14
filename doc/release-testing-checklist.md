# OraDBA Release Testing Checklist

Manual verification checklist for new releases. Test in both standalone and BasEnv
coexistence environments before publishing release.

## Pre-Release Checks

### Version and Documentation

- [ ] VERSION file updated
- [ ] CHANGELOG.md updated with release entry
- [ ] doc/releases/vX.X.X.md created
- [ ] File headers updated (Date, Revision)
- [ ] All markdown files pass linting (`make lint-markdown`)
- [ ] No shellcheck warnings (`make lint-shell`)

### Build and Tests

- [ ] All 892 tests passing locally (`make test-full`)
- [ ] Build succeeds (`make build`)
- [ ] Distribution tarball created (`dist/oradba-X.X.X.tar.gz`)
- [ ] Installer script created (`dist/oradba_install.sh`)
- [ ] GitHub Actions CI passing on main branch
- [ ] GitHub Actions release workflow passed (after tag)

## Test Environment: Standalone Installation

### Fresh Installation

**Test System:** Oracle Linux / Ubuntu / macOS without BasEnv

- [ ] Download installer: `curl -LO https://github.com/oehrlis/oradba/releases/download/vX.X.X/oradba_install.sh`
- [ ] Make executable: `chmod +x oradba_install.sh`
- [ ] Run installer: `./oradba_install.sh --prefix /opt/oracle/local/oradba`
- [ ] Installation completes without errors
- [ ] Verify files created in prefix directory
- [ ] Check .install_info file exists and contains correct version

**Verify .install_info:**

```bash
cat /opt/oracle/local/oradba/.install_info
```

Expected fields:

- [ ] `install_date` present
- [ ] `install_version` matches release version
- [ ] `install_method=embedded`
- [ ] `install_user` correct
- [ ] `coexist_mode=standalone`
- [ ] `basenv_detected=no`

### Environment Setup

**Test with Oracle Instance (e.g., FREE, ORCL):**

- [ ] Add oradba to PATH: `export PATH=/opt/oracle/local/oradba/bin:$PATH`
- [ ] Source oraenv: `source oraenv.sh ORCL`
- [ ] No errors during sourcing
- [ ] ORACLE_SID set correctly
- [ ] ORACLE_HOME set correctly
- [ ] ORACLE_BASE calculated correctly

### Alias Verification

**Standard Aliases:**

- [ ] SQL*Plus aliases: `sq`, `sqh`, `sqlplush`
- [ ] RMAN aliases: `rmanc`, `rmanh`, `rmanch`
- [ ] Navigation: `cdh`, `cdo`, `cdn`, `cda`, `cdd`
- [ ] Diagnostics: `taa`, `tah`, `tal`, `tac`
- [ ] Editing: `via`, `vio`, `vit`, `vip`
- [ ] Operations: `dbstart`, `dbstop`, `dbctl`
- [ ] Listener: `listener`, `lsnr`, `lsnrh`

**Test alias execution:**

```bash
# Test a few key aliases
cdh          # Should cd to ORACLE_HOME
cda          # Should cd to $ORACLE_BASE/admin/$ORACLE_SID
taa          # Should show alert log
sq           # Should launch sqlplus
```

**PDB Aliases (if CDB):**

- [ ] PDB aliases created for each PDB
- [ ] PDB navigation aliases work: `cdpdb1`, `cdpdb2`
- [ ] PDB SQL*Plus aliases work: `pdb1`, `pdb1h`

### Version Information

- [ ] `oradba_version.sh` shows correct version
- [ ] `oradba_version.sh -i` displays full installation details
- [ ] Installation Details section shows:
  - [ ] Installed date
  - [ ] Version: X.X.X
  - [ ] Method: embedded
  - [ ] User: correct
  - [ ] **Coexist Mode: standalone**
  - [ ] **BasEnv: no**
- [ ] `oradba_version.sh -v` integrity check passes
- [ ] `oradba_version.sh -c` shows version number

### Configuration Files

- [ ] `oradba_core.conf` loaded
- [ ] `oradba_standard.conf` loaded
- [ ] `oradba_local.conf` created with correct mode
- [ ] `sid.ORCL.conf` loaded (if exists)
- [ ] `ORADBA_COEXIST_MODE=standalone` set

### Update Installation

**Test Update from Previous Version:**

- [ ] Run installer with `--update`: `./oradba_install.sh --prefix /opt/oracle/local/oradba --update`
- [ ] Update completes successfully
- [ ] Configuration files preserved
- [ ] Version updated
- [ ] No data loss

## Test Environment: BasEnv Coexistence

### BasEnv Setup Verification

**Test System:** Oracle Linux / Ubuntu with TVD BasEnv or DB*Star installed

**Verify BasEnv markers exist:**

```bash
ls -la ~/.BE_HOME ~/.TVDPERL_HOME
echo $BE_HOME
```

- [ ] At least one BasEnv marker file exists OR BE_HOME variable set

### Fresh Installation with BasEnv

- [ ] Download installer
- [ ] Run installer: `./oradba_install.sh --prefix /opt/oracle/local/oradba`
- [ ] Installer detects BasEnv during installation
- [ ] See message: "TVD BasEnv / DB*Star detected - enabling coexistence mode"
- [ ] Installation completes without errors

**Verify .install_info:**

```bash
cat /opt/oracle/local/oradba/.install_info
```

Expected fields:

- [ ] `install_date` present
- [ ] `install_version` matches release version
- [ ] `install_method=embedded`
- [ ] `install_user` correct
- [ ] **`coexist_mode=basenv`** ← Critical!
- [ ] **`basenv_detected=yes`** ← Critical!

### Coexistence Mode Configuration

**Verify oradba_local.conf created:**

```bash
cat /opt/oracle/local/oradba/etc/oradba_local.conf
```

- [ ] File exists
- [ ] Contains `export ORADBA_COEXIST_MODE="basenv"`
- [ ] Contains installation metadata
- [ ] Contains comment about BasEnv detection

### Environment Setup with BasEnv

**Test with Oracle Instance:**

- [ ] Source BasEnv first: `source ~/.BE_HOME` (or equivalent)
- [ ] Verify BasEnv aliases exist: `alias taa`, `alias cdd`, `alias sq`
- [ ] Add OraDBA to PATH: `export PATH=/opt/oracle/local/oradba/bin:$PATH`
- [ ] Source oraenv: `source oraenv.sh ORCL`
- [ ] No errors or warnings
- [ ] ORACLE_SID remains correct
- [ ] ORACLE_HOME remains correct
- [ ] PS1 (prompt) NOT modified by OraDBA

### Alias Behavior in Coexistence Mode

**Verify BasEnv aliases NOT overridden:**

```bash
# Check which aliases are active
alias taa     # Should show BasEnv version
alias cdd     # Should show BasEnv version
alias sq      # Should show BasEnv version
alias via     # Should show BasEnv version (if exists)
```

- [ ] BasEnv aliases take priority
- [ ] OraDBA does NOT override existing BasEnv aliases
- [ ] Test execution: aliases work and call BasEnv versions

**Verify OraDBA-only aliases created:**

Check for aliases that DON'T exist in BasEnv (these should be created by OraDBA):

```bash
# Example: check aliases unique to OraDBA
alias dbctl           # OraDBA service management
alias oradba_version  # OraDBA version command
type oradba_check     # OraDBA check script
```

- [ ] OraDBA-specific commands available
- [ ] Non-conflicting aliases created successfully

### Version Information with Coexistence

- [ ] `oradba_version.sh -i` shows:
  - [ ] **Coexist Mode: basenv** ← Critical!
  - [ ] **BasEnv: yes** ← Critical!
- [ ] All other version info correct
- [ ] Integrity check passes

### Configuration Hierarchy

**Verify configuration loading order:**

```bash
# Check that local config is loaded
grep -r "ORADBA_COEXIST_MODE" /opt/oracle/local/oradba/etc/
```

- [ ] `oradba_core.conf` defines default (standalone)
- [ ] `oradba_local.conf` overrides with basenv
- [ ] Final value: `echo $ORADBA_COEXIST_MODE` shows "basenv"

### Force Mode Testing (Optional)

**Test alias override with ORADBA_FORCE:**

```bash
# Enable force mode
export ORADBA_FORCE=1
source oraenv.sh ORCL

# Check aliases now
alias taa    # Should now be OraDBA version
alias sq     # Should now be OraDBA version
```

- [ ] `ORADBA_FORCE=1` overrides BasEnv aliases
- [ ] Aliases now call OraDBA versions
- [ ] Force mode warning displayed (if implemented)

**Reset force mode:**

```bash
unset ORADBA_FORCE
source oraenv.sh ORCL
alias taa    # Should be BasEnv version again
```

- [ ] Unsetting ORADBA_FORCE restores BasEnv priority

### BasEnv Environment Integrity

**Critical: Verify OraDBA does NOT break BasEnv:**

- [ ] BasEnv aliases still functional
- [ ] BasEnv scripts still work
- [ ] PS1 (prompt) unchanged
- [ ] BE_HOME variable unchanged
- [ ] TVDPERL_HOME unchanged (if exists)
- [ ] BasEnv functions still available
- [ ] Can still use BasEnv commands normally

## Documentation Verification

### Online Documentation

- [ ] GitHub Pages deployed: <https://oehrlis.github.io/oradba>
- [ ] Documentation version matches release
- [ ] Navigation works
- [ ] All pages render correctly
- [ ] Images display properly
- [ ] Search functionality works

### Included Documentation

- [ ] PDF documentation in dist/: `oradba-user-guide.pdf`
- [ ] HTML documentation in dist/: `oradba-user-guide.html`
- [ ] PDF opens correctly
- [ ] HTML renders in browser

## GitHub Release

- [ ] Release created at: <https://github.com/oehrlis/oradba/releases/tag/vX.X.X>
- [ ] Release notes accurate
- [ ] Artifacts uploaded:
  - [ ] `oradba_install.sh`
  - [ ] `oradba-X.X.X.tar.gz`
  - [ ] `oradba-user-guide.pdf`
  - [ ] `oradba-user-guide.html`
- [ ] All artifacts downloadable
- [ ] Checksums match (if provided)

## Compatibility Testing

### Operating Systems

Test on multiple platforms:

- [ ] Oracle Linux 8
- [ ] Oracle Linux 9
- [ ] Ubuntu 22.04 LTS
- [ ] macOS (development/testing)

### Oracle Versions

Test with different Oracle versions:

- [ ] Oracle Database 23ai Free
- [ ] Oracle Database 19c
- [ ] Oracle Database 21c
- [ ] CDB with PDBs
- [ ] Non-CDB database

### Shell Compatibility

- [ ] bash 4.x
- [ ] bash 5.x
- [ ] Works with `set -e` (errexit)
- [ ] Works with `set -u` (nounset)

## Rollback Testing

### Verify Uninstall (Standalone)

```bash
/opt/oracle/local/oradba/bin/oradba_uninstall.sh
```

- [ ] Uninstall script exists
- [ ] Uninstall completes cleanly
- [ ] Files removed from prefix
- [ ] Backup created (if configured)
- [ ] Environment restored

### Verify Downgrade

- [ ] Install previous version over current
- [ ] Verify downgrade works
- [ ] Configuration preserved

## Post-Release Checks

- [ ] Monitor GitHub Actions for any failures
- [ ] Check GitHub Issues for new bug reports
- [ ] Monitor documentation deployment
- [ ] Verify download counts on release page
- [ ] Update project README if needed
- [ ] Announce release (if applicable)

## Critical Issues Checklist

**If ANY of these fail, DO NOT publish release:**

- [ ] Installation fails on any platform
- [ ] Coexistence mode detection fails
- [ ] BasEnv aliases overridden in coexist mode
- [ ] Integrity check fails on clean install
- [ ] Core aliases missing
- [ ] ORACLE_HOME/ORACLE_SID set incorrectly
- [ ] Documentation not deployed
- [ ] Security vulnerabilities detected

## Sign-Off

**Tested by:** ___________________  
**Date:** ___________________  
**Environments tested:**

- [ ] Standalone: ___________________
- [ ] BasEnv: ___________________

**Release approved:** [ ] Yes [ ] No

**Notes/Issues:**

```text
_________________________________________________________________________
_________________________________________________________________________
_________________________________________________________________________
```

---

## Quick Test Scripts

### Standalone Quick Test

```bash
#!/bin/bash
# Quick smoke test for standalone installation

PREFIX="/opt/oracle/local/oradba"
SID="ORCL"

echo "=== Quick Standalone Test ==="
echo "Testing OraDBA $(cat $PREFIX/VERSION)"

# Source environment
source $PREFIX/bin/oraenv.sh $SID || exit 1

# Check key variables
[[ -n "$ORACLE_SID" ]] && echo "✓ ORACLE_SID: $ORACLE_SID" || echo "✗ ORACLE_SID not set"
[[ -n "$ORACLE_HOME" ]] && echo "✓ ORACLE_HOME: $ORACLE_HOME" || echo "✗ ORACLE_HOME not set"

# Check coexist mode
[[ "$ORADBA_COEXIST_MODE" == "standalone" ]] && echo "✓ Coexist mode: standalone" || echo "✗ Wrong coexist mode: $ORADBA_COEXIST_MODE"

# Check key aliases
type sq &>/dev/null && echo "✓ Alias 'sq' exists" || echo "✗ Alias 'sq' missing"
type taa &>/dev/null && echo "✓ Alias 'taa' exists" || echo "✗ Alias 'taa' missing"
type cdh &>/dev/null && echo "✓ Alias 'cdh' exists" || echo "✗ Alias 'cdh' missing"

# Version check
$PREFIX/bin/oradba_version.sh -c | grep -q "$(cat $PREFIX/VERSION)" && echo "✓ Version matches" || echo "✗ Version mismatch"

echo "=== Test Complete ==="
```

### BasEnv Coexistence Quick Test

```bash
#!/bin/bash
# Quick smoke test for BasEnv coexistence

PREFIX="/opt/oracle/local/oradba"
SID="ORCL"

echo "=== Quick BasEnv Coexistence Test ==="
echo "Testing OraDBA $(cat $PREFIX/VERSION) with BasEnv"

# Check BasEnv exists
[[ -f "$HOME/.BE_HOME" ]] || [[ -n "$BE_HOME" ]] || { echo "✗ BasEnv not detected"; exit 1; }
echo "✓ BasEnv detected"

# Source BasEnv first
source ~/.BE_HOME 2>/dev/null || source $BE_HOME 2>/dev/null || { echo "✗ Cannot source BasEnv"; exit 1; }
echo "✓ BasEnv sourced"

# Store BasEnv alias
basenv_taa=$(type -p taa 2>/dev/null || alias taa 2>/dev/null)

# Source OraDBA
source $PREFIX/bin/oraenv.sh $SID || exit 1

# Check coexist mode
[[ "$ORADBA_COEXIST_MODE" == "basenv" ]] && echo "✓ Coexist mode: basenv" || echo "✗ Wrong coexist mode: $ORADBA_COEXIST_MODE"

# Verify BasEnv alias NOT overridden
current_taa=$(type -p taa 2>/dev/null || alias taa 2>/dev/null)
[[ "$current_taa" == "$basenv_taa" ]] && echo "✓ BasEnv alias preserved" || echo "✗ BasEnv alias overridden!"

# Check OraDBA version
$PREFIX/bin/oradba_version.sh -i | grep -q "Coexist Mode.*basenv" && echo "✓ Version shows coexistence" || echo "✗ Version missing coexistence info"

# Check .install_info
grep -q "coexist_mode=basenv" $PREFIX/.install_info && echo "✓ install_info correct" || echo "✗ install_info wrong"

echo "=== Test Complete ==="
```

Save these scripts and make them executable for quick testing.
